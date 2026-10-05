local C = require(script.Parent.Components)
local Config = require(game.ReplicatedStorage.Shared.Config.Rewards)
local Schedule = require(game.ReplicatedStorage.Shared.RewardSchedule)
local Rewards = {}

local function duration(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end

function Rewards.Create(gui, remotes)
	local panel = C.Panel(gui, "Daily Rewards")
	C.Text(
		panel,
		"Claim every UTC day. Missing a day resets your streak.",
		UDim2.fromScale(0.94, 0.07),
		UDim2.fromScale(0.03, 0.12)
	)
	local cards = {}
	for day = 1, #Config.BaseCoins do
		local card = C.New("Frame", panel, {
			Size = UDim2.fromScale(0.22, 0.22),
			Position = UDim2.fromScale(0.03 + ((day - 1) % 4) * 0.24, 0.22 + math.floor((day - 1) / 4) * 0.25),
			BackgroundColor3 = C.Navy,
		})
		C.Round(card)
		C.Text(card, "Day " .. day, UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.04))
		local value = C.Text(card, "", UDim2.fromScale(0.9, 0.3), UDim2.fromScale(0.05, 0.28))
		local status = C.Text(card, "Locked", UDim2.fromScale(0.9, 0.22), UDim2.fromScale(0.05, 0.72))
		cards[day] = { Frame = card, Value = value, Status = status }
	end
	local countdown = C.Text(panel, "Loading rewards...", UDim2.fromScale(0.94, 0.06), UDim2.fromScale(0.03, 0.73))
	local message = C.Text(
		panel,
		"Rewards scale with your current toilet tier.",
		UDim2.fromScale(0.94, 0.06),
		UDim2.fromScale(0.03, 0.92)
	)
	local state, pending = nil, false
	local request = 0
	local claim
	local function render()
		if not state then
			claim.Interactable = false
			return
		end
		-- This is only a preview; the server checks its own os.time() when claiming.
		local now = workspace:GetServerTimeNow()
		local available, day, nextAt = Schedule.Progress(state.LastClaimDay, state.Streak, now, Config)
		for index, card in ipairs(cards) do
			local claimed = if available then index < day else index <= day
			local today = available and index == day
			card.Status.Text = if claimed then "Claimed" elseif today then "Today" else "Locked"
			card.Frame.BackgroundColor3 = if claimed
				then Color3.fromRGB(35, 95, 70)
				elseif today then Color3.fromRGB(115, 85, 25)
				else C.Navy
			card.Value.Text = Schedule.Coins(index, state.ToiletTier, Config)
				.. " Coins"
				.. (if index == #Config.BaseCoins then "\nLuck x2: 10 min" else "")
		end
		countdown.Text = (if available then "Reward ready! Next UTC day in " else "Next reward in ")
			.. duration(nextAt - now)
		if state.RewardLuckExpires > now then
			countdown.Text ..= " | Luck x2: " .. duration(state.RewardLuckExpires - now)
		end
		claim.Text = if pending then "Claiming..." elseif available then "Claim Day " .. day else "Claimed Today"
		claim.Interactable = available and not pending
	end
	claim = C.Button(panel, "Loading...", UDim2.fromScale(0.5, 0.1), UDim2.fromScale(0.25, 0.81), function()
		if pending or not state then
			return
		end
		pending = true
		request += 1
		local token = request
		render()
		remotes.ClaimReward:FireServer()
		task.delay(15, function()
			if pending and request == token then
				pending = false
				message.Text = "Still waiting? Try again; each UTC day can only be claimed once."
				render()
			end
		end)
	end, Color3.fromRGB(40, 175, 110))
	remotes.Result.OnClientEvent:Connect(function(action, payload)
		if action == "ClaimReward" then
			pending = false
			message.Text = payload.Message
			render()
		end
	end)
	task.spawn(function()
		while panel.Parent do
			if panel.Visible then
				render()
			end
			task.wait(1)
		end
	end)
	render()
	return {
		Panel = panel,
		Update = function(snapshot)
			state = snapshot
			render()
		end,
	}
end

return Rewards
