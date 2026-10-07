local function socialServer()
	local e = server()
	e.Groups, e.Friends, e.Joins, e.GroupCalls, e.FriendCalls = {}, {}, {}, 0, 0
	local playerFactory = e.Player
	function e:Player(id)
		local player = playerFactory(self, id)
		function player:IsInGroupAsync(groupId)
			e.GroupCalls += 1
			assert(groupId == 711692751)
			if e.GroupLookup then
				return e.GroupLookup(self)
			end
			if e.GroupError then
				error("Lookup failed")
			end
			return e.Groups[id] == true
		end
		function player:IsFriendsWithAsync(otherId)
			e.FriendCalls += 1
			if e.FriendLookup then
				return e.FriendLookup(self, otherId)
			end
			return e.Friends[math.min(id, otherId) .. ":" .. math.max(id, otherId)] == true
		end
		function player:GetJoinData()
			return e.Joins[id] or {}
		end
		return player
	end
	function e:SocialAdvance(seconds)
		self.Now += seconds
		-- Existing lease tests cover backend ownership; these scenarios model successful autosaves.
		for player in pairs(self.Data.Profiles) do
			self.Data.LeaseExpires[player] = self.Now + 180
			local record = self.Store.Records["Player_" .. player.UserId]
			if record and record.Lock then
				record.Lock.Expires = self.Now + 180
			end
		end
	end
	return e
end
test("social group: join verification, cooldown, false/error fail closed and periodic refresh", function()
	local e = socialServer()
	e.Groups[501] = true
	local player, profile = e:Join(501)
	assert(profile.SocialRuntime.GroupMember and e.GroupCalls == 1)
	for _ = 1, 30 do
		e:Fire("CheckGroup", player)
	end
	assert(e.GroupCalls == 1)
	e:SocialAdvance(30)
	e.Groups[501] = false
	e:Fire("CheckGroup", player)
	assert(not profile.SocialRuntime.GroupMember and e.GroupCalls == 2)
	e:SocialAdvance(300)
	e.Groups[501] = true
	e.Data.Social:Tick()
	assert(profile.SocialRuntime.GroupMember)
	e:SocialAdvance(30)
	e.GroupError = true
	e:Fire("CheckGroup", player)
	assert(not profile.SocialRuntime.GroupMember and profile.SocialRuntime.GroupStatus == "Unavailable")
end)
test("social friends: each live pair is cached once; leave/rejoin updates both sides", function()
	local e = socialServer()
	e.Friends["501:502"] = true
	local a, pa = e:Join(501)
	local b, pb = e:Join(502)
	assert(pa.SocialRuntime.FriendCount == 1 and pb.SocialRuntime.FriendCount == 1 and e.FriendCalls == 1)
	e.Data.Social:Tick()
	assert(e.FriendCalls == 1)
	e.Players.PlayerRemoving:Fire(b)
	b.Parent = nil
	assert(pa.SocialRuntime.FriendCount == 0 and next(e.Data.Social.Sessions[a].Pairs) == nil)
	local replacement, pr = e:Join(502)
	assert(replacement ~= b and pr.SocialRuntime.FriendCount == 1 and e.FriendCalls == 2)
end)
test("social callbacks: late group/friend results cannot resurrect departed sessions", function()
	local e = socialServer()
	local a = e:Join(501)
	e.GroupLookup = function()
		coroutine.yield("group")
		return true
	end
	e:SocialAdvance(30)
	local pending = e:Spawn(function()
		e:Fire("CheckGroup", a)
	end)
	e.Players.PlayerRemoving:Fire(a)
	a.Parent = nil
	e:Resume(pending)
	assert(e.Data.Social.Sessions[a] == nil)
	e.GroupLookup = nil
	local b = e:Join(502)
	local thread
	e.FriendLookup = function()
		thread = coroutine.running()
		coroutine.yield("friends")
		return true
	end
	local c = e:Join(503)
	e.Players.PlayerRemoving:Fire(c)
	c.Parent = nil
	if coroutine.status(thread) == "suspended" then
		e:Resume(thread)
	end
	assert(e.Data:Get(b).SocialRuntime.FriendCount == 0)
end)

