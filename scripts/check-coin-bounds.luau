local Math = require("../src/shared/CashMath")
local Limit = require("../src/shared/Config/Economy").MaxAmount
local Items = require("../src/shared/Config/Items")
local Upgrades = require("../src/shared/Config/Upgrades")
local IncomeConfig = require("../src/shared/Config/Income")
local U = require("../src/shared/UpgradeRules").new(Upgrades)
local Income = require("../src/shared/IncomeAccrual").new(IncomeConfig, Items, U)
local Inventory = require("../src/shared/SafeInventory")
local Paid = require("../src/shared/PaidBenefits")
local Rebirth = require("../src/shared/RebirthRules").new(require("../src/shared/Config/Rebirth"))
local Format = require("../src/shared/NumberFormat")
local function profile()
	return {
		Coins = 0,
		Stats = { Earned = 0, Flushes = 300 },
		RunFlushes = 300,
		RebirthLevel = 0,
		ToiletTier = 1,
		DisplaySlots = 3,
		Displays = {},
		Inventory = { Poop = 100 },
		Upgrades = {},
		Income = { UpdatedAt = 1000, Pending = {} },
		Monetization = { Passes = {} },
	}
end
assert(Limit == 1e300 and IncomeConfig.MaxLedgerUnits == Limit and Upgrades.MaxBalance == Limit)
assert(Math.Power(Limit, Limit) == Limit)
assert(Format.Compact(1.23e303) == "1.23e303")
for _, bound in ipairs({ 0 / 0, math.huge, -1 }) do
	assert(not pcall(Math.Product, 1, 1, bound))
	assert(not pcall(Math.Add, 1, 1, bound))
end
for _, bad in ipairs({ math.huge, -math.huge, 0 / 0, -1, "10", {}, Limit * 2 }) do
	assert(not Math.Amount(bad) and Math.Sanitize(bad) == 0)
	assert(not Math.Affords(bad, 100) and not Math.Affords(100, bad))
end
for exponent = 0, 300, 3 do
	local value = 10 ^ exponent
	assert(Math.Amount(value) and Math.Sanitize(value) == value)
	assert(#Format.Compact(value) <= 10 and not Format.Compact(value):find("inf"))
	for _, factor in ipairs({ 0, 0.5, 1, 3, 6000, 86400, 1e100, Limit }) do
		local product = Math.Product(value, factor)
		assert(Math.Amount(product))
		if factor > 0 and value < Limit / factor then
			assert(Math.Near(product, value * factor))
		end
	end
	for _, price in ipairs({ 1, value / 3, value, math.min(Limit, value * 2) }) do
		local after = Math.Debit(value, price)
		if math.floor(value) < math.ceil(price) then
			assert(after == nil)
		else
			assert(after >= 0 and after < value and Math.Near(after + math.ceil(price), value))
		end
	end
	if exponent >= 15 then
		local p = profile()
		p.Coins, p.Stats.Earned = value, value / 2
		assert(U:Buy(p, "CashBoost", 0) and p.Coins < value)
		assert(not U:Buy(p, "CashBoost", 0))
		local reset = Rebirth:Build(p, 0, 2000)
		assert(reset and reset.Coins == Rebirth.Config.Levels[1].StarterCoins)
		assert(reset.RebirthLevel == 1 and next(reset.Income.Pending) == nil)
	end
	local p = profile()
	p.Income.Pending = { ["1"] = value }
	p.Income = Income:Sanitize(p.Income, p)
	local collected = Income:Collect(p)
	assert(Math.Near(collected * 6000 + Income:TotalUnits(p), value))
	assert(Income:Collect(p) == 0 and p.Coins == collected)
	if exponent >= 3 then
		p = profile()
		local items = { { Id = "Poop", Value = value } }
		assert(Inventory.Sell(p, items, "Poop", 1, 1) and p.Coins == value and p.Inventory.Poop == 99)
		p.Coins = Limit
		assert(not Inventory.Sell(p, items, "Poop", 1, 1) and p.Inventory.Poop == 99)
	end
	for _, seconds in ipairs({ 600, 3600, 21600, 86400 }) do
		assert(Paid.CoinGrant(value, seconds) == math.max(100, math.floor(Math.Product(value, seconds))))
	end
end
-- Preserve subcoin partitions at normal magnitudes, prevent a tiny collect from copying a huge ledger.
local p = profile()
p.Income.Pending = { ["1"] = 1e200 }
assert(Income:Collect(p, 1, 1) == 0 and p.Income.Pending["1"] == 1e200 and p.Coins == 0)
p.Income.Pending = { ["1"] = 9e15 - 1 }
assert(Income:Collect(p) == 1499999999999 and Income:TotalUnits(p) == 5999)
local previous = 0
for _, seconds in ipairs({ 600, 3600, 21600, 86400 }) do
	local quote = Paid.CoinGrant(1e100, seconds)
	assert(quote > previous and Math.Near(quote / 1e100, seconds))
	previous = quote
end
-- Future cost curves overflow safely; current level counts/prices stay untouched.
local future = table.clone(Upgrades)
future.Tracks = { { Id = "Future", Name = "Future", BaseCost = 1e100, Growth = 1e100, MaxLevel = 100, Step = 1 } }
local curve = require("../src/shared/UpgradeRules").new(future)
for level = 0, 99 do
	local price = curve:Price("Future", level)
	assert(Math.Amount(price) and price >= 1e100)
	local buyer = profile()
	buyer.Coins = price
	assert(curve:Buy(buyer, "Future", level) == (level == 0))
	buyer.Upgrades.Future, buyer.Coins = level, price
	assert(curve:Buy(buyer, "Future", level) and buyer.Coins == 0)
	buyer.Upgrades.Future, buyer.Coins = level, price * (1 - 2 ^ -50)
	assert(not curve:Buy(buyer, "Future", level))
end
-- Huge online/offline products remain finite and time is consumed only once.
local extreme = require("../src/shared/IncomeAccrual").new(IncomeConfig, Items, {
	Cash = function()
		return Limit
	end,
	OfflineMinutes = function()
		return 1440
	end,
})
p = profile()
p.Displays["1"] = "Mystery"
extreme:Settle(p, 1000 + 86400, true)
assert(Math.Amount(extreme:TotalUnits(p)) and extreme:TotalUnits(p) > 1e290)
local total = extreme:TotalUnits(p)
extreme:Settle(p, 1000 + 86400, true)
assert(extreme:TotalUnits(p) == total)
assert(Math.Near(extreme:Collect(p), total / 6000) and extreme:Collect(p) == 0)
print(
	"Coin bounds properties passed: 101 magnitudes, debit/sale/reset/collect, overflow, quote ratios, offline and extreme curves"
)
