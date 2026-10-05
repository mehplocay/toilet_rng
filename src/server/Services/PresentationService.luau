local Settings = require(game.ReplicatedStorage.Shared.PresentationSettings)
local Service = {}
function Service.Start(data, limiter, remotes, sync, events)
	remotes.PresentationSettings.OnServerEvent:Connect(function(player, patch, ...)
		if
			not limiter:Allow(player, "PresentationSettings")
			or select("#", ...) ~= 0
			or not Settings.ValidRequest(patch)
		then
			return
		end
		local profile = data:Get(player)
		if profile then
			Settings.Apply(profile.Settings, patch)
			sync(player)
		end
	end)
	require(script.Parent.AnnouncementService).Start(data, remotes, events)
	require(script.Parent.PlayerListService).Start(data)
end
return Service
