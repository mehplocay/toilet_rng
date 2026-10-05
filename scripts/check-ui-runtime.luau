-- Bundled by check-ui.ps1 with the production modules and ui-harness.luau.
local C = H.Load("src/client/UI/Components")
local Assets = H.Load("src/shared/Config/Assets")
local Items = H.Load("src/shared/Config/Items")
local root, remotes = H.Root(1280, 684), H.Remotes()
assert(#expectedIcons == 37, "Incomplete icon manifest")
for _, icon in ipairs(expectedIcons) do
	assert(Assets[icon.Group][icon.Key] == icon.Id, "Wrong upload mapping: " .. icon.Group .. "." .. icon.Key)
end
assert(Assets.Icons.Coin == Assets.Icons.Coins, "Coin compatibility alias differs")
-- A stalled fetch must not block UI construction; duplicate aliases preload once.
C.PreloadIcons()
assert(#H.Preloads == 0, "Preload blocked the calling thread")
H.HoldPreload = true
H.StartTasks()
assert(#H.Preloads == 1 and #H.Preloads[1] == 37, "Preload omitted icons or duplicated aliases")
local preloadSeen = {}
for _, label in ipairs(H.Preloads[1]) do
	assert(not preloadSeen[label.Image], "Duplicate icon preload")
	preloadSeen[label.Image] = true
end
local duringFetch = C.Icon(root, "Shop", H.UDim2.fromOffset(80, 80))
assert(
	duringFetch.Fallback.Visible and duringFetch.Asset.Visible and duringFetch.Asset.ImageTransparency == 0.999,
	"Pending icon must retain fallback and remain render-eligible"
)
C.PreloadIcons()
H.StartTasks()
assert(#H.Preloads == 1, "Startup preloaded twice")
H.HoldPreload = false
H.FailPreload = true
H.ResumeTasks()
H.FailPreload = false
assert(#H.Warnings == 37, "Failed preload did not report per-image status")
assert(duringFetch.Fallback.Visible and duringFetch.Asset.ImageTransparency == 0.999, "Failed preload hid fallback")
for _, label in ipairs(H.Preloads[1]) do
	assert(label._dead, "Preload ImageLabel leaked")
end
duringFetch:Destroy()
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
local shopId = Assets.Icons.Shop
Assets.Icons.Shop = 123 -- Test-only mock ID; never shipped in Assets.
local image = C.Icon(imageRoot, "Shop", H.UDim2.fromOffset(80, 80))
assert(image.Fallback.Visible and image.Asset.Image == "rbxassetid://123")
image.Asset.IsLoaded = true
assert(not image.Fallback.Visible and image.Asset.ImageTransparency == 0, "Loaded image does not replace fallback")
image.Asset.IsLoaded = false
assert(image.Fallback.Visible and image.Asset.ImageTransparency == 0.999, "Failed image removes fallback")
for _, value in ipairs({ 0, "", "0", "rbxassetid://0" }) do
	local fallback = C.Icon(imageRoot, "Shop", H.UDim2.fromOffset(80, 80), nil, value)
	assert(fallback.Fallback.Visible and not fallback:FindFirstChild("Asset"), "Zero/empty icon lost fallback")
end
Assets.Icons.Shop = shopId
local previewModule = H.Load("src/client/UI/Preview")
for _, item in ipairs(Items) do
	local itemPreview = previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, item)
	assert(itemPreview:FindFirstChild("Asset", true).Image == Assets.ItemIcons[item.Id], "Item icon mismatch")
end
for tier, toilet in ipairs(H.Load("src/shared/Config/Toilets")) do
	local toiletPreview = previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, nil, tier)
	assert(toiletPreview:FindFirstChild("Asset", true).Image == Assets.ToiletIcons[toilet.Id], "Toilet icon mismatch")
end
local hiddenPreview = previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, Items[11], nil, true)
assert(hiddenPreview:FindFirstChild("Asset", true).Image == Assets.Icons.Lock, "Undiscovered icon leaks item art")
local poopId, basicId = Assets.ItemIcons.Poop, Assets.ToiletIcons.Basic
Assets.ItemIcons.Poop, Assets.ToiletIcons.Basic = "", 0
for _, fallback in ipairs({
	previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, Items[1]),
	previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, nil, 1),
}) do
	assert(not fallback:FindFirstChild("Asset", true), "Empty preview accidentally used a UI asset")
