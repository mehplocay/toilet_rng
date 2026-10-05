local RollService = require("../src/server/Services/RollService")
local ServiceCoins = require("../src/server/Services/ServiceCoinService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")

local legacyTargets = { 1, 4, 10, 25, 60, 120 }
local uptime, cohortSize = 0.75, 2000
local distributions = {}
local poop
for _, item in ipairs(Items) do
	if item.Id == "Poop" then
		poop = item
	end
end
assert(poop)

print("Minutes per next upgrade from an empty wallet; no tutorial/daily rewards, boosts or rebirth.")
print("Legacy sales uses 100% uptime; all other columns use 75% cooldown uptime.")
print("Service-only keeps every item. Poop-only sells fallback drops; neither requires a rare drop.")
print("From -> To              Sale EV   Service  Legacy sales  Sales+service  Poop-only  Service-only")
local serviceTotal, poopTotal = 0, 0
for tier, toilet in ipairs(Toilets) do
	local entries = RollService.Distribution(Items, Toilets, tier, toilet.Luck)
	distributions[tier] = entries
	local expected = 0
	for _, entry in ipairs(entries) do
		expected += entry.Probability * entry.Item.Value
	end
	local nextToilet = Toilets[tier + 1]
	if nextToilet then
		local minutesPerFlush = toilet.Cooldown / 60 / uptime
		local legacy = nextToilet.Price / expected * toilet.Cooldown / 60
		local withService = nextToilet.Price / (expected + toilet.ServiceCoins) * minutesPerFlush
		local poopOnly = math.ceil(nextToilet.Price / (poop.Value + toilet.ServiceCoins)) * minutesPerFlush
		local serviceOnly = math.ceil(nextToilet.Price / toilet.ServiceCoins) * minutesPerFlush
		print(
			string.format(
				"%-11s -> %-11s %7.2f %9d %12.2f %14.2f %10.2f %13.2f",
				toilet.Id,
				nextToilet.Id,
				expected,
				toilet.ServiceCoins,
				legacy,
				withService,
				poopOnly,
				serviceOnly
			)
		)
		assert(
			math.abs(legacy - legacyTargets[tier]) <= legacyTargets[tier] * 0.02,
			"Legacy sale-value balance outside 2% target for " .. nextToilet.Id
		)
		if tier <= 4 then
			serviceTotal += serviceOnly
			poopTotal += poopOnly
			assert(serviceOnly <= 35, "First four upgrades must each have a bounded service-only route")
		end
	else
		print(string.format("%-11s (final tier)     %7.2f %9d", toilet.Id, expected, toilet.ServiceCoins))
	end
end
assert(poopTotal <= 51 and serviceTotal <= 95, "Unlucky first-four progression exceeded its bound")
print(
	string.format(
		"First four cumulative upper bounds: Poop-only %.2f min; service-only %.2f min.",
		poopTotal,
		serviceTotal
	)
)

-- Fixed Park-Miller seed, independent rare-first checks, sequential purchases and carryover.
local seed = 20261005
local function sample()
	seed = seed * 16807 % 2147483647
	return seed / 2147483647
end
local stages, cumulative = {}, {}
for tier = 1, 4 do
	stages[tier], cumulative[tier] = {}, {}
end
for _ = 1, cohortSize do
	local profile = { Coins = 0, Stats = { Earned = 0 } }
	local elapsed = 0
	for tier = 1, 4 do
		local toilet, price = Toilets[tier], Toilets[tier + 1].Price
		local duration = 0
		while profile.Coins < price do
			local item = RollService.Sample(distributions[tier], sample)
			assert(ServiceCoins.Grant(profile, toilet) == toilet.ServiceCoins)
			-- Baseline cohort sells each drop; retained/displayed copies use the conservative bounds above.
			profile.Coins += item.Value
			profile.Stats.Earned += item.Value
			duration += toilet.Cooldown / 60 / uptime
		end
		profile.Coins -= price
		elapsed += duration
		table.insert(stages[tier], duration)
		table.insert(cumulative[tier], elapsed)
	end
end
local function percentile(values, fraction)
	table.sort(values)
	return values[math.ceil(#values * fraction)]
end
print(
	string.format(
		"Seeded cohort: %d players, 75%% uptime, sell every real drop, sequential upgrades, wallet carryover.",
		cohortSize
	)
)
print("Upgrade      Stage p50  Stage p90  Cumulative p50  Cumulative p90")
for tier = 1, 4 do
	local median = percentile(stages[tier], 0.5)
	local p90 = percentile(stages[tier], 0.9)
	print(
		string.format(
			"%-12s %9.2f %10.2f %15.2f %15.2f",
			Toilets[tier + 1].Id,
			median,
			p90,
			percentile(cumulative[tier], 0.5),
			percentile(cumulative[tier], 0.9)
		)
	)
	if tier == 1 then
		assert(median <= 2, "Median Dirty must take at most two active minutes")
	end
	assert(
		p90
			<= math.ceil(Toilets[tier + 1].Price / (poop.Value + Toilets[tier].ServiceCoins))
					* Toilets[tier].Cooldown
					/ 60
					/ uptime
				+ 1e-9,
		"Cohort exceeds all-Poop bound"
	)
end
print("Balance checks passed: legacy targets, deterministic progression bounds and median Dirty <= 2 min.")
