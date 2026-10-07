-- Subcoin accounting: exact at ordinary scales, approximate above 2^53. Mutations never yield.
local Income = {}
local CashMath = require(if script then script.Parent.CashMath else "./CashMath")
local Social = require(if script then script.Parent.SocialBoostRules else "./SocialBoostRules")
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
		then CashMath.Product(
			self.Upgrades:Cash(profile, nil, 1), -- Social boosts increase rates, not storage capacity.
			self.Upgrades:OfflineMinutes(profile, self.Config.OfflineMinutes) / self.Config.OfflineMinutes
		)
		else 1
end
-- Retain the persisted scale and apply the same technical bound in subcoin units.
function Income:StorageUnits(_profile, _perSlot)
	return self.Config.MaxLedgerUnits
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
			remaining = math.max(0, remaining - units)
		end
	end
	if type(raw.Offline) == "table" then
		local total = self:TotalUnits({ Income = result })
		local units = math.min(total, bounded(raw.Offline.Units, c.MaxLedgerUnits))
		if units > 0 then
			result.Offline = {
				Units = units,
				EarnedUnits = math.max(units, bounded(raw.Offline.EarnedUnits, c.MaxLedgerUnits)),
				AwaySeconds = bounded(raw.Offline.AwaySeconds, c.MaxTimestamp),
				FullSeconds = math.min(
					bounded(raw.Offline.FullSeconds, c.MaxTimestamp),
					bounded(raw.Offline.AwaySeconds, c.MaxTimestamp)
				),
			}
		end
	end
	return result
end

function Income:OfflineSnapshot(profile)
	local report = profile.Income.Offline
	if not report or self:WholeCoins(report.Units) < 1 then
		return nil
	end
	return {
		Coins = self:WholeCoins(report.Units),
		Earned = self:WholeCoins(report.EarnedUnits),
		AwaySeconds = report.AwaySeconds,
		FullSeconds = report.FullSeconds,
	}
end
function Income:TotalUnits(profile)
	local total = 0
	for _, units in pairs(profile.Income.Pending) do
		total = CashMath.Add(total, units, self.Config.MaxLedgerUnits)
	end
	return total
end
-- Correct division rounding while subcoins are exact; larger amounts intentionally approximate.
function Income:WholeCoins(units)
	local scale = self.Config.UnitsPerCoin
	local coins = math.floor(units / scale)
	return if units < 2 ^ 53 and coins * scale > units then coins - 1 else coins
end
function Income:PendingCoins(profile)
	return self:WholeCoins(self:TotalUnits(profile))
