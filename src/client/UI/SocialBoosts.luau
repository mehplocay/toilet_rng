local Config = require(game.ReplicatedStorage.Shared.Config.SocialBoosts)
local UI = {}

local function percent(value)
	return string.format("%d%%", math.round(value * 100))
end

function UI.Timer(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

function UI.ChipText(social, elapsed)
	social = social or {}
	local count = social.FriendCount or 0
	local remaining = math.max(0, (social.InviteRemaining or 0) - (elapsed or 0))
	return string.format(
		"Friends +%s (%d)\n%s",
		percent(count * Config.FriendBonus),
		count,
		if remaining > 0
			then "Invite +" .. percent(Config.InviteBonus) .. " " .. UI.Timer(remaining)
			else "Social boosts"
	)
end

return UI
