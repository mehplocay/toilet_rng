local C = require(script.Parent.Components)
local Layout = require(script.Parent.Layout)
local UserInputService = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Monetization = require(Shared.Config.Monetization)
local AutoConfig = require(Shared.Config.AutoFlush)
local Rewards = require(Shared.Config.Rewards)
local Schedule = require(Shared.RewardSchedule)
local SocialConfig = require(Shared.Config.SocialBoosts)
local SocialUI = require(script.Parent.SocialBoosts)
local rebirth = require(Shared.RebirthRules).new(require(Shared.Config.Rebirth))
local Odds = require(script.Parent.LuckyOdds)
local Format = require(Shared.NumberFormat)
local HUD = {}
function HUD.Create(root, remotes, open, prompts, shopNavigation)
	local gui = C.New("Frame", root, { Name = "HUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	local navigation, buttons = {}, {}
	local names = { "Shop", "Rebirth", "Collection", "Upgrades", "Passes", "Daily" }
	local colors = { Color3.fromRGB(239, 77, 103), C.Purple, C.Blue, C.Green, C.Purple, C.Gold }
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
		C.Icon(
			button,
			if name == "Rebirth" then "Crown" else name,
			UDim2.fromScale(0.67, 0.65),
			UDim2.fromScale(0.165, 0.035)
		)
		navigation[name], buttons[i] = button, button
	end
	local dailyBadge = C.Badge(navigation.Daily, 0)
	local passHint = C.Text(navigation.Passes, "", UDim2.new(1, -4, 0, 12), UDim2.fromOffset(2, 2), 12)
	local dailyHint = C.Text(navigation.Daily, "", UDim2.new(1, -4, 0, 12), UDim2.fromOffset(2, 2), 12)
	passHint.Name, dailyHint.Name = "PhonePromotion", "PhoneReward"
	passHint.UITextSizeConstraint.MinTextSize, dailyHint.UITextSizeConstraint.MinTextSize = 12, 12
	local rebirthBadge = C.Badge(navigation.Rebirth, 0)
	local badgeDefaults = {}
	for _, badge in ipairs({ dailyBadge, rebirthBadge }) do
		local label = badge.Frame:FindFirstChildWhichIsA("TextLabel")
		badgeDefaults[badge] = {
			Size = badge.Frame.Size,
			Position = badge.Frame.Position,
			Label = label,
			LabelSize = label.Size,
			LabelPosition = label.Position,
			Minimum = label.UITextSizeConstraint.MinTextSize,
		}
	end
	rebirthBadge.Set(0)
	dailyBadge.Set(0)
	local travel = C.New("Frame", gui, { Name = "Travel", BackgroundTransparency = 1 })
	for i, name in ipairs({ "Hub", "Home", "Shop" }) do
		local button = C.Button(travel, name, UDim2.new(1 / 3, -10, 1, 0), UDim2.new((i - 1) / 3, 5, 0, 0), function()
			open(if name == "Shop" then "TravelShop" else name)
		end, ({ C.Gold, C.Blue, C.Green })[i], { Icon = name, TextSize = 30 })
		if name == "Home" then
			navigation.Home = button
		end
	end
	local settings = C.Button(gui, "", UDim2.fromOffset(44, 44), nil, function()
		open("Settings")
	end, C.Navy)
	C.Icon(settings, "Settings", UDim2.fromScale(0.74, 0.74), UDim2.fromScale(0.13, 0.13))
	local wallet = C.New("Frame", gui, { Name = "Wallet", BackgroundTransparency = 1 })
	C.Icon(wallet, "Coin", UDim2.fromScale(0.22, 0.94), UDim2.fromScale(0, 0.03))
	local coins = C.Text(wallet, "0", UDim2.fromScale(0.76, 0.92), UDim2.fromScale(0.24, 0.04), 58)
	coins.TextXAlignment, coins.TextColor3 = Enum.TextXAlignment.Left, Color3.fromRGB(193, 255, 76)
	coins.UIStroke.Thickness = 3
	local value = C.New("NumberValue", wallet, { Value = 0 })
	value.Changed:Connect(function(number)
		coins.Text = C.Commas(number)
	end)
	local boost = C.New("Frame", gui, { Name = "Boosts", BackgroundTransparency = 1 })
	local luckChip, serverText = C.Chip(boost, "Luck x1", C.Navy, UDim2.new(0.5, -4, 1, 0))
	local socialChip = C.Button(gui, SocialUI.ChipText(nil), UDim2.fromOffset(240, 44), nil, function()
		open("Social")
	end, C.Navy, { Name = "SocialBoostsChip", TextSize = 16 })
	local socialState, socialAt = {}, os.clock()
	local _, personalText = C.Chip(boost, "Daily luck", C.Navy, UDim2.new(0.5, -4, 1, 0), UDim2.fromScale(0.5, 0))
	serverText.TextColor3, personalText.TextColor3 = Color3.fromRGB(151, 255, 128), Color3.fromRGB(221, 173, 255)
	serverText.Name = "TotalLuck"
	local luckDialog = Odds.Create(root, remotes)
	luckDialog.Panel.Name = "Luck details"
	local luckState, luckDeadline = nil, 0
	local breakdown = C.BodyText(luckChip, "", UDim2.new(0, 290, 0, 140), UDim2.new(0, 0, 1, 4))
	breakdown.Name, breakdown.Visible, breakdown.BackgroundTransparency = "LuckBreakdown", false, 0
	breakdown.BackgroundColor3, breakdown.ZIndex = C.Navy, 30
	local info = C.New(
		"TextButton",
		luckChip,
		{ Name = "LuckInfo", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }
	)
	info.Activated:Connect(function()
		breakdown.Visible = not breakdown.Visible
		luckDialog.Show(luckState)
	end)
	gui.Destroying:Connect(function()
		luckDialog.Panel:Destroy()
	end)
	local mobileStatus = C.Button(gui, "", UDim2.fromOffset(180, 44), nil, function()
		-- Details are opened by the handler below.
	end, C.Navy, { Name = "PhoneStatus", TextSize = 14 })
	mobileStatus.Label.UITextSizeConstraint.MinTextSize = 14
	mobileStatus.Visible = false
	local statusDetails = C.Panel(root, "Boost details", C.Blue)
	statusDetails:GetPropertyChangedSignal("Visible"):Connect(function()
		gui.Visible = not statusDetails.Visible
	end)
	local statusBody = statusDetails.ContentScroll.Body
	local autoDetail = C.BodyText(statusBody, "", UDim2.new(1, -12, 0, 180), UDim2.fromOffset(6, 316))
	autoDetail.Name = "AutomationDetails"
	local statusText = C.BodyText(statusBody, "", UDim2.new(1, -12, 0, 180), UDim2.fromOffset(6, 8))
	C.Button(statusBody, "Luck odds", UDim2.new(1, -12, 0, 44), UDim2.fromOffset(6, 200), function()
		statusDetails.Visible = false
		luckDialog.Show(luckState)
	end, C.Blue)
	C.Button(statusBody, "Social boosts", UDim2.new(1, -12, 0, 44), UDim2.fromOffset(6, 256), function()
		statusDetails.Visible = false
		open("Social")
	end, C.Blue)
	mobileStatus.Activated:Connect(function()
		luckDialog.Close()
		statusDetails.Visible = true
	end)
	gui.Destroying:Connect(function()
		statusDetails:Destroy()
	end)
	local hint = C.New("CanvasGroup", gui, { Name = "CenterHint", BackgroundTransparency = 1, Visible = false })
	local hintTitle = C.Text(hint, "Make your next great flush!", UDim2.new(1, 0, 0.55, 0), nil, 38)
	hintTitle.UIStroke.Thickness = 3
	local hintDetail = C.Text(hint, "Head home to your toilet", UDim2.new(1, -56, 0.4, 0), UDim2.fromScale(0, 0.6), 17)
	hintDetail.TextColor3 = C.Gold
	local hintUntil, hintKey, lastAwayHint = 0, nil, -math.huge
	local function showHint(title, detail)
		local key = title .. (detail or "")
		if key ~= hintKey then
			hintUntil, hintKey = os.clock() + 5, key
		end
		hintTitle.Text, hintDetail.Text = title, detail or ""
	end
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
	local autoStatus, statusAt = {}, 0
	local autoRunningUntil, autoPulseAt, lastAutoId = 0, 0, 0
	local flush
	flush = C.Button(action, "FLUSH", UDim2.new(1, -96, 1, 0), nil, function()
		if state and not prompts.Near() then
			open("Home")
			return
		end
		if not state or os.clock() - lastRequest < 0.3 then
			return
		end
		lastRequest = os.clock()
		remotes.Flush:FireServer()
	end, C.Green, { TextSize = 42 })
	flush.Interactable = false
	flush.Label.Size, flush.Label.Position = UDim2.fromScale(0.69, 0.8), UDim2.fromScale(0.28, 0.1)
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
	local pointer = C.Icon(flush, "Pointer", UDim2.fromOffset(48, 48), UDim2.new(1, -52, 0, -24))
	pointer.Visible = false
	pointer.Rotation = -12
	local auto = C.Button(action, "AUTO\n0/100", UDim2.fromOffset(84, 58), UDim2.new(1, -84, 0, 0), function()
		if autoUnlocked then
			remotes.AutoFlush:FireServer(not autoEnabled)
		end
	end, C.Blue, { TextSize = 18 })
	auto.Label.TextWrapped = false
	auto.Label.UITextSizeConstraint.MaxTextSize = 14
	auto.Interactable = false
	local autoIcon = C.Icon(auto, "Flush", UDim2.fromOffset(18, 18), UDim2.fromOffset(3, 2))
	autoIcon.Visible = false
	local autoTitle = C.Text(auto, "AUTO", UDim2.fromOffset(48, 18), UDim2.fromOffset(22, 2), 14)
	autoTitle.UITextSizeConstraint.MinTextSize = 14
	autoTitle.Visible = false
	local autoProgress = C.ProgressBar(auto, UDim2.new(1, -14, 0, 5), UDim2.new(0, 7, 1, -9), C.Gold)
	auto.Name = "AutoFlushSwitch"
	local idle = C.Button(
		action,
		"Still there? Tap to continue",
		UDim2.new(1, -96, 1, 0),
		UDim2.fromOffset(0, 0),
		function()
			remotes.PlayerActivity:FireServer()
		end,
		C.Gold,
		{ TextSize = 20 }
	)
	idle.Name, idle.Visible = "IdleGuard", false
	local offers = C.New("Frame", gui, { Name = "Offers", BackgroundTransparency = 1 })
	local function offer(y, title, detail, icon, color, target)
		local card = C.Button(offers, "", UDim2.new(1, 0, 0, 130), UDim2.fromOffset(0, y), function()
			open(target)
		end, color)
		local burst = C.Icon(card, "OfferBurst", UDim2.fromOffset(52, 52), UDim2.new(1, -48, 0, -12))
		burst.Rotation = 12
		C.Icon(card, icon, UDim2.fromOffset(64, 64), UDim2.new(0.5, -32, 0, 8))
		C.Text(card, title, UDim2.new(1, -12, 0, 26), UDim2.fromOffset(6, 72), 25)
		local text = C.Text(card, detail, UDim2.new(1, -12, 0, 23), UDim2.fromOffset(6, 101), 16)
		return card, text
	end
	offer(0, "STYLE UP!", "Explore passes", "Crown", C.Purple, "Passes")
	local _, luckyText = offer(154, "FEELING LUCKY?", "Daily rewards", "Luck", C.Green, "Daily")
	local layout, eventActive, revealing, shopOpen = nil, false, false, false
	local function resize()
		layout = Layout.Compute(root.AbsoluteSize.X, root.AbsoluteSize.Y, UserInputService.TouchEnabled)
		for i, button in ipairs(buttons) do
			if not shopOpen or (button ~= navigation.Shop and button ~= navigation.Upgrades) then
				C.Place(button, layout.Nav[i])
				button.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 12 else 10
				button.Label.UITextSizeConstraint.MaxTextSize = if layout.Phone then 12 else 22
				button.Label.Size = UDim2.fromScale(0.96, if layout.Phone then 0.3 else 0.25)
				if names[i] == "Upgrades" then
					button.Text = if layout.Phone then "Upg." else "Upgrades"
				end
				local icon = button:FindFirstChild((if names[i] == "Rebirth" then "Crown" else names[i]) .. "Icon")
				if icon then
					icon.Size = UDim2.fromScale(0.6, 0.52)
					icon.Position = UDim2.fromScale(0.2, if layout.Phone then 0.16 else 0.035)
					if not layout.Phone then
						icon.Size = UDim2.fromScale(0.67, 0.65)
						icon.Position = UDim2.fromScale(0.165, 0.035)
					end
				end
			end
		end
		for object, r in pairs({
			[travel] = layout.Travel,
			[settings] = layout.Settings,
			[wallet] = layout.Coins,
			[boost] = layout.Boosts,
			[socialChip] = layout.SocialBoosts,
			[hint] = layout.Hint,
			[action] = layout.Action,
			[offers] = layout.Offers,
		}) do
			C.Place(object, r)
		end
		offers.Visible = layout.OffersVisible
		travel.Visible = not eventActive
		auto.Size = UDim2.new(0, 84, 1, 0)
		boost.Visible, socialChip.Visible = not layout.Phone, not layout.Phone
		passHint.Visible, dailyHint.Visible = layout.Phone == true, layout.Phone == true
		passHint.Text = if layout.Phone then "STYLE" else ""
		for badge, defaults in pairs(badgeDefaults) do
			badge.Frame.Size = if layout.Phone then UDim2.fromOffset(22, 22) else defaults.Size
			badge.Frame.Position = if layout.Phone then UDim2.new(1, -22, 0, 0) else defaults.Position
			defaults.Label.Size = if layout.Phone then UDim2.new(1, -4, 1, -2) else defaults.LabelSize
			defaults.Label.Position = if layout.Phone then UDim2.fromOffset(2, 1) else defaults.LabelPosition
			defaults.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 12 else defaults.Minimum
		end
		coins.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
		coins.UITextSizeConstraint.MaxTextSize = if layout.Phone then 24 else 58
		hintTitle.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
		hintTitle.UITextSizeConstraint.MaxTextSize = if layout.Phone then 22 else 38
		hintDetail.UITextSizeConstraint.MinTextSize = if layout.Phone then 12 else 10
		hintDetail.UITextSizeConstraint.MaxTextSize = if layout.Phone then 16 else 17
		skip.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
		for _, button in ipairs(travel:GetChildren()) do
			if button:IsA("TextButton") then
				button.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
				button.Label.UITextSizeConstraint.MaxTextSize = if layout.Phone then 16 else 30
				local icon = button:FindFirstChild(button.Name .. "Icon")
				if icon then
					icon.Visible = not layout.Phone
				end
				button.Label.Position = if layout.Phone then UDim2.fromScale(0.04, 0.1) else UDim2.fromScale(0.29, 0.12)
				button.Label.Size = if layout.Phone then UDim2.fromScale(0.92, 0.8) else UDim2.fromScale(0.66, 0.76)
			end
		end
		if layout.Phone then
			C.Place(mobileStatus, layout.Status)
			flush.Size, idle.Size = UDim2.new(1, -80, 1, 0), UDim2.new(1, -80, 1, 0)
			auto.Size, auto.Position = UDim2.new(0, 74, 1, 0), UDim2.new(1, -74, 0, 0)
		else
			flush.Size, idle.Size = UDim2.new(1, -96, 1, 0), UDim2.new(1, -96, 1, 0)
			mobileStatus.Label.UITextSizeConstraint.MinTextSize = 14
			mobileStatus.Visible = false
		end
		flush.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
		flush.Label.UITextSizeConstraint.MaxTextSize = if layout.Phone then 18 else 42
		idle.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
		idle.Label.UITextSizeConstraint.MaxTextSize = if layout.Phone then 14 else 20
		auto.Label.UITextSizeConstraint.MinTextSize = if layout.Phone then 14 else 10
		auto.Label.TextWrapped = layout.Phone == true
		autoIcon.Visible, autoTitle.Visible = layout.Phone == true, layout.Phone == true
		auto.Label.Position = if layout.Phone then UDim2.fromScale(0.04, 0.28) else UDim2.fromScale(0.06, 0.12)
		auto.Label.Size = if layout.Phone then UDim2.fromScale(0.92, 0.65) else UDim2.fromScale(0.88, 0.76)
		autoProgress.Frame.Visible = not layout.Phone
		pointer.Visible = false
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
		local elapsed = math.max(0, os.clock() - statusAt)
		idle.Text = if layout.Phone then "Still there?\nTap" else "Still there? Tap to continue"
		local idleLeft = math.max(0, math.ceil((autoStatus.IdleRemaining or 0) - elapsed))
		local paused = autoStatus.Paused == true
		local collecting = autoStatus.CollectEnabled == true
		local running = autoEnabled and not paused and os.clock() < autoRunningUntil
		idle.Visible = (autoEnabled or collecting) and paused
		flush.Visible = not idle.Visible
		if autoUnlocked then
			local uptime = math.floor((autoStatus.Uptime or 0) + (if autoEnabled and not paused then elapsed else 0))
			auto.Text = "AUTO\n"
				.. (if autoEnabled
					then (if paused then "PAUSED\n" .. timer(uptime) else "ON " .. timer(uptime))
					else "OFF")
				.. (
					if autoEnabled
							and not paused
							and idleLeft <= AutoConfig.IdleWarningSeconds
						then "\nIdle " .. timer(idleLeft)
						else ""
				)
		else
			auto.Text = "AUTO\n" .. (if state then state.LifetimeFlushes else 0) .. "/" .. Monetization.AutoFlushUnlock
		end
		-- Extend the existing automation chip upwards, keeping the action's bottom edge.
		auto.Size = UDim2.new(0, 84, 1, if collecting then 40 else 0)
		auto.Position = UDim2.new(1, -84, 0, if collecting then -40 else 0)
		if collecting then
			if not autoEnabled and not paused and idleLeft <= AutoConfig.IdleWarningSeconds then
				auto.Text ..= "\nIdle " .. timer(idleLeft)
			end
			auto.Text ..= "\nCOLLECT\n" .. (if paused
				then "PAUSED"
				elseif autoStatus.CollectRunning then "ON / 5s"
				else "WAITING")
		end
		autoDetail.Text = auto.Text
		if layout.Phone then
			auto.Size, auto.Position = UDim2.new(0, 74, 1, 0), UDim2.new(1, -74, 0, 0)
			auto.Text = (
				if paused
					then "PAUSE"
					elseif autoEnabled then "ON"
					elseif autoUnlocked then "OFF"
					else tostring(if state then state.LifetimeFlushes else 0) .. "/" .. Monetization.AutoFlushUnlock
			)
				.. (
					if collecting
						then "\nCOLLECT\n" .. (if paused
							then "PAUSED"
							elseif autoStatus.CollectRunning then "ON"
							else "WAIT")
						else ""
				)
		end
		auto.Label.TextTransparency = if collecting or autoUnlocked then 0 else 0.4
		flush.Interactable = state ~= nil and (not near or remaining <= 0)
		flush.Text = if not state
			then "LOADING..."
			elseif autoEnabled and not near then (if running then "Auto Flush running" else "Auto Flush waiting")
			elseif not near then "GO TO YOUR TOILET"
			elseif remaining > 0 then string.format("%.1fs", remaining)
			else "FLUSH"
		if layout.Phone and state and not near and not autoEnabled then
			flush.Text = "GO TO\nTOILET"
		end
		flushIcon.Visible = (near or running) and not layout.Phone
		-- Reuse the action icon: one scalar update, no new instances or repeating tweens.
		flushIcon.Rotation = if running then math.sin((os.clock() - autoPulseAt) * 8) * 12 else 0
		flush.Label.Position = if near or running then UDim2.fromScale(0.28, 0.1) else UDim2.fromScale(0.05, 0.1)
		flush.Label.Size = if near or running then UDim2.fromScale(0.69, 0.8) else UDim2.fromScale(0.9, 0.8)
		if layout.Phone then
			flush.Label.Position, flush.Label.Size = UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8)
		end
		ring.Visible = remaining > 0
		for i, tick in ipairs(ticks) do
			tick.Visible = i <= math.ceil(remaining / cooldown * 24)
		end
		local coinPopup = gui:FindFirstChild("ServiceCoinPopup")
		pointer.Visible = not layout.Phone
			and near
			and remaining == 0
			and not autoEnabled
			and not revealing
			and not coinPopup
		if pointer.Visible then
			pointer.Size = UDim2.fromOffset(layout.Pointer.W, layout.Pointer.H)
			pointer.Position = UDim2.fromOffset(
				layout.Pointer.X - layout.Action.X,
				layout.Pointer.Y - layout.Action.Y + math.sin(os.clock() * 4) * 3
			)
		end
		flush.Position = UDim2.fromOffset(0, if pointer.Visible then math.sin(os.clock() * 4) * 2 else 0)
		if state and not tutorial and not autoEnabled and not near and os.clock() - lastAwayHint > 30 then
			lastAwayHint = os.clock()
			showHint("Find your toilet", "Tap Home to return")
		end
		local hintLeft = if tutorial and hintUntil > 0 then 1 else hintUntil - os.clock()
		hint.Visible = hintLeft > 0 and not revealing and not eventActive and not coinPopup
		socialChip.Visible = not layout.Phone and not revealing and not coinPopup
		hint.GroupTransparency = math.clamp(1 - hintLeft / 0.5, 0, 1)
	end)
	local characterRemoving = game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
		autoEnabled, autoRunningUntil, flushIcon.Rotation = false, 0, 0
		autoStatus.CollectEnabled, autoStatus.CollectRunning = false, false
	end)
	gui.Destroying:Connect(function()
		heartbeat:Disconnect()
		characterRemoving:Disconnect()
	end)
	task.spawn(function()
		while gui.Parent do
			socialChip.Text = SocialUI.ChipText(socialState, os.clock() - socialAt)
			local now = workspace:GetServerTimeNow()
			local serverLeft, personalLeft =
				math.max(0, math.ceil(serverExpiry - now)), math.max(0, math.ceil(personalExpiry - now))
			local eligible = luckState and luckState.Allowed and os.clock() < luckDeadline
			local odds = eligible and luckState.Odds
			local total = if odds
				then (if luckState.Count > 0 and luckState.Armed then odds.Luck else odds.BaseLuck)
				else (luckState and luckState.FreeLuck)
					or (state and state.UpgradeStats and state.UpgradeStats.LuckMultiplier)
					or 1
			local friends = socialState.FriendCount or 0
			mobileStatus.Text =
				string.format("Luck x%.3g - Friends +%d%%", total, math.round(friends * SocialConfig.FriendBonus * 100))
			mobileStatus.Visible = layout.Phone == true
				and (
					total ~= 1
					or friends > 0
					or socialState.GroupMember == true
					or personalLeft > 0
					or serverLeft > 0
					or (socialState.InviteRemaining or 0) > 0
				)
			statusText.Text = mobileStatus.Text
				.. "\n"
				.. SocialUI.ChipText(socialState, os.clock() - socialAt)
				.. (if personalLeft > 0 then "\nDaily x2: " .. timer(personalLeft) else "")
				.. (if serverLeft > 0 then "\nServer x2: " .. timer(serverLeft) else "")
			serverText.Text = (if total >= 1e6 then "Luck\nx" else "Luck x") .. Format.Luck(total)
			breakdown.Text = string.format(
				"Total luck x%s (no cap)\n%s\n%s\nRounded; see Info for all item odds.",
				Format.Luck(total, true),
				if eligible
					then (if odds and odds.VIPLuck then "VIP +25% luck" else "VIP luck: inactive")
					else "VIP luck unavailable in your region",
				if eligible
					then (if odds and odds.DoubleLuck then "2x Luck pass" else "2x Luck pass: inactive")
					else "2x Luck unavailable in your region"
			)
			if serverLeft > 0 then
				breakdown.Text ..= "\nServer x2: " .. timer(serverLeft)
			end
			if luckState and not eligible then
				luckState = table.clone(luckState)
				luckState.Allowed = false
				luckDialog.Close()
			end
			personalText.Text = if personalLeft > 0
				then "Daily x2\n" .. timer(personalLeft)
				else "Daily boost\nDay 7 reward"
			if state then
				local ready, _, nextAt = Schedule.Progress(state.LastClaimDay, state.Streak, now, Rewards)
				dailyBadge.Set(if ready and not layout.Phone then 1 else 0)
				dailyHint.Text = if ready then "READY" else timer(math.max(0, math.ceil(nextAt - now)))
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
		StatusPanel = statusDetails,
		Navigation = navigation,
		SetShopNavigation = function(active)
			if not shopNavigation or shopOpen == active then
				return
			end
			shopOpen = active
			-- Keep the actual HUD buttons reachable while the rest of the HUD is hidden.
			for i, name in ipairs({ "Shop", "Upgrades" }) do
				local button = navigation[name]
				button.Parent = if active then shopNavigation else gui
				local z = if active then shopNavigation.ZIndex + 2 else gui.ZIndex + 2
				local delta = z - button.ZIndex
				button.ZIndex = z
				for _, object in ipairs(button:GetDescendants()) do
					if object:IsA("GuiObject") then
						object.ZIndex += delta
					end
				end
				button[name .. "Icon"].Visible = not active
				button.Label.Position = if active then UDim2.fromScale(0.06, 0.12) else UDim2.fromScale(0.02, 0.7)
				button.Label.Size = if active then UDim2.fromScale(0.88, 0.76) else UDim2.fromScale(0.96, 0.25)
				if active then
					button.Size = UDim2.new(0.5, -5, 0, 44)
					button.Position = UDim2.new((i - 1) * 0.5, (i - 1) * 5, 0, 0)
				end
			end
			resize()
		end,
		FlushButton = flush,
		SetTutorialActive = function(active)
			tutorial = active
			if active then
				hintUntil, hint.Visible = 0, false
			end
		end,
		Hint = hint,
		EventActive = function(active)
			eventActive = active
			resize()
		end,
		SetTutorial = function(title, detail, onSkip)
			tutorial = title ~= nil
			hintTitle.Size = UDim2.new(1, if onSkip then -56 else 0, 0.55, 0)
			if title then
				showHint(title, detail)
			else
				hintUntil, hintKey = 0, nil
			end
			skipCallback, skip.Visible = onSkip, onSkip ~= nil
		end,
		SetHintVisible = function(visible)
			hint.Visible = visible and hintUntil > os.clock()
			revealing = not visible
		end,
		Update = function(snapshot)
			socialState, socialAt = snapshot.Social or {}, os.clock()
			socialChip.Text = SocialUI.ChipText(socialState)
			state = snapshot
			autoStatus, statusAt = state.AutoStatus or {}, os.clock()
			rebirthBadge.Set(if rebirth:Eligible(state, rebirth:Level(state)) then 1 else 0)
			if coinTarget ~= state.Coins then
				coinTarget = state.Coins
				C.Tween(value, 0.55, { Value = state.Coins })
			end
			autoUnlocked, autoEnabled = state.LifetimeFlushes >= Monetization.AutoFlushUnlock, state.AutoFlush
			if not autoEnabled or autoStatus.Paused then
				autoRunningUntil, flushIcon.Rotation = 0, 0
			end
			auto.Interactable = autoUnlocked
			auto.Text = if autoUnlocked
				then (if autoEnabled then "AUTO\nON" else "AUTO\nOFF")
				else "AUTO\n" .. state.LifetimeFlushes .. "/" .. Monetization.AutoFlushUnlock
			autoProgress.Set(state.LifetimeFlushes / Monetization.AutoFlushUnlock)
			serverExpiry, personalExpiry = state.ServerLuckExpires or 0, state.RewardLuckExpires or 0
			luckState = state.Commerce and state.Commerce.Lucky
			luckDeadline = os.clock() + ((luckState or {}).PolicyRemaining or 0)
			luckDialog.Invalidate(luckState)
		end,
		Flushed = function(payload)
			if
				autoEnabled
				and not autoStatus.Paused
				and payload.Automatic
				and not payload.Admin
				and (payload.FlushId or 0) > lastAutoId
			then
				lastAutoId = payload.FlushId
				autoPulseAt = os.clock()
				autoRunningUntil = autoPulseAt
					+ (payload.AutoInterval or payload.Cooldown or 3)
					+ AutoConfig.StatusGrace
			end
			cooldown = math.max(0.1, payload.Cooldown or 3)
			untilAt = os.clock() + cooldown
		end,
		Luck = function(expires)
			serverExpiry = expires
		end,
		Best = function()
			-- The server owns the landmark record. Rare events already have a timed banner.
		end,
	}
end
return HUD