end
Assets.ItemIcons.Poop, Assets.ToiletIcons.Basic = poopId, basicId

-- Measure real offer subtrees at every supported safe viewport.
local shopConfig = H.Load("src/shared/Config/Shop")
local passConfig = H.Load("src/shared/Config/Monetization")
local offerGrid = passes.Panel:FindFirstChild("OfferGrid", true)
passes.Panel.Visible = true
for _, viewport in ipairs({
	{ 1920, 1044 },
	{ 1280, 684 },
	{ 375, 690 },
	{ 724, 318 },
	{ 1024, 712 },
	{ 768, 968 },
	{
		1116,
		483,
	},
}) do
	root._fixed, root._abs = { X = viewport[1], Y = viewport[2] }, nil
	root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	H.Layout(root)
	for _, key in ipairs(passConfig.PassOrder) do
		local slot, offer = offerGrid[key], offerGrid[key].OfferCard
		local icon = offer[shopConfig.Offers[key].Icon .. "Icon"]
		assert(icon.Asset.Image == Assets.Icons[shopConfig.Offers[key].Icon])
		assert(icon.AbsolutePosition.Y >= slot.AbsolutePosition.Y, "Offer sculpture clips above grid cell")
		assert(icon.AbsolutePosition.Y < offer.AbsolutePosition.Y, "Offer sculpture does not overflow card")
		assert(
			icon.AbsolutePosition.Y + icon.AbsoluteSize.Y <= offer.OfferTitle.AbsolutePosition.Y,
			"Sculpture overlaps title"
		)
		local lastBottom = offer.OfferTitle.AbsolutePosition.Y
		for _, element in ipairs({ offer.OfferTitle, offer.Description, offer.OfferStatus, offer.Buy }) do
			assert(element.AbsolutePosition.Y >= lastBottom, "Offer text/actions overlap")
			lastBottom = element.AbsolutePosition.Y + element.AbsoluteSize.Y
		end
		assert(not offer.Description.TextWrapped, "Description is not one line")
		assert(offer.Buy.AbsoluteSize.X >= 100 and offer.Buy.AbsoluteSize.Y >= 44)
		assert(offer.Gift.AbsoluteSize.X >= 44 and offer.Gift.AbsoluteSize.Y >= 44)
		assert(
			offer.Buy.AbsolutePosition.X + offer.Buy.AbsoluteSize.X < offer.Gift.AbsolutePosition.X,
			"Buy/gift overlap"
		)
		assert(lastBottom <= offer.AbsolutePosition.Y + offer.AbsoluteSize.Y, "Buy button clips below card")
		assert(offer.Gift.Text == "Coming soon" and not offer.Gift.Interactable)
		local before = #H.Calls
		offer.Gift.Activated:Fire()
		offer.Buy.Activated:Fire()
		assert(#H.Calls == before, "Zero-ID purchase or gift sent a request")
	end
	H.Snapshot(root, "passes-" .. viewport[1] .. "x" .. viewport[2])
end
root._fixed, root._abs = { X = 1280, Y = 684 }, nil
root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
H.Layout(root)
assert(H.Services.Lighting.PassesBlur.Enabled, "Opening passes did not enable blur")
passes.Panel.TitleBar.X.Activated:Fire()
assert(not H.Services.Lighting.PassesBlur.Enabled, "Closing passes left blur enabled")

-- Mock-only product ID and metadata exercise the original BuyPass path.
local productCalls, productInfo = 0, { IsForSale = true, PriceInRobux = 79 }
H.Services.MarketplaceService.GetProductInfoAsync = function(_, id, infoType)
	assert(id == 123 and infoType == "InfoType.GamePass")
	productCalls += 1
	if productInfo == false then
		error("Test price lookup failure")
	end
	return productInfo
end
H.StartTasks()
assert(productCalls == 0, "Zero-ID pass requested metadata")
passConfig.Gamepasses.SparkleTrail.Id = 123
passes.Panel.Visible = true
H.StartTasks()
local offer = offerGrid.SparkleTrail.OfferCard
assert(offer.Buy.Text == "79" and offer.Buy.RobuxIcon.Visible and offer.Buy.Interactable)
offer.Buy.Activated:Fire()
assert(H.Calls[#H.Calls].Name == "BuyPass" and H.Calls[#H.Calls].Args[1] == "SparkleTrail")
H.Snapshot(root, "passes-price-preview")
state.OwnedPasses.SparkleTrail = true
passes.Update(state)
assert(not offer.Buy.Interactable and offer.Buy.Text == "Owned" and offer.CheckIcon.Visible)
state.OwnedPasses.SparkleTrail = nil
for _, info in ipairs({ { IsForSale = false, PriceInRobux = 79 }, false, { IsForSale = true, PriceInRobux = -1 } }) do
	productInfo = info
	passes.Panel.Visible = false
	passes.Panel.Visible = true
	H.StartTasks()
	assert(not offer.Buy.Interactable and offer.Buy.Text == "Unavailable", "Bad metadata enabled purchase")
end
passConfig.Gamepasses.SparkleTrail.Id = 0
passes.Update(state)
passes.Panel.Visible = false
local passBlur = H.Services.Lighting.PassesBlur
passes.Panel:Destroy()
assert(passBlur._dead, "Destroyed shop leaked its blur effect")
print(
	"Icon/shop checks passed: 37 upload mappings, async preload, fallbacks, 7 card layouts, prices, ownership and disabled gifting"
)
local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
	Near = function()
		return true
	end,
})
hud.Update(state)
for _, name in ipairs({ "Shop", "Collection", "Upgrades", "Passes", "Daily" }) do
	assert(hud.Navigation[name][name .. "Icon"].Asset.Image == Assets.Icons[name], "HUD icon slot not wired")
end
for _, name in ipairs({ "Hub", "Home", "Shop" }) do
	assert(hud.Frame.Travel[name][name .. "Icon"].Asset.Image == Assets.Icons[name], "Travel icon slot not wired")
end
assert(hud.Frame.Wallet.CoinIcon.Asset.Image == Assets.Icons.Coin)
assert(hud.Frame.FlushActions:FindFirstChild("AutoFlushIcon", true).Asset.Image == Assets.Icons.AutoFlush)
assert(hud.Frame.Offers:FindFirstChild("OfferBurstIcon", true).Asset.Image == Assets.Icons.OfferBurst)
H.Load("src/client/UI/IncomeChip").Create(hud.Frame).Update(1234)
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
local actualPrompts = H.Load("src/client/UI/FlushPrompt").Start()
local collectPrompt = H.Instance.new("ProximityPrompt")
collectPrompt.ActionText = "Collect"
collectPrompt:SetAttribute("OwnerUserId", H.Services.Players.LocalPlayer.UserId)
H.Workspace.DescendantAdded:Fire(collectPrompt)
assert(actualPrompts.Own() == nil, "Collect prompt was selected as the flush target")
local flushPrompt = H.Instance.new("ProximityPrompt")
flushPrompt.ActionText = "FLUSH"
flushPrompt:SetAttribute("OwnerUserId", H.Services.Players.LocalPlayer.UserId)
H.Workspace.DescendantAdded:Fire(flushPrompt)
assert(actualPrompts.Own() == flushPrompt)
H.Services.UserInputService.TouchEnabled = false
local clientRoot = H.BootClient(bootRemotes)
bootRemotes.State.OnClientEvent:Fire(state)
H.StartTasks()
H.Services.RunService.Heartbeat:Fire(0.3)
assert(clientRoot.HUD.Daily.ClaimBadge.Visible, "Daily claim badge missing")
local reads = H.WorkspaceReads
local pendingChip = clientRoot.HUD.PendingIncome
assert(pendingChip, "Pending income chip missing")
local objectCount = #H.Objects
for _ = 1, 20 do
	bootRemotes.IncomePending.OnClientEvent:Fire(123)
end
assert(#H.Objects == objectCount, "Pending updates create UI instances")
assert(pendingChip:FindFirstChildWhichIsA("TextLabel").Text == "Pending: 123")
local prompt = H.Instance.new("ProximityPrompt")
prompt:SetAttribute("IncomeOwnerUserId", H.Services.Players.LocalPlayer.UserId)
H.Services.ProximityPromptService.PromptTriggered:Fire(prompt)
assert(H.Calls[#H.Calls].Name == "CollectIncome" and H.Calls[#H.Calls].Count == 0)
local requests = #H.Calls
prompt:SetAttribute("IncomeOwnerUserId", -1)
H.Services.ProximityPromptService.PromptTriggered:Fire(prompt)
assert(#H.Calls == requests, "Foreign collect prompt sent a request")
bootRemotes.Result.OnClientEvent:Fire("CollectIncome", { Success = true, Coins = 123 })
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
