local C = require(script.Parent.Components)
local Shared = game.ReplicatedStorage.Shared
local Items, Toilets = require(Shared.Visuals.Items), require(Shared.Visuals.Toilets)
local Preview = {}
function Preview.Create(parent, size, position, item, tier, silhouette)
	local viewport = C.New("ViewportFrame", parent, {
		Size = size,
		Position = position,
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(180, 191, 230),
		LightColor = Color3.fromRGB(255, 240, 210),
		LightDirection = Vector3.new(-1, -1, -2),
	})
	local world = C.New("WorldModel", viewport)
	local model = if item
		then Items.Build(world, CFrame.new(), item, true)
		else Toilets.Build(world, CFrame.new(), tier, true)
	if silhouette then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color, part.Material, part.Transparency = Color3.fromRGB(6, 10, 20), Enum.Material.SmoothPlastic, 0
			end
		end
	end
	local camera = C.New("Camera", viewport, {
		FieldOfView = 35,
		CFrame = if item
			then CFrame.lookAt(Vector3.new(4.8, 3.2, -7.4), Vector3.new(0, 0.65, 0))
			else CFrame.lookAt(Vector3.new(9, 7, -14), Vector3.new(0, 3, 0)),
	})
	viewport.CurrentCamera = camera
	return viewport
end
return Preview
