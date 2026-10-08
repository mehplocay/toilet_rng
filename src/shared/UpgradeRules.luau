-- Pure, bounded upgrade math. Server callers hold a live profile and never yield during Buy.
local Rules = {}
local CashMath = require(if script then script.Parent.CashMath else "./CashMath")
local Paid = require(if script then script.Parent.PaidBenefits else "./PaidBenefits")
local Income = require(if script then script.Parent.Config.Income else "./Config/Income")
local Social = require(if script then script.Parent.SocialBoostRules else "./SocialBoostRules")
Rules.__index = Rules
local function integer(value, maximum)
	return type(value) == "number" and value == value and value >= 0 and value <= maximum and value % 1 == 0
end
function Rules.new(config)
	local self = setmetatable({ Config = config, ById = {} }, Rules)
	for _, track in ipairs(config.Tracks) do
		assert(integer(track.MaxLevel, 100) and track.MaxLevel > 0)
		self.ById[track.Id] = track
		local previous = 0
		for level = 0, track.MaxLevel - 1 do
			local price = self:Price(track.Id, level)
			assert(
				integer(price, config.MaxBalance) and (price > previous or price == config.MaxBalance),
				"Invalid upgrade curve"
			)
			previous = price
		end
	end
	return self
end
function Rules:Level(profile, id)
	local raw = profile and profile.Upgrades
	local value = if type(raw) == "table" then raw[id] else nil
	return if integer(value, 9e15) then math.min(value, self.ById[id].MaxLevel) else 0
end
function Rules:Sanitize(raw)
	local levels = {}
	for _, track in ipairs(self.Config.Tracks) do
		levels[track.Id] = self:Level({ Upgrades = raw }, track.Id)
	end
	return levels
end
function Rules:Restore(profile, raw, version)
	profile.Upgrades = self:Sanitize(raw)
	if version ~= nil and version < self.Config.Version then
		-- Never reinterpret corrupt legacy levels as new purchases.
		for id, level in pairs(profile.Upgrades) do
			profile.Upgrades[id] = math.min(level, if id == "DisplaySlots" then 7 else 10)
		end
	end
	profile.UpgradeVersion = self.Config.Version
	profile.DisplaySlots = math.max(
		profile.DisplaySlots,
		math.min(self.Config.DisplayCapacity, self.Config.BaseDisplaySlots + profile.Upgrades.DisplaySlots)
	)
end
function Rules:IndexSlots(profile, minimum)
	return math.min(self.Config.DisplayCapacity, minimum + self:Level(profile, "DisplaySlots"))
end
function Rules:Price(id, level)
	local track = if type(id) == "string" then self.ById[id] else nil
	if not track or not integer(level, track.MaxLevel - 1) then
		return nil
	end
	if track.Costs then
		local target = level + 1
		for i = 2, #track.Costs do
			local a, b = track.Costs[i - 1], track.Costs[i]
			if target <= b[1] then
				return math.ceil(CashMath.Product(a[2], CashMath.Power(b[2] / a[2], (target - a[1]) / (b[1] - a[1]))))
			end
		end
	end
	return math.ceil(CashMath.Product(track.BaseCost, CashMath.Power(track.Growth, level)))
end
function Rules:Effect(profile, id)
	local track, level = self.ById[id], self:Level(profile, id)
	return math.min(level, 10) * track.Step + math.max(0, level - 10) * (track.LateStep or track.Step)
end
function Rules:Milestone(profile, id)
	local track, level = self.ById[id], self:Level(profile, id)
	if
		level == track.MaxLevel
		or (id == "DisplaySlots" and (profile.DisplaySlots or 0) >= self.Config.DisplayCapacity)
	then
		return track.Name .. " Master", nil
	end
	local reached = math.floor(level / self.Config.MilestoneEvery) * self.Config.MilestoneEvery
	return if reached > 0
		then track.Name .. " " .. self.Config.MilestoneTitles[reached / self.Config.MilestoneEvery]
		else "Novice",
		math.min(track.MaxLevel, reached + self.Config.MilestoneEvery)
end
function Rules:Cash(profile, toiletFactor, socialFactor)
	return Paid.Cash(
		profile,
		CashMath.Product(
			CashMath.Product(1 + self:Effect(profile, "CashBoost"), 1 + self:RebirthBonus(profile, "Cash")),
			CashMath.Product(toiletFactor or 1, socialFactor or Social.Multiplier(profile))
		)
	)
end
function Rules:RebirthBonus(profile, key)
	local level = profile and profile.RebirthLevel
	local bonus = if integer(level, #self.Config.Rebirth.Levels) then self.Config.Rebirth.Levels[level] else nil
	return if bonus then bonus[key] else 0
end
function Rules:Luck(profile, tier, ...)
	assert(type(tier) == "number" and tier >= 1 and tier < math.huge, "Invalid toilet luck")
	local luck = tier
		* (1 + self:Effect(profile, "LuckBoost") + self:RebirthBonus(profile, "Luck"))
		* Social.Luck(profile)
	assert(luck >= 1 and luck < math.huge, "Non-finite luck")
	for i = 1, select("#", ...) do
		local factor = select(i, ...)
		assert(type(factor) == "number" and factor >= 1 and factor < math.huge)
		luck *= factor
		-- Reject numeric overflow; never silently clip a valid luck multiplier.
		assert(luck < math.huge, "Luck multiplication overflow")
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
	return math.min(Income.MaxOfflineMinutes, Paid.Offline(profile, base + self:Effect(profile, "OfflineTank")))
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
		or not CashMath.Affords(profile.Coins, price)
	then
		return false
	end
	if id == "DisplaySlots" and profile.DisplaySlots >= self.Config.DisplayCapacity then
		return false
	end
	profile.Upgrades = profile.Upgrades or self:Sanitize(nil)
	profile.Coins = CashMath.Debit(profile.Coins, price)
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
		Cooldown = cooldown,
		AutoInterval = self:AutoInterval(profile, cooldown),
		OfflineMinutes = self:OfflineMinutes(profile, offlineBase),
		DisplayCapacity = self.Config.DisplayCapacity,
	}
end
return Rules
