local Config = require("../src/shared/Config/Upgrades")
local U = require("../src/shared/UpgradeRules").new(Config)
local Toilets = require("../src/shared/Config/Toilets")
local Items = require("../src/shared/Config/Items")
local IncomeConfig = require("../src/shared/Config/Income")
local Income = require("../src/shared/IncomeAccrual").new(IncomeConfig, Items, U)
local Inventory = require("../src/shared/SafeInventory")
local Roll = require("../src/server/Services/RollService")
local function profile()
	return {
		Coins = 9e15,
		Upgrades = U:Sanitize(nil),
		DisplaySlots = 3,
		Stats = { Earned = 0 },
		Inventory = { Poop = 10 },
		Displays = {},
		ToiletTier = 7,
	}
end
assert(#Config.Tracks == 6 and Config.DisplayCapacity == 10)
for _, track in ipairs(Config.Tracks) do
	assert(
		track.MaxLevel >= 8 and track.MaxLevel <= 12
			or track.Id == "DisplaySlots" and track.MaxLevel == Config.DisplayCapacity - Config.BaseDisplaySlots
	)
	local p, spent = profile(), 0
	for level = 0, track.MaxLevel - 1 do
		local price = U:Price(track.Id, level)
		assert(price and price > 0 and price % 1 == 0 and price <= Config.MaxBalance)
		if level > 0 then
			assert(price > U:Price(track.Id, level - 1))
		end
		local thread = coroutine.create(function()
			assert(U:Buy(p, track.Id, level))
		end)
		assert(coroutine.resume(thread) and coroutine.status(thread) == "dead", "Purchase yielded")
		spent += price
		assert(p.Coins == Config.MaxBalance - spent and U:Level(p, track.Id) == level + 1)
		assert(not U:Buy(p, track.Id, level), "Replay bought another level")
	end
	assert(not U:Buy(p, track.Id, track.MaxLevel) and U:Price(track.Id, track.MaxLevel) == nil)
end
local p = profile()
for _, bad in ipairs({ -1, 0 / 0, math.huge, -math.huge, 0.5, "0", {}, true, 9e15 + 1 }) do
	assert(not U:Buy(p, "CashBoost", bad))
	assert(U:Sanitize({ CashBoost = bad }).CashBoost == 0)
end
for _, bad in ipairs({ 0 / 0, {}, false, 1, "", "Unknown", string.rep("A", 10000) }) do
	assert(not U:Buy(p, bad, 0))
end
assert(not U:Buy(p, nil, 0) and not U:Buy(p, "CashBoost", nil))
for _, bad in ipairs({ -1, 0 / 0, math.huge, 1.5, "30", 9e15 + 1 }) do
	p.Coins = bad
	assert(not U:Buy(p, "CashBoost", 0))
end
p.Coins = U:Price("CashBoost", 0) - 1
assert(not U:Buy(p, "CashBoost", 0))
p.Coins += 1
assert(U:Buy(p, "CashBoost", 0) and p.Coins == 0)
local old = { DisplaySlots = 100 }
U:Restore(old, nil)
assert(old.DisplaySlots == 100 and old.Upgrades.CashBoost == 0)
U:Restore(old, { DisplaySlots = 999, CashBoost = 999, Unknown = 10 })
assert(old.DisplaySlots == 100 and old.Upgrades.CashBoost == 10 and old.Upgrades.Unknown == nil)
local fresh = { DisplaySlots = 3 }
U:Restore(fresh, { DisplaySlots = 4 })
U:Restore(fresh, fresh.Upgrades)
assert(fresh.DisplaySlots == 7, "Migration repeatedly added display levels")
fresh.Coins = 9e15
fresh.DisplaySlots = 10
assert(not U:Buy(fresh, "DisplaySlots", 4), "Sold an unusable display slot")

for _, toilet in ipairs(Toilets) do
	local previous, autoPrevious = toilet.Cooldown, toilet.Cooldown * Config.AutoBaseMultiplier
	for level = 0, 10 do
		p.Upgrades.FlushSpeed, p.Upgrades.AutoFlushSpeed, p.Upgrades.LuckBoost = level, level, level
		local cd = U:Cooldown(p, toilet.Cooldown)
		local auto = U:AutoInterval(p, cd)
		assert(cd >= 0.4 and cd <= previous and auto >= cd and auto <= autoPrevious)
		assert(U:Animation(cd) < cd and U:Animation(cd) < 1)
		assert(U:Luck(p, toilet.Luck, 2, 2, 1e300) == Config.LuckCap)
		previous, autoPrevious = cd, auto
	end
end
assert(U:Cooldown(p, Toilets[#Toilets].Cooldown * 0.8) == 0.4)
assert(U:AutoInterval(p, 0.4) == 0.4)
for _, factor in ipairs({ 0, 0 / 0, math.huge, -1 }) do
	assert(not pcall(U.Luck, U, p, 1, factor))
end

local a, b = profile(), profile()
a.Coins, b.Coins = 0, 0
assert(Inventory.Sell(a, Items, "Poop", 8, 1.3))
for _ = 1, 8 do
	assert(Inventory.Sell(b, Items, "Poop", 1, 1.3))
end
assert(a.Coins == b.Coins and a.Inventory.Poop == 2)
a.Coins = 9e15
assert(not Inventory.Sell(a, Items, "Poop", 1, 2) and a.Inventory.Poop == 2)

p = profile()
p.Coins = 0
p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 10, 10
p.DisplaySlots = 10
for slot = 1, 10 do
	p.Displays[tostring(slot)] = "Mystery"
end
p.Income = Income:Sanitize(nil, p)
Income:Settle(p, 1000, false)
Income:Settle(p, 1000 + 86400 * 30, true)
assert(U:OfflineMinutes(p, 240) == 480)
assert(Income:PendingCoins(p) == 420 * 2 * 480, "Tank/boost clipped by old pending cap")
p.Income = Income:Sanitize(p.Income, p)
assert(Income:Collect(p) == 403200)
assert(Income:Collect(p) == 0)
Income:Settle(p, p.Income.UpdatedAt, true)
assert(Income:PendingCoins(p) == 0)

for tier = 1, #Toilets do
	local entries, empty = Roll.Distribution(Items, Toilets, tier, U:Luck(p, Toilets[tier].Luck, 2, 2, 2))
	local total, events = 0, 0
	for _, entry in ipairs(entries) do
		total += entry.Probability
		if entry.Item.Event then
			events += entry.Probability
		end
		if entry.Item.Id == "KingPoop" then
			assert(entry.Probability >= 0.0000499997 and entry.Probability <= 0.00005)
		end
	end
	assert(empty == 0 and math.abs(total - 1) < 1e-12)
	assert(events <= 0.0000555 and (tier < 5 or events >= 0.00005 - 1e-12))
	assert(Roll.Sample(entries, function()
		return 0.999999999
	end).Id == "Poop")
end
print(
	"Upgrade checks passed: bounded exponential purchases, compare-and-swap replay, migration, slots, luck/cooldown/auto caps, cash rounding, full tank and exact odds"
)
