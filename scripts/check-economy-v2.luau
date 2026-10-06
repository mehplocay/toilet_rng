local Config = require("../src/shared/Config/Income")
local Items = require("../src/shared/Config/Items")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Income = require("../src/shared/IncomeAccrual").new(Config, Items, U)
local Format = require("../src/shared/NumberFormat")
local function profile(tier, item, slots)
	local p = {
		ToiletTier = tier,
		DisplaySlots = slots,
		Displays = {},
		Coins = 0,
		Stats = { Earned = 0 },
		Upgrades = {},
		Income = { UpdatedAt = 1000, Pending = {} },
	}
	for slot = 1, slots do
		p.Displays[tostring(slot)] = item
	end
	return p
end
-- Pin the design independently of the formulas under test.
for _, pair in ipairs({
	{ "Poop", 1 },
	{ "ToiletPaper", 3 },
	{ "Rat", 10 },
	{ "Duck", 40 },
	{ "GoldenPoop", 200 },
	{ "ToiletBaby", 1000 },
	{ "SewerShark", 6000 },
	{ "Mystery", 100000 },
}) do
	assert(Income:Rates(profile(1, pair[1], 1))["1"] == pair[2] * 6000)
end
local p = profile(4, "Poop", 1)
p.RebirthLevel, p.Upgrades.CashBoost = 1, 1
assert(Income:Rates(p)["1"] == 26730, "3.3 tier * (1 + .1 cash + .25 rebirth) must retain fractions")
for second = 1001, 11000 do
	Income:Settle(p, second, false)
end
assert(Income:TotalUnits(p) == 267300000)
assert(Income:Collect(p) == 44550 and Income:TotalUnits(p) == 0)

-- Large whole balances plus one subcoin survive every save/collect; division cannot round up.
p = profile(7, "Mystery", 100)
p.RebirthLevel, p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 15, 10, 10
local rates, sum = Income:Rates(p), 0
for _, rate in pairs(rates) do
	assert(rate >= 0 and rate % 1 == 0)
	sum += rate
end
assert(sum == 259200000000, "100 legacy Secrets must share ten-slot total cap exactly")
Income:Settle(p, Config.MaxTimestamp, true)
assert(Income:TotalUnits(p) == 9e15 and Income:PendingCoins(p) == 1500000000000)
local sanitized = Income:Sanitize(p.Income, p)
assert(Income:TotalUnits({ Income = sanitized }) == 9e15)
-- Construct a legal cross-slot ledger right below the global integer ceiling.
local last
for slot = 1, Config.MaxSlots do
	if p.Income.Pending[tostring(slot)] then
		last = tostring(slot)
	end
end
p.Income.Pending[last] -= 1
assert(Income:PendingCoins(p) == 1499999999999, "Division rounded a fractional coin up")
assert(Income:Collect(p) == 1499999999999 and Income:TotalUnits(p) == 5999)
assert(Income:Collect(p) == 0)
p.Income = Income:Sanitize(p.Income, p)
assert(Income:TotalUnits(p) == 5999, "Serialization lost the last fractional coin")

-- Huge elapsed time is clamped before multiplication; settlement partitioning is exact.
local a, b = profile(7, "Mystery", 10), profile(7, "Mystery", 10)
for _, x in ipairs({ a, b }) do
	x.RebirthLevel = 15
	x.Upgrades.CashBoost = 10
end
for second = 1001, 3000 do
	Income:Settle(a, second, false)
end
Income:Settle(b, 3000, false)
assert(Income:TotalUnits(a) == Income:TotalUnits(b))
Income:Settle(a, Config.MaxTimestamp, false)
assert(Income:TotalUnits(a) == Income:StorageUnits(a, false))
local timestamp = a.Income.UpdatedAt
Income:Collect(a)
Income:Settle(a, timestamp, true)
assert(Income:TotalUnits(a) == 0, "Cap consumed time was reclaimed")

-- One-unit tails at per-slot limits and wallet/earned ceilings cannot be erased or minted.
p = profile(7, "Mystery", 1)
p.Upgrades.CashBoost, p.Upgrades.OfflineTank, p.RebirthLevel = 10, 10, 15
local cap = Income:StorageUnits(p, true)
p.Income.Pending["1"] = cap - 1
Income:Settle(p, 1001, false)
assert(p.Income.Pending["1"] == cap)
p.Income.Pending["1"] = cap - 1
p.Coins, p.Stats.Earned = 9e15 - 1, 9e15 - 1
assert(Income:Collect(p, 1) == 1 and p.Income.Pending["1"] == cap - 6001)
assert(p.Coins == 9e15 and p.Stats.Earned == 9e15 and Income:Collect(p) == 0)

for _, pair in ipairs({
	{ 999, "999" },
	{ 1000, "1K" },
	{ 1999, "1.9K" },
	{ 1e6, "1M" },
	{ 1e9, "1B" },
	{ 1e12, "1T" },
	{ 1e15, "1Qa" },
	{ 9e15, "9Qa" },
	{ 1e18, "1Qi" },
	{ math.huge, "0" },
	{ 0 / 0, "0" },
	{ -1, "0" },
}) do
	assert(Format.Compact(pair[1]) == pair[2])
end
assert(Format.Rate(1) == "1" and Format.Rate(1.5) == "1.5" and Format.Rate(6000) == "6K")
print(
	"Economy v2 checks passed: pinned rarity rates, fractional accrual, large storage, exact ceilings, partitions, caps and K/M/B/T/Qa/Qi"
)
