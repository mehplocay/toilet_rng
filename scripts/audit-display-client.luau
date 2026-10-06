test("display UI: Display places another owned copy instead of removing the first", function()
	local root = H.Instance.new("Frame")
	local remotes = H.Remotes()
	local collection = H.Load("src/client/UI/Collection").Create(root, remotes)
	local state = {
		Collection = { Poop = 1 },
		Inventory = { Poop = 3 },
		Displays = { ["1"] = "Poop" },
		DisplaySlots = 3,
		IndexClaims = {},
		Stamps = 0,
	}
	collection.Update(state)
	collection.Panel.Visible = true
	local card = collection.Panel:FindFirstChild("Poop", true)
	card:FindFirstChild("Display").Activated:Fire()
	local call = H.Calls[#H.Calls]
	assert(
		call.Name == "Display" and call.Args[1] == "Poop" and call.Args[2] == 2,
		"Display toggled removal instead of placing duplicate"
	)
	root:Destroy()
end)

test("collect UI: owner filtering survives stream-in and ownership changes for jar and pads", function()
	H.Load("src/client/UI/FlushPrompt").Start()
	for _, slot in ipairs({ 0, 1, 10 }) do
		local prompt = H.Instance.new("ProximityPrompt")
		prompt.ActionText = if slot == 0 then "Collect All" else "Collect"
		prompt:SetAttribute("OwnerUserId", -1)
		prompt:SetAttribute("IncomeOwnerUserId", -1)
		prompt.Parent = H.Workspace
		H.Workspace.DescendantAdded:Fire(prompt)
		assert(prompt.Enabled == false, "Foreign prompt enabled")
		prompt:SetAttribute("OwnerUserId", H.Services.Players.LocalPlayer.UserId)
		assert(prompt.Enabled == true, "Own collect prompt disabled")
		H.Workspace.DescendantRemoving:Fire(prompt)
		prompt.Parent = nil
		prompt:SetAttribute("OwnerUserId", -1)
		prompt.Parent = H.Workspace
		H.Workspace.DescendantAdded:Fire(prompt)
		assert(prompt.Enabled == false, "Streamed prompt retained old owner visibility")
		H.Workspace.DescendantRemoving:Fire(prompt)
		prompt:Destroy()
	end
end)

test("collect UI: popup plays its accent, shows +N and releases all coin flights", function()
	local C = H.Load("src/client/UI/Components")
	local oldHook, sounds = C.SoundHook, 0
	C.SoundHook = function(name)
		assert(name == "CoinPopup", "Popup duplicated the confirmed collection success cue")
		sounds += 1
	end
	local service = H.Services.TweenService
	local create, flights, completed = service.Create, 0, {}
	service.Create = function(self, target, info, props)
		local tween = create(self, target, info, props)
		if target.Name == "IncomeCoinFlight" then
			flights += 1
		end
		table.insert(completed, tween)
		return tween
	end
	local root = H.Instance.new("Frame")
	root._fixed = Vector2.new(360, 518)
	H.Load("src/client/UI/CoinPopup").Create(root)(123, true)
	assert(sounds == 1 and flights == 5 and root.ServiceCoinPopup:FindFirstChild("TextLabel", true).Text == "+123")
	for _, tween in ipairs(completed) do
		tween.Completed:Fire()
	end
	assert(#root:GetChildren() == 0, "Completed income animation leaked instances")
	service.Create, C.SoundHook = create, oldHook
	root:Destroy()
end)

test("collect UI: income glow follows readiness, camera distance and stream cleanup", function()
	H.Load("src/client/VisualIdle").Start()
	local loop = coroutine.create(H.Spawned[#H.Spawned])
	local part, glow = H.Instance.new("Part"), H.Instance.new("PointLight")
	part.Position, part.Parent = Vector3.new(), H.Workspace
	glow:SetAttribute("VisualIdle", true)
	glow:SetAttribute("IncomeGlow", true)
	glow:SetAttribute("IncomeReady", false)
	glow.FindFirstAncestor = function()
		return nil
	end
	glow.Parent = part
	H.Workspace.DescendantAdded:Fire(glow)
	local function tick()
		local ok, err = coroutine.resume(loop)
		assert(ok, err)
	end
	tick()
	assert(glow.Enabled == false)
	glow:SetAttribute("IncomeReady", true)
	tick()
	assert(glow.Enabled == true)
	part.Position = Vector3.new(1000, 0, 0)
	tick()
	assert(glow.Enabled == false)
	part.Position = Vector3.new()
	tick()
	assert(glow.Enabled == true)
	glow:SetAttribute("IncomeReady", false)
	tick()
	assert(glow.Enabled == false)
	H.Workspace.DescendantRemoving:Fire(glow)
	part:Destroy()
end)

test("display UI: protected first copy, exact slot selection, Put Back and latest sell reservations", function()
	local C = H.Load("src/client/UI/Components")
	local oldHook, sounds = C.SoundHook, {}
	C.SoundHook = function(name)
		table.insert(sounds, name)
	end
	local root, remotes = H.Instance.new("Frame"), H.Remotes()
	local collection = H.Load("src/client/UI/Collection").Create(root, remotes)
	local state = {
		Collection = { Poop = 1 },
		Inventory = { Poop = 3 },
		ProtectedInventory = { Poop = 2 },
		Displays = {},
		DisplaySlots = 3,
		IndexClaims = {},
		Stamps = 0,
	}
	collection.Update(state)
	collection.Panel:FindFirstChild("Rewards", true).Activated:Fire()
	assert(sounds[#sounds] == "TabSwitch", "Rewards lost its tab sound")
	collection.OpenSlot(3)
	assert(sounds[#sounds] == "Open", "Slot selection lost its panel sound")
	local card = collection.Panel:FindFirstChild("Poop", true)
	assert(
		card.Parent.Visible and collection.Panel:FindFirstChild("Slots", true).Visible,
		"Place left the reward view covering items"
	)
	card.Display.Activated:Fire()
	assert(sounds[#sounds] == "Click", "Placement lost its button sound")
	assert(H.Calls[#H.Calls].Args[1] == "Poop" and H.Calls[#H.Calls].Args[2] == 3)
	state.Displays["3"] = "Poop"
	collection.Update(state)
	card.Display.Activated:Fire()
	assert(H.Calls[#H.Calls].Args[1] == "Poop" and H.Calls[#H.Calls].Args[2] == 1)
	state.Displays["1"], state.Displays["2"] = "Poop", "Poop"
	collection.Update(state)
	local calls = #H.Calls
	card.Display.Activated:Fire()
	assert(sounds[#sounds] == "DisplayLocked", "Full slots lost disabled display feedback")
	card["Sell All"].Activated:Fire()
	assert(#H.Calls == calls, "Full reservations remained interactive")
	card["Put Back"].Activated:Fire()
	assert(sounds[#sounds] == "Click", "Put Back lost its button sound")
	assert(H.Calls[#H.Calls].Args[1] == nil and H.Calls[#H.Calls].Args[2] == 3)
	state.Displays["3"] = nil
	collection.Update(state)
	card["Sell All"].Activated:Fire()
	assert(H.Calls[#H.Calls].Name == "Sell" and H.Calls[#H.Calls].Args[2] == 1)
	collection.Panel:FindFirstChild("Slots", true).Activated:Fire()
	assert(collection.SlotsPanel.Visible and not collection.Panel.Visible)
	collection.SlotsPanel:FindFirstChild("Slot 3", true).Activated:Fire()
	assert(collection.Panel.Visible and not collection.SlotsPanel.Visible)
	state.Inventory.Poop, state.Displays = 1, {}
	state.ProtectedInventory.Poop = 1
	collection.Update(state)
	card.Display.Activated:Fire()
	assert(
		H.Calls[#H.Calls].Name == "Display" and H.Calls[#H.Calls].Args[1] == "Poop",
		"Protected first copy was blocked"
	)
	state.Displays["3"] = "Poop"
	collection.Update(state)
	collection.Panel:FindFirstChild("Slots", true).Activated:Fire()
	collection.SlotsPanel:FindFirstChild("Slot 3", true).Activated:Fire()
	assert(H.Calls[#H.Calls].Args[1] == nil and H.Calls[#H.Calls].Args[2] == 3)
	assert(sounds[#sounds] == "Click", "Per-slot Put Back lost its button sound")
	-- Semantic success cues come from Feedback.State, not optimistic UI callbacks.
	for _, name in ipairs(sounds) do
		assert(name ~= "DisplayPlace" and name ~= "DisplayReturn" and name ~= "Sell" and name ~= "SellAll")
	end
	C.SoundHook = oldHook
	root:Destroy()
end)
