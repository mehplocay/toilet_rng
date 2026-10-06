-- Service scheduling/lifecycle integration; real world tween cleanup is covered by check-visuals.
for _, cause in ipairs({ "disable", "idle", "respawn", "leave", "dead" }) do
	test("auto animation: far cycles stop cleanly on " .. cause, function()
		local e = server()
		local player, profile = e:Join(940)
		local auto = e:Load("src/server/Services/MonetizationService")
		profile.Stats.Flushes, profile.Settings.SkipAnimation, player.Distance = 100, true, 10000
		local cycles, active = 0, false
		e.World.Animate = function(_, owner, _, skip, duration, _, compact, automatic)
			assert(owner == player and skip and compact and automatic and duration <= 0.9)
			cycles, active = cycles + 1, true
		end
		e.World.StopAnimation = function(_, owner)
			assert(owner == player)
			active = false
		end
		e:Fire("AutoFlush", player, true)
		for _ = 1, 3 do
			e.Now += 5
			e:Resume(e.Threads[1])
		end
		assert(cycles == 3 and active and profile.Stats.Flushes == 103)
		if cause == "disable" then
			e:Fire("AutoFlush", player, false)
		elseif cause == "idle" then
			auto.Activity[player].Last = e.Now - 1800
		elseif cause == "respawn" then
			player.CharacterRemoving:Fire(player.Character)
		elseif cause == "leave" then
			e.Players.PlayerRemoving:Fire(player)
			player.Parent = nil
			assert(auto.Auto[player] == nil and auto.Activity[player] == nil)
		else
			player.Health = 0
		end
		e.Now += 5
		e:Resume(e.Threads[1])
		assert(not active and cycles == 3)
		e.Now += 5
		e:Resume(e.Threads[1])
		assert(not active and cycles == 3, "Stopped auto restarted an effect")
	end)
end

test("auto animation: disable during a paid save cannot restart presentation on completion", function()
	local e = server()
	local player, profile = e:Join(941)
	profile.Stats.Flushes, profile.Monetization.LuckyFlushes, player.Distance = 100, 1, 10000
	local lucky = e:Load("src/server/Services/LuckyService")
	e:Fire("AutoFlush", player, true)
	e:Fire("LuckyFlush", player, lucky:Odds(profile).Token)
	assert(lucky.Armed[player])
	local held
	e.Store.Before = function()
		held = coroutine.running()
		coroutine.yield("paid auto save")
	end
	local cycles = 0
	e.World.Animate = function()
		cycles += 1
	end
	e:Resume(e.Threads[1])
	assert(held and cycles == 0)
	e:Fire("AutoFlush", player, false)
	e.Store.Before = nil
	e:Resume(held)
	assert(cycles == 0 and e.Data:Get(player).Stats.Flushes == 101)
end)
