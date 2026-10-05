local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local C = require(script.Parent.Components)
local Prompt = {}
function Prompt.Start()
	local active = {}
	local function hide(prompt)
		local gui = active[prompt]
		if gui then
			gui:Destroy()
		end
		active[prompt] = nil
	end
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if
			prompt.Style ~= Enum.ProximityPromptStyle.Custom
			or prompt:GetAttribute("OwnerUserId") ~= Players.LocalPlayer.UserId
		then
			return
		end
		hide(prompt)
		local gui = C.New("BillboardGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
			Name = "FlushPrompt",
			Adornee = prompt.Parent,
			Size = UDim2.fromOffset(240, 92),
			StudsOffset = Vector3.new(0, 1.4, -0.6),
			AlwaysOnTop = true,
			Active = true,
		})
		active[prompt] = gui
		local key = if inputType == Enum.ProximityPromptInputType.Touch
			then "TAP"
			elseif inputType == Enum.ProximityPromptInputType.Gamepad then prompt.GamepadKeyCode.Name
			else prompt.KeyboardKeyCode.Name
		C.Text(gui, "YOUR TOILET", UDim2.fromScale(0.9, 0.24), UDim2.fromScale(0.05, 0))
		C.Button(gui, key .. "  |  FLUSH", UDim2.fromScale(0.94, 0.65), UDim2.fromScale(0.03, 0.29), function()
			if prompt.Enabled then
				prompt:InputHoldBegin()
				prompt:InputHoldEnd()
			end
		end, Color3.fromRGB(55, 214, 35))
	end)
	ProximityPromptService.PromptHidden:Connect(hide)
end
return Prompt
