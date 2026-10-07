do
	local C = H.Load("src/client/UI/Components")
	local root = H.Root(1280, 720)
	H.Services.Players.LocalPlayer.CharacterRemoving = H.Services.Players.LocalPlayer.CharacterRemoving or H.Signal()
	local remote = { OnClientEvent = H.Signal(), Calls = {} }
	function remote:FireServer(...)
		table.insert(self.Calls, { ... })
	end
	local window = H.Load("src/admin-client/Window").Create(root, remote, C)
	assert(not window.Panel.Visible and window.Open.Text == "Admin")
	assert(window.Pages.Items and not window.Pages.Economy, "Tabs must be lazy")
	assert(remote.Calls[1][2] == "Hello")
	remote.OnClientEvent:Fire(1, { Success = true, Message = "Ready" })
	window.Open.Activated:Fire()
	assert(window.Panel.Visible and remote.Calls[2][2] == "Snapshot")
	remote.OnClientEvent:Fire(
		2,
		{ Success = true, Message = "Ready", Data = { Coins = 1e300, ToiletTier = 1, RebirthLevel = 0 } }
	)
	local initialCalls = #remote.Calls
	for _, args in ipairs({
		{ Amount = 1 },
		{ Amount = 1, Slot = 0 / 0 },
		{ Amount = 1, Slot = 0 },
		{
			Amount = 1,
			Slot = 101,
		},
	}) do
		window.Send("Pending", args)
	end
	window.Send("Give", { ItemId = "Poop", Count = 0 })
	window.Send("Give", { ItemId = "Poop", Count = 10001 })
	window.Send("SetCoins", { Amount = math.huge })
	window.Send("Upgrade", { Track = "CashBoost", Level = 101 })
	assert(#remote.Calls == initialCalls, "Invalid numeric fields must not lock the UI waiting for a dropped request")
	H.Services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.F2 }, true)
	assert(window.Panel.Visible, "Processed F2 must not toggle the panel while typing")
	for _, name in ipairs({ "Items", "Economy", "Player", "Events", "Map / Debug", "Tools" }) do
		window.Select(name)
		assert(window.Pages[name].Visible)
		for _, size in ipairs(H.Viewports) do
			root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
			root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
			H.Layout(root)
			for _, object in ipairs(window.Pages[name]:GetDescendants()) do
				if object:IsA("TextButton") then
					assert(object.AbsoluteSize.X >= 44 and object.AbsoluteSize.Y >= 44, name .. " touch target")
				end
			end
		end
	end
	window.Select("Items")
	local itemField = window.Pages.Items:FindFirstChild("Item ID", true)
	local nextItem = window.Pages.Items:FindFirstChild("Next catalog item", true)
	for _, item in ipairs(H.Load("src/shared/Config/Items")) do
		assert(itemField.Text == item.Id, "Admin item picker omitted " .. item.Id)
		nextItem.Activated:Fire()
	end
	if previewIcons then
		for _, size in ipairs({ { 1280, 720 }, { 390, 722 }, { 640, 303 } }) do
			root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
			root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
			H.Layout(root)
			H.Snapshot(root, "admin-" .. size[1] .. "x" .. size[2])
		end
	end
	window.Pages.Items:FindFirstChild("Spawn into inventory", true).Activated:Fire()
	local request = remote.Calls[#remote.Calls]
	assert(request[2] == "Give" and request[3].ItemId == "Poop" and request[3].Count == 1)
	local before = #remote.Calls
	window.Pages.Items:FindFirstChild("Spawn into inventory", true).Activated:Fire()
	assert(#remote.Calls == before, "Pending clicks must not replay a grant")
	remote.OnClientEvent:Fire(request[1], { Success = true, Message = "Saved" })
	window.Select("Economy")
	local economy = window.Pages.Economy
	local toilets = H.Load("src/shared/Config/Toilets")
	local toiletField = economy:FindFirstChild("Toilet tier (1-" .. #toilets .. ")", true)
	for tier in ipairs(toilets) do
		assert(toiletField.Text == tostring(tier))
		economy:FindFirstChild("Next catalog toilet", true).Activated:Fire()
	end
	assert(toiletField.Text == "1", "Admin toilet picker must wrap after tier 15")
	local levelBox = economy:FindFirstChild("Track / rebirth level", true)
	local picker = economy:FindFirstChild("Upgrade track: CashBoost", true)
	for _, track in ipairs(H.Load("src/shared/Config/Upgrades").Tracks) do
		levelBox.Text = tostring(track.MaxLevel)
		economy:FindFirstChild("Set selected upgrade level", true).Activated:Fire()
		request = remote.Calls[#remote.Calls]
		assert(request[2] == "Upgrade" and request[3].Track == track.Id and request[3].Level == track.MaxLevel)
		remote.OnClientEvent:Fire(request[1], { Success = true, Message = "Saved" })
		before = #remote.Calls
		levelBox.Text = tostring(track.MaxLevel + 1)
		economy:FindFirstChild("Set selected upgrade level", true).Activated:Fire()
		assert(#remote.Calls == before, "Admin accepted an out-of-range track level")
		picker.Activated:Fire()
	end
	levelBox.Text = "15"
	economy:FindFirstChild("Set rebirth level (no rebirth reset)", true).Activated:Fire()
	request = remote.Calls[#remote.Calls]
	assert(request[2] == "Rebirth" and request[3].Level == 15)
	remote.OnClientEvent:Fire(request[1], { Success = true, Message = "Saved" })
	before = #remote.Calls
	window.Select("Player")
	window.Pages.Player:FindFirstChild("Reset my tutorial", true).Activated:Fire()
	request = remote.Calls[#remote.Calls]
	assert(request[2] == "ResetTutorial" and next(request[3]) == nil, "Tutorial reset must target only the sender")
	remote.OnClientEvent:Fire(request[1], { Success = true, Message = "Saved" })
	assert(not window.Panel.Visible, "Owner reset must reveal the tutorial after confirmation")
	before = #remote.Calls
	window.Pages.Player:FindFirstChild("Confirm reset + create backup", true).Activated:Fire()
	assert(#remote.Calls == before, "Reset must have a challenge and explicit text")
	window.Select("Tools")
	window.Pages.Tools:FindFirstChild("Export current profile JSON", true).Activated:Fire()
	request = remote.Calls[#remote.Calls]
	remote.OnClientEvent:Fire(request[1], { Success = true, Message = "Copy", Data = { Json = '{"Coins":1000}' } })
	assert(window.Pages.Tools:FindFirstChild("Profile JSON (select / copy / paste)", true).Text == '{"Coins":1000}')
	root:Destroy()
	before = #remote.Calls
	H.Services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.F2 }, false)
	H.Services.RunService.Heartbeat:Fire(6)
	assert(#remote.Calls == before, "Destroyed admin client leaked input/renewal callbacks")
	print(
		"Admin UI: lazy tabs, responsive 44px controls, request serialization, reset guard, JSON export and cleanup pass"
	)
end
