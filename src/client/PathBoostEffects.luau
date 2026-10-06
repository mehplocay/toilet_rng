local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.PathBoost)
local Rules = require(Shared.PathBoostRules)
local zones = Rules.Zones(require(Shared.Config.MapLayout), require(Shared.Config.MeshCatalog), Config)
local C = require(script.Parent.UI.Components)
local Effects = {}
function Effects.Start(root, player, remotes)
	local chip = C.Text(root, "Speed x3", UDim2.fromOffset(114, 28), UDim2.new(0.5, -57, 0, 65), 20)
	chip.Name, chip.TextColor3, chip.Visible = "PathSpeedChip", C.Blue, false
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalPathChevrons", workspace
	local arrows, lines = {}, {}
	for i = 1, Config.ChevronCount * 2 do
		local part = Instance.new("Part")
		part.Name = "Chevron"
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
		part.Size, part.Material, part.Color =
			Vector3.new(0.18, 0.06, 1.5), Enum.Material.Neon, Color3.fromRGB(130, 250, 255)
		part.Transparency, part.Parent = 1, folder
		arrows[i] = part
	end
	for i = 1, 6 do
		lines[i] = C.New("Frame", root, {
			Name = "SpeedLine",
			Size = UDim2.fromOffset(36, 2),
			Position = UDim2.new(if i <= 3 then 0 else 1, if i <= 3 then 8 else -44, 0.3 + ((i - 1) % 3) * 0.15, 0),
			BackgroundColor3 = C.Blue,
			BackgroundTransparency = 0.7,
			Visible = false,
		})
	end
	local mode, camera, fovOffset, lastFOV = "Full", nil, 0, nil
	local function restoreCamera()
		if camera and lastFOV and math.abs(camera.FieldOfView - lastFOV) < 0.01 then
			camera.FieldOfView -= fovOffset
		end
		fovOffset, lastFOV = 0, nil
	end
	local settings = remotes.State.OnClientEvent:Connect(function(state)
		mode = (state.Settings or {}).RevealIntensity or "Full"
	end)
	local elapsed = 0
	local render = game:GetService("RunService").RenderStepped:Connect(function(dt)
		elapsed += dt
		local multiplier = player:GetAttribute("PathSpeedMultiplier") or 1
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local active = multiplier > 1 and hrp ~= nil and humanoid ~= nil and humanoid.Health > 0
		chip.Visible, chip.Text = active, string.format("Speed x%g", multiplier)
		local moving = active and humanoid.MoveDirection.Magnitude > 0.1
		local full = moving and mode == "Full"
		if workspace.CurrentCamera ~= camera then
			restoreCamera()
			camera = workspace.CurrentCamera
		end
		if camera then
			-- A reveal or another camera controller may have replaced our last value.
			-- Never subtract an offset that is no longer present in the camera.
			if lastFOV and math.abs(camera.FieldOfView - lastFOV) >= 0.01 then
				fovOffset = 0
			end
			local target = if full then Config.FOVKick else 0
			local nextOffset = fovOffset + (target - fovOffset) * math.min(1, dt * 8)
			if math.abs(nextOffset - target) < 0.01 then
				nextOffset = target
			end
			camera.FieldOfView += nextOffset - fovOffset
			fovOffset = nextOffset
			lastFOV = camera.FieldOfView
		end
		for i, line in ipairs(lines) do
			line.Visible = full
			line.BackgroundTransparency = 0.78 + math.sin(elapsed * 7 + i) * 0.1
		end
		for i = 1, Config.ChevronCount do
			local left, right = arrows[i * 2 - 1], arrows[i * 2]
			left.Transparency, right.Transparency = 1, 1
			if moving and mode == "Full" then
				local direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z).Unit
				local distance = (
					(elapsed * Config.ChevronSpeed + i * Config.ChevronSpacing)
					% (Config.ChevronCount * Config.ChevronSpacing)
				) + 1
				local pos = hrp.Position + direction * distance
				local zone = Rules.Find(zones, pos.X, hrp.Position.Y, pos.Z, Config.RootHeight)
				if zone then
					pos = Vector3.new(pos.X, zone.Y + 0.12, pos.Z)
					local cf = CFrame.lookAt(pos, pos + direction)
					left.CFrame = cf * CFrame.new(-0.48, 0, 0.48) * CFrame.Angles(0, math.rad(-45), 0)
					right.CFrame = cf * CFrame.new(0.48, 0, 0.48) * CFrame.Angles(0, math.rad(45), 0)
					left.Transparency, right.Transparency = 0.4, 0.4
				end
			end
		end
	end)
	root.Destroying:Connect(function()
		render:Disconnect()
		settings:Disconnect()
		restoreCamera()
		folder:Destroy()
	end)
end
return Effects
