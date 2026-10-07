do
	H.StartTasks()
	H.UseCommerceIds(true)
	H.Services.MarketplaceService = H.Services.MarketplaceService or {}
	local config = H.Load("src/shared/Config/Monetization")
	config.Gamepasses.DoubleLuck.Id = 0 -- Explicit unavailable-offer fixture.
	local original = H.Services.MarketplaceService.GetProductInfoAsync
	H.Services.MarketplaceService.GetProductInfoAsync = function()
		return { IsForSale = true, PriceInRobux = 399 }
	end
	local root, remotes = H.Root(390, 722), H.Remotes()
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local grid = ui.Panel:FindFirstChild("OfferGrid", true)
	local ribbon
	for _, object in ipairs(grid.DoubleLuck:GetDescendants()) do
		if object:IsA("TextLabel") and object.Text == "2x" then
			ribbon = object
		end
	end
	assert(ribbon, "2x fallback ribbon label missing")
	for _, sibling in ipairs(ribbon.Parent:GetChildren()) do
		if sibling:IsA("Frame") then
			assert(ribbon.ZIndex > sibling.ZIndex, "2x label hidden behind ribbon")
		end
	end
	local odds = {
		Token = "VIPPack:1:1:1.25",
		BaseLuck = 1,
		Luck = 1.25,
		Offer = "VIPPack",
		VIPLuck = false,
		DoubleLuck = false,
		Items = { { Name = "Poop", Rarity = "Common", Fallback = true, Normal = 0.8, Boosted = 0.75 } },
		Rarities = { Common = { Normal = 0.8, Boosted = 0.75 } },
	}
	local lucky = {
		Allowed = true,
		PolicyRemaining = 120,
		Count = 0,
		FreeLuck = 1,
		Odds = odds,
		PassOdds = { VIPPack = odds, DoubleLuck = odds, UltimateBundle = odds },
	}
	local state = { OwnedPasses = {}, Settings = {}, Commerce = { Quotes = {}, Lucky = lucky } }
	ui.Update(state)
	ui.Panel.Visible = true
	H.StartTasks()
	assert(grid.DoubleLuck.OfferCard.Buy.Text == "Coming soon" and not grid.DoubleLuck.OfferCard.Buy.Interactable)
	assert(
		grid.VIPPack.Perks.Text:find("+25% luck", 1, true)
			and grid.VIPPack.Perks.Text:find("random-item odds boost", 1, true)
	)
	local before = #H.Calls
	grid.VIPPack.OfferCard.Buy.Activated:Fire()
	local dialog = root:FindFirstChild("Lucky Flush odds")
	assert(dialog.Visible and #H.Calls == before)
	dialog:FindFirstChild("ConfirmLucky", true).Activated:Fire()
	assert(H.Calls[#H.Calls].Name == "BuyPass" and H.Calls[#H.Calls].Args[2] == odds.Token)
	config.Gamepasses.DoubleLuck.Id = 18002
	ui.Panel.Visible = false
	ui.Panel.Visible = true
	H.StartTasks()
	ui.Update(state)
	assert(grid.DoubleLuck.OfferCard.Buy.Interactable)
	state.OwnedPasses = { UltimateBundle = true }
	ui.Update(state)
	assert(grid.DoubleLuck.OfferCard.Buy.Text == "Owned")
	for _, mode in ipairs({ "restricted", "failed", "expired", "missing" }) do
		state.Commerce.Lucky = table.clone(lucky)
		ui.Update(state)
		grid.VIPPack.OddsInfo.Activated:Fire()
		if mode == "expired" then
			H.Advance(121)
		else
			state.Commerce.Lucky = if mode == "missing" then nil else { Allowed = false, Count = 0 }
			ui.Update(state)
		end
		assert(not dialog.Visible)
		assert(grid.VIPPack.Perks.Text:find("unavailable in your region", 1, true))
		assert(not grid.VIPPack.Perks.Text:find("+25%", 1, true))
		assert(not grid.DoubleLuck.OddsInfo.Interactable)
	end
	config.Gamepasses.DoubleLuck.Id = 0
	H.Services.MarketplaceService.GetProductInfoAsync = original
	root:Destroy()
	H.UseCommerceIds(false)
	print("Paid luck UI: pass disclosure, reviewed purchase, pending ID, bundle and regional expiry passed")
end

do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
		Near = function()
			return true
		end,
	})
	local lucky = {
		Allowed = true,
		PolicyRemaining = 120,
		Count = 0,
		FreeLuck = 1,
		Odds = {
			Token = "Lucky:1:2.5:10",
			BaseLuck = 2.5,
			Luck = 10,
			VIPLuck = true,
			DoubleLuck = true,
			Items = {},
			Rarities = {},
		},
	}
	local state = {
		Coins = 0,
		ToiletTier = 1,
		RebirthLevel = 0,
		RunFlushes = 0,
		LifetimeFlushes = 0,
		LastClaimDay = 0,
		Streak = 0,
		Commerce = { Lucky = lucky },
		UpgradeStats = { LuckMultiplier = 2.5 },
	}
	hud.Update(state)
	H.StartTasks()
	H.Advance(1.01)
	H.ResumeTasks()
	local chip = root.HUD:FindFirstChild("TotalLuck", true)
	local breakdown = root.HUD:FindFirstChild("LuckBreakdown", true)
	assert(chip.Text == "Luck x2.5")
	assert(breakdown.Text:find("VIP +25% luck", 1, true) and breakdown.Text:find("2x Luck pass", 1, true))
	lucky.Count, lucky.Armed = 1, true
	hud.Update(state)
	H.Advance(1.01)
	H.ResumeTasks()
	assert(chip.Text == "Luck x10 (cap)")
	H.Advance(121)
	H.ResumeTasks()
	assert(chip.Text == "Luck x1" and breakdown.Text:find("unavailable in your region", 1, true))
	root:Destroy()
	print("Paid luck HUD: true active multipliers, charge cap and expired policy passed")
end
