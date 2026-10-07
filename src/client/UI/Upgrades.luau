local C = require(script.Parent.Components)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local Income = require(game.ReplicatedStorage.Shared.Config.Income)
local Style = require(game.ReplicatedStorage.Shared.Config.World)
local Preview = require(script.Parent.Preview)
local Upgrades = {}
function Upgrades.Create(gui, remotes)
	local panel = C.Panel(gui, "Toilet Upgrades", C.Green)
	local body = panel.ContentScroll.Body
	local navigation = C.New("Frame", body, {
		Name = "ShopNavigation",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	})
	local wallet =
		C.Text(body, "Better toilets. Bigger possibilities!", UDim2.new(1, 0, 0, 32), UDim2.fromOffset(0, 54), 24)
	wallet.TextColor3 = Color3.fromRGB(153, 255, 143)
	local footer = C.BodyText(
		body,
		"Display and paid cash bonuses multiply with no multiplier cap.",
		UDim2.new(1, 0, 0, 26),
		UDim2.new(0, 0, 1, -26)
	)
	local row = C.Scroll(body, UDim2.new(1, 0, 1, -200), UDim2.fromOffset(0, 164))
	row.Name = "ToiletCards"
	local tracks = require(script.Parent.UpgradeTracks).Create(body, remotes)
	tracks.Frame.Size, tracks.Frame.Position = row.Size, row.Position
	local title = panel.TitleBar:FindFirstChildWhichIsA("TextLabel")
	local function applyTab(name)
		row.Visible, tracks.Frame.Visible = name == "Toilets", name == "Coin Upgrades"
		title.Text = if name == "Toilets" then "Toilet Shop" else "Upgrades"
		footer.Text = if name == "Toilets"
			then "Display and paid cash bonuses multiply with no multiplier cap."
			else "Toilets and coin upgrades are permanent."
	end
	local tabs = C.TabBar(body, { "Toilets", "Coin Upgrades" }, applyTab)
	tabs.Frame.Position = UDim2.fromOffset(0, 92)
	local function selectTab(name)
		assert(name == "Toilets" or name == "Coin Upgrades", "Unknown shop tab")
		tabs.Select(name)
		applyTab(name)
	end
	selectTab("Toilets")
	local entryTab
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if not panel.Visible then
			entryTab = nil
		end
	end)
	local function openTab(name)
		selectTab(name)
		entryTab = name
		panel.ContentScroll.CanvasPosition = Vector2.new()
		panel.Visible = true
	end
	C.Grid(row, 144, 310)
	local buttons, bars, marks = {}, {}, {}
	for tier, toilet in ipairs(Toilets) do
		local color = Style.ToiletColors[tier]
		local card = C.Card(row, color, tier >= 3)
		card.Name = toilet.Id
		card.LayoutOrder = tier
		local _, tierLabel =
			C.Pill(card, "TIER " .. tier, color:Lerp(C.Navy, 0.5), UDim2.fromOffset(72, 23), UDim2.fromOffset(8, 8))
		tierLabel.TextColor3 = Color3.new(1, 1, 1)
		Preview.Create(card, UDim2.new(1, -24, 0, 106), UDim2.fromOffset(12, 33), nil, tier)
		C.Text(card, toilet.Name, UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 140), 22)
		C.BodyText(
			card,
			string.format("%.3g", Income.TierMultipliers[tier]) .. "x display income / " .. toilet.Luck .. "x luck",
			UDim2.new(1, -12, 0, 25),
			UDim2.fromOffset(6, 174)
		)
		C.Text(card, C.Commas(toilet.Price) .. " Coins", UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 202), 21).TextColor3 =
			C.Gold
		bars[tier] = C.ProgressBar(card, UDim2.new(1, -20, 0, 7), UDim2.fromOffset(10, 239), C.Green)
		buttons[tier] = C.Button(card, "Locked", UDim2.new(1, -18, 0, 44), UDim2.fromOffset(9, 255), function()
			remotes.BuyToilet:FireServer(toilet.Id)
		end, C.Green, { TextSize = 20 })
		buttons[tier].Interactable = false
		marks[tier] = C.StatusIcons(card, UDim2.fromOffset(24, 24), UDim2.new(1, -32, 0, 8))
	end
	return {
		Panel = panel,
		Navigation = navigation,
		SelectTab = selectTab,
		SelectedTab = tabs.Selected,
		Open = openTab,
		Toggle = function(name)
			-- Manual tab changes do not change which HUD button opened this window.
			if panel.Visible and entryTab == name then
				panel.Visible = false
			else
				openTab(name)
			end
		end,
		Update = function(state)
			tracks.Update(state)
			wallet.Text = C.Commas(state.Coins) .. " Coins  |  Tier " .. state.ToiletTier .. "/" .. #Toilets
			for tier, button in ipairs(buttons) do
				button.Text = if tier <= state.ToiletTier
					then "Owned"
					elseif tier == state.ToiletTier + 1 then (if state.Coins >= Toilets[tier].Price
						then "Upgrade!"
						else "Save up")
					else "Locked"
				button.Interactable = tier == state.ToiletTier + 1 and state.Coins >= Toilets[tier].Price
				marks[tier](tier > state.ToiletTier + 1, tier <= state.ToiletTier)
				bars[tier].Set(if tier <= state.ToiletTier then 1 else state.Coins / math.max(1, Toilets[tier].Price))
			end
		end,
	}
end
return Upgrades
