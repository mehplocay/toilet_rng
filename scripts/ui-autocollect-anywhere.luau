-- Included by audit and UI runners: extend the existing chip and shared resume action.
do
	local check = test or function(name, callback)
		callback()
		print("PASS " .. name)
	end
	check("auto collect HUD: running/waiting/paused states share one chip and Still-there action", function()
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
			local root, remotes = H.Root(size[1], size[2]), H.Remotes()
			local near = false
			local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
				Near = function()
					return near
				end,
			})
			local state = {
				Coins = 0,
				ToiletTier = 1,
				LifetimeFlushes = 0,
				RebirthLevel = 5,
				AutoFlush = false,
				AutoStatus = { CollectEnabled = true, CollectRunning = true, IdleRemaining = 1800 },
				LastClaimDay = 0,
				Streak = 0,
			}
			local phone = H.Load("src/client/UI/Layout")
				.Compute(size[1], size[2], H.Services.UserInputService.TouchEnabled).Phone
			local action = root.HUD.FlushActions
			local chip, idle = action.AutoFlushSwitch, action.IdleGuard
			local children = #action:GetChildren()
			for _, atHome in ipairs({ false, true }) do
				near = atHome
				hud.Update(state)
				H.Services.RunService.Heartbeat:Fire(0.1)
				H.Layout(root)
				assert(
					chip.Label.Text:find(if phone then "COLLECT\nON" else "COLLECT\nON / 5s", 1, true)
						and not idle.Visible
				)
				assert(not chip.Interactable and chip.Label.TextTransparency == 0)
				assert(chip.AbsolutePosition.X >= 0 and chip.AbsolutePosition.Y >= 0)
				assert(chip.AbsolutePosition.X + chip.AbsoluteSize.X <= size[1])
				assert(chip.AbsolutePosition.Y + chip.AbsoluteSize.Y <= size[2])
			end
			if not test and (size[1] == 390 or size[1] == 640) then
				H.Snapshot(root, "collect-running-" .. size[1] .. "x" .. size[2])
			end
			state.AutoStatus.CollectRunning = false
			hud.Update(state)
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(chip.Label.Text:find(if phone then "COLLECT\nWAIT" else "COLLECT\nWAITING", 1, true))
			state.AutoStatus.IdleRemaining = 300
			hud.Update(state)
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(
				(
					if phone
						then root["Boost details"]:FindFirstChild("AutomationDetails", true).Text
						else chip.Label.Text
				):find("Idle 05:00", 1, true),
				"Collect-only mode lost the shared idle warning"
			)
			state.AutoStatus.Paused = true
			hud.Update(state)
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(chip.Label.Text:find("COLLECT\nPAUSED", 1, true) and idle.Visible)
			if not test and (size[1] == 390 or size[1] == 640) then
				H.Snapshot(root, "collect-paused-" .. size[1] .. "x" .. size[2])
			end
			idle.Activated:Fire()
			assert(H.Calls[#H.Calls].Name == "PlayerActivity" and H.Calls[#H.Calls].Count == 0)
			state.LifetimeFlushes, state.AutoFlush = 100, true
			state.AutoStatus.Paused, state.AutoStatus.CollectRunning = false, true
			state.AutoStatus.Uptime, state.AutoStatus.IdleRemaining = 1500, 300
			hud.Update(state)
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(
				chip.Label.Text:find(if phone then "ON" else "ON 25:00", 1, true)
					and chip.Label.Text:find(if phone then "COLLECT\nON" else "COLLECT\nON / 5s", 1, true)
			)
			assert(#action:GetChildren() == children, "Automation status duplicated controls")
			H.Services.Players.LocalPlayer.CharacterRemoving:Fire()
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(not chip.Label.Text:find("COLLECT", 1, true))
			-- A subsequent authoritative respawn snapshot restores collecting.
			state.AutoStatus = { CollectEnabled = true, CollectRunning = true, IdleRemaining = 300 }
			hud.Update(state)
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(chip.Label.Text:find(if phone then "COLLECT\nON" else "COLLECT\nON / 5s", 1, true))
			state.AutoStatus = {}
			hud.Update(state)
			H.Services.RunService.Heartbeat:Fire(0.1)
			assert(not chip.Label.Text:find("COLLECT", 1, true))
			root:Destroy()
		end
	end)
end
