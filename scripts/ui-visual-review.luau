-- Independent review: inspect actual trees, including scrolled content and touch targets.
do
	H.UseCommerceIds(true)
	local previousInfo = H.Services.MarketplaceService.GetProductInfoAsync
	H.Services.MarketplaceService.GetProductInfoAsync = function()
		return { IsForSale = true, PriceInRobux = 49 }
	end
	local C = H.Load("src/client/UI/Components")
	local items = H.Load("src/shared/Config/Items")
	local review = table.clone(state)
	review.TutorialDone, review.TutorialStep = true, 5
	review.Coins, review.PendingCoins = 1.23e100, 1.23e45
	review.RunFlushes, review.LifetimeFlushes = 1000, 1000
	review.Collection, review.Inventory, review.Displays = {}, {}, {}
	review.OwnedPasses = { CustomPlotColor = true, VIPPack = true, DancePack = true }
	review.Settings = { MusicVolume = 0.6, SFXVolume = 0.7 }
	for _, item in ipairs(items) do
		review.Collection[item.Id], review.Inventory[item.Id] = 1, 10
	end
	local odds =
		{ Token = "review", BaseLuck = 2.5, Luck = 10, VIPLuck = true, DoubleLuck = true, Items = {}, Rarities = {} }
	local roll = H.Load("src/server/Services/RollService")
	local toilets = H.Load("src/shared/Config/Toilets")
	local normal, boosted = roll.Distribution(items, toilets, 1, 2.5), roll.Distribution(items, toilets, 1, 10)
	for i, entry in ipairs(normal) do
		local item = entry.Item
		table.insert(odds.Items, {
			Id = item.Id,
			Name = item.Name,
			Rarity = item.Rarity,
			BaseChance = item.Chance,
			Fallback = item.Id == "Poop",
			Normal = entry.Probability,
			Boosted = boosted[i].Probability,
		})
		local sum = odds.Rarities[item.Rarity] or { Normal = 0, Boosted = 0 }
		sum.Normal += entry.Probability
		sum.Boosted += boosted[i].Probability
		odds.Rarities[item.Rarity] = sum
	end
	review.Commerce = {
		Quotes = { Coins10Minutes = 1.23e45, Coins1Hour = 7.38e45, Coins6Hours = 4.42e46, Coins24Hours = 1.77e47 },
		Lucky = { Allowed = true, PolicyRemaining = 1200, Count = 3, Odds = odds },
	}
	local function visible(object)
		while object and object ~= clientRoot do
			if object:IsA("GuiObject") and not object.Visible then
				return false
			end
			object = object.Parent
		end
		return true
	end
	local function capture(name, viewport)
		H.Layout(clientRoot)
		H.Services.RunService.Heartbeat:Fire(0.1)
		for _, object in ipairs(clientRoot:GetDescendants()) do
			if visible(object) and (object:IsA("GuiButton") or object:IsA("TextBox")) then
				assert(
					object.AbsoluteSize.X >= 44 and object.AbsoluteSize.Y >= 44,
					"Review touch target below 44px: " .. object.Name .. " in " .. name
				)
			end
		end
		H.Snapshot(clientRoot, "review-" .. name:gsub("[^%w%-]", "-") .. "-" .. viewport[1] .. "x" .. viewport[2])
	end
	local function scrollTo(object)
		H.Layout(clientRoot)
		C.ScrollTo(object)
		H.Layout(clientRoot)
	end
	local function resetScroll(panel)
		for _, object in ipairs(panel:GetDescendants()) do
			if object:IsA("ScrollingFrame") then
				object.CanvasPosition = Vector2.new()
			end
		end
	end
	clientRoot.ModalBackdrop.Activated:Fire()
	bootRemotes.State.OnClientEvent:Fire(review)
	H.StartTasks()
	-- Let the preceding suite's six-second tutorial farewell expire before window captures.
	H.Advance(6.1)
	for _, viewport in ipairs(H.Viewports) do
		H.Services.UserInputService.TouchEnabled = viewport[1] < 1200
		clientRoot._fixed, clientRoot._abs = { X = viewport[1], Y = viewport[2] }, nil
		clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Advance(0.3)
		clientRoot.HUD.Wallet.NumberValue.Changed:Fire(review.Coins)
		capture("hud-huge", viewport)
		if reviewHUDOnly then
			local breakdown = clientRoot.HUD:FindFirstChild("LuckBreakdown", true)
			review.Commerce.Lucky.Allowed = false
			bootRemotes.State.OnClientEvent:Fire(review)
			clientRoot.HUD:FindFirstChild("LuckInfo", true).Activated:Fire()
			H.Layout(clientRoot)
			assert(breakdown.Visible and breakdown.AbsolutePosition.X >= 0 and breakdown.AbsolutePosition.Y >= 0)
			assert(breakdown.AbsolutePosition.X + breakdown.AbsoluteSize.X <= viewport[1])
			assert(breakdown.AbsolutePosition.Y + breakdown.AbsoluteSize.Y <= viewport[2])
			for _, button in ipairs({ clientRoot.HUD.SocialBoostsChip, clientRoot.HUD.FlushActions }) do
				if button then
					local p, s, bp, bs =
						breakdown.AbsolutePosition, breakdown.AbsoluteSize, button.AbsolutePosition, button.AbsoluteSize
					assert(
						p.X + s.X <= bp.X or bp.X + bs.X <= p.X or p.Y + s.Y <= bp.Y or bp.Y + bs.Y <= p.Y,
						"Luck disclosure overlaps action controls"
					)
				end
			end
			capture("luck-unavailable", viewport)
			breakdown.Visible = false
			review.Commerce.Lucky.Allowed = true
			bootRemotes.State.OnClientEvent:Fire(review)
			local shop, upgrades = clientRoot.HUD.Shop, clientRoot.HUD.Upgrades
			local panel = clientRoot["Toilet Upgrades"]
			for _, entry in ipairs({ { shop, "shop" }, { upgrades, "upgrades" } }) do
				entry[1].Activated:Fire()
				capture(entry[2], viewport)
				local target = if entry[2] == "shop"
					then panel.ContentScroll.Body.ToiletCards[toilets[review.ToiletTier + 1].Id].Locked
					else panel.ContentScroll.Body.PermanentUpgradeTracks.CashBoost.Buy
				scrollTo(target)
				capture(entry[2] .. "-action", viewport)
				bootRemotes.Result.OnClientEvent:Fire(
					"BuyUpgrade",
					{ Success = true, Message = "Permanent upgrade purchased!" }
				)
				capture("result-toast", viewport)
				clientRoot.ModalBackdrop.Activated:Fire()
				H.Advance(3)
			end
			clientRoot.HUD.Daily.Activated:Fire()
			local daily = clientRoot["Daily Rewards"]
			resetScroll(daily)
			capture("daily", viewport)
			scrollTo(daily:FindFirstChild("Loading...", true))
			capture("daily-action", viewport)
			clientRoot.ModalBackdrop.Activated:Fire()
			continue
		end
		local info = clientRoot.HUD:FindFirstChild("LuckInfo", true)
		info.Activated:Fire()
		local dialog = clientRoot["Luck details"]
		assert(dialog.Visible and not clientRoot.HUD:FindFirstChild("LuckBreakdown", true).Visible)
		capture("odds-top", viewport)
		scrollTo(dialog.ContentScroll.Body.RarityOdds)
		capture("odds-rarities", viewport)
		scrollTo(dialog.ContentScroll.Body.Poop)
		capture("odds-last", viewport)
		dialog.Visible = false
		for _, name in ipairs({ "My Collection", "Settings", "REBIRTH", "Passes & Style" }) do
			local panel = clientRoot[name]
			resetScroll(panel)
			panel.Visible = true
			H.StartTasks()
			capture(name, viewport)
			if name == "My Collection" then
				local slots = panel:FindFirstChild("Slots", true)
				local card = panel:FindFirstChild("Poop", true)
				assert(slots.AbsolutePosition.Y + slots.AbsoluteSize.Y <= card.Parent.AbsolutePosition.Y)
				for _, item in ipairs(items) do
					local entry = panel:FindFirstChild(item.Id, true)
					assert(entry and entry:FindFirstChild("Preview"), "Missing collection icon " .. item.Id)
				end
				scrollTo(panel:FindFirstChild("Mystery", true)["Put Back"])
				capture("collection-last", viewport)
			elseif name == "Settings" then
				scrollTo(panel:FindFirstChild("SFXAudio", true).SFXPreview)
				capture("settings-sfx", viewport)
				scrollTo(panel:FindFirstChild("ReplayTutorial", true))
				capture("settings-replay", viewport)
			elseif name == "REBIRTH" then
				scrollTo(panel:FindFirstChild("Confirm", true))
				capture("rebirth-action", viewport)
			else
				for _, key in ipairs({ "VIPPack", "DoubleLuck" }) do
					scrollTo(panel:FindFirstChild("OfferGrid", true)[key].OddsInfo)
					capture("pass-" .. key, viewport)
				end
				scrollTo(panel:FindFirstChild("PlotColor_Default", true))
				capture("plot-colors", viewport)
				panel:FindFirstChild("BoostsTab", true).Activated:Fire()
				for _, key in ipairs({ "Coins10Minutes", "Coins1Hour", "Coins6Hours", "Coins24Hours" }) do
					scrollTo(panel:FindFirstChild("BoostGrid", true)[key].OfferCard.Buy)
					capture(key, viewport)
				end
				panel:FindFirstChild("PassesTab", true).Activated:Fire()
			end
			panel.Visible = false
		end
	end
	bootRemotes.State.OnClientEvent:Fire(state)
	H.Services.MarketplaceService.GetProductInfoAsync = previousInfo
	H.UseCommerceIds(false)
	print("Independent visual review: all controls >=44px, collection icons and scrolled windows at 12 viewports")
end
