local C = require("./economy-cohort")
local Long = require("./permanent-cohort")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Upgrades")
local Rebirth = require("../src/shared/Config/Rebirth")
local U = require("../src/shared/UpgradeRules").new(Config)
local function percentile(values, fraction)
	return C.Percentile(table.clone(values), fraction)
end
local failures = {}
-- Measured uncapped fresh-account baselines (docs/design/no-cash-cap.md).
-- These are regression snapshots, not changes to the requested early/rebirth targets.
-- Unlike the conditional Wave 1
-- targets these players also pay for permanent upgrades throughout the run.
local extendedTargets = {
	Normal = { 84, 109.5, 146.5, 214, 315.5, 455, 711, 1027.5 },
	Casual = { 138, 178, 220, 324, 488, 702, 1036, 1486 },
	Grinder = { 72, 95.5, 128, 184.5, 270, 402.5, 626.5, 909 },
}
local function within(value, low, high, message)
	if not (value >= low and value <= high) then
		table.insert(failures, message .. ": " .. tostring(value) .. " (expected " .. low .. "-" .. high .. ")")
	end
end
print("PERMANENT ECONOMY: paid OFF, daily/server boosts OFF; fresh accounts, production roll/accrual/sale/reset math.")
print(
	"Short cohort: 200 seeds, per-flush settlement. Long cohort: 64 seeds, 2s batches in hour one, 30s later; 300h censoring."
)
print("Casual/normal/grinder flush uptime 30/75/100%; collect every 120/30/15s; online displays earn continuously.")
print(
	"Buy Dirty, five slots, then affordable slots and one Cash/Luck/Speed per tier through L4; purchase every next toilet."
)
print(
	"After Galaxy, buy the cheapest track at <=25% of wallet and affordable next toilets; check rebirth first. All purchases debit coins."
)
print("Galaxy timing defers rebirth. Long cohort rebirths at every coin gate: its Galaxy timing may be later.")
print(
	"Milestone titles every 10; max Master. Display Slots cap 10 levels, stops at ten physical slots (normally seven purchases)."
)
for _, track in ipairs(Config.Tracks) do
	print(
		"Price",
		track.Id,
		"levels",
		track.MaxLevel,
		"first",
		U:Price(track.Id, 0),
		"last",
		U:Price(track.Id, track.MaxLevel - 1)
	)
end
-- Conservative early affordability proof: service only, zero sales/displays/rewards.
local starter = { Coins = 0, Stats = { Earned = 0 }, Upgrades = U:Sanitize(nil), DisplaySlots = 3 }
local seconds = 0
for level = 0, 4 do
	local price = U:Price("CashBoost", level)
	local before = seconds
	while starter.Coins < price do
		assert(require("../src/server/Services/ServiceCoinService").Grant(starter, Toilets[1], U:Cash(starter)))
		seconds += Toilets[1].Cooldown / 0.75
	end
	assert(U:Buy(starter, "CashBoost", level))
	print(
		string.format(
			"Service-only early Cash L%d: %.2f cumulative minutes, %.2f minutes this level",
			level + 1,
			seconds / 60,
			(seconds - before) / 60
		)
	)
