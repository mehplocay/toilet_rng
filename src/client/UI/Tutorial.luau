local Progress =
	require(if script then game.ReplicatedStorage.Shared.TutorialProgress else "../../shared/TutorialProgress")
local Tutorial = { NextStep = Progress.NextStep }
function Tutorial.Create(_player, remotes, hud, prompts, hooks)
	local C = require(script.Parent.Components)
	local Layout = require(script.Parent.Layout)
	hooks = hooks or {}
	local root = hud.Frame.Parent
	local oddsPanel = root:FindFirstChild("Luck details")
	local snapshot, destroyed, dismissed, replayPending = nil, false, false, false
	local lastStep, farewellUntil, requestAt = nil, 0, -math.huge
	local dismissAt = -math.huge
	local connections, highlight, highlightedButton = {}, nil, nil
	local card = C.New("Frame", root, { Name = "Tutorial", Visible = false, BackgroundColor3 = C.Navy, ZIndex = 90 })
	C.Round(card, C.Gold, 12, 2)
	local title = C.Text(card, "", UDim2.new(1, -76, 0, 26), UDim2.fromOffset(10, 6), 22)
	title.Name, title.TextXAlignment = "Title", Enum.TextXAlignment.Left
	local detail = C.BodyText(card, "", UDim2.new(1, -76, 1, -38), UDim2.fromOffset(10, 32))
	detail.Name, detail.TextXAlignment = "Detail", Enum.TextXAlignment.Left
	local progressBar = C.New("Frame", card, {
		Name = "StepProgress",
		BackgroundColor3 = C.Muted,
		Visible = false,
	})
	local progressFill = C.New("Frame", progressBar, { Name = "Fill", BackgroundColor3 = C.Gold })
	local function clearHighlight()
		if highlight then
			highlight:Destroy()
		end
		highlight, highlightedButton = nil, nil
	end
	local function hide()
		card.Visible = false
		if root:GetAttribute("TutorialActive") then
			root:SetAttribute("TutorialActive", false)
			hud.SetTutorial(nil)
			hud.SetTutorialActive(false)
		end
		clearHighlight()
	end
	local skip = C.Button(card, "Skip", UDim2.fromOffset(54, 44), UDim2.new(1, -62, 0.5, -22), function()
		if not card.Visible then
			return
		end
		dismissed = true
		dismissAt = os.clock()
		hide()
		remotes.TutorialDone:FireServer()
	end, C.Navy, { TextSize = 14 })
	skip.Name = "SkipTutorial"
	local function hasCopies()
		for _, count in pairs(snapshot.Inventory or {}) do
			if count > 0 then
				return true
			end
		end
		return false
	end
	local function target(step)
		if oddsPanel and oddsPanel.Visible then
			return nil
		end
		if step == 1 then
			return if hud.Frame.Visible then hud.Navigation.Home else nil
		end
		if step == 2 then
			return if hud.Frame.Visible then hud.FlushButton else nil
		end
		if step == 3 and hooks.Collection and hooks.Collection.Panel.Visible then
			if not hasCopies() then
				return hooks.Collection.Panel.TitleBar.X
			end
			return hooks.Collection.TutorialTarget()
		end
		if step == 4 and hooks.Upgrades and hooks.Upgrades.Panel.Visible then
			return hooks.Upgrades.TutorialTarget()
		end
		if not hud.Frame.Visible then
			return nil
		end
		if step == 3 then
			if not hasCopies() then
				return hud.FlushButton
			end
		end
		return if step == 3 then hud.Navigation.Collection elseif step == 4 then hud.Navigation.Upgrades else nil
	end
	local function render()
		if destroyed or not snapshot or dismissed then
			return
		end
		if snapshot.TutorialDone and farewellUntil <= os.clock() then
			hide()
			return
		end
		local step = if snapshot.TutorialDone then 5 else Progress.Step(snapshot)
		-- Proximity changes the instruction, never the persisted progress.
		if step == 1 and prompts.Near() then
			step = 2
		end
		local messages = {
			"1/5 - Find your toilet",
			"2/5 - Let's FLUSH!",
			"3/5 - Use your collection",
			"4/5 - Grow your income",
			"Tutorial complete!",
		}
		local details = {
			"Tap Home to return to your toilet.",
			if game:GetService("UserInputService").TouchEnabled
				then "Tap FLUSH. Every flush gives an item and coins."
				else "Tap FLUSH or press E. Every flush gives an item and coins.",
			"Open Index. Display a copy to earn coins, or sell a spare. First copies stay yours.",
			"Open Upgrades for Coin Upgrades, or Shop for Toilets in the Toilet Shop. Buy one. Luck stacks without a cap!",
			"Rebirth spends coins in one click; toilets and upgrades stay. Passes are optional. Replay in Settings.",
		}
		if step == 3 and not hasCopies() then
			details[3] = "Close Index and FLUSH for a copy. Then display it or sell a spare in Index."
		end
		if lastStep and step > lastStep then
			C.Sound("TutorialStep")
		end
		lastStep = step
		title.Text, detail.Text = messages[step], details[step]
		card.Visible, skip.Visible = true, step < 5
		if not root:GetAttribute("TutorialActive") then
			root:SetAttribute("TutorialActive", true)
		end
		hud.SetTutorialActive(true)
		local w, h = root.AbsoluteSize.X, root.AbsoluteSize.Y
		local hudVisible = hud.Frame.Visible and not (oddsPanel and oddsPanel.Visible)
		local bounds = if hudVisible
			then Layout.Compute(w, h, game:GetService("UserInputService").TouchEnabled).Hint
			else { X = 12, Y = 6, W = w - 24, H = 78 }
		local phone = Layout.IsPhone(w, h, game:GetService("UserInputService").TouchEnabled)
		card.BackgroundTransparency = if phone and hudVisible then 0.3 else 0
		if phone then
			local shortTitles = {
				"1/5 Find your toilet",
				"2/5 Let's FLUSH!",
				"3/5 Use your collection",
				"4/5 Grow your income",
				"5/5 Tutorial complete!",
			}
			title.Text = shortTitles[step]
		end
		if phone then
			local shortDetails = {
				"Tap Home to teleport.",
				"Tap FLUSH for an item.",
				if hasCopies() then "Open Index to use an item." else "FLUSH for a copy first.",
				"Buy an upgrade in Upgrades.",
				"Replay in Settings.",
			}
			detail.Text = shortDetails[step]
		end
		title.Size = UDim2.new(1, if step == 5 then -20 else -76, 0, if phone then 20 else 26)
		title.Position = UDim2.fromOffset(10, 6)
		detail.Position = UDim2.fromOffset(10, if phone then 26 else 32)
		detail.Size = UDim2.new(1, -76, 1, if phone then -32 else -38)
		bounds.H = if phone and hudVisible then bounds.H elseif hudVisible then 96 else 78
		title.UITextSizeConstraint.MinTextSize = if phone then 14 else 10
		title.UITextSizeConstraint.MaxTextSize = if phone then 14 else 22
		detail.UITextSizeConstraint.MinTextSize = if phone then 14 else 10
		detail.UITextSizeConstraint.MaxTextSize = if phone then 14 else 17
		skip.Label.UITextSizeConstraint.MinTextSize = if phone then 14 else 10
		progressBar.Visible = phone
		progressFill.Size = UDim2.fromScale(step / 5, 1)
		title.TextScaled, detail.TextScaled = not phone, not phone
		if phone then
			-- The title owns the entire top row; Skip cannot squeeze away n/5.
			title.TextSize, detail.TextSize = 14, 14
			title.Size = UDim2.new(1, -20, 0, 36)
			detail.Position, detail.Size = UDim2.fromOffset(10, 44), UDim2.new(1, -76, 0, 54)
			skip.Position = UDim2.new(1, -62, 0, 44)
			progressBar.Position, progressBar.Size = UDim2.fromOffset(10, 104), UDim2.new(1, -20, 0, 3)
			if hudVisible then
				bounds.Y, bounds.H = if h < 280 then 52 else 64, 112
				if w > h then
					-- Use the top strip beside Home, leaving the avatar and action row clear.
					bounds = { X = 184, Y = if h < 280 then 0 else 4, W = w - 244, H = 56 }
					title.Position, title.Size = UDim2.fromOffset(10, 4), UDim2.new(1, -76, 0, 20)
					detail.Position, detail.Size = UDim2.fromOffset(10, 24), UDim2.new(1, -76, 0, 22)
					skip.Position = UDim2.new(1, -62, 0, 4)
					progressBar.Position = UDim2.fromOffset(10, 50)
					if h < 280 then
						bounds.X, bounds.W, bounds.H = 212, w - 272, 48
						title.Position, detail.Position = UDim2.fromOffset(10, 2), UDim2.fromOffset(10, 22)
						skip.Position, progressBar.Position = UDim2.new(1, -62, 0, 2), UDim2.fromOffset(10, 44)
					end
				end
			else
				title.Size = UDim2.new(1, -76, 0, 20)
				detail.Position, detail.Size = UDim2.fromOffset(10, 26), UDim2.new(1, -76, 0, 44)
				skip.Position = UDim2.new(1, -62, 0.5, -22)
				progressBar.Position = UDim2.fromOffset(10, 72)
			end
		else
			skip.Position = UDim2.new(1, -62, 0.5, -22)
		end
		if hudVisible and not phone and w < 760 and h > w then
			-- Leave a gap between pending income and the social boosts touch target.
			bounds.Y, bounds.H = 192, 88
		end
		-- Keep Skip reachable during reveals without covering the item or result toast.
		local reveal = hud.Frame:FindFirstChild("FlushReveal")
		local layer = root:FindFirstChild("RareReveal")
		local busy = hud.Frame.Visible
			and ((reveal and reveal.Visible) or (layer and layer:FindFirstChild("RevealContent")))
		for _, transient in pairs({ root:FindFirstChild("ResultToast"), layer and layer:FindFirstChild("CompactDrop") }) do
			if transient and transient.Visible then
				local p, size = transient.AbsolutePosition, transient.AbsoluteSize
				busy = busy
					or (
						p.X < bounds.X + bounds.W
						and p.X + size.X > bounds.X
						and p.Y < bounds.Y + bounds.H
						and p.Y + size.Y > bounds.Y
					)
			end
		end
		if busy then
			bounds = if phone
				then { X = bounds.X + bounds.W - 62, Y = bounds.Y, W = 62, H = 56 }
				else { X = w - 100, Y = 6, W = 88, H = 56 }
			if phone then
				skip.Position = UDim2.fromOffset(4, 6)
			end
		end
		title.Visible, detail.Visible = not busy, not busy
		progressBar.Visible = phone and not busy
		card.Visible = step < 5 or not busy
		-- On short phones, the open window and its highlighted action need the space.
		-- Closing it restores the guide and Skip immediately on the next update.
		if phone and h < 500 and not hudVisible then
			card.Visible = false
		end
		C.Place(card, bounds)
		local button = target(step)
		-- Never highlight an invisible or unlaid-out action.
		local ancestor = button
		while ancestor and ancestor ~= root do
			if ancestor:IsA("GuiObject") and not ancestor.Visible then
				button = nil
				break
			end
			ancestor = ancestor.Parent
		end
		if button and (button.AbsoluteSize.X <= 0 or button.AbsoluteSize.Y <= 0) then
			button = nil
		end
		if button ~= highlightedButton then
			clearHighlight()
			if button then
				highlightedButton = button
				highlight = C.New("Frame", button, {
					Name = "TutorialHighlight",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Active = false,
				})
				C.Round(highlight, C.Gold, 12, 4)
				C.Icon(highlight, "Pointer", UDim2.fromOffset(18, 18), UDim2.new(1, -20, 0, 2))
				C.ScrollTo(button)
				task.delay(0.05, function()
					if not destroyed and highlightedButton == button then
						C.ScrollTo(button)
					end
				end)
			end
		end
	end
	local function replay()
		if destroyed or replayPending or os.clock() - requestAt < 2 then
			return
		end
		replayPending, requestAt = true, os.clock()
		remotes.TutorialReplay:FireServer()
		-- Recovery permits retry if the server is loading/saving or throttled the request.
		task.delay(3, function()
			if not destroyed and replayPending then
				replayPending = false
				remotes.State:FireServer()
			end
		end)
	end
	table.insert(
		connections,
		remotes.State.OnClientEvent:Connect(function(state)
			if type(state) ~= "table" then
				return
			end
			local previous = snapshot
			snapshot = state
			if replayPending and not state.TutorialDone and Progress.Step(state) == 1 then
				replayPending, dismissed, lastStep, farewellUntil = false, false, nil, 0
				if hooks.CloseAll then
					hooks.CloseAll()
				end
			elseif
				previous
				and not state.TutorialDone
				and ((state.TutorialRun or 0) ~= (previous.TutorialRun or 0) or previous.TutorialDone)
			then
				-- Owner-only reset is also echoed through authoritative State.
				dismissed, lastStep, farewellUntil = false, nil, 0
				if hooks.CloseAll then
					hooks.CloseAll()
				end
			end
			if previous and not previous.TutorialDone and state.TutorialDone and not dismissed then
				farewellUntil = os.clock() + 6
			end
			render()
		end)
	)
	-- Results do not advance locally: the saved server checkpoint is the source of truth.
	-- Modal transitions must not leave the overlay over a header or a result for a heartbeat interval.
	table.insert(connections, hud.Frame:GetPropertyChangedSignal("Visible"):Connect(render))
	if oddsPanel then
		table.insert(connections, oddsPanel:GetPropertyChangedSignal("Visible"):Connect(render))
	end
	local resultToast = root:FindFirstChild("ResultToast")
	if resultToast then
		table.insert(connections, resultToast:GetPropertyChangedSignal("Visible"):Connect(render))
	end
	local elapsed = 0
	table.insert(
		connections,
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			if
				dismissed
				and not replayPending
				and snapshot
				and not snapshot.TutorialDone
				and os.clock() - dismissAt >= 3
			then
				dismissAt = os.clock()
				remotes.TutorialDone:FireServer()
			end
			elapsed += dt
			if elapsed >= 0.25 then
				elapsed = 0
				render()
			end
		end)
	)
	table.insert(
		connections,
		root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			clearHighlight()
			render()
		end)
	)
	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		hide()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		card:Destroy()
	end
	table.insert(connections, root.Destroying:Connect(destroy))
	return { Destroy = destroy, Replay = replay, Frame = card }
end
return Tutorial
