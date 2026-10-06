-- This script and its modules are cloned only into an authorized player's PlayerGui.
local player = game:GetService("Players").LocalPlayer
local client = player:WaitForChild("PlayerScripts"):WaitForChild("Client")
local C = require(client:WaitForChild("UI"):WaitForChild("Components"))
local gui = script.Parent.Parent
local remote = gui:WaitForChild("Command")
-- A replicated folder can arrive before all of its descendants.
local window = script.Parent:WaitForChild("Window")
script.Parent:WaitForChild("Movement")
script.Parent:WaitForChild("Previews")
require(window).Create(gui, remote, C, function()
	local labels = require(client:WaitForChild("WorldLabels"))
	if labels.Reload then
		labels.Reload()
	end
end)
