local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local function configurePrompt(object)
	if object:IsA("ProximityPrompt") then
		local function update()
			local owner = object:GetAttribute("OwnerUserId")
			if owner then
				object.Enabled = owner == player.UserId
			end
		end
		object:GetAttributeChangedSignal("OwnerUserId"):Connect(update)
		update()
	end
end
workspace.DescendantAdded:Connect(configurePrompt)
for _, object in ipairs(workspace:GetDescendants()) do
	configurePrompt(object)
end
local Config = game.ReplicatedStorage.Shared.Config
local definitions, Items, Rarities = require(Config.Remotes), require(Config.Items), require(Config.Rarities)
local folder = game.ReplicatedStorage:WaitForChild(definitions.Folder)
local remotes = {}
for _, name in ipairs({
	"State",
	"Result",
	"Sell",
	"BuyToilet",
	"Display",
	"Event",
	"ServerLuck",
	"Settings",
	"AutoFlush",
	"DevGrant",
}) do
	remotes[name] = folder:WaitForChild(definitions[name])
end
local C = require(script.UI.Components)
local gui = C.New(
	"ScreenGui",
	player:WaitForChild("PlayerGui"),
	{ Name = "ToiletUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }
)
local screen = gui
gui = C.New("Frame", screen, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
local scale = C.New("UIScale", gui, { Scale = 1 })
local function resize()
	local camera = workspace.CurrentCamera
	if camera then
		scale.Scale = math.clamp(camera.ViewportSize.Y / 720, 0.65, 1)
		gui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
	end
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
resize()
local coins = C.Text(gui, "Loading coins...", UDim2.fromScale(0.23, 0.065), UDim2.fromScale(0.75, 0.025))
coins.BackgroundTransparency = 0
coins.BackgroundColor3 = C.Navy
C.Round(coins)
local collection = require(script.UI.Collection).Create(gui, remotes)
local upgrades = require(script.UI.Upgrades).Create(gui, remotes)
if RunService:IsStudio() then
	local panel = C.New("Frame", gui, {
		Size = UDim2.fromScale(0.28, 0.16),
		Position = UDim2.fromScale(0.02, 0.81),
		BackgroundColor3 = C.Navy,
	})
	C.Round(panel, Color3.fromRGB(220, 80, 80))
	C.Text(panel, "DEV", UDim2.fromScale(0.18, 0.28), UDim2.fromScale(0.02, 0.02))
	for index, grantKey in ipairs({ "1000", "100000", "10000000" }) do
		local labels = { "+1,000", "+100,000", "+10,000,000" }
		C.Button(
			panel,
			labels[index],
			UDim2.fromScale(0.3, 0.55),
			UDim2.fromScale(0.03 + (index - 1) * 0.32, 0.38),
			function()
				remotes.DevGrant:FireServer(grantKey)
			end,
			Color3.fromRGB(160, 55, 65)
		)
	end
end
local settings = C.Panel(gui, "Settings")
local soundOn = true
local soundGroup = C.New("SoundGroup", SoundService, { Name = "ToiletSounds" })
local toggle
local function updateSounds()
	soundGroup.Volume = if soundOn then 1 else 0
	for _, sound in ipairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") then
			sound.SoundGroup = soundGroup
		end
	end
end
workspace.DescendantAdded:Connect(function(object)
	if object:IsA("Sound") then
		object.SoundGroup = soundGroup
	end
end)
toggle = C.Button(settings, "Sound: ON", UDim2.fromScale(0.6, 0.16), UDim2.fromScale(0.2, 0.35), function()
	soundOn = not soundOn
	toggle.Text = if soundOn then "Sound: ON" else "Sound: OFF"
	updateSounds()
	remotes.Settings:FireServer(soundOn)
end)
C.Text(settings, "Sound settings are saved.", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.6))
local function open(panel)
	for _, other in ipairs({ collection.Panel, upgrades.Panel, settings }) do
		other.Visible = other == panel and not other.Visible
	end
end
local colors = {
	Color3.fromRGB(230, 65, 70),
	Color3.fromRGB(35, 150, 225),
	Color3.fromRGB(40, 175, 110),
	Color3.fromRGB(160, 65, 225),
	Color3.fromRGB(65, 85, 105),
}
for index, name in ipairs({ "Shop", "Collection", "Upgrades", "Teleport", "Settings" }) do
	C.Button(gui, name, UDim2.fromScale(0.16, 0.075), UDim2.fromScale(0.025, 0.24 + (index - 1) * 0.09), function()
		if name == "Collection" then
			open(collection.Panel)
		elseif name == "Settings" then
			open(settings)
		elseif name == "Teleport" then
			local position = player:GetAttribute("PlotPosition")
			if typeof(position) == "Vector3" and player.Character then
				player.Character:PivotTo(CFrame.new(position))
			end
		else
			open(upgrades.Panel)
		end
	end, colors[index])
end
local popup = C.New("Frame", gui, {
	Visible = false,
	Size = UDim2.fromScale(0.43, 0.2),
	Position = UDim2.fromScale(0.34, 0.72),
	BackgroundColor3 = C.Navy,
})
C.Round(popup)
local resultText = C.Text(popup, "", UDim2.fromScale(0.94, 0.9), UDim2.fromScale(0.03, 0.05))
local effects = require(script.Effects).Create(gui, soundGroup)
local autoOwned, autoEnabled = false, false
local autoButton
autoButton = C.Button(
	gui,
	"Auto Flush: Coming soon",
	UDim2.fromScale(0.23, 0.06),
	UDim2.fromScale(0.75, 0.1),
	function()
		if autoOwned then
			remotes.AutoFlush:FireServer(not autoEnabled)
		end
	end
)
remotes.Event.OnClientEvent:Connect(effects.Event)
remotes.ServerLuck.OnClientEvent:Connect(effects.Luck)
local generation = 0
remotes.Result.OnClientEvent:Connect(function(action, payload)
	generation += 1
	local token = generation
	if action == "Flush" then
		for _, item in ipairs(Items) do
			if item.Id == payload.ItemId then
				local rarity = Rarities[item.Rarity]
				effects.Drop(item)
				resultText.Text = item.Name .. "\n" .. item.Rarity .. " - 1 in " .. item.Chance
				resultText.TextColor3 = rarity.Color
				popup.Size = if rarity.Order >= 4 then UDim2.fromScale(0.52, 0.26) else UDim2.fromScale(0.43, 0.2)
				if rarity.Order >= 4 then
					TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Rotation = 3 }):Play()
				else
					popup.Rotation = 0
				end
			end
		end
	elseif payload.Success == false then
		resultText.Text = "Request unavailable. Check coins, items or display slots."
		resultText.TextColor3 = Color3.fromRGB(255, 180, 100)
	else
		return
	end
	popup.Visible = true
	task.delay(3, function()
		if generation == token then
			popup.Visible = false
		end
	end)
end)
remotes.State.OnClientEvent:Connect(function(state)
	soundOn = state.Settings.Sound
	toggle.Text = if soundOn then "Sound: ON" else "Sound: OFF"
	updateSounds()
	autoOwned, autoEnabled = state.OwnedPasses.AutoFlush == true, state.AutoFlush
	autoButton.Text = if autoOwned
		then (if autoEnabled then "Auto Flush: ON" else "Auto Flush: OFF")
		else "Auto Flush: Coming soon"
	effects.Luck(state.ServerLuckExpires)
	coins.Text = tostring(state.Coins) .. " Coins"
	collection.Update(state)
	upgrades.Update(state)
end)
remotes.State:FireServer()
