local Config = game.ReplicatedStorage.Shared.Config
local Visuals = require(Config.Visuals)
local Assets = require(Config.Assets)
local P = {}
function P.Part(parent, name, size, cf, color, shape, material)
	local part = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
	part.Name, part.Size, part.CFrame, part.Color = name, size, cf, color
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Material = material or Enum.Material.SmoothPlastic
	part.CastShadow = size.Magnitude > 2
	if shape and shape ~= "Wedge" then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end
function P.Ball(parent, name, size, cf, color, material)
	return P.Part(parent, name, size, cf, color, Enum.PartType.Ball, material)
end
function P.Cylinder(parent, name, radius, height, cf, color, material)
	return P.Part(
		parent,
		name,
		Vector3.new(height, radius * 2, radius * 2),
		cf * CFrame.Angles(0, 0, math.pi / 2),
		color,
		Enum.PartType.Cylinder,
		material
	)
end
function P.Ring(parent, name, cf, rx, rz, thickness, color, material, segments)
	local parts = {}
	local count = segments or 12
	for i = 1, count do
		local angle = (i - 0.5) * math.pi * 2 / count
		local tangent = Vector3.new(rx * math.cos(angle), 0, -rz * math.sin(angle)).Unit
		local center = cf * CFrame.new(rx * math.sin(angle), 0, rz * math.cos(angle))
		local frame = CFrame.lookAt(center.Position, center.Position + cf:VectorToWorldSpace(tangent))
		local length = 2 * math.pi / count * math.sqrt((rx * math.cos(angle)) ^ 2 + (rz * math.sin(angle)) ^ 2)
			+ thickness * 0.35
		table.insert(
			parts,
			P.Part(parent, name, Vector3.new(thickness, thickness, length), frame, color, nil, material)
		)
	end
	return parts
end
function P.Eyes(parent, cf, spread, scale)
	for _, x in ipairs({ -spread, spread }) do
		P.Ball(parent, "EyeWhite", Vector3.new(0.52, 0.64, 0.24) * scale, cf * CFrame.new(x, 0, 0), Color3.new(1, 1, 1))
		P.Ball(
			parent,
			"Pupil",
			Vector3.new(0.25, 0.35, 0.15) * scale,
			cf * CFrame.new(x, -0.015, -0.13 * scale),
			Color3.fromRGB(20, 22, 37)
		)
		P.Ball(
			parent,
			"EyeShine",
			Vector3.new(0.08, 0.1, 0.05) * scale,
			cf * CFrame.new(x - 0.045 * scale, 0.08 * scale, -0.21 * scale),
			Color3.new(1, 1, 1)
		)
	end
end
function P.Crown(parent, cf, scale)
	local gold = Visuals.Palette.Gold
	P.Cylinder(parent, "CrownBand", 0.85 * scale, 0.35 * scale, cf, gold, Enum.Material.Metal)
	for i = 1, 5 do
		local a = i * math.pi * 2 / 5
		local point = cf * CFrame.new(math.sin(a) * 0.72 * scale, 0.55 * scale, math.cos(a) * 0.72 * scale)
		P.Part(parent, "CrownPoint", Vector3.new(0.3, 0.9, 0.4) * scale, point, gold, "Wedge", Enum.Material.Metal)
		P.Ball(
			parent,
			"CrownJewel",
			Vector3.new(0.22, 0.22, 0.22) * scale,
			point * CFrame.new(0, 0.45 * scale, 0),
			Color3.fromRGB(255, 90, 161),
			Enum.Material.Neon
		)
	end
end
function P.Particles(part, name, color, rate, options)
	options = options or {}
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name, emitter.Texture = name, Assets.Textures.Sparkle
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.LightEmission, emitter.LightInfluence = 0.8, 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.16),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	for key, value in pairs(options) do
		emitter[key] = value
	end
	if rate > 0 then
		emitter.Enabled = false
		emitter:SetAttribute("VisualIdle", true)
	end
	emitter.Parent = part
	return emitter
end
function P.Light(part, color, range)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = color, range or 9, 0.7, false
	light:SetAttribute("VisualIdle", true)
	light.Enabled = false
	light.Parent = part
	return light
end
function P.Count(root)
	local count = 0
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("BasePart") then
			count += 1
		end
	end
	return count
end
return P
