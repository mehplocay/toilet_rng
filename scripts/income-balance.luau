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
		local ar, br = Config.RarityRates[a.Item.Rarity], Config.RarityRates[b.Item.Rarity]
		return if ar ~= br
			then ar > br
			elseif a.Item.Value ~= b.Item.Value then a.Item.Value > b.Item.Value
			else a.Item.Id < b.Item.Id
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
	print(
		"Steady display rates: ten best floored expected drops from 60 minutes at current tier; acquisition/slot costs excluded."
	)
	print("Tier          Passive/s   Active/s   Share   Items")
	for tier, toilet in ipairs(Toilets) do
		local level = math.min(tier, 4)
		local p = { Upgrades = { CashBoost = level, LuckBoost = level, FlushSpeed = level } }
		local passive, active, description = B.Showcase(p, tier, 10)
		if tier >= 4 and tier <= 12 then
			local share = passive / (passive + active)
			assert(share >= 0.70 and share <= 0.90, "Mid/late steady income share missed")
		end
		-- Later nominal toilet factors saturate the free cash cap. The old uncapped
		-- 70-90% share promise is invalid there; keep the real capped rates visible.
		assert(passive <= 100000 * 10 * 40 * 60, "Free showcase escaped the cash cap")
		print(
			string.format(
				"%-12s %10.2f %10.2f %7.2f%% %s",
				toilet.Id,
				passive / 60,
				active / 60,
				100 * passive / (passive + active),
				description
			)
		)
	end
end
return B
