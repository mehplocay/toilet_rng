do
	local SocialUI = H.Load("src/client/UI/SocialBoosts")
	local social = { GameInvitePromptClosed = H.Signal() }
	function social:CanSendGameInviteAsync()
		return true
	end
	function social:PromptGameInvite() end
	H.Services.SocialService = social
	local previousPlayer = H.Services.Players.LocalPlayer
	H.Services.Players.LocalPlayer = { UserId = 101 }
	for _, size in ipairs(H.Viewports) do
		local root, remotes = H.Root(size[1], size[2]), H.Remotes()
		local passes = H.Load("src/client/UI/Passes").Create(root, remotes)
		passes.OpenSocial()
		passes.Update({ Settings = {}, OwnedPasses = {}, Social = { FriendCount = 11, InviteRemaining = 1800 } })
		H.StartTasks()
		H.Layout(root)
		assert(not passes.Panel:FindFirstChild("SocialBoosts", true), "Verbose social panel remains in Passes")
		local scroll = passes.Panel.ContentScroll.Body:FindFirstChildWhichIsA("ScrollingFrame")
		local offers = scroll:FindFirstChild("OfferGrid", true)
		assert(
			math.abs(offers.AbsolutePosition.Y - scroll.AbsolutePosition.Y) < 2,
			string.format(
				"Passes content has a top gap: offers=%d scroll=%d",
				offers.AbsolutePosition.Y,
				scroll.AbsolutePosition.Y
			)
		)
		local invite = passes.Panel:FindFirstChild("InviteFriends", true)
		assert(invite.Visible and invite.Text == "Invite friends for extra coins")
		assert(invite.AbsoluteSize.Y == 44 and invite.AbsoluteSize.X > 0 and invite.AbsoluteSize.X <= size[1])
		assert(invite.AbsolutePosition.Y >= passes.Panel.AbsolutePosition.Y)
		local refresh = passes.Panel:FindFirstChild("Refresh passes", true)
		assert(
			math.abs(invite.AbsolutePosition.Y - refresh.AbsolutePosition.Y) < 2,
			"Invite text is not on refresh row"
		)
		assert(SocialUI.ChipText({ FriendCount = 3, InviteRemaining = 1 }, 2):find("Social boosts", 1, true))
		H.Snapshot(root, string.format("social-compact-%dx%d", size[1], size[2]))
		passes.Panel:Destroy()
		root:Destroy()
	end
	H.Services.Players.LocalPlayer = previousPlayer
	print("Social UI: compact invite row, no social text panel and 12 viewports passed")
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
		local ui = H.Load("src/client/UI/Passes").Create(root, remotes)
		H.StartTasks()
		local checksBefore = social.Checks
		local button = ui.Panel:FindFirstChild("InviteFriends", true)
		assert(
			button.Visible == (mode ~= "restricted" and mode ~= "lookup-error"),
			"Invite capability visibility mismatch"
		)
		local before = #H.Calls
		remotes.Result.OnClientEvent:Fire("PromptInvite", { Success = true })
		assert(social.Checks == checksBefore, "Unsolicited acknowledgement opened a modal")
		if button.Visible then
			button.Activated:Fire()
			button.Activated:Fire()
			assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "PromptInvite")
			remotes.Result.OnClientEvent:Fire("PromptInvite", { Success = true })
			H.StartTasks()
			assert(social.Checks == checksBefore + 1)
			assert(social.Prompts == (if mode == "allowed" or mode == "prompt-error" then 1 else 0))
		else
			button.Activated:Fire()
			assert(#H.Calls == before, "Unavailable invite control sent a request")
		end
		if mode == "allowed" then
			social.GameInvitePromptClosed:Fire(H.Services.Players.LocalPlayer, { 123, 456 })
		end
		assert(#H.Calls == before + (if button.Visible then 1 else 0), "Modal/recipient results sent a reward claim")
		ui.Panel:Destroy()
		root:Destroy()
	end
	H.Services.SocialService = previous
	print(
		"Social invite UI: hidden capability failures, server acknowledgement gate, prompt errors and no reward claims passed"
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
