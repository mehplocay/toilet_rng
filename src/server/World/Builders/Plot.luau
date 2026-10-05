local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local V = require(game.ReplicatedStorage.Shared.Config.Visuals).Palette
local Decor = require(script.Parent.Decor)
local Guidance = require(game.ReplicatedStorage.Shared.Config.PlotGuidance)
local Settings = require(game.ReplicatedStorage.Shared.Config.WorldModels)
local Plot = {}
function Plot.Build(root, cf, index)
	local model = Instance.new("Model")
	model.Name, model.Parent = "Plot" .. index, root
	local floor = P.Part(model, "Lawn", Vector3.new(30, 0.4, 28), cf, V.Grass)
	floor.CanCollide = true
	for _, x in ipairs({ -15, 15 }) do
		P.Part(model, "StoneBorder", Vector3.new(0.7, 0.7, 28), cf * CFrame.new(x, 0.25, 0), V.TileA)
		Decor.Fence(model, cf * CFrame.new(x, 0.2, 0) * CFrame.Angles(0, math.pi / 2, 0), 28)
		Decor.Tree(model, cf * CFrame.new(x * 0.75, 0.2, 9), true)
		Decor.Bush(model, cf * CFrame.new(x * 0.78, 0.2, -4))
		Decor.Flower(model, cf * CFrame.new(x * 0.7, 0.2, -10), Color3.fromRGB(255, 107, 181))
	end
	Decor.Fence(model, cf * CFrame.new(0, 0.2, 14), 30)
	for i = 0, 4 do
		P.Part(
			model,
			"PathTile",
			Vector3.new(5.8, 0.15, 3),
			cf * CFrame.new(0, 0.28, -12 + i * 3),
			if i % 2 == 0 then V.TileA else V.TileB
		)
	end
	local color = Settings.PathColors[(index - 1) % #Settings.PathColors + 1]
	for _, x in ipairs({ -3.2, 3.2 }) do
		P.Part(
			model,
			"HomePathStrip",
			Vector3.new(0.22, 0.1, 13),
			cf * CFrame.new(x, 0.39, -6),
			color,
			nil,
			Enum.Material.Neon
		)
	end
	local sign = Decor.PlotSign(model, cf * CFrame.new(0, 0.2, 11))
	sign.Parent.MaxDistance = Guidance.SignDistance
	local toiletCF = cf * CFrame.new(0, 0.3, 0)
	local position = (toiletCF * CFrame.new(Guidance.SpawnOffset)).Position
	local spawnCF = CFrame.lookAt(position, Vector3.new(toiletCF.Position.X, position.Y, toiletCF.Position.Z))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlotSpawn"
	spawn.Size = Vector3.new(2, 0.2, 2)
	spawn.CFrame = spawnCF - Vector3.new(0, Guidance.SpawnOffset.Y - 0.1, 0)
	spawn.Anchored, spawn.CanCollide, spawn.CanTouch, spawn.CanQuery = true, false, false, false
	spawn.Transparency, spawn.Duration = 1, 0
	spawn.Neutral, spawn.AllowTeamChangeOnTouch = true, false
	spawn.Enabled = true
	spawn.Parent = model
	local displays = Instance.new("Folder")
	displays.Name, displays.Parent = "Displays", model
	return { Model = model, CFrame = toiletCF, Spawn = spawn, SpawnCFrame = spawnCF, Sign = sign, Displays = displays }
end
return Plot
