local C = require(script.Parent.Components)
local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local Preview = require(script.Parent.Preview)
local SafeInventory = require(game.ReplicatedStorage.Shared.SafeInventory)
local index = require(game.ReplicatedStorage.Shared.IndexProgress).new(
	Items,
	require(game.ReplicatedStorage.Shared.Config.IndexRewards)
)
local Collection = {}
function Collection.Create(gui, remotes)
	local panel = C.Panel(gui, "My Collection")
	local counter = C.Text(panel, "Discovered 0/" .. #Items, UDim2.fromScale(0.32, 0.07), UDim2.fromScale(0.03, 0.12))
	local search = C.New("TextBox", panel, {
		PlaceholderText = "Search...",
		Text = "",
		ClearTextOnFocus = false,
		Size = UDim2.fromScale(0.39, 0.07),
		Position = UDim2.fromScale(0.37, 0.12),
		BackgroundColor3 = C.Navy,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		Font = C.Font,
	})
	C.Round(search)
	local tabs = C.New("ScrollingFrame", panel, {
		Size = UDim2.fromScale(0.93, 0.08),
		Position = UDim2.fromScale(0.03, 0.21),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
	})
	C.New("UIListLayout", tabs, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })
	local grid = C.New("ScrollingFrame", panel, {
		Size = UDim2.fromScale(0.94, 0.58),
		Position = UDim2.fromScale(0.03, 0.39),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 5,
	})
	C.New("UIGridLayout", grid, {
		CellSize = UDim2.new(0.3, 0, 0, 205),
		CellPadding = UDim2.new(0.025, 0, 0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local help = C.Text(
		panel,
		"First copy + displayed copies kept. Discoveries are permanent.",
		UDim2.fromScale(0.94, 0.065),
		UDim2.fromScale(0.03, 0.31)
	)
	local rewards = require(script.Parent.IndexRewards).Create(panel, remotes)
	local rewardsButton
	rewardsButton = C.Button(panel, "Rewards", UDim2.fromScale(0.16, 0.07), UDim2.fromScale(0.8, 0.12), function()
		rewards.Frame.Visible = not rewards.Frame.Visible
		grid.Visible, tabs.Visible, help.Visible, search.Visible =
			not rewards.Frame.Visible, not rewards.Frame.Visible, not rewards.Frame.Visible, not rewards.Frame.Visible
		rewardsButton.Text = if rewards.Frame.Visible then "Items" else "Rewards"
	end)
	local filter, state = "All", nil
	local tabButtons = {}
	local function render()
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		if not state then
			return
		end
		local total, rarities = index:Progress(state)
		counter.Text = "Discovered " .. total .. "/" .. #Items
		for name, button in pairs(tabButtons) do
			local rarity = rarities[name]
			button.Text = name
				.. " "
				.. (if rarity then rarity.Discovered .. "/" .. rarity.Total else total .. "/" .. #Items)
		end
		for index, item in ipairs(Items) do
			local discovered = (state.Collection[item.Id] or 0) > 0
			local name = if discovered then item.Name else "???"
			if
				(filter == "All" or filter == item.Rarity)
				and string.find(string.lower(name), string.lower(search.Text), 1, true)
			then
				local card = C.New("Frame", grid, { BackgroundColor3 = C.Navy, LayoutOrder = index })
				C.Chrome(card, C.Navy)
				C.Round(card, Rarities[item.Rarity].Color)
				Preview.Create(
					card,
					UDim2.fromScale(0.9, 0.32),
					UDim2.fromScale(0.05, 0.015),
					item,
					nil,
					not discovered
				)
				C.Text(card, name, UDim2.fromScale(0.92, 0.12), UDim2.fromScale(0.04, 0.34))
				C.Text(
					card,
					item.Rarity .. (if discovered then " | 1/" .. item.Chance else ""),
					UDim2.fromScale(0.92, 0.1),
					UDim2.fromScale(0.04, 0.47)
				).TextColor3 =
					Rarities[item.Rarity].Color
				local count = state.Inventory[item.Id] or 0
				local displaySlot = nil
				for slot, id in pairs(state.Displays) do
					if id == item.Id then
						displaySlot = tonumber(slot)
					end
				end
				C.Text(card, "Owned: " .. count, UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.05, 0.58))
				if count > 0 then
					-- Part-built lock icon: no external asset ID or font-specific symbol.
					local lock = C.New("Frame", card, {
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(18, 22),
						Position = UDim2.new(1, -25, 0, 8),
					})
					local shackle = C.New("Frame", lock, {
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(10, 12),
						Position = UDim2.fromOffset(4, 0),
					})
					C.New("UICorner", shackle, { CornerRadius = UDim.new(0, 5) })
					C.New("UIStroke", shackle, { Color = Color3.fromRGB(255, 220, 80), Thickness = 2 })
					C.New("Frame", lock, {
						Size = UDim2.fromOffset(18, 13),
						Position = UDim2.fromOffset(0, 9),
						BackgroundColor3 = Color3.fromRGB(255, 220, 80),
						BorderSizePixel = 0,
					})
					local available = SafeInventory.Sellable(state, item.Id)
					local sellOne = C.Button(
						card,
						"Sell 1",
						UDim2.fromScale(0.43, 0.14),
						UDim2.fromScale(0.04, 0.65),
						function()
							if available > 0 then
								remotes.Sell:FireServer(item.Id, 1)
							end
						end
					)
					local sellAll = C.Button(
						card,
						"Sell All",
						UDim2.fromScale(0.43, 0.14),
						UDim2.fromScale(0.53, 0.65),
						function()
							if available > 0 then
								remotes.Sell:FireServer(item.Id, available)
							end
						end
					)
					sellOne.Interactable, sellAll.Interactable = available > 0, available > 0
					C.Text(
						card,
						"Keep " .. (count - available) .. " | Sell " .. available,
						UDim2.fromScale(0.9, 0.06),
						UDim2.fromScale(0.05, 0.77)
					)
					C.Button(
						card,
						if displaySlot then "Remove Display" else "Display",
						UDim2.fromScale(0.92, 0.14),
						UDim2.fromScale(0.04, 0.82),
						function()
							if displaySlot then
								remotes.Display:FireServer(nil, displaySlot)
							else
								for slot = 1, state.DisplaySlots do
									if not state.Displays[tostring(slot)] then
										remotes.Display:FireServer(item.Id, slot)
										break
									end
								end
							end
						end
					)
				end
			end
		end
	end
	local names = { "All" }
	local ordered = {}
	for name, rarity in pairs(Rarities) do
		table.insert(ordered, { Name = name, Order = rarity.Order })
	end
	table.sort(ordered, function(a, b)
		return a.Order < b.Order
	end)
	for _, entry in ipairs(ordered) do
		table.insert(names, entry.Name)
	end
	for _, name in ipairs(names) do
		tabButtons[name] = C.Button(tabs, name, UDim2.fromOffset(145, 32), nil, function()
			filter = name
			render()
		end, if Rarities[name] then Rarities[name].Color else nil)
	end
	search:GetPropertyChangedSignal("Text"):Connect(render)
	return {
		Panel = panel,
		Update = function(newState)
			state = newState
			rewards.Update(state)
			render()
		end,
	}
end
return Collection
