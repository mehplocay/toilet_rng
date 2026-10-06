local Rules = require("../src/shared/MonetizationRules")
local Config = require("../src/shared/Config/Monetization")
local Toilets = require("../src/shared/Config/Toilets")
local Limiter = require("../src/server/Services/RateLimiter")
local Remotes = require("../src/shared/Config/Remotes")

local profile = { Stats = { Flushes = 99 }, Settings = {}, Inventory = { Poop = 0 } }
assert(not Rules.AutoUnlocked(profile, Config))
assert(not Rules.AutoUnlocked(nil, Config))
assert(not Rules.AutoUnlocked({ Stats = { Flushes = 0 / 0 } }, Config))
assert(not Rules.AutoUnlocked({ Stats = { Flushes = math.huge } }, Config))
assert(not Rules.AutoEnabled(true, profile, true, Config))
profile.Stats.Flushes = 100
assert(Rules.AutoUnlocked(profile, Config))
assert(not Rules.AutoEnabled(nil, profile, true, Config)) -- Join never enables it.
assert(not Rules.AutoEnabled(false, profile, true, Config))
assert(not Rules.AutoEnabled("true", profile, true, Config))
assert(Rules.AutoEnabled(true, profile, true, Config))
assert(not Rules.AutoEnabled(true, profile, false, Config))
assert(not Rules.AutoEnabled(true, profile, nil, Config)) -- Missing/dead character.
assert(not Rules.AutoEnabled(true, nil, true, Config)) -- Unloaded/closing data.
for _, distance in ipairs({ -1, 0 / 0, math.huge, "0", {} }) do
	assert(not Rules.InRange(distance, Config))
end
local enabled = Rules.AutoEnabled(true, profile, true, Config)
enabled = Rules.AutoEnabled(enabled, profile, false, Config)
assert(not enabled)
assert(not Rules.AutoEnabled(enabled, profile, true, Config)) -- Returning does not resume.

for _, toilet in ipairs(Toilets) do
	assert(Rules.Cooldown(toilet.Cooldown, {}, Config) == toilet.Cooldown)
	assert(math.abs(Rules.Cooldown(toilet.Cooldown, { FastFlush = true }, Config) - toilet.Cooldown * 0.8) < 1e-12)
	assert(Rules.Cooldown(toilet.Cooldown, { FastFlush = "true" }, Config) == toilet.Cooldown)
end

-- The production reservation is shared by manual/auto requests and never yields.
local player, nextFlush, awards = {}, {}, 0
local cooldown = Rules.Cooldown(Toilets[#Toilets].Cooldown, { FastFlush = true }, Config)
local function flush(now, distance)
	if not Rules.TryFlush(nextFlush, player, now, distance, cooldown, Config) then
		return false
	end
	awards += 1
	profile.Stats.Flushes += 1
	profile.Inventory.Poop += 1
	return true
end
assert(not flush(10, 15) and nextFlush[player] == nil)
assert(flush(10, 0))
for _ = 1, 100 do
	assert(not flush(10, 0))
end
assert(not flush(10 + cooldown - 0.001, 0))
assert(flush(10 + cooldown, 0))
assert(profile.Inventory.Poop == 2 and profile.Stats.Flushes == 102 and awards == 2)
local ready = nextFlush[player]
assert(not flush(ready, nil) and nextFlush[player] == ready)
assert(flush(ready, 0))
assert(awards == 3)

local expectedPrices = {
	SparkleTrail = 49,
	VIPStar = 59,
	CustomPlotColor = 79,
	FastFlush = 99,
	DoubleCash = 249,
	AutoCollect = 149,
	ExtraSlots = 149,
	OfflinePlus = 129,
	VIPPack = 399,
}
for _, key in ipairs(Config.PassOrder) do
	assert(Rules.Pass(Config, key).Price == expectedPrices[key])
	assert(Config.Gamepasses[key].Id == 0)
end
assert(#Config.PassOrder == 9 and #Config.ProductOrder == 4)
local productPrices = { Coins10Minutes = 49, Coins1Hour = 149, Coins6Hours = 399, PathBoost10Minutes = 29 }
for _, key in ipairs(Config.ProductOrder) do
	assert(Config.DeveloperProducts[key].Price == productPrices[key])
	assert(Config.DeveloperProducts[key].Id == 0)
end
assert(Config.Gamepasses.DoubleLuck == nil and Config.Gamepasses.AutoFlush == nil)
assert(Rules.Pass(Config, {}) == nil and Rules.Pass(Config, "Unknown") == nil)
assert(Rules.PassKey(Config, 0) == nil)
local catalog = { PassOrder = { "Test" }, Gamepasses = { Test = { Id = 42 } } }
assert(Rules.PassKey(catalog, 42) == "Test")
assert(Rules.PassKey(catalog, "42") == nil and Rules.PassKey(catalog, 999) == nil)

local owned = {}
Rules.MergeOwnership(owned, "VIPStar", false, true)
assert(owned.VIPStar == nil) -- Failed lookup grants nothing.
Rules.MergeOwnership(owned, "VIPStar", true, false)
assert(owned.VIPStar == false)
Rules.MergeOwnership(owned, "VIPStar", true, true)
Rules.MergeOwnership(owned, "VIPStar", true, true) -- Duplicate completion.
Rules.MergeOwnership(owned, "VIPStar", false, false) -- API outage.
Rules.MergeOwnership(owned, "VIPStar", true, false) -- Stale load after purchase.
assert(owned.VIPStar == true)
Rules.MergeOwnership(owned, "FastFlush", true, "true")
assert(owned.FastFlush == false)

Rules.RestoreSettings(profile.Settings, nil, Config)
assert(profile.Settings.SkipAnimation == false and profile.Settings.PlotColor == "Default")
Rules.RestoreSettings(profile.Settings, { SkipAnimation = "true", PlotColor = "Unknown", AutoFlush = true }, Config)
assert(
	profile.Settings.SkipAnimation == false
		and profile.Settings.PlotColor == "Default"
		and profile.Settings.AutoFlush == nil
)
Rules.RestoreSettings(profile.Settings, { SkipAnimation = true, PlotColor = "Mint" }, Config)
assert(profile.Settings.SkipAnimation and profile.Settings.PlotColor == "Mint")
assert(not Rules.SetPlotColor(profile, {}, "Rose", Config))
assert(not Rules.SetPlotColor(profile, { CustomPlotColor = "true" }, "Rose", Config))
assert(profile.Settings.PlotColor == "Mint")
for _, id in ipairs({ "Unknown", "#FFFFFF", {}, 1, true }) do
	assert(not Rules.SetPlotColor(profile, { CustomPlotColor = true }, id, Config))
end
for _, color in ipairs(Config.PlotColors) do
	assert(Rules.SetPlotColor(profile, { CustomPlotColor = true }, color.Id, Config))
	assert(profile.Settings.PlotColor == color.Id)
end
assert(not Rules.SetPlotColor(nil, { CustomPlotColor = true }, "Mint", Config))

local limiter = Limiter.new(Remotes.Limits)
for _, action in ipairs({ "AutoFlush", "AnimationSkip", "PlotColor", "BuyPass", "RefreshPasses" }) do
	for _ = 1, Remotes.Limits[action].Capacity do
		assert(limiter:Allow(player, action))
	end
	assert(not limiter:Allow(player, action))
end
limiter:Remove(player)
assert(limiter.Players[player] == nil)
print(
	"Auto-Flush/pass checks passed: unlock, living guard, manual range, shared cooldown/awards, speed, ownership recovery, palette/settings, limits"
)
