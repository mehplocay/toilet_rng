local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local Config = game.ReplicatedStorage.Shared.Config
local definitions, Items, Assets = require(Config.Remotes), require(Config.Items), require(Config.Assets)
local folder = game.ReplicatedStorage:WaitForChild(definitions.Folder)
local remotes = {}
for _, name in ipairs({
	"Flush",
	"State",
	"Result",
	"Sell",
	"BuyToilet",
	"Display",
	"CollectIncome",
	"IncomePending",
	"Event",
	"ServerLuck",
	"Settings",
	"AutoFlush",
	"AnimationSkip",
	"PlotColor",
	"BuyPass",
	"RefreshPasses",
	"DevGrant",
	"TutorialDone",
	"ClaimReward",
	"ClaimIndexReward",
}) do
	remotes[name] = folder:WaitForChild(definitions[name])
end
local C = require(script.UI.Components)
local prompts = require(script.UI.FlushPrompt).Start()
require(script.VisualIdle).Start()
require(script.PlotGuidance).Start()
require(script.VIPChat).Start()
local screen = C.New("ScreenGui", player:WaitForChild("PlayerGui"), {
	Name = "ToiletUI",
	ResetOnSpawn = false,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
	ClipToDeviceSafeArea = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local root = C.New("Frame", screen, { Name = "SafeArea", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
local collection = require(script.UI.Collection).Create(root, remotes)
local upgrades = require(script.UI.Upgrades).Create(root, remotes)
local rewards = require(script.UI.Rewards).Create(root, remotes)
local passes = require(script.UI.Passes).Create(root, remotes)
local settings = C.Panel(root, "Settings", C.Blue)
local soundOn, skipAnimation = true, false
local soundGroup = C.New("SoundGroup", SoundService, { Name = "ToiletSounds" })
-- One startup traversal; new sounds are assigned as they arrive. State only sets group volume.
local function registerSound(object)
	if object:IsA("Sound") then
		object.SoundGroup = soundGroup
	end
end
workspace.DescendantAdded:Connect(registerSound)
for _, object in ipairs(workspace:GetDescendants()) do
	registerSound(object)
end
C.SoundHook = function(key)
	local id = C.AssetId(Assets.Sounds[key])
	if not id or not soundOn then
		return
	end
	local sound = C.New("Sound", SoundService, { SoundId = id, SoundGroup = soundGroup, Volume = 0.35 })
	sound:Play()
	Debris:AddItem(sound, 5)
end
local settingsList = C.Scroll(settings.ContentScroll.Body, UDim2.fromScale(1, 1))
C.New("UIListLayout", settingsList, { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder })
local intro = C.BodyText(settingsList, "Play your way. Your preferences are saved.", UDim2.new(1, -18, 0, 46))
intro.LayoutOrder = 1
local toggle
local function settingsRow(title, description, order, callback)
	local row = C.Card(settingsList, C.Blue)
	row.Size, row.LayoutOrder = UDim2.new(1, -18, 0, 130), order
	C.Text(row, title, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 8), 24).TextXAlignment = Enum.TextXAlignment.Left
	C.BodyText(row, description, UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 39)).TextXAlignment =
		Enum.TextXAlignment.Left
	return C.Button(row, "", UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, 76), callback, C.Green, { TextSize = 20 })
end
toggle = settingsRow("Game sounds", "Flush sounds, rewards and button clicks.", 2, function()
	soundOn = not soundOn
	toggle.Text = if soundOn then "Sound: ON" else "Sound: OFF"
	soundGroup.Volume = if soundOn then 1 else 0
	remotes.Settings:FireServer(soundOn)
end)
local skipToggle = settingsRow(
	"Quick reveals",
	"Shorten drop reveals and skip event effects. Free for everyone.",
	3,
	function()
		remotes.AnimationSkip:FireServer(not skipAnimation)
	end
)
local panels = { collection.Panel, upgrades.Panel, rewards.Panel, passes.Panel, settings }
local dev
if RunService:IsStudio() then
	dev = C.Panel(root, "Developer Tools", Color3.fromRGB(219, 78, 105))
	table.insert(panels, dev)
	local row = C.Scroll(dev.ContentScroll.Body, UDim2.fromScale(1, 1))
	C.New("UIListLayout", row, { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder })
	local note = C.BodyText(row, "Studio test grants • server validated", UDim2.new(1, -18, 0, 50))
	note.LayoutOrder = 1
	for i, key in ipairs({ "1000", "100000", "10000000" }) do
		local button = C.Button(
			row,
			"+" .. C.Commas(tonumber(key)) .. " Coins",
			UDim2.new(1, -18, 0, 58),
			nil,
			function()
				remotes.DevGrant:FireServer(key)
			end,
			C.Purple
		)
		button.LayoutOrder = i + 1
	end
	local button = C.Button(settingsList, "Open Developer Tools", UDim2.new(1, -18, 0, 48), nil, function()
		settings.Visible = false
		dev.Visible = true
	end, C.Purple)
	button.LayoutOrder = 4
end
local backdrop = C.New("TextButton", root, {
	Name = "ModalBackdrop",
	Text = "",
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Ink,
	BackgroundTransparency = 0.26,
	Visible = false,
	Active = true,
	Modal = true,
	ZIndex = 30,
})
local hud
local function closeAll()
	for _, panel in ipairs(panels) do
		panel.Visible = false
	end
end
local function show(panel)
	local wasOpen = panel.Visible
	closeAll()
	panel.Visible = not wasOpen
end
local function travelHome()
	local cf = player:GetAttribute("PlotCFrame")
	if typeof(cf) == "CFrame" and player.Character then
		player.Character:PivotTo(cf)
	end
end
local function open(name)
	if name == "Home" then
		closeAll()
		travelHome()
	elseif name == "Hub" or name == "TravelShop" then
		closeAll()
		local hub = workspace:FindFirstChild("Hub", true)
		local spawn = hub and hub:FindFirstChild(if name == "TravelShop" then "ShowcaseStand" else "SpawnPad")
		if spawn and player.Character then
			local offset = if name == "TravelShop" then Vector3.new(0, 4, -8) else Vector3.new(0, 4, 0)
			player.Character:PivotTo(CFrame.lookAt(spawn.Position + offset, spawn.Position + Vector3.new(0, 4, 1)))
		end
		if name == "TravelShop" then
			show(upgrades.Panel)
		end
	elseif name == "Collection" then
		show(collection.Panel)
	elseif name == "Daily" then
		show(rewards.Panel)
	elseif name == "Passes" then
		show(passes.Panel)
	elseif name == "Settings" then
		show(settings)
	else
		show(upgrades.Panel)
	end
end
hud = require(script.UI.HUD).Create(root, remotes, open, prompts)
local function syncModal()
	local any = false
	for _, panel in ipairs(panels) do
		if panel.Visible then
			any = true
		end
	end
	backdrop.Visible, hud.Frame.Visible = any, not any
end
for _, panel in ipairs(panels) do
	panel:GetPropertyChangedSignal("Visible"):Connect(syncModal)
end
backdrop.Activated:Connect(closeAll)
ContextActionService:BindAction("CloseToiletPanel", function(_, state)
	if state == Enum.UserInputState.Begin and backdrop.Visible then
		closeAll()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.ButtonB)
require(script.UI.Tutorial).Create(player, remotes, hud, prompts)
local effects = require(script.Effects).Create(hud.Frame, soundGroup, hud)
local reveal = require(script.UI.Reveal).Create(hud.Frame, hud)
local showServiceCoins = require(script.UI.CoinPopup).Create(hud.Frame)
local toast = C.Toast(root)
local incomeChip = require(script.UI.IncomeChip).Create(hud.Frame)
local PromptService = game:GetService("ProximityPromptService")
PromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("IncomeOwnerUserId") == player.UserId then
		remotes.CollectIncome:FireServer()
	end
end)
remotes.IncomePending.OnClientEvent:Connect(incomeChip.Update)
local byId = {}
for _, item in ipairs(Items) do
	byId[item.Id] = item
