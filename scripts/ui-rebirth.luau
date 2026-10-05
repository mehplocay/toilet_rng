do
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local config = H.Load("src/shared/Config/Rebirth")
	local ui = H.Load("src/client/UI/Rebirth").Create(root, remotes)
	local body, input = ui.Panel.ContentScroll.Body, H.Services.UserInputService
	local button = body.Confirm
	local state = {
		Coins = 98765,
		PendingCoins = 300,
		ToiletTier = 4,
		RunFlushes = config.RequiredFlushes,
		RebirthLevel = 0,
		Settings = {},
	}
	ui.Update(state)
	ui.Panel.Visible = true
	local click = { UserInputType = Enum.UserInputType.MouseButton1 }
	local function calls()
		local count = 0
		for _, call in ipairs(H.Calls) do
			if call.Name == "Rebirth" then
				count += 1
			end
		end
		return count
	end
	local before = calls()
	button.InputBegan:Fire(click)
	H.Advance(3)
	input.InputEnded:Fire(click)
	assert(calls() == before, "Holding without review could reset")
	button.Activated:Fire()
	assert(string.find(button.Text, "HOLD", 1, true))
	button.InputBegan:Fire(click)
	H.Advance(config.HoldSeconds - 0.1)
	input.InputEnded:Fire(click)
	H.Advance(1)
	assert(calls() == before, "Short hold committed")
	button.InputBegan:Fire(click)
	input.WindowFocusReleased:Fire()
	H.Advance(3)
	assert(calls() == before, "Focus loss retained destructive hold")
	button.Activated:Fire()
	button.InputBegan:Fire(click)
	ui.Panel.Visible = false
	H.Advance(3)
	assert(calls() == before)
	ui.Panel.Visible = true
	button.Activated:Fire()
	button.InputBegan:Fire(click)
	button.MouseLeave:Fire()
	H.Advance(3)
	assert(calls() == before)
	local touch = { UserInputType = Enum.UserInputType.Touch }
	button.InputBegan:Fire(touch)
	H.Advance(config.HoldSeconds + 0.1)
	assert(calls() == before + 1 and H.Calls[#H.Calls].Args[1] == 0 and H.Calls[#H.Calls].Count == 1)
	button.Activated:Fire()
	button.InputBegan:Fire(touch)
	H.Advance(5)
	assert(calls() == before + 1 and button.Text == "SAVING...")
	remotes.Result.OnClientEvent:Fire("Rebirth", { Success = false, Message = "Please wait." })
	button.Activated:Fire()
	local pad = { KeyCode = Enum.KeyCode.ButtonA }
	H.Services.GuiService.SelectedObject = button
	input.InputBegan:Fire(pad)
	H.Advance(config.HoldSeconds + 0.1)
	assert(calls() == before + 2, "Selected gamepad hold failed")
	H.Advance(config.ResponseTimeout + 0.1)
	assert(calls() == before + 2 and button.Text ~= "SAVING...", "Timeout retried reset or trapped the UI")
	assert(H.Calls[#H.Calls].Name == "State", "Timeout did not request authoritative state")
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
	state.RunFlushes = config.RequiredFlushes
	ui.Update(state)
	for _, size in ipairs(H.Viewports) do
		root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
		root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		H.Layout(root)
		assert(button.AbsoluteSize.Y >= 44 and button.AbsoluteSize.X >= 44)
		assert(body.RESETS.AbsolutePosition.X + body.RESETS.AbsoluteSize.X < body.KEEPS.AbsolutePosition.X)
		assert(button.AbsolutePosition.Y >= body.TokenPerks.AbsolutePosition.Y + body.TokenPerks.AbsoluteSize.Y)
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
	local after = calls()
	input.InputBegan:Fire(pad)
	H.Advance(3)
	assert(calls() == after, "Destroyed panel kept input listeners")
	H.Services.GuiService.SelectedObject = nil
	print(
		"Rebirth UI passed: review/hold, mouse/touch/gamepad, early release, focus/close/leave cancellation, pending lock, max state, celebration expiry, two-column mobile layout and cleanup"
	)
end
