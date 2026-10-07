-- Long-horizon seeded cohort: no free items, levels, slots, coins or rebirths.
-- Batch rolls use the exact equivalent distribution; income settles before each batch.
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Upgrades")
local U = require("../src/shared/UpgradeRules").new(Config)
local R = require("../src/shared/RebirthRules").new(require("../src/shared/Config/Rebirth"))
local I = require("../src/shared/IncomeAccrual").new(require("../src/shared/Config/Income"), Items, U)
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
function C.Run(population, uptime, horizon, deferRebirth, passes)
	local result = { Levels = {}, Rebirths = {}, Tiers = {}, FirstTen = {} }
	for _, track in ipairs(Config.Tracks) do
		result.Levels[track.Id] = {}
		for level = 1, track.MaxLevel do
			result.Levels[track.Id][level] = {}
		end
	end
	for level = 1, 15 do
		result.Rebirths[level] = {}
	end
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
		local seconds, nextCollect, fractional = 0, 0, 0
		local collectInterval = if uptime <= 0.3 then 120 elseif uptime >= 1 then 15 else 30
		local entries, oldTier, oldLuck
		local function buy(id)
			local level = U:Level(p, id)
			if U:Buy(p, id, level) then
				result.Levels[id][level + 1][player] = seconds / 3600
				return true
			end
			return false
		end
		while seconds <= horizon * 3600 do
			I:Settle(p, 1000 + seconds, false)
			if seconds >= nextCollect then
				I:Collect(p)
				nextCollect = seconds
					+ (
						if R:Bonus(p).AutoCollect or Paid.Owns(p, "AutoCollect")
							then math.min(5, collectInterval)
							else collectInterval
					)
			end
			if not deferRebirth and R:Eligible(p, p.RebirthLevel) then
				result.Rebirths[p.RebirthLevel + 1][player] = seconds / 3600
				p = assert(R:Build(p, p.RebirthLevel, 1000 + seconds))
			end
			if p.ToiletTier < 7 then
				local slots = if p.ToiletTier >= 4 then 10 elseif p.ToiletTier == 1 then 3 else 5
				if p.DisplaySlots < slots then
					buy("DisplaySlots")
				end
				for _, id in ipairs({ "FlushSpeed", "CashBoost", "LuckBoost" }) do
					if U:Level(p, id) < math.min(p.ToiletTier - 1, 4) then
						buy(id)
					end
				end
				local toilet = Toilets[p.ToiletTier + 1]
				if (p.DisplaySlots >= slots or p.ToiletTier >= 4) and p.Coins >= toilet.Price then
					p.Coins -= toilet.Price
					p.ToiletTier += 1
					result.Tiers[p.ToiletTier][player] = seconds / 3600
				end
			else
				-- Save three quarters of the wallet toward the next coin gate.
				-- Compare costs so optional utility tracks compete for real income.
				for _ = 1, 6 do
					local selected, lowest = nil, math.huge
					for _, track in ipairs(Config.Tracks) do
						local price = U:Price(track.Id, U:Level(p, track.Id))
						if price and price < lowest and (track.Id ~= "DisplaySlots" or p.DisplaySlots < 10) then
							selected, lowest = track.Id, price
						end
					end
					if not selected or p.Coins < lowest * 4 then
						break
					end
					assert(buy(selected))
				end
				local toilet = Toilets[p.ToiletTier + 1]
				if toilet and p.Coins >= toilet.Price then
					p.Coins -= toilet.Price
					p.ToiletTier += 1
					result.Tiers[p.ToiletTier][player] = seconds / 3600
				end
			end
			local toilet, luck = Toilets[p.ToiletTier], U:Luck(p, Toilets[p.ToiletTier].Luck)
			if oldTier ~= p.ToiletTier or oldLuck ~= luck then
				entries = Roll.Distribution(Items, Toilets, p.ToiletTier, luck)
				oldTier, oldLuck = p.ToiletTier, luck
			end
			local step = if seconds < 3600 then 2 else 30
			fractional += step * uptime / cooldown(p, toilet)
			local rolls = math.floor(fractional)
			fractional -= rolls
			for _ = 1, rolls do
				local item = Roll.Sample(entries, random())
				p.Inventory[item.Id] = (p.Inventory[item.Id] or 0) + 1
				p.Collection[item.Id] = (p.Collection[item.Id] or 0) + 1
			end
			local award = Service.Grant({ Coins = 0, Stats = { Earned = 0 } }, toilet, U:Cash(p)) * rolls
			p.Coins += award
			p.Stats.Earned += award
			p.Stats.Flushes += rolls
			p.RunFlushes += rolls
			Display.ReserveAndSell(p)
			seconds += step
			if deferRebirth and p.ToiletTier == #Toilets then
				break
			end
			if
				p.RebirthLevel == 15
				and p.Upgrades.CashBoost == 100
				and p.Upgrades.OfflineTank == 100
				and p.Upgrades.LuckBoost == 50
				and p.Upgrades.FlushSpeed == 10
				and p.Upgrades.AutoFlushSpeed == 10
				and p.DisplaySlots == 10
			then
				break
			end
		end
		-- Censor unfinished levels explicitly, never drop slow accounts from percentiles.
		for _, levels in pairs(result.Levels) do
			for _, values in ipairs(levels) do
				values[player] = values[player] or math.huge
			end
		end
		for _, values in ipairs(result.Rebirths) do
			values[player] = values[player] or math.huge
		end
		for _, values in pairs(result.Tiers) do
			values[player] = values[player] or math.huge
		end
	end
	return result
end
return C
