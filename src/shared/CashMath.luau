-- Numeric safety only: cash factors have no gameplay ceiling.
local CashMath = {}
local MAX_FINITE = 1.7976931348623157e308
function CashMath.Finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function CashMath.Product(a, b, maximum)
	assert(CashMath.Finite(a) and a >= 0 and CashMath.Finite(b) and b >= 0, "Invalid cash product")
	maximum = maximum or MAX_FINITE
	if a == 0 or b == 0 then
		return 0
	end
	if a >= maximum / b then
		return maximum
	end
	return math.min(maximum, a * b)
end
function CashMath.Round(value)
	-- Adding 0.5 at the integer precision boundary can round UP a whole integer.
	return if value >= 2 ^ 52 then math.floor(value) else math.floor(value + 0.5)
end
return CashMath
