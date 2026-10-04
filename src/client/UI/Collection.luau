local C = require(script.Parent.Components)
local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Rarities = require(game.ReplicatedStorage.Shared.Config.Rarities)
local Collection = {}
function Collection.Create(gui, remotes)
	local panel = C.Panel(gui, "My Collection")
	local search = C.New("TextBox", panel, {
		PlaceholderText = "Search...",
		Text = "",
		ClearTextOnFocus = false,
		Size = UDim2.fromScale(0.48, 0.07),
		Position = UDim2.fromScale(0.48, 0.12),
		BackgroundColor3 = C.Navy,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
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
		Size = UDim2.fromScale(0.94, 0.65),
		Position = UDim2.fromScale(0.03, 0.32),
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
	local filter, state = "All", nil
	local function render()
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		if not state then
			return
		end
		for index, item in ipairs(Items) do
			local discovered = (state.Collection[item.Id] or 0) > 0
			local name = if discovered then item.Name else "???"
			if
				(filter == "All" or filter == item.Rarity)
				and string.find(string.lower(name), string.lower(search.Text), 1, true)
			then
				local card = C.New("Frame", grid, { BackgroundColor3 = C.Navy, LayoutOrder = index })
				C.Round(card, Rarities[item.Rarity].Color)
				C.Text(card, if discovered then "?" else "?", UDim2.fromScale(0.8, 0.23), UDim2.fromScale(0.1, 0.02)).TextColor3 = if discovered
					then Rarities[item.Rarity].Color
					else Color3.fromRGB(8, 12, 20)
				C.Text(card, name, UDim2.fromScale(0.92, 0.13), UDim2.fromScale(0.04, 0.26))
				C.Text(
					card,
					item.Rarity .. (if discovered then " | 1/" .. item.Chance else ""),
					UDim2.fromScale(0.92, 0.1),
					UDim2.fromScale(0.04, 0.4)
				).TextColor3 =
					Rarities[item.Rarity].Color
				local count = state.Inventory[item.Id] or 0
				local reserved, displaySlot = 0, nil
				for slot, id in pairs(state.Displays) do
					if id == item.Id then
						reserved += 1
						displaySlot = tonumber(slot)
					end
				end
				C.Text(card, "Owned: " .. count, UDim2.fromScale(0.9, 0.1), UDim2.fromScale(0.05, 0.51))
				if count > 0 then
					local available = count - reserved
					C.Button(card, "Sell 1", UDim2.fromScale(0.43, 0.14), UDim2.fromScale(0.04, 0.65), function()
						if available > 0 then
							remotes.Sell:FireServer(item.Id, 1)
						end
					end)
					C.Button(card, "Sell All", UDim2.fromScale(0.43, 0.14), UDim2.fromScale(0.53, 0.65), function()
						if available > 0 then
							remotes.Sell:FireServer(item.Id, available)
						end
					end)
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
		C.Button(tabs, name, UDim2.fromOffset(110, 32), nil, function()
			filter = name
			render()
		end, if Rarities[name] then Rarities[name].Color else nil)
	end
	search:GetPropertyChangedSignal("Text"):Connect(render)
	return {
		Panel = panel,
		Update = function(newState)
			state = newState
			render()
		end,
	}
end
return Collection
