-- Pure UTC calendar math shared by the server and the reward preview.
local Schedule = {}

function Schedule.Progress(lastClaimDay, streak, now, config)
	local today = math.floor(now / config.DaySeconds)
	if lastClaimDay >= today then
		return false, streak, (lastClaimDay + 1) * config.DaySeconds
	end
	local nextDay = if lastClaimDay == today - 1 then streak % #config.BaseCoins + 1 else 1
	return true, nextDay, (today + 1) * config.DaySeconds
end

function Schedule.Coins(day, tier, config)
	return config.BaseCoins[day] * config.TierMultipliers[tier]
end

return Schedule
