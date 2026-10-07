function H.CheckPurchaseUI()
	H.StartTasks()
	H.UseCommerceIds(true)
	H.Services.MarketplaceService = H.Services.MarketplaceService or {}
	local marketplace = H.Services.MarketplaceService
	local original = marketplace.GetProductInfoAsync
	marketplace.GetProductInfoAsync = function()
		return { IsForSale = true, PriceInRobux = 25 }
	end
	local root, remotes = H.Root(390, 722), H.Remotes()
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local config = H.Load("src/shared/Config/Monetization")
	local body = ui.Panel.ContentScroll.Body
	local grid = ui.Panel:FindFirstChild("LuckyGrid", true)
	local dialog = root:FindFirstChild("Lucky Flush odds")
	local confirm = dialog:FindFirstChild("ConfirmLucky", true)
	local use = ui.Panel:FindFirstChild("UseLucky", true)
	local odds = { Token = "1:1:10", Items = {}, Rarities = {} }
	local state = {
		Settings = {},
		OwnedPasses = {},
		Commerce = { Quotes = {}, Lucky = { Allowed = true, PolicyRemaining = 120, Count = 0, Odds = odds } },
	}
	ui.Update(state)
	ui.Panel.Visible = true
	H.StartTasks()
	body.LuckyTab.Activated:Fire()
	for _, key in ipairs({ "LuckyFlush1", "LuckyFlush5", "LuckyFlush20" }) do
		grid[key].OfferCard.Buy.Activated:Fire()
		assert(
			dialog.Visible and body.PurchaseStatus.Text ~= "Preparing your purchase...",
			"Review started request timeout before confirmation"
		)
		confirm.Activated:Fire()
		assert(body.PurchaseStatus.Text == "Preparing your purchase...")
		state.Commerce.PendingProduct, state.Commerce.CanResume = key, false
		ui.Update(state)
		assert(body.LuckyTab.Visible and grid.Visible and not grid[key].OfferCard.Buy.Interactable)
		remotes.Result.OnClientEvent:Fire(
			"BuyProduct",
			{ Success = true, Message = "Complete or close the Roblox purchase prompt." }
		)
		state.Commerce.CanResume = true
		ui.Update(state)
		assert(grid[key].OfferCard.Buy.Interactable)
		state.Commerce.PendingProduct = nil
		state.Commerce.Lucky.Count += config.DeveloperProducts[key].LuckyCharges
		state.Commerce.CanResume = false -- A receipt can sync before prompt closure.
		ui.Update(state)
		assert(not grid[key].OfferCard.Buy.Interactable and body.LuckyTab.Visible)
		state.Commerce.CanResume = true
		ui.Update(state)
		assert(body.LuckyTab.Visible and grid.Visible and use.Interactable)
		assert(grid[key].OfferCard.OfferStatus.Text == tostring(state.Commerce.Lucky.Count) .. " Lucky Flushes owned")
		use.Activated:Fire()
		assert(confirm.Interactable and confirm.Text == "Use on next flush")
		state.Commerce.Lucky.Armed = true
		ui.Update(state)
		assert(
			dialog.Visible and not confirm.Interactable and confirm.Text == "Ready for next flush",
			"Open review did not update armed state"
		)
		state.Commerce.Lucky.Armed = false
		state.Commerce.Lucky.Count -= 1
		ui.Update(state)
		assert(body.LuckyTab.Visible and grid.Visible and confirm.Interactable == (state.Commerce.Lucky.Count > 0))
		dialog.Visible = false
	end
	local boostGrid = ui.Panel:FindFirstChild("BoostGrid", true)
	for _, key in ipairs({ "Coins10Minutes", "Coins1Hour", "Coins6Hours", "Coins24Hours", "PathBoost10Minutes" }) do
		local card = boostGrid[key].OfferCard
		card.Buy.Activated:Fire()
		state.Commerce.PendingProduct, state.Commerce.CanResume = key, false
		ui.Update(state)
		assert(not card.Buy.Interactable)
		remotes.Result.OnClientEvent:Fire(
			"BuyProduct",
			{ Success = false, Message = "Purchases are temporarily unavailable. Please try again in a moment." }
		)
		assert(
			body.PurchaseMessage.Text:find("temporarily unavailable", 1, true)
				and body.PurchaseStatus.Text ~= "Preparing your purchase..."
		)
		state.Commerce.PendingProduct, state.Commerce.CanResume = nil, true
		state.Commerce.Quotes[key] = 9876
		ui.Update(state)
		assert(card.Buy.Interactable)
		if config.DeveloperProducts[key].IncomeSeconds then
			assert(card.OfferStatus.Text == H.Load("src/client/UI/Components").Commas(9876) .. " Coins")
		end
	end
	-- Both ordinary requests and confirmed Lucky requests recover with no server answer.
	for _, key in ipairs({ "Coins10Minutes", "LuckyFlush5" }) do
		local card = (if config.DeveloperProducts[key].LuckyCharges then grid else boostGrid)[key].OfferCard
		card.Buy.Activated:Fire()
		if config.DeveloperProducts[key].LuckyCharges then
			confirm.Activated:Fire()
		end
		assert(body.PurchaseStatus.Text == "Preparing your purchase...")
		H.Advance(9)
		ui.Update(state) -- An unrelated sync must not erase the pending deadline.
		assert(body.PurchaseStatus.Text == "Preparing your purchase...")
		H.Advance(1)
		assert(
			body.PurchaseStatus.Text ~= "Preparing your purchase..."
				and body.PurchaseMessage.Text:find("try again", 1, true)
		)
	end
	boostGrid.Coins10Minutes.OfferCard.Buy.Activated:Fire()
	remotes.Result.OnClientEvent:Fire("BuyProduct", { Message = "Purchase canceled." })
	H.Advance(10)
	assert(body.PurchaseMessage.Text == "Purchase canceled.", "Completed request later timed out")
	state.OwnedPasses = {}
	for _, key in ipairs(config.PassOrder) do
		state.OwnedPasses[key] = true
	end
	ui.Update(state)
	body["Refresh passes"].Activated:Fire()
	H.StartTasks()
	for _ = 1, 2 do
		ui.Update(state)
		for _, key in ipairs(config.PassOrder) do
			local card = ui.Panel:FindFirstChild("OfferGrid", true)[key].OfferCard
			assert(
				card.Buy.Text == "Owned"
					and not card.Buy.Interactable
					and card.CheckIcon.Visible
					and not card.LockIcon.Visible
			)
		end
	end
	for _, mode in ipairs({ "missing", "failed", "restricted", "expired", "missing-deadline" }) do
		state.Commerce.Lucky = { Allowed = true, Count = 5, Odds = odds, PolicyRemaining = 120 }
		ui.Update(state)
		body.LuckyTab.Activated:Fire()
		use.Activated:Fire()
		if mode == "missing" then
			state.Commerce.Lucky = nil
		elseif mode == "expired" then
			state.Commerce.Lucky.PolicyRemaining = 0
		elseif mode == "missing-deadline" then
			state.Commerce.Lucky.PolicyRemaining = nil
		else
			state.Commerce.Lucky.Allowed = false
		end
		ui.Update(state)
		assert(not body.LuckyTab.Visible and not grid.Visible and not dialog.Visible)
		local before = #H.Calls
		use.Activated:Fire()
		for _, key in ipairs({ "LuckyFlush1", "LuckyFlush5", "LuckyFlush20" }) do
			assert(not grid[key].OfferCard.Buy.Interactable)
			grid[key].OfferCard.Buy.Activated:Fire()
		end
		assert(#H.Calls == before and not dialog.Visible)
	end
	state.Commerce.Lucky = { Allowed = true, Count = 2, Odds = odds, PolicyRemaining = 120 }
	ui.Update(state) -- Rejoin / restored authoritative snapshot.
	assert(body.LuckyTab.Visible and use.Interactable)
	root:Destroy()
	marketplace.GetProductInfoAsync = original
	H.UseCommerceIds(false)
end
