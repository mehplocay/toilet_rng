local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local C = require(script.Parent.Components)
local Passes = {}
function Passes.Create(gui, remotes)
	local panel = C.Panel(gui, "Passes & Style", C.Purple)
	local body = panel.ContentScroll.Body
	local owned, metadata, buttons, prices, colors = {}, {}, {}, {}, {}
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
	C.Grid(row, 145, 300, 4)
	local function updateButtons()
		for _, key in ipairs(Config.PassOrder) do
			local pass, info, button = Config.Gamepasses[key], metadata[key], buttons[key]
			button.Text = if owned[key]
				then "Owned"
				elseif pass.Id == 0 then "Coming soon"
				elseif info and info.IsForSale then "Buy"
				else "Unavailable"
			button.Interactable = not owned[key] and pass.Id > 0 and info ~= nil and info.IsForSale == true
		end
	end
	for order, key in ipairs(Config.PassOrder) do
		local pass = Config.Gamepasses[key]
		local color = if order % 2 == 0 then C.Gold else C.Purple
		local card = C.Card(row, color, true)
		card.LayoutOrder = order
		C.Icon(
			card,
			if key == "FastFlush" then "Flush" elseif key == "CustomPlotColor" then "Home" else "Crown",
			UDim2.fromOffset(72, 72),
			UDim2.new(0.5, -36, 0, 12)
		)
		C.Text(card, pass.Name, UDim2.new(1, -16, 0, 44), UDim2.fromOffset(8, 90), 24)
		C.BodyText(card, pass.Description, UDim2.new(1, -20, 0, 66), UDim2.fromOffset(10, 137))
		prices[key] = C.Text(
			card,
			if pass.Id == 0 then "Not on sale yet" else "Checking price...",
			UDim2.new(1, -16, 0, 25),
			UDim2.fromOffset(8, 215),
			20
		)
		prices[key].TextColor3 = C.Gold
		buttons[key] = C.Button(card, "Coming soon", UDim2.new(1, -18, 0, 44), UDim2.fromOffset(9, 247), function()
			if buttons[key].Interactable then
				status.Text = "Checking pass ownership..."
				remotes.BuyPass:FireServer(key)
			end
		end, color, { TextSize = 19 })
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
					metadata[key] = if valid then info else nil
					prices[key].Text = if valid then tostring(info.PriceInRobux) .. " R$" else "Price unavailable"
					updateButtons()
				end
			end
			loading = false
		end)
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
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
