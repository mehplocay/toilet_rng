local P = require(script.Parent.Primitives)
local Config = game.ReplicatedStorage.Shared.Config
local Style, Visuals, Rarities = require(Config.World), require(Config.Visuals), require(Config.Rarities)
local Items = {}
function Items.BuildPrimitive(parent, cf, item, preview)
	local model = Instance.new("Model")
	model.Name = item.Id
	local color = Style.ItemColors[item.Id]
	local material = if string.find(item.Id, "Poop") and item.Id ~= "Poop"
		then Enum.Material.Metal
		else Enum.Material.SmoothPlastic
	local function part(name, size, offset, shape, tint, mat)
		return P.Part(model, name, size, cf * offset, tint or color, shape, mat or material)
	end
	local body
	if string.find(item.Id, "Poop") then
		body = part("SwirlBase", Vector3.new(2.6, 1.3, 2.1), CFrame.new(), Enum.PartType.Ball)
		part("SwirlMiddle", Vector3.new(1.9, 1.2, 1.6), CFrame.new(0.1, 0.75, 0), Enum.PartType.Ball)
		part(
			"SwirlTip",
			Vector3.new(1, 1.1, 1),
			CFrame.new(0.25, 1.45, 0) * CFrame.Angles(0, 0, -0.3),
			Enum.PartType.Ball
		)
		P.Eyes(model, cf * CFrame.new(0, 0.55, -0.88), 0.45, 1)
		part(
			"HappyMouth",
			Vector3.new(0.6, 0.3, 0.12),
			CFrame.new(0, -0.05, -1.04),
			Enum.PartType.Ball,
			Color3.fromRGB(51, 23, 27)
		)
		if item.Id == "KingPoop" then
			P.Crown(model, cf * CFrame.new(0.15, 2.12, 0), 1)
		end
	elseif item.Id == "ToiletPaper" then
		body = P.Cylinder(model, "PaperRoll", 1, 1.7, cf, color)
		P.Cylinder(model, "CardboardCore", 0.32, 0.04, cf * CFrame.new(0, 0.87, 0), Color3.fromRGB(137, 102, 75))
		P.Cylinder(model, "CoreHole", 0.2, 0.05, cf * CFrame.new(0, 0.9, 0), Color3.fromRGB(41, 31, 35))
		part("LooseSheet", Vector3.new(1.7, 1.6, 0.1), CFrame.new(0, -0.45, -0.98) * CFrame.Angles(-0.12, 0, 0))
		for i = 1, 3 do
			part(
				"Perforation",
				Vector3.new(0.22, 0.03, 0.02),
				CFrame.new((i - 2) * 0.45, -0.5, -1.05),
				nil,
				Color3.fromRGB(213, 222, 233)
			)
		end
	elseif item.Id == "Rat" then
		body = part("Body", Vector3.new(2.4, 1.3, 1.8), CFrame.new(), Enum.PartType.Ball)
		part("Head", Vector3.new(1.65, 1.4, 1.3), CFrame.new(0, 0.65, -0.55), Enum.PartType.Ball)
		for _, x in ipairs({ -0.65, 0.65 }) do
			part("Ear", Vector3.new(0.8, 0.85, 0.32), CFrame.new(x, 1.28, -0.42), Enum.PartType.Ball)
			part(
				"InnerEar",
				Vector3.new(0.5, 0.55, 0.12),
				CFrame.new(x, 1.28, -0.63),
				Enum.PartType.Ball,
				Color3.fromRGB(255, 153, 181)
			)
			part("Paw", Vector3.new(0.45, 0.3, 0.65), CFrame.new(x, -0.6, -0.4), Enum.PartType.Ball)
		end
		P.Eyes(model, cf * CFrame.new(0, 0.85, -1.13), 0.35, 0.75)
		part(
			"PinkNose",
			Vector3.new(0.36, 0.3, 0.3),
			CFrame.new(0, 0.5, -1.28),
			Enum.PartType.Ball,
			Color3.fromRGB(255, 132, 167)
		)
		part(
			"Tail",
			Vector3.new(0.16, 0.16, 1.8),
			CFrame.new(0.55, -0.3, 1.45) * CFrame.Angles(0, 0.5, 0),
			Enum.PartType.Ball,
			Color3.fromRGB(247, 146, 178)
		)
	elseif item.Id == "Fish" or item.Id == "SewerShark" then
		local shark = item.Id == "SewerShark"
		body = part("Body", Vector3.new(2.2, 1.5, 3.1), CFrame.new(), Enum.PartType.Ball)
		part(
			"Belly",
			Vector3.new(1.7, 0.65, 2.5),
			CFrame.new(0, -0.45, -0.15),
			Enum.PartType.Ball,
			Color3.fromRGB(201, 233, 255)
		)
		part("TailFin", Vector3.new(0.3, 1.9, 1.2), CFrame.new(0, 0, 1.75) * CFrame.Angles(0, math.pi / 2, 0), "Wedge")
		part("DorsalFin", Vector3.new(0.28, if shark then 1.3 else 0.7, 1.1), CFrame.new(0, 1, 0.3), "Wedge")
		for _, x in ipairs({ -1, 1 }) do
			part(
				"SideFin",
				Vector3.new(0.25, 0.65, 1.1),
				CFrame.new(x * 1.15, -0.2, 0) * CFrame.Angles(0, 0, x * 0.9),
				"Wedge"
			)
		end
		P.Eyes(model, cf * CFrame.new(0, 0.35, -1.34), 0.55, 0.8)
		part(
			"Smile",
			Vector3.new(0.9, 0.25, 0.16),
			CFrame.new(0, -0.25, -1.52),
			Enum.PartType.Ball,
			Color3.fromRGB(39, 56, 91)
		)
		if shark then
			for i = 1, 3 do
				part(
					"Tooth",
					Vector3.new(0.15, 0.18, 0.15),
					CFrame.new((i - 2) * 0.24, -0.26, -1.63),
					"Wedge",
					Color3.new(1, 1, 1)
				)
			end
		end
	elseif item.Id == "Duck" then
		body = part("RubberBody", Vector3.new(2.5, 1.5, 2.4), CFrame.new(), Enum.PartType.Ball)
		part("Head", Vector3.new(1.65, 1.65, 1.65), CFrame.new(0, 1.05, -0.55), Enum.PartType.Ball)
		part(
			"Beak",
			Vector3.new(1.05, 0.36, 0.8),
			CFrame.new(0, 0.88, -1.5),
			Enum.PartType.Ball,
			Color3.fromRGB(255, 131, 31)
		)
		P.Eyes(model, cf * CFrame.new(0, 1.3, -1.23), 0.45, 0.7)
		for _, x in ipairs({ -1, 1 }) do
			part(
				"Wing",
				Vector3.new(0.35, 0.8, 1.6),
				CFrame.new(x * 1.15, 0.15, 0.2),
				Enum.PartType.Ball,
				Color3.fromRGB(255, 184, 19)
			)
		end
		part("Tail", Vector3.new(0.8, 0.6, 0.9), CFrame.new(0, 0.3, 1.13) * CFrame.Angles(-0.4, 0, 0), "Wedge")
	elseif item.Id == "ToiletBaby" then
		body = part("Body", Vector3.new(1.5, 1.3, 1.2), CFrame.new(), Enum.PartType.Ball)
		part("Diaper", Vector3.new(1.6, 0.7, 1.3), CFrame.new(0, -0.4, 0), Enum.PartType.Ball, Color3.new(1, 1, 1))
		part("Head", Vector3.new(1.65, 1.65, 1.5), CFrame.new(0, 1.2, 0), Enum.PartType.Ball)
		P.Eyes(model, cf * CFrame.new(0, 1.35, -0.7), 0.35, 0.75)
		part(
			"Pacifier",
			Vector3.new(0.5, 0.42, 0.25),
			CFrame.new(0, 0.9, -0.83),
			Enum.PartType.Ball,
			Visuals.Palette.Cyan
		)
		part(
			"HairCurl",
			Vector3.new(0.3, 0.35, 0.3),
			CFrame.new(0.18, 2, 0),
			Enum.PartType.Ball,
			Color3.fromRGB(135, 80, 44)
		)
		for _, x in ipairs({ -1, 1 }) do
			part(
				"Arm",
				Vector3.new(0.55, 0.9, 0.6),
				CFrame.new(x * 0.85, 0.1, -0.05) * CFrame.Angles(0, 0, x * 0.45),
				Enum.PartType.Ball
			)
			part("Foot", Vector3.new(0.6, 0.55, 0.9), CFrame.new(x * 0.65, -0.6, -0.45), Enum.PartType.Ball)
		end
	elseif item.Id == "AlienToilet" then
		body = part("AlienBowl", Vector3.new(2.4, 1.2, 2.3), CFrame.new(), Enum.PartType.Ball)
		part("Foot", Vector3.new(1.2, 0.7, 1.2), CFrame.new(0, -0.7, 0), Enum.PartType.Ball)
		part("AlienTank", Vector3.new(2, 1.7, 0.6), CFrame.new(0, 0.7, 0.85))
		part("AlienLid", Vector3.new(2, 2.1, 0.4), CFrame.new(0, 1.3, 0.55), Enum.PartType.Ball)
		P.Eyes(model, cf * CFrame.new(0, 1.6, 0.25), 0.4, 0.9)
		for _, x in ipairs({ -0.7, 0.7 }) do
			part("Antenna", Vector3.new(0.12, 0.8, 0.12), CFrame.new(x, 2.45, 0.55) * CFrame.Angles(0, 0, -x * 0.4))
			part(
				"AntennaTip",
				Vector3.new(0.35, 0.35, 0.35),
				CFrame.new(x * 1.3, 2.9, 0.55),
				Enum.PartType.Ball,
				Visuals.Palette.Cyan,
				Enum.Material.Neon
			)
		end
		P.Ring(
			model,
			"UFORim",
			cf * CFrame.new(0, 0.4, 0),
			1.15,
			1.15,
			0.16,
			Visuals.Palette.Cyan,
			Enum.Material.Neon,
			8
		)
	else
		body = part(
			"MysteryBody",
			Vector3.new(1.8, 1.8, 1.8),
			CFrame.Angles(0, 0, math.pi / 4),
			nil,
			Color3.fromRGB(24, 15, 43)
		)
		P.Ring(model, "MysteryHalo", cf * CFrame.new(0, 0.1, 0), 1.6, 1.6, 0.14, color, Enum.Material.Neon, 8)
		P.Eyes(model, cf * CFrame.new(0, 0.3, -0.97), 0.35, 0.8)
		part(
			"QuestionStem",
			Vector3.new(0.22, 0.7, 0.22),
			CFrame.new(0, 1.75, 0),
			nil,
			Visuals.Palette.Cyan,
			Enum.Material.Neon
		)
		part(
			"QuestionHook",
			Vector3.new(0.7, 0.22, 0.22),
			CFrame.new(-0.22, 2.08, 0),
			nil,
			Visuals.Palette.Cyan,
			Enum.Material.Neon
		)
		part(
			"QuestionDot",
			Vector3.new(0.25, 0.25, 0.25),
			CFrame.new(0, 1.15, 0),
			Enum.PartType.Ball,
			Visuals.Palette.Cyan,
			Enum.Material.Neon
		)
	end
	if not body then
		body = part("Placeholder", Vector3.new(2, 2, 2), CFrame.new(), Enum.PartType.Ball)
		P.Eyes(model, cf * CFrame.new(0, 0.3, -0.9), 0.3, 0.7)
	end
	model.PrimaryPart = body
	if not preview then
		local rarity = Rarities[item.Rarity]
		local aura = if item.Rarity == "Secret" then Visuals.Palette.Cyan else rarity.Color
		P.Ring(model, "RarityAura", cf * CFrame.new(0, -0.85, 0), 1.45, 1.45, 0.09, aura, Enum.Material.Neon, 8)
		if rarity.Order >= 5 then
			P.Particles(body, "RareAura", aura, Visuals.Budget.IdleRate)
		end
	end
	model.Parent = parent
	return model
end
function Items.Build(parent, cf, item, preview)
	local template = require(script.Parent.TemplateLoader).Clone(
		require(Config.WorldModels).ItemNames[item.Id] or item.Id,
		parent,
		cf * CFrame.new(0, -0.8, 0)
	)
	if template then
		template.Name = item.Id
		if not preview then
			require(script.Parent.TemplateAccents).Apply(template)
		end
		return template
	end
	return Items.BuildPrimitive(parent, cf, item, preview)
end

return Items
