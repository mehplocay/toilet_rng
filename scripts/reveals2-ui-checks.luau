-- Production presentation with a temporary ninth-tier fixture, never shipped data.
do
	local module = H.Load("src/client/Presentation/RevealController")
	local config = H.Load("src/shared/Config/Reveals")
	local rarities = H.Load("src/shared/Config/Rarities")
	local items = H.Load("src/shared/Config/Items")
	local function find(rarity)
		for _, item in ipairs(items) do
			if item.Rarity == rarity then
				return item
			end
		end
		error(rarity)
	end
	local celestial = table.clone(find("Godly"))
	celestial.Id, celestial.Name, celestial.Rarity = "CelestialFixture", "Astral Discovery", "Celestial"
	local oldCelestial, oldOrder = rarities.Celestial, rarities.Secret.Order
	local lighting = H.Services.Lighting
	lighting.ClockTime = 14
	local sky = H.Instance.new("Sky")
	sky.StarCount, sky.Parent = 321, lighting
	for _, viewport in ipairs(H.Viewports) do
		local root = H.Root(viewport[1], viewport[2])
		local mobile = viewport[1] < 760
		H.Services.UserInputService.TouchEnabled = mobile
		local cues = {}
		local controller = module.Create(root, { Frame = root, SetHintVisible = function() end }, {
			Play = function(_, cue, _, gain)
				table.insert(cues, { cue, gain })
			end,
		})
		controller:UpdateDiscovery({ [find("Legendary").Id] = 1 })
		controller:Show(find("Mythic"), { Admin = true })
		assert(not root.RareReveal.RevealContent:FindFirstChild("NewDiscovery"))
		controller:Skip()
		if not oldCelestial then
			rarities.Celestial = nil
			controller:Show(celestial)
			assert(not controller.Queue.Active, "Dormant rarity must allocate nothing")
		end
		rarities.Celestial = { Order = 8, Color = Color3.fromRGB(178, 247, 255) }
		rarities.Secret.Order = 9
		for _, rarity in ipairs({ "Legendary", "Mythic", "Godly", "Celestial", "Secret" }) do
			local item = if rarity == "Celestial" then celestial else find(rarity)
			controller:Show(item)
			local content = root.RareReveal.RevealContent
			assert(content:FindFirstChild(config.Tiers[rarity].Signature), rarity .. " signature missing")
			assert((content:FindFirstChild("NewDiscovery") ~= nil) == (rarity ~= "Legendary"))
			assert(cues[#cues][1] == config.Tiers[rarity].Sound)
			local particles = 0
			for _, child in ipairs(content:GetDescendants()) do
				if child.Name == "Star" or child.Name == "CrystalShard" or child.Name == "Confetti" then
					particles += 1
				end
				assert(child.ClassName ~= "ParticleEmitter", "Reveal must not add world emitters")
			end
			assert(particles <= (if mobile then config.MobileParticleCap else config.ParticleCap))
			if mobile then
				assert(not lighting:FindFirstChild("RevealFocus"))
			end
			if rarity == "Secret" then
				assert(content.ItemName.Text == "???" and not content.ItemViewport.Visible and not content.Odds.Visible)
				H.Snapshot(root, "reveal2-secret-hidden-" .. viewport[1] .. "x" .. viewport[2])
				H.Advance(1.5)
				assert(
					content.ItemName.Text == item.Name and content.ItemViewport.Visible and content.GlitchRed.Visible
				)
			elseif rarity == "Celestial" then
				assert(
					content.Starlight:FindFirstChild("Halo") and content.Starlight:FindFirstChild("ConstellationLine")
				)
				assert(content.ItemName:FindFirstChildOfClass("UIGradient") and not H.RenderBindings.FlushRevealShake)
				assert(lighting.ClockTime == 0 and sky.StarCount == 1800)
			end
			H.Advance(0.25)
			H.Snapshot(root, "reveal2-" .. string.lower(rarity) .. "-" .. viewport[1] .. "x" .. viewport[2])
			controller:Skip()
			assert(lighting.ClockTime == 14 and sky.StarCount == 321)
			assert(not lighting:FindFirstChild("FlushCinematicTint") and not lighting:FindFirstChild("RevealFocus"))
			assert(not H.RenderBindings.FlushRevealUndo and not H.RenderBindings.FlushRevealShake)
			controller:Show(item)
			assert(not root.RareReveal.RevealContent:FindFirstChild("NewDiscovery"), "Repeat discovery stamped")
			controller:Skip()
		end
		controller:UpdateDiscovery({}) -- A replacement/reset snapshot must not forget lifetime finds.
		controller:Show(find("Secret"), { Admin = true })
		assert(not root.RareReveal.RevealContent:FindFirstChild("NewDiscovery"))
		for _ = 1, 100 do
			controller:Show(find("Mythic"))
			controller:Show(find("Common"), { Compact = true })
		end
		assert(controller.Queue.Active.Item.Rarity == "Secret" and #controller.Queue.Pending == 2)
		controller:SetIntensity("Reduced")
		assert(lighting.ClockTime == 14 and sky.StarCount == 321)
		controller:Show(celestial)
		assert(controller.Queue.Active.Tier == "Pop" and not root:FindFirstChild("Starlight", true))
		controller:SetIntensity("Off")
		controller:Show(celestial)
		assert(not controller.Queue.Active and root.RareReveal.CompactDrop.Visible)
		controller:SetIntensity("Full")
		controller:Show(find("Secret"))
		H.Advance(config.Tiers.Secret.Duration + 0.01)
		assert(not controller.Queue.Active and lighting.ClockTime == 14)
		controller:Show(celestial)
		controller:Destroy()
		assert(lighting.ClockTime == 14 and sky.StarCount == 321)
		root:Destroy()
	end
	H.Services.UserInputService.TouchEnabled = false
	rarities.Celestial, rarities.Secret.Order = oldCelestial, oldOrder
	-- Real server-event consumer plus overlapping local sky, including replacement/skip.
	local root = H.Root(1280, 684)
	local effects = H.Load("src/client/Effects").Create(root, nil, { EventActive = function() end })
	local components = H.Load("src/client/UI/Components")
	local oldHook, eventCues = components.SoundHook, {}
	components.SoundHook = function(cue)
		table.insert(eventCues, cue)
	end
	effects.Event({ ItemId = find("Secret").Id, PlayerName = H.Services.Players.LocalPlayer.Name })
	assert(#eventCues == 0, "Finder event must not replace the unique reveal stinger")
	effects.SetSkip(true)
	effects.SetSkip(false)
	local lease = H.Load("src/client/Presentation/RevealSky").Acquire(config.Tiers.Celestial)
	effects.Event({ ItemId = find("Secret").Id, PlayerName = "Tester" })
	assert(eventCues[#eventCues] == "Secret", "Other recipients use the unique Secret hook")
	assert(root.ServerEventBanner.Visible and sky.StarCount == 900)
	lease()
	assert(lighting.ClockTime == 0 and sky.StarCount == 900, "Local skip restored active server night")
	effects.SetSkip(true)
	assert(lighting.ClockTime == 14 and sky.StarCount == 321)
	effects.SetSkip(false)
	effects.Event({ ItemId = find("Secret").Id, PlayerName = "Tester" })
	H.Advance(5.1)
	assert(not root.ServerEventBanner.Visible and lighting.ClockTime == 14)
	effects.Event({ ItemId = find("Secret").Id, PlayerName = "Tester" })
	root:Destroy()
	H.Advance(6)
	assert(lighting.ClockTime == 14 and sky.StarCount == 321)
	sky:Destroy()
	components.SoundHook = oldHook
end
do
	local oldAuto = state.AutoFlush
	state.AutoFlush, H.FarFromPlot = true, true
	bootRemotes.State.OnClientEvent:Fire(state)
	bootRemotes.Event.OnClientEvent:Fire({ ItemId = "Mystery", PlayerName = H.Services.Players.LocalPlayer.Name })
	assert(clientRoot.HUD.ServerEventBanner.Visible, "Far Secret finder missed the shared banner")
	assert(H.Services.Lighting.ClockTime == 0, "Far Secret finder missed the shared sky")
	state.AutoFlush, H.FarFromPlot = oldAuto, false
	bootRemotes.State.OnClientEvent:Fire(state)
	H.Advance(5.1)
	assert(not clientRoot.HUD.ServerEventBanner.Visible and H.Services.Lighting.ClockTime == 14)
end
print(
	"Reveals2 passed: nine-tier activation, signatures, discovery, conceal/reveal, mobile caps, queue pressure, all modes, shared sky and teardown"
)
