local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local V = require(game.ReplicatedStorage.Shared.Config.Visuals).Palette
local Decor = require(script.Parent.Decor)
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
	for _, x in ipairs({ -10, 10 }) do
		P.Part(model, "SignPost", Vector3.new(0.7, 8, 0.7), cf * CFrame.new(x, 4, 11), V.Wood, nil, Enum.Material.Wood)
	end
	local sign = Decor.Sign(model, cf * CFrame.new(0, 8, 11), 20, 3.3, "Available Plot", Color3.new(1, 1, 1))
	local displays = Instance.new("Folder")
	displays.Name, displays.Parent = "Displays", model
	return { Model = model, CFrame = cf * CFrame.new(0, 0.3, 0), Sign = sign, Displays = displays }
end
return Plot
