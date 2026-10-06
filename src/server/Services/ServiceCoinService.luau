-- Pure profile mutation; only the validated server flush path grants this award.
local ServiceCoinService = {}
local MAX_COINS = 9e15
local Monetization =
	require(if script then game.ReplicatedStorage.Shared.Config.Monetization else "../../shared/Config/Monetization")

function ServiceCoinService.Grant(profile, toilet, cashMultiplier)
	local amount = toilet.ServiceCoins
	assert(
		type(amount) == "number" and amount > 0 and amount <= MAX_COINS and amount % 1 == 0,
		"Invalid service Coins configuration"
	)
	local multiplier = cashMultiplier or 1
	assert(
		type(multiplier) == "number" and multiplier >= 1 and multiplier <= Monetization.CashMultiplierCap,
		"Invalid cash multiplier"
	)
	amount = math.floor(amount * multiplier + 1e-9)
	if profile.Coins > MAX_COINS - amount or profile.Stats.Earned > MAX_COINS - amount then
		return nil
	end
	profile.Coins += amount
	profile.Stats.Earned += amount
	return amount
end

return ServiceCoinService
