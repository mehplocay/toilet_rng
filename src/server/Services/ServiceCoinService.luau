-- Pure profile mutation; only the validated server flush path grants this award.
local ServiceCoinService = {}
local MAX_COINS = 9e15
local CashMath = require(if script then game.ReplicatedStorage.Shared.CashMath else "../../shared/CashMath")

function ServiceCoinService.Grant(profile, toilet, cashMultiplier)
	local amount = toilet.ServiceCoins
	assert(
		type(amount) == "number" and amount > 0 and amount <= MAX_COINS and amount % 1 == 0,
		"Invalid service Coins configuration"
	)
	local multiplier = cashMultiplier or 1
	assert(CashMath.Finite(multiplier) and multiplier >= 1, "Invalid cash multiplier")
	amount = math.floor(CashMath.Product(amount, multiplier, MAX_COINS) + 1e-9)
	if profile.Coins > MAX_COINS - amount or profile.Stats.Earned > MAX_COINS - amount then
		return nil
	end
	profile.Coins += amount
	profile.Stats.Earned += amount
	return amount
end

return ServiceCoinService
