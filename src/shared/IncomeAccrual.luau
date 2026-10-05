-- Pure fixed-point accounting; callers own the session lease and never yield during mutation.
local Income = {}
function Income.new(config, items)
	local self = { Config = config, Items = {} }
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
function Income:Sanitize(raw)
	local c = self.Config
	local result = { UpdatedAt = 0, Pending = {} }
	if type(raw) ~= "table" then
		return result
	end
	if type(raw.UpdatedAt) == "number" and raw.UpdatedAt <= c.MaxTimestamp then
		result.UpdatedAt = bounded(raw.UpdatedAt, c.MaxTimestamp)
	end
	local remaining = c.PlayerPendingCap * c.UnitsPerCoin
	for slot = 1, c.MaxSlots do
		local key = tostring(slot)
		local value = if type(raw.Pending) == "table" then raw.Pending[key] else nil
		local units = math.min(bounded(value, c.SlotPendingCap * c.UnitsPerCoin), remaining)
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
function Income:PendingCoins(profile)
	return math.floor(self:TotalUnits(profile) / self.Config.UnitsPerCoin)
end
function Income:Rates(profile)
	local c, rates, total = self.Config, {}, 0
	local slotCap = c.SlotRateCaps[profile.ToiletTier] or 0
	for slot = 1, math.min(profile.DisplaySlots, c.MaxSlots) do
		local key = tostring(slot)
		local item = self.Items[profile.Displays[key]]
		if item then
			local units = math.floor(math.min(item.Value * c.PassiveRate, slotCap) * c.UnitsPerCoin / 60 + 1e-9)
			rates[key], total = units, total + units
		end
	end
	local cap = math.floor((c.PlayerRateCaps[profile.ToiletTier] or 0) * c.UnitsPerCoin / 60)
	if total > cap then
		-- Cumulative rounding preserves the total cap without losing units for larger displays.
		local numerator, allocated = 0, 0
		for slot = 1, c.MaxSlots do
			local key = tostring(slot)
			numerator += (rates[key] or 0) * cap
			local cumulative = math.floor(numerator / total)
			rates[key], allocated = cumulative - allocated, cumulative
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
		elapsed = math.min(elapsed, c.OfflineMinutes * 60)
	end
	ledger.UpdatedAt = now -- Consume capped time too; reconnecting cannot reclaim it.
	local rates = self:Rates(profile)
	local room = c.PlayerPendingCap * c.UnitsPerCoin - self:TotalUnits(profile)
	for slot = 1, c.MaxSlots do
		local key = tostring(slot)
		local pending = ledger.Pending[key] or 0
		local grant = math.min((rates[key] or 0) * elapsed, c.SlotPendingCap * c.UnitsPerCoin - pending, room)
		if grant > 0 then
			ledger.Pending[key] = pending + grant
			room -= grant
		end
	end
end
function Income:Collect(profile)
	local c = self.Config
	local coins =
		math.min(self:PendingCoins(profile), c.MaxBalance - profile.Coins, c.MaxBalance - profile.Stats.Earned)
	if coins <= 0 then
		return 0
	end
	local remaining = coins * c.UnitsPerCoin
	for slot = 1, c.MaxSlots do
		local key = tostring(slot)
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
