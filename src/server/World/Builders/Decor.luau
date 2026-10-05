local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Models = require(script.Parent.Parent.Models)
local V = require(game.ReplicatedStorage.Shared.Config.Visuals).Palette
local Decor = {}
function Decor.Tree(parent, cf, small)
	local s = if small then 0.65 else 1
	P.Cylinder(parent, "TreeTrunk", 0.7 * s, 7 * s, cf * CFrame.new(0, 3.5 * s, 0), V.Wood)
	for i, offset in ipairs({
		Vector3.new(0, 8, 0),
		Vector3.new(-2.1, 7, 0),
		Vector3.new(2.1, 7.4, 0.5),
		Vector3.new(0, 7, -2),
	}) do
		P.Ball(
			parent,
			"TreeCanopy",
			Vector3.new(5.8, 5.2, 5.6) * s,
			cf + cf:VectorToWorldSpace(offset * s),
			if i % 2 == 0 then V.LeafLight else V.Leaf
		)
	end
end
function Decor.Bush(parent, cf)
	for i = -1, 1 do
		P.Ball(
			parent,
			"Bush",
			Vector3.new(2.4, 2.5, 2.4),
			cf * CFrame.new(i * 1.1, 1.1, 0),
			if i == 0 then V.LeafLight else V.Leaf
		)
	end
end
function Decor.Flower(parent, cf, color)
	P.Cylinder(parent, "Stem", 0.08, 0.8, cf * CFrame.new(0, 0.5, 0), V.Leaf)
	for i = 1, 4 do
		local a = i * math.pi / 2
		P.Ball(
			parent,
			"Petal",
			Vector3.new(0.55, 0.25, 0.55),
			cf * CFrame.new(math.sin(a) * 0.22, 0.95, math.cos(a) * 0.22),
			color
		)
	end
	P.Ball(parent, "FlowerCenter", Vector3.new(0.27, 0.27, 0.27), cf * CFrame.new(0, 1.04, 0), V.Gold)
end
function Decor.Sign(parent, cf, width, height, text, color)
	P.Part(parent, "WoodenFrame", Vector3.new(width + 0.7, height + 0.7, 0.65), cf, V.Wood, nil, Enum.Material.Wood)
	local board = P.Part(parent, "SignBoard", Vector3.new(width, height, 0.15), cf * CFrame.new(0, 0, -0.4), V.Navy)
	for _, x in ipairs({ -width / 2 + 0.5, width / 2 - 0.5 }) do
		P.Ball(
			parent,
			"SignBolt",
			Vector3.new(0.2, 0.2, 0.12),
			cf * CFrame.new(x, height / 2 - 0.3, -0.51),
			V.Gold,
			Enum.Material.Metal
		)
	end
	return Models.Label(board, text, color, true)
end
function Decor.Bench(parent, cf)
	for _, x in ipairs({ -2.2, 2.2 }) do
		P.Part(parent, "BenchLeg", Vector3.new(0.5, 1.6, 1.5), cf * CFrame.new(x, 0.8, 0), V.Navy)
	end
	for i = 1, 3 do
		P.Part(
			parent,
			"SeatSlat",
			Vector3.new(6, 0.25, 0.42),
			cf * CFrame.new(0, 1.7, (i - 2) * 0.5),
			V.Wood,
			nil,
			Enum.Material.Wood
		)
	end
	P.Part(
		parent,
		"Backrest",
		Vector3.new(6, 1.25, 0.3),
		cf * CFrame.new(0, 2.55, 0.7) * CFrame.Angles(-0.1, 0, 0),
		V.Wood,
		nil,
		Enum.Material.Wood
	)
end
function Decor.Lamp(parent, cf)
	P.Cylinder(parent, "LampBase", 0.8, 0.35, cf * CFrame.new(0, 0.2, 0), V.Navy)
	P.Cylinder(parent, "LampPost", 0.18, 7, cf * CFrame.new(0, 3.5, 0), V.Navy)
	local lamp = P.Ball(
		parent,
		"LampGlow",
		Vector3.new(1.5, 1.7, 1.5),
		cf * CFrame.new(0, 7.3, 0),
		Color3.fromRGB(255, 230, 143),
		Enum.Material.Neon
	)
	P.Cylinder(parent, "LampCap", 1, 0.25, cf * CFrame.new(0, 8.1, 0), V.Navy)
	P.Light(lamp, Color3.fromRGB(255, 219, 151), 10)
end
function Decor.Fence(parent, cf, length)
	P.Part(
		parent,
		"FenceRail",
		Vector3.new(length, 0.3, 0.35),
		cf * CFrame.new(0, 1.5, 0),
		Color3.fromRGB(242, 243, 255)
	)
	local steps = math.floor(length / 3)
	for i = 0, steps do
		P.Part(
			parent,
			"FencePicket",
			Vector3.new(0.4, 2.2, 0.4),
			cf * CFrame.new((i / steps - 0.5) * length, 1.1, 0),
			Color3.fromRGB(242, 243, 255)
		)
	end
end
return Decor
