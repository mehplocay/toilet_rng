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
				local call = H.Calls[#H.Calls]
				assert(#H.Calls == before + 1 and call.Args[1] == key)
				assert(call.Name == (if group == "Gamepasses" then "BuyPass" else "BuyProduct"))
				if group == "DeveloperProducts" then
					assert(call.Args[2] == state.Commerce.Quotes[key])
				end
			end
		end
	end
	state.OwnedPasses = { UltimateBundle = true }
	ui.Update(state)
	for _, key in ipairs(config.PassOrder) do
		local card = ui.Panel:FindFirstChild("OfferGrid", true)[key].OfferCard
		assert(card.Buy.Text == "Owned" and not card.Buy.Interactable and card.CheckIcon.Visible)
	end
	assert(ui.Panel:FindFirstChild("BoostGrid", true).Coins10Minutes.OfferCard.Buy.Interactable)
	root:Destroy()
	H.Services.MarketplaceService.GetProductInfoAsync = original
	H.UseCommerceIds(false)
end
print("Wired catalog UI passed: all 20 production price mappings, purchases, bundle states and disabled Lucky offers")
