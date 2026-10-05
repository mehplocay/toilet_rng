local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local UserInputService = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Monetization = require(Shared.Config.Monetization)
local Toilets = require(Shared.Config.Toilets)
local Rewards = require(Shared.Config.Rewards)
local Schedule = require(Shared.RewardSchedule)
local HUD = {}
function HUD.Create(root, remotes, open, prompts)
	local gui = C.New("Frame", root, { Name = "HUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	local navigation, buttons = {}, {}
	local names = { "Shop", "Collection", "Upgrades", "Passes", "Daily" }
	local colors = { Color3.fromRGB(239, 77, 103), C.Blue, C.Green, C.Purple, C.Gold }
	for i, name in ipairs(names) do
		local button = C.Button(
			gui,
			if name == "Collection" then "Index" else name,
			UDim2.fromOffset(80, 80),
			nil,
			function()
				open(name)
			end,
			colors[i],
			{ TextSize = 22 }
		)
		button.Label.Position, button.Label.Size = UDim2.fromScale(0.02, 0.7), UDim2.fromScale(0.96, 0.25)
		C.Icon(button, name, UDim2.fromScale(0.67, 0.65), UDim2.fromScale(0.165, 0.035))
		navigation[name], buttons[i] = button, button
	end
	local dailyBadge = C.Badge(navigation.Daily, 0)
	dailyBadge.Set(0)
	local travel = C.New("Frame", gui, { Name = "Travel", BackgroundTransparency = 1 })
	for i, name in ipairs({ "Hub", "Home", "Shop" }) do
		C.Button(travel, name, UDim2.new(1 / 3, -10, 1, 0), UDim2.new((i - 1) / 3, 5, 0, 0), function()
			open(if name == "Shop" then "TravelShop" else name)
		end, ({ C.Gold, C.Blue, C.Green })[i], { Icon = name, TextSize = 30 })
	end
	local settings = C.Button(gui, "", UDim2.fromOffset(44, 44), nil, function()
		open("Settings")
	end, C.Navy)
	C.Icon(settings, "Settings", UDim2.fromScale(0.74, 0.74), UDim2.fromScale(0.13, 0.13))
	local wallet = C.New("Frame", gui, { Name = "Wallet", BackgroundTransparency = 1 })
	C.Icon(wallet, "Coins", UDim2.fromScale(0.22, 0.94), UDim2.fromScale(0, 0.03))
	local coins = C.Text(wallet, "0", UDim2.fromScale(0.76, 0.92), UDim2.fromScale(0.24, 0.04), 58)
	coins.TextXAlignment, coins.TextColor3 = Enum.TextXAlignment.Left, Color3.fromRGB(193, 255, 76)
	coins.UIStroke.Thickness = 3
	local value = C.New("NumberValue", wallet, { Value = 0 })
	value.Changed:Connect(function(number)
		coins.Text = C.Commas(number)
	end)
	local boost = C.New("Frame", gui, { Name = "Boosts", BackgroundTransparency = 1 })
	local _, serverText = C.Chip(boost, "Luck x1", C.Navy, UDim2.new(0.5, -4, 1, 0))
	local _, personalText = C.Chip(boost, "Daily luck", C.Navy, UDim2.new(0.5, -4, 1, 0), UDim2.fromScale(0.5, 0))
	serverText.TextColor3, personalText.TextColor3 = Color3.fromRGB(151, 255, 128), Color3.fromRGB(221, 173, 255)
	local board = C.Card(gui, C.Gold, false)
	board.Name = "BestFlushBoard"
	C.Text(board, "BEST FLUSH EVER", UDim2.new(1, -12, 0.36, 0), UDim2.fromOffset(6, 4), 21).TextColor3 = C.Gold
	local bestText =
		C.Text(board, "Your server's next legend awaits!", UDim2.new(1, -16, 0.51, 0), UDim2.new(0, 8, 0.42, 0), 18)
	local bestChance = 0
	local hint = C.New("Frame", gui, { Name = "CenterHint", BackgroundTransparency = 1 })
	local hintTitle = C.Text(hint, "Make your next great flush!", UDim2.new(1, 0, 0.55, 0), nil, 38)
	hintTitle.UIStroke.Thickness = 3
	local hintDetail = C.Text(hint, "Head home to your toilet", UDim2.new(1, -56, 0.4, 0), UDim2.fromScale(0, 0.6), 17)
	hintDetail.TextColor3 = C.Gold
	local skipCallback
	local skip = C.Button(hint, "Skip", UDim2.fromOffset(48, 44), UDim2.new(1, -48, 1, -44), function()
		if skipCallback then
			skipCallback()
		end
	end, C.Navy, { TextSize = 14 })
	skip.Visible = false
	local action = C.New("Frame", gui, { Name = "FlushActions", BackgroundTransparency = 1 })
	local state, untilAt, cooldown, lastRequest = nil, 0, 3, -math.huge
	local autoEnabled, autoUnlocked = false, false
	local flush
	flush = C.Button(action, "FLUSH", UDim2.new(1, -96, 1, 0), nil, function()
		if not state or os.clock() - lastRequest < 0.3 or not prompts.Near() then
			return
		end
		lastRequest = os.clock()
		remotes.Flush:FireServer()
	end, C.Green, { TextSize = 42 })
	flush.Interactable = false
	flush.Label.Size, flush.Label.Position = UDim2.fromScale(0.69, 0.62), UDim2.fromScale(0.28, 0.12)
	local flushIcon = C.Icon(flush, "Flush", UDim2.fromScale(0.25, 0.67), UDim2.fromScale(0.02, 0.12))
	local ring = C.New("Frame", flushIcon, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	ring.Visible = false
	local ticks = {}
	for i = 1, 24 do
		local a = (i / 24) * math.pi * 2
		local tick = C.New("Frame", ring, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + math.sin(a) * 0.52, 0.5 - math.cos(a) * 0.52),
			Size = UDim2.fromScale(0.075, 0.16),
			Rotation = i * 15,
			BackgroundColor3 = C.Gold,
		})
		C.New("UICorner", tick, { CornerRadius = UDim.new(0.5, 0) })
		ticks[i] = tick
	end
	local actionDetail = C.Text(flush, "TAP TO FLUSH", UDim2.fromScale(0.84, 0.2), UDim2.fromScale(0.08, 0.75), 14)
	local pointer = C.Icon(flush, "Pointer", UDim2.fromOffset(48, 48), UDim2.new(1, -52, 0, -24))
	pointer.Visible = false
	pointer.Rotation = -12
	local auto = C.Button(action, "AUTO\n0/100", UDim2.fromOffset(84, 58), UDim2.new(1, -84, 0, 0), function()
		if autoUnlocked then
			remotes.AutoFlush:FireServer(not autoEnabled)
		end
	end, C.Blue, { TextSize = 18 })
	auto.Interactable = false
	local autoProgress = C.ProgressBar(auto, UDim2.new(1, -14, 0, 5), UDim2.new(0, 7, 1, -9), C.Gold)
	local offers = C.New("Frame", gui, { Name = "Offers", BackgroundTransparency = 1 })
	local function offer(y, title, detail, icon, color, target)
		local card = C.Button(offers, "", UDim2.new(1, 0, 0, 130), UDim2.fromOffset(0, y), function()
			open(target)
		end, color)
		C.Icon(card, icon, UDim2.fromOffset(64, 64), UDim2.new(0.5, -32, 0, 8))
		C.Text(card, title, UDim2.new(1, -12, 0, 26), UDim2.fromOffset(6, 72), 25)
		local text = C.Text(card, detail, UDim2.new(1, -12, 0, 23), UDim2.fromOffset(6, 101), 16)
		return card, text
	end
	local passOffer = offer(0, "STYLE UP!", "Explore passes", "Crown", C.Purple, "Passes")
	local sticker = C.Pill(passOffer, "VIP", C.Gold, UDim2.fromOffset(46, 27), UDim2.new(1, -46, 0, -9))
	sticker.Rotation = 12
	local _, luckyText = offer(154, "FEELING LUCKY?", "Daily rewards", "Luck", C.Green, "Daily")
	local layout, eventActive, revealing = nil, false, false
	local function resize()
		layout = Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y, UserInputService.TouchEnabled)
		for i, button in ipairs(buttons) do
			C.Place(button, layout.Nav[i])
		end
		for object, r in pairs({
			[travel] = layout.Travel,
			[settings] = layout.Settings,
			[wallet] = layout.Coins,
			[boost] = layout.Boosts,
			[board] = layout.Board,
			[hint] = layout.Hint,
			[action] = layout.Action,
			[offers] = layout.Offers,
		}) do
			C.Place(object, r)
		end
		offers.Visible, board.Visible = layout.OffersVisible, not layout.Short and not eventActive and not revealing
		travel.Visible = not eventActive
		auto.Size = UDim2.new(0, 84, 1, 0)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	local serverExpiry, personalExpiry, tutorial = 0, 0, false
	local function timer(remaining)
		return string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
	end
	local heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
		if not gui.Visible then
			return
		end
		local remaining = math.max(0, untilAt - os.clock())
		local near = prompts.Near()
		flush.Interactable = state ~= nil and near and remaining <= 0
		flush.Text = if remaining > 0 then string.format("%.1fs", remaining) else "FLUSH"
		actionDetail.Text = if not state
			then "LOADING..."
			elseif not near then "GO TO YOUR TOILET"
			elseif remaining > 0 then "GET READY..."
			else (if UserInputService.TouchEnabled then "TAP TO FLUSH" else "CLICK OR PRESS E")
		ring.Visible = remaining > 0
		for i, tick in ipairs(ticks) do
			tick.Visible = i <= math.ceil(remaining / cooldown * 24)
		end
		pointer.Visible = near and remaining == 0 and not autoEnabled
		if pointer.Visible then
			pointer.Size = UDim2.fromOffset(layout.Pointer.W, layout.Pointer.H)
			pointer.Position = UDim2.fromOffset(
				layout.Pointer.X - layout.Action.X,
				layout.Pointer.Y - layout.Action.Y + math.sin(os.clock() * 4) * 3
			)
		end
		flush.Position = UDim2.fromOffset(0, if pointer.Visible then math.sin(os.clock() * 4) * 2 else 0)
		if not tutorial then
			hintTitle.Text = if near then "Flush something legendary!" else "Your next great find awaits!"
			hintDetail.Text = if near then "Every flush brings an item" else "Tap Home to find your toilet"
		end
	end)
	gui.Destroying:Connect(function()
		heartbeat:Disconnect()
	end)
	task.spawn(function()
		while gui.Parent do
			local now = workspace:GetServerTimeNow()
			local serverLeft, personalLeft =
				math.max(0, math.ceil(serverExpiry - now)), math.max(0, math.ceil(personalExpiry - now))
			serverText.Text = if serverLeft > 0
				then "Server x2\n" .. timer(serverLeft)
				else "Luck x" .. tostring(if state then Toilets[state.ToiletTier].Luck else 1)
			personalText.Text = if personalLeft > 0
				then "Daily x2\n" .. timer(personalLeft)
				else "Daily boost\nDay 7 reward"
			if state then
				local ready, _, nextAt = Schedule.Progress(state.LastClaimDay, state.Streak, now, Rewards)
				dailyBadge.Set(if ready then 1 else 0)
				luckyText.Text = if ready
					then "Daily reward ready!"
					else "Next: " .. timer(math.max(0, math.ceil(nextAt - now)))
			end
			task.wait(1)
		end
	end)
	local coinTarget
	return {
		Frame = gui,
		Navigation = navigation,
		Hint = hint,
		EventActive = function(active)
			eventActive = active
			resize()
		end,
		SetTutorial = function(title, detail, onSkip)
			tutorial = title ~= nil
			hintTitle.Size = UDim2.new(1, if onSkip then -56 else 0, 0.55, 0)
			if title then
				hintTitle.Text, hintDetail.Text = title, detail or ""
			end
			skipCallback, skip.Visible = onSkip, onSkip ~= nil
		end,
		SetHintVisible = function(visible)
			hint.Visible = visible
			revealing = not visible
			board.Visible = visible and not eventActive and not layout.Short
		end,
		Update = function(snapshot)
			state = snapshot
			if coinTarget ~= state.Coins then
				coinTarget = state.Coins
				C.Tween(value, 0.55, { Value = state.Coins })
			end
			autoUnlocked, autoEnabled = state.LifetimeFlushes >= Monetization.AutoFlushUnlock, state.AutoFlush
			auto.Interactable = autoUnlocked
			auto.Text = if autoUnlocked
				then (if autoEnabled then "AUTO\nON" else "AUTO\nOFF")
				else "AUTO\n" .. state.LifetimeFlushes .. "/" .. Monetization.AutoFlushUnlock
			autoProgress.Set(state.LifetimeFlushes / Monetization.AutoFlushUnlock)
			serverExpiry, personalExpiry = state.ServerLuckExpires or 0, state.RewardLuckExpires or 0
		end,
		Flushed = function(payload)
			cooldown = math.max(0.1, payload.Cooldown or 3)
			untilAt = os.clock() + cooldown
		end,
		Luck = function(expires)
			serverExpiry = expires
		end,
		Best = function(playerName, item)
			if item.Chance <= bestChance then
				return
			end
			bestChance = item.Chance
			bestText.Text = playerName .. " • " .. item.Name .. "\n1 in " .. C.Commas(item.Chance)
			C.Pop(board)
		end,
	}
end
return HUD
