local CashMath = require(game.ReplicatedStorage.Shared.CashMath)
local Items = require(game.ReplicatedStorage.Shared.Config.Items)
local Toilets = require(game.ReplicatedStorage.Shared.Config.Toilets)
local SafeInventory = require(game.ReplicatedStorage.Shared.SafeInventory)
local upgrades =
	require(game.ReplicatedStorage.Shared.UpgradeRules).new(require(game.ReplicatedStorage.Shared.Config.Upgrades))
local EconomyService = {}

function EconomyService.Sell(profile, id, count)
	return SafeInventory.Sell(profile, Items, id, count, upgrades:Cash(profile))
end

function EconomyService.BuyToilet(profile, id)
	if type(id) ~= "string" then
		return false
	end
	local nextTier = profile.ToiletTier + 1
	local toilet = Toilets[nextTier]
	if not toilet or toilet.Id ~= id or not CashMath.Affords(profile.Coins, toilet.Price) then
		return false
	end
	profile.Coins = CashMath.Debit(profile.Coins, toilet.Price)
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
