-- Real service handlers and persistence transforms; no alternate reward implementation.
local function awayFixture(id, seconds)
	local e = server()
	local player, p = e:Join(id)
	p.Inventory.Poop, p.Displays["1"] = 1, "Poop"
	e.Data:Close(player)
	player.Parent = nil
	e.Now += seconds or 3600
	local joined, restored = e:Join(id)
	return e, joined, restored
end
local function accounting(e)
	return e:Load("src/shared/IncomeAccrual").new(
		e:Load("src/shared/Config/Income"),
		e:Load("src/shared/Config/Items"),
		e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	)
end

test("anywhere: compact jackpot still records the item, server luck and existing chat announcement", function()
	local e = server()
	local player, p = e:Join(914)
	p.Stats.Flushes, player.Distance = 100, 300
	e.Players.List = { player }
	local item = e:Load("src/shared/Config/Items")[9]
	e:Load("src/server/Services/RollService").Roll = function()
		return item, 0.00002
	end
	e.World.Animate = function()
		error("Remote auto award played toilet animation")
	end
	e:Fire("AutoFlush", player, true)
	e.World.Flush(player, true)
	assert(p.Inventory[item.Id] == 1 and p.Collection[item.Id] == 1)
	local compact, luck = false, false
	for _, message in ipairs(e.Results) do
		if message.Payload[1] == "Flush" then
			compact = message.Payload[2].Compact
		end
		if type(message.Payload[1]) == "number" and message.Payload[1] > e.Now then
			luck = true
		end
	end
	assert(compact and luck)
	local before = #e.Results
	e:Resume(e.Threads[2])
	assert(#e.Results == before + 1 and e.Results[#e.Results].Payload[1].ItemId == item.Id)
end)

test("anywhere: unlock and living owner authorize hub/path/plot auto, manual proximity stays enforced", function()
	local e = server()
	local player, p = e:Join(900)
	local auto = e:Load("src/server/Services/MonetizationService")
	player.Distance = 300
	p.Stats.Flushes = 99
	e:Fire("AutoFlush", player, true)
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 99 and not auto.Auto[player])
	p.Stats.Flushes = 100
	e:Fire("AutoFlush", player, true)
	local animations = 0
	e.World.Animate = function()
		animations += 1
	end
	for _, distance in ipairs({ 300, 70, 0 }) do
		player.Distance = distance
		e.Now += 4
		e:Resume(e.Threads[1])
	end
	assert(p.Stats.Flushes == 103 and animations == 1 and auto.Auto[player])
	assert(p.Inventory.Poop == 3 and p.Coins == 120)
	player.Distance = 300
	e.Now += 4
	e:Fire("Flush", player)
	e.World.Flush(player)
	assert(p.Stats.Flushes == 103)
	local compact = 0
	for _, result in ipairs(e.Results) do
		if result.Payload[1] == "Flush" and result.Payload[2].Compact then
			compact += 1
		end
	end
	assert(compact == 2)
end)

test("anywhere: forged automatic path cannot bypass toggle, death, ownership or lease", function()
	for _, cause in ipairs({ "off", "dead", "missing", "foreign", "lease" }) do
		local e = server()
		local player, p = e:Join(901)
		p.Stats.Flushes, player.Distance = 100, 200
		e:Fire("AutoFlush", player, true)
		if cause == "off" then
			e:Fire("AutoFlush", player, false)
		elseif cause == "dead" then
			player.Health = 0
		elseif cause == "missing" then
			player.Character = nil
		elseif cause == "foreign" then
			e.World.Assigned[player].Owner = e:Player(902)
		else
			e.Now += 181
		end
		e.World.Flush(player, true)
		assert(p.Stats.Flushes == 100 and p.Coins == 0, cause)
	end
end)

test("anywhere: manual/auto share reservations and tokens across travel at the 0.4s floor", function()
	local e = server()
	local player, p = e:Join(903)
	p.Stats.Flushes, p.ToiletTier = 100, 7
	p.Upgrades.FlushSpeed, p.Upgrades.AutoFlushSpeed = 10, 10
	e:Fire("AutoFlush", player, true)
	e:Fire("Flush", player)
	player.Distance = 400
	for _ = 1, 1000 do
		e.World.Flush(player, true)
	end
	e.Now += 0.399
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 101)
	e.Now += 0.002
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 102)
	player.Distance = 0
	e:Fire("Flush", player)
	e:Fire("Flush", player)
	player.Distance = 400
	e.Now += 0.401
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 103)
end)

