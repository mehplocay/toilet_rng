local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Shop = require(game.ReplicatedStorage.Shared.Config.Shop)
local C = require(script.Parent.Components)
local Card = require(script.Parent.Layout).PassCard
local Odds = require(script.Parent.LuckyOdds)
local Rules = require(game.ReplicatedStorage.Shared.MonetizationRules)
local Passes = {}
function Passes.Create(gui, remotes)
	local panel = C.Panel(gui, "Passes & Style", C.Purple)
	local gradient = panel.TitleBar.UIGradient
	gradient.Rotation = 0
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 77, 113)),
		ColorSequenceKeypoint.new(0.2, C.Gold),
		ColorSequenceKeypoint.new(0.4, C.Green),
		ColorSequenceKeypoint.new(0.6, C.Blue),
		ColorSequenceKeypoint.new(0.8, C.Purple),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 91, 208)),
	})
	local close = panel.TitleBar:FindFirstChild("X")
	close.Size, close.Position = UDim2.fromOffset(50, 50), UDim2.new(1, -54, 0, 4)
	local blur = C.New("BlurEffect", game:GetService("Lighting"), { Name = "PassesBlur", Size = 18, Enabled = false })
	panel.Destroying:Connect(function()
		blur:Destroy()
	end)
	local body = panel.ContentScroll.Body
	local owned, metadata, buttons, prices, colors, marks = {}, {}, {}, {}, {}, {}
	local selectedColor = "Default"
	local commerce = { Quotes = {} }
	local beginPurchase
	local oddsUI = Odds.Create(gui, remotes, function()
		beginPurchase("BuyProduct")
	end)
	local alive = true
	panel.Destroying:Connect(function()
		alive = false
	end)
	panel.Destroying:Connect(function()
		oddsUI.Panel:Destroy()
	end)
	local luckyLabels = {}
	local policyDeadline = 0
	local keys = table.clone(Config.PassOrder)
	for _, key in ipairs(Config.ProductOrder) do
		table.insert(keys, key)
	end
	local function definition(key)
		return Config.Gamepasses[key] or Config.DeveloperProducts[key]
	end
	local status = C.BodyText(body, "Permanent passes and consumable boosts.", UDim2.new(1, 0, 0, 40))
	status.Name = "PurchaseStatus"
	local pendingAction, pendingDeadline
	beginPurchase = function(action)
		pendingAction, pendingDeadline = action, os.clock() + 10
		status.Text = if action == "BuyPass" then "Checking pass ownership..." else "Preparing your purchase..."
	end
	local scroll = C.Scroll(body, UDim2.new(1, 0, 1, -150), UDim2.fromOffset(0, 92))
	local content = C.New(
		"Frame",
		scroll,
		{ Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }
	)
	C.New("UIListLayout", content, { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder })
	local row = C.New("Frame", content, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	})
	row.Name = "OfferGrid"
	C.Grid(row, Card.MinimumWidth, Card.CellHeight + 172, 4)
	local boostRow = C.New("Frame", content, {
		Name = "BoostGrid",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Visible = false,
	})
	C.Grid(boostRow, Card.MinimumWidth, Card.CellHeight, 4)
	local luckyRow = C.New("Frame", content, {
		Name = "LuckyGrid",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Visible = false,
	})
	C.Grid(luckyRow, Card.MinimumWidth, Card.CellHeight + 280, 4)
	local selectTab
	C.Button(body, "Passes", UDim2.new(1 / 3, -5, 0, 40), UDim2.fromOffset(0, 44), function()
		selectTab(false)
	end, C.Purple, { Name = "PassesTab" })
	C.Button(body, "Boosts", UDim2.new(1 / 3, -5, 0, 40), UDim2.new(1 / 3, 2, 0, 44), function()
		selectTab(true)
	end, C.Blue, { Name = "BoostsTab" })
	local luckyTab = C.Button(body, "Lucky", UDim2.new(1 / 3, -5, 0, 40), UDim2.new(2 / 3, 5, 0, 44), function()
		selectTab("Lucky")
	end, C.Gold, { Name = "LuckyTab" })
	luckyTab.Visible = false
	local function updateButtons()
		for _, key in ipairs(keys) do
			local pass, info, button = definition(key), metadata[key], buttons[key]
			button.Text = if owned[key]
				then "Owned"
				elseif pass.Id == 0 then "Coming soon"
				elseif info and info.IsForSale then C.Commas(info.PriceInRobux)
				else "Unavailable"
			button.Interactable = not owned[key]
				and pass.Id > 0
				and info ~= nil
				and info.IsForSale == true
				and (not Config.DeveloperProducts[key] or commerce.CanResume ~= false)
				and (not pass.LuckyCharges or (commerce.Lucky ~= nil and commerce.Lucky.Allowed == true and commerce.Lucky.Count <= Config.LuckyFlushCap - pass.LuckyCharges))
				and not (
					Config.DeveloperProducts[key]
					and commerce.PendingProduct
					and not (commerce.PendingProduct == key and commerce.CanResume)
				)
			button.RobuxIcon.Visible = button.Interactable
			button.Label.Position = if button.Interactable
				then UDim2.fromScale(0.29, 0.12)
				else UDim2.fromScale(0.06, 0.12)
			button.Label.Size = if button.Interactable then UDim2.fromScale(0.66, 0.76) else UDim2.fromScale(0.88, 0.76)
			marks[key](not owned[key] and not button.Interactable, owned[key] == true)
			prices[key].Text = if owned[key]
				then "Yours to enjoy"
				elseif pass.Id == 0 then "Not on sale yet"
				elseif not info then "Price unavailable"
				elseif Config.DeveloperProducts[key] and pass.IncomeSeconds then C.Commas(
					(commerce.Quotes or {})[key] or 0
				) .. " Coins"
				elseif pass.LuckyCharges then tostring((commerce.Lucky or {}).Count or 0) .. " Lucky Flushes owned"
				elseif Config.DeveloperProducts[key] then "Timer continues offline"
				else "One-time purchase"
		end
	end
	for order, key in ipairs(keys) do
		local pass = definition(key)
		local offer = Shop.Offers[key]
		local color = Color3.fromRGB(table.unpack(offer.Color))
		local slot = C.New(
			"Frame",
			if pass.LuckyCharges then luckyRow elseif Config.DeveloperProducts[key] then boostRow else row,
			{ Name = key, BackgroundTransparency = 1, LayoutOrder = if key == "VIPPack" then 0 else order }
		)
		local card = C.Card(slot, color, true)
		card.Background.UIGradient.Color = ColorSequence.new(C.Navy:Lerp(color, 0.12), C.Ink)
		card.Name = "OfferCard"
		card.Position, card.Size = UDim2.fromOffset(0, Card.Top), UDim2.new(1, 0, 0, Card.Height)
		card.ClipsDescendants = false
		C.Icon(
			card,
			offer.Icon,
			UDim2.fromOffset(Card.IconSize, Card.IconSize),
			UDim2.new(0.5, -Card.IconSize / 2, 0, Card.IconY)
		)
		local title =
			C.Text(card, pass.Name, UDim2.new(1, -24, 0, Card.TitleHeight), UDim2.fromOffset(12, Card.TitleY), 28)
		title.Name, title.TextColor3, title.TextWrapped = "OfferTitle", color, false
		title.UIStroke.Thickness = 3
		local description = C.BodyText(
			card,
			offer.Description,
			UDim2.new(1, -24, 0, Card.DescriptionHeight),
			UDim2.fromOffset(12, Card.DescriptionY)
		)
		description.Name, description.TextWrapped = "Description", false
		prices[key] = C.Text(
			card,
			if pass.Id == 0 then "Not on sale yet" else "Checking price...",
			UDim2.new(1, -52, 0, Card.StatusHeight),
			UDim2.fromOffset(38, Card.StatusY),
			16
		)
		prices[key].Name, prices[key].TextColor3 = "OfferStatus", C.Muted
		marks[key] = C.StatusIcons(card, UDim2.fromOffset(24, 24), UDim2.fromOffset(12, Card.StatusY))
		buttons[key] = C.Button(
			card,
			"Coming soon",
			UDim2.new(1, -Card.Inset * 2 - Card.Gap - Card.GiftWidth, 0, Card.ButtonHeight),
			UDim2.fromOffset(Card.Inset, Card.ButtonY),
			function()
				if buttons[key].Interactable then
					if Config.DeveloperProducts[key] then
						if pass.LuckyCharges then
							oddsUI.Show(commerce.Lucky, key, (commerce.Quotes or {})[key] or 0)
						else
							beginPurchase("BuyProduct")
							remotes.BuyProduct:FireServer(key, (commerce.Quotes or {})[key] or 0)
						end
					else
						beginPurchase("BuyPass")
						remotes.BuyPass:FireServer(key)
					end
				end
			end,
			C.Green,
			{ Name = "Buy", TextSize = 24, Icon = "Robux" }
		)
		if pass.LuckyCharges then
			card.Size = UDim2.new(1, 0, 0, Card.Height + 280)
			buttons[key].Position = UDim2.fromOffset(Card.Inset, Card.ButtonY + 220)
			prices[key].Position = UDim2.fromOffset(38, Card.StatusY + 220)
			for _, name in ipairs({ "LockIcon", "CheckIcon" }) do
				local mark = card:FindFirstChild(name)
				if mark then
					mark.Position = UDim2.fromOffset(12, Card.StatusY + 220)
				end
			end
			luckyLabels[key] =
				C.BodyText(card, Odds.RarityText(nil), UDim2.new(1, -16, 0, 212), UDim2.fromOffset(8, Card.StatusY))
			luckyLabels[key].TextXAlignment = Enum.TextXAlignment.Left
			C.Button(
				card,
				"Info: all item odds",
				UDim2.new(1, -16, 0, 44),
				UDim2.fromOffset(8, Card.ButtonY + 278),
				function()
					oddsUI.Show(
						commerce.Lucky,
						if buttons[key].Interactable then key else nil,
						(commerce.Quotes or {})[key]
					)
				end,
				C.Blue,
				{ Name = "OddsInfo" }
			)
		elseif key == "VIPPack" then
			C.New("UIStroke", card, { Color = C.Gold, Thickness = 4 })
			C.BodyText(
				slot,
				"1.5x cash / +1 path speed step\n+50% offline tank\nDaily income-scaled chest\nVIP hub pad coin bonus\nGold star, trail and sign trim\nNo luck. Cash bonuses multiply without a cap. Speed cap 5x.",
				UDim2.new(1, -16, 0, 162),
				UDim2.fromOffset(8, Card.CellHeight + 4)
			)
		elseif Config.Gamepasses[key] then
			C.BodyText(slot, pass.Description, UDim2.new(1, -16, 0, 162), UDim2.fromOffset(8, Card.CellHeight + 4))
		end
		local gift = C.Button(
			card,
			"Coming soon",
			UDim2.fromOffset(Card.GiftWidth, Card.ButtonHeight),
			UDim2.new(1, -Card.Inset - Card.GiftWidth, 0, Card.ButtonY),
			function() end,
			C.Purple,
			{ Name = "Gift", TextSize = 12 }
		)
		if pass.LuckyCharges then
			gift.Position = UDim2.new(1, -Card.Inset - Card.GiftWidth, 0, Card.ButtonY + 220)
		end
		gift.Interactable = false
		C.Icon(gift, "Gift", UDim2.fromOffset(24, 24), UDim2.new(0.5, -12, 0, 2), 0)
		gift.Label.Position, gift.Label.Size = UDim2.new(0, 3, 0, 29), UDim2.new(1, -6, 0, 16)
	end
	local loading = false
	local function refreshPrices()
		if loading then
			return
		end
		loading = true
		task.spawn(function()
			for _, key in ipairs(keys) do
				local pass = definition(key)
				if pass.Id > 0 then
					local ok, info = pcall(
						MarketplaceService.GetProductInfoAsync,
						MarketplaceService,
						pass.Id,
						if Config.Gamepasses[key] then Enum.InfoType.GamePass else Enum.InfoType.Product
					)
					if not alive then
						return
					end
					local valid = ok
						and type(info) == "table"
						and type(info.PriceInRobux) == "number"
						and info.PriceInRobux >= 0
						and info.PriceInRobux < math.huge
					metadata[key] = if valid then info else nil
					updateButtons()
				end
			end
			loading = false
		end)
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		blur.Enabled = panel.Visible
		if panel.Visible then
			refreshPrices()
		end
	end)
	local colorSummary = C.New("Frame", content, {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	})
	local colorHeading = C.BodyText(
		colorSummary,
		"Plot color: requires Custom Plot Color",
		UDim2.new(1, -38, 1, 0),
		UDim2.fromOffset(38, 0)
	)
	colorHeading.TextXAlignment = Enum.TextXAlignment.Left
	local currentSwatch = C.New("Frame", colorSummary, {
		Name = "CurrentColorSwatch",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = C.Green,
	})
	C.New("UICorner", currentSwatch, { CornerRadius = UDim.new(0, 6) })
	local swatches = C.New("Frame", content, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	})
	C.Grid(swatches, 142, 48)
	local details = C.BodyText(
		content,
		"VIP: 1.5x cash, +1 path speed step, +50% offline tank, gold star/trail/sign trim, daily chest and VIP hub pad. No luck.\nCoin packs and VIP chest: 100 to 1,000,000,000 Coins. Cash bonuses multiply without a cap; path speed caps at 5x.",
		UDim2.new(1, -12, 0, 112)
	)
	details.LayoutOrder = 5
	local chest = C.Button(content, "VIP daily chest", UDim2.new(1, -12, 0, 44), nil, function()
		remotes.ClaimVIP:FireServer()
	end, C.Gold, { Name = "VIPChest" })
	chest.LayoutOrder, chest.Interactable = 0, false
	local useLucky = C.Button(content, "Review next Lucky Flush", UDim2.new(1, -12, 0, 48), nil, function()
		oddsUI.Show(commerce.Lucky)
	end, C.Gold, { Name = "UseLucky" })
	useLucky.LayoutOrder, useLucky.Visible = 0, false
	local styleFeedback = C.BodyText(content, "", UDim2.new(1, -12, 0, 48))
	styleFeedback.Name, styleFeedback.LayoutOrder = "StyleFeedback", 4
	selectTab = function(boosts)
		local lucky = boosts == "Lucky" and commerce.Lucky and commerce.Lucky.Allowed == true
		row.Visible, boostRow.Visible, luckyRow.Visible = not boosts, boosts == true, lucky == true
		useLucky.Visible = lucky == true
		details.Visible = not lucky
		colorSummary.Visible, swatches.Visible = not boosts, not boosts
		styleFeedback.Visible = not boosts
		chest.Visible = not boosts
		scroll.CanvasPosition = Vector2.new(0, 0)
	end
	local message = C.BodyText(body, "", UDim2.new(0.55, -8, 0, 48), UDim2.new(0, 0, 1, -50))
	message.Name = "PurchaseMessage"
	for order, color in ipairs(Config.PlotColors) do
		local button = C.Button(swatches, color.Name, UDim2.fromOffset(142, 48), nil, function()
			if not colors[color.Id].Interactable then
				return
			end
			styleFeedback.Text = "Applying " .. color.Name .. "..."
			remotes.PlotColor:FireServer(color.Id)
		end, C.Navy, { TextSize = 16, Name = "PlotColor_" .. color.Id })
		colors[color.Id] = button
		button.LayoutOrder, button.Interactable = order, false
		button.Label.Position, button.Label.Size = UDim2.fromOffset(34, 4), UDim2.new(1, -38, 1, -8)
		local swatch = C.New("Frame", button, {
			Name = "ColorSwatch",
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.fromOffset(7, 13),
			BackgroundColor3 = if color.RGB then Color3.fromRGB(table.unpack(color.RGB)) else C.Green,
		})
		C.New("UICorner", swatch, { CornerRadius = UDim.new(0, 5) })
		C.New("UIStroke", swatch, { Name = "Selection", Color = Color3.new(1, 1, 1), Thickness = 3, Enabled = false })
	end
	C.Button(body, "Refresh passes", UDim2.new(0.45, -8, 0, 44), UDim2.new(0.55, 4, 1, -48), function()
		message.Text = "Checking..."
		remotes.RefreshPasses:FireServer()
		refreshPrices()
	end, C.Blue, { TextSize = 18 })
	local results = remotes.Result.OnClientEvent:Connect(function(action, payload)
		if action == "PlotColor" then
			styleFeedback.Text = payload.Message or "Request unavailable."
		end
		if action == "LuckyReview" then
			oddsUI.Show(commerce.Lucky)
		end
		if action == "BuyPass" or action == "BuyProduct" or action == "ClaimVIP" or action == "RefreshPasses" then
			message.Text = payload.Message or "Request unavailable."
			if action == pendingAction then
				pendingAction, pendingDeadline = nil, nil
			end
			if not pendingAction then
				status.Text = "Permanent passes and consumable boosts."
			end
		end
	end)
	local policyExpiry = game:GetService("RunService").Heartbeat:Connect(function()
		if pendingDeadline and os.clock() >= pendingDeadline then
			pendingAction, pendingDeadline = nil, nil
			status.Text = "Permanent passes and consumable boosts."
			message.Text =
				"Purchase request timed out. Please try again in a moment. Already paid? Rejoin for delivery."
		end
		if luckyTab.Visible and os.clock() >= policyDeadline then
			luckyTab.Visible = false
			if commerce.Lucky then
				commerce.Lucky = table.clone(commerce.Lucky)
				commerce.Lucky.Allowed = false
			end
			oddsUI.Close()
			if luckyRow.Visible then
				selectTab(false)
			end
			updateButtons()
		end
	end)
	panel.Destroying:Connect(function()
		results:Disconnect()
		policyExpiry:Disconnect()
	end)
	updateButtons()
	return {
		Panel = panel,
		Update = function(state)
			owned = Rules.Entitlements(state.OwnedPasses, Config)
			commerce = table.clone(state.Commerce or { Quotes = {} })
			local lucky = commerce.Lucky
			policyDeadline = os.clock() + math.max(0, (lucky or {}).PolicyRemaining or 0)
			if lucky and policyDeadline <= os.clock() then
				lucky = table.clone(lucky)
				lucky.Allowed = false
				commerce.Lucky = lucky
			end
			oddsUI.Invalidate(lucky, commerce)
			luckyTab.Visible = lucky ~= nil and lucky.Allowed == true and policyDeadline > os.clock()
			if not luckyTab.Visible then
				if luckyRow.Visible then
					selectTab(false)
				end
				oddsUI.Close()
			end
			useLucky.Text = tostring((lucky or {}).Count or 0)
				.. " owned - "
				.. (if lucky and lucky.Armed then "ready for next flush" else "review odds to use")
			useLucky.Interactable = luckyTab.Visible and lucky.Count > 0
			for _, label in pairs(luckyLabels) do
				label.Text = Odds.RarityText(lucky and lucky.Odds)
			end
			if not pendingAction then
				status.Text = if commerce.PendingProduct
					then "Saved offer: reopen to finish or cancel. Already paid? Rejoin for delivery."
					else "Permanent passes and consumable boosts."
			end
			chest.Interactable = owned.VIPPack == true and (commerce.VIPDay or 0) < math.floor(os.time() / 86400)
			chest.Text = if chest.Interactable
				then "Claim VIP daily chest"
				elseif owned.VIPPack then "VIP chest claimed today"
				else "Daily chest requires VIP"
			updateButtons()
			local choice = Rules.PlotColor(Config, (state.Settings or {}).PlotColor) or Config.PlotColors[1]
			selectedColor = choice.Id
			currentSwatch.BackgroundColor3 = if choice.RGB then Color3.fromRGB(table.unpack(choice.RGB)) else C.Green
			colorHeading.Text = if owned.CustomPlotColor
				then "Your plot color: " .. choice.Name
				else "Plot color: requires Custom Plot Color"
			for id, button in pairs(colors) do
				button.Interactable = owned.CustomPlotColor == true
				button.Text = (Rules.PlotColor(Config, id)).Name
				button.ColorSwatch.Selection.Enabled = id == selectedColor
			end
		end,
	}
end
return Passes
