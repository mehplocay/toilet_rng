local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Assets, Style, Toilets =
	require(Shared.Config.Assets), require(Shared.Config.World), require(Shared.Config.Toilets)
local Preview = {}
function Preview.Create(parent, size, position, item, tier, silhouette)
	local frame =
		C.New("Frame", parent, { Name = "Preview", Size = size, Position = position, BackgroundTransparency = 1 })
	local kind = if silhouette then "Lock" elseif item then item.Id else "Flush"
	local id = if silhouette
		then nil
		elseif item then (Assets.ItemIcons or {})[item.Id]
		else (Assets.ToiletIcons or {})[Toilets[tier].Id]
	local tint = if item then Style.ItemColors[item.Id] else Style.ToiletColors[tier or 1]
	if not silhouette and id == "" then
		-- Static, effect-free template preview until a real uploaded icon is configured.
		local viewport = C.New("ViewportFrame", frame, {
			Name = "ModelPreview",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Ambient = Color3.fromRGB(210, 210, 230),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(-1, -1, -1),
		})
		local model = if item
			then require(Shared.Visuals.Items).Build(viewport, CFrame.new(), item, true)
			else require(Shared.Visuals.Toilets).Build(viewport, CFrame.new(), tier, true)
		local bounds, dimensions = model:GetBoundingBox()
		local radius = math.max(dimensions.X, dimensions.Y, dimensions.Z) * 0.5
		local camera = C.New("Camera", viewport, { FieldOfView = 35 })
		camera.CFrame = CFrame.lookAt(
			bounds.Position + Vector3.new(radius * 0.55, radius * 0.35, radius / math.tan(math.rad(17.5)) + radius),
			bounds.Position
		)
		viewport.CurrentCamera = camera
		return frame
	end
	local icon = C.Icon(frame, kind, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), id, tint)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	return frame
end
return Preview
