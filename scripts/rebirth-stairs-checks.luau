-- Bundled by check-visuals.ps1: exercise production refresh and reused world geometry.
do
	local stairs = loadModule(node("src/server/World/RebirthStairs"))
	local config = loadModule(node("src/shared/Config/Rebirth"))
	local layout = loadModule(node("src/shared/Config/MapLayout"))
	local rarities = loadModule(node("src/shared/Config/Rarities"))
	local plot = Plot.Build(root, CFrame.new(), 1)
	local owner = { UserId = 321, DisplayName = "Visitor-visible Owner" }
	local profile = { ToiletTier = 4, DisplaySlots = 3, Displays = {}, RebirthLevel = 0 }
	World.Assigned[owner], plot.Owner = plot, owner
	World:Refresh(owner, profile)
	local instances, tweenCount = #plot.Model:GetDescendants(), #tweens
	for level = 0, #config.Levels do
		profile.RebirthLevel = level
		World:Refresh(owner, profile)
		assert(plot.Sign.Text == owner.DisplayName .. "'s Plot\nRebirth " .. level)
		local unlockedCount, nextCount = 0, 0
		for _, step in ipairs(plot.RebirthSteps) do
			assert(#step.Surfaces == 2, "Each terrace must reuse its step and trim")
			local milestone = tonumber(step.Label.Text:match("Rebirth (%d+)"))
			local unlocked = milestone <= level
			local nextStep = milestone == level + 1 and level < #config.Levels
			unlockedCount += if unlocked then 1 else 0
			nextCount += if nextStep then 1 else 0
			assert(step.Label.Parent.MaxDistance == layout.Rebirth.SignDistance)
			assert(not step.Label.RichText and not step.Label.Parent.AlwaysOnTop)
			if nextStep then
				assert(step.Label.Text == "Rebirth " .. (level + 1) .. ":\n3,600 flushes + Diamond")
			elseif unlocked then
				assert(step.Label.Text == "Rebirth " .. milestone .. ": Unlocked")
			else
				assert(step.Label.Text == "\u{1F512} Rebirth " .. milestone)
			end
			for _, surface in ipairs(step.Surfaces) do
				assert(not surface.Part.CanCollide and not surface.Part.CanTouch and not surface.Part.CanQuery)
				assert(
					surface.Part.Material
						== (if unlocked or nextStep then Enum.Material.Neon else Enum.Material.SmoothPlastic)
				)
				assert(surface.Part.Color == (if unlocked or nextStep then step.Label.TextColor3 else surface.Color))
			end
		end
		assert(nextCount == (if level < #config.Levels then 1 else 0))
		assert(unlockedCount == math.min(level, if level == #config.Levels then 5 else 4))
		World:Refresh(owner, profile)
		assert(
			#plot.Model:GetDescendants() == instances and #tweens == tweenCount,
			"Stairs refresh allocated instances/VFX"
		)
	end
	stairs.Refresh(plot, nil, nil)
	for index, step in ipairs(plot.RebirthSteps) do
		assert(step.Label.Text == "\u{1F512} Rebirth " .. index)
		assert(step.Label.TextColor3 == rarities.Common.Color)
		for _, surface in ipairs(step.Surfaces) do
			assert(surface.Part.Color == surface.Color and surface.Part.Material == Enum.Material.SmoothPlastic)
		end
	end
	local replacementOwner = { UserId = 654, DisplayName = "New Owner" }
	World.Assigned[owner], World.Assigned[replacementOwner], plot.Owner = nil, plot, replacementOwner
	profile.RebirthLevel = 2
	World:Refresh(replacementOwner, profile)
	assert(plot.StairsOwnerId == replacementOwner.UserId)
	assert(plot.Sign.Text == "New Owner's Plot\nRebirth 2")
	assert(plot.RebirthSteps[3].Label.Text == "Rebirth 3:\n3,600 flushes + Diamond")
	World.Assigned[replacementOwner] = nil
	plot.Model:Destroy()
	print(
		"Rebirth stairs: levels 0-15, next requirement, cap, release/reassignment, idempotence and zero added instances passed"
	)
end
