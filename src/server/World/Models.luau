local Shared = game.ReplicatedStorage.Shared
local P = require(Shared.Visuals.Primitives)
local Visuals = require(Shared.Config.Visuals)
local Rarities = require(Shared.Config.Rarities)
local Loader = require(script.Parent.MeshLoader)
local Placement = require(Shared.Config.WorldModels)
local Models = { Part = P.Part }
function Models.Toilet(parent, cf, tier)
	local model = Loader.Build(Placement.ToiletNames[tier], parent, cf, function()
		return require(Shared.Visuals.Toilets).Build(parent, cf, tier)
	end)
	model.Name = "Toilet"
	return model
end
function Models.Label(part, text, color, surface)
	local gui = Instance.new(if surface then "SurfaceGui" else "BillboardGui")
	if surface then
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(900, math.max(100, math.floor(900 * part.Size.Y / part.Size.X)))
		gui.LightInfluence = 0
		gui.MaxDistance = 150
	else
		gui.Size = UDim2.fromOffset(190, 60)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.MaxDistance = 65
		gui.AlwaysOnTop = false
	end
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(0.94, 0.88), 1
	label.Position = UDim2.fromScale(0.03, 0.06)
	label.Text, label.TextColor3, label.TextScaled = text, color or Color3.new(1, 1, 1), true
	label.Font = Visuals.Font
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Visuals.Palette.Navy, 2
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = part
	return label
end
function Models.Item(parent, cf, item)
	-- Existing callers pass the drop center; uploaded artwork uses a ground pivot.
	local model = Loader.Build(Placement.ItemNames[item.Id] or item.Id, parent, cf * CFrame.new(0, -0.8, 0), function()
		return require(Shared.Visuals.Items).Build(parent, cf, item)
	end)
	if not model:GetAttribute("MeshFallback") then
		local color = if item.Rarity == "Secret" then Visuals.Palette.Cyan else Rarities[item.Rarity].Color
		P.Ring(model, "RarityAura", cf * CFrame.new(0, -0.85, 0), 1.45, 1.45, 0.09, color, Enum.Material.Neon, 8)
		if Rarities[item.Rarity].Order >= 5 then
			P.Particles(model.PrimaryPart, "RareAura", color, Visuals.Budget.IdleRate)
		end
	end
	Models.Label(
		model.PrimaryPart,
		item.Name .. "\n" .. item.Rarity .. " | 1/" .. item.Chance,
		if item.Rarity == "Secret" then Visuals.Palette.Cyan else Rarities[item.Rarity].Color
	)
	return model
end
return Models
