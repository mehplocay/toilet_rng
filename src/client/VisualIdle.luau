local TweenService = game:GetService("TweenService")
local Visuals = require(game.ReplicatedStorage.Shared.Config.Visuals)
local Idle = {}
function Idle.Start()
	local registry = {}
	local function remove(object)
		local entry = registry[object]
		if not entry then
			return
		end
		if entry.Tween then
			entry.Tween:Cancel()
		end
		if entry.Link then
			entry.Link:Disconnect()
		end
		if entry.Value then
			entry.Value:Destroy()
		end
		if entry.DestroyLink then
			entry.DestroyLink:Disconnect()
		end
		registry[object] = nil
	end
	local function add(object)
		if
			registry[object]
			or not (
				object:GetAttribute("VisualIdle")
				or object:GetAttribute("IdleBob")
				or object:GetAttribute("IdleOrbit")
			)
		then
			return
		end
		local entry = {}
		registry[object] = entry
		if object:IsA("BasePart") then
			entry.Base = object.CFrame
			entry.Tween = TweenService:Create(
				object,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ CFrame = object.CFrame * CFrame.new(0, object:GetAttribute("IdleBob"), 0) }
			)
		elseif object:IsA("Model") then
			entry.Base = object:GetPivot()
			entry.Value = Instance.new("NumberValue")
			entry.Value.Value = 0
			entry.Link = entry.Value.Changed:Connect(function(angle)
				if object.Parent then
					object:PivotTo(entry.Base * CFrame.Angles(0, angle, 0))
				end
			end)
			entry.Tween = TweenService:Create(
				entry.Value,
				TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
				{ Value = math.pi * 2 }
			)
		elseif object:IsA("PointLight") then
			entry.Tween = TweenService:Create(
				object,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Brightness = 1.1 }
			)
		end
		entry.DestroyLink = object.Destroying:Connect(function()
			remove(object)
		end)
	end
	workspace.DescendantAdded:Connect(add)
	for _, object in ipairs(workspace:GetDescendants()) do
		add(object)
	end
	task.spawn(function()
		while true do
			local camera = workspace.CurrentCamera
			for object, entry in pairs(registry) do
				local part = if object:IsA("BasePart")
					then object
					elseif object:IsA("Model") then object:FindFirstChildWhichIsA("BasePart")
					elseif object:IsA("Highlight") then object.Parent.PrimaryPart
					else object.Parent
				local toilet = object:FindFirstAncestor("Toilet")
				local flushing = toilet and toilet:GetAttribute("Flushing")
				local near = camera
					and part
					and part:IsA("BasePart")
					and (camera.CFrame.Position - part.Position).Magnitude <= Visuals.Budget.IdleDistance
				local enabled = near == true and not flushing
				if enabled ~= entry.Enabled then
					entry.Enabled = enabled
					if entry.Tween then
						if enabled then
							entry.Tween:Play()
						else
							entry.Tween:Pause()
						end
					end
					if object:IsA("ParticleEmitter") or object:IsA("PointLight") or object:IsA("Highlight") then
						object.Enabled = enabled
					end
				end
			end
			task.wait(0.5)
		end
	end)
end
return Idle
