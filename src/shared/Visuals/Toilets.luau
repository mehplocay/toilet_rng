local P = require(script.Parent.Primitives)
local Config = game.ReplicatedStorage.Shared.Config
local Style, Visuals = require(Config.World), require(Config.Visuals)
local Toilets = {}
function Toilets.BuildPrimitive(parent, cf, tier, preview)
	local model = Instance.new("Model")
	model.Name = "Toilet"
	local color, material = Style.ToiletColors[tier], Visuals.ToiletMaterials[tier]
	local accent = if tier == 6 then Color3.fromRGB(255, 45, 60) else color:Lerp(Color3.new(1, 1, 1), 0.3)
	local function part(name, size, offset, shape, tint, mat)
		local result = P.Part(model, name, size, cf * offset, tint or color, shape, mat or material)
		if tier == 4 and mat == nil then
			result.Transparency = 0.24
		end
		return result
	end
	part("Foot", Vector3.new(2.9, 0.45, 3.5), CFrame.new(0, 0.25, 0), Enum.PartType.Ball)
	part("PedestalStem", Vector3.new(1.8, 1.75, 2), CFrame.new(0, 1.1, 0.25), Enum.PartType.Ball)
	local bowl = part("Bowl", Vector3.new(4.1, 1.8, 4.6), CFrame.new(0, 2.35, -0.15), Enum.PartType.Ball)
	model.PrimaryPart = bowl
	part("Tank", Vector3.new(3.6, 2.8, 1.2), CFrame.new(0, 3.2, 1.9))
	part("TankCap", Vector3.new(3.85, 0.32, 1.45), CFrame.new(0, 4.7, 1.9))
	part(
		"OpenLid",
		Vector3.new(3.75, 4.05, 0.4),
		CFrame.new(0, 4.85, 1.1) * CFrame.Angles(-0.12, 0, 0),
		Enum.PartType.Ball
	)
	part(
		"LidInset",
		Vector3.new(3.05, 3.3, 0.14),
		CFrame.new(0, 4.9, 0.83),
		Enum.PartType.Ball,
		color:Lerp(Color3.new(1, 1, 1), 0.13),
		if tier == 4 then Enum.Material.Ice else material
	)
	for _, x in ipairs({ -1.05, 1.05 }) do
		part("SeatHinge", Vector3.new(0.42, 0.42, 0.5), CFrame.new(x, 3.37, 1.55), nil, accent, Enum.Material.Metal)
	end
	part("HandleMount", Vector3.new(0.22, 0.45, 0.45), CFrame.new(-1.88, 4, 1.75), nil, accent, Enum.Material.Metal)
	part(
		"FlushHandle",
		Vector3.new(0.35, 0.23, 0.9),
		CFrame.new(-2.06, 4, 1.5),
		nil,
		Color3.fromRGB(221, 236, 255),
		Enum.Material.Metal
	)
	P.Ring(
		model,
		"Seat",
		cf * CFrame.new(0, 3.26, -0.15),
		1.66,
		1.94,
		0.36,
		accent,
		if tier >= 4 then Enum.Material.Neon else material
	)
	local water = part(
		"Water",
		Vector3.new(2.9, 0.12, 3.4),
		CFrame.new(0, 3.21, -0.15),
		Enum.PartType.Ball,
		if tier >= 5 then accent else Color3.fromRGB(67, 200, 255),
		if tier >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	)
	if not preview then
		water:SetAttribute("IdleBob", 0.06)
	end
	if tier == 2 then
		for i = 1, 5 do
			part(
				"MudStain",
				Vector3.new(0.65, 0.5 + i * 0.1, 0.14),
				CFrame.new((i % 3 - 1) * 1.15, 2.3 + (i % 2) * 0.4, -2.2),
				Enum.PartType.Ball,
				Color3.fromRGB(103, 65, 36),
				Enum.Material.SmoothPlastic
			)
		end
	elseif tier == 3 then
		part(
			"GoldBadge",
			Vector3.new(0.75, 0.75, 0.13),
			CFrame.new(0, 4.15, 1.23),
			Enum.PartType.Ball,
			Visuals.Palette.Gold,
			Enum.Material.Neon
		)
	elseif tier == 4 then
		for _, x in ipairs({ -1.4, 1.4 }) do
			part(
				"IceCrystal",
				Vector3.new(0.45, 1.2, 0.45),
				CFrame.new(x, 4.9, 0.7) * CFrame.Angles(0, 0, x * 0.18),
				"Wedge",
				Color3.fromRGB(196, 251, 255),
				Enum.Material.Ice
			)
		end
		if not preview then
			P.Particles(water, "DiamondSparkles", accent, Visuals.Budget.IdleRate)
		end
	elseif tier == 5 then
		for i = 1, 3 do
			local bubble = part(
				"ReactorBubble",
				Vector3.new(0.22, 0.22, 0.22),
				CFrame.new((i - 2) * 0.65, 3.6 + i * 0.15, -0.4),
				Enum.PartType.Ball,
				accent,
				Enum.Material.Neon
			)
			bubble.Transparency = 0.25
			if not preview then
				bubble:SetAttribute("IdleBob", 0.45 + i * 0.12)
			end
		end
		for _, x in ipairs({ -1.3, 0, 1.3 }) do
			part(
				"HazardStripe",
				Vector3.new(0.35, 1.2, 0.13),
				CFrame.new(x, 3.9, 1.22) * CFrame.Angles(0, 0, -0.4),
				nil,
				Color3.fromRGB(30, 46, 26),
				Enum.Material.SmoothPlastic
			)
		end
		if not preview then
			P.Particles(
				water,
				"Bubbles",
				accent,
				Visuals.Budget.IdleRate,
				{ Size = NumberSequence.new(0.22), Acceleration = Vector3.new(0, 2, 0) }
			)
		end
	elseif tier == 6 then
		for _, x in ipairs({ -1.4, 1.4 }) do
			part(
				"Horn",
				Vector3.new(0.55, 1.6, 0.65),
				CFrame.new(x, 6.7, 1.05) * CFrame.Angles(0, 0, -x * 0.25),
				"Wedge",
				accent,
				Enum.Material.Neon
			)
			part(
				"DemonEye",
				Vector3.new(0.6, 0.3, 0.16),
				CFrame.new(x * 0.48, 5.25, 0.71) * CFrame.Angles(0, 0, x * 0.12),
				Enum.PartType.Ball,
				accent,
				Enum.Material.Neon
			)
		end
		if not preview then
			P.Particles(water, "Embers", accent, Visuals.Budget.IdleRate, { Acceleration = Vector3.new(0, 2, 0) })
		end
	elseif tier == 7 then
		local orbit = Instance.new("Model")
		orbit.Name = "StarOrbit"
		for i = 1, 3 do
			local a = i * math.pi * 2 / 3
			local starCF = cf * CFrame.new(math.sin(a) * 2.7, 4.6, math.cos(a) * 2.7)
			local star =
				P.Part(orbit, "Star", Vector3.new(0.2, 0.7, 0.2), starCF, Visuals.Palette.Cyan, nil, Enum.Material.Neon)
			P.Part(
				orbit,
				"StarCross",
				Vector3.new(0.7, 0.2, 0.2),
				starCF,
				Visuals.Palette.Cyan,
				nil,
				Enum.Material.Neon
			)
			if not preview then
				P.Particles(star, "StarDust", accent, 2, { LockedToPart = true })
			end
		end
		orbit.WorldPivot = cf * CFrame.new(0, 4.6, 0)
		if not preview then
			orbit:SetAttribute("IdleOrbit", true)
		end
		orbit.Parent = model
	end
	if tier >= 4 and not preview then
		P.Light(water, accent, 8)
	end
	model.Parent = parent
	return model
end
function Toilets.Build(parent, cf, tier, preview)
	local template =
		require(script.Parent.TemplateLoader).Clone(require(Config.WorldModels).ToiletNames[tier], parent, cf)
	if template then
		template.Name = "Toilet"
		if not preview then
			require(script.Parent.TemplateAccents).Apply(template)
		end
		return template
	end
	return Toilets.BuildPrimitive(parent, cf, tier, preview)
end

return Toilets
