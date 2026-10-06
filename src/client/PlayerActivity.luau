local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.AutoFlush)
local Activity = {}
function Activity.Start(root, remote)
	local dirty, lastSent, focused = false, -math.huge, true
	local function input()
		if focused then
			dirty = true
		end
	end
	local connections = {
		Input.InputBegan:Connect(input),
		Input.InputEnded:Connect(input),
		Input.InputChanged:Connect(function(event)
			-- Ignore stationary analog noise and non-user sensor updates.
			if event.UserInputType == Enum.UserInputType.MouseWheel then
				if event.Position.Z ~= 0 then
					input()
				end
			elseif
				event.UserInputType == Enum.UserInputType.MouseMovement
				or event.UserInputType == Enum.UserInputType.Touch
			then
				if event.Delta and event.Delta.Magnitude > 0 then
					input()
				end
			elseif
				(event.KeyCode == Enum.KeyCode.Thumbstick1 or event.KeyCode == Enum.KeyCode.Thumbstick2)
				and event.Position.Magnitude > 0.2
				and event.Delta.Magnitude > 0.05
			then
				input()
			end
		end),
		Input.WindowFocusReleased:Connect(function()
			focused, dirty = false, false
		end),
		Input.WindowFocused:Connect(function()
			focused = true
		end),
		Run.Heartbeat:Connect(function()
			if dirty and focused and os.clock() - lastSent >= Config.ActivityInterval then
				dirty, lastSent = false, os.clock()
				remote:FireServer()
			end
		end),
	}
	root.Destroying:Connect(function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end)
end
return Activity
