-- Bundled by check-ui.ps1 with the production modules and ui-harness.luau.
H.UseCommerceIds(false) -- Explicit zero-ID fixture for disabled offers and single-ID price tests.
local C = H.Load("src/client/UI/Components")
local Assets = H.Load("src/shared/Config/Assets")
local shippedMusic, shippedSounds = table.clone(Assets.Music), table.clone(Assets.Sounds)
local audioSlots = H.Load("src/shared/Config/Audio").Cues
for index, id in ipairs(Assets.Music) do
	assert(id == expectedAudio["Music" .. index], "Wrong uploaded music ID: Music" .. index)
end
for key in pairs(audioSlots) do
	assert(
		Assets.Sounds[key] == expectedAudio[if key == "Celestial" then "Godly" else key],
		"Slot without uploaded ID or wrong mapping: " .. key
	)
end
for key in pairs(Assets.Sounds) do
	assert(audioSlots[key], "Configured ID without runtime slot: " .. key)
end
for key in pairs(expectedAudio) do
	local index = key:match("^Music([1-5])$")
	assert(index or audioSlots[key], "Uploaded ID without slot: " .. key)
end
-- UI suites intentionally use empty-safe fixtures; restore shipped IDs after lifecycle checks.
Assets.Music = { "", "", "", "", "" }
for key in pairs(Assets.Sounds) do
	Assets.Sounds[key] = ""
