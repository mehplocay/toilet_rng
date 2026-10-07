local Progress =
	require(if script then game.ReplicatedStorage.Shared.TutorialProgress else "../../shared/TutorialProgress")
local Tutorial = { NextStep = Progress.NextStep }
function Tutorial.Create(_player, remotes, hud, prompts, hooks)
	local C = require(script.Parent.Components)
	local Layout = require(script.Parent.Layout)
	hooks = hooks or {}
	local root = hud.Frame.Parent
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
			"Tap FLUSH or press E. Every flush gives an item and coins.",
			"Open Index. Display a copy to earn coins, or sell a spare. First copies stay yours.",
			"Open Upgrades for Coin Upgrades, or Shop for Toilets in the Toilet Shop. Buy one; keep flushing to save up!",
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
		local bounds = if hud.Frame.Visible
			then Layout.Compute(w, h, game:GetService("UserInputService").TouchEnabled).Hint
			else { X = 12, Y = 6, W = w - 24, H = 78 }
		bounds.H = if hud.Frame.Visible then 96 else 78
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
			bounds = { X = w - 100, Y = 6, W = 88, H = 56 }
		end
		title.Visible, detail.Visible = not busy, not busy
		card.Visible = step < 5 or not busy
		C.Place(card, bounds)
		local button = target(step)
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
