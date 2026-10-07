do
	local config = H.Load("src/shared/Config/Monetization")
	local format = H.Load("src/shared/NumberFormat")
	local Passes = H.Load("src/client/UI/Passes")
	local oldInfo = H.Services.MarketplaceService.GetProductInfoAsync
	H.Services.MarketplaceService.GetProductInfoAsync = function()
		return { IsForSale = true, PriceInRobux = 49 }
	end
	local root, remotes = H.Root(390, 722), H.Remotes()
	local passes = Passes.Create(root, remotes)
	local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
		Near = function()
			return true
		end,
	})
	local chip = H.Load("src/client/UI/IncomeChip").Create(root)
	local grid = passes.Panel:FindFirstChild("BoostGrid", true)
	passes.Panel.Visible = true
	passes.Panel:FindFirstChild("BoostsTab", true).Activated:Fire()
	local durations = {
		Coins10Minutes = "= 10 minutes of income",
		Coins1Hour = "= 1 hour of income",
		Coins6Hours = "= 6 hours of income",
		Coins24Hours = "= 24 hours of income",
	}
	local savedIds = {}
	for key in pairs(durations) do
		savedIds[key] = config.DeveloperProducts[key].Id
		config.DeveloperProducts[key].Id = 999
	end
	H.StartTasks()
	for _, amount in ipairs({ 1e18, 1.23e45, 1.23e100, 1.23e290, 1e300 }) do
		local quotes = {}
		for key in pairs(durations) do
			quotes[key] = math.min(1e300, amount / 100000 * config.DeveloperProducts[key].IncomeSeconds)
		end
		local state = {
			Coins = amount,
			PendingCoins = amount / 6000,
			ToiletTier = 15,
			LifetimeFlushes = 300,
			RunFlushes = 300,
			RebirthLevel = 0,
			Settings = {},
			OwnedPasses = {},
			Commerce = { Quotes = quotes },
		}
		passes.Update(state)
		hud.Update(state)
		chip.Update(state.PendingCoins)
		root.HUD.Wallet.NumberValue.Changed:Fire(amount)
		local seen = {}
		for key, duration in pairs(durations) do
			local card = grid[key].OfferCard
			assert(card.Description.Text == duration)
			assert(card.OfferStatus.Text == format.Compact(quotes[key]) .. " Coins")
			assert(not seen[card.OfferStatus.Text], "Pack amounts collapsed to the same label")
			seen[card.OfferStatus.Text] = true
		end
		for _, viewport in ipairs(H.Viewports) do
			root._fixed, root._abs = { X = viewport[1], Y = viewport[2] }, nil
			root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
			H.Layout(root)
			for key in pairs(durations) do
				local card = grid[key].OfferCard
				for _, label in ipairs({ card.Description, card.OfferStatus }) do
					assert(
						label.TextScaled and label.AbsoluteSize.X >= #label.Text * 6,
						"Huge pack label cannot fit at minimum font size"
					)
					assert(label.AbsolutePosition.X >= card.AbsolutePosition.X)
					assert(
						label.AbsolutePosition.X + label.AbsoluteSize.X <= card.AbsolutePosition.X + card.AbsoluteSize.X
					)
				end
			end
		end
	end
	for key, id in pairs(savedIds) do
		config.DeveloperProducts[key].Id = id
	end
	H.Services.MarketplaceService.GetProductInfoAsync = oldInfo
	root:Destroy()
	print(
		"Huge coin UI passed: distinct pack amounts and duration labels, wallet/pending, five magnitudes at all 12 viewports"
	)
end
