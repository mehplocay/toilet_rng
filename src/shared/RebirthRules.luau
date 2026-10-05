-- Pure reset construction. The caller swaps this complete tree without yielding.
local Rules = {}
local IndexRewards = require(if script then script.Parent.Config.IndexRewards else "./Config/IndexRewards")
Rules.__index = Rules
local function integer(value, maximum)
	return type(value) == "number" and value == value and value >= 0 and value <= maximum and value % 1 == 0
end
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end
function Rules.new(config)
	return setmetatable({ Config = config }, Rules)
end
function Rules:Level(profile)
	local value = profile and profile.RebirthLevel
	return if integer(value, self.Config.MaxBalance) then math.min(value, #self.Config.Levels) else 0
end
function Rules:Bonus(profile)
	return self.Config.Levels[self:Level(profile)]
		or { Cash = 0, Luck = 0, Speed = 0, StarterCoins = 0, Title = "New Flusher", Perks = {} }
end
function Rules:Restore(profile, raw)
	profile.RebirthLevel = self:Level(raw)
	local flushes = raw and raw.RunFlushes
	-- Legacy lifetime rolls count toward the first run, never toward later runs.
	profile.RunFlushes = if integer(flushes, self.Config.MaxBalance)
		then flushes
		elseif profile.RebirthLevel == 0 then profile.Stats.Flushes
		else 0
	profile.ProtectedInventory = {}
	for id, count in pairs(profile.Inventory) do
		local protected = raw and type(raw.ProtectedInventory) == "table" and raw.ProtectedInventory[id]
		if integer(protected, self.Config.MaxBalance) then
			profile.ProtectedInventory[id] = math.min(count, protected)
		end
	end
end
function Rules:Eligible(profile, expectedLevel)
	return profile ~= nil
		and integer(expectedLevel, #self.Config.Levels - 1)
		and self:Level(profile) == expectedLevel
		and (profile.RunFlushes or 0) >= self.Config.RequiredFlushes
		and profile.ToiletTier >= self.Config.RequiredTier
end
function Rules:Build(profile, expectedLevel, now)
	if not self:Eligible(profile, expectedLevel) then
		return nil
	end
	local result = copy(profile)
	result.RebirthLevel, result.RunFlushes = expectedLevel + 1, 0
	local bonus = self:Bonus(result)
	if result.Stats.Earned > self.Config.MaxBalance - bonus.StarterCoins then
		return nil
	end
	result.Coins, result.ToiletTier = bonus.StarterCoins, self.Config.ResetTier
	result.Stats.Earned += bonus.StarterCoins
	-- Preserve capacity of unknown/legacy/paid origin. Remove only tracked coin purchases.
	result.DisplaySlots =
		math.max(self.Config.BaseDisplaySlots, profile.DisplaySlots - (profile.Upgrades.DisplaySlots or 0))
	for _, reward in ipairs(IndexRewards.Milestones) do
		if profile.IndexClaims["total:" .. reward.Count] and reward.DisplaySlots then
			result.DisplaySlots = math.max(result.DisplaySlots, reward.DisplaySlots)
		end
	end
	for id in pairs(result.Upgrades) do
		result.Upgrades[id] = 0
	end
	local reserved = {}
	for _, id in pairs(profile.Displays) do
		reserved[id] = (reserved[id] or 0) + 1
	end
	result.ProtectedInventory = {}
	for id, count in pairs(profile.Inventory) do
		local kept = math.min(count, math.max(1, reserved[id] or 0, (profile.ProtectedInventory or {})[id] or 0))
		result.Inventory[id], result.ProtectedInventory[id] = kept, kept
	end
	-- Repack surviving displays into retained slots; excess copies stay protected in inventory.
	result.Displays = {}
	local destination = 1
	for slot = 1, profile.DisplaySlots do
		local id = profile.Displays[tostring(slot)]
		if id and destination <= result.DisplaySlots then
			result.Displays[tostring(destination)] = id
			destination += 1
		end
	end
	result.Income = { Pending = {}, UpdatedAt = math.max(now, profile.Income.UpdatedAt) }
	return result
end
return Rules