test("idle: no heartbeat pauses at 30 minutes, stays enabled, resumes without catch-up", function()
	local e = server()
	local player, p = e:Join(904)
	p.Stats.Flushes = 100
	player.Distance = 200
	e:Fire("AutoFlush", player, true)
	local auto = e:Load("src/server/Services/MonetizationService")
	for _ = 1, 29 do
		e.Now += 60
		assert(e.Data:Save(player, false))
	end
	e.Now += 59
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 101 and auto:AutoStatus(player).IdleRemaining == 1)
	e.Now += 1
	e.World.Flush(player, true)
	assert(auto:AutoStatus(player).Paused and auto.Auto[player] and p.Stats.Flushes == 101)
	local uptime = auto:AutoStatus(player).Uptime
	e.Now += 30
	e:Resume(e.Threads[1])
	assert(auto:AutoStatus(player).Uptime == uptime and p.Stats.Flushes == 101)
	e:Fire("PlayerActivity", player)
	assert(not auto:AutoStatus(player).Paused)
	e:Resume(e.Threads[1])
	assert(p.Stats.Flushes == 102)
	e:Resume(e.Threads[1])
	assert(p.Stats.Flushes == 102, "Resume caught up missed rolls")
	e.Players.PlayerRemoving:Fire(player)
	assert(auto.Activity[player] == nil and auto.Auto[player] == nil)
end)

test("idle: malformed timestamps and spam cannot renew activity or buy faster rolls", function()
	local e = server()
	local player, p = e:Join(905)
	p.Stats.Flushes = 100
	e:Fire("AutoFlush", player, true)
	local auto = e:Load("src/server/Services/MonetizationService")
	local first = auto.Activity[player].Last
	e.Now += 20
	for _, bad in ipairs({ 0 / 0, math.huge, 999999999, true, {}, "now" }) do
		e:Fire("PlayerActivity", player, bad)
	end
	assert(auto.Activity[player].Last == first)
	local before = #e.Results
	for _ = 1, 1000 do
		e:Fire("PlayerActivity", player)
	end
	assert(#e.Results == before + 1 and auto.Activity[player].Last == e.Now)
	e.Now += 1
	e:Fire("PlayerActivity", player)
	assert(auto.Activity[player].Last == e.Now - 1)
	assert(p.Stats.Flushes == 100 and p.Coins == 0)
	auto.Activity[player] = nil
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 100, "Missing guard state failed open")
end)

test("offline: all tank levels and optional Plus use half rates with a 24-hour hard cap", function()
	local e = server()
	local income = accounting(e)
	for level = 0, 10 do
		for _, plus in ipairs({ false, true }) do
			local p = e.Data.DefaultProfile()
			p.Upgrades.OfflineTank = level
			p.Monetization.Passes.OfflinePlus = plus
			p.Displays["1"], p.Inventory.Poop = "Poop", 1
			p.Income.UpdatedAt = 1000
			income:Settle(p, 1000 + 3 * 86400, true)
			local seconds = (480 + level * 24) * (if plus then 2 else 1) * 60
			assert(income:TotalUnits(p) == seconds * 3000)
			local report = income:OfflineSnapshot(p)
			assert(report.Coins == seconds / 2 and report.FullSeconds == 3 * 86400 - seconds)
			assert(report.AwaySeconds == 3 * 86400)
			income:Settle(p, 1000 + 3 * 86400, true)
			assert(income:TotalUnits(p) == seconds * 3000)
		end
	end
	local p = e.Data.DefaultProfile()
	p.Displays["1"], p.Income.UpdatedAt = "Poop", 1000
	income.Upgrades = {
		OfflineMinutes = function()
			return 1e9
		end,
		Cash = function()
			return 1
		end,
	}
	income:Settle(p, 1000 + 3 * 86400, true)
	assert(income:PendingCoins(p) == 43200, "Configured hard time cap bypassed")
end)

test("offline: full storage timing, bounded reports, fractions, empty display and backward clock", function()
	local e = server()
	local income = accounting(e)
	local p = e.Data.DefaultProfile()
	p.Displays["1"], p.Income.UpdatedAt = "Poop", 1000
	local cap = income:StorageUnits(p, true)
	p.Income.Pending["1"] = cap - 3000
	income:Settle(p, 4600, true)
	assert(p.Income.Offline.Units == 3000 and p.Income.Offline.FullSeconds == 3599)
	assert(income:OfflineSnapshot(p) == nil, "Fraction-only report advertised Collect")
	local saved = copy(p.Income)
	income:Settle(p, 2000, true)
	assert(p.Income.UpdatedAt == saved.UpdatedAt and p.Income.Offline.Units == 3000)
	p.Income.Offline.Units = math.huge
	p.Income = income:Sanitize(p.Income, p)
	assert(p.Income.Offline == nil)
	p = e.Data.DefaultProfile()
	p.Income.UpdatedAt = 1000
	income:Settle(p, 4600, true)
	assert(income:TotalUnits(p) == 0 and income:OfflineSnapshot(p) == nil)
end)

test("offline: join Collect transfers only offline coins at distance; active income remains", function()
	local e, player, p = awayFixture(906)
	local income = accounting(e)
	assert(income:OfflineSnapshot(p).Coins == 1800)
	e.Now += 60
	player.Distance = 400
	e:Fire("CollectOffline", player, 999999)
	e:Fire("CollectIncome", player)
	assert(p.Coins == 0)
	e:Fire("CollectOffline", player)
	assert(p.Coins == 1800 and income:PendingCoins(p) == 60 and income:OfflineSnapshot(p) == nil)
	for _ = 1, 1000 do
		e:Fire("CollectOffline", player)
	end
	assert(p.Coins == 1800 and income:PendingCoins(p) == 60)
	assert(e.Store.Records.Player_906.Data.Income.Offline == nil)
end)

