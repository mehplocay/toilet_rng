-- Production service/DataStore integration, appended to the existing adversarial scheduler.
test("economy v2: billion-coin collect retries, saves and rejoins without fractional loss", function()
	local e = server()
	local player, p = e:Join(810)
	p.Income.Pending = { ["1"] = 6000000000001, ["2"] = 12000000000002 }
	e.Store.After = function()
		error("committed billion-coin response lost")
	end
	local collect = e:Spawn(function()
		e:Fire("CollectIncome", player)
	end)
	assert(p.Coins == 3000000000 and p.Income.Pending["2"] == 3)
	assert(e.Store.Records.Player_810.Data.Coins == 3000000000)
	e:Fire("CollectIncome", player)
	e.Store.After = nil
	e:Resume(collect)
	e.Data:Close(player)
	local joined, restored = e:Join(810)
	e:Fire("CollectIncome", joined)
	assert(restored.Coins == 3000000000 and restored.Stats.Earned == 3000000000)
	assert(restored.Income.Pending["2"] == 3)
end)

test("economy v2: 9e15-subcoin sanitizer and collect preserve the last fraction", function()
	local e = server()
	local player, p = e:Join(811)
	p.RebirthLevel, p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 15, 10, 10
	local raw = { UpdatedAt = e.Now, Pending = {} }
	for slot = 1, 100 do
		raw.Pending[tostring(slot)] = 9e15
	end
	local income = e:Load("src/shared/IncomeAccrual").new(
		e:Load("src/shared/Config/Income"),
		e:Load("src/shared/Config/Items"),
		e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	)
	p.Income = income:Sanitize(raw, p)
	assert(income:TotalUnits(p) == 9e15)
	p.Income.Pending["1"] -= 1
	e:Fire("CollectIncome", player)
	assert(p.Coins == 1499999999999 and income:TotalUnits(p) == 5999)
	e.Data:Close(player)
	local joined, restored = e:Join(811)
	assert(restored.Coins == 1499999999999 and income:TotalUnits(restored) == 5999)
	e:Fire("CollectIncome", joined)
	assert(restored.Coins == 1499999999999 and income:TotalUnits(restored) == 5999)
end)

test("economy v2: eight-hour Secret offline award consumes elapsed time once", function()
	local e = server()
	local player, p = e:Join(812)
	p.ToiletTier, p.Inventory.Mystery, p.Displays["1"] = 7, 1, "Mystery"
	e.Data:Close(player)
	e.Now += 86400 * 30
	local joined, restored = e:Join(812)
	assert(restored.Income.Pending["1"] == 18720000000 * 6000)
	e:Fire("CollectIncome", joined)
	assert(restored.Coins == 18720000000)
	e.Data:Close(joined)
	local _, again = e:Join(812)
	assert(again.Coins == 18720000000 and next(again.Income.Pending) == nil)
end)

test("economy v2: cash, toilet and rebirth multipliers settle only future seconds", function()
	local e = server()
	local player, p = e:Join(813)
	p.Coins, p.Inventory.Poop = 100000, 1
	e:Fire("Display", player, "Poop", 1)
	e.Now += 60
	e:Fire("BuyToilet", player, "Dirty")
	assert(p.ToiletTier == 2 and p.Income.Pending["1"] == 360000)
	e.Now += 60
	e:Fire("BuyUpgrade", player, "CashBoost", 0)
	assert(p.Income.Pending["1"] == 900000)
	e.Now += 60
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == 1494000)
	-- A loaded rebirth bonus is additive with Cash Boost and does not reprice pending units.
	p.RebirthLevel = 1
	e.Now += 10
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == 1638000)
end)

test("economy v2: wallet and lifetime ceilings retain unpaid large pending balances", function()
	local e = server()
	local player, p = e:Join(814)
	p.Coins, p.Stats.Earned = 9e15 - 1, 9e15 - 1
	p.Income.Pending["1"] = 6000000000001
	e:Fire("CollectIncome", player)
	assert(p.Coins == 9e15 and p.Stats.Earned == 9e15 and p.Income.Pending["1"] == 5999999994001)
	e.Now += 1
	e:Fire("CollectIncome", player)
	assert(p.Coins == 9e15 and p.Income.Pending["1"] == 5999999994001)
	e.Data:Close(player)
	local _, restored = e:Join(814)
	assert(restored.Coins == 9e15 and restored.Income.Pending["1"] == 5999999994001)
end)
