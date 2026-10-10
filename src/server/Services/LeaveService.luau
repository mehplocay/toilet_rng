local Players = game:GetService("Players")
local LeaveService = {}
function LeaveService.Start(limiter, remotes)
	remotes.LeaveRequest.OnServerEvent:Connect(function(player, ...)
		-- Roblox supplies the sender; no target or payload is accepted.
		if player.Parent ~= Players or Players:GetPlayerByUserId(player.UserId) ~= player then
			return
		end
		if not limiter:Allow(player, "LeaveRequest") or select("#", ...) ~= 0 then
			return
		end
		-- PlayerRemoving runs the normal DataService.Close and all service cleanup.
		player:Kick("See you soon! Your displays keep earning.")
	end)
end
return LeaveService
