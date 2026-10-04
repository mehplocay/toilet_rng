local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local RollService = require(script.Parent.RollService)
local FlushService = {}

function FlushService.Start(data, limiter, remotes)
	local nextFlush = {}
	local random = Random.new()
	remotes.Flush.OnServerEvent:Connect(function(player, ...)
		if not limiter:Allow(player, "Flush") then
			return
		end
		if select("#", ...) ~= 0 then
			return
		end
		local profile = data:Get(player)
		if not profile then
			return
		end
		local now = os.clock()
		if now < (nextFlush[player] or 0) then
			return
		end
		local toilet = Toilets[profile.ToiletTier]
		if not toilet then
			return
		end
		nextFlush[player] = now + toilet.Cooldown
		local item = RollService.Roll(Items, Toilets, profile.ToiletTier, random:NextNumber())
		profile.Stats.Flushes += 1
		if item then
			profile.Inventory[item.Id] = (profile.Inventory[item.Id] or 0) + 1
			profile.Collection[item.Id] = (profile.Collection[item.Id] or 0) + 1
		end
		remotes.Result:FireClient(
			player,
			"Flush",
			{ ItemId = if item then item.Id else nil, Cooldown = toilet.Cooldown, Coins = profile.Coins }
		)
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		nextFlush[player] = nil
	end)
end

return FlushService
