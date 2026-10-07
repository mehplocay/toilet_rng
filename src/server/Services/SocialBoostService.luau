local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.SocialBoosts)
local Rules = require(Shared.SocialBoostRules)
local Copy = require(Shared.CommerceProfile).Copy
local Service = {}

function Service.Start(data, limiter, remotes, sync)
	local self = { Sessions = {} }
	data.Social = self
	local function present(player, session)
		return player.Parent == Players and self.Sessions[player] == session and not data.Stopping
	end
	function self:Attach(player, profile)
		local session = self.Sessions[player]
		if session then
			profile.SocialRuntime = Copy(session.Runtime)
		end
	end
	local function publish(player, session, update)
		if not present(player, session) then
			return
		end
		local profile = data:Get(player) -- Settle the previous factors before changing cached state.
		update(session.Runtime)
		if profile then
			self:Attach(player, profile)
			sync(player)
		end
	end
	function self:CheckGroup(player, manual)
		local session = self.Sessions[player]
		if not session or session.GroupBusy or os.time() < session.Runtime.GroupNextCheck then
			return
		end
		session.GroupBusy = true
		session.Runtime.GroupNextCheck = os.time() + Config.GroupCheckSeconds
		session.NextGroup = os.time() + Config.GroupRefreshSeconds
		local ok, member = false, false
		local studio = RunService:IsStudio() and not Config.StudioLookups
		if not studio then
			ok, member = pcall(function()
				return player:IsInGroupAsync(Config.GroupId)
			end)
		end
		if not present(player, session) then
			return
		end
		local unlocked = not session.Runtime.GroupMember and Rules.GroupResult(ok, member)
		publish(player, session, function(runtime)
			runtime.GroupMember = Rules.GroupResult(ok, member)
			runtime.GroupStatus = if studio
				then "Studio"
				elseif not ok then "Unavailable"
				elseif runtime.GroupMember then "Member"
				else "NotMember"
		end)
		session.GroupBusy = false
		if unlocked or manual then
			remotes.Result:FireClient(player, "CheckGroup", {
				Success = session.Runtime.GroupMember,
				Message = if unlocked
					then "Group bonus unlocked!"
					elseif session.Runtime.GroupMember then "Group bonus is active."
					elseif studio then "Group checks are disabled in Studio."
					elseif not ok then "Group check unavailable. No group bonus until verification succeeds."
					else "Join Dreadlight Studio on Roblox, then check again. Roblox may require a rejoin to refresh membership.",
			})
		end
	end
	local function refreshFriends(player, session)
		local names = {}
		for other, pair in pairs(session.Pairs) do
			if other.Parent == Players and self.Sessions[other] and pair.Friends then
				table.insert(names, other.Name)
			end
		end
		table.sort(names)
		while #names > Config.MaxFriends do
			table.remove(names)
		end
		publish(player, session, function(runtime)
			runtime.FriendNames, runtime.FriendCount = names, #names
		end)
	end
	local function checkPair(a, sa, b, sb, pair)
		if pair.Busy or os.time() < pair.NextCheck then
			return
		end
		pair.Busy, pair.NextCheck = true, os.time() + Config.FriendRetrySeconds
		local ok, friends = false, false
		if not RunService:IsStudio() or Config.StudioLookups then
			ok, friends = pcall(function()
				return a:IsFriendsWithAsync(b.UserId)
			end)
		end
		if not present(a, sa) or not present(b, sb) then
			return
		end
		pair.Busy, pair.Friends, pair.Resolved = false, ok and friends == true, ok
		refreshFriends(a, sa)
		refreshFriends(b, sb)
	end
	function self:Load(player)
		if self.Sessions[player] then
			return
		end
		local session = {
			Runtime = {
				GroupMember = false,
				GroupStatus = "Checking",
				GroupNextCheck = 0,
				FriendCount = 0,
				FriendNames = {},
			},
			Pairs = {},
			NextGroup = 0,
			JoinedAt = os.time(),
			Flushes = 0,
		}
		self.Sessions[player] = session
		local profile = data:Get(player)
		if profile then
			self:Attach(player, profile)
		end
		task.spawn(function()
			self:CheckGroup(player, false)
		end)
		for other, otherSession in pairs(self.Sessions) do
			if other ~= player then
				local pair = { Friends = false, Resolved = false, Busy = false, NextCheck = 0 }
				session.Pairs[other], otherSession.Pairs[player] = pair, pair
				task.spawn(checkPair, player, session, other, otherSession, pair)
			end
		end
		task.spawn(function()
			for attempt = 1, Config.JoinDataAttempts do
				if not present(player, session) then
					return
				end
				local ok, join = pcall(function()
					return player:GetJoinData()
				end)
				if not present(player, session) then
					return
				end
				local referrer = ok and Rules.Referrer(join, player.UserId)
				if referrer then
					session.Referrer = referrer
					return
				end
				if attempt < Config.JoinDataAttempts then
					task.wait(Config.JoinDataRetrySeconds)
				end
			end
		end)
	end
	function self:Flushed(player)
		local session = self.Sessions[player]
		if session then
			session.Flushes = math.min(Config.InviteFlushes, session.Flushes + 1)
		end
	end
	function self:Qualify(player, session)
		if not present(player, session) or not Rules.Qualified(session, os.time()) then
			return
		end
		local inviter = Players:GetPlayerByUserId(session.Referrer)
		if not inviter or not self.Sessions[inviter] or data.Saving[inviter] then
			return
		end
		local profile = data:Get(inviter)
		if not profile then
			return
		end
		local replacement = Copy(profile)
		local awarded, reason = Rules.Award(replacement, inviter.UserId, player.UserId, os.time())
		if not awarded then
			if reason == "Duplicate" or reason == "HistoryFull" then
				session.Done = true
			end
			return
		end
		-- Dedupe and timer commit in the SAME profile transaction. No reward is spendable before save.
		session.Done = true
		if data:ReplaceAndSave(inviter, profile, replacement) then
			sync(inviter)
			remotes.Result:FireClient(
				inviter,
				"InviteReward",
				{ Success = true, Message = "Invite reward unlocked! Your coin boost has been extended." }
			)
		else
			-- Retry against the durable record after the inviter reloads. An ambiguous
			-- committed write remains protected by its saved invitee ID.
			session.Done = false
		end
	end
	function self:Tick()
		for player, session in pairs(self.Sessions) do
			if not session.GroupBusy and os.time() >= session.NextGroup then
				task.spawn(function()
					self:CheckGroup(player, false)
				end)
			end
			for other, pair in pairs(session.Pairs) do
				local otherSession = self.Sessions[other]
				if otherSession and not pair.Resolved and not pair.Busy and os.time() >= pair.NextCheck then
					task.spawn(checkPair, player, session, other, otherSession, pair)
				end
			end
			if Rules.Qualified(session, os.time()) then
				task.spawn(function()
					self:Qualify(player, session)
				end)
			end
			local profile = data:Get(player)
			if profile then
				local active = profile.Social.InviteExpires > os.time()
				if session.InviteActive ~= active then
					session.InviteActive = active
					sync(player)
				end
			end
		end
	end
	remotes.CheckGroup.OnServerEvent:Connect(function(player, ...)
		if not limiter:Allow(player, "CheckGroup") or select("#", ...) ~= 0 then
			return
		end
		self:CheckGroup(player, true)
	end)
	-- The client only asks to open Roblox's modal. There is deliberately no reward/result remote.
	remotes.PromptInvite.OnServerEvent:Connect(function(player, ...)
		if not limiter:Allow(player, "PromptInvite") or select("#", ...) ~= 0 or not data:Get(player) then
			return
		end
		remotes.Result:FireClient(player, "PromptInvite", { Success = true })
	end)
	Players.PlayerRemoving:Connect(function(player)
		local session = self.Sessions[player]
		self.Sessions[player] = nil
		if not session then
			return
		end
		for other in pairs(session.Pairs) do
			local otherSession = self.Sessions[other]
			if otherSession then
				otherSession.Pairs[player] = nil
				refreshFriends(other, otherSession)
			end
		end
	end)
	task.spawn(function()
		while not data.Stopping do
			task.wait(Config.TickSeconds)
			self:Tick()
		end
	end)
	return self
end
return Service