end
local Items = H.Load("src/shared/Config/Items")
local root, remotes = H.Root(1280, 684), H.Remotes()
-- Shared by the shop, upgrade and presentation suites bundled by check-ui.ps1.
H.Viewports = {
	{ 1920, 1044 },
	{ 1280, 684 },
	{ 375, 690 },
	{ 724, 318 },
	{ 1024, 712 },
	{ 768, 968 },
	{ 1116, 483 },
	{ 711, 751 },
	{ 711, 731 },
	{ 360, 518 },
	{ 390, 722 },
	{ 640, 303 },
}
assert(#expectedIcons == 37, "Incomplete icon manifest")
-- Wave 1: every uploaded item/toilet icon beyond the original 37 must resolve like the rest.
local known = {}
for _, icon in ipairs(expectedIcons) do
	known[icon.Group .. "." .. icon.Key] = true
end
local wave1Icons = 0
for _, group in ipairs({ "ItemIcons", "ToiletIcons" }) do
	for key, value in pairs(Assets[group]) do
		if value ~= "" and not known[group .. "." .. key] then
			table.insert(expectedIcons, { Group = group, Key = key, Id = value })
			wave1Icons += 1
		end
	end
end
assert(wave1Icons == 44, "Wave 1 icon ids incomplete: " .. wave1Icons)
for _, icon in ipairs(expectedPlaceholderIcons) do
	local value = Assets[icon.Group][icon.Key]
	local verified = value == nil or value == ""
	for _, uploaded in ipairs(expectedIcons) do
		verified = verified or (uploaded.Group == icon.Group and uploaded.Key == icon.Key and uploaded.Id == value)
	end
	assert(verified, "Unverified catalog icon ID: " .. icon.Key)
end
for _, icon in ipairs(expectedIcons) do
	assert(Assets[icon.Group][icon.Key] == icon.Id, "Wrong upload mapping: " .. icon.Group .. "." .. icon.Key)
end
assert(Assets.Icons.Coin == Assets.Icons.Coins, "Coin compatibility alias differs")
-- Test-only resolved contents are distinct from Decal wrappers.
local Content = H.Load("src/shared/IconContent")
local waitingIcon = C.Icon(root, "Shop", H.UDim2.fromOffset(80, 80))
assert(waitingIcon.Fallback.Visible and waitingIcon.Asset.Image == "", "Decal wrapper reached ImageLabel")
H.StartTasks()
H.Now += 2.1
H.ResumeTasks()
assert(
	#H.Preloads == 0 and waitingIcon.Fallback.Visible,
	"Resolution timeout should keep vectors without fetching wrappers"
)
local resolved = H.Instance.new("Folder")
resolved.Name = "ResolvedIcons"
for i, icon in ipairs(expectedIcons) do
	local id = Content.Id(icon.Id)
	if not resolved:GetAttribute("Image_" .. id) then
		resolved:SetAttribute("Image_" .. id, "rbxassetid://" .. (900000 + i))
	end
	icon.Image = resolved:GetAttribute("Image_" .. id)
end
resolved:SetAttribute("Complete", true)
resolved.Parent = H.Services.ReplicatedStorage
local Images = H.Load("src/client/UI/ResolvedIcons")
assert(waitingIcon.Asset.Image == Images.Get(Assets.Icons.Shop), "Late folder failed to update existing icon")
local shopKey = "Image_" .. Content.Id(Assets.Icons.Shop)
local originalImage = resolved:GetAttribute(shopKey)
resolved:SetAttribute(shopKey, nil)
assert(waitingIcon.Asset.Image == "" and waitingIcon.Fallback.Visible)
resolved:SetAttribute(shopKey, originalImage)
assert(waitingIcon.Asset.Image == originalImage, "Late attribute failed to update icon")
waitingIcon:Destroy()
-- A stalled fetch must not block UI construction; duplicate aliases preload once.
C.PreloadIcons()
assert(#H.Preloads == 0, "Preload blocked the calling thread")
H.HoldPreload = true
H.StartTasks()
assert(#H.Preloads == 1 and #H.Preloads[1] == #expectedIcons, "Preload omitted icons or duplicated aliases")
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
assert(#H.Warnings == #expectedIcons, "Failed preload did not report per-image status")
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
collection.Panel:FindFirstChild("Slots", true).Activated:Fire()
H.Snapshot(root, "display-slots-desktop")
collection.SlotsPanel.Visible = false
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
Assets.IconImages["123"] = 123
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
	if Assets.ItemIcons[item.Id] == "" then
		assert(itemPreview:FindFirstChild("ModelPreview"), "New item needs a model icon fallback")
		continue
	end
	assert(
		itemPreview:FindFirstChild("Asset", true).Image == Images.Get(Assets.ItemIcons[item.Id]),
		"Item icon mismatch"
	)
end
for tier, toilet in ipairs(H.Load("src/shared/Config/Toilets")) do
	local toiletPreview = previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, nil, tier)
	if Assets.ToiletIcons[toilet.Id] == "" then
		assert(toiletPreview:FindFirstChild("ModelPreview"), "New toilet needs a model icon fallback")
		continue
	end
	assert(
		toiletPreview:FindFirstChild("Asset", true).Image == Images.Get(Assets.ToiletIcons[toilet.Id]),
		"Toilet icon mismatch"
	)
end
local hiddenPreview = previewModule.Create(imageRoot, H.UDim2.fromOffset(80, 80), nil, Items[11], nil, true)
assert(
	hiddenPreview:FindFirstChild("Asset", true).Image == Images.Get(Assets.Icons.Lock),
	"Undiscovered icon leaks item art"
)
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
for _, viewport in ipairs(H.Viewports) do
	root._fixed, root._abs = { X = viewport[1], Y = viewport[2] }, nil
	root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	H.Layout(root)
	for _, key in ipairs(passConfig.PassOrder) do
		local slot, offer = offerGrid[key], offerGrid[key].OfferCard
		local icon = offer[shopConfig.Offers[key].Icon .. "Icon"]
		if Assets.Icons[shopConfig.Offers[key].Icon] == "" then
			assert(
				icon.Fallback.Visible and not icon:FindFirstChild("Asset"),
				"Unuploaded catalog art must use vectors"
			)
		else
			assert(icon.Asset.Image == Images.Get(Assets.Icons[shopConfig.Offers[key].Icon]))
		end
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
		assert(offer.Description.TextWrapped == (key == "ExtraSlots"), "Unexpected offer description wrapping")
		if key == "ExtraSlots" then
			assert(offer.Description.Text == "+3 slots (max 10). Also free via coin upgrades!")
			assert(offer.Description.UITextSizeConstraint.MinTextSize == 14, "Free slot route is too small to read")
		end
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
	productCalls += 1
	assert(id == 123 and infoType == "InfoType.GamePass")
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
passes.Update(state)
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
	"Icon/shop checks passed: 81 upload mappings, async preload, fallbacks, 7 card layouts, prices, ownership and disabled gifting"
)
local nearToilet, openedHome = true, false
local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function(name)
	openedHome = name == "Home"
end, {
	Near = function()
		return nearToilet
	end,
})
hud.Update(state)
for _, name in ipairs({ "Shop", "Collection", "Upgrades", "Passes", "Daily" }) do
	assert(
		hud.Navigation[name][name .. "Icon"].Asset.Image == Images.Get(Assets.Icons[name]),
		"HUD icon slot not wired"
	)
end
for _, name in ipairs({ "Hub", "Home", "Shop" }) do
	assert(
		hud.Frame.Travel[name][name .. "Icon"].Asset.Image == Images.Get(Assets.Icons[name]),
		"Travel icon slot not wired"
	)
end
assert(hud.Frame.Wallet.CoinIcon.Asset.Image == Images.Get(Assets.Icons.Coin))
assert(hud.Frame.Offers:FindFirstChild("OfferBurstIcon", true).Asset.Image == Images.Get(Assets.Icons.OfferBurst))
H.Load("src/client/UI/IncomeChip").Create(hud.Frame).Update(1234)
H.Services.RunService.Heartbeat:Fire(0.2)
local flush = hud.Frame.FlushActions:FindFirstChild("FLUSH")
flush.Activated:Fire()
assert(H.Calls[#H.Calls].Name == "Flush" and H.Calls[#H.Calls].Count == 0, "HUD flush uses wrong server path")
assert(not hud.Frame:FindFirstChild("BestFlushBoard"), "Persistent landmark record leaked onto HUD")
nearToilet = false
H.Services.RunService.Heartbeat:Fire(0.1)
assert(
	flush.Text == "GO TO YOUR TOILET" and flush.Label.Text == flush.Text,
	"Away action has multiple/conflicting labels"
)
local beforeHome = #H.Calls
flush.Activated:Fire()
assert(openedHome and #H.Calls == beforeHome, "Away action must route home without sending a flush")
assert(hud.Hint.Visible)
H.Advance(4.75)
assert(hud.Hint.Visible and hud.Hint.GroupTransparency > 0, "Hint does not fade")
H.Advance(0.5)
assert(not hud.Hint.Visible, "Center hint is permanent")
hud.SetTutorial("Find your toilet", "Tap Home", function() end)
H.Advance(6)
hud.SetTutorial("Find your toilet", "Tap Home", function() end)
H.Services.RunService.Heartbeat:Fire(0.1)
assert(hud.Hint.Visible, "Tutorial instructions must not expire after five seconds")
hud.SetTutorial(nil)
nearToilet = true
hud.Best("Avery", Items[6])
H.Snapshot(root, "hud-desktop")
for _, viewport in ipairs({ { 711, 751 }, { 360, 518 } }) do
	root._fixed, root._abs = { X = viewport[1], Y = viewport[2] }, nil
	H.Services.UserInputService.TouchEnabled = viewport[1] == 360
	root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	H.Services.RunService.Heartbeat:Fire(0.1)
	H.Snapshot(root, "hud-fixed-" .. viewport[1])
	nearToilet = false
	H.Services.RunService.Heartbeat:Fire(0.1)
	H.Snapshot(root, "hud-away-" .. viewport[1])
	nearToilet = true
end
root._fixed, root._abs = { X = 1280, Y = 684 }, nil
H.Services.UserInputService.TouchEnabled = false
root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
local reveal = H.Load("src/client/UI/Reveal").Create(hud.Frame, hud)
reveal(Items[6], false)
H.Services.RunService.Heartbeat:Fire(0.1)
assert(not flush.PointerIcon.Visible, "Idle pointer overlaps reveal/coin presentation")
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
collection.Panel:FindFirstChild("Slots", true).Activated:Fire()
H.Snapshot(root, "display-slots-portrait")
collection.SlotsPanel.Visible = false
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
local function reportUI(label)
	local objects, frames, visible = clientRoot:GetDescendants(), 0, 0
	for _, object in ipairs(objects) do
		if object:IsA("GuiObject") then
			frames += 1
			local shown, ancestor = true, object
			while ancestor and ancestor ~= clientRoot do
				if ancestor:IsA("GuiObject") and not ancestor.Visible then
					shown = false
				end
				ancestor = ancestor.Parent
			end
			if shown then
				visible += 1
			end
		end
	end
	print(
		string.format(
			"Audit2 UI %s: %d descendants, %d GuiObjects, %d ancestor-visible (headless fixture, not draw calls)",
			label,
			#objects,
			frames,
			visible
		)
	)
end
reportUI("boot")
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
prompt:SetAttribute("CollectSlot", 3)
H.Services.ProximityPromptService.PromptTriggered:Fire(prompt)
assert(H.Calls[#H.Calls].Name == "CollectIncome" and H.Calls[#H.Calls].Count == 1 and H.Calls[#H.Calls].Args[1] == 3)
local requests = #H.Calls
prompt:SetAttribute("IncomeOwnerUserId", -1)
H.Services.ProximityPromptService.PromptTriggered:Fire(prompt)
assert(#H.Calls == requests, "Foreign collect prompt sent a request")
bootRemotes.Result.OnClientEvent:Fire("CollectIncome", { Success = true, Coins = 123 })
local flights = 0
for _, object in ipairs(clientRoot:GetChildren()) do
	if object.Name == "IncomeCoinFlight" then
		flights += 1
	end
end
assert(flights == 5, "Income collection lacks a bounded coin flight burst")
local displayPrompt = H.Instance.new("ProximityPrompt")
displayPrompt:SetAttribute("OwnerUserId", H.Services.Players.LocalPlayer.UserId)
displayPrompt:SetAttribute("DisplaySlot", 3)
displayPrompt:SetAttribute("DisplayOccupied", false)
H.Services.ProximityPromptService.PromptTriggered:Fire(displayPrompt)
local collectionPanel = clientRoot:FindFirstChild("My Collection")
assert(collectionPanel.Visible, "Place prompt did not open Collection")
collectionPanel:FindFirstChild("Poop", true).Display.Activated:Fire()
assert(H.Calls[#H.Calls].Name == "Display" and H.Calls[#H.Calls].Args[1] == "Poop" and H.Calls[#H.Calls].Args[2] == 3)
displayPrompt:SetAttribute("DisplayOccupied", true)
H.Services.ProximityPromptService.PromptTriggered:Fire(displayPrompt)
assert(H.Calls[#H.Calls].Name == "Display" and H.Calls[#H.Calls].Args[1] == nil and H.Calls[#H.Calls].Args[2] == 3)
collectionPanel.Visible = false
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
assert(musicCard.MusicPercentage.Text == "60%" and sfxCard.SFXPercentage.Text == "70%")
local previewCalls = #H.Calls
musicCard.MusicPreview.Activated:Fire()
assert(musicCard.MusicPreview.Text == "Music loading; try again")
sfxCard.SFXPreview.Activated:Fire()
assert(sfxCard.SFXPreview.Text == "Try again shortly", "Empty SFX asset claimed audible playback")
assert(#H.Calls == previewCalls, "Preview saved settings")
musicCard.MusicMute.Activated:Fire()
musicCard.MusicPreview.Activated:Fire()
assert(musicCard.MusicPreview.Text == "Unmute to preview")
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
do
	local audioService = H.Load("src/client/Audio/AudioService")
	local originalFlush, water = audioService.Flush, 0
	audioService.Flush = function()
		water += 1
	end
	local before = #clientRoot.HUD:GetChildren()
	bootRemotes.Result.OnClientEvent:Fire(
		"Flush",
		{ ItemId = "Mystery", FlushId = 100000, Cooldown = 0.4, ServiceCoins = 4500, Compact = true }
	)
	audioService.Flush = originalFlush
	assert(water == 0 and #clientRoot.HUD:GetChildren() == before, "Far award played water or allocated a coin popup")
	assert(not clientRoot.HUD.FlushReveal.Visible and clientRoot.RareReveal.CompactDrop.Visible)
	assert(not clientRoot.RareReveal:FindFirstChild("RevealContent"), "Far jackpot opened a cinematic")
end
local indexPanel = clientRoot["My Collection"]
indexPanel.Visible = true
indexPanel.ContentScroll.Body.Rewards.Activated:Fire()
reportUI("collection/rewards visited")
H.Snapshot(clientRoot, "index-rewards-desktop")
print(
	"UI runtime checks passed: all screen constructors, hidden/diffed collection, current sell callbacks, disabled input, image fallback lifecycle, flush remote and cooldown"
)

-- Project a world station label onto/away from a HUD control; late tags and streaming work.
do
	local testHud = H.Root(711, 751)
	local control =
		C.New("Frame", testHud, { Position = H.UDim2.fromOffset(100, 10), Size = H.UDim2.fromOffset(300, 44) })
	H.Layout(testHud)
	local anchor = H.Instance.new("BasePart")
	anchor.Position, anchor.Parent = Vector3.new(), H.Workspace
	local billboard = H.Instance.new("BillboardGui")
	billboard.Size, billboard.Parent = H.UDim2.fromScale(10, 2), anchor
	billboard.MaxDistance = 100
	local previousCamera = H.Workspace.CurrentCamera
	local centerY = 30
	H.Workspace.CurrentCamera = {
		FieldOfView = 70,
		CFrame = { UpVector = Vector3.new(0, 1, 0), Position = Vector3.new() },
		WorldToScreenPoint = function(_, position)
			return { X = 250, Y = centerY - position.Y * 10, Z = 20 }
		end,
	}
	H.Load("src/client/WorldLabels").Start(testHud)
	billboard:SetAttribute("AvoidHUD", true)
	H.Services.RunService.RenderStepped:Fire(1 / 60)
	assert(not billboard.Enabled, "World PASSES label overlaps travel controls")
	centerY = 300
	H.Services.RunService.RenderStepped:Fire(1 / 60)
	assert(billboard.Enabled, "World landmark label did not return in clear space")
	control.Visible, centerY = false, 30
	H.Services.RunService.RenderStepped:Fire(1 / 60)
	assert(billboard.Enabled, "Hidden controls unnecessarily suppress world labels")
	testHud.Visible = false
	H.Services.RunService.RenderStepped:Fire(1 / 60)
	assert(not billboard.Enabled, "Modal view leaves world text over its content")
	testHud:Destroy()
	assert(billboard.Enabled, "Label suppression leaked after HUD destruction")
	H.Workspace.DescendantRemoving:Fire(billboard)
	anchor:Destroy()
	H.Workspace.CurrentCamera = previousCamera
end

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
assert(otherFlush.SoundGroup == audio.WorldSFX and audio.WorldSFX.Parent == audio.SFX, "Nearby flush bypassed SFX mix")
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
assert(math.abs(audio.Music.Volume - AudioConfig.Defaults.MusicVolume * AudioConfig.DuckGain) < 1e-10)
H.Advance(2.5)
assert(
	math.abs(audio.Music.Volume - AudioConfig.Defaults.MusicVolume * AudioConfig.DuckGain) < 1e-10,
	"Reveal ending released overlapping event duck"
)
audio:ApplySettings({ MusicVolume = 0.5, SFXVolume = 0.2, MusicMuted = false, SFXMuted = true })
assert(math.abs(audio.Music.Volume - 0.5 * AudioConfig.DuckGain) < 1e-10 and audio.SFX.Volume == 0)
H.Advance(2.6)
assert(audio.Music.Volume == 0.5 and audio.Equalizer.HighGain == 0)
audio:Destroy()
H.Advance(AudioConfig.StopFade)
assert(#audio.Voices == 0 and audio.Music._dead and audio.SFX._dead)
ownPlot:Destroy()
otherPlot:Destroy()
Assets.Sounds.Click, Assets.Sounds.CoinCollect, Assets.Sounds.Hover = "", "", ""
Assets.Music = { "201", "202", "203", "204", "205" }
H.Services.Players.LocalPlayer.Character = H.Instance.new("Model")
local music = AudioService.Start()
music:ApplySettings(AudioConfig.Defaults)
H.StartTasks() -- Playlist waits for first preload.
H.StartTasks() -- First preload resolves.
H.ResumeTasks() -- First deck starts; next deck preloads.
assert(music.Current and music.Current.IsPlaying and music.Current.Volume == AudioConfig.MusicTrackGains[1])
assert(music.Current.SoundId == "rbxassetid://201", "Startup preload was not reused as the first track")
local first = music.Current
first.TimePosition = 110
H.ResumeTasks() -- Next track fetch begins only near the transition.
H.StartTasks()
H.ResumeTasks() -- Second deck ready, waiting for crossfade position.
first.TimePosition = 117
H.ResumeTasks()
local nextIndex = table.find(Assets.Music, music.Current.SoundId:match("(%d+)$"))
assert(
	music.Current ~= first and music.Current.Volume == AudioConfig.MusicTrackGains[nextIndex] and first.Volume == 0,
	"Crossfade did not swap decks"
)
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
local stalledWorker = held.MusicPreloadThread
H.Advance(11)
H.ResumeTasks()
for _ = 1, 5 do
	H.ResumeTasks()
end
assert(#H.Preloads == fetchCount, "Hung preload accumulated fetch workers")
assert(coroutine.status(stalledWorker) == "dead", "Timed-out fetch worker kept blocking retries")
H.HoldPreload = false
H.StartTasks()
H.ResumeTasks()
assert(held.Current and held.Current.IsPlaying, "Music never recovered after a hung fetch")
held:Destroy()
H.ResumeTasks()
Assets.Music = { "", "", "", "", "" }

Assets.Music = { "401" }
H.FailPreload = true
local failed = AudioService.Start()
failed:ApplySettings(AudioConfig.Defaults)
H.StartTasks()
H.StartTasks()
H.ResumeTasks()
H.StartTasks() -- Startup failure falls through to the normal bounded playlist retry.
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
assert(single:Preview("Music") and not single:Preview("Unknown"))
local current, preloads = single.Current, #H.Preloads
assert(current.Parent == H.Services.SoundService and current.SoundGroup == single.Music)
assert(
	current.Volume == AudioConfig.MusicTrackGains[1] and single.Music.Volume == AudioConfig.Defaults.MusicVolume,
	"Deck and bus applied the music slider twice"
)
-- The global music deck survives hub/plot/path movement, Settings, respawn,
-- and the Settings snapshots emitted after a rebirth.
for _, area in ipairs({ "Hub", "Plot", "Path", "Settings", "Respawn", "Rebirth" }) do
	if area == "Respawn" then
		H.Services.Players.LocalPlayer.Character = nil
		H.Advance(0.2)
		H.Services.Players.LocalPlayer.Character = H.Instance.new("Model")
	elseif area == "Rebirth" then
		single:ApplySettings(AudioConfig.Defaults)
	end
	H.Advance(0.2)
	assert(
		single.Current == current and current.IsPlaying and current.SoundGroup == single.Music,
		area .. " silenced music"
	)
end
H.ResumeTasks()
H.StartTasks()
assert(single.Current == current and #H.Preloads == preloads, "Single track reloaded itself")
current.TimePosition = 42
single:ApplySettings({ MusicVolume = 0.6, MusicMuted = true, SFXVolume = 0.7, SFXMuted = false })
assert(current.IsPlaying, "Music paused before its release finished")
H.Advance(AudioConfig.StopFade / 2)
assert(current.IsPlaying)
H.Advance(AudioConfig.StopFade / 2 + 0.001)
assert(not current.IsPlaying and current.TimePosition == 42, "Pause lost the playback position")
assert(not single:Preview("Music"), "Preview bypassed music mute")
single:ApplySettings(AudioConfig.Defaults)
assert(current.IsPlaying and current.TimePosition == 42 and current.Resumes == 1, "Unmute restarted music")
single:ApplySettings({ MusicVolume = 0.6, MusicMuted = true, SFXVolume = 0.7, SFXMuted = false })
single:ApplySettings(AudioConfig.Defaults)
H.Advance(AudioConfig.StopFade + 0.001)
assert(current.IsPlaying, "Rapid unmute retained a stale pause callback")
single:ApplySettings({ MusicVolume = 0, MusicMuted = false, SFXVolume = 0.7, SFXMuted = false })
H.Advance(AudioConfig.StopFade + 0.001)
assert(not current.IsPlaying, "Zero music slider did not pause")
single:ApplySettings(AudioConfig.Defaults)
single:Destroy()
assert(not current._dead and single.Releasing[current], "Music teardown hard-cut the deck")
H.Advance(AudioConfig.StopFade + 0.001)
assert(current._dead and single.Music._dead and single.SFX._dead, "Faded teardown leaked a deck or group")
Assets.Music = { "", "", "", "", "" }
Assets.Music, Assets.Sounds = shippedMusic, shippedSounds
print(
	"Audio runtime checks passed: silent placeholders, controls, stale snapshots, voice cap, cleanup, crossfades and ducking"
)
