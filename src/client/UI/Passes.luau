local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local C = require(script.Parent.Components)
local Passes = {}

function Passes.Create(gui, remotes)
	local panel = C.Panel(gui, "Passes")
	local owned, metadata, buttons, prices, colors = {}, {}, {}, {}, {}
	local status = C.Text(
		panel,
		"One-time passes. Auto-Flush and animation skip are free.",
		UDim2.fromScale(0.94, 0.055),
		UDim2.fromScale(0.03, 0.1)
	)
	local row = C.New("ScrollingFrame", panel, {
		Size = UDim2.fromScale(0.94, 0.5),
		Position = UDim2.fromScale(0.03, 0.18),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
	})
	C.New("UIListLayout", row, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) })
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
	for _, key in ipairs(Config.PassOrder) do
		local pass = Config.Gamepasses[key]
		local card = C.New("Frame", row, { Size = UDim2.new(0, 180, 0.94, 0), BackgroundColor3 = C.Navy })
		C.Chrome(card, C.Navy)
		C.Text(card, pass.Name, UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.04))
		C.Text(card, pass.Description, UDim2.fromScale(0.9, 0.34), UDim2.fromScale(0.05, 0.29))
		prices[key] = C.Text(
			card,
			if pass.Id == 0 then "Planned: " .. pass.Price .. " R$" else "Checking price...",
			UDim2.fromScale(0.9, 0.1),
			UDim2.fromScale(0.05, 0.68)
		)
		buttons[key] = C.Button(card, "Coming soon", UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0.05, 0.82), function()
			if buttons[key].Interactable then
				status.Text = "Checking pass ownership..."
				remotes.BuyPass:FireServer(key)
			end
		end)
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
	local colorHeading = C.Text(
		panel,
		"Plot color: requires Custom Plot Color",
		UDim2.fromScale(0.94, 0.055),
		UDim2.fromScale(0.03, 0.71)
	)
	for index, color in ipairs(Config.PlotColors) do
		colors[color.Id] = C.Button(
			panel,
			color.Name,
			UDim2.fromScale(0.145, 0.09),
			UDim2.fromScale(0.03 + (index - 1) * 0.158, 0.79),
			function()
				remotes.PlotColor:FireServer(color.Id)
			end,
			if color.RGB then Color3.fromRGB(table.unpack(color.RGB)) else C.Navy
		)
		colors[color.Id].Interactable = false
	end
	local message = C.Text(panel, "", UDim2.fromScale(0.65, 0.06), UDim2.fromScale(0.03, 0.91))
	C.Button(panel, "Refresh owned passes", UDim2.fromScale(0.27, 0.06), UDim2.fromScale(0.7, 0.91), function()
		message.Text = "Checking..."
		remotes.RefreshPasses:FireServer()
		refreshPrices()
	end)
	remotes.Result.OnClientEvent:Connect(function(action, payload)
		if action == "BuyPass" or action == "RefreshPasses" or action == "PlotColor" then
			message.Text = payload.Message or "Request unavailable."
			status.Text = "One-time passes. Auto-Flush and animation skip are free."
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
				then "Plot color: " .. selected
				else "Plot color: requires Custom Plot Color"
			for id, button in pairs(colors) do
				button.Interactable = owned.CustomPlotColor == true
				button.Text = (if id == selected and owned.CustomPlotColor then "✓ " else "") .. id
			end
		end,
	}
end

return Passes