test("offline: ordinary pads consume the same credit; saturated wallet leaves remaining window credit", function()
	local e, player, p = awayFixture(907)
	local income = accounting(e)
	e.World.Assigned[player].CollectSlots = { [1] = e.World.Assigned[player].IncomePoint }
	p.Coins = 9e15 - 100
	e:Fire("CollectIncome", player, 1)
	assert(p.Coins == 9e15 and income:OfflineSnapshot(p).Coins == 1700)
	e.Now += 1
	e:Fire("CollectOffline", player)
	assert(income:OfflineSnapshot(p).Coins == 1700)
	p.Coins = 0
	e.Now += 1
	e:Fire("CollectIncome", player)
	assert(income:OfflineSnapshot(p) == nil and p.Coins == 1702)
end)

test("offline: dead, missing, foreign and expired sessions cannot collect the window", function()
	for _, cause in ipairs({ "dead", "missing", "foreign", "lease" }) do
		local e, player, p = awayFixture(908)
		if cause == "dead" then
			player.Health = 0
		elseif cause == "missing" then
			player.Character = nil
		elseif cause == "foreign" then
			e.World.Assigned[player].Owner = e:Player(909)
		else
			e.Now += 181
		end
		e:Fire("CollectOffline", player)
		assert(p.Coins == 0 and p.Income.Offline.Units == 1800 * 6000, cause)
	end
end)

test("offline: held window save blocks pad races and overlapping rejoin, then persists one transfer", function()
	local e, player, p = awayFixture(910)
	e.Store.Before = function()
		coroutine.yield("held")
	end
	local collect = e:Spawn(function()
		e:Fire("CollectOffline", player)
	end)
	assert(p.Coins == 1800 and p.Income.Offline == nil)
	e.Now += 1
	e:Fire("CollectIncome", player)
	e:Fire("CollectOffline", player)
	e.Store.Before = nil
	local overlap = e:Player(910)
	e.Data:Load(overlap)
	assert(overlap.Kicked and not e.Data:Get(overlap))
	e:Resume(collect)
	e.Data:Close(player)
	local joined, restored = e:Join(910)
	e:Fire("CollectOffline", joined)
	assert(restored.Coins == 1800 and restored.Income.Offline == nil)
end)

for _, committed in ipairs({ false, true }) do
	test(
		"offline: exhausted window save recovers one complete ledger on rejoin, committed=" .. tostring(committed),
		function()
			local e, player, p = awayFixture(911)
			p.Displays = {} -- Isolate transaction recovery from new online/offline accrual.
			assert(e.Data:Save(player, false))
			e.Store[if committed then "After" else "Before"] = function()
				error("outage")
			end
			local collect = e:Spawn(function()
				e:Fire("CollectOffline", player)
			end)
			for _ = 1, 3 do
				e:Resume(collect)
			end
			assert(not e.Data:Get(player))
			e.Store.After, e.Store.Before = nil, nil
			e.Now += 181
			local joined, restored = e:Join(911)
			assert(restored.Coins == (if committed then 1800 else 0))
			e:Fire("CollectOffline", joined)
			assert(restored.Coins == 1800 and restored.Income.Offline == nil)
		end
	)
end

test(
	"offline: acquisition response loss and callback replay retain the report and no duplicate elapsed time",
	function()
		local e, player, p = awayFixture(912)
		p.Displays = {}
		e.Data:Close(player)
		local before = copy(e.Store.Records.Player_912.Data.Income)
		e.Store.After = function()
			error("acquired but response lost")
		end
		local joined = e:Player(912)
		local load = e:Spawn(function()
			e.Data:Load(joined)
		end)
		e.Store.After = nil
		e.Store.Replay = function() end
		e:Resume(load)
		local restored = e.Data:Get(joined)
		assert(restored.Income.Offline.Units == before.Offline.Units)
		assert(restored.Income.Offline.AwaySeconds == before.Offline.AwaySeconds)
		assert(restored.Income.Pending["1"] == before.Pending["1"])
	end
)

test("offline: cross-server takeover during window-save callback cannot overwrite the new owner", function()
	local e, player, p = awayFixture(913)
	p.Displays = {}
	assert(e.Data:Save(player, false))
	local held
	e.Store.Replay = function()
		if not held then
			held = true
			coroutine.yield("callback replay")
		end
	end
	local collect = e:Spawn(function()
		e:Fire("CollectOffline", player)
	end)
	e.Store.Replay = nil
	e.Now += 181
	local joined, restored = e:Join(913)
	e:Fire("CollectOffline", joined)
	e:Resume(collect)
	assert(restored.Coins == 1800 and e.Store.Records.Player_913.Data.Coins == 1800)
	assert(e.Store.Records.Player_913.Data.Income.Offline == nil)
	assert(e.Store.Records.Player_913.Lock.Session == e.Data.Sessions[joined])
end)
