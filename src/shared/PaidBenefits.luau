-- Pure entitlement math. Passes are written only by server marketplace verification.
local Config = require(if script then script.Parent.Config.Monetization else "./Config/Monetization")
local Benefits = {}
function Benefits.Owns(profile, key)
	local passes = profile and (if profile.Monetization then profile.Monetization.Passes else profile.OwnedPasses)
	return passes ~= nil and passes[key] == true
end
function Benefits.Cash(profile, base)
	local factor = 1
	for _, key in ipairs({ "DoubleCash", "VIPPack" }) do
		if Benefits.Owns(profile, key) then
			factor *= Config.Gamepasses[key].CashMultiplier
		end
	end
	return math.min(Config.CashMultiplierCap, base * factor)
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
