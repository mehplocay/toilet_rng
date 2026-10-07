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

test("wired products: prompts and durable receipts map every enabled product; zero Lucky cannot grant", function()
	local e = server()
	local player, p = e:Join(1301)
	local service = e:Load("src/server/Services/MonetizationService")
	local config = e:Load("src/shared/Config/Monetization")
	local receipts = service.Commerce.Receipts
	for _, key in ipairs(config.ProductOrder) do
		local product = config.DeveloperProducts[key]
		local coins, expires, count = p.Coins, p.Monetization.PathExpires, #p.Monetization.Receipts
		e.Now += 10 -- Respect BuyProduct's one-token / 0.1-per-second limiter.
		e.Marketplace.LastProduct = nil
		local quote = receipts:Quote(p, key)
		e:Fire("BuyProduct", player, key, quote)
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
			assert(not service.Commerce.Prompting[player], "Completion did not release prompt: " .. key)
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
			p = e.Data:Get(player)
			assert(#p.Monetization.Receipts == count + 1 and not p.Monetization.Quote)
			if product.IncomeSeconds then
				assert(p.Coins == coins + quote and p.Monetization.PathExpires == expires)
			else
				assert(p.Coins == coins and p.Monetization.PathExpires == e.Now + product.Duration)
			end
			assert(e.Store.Records.Player_1301.Data.Coins == p.Coins)
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted" and e.Data:Get(player) == p)
		end
	end
end)
