-- World interactions only; panel implementations remain owned by the UI workstream.
local Players = game:GetService("Players")
local PromptService = game:GetService("ProximityPromptService")
local Navigation = {}
function Navigation.Travel(name)
	local Layout = require(game.ReplicatedStorage.Shared.Config.MapLayout)
	local player = Players.LocalPlayer
	local position = if name == "TravelShop" then Layout.ShopArrival else Layout.HubArrival
	-- Requests may time out; engine streaming integrity protects unloaded collision regions.
	pcall(function()
		player:RequestStreamAroundAsync(position, 3)
	end)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.lookAt(position, Vector3.new(0, position.Y, 0)))
	end
end
function Navigation.Start(open)
	PromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("RebirthOwnerUserId") == Players.LocalPlayer.UserId then
			open("Rebirth")
			return
		end
		local panel = prompt:GetAttribute("StationPanel")
		if panel == "Shop" or panel == "Upgrades" or panel == "Collection" or panel == "Daily" or panel == "Passes" then
			open(panel)
		end
	end)
end
return Navigation
