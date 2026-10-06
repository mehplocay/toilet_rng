do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local player = H.Instance.new("Player")
	local character = H.Instance.new("Model")
	local humanoid = H.Instance.new("Humanoid")
	humanoid.Health, humanoid.MoveDirection, humanoid.Parent = 100, Vector3.new(0, 0, 1), character
	local hrp = H.Instance.new("Part")
	hrp.Name, hrp.Position, hrp.Parent = "HumanoidRootPart", Vector3.new(-114, 3, -200), character
	player.Character = character
	player:SetAttribute("PathSpeedMultiplier", 3)
	local camera = H.Workspace.CurrentCamera
	camera.FieldOfView = 70
	local frame = H.Services.RunService.RenderStepped
	H.Load("src/client/PathBoostEffects").Start(root, player, remotes)
	local folder
	for _, child in ipairs(H.Workspace:GetChildren()) do
		if child.Name == "LocalPathChevrons" then
			folder = child -- The full-client boot fixture owns an earlier effects instance.
		end
	end
	assert(folder and #folder:GetChildren() == 8)
	local function advance()
		for _ = 1, 90 do
			frame:Fire(1 / 60)
		end
	end
	advance()
	local pathRules = H.Load("src/shared/PathBoostRules")
	local zones = pathRules.Zones(
		H.Load("src/shared/Config/MapLayout"),
		H.Load("src/shared/Config/MeshCatalog"),
		H.Load("src/shared/Config/PathBoost")
	)
	assert(pathRules.Find(zones, -114, 3, -196, 7), "Fixture is not on a promenade")
	assert(root.PathSpeedChip.Visible and root.PathSpeedChip.Text == "Speed x3")
	assert(math.abs(camera.FieldOfView - 75) < 1e-8, "Boost FOV: " .. tostring(camera.FieldOfView))
	assert(folder:GetChildren()[1].Transparency < 1, "Moving path arrows are hidden")
	local firstPosition = folder:GetChildren()[1].CFrame.Position
	frame:Fire(0.05)
	assert((folder:GetChildren()[1].CFrame.Position - firstPosition).Magnitude > 0)
	for _, mode in ipairs({ "Reduced", "Off" }) do
		remotes.State.OnClientEvent:Fire({ Settings = { RevealIntensity = mode } })
		advance()
		assert(root.PathSpeedChip.Visible and math.abs(camera.FieldOfView - 70) < 1e-8, "Reduced FOV was not restored")
		for _, part in ipairs(folder:GetChildren()) do
			assert(part.Transparency == 1 and not part.CanCollide and not part.CanTouch and not part.CanQuery)
		end
		for _, child in ipairs(root:GetChildren()) do
			assert(child.Name ~= "SpeedLine" or not child.Visible)
		end
	end
	remotes.State.OnClientEvent:Fire({ Settings = { RevealIntensity = "Full" } })
	advance()
	local nextCamera = H.Instance.new("Camera")
	nextCamera.FieldOfView = 80
	H.Workspace.CurrentCamera = nextCamera
	advance()
	assert(
		math.abs(camera.FieldOfView - 70) < 1e-8 and math.abs(nextCamera.FieldOfView - 85) < 1e-8,
		"Camera swap leaked FOV"
	)
	nextCamera.FieldOfView = 90 -- Another controller owns this new base.
	advance()
	player:SetAttribute("PathSpeedMultiplier", 1)
	advance()
	assert(not root.PathSpeedChip.Visible and math.abs(nextCamera.FieldOfView - 90) < 1e-8, "Path exit leaked FOV")
	player:SetAttribute("PathSpeedMultiplier", 4)
	advance()
	humanoid.Health = 0
	advance()
	assert(not root.PathSpeedChip.Visible and math.abs(nextCamera.FieldOfView - 90) < 1e-8, "Death leaked FOV")
	humanoid.Health = 100
	advance()
	assert(root.PathSpeedChip.Text == "Speed x4")
	root:Destroy()
	assert(folder._dead and math.abs(nextCamera.FieldOfView - 90) < 1e-8, "Destroy leaked path effects")
	frame:Fire(1 / 60)
	assert(math.abs(nextCamera.FieldOfView - 90) < 1e-8 and folder._dead)
	H.Workspace.CurrentCamera = camera
	character:Destroy()
	player:Destroy()
end
print(
	"Path feedback passed: moving arrows, speed chip, Reduced/Off, camera replacement, exact FOV restore, death and cleanup"
)
do
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local config = H.Load("src/shared/Config/Monetization")
	local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
	local body = ui.Panel.ContentScroll.Body
	local passes = ui.Panel:FindFirstChild("OfferGrid", true)
	local boosts = ui.Panel:FindFirstChild("BoostGrid", true)
	ui.Panel.Visible = true
	body.BoostsTab.Activated:Fire()
	assert(boosts.Visible and not passes.Visible)
	for _, viewport in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = viewport[1], Y = viewport[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		for _, key in ipairs(config.ProductOrder) do
			local card = (if config.DeveloperProducts[key].LuckyCharges
				then ui.Panel:FindFirstChild("LuckyGrid", true)
				else boosts)[key].OfferCard
			assert(card.Buy.Text == "Coming soon" and not card.Buy.Interactable)
			assert(card.Buy.AbsoluteSize.X >= 100 and card.Buy.AbsoluteSize.Y >= 44)
			local calls = #H.Calls
			card.Buy.Activated:Fire()
			assert(#H.Calls == calls, "Zero-ID product sent a request")
		end
		H.Snapshot(root, "boosts-" .. viewport[1] .. "x" .. viewport[2])
	end
	local original = H.Services.MarketplaceService.GetProductInfoAsync
	H.Services.MarketplaceService.GetProductInfoAsync = function(_, id, kind)
		if kind == "InfoType.GamePass" then
			return { IsForSale = false, PriceInRobux = 59 }
		end
		assert(id == 234 and kind == "InfoType.Product")
		return { IsForSale = true, PriceInRobux = 45 }
	end
	config.DeveloperProducts.Coins10Minutes.Id = 234
	ui.Panel.Visible = false
	ui.Panel.Visible = true
	H.StartTasks()
	local state = { Settings = {}, OwnedPasses = {}, Commerce = { Quotes = { Coins10Minutes = 4321 } } }
	ui.Update(state)
	local card = boosts.Coins10Minutes.OfferCard
	assert(card.Buy.Text == "45" and card.Buy.Interactable and card.OfferStatus.Text == "4.3K Coins")
	card.Buy.Activated:Fire()
	local call = H.Calls[#H.Calls]
	assert(call.Name == "BuyProduct" and call.Args[1] == "Coins10Minutes" and call.Args[2] == 4321)
	state.Commerce.PendingProduct = "Coins10Minutes"
	ui.Update(state)
	assert(not card.Buy.Interactable)
	state.Commerce.CanResume = true
	ui.Update(state)
	assert(card.Buy.Interactable)
	state.Commerce.PendingProduct = nil
	ui.Update(state)
	for _, child in ipairs(body:GetChildren()) do
		assert(
			not (child.Text and string.find(child.Text, "Saved offer:", 1, true)),
			"Completed quote left a stale banner"
		)
	end
	body.PassesTab.Activated:Fire()
	assert(passes.Visible and not boosts.Visible)
	local chest = ui.Panel:FindFirstChild("VIPChest", true)
	assert(not chest.Interactable)
	state.OwnedPasses.VIPPack = true
	ui.Update(state)
	assert(chest.Interactable)
	chest.Activated:Fire()
	assert(H.Calls[#H.Calls].Name == "ClaimVIP")
	state.Commerce.VIPDay = math.floor(os.time() / 86400)
	ui.Update(state)
	assert(not chest.Interactable and chest.Text == "VIP chest claimed today")
	config.DeveloperProducts.Coins10Minutes.Id = 0
	H.Services.MarketplaceService.GetProductInfoAsync = original
	root:Destroy()
end
print(
	"Catalog UI passed: Passes/Boosts tabs, product phone layouts, zero IDs, platform prices, quotes, resume and VIP chest"
)
