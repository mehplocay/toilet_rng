-- Optional polish integration: call Attach on the stairs' existing invisible GUI anchor.
-- This module creates no geometry and never performs a reset; it only opens the owner UI.
local Hook = {}
function Hook.Attach(anchor, owner)
	local prompt = anchor:FindFirstChild("RebirthPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "RebirthPrompt"
		prompt.ActionText, prompt.ObjectText = "View Rebirth", "Rebirth Stairs"
		prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.R, Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 10, false
		prompt.Parent = anchor
	end
	prompt:SetAttribute("RebirthOwnerUserId", if owner then owner.UserId else 0)
	prompt:SetAttribute("OwnerUserId", if owner then owner.UserId else 0)
	prompt.Enabled = owner ~= nil
	return prompt
end
return Hook
