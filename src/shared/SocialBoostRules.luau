-- Pure rules: no platform calls, client claims, or yielding in currency mutations.
local Config = require(if script then script.Parent.Config.SocialBoosts else "./Config/SocialBoosts")
local Rules = {}
local function integer(value, maximum)
	return type(value) == "number" and value == value and value >= 0 and value <= maximum and value % 1 == 0
end
function Rules.UserId(value)
	return integer(value, Config.MaxUserId) and value > 0
end
function Rules.Sanitize(raw, now)
	now = now or os.time()
	local result =
		{ Version = Config.Version, InviteExpires = 0, Rewarded = {}, Day = 0, DailyCount = 0, HistoryFull = false }
	if type(raw) ~= "table" then
		return result
	end
	result.InviteExpires = if integer(raw.InviteExpires, Config.MaxTimestamp)
		then math.min(raw.InviteExpires, now + Config.InviteMaxSeconds)
		else 0
	result.Day = if integer(raw.Day, math.floor(Config.MaxTimestamp / Config.SecondsPerDay)) then raw.Day else 0
	result.DailyCount = if integer(raw.DailyCount, Config.InviteDailyLimit)
		then raw.DailyCount
		else Config.InviteDailyLimit
	result.HistoryFull = raw.HistoryFull == true
	local seen = {}
	if type(raw.Rewarded) == "table" then
		-- Inspect a bounded number of entries; fail closed instead of evicting IDs.
		local inspected = 0
		for key, id in pairs(raw.Rewarded) do
			inspected += 1
			if inspected > Config.InviteHistoryLimit then
				result.HistoryFull = true
				break
			end
			if integer(key, Config.InviteHistoryLimit) and key > 0 and Rules.UserId(id) and not seen[id] then
				seen[id] = true
				table.insert(result.Rewarded, id)
			else
				result.HistoryFull = true
			end
		end
		table.sort(result.Rewarded)
		if raw.Rewarded[Config.InviteHistoryLimit + 1] ~= nil then
			result.HistoryFull = true
		end
	elseif raw.Rewarded ~= nil or raw.Version == Config.Version then
		result.HistoryFull = true
	end
	result.HistoryFull = result.HistoryFull or #result.Rewarded >= Config.InviteHistoryLimit
	return result
end
function Rules.GroupResult(ok, member)
	return ok == true and member == true
end
function Rules.Base(profile, offline)
	local runtime = not offline and profile and profile.SocialRuntime
	if not runtime then
		return 1
	end
	local count = if integer(runtime.FriendCount, Config.MaxFriends) then runtime.FriendCount else 0
	return (if runtime.GroupMember == true then 1 + Config.GroupBonus else 1) * (1 + count * Config.FriendBonus)
end
function Rules.Multiplier(profile, now)
	local expires = profile and profile.Social and profile.Social.InviteExpires or 0
	if expires <= 0 then
		return Rules.Base(profile)
	end
	return Rules.Base(profile) * (if expires > (now or os.time()) then 1 + Config.InviteBonus else 1)
end
function Rules.Average(profile, startAt, endAt, offline)
	local expires = profile.Social and profile.Social.InviteExpires or 0
	local active = math.clamp(expires - startAt, 0, math.max(0, endAt - startAt))
	return Rules.Base(profile, offline) * (1 + Config.InviteBonus * active / math.max(1, endAt - startAt))
end
function Rules.Referrer(joinData, inviteeId)
	local id = if type(joinData) == "table" then joinData.ReferredByPlayerId else nil
	return if Rules.UserId(id) and id ~= inviteeId then id else nil
end
function Rules.Qualified(candidate, now)
	return candidate ~= nil
		and not candidate.Done
		and candidate.Referrer ~= nil
		and now - candidate.JoinedAt >= Config.InviteStaySeconds
		and candidate.Flushes >= Config.InviteFlushes
end
function Rules.Award(profile, inviterId, inviteeId, now)
	if not Rules.UserId(inviterId) or not Rules.UserId(inviteeId) or inviterId == inviteeId then
		return false, "Invalid"
	end
	local social = profile.Social
	if not social or social.HistoryFull or #social.Rewarded >= Config.InviteHistoryLimit then
		return false, "HistoryFull"
	end
	if table.find(social.Rewarded, inviteeId) then
		return false, "Duplicate"
	end
	local day = math.floor(now / Config.SecondsPerDay)
	-- A backward clock must not reset the daily budget.
	if day > social.Day then
		social.Day, social.DailyCount = day, 0
	end
	if social.DailyCount >= Config.InviteDailyLimit then
		return false, "DailyLimit"
	end
	if social.InviteExpires >= now + Config.InviteMaxSeconds then
		return false, "DurationLimit"
	end
	table.insert(social.Rewarded, inviteeId)
	social.DailyCount += 1
	social.HistoryFull = #social.Rewarded >= Config.InviteHistoryLimit
	social.InviteExpires =
		math.min(now + Config.InviteMaxSeconds, math.max(now, social.InviteExpires) + Config.InviteSeconds)
	return true
end
function Rules.Snapshot(profile, now)
	now = now or os.time()
	local runtime, social = profile.SocialRuntime or {}, profile.Social or Rules.Sanitize(nil, now)
	return {
		GroupMember = runtime.GroupMember == true,
		GroupStatus = runtime.GroupStatus or "Checking",
		GroupCheckRemaining = math.max(0, (runtime.GroupNextCheck or 0) - now),
		FriendCount = runtime.FriendCount or 0,
		FriendNames = table.clone(runtime.FriendNames or {}),
		InviteExpires = social.InviteExpires,
		InviteRemaining = math.max(0, social.InviteExpires - now),
		DailyCount = if math.floor(now / Config.SecondsPerDay) > social.Day then 0 else social.DailyCount,
		RewardedCount = #social.Rewarded,
		HistoryFull = social.HistoryFull,
		Multiplier = Rules.Multiplier(profile, now),
	}
end
return Rules
