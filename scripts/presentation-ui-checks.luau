-- Run after boot/runtime checks, using production controllers with engine doubles.
local presentationRoot = H.Root(375, 690)
local presentationHUD = { Frame = H.Root(375, 690), SetHintVisible = function() end }
local cues = {}
local controller = H.Load("src/client/Presentation/RevealController").Create(presentationRoot, presentationHUD, {
	Play = function(_, cue)
		table.insert(cues, cue)
	end,
	Duck = function() end,
})
local catalog = H.Load("src/shared/Config/Items")
local function item(id)
	for _, entry in ipairs(catalog) do
		if entry.Id == id then
			return entry
		end
	end
	error(id)
end
controller:Show(item("SewerShark"), { FlushId = 1, Probability = 0.00008 })
assert(controller.Queue.Active.Tier == "Cinematic" and H.PreviewBuilds > 0)
local cinematic = presentationRoot.RareReveal.RevealContent
assert(cinematic.ItemViewport.CurrentCamera and cinematic.Skip.AbsoluteSize.Y == 44)
assert(cinematic.Odds.Text:find("Your outcome:", 1, true))
assert(H.RenderBindings.FlushRevealShake and H.RenderBindings.FlushRevealUndo)
H.Snapshot(presentationRoot, "cinematic-portrait")
local camera, base = H.Workspace.CurrentCamera, H.Workspace.CurrentCamera.CFrame
H.RenderBindings.FlushRevealShake(0.1)
assert(camera.CFrame ~= base)
H.RenderBindings.FlushRevealUndo()
assert(camera.CFrame == base)
for _, id in ipairs({ "Poop", "Rat", "Duck" }) do
	controller:Show(item(id))
