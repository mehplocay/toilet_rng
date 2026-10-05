local Tutorial = {}
-- Progress follows server outcomes, never button clicks or local inventory edits.
function Tutorial.NextStep(step, action, payload)
	if type(payload) ~= "table" then
		return step
	end
	if step <= 2 and action == "Flush" and type(payload.ItemId) == "string" then
		return 3
	elseif step == 3 and action == "Sell" and payload.Success == true then
		return 4
	elseif step == 4 and action == "BuyToilet" and payload.Success == true then
		return 5
	end
	return step
end
function Tutorial.Create(player, remotes, hud, prompts)
	local C = require(script.Parent.Components)
	local step, snapshot, stopped, finishing = 1, nil, false, false
	local connections, highlight = {}, nil
	local function clearHighlight()
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
	end
	local function stop()
		if stopped then
			return
		end
		stopped = true
		clearHighlight()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		hud.SetTutorial(nil)
	end
	local function finish(skipped)
		if finishing or stopped then
			return
		end
		finishing = true
		clearHighlight()
		remotes.TutorialDone:FireServer()
		if skipped then
			stop()
		else
			task.delay(4, stop)
		end
	end
	local function render()
		if stopped or not snapshot then
			return
		end
		if step == 4 and snapshot.ToiletTier > 1 then
			step = 5
		end
		local messages = {
			"Find your toilet!",
			"Let's FLUSH!",
			"Your collection is growing!",
			"Time for an upgrade!",
			"Go find something legendary!",
		}
		local details = {
			"1/5 • Tap Home to get there",
			"2/5 • Tap FLUSH or press E",
			"3/5 • Open Index. Sell a spare copy",
			"4/5 • Open Upgrades. Buy your next tier",
			"Tutorial complete!",
		}
		hud.SetTutorial(
			messages[step],
			details[step],
			if finishing
				then nil
				else function()
					finish(true)
				end
		)
		clearHighlight()
		local button = if step == 3 then hud.Navigation.Collection elseif step == 4 then hud.Navigation.Upgrades else nil
		if button then
			highlight = C.New(
				"Frame",
				button,
				{ Name = "TutorialHighlight", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }
			)
			C.Round(highlight, C.Gold, 12, 4)
		end
		if step == 5 then
			finish(false)
		end
	end
	table.insert(
		connections,
		remotes.State.OnClientEvent:Connect(function(state)
			if state.TutorialDone == true then
				if not finishing then
					stop()
				end
				return
			end
			snapshot = state
			render()
		end)
	)
	table.insert(
		connections,
		remotes.Result.OnClientEvent:Connect(function(action, payload)
			if stopped or finishing or not snapshot then
				return
			end
			step = Tutorial.NextStep(step, action, payload)
			render()
		end)
	)
	local elapsed = 0
	table.insert(
		connections,
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			elapsed += dt
			if stopped or not snapshot or step > 2 or elapsed < 0.25 then
				return
			end
			elapsed = 0
			if step == 1 and prompts.Near() then
				step = 2
				render()
			end
		end)
	)
	return { Destroy = stop }
end
return Tutorial
