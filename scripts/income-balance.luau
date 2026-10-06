-- Comparable active/passive scenarios use real rare-first probabilities and per-copy cash rounding.
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Income")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Roll = require("../src/server/Services/RollService")
local Income = require("../src/shared/IncomeAccrual").new(Config, Items, U)
local B = {}
function B.Active(p, tier)
	local t, cash = Toilets[tier], U:Cash(p)
	local entries = Roll.Distribution(Items, Toilets, tier, U:Luck(p, t.Luck))
	local value = math.floor(t.ServiceCoins * cash + 1e-9)
	for _, entry in ipairs(entries) do
		value += entry.Probability * math.floor(entry.Item.Value * cash + 1e-9)
	end
	return value * 60 / U:Cooldown(p, t.Cooldown) * 0.75, entries
end
function B.Showcase(p, tier, slots)
	local active, entries = B.Active(p, tier)
	table.sort(entries, function(a, b)
		return a.Item.Value > b.Item.Value
	end)
	p.ToiletTier, p.DisplaySlots, p.Displays = tier, slots, {}
	local used, description = 0, {}
	for _, entry in ipairs(entries) do
		local count =
			math.min(slots - used, math.floor(entry.Probability * 3600 / U:Cooldown(p, Toilets[tier].Cooldown) * 0.75))
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
		passive += units * 60 / Config.UnitsPerCoin
	end
	return passive, active, table.concat(description, ", ")
end
function B.Print()
	local common = { ToiletTier = 1, DisplaySlots = 10, Displays = {} }
	for slot = 1, 10 do
		common.Displays[tostring(slot)] = "Poop"
	end
	local commonRate = 0
	for _, units in pairs(Income:Rates(common)) do
		commonRate += units * 60 / Config.UnitsPerCoin
	end
	local commonRatio = commonRate / B.Active(common, 1)
	assert(commonRatio >= 0.20 and commonRatio <= 0.35, "Even an all-Common Basic plot should feel useful")
	print(
		string.format("Basic, ten Common Poop: $%.2f/s = %.2f%% of active income.", commonRate / 60, commonRatio * 100)
	)
	print("Display income: coins/second UI; ten reasonable retained copies from 60 active minutes; 75% manual uptime.")
	print(
		"No-track and normal stage tracks (Cash/Luck/Speed through L4); acquisition/slot costs excluded from steady-state rates."
	)
	for tier, t in ipairs(Toilets) do
		for _, tracks in ipairs({ false, true }) do
			local level = if tracks then math.min(tier, 4) else 0
			local p = { Upgrades = { CashBoost = level, LuckBoost = level, FlushSpeed = level } }
			local passive, active, description = B.Showcase(p, tier, 10)
			local ratio = passive / active
			assert(ratio >= 0.20 and ratio <= 0.35, "Ten-slot target missed: " .. t.Id .. " " .. ratio)
			print(
				string.format(
					"  %-12s L%d: $%.2f/s / active $%.2f/s = %.2f%%; %s",
					t.Id,
					level,
					passive / 60,
					active / 60,
					ratio * 100,
					description
				)
			)
			local three = B.Showcase(p, tier, 3)
			assert(three <= passive and three / active <= 0.40)
		end
	end
	local highest = 0
	-- Least luck is the conservative active comparator; extra luck only increases expected sale value.
	for rebirth = 0, 15 do
		for tier in ipairs(Toilets) do
			for cash = 0, 10 do
				for speed = 0, 10 do
					local p = { RebirthLevel = rebirth, Upgrades = { CashBoost = cash, FlushSpeed = speed } }
					local active = B.Active(p, tier)
					local cap = Config.PlayerRateCaps[tier] * U:Cash(p)
					highest = math.max(highest, cap / active)
					assert(cap <= active * 0.40, "Absolute passive cap exceeds 40% of same-stage active flush income")
				end
			end
		end
	end
	print(
		string.format(
			"Absolute 100-jackpot-slot ceiling: %.2f%% maximum across 0..15 rebirths and independent Cash/Speed 0..10.",
			highest * 100
		)
	)
	print(
		"Base tank: 240 minutes; upgraded tank: 480. Storage/rates scale with cash; persisted 6000 units/coin unchanged."
	)
end
return B