end
assert(seconds <= 240, "First five levels must be affordable in four active minutes even without sales/display")
for _, arch in ipairs({ { "Normal", 0.75 }, { "Casual", 0.3 }, { "Grinder", 1 } }) do
	local short = C.Run(200, arch[2], false, nil, nil, 7)
	local long = Long.Run(64, arch[2], 300)
	local extended = Long.Run(64, arch[2], 300, true)
	print(arch[1] .. " | tier | p50 / p90 minutes (rebirth deferred)")
	local target = { 0, 1.5, 3, 6, 12, 20, 35 }
	for tier = 2, 7 do
		local median, tail = percentile(short.Tiers[tier], 0.5), percentile(short.Tiers[tier], 0.9)
		print(string.format("%s | %s | %.2f / %.2f", arch[1], Toilets[tier].Id, median, tail))
		if arch[1] == "Normal" then
			within(median, target[tier] * 0.8, target[tier] * 1.2, "Tier " .. Toilets[tier].Id)
		end
	end
	print(arch[1] .. " | Wave 1 tier | fresh-account p50 / p90 minutes (rebirth deferred; upgrades continue)")
	for tier = 8, #Toilets do
		local median, tail = percentile(extended.Tiers[tier], 0.5) * 60, percentile(extended.Tiers[tier], 0.9) * 60
		print(string.format("%s | %s | %.2f / %.2f", arch[1], Toilets[tier].Id, median, tail))
		assert(median < math.huge and tail >= median, "Unreachable extended toilet")
		local expected = extendedTargets[arch[1]][tier - 7]
		within(median, expected * 0.8, expected * 1.2, arch[1] .. " extended " .. Toilets[tier].Id)
	end
	print(arch[1] .. " | rebirth | required coins | cumulative p50 / p90 hours")
	for level = 1, 15 do
		print(
			string.format(
				"%s | R%d | %.0f | %.2f / %.2f",
				arch[1],
				level,
				Rebirth.Levels[level].RequiredCoins,
				percentile(long.Rebirths[level], 0.5),
				percentile(long.Rebirths[level], 0.9)
			)
		)
	end
	if arch[1] == "Normal" then
		within(percentile(short.Tiers[7], 0.5), 35, 38, "Galaxy minutes")
		within(percentile(long.Rebirths[1], 0.5) * 60, 23, 25, "First rebirth minutes")
		within(percentile(long.Rebirths[5], 0.5), 2, 2.2, "Rebirth 5 hours")
		within(percentile(long.Rebirths[10], 0.5), 25, 40, "Rebirth 10 hours")
		within(percentile(long.Rebirths[15], 0.5), 90, 100, "Rebirth 15 hours")
	end
	print(arch[1] .. " | track | level | cumulative p50 / p90 hours")
	for _, track in ipairs(Config.Tracks) do
		local levels = if track.MaxLevel == 100
			then { 1, 10, 35, 60, 85, 100 }
			elseif track.MaxLevel == 50 then { 1, 10, 18, 30, 43, 50 }
			elseif track.Id == "DisplaySlots" then { 1, 4, 6, 7 }
			else { 1, 4, 7, 10 }
		for _, level in ipairs(levels) do
			local median, tail =
				percentile(long.Levels[track.Id][level], 0.5), percentile(long.Levels[track.Id][level], 0.9)
			print(string.format("%s | %s | %d | %.2f / %.2f", arch[1], track.Id, level, median, tail))
			if arch[1] == "Normal" then
				if track.MaxLevel == 100 then
					if level == 35 then
						within(median, 1.8, 3, "L35 " .. track.Id)
					elseif level == 60 then
						within(median, 5, 12, "L60 " .. track.Id)
					elseif level == 85 then
						-- Preserve the existing upgrade timing acceptance after the cash retune.
						within(median, 12, 28, "L85 " .. track.Id)
					elseif level == 100 then
						within(median, 25, 45, "L100 " .. track.Id)
					end
				elseif track.MaxLevel == 50 and level == 50 then
					within(median, 8, 22, "Luck max")
				elseif (track.Id == "FlushSpeed" or track.Id == "AutoFlushSpeed") and level == 10 then
					within(median, 2, 5, "Speed max")
				elseif track.Id == "DisplaySlots" and level == 7 then
					within(median, 1.8, 5, "Full plot")
				end
			end
		end
	end
	local early, mid = percentile(short.EarlyShare, 0.5), percentile(short.MidShare, 0.5)
	print(
		string.format(
			"%s passive income shares: first 10min %.2f%%; 10min after Diamond %.2f%%",
			arch[1],
			early * 100,
			mid * 100
		)
	)
	assert(mid > 0.5, "Displays must lead midgame income")
end
local a, b = C.Run(3, 0.75, true), C.Run(3, 0.75, true)
for run = 1, 2 do
	for i = 1, 3 do
		assert(a.Runs[run][i] == b.Runs[run][i], "Seed replay drift")
	end
end
local a, b = Long.Run(2, 0.75, 4), Long.Run(2, 0.75, 4)
for level = 1, 15 do
	for i = 1, 2 do
		assert(a.Rebirths[level][i] == b.Rebirths[level][i], "Long seed replay drift")
	end
end
require("./income-balance").Print()
assert(#failures == 0, table.concat(failures, "\n"))
print(
	"Balance targets and replay passed. Timings are policy-dependent estimates, not guaranteed player outcomes; inf = censored after 300h."
)
