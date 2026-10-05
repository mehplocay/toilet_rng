local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Rebirth")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local R = require("../src/shared/RebirthRules")
local Roll = require("../src/server/Services/RollService")
local Service = require("../src/server/Services/ServiceCoinService")
local Inventory = require("../src/shared/SafeInventory")
local Cohort = require("./upgrade-cohort")
local Balance = {}
function Balance.Run(required, population)
	local config = table.clone(Config)
	config.RequiredFlushes = required
	local rules = R.new(config)
	local runs = { {}, {} }
	local seed = 20261005
	local function random()
		seed = seed * 16807 % 2147483647
		return seed / 2147483647
	end
	for _ = 1, population do
		local p = {
			Coins = 0,
			ToiletTier = 1,
			Stats = { Flushes = 0, Earned = 0 },
			Inventory = {},
			Collection = {},
			Displays = {},
			DisplaySlots = 3,
			Upgrades = U:Sanitize(nil),
			IndexClaims = {},
			Income = { UpdatedAt = 1, Pending = {} },
			RebirthLevel = 0,
			RunFlushes = 0,
		}
		for run = 1, 2 do
			local elapsed, entries, lastTier, lastLuck = 0, nil, nil, nil
			while not rules:Eligible(p, run - 1) do
				local pending = false
				for _, id in ipairs({ "FlushSpeed", "CashBoost", "LuckBoost" }) do
					local level = U:Level(p, id)
					if level < math.min(p.ToiletTier, 4) and not U:Buy(p, id, level) then
						pending = true
					end
				end
				local nextTier = Toilets[p.ToiletTier + 1]
				if not pending and nextTier and p.Coins >= nextTier.Price then
					p.Coins -= nextTier.Price
					p.ToiletTier += 1
				end
				local toilet = Toilets[p.ToiletTier]
				local luck = U:Luck(p, toilet.Luck)
				if p.ToiletTier ~= lastTier or luck ~= lastLuck then
					entries = Roll.Distribution(Items, Toilets, p.ToiletTier, luck)
					lastTier, lastLuck = p.ToiletTier, luck
				end
				local item = Roll.Sample(entries, random)
				assert(Service.Grant(p, toilet, U:Cash(p)))
				p.Inventory[item.Id] = (p.Inventory[item.Id] or 0) + 1
				p.Collection[item.Id] = (p.Collection[item.Id] or 0) + 1
				p.Stats.Flushes += 1
				p.RunFlushes += 1
				if Inventory.Sellable(p, item.Id) > 0 then
					assert(Inventory.Sell(p, Items, item.Id, 1, U:Cash(p)))
				end
				elapsed += U:Cooldown(p, toilet.Cooldown) / 60 / 0.75
				assert(elapsed < 300)
			end
			table.insert(runs[run], elapsed)
			p = assert(rules:Build(p, run - 1, 1))
		end
	end
	return Cohort.Percentile(runs[1], 0.5),
		Cohort.Percentile(runs[2], 0.5),
		Cohort.Percentile(runs[1], 0.9),
		Cohort.Percentile(runs[2], 0.9)
end
function Balance.Print()
	print(
		"Rebirth: seeded 500-player cohort; 75% manual uptime, duplicate sales, active tracks through L4; no daily/offline/pass income"
	)
	local first, second, p90first, p90second = Balance.Run(Config.RequiredFlushes, 500)
	print(
		string.format(
			"  %d flushes + tier %d: first p50 %.2f / p90 %.2f min; second p50 %.2f / p90 %.2f min; %.1f%% faster",
			Config.RequiredFlushes,
			Config.RequiredTier,
			first,
			p90first,
			second,
			p90second,
			(1 - second / first) * 100
		)
	)
	assert(second < first * 0.92 and second > 10, "Second run must improve without becoming instant")
	assert(first >= 60 and first <= 90, "First rebirth left the active-time target")
	return first, second
end
return Balance
