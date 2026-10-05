-- World billboards yield to screen controls when the camera projects them underneath.
local Labels = {}
function Labels.Overlaps(a, b)
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end
function Labels.Start(hud)
	local registry = {}
	local function add(object)
		if object:IsA("BillboardGui") then
			registry[object] = true
		end
	end
	local added = workspace.DescendantAdded:Connect(add)
	local removed = workspace.DescendantRemoving:Connect(function(object)
		registry[object] = nil
	end)
	for _, object in ipairs(workspace:GetDescendants()) do
		add(object)
	end
	local step = game:GetService("RunService").RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local occupied = {}
		if hud.Visible then
			for _, object in ipairs(hud:GetChildren()) do
				if object:IsA("GuiObject") and object.Visible then
					local p, s = object.AbsolutePosition, object.AbsoluteSize
					table.insert(occupied, { X = p.X - 8, Y = p.Y - 8, W = s.X + 16, H = s.Y + 16 })
				end
			end
		end
		for gui in pairs(registry) do
			if gui:GetAttribute("AvoidHUD") then
				local anchor = gui.Adornee or gui.Parent
				if anchor and anchor:IsA("BasePart") then
					local position = anchor.Position
					local center = camera:WorldToScreenPoint(position)
					local edge = camera:WorldToScreenPoint(position + camera.CFrame.UpVector)
					local pixels = math.abs(edge.Y - center.Y)
					local w, h =
						gui.Size.X.Scale * pixels + gui.Size.X.Offset, gui.Size.Y.Scale * pixels + gui.Size.Y.Offset
					local bounds = { X = center.X - w / 2, Y = center.Y - h / 2, W = w, H = h }
					local enabled = hud.Visible and center.Z > 0
					for _, rect in ipairs(occupied) do
						if Labels.Overlaps(bounds, rect) then
							enabled = false
							break
						end
					end
					gui.Enabled = enabled
				end
			end
		end
	end)
	hud.Destroying:Connect(function()
		added:Disconnect()
		removed:Disconnect()
		step:Disconnect()
		for gui in pairs(registry) do
			if gui:GetAttribute("AvoidHUD") then
				gui.Enabled = true
			end
		end
	end)
end
return Labels
