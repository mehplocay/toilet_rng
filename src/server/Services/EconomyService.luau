local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local EconomyService = {}
local byId = {}
for _, item in ipairs(Items) do
	byId[item.Id] = item
end

function EconomyService.Sell(profile, id, count)
	if
		type(id) ~= "string"
		or not byId[id]
		or type(count) ~= "number"
		or count ~= count
		or count < 1
		or count > 1000000
		or count % 1 ~= 0
	then
		return false
	end
	local owned = profile.Inventory[id] or 0
	local displayed = 0
	for _, displayId in pairs(profile.Displays) do
		if displayId == id then
			displayed += 1
		end
	end
	if owned - displayed < count then
		return false
	end
	local value = byId[id].Value * count
	if profile.Coins + value > 9e15 then
		return false
	end
	profile.Inventory[id] = owned - count
	profile.Coins += value
	profile.Stats.Earned += value
	return true
end

function EconomyService.BuyToilet(profile, id)
	if type(id) ~= "string" then
		return false
	end
	local nextTier = profile.ToiletTier + 1
	local toilet = Toilets[nextTier]
	if not toilet or toilet.Id ~= id or profile.Coins < toilet.Price then
		return false
	end
	profile.Coins -= toilet.Price
	profile.ToiletTier = nextTier
	return true
end

function EconomyService.Start(data, limiter, remotes, sync)
	remotes.Sell.OnServerEvent:Connect(function(player, id, count, ...)
		if not limiter:Allow(player, "Sell") or select("#", ...) ~= 0 then
			return
		end
		local profile = data:Get(player)
		if not profile then
			return
		end
		local success = EconomyService.Sell(profile, id, count)
		if success then
			sync(player)
		end
		remotes.Result:FireClient(player, "Sell", { Success = success, Coins = profile.Coins })
	end)
	remotes.BuyToilet.OnServerEvent:Connect(function(player, id, ...)
		if not limiter:Allow(player, "BuyToilet") or select("#", ...) ~= 0 then
			return
		end
		local profile = data:Get(player)
		if not profile then
			return
		end
		local success = EconomyService.BuyToilet(profile, id)
		if success then
			sync(player)
		end
		remotes.Result:FireClient(
			player,
			"BuyToilet",
			{ Success = success, Coins = profile.Coins, ToiletTier = profile.ToiletTier }
		)
	end)
end

return EconomyService
