local CashMath = require(game.ReplicatedStorage.Shared.CashMath)
local RunService = game:GetService("RunService")

local DevGrantService = {}
local grants = { ["1000"] = 1000, ["100000"] = 100000, ["10000000"] = 10000000 }

function DevGrantService.Start(data, limiter, remotes, sync)
	remotes.DevGrant.OnServerEvent:Connect(function(player, grantKey, ...)
		if not RunService:IsStudio() then
			return
		end
		if select("#", ...) ~= 0 or type(grantKey) ~= "string" or not limiter:Allow(player, "DevGrant") then
			return
		end
		local amount = grants[grantKey]
		local profile = data:Get(player)
		if not amount or not profile or not CashMath.CanGrant(profile, amount) then
			return
		end
		profile.Coins += amount
		profile.Stats.Earned += amount
		sync(player)
	end)
end

return DevGrantService
