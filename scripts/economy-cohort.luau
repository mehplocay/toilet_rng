-- Seeded end-to-end economy policy. All grants, rolls, sales, accrual and resets use production math.
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local R = require("../src/shared/RebirthRules").new(require("../src/shared/Config/Rebirth"))
local Income = require("../src/shared/IncomeAccrual").new(require("../src/shared/Config/Income"), Items, U)
local Roll = require("../src/server/Services/RollService")
local Service = require("../src/server/Services/ServiceCoinService")
local Display = require("./display-cohort")
local C = {}
local Paid = require("../src/shared/PaidBenefits")
local Monetization = require("../src/shared/Config/Monetization")
local function cooldown(p, toilet)
	return U:Cooldown(
		p,
		toilet.Cooldown
			* (if Paid.Owns(p, "FastFlush") then Monetization.Gamepasses.FastFlush.CooldownMultiplier else 1)
	)
end
function C.Percentile(values, fraction)
	table.sort(values)
	return values[math.ceil(#values * fraction)]
end
function C.Run(population, uptime, rebirthRuns, slotLimit, stopAt, maxTier, passes)
	local result = { Tiers = {}, Runs = { {}, {} }, EarlyShare = {}, MidShare = {} }
	for tier = 2, #Toilets do
		result.Tiers[tier] = {}
	end
	for player = 1, population do
		local seed = 20261006 + player * 7919
		local function random()
			seed = seed * 16807 % 2147483647
			return seed / 2147483647
		end
		local p = {
			Coins = 0,
			Monetization = { Passes = passes or {} },
			Stats = { Earned = 0, Flushes = 0 },
			Inventory = {},
			Collection = {},
			Displays = {},
			DisplaySlots = 3,
			Upgrades = U:Sanitize(nil),
			UpgradeVersion = U.Config.Version,
			ToiletTier = 1,
			Income = { UpdatedAt = 1000, Pending = {} },
			IndexClaims = {},
			RebirthLevel = 0,
			RunFlushes = 0,
		}
		local interval = if Paid.Owns(p, "AutoCollect")
			then 5
			elseif uptime <= 0.3 then 120
			elseif uptime >= 1 then 15
			else 30
		local seconds, runStart, nextCollect, passive, earlyTaken = 0, 0, interval, 0, false
		local midPassive, midEarned, midStart
		local entries, oldTier, oldLuck
		while true do
			Income:Settle(p, 1000 + math.floor(seconds), false)
			if seconds >= nextCollect then
				passive += Income:Collect(p)
				nextCollect = seconds + interval
			end
			if seconds >= 600 and not earlyTaken then
				local pending = Income:PendingCoins(p)
				table.insert(result.EarlyShare, (passive + pending) / (p.Stats.Earned + pending))
				earlyTaken = true
			end
			if midStart and seconds >= midStart + 600 then
				local pending = Income:PendingCoins(p)
				table.insert(result.MidShare, (passive + pending - midPassive) / (p.Stats.Earned + pending - midEarned))
				midStart = nil
			end
			if rebirthRuns and R:Eligible(p, p.RebirthLevel) then
				table.insert(result.Runs[p.RebirthLevel + 1], (seconds - runStart) / 60)
				if p.RebirthLevel == 1 then
					break
				end
				p = assert(R:Build(p, 0, 1000 + math.floor(seconds)))
				runStart = seconds
			end
			if stopAt and seconds >= stopAt then
				break
			end
			local pendingPurchase = false
			local slots = math.min(slotLimit or 10, if p.ToiletTier >= 4 then 10 elseif p.ToiletTier == 1 then 3 else 5)
			if p.DisplaySlots < slots then
				U:Buy(p, "DisplaySlots", U:Level(p, "DisplaySlots"))
				pendingPurchase = p.ToiletTier < 4 and p.DisplaySlots < slots
			end
			for _, id in ipairs({ "FlushSpeed", "CashBoost", "LuckBoost" }) do
				local level = U:Level(p, id)
				if level < math.min(p.ToiletTier - 1, 4) then
					U:Buy(p, id, level)
				end
			end
			local nextTier = Toilets[p.ToiletTier + 1]
			if not pendingPurchase and nextTier and p.Coins >= nextTier.Price then
				p.Coins -= nextTier.Price
				p.ToiletTier += 1
				if p.RebirthLevel == 0 then
					table.insert(result.Tiers[p.ToiletTier], seconds / 60)
					if p.ToiletTier == 4 then
						midStart, midPassive, midEarned =
							seconds, passive + Income:PendingCoins(p), p.Stats.Earned + Income:PendingCoins(p)
					end
				end
			end
			if not rebirthRuns and p.ToiletTier == (maxTier or #Toilets) and earlyTaken and not midStart then
				break
			end
			local toilet = Toilets[p.ToiletTier]
			local luck = U:Luck(p, toilet.Luck)
			if oldTier ~= p.ToiletTier or oldLuck ~= luck then
				entries = Roll.Distribution(Items, Toilets, p.ToiletTier, luck)
				oldTier, oldLuck = p.ToiletTier, luck
			end
			local item = Roll.Sample(entries, random)
			assert(Service.Grant(p, toilet, U:Cash(p)))
			p.Inventory[item.Id] = (p.Inventory[item.Id] or 0) + 1
			p.Collection[item.Id] = (p.Collection[item.Id] or 0) + 1
			p.Stats.Flushes += 1
			p.RunFlushes += 1
			Display.ReserveAndSell(p)
			seconds += cooldown(p, toilet) / uptime
			assert(seconds < 86400, "Cohort stalled")
		end
	end
	return result
end
return C
