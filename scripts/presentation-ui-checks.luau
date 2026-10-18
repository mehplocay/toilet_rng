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
controller:Show(item("Poop"))
assert(
	presentationHUD.Frame.FlushReveal.RevealContent.Odds.Text:find("Fallback drop", 1, true)
		and not presentationHUD.Frame.FlushReveal.RevealContent.Odds.Text:find("1 in", 1, true),
	"Poop must not advertise an unused 1-in-2 roll"
)
do
	-- Boxless Common result: no panel, fill or border; outlined tinted name, tag, short odds.
	local revealCard = presentationHUD.Frame.FlushReveal
	assert(revealCard.Visible and revealCard.BackgroundTransparency == 1)
	for _, child in ipairs(revealCard:GetChildren()) do
		if child.Name ~= "RevealContent" and child:IsA("GuiObject") then
			assert(not child.Visible, "Common result still draws card chrome: " .. child.Name)
		end
	end
	local result = revealCard.RevealContent
	assert(result.BackgroundTransparency == 1, "Common result has a background fill")
	assert(result.ItemName:FindFirstChild("RarityTint") and result.ItemName.UIStroke.Thickness >= 3)
	assert(result.Odds.Text:find("COMMON", 1, true) and not result:FindFirstChild("Shine"))
	assert(not result:FindFirstChild("RarityTag") and result.ItemName.TextSize >= 18)
	for _, label in ipairs({ result.ItemName, result.Odds }) do
		assert(label.UITextSizeConstraint.MinTextSize >= 14, label.Name .. " below 14 px")
		assert(label.BackgroundTransparency == 1)
	end
	local bounce = result.Preview:FindFirstChild("Bounce")
	assert(bounce, "Common card icon bounce missing")
	H.Advance(0.1)
	assert(bounce.Scale >= 1, "Icon bounce must not shrink the icon")
end
controller:Skip()
controller:Show(item("Mystery"), { FlushId = 5 })
assert(not controller.Queue.Active, "Duplicate authoritative result replayed")
controller:Show(item("GoldenPoop"), { FlushId = 6 })
assert(controller.Queue.Active.Tier == "Banner")
assert(not presentationHUD.Frame.FlushReveal.Visible, "Big reveals hide the small result")
assert(presentationRoot.RareReveal.RevealContent.AbsoluteSize.X == 375)
H.Snapshot(presentationRoot, "legendary-portrait")
H.Advance(2.1)
assert(not controller.Queue.Active and not H.RenderBindings.FlushRevealShake)
controller:Show(item("Mystery"), { FlushId = 7 })
H.Advance(4.9)
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
	H.Advance(4.81)
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

-- Boxless result block: one centred group in the upper-middle hint band, clear of the Flush
-- button, pointer, coin popup and lower half; one rarity word only (Rare+ use the stinger).
do
	local HUDLayout = H.Load("src/client/UI/Layout")
	local function overlaps(a, b)
		return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
	end
	local checked = 0
	for _, touch in ipairs({ false, true }) do
		H.Services.UserInputService.TouchEnabled = touch
		for _, viewport in ipairs(H.Viewports) do
			local w, h = viewport[1], viewport[2]
			local blockRoot = H.Root(w, h)
			local blockHUD = { Frame = blockRoot, SetHintVisible = function() end }
			local reveals = H.Load("src/client/Presentation/RevealController").Create(blockRoot, blockHUD, {
				Play = function() end,
				Duck = function() end,
			})
			local layout = HUDLayout.Compute(w, h, touch)
			for index, name in ipairs({ "Poop", "Rat", "Duck" }) do
				reveals:Show(item(name), { FlushId = index, Cooldown = 1.5 })
				local card = blockRoot.FlushReveal
				assert(card.Visible, name .. " result hidden")
				local r = {
					X = card.Position.X.Offset,
					Y = card.Position.Y.Offset,
					W = card.Size.X.Offset,
					H = card.Size.Y.Offset,
				}
				local band = layout.Hint
				assert(r.X == band.X and r.Y == band.Y and r.W == band.W and r.H == band.H, "Result left the hint band")
				for _, key in ipairs({ "Action", "Pointer", "CoinPopup" }) do
					assert(not layout[key] or not overlaps(r, layout[key]), name .. " result overlaps " .. key)
				end
				assert(r.Y + r.H <= h * 0.6, string.format("Result too low at %dx%d", w, h))
				local content = card.RevealContent
				local oddsText = content.Odds.Text
				local rarity = string.upper(item(name).Rarity)
				if name == "Poop" then
					assert(oddsText:find(rarity, 1, true), "Common result needs its small rarity tag")
				else
					assert(not oddsText:find(rarity, 1, true), name .. " repeats the rarity next to the stinger")
				end
				assert(not content:FindFirstChild("RarityTag"))
				local minimum = if layout.Phone then 18 else 22
				assert(content.ItemName.TextSize >= minimum, name .. " name too small")
				assert(content.Odds.TextSize >= 14, name .. " odds below 14 px")
				-- Icon, name and odds form one centred group inside the band.
				local icon, label = content.Preview, content.ItemName
				local left = icon.Position.X.Offset
				local right = label.Position.X.Offset + label.Size.X.Offset
				assert(left >= 0 and right <= r.W + 1, name .. " group leaves the band")
				assert(math.abs(left - (r.W - right)) <= 2, name .. " group is not centred")
				assert(label.Position.X.Offset >= left + icon.Size.X.Offset, "Name overlaps its icon")
				reveals:Skip()
				checked += 1
			end
			reveals:Destroy()
			blockRoot:Destroy()
		end
	end
	H.Services.UserInputService.TouchEnabled = false
	print("Boxless result block: " .. checked .. " placements clear of Flush button and prompt band")
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
