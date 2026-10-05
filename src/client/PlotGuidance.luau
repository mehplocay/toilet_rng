local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.PlotGuidance)
local Chooser = require(Shared.PlotChooser)
local C = require(script.Parent.UI.Components)
local Guidance = {}

function Guidance.Start()
	local player = Players.LocalPlayer
	-- All guidance instances are local; other players never receive the beacon.
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "OwnPlotGuidance", workspace
	local function part(name)
		local object = Instance.new("Part")
		object.Name = name
		object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
		object.Transparency = 1
		object.Parent = folder
		return object
	end
	local pillar, target, sign = part("OwnPlotPillar"), part("GuideTarget"), part("OwnPlotSign")
	pillar.Material, pillar.Color = Enum.Material.Neon, Config.Color
	pillar.Size = Vector3.new(Config.BeaconWidth, Config.BeaconHeight, Config.BeaconWidth)
	local destination = Instance.new("Attachment")
	destination.Parent = target
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment1, beam.FaceCamera = "OwnPlotGuide", destination, true
	beam.Width0, beam.Width1 = 0.3, 0.8
	beam.Color, beam.LightEmission = ColorSequence.new(Config.Color), 1
	beam.Transparency, beam.Enabled, beam.Parent = NumberSequence.new(0.15), false, folder
	local billboard = Instance.new("BillboardGui")
	billboard.Name, billboard.Adornee = "OwnPlotName", sign
	billboard.Size = UDim2.fromOffset(Config.SignSize.X, Config.SignSize.Y)
	billboard.AlwaysOnTop, billboard.MaxDistance, billboard.Enabled = true, Config.SignDistance, false
	billboard.Parent = folder
	local card = C.New("Frame", billboard, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	C.Chrome(card, C.Navy)
	C.Text(card, player.DisplayName .. "'s Plot", UDim2.fromScale(0.94, 0.86), UDim2.fromScale(0.03, 0.07)).TextColor3 =
		Config.Color
	local source
	RunService.Heartbeat:Connect(function()
		local center = player:GetAttribute("PlotCenter")
		local position = player:GetAttribute("PlotPosition")
		local signPosition = player:GetAttribute("PlotSignPosition")
		local valid = typeof(center) == "Vector3"
			and typeof(position) == "Vector3"
			and typeof(signPosition) == "Vector3"
		pillar.Transparency, billboard.Enabled = if valid then 0.55 else 1, valid
		if not valid then
			beam.Enabled = false
			return
		end
		pillar.Position = center + Vector3.new(0, Config.BeaconHeight / 2, 0)
		target.Position, sign.Position = position, signPosition
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			beam.Enabled = false
			return
		end
		if not source or source.Parent ~= root then
			if source then
				source:Destroy()
			end
			source = Instance.new("Attachment")
			source.Name, source.Parent = "OwnPlotGuideOrigin", root
			beam.Attachment0 = source
		end
		local delta = root.Position - position
		local plotDistance = Vector2.new(delta.X, delta.Z).Magnitude
		local hubDistance = Vector2.new(root.Position.X, root.Position.Z).Magnitude
		beam.Enabled = Chooser.ShowGuide(plotDistance, hubDistance, Config.NearDistance, Config.HubRadius)
	end)
end

return Guidance
