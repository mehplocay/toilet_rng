local upgrades =
	require(game.ReplicatedStorage.Shared.UpgradeRules).new(require(game.ReplicatedStorage.Shared.Config.Upgrades))
local Service = {}
local TutorialProgress = require(game.ReplicatedStorage.Shared.TutorialProgress)
function Service.Start(data, limiter, remotes, sync)
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player, id, expectedLevel, ...)
		if not limiter:Allow(player, "BuyUpgrade") or select("#", ...) ~= 0 then
			return
		end
		-- Get settles passive earnings at the old multiplier before this non-yielding transaction.
		local profile = data:Get(player)
		if not profile or data.Saving[player] then
			return
		end
		local success = upgrades:Buy(profile, id, expectedLevel)
		if success then
			TutorialProgress.Record(profile, "BuyUpgrade", { Success = true })
		end
		if success and not data:Save(player, false) then
			return
		end
		if data:Get(player) ~= profile then
			return
		end
		sync(player)
		remotes.Result:FireClient(player, "BuyUpgrade", {
			Success = success,
			Message = if success
				then "Permanent upgrade purchased!"
				else "Upgrade unavailable. Check your coins and current level.",
		})
	end)
end
return Service
