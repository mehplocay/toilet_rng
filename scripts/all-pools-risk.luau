local C = require("./economy-cohort")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Income")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Income = require("../src/shared/IncomeAccrual").new(Config, Items, U)
local cohort = C.Run(200, 0.75, false, nil, nil, 7)
print("Normal fresh-account fast/slow tails; same 200 deterministic seeds and purchase policy as balance.luau.")
print("| Toilet | p01 | p10 | p50 | p90 | p99 minutes |")
print("|---|---:|---:|---:|---:|---:|")
for tier = 2, 7 do
	local cells = { Toilets[tier].Name }
	for _, q in ipairs({ 0.01, 0.1, 0.5, 0.9, 0.99 }) do
		table.insert(cells, string.format("%.2f", C.Percentile(table.clone(cohort.Tiers[tier]), q)))
	end
	print("| " .. table.concat(cells, " | ") .. " |")
end
print(
	"Stress case: one item already displayed on Basic, no boosts, 30 online seconds before collection; not a probability estimate."
)
for _, id in ipairs({ "ToiletBaby", "PlungerPaladin", "StarlightSeraph", "CosmicCourtesy" }) do
	local p = {
		ToiletTier = 1,
		DisplaySlots = 3,
		Displays = { ["1"] = id },
		Upgrades = {},
		Coins = 0,
		Stats = { Earned = 0 },
		Income = { UpdatedAt = 1000, Pending = {} },
	}
	Income:Settle(p, 1030, false)
	print(id, Income:Collect(p), "Coins in 30 seconds")
end
print("Early jackpots intentionally can accelerate progression. Median pacing is not a minimum time gate.")
