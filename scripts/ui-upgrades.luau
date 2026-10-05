do
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local config = H.Load("src/shared/Config/Upgrades")
	local panel = H.Load("src/client/UI/Upgrades").Create(root, remotes)
	local body = panel.Panel.ContentScroll.Body
	local tracks = body.PermanentUpgradeTracks
	local tab = body:FindFirstChild("Coin Upgrades", true)
	assert(tab and not tracks.Visible)
	tab.Activated:Fire()
	assert(tracks.Visible)
	local state = {
		Coins = 100,
		ToiletTier = 1,
		DisplaySlots = 3,
		Upgrades = {},
		UpgradeStats = { Cooldown = 1.5, AutoInterval = 3, OfflineMinutes = 240, LuckCapped = false },
	}
	panel.Update(state)
	local before = #H.Calls
	tracks.CashBoost.Buy.Activated:Fire()
	assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "BuyUpgrade" and H.Calls[#H.Calls].Count == 2)
	assert(H.Calls[#H.Calls].Args[1] == "CashBoost" and H.Calls[#H.Calls].Args[2] == 0)
	state.Upgrades.CashBoost = 1
	panel.Update(state)
	assert(tracks.CashBoost.Level.Text == "LEVEL 1 / 10" and tracks.CashBoost.Price.Text == "90 Coins")
	tracks.CashBoost.Buy.Activated:Fire()
	assert(H.Calls[#H.Calls].Args[2] == 1, "Purchase callback retained an old level")
	state.Coins = 0
	panel.Update(state)
	before = #H.Calls
	tracks.CashBoost.Buy.Activated:Fire()
	assert(#H.Calls == before and not tracks.CashBoost.Buy.Interactable)
	state.Coins = 9e15
	for _, track in ipairs(config.Tracks) do
		state.Upgrades[track.Id] = track.MaxLevel
	end
	state.DisplaySlots = 10
	state.UpgradeStats = { Cooldown = 0.4, AutoInterval = 0.4, OfflineMinutes = 480, LuckCapped = true }
	panel.Update(state)
	assert(string.find(tracks.LuckBoost.Effect.Text, "5x CAP REACHED", 1, true))
	for _, track in ipairs(config.Tracks) do
		assert(not tracks[track.Id].Buy.Interactable and tracks[track.Id].Buy.Text == "Max")
	end
	panel.Panel.Visible = true
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		for _, track in ipairs(config.Tracks) do
			local card = tracks[track.Id]
			assert(card.Buy.AbsoluteSize.Y >= 44 and card.Buy.AbsoluteSize.X >= 44)
			assert(card.AbsoluteSize.X >= 200 and card.AbsoluteSize.X <= tracks.AbsoluteSize.X)
			assert(card.Buy.AbsolutePosition.X >= card.AbsolutePosition.X)
			assert(
				card.Buy.AbsolutePosition.X + card.Buy.AbsoluteSize.X <= card.AbsolutePosition.X + card.AbsoluteSize.X
			)
			assert(
				card.Buy.AbsolutePosition.Y + card.Buy.AbsoluteSize.Y <= card.AbsolutePosition.Y + card.AbsoluteSize.Y
			)
		end
		H.Snapshot(root, "upgrade-tracks-" .. size[1] .. "x" .. size[2])
	end
	local reveal = H.Load("src/client/UI/Reveal").Create(root, { SetHintVisible = function() end })
	reveal(H.Load("src/shared/Config/Items")[1], false, 0.4)
	assert(root.FlushReveal.Visible)
	H.Advance(0.33)
	assert(not root.FlushReveal.Visible, "Reveal exceeded the minimum cooldown")
	reveal(H.Load("src/shared/Config/Items")[1], true, 1.5)
	H.Advance(0.16)
	assert(not root.FlushReveal.Visible, "Quick reveal ignored skip preference")
	print(
		"Upgrade UI passed: tabs, latest-level purchases, affordability/max/cap states, desktop/mobile cards and bounded reveal timing"
	)
end
