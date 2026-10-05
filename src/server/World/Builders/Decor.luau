local P = require(game.ReplicatedStorage.Shared.Visuals.Primitives)
local Models = require(script.Parent.Parent.Models)
local V = require(game.ReplicatedStorage.Shared.Config.Visuals).Palette
local Settings = require(game.ReplicatedStorage.Shared.Config.WorldModels)
local Catalog = require(game.ReplicatedStorage.Shared.Config.MeshCatalog)
local Loader = require(script.Parent.Parent.MeshLoader)
local Decor = {}
function Decor.Tree(parent, cf, small)
	local s = if small then 0.65 else 1
	P.Cylinder(parent, "PalmTrunk", 0.55 * s, 12 * s, cf * CFrame.new(0, 6 * s, 0) * CFrame.Angles(0, 0, -0.08), V.Wood)
	for i = 1, 7 do
		local angle = i * math.pi * 2 / 7
		P.Part(
			parent,
			"PalmFrond",
			Vector3.new(2.4, 0.6, 6.6) * s,
			cf
				* CFrame.new(0.5 * s, 12 * s, 0)
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(0, -0.5 * s, 2.5 * s)
				* CFrame.Angles(0.22, 0, 0),
			if i % 2 == 0 then V.LeafLight else V.Leaf,
			"Wedge"
		)
	end
	P.Ball(parent, "PalmCrown", Vector3.new(1.7, 1.4, 1.7) * s, cf * CFrame.new(0.5 * s, 11.8 * s, 0), V.Leaf)
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

-- Keep the original builders as offline/permission-safe fallbacks.
local function collision(model, name, cf, scale)
	local box = Settings.BoxColliders[name]
	if box then
		local part = P.Part(
			model,
			"WalkingCollision",
			box.Size * (scale or 1),
			cf * CFrame.new(box.Center * (scale or 1)),
			V.Navy
		)
		part.Transparency, part.CanCollide, part.CastShadow = 1, true, false
	end
end

local function prop(name, parent, cf, fallback, scale)
	local model = Loader.Build(name, parent, cf, function()
		local model = Instance.new("Model")
		model.Name, model.WorldPivot = name, cf
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		fallback(model)
		model.Parent = parent
		return model
	end, scale)
	collision(model, name, cf, scale)
	return model
end

for method, asset in pairs({
	Tree = "PalmTree",
	Bush = "RoundBush",
	Flower = "FlowerPack",
	Bench = "Bench",
	Lamp = "LampPost",
}) do
	local primitive = Decor[method]
	Decor[method] = function(parent, cf, option)
		local scale = (Settings.PropScales[asset] or 1) * (if method == "Tree" and option then 0.65 else 1)
		local model = prop(asset, parent, cf, function(container)
			primitive(container, cf, option)
		end, scale)
		if method == "Lamp" and not model:GetAttribute("MeshFallback") then
			local glow = P.Ball(
				model,
				"LampGlow",
				Vector3.new(0.7, 1, 0.7),
				cf * CFrame.new(0, 4.78 * scale, 0),
				V.Gold,
				Enum.Material.Neon
			)
			P.Light(glow, V.Gold, 10)
		end
		return model
	end
end

local fence = Decor.Fence
function Decor.Fence(parent, cf, length)
	if Loader.Status("WoodenFence") ~= "Ready" then
		return prop("WoodenFence", parent, cf, function(container)
			fence(container, cf, length)
		end)
	end
	local count = math.ceil(length / Catalog.WoodenFence.Size.X)
	for i = 1, count do
		local section = cf * CFrame.new((i - 0.5) * length / count - length / 2, 0, 0)
		prop("WoodenFence", parent, section, function(container)
			fence(container, section, length / count)
		end, length / count / Catalog.WoodenFence.Size.X)
	end
end

function Decor.PlotSign(parent, cf)
	local label
	local scale = 4.5
	local model = prop("PlotSignboard", parent, cf, function(container)
		for _, x in ipairs({ -7, 7 }) do
			P.Part(container, "SignPost", Vector3.new(0.6, 10, 0.6), cf * CFrame.new(x, 5, 0), V.Wood)
		end
		label = Decor.Sign(container, cf * CFrame.new(0, 9.8, 0), 15.6, 5.2, "Available Plot", Color3.new(1, 1, 1))
	end, scale)
	if not label then
		local face = P.Part(
			model,
			"SignTextFace",
			Vector3.new(3.38, 1.12, 0.025) * scale,
			cf * CFrame.new(0, 2.17 * scale, -0.34 * scale),
			V.Navy
		)
		label = Models.Label(face, "Available Plot", Color3.new(1, 1, 1), true)
	end
	return label
end

function Decor.Pedestal(parent, cf, slot, text, color)
	local model = prop("DisplayPedestal", parent, cf, function(container)
		P.Part(container, "PedestalBody", Vector3.new(3.9, 1.8, 3.9), cf * CFrame.new(0, 0.9, 0), V.Navy)
	end, Settings.PropScales.DisplayPedestal)
	model.Name = "Slot" .. slot
	model:SetAttribute("DisplaySlot", slot)
	local face = P.Part(model, "DisplayLabel", Vector3.new(3.2, 0.85, 0.08), cf * CFrame.new(0, 0.9, -1.98), V.Navy)
	Models.Label(face, text, color, true)
	P.Ring(model, "PedestalGlow", cf * CFrame.new(0, 1.92, 0), 1.55, 1.55, 0.1, color, Enum.Material.Neon, 8)
	return model
