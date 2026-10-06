local Shared = game.ReplicatedStorage.Shared
local P = require(Shared.Visuals.Primitives)
local Visuals = require(Shared.Config.Visuals)
local Rarities = require(Shared.Config.Rarities)
local Loader = require(script.Parent.MeshLoader)
local Placement = require(Shared.Config.WorldModels)
local Models = { Part = P.Part }
function Models.Toilet(parent, cf, tier, scale, owner)
	local model = Loader.Build(Placement.ToiletNames[tier], parent, cf, function()
		return require(Shared.Visuals.Toilets).BuildPrimitive(parent, cf, tier)
	end)
	model.Name = "Toilet"
	-- Scale about the shared foot datum, including primitive fallbacks.
	model.PrimaryPart.PivotOffset = model.PrimaryPart.CFrame:Inverse() * cf
	if scale and scale ~= 1 then
		model:ScaleTo(model:GetScale() * scale)
		model:PivotTo(cf)
	end
	if not model:GetAttribute("MeshFallback") then
		require(Shared.Visuals.TemplateAccents).Apply(model, scale)
	end
	if owner then
		-- Only the small owned toilet persists; visitors use normal atomic streaming.
		model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
		model:AddPersistentPlayer(owner)
	end
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
function Models.Item(parent, cf, item, display)
	-- Existing callers pass the drop center; uploaded artwork uses a ground pivot.
	local model = Loader.Build(Placement.ItemNames[item.Id] or item.Id, parent, cf * CFrame.new(0, -0.8, 0), function()
		if display then
			local fallback = Instance.new("Model")
			fallback.Name, fallback.Parent = item.Id, parent
			fallback.PrimaryPart =
				P.Ball(fallback, "MissingItem", Vector3.new(2, 2, 2), cf, Rarities[item.Rarity].Color)
			return fallback
		end
		return require(Shared.Visuals.Items).BuildPrimitive(parent, cf, item)
	end)
	if not model:GetAttribute("MeshFallback") then
		require(Shared.Visuals.TemplateAccents).Apply(model)
		local color = if item.Rarity == "Secret" then Visuals.Palette.Cyan else Rarities[item.Rarity].Color
		if Rarities[item.Rarity].Order >= 4 then
			local highlight = Instance.new("Highlight")
			highlight.Name, highlight.Adornee = "RarityOutline", model
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.FillColor, highlight.OutlineColor = color, color
			highlight.FillTransparency, highlight.OutlineTransparency = 0.85, 0.1
			highlight.Enabled = false
			highlight:SetAttribute("VisualIdle", true)
			highlight.Parent = model
		end
		if Rarities[item.Rarity].Order >= 4 and not model:GetAttribute("TemplateAccents") then
			P.Particles(model.PrimaryPart, "RareAura", color, Visuals.Budget.IdleRate)
		end
	end
	if display then
		return model
	end
	Models.Label(
		model.PrimaryPart,
		item.Name .. "\n" .. item.Rarity .. " | 1/" .. item.Chance,
		if item.Rarity == "Secret" then Visuals.Palette.Cyan else Rarities[item.Rarity].Color
	)
	return model
end
return Models
