-- Shared balance experiment: real purchases, protected first copies, seeded independent checks.
local Roll = require("../src/server/Services/RollService")
local Service = require("../src/server/Services/ServiceCoinService")
local Inventory = require("../src/shared/SafeInventory")
local Upgrades = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Cohort = {}
local DisplayCohort = require("./display-cohort")
function Cohort.Run(items, toilets, players, buyTracks, seed, displaySlots)
	local stages, cumulative = {}, {}
	for tier = 1, #toilets - 1 do
		stages[tier], cumulative[tier] = {}, {}
	end
	seed = seed or 20261005
	local function sample()
		seed = seed * 16807 % 2147483647
		return seed / 2147483647
	end
	for _ = 1, players do
		local profile =
			{ Coins = 0, Stats = { Earned = 0 }, Inventory = {}, Displays = {}, Upgrades = {}, DisplaySlots = 3 }
		local elapsed = 0
		if displaySlots then
			profile.DisplaySlots = displaySlots
			profile.Income = { UpdatedAt = 1000, Pending = {} }
		end
		for tier = 1, #toilets - 1 do
			profile.ToiletTier = tier
			local toilet, nextToilet = toilets[tier], toilets[tier + 1]
			local duration = 0
			local entries, luck
			while true do
				if displaySlots then
					DisplayCohort.Settle(profile, (elapsed + duration) * 60)
				end
				local pending = false
				if buyTracks then
					-- One affordable step in each active track per tier, capped at four.
					for _, id in ipairs({ "FlushSpeed", "CashBoost", "LuckBoost" }) do
						local level = Upgrades:Level(profile, id)
						if level < math.min(tier, 4) then
							if not Upgrades:Buy(profile, id, level) then
								pending = true
							end
						end
					end
				end
				if not pending and profile.Coins >= nextToilet.Price then
					break
				end
				local effectiveLuck = Upgrades:Luck(profile, toilet.Luck)
				if luck ~= effectiveLuck then
					luck = effectiveLuck
					entries = Roll.Distribution(items, toilets, tier, luck)
				end
				local item = Roll.Sample(entries, sample)
				local cash = Upgrades:Cash(profile)
				assert(Service.Grant(profile, toilet, cash))
				profile.Inventory[item.Id] = (profile.Inventory[item.Id] or 0) + 1
				if displaySlots then
					DisplayCohort.ReserveAndSell(profile)
				elseif profile.Inventory[item.Id] > 1 then
					assert(Inventory.Sell(profile, items, item.Id, 1, cash))
				end
				duration += Upgrades:Cooldown(profile, toilet.Cooldown) / 60 / 0.75
				assert(duration < 200, "Progression stalled")
			end
			profile.Coins -= nextToilet.Price
			elapsed += duration
			table.insert(stages[tier], duration)
			table.insert(cumulative[tier], elapsed)
		end
	end
	return stages, cumulative
end
function Cohort.Percentile(values, fraction)
	table.sort(values)
	return values[math.ceil(#values * fraction)]
end
return Cohort
