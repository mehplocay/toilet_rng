local C = require(script.Parent.Components)
local Config = require(game.ReplicatedStorage.Shared.Config.Rewards)
local Schedule = require(game.ReplicatedStorage.Shared.RewardSchedule)
local CashMath = require(game.ReplicatedStorage.Shared.CashMath)
local Paid = require(game.ReplicatedStorage.Shared.PaidBenefits)
local Rewards = {}
local function duration(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
function Rewards.Create(gui, remotes)
	local panel = C.Panel(gui, "Daily Rewards", C.Gold)
	local body = panel.ContentScroll.Body
	C.BodyText(body, "A fresh reward every UTC day. Keep your streak!", UDim2.new(1, 0, 0, 32))
	local row = C.Scroll(body, UDim2.new(1, 0, 1, -164), UDim2.fromOffset(0, 38))
	C.Grid(row, 132, 184, 4)
	local cards = {}
	for day = 1, #Config.BaseCoins do
		local card = C.Card(row, if day == #Config.BaseCoins then C.Purple else C.Gold, day == #Config.BaseCoins)
		card.LayoutOrder = day
		C.Text(card, "DAY " .. day, UDim2.new(1, -12, 0, 26), UDim2.fromOffset(6, 8), 22)
		C.Icon(
			card,
			if day == #Config.BaseCoins then "Luck" else "Coins",
			UDim2.fromOffset(56, 56),
			UDim2.new(0.5, -28, 0, 38)
		)
		local value = C.Text(card, "", UDim2.new(1, -12, 0, 43), UDim2.fromOffset(6, 98), 21)
		local pill, status = C.Pill(card, "Locked", C.Navy, UDim2.new(1, -18, 0, 26), UDim2.fromOffset(9, 149))
		status.Position, status.Size = UDim2.fromOffset(28, 3), UDim2.new(1, -32, 1, -6)
		local marks = C.StatusIcons(pill, UDim2.fromOffset(22, 22), UDim2.fromOffset(3, 2))
		cards[day] = { Frame = card, Value = value, Status = status, Marks = marks }
	end
	local countdown = C.Text(body, "Loading rewards...", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 1, -122), 19)
	local message = C.BodyText(
		body,
		"Missing a day resets your streak. Rewards grow with your tier.",
		UDim2.new(1, 0, 0, 40),
		UDim2.new(0, 0, 1, -40)
	)
	local state, pending, request = nil, false, 0
	local claim
	local function render()
		if not state then
			claim.Interactable = false
			return
		end
		-- Preview only: claim validation and the UTC boundary remain on the server.
		local now = workspace:GetServerTimeNow()
		local available, day, nextAt = Schedule.Progress(state.LastClaimDay, state.Streak, now, Config)
		for index, card in ipairs(cards) do
			local claimed = if available then index < day else index <= day
			local today = available and index == day
			card.Status.Text = if claimed then "CLAIMED" elseif today then "READY!" else "UP NEXT"
			card.Status.TextColor3 = if claimed then C.Muted elseif today then C.Green else Color3.new(1, 1, 1)
			card.Marks(not claimed and not today, claimed)
			card.Frame.Background.UIStroke.Color = if today then C.Green elseif claimed then C.Muted else C.Gold
			card.Value.Text = C.Commas(
				math.floor(
					CashMath.Product(
						Schedule.Coins(index, state.ToiletTier, Config),
						Paid.Cash(state, 1),
						CashMath.Limit
					)
				)
			) .. " Coins" .. (if index == #Config.BaseCoins then "\n+ 10 min x2 Luck" else "")
		end
		countdown.Text = (if available then "Ready! Resets in " else "Next reward in ") .. duration(nextAt - now)
		claim.Text = if pending then "Claiming..." elseif available then "Claim Day " .. day else "Claimed Today"
		claim.Interactable = available and not pending
	end
	claim = C.Button(body, "Loading...", UDim2.new(1, -32, 0, 48), UDim2.new(0, 16, 1, -90), function()
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
				message.Text = "Still waiting? You can retry safely."
				render()
			end
		end)
	end, C.Green, { Icon = "Daily" })
	remotes.Result.OnClientEvent:Connect(function(action, payload)
		if action == "ClaimReward" then
			pending = false
			message.Text = payload.Message
			render()
			if payload.Success then
				C.Shine(claim)
			end
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
