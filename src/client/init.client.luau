local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local Config = game.ReplicatedStorage.Shared.Config
local definitions, Items = require(Config.Remotes), require(Config.Items)
local folder = game.ReplicatedStorage:WaitForChild(definitions.Folder)
local remotes = {}
for _, name in ipairs({
	"Flush",
	"PresentationSettings",
	"DropAnnouncement",
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
C.PreloadIcons()
local audio = require(script.Audio.AudioService).Start()
C.SoundHook = function(key)
	audio:Play(key)
end
C.AudioHook = function(key, duration)
	audio:Duck(key, duration)
end
script.Destroying:Connect(function()
	audio:Destroy()
	C.SoundHook, C.AudioHook = nil, nil
end)
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
local skipAnimation, autoFlush = false, false
local settingsList = C.Scroll(settings.ContentScroll.Body, UDim2.fromScale(1, 1))
C.New("UIListLayout", settingsList, { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder })
local intro = C.BodyText(settingsList, "Play your way. Your preferences are saved.", UDim2.new(1, -18, 0, 46))
intro.LayoutOrder = 1
local audioSettings = require(script.Audio.SettingsUI).Create(settingsList, remotes.Settings, audio)
local function settingsRow(title, description, order, callback)
	local row = C.Card(settingsList, C.Blue)
	row.Size, row.LayoutOrder = UDim2.new(1, -18, 0, 130), order
	C.Text(row, title, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 8), 24).TextXAlignment = Enum.TextXAlignment.Left
	C.BodyText(row, description, UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 39)).TextXAlignment =
		Enum.TextXAlignment.Left
	return C.Button(row, "", UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, 76), callback, C.Green, { TextSize = 20 })
end
local skipToggle = settingsRow(
	"Quick reveals",
	"Shorten drop reveals and skip event effects. Free for everyone.",
	4,
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
	button.LayoutOrder = 5
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
	if typeof(cf) == "CFrame" then
		pcall(function()
			player:RequestStreamAroundAsync(cf.Position, 3)
		end)
		if player.Character then
			player.Character:PivotTo(cf)
		end
	end
end
local function open(name)
	if name == "Home" then
		closeAll()
		travelHome()
	elseif name == "Hub" or name == "TravelShop" then
		closeAll()
		require(script.WorldNavigation).Travel(name)
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
require(script.WorldNavigation).Start(open)
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
local effects = require(script.Effects).Create(hud.Frame, audio.SFX, hud)
local presentation = require(script.Presentation.Controller).Start(root, hud, remotes, audio, settingsList)
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
		audio:Flush(autoFlush)
		hud.Flushed(payload)
		hud.Best(player.DisplayName, item)
		showServiceCoins(payload.ServiceCoins)
		presentation.Reveal(item, payload)
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
	if payload.Success == false then
		audio:Play("Error")
	elseif payload.Success == true and (action == "BuyToilet" or action == "BuyPass") then
		audio:Play("PurchaseSuccess")
	elseif payload.Success == true and action == "Sell" then
		audio:Play("CoinCollect")
	end
end)
remotes.State.OnClientEvent:Connect(function(state)
	skipAnimation, autoFlush = state.Settings.SkipAnimation == true, state.AutoFlush == true
	audioSettings.Update(state.Settings)
	presentation.Update(state.Settings)
	skipToggle.Text = if skipAnimation then "Quick reveals: ON" else "Quick reveals: OFF"
	effects.SetSkip(
		skipAnimation or state.Settings.RevealIntensity == "Reduced" or state.Settings.RevealIntensity == "Off"
	)
	hud.Update(state)
	incomeChip.Update(state.PendingCoins or 0)
	collection.Update(state)
	upgrades.Update(state)
	rewards.Update(state)
	passes.Update(state)
end)
remotes.State:FireServer()