end

function Decor.Cloud(parent, cf, scale)
	local model = prop("CloudPuffs", parent, cf, function(container)
		for i = -1, 1 do
			P.Ball(
				container,
				"CloudPuff",
				Vector3.new(2.5, 1.5 - math.abs(i) * 0.35, 1.5) * scale,
				cf * CFrame.new(i * scale, scale * 0.65, 0),
				Color3.fromRGB(242, 252, 255)
			)
		end
	end, scale)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CastShadow = false
		end
	end
	return model
end

function Decor.Foliage(parent, cf, scale)
	return prop("ForegroundFoliage", parent, cf, function(container)
		for i = 1, 5 do
			P.Part(
				container,
				"SpearLeaf",
				Vector3.new(0.7, 2.9, 0.32) * scale,
				cf * CFrame.Angles(0, i * 1.3, 0) * CFrame.new(0, scale, scale * 0.7) * CFrame.Angles(0.65, 0, 0),
				if i % 2 == 0 then V.LeafLight else V.Leaf,
				"Wedge"
			)
		end
	end, scale)
end

function Decor.Rocks(parent, cf, scale)
	return prop("RocksCrystals", parent, cf, function(container)
		for i = -1, 1 do
			P.Ball(
				container,
				"CoastalRock",
				Vector3.new(1.5, 1.2, 1.5) * scale,
				cf * CFrame.new(i * scale, 0.4 * scale, 0),
				Color3.fromRGB(100, 132, 174)
			)
		end
		for i = 1, 2 do
			P.Part(
				container,
				"Crystal",
				Vector3.new(0.65, 2.6, 0.65) * scale,
				cf * CFrame.new((i - 1.5) * scale, 1.2 * scale, 0.2 * scale) * CFrame.Angles(0, 0, i * 0.18),
				if i == 1 then V.Cyan else Color3.fromRGB(171, 105, 255),
				"Wedge",
				Enum.Material.Neon
			)
		end
	end, scale)
end

function Decor.Aura(parent, cf, radius, color)
	P.Ring(parent, "AuraRing", cf, radius, radius, 0.12, color, Enum.Material.Neon, 16)
	local light = P.Part(parent, "AuraSource", Vector3.new(0.2, 0.2, 0.2), cf, color)
	light.Transparency = 1
	P.Light(light, color, radius * 2)
	P.Particles(light, "AuraSparkles", color, 3, { SpreadAngle = Vector2.new(180, 180), Speed = NumberRange.new(1, 2) })
end

function Decor.Trophy(parent, cf)
	local model = Loader.Build("GoldenTrophy", parent, cf, function()
		local model = require(game.ReplicatedStorage.Shared.Visuals.Toilets).BuildPrimitive(parent, cf, 3, true)
		P.Crown(model, cf * CFrame.new(0, 7.5, 1), 1.2)
		model.Name = "GoldenTrophy"
		return model
	end)
	collision(model, "GoldenTrophy", cf)
	return model
end

function Decor.Portal(parent, cf, name, color)
	local scale = 1.8
	local model = prop("PortalGate", parent, cf, function(container)
		for _, x in ipairs({ -4.1, 4.1 }) do
			P.Part(container, "PortalPillar", Vector3.new(0.8, 7.2, 1), cf * CFrame.new(x, 3.6, 0), V.Navy)
			P.Part(
				container,
				"PortalEdge",
				Vector3.new(0.18, 7.3, 1.1),
				cf * CFrame.new(x, 3.8, 0),
				color,
				nil,
				Enum.Material.Neon
			)
		end
		for i = 0, 7 do
			local a = i * math.pi / 7
			P.Part(
				container,
				"PortalArch",
				Vector3.new(1.9, 0.55, 1),
				cf * CFrame.new(math.cos(a) * 4.1, 7.1 + math.sin(a) * 3.4, 0) * CFrame.Angles(0, 0, a + math.pi / 2),
				color,
				nil,
				Enum.Material.Neon
			)
		end
	end, scale)
	if not model:GetAttribute("MeshFallback") then
		for i = 1, #Settings.PortalTrim - 1 do
			local a, b = Settings.PortalTrim[i] * scale, Settings.PortalTrim[i + 1] * scale
			local midpoint = cf * CFrame.new((a + b) * 0.5)
			local target = cf * CFrame.new(b)
			P.Part(
				model,
				"PortalTrimGlow",
				Vector3.new(0.18, 0.18, (b - a).Magnitude + 0.08),
				CFrame.lookAt(midpoint.Position, target.Position),
				color,
				nil,
				Enum.Material.Neon
			)
		end
	end
	-- Opaque recess gives the inactive entrance depth without a transparent fill plane.
	P.Part(model, "PortalRecess", Vector3.new(7.3, 7.7, 0.25), cf * CFrame.new(0, 4, 0.5), V.Navy)
	local label =
		Decor.Sign(model, cf * CFrame.new(0, 4.8, -0.15), 6.5, 2.8, string.upper(name) .. "\nComing soon", color)
	label.Parent.MaxDistance = 120
	Decor.Aura(model, cf * CFrame.new(0, 0.1, 0), 5.7, color)
	return model
end

return Decor
