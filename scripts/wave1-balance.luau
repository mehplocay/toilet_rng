-- Runs directly against production config and economy math; no synthetic uncapped formula.
assert(require("./check-wave1"))
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Income")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Income = require("../src/shared/IncomeAccrual").new(Config, Items, U)
local Roll = require("../src/server/Services/RollService")
local Service = require("../src/server/Services/ServiceCoinService")
local Display = require("./display-cohort")
local Cohort = require("./economy-cohort")
local Spec = require("./wave1-contract")
local Inventory = require("../src/shared/SafeInventory")
local order = table.clone(Items)
table.sort(order, function(a, b)
	local ar, br = Config.RarityRates[a.Rarity], Config.RarityRates[b.Rarity]
	return if ar ~= br then ar > br elseif a.Value ~= b.Value then a.Value > b.Value else a.Id < b.Id
end)
local rank = {}
for i, item in ipairs(order) do
	rank[item.Id] = i
end
local failures = {}
local function percentile(values, fraction)
	return Cohort.Percentile(table.clone(values), fraction)
end
print("WAVE 1: INTEGRATED CONFIG; luck cap 10x; full luck on every item check.")
print("Cash: upgrade, rebirth, toilet and paid factors multiply without a multiplier cap.")
print("POOL | item | outcome at total luck 1x / 5x / 10x; Poop is the remainder")
for tier, toilet in ipairs(Toilets) do
	local maps = {}
	for _, luck in ipairs({ 1, 5, 10 }) do
		local map = {}
		for _, entry in ipairs(Roll.Distribution(Items, Toilets, tier, luck)) do
			map[entry.Item.Id] = entry.Probability
		end
		table.insert(maps, map)
	end
	for _, item in ipairs(Items) do
		if maps[1][item.Id] then
			print(
				string.format(
					"T%02d %-20s %-20s %.9g / %.9g / %.9g",
					tier,
					toilet.Id,
					item.Id,
					maps[1][item.Id],
					maps[2][item.Id],
					maps[3][item.Id]
				)
			)
		end
	end
end
print("FIRST SIGHT: expected flushes / online minutes from Basic; 75% uptime, no upgrades.")
for _, item in ipairs(Spec.Items) do
	local values = {}
	for _, luck in ipairs({ 1, 5, 10 }) do
		for _, entry in ipairs(Roll.Distribution(Items, Toilets, 1, luck)) do
			if entry.Item.Id == item.Id then
				local n = if entry.Probability > 0 then 1 / entry.Probability else math.huge
				table.insert(values, string.format("%.2f/%.2f", n, n * Toilets[1].Cooldown / 45))
			end
		end
	end
	print(item.Id .. " | " .. table.concat(values, " | "))
end
require("./income-balance").Print()
-- The original synthetic portfolio is retained, but settlement uses the real capped ledger.
local function simulate(player, uptime)
	local seed = 20261006 + player * 7919
	local function random()
		seed = seed * 16807 % 2147483647
		return seed / 2147483647
	end
	local p = {
		Coins = 0,
		Stats = { Earned = 0, Flushes = 0 },
		RebirthLevel = 0,
		Inventory = { Duck = 8, GoldenPoop = 2 },
		Collection = { Duck = 8, GoldenPoop = 2 },
		Displays = {},
		DisplaySlots = 10,
		ToiletTier = 7,
		Upgrades = { CashBoost = 4, LuckBoost = 4, FlushSpeed = 4 },
		Income = { UpdatedAt = 3100, Pending = {} },
	}
	Display.ReserveAndSell(p)
	local worst = rank[p.Displays["10"]] or math.huge
	local seconds, nextCollect = 2100, 2130
	local collectInterval = if uptime <= 0.3 then 120 elseif uptime >= 1 then 15 else 30
	local reached, oldTier, entries = {}, nil, nil
	-- Rates stay constant between collects, tier purchases and display changes.
	-- Settle at those boundaries using the production ledger instead of every flush.
	while p.ToiletTier < #Toilets and seconds < 300 * 3600 do
		if seconds >= nextCollect then
			Income:Settle(p, 1000 + math.floor(seconds), false)
			Income:Collect(p)
			nextCollect = seconds + collectInterval
		end
		local nextToilet = Toilets[p.ToiletTier + 1]
		if p.Coins >= nextToilet.Price then
			Income:Settle(p, 1000 + math.floor(seconds), false)
			p.Coins -= nextToilet.Price
			p.ToiletTier += 1
			reached[p.ToiletTier] = seconds / 60
		end
		local toilet = Toilets[p.ToiletTier]
		if oldTier ~= p.ToiletTier then
			entries = Roll.Distribution(Items, Toilets, p.ToiletTier, U:Luck(p, toilet.Luck))
			oldTier = p.ToiletTier
		end
		local item = Roll.Sample(entries, random())
		assert(Service.Grant(p, toilet, U:Cash(p)))
		p.Inventory[item.Id] = (p.Inventory[item.Id] or 0) + 1
		p.Collection[item.Id] = (p.Collection[item.Id] or 0) + 1
		if rank[item.Id] < worst then
			Income:Settle(p, 1000 + math.floor(seconds), false)
			Display.ReserveAndSell(p)
			worst = rank[p.Displays["10"]] or math.huge
		else
			local sellable = Inventory.Sellable(p, item.Id)
			if sellable > 0 then
				assert(Inventory.Sell(p, Items, item.Id, sellable, U:Cash(p)))
			end
		end
		seconds += U:Cooldown(p, toilet.Cooldown) / uptime
	end
	for tier = 8, #Toilets do
		reached[tier] = reached[tier] or math.huge
	end
	return reached
