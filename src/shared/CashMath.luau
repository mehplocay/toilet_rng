-- Numeric safety only: cash factors have no gameplay ceiling.
local CashMath = {}
local Limit = require(if script then script.Parent.Config.Economy else "./Config/Economy").MaxAmount
CashMath.Limit = Limit
function CashMath.Finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function CashMath.Product(a, b, maximum)
	assert(CashMath.Finite(a) and a >= 0 and CashMath.Finite(b) and b >= 0, "Invalid cash product")
	assert(maximum == nil or (CashMath.Finite(maximum) and maximum >= 0), "Invalid cash bound")
	maximum = math.min(maximum or Limit, Limit)
	if a == 0 or b == 0 then
		return 0
	end
	if a >= maximum / b then
		return maximum
	end
	return math.min(maximum, a * b)
end
function CashMath.Amount(value)
	return CashMath.Finite(value) and value >= 0 and value <= Limit
end
function CashMath.Sanitize(value)
	return if CashMath.Amount(value) then math.floor(value) else 0
end
function CashMath.Add(a, b, maximum)
	assert(CashMath.Amount(a) and CashMath.Amount(b), "Invalid cash sum")
	assert(maximum == nil or (CashMath.Finite(maximum) and maximum >= 0), "Invalid cash bound")
	maximum = math.min(maximum or Limit, Limit)
	return math.min(maximum, a + b)
end
function CashMath.CanCredit(balance, amount)
	return CashMath.Amount(balance)
		and CashMath.Amount(amount)
		and amount <= Limit - balance
		and (amount == 0 or balance + amount > balance)
end
function CashMath.CanGrant(profile, amount)
	return CashMath.CanCredit(profile.Coins, amount)
		and CashMath.Amount(profile.Stats.Earned)
		and amount <= Limit - profile.Stats.Earned
end
function CashMath.Affords(balance, price)
	-- Never use an epsilon to turn insufficient funds into an affordable purchase.
	return CashMath.Amount(balance) and CashMath.Amount(price) and math.floor(balance) >= math.ceil(price)
end
function CashMath.Debit(balance, price)
	if not CashMath.Affords(balance, price) then
		return nil
	end
	price = math.ceil(price)
	local result = math.floor(balance) - price
	-- Charge a representable step if the price is smaller than one wallet ULP.
	-- This is conservative: a purchase can never be free or produce a negative wallet.
	if price > 0 and result == balance then
		result = balance - balance * 2 ^ -52
	end
	return math.max(0, result)
end
function CashMath.Near(a, b)
	return CashMath.Finite(a)
		and CashMath.Finite(b)
		and math.abs(a - b) <= math.max(1, math.abs(a), math.abs(b)) * 2 ^ -48
end
function CashMath.Power(base, exponent)
	assert(CashMath.Finite(base) and base > 0 and CashMath.Finite(exponent) and exponent >= 0)
	if base > 1 and exponent >= math.log(Limit) / math.log(base) then
		return Limit
	end
	return math.min(Limit, base ^ exponent)
end
function CashMath.Round(value)
	-- Adding 0.5 at the integer precision boundary can round UP a whole integer.
	return if value >= 2 ^ 52 then math.floor(value) else math.floor(value + 0.5)
end
return CashMath
