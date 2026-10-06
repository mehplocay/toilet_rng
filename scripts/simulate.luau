local Roll = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Upgrades")
assert(Config.LuckCap == 10)
print("Galaxy effective odds: independent rare-first checks; Poop fallback, no paid luck.")
for _, luck in ipairs({ 1, 5, 10 }) do
	local entries, empty = Roll.Distribution(Items, Toilets, 7, luck)
	local total, secrets, events = 0, 0, 0
	local counts = {}
	math.randomseed(20261006 + luck)
	local n = 1000000
	for _ = 1, n do
		local item = Roll.Sample(entries, math.random)
		assert(item)
		counts[item.Id] = (counts[item.Id] or 0) + 1
	end
	local counted = 0
	for _, entry in ipairs(entries) do
		local p = entry.Probability
		local observed = counts[entry.Item.Id] or 0
		counted += observed
		total += p
		if entry.Item.Rarity == "Secret" then
			secrets += p
		end
		if entry.Item.Event then
			events += p
		end
		assert(
			math.abs(observed - n * p) <= 6 * math.sqrt(n * p * (1 - p)) + 1,
			"Seeded odds outside six sigma: " .. entry.Item.Id
		)
		print(
			string.format(
				"%dx | %-14s | check %.9f | effective 1 / %.3f | observed %d / %d",
				luck,
				entry.Item.Id,
				entry.Check,
				if p > 0 then 1 / p else math.huge,
				observed,
				n
			)
		)
	end
	assert(counted == n and empty == 0 and math.abs(total - 1) < 1e-12)
	print(
		string.format(
			"%dx | expected first Secret at 1 flush/s: %.2f hours; event probability %.9f; 12 players at 0.4s floor: %.3f events/hour",
			luck,
			1 / secrets / 3600,
			events,
			events * 30 * 3600
		)
	)
	assert(events <= 0.00008325 and events * 30 < 1 / 8, "Expected arrivals exceed existing event drain")
end
print("Odds simulation passed: all items, 3 million independent rolls, exact sum 1; queue/rate limit unchanged.")
