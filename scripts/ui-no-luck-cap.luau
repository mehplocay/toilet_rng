for _, luck in ipairs({ 1e3, 1e6, 1e12, 1e300, 1.79e307 }) do
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
	local roll = H.Load("src/server/Services/RollService")
	local ui = H.Load("src/client/UI/LuckyOdds").Create(root, remotes)
	local odds = {
		Token = tostring(luck),
		BaseLuck = luck,
		Luck = luck * 10,
		Items = {},
		Rarities = {},
		VIPLuck = true,
		DoubleLuck = true,
	}
	local normal, boosted = roll.Distribution(items, toilets, 1, luck), roll.Distribution(items, toilets, 1, luck * 10)
	for i, entry in ipairs(normal) do
		local item = entry.Item
		odds.Items[i] = {
			Id = item.Id,
			Name = item.Name,
			Rarity = item.Rarity,
			BaseChance = item.Chance,
			Fallback = item.Id == "Poop",
			Normal = entry.Probability,
			Boosted = boosted[i].Probability,
		}
		local sum = odds.Rarities[item.Rarity] or { Normal = 0, Boosted = 0 }
		sum.Normal += entry.Probability
		sum.Boosted += boosted[i].Probability
		odds.Rarities[item.Rarity] = sum
	end
	local format = H.Load("src/client/UI/LuckyOdds")
	local numberFormat = H.Load("src/shared/NumberFormat")
	for _, key in ipairs({ "Normal", "Boosted" }) do
		local labels, units = format.Column(odds.Items, key)
		local total, parsed = 0, 0
		for i, row in ipairs(odds.Items) do
			total += units[i]
			local shown = assert(tonumber(labels[i]:match("^([%d%.]+)%%")))
			parsed += shown
			assert(math.abs(shown / 100 - row[key]) <= 1.1e-14, "Displayed odds drift")
			assert((labels[i]:find("(certain)", 1, true) ~= nil) == (row[key] == 1))
		end
		assert(total == 1e14 and math.abs(parsed - 100) < 1e-10, "Displayed column must sum to 100%")
	end
	if luck >= 1e12 then
		assert(odds.Items[1].Normal == 1 and odds.Items[2].Normal == 0)
	end
	local tiny = format.Column({ { P = 1e-30 }, { P = 1 } }, "P")
	assert(tiny[1]:find("raw", 1, true), "Tiny nonzero odds must not silently become impossible")
	local lucky = { Allowed = true, PolicyRemaining = 120, Count = 1, Armed = true, FreeLuck = luck / 2.5, Odds = odds }
	local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
		Near = function()
			return true
		end,
	})
	hud.Update({
		Coins = 0,
		ToiletTier = 15,
		RebirthLevel = 15,
		RunFlushes = 300,
		LifetimeFlushes = 300,
		LastClaimDay = 0,
		Streak = 0,
		Commerce = { Lucky = lucky },
		UpgradeStats = { LuckMultiplier = luck },
	})
	H.StartTasks()
	H.Advance(1.01)
	H.ResumeTasks()
	local chip = root.HUD:FindFirstChild("TotalLuck", true)
	assert(chip.Text == (if luck * 10 >= 1e6 then "Luck\nx" else "Luck x") .. numberFormat.Luck(luck * 10))
	assert(not chip.Text:find("cap", 1, true) and #chip.Text <= 18)
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		-- Let the existing one-second status updater refresh after changing viewport mode.
		H.Advance(1.01)
		H.ResumeTasks()
		ui.Show({ Allowed = true, Count = 1, Odds = odds })
		H.Layout(root)
		local scroll, body = ui.Panel.ContentScroll, ui.Panel.ContentScroll.Body
		assert(body.Explanation.AbsolutePosition.Y - scroll.AbsolutePosition.Y <= 2, "Top gap returned")
		local previousBottom = scroll.AbsolutePosition.Y
		local labels = {}
		for _, label in ipairs(body:GetChildren()) do
			if label:IsA("TextLabel") then
				table.insert(labels, label)
			end
		end
		table.sort(labels, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		assert(#labels == #items + 3, "Odds list includes explanation, luck breakdown and rarity summary")
		for _, label in ipairs(labels) do
			assert(label.TextWrapped and not label.TextScaled and label.TextSize == 17)
			assert(label.TextTruncate == Enum.TextTruncate.None and label.TextYAlignment == Enum.TextYAlignment.Top)
			local right = label.AbsolutePosition.X + label.AbsoluteSize.X
			assert(right <= scroll.AbsolutePosition.X + scroll.AbsoluteSize.X - 8, "Right clipping")
			local bounds = H.Services.TextService:GetTextSize(
				label.Text,
				label.TextSize,
				label.Font,
				Vector2.new(label.AbsoluteSize.X - 4, 100000)
			)
			assert(label.AbsoluteSize.Y >= bounds.Y and label.AbsolutePosition.Y >= previousBottom)
			previousBottom = label.AbsolutePosition.Y + label.AbsoluteSize.Y
		end
		for line in chip.Text:gmatch("[^\n]+") do
			assert(chip.AbsoluteSize.X >= #line * 5, "Extreme HUD multiplier cannot fit")
		end
		-- Check the visible replacement too: the desktop chip is collapsed on phones.
		local phone = root.HUD.PhoneStatus
		local label = if root.HUD.Boosts.Visible then chip else phone.Label
		local minimum = label.UITextSizeConstraint.MinTextSize
		local lines = 0
		for line in label.Text:gmatch("[^\n]+") do
			lines += 1
			assert(label.AbsoluteSize.X >= #line * minimum * 0.58, "Luck label cannot fit at its text minimum")
		end
		assert(label.AbsoluteSize.Y >= lines * minimum * 1.2, "Luck label lines clip vertically")
		if not root.HUD.Boosts.Visible then
			assert(phone.Visible and minimum >= 14, "Phone luck must stay visible and readable")
			assert(phone.Text:find("Luck x" .. numberFormat.Luck(luck * 10), 1, true), "Phone luck value lost")
			assert(phone.AbsoluteSize.Y >= 44, "Collapsed luck target must remain reachable")
		end
		if size[1] == 390 and size[2] == 722 then
			H.Snapshot(root, "uncapped-luck-" .. tostring(luck))
			ui.Panel.Visible = false
			H.Snapshot(root, "uncapped-hud-" .. tostring(luck))
			ui.Panel.Visible = true
			scroll.CanvasPosition = Vector2.new(0, body.CosmicCourtesy.AbsolutePosition.Y - scroll.AbsolutePosition.Y)
			H.Layout(root)
			H.Snapshot(root, "uncapped-outcomes-" .. tostring(luck))
			scroll.CanvasPosition = Vector2.new()
			H.Layout(root)
		end
		local confirm = ui.Panel.ConfirmLucky
		assert(scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y <= confirm.AbsolutePosition.Y)
		assert(confirm.AbsoluteSize.Y >= 44 and confirm.AbsoluteSize.X >= 44)
		local last = labels[#labels]
		scroll.CanvasPosition = Vector2.new(0, last.AbsolutePosition.Y - scroll.AbsolutePosition.Y)
		H.Layout(root)
		assert(math.abs(last.AbsolutePosition.Y - scroll.AbsolutePosition.Y) < 1)
		ui.Show({ Allowed = true, Count = 1, Odds = odds })
		assert(scroll.CanvasPosition.Y == 0, "Reopening must start at the disclosure")
	end
	ui.Invalidate({ Allowed = true, Count = 1, Odds = { Token = "2:1.12:10" } })
	assert(not ui.Panel.Visible, "Tier changes must invalidate the review")
	root:Destroy()
	print(
		"Uncapped luck UI: extreme multiplier, 100% column sums, certainty, HUD and 47 readable rows across 12 viewports"
	)
end

do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local passes = H.Load("src/client/UI/Passes").Create(root, remotes)
	local roll = H.Load("src/server/Services/RollService")
	local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
	local odds = { Token = "extreme-card", BaseLuck = 1e6, Luck = 1e7, Items = {}, Rarities = {} }
	local normal, boosted = roll.Distribution(items, toilets, 1, 1e6), roll.Distribution(items, toilets, 1, 1e7)
	for i, entry in ipairs(normal) do
		local rarity = odds.Rarities[entry.Item.Rarity] or { Normal = 0, Boosted = 0 }
		rarity.Normal += entry.Probability
		rarity.Boosted += boosted[i].Probability
		odds.Rarities[entry.Item.Rarity] = rarity
	end
	passes.Update({
		OwnedPasses = {},
		Settings = {},
		Commerce = {
			Quotes = {},
			Lucky = {
				Allowed = true,
				PolicyRemaining = 120,
				Count = 20,
				Odds = odds,
			},
		},
	})
	passes.Panel.Visible = true
	passes.Panel:FindFirstChild("LuckyTab", true).Activated:Fire()
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		for _, key in ipairs({ "LuckyFlush1", "LuckyFlush5", "LuckyFlush20" }) do
			local card = passes.Panel:FindFirstChild("LuckyGrid", true)[key].OfferCard
			local scroll = card.RarityOddsScroll
			local label = scroll.RarityOdds
			local bounds = H.Services.TextService:GetTextSize(
				label.Text,
				17,
				label.Font,
				Vector2.new(label.AbsoluteSize.X, 100000)
			)
			assert(label.TextSize == 17 and not label.TextScaled and label.TextWrapped)
			assert(label.AbsoluteSize.Y >= bounds.Y, "Lucky card odds must scroll, never shrink or clip")
			assert(scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y <= card.Buy.AbsolutePosition.Y)
			assert(
				label.AbsolutePosition.X + label.AbsoluteSize.X <= scroll.AbsolutePosition.X + scroll.AbsoluteSize.X - 4
			)
		end
	end
	root._fixed, root._abs = { X = 390, Y = 722 }, nil
	root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	H.Layout(root)
	local mainScroll = passes.Panel.ContentScroll
	local rarityScroll = passes.Panel:FindFirstChild("LuckyGrid", true).LuckyFlush1.OfferCard.RarityOddsScroll
	mainScroll.CanvasPosition = Vector2.new(0, rarityScroll.AbsolutePosition.Y - mainScroll.AbsolutePosition.Y)
	H.Layout(root)
	H.Snapshot(root, "uncapped-lucky-cards")
	root:Destroy()
	print("Uncapped Lucky cards: readable scrolling rarity percentages at all 12 viewports")
end
