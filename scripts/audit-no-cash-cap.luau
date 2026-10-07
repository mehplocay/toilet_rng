test("uncapped cash: all passes, R15, max upgrades and every display tier", function()
	local e = server()
	local p = e.Data.DefaultProfile()
	local config = e:Load("src/shared/Config/Upgrades")
	local u = e:Load("src/shared/UpgradeRules").new(config)
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"), u)
	p.RebirthLevel = 15
	for _, track in ipairs(config.Tracks) do
		p.Upgrades[track.Id] = track.MaxLevel
	end
	for key in pairs(e:Load("src/shared/Config/Monetization").Gamepasses) do
		p.Monetization.Passes[key] = true
	end
	assert(u:Cash(p) == 204)
	for tier, factor in ipairs(income.Config.TierMultipliers) do
		p.ToiletTier = tier
		assert(math.abs(u:Cash(p, factor) - 204 * factor) < 1e-8)
		for _, slots in ipairs({ 1, 10, 100 }) do
			p.DisplaySlots, p.Displays = slots, {}
			for slot = 1, slots do
				p.Displays[tostring(slot)] = "Mystery"
			end
			local total = 0
			for _, units in pairs(income:Rates(p)) do
				assert(units % 1 == 0 and units >= 0 and units <= 9e15)
				total += units
			end
			assert(math.abs(total - slots * 100000 * 204 * factor * 6000) <= 1)
		end
	end
	assert(u:Cash(p, 325) == 66300 and u:Luck(p, 10, 1e300) == u:Luck(p, 10) * 1e300 and u:Cooldown(p, 0.1) == 0.4)
end)

test("uncapped cash: future factors saturate only numeric bounds and reject nonfinite inputs", function()
	local e = server()
	local mathRules = e:Load("src/shared/CashMath")
	local config = e:Load("src/shared/Config/Monetization")
	local paid = e:Load("src/shared/PaidBenefits")
	local p = e.Data.DefaultProfile()
	config.Gamepasses.FutureCash = { CashMultiplier = 4 }
	p.Monetization.Passes = { FutureCash = true, DoubleCash = true, VIPPack = true }
	assert(paid.Cash(p, 100) == 1200, "A future paid pass must stack beyond the former 3x cap")
	config.Gamepasses.FutureCash.CashMultiplier = 1e300
	local factor = paid.Cash(p, 1e300)
	assert(factor == 1e300 and factor < math.huge)
	assert(mathRules.Product(9e15 - 1, 1, 9e15) == 9e15 - 1)
	assert(mathRules.Round(9e15 - 1) == 9e15 - 1)
	local inventory = e:Load("src/shared/SafeInventory")
	local service = e:Load("src/server/Services/ServiceCoinService")
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	for _, invalid in ipairs({ 0 / 0, math.huge, -math.huge, -1, "2", {} }) do
		assert(not pcall(paid.Cash, p, invalid))
		assert(not pcall(mathRules.Product, invalid, 2, 9e15))
		p.Inventory.Poop = 2
		assert(not inventory.Sell(p, items, "Poop", 1, invalid))
		assert(not pcall(service.Grant, p, toilets[1], invalid))
		assert(p.Coins == 0 and p.Stats.Earned == 0 and p.Inventory.Poop == 2)
	end
	assert(service.Grant(p, toilets[1], factor) == 1e300)
	assert(service.Grant(p, toilets[1], factor) == nil)
	p.Coins, p.Stats.Earned = 0, 0
	assert(inventory.Sell(p, items, "Poop", 1, factor) and p.Coins == 1e300 and p.Stats.Earned == 1e300)
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local income = e:Load("src/shared/IncomeAccrual").new(e:Load("src/shared/Config/Income"), items, u)
	p.ToiletTier, p.RebirthLevel, p.DisplaySlots = 15, 15, 100
	p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 100, 100
	for slot = 1, 100 do
		p.Displays[tostring(slot)] = if slot % 2 == 0 then "Mystery" else "Poop"
	end
	local total = 0
	for _, rate in pairs(income:Rates(p)) do
		assert(rate % 1 == 0)
		total += rate
	end
	assert(mathRules.Near(total, 1e300))
	p.Income = { UpdatedAt = 1000, Pending = { ["1"] = 1 } }
	income:Settle(p, income.Config.MaxTimestamp, true)
	assert(income:TotalUnits(p) == 1e300)
	p.Income.Pending["1"] -= 1
	p.Income = income:Sanitize(p.Income, p)
	assert(income:TotalUnits(p) == 1e300 and income:Collect(p) == 0)
	p.Coins, p.Stats.Earned = 0, 0
	assert(mathRules.Near(income:Collect(p), 1e300 / 6000) and income:TotalUnits(p) == 0)
	local format = e:Load("src/shared/NumberFormat")
	assert(format.Compact(1e21) == "1Sx" and format.Compact(1e33) == "1Dc")
	for _, value in ipairs({ 1e36, 1e100, 1e300, factor }) do
		local label = format.Compact(value)
		assert(#label <= 12 and not label:find("inf") and not label:find("nan"))
	end
end)
