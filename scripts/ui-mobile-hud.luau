-- Executes production constructors. PNGs use the existing offline tree renderer.
do
	local cases = {
		{ 375, 667, 0, 36, 0, 21 },
		{ 375, 812, 0, 88, 0, 34 },
		{ 390, 844, 0, 88, 0, 34 },
		{ 360, 740, 0, 88, 0, 34 },
		{ 430, 932, 0, 88, 0, 34 },
		{ 812, 375, 44, 36, 44, 21 },
		{ 844, 390, 44, 36, 44, 21 },
		{ 932, 430, 44, 36, 44, 21 },
		{ 667, 375, 0, 36, 0, 21 },
		{ 568, 320, 0, 36, 0, 21 },
		{ 740, 360, 44, 36, 44, 21 },
		{ 640, 360, 0, 36, 0, 21 },
		{ 1170, 540, 54, 36, 0, 21 },
		{ 768, 1024, 0, 36, 0, 20 },
	}
	local function bounds(o)
		return { X = o.AbsolutePosition.X, Y = o.AbsolutePosition.Y, W = o.AbsoluteSize.X, H = o.AbsoluteSize.Y }
	end
	local function overlaps(a, b)
		return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
	end
	for _, case in ipairs(cases) do
		local width, height, left, top, right, bottom = table.unpack(case)
		local w, h = width - left - right, height - top - bottom
		H.Services.UserInputService.TouchEnabled = true
		local root, remotes = H.Root(w, h), H.Remotes()
		local near = true
		local prompts = {
			Near = function()
				return near
			end,
		}
		local shop = H.Load("src/client/UI/Upgrades").Create(root, remotes)
		local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, prompts, shop.Navigation)
		local components = H.Load("src/client/UI/Components")
		local admin = H.Load("src/admin-client/Window")
			.Create(root, { OnClientEvent = H.Signal(), FireServer = function() end }, components)
		local dance = H.Load("src/client/DancePackEffects").Start(root, H.Services.Players.LocalPlayer, remotes)
		assert(not root.CelebrationMenu.Visible, "Dance button shown without ownership")
		H.Load("src/client/UI/IncomeChip").Create(hud.Frame).Update(12345)
		local state = {
			Coins = 1234567,
			ToiletTier = 1,
			Inventory = { Poop = 1 },
			Collection = { Poop = 1 },
			Displays = {},
			DisplaySlots = 3,
			Upgrades = {},
			LifetimeFlushes = 12,
			AutoFlush = false,
			IndexClaims = {},
			IndexCosmetics = {},
			Stamps = 0,
			LastClaimDay = 0,
			Streak = 0,
			TutorialDone = false,
			TutorialStep = 2,
			TutorialRun = 0,
			UpgradeStats = { LuckMultiplier = 2.5 },
			Social = { FriendCount = 3 },
		}
		hud.Update(state)
		state.OwnedPasses = { DancePack = true }
		remotes.State.OnClientEvent:Fire(state)
		assert(root.CelebrationMenu.Visible)
		H.StartTasks()
		H.Advance(1.1)
		H.Layout(root)
		local phone = width ~= 768
		local flush = hud.FlushButton
		if phone then
			state.UpgradeStats.LuckMultiplier, state.Social = 1, { FriendCount = 0 }
			hud.Update(state)
			H.Advance(1.1)
			H.ResumeTasks()
			assert(not hud.Frame.PhoneStatus.Visible, "Neutral phone status must be hidden")
			state.Social.GroupMember = true
			hud.Update(state)
			H.Advance(1.1)
			H.ResumeTasks()
			assert(hud.Frame.PhoneStatus.Visible, "Active group boost must expose details")
			state.UpgradeStats.LuckMultiplier, state.Social = 2.5, { FriendCount = 3 }
			hud.Update(state)
			H.Advance(1.1)
			H.ResumeTasks()
			H.Layout(root)
			local layout = H.Load("src/client/UI/Layout").Compute(w, h, true)
			local elements = {
				hud.Frame.Travel,
				hud.Frame.Wallet,
				hud.Frame.PendingIncome,
				hud.Frame.PhoneStatus,
				root.CelebrationMenu,
				admin.Open,
				hud.Frame.Settings,
			}
			for _, name in ipairs({ "Shop", "Rebirth", "Collection", "Upgrades", "Passes", "Daily" }) do
				table.insert(elements, hud.Navigation[name])
			end
			table.insert(elements, hud.Frame.FlushActions)
			local zones = {
				{ X = 0, Y = h * 0.6, W = w * 0.28, H = h * 0.4 },
				{ X = w * 0.78, Y = h * 0.65, W = w * 0.22, H = h * 0.35 },
			}
			for i, object in ipairs(elements) do
				local r = bounds(object)
				assert(r.X >= 0 and r.Y >= 0 and r.X + r.W <= w and r.Y + r.H <= h, object.Name .. " outside safe area")
				for _, zone in ipairs(zones) do
					assert(
						object.Name == "PendingIncome"
							or (object.Name == "PhoneStatus" and layout.Portrait)
							or not overlaps(r, zone),
						object.Name .. " in thumb zone"
					)
				end
				for j, other in ipairs(elements) do
					if i < j then
						assert(not overlaps(r, bounds(other)), object.Name .. " overlaps " .. other.Name)
					end
				end
			end
			assert(
				not hud.Frame.Offers.Visible and not hud.Frame.Boosts.Visible and not hud.Frame.SocialBoostsChip.Visible
			)
			local targets = {
				flush,
				hud.Frame.FlushActions.AutoFlushSwitch,
				hud.Frame.PhoneStatus,
				hud.Frame.Travel.Hub,
				hud.Frame.Travel.Home,
				hud.Frame.Settings,
			}
			for _, b in pairs(hud.Navigation) do
				table.insert(targets, b)
			end
			for _, b in ipairs(targets) do
				assert(b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, b.Name .. " target below 44px")
				assert(b.Label.UITextSizeConstraint.MinTextSize >= 14, b.Name .. " text too small")
			end
			assert(flush.Label.UITextSizeConstraint.MinTextSize >= 14)
			assert(hud.Frame.FlushActions.AutoFlushSwitch.Label.UITextSizeConstraint.MinTextSize >= 14)
			assert(hud.Frame.Wallet:FindFirstChildWhichIsA("TextLabel").UITextSizeConstraint.MinTextSize >= 14)
			local pending = hud.Frame.PendingIncome
			assert(pending.AbsoluteSize.X == 110 and pending.AbsoluteSize.Y == 28)
			assert(not pending.Active and not pending.Selectable and not pending:IsA("GuiButton"))
			assert(pending:FindFirstChildWhichIsA("TextLabel").UITextSizeConstraint.MinTextSize >= 12)
			local jump = {
				X = w * 0.78,
				Y = if layout.Portrait then h - 96 else h * 0.65,
				W = w * 0.22,
				H = if layout.Portrait then 96 else h * 0.35,
			}
			assert(not overlaps(bounds(hud.Frame.PhoneStatus), jump))
			assert(hud.Frame.PhoneStatus.AbsoluteSize.X <= 136)
			assert(not hud.Frame.Travel:FindFirstChild("Shop"))
			if not layout.Portrait then
				assert(layout.Hint.Y == 64 and layout.Hint.H <= 76, "Landscape hint must sit below top bar")
				assert(layout.Nav[1].H == 44 and layout.Nav[4].Y > layout.Nav[1].Y)
			end
			hud.Frame.PhoneStatus.Activated:Fire()
			assert(root["Boost details"].Visible and not hud.Frame.Visible)
			root["Boost details"].TitleBar.X.Activated:Fire()
			assert(hud.Frame.Visible)
		end
		local prefix = string.format("mobile-%dx%d", width, height)
		H.Snapshot(root, prefix .. "-hud")
		local guide = H.Load("src/client/UI/Tutorial").Create(H.Services.Players.LocalPlayer, remotes, hud, prompts)
		remotes.State.OnClientEvent:Fire(state)
		H.Advance(0.3)
		H.Layout(root)
		local card = root.Tutorial
		assert(card.Visible and not overlaps(bounds(card), bounds(flush)))
		if phone then
			assert(card.BackgroundTransparency >= 0.25)
			assert(card.Detail.UITextSizeConstraint.MinTextSize >= 14)
			for _, chip in ipairs({ hud.Frame.PendingIncome, hud.Frame.PhoneStatus }) do
				assert(not overlaps(bounds(card), bounds(chip)), "Tutorial overlaps lower chip")
			end
		end
		for _, b in pairs(hud.Navigation) do
			assert(not overlaps(bounds(card), bounds(b)))
		end
		H.Snapshot(root, prefix .. "-tutorial")
		if phone then
			components.Toast(root)("A new item was collected!")
			H.Advance(0.3)
			H.Layout(root)
			assert(not overlaps(bounds(root.ResultToast), bounds(card)), "Toast overlaps tutorial Skip")
			for _, chip in ipairs({ hud.Frame.PendingIncome, hud.Frame.PhoneStatus }) do
				assert(not overlaps(bounds(root.ResultToast), bounds(chip)), "Result toast overlaps lower chip")
			end
			root.ResultToast.Visible = false
		end
		card.SkipTutorial.Activated:Fire()
		for _, module in ipairs({ "Passes", "Upgrades", "Collection", "Rebirth", "Rewards" }) do
			local window = if module == "Upgrades"
				then shop
				else H.Load("src/client/UI/" .. module).Create(root, remotes)
			window.Update(state)
			window.Panel.Visible = true
			hud.Frame.Visible = false
			H.Layout(root)
			local p, close = window.Panel, window.Panel.TitleBar.X
			assert(p.AbsolutePosition.X >= 0 and p.AbsolutePosition.Y >= 0)
			assert(p.AbsolutePosition.X + p.AbsoluteSize.X <= w and p.AbsolutePosition.Y + p.AbsoluteSize.Y <= h)
			assert(close.AbsoluteSize.X >= 44 and close.AbsoluteSize.Y >= 44)
			assert(close.AbsolutePosition.Y >= 0 and close.AbsolutePosition.Y + close.AbsoluteSize.Y <= h)
			if phone then
				for _, object in ipairs(p:GetDescendants()) do
					if object:IsA("GuiButton") then
						assert(
							object.AbsoluteSize.X >= 44 and object.AbsoluteSize.Y >= 44,
							p.Name .. "/" .. object.Name .. " target too small"
						)
					end
				end
			end
			assert(p.ContentScroll.AbsoluteSize.Y > 0)
			if module == "Upgrades" then
				hud.SetShopNavigation(true)
				H.Layout(root)
				H.Snapshot(root, prefix .. "-window")
			end
			if module == "Upgrades" then
				p.ContentScroll.Body.ToiletCards.CanvasPosition = { X = 0, Y = 164 }
				H.Layout(root)
				H.Snapshot(root, prefix .. "-window-scrolled")
				local buy = p:FindFirstChild("Locked", true)
				if buy then
					components.ScrollTo(buy)
					H.Layout(root)
					components.ScrollTo(buy)
					H.Layout(root)
					local r, scroll = bounds(buy), bounds(p.ContentScroll.Body.ToiletCards)
					assert(
						r.Y >= scroll.Y and r.Y + r.H <= scroll.Y + scroll.H,
						"Phone window action unreachable by scrolling"
					)
				end
				hud.SetShopNavigation(false)
			end
			p.TitleBar.X.Activated:Fire()
			assert(not p.Visible)
			p:Destroy()
		end
		guide.Destroy()
		dance.Destroy()
		root:Destroy()
	end
	local settingsRoot = H.BootClient(H.Remotes())
	for _, case in ipairs(cases) do
		local width, height, left, top, right, bottom = table.unpack(case)
		local w, h = width - left - right, height - top - bottom
		settingsRoot._fixed, settingsRoot._abs = { X = w, Y = h }, nil
		settingsRoot:GetPropertyChangedSignal("AbsoluteSize"):Fire()
		local previousToast = settingsRoot:FindFirstChild("ResultToast")
		if previousToast then
			previousToast.Visible = false
		end
		settingsRoot.Settings.Visible = true
		H.Layout(settingsRoot)
		local close = settingsRoot.Settings.TitleBar.X
		assert(close.AbsolutePosition.X >= 0 and close.AbsolutePosition.X + close.AbsoluteSize.X <= w)
		assert(close.AbsolutePosition.Y >= 0 and close.AbsolutePosition.Y + close.AbsoluteSize.Y <= h)
		assert(close.AbsoluteSize.X >= 44 and close.AbsoluteSize.Y >= 44)
		H.Snapshot(settingsRoot, string.format("mobile-%dx%d-settings", width, height))
		close.Activated:Fire()
		assert(not settingsRoot.Settings.Visible)
		settingsRoot:SetAttribute("TutorialActive", true)
		for _, panel in ipairs(settingsRoot:GetDescendants()) do
			if panel:IsA("Frame") and panel:FindFirstChild("TitleBar") then
				panel.Visible = true
				H.Load("src/client/UI/Components").Toast(settingsRoot)("Permanent upgrade purchased!")
				H.Layout(settingsRoot)
				local toast = settingsRoot.ResultToast
				assert(not overlaps(bounds(toast), bounds(panel.TitleBar)), panel.Name .. " phone toast covers header")
				assert(not overlaps(bounds(toast), bounds(panel.TitleBar.X)), panel.Name .. " phone toast covers Close")
				panel.Visible = false
			end
		end
		settingsRoot:SetAttribute("TutorialActive", false)
	end
	settingsRoot:Destroy()
	H.Services.UserInputService.TouchEnabled = false
	print(
		"Mobile production UI: "
			.. #cases
			.. " viewports, lower chips, targets, text, HUD/window/tutorial previews passed"
	)
end