test("social rewards: UTC limit, full duration, immutable dedupe and expiry survive saves", function()
	local e = socialServer()
	local inviter, profile = e:Join(501)
	local rules = e:Load("src/shared/SocialBoostRules")
	local config = e:Load("src/shared/Config/SocialBoosts")
	for id = 1, config.InviteDailyLimit do
		assert(rules.Award(profile, 501, 1000 + id, e.Now))
	end
	assert(not rules.Award(profile, 501, 2000, e.Now))
	assert(e.Data:Save(inviter, false))
	e.Players.PlayerRemoving:Fire(inviter)
	inviter.Parent = nil
	inviter, profile = e:Join(501)
	assert(profile.Social.DailyCount == config.InviteDailyLimit and not rules.Award(profile, 501, 1001, e.Now))
	e:SocialAdvance(config.SecondsPerDay)
	assert(rules.Multiplier(profile, e.Now) == 1)
	assert(rules.Award(profile, 501, 2000, e.Now))
	profile.Social.InviteExpires = e.Now + config.InviteMaxSeconds
	assert(not rules.Award(profile, 501, 2001, e.Now))
	assert(#profile.Social.Rewarded == config.InviteDailyLimit + 1)
end)

test("social referral: inviter may return, invitee departure resets incomplete progress", function()
	local e = socialServer()
	local inviter = e:Join(501)
	e.Joins[502] = { ReferredByPlayerId = 501 }
	local invitee = e:Join(502)
	e.Data.Social.Sessions[invitee].Flushes = 20
	e.Players.PlayerRemoving:Fire(inviter)
	inviter.Parent = nil
	e:SocialAdvance(300)
	e.Data.Social:Tick()
	assert(not e.Data.Social.Sessions[invitee].Done)
	local returned = e:Join(501)
	e.Data.Social:Tick()
	assert(e.Data:Get(returned).Social.DailyCount == 1)
	e.Joins[503] = { ReferredByPlayerId = 501 }
	local incomplete = e:Join(503)
	e.Data.Social.Sessions[incomplete].Flushes = 19
	e.Players.PlayerRemoving:Fire(incomplete)
	incomplete.Parent = nil
	local rejoined = e:Join(503)
	e:SocialAdvance(300)
	e.Data.Social:Tick()
	assert(e.Data.Social.Sessions[rejoined].Flushes == 0 and e.Data:Get(returned).Social.DailyCount == 1)
end)

test("social invite save: in-flight save cannot replay an award", function()
	local e = socialServer()
	local inviter = e:Join(501)
	e.Joins[502] = { ReferredByPlayerId = 501 }
	local invitee = e:Join(502)
	local candidate = e.Data.Social.Sessions[invitee]
	candidate.Flushes = 20
	e:SocialAdvance(300)
	local writes = e.Store.Writes
	e.Store.Before = function()
		coroutine.yield("saving")
	end
	local pending = e:Spawn(function()
		e.Data.Social:Qualify(invitee, candidate)
	end)
	assert(e.Data:Get(inviter) == nil and candidate.Done)
	e.Data.Social:Qualify(invitee, candidate)
	assert(e.Store.Writes == writes)
	e.Store.Before = nil
	e:Resume(pending)
	assert(e.Data:Get(inviter).Social.DailyCount == 1 and #e.Store.Records.Player_501.Data.Social.Rewarded == 1)
end)

test("social invite save: ambiguous committed failure reloads its durable dedupe", function()
	local e = socialServer()
	local inviter = e:Join(501)
	e.Joins[502] = { ReferredByPlayerId = 501 }
	local invitee = e:Join(502)
	local candidate = e.Data.Social.Sessions[invitee]
	candidate.Flushes = 20
	e:SocialAdvance(300)
	e.Store.After = function()
		error("Response lost after commit")
	end
	local pending = e:Spawn(function()
		e.Data.Social:Qualify(invitee, candidate)
	end)
	while coroutine.status(pending) ~= "dead" do
		e:Resume(pending)
	end
	assert(e.Data.Closing[inviter] and not candidate.Done)
	e.Store.After = nil
	e.Players.PlayerRemoving:Fire(inviter)
	inviter.Parent = nil
	local returned, profile = e:Join(501)
	e.Data.Social:Qualify(invitee, candidate)
	assert(candidate.Done and profile.Social.DailyCount == 1 and #profile.Social.Rewarded == 1)
	assert(e.Data:Get(returned) == profile)
end)
test("social invite: modal and launch data grant nothing; qualified referral commits once across rejoin", function()
	local e = socialServer()
	local inviter = e:Join(501)
	e.Joins[502] = { ReferredByPlayerId = 501 }
	local invitee = e:Join(502)
	local candidate = e.Data.Social.Sessions[invitee]
	e:Fire("PromptInvite", inviter)
	assert(e.Data:Get(inviter).Social.InviteExpires == 0)
	for _ = 1, 19 do
		e:Fire("Flush", invitee)
		e:SocialAdvance(3)
	end
	e:SocialAdvance(300)
	e.Data.Social:Tick()
	assert(e.Data:Get(inviter).Social.InviteExpires == 0)
	e:Fire("Flush", invitee)
	e.Data.Social:Tick()
	local profile = e.Data:Get(inviter)
	assert(candidate.Done and profile.Social.InviteExpires == e.Now + 1800 and #profile.Social.Rewarded == 1)
	assert(e.Store.Records.Player_501.Data.Social.Rewarded[1] == 502)
	e.Data.Social:Tick()
	assert(profile.Social.DailyCount == 1)
	e.Players.PlayerRemoving:Fire(invitee)
	invitee.Parent = nil
	local again = e:Join(502)
	local nextCandidate = e.Data.Social.Sessions[again]
	nextCandidate.Flushes = 20
	e:SocialAdvance(300)
	e.Data.Social:Tick()
	assert(e.Data:Get(inviter).Social.DailyCount == 1 and nextCandidate.Done)
	local forged = e:Join(503)
	e.Joins[503] = { LaunchData = '{"inviter":501}' }
	assert(not e.Data.Social.Sessions[forged].Referrer)
end)
test("social data: migration drops persisted membership; admin reset/import preserve immutable rewards", function()
	local e = socialServer()
	local player, profile = e:Join(501)
	local migrated = e.Data.Sanitize({ SocialRuntime = { GroupMember = true, FriendCount = 11 } })
	assert(migrated.Social.InviteExpires == 0 and migrated.SocialRuntime == nil)
	local rules = e:Load("src/shared/SocialBoostRules")
	assert(rules.Award(profile, 501, 502, e.Now))
	for _, action in ipairs({ "Reset", "Import" }) do
		local result = e:Load("src/server/Admin/Mutations").Build(e.Data, profile, action, {}, e.Now, {})
		assert(result.Social.Rewarded[1] == 502 and result.Social.InviteExpires == profile.Social.InviteExpires)
	end
	assert(e.Data.Social.Sessions[player])
end)
