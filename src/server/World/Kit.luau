-- One render mesh per kit piece. Invisible boxes own collision and GUI anchors.
local Shared = game.ReplicatedStorage.Shared
local Loader = require(script.Parent.MeshLoader)
local Catalog = require(Shared.Config.MeshCatalog)
local Layout = require(Shared.Config.MapLayout)
local P = require(Shared.Visuals.Primitives)
local Models = require(script.Parent.Models)
local Kit = {}
function Kit.Proxy(parent, name, cf, size, collide)
	local part = P.Part(parent, name, size, cf, Color3.new(1, 1, 1))
	part.Transparency, part.CastShadow = 1, false
	part.CanCollide, part.CanQuery = collide == true, collide == true
	return part
end
function Kit.Place(parent, entry, origin)
	local cf = (origin or CFrame.new())
		* CFrame.new(entry.Position)
		* CFrame.Angles(math.rad(entry.Pitch or 0), math.rad(entry.Yaw or 0), 0)
	local model = Loader.Build(entry.Asset, parent, CFrame.new(), function()
		local fallback = Instance.new("Model")
		fallback.Name, fallback.Parent = entry.Asset, parent
		local size = Catalog[entry.Asset].Size
		local part = P.Part(fallback, entry.Asset, size, CFrame.new(0, size.Y / 2, 0), Color3.fromRGB(80, 158, 180))
		part.PivotOffset = CFrame.new(0, -size.Y / 2, 0)
		fallback.PrimaryPart = part
		return fallback
	end)
	if entry.Size then
		-- Architectural stretching follows canonical normalization; never stretch toilets/items.
		local part = model.PrimaryPart
		local rotation = part.CFrame - part.CFrame.Position
		part.Size = entry.Size
		part.CFrame = CFrame.new(0, entry.Size.Y / 2, 0) * rotation
		part.PivotOffset = part.CFrame:Inverse()
	elseif entry.Scale and entry.Scale ~= 1 then
		model:ScaleTo(entry.Scale)
	end
	local part = model.PrimaryPart
	if entry.Solid then
		if part:IsA("MeshPart") then
			part.TextureID = ""
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
		end
		part.Color = Color3.fromRGB(unpack(entry.Solid))
		model:SetAttribute("SolidFinish", true)
	elseif entry.Tint then
		part.Color = Color3.fromRGB(unpack(entry.Tint))
	end
	if entry.Neon then
		part.Material = Enum.Material.Neon
	end
	if entry.NoShadow then
		part.CastShadow = false
	end
	-- A capped skyline preserves depth; the walkable island and plots stream normally.
	if entry.Group == "Middle" or entry.Group == "Far" or entry.Group == "Skyline" or entry.Asset == "ToiletCastle" then
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		model:SetAttribute("ResortSkyline", true)
	end
	model:PivotTo(cf)
	if entry.IdleBob then
		part:SetAttribute("IdleBob", entry.IdleBob)
	end
	if entry.IdleOrbit then
		model:SetAttribute("IdleOrbit", true)
	end
	if entry.Sparkle then
		P.Particles(part, "CoinSparkles", part.Color, Layout.Ambience.CoinRate)
	end
	if entry.WalkStep then
		Kit.Proxy(model, "WalkStep", cf * CFrame.new(0, entry.Size.Y / 2, 0), entry.Size, true)
	end
	if entry.Pulse then
		local anchor = Kit.Proxy(
			model,
			"PortalPulse",
			cf * CFrame.new(0, Layout.Ambience.PortalLightHeight, 0),
			Vector3.new(0.1, 0.1, 0.1),
			false
		)
		P.Light(anchor, Color3.fromRGB(unpack(Layout.Ambience.PortalLightColor)), Layout.Ambience.PortalLightRange)
	end
	return model
end
function Kit.Label(parent, name, cf, size, text, color, billboard, distance)
	local anchor = Kit.Proxy(parent, name, cf, size, false)
	local label = Models.Label(anchor, text, color, not billboard)
	label.RichText = false
	label.Parent.MaxDistance = distance or 160
	if billboard then
		label.Parent:SetAttribute("AvoidHUD", true)
		label.Parent.Size = UDim2.fromScale(size.X, size.Y)
		label.Parent.StudsOffset = Vector3.new()
	end
	return label, anchor
end
function Kit.Beam(parent, cf, name, a, b, color, width, fade)
	local anchor = Kit.Proxy(parent, name .. "Anchor", cf, Vector3.new(0.1, 0.1, 0.1), false)
	local start, finish = Instance.new("Attachment"), Instance.new("Attachment")
	start.Position, finish.Position, start.Parent, finish.Parent = a, b, anchor, anchor
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, start, finish
	beam.FaceCamera, beam.LightEmission, beam.LightInfluence = true, 1, 0
	beam.Color, beam.Width0, beam.Width1 = ColorSequence.new(color), width, width * 0.6
	beam.Transparency, beam.Segments, beam.Parent = NumberSequence.new(fade or 0.25), 1, anchor
	return beam
end
function Kit.Chevron(parent, cf, scale)
	for _, sign in ipairs({ -1, 1 }) do
		Kit.Beam(
			parent,
			cf,
			"Wayfinding",
			Vector3.new(sign * scale, 0, scale),
			Vector3.new(0, 0, -scale),
			Color3.fromRGB(95, 255, 237),
			0.65,
			0.05
		)
	end
end
return Kit
