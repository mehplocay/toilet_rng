-- Pure entitlement math. Passes are written only by server marketplace verification.
local Config = require(if script then script.Parent.Config.Monetization else "./Config/Monetization")
local CashMath = require(if script then script.Parent.CashMath else "./CashMath")
local Benefits = {}
function Benefits.Owns(profile, key)
	local passes = profile and (if profile.Monetization then profile.Monetization.Passes else profile.OwnedPasses)
	return Config.Gamepasses[key] ~= nil
		and passes ~= nil
		and (
			passes[key] == true
			or (key ~= "UltimateBundle" and Config.Gamepasses[key] ~= nil and passes.UltimateBundle == true)
		)
end
function Benefits.Cash(profile, base)
	assert(CashMath.Finite(base) and base >= 1, "Invalid base cash factor")
	local factor = math.min(base, CashMath.Limit)
	for key, pass in pairs(Config.Gamepasses) do
		if pass.CashMultiplier and Benefits.Owns(profile, key) then
			assert(pass.CashMultiplier >= 1 and pass.CashMultiplier < math.huge, "Invalid paid cash factor")
			factor = CashMath.Product(factor, pass.CashMultiplier)
		end
	end
	return factor
end
function Benefits.Offline(profile, minutes)
	return minutes
		* (if Benefits.Owns(profile, "OfflinePlus") then Config.Gamepasses.OfflinePlus.OfflineMultiplier else 1)
		* (if Benefits.Owns(profile, "VIPPack") then Config.Gamepasses.VIPPack.OfflineMultiplier else 1)
end
function Benefits.CoinGrant(rate, seconds)
	if not CashMath.Finite(rate) or rate < 0 or not CashMath.Finite(seconds) or seconds < 0 then
		return nil
	end
	return math.clamp(
		math.floor(CashMath.Product(rate, seconds, Config.CoinGrantMax)),
		Config.CoinGrantMin,
		Config.CoinGrantMax
	)
end
return Benefits
