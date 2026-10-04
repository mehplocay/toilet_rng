local C = require(script.Parent.Components)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local Style = require(game.ReplicatedStorage.Shared.Config.World)
local Upgrades = {}
function Upgrades.Create(gui, remotes)
	local panel = C.Panel(gui, "Toilet Upgrades")
	C.Text(panel, "Better toilets = new drops + higher odds!", UDim2.fromScale(0.94, 0.1), UDim2.fromScale(0.03, 0.85)).TextColor3 =
		Color3.fromRGB(90, 255, 115)
	local row = C.New("ScrollingFrame", panel, {
		Size = UDim2.fromScale(0.94, 0.66),
		Position = UDim2.fromScale(0.03, 0.16),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
	})
	C.New("UIListLayout", row, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) })
	local buttons = {}
	for tier, toilet in ipairs(Toilets) do
		local card = C.New("Frame", row, { Size = UDim2.new(0, 155, 0.93, 0), BackgroundColor3 = C.Navy })
		C.Round(card, Style.ToiletColors[tier])
		local viewport = C.New(
			"ViewportFrame",
			card,
			{ Size = UDim2.fromScale(0.9, 0.48), Position = UDim2.fromScale(0.05, 0.04), BackgroundTransparency = 1 }
		)
		local camera =
			C.New("Camera", viewport, { CFrame = CFrame.lookAt(Vector3.new(7, 5, -9), Vector3.new(0, 2, 0)) })
		viewport.CurrentCamera = camera
		for _, spec in ipairs({
			{ Vector3.new(3, 1, 3), Vector3.new(0, 0, 0) },
			{ Vector3.new(4, 2, 4), Vector3.new(0, 1.5, 0) },
			{ Vector3.new(3, 3, 1), Vector3.new(0, 3, 2) },
		}) do
			C.New(
				"Part",
				viewport,
				{ Size = spec[1], Position = spec[2], Color = Style.ToiletColors[tier], Anchored = true }
			)
		end
		C.Text(card, toilet.Id .. " Toilet", UDim2.fromScale(0.94, 0.14), UDim2.fromScale(0.03, 0.55))
		C.Text(card, tostring(toilet.Price) .. " Coins", UDim2.fromScale(0.94, 0.1), UDim2.fromScale(0.03, 0.71))
		buttons[tier] = C.Button(card, "Buy", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.84), function()
			remotes.BuyToilet:FireServer(toilet.Id)
		end)
	end
	return {
		Panel = panel,
		Update = function(state)
			for tier, button in ipairs(buttons) do
				button.Text = if tier <= state.ToiletTier
					then "Owned"
					elseif tier == state.ToiletTier + 1 then "Buy"
					else "Locked"
				button.Interactable = tier == state.ToiletTier + 1 and state.Coins >= Toilets[tier].Price
			end
		end,
	}
end
return Upgrades
