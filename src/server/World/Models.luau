local Config = game.ReplicatedStorage.Shared.Config
local Style = require(Config.World)
local Rarities = require(Config.Rarities)
local Models = {}
function Models.Part(parent, name, size, cf, color, shape)
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame, part.Color = name, size, cf, color
	part.Anchored, part.TopSurface, part.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end
function Models.Label(part, text, color, surface)
	local gui = Instance.new(if surface then "SurfaceGui" else "BillboardGui")
	if surface then
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(800, 400)
	else
		gui.Size = UDim2.fromOffset(220, 65)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.AlwaysOnTop = false
	end
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3, label.TextScaled = text, color or Color3.new(1, 1, 1), true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return label
end
function Models.Toilet(parent, cf, tier)
	local model = Instance.new("Model")
	model.Name = "Toilet"
	model.Parent = parent
	local color = Style.ToiletColors[tier]
	Models.Part(model, "Base", Vector3.new(3, 1, 3), cf * CFrame.new(0, 0.5, 0), color)
	local bowl = Models.Part(model, "Bowl", Vector3.new(4, 2, 4), cf * CFrame.new(0, 2, 0), color, Enum.PartType.Ball)
	Models.Part(model, "Water", Vector3.new(2.8, 0.15, 2.8), cf * CFrame.new(0, 2.9, 0), Color3.fromRGB(40, 195, 255))
	Models.Part(model, "Tank", Vector3.new(3.5, 3, 1), cf * CFrame.new(0, 3, 2), color)
	Models.Part(model, "Lid", Vector3.new(3.2, 4, 0.4), cf * CFrame.new(0, 4, 1.3), color, Enum.PartType.Ball)
	if tier >= 5 then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.Neon
			end
		end
	end
	if tier == 6 then
		for _, x in ipairs({ -1.5, 1.5 }) do
			Models.Part(model, "Horn", Vector3.new(0.5, 2, 0.5), cf * CFrame.new(x, 6, 2), Color3.fromRGB(255, 40, 40))
		end
	end
	model.PrimaryPart = bowl
	return model
end
function Models.Item(parent, cf, item)
	local model = Instance.new("Model")
	model.Name = item.Id
	model.Parent = parent
	local color = Style.ItemColors[item.Id]
	local body = Models.Part(
		model,
		"Body",
		Vector3.new(2, 1.6, 2),
		cf,
		color,
		if item.Id == "ToiletPaper" then Enum.PartType.Cylinder else Enum.PartType.Ball
	)
	model.PrimaryPart = body
	if string.find(item.Id, "Poop") then
		Models.Part(model, "Top", Vector3.new(1.3, 1.3, 1.3), cf * CFrame.new(0, 0.9, 0), color, Enum.PartType.Ball)
	elseif item.Id == "Fish" or item.Id == "SewerShark" then
		Models.Part(model, "Tail", Vector3.new(0.4, 1.8, 1.8), cf * CFrame.new(1.4, 0, 0), color)
	elseif item.Id == "Duck" or item.Id == "ToiletBaby" or item.Id == "Rat" then
		Models.Part(model, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 1, 0), color, Enum.PartType.Ball)
	elseif item.Id == "AlienToilet" then
		Models.Part(model, "Tank", Vector3.new(1.8, 2, 0.6), cf * CFrame.new(0, 1, 1), color)
	end
	if item.Id ~= "ToiletPaper" then
		for _, x in ipairs({ -0.4, 0.4 }) do
			Models.Part(
				model,
				"Eye",
				Vector3.new(0.35, 0.4, 0.2),
				cf * CFrame.new(x, 0.3, -0.9),
				Color3.new(1, 1, 1),
				Enum.PartType.Ball
			)
		end
	end
	if item.Id == "KingPoop" then
		Models.Part(
			model,
			"Crown",
			Vector3.new(1.5, 0.5, 1.5),
			cf * CFrame.new(0, 1.9, 0),
			Color3.fromRGB(255, 230, 40)
		)
	end
	Models.Label(body, item.Name .. "\n" .. item.Rarity .. " | 1/" .. item.Chance, Rarities[item.Rarity].Color)
	return model
end
return Models
