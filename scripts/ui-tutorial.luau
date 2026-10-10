-- Shared by the UI and audit runners; execute the production tutorial and its hooks.
do
	local check = test or function(name, callback)
		callback()
		print("PASS " .. name)
	end
	local viewports = H.Viewports
		or {
			{ 1920, 1044 },
			{ 1280, 684 },
			{ 375, 690 },
			{ 724, 318 },
			{ 1024, 712 },
			{ 768, 968 },
			{ 1116, 483 },
			{ 711, 751 },
			{ 711, 731 },
			{ 360, 518 },
			{ 390, 722 },
			{ 640, 303 },
		}
	local function fixture(w, h)
		local root, remotes = H.Root(w, h), H.Remotes()
		local near = false
		local prompts = {
			Near = function()
				return near
			end,
		}
		local collection = H.Load("src/client/UI/Collection").Create(root, remotes)
		local upgrades = H.Load("src/client/UI/Upgrades").Create(root, remotes)
		local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, prompts)
		local guide = H.Load("src/client/UI/Tutorial").Create(
			H.Services.Players.LocalPlayer,
			remotes,
			hud,
			prompts,
			{ Collection = collection, Upgrades = upgrades }
		)
		local state = {
			TutorialDone = false,
			TutorialStep = 1,
			TutorialRun = 0,
			Coins = 1000,
			ToiletTier = 1,
			Inventory = { Poop = 1 },
			Collection = { Poop = 1 },
			Displays = {},
			DisplaySlots = 3,
			Upgrades = {},
			LifetimeFlushes = 0,
			AutoFlush = false,
			IndexClaims = {},
			IndexCosmetics = {},
			Stamps = 0,
			LastClaimDay = 0,
			Streak = 0,
		}
		local function update(step, done)
			state.TutorialStep, state.TutorialDone = step, done == true
			collection.Update(state)
			upgrades.Update(state)
			hud.Update(state)
			remotes.State.OnClientEvent:Fire(table.clone(state))
			H.Layout(root)
			H.Advance(0.3)
			H.Layout(root)
		end
		return {
			Root = root,
			Remotes = remotes,
			HUD = hud,
			Guide = guide,
			Collection = collection,
			Upgrades = upgrades,
			State = state,
			Update = update,
			Near = function(value)
				near = value
			end,
		}
	end
	local function reachable(button, root)
		local top, bottom = button.AbsolutePosition.Y, button.AbsolutePosition.Y + button.AbsoluteSize.Y
		assert(top >= 0 and bottom <= root.AbsoluteSize.Y, "Highlighted action is outside the safe area")
		local parent = button.Parent
		while parent and parent ~= root do
			if parent:IsA("ScrollingFrame") then
				assert(
					top >= parent.AbsolutePosition.Y and bottom <= parent.AbsolutePosition.Y + parent.AbsoluteSize.Y,
					"Highlighted action is clipped by a scroll frame"
				)
			end
			parent = parent.Parent
		end
	end
	check(
		"tutorial UI: all steps stay visible, correct highlights and reachable modal actions at 12 viewports",
		function()
			for _, viewport in ipairs(viewports) do
				H.Services.UserInputService.TouchEnabled = viewport[1] < 1200
				local f = fixture(viewport[1], viewport[2])
				f.Update(1)
				if viewport[1] < 760 and viewport[2] > viewport[1] then
					local guide, social = f.Guide.Frame, f.Root.HUD.SocialBoostsChip
					if social.Visible then
						assert(
							guide.AbsolutePosition.Y + guide.AbsoluteSize.Y + 4 <= social.AbsolutePosition.Y,
							"Tutorial overlaps social boosts"
						)
					end
				end
				H.Snapshot(f.Root, "review-tutorial-1-" .. viewport[1] .. "x" .. viewport[2])
				assert(f.Guide.Frame.Visible and f.HUD.Navigation.Home:FindFirstChild("TutorialHighlight"))
				H.Advance(10)
				assert(f.Guide.Frame.Visible, "Tutorial expired after five seconds")
				f.Near(true)
				H.Advance(0.3)
				H.Snapshot(f.Root, "review-tutorial-2-" .. viewport[1] .. "x" .. viewport[2])
				assert(
					not H.Services.UserInputService.TouchEnabled
						or not f.Guide.Frame.Detail.Text:find("press E", 1, true)
				)
				assert(
					f.Guide.Frame.Title.Text:find("2/5", 1, true)
						and f.HUD.FlushButton:FindFirstChild("TutorialHighlight")
				)
				for _, result in ipairs({
					{ "Flush", { ItemId = "Poop", Admin = true } },
					{ "Sell", { Success = true } },
					{ "BuyToilet", { Success = true } },
					{ "BuyUpgrade", { Success = true } },
					{ "Display", { Success = true } },
					{ "Rebirth", { Success = true } },
					{ "BuyPass", { Success = true } },
				}) do
					f.Remotes.Result.OnClientEvent:Fire(result[1], result[2])
				end
				assert(f.Guide.Frame.Title.Text:find("2/5", 1, true), "Results bypassed saved checkpoint")
				f.Update(3)
				H.Snapshot(f.Root, "review-tutorial-3-" .. viewport[1] .. "x" .. viewport[2])
				assert(f.HUD.Navigation.Collection:FindFirstChild("TutorialHighlight"))
				-- The synthetic upgrade Result above also created a bounded result toast.
				H.Advance(5)
				local reveal = H.Instance.new("Frame")
				reveal.Name, reveal.Parent, reveal.Visible = "FlushReveal", f.HUD.Frame, true
				H.Advance(0.3)
				H.Layout(f.Root)
				assert(
					f.Guide.Frame.Visible and f.Guide.Frame.SkipTutorial.Visible and not f.Guide.Frame.Detail.Visible,
					"Reveal covered Skip or tutorial covered the item"
				)
				reveal:Destroy()
				H.Advance(0.3)
				assert(f.Guide.Frame.Detail.Visible, "Reveal dismissal did not restore instructions")
				f.Collection.Panel.Visible, f.HUD.Frame.Visible = true, false
				assert(f.Guide.Frame.Position.Y.Offset == 6, "Modal transition left the tutorial over its header")
				H.Layout(f.Root)
				H.Advance(0.3)
				H.Layout(f.Root)
				local button = f.Collection.TutorialTarget()
				H.Snapshot(f.Root, "review-tutorial-display-" .. viewport[1] .. "x" .. viewport[2])
				assert(button.Text == "Display" and button:FindFirstChild("TutorialHighlight"))
				reachable(button, f.Root)
				assert(
					(viewport[2] < 500 and not f.Guide.Frame.Visible)
						or (f.Guide.Frame.Visible and f.Guide.Frame.SkipTutorial.Visible)
				)
				assert(
					viewport[2] < 500 or f.Collection.Panel.AbsolutePosition.Y >= 90,
					"Tutorial covers modal close/header"
				)
				button.Activated:Fire()
				assert(H.Calls[#H.Calls].Name == "Display" and H.Calls[#H.Calls].Args[1] == "Poop")
				f.Update(4)
				f.Collection.Panel.Visible, f.Upgrades.Panel.Visible = false, true
				H.Layout(f.Root)
				H.Advance(0.3)
				local tab = f.Upgrades.TutorialTarget()
				assert(tab.Text == "Coin Upgrades" and tab:FindFirstChild("TutorialHighlight"))
				tab.Activated:Fire()
				H.Layout(f.Root)
				H.Advance(0.3)
				H.Layout(f.Root)
				local buy = f.Upgrades.TutorialTarget()
				assert(buy.Interactable and buy:FindFirstChild("TutorialHighlight"))
				reachable(buy, f.Root)
				buy.Activated:Fire()
				assert(H.Calls[#H.Calls].Name == "BuyUpgrade")
				local skip = f.Guide.Frame.SkipTutorial
				assert(skip.AbsoluteSize.X >= 44 and skip.AbsoluteSize.Y >= 44)
				assert(skip.AbsolutePosition.Y >= 0 and skip.AbsolutePosition.Y + skip.AbsoluteSize.Y <= viewport[2])
				assert(
					f.Guide.Frame.AbsolutePosition.X >= 0
						and f.Guide.Frame.AbsolutePosition.X + f.Guide.Frame.AbsoluteSize.X <= viewport[1]
				)
				if H.Viewports then
					H.Snapshot(f.Root, "tutorial-modal-" .. viewport[1] .. "x" .. viewport[2])
				end
				f.Update(5, true)
				H.Snapshot(f.Root, "review-tutorial-5-" .. viewport[1] .. "x" .. viewport[2])
				assert(
					(viewport[2] < 500 or f.Guide.Frame.Visible)
						and f.Guide.Frame.Title.Text:find("Tutorial complete!", 1, true)
				)
				H.Advance(7)
				assert(not f.Guide.Frame.Visible and not f.Root:GetAttribute("TutorialActive"))
				f.HUD.Frame.Visible, f.Upgrades.Panel.Visible = true, false
				f.Near(false)
				H.Advance(31)
				assert(f.HUD.Hint.Visible, "Completed tutorial erased normal away hints")
				f.Root:Destroy()
			end
		end
	)
	check(
		"tutorial UI: skip each step, acknowledgement retry, rejoin, completed suppression and replay timeout",
		function()
			for _, step in ipairs({ 1, 2, 3, 4, 5 }) do
				local f = fixture(390, 722)
				f.Update(step, step == 5)
				if step == 5 then
					assert(not f.Guide.Frame.Visible, "Completed profile reappeared on join")
				else
					assert(f.Guide.Frame.Title.Text:find(tostring(step) .. "/5", 1, true))
					f.Guide.Frame.SkipTutorial.Activated:Fire()
					assert(not f.Guide.Frame.Visible and H.Calls[#H.Calls].Name == "TutorialDone")
					H.Advance(3)
					assert(H.Calls[#H.Calls].Name == "TutorialDone", "Rejected dismissal cannot recover")
					f.Update(5, true)
				end
				f.Guide.Replay()
				f.Guide.Replay()
				assert(H.Calls[#H.Calls].Name == "TutorialReplay")
				f.State.TutorialRun += 1
				f.Update(1)
				assert(f.Guide.Frame.Visible and f.Guide.Frame.Title.Text:find("1/5", 1, true))
				f.Update(3)
				H.Advance(3)
				f.Guide.Replay()
				H.Advance(4)
				assert(H.Calls[#H.Calls].Name == "State" and f.Guide.Frame.Title.Text:find("3/5", 1, true))
				f.State.TutorialRun += 1
				f.Update(1)
				assert(f.Guide.Frame.Title.Text:find("1/5", 1, true), "Admin reset during active guide failed")
				f.Root:Destroy()
			end
		end
	)
	check("tutorial UI: luck odds reserve the guide strip even while HUD remains visible", function()
		for _, viewport in ipairs(viewports) do
			local f = fixture(viewport[1], viewport[2])
			f.Update(2)
			local oddsPanel = f.Root["Luck details"]
			oddsPanel.Visible = true
			assert(f.HUD.Frame.Visible and f.Guide.Frame.Position.Y.Offset == 6)
			assert(not f.HUD.FlushButton:FindFirstChild("TutorialHighlight"))
			f.Update(5, true)
			-- This fixture has no commerce policy, so HUD.Update closes the dialog; reopen it for the farewell.
			oddsPanel.Visible = true
			H.Layout(f.Root)
			assert(
				not f.Guide.Frame.Visible
					or f.Guide.Frame.AbsolutePosition.Y + f.Guide.Frame.AbsoluteSize.Y
						<= oddsPanel.AbsolutePosition.Y
			)
			H.Snapshot(f.Root, "review-tutorial-odds-" .. viewport[1] .. "x" .. viewport[2])
			oddsPanel.Visible = false
			f.Root:Destroy()
		end
	end)
	check("tutorial UI: Settings replay control is wired in the real bootstrap", function()
		-- Existing runners boot the real client before this suite.
		local screen = H.Services.Players.LocalPlayer.PlayerGui:FindFirstChild("ToiletUI")
		local root = if screen then screen.SafeArea else H.BootClient(H.Remotes())
		local button = root:FindFirstChild("ReplayTutorial", true)
		assert(button and button.Text == "Replay tutorial")
		local before = #H.Calls
		button.Activated:Fire()
		assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "TutorialReplay" and H.Calls[#H.Calls].Count == 0)
	end)
	check("tutorial UI: empty inventory after rebirth and insufficient upgrade coins have an exit", function()
		local f = fixture(390, 722)
		f.State.Inventory = { Poop = 0 }
		f.Update(3)
		assert(f.HUD.FlushButton:FindFirstChild("TutorialHighlight"))
		f.Collection.Panel.Visible, f.HUD.Frame.Visible = true, false
		H.Layout(f.Root)
		H.Advance(0.3)
		assert(f.Collection.Panel.TitleBar.X:FindFirstChild("TutorialHighlight"))
		f.State.Coins = 0
		f.Update(4)
		f.Collection.Panel.Visible, f.Upgrades.Panel.Visible = false, true
		f.Upgrades.TutorialTarget().Activated:Fire()
		H.Layout(f.Root)
		H.Advance(0.3)
		assert(f.Upgrades.TutorialTarget() == f.Upgrades.Panel.TitleBar.X)
		assert(f.Upgrades.Panel.TitleBar.X:FindFirstChild("TutorialHighlight") and f.Guide.Frame.SkipTutorial.Visible)
		f.Root:Destroy()
	end)
end
