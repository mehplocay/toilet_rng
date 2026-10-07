do
	local config = H.Load("src/shared/Config/SocialBoosts")
	local SocialUI = H.Load("src/client/UI/SocialBoosts")
	for _, size in ipairs(H.Viewports) do
		local root, remotes = H.Root(size[1], size[2]), H.Remotes()
		local passes = H.Load("src/client/UI/Passes").Create(root, remotes)
		passes.OpenSocial()
		local names = {}
		for i = 1, config.MaxFriends do
			names[i] = "FriendUsername" .. i
		end
		local state = {
			Settings = {},
			OwnedPasses = {},
			Social = {
				GroupMember = true,
				GroupStatus = "Member",
				FriendCount = 11,
				FriendNames = names,
				InviteRemaining = 1800,
				DailyCount = 5,
				RewardedCount = 50,
			},
		}
		passes.Update(state)
		H.Layout(root)
		local section = passes.Panel:FindFirstChild("SocialBoosts", true)
		assert(section.Visible and section.FriendStatus.Text:find("55%%"))
		assert(section.GroupStatus.Text:find("active", 1, true) and section.InviteStatus.Text:find("30:00", 1, true))
		assert(section.FriendNames.Text:find("FriendUsername11", 1, true))
		assert(section.CheckGroup.AbsoluteSize.Y >= 44 and section.InviteFriends.AbsoluteSize.Y >= 44)
		assert(section.CheckGroup.AbsoluteSize.X > 0 and section.InviteFriends.AbsoluteSize.X <= size[1])
		local scroll = section.Parent.Parent
		local oldScroll = scroll.CanvasPosition
		scroll.CanvasPosition = { X = 0, Y = section.InviteFriends.AbsolutePosition.Y - scroll.AbsolutePosition.Y }
		H.Layout(root)
		assert(section.InviteFriends.AbsolutePosition.Y >= scroll.AbsolutePosition.Y)
		assert(
			section.InviteFriends.AbsolutePosition.Y + section.InviteFriends.AbsoluteSize.Y <= size[2],
			"Invite button is not reachable by scrolling"
		)
		scroll.CanvasPosition = oldScroll
		H.Layout(root)
		local before = #H.Calls
		section.CheckGroup.Activated:Fire()
		section.CheckGroup.Activated:Fire()
		-- The local control must close its own request window without waiting for state replication.
		assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "CheckGroup")
		state.Social = { GroupStatus = "Unavailable", FriendCount = 0, InviteRemaining = 0 }
		passes.Update(state)
		assert(
			section.GroupStatus.Text:find("inactive", 1, true) and section.InviteStatus.Text:find("inactive", 1, true)
		)
		assert(SocialUI.ChipText({ FriendCount = 3, InviteRemaining = 1 }, 2):find("Social boosts", 1, true))
		H.Snapshot(root, string.format("social-%dx%d", size[1], size[2]))
		passes.Panel:Destroy()
		root:Destroy()
	end
	print("Social UI: group/friends/expiry states, names, request cooldowns and 12 viewports passed")
end

do
	local config = H.Load("src/shared/Config/SocialBoosts")
	local previous = H.Services.SocialService
	for _, mode in ipairs({ "allowed", "restricted", "lookup-error", "prompt-error" }) do
		local social = { GameInvitePromptClosed = H.Signal(), Checks = 0, Prompts = 0 }
		function social:CanSendGameInviteAsync(player)
			assert(player == H.Services.Players.LocalPlayer)
			self.Checks += 1
			if mode == "lookup-error" then
				error("Unavailable")
			end
			return mode ~= "restricted"
		end
		function social:PromptGameInvite()
			self.Prompts += 1
			if mode == "prompt-error" then
				error("Unavailable")
			end
		end
		H.Services.SocialService = social
		local root, remotes = H.Root(390, 722), H.Remotes()
		local ui = H.Load("src/client/UI/SocialBoosts").Create(root, remotes)
		H.StartTasks()
		local before = #H.Calls
		remotes.Result.OnClientEvent:Fire("PromptInvite", { Success = true })
		assert(social.Checks == 0, "Unsolicited acknowledgement opened a modal")
		ui.Frame.InviteFriends.Activated:Fire()
		ui.Frame.InviteFriends.Activated:Fire()
		assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "PromptInvite")
		remotes.Result.OnClientEvent:Fire("PromptInvite", { Success = true })
		H.StartTasks()
		assert(social.Checks == 1)
		assert(social.Prompts == (if mode == "allowed" or mode == "prompt-error" then 1 else 0))
		if mode == "allowed" then
			social.GameInvitePromptClosed:Fire(H.Services.Players.LocalPlayer, { 123, 456 })
			assert(ui.Frame.InviteFeedback.Text:find("qualifying", 1, true))
		end
		assert(#H.Calls == before + 1, "Modal/recipient results sent a reward claim")
		H.Advance(config.InvitePromptSeconds + 1)
		H.ResumeTasks()
		assert(ui.Frame.InviteFriends.Interactable)
		ui.Frame:Destroy()
		root:Destroy()
	end
	H.Services.SocialService = previous
	print(
		"Social invite UI: native capability gate, errors, unsolicited results, cooldowns and untrusted closure passed"
	)
end

do
	local C = H.Load("src/client/UI/Components")
	local root = H.Root(1280, 684)
	local panel = C.Panel(root, "Upgrade cash check", C.Blue)
	local tracks = H.Load("src/client/UI/UpgradeTracks").Create(panel.ContentScroll.Body, H.Remotes())
	tracks.Update({ Coins = 0, Upgrades = {}, DisplaySlots = 3, UpgradeStats = { CashMultiplier = 1.518 } })
	assert(tracks.Frame.CashBoost.Effect.Text == H.Load("src/shared/NumberFormat").Compact(1.518, 2) .. "x coins")
	panel:Destroy()
	root:Destroy()
	print("Social upgrade UI: authoritative cash factor is displayed")
end
