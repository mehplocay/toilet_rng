-- Pure, bounded upgrade math. Server callers hold a live profile and never yield during Buy.
local Rules = {}
local Paid = require(if script then script.Parent.PaidBenefits else "./PaidBenefits")
Rules.__index = Rules
local function integer(value, maximum)
	return type(value) == "number" and value == value and value >= 0 and value <= maximum and value % 1 == 0
end
function Rules.new(config)
	local self = setmetatable({ Config = config, ById = {} }, Rules)
	for _, track in ipairs(config.Tracks) do
		assert(integer(track.MaxLevel, 12) and track.MaxLevel > 0)
		assert(
			track.Growth > 1
				and integer(math.ceil(track.BaseCost * track.Growth ^ (track.MaxLevel - 1)), config.MaxBalance)
		)
		self.ById[track.Id] = track
	end
	return self
end
function Rules:Level(profile, id)
	local raw = profile and profile.Upgrades
	local value = if type(raw) == "table" then raw[id] else nil
	return if integer(value, self.Config.MaxBalance) then math.min(value, self.ById[id].MaxLevel) else 0
end
function Rules:Sanitize(raw)
	local levels = {}
	for _, track in ipairs(self.Config.Tracks) do
		levels[track.Id] = self:Level({ Upgrades = raw }, track.Id)
	end
	return levels
end
function Rules:Restore(profile, raw)
	profile.Upgrades = self:Sanitize(raw)
	profile.DisplaySlots = math.max(
		profile.DisplaySlots,
		math.min(
			self.Config.DisplayCapacity,
			self.Config.BaseDisplaySlots + profile.Upgrades.DisplaySlots + Paid.Slots(profile)
		)
	)
end
function Rules:IndexSlots(profile, minimum)
	return math.min(self.Config.DisplayCapacity, minimum + self:Level(profile, "DisplaySlots") + Paid.Slots(profile))
end
function Rules:Price(id, level)
	local track = if type(id) == "string" then self.ById[id] else nil
	if not track or not integer(level, track.MaxLevel - 1) then
		return nil
	end
	return math.ceil(track.BaseCost * track.Growth ^ level)
end
function Rules:Cash(profile)
	return Paid.Cash(
		profile,
		1 + self:Level(profile, "CashBoost") * self.ById.CashBoost.Step + self:RebirthBonus(profile, "Cash")
	)
end
function Rules:RebirthBonus(profile, key)
	local level = profile and profile.RebirthLevel
	local bonus = if integer(level, #self.Config.Rebirth.Levels) then self.Config.Rebirth.Levels[level] else nil
	return if bonus then bonus[key] else 0
end
function Rules:Luck(profile, tier, ...)
	local cap = self.Config.LuckCap
	local luck = tier
		* (1 + self:Level(profile, "LuckBoost") * self.ById.LuckBoost.Step + self:RebirthBonus(profile, "Luck"))
	assert(luck >= 1 and luck < math.huge)
	luck = math.min(cap, luck)
	for i = 1, select("#", ...) do
		local factor = select(i, ...)
		assert(type(factor) == "number" and factor >= 1 and factor < math.huge)
		-- Clamp each positive factor before multiplication to prevent overflow.
		luck = math.min(cap, luck * math.min(cap, factor))
	end
	return luck
end
function Rules:Cooldown(profile, base)
	return math.max(
		self.Config.CooldownFloor,
		base * (1 - self:Level(profile, "FlushSpeed") * self.ById.FlushSpeed.Step - self:RebirthBonus(profile, "Speed"))
	)
end
function Rules:AutoInterval(profile, cooldown)
	return math.max(
		cooldown,
		cooldown
			* self.Config.AutoBaseMultiplier
			* (1 - self:Level(profile, "AutoFlushSpeed") * self.ById.AutoFlushSpeed.Step)
	)
end
function Rules:OfflineMinutes(profile, base)
	return Paid.Offline(profile, base + self:Level(profile, "OfflineTank") * self.ById.OfflineTank.Step)
end
function Rules:Animation(cooldown)
	return math.min(self.Config.AnimationMax, cooldown * 0.8)
end
function Rules:Buy(profile, id, expectedLevel)
	local track = if type(id) == "string" then self.ById[id] else nil
	if not profile or not track or not integer(expectedLevel, track.MaxLevel) then
		return false
	end
	local level = self:Level(profile, id)
	local price = self:Price(id, level)
	if
		level ~= expectedLevel
		or not price
		or not integer(profile.Coins, self.Config.MaxBalance)
		or profile.Coins < price
	then
		return false
	end
	if id == "DisplaySlots" and profile.DisplaySlots >= self.Config.DisplayCapacity then
		return false
	end
	profile.Upgrades = profile.Upgrades or self:Sanitize(nil)
	profile.Coins -= price
	profile.Upgrades[id] = level + 1
	if id == "DisplaySlots" then
		profile.DisplaySlots += 1
	end
	return true
end
function Rules:Snapshot(profile, cooldown, luck, offlineBase)
	return {
		CashMultiplier = self:Cash(profile),
		LuckMultiplier = luck,
		LuckCap = self.Config.LuckCap,
		LuckCapped = luck >= self.Config.LuckCap,
		Cooldown = cooldown,
		AutoInterval = self:AutoInterval(profile, cooldown),
		OfflineMinutes = self:OfflineMinutes(profile, offlineBase),
		DisplayCapacity = self.Config.DisplayCapacity,
	}
end
return Rules
