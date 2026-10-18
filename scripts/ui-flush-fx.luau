-- Flush moment: world rig, screen overlays and camera punch with engine-boundary doubles.
-- A function scope keeps these locals out of the bundled file's register budget.
do
	local function run()
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
		-- Real toilet parts (hidden locally during the motion) and a Clone double for the visual copy.
		local function toiletPart(parent, name, y)
			local piece = H.Instance.new("Part")
			piece.Name, piece.CFrame, piece.Size, piece.Parent =
				name, H.CFrame.new(0, y, 0), H.Vector3.new(4, 2, 4), parent
			return piece
		end
		local bowlPart, lidPart = toiletPart(toilet, "Bowl", 2), toiletPart(toilet, "OpenLid", 4)
		function toilet:GetPivot()
			return H.CFrame.new(0, 0, 0)
		end
		local clones = 0
		function toilet:Clone()
			clones += 1
			local copy = H.Instance.new("Model")
			copy.Name = "Toilet"
			function copy:GetPivot()
				return H.CFrame.new(0, 0, 0)
			end
			toiletPart(copy, "Bowl", 2)
			toiletPart(copy, "OpenLid", 4)
			H.Instance.new("Sound").Parent = copy
			return copy
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

		-- No solid square tiles anywhere in the flush moment: every filled overlay frame must be
		-- rounded or soft (UICorner / UIGradient), every emitter uses a soft engine sprite and
		-- every visible world prop is a sphere or mesh. Coin icon art is the intended exception.
		local function shown(object, stop)
			while object and object ~= stop do
				if object.Visible == false then
					return false
				end
				object = object.Parent
			end
			return true
		end
		local function assertNoSquares(screenRoot, label)
			for _, layerName in ipairs({ "FlushFxFront", "FlushFxBack" }) do
				local layer = screenRoot:FindFirstChild(layerName)
				for _, object in ipairs(layer and layer:GetDescendants() or {}) do
					local inCoin = false
					local walk = object
					while walk and walk ~= layer do
						inCoin = inCoin or walk.Name == "FlyingCoin"
						walk = walk.Parent
					end
					if
						not inCoin
						and object:IsA("GuiObject")
						and object.BackgroundTransparency < 1
						and shown(object, screenRoot)
					then
						assert(
							object:FindFirstChildOfClass("UICorner") or object:FindFirstChildOfClass("UIGradient"),
							label .. ": opaque square tile " .. object.Name
						)
					end
				end
			end
			local burst = screenRoot.FlushFxFront:FindFirstChild("ComicBurst")
			if burst and burst.Visible then
				for _, child in ipairs(burst:GetChildren()) do
					if child.Name == "ComicHalo" then
						assert(child.BackgroundTransparency >= 0.5, label .. ": comic halo covers the word")
						assert(child.ZIndex < burst.ComicWord.ZIndex)
					end
				end
				for _, child in ipairs(screenRoot.FlushFxFront:GetChildren()) do
					if child ~= burst and child.Visible and child:IsA("GuiObject") then
						assert(
							child.ZIndex < burst.ComicWord.ZIndex,
							label .. ": " .. child.Name .. " covers the comic word"
						)
					end
				end
			end
			local folder = H.Workspace:FindFirstChild("FlushFx")
			for _, object in ipairs(folder and folder:GetDescendants() or {}) do
				if object.ClassName == "ParticleEmitter" then
					assert(not tostring(object.Texture):find("Square"), label .. ": square sprite on " .. object.Name)
					assert(tostring(object.Texture):match("^rbxasset://textures/particles/.+_main%.dds$"))
				elseif object:IsA("BasePart") and (object.Transparency or 0) < 1 then
					local inClone = false
					local walk = object
					while walk and walk ~= folder do
						inClone = inClone or walk.Name == "FlushFxToilet"
						walk = walk.Parent
					end
					assert(
						inClone or object.Shape == Enum.PartType.Ball or object:FindFirstChildOfClass("SpecialMesh"),
						label .. ": visible block prop " .. object.Name
					)
				end
			end
		end
		local fx, root, hud = harness(false) -- Press feel: deeper squash than the generic button press, plus a ripple.
		hud.FlushButton.Activated:Fire()
		assert(hud.FlushButton.PressRipple.Visible, "Flush press ripple missing")
		-- Common: geyser, toilet motion, comic burst, emoji pops, comet bounce, coins, camera punch.
		local plan = fx:Flush(find("Common"), { Cooldown = 1.5, ServiceCoins = 12 })
		assert(plan and plan.Level == "Clean" and not plan.Collapsed)
		local rig = assert(H.Workspace:FindFirstChild("FlushFx"), "World rig missing")
		assert(rig.FlushFxBowl.Drain.Enabled and rig.FlushFxBowl.Center.Vortex.Emitted == 1, "Wind-up missing")
		assert(root.FlushFxFront.Visible and root.FlushFxBack.Visible and root.FlushFxFront.Flash.Visible)
		-- The local toilet motion hides the server toilet and animates a pooled clone.
		assert(plan.Motion and clones == 1, "Toilet clone missing")
		local copy = assert(rig:FindFirstChild("FlushFxToilet"), "Toilet clone not in the world")
		assert(
			bowlPart.LocalTransparencyModifier == 1 and lidPart.LocalTransparencyModifier == 1,
			"Real toilet not hidden"
		)
		assert(not copy:FindFirstChildOfClass("Sound"), "Clone keeps sounds")
		advance(plan.Burst * 0.5)
		assert(camera.FieldOfView < 70, "Gulp zoom missing")
		advance(plan.Burst * 0.5 + 0.03)
		assert(camera.FieldOfView > 70 and camera.FieldOfView <= 70 + plan.Fov, "FOV punch out of bounds")
		assert(not rig.FlushFxBowl.Drain.Enabled and rig.FlushFxBowl.Center.Splash.Emitted > 0, "Burst missing")
		assert(rig.FlushFxComet.Transparency == 0 and rig.FlushFxComet.CometTrail.Enabled, "Comet not launched")
		local center = rig.FlushFxBowl.Center
		assert(center.Geyser.Enabled and center.Geyser.Rate > 0, "Geyser missing")
		for _, name in ipairs({ "Bubbles", "Foam", "Stars", "Shockwave", "Core" }) do
			assert((center[name].Emitted or 0) > 0, name .. " missing on a Common flush")
		end
		assert((center.Pieces.Emitted or 0) > 0 or (rig.FlushFxBowl.Cannon.CannonPieces.Emitted or 0) > 0)
		-- Overlays update at ScreenHz, so give them a frame or two past the burst.
		advance(0.15)
		assert(root.FlushFxFront.ComicBurst.Visible, "Comic burst missing")
		local word = root.FlushFxFront.ComicBurst.ComicWord.Text
		assert(table.find(Config.Styles[plan.Style].Words, word), "Comic word not from the style: " .. word)
		local pops = 0
		for _, child in ipairs(root.FlushFxFront:GetChildren()) do
			if child.Name == "EmojiPop" and child.Visible then
				pops += 1
			end
		end
		assert(pops > 0 and pops <= plan.EmojiPops, "Emoji pops missing")
		assert(H.RenderBindings.FlushFxCameraApply, "Camera punch missing")
		advance(plan.Land - plan.Burst - 0.1)
		assert(rig.FlushFxComet.Center.LandSparks.Emitted > 0, "Landing missing")
		assert(rig.FlushFxComet.Transparency == 0, "Item bounce missing")
		advance(plan.BounceTime + 0.05)
		assert(rig.FlushFxComet.Transparency == 1, "Bounce outlived its time")
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
		assert(
			bowlPart.LocalTransparencyModifier == 0 and lidPart.LocalTransparencyModifier == 0,
			"Toilet not restored"
		)
		assert(copy.Parent == nil, "Idle clone left in the world")

		do
			-- Every style plays on a Common, with its special props, and never repeats twice in a row.
			local lastStyle
			for _, style in ipairs(Config.StyleOrder) do
				plan = fx:Flush(find("Common"), { ServiceCoins = 4 }, { Style = style })
				assert(plan.Style == style and plan.Comic)
				advance(plan.Burst + 0.12)
				assertNoSquares(root, style)
				if plan.Special == "Ducks" then
					assert(rig.FlushFxDuck.Transparency == 0, "Ducks missing")
				elseif plan.Special == "Rainbow" then
					assert(rig.FlushFxBowl.RainbowBand.Enabled, "Rainbow missing")
				elseif plan.Special == "Lightning" then
					local lit = false
					for _, child in ipairs(rig.FlushFxBowl:GetChildren()) do
						lit = lit or (child.Name == "BoltSegment" and child.Enabled)
					end
					assert(lit, "Lightning missing")
				elseif plan.Special == "Cannons" then
					assert((rig.FlushFxBowl.Cannon.CannonPieces.Emitted or 0) > 0, "Cannons missing")
				elseif plan.Special == "Tornado" then
					assert(center.Twister.Enabled, "Tornado missing")
				end
				advance(4)
			end
			for _ = 1, 40 do
				plan = fx:Flush(find("Common"), { ServiceCoins = 1 })
				assert(plan.Style ~= lastStyle, "Style repeated")
				lastStyle = plan.Style
				advance(2)
			end
			assert(clones == 1, "Toilet clone rebuilt per flush")
			assert(bowlPart.LocalTransparencyModifier == 0)
		end

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
		assertNoSquares(root, "Legendary")
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
		H.Services.UserInputService.TouchEnabled = false

		do
			-- Studio preview buttons: every rarity, x10 random run and a named style, all local.
			local Preview = H.Load("src/client/FlushFx/Preview")
			local studio, studioRoot = harness(false)
			local list = H.Instance.new("Frame")
			list.Parent = studioRoot
			local closed = 0
			local api = assert(Preview.Attach(list, studio, Items, function()
				closed += 1
			end))
			for _, rarity in ipairs(Preview.Rarities) do
				local button = assert(api.Buttons[rarity], "Missing preview button " .. rarity)
				assert(button.Text == "FX preview: " .. rarity or button.Label.Text == "FX preview: " .. rarity)
				local before = studio.Ledger:Live(H.Now)
				local played = api.Play(rarity)
				assert(played and played.Rarity == rarity, rarity .. " preview did not play")
				assert(studio.Ledger:Live(H.Now) >= before)
				advance(4)
			end
			assert(closed >= #Preview.Rarities, "Preview must close the dev panel")
			local flushes = 0
			local original = studio.Flush
			studio.Flush = function(...)
				flushes += 1
				return original(...)
			end
			api.RandomRun(10)
			for _ = 1, 12 do
				advance(Preview.Spacing)
			end
			assert(flushes == 10, "Random run should play 10 flushes, got " .. flushes)
			studio.Flush = original
			api.Buttons.Style.Activated:Fire()
			local chosen = api.Selected()
			assert(chosen == Config.StyleOrder[2])
			local styled = api.Play("Common", chosen)
			assert(styled.Style == chosen, "Named style preview ignored")
			advance(4)
			studio:Destroy()
			studioRoot:Destroy()
		end
		plot:Destroy()
		camera.CFrame = H.CFrame.new()
		print(
			"Flush FX passed: world rig, toilet clone, styles, comic, bounce, press feel, tiers, underlay, cadence, pooling, settings, mobile caps, Studio preview, teardown"
		)
	end
	run()
end
