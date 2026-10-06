local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.Presentation)
local PlayerList = {}
function PlayerList.Create(_root)
	-- CoreScripts own layout, device support and Tab. No custom input binding.
	local elapsed, lifetime, connection = 0, 0, nil
	local function enable()
		return pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end)
	end
	if not enable() then
		connection = RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			lifetime += dt
			if elapsed >= 0.25 then
				elapsed = 0
				local enabled = enable()
				if enabled or lifetime >= Config.CoreGuiRetryTTL then
					if not enabled then
						warn("Roblox PlayerList could not initialize within the startup retry window.")
					end
					connection:Disconnect()
					connection = nil
				end
			end
		end)
	end
	return {
		Destroy = function()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end,
	}
end
return PlayerList
