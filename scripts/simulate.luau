local RollService = require("../src/server/Services/RollService")
local Simulation = require("../src/server/Simulation")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
math.randomseed(20261004)
Simulation.Run(RollService, Items, Toilets, math.random)
local Config = require("../src/shared/Config/Upgrades")
local upgrades = require("../src/shared/UpgradeRules").new(Config)
local luck = upgrades:Luck({ Upgrades = { LuckBoost = 10 } }, Toilets[#Toilets].Luck, 2, 2, 2)
assert(luck == 5)
local entries, empty = RollService.Distribution(Items, Toilets, #Toilets, luck)
local expected = 0
for _, entry in ipairs(entries) do
	if entry.Item.Event then
		expected += entry.Probability
	end
end
assert(empty == 0 and expected >= 0.00005 and expected <= 0.0000555)
math.randomseed(20261005)
local rolls = 5000000
local counts = Simulation.Run(RollService, Items, Toilets, math.random, rolls, #Toilets, luck)
local events, total = 0, 0
for _, item in ipairs(Items) do
	local count = counts[item.Id] or 0
	total += count
	if item.Event then
		events += count
	end
end
assert(total == rolls and not counts.NoDrop, "A roll did not return exactly one known item")
local tolerance = 6 * math.sqrt(rolls * expected * (1 - expected))
assert(math.abs(events - rolls * expected) <= tolerance, "Observed Event rate outside six-sigma seeded test range")
print(
	string.format(
		"5x cap: Event probability %.9f (%.6f%%); %d/%d observed; six-sigma count range %.1f..%.1f; no empty rolls.",
		expected,
		expected * 100,
		events,
		rolls,
		rolls * expected - tolerance,
		rolls * expected + tolerance
	)
)
