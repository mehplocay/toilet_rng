-- Exercise the unmodified shipped mappings, independently of catalogPlayer's synthetic IDs.
test("wired passes: exact ownership IDs, prompts, callback mapping and bundle implication", function()
	local e = server()
	local config = e:Load("src/shared/Config/Monetization")
	local service = e:Load("src/server/Services/MonetizationService")
	local queries, prompts = {}, {}
	e.Marketplace.Lookup = function(userId, id)
		assert(userId == 1300 and id > 0)
		table.insert(queries, id)
		return false
	end
	e.Marketplace.PromptGamePassPurchase = function(_, player, id)
		assert(player.UserId == 1300)
		table.insert(prompts, id)
	end
	local player, p = e:Join(1300)
	assert(#queries == #config.PassOrder, "Wrong join query count: " .. #queries)
	for i, key in ipairs(config.PassOrder) do
		assert(queries[i] == config.Gamepasses[key].Id)
	end
	service.Cosmetics = nil -- Geometry/lifecycle is covered by the cosmetic UI harness.
	for _, key in ipairs(config.PassOrder) do
		e.Now += 5
		e:Fire("BuyPass", player, key)
		assert(prompts[#prompts] == config.Gamepasses[key].Id, "Missing/wrong prompt: " .. key)
		e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, config.Gamepasses[key].Id, false)
		assert(not service:EffectiveOwned(player)[key], "Canceled prompt granted " .. key)
	end
	e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, config.Gamepasses.UltimateBundle.Id, true)
	local paid = e:Load("src/shared/PaidBenefits")
	for _, key in ipairs(config.PassOrder) do
		assert(service:EffectiveOwned(player)[key] and paid.Owns(p, key))
	end
	assert(p.Coins == 0 and p.DisplaySlots == 3 and p.Monetization.LuckyFlushes == 0)
	assert(p.Monetization.PathExpires == 0 and service.Commerce.Income.Upgrades:Cash(p) == 3)
	local before = #prompts
	e.Now += 5
	e:Fire("BuyPass", player, "DoubleCash")
	assert(#prompts == before, "Bundle owner was prompted for an implied pass")
end)

for index, entry in ipairs({
	{ Key = "LuckyFlush1", Id = 3716998840, Charges = 1 },
	{ Key = "LuckyFlush5", Id = 3716998876, Charges = 5 },
	{ Key = "LuckyFlush20", Id = 3716998923, Charges = 20 },
}) do
	test("wired Lucky: prompt, receipt, credit, reviewed use and rejoin: " .. entry.Key, function()
		local e = server()
		local player, p = e:Join(1310 + index)
		local config = e:Load("src/shared/Config/Monetization")
		local lucky = e:Load("src/server/Services/LuckyService")
		assert(config.DeveloperProducts[entry.Key].Id == entry.Id)
		e:Fire("BuyProduct", player, entry.Key, 0, "forged")
		assert(not e.Marketplace.LastProduct and p.Monetization.LuckyFlushes == 0)
		e.Now += 10
		e:Fire("BuyProduct", player, entry.Key, 0, lucky:Odds(p).Token)
		assert(e.Marketplace.LastProduct.Id == entry.Id)
		assert(e.Data:Get(player).Monetization.LuckyFlushes == 0)
		e.Marketplace.PromptProductPurchaseFinished:Fire(player.UserId, entry.Id, true)
		assert(e.Data:Get(player).Monetization.LuckyFlushes == 0)
		local info = receipt(player, "wired-use-" .. entry.Key, entry.Id)
		assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
		p = e.Data:Get(player)
		assert(p.Monetization.LuckyFlushes == entry.Charges and #p.Monetization.Receipts == 1)
		assert(e.Store.Records["Player_" .. player.UserId].Data.Monetization.LuckyFlushes == entry.Charges)
		e:Fire("Flush", player)
		assert(p.Stats.Flushes == 0 and p.Monetization.LuckyFlushes == entry.Charges)
		e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
		e.Now += 5
		e:Fire("Flush", player)
		p = e.Data:Get(player)
		assert(p.Stats.Flushes == 1 and p.Monetization.LuckyFlushes == entry.Charges - 1)
		assert(not lucky.Armed[player])
		if entry.Charges > 1 then
			e.Now += 5
			e:Fire("Flush", player)
			assert(
				p.Stats.Flushes == 1 and p.Monetization.LuckyFlushes == entry.Charges - 1,
				"Next charge bypassed review"
			)
		end
		local items = 0
		for _, count in pairs(p.Inventory) do
			items += count
		end
		assert(items == 1 and p.Coins >= 0)
		assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted" and e.Data:Get(player) == p)
		e.Data:Close(player)
		player.Parent = nil
		e.Players.PlayerRemoving:Fire(player)
		local joined, restored = e:Join(1310 + index)
		assert(restored.Monetization.LuckyFlushes == entry.Charges - 1 and restored.Stats.Flushes == 1)
		assert(not lucky.Armed[joined] and e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
		assert(e.Data:Get(joined).Monetization.LuckyFlushes == entry.Charges - 1)
	end)
	for _, mode in ipairs({ "zero", "restricted", "failed", "missing", "expired", "capacity" }) do
		test("wired Lucky fails closed: " .. entry.Key .. "/" .. mode, function()
			local e = server()
			local config = e:Load("src/shared/Config/Monetization")
			if mode == "zero" then
				config.DeveloperProducts[entry.Key].Id = 0
			end
			if mode == "restricted" then
				e.PolicyLookup = function()
					return { ArePaidRandomItemsRestricted = true }
				end
			elseif mode == "failed" then
				e.PolicyError = true
			elseif mode == "missing" then
				e.PolicyLookup = function()
					return {}
				end
			end
			local player, p = e:Join(1320 + index)
			local lucky = e:Load("src/server/Services/LuckyService")
			if mode == "expired" then
				e.Now += config.PolicySeconds
			end
			if mode == "capacity" then
				p.Monetization.LuckyFlushes = config.LuckyFlushCap
			end
			local snapshot = lucky:Snapshot(player, p)
			if mode ~= "zero" and mode ~= "capacity" then
				assert(not snapshot.Allowed and not snapshot.Odds and snapshot.PolicyRemaining == 0)
				e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
				assert(not lucky.Armed[player])
			end
			local charges = p.Monetization.LuckyFlushes
			e:Fire("BuyProduct", player, entry.Key, 0, lucky:Odds(p).Token)
			assert(not e.Marketplace.LastProduct and not e.Data:Get(player).Monetization.Quote)
			assert(e.Marketplace.ProcessReceipt(receipt(player, "blocked-" .. mode, entry.Id)) == "NotProcessedYet")
			if mode == "zero" then
				assert(e.Marketplace.ProcessReceipt(receipt(player, "zero-id", 0)) == "NotProcessedYet")
			end
			assert(e.Data:Get(player).Monetization.LuckyFlushes == charges and #p.Monetization.Receipts == 0)
			if mode ~= "zero" and mode ~= "capacity" then
				p.Monetization.LuckyFlushes = 1 -- A previously credited charge must remain unusable under denied policy.
				e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
				e:Fire("Flush", player)
				assert(not lucky.Armed[player] and p.Monetization.LuckyFlushes == 1 and p.Stats.Flushes == 1)
			end
		end)
	end
end

test("wired products: prompts and durable receipts map every enabled product", function()
	local e = server()
	local player, p = e:Join(1301)
	local service = e:Load("src/server/Services/MonetizationService")
	local config = e:Load("src/shared/Config/Monetization")
	local receipts = service.Commerce.Receipts
	local lucky = e:Load("src/server/Services/LuckyService")
	for _, key in ipairs(config.ProductOrder) do
		local product = config.DeveloperProducts[key]
		local coins, expires, count, charges =
			p.Coins, p.Monetization.PathExpires, #p.Monetization.Receipts, p.Monetization.LuckyFlushes
		e.Now += 10 -- Respect BuyProduct's one-token / 0.1-per-second limiter.
		e.Marketplace.LastProduct = nil
		local quote = receipts:Quote(p, key)
		e:Fire("BuyProduct", player, key, quote, if product.LuckyCharges then lucky:Odds(p).Token else nil)
		local info = { PlayerId = player.UserId, ProductId = product.Id, PurchaseId = "wired-" .. key }
		if product.Id == 0 then
			assert(not e.Marketplace.LastProduct)
			assert(e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
			assert(p.Coins == coins and p.Monetization.PathExpires == expires)
			assert(#p.Monetization.Receipts == count and p.Monetization.LuckyFlushes == 0)
		else
			assert(
				e.Marketplace.LastProduct and e.Marketplace.LastProduct.Id == product.Id,
				"Missing/wrong prompt: " .. key
			)
			e.Marketplace.PromptProductPurchaseFinished:Fire(player.UserId, product.Id, true)
			assert(e.Data:Get(player).Monetization.LuckyFlushes == charges, "Prompt completion granted charges")
			assert(not service.Commerce.Prompting[player], "Completion did not release prompt: " .. key)
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
			p = e.Data:Get(player)
			assert(#p.Monetization.Receipts == count + 1 and not p.Monetization.Quote)
			if product.IncomeSeconds then
				assert(p.Coins == coins + quote and p.Monetization.PathExpires == expires)
			elseif product.Duration then
				assert(p.Coins == coins and p.Monetization.PathExpires == e.Now + product.Duration)
			else
				assert(p.Coins == coins and p.Monetization.PathExpires == expires)
				assert(p.Monetization.LuckyFlushes == charges + product.LuckyCharges)
			end
			assert(e.Store.Records.Player_1301.Data.Coins == p.Coins)
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted" and e.Data:Get(player) == p)
		end
	end
end)
