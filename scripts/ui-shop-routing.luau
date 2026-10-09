-- Exercise production init.open through the actual HUD buttons and world prompts.
do
	local hud = clientRoot.HUD
	local shop, upgrades = hud.Shop, hud.Upgrades
	local panel = clientRoot["Toilet Upgrades"]
	local body = panel.ContentScroll.Body
	local toilets, coins = body.ToiletCards, body.PermanentUpgradeTracks
	local toiletTab = body:FindFirstChild("Toilets", true)
	local coinTab = body:FindFirstChild("Coin Upgrades", true)
	local title = panel.TitleBar:FindFirstChildWhichIsA("TextLabel")
	local backdrop = clientRoot.ModalBackdrop
	backdrop.Activated:Fire()
	local before = #H.Calls
	local function checkTab(name)
		assert(panel.Visible and backdrop.Visible and not hud.Visible)
		assert(toilets.Visible == (name == "Toilets") and coins.Visible == (name == "Coin Upgrades"))
		assert(title.Text == (if name == "Toilets" then "Toilet Shop" else "Upgrades"))
		assert(shop.Parent == body.ShopNavigation and upgrades.Parent == body.ShopNavigation)
		local selected = if name == "Toilets" then toiletTab else coinTab
		assert(selected.Background.UIStroke.Color == H.Load("src/client/UI/Components").Gold)
	end
	local function closed()
		assert(not panel.Visible and not backdrop.Visible and hud.Visible)
		assert(shop.Parent == hud and upgrades.Parent == hud, "HUD navigation did not return after close")
	end
	shop.Activated:Fire()
	checkTab("Toilets")
	coinTab.Activated:Fire()
	checkTab("Coin Upgrades")
	shop.Activated:Fire() -- Same opener closes even after a manual tab switch.
	closed()
	upgrades.Activated:Fire()
	checkTab("Coin Upgrades")
	toiletTab.Activated:Fire()
	checkTab("Toilets")
	upgrades.Activated:Fire()
	closed()
	for _ = 1, 3 do
		shop.Activated:Fire()
		checkTab("Toilets")
		upgrades.Activated:Fire()
		checkTab("Coin Upgrades")
		shop.Activated:Fire()
		checkTab("Toilets")
		panel.TitleBar.X.Activated:Fire()
		closed()
	end
	upgrades.Activated:Fire()
	backdrop.Activated:Fire()
	closed()
	shop.Activated:Fire()
	local closeAction = H.Actions.CloseToiletPanel
	assert(closeAction.Keys[1] == "KeyCode.ButtonB")
	assert(closeAction.Callback(nil, "UserInputState.Begin") == "ContextActionResult.Sink")
	closed()
	assert(closeAction.Callback(nil, "UserInputState.Begin") == "ContextActionResult.Pass")
	local station = H.Instance.new("ProximityPrompt")
	station:SetAttribute("StationPanel", "Upgrades")
	H.Services.ProximityPromptService.PromptTriggered:Fire(station)
	checkTab("Coin Upgrades")
	station:SetAttribute("StationPanel", "Shop")
	H.Services.ProximityPromptService.PromptTriggered:Fire(station)
	checkTab("Toilets")
	backdrop.Activated:Fire()
	station:Destroy()
	assert(not hud.Travel:FindFirstChild("Shop"), "Duplicate Shop in travel bar")
	hud.Index.Activated:Fire()
	shop.Activated:Fire()
	assert(not clientRoot["My Collection"].Visible, "Shop left another modal open")
	checkTab("Toilets")
	assert(#H.Calls == before, "Tab routing sent a purchase request")
	local function visible(object)
		while object and object ~= clientRoot do
			if object:IsA("GuiObject") and not object.Visible then
				return false
			end
			object = object.Parent
		end
		return true
	end
	local touchBefore = H.Services.UserInputService.TouchEnabled
	for _, touch in ipairs({ false, true }) do
		H.Services.UserInputService.TouchEnabled = touch
		for _, size in ipairs(H.Viewports) do
			clientRoot._fixed, clientRoot._abs = { X = size[1], Y = size[2] }, nil
			clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
			for _, button in ipairs({ shop, upgrades }) do
				backdrop.Activated:Fire()
				button.Activated:Fire({ UserInputType = "UserInputType.Gamepad1" })
				checkTab(if button == shop then "Toilets" else "Coin Upgrades")
				H.Layout(clientRoot)
				for _, entry in ipairs({ shop, upgrades, toiletTab, coinTab }) do
					local p, s = entry.AbsolutePosition, entry.AbsoluteSize
					assert(visible(entry) and entry.Interactable and entry.Selectable ~= false)
					assert(s.X >= 44 and s.Y >= 44 and p.X >= 0 and p.Y >= 0)
					assert(p.X + s.X <= size[1] and p.Y + s.Y <= size[2])
					assert(entry.ZIndex > backdrop.ZIndex, "Navigation is behind the modal backdrop")
				end
				H.Snapshot(
					clientRoot,
					(if button == shop then "toilet-shop-" else "coin-upgrades-") .. size[1] .. "x" .. size[2]
				)
				button.Activated:Fire({ UserInputType = "UserInputType.Keyboard" })
				closed()
			end
		end
	end
	H.Services.UserInputService.TouchEnabled = touchBefore
	clientRoot._fixed, clientRoot._abs = { X = 1280, Y = 684 }, nil
	clientRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
	-- Use the real bootstrap: checkpoints, routed entries, tabs and affordable actions.
	backdrop.Activated:Fire()
	local tutorialState = table.clone(state)
	tutorialState.TutorialDone, tutorialState.TutorialStep = false, 4
	tutorialState.Coins, tutorialState.ToiletTier = 1000, 1
	bootRemotes.State.OnClientEvent:Fire(tutorialState)
	H.Advance(0.3)
	local guide = clientRoot.Tutorial
	assert(guide.Detail.Text:find("Upgrades for Coin Upgrades", 1, true))
	assert(guide.Detail.Text:find("Shop for Toilets in the Toilet Shop", 1, true))
	assert(upgrades:FindFirstChild("TutorialHighlight") and not shop:FindFirstChild("TutorialHighlight"))
	shop.Activated:Fire()
	H.Layout(clientRoot)
	H.Advance(0.3)
	assert(coinTab:FindFirstChild("TutorialHighlight"), "Unaffordable toilet needs the coin-upgrade tab")
	coinTab.Activated:Fire()
	H.Layout(clientRoot)
	H.Advance(0.3)
	local cashBuy = coins.CashBoost.Buy
	assert(cashBuy:FindFirstChild("TutorialHighlight") and cashBuy.Interactable)
	backdrop.Activated:Fire()
	upgrades.Activated:Fire()
	checkTab("Coin Upgrades")
	H.Layout(clientRoot)
	H.Advance(0.3)
	assert(cashBuy:FindFirstChild("TutorialHighlight"), "Upgrades entry must highlight a coin purchase")
	backdrop.Activated:Fire()
	tutorialState.Coins = 100000
	bootRemotes.State.OnClientEvent:Fire(tutorialState)
	shop.Activated:Fire()
	checkTab("Toilets")
	H.Layout(clientRoot)
	H.Advance(0.3)
	local toiletBuy = toilets[H.Load("src/shared/Config/Toilets")[2].Id].Locked
	assert(toiletBuy:FindFirstChild("TutorialHighlight") and toiletBuy.Interactable)
	backdrop.Activated:Fire()
	bootRemotes.State.OnClientEvent:Fire(state)
	print(
		"Shop routing passed: entry tabs/titles, toggles, manual tabs, close paths, travel, tutorial and 12 viewports with mouse/touch/controller/keyboard callbacks"
	)
end
