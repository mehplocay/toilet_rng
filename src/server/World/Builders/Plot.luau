local Kit = require(script.Parent.Parent.Kit)
local Layout = require(game.ReplicatedStorage.Shared.Config.MapLayout)
local Guidance = require(game.ReplicatedStorage.Shared.Config.PlotGuidance)
local Plot = {}
function Plot.Build(root, cf, index)
	cf = cf + Vector3.new(0, Layout.PlotRise, 0)
	local model = Instance.new("Model")
	model.Name, model.Parent = "Plot" .. index, root
	Kit.Proxy(
		model,
		"PlotFloor",
		cf * CFrame.new(0, -Layout.PlotRise / 2, 0),
		Vector3.new(Layout.PlotWidth, Layout.PlotRise, Layout.PlotDepth),
		true
	)
	local glowRing = {}
	for _, entry in ipairs(Layout.PlotPieces) do
		local piece = Kit.Place(model, entry, cf)
		if entry.Asset == "PlotPlatform" then
			piece.PrimaryPart:SetAttribute("PlotTint", true)
		end
		if entry.ToiletRing then
			piece.Name = "ToiletGlowRing"
			table.insert(glowRing, { Part = piece.PrimaryPart, Size = piece.PrimaryPart.Size })
		end
	end
	local signCF = cf * CFrame.new(Layout.PlotSign.Position)
	local sign = Kit.Label(
		model,
		"PlotName",
		signCF,
		Layout.PlotSign.Size,
		"Available Plot " .. index,
		Color3.new(1, 1, 1),
		false,
		Guidance.SignDistance
	)
	local _, flushAnchor = Kit.Label(
		model,
		"FlushMarker",
		cf * CFrame.new(Layout.FlushLabel.Position),
		Layout.FlushLabel.Size,
		"FLUSH",
		Color3.new(1, 1, 1),
		true,
		Layout.FlushLabel.Distance
	)
	for step = 1, Layout.Rebirth.Steps do
		Kit.Label(
			model,
			"RebirthLocked",
			cf
				* CFrame.new(
					Layout.Rebirth.X,
					Layout.Rebirth.SignBaseHeight + step * Layout.Rebirth.Rise,
					Layout.Rebirth.StartZ + (step - 1) * Layout.Rebirth.Pitch
				),
			Layout.Rebirth.SignSize,
			"\u{1F512} Rebirth " .. step,
			Color3.fromRGB(unpack(Layout.Rebirth.SignColor)),
			true,
			Layout.Rebirth.SignDistance
		)
	end
	local toiletCF = cf * CFrame.new(Layout.ToiletOffset)
	-- The client reads a BasePart prompt parent, while the server reads plot.CFrame.
	-- Both stay at the foot datum, independent of tall tier ornaments and animation.
	local promptAnchor = Kit.Proxy(model, "FlushAnchor", toiletCF, Vector3.new(0.2, 0.2, 0.2), false)
	local position = (toiletCF * CFrame.new(Guidance.SpawnOffset)).Position
	local spawnCF = CFrame.lookAt(position, Vector3.new(toiletCF.Position.X, position.Y, toiletCF.Position.Z))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size = "PlotSpawn", Vector3.new(2, 0.2, 2)
	spawn.CFrame = spawnCF - Vector3.new(0, Guidance.SpawnOffset.Y - 0.1, 0)
	spawn.Anchored, spawn.CanCollide, spawn.CanTouch, spawn.CanQuery = true, false, false, false
	spawn.Transparency, spawn.Duration = 1, 0
	spawn.Neutral, spawn.AllowTeamChangeOnTouch, spawn.Enabled = true, false, true
	spawn.Parent = model
	local displays = Instance.new("Folder")
	displays.Name, displays.Parent = "Displays", model
	local plot = {
		Model = model,
		CFrame = toiletCF,
		LayoutCFrame = cf,
		SignPosition = signCF.Position,
		Spawn = spawn,
		SpawnCFrame = spawnCF,
		Sign = sign,
		PromptAnchor = promptAnchor,
		FlushMarker = flushAnchor,
		GlowRing = glowRing,
		Displays = displays,
	}
	require(script.Parent.Parent.DisplayRows).Build(plot, { ToiletTier = 1, DisplaySlots = 0, Displays = {} })
	return plot
end
return Plot
