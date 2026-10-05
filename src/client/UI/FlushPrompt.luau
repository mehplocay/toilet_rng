local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local C = require(script.Parent.Components)
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Prompt = {}
function Prompt.Start()
	local player, active, tracked = Players.LocalPlayer, {}, {}
	local function hide(prompt)
		if active[prompt] then
			active[prompt]:Destroy()
		end
		active[prompt] = nil
	end
	local function track(object)
		if not object:IsA("ProximityPrompt") or tracked[object] then
			return
		end
		local function update()
			local owner = object:GetAttribute("OwnerUserId")
			if owner then
				object.Enabled = owner == player.UserId
			end
		end
		tracked[object] = object:GetAttributeChangedSignal("OwnerUserId"):Connect(update)
		update()
	end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(object)
		if tracked[object] then
			tracked[object]:Disconnect()
			tracked[object] = nil
			hide(object)
		end
	end)
	for _, object in ipairs(workspace:GetDescendants()) do
		track(object)
	end
	local function own()
		for object in pairs(tracked) do
			if object:GetAttribute("OwnerUserId") == player.UserId then
				return object
			end
		end
		return nil
	end
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom or prompt:GetAttribute("OwnerUserId") ~= player.UserId then
			return
		end
		hide(prompt)
		local gui = C.New("BillboardGui", player:WaitForChild("PlayerGui"), {
			Name = "FlushPrompt",
			Adornee = prompt.Parent,
			Size = UDim2.fromOffset(216, 78),
			StudsOffset = Vector3.new(0, 1.4, -0.6),
			AlwaysOnTop = true,
			Active = true,
		})
		active[prompt] = gui
		local key = if inputType == Enum.ProximityPromptInputType.Touch
			then "TAP"
			elseif inputType == Enum.ProximityPromptInputType.Gamepad then prompt.GamepadKeyCode.Name
			else prompt.KeyboardKeyCode.Name
		C.Text(gui, "YOUR TOILET", UDim2.fromScale(0.9, 0.25), UDim2.fromScale(0.05, 0), 19)
		C.Button(gui, key .. "  •  FLUSH", UDim2.fromScale(0.94, 0.62), UDim2.fromScale(0.03, 0.3), function()
			if prompt.Enabled then
				prompt:InputHoldBegin()
				prompt:InputHoldEnd()
			end
		end, C.Green)
	end)
	ProximityPromptService.PromptHidden:Connect(hide)
	return {
		Own = own,
		Near = function()
			local prompt = own()
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
			local target = prompt and prompt.Parent
			if
				not prompt
				or not prompt.Enabled
				or not root
				or not humanoid
				or humanoid.Health <= 0
				or not target
				or not target:IsA("BasePart")
			then
				return false
			end
			local distance = (root.Position - target.Position).Magnitude
			return distance == distance and distance <= math.min(prompt.MaxActivationDistance, Config.FlushRange)
		end,
	}
end
return Prompt
