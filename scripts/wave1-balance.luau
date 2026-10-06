-- Pure Luau, no Roblox engine or filesystem APIs.
-- wave1-balance.ps1 serializes canonical JSON to a temporary required module, then runs this file.
local D = require("./wave1-input")
assert(type(D) == "table", tostring(D))
local byId, rarityById = {}, {}
local counts, newCounts, totalNew = {}, {}, 0
local function near(a, b)
	assert(math.abs(a - b) < 1e-10, string.format("Mismatch %.12g vs %.12g", a, b))
end
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
for order, rarity in ipairs(D.Rarities) do
	assert(rarity.Order == order)
	rarityById[rarity.Id] = rarity
	counts[rarity.Id], newCounts[rarity.Id] = 0, 0
	if order > 1 then
		assert(D.Rarities[order - 1].MaxChance < rarity.MinChance, "Rarity bands overlap")
		assert(D.Rarities[order - 1].IncomePerSecond < rarity.IncomePerSecond)
	end
end
for _, item in ipairs(D.Items) do
	assert(not byId[item.Id] and item.Id:match("^[A-Z][A-Za-z]+$"), "Duplicate/invalid item ID")
	byId[item.Id] = item
	local rarity = assert(rarityById[item.Rarity])
	assert(item.Chance >= rarity.MinChance and item.Chance <= (rarity.MaxChance or math.huge))
	assert(item.IncomePerSecond == rarity.IncomePerSecond, "Income ladder mismatch")
	assert(finite(item.Value) and item.Value > 0 and item.Value % 1 == 0)
	assert(item.FirstToiletTier >= 1 and item.FirstToiletTier <= #D.Toilets)
	counts[item.Rarity] += 1
	if item.New then
		totalNew += 1
		newCounts[item.Rarity] += 1
		assert(item.Model.TriangleBudget <= 2500)
		local size = math.max(table.unpack(item.Model.SizeStuds))
		assert(size >= 2 and size <= 3)
		assert(item.Model.File == "assets/models/items/" .. item.Id .. ".fbx")
		assert(item.Icon.Key == "Assets.ItemIcons." .. item.Id)
	end
end
assert(#D.Rarities == 9 and #D.Items == 47 and totalNew == 36 and #D.Toilets == 15)
local pooled, toiletIds = {}, {}
for tier, toilet in ipairs(D.Toilets) do
	assert(toilet.Tier == tier and not toiletIds[toilet.Id])
	toiletIds[toilet.Id] = true
	assert(toilet.Cooldown >= D.Rules.CooldownFloor and toilet.Luck <= D.Rules.LuckCap)
	near(toilet.CooldownMultiplier * D.Rules.BaseCooldown, toilet.Cooldown)
	assert(toilet.Price >= 0 and toilet.Price % 1 == 0 and toilet.Price <= D.Rules.MaxBalance)
	near(toilet.SlotRateCapPerMinute, 60 * 100000 * toilet.IncomeMultiplier)
	near(toilet.PlayerRateCapPerMinute, toilet.SlotRateCapPerMinute * 10)
	if tier > 1 then
		local previous = D.Toilets[tier - 1]
		assert(toilet.Price > previous.Price and toilet.IncomeMultiplier > previous.IncomeMultiplier)
		assert(toilet.Cooldown <= previous.Cooldown and toilet.Luck >= previous.Luck)
	end
	if toilet.New then
		assert(toilet.Model.TriangleBudget <= 5000)
		near(toilet.Model.SeatCenterHeight, 2.08)
		near(toilet.Model.CoreLidTop, 4.79)
		assert(toilet.Icon.Key == "Assets.ToiletIcons." .. toilet.Id)
		if tier > 8 then
			near(toilet.Price / D.Toilets[tier - 1].Price, 2.5)
		end
	end
	for _, id in ipairs(toilet.Pool) do
		assert(byId[id] and not pooled[id], "Unknown or repeated pool addition")
		assert(byId[id].FirstToiletTier == tier, "Unlock mismatch")
		pooled[id] = true
	end
end
for _, item in ipairs(D.Items) do
	assert(pooled[item.Id], "Item missing from pools")
end
for level, tier in ipairs(D.Rebirth.MinimumToiletTierByNextLevel) do
	assert(tier >= 1 and tier <= 15)
	if level > 1 then
		assert(tier >= D.Rebirth.MinimumToiletTierByNextLevel[level - 1])
	end
end
assert(#D.Rebirth.MinimumToiletTierByNextLevel == 15)
local function distribution(tier, luck)
	local sorted = {}
	for _, item in ipairs(D.Items) do
		if item.FirstToiletTier <= tier and item.Id ~= D.Rules.FallbackId then
			table.insert(sorted, item)
		end
	end
	table.sort(sorted, function(a, b)
		return if a.Chance == b.Chance then a.Id < b.Id else a.Chance > b.Chance
	end)
	table.insert(sorted, byId[D.Rules.FallbackId])
	local entries, probabilities, remaining, sum = {}, {}, 1, 0
	for _, item in ipairs(sorted) do
		local q = if item.Id == D.Rules.FallbackId then 1 else math.min(1, luck / item.Chance)
		local p = remaining * q
		remaining *= 1 - q
		sum += p
		assert(p >= 0 and p <= 1 and finite(p))
		table.insert(entries, { Item = item, Probability = p, Cumulative = sum })
		probabilities[item.Id] = p
	end
	near(sum, 1)
	near(remaining, 0)
	return entries, probabilities, sum
end
-- Closed-form independent cross-check of the fallback product, not a normalized weight sum.
for tier = 1, #D.Toilets do
	for _, luck in ipairs(D.Balance.LuckScenarios) do
		local _, probabilities = distribution(tier, luck)
		local product = 1
		for _, item in ipairs(D.Items) do
			if item.FirstToiletTier <= tier and item.Id ~= "Poop" then
				product *= 1 - math.min(1, luck / item.Chance)
			end
		end
		near(probabilities.Poop, product)
	end
end
print("WAVE 1 | JSON-derived data | 47 items / 36 new / 9 rarities / 15 toilets / 8 new")
print("1x and 5x are total effective luck overrides; 10x is uncapped stress-only, production cap remains 5x.")
print(
	"Base odds ordering is strict between rarity bands. Effective outcomes may invert under sequential checks/saturation."
)
print("RARITY | order | total/new | base income/s")
for _, rarity in ipairs(D.Rarities) do
	assert(newCounts[rarity.Id] == 4)
	print(
		string.format(
			"%s | %d | %d/%d | %d",
			rarity.Id,
			rarity.Order,
			counts[rarity.Id],
			newCounts[rarity.Id],
			rarity.IncomePerSecond
		)
	)
end
print("POOL PROBABILITIES: unconditional fractions, columns 1x / 5x / 10x stress; Poop is remainder.")
for tier, toilet in ipairs(D.Toilets) do
	local maps, sums = {}, {}
	for _, luck in ipairs(D.Balance.LuckScenarios) do
		local _, probabilities, sum = distribution(tier, luck)
		table.insert(maps, probabilities)
		table.insert(sums, sum)
	end
	print(string.format("T%02d %s | sum %.12f / %.12f / %.12f", tier, toilet.Id, table.unpack(sums)))
	for _, item in ipairs(D.Items) do
		if maps[1][item.Id] then
			print(
				string.format(
					"  %-22s %.9g | %.9g | %.9g",
					item.Id,
					maps[1][item.Id],
					maps[2][item.Id],
					maps[3][item.Id]
				)
			)
		end
	end
end
print("FIRST SIGHT AT FIRST UNLOCK: expected flushes / online minutes, 75% uptime, speed level 0, no unlock time.")
print("For any later pool use p above: E[N]=1/p; E[minutes]=cooldown/(60*0.75*p). Zero p => infinite.")
print("Item | first tier | 1x N/min | 5x N/min | 10x stress N/min")
for _, item in ipairs(D.Items) do
	local row = {}
	for _, luck in ipairs(D.Balance.LuckScenarios) do
		local _, probabilities = distribution(item.FirstToiletTier, luck)
		local p = probabilities[item.Id]
		local n = if p > 0 then 1 / p else math.huge
		local minutes = n * D.Toilets[item.FirstToiletTier].Cooldown / (60 * D.Balance.Uptime)
		table.insert(row, if p > 0 then string.format("%.2f / %.2f", n, minutes) else "inf / inf")
	end
	print(string.format("%s | %d | %s", item.Id, item.FirstToiletTier, table.concat(row, " | ")))
end
local function interval(tier, speed)
	return math.max(D.Rules.CooldownFloor, D.Toilets[tier].Cooldown * speed) / D.Balance.Uptime
end
local incomeSorted = table.clone(D.Items)
table.sort(incomeSorted, function(a, b)
	return if a.IncomePerSecond == b.IncomePerSecond then a.Id < b.Id else a.IncomePerSecond > b.IncomePerSecond
end)
local function display(inventory, slots)
	local used, baseRate, placed, names, lowestRate = 0, 0, {}, {}, 0
	for _, item in ipairs(incomeSorted) do
		local count = math.min(slots - used, inventory[item.Id] or 0)
		if count > 0 then
			used += count
			baseRate += count * item.IncomePerSecond
			lowestRate = item.IncomePerSecond
			placed[item.Id] = count
			table.insert(names, count .. "x" .. item.Id)
		end
	end
	return baseRate, placed, table.concat(names, ","), if used == slots then lowestRate else 0
end
-- E[min(slots, Binomial(n,q))] gives exact expected occupancy above a rarity threshold.
local function expectedSlots(n, q, slots)
	if q >= 1 then
		return math.min(n, slots)
	end
	if q <= 0 then
		return 0
	end
	local mass = (1 - q) ^ n
	local missing = slots * mass
	for k = 1, slots - 1 do
		mass *= (n - k + 1) / k * q / (1 - q)
		missing += (slots - k) * mass
	end
	return slots - missing
end
print("TYPICAL SHOWCASE: 60 min at fixed tier; floor(expected copies), best income first, 10 slots.")
print("This is economy-v2's steady showcase estimator, NOT a stochastic mean or a fresh-account acquisition cohort.")
print("Cash 1.4, luck min(5,toilet*1.4), speed factor 0.8; active includes every drop sale (optimistic comparator).")
print("Tier | typical display/s | exact mean best-10/s | active/s | typical passive share | typical composition")
for tier, toilet in ipairs(D.Toilets) do
	local entries = distribution(tier, math.min(D.Rules.LuckCap, toilet.Luck * D.Balance.ShowcaseLuckFactor))
	local dt, inventory = interval(tier, D.Balance.ShowcaseSpeedFactor), {}
	local value = math.floor(toilet.ServiceCoins * D.Balance.ShowcaseCash)
	for _, entry in ipairs(entries) do
		inventory[entry.Item.Id] = math.floor(entry.Probability * 60 * D.Balance.ShowcaseMinutes / dt)
		value += entry.Probability * math.floor(entry.Item.Value * D.Balance.ShowcaseCash)
	end
	local base, _, description = display(inventory, D.Balance.ShowcaseSlots)
	local passive = base * toilet.IncomeMultiplier * D.Balance.ShowcaseCash
	local active = value / dt
	if tier >= 4 then
		local share = passive / (passive + active)
		assert(share >= 0.7 and share <= 0.9, "Typical mid/late passive share must remain 70-90%")
	end
	local meanBase, previousRate = 0, 0
	for _, rarity in ipairs(D.Rarities) do
		local q = 0
		for _, entry in ipairs(entries) do
			if rarityById[entry.Item.Rarity].Order >= rarity.Order then
				q += entry.Probability
			end
		end
		meanBase += (rarity.IncomePerSecond - previousRate) * expectedSlots(
			math.floor(60 * D.Balance.ShowcaseMinutes / dt),
			math.min(1, q),
			D.Balance.ShowcaseSlots
		)
		previousRate = rarity.IncomePerSecond
	end
	local mean = meanBase * toilet.IncomeMultiplier * D.Balance.ShowcaseCash
	print(
		string.format(
			"%02d %-17s | %.2f | %.2f | %.2f | %.2f%% | %s",
			tier,
			toilet.Id,
			passive,
			mean,
			active,
			100 * passive / (passive + active),
			description
		)
	)
end
local C = D.Balance.ConditionalCohort
local cohorts = {}
for tier = C.StartTier + 1, #D.Toilets do
	cohorts[tier] = {}
end
local function simulate(player)
	local seed = C.Seed + player * 7919
	local function random()
		seed = seed * 16807 % 2147483647
		return seed / 2147483647
	end
	local inventory = {}
	for _, entry in ipairs(C.StartItems) do
		inventory[entry.Id] = entry.Count
	end
	local tier, seconds, coins, pending = C.StartTier, C.StartMinute * 60, C.StartCoins, 0
	local nextCollect = seconds + C.CollectSeconds
	local base, placed, _, lowest = display(inventory, C.Slots)
	local entries = distribution(tier, math.min(D.Rules.LuckCap, D.Toilets[tier].Luck * C.LuckFactor))
	local reached = {}
	while tier < #D.Toilets do
		local dt = interval(tier, C.SpeedFactor)
		seconds += dt
		assert(seconds < C.MaxMinutes * 60, "Conditional cohort stalled")
		pending += base * D.Toilets[tier].IncomeMultiplier * C.Cash * dt
		if seconds >= nextCollect then
			local whole = math.floor(pending)
			coins += whole
			pending -= whole
			nextCollect = seconds + C.CollectSeconds
		end
		local sample, item = random(), entries[#entries].Item
		for _, entry in ipairs(entries) do
			if sample < entry.Cumulative then
				item = entry.Item
				break
			end
		end
		coins += math.floor(D.Toilets[tier].ServiceCoins * C.Cash)
		inventory[item.Id] = (inventory[item.Id] or 0) + 1
		if item.IncomePerSecond > lowest then
			base, placed, _, lowest = display(inventory, C.Slots)
			for _, ownedItem in ipairs(D.Items) do
				local owned = inventory[ownedItem.Id] or 0
				local retain = math.max(if owned > 0 then 1 else 0, placed[ownedItem.Id] or 0)
				if owned > retain then
					coins += (owned - retain) * math.floor(ownedItem.Value * C.Cash)
					inventory[ownedItem.Id] = retain
				end
			end
		else
			local retain = math.max(1, placed[item.Id] or 0)
			if inventory[item.Id] > retain then
				coins += (inventory[item.Id] - retain) * math.floor(item.Value * C.Cash)
				inventory[item.Id] = retain
			end
		end
		if coins >= D.Toilets[tier + 1].Price then
			coins -= D.Toilets[tier + 1].Price
			tier += 1
			reached[tier] = seconds / 60
			entries = distribution(tier, math.min(D.Rules.LuckCap, D.Toilets[tier].Luck * C.LuckFactor))
		end
	end
	return reached
end
for player = 1, C.Population do
	local reached = simulate(player)
	for tier, minutes in pairs(reached) do
		table.insert(cohorts[tier], minutes)
	end
end
local replayA, replayB = simulate(1), simulate(1)
for tier = 8, 15 do
	near(replayA[tier], replayB[tier])
end
print("CONDITIONAL POST-GALAXY COHORT: 200 seeds; synthetic Galaxy at minute 35; 8 Ducks + 2 GoldenPoops, 10 slots.")
print("Zero wallet, cash/luck 1.4, speed .8, 75% uptime, collect 30s; retain first/displayed copies, sell surplus.")
print(
	"No offline/daily/events/passes/rebirth/further upgrades. Pending accrual continuous; no travel or latency model."
)
print("These are conditional estimates, not a proof of the owner's 35-minute Galaxy target.")
print("Tier | price | p50 cumulative min | p90 cumulative min")
for tier = 8, 15 do
	table.sort(cohorts[tier])
	local p50, p90 = cohorts[tier][math.ceil(C.Population * 0.5)], cohorts[tier][math.ceil(C.Population * 0.9)]
	assert(p50 > C.StartMinute)
	local target = D.Toilets[tier].TargetCumulativeMinutes
	assert(p50 >= target * 0.8 and p50 <= target * 1.2, "Conditional pacing target missed")
	print(string.format("%02d %-17s | %.0f | %.2f | %.2f", tier, D.Toilets[tier].Id, D.Toilets[tier].Price, p50, p90))
end
local top = D.Toilets[15]
print(
	string.format(
		"MAX RATE: T15 ten Secrets = %.0f coins/s at cash 1, %.0f at hard cash 10.",
		100000 * top.IncomeMultiplier * 10,
		100000 * top.IncomeMultiplier * 100
	)
)
print(
	string.format(
		"Global 9e15-subcoin storage lasts %.2f / %.2f online minutes for those plots (cash 1 / 10).",
		D.Rules.MaxLedgerUnits / D.Rules.UnitsPerCoin / (100000 * top.IncomeMultiplier * 10) / 60,
		D.Rules.MaxLedgerUnits / D.Rules.UnitsPerCoin / (100000 * top.IncomeMultiplier * 100) / 60
	)
)
print(
	"PASS: counts, IDs, 9 ordered bands, exact income ladder, unique cumulative pools, 45 unit-mass distributions, independent fallback products, model budgets, price growth, floor/cap bounds, rebirth gates, seeded replay."
)
