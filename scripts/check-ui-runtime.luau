-- Bundled by check-ui.ps1 with the production modules and ui-harness.luau.
local C = H.Load("src/client/UI/Components")
local Assets = H.Load("src/shared/Config/Assets")
local Items = H.Load("src/shared/Config/Items")
local root, remotes = H.Root(1280, 684), H.Remotes()
local state = {
	Coins = 12450,
	Collection = {},
	Inventory = {},
	Displays = {},
	DisplaySlots = 5,
	ToiletTier = 3,
	Settings = { Sound = true, SkipAnimation = false },
	Stamps = 12,
	IndexClaims = {},
	IndexCosmetics = {},
	OwnedPasses = {},
	LifetimeFlushes = 134,
	AutoFlush = false,
	LastClaimDay = -1,
	Streak = 0,
	RewardLuckExpires = 0,
	ServerLuckExpires = 1800000100,
}
for i, item in ipairs(Items) do
	if i <= 6 then
		state.Collection[item.Id], state.Inventory[item.Id] = 1, i + 1
	end
end
local collection = H.Load("src/client/UI/Collection").Create(root, remotes)
local count = #H.Objects
collection.Update(state)
assert(#H.Objects == count, "Hidden collection creates cards")
collection.Panel.Visible = true
H.Layout(root)
local card = collection.Panel:FindFirstChild("Poop", true)
assert(card and card:FindFirstChild("Preview"), "Discovered preview missing")
local preview = card.Preview
count = #H.Objects
for _ = 1, 20 do
	collection.Update(state)
end
assert(#H.Objects == count and card.Preview == preview, "Repeated State rebuilds cards/previews")
state.Inventory.Poop = 9
collection.Update(state)
assert(#H.Objects == count and card.Preview == preview, "Inventory-only change rebuilds preview")
local sell = card:FindFirstChild("Sell All")
sell.Activated:Fire()
assert(H.Calls[#H.Calls].Name == "Sell" and H.Calls[#H.Calls].Args[2] == 8, "Sell callback used stale state")
state.Collection.ToiletBaby, state.Inventory.ToiletBaby = 1, 1
collection.Update(state)
assert(card.Preview == preview, "Other discovery rebuilt unchanged preview")
local calls = #H.Calls
local locked = collection.Panel:FindFirstChild("Mystery", true):FindFirstChild("Sell 1")
locked.Activated:Fire()
assert(#H.Calls == calls, "Disabled button sends requests")
H.Snapshot(root, "collection-desktop")
collection.Panel.Visible = false
state.Inventory.Poop = 10
count = #H.Objects
collection.Update(state)
assert(#H.Objects == count, "Hidden state allocates collection objects")
local upgrades = H.Load("src/client/UI/Upgrades").Create(root, remotes)
local daily = H.Load("src/client/UI/Rewards").Create(root, remotes)
local passes = H.Load("src/client/UI/Passes").Create(root, remotes)
for name, screen in pairs({ upgrades = upgrades, daily = daily, passes = passes }) do
	screen.Update(state)
	screen.Panel.Visible = true
	H.Layout(root)
	H.Snapshot(root, name .. "-desktop")
	screen.Panel.Visible = false
end
local imageRoot = H.Root(100, 100)
Assets.Icons.Shop = 123 -- Test-only mock ID; never shipped in Assets.
local image = C.Icon(imageRoot, "Shop", H.UDim2.fromOffset(80, 80))
assert(image.Fallback.Visible and image.Asset.Image == "rbxassetid://123")
image.Asset.IsLoaded = true
assert(not image.Fallback.Visible, "Loaded image does not replace fallback")
image.Asset.IsLoaded = false
assert(image.Fallback.Visible, "Failed image removes fallback")
Assets.Icons.Shop = 0
local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
	Near = function()
		return true
	end,
})
hud.Update(state)
H.Services.RunService.Heartbeat:Fire(0.2)
local flush = hud.Frame.FlushActions:FindFirstChild("FLUSH")
flush.Activated:Fire()
assert(H.Calls[#H.Calls].Name == "Flush" and H.Calls[#H.Calls].Count == 0, "HUD flush uses wrong server path")
hud.Best("Avery", Items[6])
H.Snapshot(root, "hud-desktop")
local reveal = H.Load("src/client/UI/Reveal").Create(hud.Frame, hud)
reveal(Items[6], false)
H.Snapshot(root, "rare-reveal")
hud.Frame.FlushReveal.Visible = false
hud.SetHintVisible(true)
H.Services.UserInputService.TouchEnabled = true
root._fixed = { X = 375, Y = 690 }
root._abs = nil
root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
H.Layout(root)
H.Services.RunService.Heartbeat:Fire(0.2)
H.Snapshot(root, "hud-portrait")
hud.Flushed({ Cooldown = 3 })
H.Services.RunService.Heartbeat:Fire(0.2)
assert(not flush.Interactable, "Cooldown does not disable manual action")
hud.Frame.Visible = false
collection.Panel.Visible = true
H.Snapshot(root, "collection-portrait")
collection.Panel.Visible = false
hud.Frame.Visible = true
root._fixed = { X = 724, Y = 318 }
root._abs = nil
root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
H.Layout(root)
H.Snapshot(root, "hud-landscape")
hud.Frame.Visible = false
daily.Panel.Visible = true
H.Snapshot(root, "daily-landscape")
local bootRemotes = H.Remotes()
H.Services.UserInputService.TouchEnabled = false
local clientRoot = H.BootClient(bootRemotes)
bootRemotes.State.OnClientEvent:Fire(state)
H.StartTasks()
H.Services.RunService.Heartbeat:Fire(0.3)
assert(clientRoot.HUD.Daily.ClaimBadge.Visible, "Daily claim badge missing")
local reads = H.WorkspaceReads
for _ = 1, 20 do
	bootRemotes.State.OnClientEvent:Fire(state)
end
assert(H.WorkspaceReads == reads, "State scans workspace sounds")
local sound = H.Instance.new("Sound")
sound.Parent = H.Workspace
H.Workspace.DescendantAdded:Fire(sound)
assert(sound.SoundGroup.Name == "ToiletSounds", "New sound is not registered")
H.Snapshot(clientRoot, "tutorial-desktop")
local settings = clientRoot.Settings
settings.Visible = true
assert(not clientRoot.HUD.Visible and clientRoot.ModalBackdrop.Visible, "Modal fails to suppress HUD")
local musicCard = settings:FindFirstChild("MusicAudio", true)
local sfxCard = settings:FindFirstChild("SFXAudio", true)
assert(musicCard.MusicMute.Text == "Music: ON" and sfxCard.SFXMute.Text == "SFX: ON")
musicCard.MusicMute.Activated:Fire()
sfxCard.SFXIncrease.Activated:Fire()
local countBefore = #H.Calls
H.Advance(1.1)
assert(#H.Calls == countBefore + 1, "Audio settings were not coalesced")
local saved = H.Calls[#H.Calls]
assert(saved.Name == "Settings" and saved.Count == 1 and saved.Args[1].MusicMuted)
assert(math.abs(saved.Args[1].SFXVolume - 0.75) < 1e-10 and not saved.Args[1].SFXMuted)
assert(H.Services.SoundService.Music.Volume == 0, "Music mute was not applied locally")
bootRemotes.State.OnClientEvent:Fire(state)
assert(musicCard.MusicMute.Text == "Music: MUTED", "Stale State erased pending audio preferences")
state.Settings = saved.Args[1]
bootRemotes.State.OnClientEvent:Fire(state)
local slider = sfxCard.SFXSlider
local mouse = {
	UserInputType = "UserInputType.MouseButton1",
	Position = { X = slider.AbsolutePosition.X + slider.AbsoluteSize.X / 2 },
}
slider.InputBegan:Fire(mouse)
assert(slider.Fill.Size.X.Scale == 0.5, "Slider pointer math is wrong")
H.Services.UserInputService.InputChanged:Fire({
	UserInputType = "UserInputType.MouseMovement",
	Position = { X = slider.AbsolutePosition.X + slider.AbsoluteSize.X },
})
assert(slider.Fill.Size.X.Scale == 1, "Mouse drag did not reach full volume")
H.Services.UserInputService.InputEnded:Fire(mouse)
local touch = { UserInputType = "UserInputType.Touch", Position = { X = slider.AbsolutePosition.X } }
slider.InputBegan:Fire(touch)
assert(slider.Fill.Size.X.Scale == 0, "Touch slider failed")
H.Services.UserInputService.InputEnded:Fire(touch)
H.Advance(1.1)
H.Snapshot(clientRoot, "settings-desktop")
clientRoot._fixed, clientRoot._abs = { X = 375, Y = 690 }, nil
clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
H.Snapshot(clientRoot, "settings-portrait")
assert(sfxCard.SFXSlider.AbsoluteSize.X >= 44, "Portrait slider is too narrow")
clientRoot._fixed, clientRoot._abs = { X = 724, Y = 318 }, nil
clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
H.Snapshot(clientRoot, "settings-landscape")
clientRoot._fixed, clientRoot._abs = { X = 1280, Y = 684 }, nil
clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
settings.Visible = false
clientRoot["Developer Tools"].Visible = true
H.Snapshot(clientRoot, "dev-desktop")
clientRoot["Developer Tools"].Visible = false
bootRemotes.Event.OnClientEvent:Fire({ PlayerName = "Avery", ItemId = "KingPoop" })
assert(
	clientRoot.HUD.ServerEventBanner.Visible and not clientRoot.HUD.Travel.Visible,
	"Event banner overlaps travel tabs"
)
H.Snapshot(clientRoot, "event-desktop")
bootRemotes.Result.OnClientEvent:Fire("Flush", { ItemId = "Rat", Cooldown = 3, ServiceCoins = 7 })
assert(
	clientRoot.HUD.FlushReveal.Visible and clientRoot.HUD:FindFirstChild("ServiceCoinPopup"),
	"Flush result presentation missing"
)
local indexPanel = clientRoot["My Collection"]
indexPanel.Visible = true
indexPanel.ContentScroll.Body.Rewards.Activated:Fire()
H.Snapshot(clientRoot, "index-rewards-desktop")
print(
	"UI runtime checks passed: all screen constructors, hidden/diffed collection, current sell callbacks, disabled input, image fallback lifecycle, flush remote and cooldown"
)

-- Run the production audio lifecycle with mock-only IDs and controllable fetches.
local AudioService = H.Load("src/client/Audio/AudioService")
local AudioConfig = H.Load("src/shared/Config/Audio")
Assets.Sounds.Flush = "500"
local ownPlot = H.Instance.new("Model")
ownPlot:SetAttribute("OwnerUserId", H.Services.Players.LocalPlayer.UserId)
ownPlot.Parent = H.Workspace
local worldFlush = H.Instance.new("Sound")
worldFlush.SoundId, worldFlush.Parent = "rbxassetid://500", ownPlot
local audio = AudioService.Start()
assert(worldFlush.SoundGroup == audio.LocalFlush and worldFlush.SoundGroup.Volume == 0, "Owner hears duplicate flush")
local otherPlot = H.Instance.new("Model")
otherPlot:SetAttribute("OwnerUserId", 999)
otherPlot.Parent = H.Workspace
local otherFlush = H.Instance.new("Sound")
otherFlush.SoundId, otherFlush.Parent = "rbxassetid://500", otherPlot
H.Workspace.DescendantAdded:Fire(otherFlush)
assert(otherFlush.SoundGroup == audio.SFX, "Other players' spatial flush was muted")
Assets.Sounds.Flush = ""
audio:ApplySettings(AudioConfig.Defaults)
local allocated, requests = #H.Objects, #H.Preloads
for key in pairs(AudioConfig.Cues) do
	audio:Play(key)
end
H.StartTasks()
assert(#H.Objects == allocated and #H.Preloads == requests, "Empty IDs allocate or preload sounds")
for _, invalid in ipairs({ 0, "0", " ", "rbxassetid://0", "malformed", false, -1, math.huge, 0 / 0 }) do
	Assets.Sounds.Click = invalid
	audio:Play("Click")
end
assert(#H.Objects == allocated, "Invalid IDs allocate sounds")
Assets.Sounds.Click, Assets.Sounds.CoinCollect, Assets.Sounds.Hover = 123, "rbxassetid://124", "125"
audio:Play("Click")
assert(#audio.Voices == 1 and audio.Voices[1].SoundId == "rbxassetid://123")
assert(audio.Voices[1].SoundGroup.Parent == audio.SFX, "SFX bus bypasses volume")
audio:Play("Click")
assert(#audio.Voices == 1, "Click throttle failed")
audio:Play("CoinCollect")
local initialPitch = audio.Voices[#audio.Voices].PlaybackSpeed
H.Advance(0.2)
audio:Play("CoinCollect")
assert(audio.Combo == 1, "Coin combo did not rise")
assert(audio.Voices[#audio.Voices].PlaybackSpeed > initialPitch, "Random jitter reversed coin combo pitch")
for _ = 1, 30 do
	H.Advance(0.2)
	audio:Play("Click")
end
assert(#audio.Voices <= AudioConfig.MaxVoices, "Voice cap exceeded")
local voice = audio.Voices[#audio.Voices]
voice.Ended:Fire()
assert(voice._dead, "Ended voice leaked")
audio:Duck("Reveal", 2.4)
audio:Duck("Event", 5)
assert(math.abs(audio.Music.Volume - 0.1) < 1e-10)
H.Advance(2.5)
assert(math.abs(audio.Music.Volume - 0.1) < 1e-10, "Reveal ending released overlapping event duck")
audio:ApplySettings({ MusicVolume = 0.5, SFXVolume = 0.2, MusicMuted = false, SFXMuted = true })
assert(math.abs(audio.Music.Volume - 0.2) < 1e-10 and audio.SFX.Volume == 0)
H.Advance(2.6)
assert(audio.Music.Volume == 0.5 and audio.Equalizer.HighGain == 0)
audio:Destroy()
assert(#audio.Voices == 0 and audio.Music._dead and audio.SFX._dead)
ownPlot:Destroy()
otherPlot:Destroy()
Assets.Sounds.Click, Assets.Sounds.CoinCollect, Assets.Sounds.Hover = "", "", ""
Assets.Music = { "201", "202", "203", "204", "205" }
H.Services.Players.LocalPlayer.Character = {}
local music = AudioService.Start()
music:ApplySettings(AudioConfig.Defaults)
H.StartTasks() -- Playlist waits for first preload.
H.StartTasks() -- First preload resolves.
H.ResumeTasks() -- First deck starts; next deck preloads.
assert(music.Current and music.Current.IsPlaying and music.Current.Volume == 1)
H.StartTasks()
H.ResumeTasks() -- Second deck ready, waiting for crossfade position.
local first = music.Current
first.TimePosition = 117
H.ResumeTasks()
assert(music.Current ~= first and music.Current.Volume == 1 and first.Volume == 0, "Crossfade did not swap decks")
H.ResumeTasks()
assert(first._dead, "Outgoing music deck leaked")
music:Destroy()
H.ResumeTasks()
H.StartTasks()
Assets.Music = { "301", "302" }
H.HoldPreload = true
local held = AudioService.Start()
held:ApplySettings(AudioConfig.Defaults)
H.StartTasks()
H.StartTasks()
local fetchCount = #H.Preloads
H.Advance(11)
H.ResumeTasks()
for _ = 1, 5 do
	H.ResumeTasks()
end
assert(#H.Preloads == fetchCount, "Hung preload accumulated fetch workers")
held:Destroy()
H.HoldPreload = false
H.ResumeTasks()
Assets.Music = { "", "", "", "", "" }

Assets.Music = { "401" }
H.FailPreload = true
local failed = AudioService.Start()
failed:ApplySettings(AudioConfig.Defaults)
H.StartTasks()
H.StartTasks()
H.ResumeTasks()
assert(not failed.Current and not failed.Loading, "Failed music played or leaked")
failed:Destroy()
H.ResumeTasks()
H.FailPreload = false
local single = AudioService.Start()
single:ApplySettings(AudioConfig.Defaults)
H.StartTasks()
H.StartTasks()
H.ResumeTasks()
assert(single.Current and single.Current.Looped, "Single music track did not loop")
local current, preloads = single.Current, #H.Preloads
H.ResumeTasks()
H.StartTasks()
assert(single.Current == current and #H.Preloads == preloads, "Single track reloaded itself")
single:Destroy()
Assets.Music = { "", "", "", "", "" }
print(
	"Audio runtime checks passed: silent placeholders, controls, stale snapshots, voice cap, cleanup, crossfades and ducking"
)
