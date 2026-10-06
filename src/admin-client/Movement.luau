local Movement = {}
function Movement.Start(gui, C)
	local player = game:GetService("Players").LocalPlayer
	local input, run = game:GetService("UserInputService"), game:GetService("RunService")
	local state, expires, actuator, attachment, currentRoot = {}, 0, nil, nil, nil
	local links, axis = {}, 0
	local controls = C.New("Frame", gui, {
		Name = "AdminFlightControls",
		Size = UDim2.fromOffset(132, 52),
		Position = UDim2.new(1, -148, 1, -170),
		BackgroundTransparency = 1,
		Visible = false,
	})
	for index, direction in ipairs({ 1, -1 }) do
		local button = C.Button(
			controls,
			if direction == 1 then "UP" else "DOWN",
			UDim2.fromOffset(60, 48),
			UDim2.fromOffset((index - 1) * 68, 0),
			function() end,
			C.Purple,
			{ TextSize = 16 }
		)
		button.InputBegan:Connect(function(event)
			if
				event.UserInputType == Enum.UserInputType.Touch
				or event.UserInputType == Enum.UserInputType.MouseButton1
			then
				axis = direction
			end
		end)
		button.InputEnded:Connect(function()
			axis = 0
		end)
	end
	local function clear()
		if actuator then
			actuator:Destroy()
			actuator = nil
		end
		if attachment then
			attachment:Destroy()
			attachment = nil
		end
		currentRoot, axis = nil, 0
		controls.Visible = false
	end
	table.insert(
		links,
		run.PreSimulation:Connect(function()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
			if os.clock() >= expires or not root or not humanoid or humanoid.Health <= 0 then
				clear()
				return
			end
			if currentRoot and root ~= currentRoot then
				clear()
			end
			if state.Fly then
				if not actuator then
					attachment = Instance.new("Attachment")
					attachment.Name = "AdminFlightAttachment"
					attachment.Parent = root
					actuator = Instance.new("LinearVelocity")
					actuator.Name = "AdminFlight"
					actuator.Attachment0 = attachment
					actuator.RelativeTo = Enum.ActuatorRelativeTo.World
					actuator.MaxForce = 1000000
					actuator.Parent = root
					currentRoot = root
				end
				local vertical = axis
				if not input:GetFocusedTextBox() then
					if input:IsKeyDown(Enum.KeyCode.Space) then
						vertical += 1
					end
					if input:IsKeyDown(Enum.KeyCode.LeftControl) then
						vertical -= 1
					end
				end
				local direction = humanoid.MoveDirection + Vector3.new(0, vertical, 0)
				if direction.Magnitude > 1 then
					direction = direction.Unit
				end
				actuator.VectorVelocity = direction * require(game.ReplicatedStorage.Shared.Config.Admin).FlySpeed
				controls.Visible = true
			elseif actuator then
				clear()
			end
			-- Noclip collision state is applied/restored by the server; do not race its replication.
		end)
	)
	table.insert(
		links,
		player.CharacterRemoving:Connect(function()
			state = {}
			expires = 0
			clear()
		end)
	)
	return {
		Set = function(value)
			state = value
			expires = os.clock() + value.LeaseSeconds
		end,
		Destroy = function()
			for _, link in ipairs(links) do
				link:Disconnect()
			end
			clear()
			controls:Destroy()
		end,
	}
end
return Movement
