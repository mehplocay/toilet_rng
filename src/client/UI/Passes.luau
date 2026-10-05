local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Shop = require(game.ReplicatedStorage.Shared.Config.Shop)
local C = require(script.Parent.Components)
local Card = require(script.Parent.Layout).PassCard
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
	local status = C.BodyText(body, "Make it yours! Auto-Flush and animation skip are free.", UDim2.new(1, 0, 0, 40))
	local scroll = C.Scroll(body, UDim2.new(1, 0, 1, -102), UDim2.fromOffset(0, 44))
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
	C.Grid(row, Card.MinimumWidth, Card.CellHeight, 4)
	local function updateButtons()
		for _, key in ipairs(Config.PassOrder) do
			local pass, info, button = Config.Gamepasses[key], metadata[key], buttons[key]
			button.Text = if owned[key]
				then "Owned"
				elseif pass.Id == 0 then "Coming soon"
				elseif info and info.IsForSale then C.Commas(info.PriceInRobux)
				else "Unavailable"
			button.Interactable = not owned[key] and pass.Id > 0 and info ~= nil and info.IsForSale == true
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
				else "One-time purchase"
		end
	end
	for order, key in ipairs(Config.PassOrder) do
		local pass = Config.Gamepasses[key]
		local offer = Shop.Offers[key]
		local color = Color3.fromRGB(table.unpack(offer.Color))
		local slot = C.New("Frame", row, { Name = key, BackgroundTransparency = 1, LayoutOrder = order })
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
					status.Text = "Checking pass ownership..."
					remotes.BuyPass:FireServer(key)
				end
			end,
			C.Green,
			{ Name = "Buy", TextSize = 24, Icon = "Robux" }
		)
		local gift = C.Button(
			card,
			"Coming soon",
			UDim2.fromOffset(Card.GiftWidth, Card.ButtonHeight),
			UDim2.new(1, -Card.Inset - Card.GiftWidth, 0, Card.ButtonY),
			function() end,
			C.Purple,
			{ Name = "Gift", TextSize = 12 }
		)
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
			for _, key in ipairs(Config.PassOrder) do
				local pass = Config.Gamepasses[key]
				if pass.Id > 0 then
					local ok, info = pcall(
						MarketplaceService.GetProductInfoAsync,
						MarketplaceService,
						pass.Id,
						Enum.InfoType.GamePass
					)
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
	local colorHeading = C.BodyText(content, "Plot color: requires Custom Plot Color", UDim2.new(1, 0, 0, 30))
	colorHeading.LayoutOrder = 2
	local swatches = C.New("Frame", content, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	})
	C.Grid(swatches, 112, 48)
	for order, color in ipairs(Config.PlotColors) do
		colors[color.Id] = C.Button(swatches, color.Name, UDim2.fromOffset(120, 48), nil, function()
			remotes.PlotColor:FireServer(color.Id)
		end, if color.RGB then Color3.fromRGB(table.unpack(color.RGB)) else C.Navy, { TextSize = 18 })
		colors[color.Id].LayoutOrder, colors[color.Id].Interactable = order, false
	end
	local message = C.BodyText(body, "", UDim2.new(0.55, -8, 0, 48), UDim2.new(0, 0, 1, -50))
	C.Button(body, "Refresh passes", UDim2.new(0.45, -8, 0, 44), UDim2.new(0.55, 4, 1, -48), function()
		message.Text = "Checking..."
		remotes.RefreshPasses:FireServer()
		refreshPrices()
	end, C.Blue, { TextSize = 18 })
	remotes.Result.OnClientEvent:Connect(function(action, payload)
		if action == "BuyPass" or action == "RefreshPasses" or action == "PlotColor" then
			message.Text = payload.Message or "Request unavailable."
			status.Text = "Make it yours! Auto-Flush and animation skip are free."
		end
	end)
	updateButtons()
	return {
		Panel = panel,
		Update = function(state)
			owned = state.OwnedPasses or {}
			updateButtons()
			local selected = state.Settings.PlotColor or "Default"
			colorHeading.Text = if owned.CustomPlotColor
				then "Your plot color: " .. selected
				else "Plot color: requires Custom Plot Color"
			for id, button in pairs(colors) do
				button.Interactable = owned.CustomPlotColor == true
				button.Text = (if id == selected and owned.CustomPlotColor then "> " else "") .. id
			end
		end,
	}
end
return Passes
