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
	for _, entry in ipairs(Layout.PlotPieces) do
		local piece = Kit.Place(model, entry, cf)
		if entry.Asset == "PlotPlatform" then
			piece.PrimaryPart:SetAttribute("PlotTint", true)
		end
	end
	local signCF = cf * CFrame.new(-19, 5.5, -22.95)
	local sign = Kit.Label(
		model,
		"PlotName",
		signCF,
		Vector3.new(6.3, 2.2, 0.1),
		"Available Plot " .. index,
		Color3.new(1, 1, 1),
		false,
		Guidance.SignDistance
	)
	Kit.Label(
		model,
		"EntranceName",
		cf * CFrame.new(0, 12.6, -27.65),
		Vector3.new(12, 2.5, 0.1),
		"PLOT " .. index,
		Color3.new(1, 1, 1),
		false
	)
	local toiletCF = cf * CFrame.new(Layout.ToiletOffset)
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
		Displays = displays,
	}
	require(script.Parent.Parent.DisplayRows).Build(plot, { ToiletTier = 1, DisplaySlots = 0, Displays = {} })
	return plot
end
return Plot
