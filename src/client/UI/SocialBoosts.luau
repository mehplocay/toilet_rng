local C = require(script.Parent.Components)
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
function UI.Create(parent, remotes)
	local frame = C.New("Frame", parent, {
		Name = "SocialBoosts",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = -1,
	})
	C.New("UIListLayout", frame, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	local order = 0
	local function text(name, value, height)
		order += 1
		local label = C.BodyText(frame, value, UDim2.new(1, -12, 0, height))
		label.Name, label.LayoutOrder, label.TextXAlignment = name, order, Enum.TextXAlignment.Left
		return label
	end
	local function button(name, value, callback)
		order += 1
		local control =
			C.Button(frame, value, UDim2.new(1, -12, 0, 44), nil, callback, C.Blue, { Name = name, TextSize = 18 })
		control.LayoutOrder = order
		return control
	end
	text("SocialHeading", "Social boosts - FREE coin bonuses", 32)
	text(
		"SocialExplanation",
		"These bonuses multiply with all other coin boosts. No coin multiplier cap. Luck and speed stay the same.",
		72
	)
	local group = text("GroupStatus", "Group bonus: checking...", 36)
	text(
		"GroupInstructions",
		string.format(
			"Join our group: %s (ID %d).\nFind it on roblox.com/groups, join, then press Check again.\n+%s coins while you remain a member. Roblox may require a rejoin to refresh membership.",
			Config.GroupName,
			Config.GroupId,
			percent(Config.GroupBonus)
		),
		160
	)
	local state, receivedAt = {}, os.clock()
	local checkUntil, inviteUntil, waitingUntil = 0, 0, 0
	local check = button("CheckGroup", "Check again", function()
		if os.clock() < checkUntil then
			return
		end
		checkUntil = os.clock() + Config.GroupCheckSeconds
		group.Text = "Checking group membership..."
		remotes.CheckGroup:FireServer()
	end)
	local friends = text("FriendStatus", "Friends: 0 in this server", 42)
	text(
		"FriendsExplanation",
		string.format(
			"+%s coins per friend in your server, up to +%s with %d friends. Updates when friends join or leave.",
			percent(Config.FriendBonus),
			percent(Config.FriendBonus * Config.MaxFriends),
			Config.MaxFriends
		),
		88
	)
	local names = text("FriendNames", "No friends in this server yet.", 96)
	local invite = text("InviteStatus", "Invite bonus: inactive", 42)
	text(
		"InviteExplanation",
		string.format(
			"Invite friends for +%s coins for %d minutes per qualified invite. Your invitee must join through a Roblox invitation, stay %d minutes and flush %d times in that visit. You must be in their server when they qualify.",
			percent(Config.InviteBonus),
			Config.InviteSeconds / 60,
			Config.InviteStaySeconds / 60,
			Config.InviteFlushes
		),
		176
	)
	text(
		"InviteLimits",
		string.format(
			"Once ever per invited player. Up to %d rewards per UTC day and %d total. Duration stacks up to %d hours; the timer continues offline. Opening or sending an invite alone gives no reward.",
			Config.InviteDailyLimit,
			Config.InviteHistoryLimit,
			Config.InviteMaxSeconds / 3600
		),
		144
	)
	local feedback = text("InviteFeedback", "Invites depend on your Roblox settings and device.", 64)
	local promptOpen, alive = false, true
	local inviteButton = button("InviteFriends", "Invite friends", function()
		if promptOpen or os.clock() < inviteUntil then
			return
		end
		inviteUntil, waitingUntil = os.clock() + Config.InvitePromptSeconds, os.clock() + Config.InvitePromptTimeout
		feedback.Text = "Checking invite availability..."
		remotes.PromptInvite:FireServer()
	end)
	local closeConnection
	local results = remotes.Result.OnClientEvent:Connect(function(action, payload)
		if action == "CheckGroup" then
			group.Text = payload.Message or "Group check unavailable."
		end
		if action ~= "PromptInvite" or payload.Success ~= true or waitingUntil <= os.clock() then
			return
		end
		waitingUntil = 0
		if promptOpen then
			return
		end
		promptOpen = true
		task.spawn(function()
			local player = game:GetService("Players").LocalPlayer
			local social = game:GetService("SocialService")
			local ok, canInvite = pcall(function()
				return social:CanSendGameInviteAsync(player)
			end)
			if not alive then
				return
			end
			if not ok or canInvite ~= true then
				promptOpen = false
				feedback.Text = "Invites are unavailable for your account or device right now."
				return
			end
			if not closeConnection then
				closeConnection = social.GameInvitePromptClosed:Connect(function(closedPlayer)
					if closedPlayer == player then
						promptOpen = false
						feedback.Text = "Invite closed. Rewards unlock after a qualifying friend joins and plays."
					end
				end)
			end
			local shown = pcall(function()
				social:PromptGameInvite(player)
			end)
			if not alive then
				return
			end
			if shown then
				feedback.Text = "Invite your friends using Roblox's invite window."
			else
				promptOpen = false
				feedback.Text = "The invite window could not open. Try again later."
			end
		end)
	end)
	local function updateTimers()
		local elapsed = os.clock() - receivedAt
		check.Interactable = os.clock() >= checkUntil
		check.Text = if check.Interactable
			then "Check again"
			else "Check again in " .. math.ceil(checkUntil - os.clock()) .. "s"
		inviteButton.Interactable = not promptOpen and os.clock() >= inviteUntil and waitingUntil == 0
		inviteButton.Text = if promptOpen
			then "Invite window open"
			elseif os.clock() < inviteUntil then "Invite friends in " .. math.ceil(inviteUntil - os.clock()) .. "s"
			else "Invite friends"
		if waitingUntil > 0 and os.clock() >= waitingUntil then
			waitingUntil = 0
			feedback.Text = "Invite request timed out. Please try again."
		end
		local remaining = math.max(0, (state.InviteRemaining or 0) - elapsed)
		invite.Text = (
			if remaining > 0
				then "Invite bonus +" .. percent(Config.InviteBonus) .. " - " .. UI.Timer(remaining)
				else "Invite bonus: inactive"
		)
			.. string.format(
				"\n%d/%d rewards today%s",
				state.DailyCount or 0,
				Config.InviteDailyLimit,
				if state.HistoryFull then " - lifetime limit reached" else ""
			)
	end
	frame.Destroying:Connect(function()
		alive = false
		results:Disconnect()
		if closeConnection then
			closeConnection:Disconnect()
		end
	end)
	task.spawn(function()
		while alive do
			updateTimers()
			task.wait(1)
		end
	end)
	return {
		Frame = frame,
		Update = function(snapshot)
			state, receivedAt = snapshot or {}, os.clock()
			checkUntil = math.max(checkUntil, os.clock() + (state.GroupCheckRemaining or 0))
			group.Text = if state.GroupMember
				then "Group bonus +" .. percent(Config.GroupBonus) .. " - active"
				elseif state.GroupStatus == "Unavailable" then "Group lookup unavailable - bonus inactive"
				elseif state.GroupStatus == "Studio" then "Group checks disabled in Studio"
				else "Group bonus: join our group to unlock"
			friends.Text = string.format(
				"Friends +%s - %d in this server",
				percent((state.FriendCount or 0) * Config.FriendBonus),
				state.FriendCount or 0
			)
			names.Text = if #(state.FriendNames or {}) > 0
				then table.concat(state.FriendNames, ", ")
				else "No friends in this server yet."
			updateTimers()
		end,
	}
end
return UI
