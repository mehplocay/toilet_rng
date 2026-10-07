-- Paid entitlements must never alter display capacity; saved legacy capacity is permanent.
test("free slots: exact catalog and unchanged bundle benefits", function()
	local e, player, p, commerce, config = catalogPlayer(1100)
	local expected = {
		"SparkleTrail",
		"VIPStar",
		"CustomPlotColor",
		"FastFlush",
		"DoubleCash",
		"AutoCollect",
		"OfflinePlus",
		"VIPPack",
		"DoubleLuck",
		"RainbowName",
		"ConfettiReveal",
		"GoldenName",
		"DancePack",
		"ToiletGlow",
		"Companion",
		"UltimateBundle",
	}
	assert(#config.PassOrder == 16 and #config.ProductOrder == 8)
	for i, key in ipairs(expected) do
		assert(config.PassOrder[i] == key and config.Gamepasses[key])
		assert(config.Gamepasses[key].Slots == nil and config.Gamepasses[key].DisplaySlots == nil)
	end
	local count = 0
	for key in pairs(config.Gamepasses) do
		count += 1
		assert(table.find(expected, key))
	end
	assert(count == 16 and config.Gamepasses.ExtraSlots == nil)
	assert(config.Gamepasses.UltimateBundle.Price == 799)
	assert(string.find(config.Gamepasses.UltimateBundle.Description, "all 15 other passes", 1, true))
	local rules, paid = e:Load("src/shared/MonetizationRules"), e:Load("src/shared/PaidBenefits")
	local bundle = rules.Entitlements({ UltimateBundle = true, ExtraSlots = true }, config)
	assert(bundle.ExtraSlots == nil and not rules.Pass(config, "ExtraSlots"))
	assert(not rules.PassKey(config, 8001))
	assert(not paid.Owns({ OwnedPasses = { ExtraSlots = true, UltimateBundle = true } }, "ExtraSlots"))
	local service = e:Load("src/server/Services/MonetizationService")
	service.Cosmetics = nil
	for i, key in ipairs(expected) do
		config.Gamepasses[key].Id = 12000 + i
	end
	service.Owned[player] = { UltimateBundle = true }
	commerce:Apply(player, service.Owned[player])
	for _, key in ipairs(expected) do
		assert(service:EffectiveOwned(player)[key] and paid.Owns(p, key))
	end
	assert(p.DisplaySlots == 3 and commerce.Income.Upgrades:Cash(p) == 3)
	assert(commerce.Income.Upgrades:OfflineMinutes(p, 480) == 1440)
	assert(math.abs(service:Cooldown(player, 3) - 2.4) < 1e-12 and service:Luck(player) == 2.5)
	assert(config.Gamepasses.VIPPack.PathSpeedStep == 1)
	assert(p.Monetization.LuckyFlushes == 0 and p.Monetization.PathExpires == 0 and p.Coins == 0)
	for _, key in ipairs(expected) do
		service.Owned[player][key] = true
	end
	commerce:Apply(player, service.Owned[player])
	assert(p.DisplaySlots == 3 and commerce.Income.Upgrades:Cash(p) == 3)
	assert(commerce.Income.Upgrades:OfflineMinutes(p, 480) == 1440)
end)

do
	local e = server()
	for i, key in ipairs(e:Load("src/shared/Config/Monetization").PassOrder) do
		test("free slots: purchase, refresh, replay and rejoin never grant slots: " .. key, function()
			local env, player, p, commerce, config = catalogPlayer(1110 + i)
			local service = env:Load("src/server/Services/MonetizationService")
			service.Cosmetics = nil
			config.Gamepasses[key].Id = 13000 + i
			env.Marketplace.Lookup = function(_, id)
				return id == config.Gamepasses[key].Id
			end
			env.Marketplace.PromptGamePassPurchaseFinished:Fire(player, config.Gamepasses[key].Id, true)
			for _ = 1, 3 do
				service:Load(player)
				env.Marketplace.PromptGamePassPurchaseFinished:Fire(player, config.Gamepasses[key].Id, true)
				commerce:Apply(player, service.Owned[player])
			end
			assert(p.DisplaySlots == 3 and p.Monetization.Passes[key])
			-- Retired purchase requests/callbacks cannot prompt or grant anything.
			env:Fire("BuyPass", player, "ExtraSlots")
			env.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 8001, true)
			assert(not env.Marketplace.LastPrompt and p.DisplaySlots == 3)
			env.Data:Close(player)
			player.Parent = nil
			local _, restored = env:Join(player.UserId)
			assert(restored.DisplaySlots == 3 and restored.Monetization.Passes[key])
		end)
	end
end

for _, slots in ipairs({ 4, 5, 8, 10, 12, 100 }) do
	for _, occupied in ipairs({ false, true }) do
		test(
			"free slots: saved legacy capacity survives migration/rebirth/rejoin " .. slots .. "/" .. tostring(occupied),
			function()
				local e = server()
				local raw = e.Data.DefaultProfile()
				raw.DisplaySlots = slots
				raw.Monetization.Passes = { ExtraSlots = true, VIPPack = true, UltimateBundle = true }
				raw.Monetization.AppliedSlots = 5
				if occupied then
					raw.Inventory.Rat, raw.Displays[tostring(slots)] = 1, "Rat"
				end
				e.Store.Records.Player_1140 = { Data = raw }
				local player, p = e:Join(1140)
				local service = e:Load("src/server/Services/MonetizationService")
				service.Cosmetics = nil
				for _ = 1, 3 do
					service:Load(player)
					p = e.Data.Sanitize(p)
					assert(p.DisplaySlots == slots and p.Monetization.AppliedSlots == nil)
					assert(p.Monetization.Passes.ExtraSlots == nil)
					if occupied then
						assert(p.Displays[tostring(slots)] == "Rat")
					end
				end
				e.Data.Profiles[player] = p
				local rebirth = e:Load("src/shared/Config/Rebirth")
				p.RunFlushes, p.Coins = rebirth.RequiredFlushes, rebirth.Levels[1].RequiredCoins
				e:Fire("Rebirth", player, 0)
				p = e.Data:Get(player)
				assert(p.RebirthLevel == 1 and p.DisplaySlots == slots)
				e.Data:Close(player)
				player.Parent = nil
				local _, restored = e:Join(1140)
				assert(restored.DisplaySlots == slots)
				if occupied then
					assert(restored.Displays[tostring(slots)] == "Rat")
				end
			end
		)
	end
end

test("free slots: coin upgrades and index claims still reach ten without passes", function()
	local e, _, p, commerce = catalogPlayer(1150)
	local upgrades = commerce.Income.Upgrades
	p.Coins = 1e9
	for level = 0, 6 do
		assert(upgrades:Buy(p, "DisplaySlots", level))
		assert(p.DisplaySlots == 4 + level)
	end
	assert(p.DisplaySlots == 10 and not upgrades:Buy(p, "DisplaySlots", 7))
	local items, config = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/IndexRewards")
	local index = e:Load("src/shared/IndexProgress").new(items, config, upgrades)
	for _, reward in ipairs(config.Milestones) do
		if reward.DisplaySlots then
			local fresh = e.Data.DefaultProfile()
			for _, item in ipairs(items) do
				fresh.Collection[item.Id] = 1
			end
			fresh.Upgrades.DisplaySlots = 2
			assert(index:Claim(fresh, "total:" .. reward.Count).Success)
			assert(fresh.DisplaySlots == reward.DisplaySlots + 2)
			local restored = e.Data.Sanitize(fresh)
			assert(restored.DisplaySlots == fresh.DisplaySlots)
		end
	end
end)
