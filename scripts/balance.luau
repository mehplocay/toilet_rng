local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Cohort = require("./upgrade-cohort")
require("./rebirth-balance").Print()
local Rewards = require("../src/shared/Config/Rewards")
local Index = require("../src/shared/IndexProgress").new(Items, require("../src/shared/Config/IndexRewards"))
local uptime, cohortSize = 0.75, 2000
local targets = { 1.40, 4.48, 9.36, 17.87, 37.11, 47.29 }
print("Minutes per next toilet; 75% manual cooldown uptime, sequential tiers, carryover, protected first copies.")
print("Buy one level of Cash/Luck/Flush Speed per tier through level 4; buy each as affordable before the toilet.")
print("Auto speed, display slots and tank are optional utility purchases, excluded from this active cohort.")
print("No daily/index/tutorial/offline starting income or timed boosts. Legacy targets are pre-change stage medians.")
local stages, cumulative = Cohort.Run(Items, Toilets, cohortSize, true)
local noTracks = Cohort.Run(Items, Toilets, cohortSize, false)
print("Toilet        Price  Target  Stage p50  Stage p90  Cumulative p50/p90  No-track p50")
for tier, values in ipairs(stages) do
	local median = Cohort.Percentile(values, 0.5)
	local p90 = Cohort.Percentile(values, 0.9)
	assert(
		math.abs(median - targets[tier]) <= targets[tier] * 0.05,
		"Upgrade-aware stage median drift: " .. Toilets[tier + 1].Id
	)
	print(
		string.format(
			"%-12s %6d %7.2f %10.2f %10.2f %10.2f / %-8.2f %10.2f",
			Toilets[tier + 1].Id,
			Toilets[tier + 1].Price,
			targets[tier],
			median,
			p90,
			Cohort.Percentile(cumulative[tier], 0.5),
			Cohort.Percentile(cumulative[tier], 0.9),
			Cohort.Percentile(noTracks[tier], 0.5)
		)
	)
end
local serviceTotal, poopTotal = 0, 0
print("Conservative no-upgrade route: every item retained or only Poop duplicates sold; zero luck required.")
for tier = 1, 4 do
	local t, nextToilet = Toilets[tier], Toilets[tier + 1]
	local service = math.ceil(nextToilet.Price / t.ServiceCoins) * t.Cooldown / 60 / uptime
	local poop = (1 + math.ceil(nextToilet.Price / (Items[1].Value + t.ServiceCoins))) * t.Cooldown / 60 / uptime
	serviceTotal += service
	poopTotal += poop
	assert(service <= 50, "Deterministic stage bound exceeded")
	print(string.format("  %-12s service-only %.2f min; Poop-only %.2f min", nextToilet.Id, service, poop))
end
assert(serviceTotal <= 95 and poopTotal <= 70, "Fair-start four-tier bound exceeded")
print(string.format("First four cumulative bounds: service-only %.2f min; Poop-only %.2f min", serviceTotal, poopTotal))
print("Daily rewards: unchanged fixed grants (Cash Boost does not multiply them); day-one / day-seven Coins:")
for tier, t in ipairs(Toilets) do
	local first, last =
		Rewards.BaseCoins[1] * Rewards.TierMultipliers[tier], Rewards.BaseCoins[7] * Rewards.TierMultipliers[tier]
	assert(first > 0 and last <= 9e15)
	print(string.format("  %-12s %d / %d", t.Id, first, last))
end
local indexProfile = { Coins = 0, Stamps = 0, DisplaySlots = 3, Collection = {}, IndexClaims = {} }
for _, item in ipairs(Items) do
	indexProfile.Collection[item.Id] = 1
end
assert(Index:Claim(indexProfile, "total:5").Success and indexProfile.DisplaySlots == 4 and indexProfile.Coins == 0)
assert(not Index:Claim(indexProfile, "total:5").Success)
print("Index: once-only fourth slot retained; no Coins or luck minted. Fair start and stage medians passed.")
require("./income-balance").Print()
print("Display-enabled 200-player cohorts: actual retained copies, collection once/minute, no starting offline wallet.")
for _, slots in ipairs({ 3, 10 }) do
	local displayStages = Cohort.Run(Items, Toilets, 200, true, nil, slots)
	for tier, values in ipairs(displayStages) do
		local median = Cohort.Percentile(values, 0.5)
		assert(
			median >= targets[tier] * 0.70 and median <= targets[tier] * 1.25,
			"Display retention/earnings exceeded the measured progression envelope"
		)
		print(
			string.format(
				"  %d slots -> %-12s p50 %.2f min (original active target %.2f)",
				slots,
				Toilets[tier + 1].Id,
				median,
				targets[tier]
			)
		)
	end
	local first, second =
		require("./rebirth-balance").Run(require("../src/shared/Config/Rebirth").RequiredFlushes, 200, slots)
	print(string.format("  %d slots rebirth: first %.2f min, second %.2f min", slots, first, second))
	assert(
		first >= 60 and first <= 90 and second < first * 0.92 and second > 10,
		"Display-enabled rebirth left its timing targets"
	)
end
