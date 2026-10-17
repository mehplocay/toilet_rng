-- Flush moment: world rig, screen overlays and camera punch with engine-boundary doubles.
do
	local Config = H.Load("src/shared/Config/FlushFx")
	local Items = H.Load("src/shared/Config/Items")
	local C = H.Load("src/client/UI/Components")
	local module = H.Load("src/client/FlushFx/Controller")
	local lighting = H.Services.Lighting
	local camera = H.Workspace.CurrentCamera
	local function find(rarity)
		for _, item in ipairs(Items) do
			if item.Rarity == rarity then
				return item
			end
		end
		error(rarity)
	end
	camera.CFrame = H.CFrame.new(0, 30, 40)
	camera.FieldOfView = 70
	camera.WorldToViewportPoint = function(_, position)
		return H.Vector3.new(640 + position.X, 300, 0), true
	end
	local function render()
		for _, name in ipairs({ "FlushFxCameraUndo", "FlushFxCameraApply" }) do
			local fn = H.RenderBindings[name]
			if fn then
				fn(1 / 60)
			end
		end
	end
	local function advance(seconds)
		local steps = math.ceil(seconds * 60)
		for _ = 1, steps do
			H.Advance(seconds / steps)
			render()
		end
	end
	-- Owned plot double: prompt -> FlushAnchor (foot datum) -> plot model -> Toilet.
	local plot = H.Instance.new("Model")
	plot.Parent = H.Workspace
	local foot = H.Instance.new("Part")
	foot.Name, foot.CFrame, foot.Parent = "FlushAnchor", H.CFrame.new(0, 0, 0), plot
	local toilet = H.Instance.new("Model")
	toilet.Name, toilet.Parent = "Toilet", plot
	function toilet:GetBoundingBox()
		return H.CFrame.new(0, 9.5, 0), H.Vector3.new(11, 19, 13)
	end
	local prompt = H.Instance.new("ProximityPrompt")
	prompt.Parent = foot
	local prompts = {
		Own = function()
			return prompt
		end,
	}
	local function harness(touch)
		H.Services.UserInputService.TouchEnabled = touch
		local root = H.Root(if touch then 390 else 1280, if touch then 844 else 720)
		local hudFrame = H.Instance.new("Frame")
		hudFrame._fixed, hudFrame.Parent = root._fixed, root
		local wallet = H.Instance.new("Frame")
		wallet.Name, wallet.Parent, wallet._pos, wallet._fixed =
			"Wallet", hudFrame, H.Vector2.new(8, 60), H.Vector2.new(136, 28)
		local button = C.Button(hudFrame, "FLUSH", H.UDim2.fromOffset(200, 80), nil, function() end, C.Green)
		local hud = { Frame = hudFrame, FlushButton = button }
		return module.Start(root, hud, prompts), root, hud
	end

	local fx, root, hud = harness(false)
	-- Press feel: deeper squash than the generic button press, plus a ripple.
	hud.FlushButton.Activated:Fire()
	assert(hud.FlushButton.PressRipple.Visible, "Flush press ripple missing")
	-- Common: world one-shots, comet, coins, FOV punch; no flash/rays/text.
	local plan = fx:Flush(find("Common"), { Cooldown = 1.5, ServiceCoins = 12 })
	assert(plan and plan.Level == "Clean" and not plan.Collapsed)
	local rig = assert(H.Workspace:FindFirstChild("FlushFx"), "World rig missing")
	assert(rig.FlushFxBowl.Drain.Enabled and rig.FlushFxBowl.Center.Vortex.Emitted == 1, "Wind-up missing")
	assert(root.FlushFxFront.Visible and not root.FlushFxBack.Visible and not root.FlushFxFront.Flash.Visible)
	advance(plan.Burst * 0.5)
	assert(camera.FieldOfView < 70, "Gulp zoom missing")
	advance(plan.Burst * 0.5 + 0.03)
	assert(camera.FieldOfView > 70 and camera.FieldOfView <= 70 + plan.Fov, "FOV punch out of bounds")
	assert(not rig.FlushFxBowl.Drain.Enabled and rig.FlushFxBowl.Center.Splash.Emitted > 0, "Burst missing")
	assert(rig.FlushFxComet.Transparency == 0 and rig.FlushFxComet.CometTrail.Enabled, "Comet not launched")
	advance(plan.Land - plan.Burst + 0.05)
	assert(rig.FlushFxComet.Transparency == 1 and rig.FlushFxComet.Center.LandSparks.Emitted > 0, "Landing missing")
	local flying = 0
	for _, child in ipairs(root.FlushFxFront:GetChildren()) do
		if child.Name == "FlyingCoin" and child.Visible then
			flying += 1
		end
	end
	assert(flying > 0 and flying <= plan.Coins, "Coins must fly to the wallet")
	advance(1.5)
	assert(hud.Frame.Wallet:FindFirstChild("FlushFxPulse"), "Wallet pulse missing")
	assert(not root.FlushFxFront.Visible and not fx.Busy(), "Overlay or heartbeat outlived the moment")
	assert(camera.FieldOfView == 70 and not H.RenderBindings.FlushFxCameraApply, "Camera not restored")

	-- Pooling: repeated flushes of every tier allocate no new instances after warm-up.
	for _, rarity in ipairs({ "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }) do
		fx:Flush(find(rarity), { Cooldown = 1.5, ServiceCoins = 5 })
		advance(5)
	end
	local warm = #H.Objects
	for i = 1, 60 do
		local rarity = ({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Celestial", "Secret" })[i % 8 + 1]
		fx:Flush(find(rarity), { Cooldown = 0.4, ServiceCoins = 3 })
		advance(0.4)
	end
	assert(#H.Objects == warm, "Flush FX allocated instances per flush: " .. (#H.Objects - warm))
	advance(6)

	-- Legendary: full-screen rays, rarity stinger, edge glow, confetti and colour grade.
	plan = fx:Flush(find("Legendary"), { Cooldown = 1.5, ServiceCoins = 50 })
	assert(plan.Big and root.FlushFxBack.Visible and root.FlushFxBack.LightRays.Visible)
	advance(plan.Burst + 0.1)
	assert(root.FlushFxBack.RarityStinger.Visible and root.FlushFxBack.RarityStinger.Text == "LEGENDARY!")
	local grade = fx.Screen:GradeEffect()
	assert(grade.Parent == lighting and grade.Enabled and grade.Brightness > 0, "Colour grade missing")
	local edges = 0
	for _, child in ipairs(root.FlushFxFront:GetChildren()) do
		if child.Name == "EdgeGlow" and child.Visible and child.BackgroundTransparency < 1 then
			edges += 1
		end
	end
	assert(edges == 4, "Edge glow missing")
	assert(not H.RenderBindings.FlushRevealShake, "Flush FX must not own reveal shake")
	assert(rig.FlushFxBowl.Pillar.Enabled and rig.FlushFxBowl.Pillar.Width0 > 0, "Light pillar missing")
	-- A common flush during the legendary is only an underlay.
	local under = fx:Flush(find("Common"), { Cooldown = 0.4 })
	assert(under.Underlay and root.FlushFxBack.LightRays.Visible, "Underlay replaced the bigger moment")
	advance(0.6)
	local pieces = 0
	for _, child in ipairs(root.FlushFxFront:GetChildren()) do
		if child.Name == "ConfettiPiece" and child.Visible then
			pieces += 1
		end
	end
	assert(pieces > 0 and pieces <= Config.Caps.ScreenConfetti, "Confetti rain missing")
	H.Snapshot(root, "flushfx-legendary-1280x720")
	advance(4)
	assert(not root.FlushFxFront.Visible and not root.FlushFxBack.Visible and not grade.Enabled)
	assert(not rig.FlushFxBowl.Pillar.Enabled and not rig.FlushFxBowl.Center.Flash.Enabled)

	-- Rapid auto flushing stays inside its cadence and the live particle budget.
	for _ = 1, 50 do
		plan = fx:Flush(find("Rare"), { Automatic = true, AutoInterval = 0.4, Cooldown = 0.4, ServiceCoins = 1 })
		assert(plan.Collapsed and plan.Duration <= 0.4 + 1e-9)
		assert(fx.Ledger:Live(H.Now) <= fx.Ledger.Cap)
		advance(0.4)
	end
	advance(3)

	-- Settings: Reduced keeps calm world one-shots only; Off and compact show nothing.
	fx:SetIntensity("Reduced")
	plan = fx:Flush(find("Mythic"), { Cooldown = 1.5, ServiceCoins = 5 })
	assert(plan.Reduced and not root.FlushFxBack.Visible and not H.RenderBindings.FlushFxCameraApply)
	assert(not grade.Enabled and not root.FlushFxFront.Flash.Visible)
	advance(3)
	fx:SetIntensity("Off")
	assert(fx:Flush(find("Secret"), { Cooldown = 1.5 }) == nil and not root.FlushFxFront.Visible)
	fx:SetIntensity("Full")
	assert(fx:Flush(find("Secret"), { Compact = true }) == nil)
	assert(fx:Flush({ Rarity = "Forged" }, {}) == nil and fx:Flush(nil, nil) == nil)

	-- Destroy mid-moment releases the rig, overlays, grade and camera bindings.
	fx:Flush(find("Secret"), { Cooldown = 1.5, ServiceCoins = 5 })
	advance(0.5)
	fx:Destroy()
	assert(not H.Workspace:FindFirstChild("FlushFx") and not root:FindFirstChild("FlushFxFront"))
	assert(grade.Parent == nil and not H.RenderBindings.FlushFxCameraApply)
	assert(camera.FieldOfView == 70)
	fx:Destroy()
	root:Destroy()

	-- Phone: mobile caps for confetti and coins.
	local phone, phoneRoot = harness(true)
	plan = phone:Flush(find("Secret"), { Cooldown = 1.5, ServiceCoins = 99 })
	assert(plan.ScreenConfetti <= Config.MobileCaps.ScreenConfetti and plan.Coins <= Config.MobileCaps.Coins)
	advance(1.2)
	local visible = 0
	for _, child in ipairs(phoneRoot.FlushFxFront:GetChildren()) do
		if child.Name == "ConfettiPiece" and child.Visible then
			visible += 1
		end
	end
	assert(visible <= Config.MobileCaps.ScreenConfetti)
	H.Snapshot(phoneRoot, "flushfx-secret-390x844")
	phone:Destroy()
	phoneRoot:Destroy()
	plot:Destroy()
	H.Services.UserInputService.TouchEnabled = false
	camera.CFrame = H.CFrame.new()
	print("Flush FX passed: world rig, press feel, tiers, underlay, cadence, pooling, settings, mobile caps, teardown")
end
