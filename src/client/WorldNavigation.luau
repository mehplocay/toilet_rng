-- World interactions only; panel implementations remain owned by the UI workstream.
local Players = game:GetService("Players")
local PromptService = game:GetService("ProximityPromptService")
local C = require(script.Parent.UI.Components)
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
		C.Sound("Teleport")
	end
end
function Navigation.Start(open, toast)
	-- Inactive portals have scenery but no server prompt. This local prompt only
	-- supplies feedback; it sends no requests and performs no travel.
	local function portal(object)
		if object:IsA("BasePart") and object.Name == "PortalPulse" and not object:FindFirstChild("ComingSoonAudio") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name, prompt.ActionText, prompt.ObjectText = "ComingSoonAudio", "Coming soon", "Portal"
			prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 16, false
			prompt.Parent = object
		end
	end
	workspace.DescendantAdded:Connect(portal)
	for _, object in ipairs(workspace:GetDescendants()) do
		portal(object)
	end
	PromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "ComingSoonAudio" then
			C.Sound("PortalLocked")
			if toast then
				toast("This world is coming soon.", C.Gold)
			end
			return
		end
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
