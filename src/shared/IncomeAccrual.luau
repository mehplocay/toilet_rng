-- Pure fixed-point accounting; callers own the session lease and never yield during mutation.
local Income = {}
function Income.new(config, items, upgrades)
	local self = { Config = config, Items = {}, Upgrades = upgrades }
	for _, item in ipairs(items) do
		self.Items[item.Id] = item
	end
	return setmetatable(self, { __index = Income })
end
local function bounded(value, maximum)
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return math.min(math.floor(value), maximum)
end
function Income:CapacityMultiplier(profile)
	return if self.Upgrades and profile
		then self.Upgrades:Cash(profile)
			* self.Upgrades:OfflineMinutes(profile, self.Config.OfflineMinutes)
			/ self.Config.OfflineMinutes
		else 1
end
-- Keep the persisted scale; cap subcoins separately from wallet coins.
function Income:StorageUnits(profile, perSlot)
	local c = self.Config
	local coins = (if perSlot then c.SlotPendingCap else c.PlayerPendingCap) * self:CapacityMultiplier(profile)
	return math.floor(math.min(coins, math.floor(c.MaxLedgerUnits / c.UnitsPerCoin))) * c.UnitsPerCoin
end
function Income:Sanitize(raw, profile)
	local c = self.Config
	local result = { UpdatedAt = 0, Pending = {} }
	if type(raw) ~= "table" then
		return result
	end
	if type(raw.UpdatedAt) == "number" and raw.UpdatedAt <= c.MaxTimestamp then
		result.UpdatedAt = bounded(raw.UpdatedAt, c.MaxTimestamp)
	end
	local remaining = self:StorageUnits(profile, false)
	local slotStorage = self:StorageUnits(profile, true)
	for slot = 1, c.MaxSlots do
		local key = tostring(slot)
		local value = if type(raw.Pending) == "table" then raw.Pending[key] else nil
		local units = math.min(bounded(value, slotStorage), remaining)
		if units > 0 then
			result.Pending[key] = units
			remaining -= units
		end
	end
	return result
end
function Income:TotalUnits(profile)
	local total = 0
	for _, units in pairs(profile.Income.Pending) do
		total += units
	end
	return total
end
-- Division can round (9e15 - 1)/6000 up to a whole coin. Correct using exact integers.
function Income:WholeCoins(units)
	local scale = self.Config.UnitsPerCoin
	local coins = math.floor(units / scale)
	return if coins * scale > units then coins - 1 else coins
end
function Income:PendingCoins(profile)
	return self:WholeCoins(self:TotalUnits(profile))
end
function Income:Rates(profile)
	local c, rates, total = self.Config, {}, 0
	local cash = if self.Upgrades then self.Upgrades:Cash(profile) else 1
	local slotCap = c.SlotRateCaps[profile.ToiletTier] or 0
	for slot = 1, math.min(profile.DisplaySlots, c.MaxSlots) do
		local key = tostring(slot)
		local item = self.Items[profile.Displays[key]]
		if item then
			local units = math.floor(
				math.min((c.RarityRates[item.Rarity] or 0) * (c.TierMultipliers[profile.ToiletTier] or 0) * 60, slotCap)
						* cash
						* c.UnitsPerCoin
						/ 60
					+ 0.5
			)
			rates[key], total = units, total + units
		end
	end
	local cap = math.floor((c.PlayerRateCaps[profile.ToiletTier] or 0) * cash * c.UnitsPerCoin / 60)
	if total > cap then
		-- Divide first: multiplying rate by cap would lose integer precision.
		local allocated = 0
		for slot = 1, c.MaxSlots do
			local key = tostring(slot)
			local units = math.floor((rates[key] or 0) / total * cap)
			rates[key], allocated = units, allocated + units
		end
		local remaining = cap - allocated
		for slot = 1, c.MaxSlots do
			local key = tostring(slot)
			if remaining > 0 and rates[key] > 0 then
				rates[key] += 1
				remaining -= 1
			end
		end
	end
	return rates
end
function Income:Settle(profile, now, offline)
	local ledger, c = profile.Income, self.Config
	if ledger.UpdatedAt == 0 then
		ledger.UpdatedAt = now -- Migration never grants time before this feature existed.
		return
	end
	if now <= ledger.UpdatedAt then
		return -- Keep the high-water mark through backward clock adjustments.
	end
	local elapsed = now - ledger.UpdatedAt
	if offline then
		local minutes = if self.Upgrades
			then self.Upgrades:OfflineMinutes(profile, c.OfflineMinutes)
			else c.OfflineMinutes
		elapsed = math.min(elapsed, minutes * 60)
	end
	ledger.UpdatedAt = now -- Consume capped time too; reconnecting cannot reclaim it.
	local rates = self:Rates(profile)
	local room = self:StorageUnits(profile, false) - self:TotalUnits(profile)
	local slotStorage = self:StorageUnits(profile, true)
	for slot = 1, math.min(profile.DisplaySlots, c.MaxSlots) do
		local key = tostring(slot)
		local pending = ledger.Pending[key] or 0
		local limit = math.max(0, math.min(slotStorage - pending, room))
		local rate = rates[key] or 0
		-- Compare before multiplying: even decades elapsed cannot overflow subcoins.
		local grant = if rate > math.floor(limit / elapsed) then limit else rate * elapsed
		if grant > 0 then
			ledger.Pending[key] = pending + grant
			room -= grant
		end
	end
end
function Income:Collect(profile, slot)
	local c = self.Config
	if slot ~= nil and (type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > c.MaxSlots) then
		return 0
	end
	local available = if slot
		then self:WholeCoins(profile.Income.Pending[tostring(slot)] or 0)
		else self:PendingCoins(profile)
	local coins = math.min(available, c.MaxBalance - profile.Coins, c.MaxBalance - profile.Stats.Earned)
	if coins <= 0 then
		return 0
	end
	local remaining = coins * c.UnitsPerCoin
	for index = slot or 1, slot or c.MaxSlots do
		local key = tostring(index)
		local pending = profile.Income.Pending[key] or 0
		local debit = math.min(pending, remaining)
		profile.Income.Pending[key] = if pending > debit then pending - debit else nil
		remaining -= debit
	end
	profile.Coins += coins
	profile.Stats.Earned += coins
	return coins
end
return Income
