do
	H.StartTasks() -- Drain earlier suites' queued refreshes before selecting shipped IDs.
	H.UseCommerceIds(true)
	H.Services.MarketplaceService = H.Services.MarketplaceService or {}
	local original = H.Services.MarketplaceService.GetProductInfoAsync
	local config = H.Load("src/shared/Config/Monetization")
	local expected, queries = {}, {}
	for group, kind in pairs({ Gamepasses = "InfoType.GamePass", DeveloperProducts = "InfoType.Product" }) do
		for key, offer in pairs(config[group]) do
			if offer.Id > 0 then
				expected[offer.Id] = { Key = key, Kind = kind, Price = offer.Price + 1 }
			end
		end
	end
	H.Services.MarketplaceService.GetProductInfoAsync = function(_, id, kind)
		queries[id] = (queries[id] or 0) + 1
		assert(id > 0 and expected[id] and expected[id].Kind == kind, "Wrong metadata ID/type")
		return { IsForSale = true, PriceInRobux = expected[id].Price }
	end
	local root, remotes = H.Root(390, 722), H.Remotes()
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local state = {
		Settings = {},
		OwnedPasses = {},
		Commerce = { Quotes = {}, Lucky = { Allowed = true, Count = 0, PolicyRemaining = 120 } },
	}
	local roll = H.Load("src/server/Services/RollService")
	local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
	local normal, boosted = roll.Distribution(items, toilets, 1, 1), roll.Distribution(items, toilets, 1, 10)
	local odds = { Token = "1:1:10", Items = {}, Rarities = {} }
	for i, row in ipairs(normal) do
		local item = row.Item
		odds.Items[i] = {
			Id = item.Id,
			Name = item.Name,
			Rarity = item.Rarity,
			Normal = row.Probability,
			Boosted = boosted[i].Probability,
		}
		local sum = odds.Rarities[item.Rarity] or { Normal = 0, Boosted = 0 }
		sum.Normal += row.Probability
		sum.Boosted += boosted[i].Probability
		odds.Rarities[item.Rarity] = sum
	end
	state.Commerce.Lucky.Odds = odds
	state.Commerce.Lucky.PassOdds = { VIPPack = odds, DoubleLuck = odds, UltimateBundle = odds }
	for key, offer in pairs(config.DeveloperProducts) do
		if offer.Id > 0 then
			state.Commerce.Quotes[key] = if offer.IncomeSeconds then 4321 else 0
		end
	end
	ui.Update(state)
	ui.Panel.Visible = true
	H.StartTasks()
	for group, grid in pairs({ Gamepasses = "OfferGrid", DeveloperProducts = "BoostGrid" }) do
		for key, offer in pairs(config[group]) do
			local card = ui.Panel:FindFirstChild(if offer.LuckyCharges then "LuckyGrid" else grid, true)[key].OfferCard
			local before = #H.Calls
			if offer.Id == 0 then
				assert(card.Buy.Text == "Coming soon" and card.OfferStatus.Text == "Not on sale yet")
				assert(not card.Buy.Interactable and not queries[0])
				card.Buy.Activated:Fire()
				assert(#H.Calls == before, "Zero-ID Lucky offer sent a purchase request")
			else
				assert(
					queries[offer.Id] == 1 and card.Buy.Interactable,
					"Wrong price state/count: " .. key .. "/" .. tostring(queries[offer.Id])
				)
				assert(card.Buy.Text == tostring(expected[offer.Id].Price), "Configured price replaced platform price")
				assert(card.OfferStatus.Text ~= "Not on sale yet")
				card.Buy.Activated:Fire()
				if offer.LuckyCharges or offer.PaidLuck then
					local dialog = root:FindFirstChild("Lucky Flush odds")
					assert(dialog.Visible and #H.Calls == before, "Wired Lucky purchase bypassed odds review")
					dialog:FindFirstChild("ConfirmLucky", true).Activated:Fire()
				end
				local call = H.Calls[#H.Calls]
				assert(#H.Calls == before + 1 and call.Args[1] == key)
				assert(call.Name == (if group == "Gamepasses" then "BuyPass" else "BuyProduct"))
				if group == "DeveloperProducts" then
					assert(call.Args[2] == state.Commerce.Quotes[key])
					if offer.LuckyCharges then
						assert(call.Args[3] == odds.Token)
					end
				end
			end
		end
	end
	local body, grid = ui.Panel.ContentScroll.Body, ui.Panel:FindFirstChild("LuckyGrid", true)
	for _, mode in ipairs({ "restricted", "failed", "expired" }) do
		state.Commerce.Lucky = { Allowed = true, Count = 1, Odds = odds, PolicyRemaining = 120 }
		ui.Update(state)
		body.LuckyTab.Activated:Fire()
		ui.Panel:FindFirstChild("UseLucky", true).Activated:Fire()
		assert(grid.Visible and root:FindFirstChild("Lucky Flush odds").Visible)
		local before = #H.Calls
		if mode == "expired" then
			H.Advance(121)
		else
			-- Restricted and failed server lookups both publish a fail-closed snapshot.
			state.Commerce.Lucky = { Allowed = false, Count = 1, PolicyRemaining = 0 }
			ui.Update(state)
		end
		assert(not body.LuckyTab.Visible and not grid.Visible and not root:FindFirstChild("Lucky Flush odds").Visible)
		body.LuckyTab.Activated:Fire()
		for _, key in ipairs({ "LuckyFlush1", "LuckyFlush5", "LuckyFlush20" }) do
			assert(not grid[key].OfferCard.Buy.Interactable)
			grid[key].OfferCard.Buy.Activated:Fire()
		end
		root:FindFirstChild("Lucky Flush odds"):FindFirstChild("ConfirmLucky", true).Activated:Fire()
		assert(#H.Calls == before and not grid.Visible, "Ineligible wired Lucky offer requested purchase/use")
	end
	state.Commerce.Lucky = { Allowed = true, Count = 0, Odds = odds, PolicyRemaining = 120 }
	H.UseCommerceIds(false)
	ui.Update(state)
	local before = #H.Calls
	for _, key in ipairs({ "LuckyFlush1", "LuckyFlush5", "LuckyFlush20" }) do
		local card = grid[key].OfferCard
		assert(card.Buy.Text == "Coming soon" and not card.Buy.Interactable)
		card.Buy.Activated:Fire()
	end
	assert(#H.Calls == before and not queries[0], "Zero-ID fixture queried a price or offered purchase")
	H.UseCommerceIds(true)
	state.OwnedPasses = { UltimateBundle = true }
	ui.Update(state)
	for _, key in ipairs(config.PassOrder) do
		local card = ui.Panel:FindFirstChild("OfferGrid", true)[key].OfferCard
		if config.Gamepasses[key].Id == 0 then
			assert(card.Buy.Text == "Coming soon" and not card.Buy.Interactable and not card.CheckIcon.Visible)
		else
			assert(card.Buy.Text == "Owned" and not card.Buy.Interactable and card.CheckIcon.Visible)
		end
	end
	assert(ui.Panel:FindFirstChild("BoostGrid", true).Coins10Minutes.OfferCard.Buy.Interactable)
	root:Destroy()
	H.Services.MarketplaceService.GetProductInfoAsync = original
	H.UseCommerceIds(false)
end
print(
	"Wired catalog UI passed: all 23 production price mappings, reviewed Lucky purchases, policy hiding and bundle states"
)
