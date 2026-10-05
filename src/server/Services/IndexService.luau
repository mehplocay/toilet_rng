local Service = {}

function Service.Start(index, data, limiter, remotes, sync)
	remotes.ClaimIndexReward.OnServerEvent:Connect(function(player, id, ...)
		if not limiter:Allow(player, "ClaimIndexReward") or select("#", ...) ~= 0 or type(id) ~= "string" then
			return
		end
		local profile = data:Get(player)
		if not profile then
			return
		end
		local result = index:Claim(profile, id)
		result.RewardId = id
		if result.Success and not data:Save(player, false) then
			return
		end
		-- Fetch through data again: a disconnect/save failure may have closed this session.
		if not data:Get(player) then
			return
		end
		sync(player)
		remotes.Result:FireClient(player, "ClaimIndexReward", result)
	end)
end

return Service
