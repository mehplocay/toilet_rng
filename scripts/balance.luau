local RollService = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Upgrades = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Cohort = require("./upgrade-cohort")
local Rewards = require("../src/shared/Config/Rewards")
local Index = require("../src/shared/IndexProgress").new(Items, require("../src/shared/Config/IndexRewards"))
local uptime, cohortSize = 0.75, 2000
local distributions = {}
for tier, toilet in ipairs(Toilets) do
	distributions[tier] = RollService.Distribution(Items, Toilets, tier, toilet.Luck)
end
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
local IncomeConfig = require("../src/shared/Config/Income")
local Income = require("../src/shared/IncomeAccrual").new(IncomeConfig, Items, Upgrades)
print("\nDisplay income: 1% sell value/minute, tier rate caps, no boosts/rewards/offline starting wallet.")
print("Realistic upper showcase: best copies from floor(expected drops in 60 min at this tier, 75% uptime).")
print("Copies are reserved, not sold; construction cost is ignored, so this overstates immediate benefit.")
print(
	"Tier        Slots  Display coins/min  Active coins/min  Ratio   Next upgrade min (base / +display)  Best realistic copies"
)
for tier, toilet in ipairs(Toilets) do
	local entries = table.clone(distributions[tier])
	table.sort(entries, function(a, b)
		return a.Item.Value > b.Item.Value
	end)
	local flushesPerMinute, ev = 60 / toilet.Cooldown * uptime, 0
	for _, entry in ipairs(entries) do
		ev += entry.Probability * entry.Item.Value
	end
	local active = flushesPerMinute * (ev + toilet.ServiceCoins)
	for _, slots in ipairs({ 3, 10 }) do
		local p = { ToiletTier = tier, DisplaySlots = slots, Displays = {} }
		local used, description = 0, {}
		for _, entry in ipairs(entries) do
			local count = math.min(slots - used, math.floor(entry.Probability * flushesPerMinute * 60))
			if count > 0 then
				table.insert(description, count .. "x " .. entry.Item.Id)
				for _ = 1, count do
					used += 1
					p.Displays[tostring(used)] = entry.Item.Id
				end
			end
		end
		local passive = 0
		for _, units in pairs(Income:Rates(p)) do
			passive += units * 60 / IncomeConfig.UnitsPerCoin
		end
		assert(passive / active <= 1 / 3, "Realistic display income exceeded one third")
		local nextToilet = Toilets[tier + 1]
		local timing = "final tier"
		if nextToilet then
			local before, after = nextToilet.Price / active, nextToilet.Price / (active + passive)
			assert(after >= before * 0.8, "Passive income accelerated upgrade timing by more than 20%")
			timing = string.format("%.2f / %.2f", before, after)
		end
		print(
			string.format(
				"%-12s %2d %17.2f %17.2f %6.2f%%  %-33s %s",
				toilet.Id,
				slots,
				passive,
				active,
				passive / active * 100,
				timing,
				table.concat(description, ", ")
			)
		)
	end
	-- Stronger proof: even 100 retained jackpot copies cannot beat this bound, independent of drop luck.
	local maximum = IncomeConfig.PlayerRateCaps[tier]
	local guaranteed = flushesPerMinute * toilet.ServiceCoins
	assert(maximum <= guaranteed / 3, "Absolute cap exceeds one third of service-only active income")
	assert(maximum <= guaranteed * 0.2 + 1e-9, "Absolute cap changes guaranteed timing by more than 1/6")
	print(
		string.format(
			"  Absolute cap: %.2f/min = %.2f%% of service-only active income; full offline tank <= %.0f coins.",
			maximum,
			maximum / guaranteed * 100,
			math.min(maximum * IncomeConfig.OfflineMinutes, IncomeConfig.PlayerPendingCap)
		)
	)
end
print(
	"Income balance passed: 3/10-slot ratios, all-inventory cap <=20% of guaranteed active income, passive caps re-verified with faster cooldowns."
)
print("Upgraded income bounds (all tiers, each Cash/Speed level 0..10):")
for tier, toilet in ipairs(Toilets) do
	for level = 0, 10 do
		local p = { Upgrades = { CashBoost = level, FlushSpeed = level, OfflineTank = 10 } }
		local cash = Upgrades:Cash(p)
		local passive = IncomeConfig.PlayerRateCaps[tier] * cash
		-- Independent cash/speed choices must preserve the bound too, not just equal levels.
		for speed = 0, 10 do
			p.Upgrades.FlushSpeed = speed
			local guaranteed = math.floor(toilet.ServiceCoins * cash + 1e-9)
				* 60
				/ Upgrades:Cooldown(p, toilet.Cooldown)
				* uptime
			assert(passive <= guaranteed * 0.2 + 1e-9, "Independent Cash/Speed levels break passive bound")
		end
		p.Upgrades.FlushSpeed = level
		local active = math.floor(toilet.ServiceCoins * cash + 1e-9)
			* 60
			/ Upgrades:Cooldown(p, toilet.Cooldown)
			* uptime
		assert(passive <= active * 0.2 + 1e-9, "Upgraded passive exceeds 20% guaranteed active income")
		if level == 4 or level == 10 then
			print(
				string.format(
					"  %-12s level %d: cap %.2f/min, %.2f%% service-only active; 480-minute tank <= %.0f Coins",
					toilet.Id,
					level,
					passive,
					passive / active * 100,
					math.min(passive * 480, IncomeConfig.PlayerPendingCap * Income:CapacityMultiplier(p))
				)
			)
		end
	end
end
