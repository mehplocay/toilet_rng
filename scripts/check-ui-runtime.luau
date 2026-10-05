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
for _, object in ipairs(settings:GetDescendants()) do
	if object.ClassName == "TextButton" and object.Text == "Sound: ON" then
		object.Activated:Fire()
	end
end
assert(H.Calls[#H.Calls].Name == "Settings" and H.Calls[#H.Calls].Args[1] == false)
H.Snapshot(clientRoot, "settings-desktop")
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