end
function Income:Rates(profile, socialFactor)
	local c, rates, total = self.Config, {}, 0
	local tier = c.TierMultipliers[profile.ToiletTier] or 0
	if tier <= 0 then
		return rates
	end
	local slots = math.min(profile.DisplaySlots, c.MaxSlots)
	local cash = if self.Upgrades then self.Upgrades:Cash(profile, tier, socialFactor) else tier
	-- Sum unmultiplied weights first, so even 100 extreme slots cannot overflow.
	local slotCap = (c.SlotRateCaps[profile.ToiletTier] or 0) / tier / 60
	for slot = 1, slots do
		local key = tostring(slot)
		local item = self.Items[profile.Displays[key]]
		if item then
			local weight = CashMath.Product(math.min(c.RarityRates[item.Rarity] or 0, slotCap), c.UnitsPerCoin)
			rates[key], total = weight, CashMath.Add(total, weight)
		end
	end
	if total == 0 then
		return rates
	end
	local playerCap = CashMath.Product((c.PlayerRateCaps[profile.ToiletTier] or 0) / tier / 60, c.UnitsPerCoin)
	local base = math.min(total, playerCap)
	local cap = math.floor(CashMath.Product(base, cash, c.MaxLedgerUnits))
	if total <= playerCap and cash < c.MaxLedgerUnits / total then
		local remaining = c.MaxLedgerUnits
		for slot = 1, slots do
			local key = tostring(slot)
			if rates[key] then
				local units = math.min(remaining, CashMath.Round(CashMath.Product(rates[key], cash, c.MaxLedgerUnits)))
				rates[key], remaining = units, remaining - units
			end
		end
	else
		local allocated = 0
		for slot = 1, slots do
			local key = tostring(slot)
			local units = math.min(math.max(0, cap - allocated), math.floor((rates[key] or 0) / total * cap))
			rates[key], allocated = units, allocated + units
		end
		local remaining = cap - allocated
		for slot = 1, slots do
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
	local away = elapsed
	if offline then
		local minutes = if self.Upgrades
			then self.Upgrades:OfflineMinutes(profile, c.OfflineMinutes)
			else c.OfflineMinutes
		elapsed = math.min(elapsed, math.min(minutes, c.MaxOfflineMinutes) * 60)
	end
	local socialFactor = Social.Average(profile, ledger.UpdatedAt, ledger.UpdatedAt + elapsed, offline)
	ledger.UpdatedAt = now -- Consume capped time too; reconnecting cannot reclaim it.
	local rates = self:Rates(profile, socialFactor)
	local before = self:TotalUnits(profile)
	local room = self:StorageUnits(profile, false) - before
	local slotStorage = self:StorageUnits(profile, true)
	local potential, hasRate = if offline then {} else nil, false
	for slot = 1, math.min(profile.DisplaySlots, c.MaxSlots) do
		local key = tostring(slot)
		local pending = ledger.Pending[key] or 0
		local limit = math.max(0, math.min(slotStorage - pending, room))
		local rate = rates[key] or 0
		if offline then
			rate = math.floor(rate * math.clamp(c.OfflineRate, 0, 1))
			hasRate = hasRate or rate > 0
			potential[key] = { Rate = rate, Room = math.max(0, slotStorage - pending) }
		end
		-- Compare before multiplying: even decades elapsed cannot overflow subcoins.
		local grant = if rate > math.floor(limit / elapsed) then limit else rate * elapsed
		if grant > 0 then
			ledger.Pending[key] = CashMath.Credit(pending, grant)
			room -= grant
		end
	end
	if offline then
		local grant = self:TotalUnits(profile) - before
		local old = ledger.Offline
		if grant > 0 or old then
			-- Earliest whole second when all credited income had fit. This accounts for
			-- individual tanks and the shared hard cap without overflowing multiplication.
			local low, high = 0, elapsed
			while low < high do
				local middle = math.floor((low + high) / 2)
				local sum = 0
				for _, entry in pairs(potential) do
					local limit = math.min(entry.Room, grant - sum)
					sum += if middle > 0 and entry.Rate > math.floor(limit / middle) then limit else entry.Rate * middle
				end
				if sum >= grant then
					high = middle
				else
					low = middle + 1
				end
			end
			ledger.Offline = {
				Units = math.min(c.MaxLedgerUnits, (if old then old.Units else 0) + grant),
				EarnedUnits = (if old then old.EarnedUnits else 0)
					+ math.min(c.MaxLedgerUnits - (if old then old.EarnedUnits else 0), grant),
				AwaySeconds = math.min(c.MaxTimestamp, (if old then old.AwaySeconds else 0) + away),
				FullSeconds = math.min(
					c.MaxTimestamp,
					(if old then old.FullSeconds else 0) + (if hasRate then away - low else 0)
				),
			}
		end
	end
end
function Income:Collect(profile, slot, maximum)
	local c = self.Config
	if slot ~= nil and (type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > c.MaxSlots) then
		return 0
	end
	local available = if slot
		then self:WholeCoins(profile.Income.Pending[tostring(slot)] or 0)
		else self:PendingCoins(profile)
	local coins =
		math.min(available, maximum or c.MaxBalance, c.MaxBalance - profile.Coins, c.MaxBalance - profile.Stats.Earned)
	if coins <= 0 or not CashMath.CanGrant(profile, coins) then
		return 0
	end
	local remaining = CashMath.Product(coins, c.UnitsPerCoin)
	local pendingCopy = table.clone(profile.Income.Pending)
	for index = slot or 1, slot or c.MaxSlots do
		local key = tostring(index)
		local pending = profile.Income.Pending[key] or 0
		-- At approximate magnitudes consume conversion dust together with the award.
		-- Exact subcoin tails below 2^53 remain untouched.
		local debit = if pending >= 2 ^ 53
				and remaining > 0
				and CashMath.Near(pending, remaining)
			then pending
			else math.min(pending, remaining)
		local after = pending - debit
		if debit > 0 and after == pending then
			return 0
		end
		after = CashMath.Subtract(pending, debit)
		pendingCopy[key] = if after > 0 then after else nil
		remaining = math.max(0, remaining - debit)
	end
	if remaining > 0 and not CashMath.Near(remaining, 0) and remaining > coins * c.UnitsPerCoin * 2 ^ -48 then
		return 0
	end
	profile.Income.Pending = pendingCopy
	profile.Coins = CashMath.Credit(profile.Coins, coins)
	profile.Stats.Earned += coins
	-- Coins are fungible: every pad/jar/away collection consumes offline credit first.
	local report = profile.Income.Offline
	if report then
		local debit = CashMath.Product(coins, c.UnitsPerCoin)
		report.Units = if report.Units >= 2 ^ 53 and CashMath.Near(report.Units, debit)
			then 0
			else math.max(0, report.Units - debit)
		if report.Units == 0 then
			profile.Income.Offline = nil
		end
	end
	return coins
end
return Income
