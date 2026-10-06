local Config = require("../src/shared/Config/Rebirth")
local rules = require("../src/shared/RebirthRules").new(Config)
local UpgradeConfig = require("../src/shared/Config/Upgrades")
local U = require("../src/shared/UpgradeRules").new(UpgradeConfig)
local Toilets = require("../src/shared/Config/Toilets")
local Items = require("../src/shared/Config/Items")
local IncomeConfig = require("../src/shared/Config/Income")
local Roll = require("../src/server/Services/RollService")
local Income = require("../src/shared/IncomeAccrual").new(IncomeConfig, Items, U)
assert(#Config.Levels >= 10 and #Config.Levels <= 20 and Config.RequiredTier == 4)
local previous = { Cash = 0, Luck = 0, Speed = 0 }
local previousCashStep = math.huge
for level, bonus in ipairs(Config.Levels) do
	assert(bonus.Cash >= previous.Cash and bonus.Cash <= Config.CashCap + 1e-9)
	assert(bonus.Luck >= previous.Luck and bonus.Luck <= Config.LuckBonusCap)
	assert(bonus.Speed >= previous.Speed and bonus.Speed <= Config.SpeedBonusCap)
	assert(bonus.Cash - previous.Cash <= previousCashStep + 1e-9)
	previousCashStep, previous = bonus.Cash - previous.Cash, bonus
	assert(bonus.StarterCoins <= 10000 and #bonus.Perks == 3 and bonus.Title and bonus.Badge)
	for tier, toilet in ipairs(Toilets) do
		for cash = 0, 10 do
			for speed = 0, 10 do
				local p = { RebirthLevel = level, Upgrades = { CashBoost = cash, FlushSpeed = speed, LuckBoost = 10 } }
				local cooldown, multiplier = U:Cooldown(p, toilet.Cooldown), U:Cash(p)
				assert(cooldown >= UpgradeConfig.CooldownFloor and multiplier <= 2 + Config.CashCap + 1e-9)
				p.ToiletTier, p.DisplaySlots, p.Displays = tier, 100, {}
				for slot = 1, 100 do
					p.Displays[tostring(slot)] = "Mystery"
				end
				local total = 0
				for _, units in pairs(Income:Rates(p)) do
					assert(units % 1 == 0 and units >= 0)
					total += units
				end
				assert(total <= math.floor(IncomeConfig.PlayerRateCaps[tier] * multiplier * 100))
				assert(Income:StorageUnits(p, false) <= 9e15)
				assert(U:Luck(p, toilet.Luck, 2, 2, 1e300) == UpgradeConfig.LuckCap)
			end
		end
		local distribution = Roll.Distribution(Items, Toilets, tier, UpgradeConfig.LuckCap)
		local total = 0
		for _, entry in ipairs(distribution) do
			total += entry.Probability
		end
		assert(math.abs(total - 1) < 1e-12)
	end
end
for _, invalid in ipairs({ -1, 0.5, math.huge, 0 / 0, "1", {} }) do
	assert(rules:Level({ RebirthLevel = invalid }) == 0)
end
assert(rules:Level({ RebirthLevel = 100 }) == #Config.Levels)
print(
	"Rebirth math passed: 15 bounded diminishing levels, global luck/cooldown caps, probability sum 1, exact bounded income across all Cash/Speed/tier/rebirth combinations"
)
