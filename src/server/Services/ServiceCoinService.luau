-- Pure profile mutation; only the validated server flush path grants this award.
local ServiceCoinService = {}
local CashMath = require(if script then game.ReplicatedStorage.Shared.CashMath else "../../shared/CashMath")

function ServiceCoinService.Grant(profile, toilet, cashMultiplier)
	local amount = toilet.ServiceCoins
	assert(
		type(amount) == "number" and amount > 0 and amount <= CashMath.Limit and amount % 1 == 0,
		"Invalid service Coins configuration"
	)
	local multiplier = cashMultiplier or 1
	assert(CashMath.Finite(multiplier) and multiplier >= 1, "Invalid cash multiplier")
	amount = math.floor(CashMath.Product(amount, multiplier, CashMath.Limit) + 1e-9)
	if not CashMath.CanGrant(profile, amount) then
		return nil
	end
	profile.Coins += amount
	profile.Stats.Earned += amount
	return amount
end

return ServiceCoinService
