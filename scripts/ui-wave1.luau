do
	local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local state = {
		Coins = 9e15,
		ToiletTier = 14,
		Inventory = {},
		Collection = {},
		Displays = {},
		DisplaySlots = 10,
		Stamps = 0,
		IndexClaims = {},
		IndexCosmetics = {},
		Upgrades = {},
		RebirthLevel = 0,
	}
	for _, item in ipairs(items) do
		state.Inventory[item.Id], state.Collection[item.Id] = 2, 2
	end
	local collection = H.Load("src/client/UI/Collection").Create(root, remotes)
	local shop = H.Load("src/client/UI/Upgrades").Create(root, remotes)
	collection.Update(state)
	shop.Update(state)
	collection.Panel.Visible, shop.Panel.Visible = true, true
	local function checkGrid(panel, records)
		local first, last = panel:FindFirstChild(records[1].Id, true), panel:FindFirstChild(records[#records].Id, true)
		assert(first and last and first.Parent == last.Parent)
		local grid = first.Parent
		assert(grid.ClassName == "ScrollingFrame" and grid.AutomaticCanvasSize == Enum.AutomaticSize.Y)
		local bottom = 0
		for _, record in ipairs(records) do
			local card = assert(grid:FindFirstChild(record.Id))
			assert(card.Visible and card.AbsoluteSize.X >= 120)
			assert(card.AbsolutePosition.X >= grid.AbsolutePosition.X)
			assert(card.AbsolutePosition.X + card.AbsoluteSize.X <= grid.AbsolutePosition.X + grid.AbsoluteSize.X + 1)
			bottom = math.max(bottom, card.AbsolutePosition.Y + card.AbsoluteSize.Y - grid.AbsolutePosition.Y)
			for _, control in ipairs(card:GetChildren()) do
				if control:IsA("TextButton") then
					assert(control.AbsoluteSize.X >= 44 and control.AbsoluteSize.Y >= 44)
				end
			end
		end
		assert(bottom > grid.AbsoluteSize.Y, "Expanded catalog must be scrollable")
		grid.CanvasPosition = { X = 0, Y = math.max(0, last.AbsolutePosition.Y - grid.AbsolutePosition.Y) }
		H.Layout(root)
		assert(
			last.AbsolutePosition.Y >= grid.AbsolutePosition.Y - 1
				and last.AbsolutePosition.Y < grid.AbsolutePosition.Y + grid.AbsoluteSize.Y
		)
		grid.CanvasPosition = { X = 0, Y = 0 }
	end
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		checkGrid(collection.Panel, items)
		H.Layout(root)
		checkGrid(shop.Panel, toilets)
	end
	local celestial = collection.Panel:FindFirstChild("Celestial", true)
	assert(celestial and celestial.Text == "Celestial 4/4")
	celestial.Activated:Fire()
	H.Layout(root)
	local shown = 0
	for _, item in ipairs(items) do
		local card = collection.Panel:FindFirstChild(item.Id, true)
		if card.Visible then
			assert(item.Rarity == "Celestial")
			shown += 1
		end
	end
	assert(shown == 4)
	local finalCard = shop.Panel:FindFirstChild("InfinityFlush", true)
	local upgrade = finalCard:FindFirstChild("Locked")
	assert(upgrade.Text == "Upgrade!" and upgrade.Interactable)
	upgrade.Activated:Fire()
	assert(H.Calls[#H.Calls].Name == "BuyToilet" and H.Calls[#H.Calls].Args[1] == "InfinityFlush")
	root:Destroy()
	print(
		"Wave 1 UI: 12 viewports, 47 collection cards, nine rarity groups, 15 shop cards, scrolling and final-tier purchase passed"
	)
end
