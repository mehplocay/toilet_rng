-- Included by both audit and UI runners; production controllers with engine doubles.
do
	local check = test or function(name, callback)
		callback()
		print("PASS " .. name)
	end
	local function contains(parent, text)
		for _, object in ipairs(parent:GetDescendants()) do
			if object:IsA("TextLabel") and object.Text:find(text, 1, true) then
				return true
			end
		end
		return false
	end
	check("away UI: join, repeated snapshots, double-click, error, timeout, pad collect and session restore", function()
		local root, remotes = H.Root(390, 722), H.Remotes()
		local window = H.Load("src/client/UI/OfflineIncome").Create(root, remotes)
		local report = { Coins = 14400, Earned = 14400, AwaySeconds = 43200, FullSeconds = 14400 }
		window.Update({})
		assert(not window.Panel.Visible)
		window.Update({ OfflineIncome = report })
		assert(window.Panel.Visible and contains(window.Panel, "4.0 hours - upgrade Offline Tank!"))
		local button = window.Panel:FindFirstChild("CollectOffline", true)
		local before = #H.Calls
		button.Activated:Fire()
		button.Activated:Fire()
		assert(#H.Calls == before + 1 and H.Calls[#H.Calls].Name == "CollectOffline" and H.Calls[#H.Calls].Count == 0)
		window.Update({ OfflineIncome = report })
		assert(not button.Interactable and contains(button, "Collecting..."))
		window.Result({ Success = false, Message = "Saving your last action." })
		assert(button.Interactable and window.Panel.Visible and contains(window.Panel, "Saving your last action."))
		button.Activated:Fire()
		H.Advance(16)
		assert(button.Interactable and H.Calls[#H.Calls].Name == "State")
		button.Activated:Fire()
		window.Update({}) -- Authoritative pad/window transfer arrives before Result.
		window.Result({ Success = true, Coins = 14400 })
		assert(not window.Panel.Visible and not button.Interactable)
		window.Update({ OfflineIncome = report })
		assert(not window.Panel.Visible, "A repeated State reopened a dismissed window")
		root:Destroy()
		local nextRoot = H.Root(390, 722)
		local nextWindow = H.Load("src/client/UI/OfflineIncome").Create(nextRoot, remotes)
		nextWindow.Update({ OfflineIncome = report })
		assert(nextWindow.Panel.Visible, "Uncollected server credit was hidden on a fresh session")
		nextRoot:Destroy()
	end)
	check("away UI: phone/desktop/landscape Collect stays reachable through scrolling", function()
		for _, size in ipairs({ { 360, 518 }, { 640, 303 }, { 1280, 684 } }) do
			local root = H.Root(size[1], size[2])
			local window = H.Load("src/client/UI/OfflineIncome").Create(root, H.Remotes())
			window.Update({
				OfflineIncome = {
					Coins = 1500000000000,
					Earned = 1500000000000,
					AwaySeconds = 86400,
					FullSeconds = 57600,
				},
			})
			H.Layout(root)
			local panel = window.Panel
			assert(panel.AbsoluteSize.X <= size[1] - 24 and panel.AbsoluteSize.Y <= size[2] - 24)
			local scroll, body = panel.ContentScroll, panel.ContentScroll.Body
			scroll.CanvasPosition = Vector2.new(0, math.max(0, body.AbsoluteSize.Y - scroll.AbsoluteSize.Y))
			H.Layout(root)
			local button = panel:FindFirstChild("CollectOffline", true)
			assert(button.AbsoluteSize.Y >= 44 and button.AbsoluteSize.X > 200)
			assert(button.AbsolutePosition.Y >= scroll.AbsolutePosition.Y)
			assert(
				button.AbsolutePosition.Y + button.AbsoluteSize.Y <= scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y
			)
			if not test then
				H.Snapshot(root, "away-" .. size[1] .. "x" .. size[2])
			end
			root:Destroy()
		end
	end)
	check("idle UI: switch shows uptime/countdown, pause has an input-only resume and cleanup", function()
		local root, remotes = H.Root(390, 722), H.Remotes()
		local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
			Near = function()
				return false
			end,
		})
		local state = {
			Coins = 0,
			ToiletTier = 1,
			LifetimeFlushes = 100,
			AutoFlush = true,
			AutoStatus = { Uptime = 1500, IdleRemaining = 300 },
			LastClaimDay = 0,
			Streak = 0,
		}
		hud.Update(state)
		H.Services.RunService.Heartbeat:Fire(0.1)
		assert(contains(root, "ON 25:00") and contains(root, "Idle 05:00"))
		state.AutoStatus.Paused = true
		hud.Update(state)
		H.Services.RunService.Heartbeat:Fire(0.1)
		local resume = root.HUD.FlushActions.IdleGuard
		assert(resume.Visible and contains(root, "Still there? Tap to continue"))
		resume.Activated:Fire()
		assert(H.Calls[#H.Calls].Name == "PlayerActivity" and H.Calls[#H.Calls].Count == 0)
		if not test then
			H.Snapshot(root, "idle-390x722")
		end
		root:Destroy()
	end)
	check("merged HUD: capped luck and idle resume share safe action bounds on every supported viewport", function()
		local root, remotes = H.Root(390, 722), H.Remotes()
		local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
			Near = function()
				return true
			end,
		})
		local state = {
			Coins = 3000000,
			ToiletTier = 7,
			RebirthLevel = 0,
			RunFlushes = 300,
			LifetimeFlushes = 100,
			AutoFlush = true,
			AutoStatus = { Uptime = 1800, IdleRemaining = 0, Paused = true },
			UpgradeStats = { LuckMultiplier = 10, LuckCapped = true },
			LastClaimDay = 0,
			Streak = 0,
		}
		hud.Update(state)
		H.Advance(1.01)
		H.StartTasks()
		assert(contains(root.HUD.Boosts, "Luck +900%"), "Merged HUD lost capped luck")
		local action = root.HUD.FlushActions
		local resume, switch = action.IdleGuard, action.AutoFlushSwitch
		local manual
		for _, object in ipairs(action:GetChildren()) do
			if object:IsA("TextButton") and object ~= resume and object ~= switch then
				manual = object
			end
		end
		for _, size in ipairs({
			{ 375, 690 },
			{ 711, 751 },
			{ 360, 518 },
			{ 390, 722 },
			{ 640, 303 },
			{ 711, 731 },
			{ 724, 318 },
			{ 768, 968 },
			{ 1024, 712 },
			{ 1116, 483 },
			{ 1280, 684 },
			{ 1920, 1044 },
		}) do
			root._fixed, root._abs = { X = size[1], Y = size[2] }, nil
			root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
			H.Services.RunService.Heartbeat:Fire(0.1)
			H.Layout(root)
			assert(resume.Visible and switch.Visible and not manual.Visible)
			assert(resume.AbsoluteSize.X >= 44 and resume.AbsoluteSize.Y >= 44)
			assert(resume.AbsolutePosition.X >= action.AbsolutePosition.X)
			assert(resume.AbsolutePosition.Y >= action.AbsolutePosition.Y)
			assert(
				resume.AbsolutePosition.Y + resume.AbsoluteSize.Y <= action.AbsolutePosition.Y + action.AbsoluteSize.Y
			)
			assert(resume.AbsolutePosition.X + resume.AbsoluteSize.X < switch.AbsolutePosition.X)
			if not test then
				H.Snapshot(root, "merged-idle-" .. size[1] .. "x" .. size[2])
			end
		end
		state.AutoStatus.Paused = false
		hud.Update(state)
		H.Services.RunService.Heartbeat:Fire(0.1)
		assert(not resume.Visible and manual.Visible and switch.Visible)
		root:Destroy()
	end)
	check("activity UI: genuine input coalesces, idle/focus loss sends nothing, any input resumes", function()
		local root = H.Root(390, 722)
		local calls = 0
		H.Load("src/client/PlayerActivity").Start(root, {
			FireServer = function(_, ...)
				assert(select("#", ...) == 0)
				calls += 1
			end,
		})
		local input = H.Services.UserInputService
		H.Advance(1801)
		assert(calls == 0, "Periodic heartbeat invented activity")
		input.InputBegan:Fire({ UserInputType = "UserInputType.Touch", Position = Vector3.new() }, true)
		H.Advance(0.01)
		assert(calls == 1)
		for _ = 1, 1000 do
			input.InputBegan:Fire({ UserInputType = "UserInputType.Keyboard" }, true)
		end
		H.Advance(1)
		assert(calls == 1)
		H.Advance(14)
		assert(calls == 2)
		input.WindowFocusReleased:Fire()
		input.InputBegan:Fire({})
		H.Advance(1801)
		assert(calls == 2)
		input.WindowFocused:Fire()
		H.Advance(1)
		assert(calls == 2, "Focus alone reset idle timer")
		input.InputChanged:Fire({ UserInputType = "UserInputType.MouseMovement", Delta = Vector3.new(2, 0, 0) })
		H.Advance(0.01)
		assert(calls == 3)
		H.Advance(15)
		input.InputChanged:Fire({
			UserInputType = "UserInputType.MouseWheel",
			Position = Vector3.new(0, 0, 1),
			Delta = Vector3.new(),
		})
		H.Advance(0.01)
		assert(calls == 4, "Wheel-only input did not resume activity")
		root:Destroy()
		input.InputBegan:Fire({})
		H.Advance(20)
		assert(calls == 4, "Destroyed input tracker leaked a heartbeat")
	end)
	check("far audio: actual class mixer scales the stinger without ducking music", function()
		local config = H.Load("src/shared/Config/Audio")
		local audio = H.Load("src/client/Audio/AudioService").Start()
		audio:ApplySettings(config.Defaults)
		local sound = audio:Play("Secret", nil, 0.25)
		assert(sound and sound.Volume == config.Cues.Secret.Gain * config.ClassGains.stinger * 0.25)
		assert(next(audio.Ducks) == nil and audio.Music.Volume == config.Defaults.MusicVolume)
		audio:Destroy()
	end)
	check("far reveals: bounded coalesced toast, quiet classes, rarest find retained and no cinematic", function()
		local root, hudRoot = H.Root(390, 722), H.Root(390, 722)
		local cues = {}
		local reveal = H.Load("src/client/Presentation/RevealController")
			.Create(root, { Frame = hudRoot, SetHintVisible = function() end }, {
				Play = function(_, key, _, gain)
					table.insert(cues, { Key = key, Gain = gain })
				end,
				Duck = function()
					error("Compact award ducked music")
				end,
			})
		local byId = {}
		for _, item in ipairs(H.Load("src/shared/Config/Items")) do
			byId[item.Id] = item
		end
		local builds = H.PreviewBuilds or 0
		for i = 1, 100 do
			reveal:Show(byId[if i % 3 == 0 then "Mystery" else "Poop"], { FlushId = i, Cooldown = 0.4, Compact = true })
			H.Advance(0.4)
			assert(not reveal.Queue.Active and #reveal.Queue.Pending == 0)
		end
		H.Advance(3)
		assert(#cues <= 15, "Compact audio exceeded one cue per three seconds")
		assert((H.PreviewBuilds or 0) == builds, "Compact award allocated a viewport model")
		for _, cue in ipairs(cues) do
			assert(cue.Gain == 0.25)
		end
		assert(root.RareReveal.CompactDrop.Text:find("more finds", 1, true))
		assert(not H.RenderBindings.FlushRevealShake and not hudRoot.FlushReveal.Visible)
		reveal:Destroy()
		root:Destroy()
		hudRoot:Destroy()
	end)
end
