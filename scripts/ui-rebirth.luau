H.CheckRebirthClick()
do
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local config = H.Load("src/shared/Config/Rebirth")
	local ui = H.Load("src/client/UI/Rebirth").Create(root, remotes)
	local body = ui.Panel.ContentScroll.Body
	assert(body.CashCaps.Text == H.Load("src/shared/Config/Cash").Explanation)
	local button = body.Confirm
	local state = {
		Coins = config.Levels[1].RequiredCoins,
		PendingCoins = 300,
		ToiletTier = 4,
		RunFlushes = config.RequiredFlushes,
		RebirthLevel = 0,
		Settings = {},
	}
	for count = 0, 15 do
		state.RebirthLevel = count
		ui.Update(state)
		local bonus = config.Levels[count]
		if bonus then
			assert(body.PermanentBonuses.Text:find("+" .. math.round(bonus.Cash * 100) .. "% cash", 1, true))
		end
		local preview = config.Levels[count + 1]
		if preview then
			assert(body.NextBonus.Text:find("+" .. math.round(preview.Cash * 100) .. "% cash", 1, true))
		end
		for _, perk in ipairs((preview or bonus).Perks) do
			assert(body.TokenPerks.Text:find(perk, 1, true), "Reward missing from preview")
		end
	end
	state.RebirthLevel = 0
	ui.Update(state)
	assert(body.CoinGate.Text == "4M / 4M Coins required" and button.Interactable)
	state.Coins -= 1
	ui.Update(state)
	assert(not button.Interactable, "Coin-short state enabled the irreversible reset")
	state.Coins += 1
	ui.Update(state)
	ui.Panel.Visible = true
	state = table.clone(state)
	state.RebirthLevel, state.RunFlushes, state.ToiletTier = 1, 0, 1
	ui.Update(state)
	remotes.Result.OnClientEvent:Fire("Rebirth", { Success = true, Level = 1 })
	assert(not ui.Panel.Visible and root.RebirthCelebration.Visible)
	H.Advance(3.1)
	assert(not root.RebirthCelebration.Visible)
	ui.Panel.Visible = true
	assert(not button.Interactable)
	state.RebirthLevel = #config.Levels
	state.RunFlushes, state.ToiletTier = 999999, 7
	ui.Update(state)
	assert(button.Text == "MAX REBIRTH" and not button.Interactable)
	state.RebirthLevel = 1
	state.Coins = config.Levels[2].RequiredCoins
	state.RunFlushes = config.RequiredFlushes
	ui.Update(state)
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		assert(button.AbsoluteSize.Y >= 44 and button.AbsoluteSize.X >= 44)
		assert(body.RESETS.AbsolutePosition.X + body.RESETS.AbsoluteSize.X < body.KEEPS.AbsolutePosition.X)
		for _, disclosure in ipairs({ body.RESETS, body.KEEPS, body.NextBonus, body.TokenPerks }) do
			assert(
				disclosure.Visible ~= false
					and button.AbsolutePosition.Y >= disclosure.AbsolutePosition.Y + disclosure.AbsoluteSize.Y
			)
		end
		assert(button.AbsolutePosition.Y + button.AbsoluteSize.Y <= body.AbsolutePosition.Y + body.AbsoluteSize.Y)
		H.Snapshot(root, "rebirth-" .. size[1] .. "x" .. size[2])
		local scroll = ui.Panel.ContentScroll
		scroll.CanvasPosition = Vector2.new(0, math.max(0, body.AbsoluteSize.Y - scroll.AbsoluteSize.Y))
		H.Layout(root)
		assert(button.AbsolutePosition.Y >= scroll.AbsolutePosition.Y)
		assert(button.AbsolutePosition.Y + button.AbsoluteSize.Y <= scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y)
		H.Snapshot(root, "rebirth-confirm-" .. size[1] .. "x" .. size[2])
		scroll.CanvasPosition = Vector2.new(0, 0)
	end
	ui.Panel:Destroy()
	print(
		"Rebirth UI passed: rewards/reset/keep previews above click button, max state, celebration expiry and desktop/mobile layout"
	)
end
