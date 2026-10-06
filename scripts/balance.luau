local C = require("./economy-cohort")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Income = require("../src/shared/Config/Income")
local Upgrades = require("../src/shared/Config/Upgrades")
local Rebirth = require("../src/shared/Config/Rebirth")
local U = require("../src/shared/UpgradeRules").new(Upgrades)
print(
	"INCOME-FIRST v2: 200 seeded accounts per archetype; fresh wallet/inventory, real protected sales and purchased slots."
)
print("Uptime: casual 30%, normal 75%, grinder 100%; collect every 120/30/15 seconds, passive runs throughout.")
print(
	"Buy Dirty first; then 5 slots, 10 at Diamond; one Cash/Luck/Speed level per tier through L4. No index/daily/pass/event/offline grants."
)
print(
	"Times are cumulative wall-clock minutes. Galaxy run defers rebirth; separate two-run cohort rebirths immediately."
)
print(
	"Cash Boost / rebirth bonuses add; toilet display multipliers multiply. Counts use unchanged rare-first probabilities."
)
print("Base rarity income per item ($/s): Basic / Dirty / Golden / Diamond / Radioactive / Demon / Galaxy")
for _, rarity in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly", "Secret" }) do
	local row = {}
	for _, factor in ipairs(Income.TierMultipliers) do
		table.insert(row, (string.format("%.4f", Income.RarityRates[rarity] * factor):gsub("0+$", ""):gsub("%.$", "")))
	end
	print(rarity .. " | " .. table.concat(row, " | "))
end
print("Sell values (before cash):")
for _, item in ipairs(Items) do
	print(item.Id, item.Value)
end
print("Upgrade costs: first / last; exponential growth; max level")
for _, t in ipairs(Upgrades.Tracks) do
	print(t.Id, t.BaseCost, U:Price(t.Id, t.MaxLevel - 1), t.Growth, t.MaxLevel)
end
local target = { 0, 1.25, 3, 8, 20, 45, 90 }
for _, archetype in ipairs({ { "Casual", 0.3 }, { "Normal", 0.75 }, { "Grinder", 1 } }) do
	local r = C.Run(200, archetype[2], false)
	local b = C.Run(200, archetype[2], true)
	print(archetype[1] .. " | Tier | Price | target | p50 | p90 (minutes)")
	for tier = 2, #Toilets do
		local median, tail = C.Percentile(r.Tiers[tier], 0.5), C.Percentile(r.Tiers[tier], 0.9)
		print(
			string.format(
				"%-7s | %-12s | %9d | %5.2f | %7.2f | %7.2f",
				archetype[1],
				Toilets[tier].Id,
				Toilets[tier].Price,
				target[tier],
				median,
				tail
			)
		)
		if archetype[1] == "Normal" then
			assert(
				median >= (if tier == 2 then 1 else target[tier] * 0.8)
					and median <= (if tier == 2 then 1.5 else target[tier] * 1.2),
				"Cumulative tier target missed: " .. Toilets[tier].Id
			)
		end
	end
	local early, mid = C.Percentile(r.EarlyShare, 0.5), C.Percentile(r.MidShare, 0.5)
	print(
		string.format(
			"%s passive share: first 10 min %.2f%%; 10 min after Diamond %.2f%%",
			archetype[1],
			early * 100,
			mid * 100
		)
	)
	local first, second = C.Percentile(b.Runs[1], 0.5), C.Percentile(b.Runs[2], 0.5)
	print(
		string.format(
			"%s rebirth %d flushes: first p50 %.2f / p90 %.2f; second p50 %.2f / p90 %.2f",
			archetype[1],
			Rebirth.RequiredFlushes,
			first,
			C.Percentile(b.Runs[1], 0.9),
			second,
			C.Percentile(b.Runs[2], 0.9)
		)
	)
	assert(
		second < first * 0.92 and second > 10,
		"Retained income should accelerate the next run without instant rebirth"
	)
	if archetype[1] == "Normal" then
		assert(early >= 0.4 and early <= 0.6 and mid >= 0.7 and mid <= 0.9, "Earned-income mix missed")
		assert(first >= 54 and first <= 66, "First rebirth must remain about 60 minutes")
	end
end
local five = C.Run(200, 0.75, false, 5, 600)
local share = C.Percentile(five.EarlyShare, 0.5)
print(
	string.format(
		"Normal, five-slot limit: first 10-minute passive share %.2f%% (slots purchased, no free inventory)",
		share * 100
	)
)
assert(share >= 0.4 and share <= 0.6, "Five-slot early target missed")
-- Exact seed replay through every production mutation, including two complete resets.
local a, b = C.Run(3, 0.75, true), C.Run(3, 0.75, true)
for run = 1, 2 do
	for i = 1, 3 do
		assert(a.Runs[run][i] == b.Runs[run][i], "Seeded simulation drift")
	end
end
require("./income-balance").Print()
print("Offline: 8 hours base / 12 hours max tank; wallet <=9e15 coins; entire ledger <=9e15 integer subcoins.")
print("All v2 balance targets and deterministic replay passed. Rare jackpot tails can exceed typical income shares.")