end
remotes.Event.OnClientEvent:Connect(function(payload)
	effects.Event(payload)
	local item = byId[payload.ItemId]
	if item then
		hud.Best(payload.PlayerName, item)
	end
end)
remotes.ServerLuck.OnClientEvent:Connect(hud.Luck)
remotes.Result.OnClientEvent:Connect(function(action, payload)
	if action == "Flush" then
		local item = byId[payload.ItemId]
		if not item then
			return
		end
		hud.Flushed(payload)
		hud.Best(player.DisplayName, item)
		showServiceCoins(payload.ServiceCoins)
		effects.Drop(item)
		reveal(item, skipAnimation)
	elseif action == "CollectIncome" then
		toast(
			if payload.Success then "+" .. C.Commas(payload.Coins) .. " display coins collected!" else payload.Message,
			C.Gold
		)
	elseif action == "Sell" or action == "BuyToilet" or action == "Display" or action == "AutoFlush" then
		if payload.Success == false then
			toast(payload.Message or "Not available yet. Check your coins, items or distance.", C.Gold)
		elseif action == "BuyToilet" then
			toast("Upgrade unlocked! Your next great flush awaits.", C.Green)
		end
	end
end)
remotes.State.OnClientEvent:Connect(function(state)
	soundOn, skipAnimation = state.Settings.Sound, state.Settings.SkipAnimation == true
	toggle.Text, skipToggle.Text =
		if soundOn then "Sound: ON" else "Sound: OFF",
		if skipAnimation then "Quick reveals: ON" else "Quick reveals: OFF"
	soundGroup.Volume = if soundOn then 1 else 0
	effects.SetSkip(skipAnimation)
	hud.Update(state)
	incomeChip.Update(state.PendingCoins or 0)
	collection.Update(state)
	upgrades.Update(state)
	rewards.Update(state)
	passes.Update(state)
end)
remotes.State:FireServer()
