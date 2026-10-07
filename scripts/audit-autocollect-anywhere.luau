-- Exercise production handlers, shared idle state and the actual fractional ledger.
do
	local function fixture(id, entitlement)
		local e = server()
		local player, p = e:Join(id)
		if entitlement == "free" then
			p.RebirthLevel = 5
		elseif entitlement then
			p.Monetization.Passes[entitlement] = true
		end
		local auto = e:Load("src/server/Services/MonetizationService")
		return e, player, p, auto.Commerce, auto
	end
	local function pending(p, coins)
		p.Income.Pending = { ["1"] = coins * 6000 + 1 }
	end
	test("auto collect anywhere: pass, bundle and R5 collect the manual jar amount at every distance", function()
		for _, entitlement in ipairs({ "AutoCollect", "UltimateBundle", "free" }) do
			local e, player, p, commerce, auto = fixture(3300, entitlement)
			for _, distance in ipairs({ 0, 70, 300, 10000 }) do
				player.Distance = distance
				p.Income.Pending = { ["1"] = 63001, ["2"] = 3000 }
				local manual = copy(p)
				local expected = commerce.Income:Collect(manual)
				local coins, writes = p.Coins, e.Store.Writes
				commerce:Collect(player)
				assert(p.Coins == coins + expected and p.Stats.Earned == manual.Stats.Earned)
				assert(commerce.Income:TotalUnits(p) == commerce.Income:TotalUnits(manual))
				assert(e.Store.Writes == writes and not auto.Auto[player])
				assert(auto:AutoStatus(player).CollectRunning)
				e.Now += 5
			end
		end
	end)
	test("auto collect anywhere: server entitlement and lifecycle guards fail closed", function()
		for _, cause in ipairs({
			"unowned",
			"R4",
			"dead",
			"health",
			"missing",
			"foreign",
			"release",
			"saving",
			"replacing",
			"closing",
			"shutdown",
			"leave",
			"lease",
			"activity",
		}) do
			local e, player, p, commerce, auto = fixture(3301, "AutoCollect")
			pending(p, 10)
			if cause == "unowned" then
				p.Monetization.Passes = {}
			elseif cause == "R4" then
				p.Monetization.Passes, p.RebirthLevel = {}, 4
			elseif cause == "dead" then
				player.Health = 0
			elseif cause == "health" then
				player.Health = math.huge
			elseif cause == "missing" then
				player.Character = nil
			elseif cause == "foreign" then
				e.World.Assigned[player].Owner = e:Player(3399)
			elseif cause == "release" then
				e.World.Assigned[player] = nil
			elseif cause == "saving" then
				e.Data.Saving[player] = true
			elseif cause == "replacing" then
				e.Data.Replacing[player] = true
			elseif cause == "closing" then
				e.Data.Closing[player] = true
			elseif cause == "shutdown" then
				e.Data.Stopping = true
			elseif cause == "leave" then
				player.Parent = nil
			elseif cause == "lease" then
				e.Now += 181
			else
				auto.Activity[player] = nil
			end
			commerce:Collect(player)
			assert(p.Coins == 0 and p.Stats.Earned == 0 and p.Income.Pending["1"] == 60001, cause)
		end
	end)
	test("auto collect anywhere: shared 30-minute idle pause works with Auto Flush off and on", function()
		for _, flush in ipairs({ false, true }) do
			local e, player, p, commerce, auto = fixture(3302, "AutoCollect")
			p.Stats.Flushes, player.Distance = 100, 400
			if flush then
				e:Fire("AutoFlush", player, true)
			end
			local activity = auto.Activity[player]
			for _ = 1, 29 do
				e.Now += 60
				assert(e.Data:Save(player, false))
			end
			e.Now += 59
			pending(p, 10)
			commerce:Collect(player)
			assert(p.Coins == 10 and auto:AutoStatus(player).IdleRemaining == 1)
			e.Now += 1
			pending(p, 5)
			commerce:Collect(player)
			assert(activity.Paused and not auto:AutoStatus(player).CollectRunning and p.Coins == 10)
			if flush then
				e.World.Flush(player, true)
				assert(p.Stats.Flushes == 100)
				e:Fire("AutoFlush", player, false)
				e.Now += 1
				e:Fire("AutoFlush", player, true)
				assert(activity.Paused, "Toggling Auto Flush renewed the collection deadline")
			end
			e.Now += 10
			e:Fire("PlayerActivity", player)
			assert(auto.Activity[player] == activity and not activity.Paused)
			commerce:Collect(player)
			assert(p.Coins == 15 and p.Income.Pending["1"] == 1)
			pending(p, 7)
			for _ = 1, 1000 do
				commerce:Collect(player)
			end
			assert(p.Coins == 15, "Resume replayed missed collection ticks")
		end
	end)
	test("auto collect anywhere: malformed activity and spam cannot renew the shared clock", function()
		local e, player, p, commerce, auto = fixture(3303, "free")
		local first = auto.Activity[player].Last
		e.Now += 20
		for _, bad in ipairs({ 0 / 0, math.huge, {}, true, "now" }) do
			e:Fire("PlayerActivity", player, bad)
		end
		assert(auto.Activity[player].Last == first)
		local results = #e.Results
		for _ = 1, 1000 do
			e:Fire("PlayerActivity", player)
		end
		assert(auto.Activity[player].Last == e.Now and #e.Results == results + 1)
		e.Now += 1
		e:Fire("PlayerActivity", player)
		assert(auto.Activity[player].Last == e.Now - 1)
		pending(p, 10)
		commerce:Collect(player)
		assert(p.Coins == 10)
	end)
	test("auto collect anywhere: empty ticks are quiet, five-second rate limits never multiply income", function()
		local e, player, p, commerce = fixture(3304, "AutoCollect")
		local writes, results = e.Store.Writes, #e.Results
		commerce:Collect(player)
		assert(p.Coins == 0 and e.Store.Writes == writes and #e.Results == results)
		pending(p, 10)
		for _ = 1, 1000 do
			commerce:Collect(player)
		end
		assert(p.Coins == 0)
		e.Now += 5
		commerce:Collect(player)
		assert(p.Coins == 10 and p.Income.Pending["1"] == 1)
		pending(p, 5)
		e.Now += 4.999
		commerce:Collect(player)
		assert(p.Coins == 10)
		e.Now += 0.002
		commerce:Collect(player)
		assert(p.Coins == 15 and p.Stats.Earned == 15 and p.Income.Pending["1"] == 1)
		assert(e.Store.Writes == writes)
	end)
	test("auto collect anywhere: manual pad/jar and auto interleavings transfer each pending coin once", function()
		for _, manualFirst in ipairs({ false, true }) do
			local e, player, p, commerce = fixture(3305, "AutoCollect")
			e.World.Assigned[player].CollectSlots = { e.World.Assigned[player].IncomePoint }
			pending(p, 10)
			if manualFirst then
				e.Store.Before = function()
					coroutine.yield("held manual save")
				end
				local save = e:Spawn(function()
					e:Fire("CollectIncome", player, 1)
				end)
				commerce:Collect(player)
				assert(p.Coins == 10 and p.Income.Pending["1"] == 1)
				e.Store.Before = nil
				e:Resume(save)
			else
				commerce:Collect(player)
				e:Fire("CollectIncome", player, 1)
			end
			e.Now += 5
			e:Fire("CollectIncome", player)
			commerce:Collect(player)
			assert(p.Coins == 10 and p.Stats.Earned == 10 and p.Income.Pending["1"] == 1)
		end
	end)
	test(
		"auto collect anywhere: R5 rebirth clears old pending, pauses guarded save and grants free automation",
		function()
			local e = server()
			local player, old = rebirthReady(e, 3306)
			local config = e:Load("src/shared/Config/Rebirth")
			old.RebirthLevel, old.Coins, old.ToiletTier = 4, config.Levels[5].RequiredCoins, 7
			local auto = e:Load("src/server/Services/MonetizationService")
			local activity = auto.Activity[player]
			local last = activity.Last
			pending(old, 100)
			auto.Commerce:Collect(player)
			assert(old.Income.Pending["1"] == 600001)
			e.Store.Before = function()
				coroutine.yield("rebirth save")
			end
			local saving = e:Spawn(function()
				e:Fire("Rebirth", player, 4)
			end)
			auto.Commerce:Collect(player)
			assert(e.Data.Replacing[player] and not e.Data:Get(player))
			e.Store.Before = nil
			e:Resume(saving)
			local p = e.Data:Get(player)
			assert(p.RebirthLevel == 5 and not next(p.Income.Pending) and not p.Monetization.Passes.AutoCollect)
			assert(auto.Activity[player] == activity and activity.Last == last)
			player.Distance = 400
			e.Now += 5
			local expected = auto.Commerce.Income:PendingCoins(e.Data:Get(player))
			local coins = p.Coins
			auto.Commerce:Collect(player)
			assert(expected > 0 and p.Coins == coins + expected)
			e:Fire("Rebirth", player, 4)
			assert(p.RebirthLevel == 5)
		end
	)
	test("auto collect anywhere: death, respawn, plot release and leave retain or clean the correct state", function()
		local e, player, p, commerce, auto = fixture(3307, "free")
		local activity, character, plot = auto.Activity[player], player.Character, e.World.Assigned[player]
		local last = activity.Last
		pending(p, 10)
		player.CharacterRemoving:Fire()
		player.Character = nil
		commerce:Collect(player)
		assert(p.Coins == 0 and auto.Activity[player] == activity)
		player.Character, player.Distance = character, 400
		commerce:Collect(player)
		assert(p.Coins == 10 and auto.Activity[player].Last == last)
		e.Now += 5
		pending(p, 7)
		e.World.Assigned[player] = nil
		commerce:Collect(player)
		assert(p.Coins == 10)
		e.World.Assigned[player] = plot
		commerce:Collect(player)
		assert(p.Coins == 17)
		e.Data:Close(player)
		player.Parent = nil
		e.Players.PlayerRemoving:Fire(player)
		commerce:Collect(player)
		assert(auto.Activity[player] == nil)
		local joined, restored = e:Join(3307)
		assert(restored.Coins == 17 and restored.RebirthLevel == 5)
		assert(auto.Activity[joined] ~= activity and auto:AutoStatus(joined).CollectRunning)
	end)
	test("auto collect anywhere: activity before R5 unlock is retained without a second clock", function()
		local e, player, p, commerce, auto = fixture(3308)
		e.Now += 60
		e:Fire("PlayerActivity", player)
		assert(auto.Activity[player].Last == e.Now and not auto:AutoStatus(player).CollectEnabled)
		p.RebirthLevel = 5
		pending(p, 10)
		commerce:Collect(player)
		assert(p.Coins == 10 and auto:AutoStatus(player).CollectRunning)
	end)
	test("auto collect anywhere: existing scheduler publishes empty-ledger lifecycle transitions once", function()
		local e, player, p, commerce, auto = fixture(3309, "free")
		e.Players.List = { player }
		local collect, calls = commerce.Collect, 0
		commerce.Collect = function(self, owner)
			calls += 1
			return collect(self, owner)
		end
		local worker
		for _, thread in ipairs(e.Threads) do
			if coroutine.status(thread) == "suspended" then
				local before = calls
				local interval = e:Resume(thread)
				if calls > before then
					assert(interval == 5)
					worker = thread
					break
				end
			end
		end
		assert(worker and p.Coins == 0 and auto:AutoStatus(player).CollectRunning)
		local results, writes = #e.Results, e.Store.Writes
		e.Now += 5
		e:Resume(worker)
		assert(#e.Results == results and e.Store.Writes == writes, "Unchanged empty tick performed work")
		local character = player.Character
		player.Character = nil
		e.Now += 5
		e:Resume(worker)
		assert(#e.Results == results + 1 and not auto:AutoStatus(player).CollectEnabled)
		player.Character = character
		e.Now += 5
		e:Resume(worker)
		assert(#e.Results == results + 2 and auto:AutoStatus(player).CollectRunning)
		assert(e.Store.Writes == writes and p.Coins == 0)
		e.Data.Saving[player] = true
		e.Now += 5
		e:Resume(worker)
		assert(not auto:AutoStatus(player).CollectRunning)
		e.Data.Saving[player] = nil
		e.Now += 5
		e:Resume(worker)
		assert(auto:AutoStatus(player).CollectRunning)
		e.Players.PlayerRemoving:Fire(player)
		assert(commerce.CollectStatus[player] == nil)
	end)
end
