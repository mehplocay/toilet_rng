test("huge coins: persisted paid quotes, full-wallet deferral, retry and replay across all packs", function()
	for _, magnitude in ipairs({ 1e18, 1e45, 1e100, 1e200, 1e290 }) do
		local e, player, p, commerce, config = catalogPlayer(975)
		local mathRules = e:Load("src/shared/CashMath")
		commerce.Receipts.Rate = function()
			return magnitude
		end
		local previous = 0
		for _, key in ipairs({ "Coins10Minutes", "Coins1Hour", "Coins6Hours", "Coins24Hours" }) do
			local product = config.DeveloperProducts[key]
			local quote = commerce.Receipts:Quote(p, key)
			assert(quote > previous and mathRules.Near(quote / magnitude, product.IncomeSeconds))
			previous = quote
			p.Monetization.Quote = { Key = key, Coins = quote }
			p.Coins, p.Stats.Earned = mathRules.Limit, 0
			assert(e.Data:Save(player, false))
			e.Data:Close(player)
			player.Parent = nil
			player, p = e:Join(975)
			assert(p.Monetization.Quote.Coins == quote and p.Coins == mathRules.Limit)
			local info = receipt(player, "huge-" .. key, product.Id)
			local messages = {}
			commerce.Receipts.Notify = function(_, message)
				table.insert(messages, message)
			end
			assert(e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
			assert(#messages == 1 and messages[1]:find("rejoin", 1, true))
			assert(p.Monetization.Quote.Coins == quote)
			p.Coins = 0
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
			p = e.Data:Get(player)
			assert(p.Coins == quote and p.Monetization.Quote == nil)
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted" and p.Coins == quote)
			assert(e.Data.Sanitize(p).Coins == quote)
		end
	end
end)

test("huge coins: VIP chest, VIP pad and daily chest retain their income/reward scaling", function()
	local e, player, p, commerce, config = catalogPlayer(976)
	config.Gamepasses.VIPPack.Id = 8976
	p.Monetization.Passes.VIPPack = true
	commerce.Receipts.Rate = function()
		return 1e200
	end
	local near = e:Load("src/shared/CashMath").Near
	e:Fire("ClaimVIP", player)
	p = e.Data:Get(player)
	assert(near(p.Coins, 6e202) and p.Monetization.VIPDay > 0)
	local before = p.Coins
	e:Fire("ClaimVIP", player)
	assert(p.Coins == before)
	local pad = e:Load("src/server/Services/VIPPadService")
	assert(pad.Claim(commerce, player))
	p = e.Data:Get(player)
	assert(near(p.Coins - before, 5e200) and not pad.Claim(commerce, player))
	local rewardConfig = e:Load("src/shared/Config/Rewards")
	rewardConfig.BaseCoins[1] = 1e200
	local daily = e:Load("src/server/Services/RewardService")
		.new(rewardConfig, e:Load("src/shared/RewardSchedule"), function()
			return e.Now
		end)
	local award = daily:Claim(p)
	assert(award.Success and near(award.Coins, 1.5e200) and not daily:Claim(p).Success)
	assert(e.Data.Sanitize(p).Coins == p.Coins)
end)

test("huge coins: owner-only commands and server prices survive large profile roundtrips", function()
	local e = adminFixture()
	local owner, p = e:JoinAdmin()
	for _, amount in ipairs({ 1e18, 1e100, 1e200, 1e300 }) do
		e:Advance()
		e:Command(owner, "SetCoins", { Amount = amount })
		p = e.Data:Get(owner)
		assert(e:Last().Success and p.Coins == amount and e.Data.Sanitize(p).Coins == amount)
	end
	local economy = e:Load("src/server/Services/EconomyService")
	local toilets = e:Load("src/shared/Config/Toilets")
	local original = toilets[2].Price
	for _, price in ipairs({ 1e30, 1e100, 1e299 }) do
		toilets[2].Price, p.ToiletTier, p.Coins = price, 1, price * (1 - 2 ^ -50)
		assert(not economy.BuyToilet(p, toilets[2].Id) and p.ToiletTier == 1)
		p.Coins = price
		assert(economy.BuyToilet(p, toilets[2].Id) and p.Coins == 0)
	end
	toilets[2].Price = original
end)
