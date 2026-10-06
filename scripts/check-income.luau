local Config = require("../src/shared/Config/Income")
local Items = require("../src/shared/Config/Items")
local Income = require("../src/shared/IncomeAccrual").new(Config, Items)
local Display = require("../src/server/Services/DisplayService")
local function profile(tier, slots, id)
	local p = {
		Coins = 0,
		Stats = { Earned = 0 },
		ToiletTier = tier or 1,
		DisplaySlots = slots or 3,
		Displays = {},
		Inventory = {},
		Income = Income:Sanitize(nil),
	}
	for slot = 1, p.DisplaySlots do
		p.Displays[tostring(slot)] = id
	end
	p.Inventory[id or "Poop"] = p.DisplaySlots
	Income:Settle(p, 1000, false)
	return p
end
local function units(p)
	return Income:TotalUnits(p)
end
local p = profile(1, 3, "Poop")
Income:Settle(p, 1060, false)
assert(units(p) == 1080000 and Income:PendingCoins(p) == 180)
for now = 1061, 7000 do
	Income:Settle(p, now, false)
end
assert(units(p) == 18000 * Config.UnitsPerCoin, "Frequent settlement lost fractions")
assert(Income:Collect(p) == 18000 and p.Coins == 18000 and p.Stats.Earned == 18000)
assert(Income:Collect(p) == 0, "Repeated collect duplicated coins")
Income:Settle(p, 6000, false)
Income:Settle(p, 7000, false)
assert(units(p) == 0 and p.Income.UpdatedAt == 7000, "Clock rollback replayed income")

p = profile(1, 3, "Duck")
Income:Settle(p, 1060, false)
assert(units(p) == 43200000)
assert(Display.Set(p, nil, 1))
assert(Display.Set(p, "Poop", 1) == false)
p.Inventory.Poop = 1
assert(Display.Set(p, "Poop", 1))
Income:Settle(p, 1120, false)
assert(units(p) == 72360000 and p.Income.Pending["1"] == 14760000, "Change lost/repriced old income")
assert(Income:Collect(p) == 12060 and units(p) == 0)
p.Income.Pending = { ["1"] = 3001, ["2"] = 3002 }
assert(Income:Collect(p, 1) == 0 and Income:Collect(p) == 1 and units(p) == 3, "Pooled fractions were lost")

p = profile(7, 10, "Mystery")
local rates, rate = Income:Rates(p), 0
for _, value in pairs(rates) do
	rate += value
end
assert(rate == 720000000 * Config.UnitsPerCoin / 60, "Player rate cap missing")
local single = profile(7, 1, "Mystery")
assert(Income:Rates(single)["1"] == 72000000 * Config.UnitsPerCoin / 60, "Slot rate cap missing")
Income:Settle(p, 1000 + 86400 * 30, true)
assert(Income:PendingCoins(p) == 720000000 * 480, "Offline interval not capped to 480 minutes")
Income:Settle(p, p.Income.UpdatedAt, true)
assert(Income:PendingCoins(p) == 720000000 * 480, "Same timestamp replayed offline award")
Income:Settle(single, 1000 + 86400 * 30, false)
assert(Income:PendingCoins(single) == Config.SlotPendingCap)
assert(Income:PendingCoins(p) == Config.PlayerPendingCap)
local fullTime = p.Income.UpdatedAt
assert(Income:Collect(p) == Config.PlayerPendingCap)
Income:Settle(p, fullTime, false)
assert(units(p) == 0, "Collect recovered time discarded at cap")

p = profile(1, 1, "Duck")
Income:Settle(p, 1060, false)
p.Coins = Config.MaxBalance
assert(Income:Collect(p) == 0 and units(p) == 2400 * Config.UnitsPerCoin)
p.Coins, p.Stats.Earned = Config.MaxBalance - 1, Config.MaxBalance
assert(Income:Collect(p) == 0 and units(p) == 2400 * Config.UnitsPerCoin)
p.Stats.Earned = Config.MaxBalance - 1
assert(Income:Collect(p) == 1 and p.Coins == Config.MaxBalance and p.Stats.Earned == Config.MaxBalance)

for _, bad in ipairs({ false, "bad", 5, { UpdatedAt = 0 / 0 }, { UpdatedAt = math.huge }, { UpdatedAt = -1 } }) do
	local clean = Income:Sanitize(bad)
	assert(clean.UpdatedAt == 0 and next(clean.Pending) == nil)
end
local clean = Income:Sanitize({
	UpdatedAt = 1234,
	Pending = { ["1"] = math.huge, ["2"] = 0 / 0, ["3"] = -1, ["4"] = 6001.9, ["101"] = 999, ["fake"] = 999, [1] = 999 },
})
assert(clean.UpdatedAt == 1234 and clean.Pending["4"] == 6001)
clean.Pending["4"] = nil
assert(next(clean.Pending) == nil)
local raw = { UpdatedAt = 1234, Pending = {} }
for slot = 1, 100 do
	raw.Pending[tostring(slot)] = 9e15
end
p.Income = Income:Sanitize(raw)
assert(Income:PendingCoins(p) == Config.PlayerPendingCap)
for _, value in pairs(p.Income.Pending) do
	assert(value <= Config.SlotPendingCap * Config.UnitsPerCoin)
end
-- Pending survives empty displays and capacity reductions; it belongs to the player.
p.Displays, p.DisplaySlots = {}, 1
assert(Income:Collect(p) == 0) -- Full wallet is unchanged.
p.Coins, p.Stats.Earned = 0, 0
assert(Income:Collect(p) == Config.PlayerPendingCap)
p.Income = Income:Sanitize(nil)
Income:Settle(p, 2000000, true)
assert(units(p) == 0 and p.Income.UpdatedAt == 2000000)
print(
	"Income checks passed: exact fractions, caps, offline cap, clock rollback, changes, idempotency, bounds and migration"
)
