-- Pure entitlement math. Passes are written only by server marketplace verification.
local Config = require(if script then script.Parent.Config.Monetization else "./Config/Monetization")
local Cash = require(if script then script.Parent.Config.Cash else "./Config/Cash")
local Benefits = {}
function Benefits.Owns(profile, key)
	local passes = profile and (if profile.Monetization then profile.Monetization.Passes else profile.OwnedPasses)
	return passes ~= nil and passes[key] == true
end
function Benefits.Cash(profile, base)
	local factor = 1
	for key, pass in pairs(Config.Gamepasses) do
		if pass.CashMultiplier and Benefits.Owns(profile, key) then
			assert(pass.CashMultiplier >= 1 and pass.CashMultiplier < math.huge, "Invalid paid cash factor")
			factor = math.min(Cash.PaidCap, factor * math.min(Cash.PaidCap, pass.CashMultiplier))
		end
	end
	return math.min(Cash.FreeCap, base) * factor
end
function Benefits.Offline(profile, minutes)
	return minutes
		* (if Benefits.Owns(profile, "OfflinePlus") then Config.Gamepasses.OfflinePlus.OfflineMultiplier else 1)
end
function Benefits.Slots(profile)
	return if Benefits.Owns(profile, "ExtraSlots") then Config.Gamepasses.ExtraSlots.Slots else 0
end
function Benefits.CoinGrant(rate, seconds)
	if type(rate) ~= "number" or rate ~= rate or rate < 0 or rate == math.huge then
		return nil
	end
	return math.clamp(math.floor(rate * seconds), Config.CoinGrantMin, Config.CoinGrantMax)
end
return Benefits