end
print("CONDITIONAL: 200 seeds/archetype; synthetic Galaxy at minute 35; 8 Ducks + 2 Golden Poops; ten slots.")
print(
	"Cash/Luck/Speed L4; no later upgrades, rebirth, paid benefits, offline/daily/events; real collect ledger and surplus sales."
)
print("This does not prove first-session Galaxy timing. Fresh-account results are in balance.luau.")
for _, arch in ipairs({ { "Normal", 0.75 }, { "Casual", 0.3 }, { "Grinder", 1 } }) do
	local cohorts = {}
	for tier = 8, #Toilets do
		cohorts[tier] = {}
	end
	for player = 1, 200 do
		for tier, time in pairs(simulate(player, arch[2])) do
			table.insert(cohorts[tier], time)
		end
	end
	for tier = 8, #Toilets do
		local median, tail = percentile(cohorts[tier], 0.5), percentile(cohorts[tier], 0.9)
		assert(median > 35 and median < math.huge and tail >= median)
		local target = Spec.Toilets[tier].TargetCumulativeMinutes
		if arch[1] == "Normal" then
			if median < target * 0.8 or median > target * 1.2 then
				table.insert(failures, Toilets[tier].Id .. " pacing drift: " .. median)
			end
		end
		if tier > 8 then
			assert(median > percentile(cohorts[tier - 1], 0.5), "Toilet arrival order drift")
		end
		print(
			string.format(
				"%s | %s | p50 %.2f / p90 %.2f min | normal target %.0f | historical uncapped %.0f",
				arch[1],
				Toilets[tier].Id,
				median,
				tail,
				target,
				Spec.Toilets[tier].HistoricalUncappedTargetMinutes or target
			)
		)
	end
end
assert(#failures == 0, table.concat(failures, "\n"))
local a, b = simulate(1, 0.75), simulate(1, 0.75)
for tier = 8, #Toilets do
	assert(a[tier] == b[tier], "Seed replay drift")
end
local p = {
	ToiletTier = 15,
	DisplaySlots = 10,
	Displays = {},
	Upgrades = {},
	Monetization = { Passes = { DoubleCash = true, VIPPack = true } },
}
for slot = 1, 10 do
	p.Displays[tostring(slot)] = "CosmicCourtesy"
end
local rate = 0
for _, units in pairs(Income:Rates(p)) do
	rate += units / Config.UnitsPerCoin
end
assert(rate == 975000000, "Unupgraded paid T15 display rate drift")
print(
	"T15 without upgrades/rebirth: ten Secrets = 325M/s free, 975M/s paid. Max R15/Cash L100: 22.1B/s free, 66.3B/s paid."
)
print(
	"PASS: actual catalog, caps, independent odds, first sight, uncapped showcase, three conditional cohorts and seeded replay."
)
