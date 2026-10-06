-- Independent numeric and migration oracles for the two-layer cash contract.
test("cash layers: fractional paid accrual is partition-invariant and never multiplied on collection", function()
	local e = server()
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"), u)
	local function profile()
		local p = e.Data.DefaultProfile()
		p.RebirthLevel, p.Upgrades.CashBoost = 15, 11
		p.Monetization.Passes = { DoubleCash = true, VIPPack = true }
		p.Inventory.Poop, p.Displays["1"] = 1, "Poop"
		p.Income = { UpdatedAt = 1000, Pending = {} }
		return p
	end
	local frequent, batched = profile(), profile()
	assert(income:Rates(frequent)["1"] == 306450)
	for second = 1001, 11001 do
		income:Settle(frequent, second, false)
	end
	income:Settle(batched, 11001, false)
	assert(income:TotalUnits(frequent) == 3064806450 and income:TotalUnits(batched) == 3064806450)
	assert(income:Collect(frequent) == 510801 and income:TotalUnits(frequent) == 450)
	assert(income:Collect(frequent) == 0)
	local offline = profile()
	income:Settle(offline, 1002, true)
	assert(income:TotalUnits(offline) == 306450 and income:Collect(offline) == 51 and income:TotalUnits(offline) == 450)
end)

test("cash layers: every reward, Cash level, toilet and paid combination uses separate caps", function()
	local e = server()
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local c = e:Load("src/shared/Config/Cash")
	assert(c.FreeCap == 40 and c.PaidCap == 3 and c.TotalCap == 120)
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"), u)
	for level = 0, 15 do
		for cash = 0, 100 do
			for tier, toilet in ipairs(income.Config.TierMultipliers) do
				for _, paid in ipairs({
					{ {}, 1 },
					{ { DoubleCash = true }, 2 },
					{ { VIPPack = true }, 1.5 },
					{ { DoubleCash = true, VIPPack = true }, 3 },
				}) do
					local p = {
						RebirthLevel = level,
						Upgrades = { CashBoost = cash },
						ToiletTier = tier,
						DisplaySlots = 1,
						Displays = { ["1"] = "Mystery" },
						Monetization = { Passes = paid[1] },
					}
					local bonus = e:Load("src/shared/Config/Rebirth").Levels[level]
					local base = 1
						+ math.min(cash, 10) * 0.1
						+ math.max(0, cash - 10) * 0.025
						+ (if bonus then bonus.Cash else 0)
					assert(math.abs(u:Cash(p) - math.min(40, base) * paid[2]) < 1e-10)
					local expected = math.min(40, base * toilet) * paid[2]
					assert(math.abs(u:Cash(p, toilet) - expected) < 1e-10)
					assert(income:Rates(p)["1"] == math.floor(100000 * expected * 6000 + 0.5))
				end
			end
		end
	end
	assert(u:Cash({ RebirthLevel = 15 }) == 16, "R15 nominal cash was clipped")
	local paid = e:Load("src/shared/PaidBenefits")
	local config = e:Load("src/shared/Config/Monetization")
	config.Gamepasses.FutureCash = { CashMultiplier = 1e300 }
	assert(paid.Cash({ Monetization = { Passes = { FutureCash = true } } }, 1e300) == 120)
	assert(paid.Cash({ Monetization = { Passes = { FutureCash = true, DoubleCash = true, VIPPack = true } } }, 2) == 6)
end)