end
assert(#controller.Queue.Pending == 0 and presentationRoot.RareReveal.CompactDrop.Visible)
controller:Show(item("Mystery"), { FlushId = 2 })
controller:Show(item("KingPoop"), { FlushId = 3 })
for _ = 1, 50 do
	controller:Show(item("Mystery"))
end
assert(#controller.Queue.Pending == 2)
H.Services.UserInputService.InputBegan:Fire({ UserInputType = "UserInputType.Touch", Position = Vector3.new() })
assert(controller.Queue.Active.Item.Id == "Mystery" and #controller.Queue.Pending == 1)
controller:SetIntensity("Reduced")
assert(not controller.Queue.Active and #controller.Queue.Pending == 0 and not H.RenderBindings.FlushRevealShake)
controller:Show(item("Mystery"), { FlushId = 4 })
assert(controller.Queue.Active.Tier == "Pop" and not H.RenderBindings.FlushRevealShake)
controller:SetIntensity("Off")
local count = #cues
controller:Show(item("Mystery"), { FlushId = 5 })
assert(
	not controller.Queue.Active and #cues == count + 1 and cues[#cues] == "Secret",
	"Visual Off must retain SFX feedback"
)
controller:SetIntensity("Full")
controller:Show(item("Mystery"), { FlushId = 5 })
assert(not controller.Queue.Active, "Duplicate authoritative result replayed")
controller:Show(item("GoldenPoop"), { FlushId = 6 })
assert(controller.Queue.Active.Tier == "Banner")
assert(presentationRoot.RareReveal.RevealContent.AbsoluteSize.X == 375)
H.Snapshot(presentationRoot, "legendary-portrait")
H.Advance(2.1)
assert(not controller.Queue.Active and not H.RenderBindings.FlushRevealShake)
controller:Show(item("Mystery"), { FlushId = 7 })
H.Advance(3.1)
assert(not controller.Queue.Active and not H.RenderBindings.FlushRevealUndo)
H.Advance(0.3)
assert(not H.Services.Lighting:FindFirstChild("FlushCinematicTint"), "Tint leaked after completion")
controller:Show(item("Mystery"), { FlushId = 8 })
controller:Destroy()
assert(not H.RenderBindings.FlushRevealShake and not controller.Queue.Active)

-- Upgrade cadence exercises the production controller, including queued rare finds.
for _, viewport in ipairs(H.Viewports) do
	local fastRoot = H.Root(viewport[1], viewport[2])
	local fast = H.Load("src/client/Presentation/RevealController").Create(fastRoot, {
		Frame = fastRoot,
		SetHintVisible = function() end,
	}, { Play = function() end, Duck = function() end })
	local id = 0
	local function show(name, cooldown)
		id += 1
		fast:Show(item(name), { FlushId = id, Cooldown = cooldown })
	end
	show("Duck", 1.5)
	assert(fast.Queue.Active.Tier == "Sparkle", "Base speed lost its tiered reveal")
	H.Advance(1.21)
	assert(not fast.Queue.Active)
	for _, name in ipairs({ "Poop", "ToiletPaper", "Rat", "Duck" }) do
		show(name, 0.4)
		assert(not fast.Queue.Active and #fast.Queue.Pending == 0)
		assert(fastRoot.RareReveal.CompactDrop.Visible, "Fast ordinary drop needs a compact toast")
		H.Advance(0.401)
	end
	show("Mystery", 0.4)
	for _ = 1, 20 do
		show("GoldenPoop", 0.4)
		show("Poop", 0.4)
		show("Duck", 0.4)
		assert(#fast.Queue.Pending <= 2 and fast.Queue.Active.Tier == "Cinematic")
	end
	assert(#fast.Queue.Pending == 2)
	H.Layout(fastRoot)
	local content = fastRoot.RareReveal.RevealContent
	assert(content.Skip.AbsoluteSize.Y >= 44 and content.ItemViewport.AbsoluteSize.Y > 0)
	assert(content.Skip.AbsolutePosition.X >= 0)
	assert(content.Skip.AbsolutePosition.X + content.Skip.AbsoluteSize.X <= viewport[1])
	assert(content.Skip.AbsolutePosition.Y + content.Skip.AbsoluteSize.Y <= viewport[2])
	H.Snapshot(fastRoot, "fast-reveal-" .. viewport[1] .. "x" .. viewport[2])
	H.Advance(3.01)
	assert(fast.Queue.Active.Tier == "Banner" and #fast.Queue.Pending == 1)
	H.Advance(2.01)
	H.Advance(2.01)
	assert(not fast.Queue.Active and #fast.Queue.Pending == 0)
	fast:SetIntensity("Reduced")
	show("Mystery", 0.4)
	assert(not fast.Queue.Active and fastRoot.RareReveal.CompactDrop.Visible)
	fast:SetIntensity("Off")
	show("Mystery", 1.5)
	assert(not fast.Queue.Active)
	fast:Destroy()
	fastRoot:Destroy()
end

local chatService = H.Services.TextChatService
local window = H.Instance.new("ChatWindowConfiguration")
window.Parent = chatService
local channels = H.Instance.new("Folder")
channels.Name, channels.Parent = "TextChannels", chatService
local channel = H.Instance.new("TextChannel")
channel.Name, channel.Parent = "RBXGeneral", channels
local messages = {}
function channel:DisplaySystemMessage(message, metadata)
	table.insert(messages, { message, metadata })
end
local chatRemote = { OnClientEvent = H.Signal() }
local chat = H.Load("src/client/Presentation/ChatAnnouncements").Start(chatRemote)
chatRemote.OnClientEvent:Fire({ ItemId = "KingPoop", PlayerName = "<b>Tester" })
assert(#messages == 0, "Chat must allow CoreScripts to initialize")
H.Advance(2.1)
assert(#messages == 1 and messages[1][1]:find("bTester found", 1, true) and not messages[1][1]:find("<b>", 1, true))
chat:SetMode("Off")
chatRemote.OnClientEvent:Fire({ ItemId = "KingPoop", PlayerName = "Tester" })
assert(#messages == 1)
chat:SetMode("Rare+")
chatRemote.OnClientEvent:Fire({ Kind = "Rebirth", Level = 5, PlayerName = "<b>Tester" })
assert(
	#messages == 2 and messages[2][1]:find("bTester reached Rebirth 5", 1, true) and messages[2][2] == "ToiletRebirth"
)
chatRemote.OnClientEvent:Fire({ Kind = "Rebirth", Level = 500, PlayerName = "Tester" })
assert(#messages == 2)
chatRemote.OnClientEvent:Fire({ Self = true, ItemId = "Fish", Count = 7 })
assert(#messages == 3 and messages[3][1]:find("You found 7 items (best: Rare Fish)!", 1, true))
chat:Destroy()
channels:Destroy()
window:Destroy()

local listRoot = H.Root(724, 318)
local starter = H.Services.StarterGui
starter.CoreEnabled["CoreGuiType.PlayerList"] = false
H.HoldCoreGui = true
local list = H.Load("src/client/Presentation/PlayerList").Create(listRoot)
assert(not listRoot:FindFirstChild("ServerPlayers") and list.Toggle == nil)
H.Advance(0.3)
assert(starter.CoreEnabled["CoreGuiType.PlayerList"] == false)
H.HoldCoreGui = nil
H.Advance(0.3)
assert(starter.CoreEnabled["CoreGuiType.PlayerList"] == true)
local calls = #starter.Calls
H.Services.UserInputService.InputBegan:Fire({ KeyCode = "KeyCode.Tab" }, false)
H.Advance(2)
assert(#starter.Calls == calls, "Native list visibility belongs to CoreScripts")
list.Destroy()
assert(starter.CoreEnabled["CoreGuiType.PlayerList"] == true)
listRoot:Destroy()

local settingsRoot = H.Root(375, 690)
local patches = {}
local settingsUI = H.Load("src/client/Presentation/SettingsUI").Create(settingsRoot, {
	FireServer = function(_, patch)
		table.insert(patches, patch)
	end,
})
local button = settingsRoot.ChatSettings:FindFirstChildWhichIsA("TextButton")
for _, pair in ipairs({ { "All", "Rare+" }, { "Rare+", "Off" }, { "Off", "All" } }) do
	settingsUI.Update({ ChatMessages = pair[1] })
	assert(button.Text == "Chat messages: " .. pair[1])
	button.Activated:Fire()
	assert(patches[#patches].ChatMessages == pair[2])
end
assert(not settingsRoot.PlayerListSettings:FindFirstChildWhichIsA("TextButton"))
settingsRoot:Destroy()
print(
	"Presentation runtime passed: reveal lifecycle, delayed rich-text chat, three chat modes and native PlayerList retry without custom Tab binding"
)
