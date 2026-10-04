local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.Monetization)
local Service = { Owned = {}, Auto = {} }
function Service:Load(player)
	local owned = {}
	for key, pass in pairs(Config.Gamepasses) do
		if pass.Id > 0 then
			local ok, result =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			owned[key] = ok and result == true
		end
	end
	if player.Parent == Players then
		self.Owned[player] = owned
	end
end
function Service:Luck(player)
	return if (self.Owned[player] or {}).DoubleLuck then 2 else 1
end
function Service:Start(limiter, remotes, sync)
	remotes.AutoFlush.OnServerEvent:Connect(function(player, enabled, ...)
		if select("#", ...) ~= 0 or type(enabled) ~= "boolean" or not limiter:Allow(player, "AutoFlush") then
			return
		end
		self.Auto[player] = enabled and (self.Owned[player] or {}).AutoFlush == true
		sync(player)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		if not purchased then
			return
		end
		for _, pass in pairs(Config.Gamepasses) do
			if pass.Id > 0 and pass.Id == id then
				self:Load(player)
				sync(player)
				break
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self.Owned[player] = nil
		self.Auto[player] = nil
	end)
end
return Service
