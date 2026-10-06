-- Pure reset construction. The caller swaps this complete tree without yielding.
local Rules = {}
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
		and integer(profile.RunFlushes, self.Config.MaxBalance)
		and profile.RunFlushes >= self.Config.RequiredFlushes
		and integer(profile.Coins, self.Config.MaxBalance)
		and profile.Coins >= self.Config.Levels[expectedLevel + 1].RequiredCoins
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
	result.Coins = bonus.StarterCoins
	result.Stats.Earned += bonus.StarterCoins
	local reserved = {}
	for _, id in pairs(profile.Displays) do
		reserved[id] = (reserved[id] or 0) + 1
	end
	result.Inventory, result.ProtectedInventory = {}, {}
	for id, count in pairs(reserved) do
		local kept = math.min(count, profile.Inventory[id] or 0)
		result.Inventory[id], result.ProtectedInventory[id] = kept, kept
	end
	-- Copied tier, upgrades, capacity and exact display positions are permanent.
	result.Income = { Pending = {}, UpdatedAt = math.max(now, profile.Income.UpdatedAt) }
	return result
end
return Rules