test("cash layers: 120x fractional accrual, legacy rate sharing, offline saturation and exact collection", function()
	local e, player, p, commerce, config = catalogPlayer(730)
	e:Load("src/server/Services/MonetizationService").Cosmetics = nil
	for i, key in ipairs({ "DoubleCash", "VIPPack", "OfflinePlus" }) do
		config.Gamepasses[key].Id = 8900 + i
		p.Monetization.Passes[key] = true
	end
	p.RebirthLevel, p.ToiletTier, p.DisplaySlots = 15, 7, 10
	p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 100, 100
	local income = commerce.Income
	for _, slots in ipairs({ 1, 10, 100 }) do
		p.DisplaySlots, p.Displays = slots, {}
		for slot = 1, slots do
			p.Displays[tostring(slot)] = "Mystery"
		end
		local total = 0
		for _, rate in pairs(income:Rates(p)) do
			assert(rate % 1 == 0 and rate <= 72000000000)
			total += rate
		end
		assert(total == math.min(slots, 10) * 72000000000)
	end
	p.Inventory.Mystery = 100
	p.Income = { UpdatedAt = 1, Pending = { ["1"] = 1 } }
	income:Settle(p, 2, false)
	assert(income:TotalUnits(p) == 720000000001)
	assert(income:Collect(p) == 120000000 and income:TotalUnits(p) == 1)
	income:Settle(p, income.Config.MaxTimestamp, true)
	assert(income:TotalUnits(p) == 9e15 and p.Income.Offline.EarnedUnits == 9e15 - 1)
	assert(income:StorageUnits(p, true) == 9e15 and income:StorageUnits(p, false) == 9e15)
	p.Income.Pending["1"] -= 1
	assert(e.Data:Save(player, false))
	e.Data:Close(player)
	local _, q = e:Join(730)
	assert(income:TotalUnits(q) == 9e15 - 1)
	q.Coins, q.Stats.Earned = 9e15 - 7, 9e15 - 5
	assert(income:Collect(q) == 5 and q.Coins == 9e15 - 2 and q.Stats.Earned == 9e15)
	assert(income:TotalUnits(q) == 9e15 - 30001 and income:Collect(q) == 0)
	q.Coins, q.Stats.Earned = 0, 0
	assert(income:Collect(q) == 1499999999994 and income:TotalUnits(q) == 5999)
	assert(income:Collect(q) == 0)
end)

test("cash layers: maximum sale/service awards respect both wallet and lifetime ceilings", function()
	local e = server()
	local items = e:Load("src/shared/Config/Items")
	local inventory = e:Load("src/shared/SafeInventory")
	local service = e:Load("src/server/Services/ServiceCoinService")
	for _, item in ipairs(items) do
		for _, field in ipairs({ "Coins", "Earned" }) do
			local p = { Coins = 0, Stats = { Earned = 0 }, Inventory = { [item.Id] = 1000001 }, Displays = {} }
			local target = if field == "Coins" then p else p.Stats
			local value = item.Value * 120
			target[field] = 9e15 - value + 1
			assert(not inventory.Sell(p, items, item.Id, 1, 120))
			target[field] -= 1
			assert(inventory.Sell(p, items, item.Id, 1, 120) and target[field] == 9e15)
			assert(not inventory.Sell(p, items, item.Id, 1, 120))
		end
	end
	for _, toilet in ipairs(e:Load("src/shared/Config/Toilets")) do
		for _, field in ipairs({ "Coins", "Earned" }) do
			local p = { Coins = 0, Stats = { Earned = 0 } }
			local target = if field == "Coins" then p else p.Stats
			local value = toilet.ServiceCoins * 120
			target[field] = 9e15 - value + 1
			assert(service.Grant(p, toilet, 120) == nil)
			target[field] -= 1
			assert(service.Grant(p, toilet, 120) == value and target[field] == 9e15)
		end
	end
	local p = { Coins = 0, Stats = { Earned = 0 }, Inventory = { Mystery = 1000001 }, Displays = {} }
	assert(not inventory.Sell(p, items, "Mystery", 1000000, 120) and p.Inventory.Mystery == 1000001)
	assert(inventory.Sell(p, items, "Mystery", 150000, 120) and p.Coins == 9e15)
end)

test("rebirth retune: R5 and R15 perks survive actual reset, migration, save and rejoin", function()
	for _, level in ipairs({ 5, 15 }) do
		local e = server()
		local player, p = rebirthReady(e, 740 + level)
		local config = e:Load("src/shared/Config/Rebirth")
		p.RebirthLevel, p.Coins, p.ToiletTier = level - 1, config.Levels[level].RequiredCoins, 7
		e:Fire("Rebirth", player, level - 1)
		e.Data:Close(player)
		local _, q = e:Join(740 + level)
		local bonus = e:Load("src/shared/RebirthRules").new(config):Bonus(q)
		assert(
			q.RebirthLevel == level
				and q.ToiletTier == 7
				and bonus.AutoCollect
				and not q.Monetization.Passes.AutoCollect
		)
		local migrated = e.Data.DefaultProfile()
		migrated.RebirthLevel, migrated.ToiletTier = level, 7
		migrated = e.Data.Sanitize(migrated)
		assert(e:Load("src/shared/RebirthRules").new(config):Bonus(migrated) == bonus)
		if level == 15 then
			assert(bonus.Cash == 15 and bonus.DisplaySlots == 2)
			assert(table.find(bonus.Perks, "Legend skin, golden title and aura"))
		end
	end
end)
