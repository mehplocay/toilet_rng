local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Items, Rarities = require(Shared.Config.Items), require(Shared.Config.Rarities)
local SafeInventory = require(Shared.SafeInventory)
local Preview = require(script.Parent.Preview)
local index = require(Shared.IndexProgress).new(Items, require(Shared.Config.IndexRewards))
local Collection = {}
function Collection.Create(gui, remotes)
	local panel = C.Panel(gui, "My Collection", C.Blue)
	local body = panel.ContentScroll.Body
	local counter = C.Text(body, "Discovered 0/" .. #Items, UDim2.new(1, -104, 0, 30), nil, 23)
	counter.TextXAlignment = Enum.TextXAlignment.Left
	local progress = C.ProgressBar(body, UDim2.new(1, -104, 0, 7), UDim2.fromOffset(0, 35), C.Blue)
	local search = C.New("TextBox", body, {
		PlaceholderText = "Search discoveries...",
		PlaceholderColor3 = C.Muted,
		Text = "",
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -8, 0, 42),
		Position = UDim2.fromOffset(4, 54),
		BackgroundColor3 = C.Ink,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 17,
		Font = Enum.Font.BuilderSansBold,
	})
	C.Round(search, Color3.fromRGB(69, 106, 148), 10, 2)
	local grid = C.Scroll(body, UDim2.new(1, 0, 1, -196), UDim2.fromOffset(0, 196))
	C.Grid(grid, 132, 366, 5)
	local empty = C.BodyText(grid, "No discoveries match your search.", UDim2.new(1, -20, 0, 70))
	empty.Visible = false
	local help = C.BodyText(body, "First copies can be displayed.", UDim2.new(1, -100, 0, 26), UDim2.fromOffset(0, 166))
	local rewards = require(script.Parent.IndexRewards).Create(body, remotes)
	local rewardsButton = C.Button(
		body,
		"Rewards",
		UDim2.fromOffset(92, 44),
		UDim2.new(1, -96, 0, 0),
		function() end,
		C.Gold,
		{ TextSize = 18, Sound = "TabSwitch" }
	)
	local filter, state, cards = "All", nil, {}
	local selectedSlot, slotsButton
	local slotsPanel = C.Panel(gui, "Choose display slot", C.Blue)
	local slotGrid = C.Scroll(slotsPanel.ContentScroll.Body, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0))
	C.Grid(slotGrid, 150, 68, 4)
	local slotButtons = {}
	local names, colors = { "All" }, {}
	local ordered = {}
	for name, rarity in pairs(Rarities) do
		table.insert(ordered, { Name = name, Order = rarity.Order })
	end
	table.sort(ordered, function(a, b)
		return a.Order < b.Order
	end)
	for _, entry in ipairs(ordered) do
		table.insert(names, entry.Name)
		colors[entry.Name] = Rarities[entry.Name].Color
	end
	local render
	local tabs = C.TabBar(body, names, function(name)
		filter = name
		render()
	end, colors)
	tabs.Frame.Position = UDim2.fromOffset(0, 102)
	local function displaySlot(itemId)
		if not state then
			return nil
		end
		for slot = state.DisplaySlots, 1, -1 do
			if state.Displays[tostring(slot)] == itemId then
				return slot
			end
		end
		return nil
	end
	local function freeSlot()
		if not state then
			return nil
		end
		if selectedSlot then
			return if selectedSlot <= state.DisplaySlots and not state.Displays[tostring(selectedSlot)]
				then selectedSlot
				else nil
		end
		for slot = 1, state.DisplaySlots do
			if not state.Displays[tostring(slot)] then
				return slot
			end
		end
		return nil
	end
	-- Feedback.State plays Sell/SellAll and DisplayPlace/DisplayReturn after server confirmation.
	-- Shared buttons/panels provide input sounds through the same cooldown-limited mixer.
	local function makeCard(item, order)
		local rarity = Rarities[item.Rarity]
		local color = if item.Rarity == "Secret" then C.Purple else rarity.Color
		local frame = C.Card(grid, color, rarity.Order >= 4)
		frame.Name, frame.LayoutOrder = item.Id, order
		local name = C.Text(frame, "???", UDim2.new(1, -12, 0, 28), UDim2.fromOffset(6, 104), 21)
		local rarityText = C.Text(frame, item.Rarity, UDim2.new(1, -12, 0, 23), UDim2.fromOffset(6, 133), 16)
		rarityText.TextColor3 = if item.Rarity == "Secret"
			then Color3.fromRGB(232, 166, 255)
			else color:Lerp(Color3.new(1, 1, 1), 0.22)
		local odds = C.BodyText(frame, "Undiscovered", UDim2.new(1, -12, 0, 20), UDim2.fromOffset(6, 157))
		local count = C.Text(frame, "", UDim2.new(1, -12, 0, 25), UDim2.fromOffset(6, 180), 17)
		local sell = C.Button(frame, "Sell 1", UDim2.new(0.5, -12, 0, 44), UDim2.fromOffset(8, 212), function()
			if state and SafeInventory.Sellable(state, item.Id) > 0 then
				remotes.Sell:FireServer(item.Id, 1)
			end
		end, C.Green, { TextSize = 16 })
		local all = C.Button(frame, "Sell All", UDim2.new(0.5, -12, 0, 44), UDim2.new(0.5, 4, 0, 212), function()
			local available = state and SafeInventory.Sellable(state, item.Id) or 0
			if available > 0 then
				remotes.Sell:FireServer(item.Id, available)
			end
		end, C.Green, { TextSize = 16 })
		local display = C.Button(frame, "Display", UDim2.new(1, -16, 0, 44), UDim2.fromOffset(8, 266), function()
			if state and SafeInventory.Displayable(state, item.Id) > 0 and freeSlot() then
				remotes.Display:FireServer(item.Id, freeSlot())
			end
		end, C.Blue, { TextSize = 17, DisabledSound = "DisplayLocked" })
		local putBack = C.Button(frame, "Put Back", UDim2.new(1, -16, 0, 44), UDim2.fromOffset(8, 314), function()
			local slot = displaySlot(item.Id)
			if slot then
				remotes.Display:FireServer(nil, slot)
			end
		end, C.Navy, { TextSize = 17, DisabledSound = "DisplayLocked" })
		return {
			Frame = frame,
			Name = name,
			Odds = odds,
			Count = count,
			Sell = sell,
			All = all,
			Display = display,
			PutBack = putBack,
		}
	end
	render = function()
		if not state or not panel.Visible or rewards.Frame.Visible then
			return
		end
		local total, rarityCounts = index:Progress(state)
		counter.Text = "Discovered " .. total .. "/" .. #Items
		progress.Set(total / #Items)
		for name, button in pairs(tabs.Buttons) do
			local entry = rarityCounts[name]
			button.Text = name
				.. " "
				.. (if entry then entry.Discovered .. "/" .. entry.Total else total .. "/" .. #Items)
		end
		local visible = 0
		for order, item in ipairs(Items) do
			local discovered = (state.Collection[item.Id] or 0) > 0
			local name = if discovered then item.Name else "???"
			local show = (filter == "All" or filter == item.Rarity)
				and string.find(string.lower(name), string.lower(search.Text), 1, true) ~= nil
			local card = cards[item.Id]
			if show and not card then
				card = makeCard(item, order)
				cards[item.Id] = card
			end
			if card then
				card.Frame.Visible = show
				if show then
					visible += 1
					local count, available, slot =
						state.Inventory[item.Id] or 0, SafeInventory.Sellable(state, item.Id), displaySlot(item.Id)
					local signature = table.concat({
						tostring(discovered),
						count,
						available,
						slot or 0,
						SafeInventory.Displayed(state, item.Id),
						freeSlot() or 0,
					}, ":")
					if card.Signature ~= signature then
						card.Signature = signature
						card.Name.Text, card.Odds.Text =
							name, if discovered then "1 in " .. C.Commas(item.Chance) else "Undiscovered"
						card.Count.Text = "x" .. count .. " owned  |  " .. available .. " to sell"
						card.Sell.Interactable, card.All.Interactable = available > 0, available > 0
						card.Display.Text = if count == 0
							then "No copies"
							elseif SafeInventory.Displayable(state, item.Id) == 0 then "All displayed"
							elseif not freeSlot() then "Slots full"
							else "Display"
						card.Display.Interactable = SafeInventory.Displayable(state, item.Id) > 0 and freeSlot() ~= nil
						card.PutBack.Interactable = slot ~= nil
					end
					if card.Discovered ~= discovered then
						if card.Preview then
							card.Preview:Destroy()
						end
						card.Preview = Preview.Create(
							card.Frame,
							UDim2.new(1, -28, 0, 88),
							UDim2.fromOffset(14, 9),
							item,
							nil,
							not discovered
						)
						card.Discovered = discovered
					end
				end
			end
		end
		empty.Visible = visible == 0
	end
	rewardsButton.Activated:Connect(function()
		rewards.Frame.Visible = not rewards.Frame.Visible
		grid.Visible, tabs.Frame.Visible, help.Visible, search.Visible =
			not rewards.Frame.Visible, not rewards.Frame.Visible, not rewards.Frame.Visible, not rewards.Frame.Visible
		rewardsButton.Text = if rewards.Frame.Visible then "Items" else "Rewards"
		slotsButton.Visible = not rewards.Frame.Visible
		render()
	end)
	search:GetPropertyChangedSignal("Text"):Connect(render)
	panel:GetPropertyChangedSignal("Visible"):Connect(render)
	local function openSlot(slot)
		if not state or type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > state.DisplaySlots then
			return
		end
		selectedSlot = slot
		rewards.Frame.Visible = false
		rewardsButton.Text = "Rewards"
		grid.Visible, tabs.Frame.Visible, help.Visible, search.Visible, slotsButton.Visible =
			true, true, true, true, true
		filter, search.Text = "All", ""
		tabs.Select("All")
		grid.CanvasPosition = Vector2.new()
		help.Text = "Choose an item for display " .. slot
		slotsPanel.Visible, panel.Visible = false, true
		render()
	end
	local function renderSlots()
		if not state or not slotsPanel.Visible then
			return
		end
		for slot = 1, state.DisplaySlots do
			if not slotButtons[slot] then
				slotButtons[slot] = C.Button(slotGrid, "Slot " .. slot, UDim2.fromOffset(150, 68), nil, function()
					if state.Displays[tostring(slot)] then
						remotes.Display:FireServer(nil, slot)
					else
						openSlot(slot)
					end
				end, C.Blue, { TextSize = 17 })
				slotButtons[slot].LayoutOrder = slot
			end
		end
		for slot, button in pairs(slotButtons) do
			button.Visible = slot <= state.DisplaySlots
			button.Text = "Slot " .. slot .. "\n" .. (if state.Displays[tostring(slot)] then "Put Back" else "Place")
		end
	end
	slotsButton = C.Button(body, "Slots", UDim2.fromOffset(92, 36), UDim2.new(1, -96, 0, 156), function()
		selectedSlot = nil
		help.Text = "First copies can be displayed."
		panel.Visible, slotsPanel.Visible = false, true
		renderSlots()
	end, C.Blue, { TextSize = 17 })
	return {
		Panel = panel,
		SlotsPanel = slotsPanel,
		OpenSlot = openSlot,
		Update = function(snapshot)
			state = snapshot
			if selectedSlot and (selectedSlot > state.DisplaySlots or state.Displays[tostring(selectedSlot)]) then
				selectedSlot = nil
				help.Text = "First copies can be displayed."
			end
			rewards.Update(state)
			render()
			renderSlots()
		end,
	}
end
return Collection
