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
H.Services.UserInputService.InputBegan:Fire({ UserInputType = "UserInputType.Touch" })
assert(controller.Queue.Active.Item.Id == "Mystery" and #controller.Queue.Pending == 1)
controller:SetIntensity("Reduced")
assert(not controller.Queue.Active and #controller.Queue.Pending == 0 and not H.RenderBindings.FlushRevealShake)
controller:Show(item("Mystery"), { FlushId = 4 })
assert(controller.Queue.Active.Tier == "Pop" and not H.RenderBindings.FlushRevealShake)
controller:SetIntensity("Off")
local count = #cues
controller:Show(item("Mystery"), { FlushId = 5 })
assert(not controller.Queue.Active and #cues == count)
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

local chatService = H.Services.TextChatService
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
assert(#messages == 1 and messages[1][1]:find("bTester flushed", 1, true) and not messages[1][1]:find("<b>", 1, true))
chat.Enabled = false
chatRemote.OnClientEvent:Fire({ ItemId = "KingPoop", PlayerName = "Tester" })
assert(#messages == 1)
chat:Destroy()

local listRoot = H.Root(724, 318)
local players = {}
for i, coins in ipairs({ 900, 1200, 1000000 }) do
	local player = H.Instance.new("Player")
	player.Name, player.UserId = "Player" .. i, i
	local stats = H.Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	local money = H.Instance.new("NumberValue")
	money.Name, money.Value, money.Parent = "Coins", coins, stats
	local rarest = H.Instance.new("StringValue")
	rarest.Name, rarest.Value, rarest.Parent = "Rarest", "Mythic", stats
	table.insert(players, player)
end
H.PlayerList = players
local list = H.Load("src/client/Presentation/PlayerList").Create(listRoot)
list.Toggle()
local rows = listRoot.ServerPlayers.ScrollingFrame
assert(rows["3"].LayoutOrder == 1 and rows["1"].LayoutOrder == 3 and rows["3"].Coins.Text == "1M")
players[1].leaderstats.Coins.Value = 2e6
H.Advance(1.1)
assert(rows["1"].LayoutOrder == 1 and rows["1"].Coins.Text == "2M")
table.remove(players, 2)
H.Advance(1.1)
assert(not rows:FindFirstChild("2"))
H.Snapshot(listRoot, "player-list-landscape")
list.Destroy()
H.PlayerList = nil
print(
	"Presentation runtime passed: cinematic template/rotation hooks, camera restore, skip, queue cap, modes, cleanup, chat opt-out and numerical player sorting"
)
