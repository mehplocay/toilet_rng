local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.Rebirth)
local rules = require(Shared.RebirthRules).new(Config)
local Service = {}
function Service.Start(data, limiter, remotes, sync, events)
	remotes.Rebirth.OnServerEvent:Connect(function(player, expectedLevel, ...)
		if not limiter:Allow(player, "Rebirth") or select("#", ...) ~= 0 then
			return
		end
		local profile = data:Get(player)
		if not profile or data.Saving[player] then
			remotes.Result:FireClient(
				player,
				"Rebirth",
				{ Success = false, Message = "A save is pending. Please wait." }
			)
			return
		end
		local replacement = rules:Build(profile, expectedLevel, os.time())
		if not replacement then
			remotes.Result:FireClient(
				player,
				"Rebirth",
				{ Success = false, Message = "Rebirth requirements changed or are not met." }
			)
			return
		end
		-- No yields between eligibility, complete construction and the guarded swap.
		if not data:ReplaceAndSave(player, profile, replacement) then
			return
		end
		if data:Get(player) ~= replacement then
			return
		end
		sync(player)
		remotes.Result:FireClient(
			player,
			"Rebirth",
			{ Success = true, Level = replacement.RebirthLevel, Message = "Rebirth saved!" }
		)
		if events.Rebirth then
			events.Rebirth(player, replacement.RebirthLevel)
		end
	end)
end
return Service
