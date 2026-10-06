-- Real server handlers, immutable store snapshots and controlled yields.
local function rebirthReady(e, id)
	local player, p = e:Join(id)
	p.Coins, p.ToiletTier = e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins, 4
	p.Stats.Flushes, p.RunFlushes = 5000, e:Load("src/shared/Config/Rebirth").RequiredFlushes
	p.Inventory.Poop, p.Inventory.Rat = 20, 4
	p.Collection.Poop, p.Collection.Rat = 100, 10
	p.Displays = { ["1"] = "Rat", ["2"] = "Rat", ["5"] = "Poop" }
	p.Upgrades.CashBoost, p.Upgrades.DisplaySlots = 5, 2
	p.DisplaySlots = 6
	p.IndexClaims["total:5"] = true
	p.Stamps, p.TutorialDone, p.LastClaimDay, p.Streak = 33, true, 123, 2
	p.Stats.RarestItemId, p.Stats.RarestChance = "Rat", 25
	p.Income.Pending = { ["1"] = 600000 }
	return player, p
end
local function rebirthSuccesses(e)
	local count = 0
	for _, message in ipairs(e.Results) do
		if message.Payload[1] == "Rebirth" and message.Payload[2].Success then
			count += 1
		end
	end
	return count
end
test("rebirth: atomic replacement keeps discoveries, first copies, displays, rewards and settings", function()
	local e = server()
	local player, before = rebirthReady(e, 200)
	e:Fire("Rebirth", player, 0)
	local p = e.Data:Get(player)
	assert(
		p ~= before
			and before.Coins == e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins
			and before.RunFlushes > 0
	)
	assert(p.RebirthLevel == 1 and p.RunFlushes == 0 and p.ToiletTier == 4 and p.Coins == 2500)
	assert(p.Inventory.Poop == 1 and p.Inventory.Rat == 2 and p.ProtectedInventory.Rat == 2)
	assert(p.DisplaySlots == 6 and p.Displays["3"] == nil and p.Displays["5"] == "Poop")
	assert(p.Collection.Poop == 100 and p.Collection.Rat == 10 and p.Stats.Flushes == 5000)
	assert(p.TutorialDone and p.Stamps == 33 and p.LastClaimDay == 123 and p.Streak == 2 and p.IndexClaims["total:5"])
	assert(p.Settings ~= before.Settings and p.Stats.RarestItemId == "Rat")
	assert(next(p.Income.Pending) == nil and p.Income.UpdatedAt == e.Now)
	for _, value in pairs(p.Upgrades) do
		assert(value == before.Upgrades[_])
	end
	assert(rebirthSuccesses(e) == 1 and e.Store.Records.Player_200.Data.RebirthLevel == 1)
	e:Fire("Rebirth", player, 0)
	e.Now += 6
	e:Fire("Rebirth", player, 0)
	e:Fire("Rebirth", player, 1)
	assert(p.Coins == 2500 and p.RebirthLevel == 1 and rebirthSuccesses(e) == 1)
end)
test("rebirth: no gameplay can mutate either side of a yielded reset; departure serializes full replacement", function()
	local e = server()
	local player, old = rebirthReady(e, 201)
	e.Store.Before = function()
		coroutine.yield("rebirth save held")
	end
	local reset = e:Spawn(function()
		e:Fire("Rebirth", player, 0)
	end)
	local p = e.Data.Profiles[player]
	assert(p ~= old and p.RebirthLevel == 1 and e.Data:Get(player) == nil)
	for _ = 1, 100 do
		e:Fire("Rebirth", player, 0)
		e:Fire("Flush", player)
		e:Fire("BuyUpgrade", player, "CashBoost", 0)
		e:Fire("BuyToilet", player, "Dirty")
		e:Fire("Sell", player, "Rat", 1)
		e:Fire("CollectIncome", player)
		e:Fire("ClaimIndexReward", player, "rarity:Common")
	end
	assert(
		p.Coins == 2500
			and p.RunFlushes == 0
			and old.Coins == e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins
			and rebirthSuccesses(e) == 0
	)
	player.Parent = nil
	local closing = e:Spawn(function()
		e.Data:Close(player)
	end)
	e.Store.Before = nil
	local overlap = e:Join(201)
	assert(overlap.Kicked and not e.Data:Get(overlap))
	e:Resume(reset)
	e:Resume(closing)
	assert(e.Data.Replacing[player] == nil and e.Data.Profiles[player] == nil and rebirthSuccesses(e) == 0)
	local _, restored = e:Join(201)
	assert(restored.RebirthLevel == 1 and restored.Coins == 2500 and restored.Inventory.Rat == 2)
end)
test(
	"rebirth: refuses while another save is pending, then rejects stale generation even when eligible again",
	function()
		local e = server()
		local player = rebirthReady(e, 202)
		e.Store.Before = function()
			coroutine.yield("ordinary save held")
		end
		local saving = e:Spawn(function()
			e.Data:Save(player, false)
		end)
		e:Fire("Rebirth", player, 0)
		assert(e.Data.Profiles[player].RebirthLevel == 0)
		e.Store.Before = nil
		e:Resume(saving)
		e.Now += 6
		e:Fire("Rebirth", player, 0)
		local p = e.Data:Get(player)
		p.RunFlushes, p.ToiletTier = 100000, 4
		p.Coins = e:Load("src/shared/Config/Rebirth").Levels[2].RequiredCoins
		assert(e:Load("src/shared/RebirthRules").new(e:Load("src/shared/Config/Rebirth")):Eligible(p, 1))
		e.Now += 6
		e:Fire("Rebirth", player, 0)
		assert(p.RebirthLevel == 1 and rebirthSuccesses(e) == 1)
	end
)
for _, afterCommit in ipairs({ false, true }) do
	test("rebirth: exhausted errors keep one complete side; committed=" .. tostring(afterCommit), function()
		local e = server()
		local player = rebirthReady(e, 203)
		e.Data:Save(player, false)
		if afterCommit then
			e.Store.After = function()
				error("lost response")
			end
		else
			e.Store.Before = function()
				error("offline")
			end
		end
		local resetting = e:Spawn(function()
			e:Fire("Rebirth", player, 0)
		end)
		for _ = 1, 3 do
			e:Resume(resetting)
		end
		assert(player.Kicked and not e.Data:Get(player) and rebirthSuccesses(e) == 0)
		local disk = e.Store.Records.Player_203.Data
		assert(disk.RebirthLevel == (if afterCommit then 1 else 0))
		assert(
			disk.Coins == (if afterCommit then 2500 else e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins)
		)
		assert(disk.ToiletTier == 4)
		assert(e.Data.Profiles[player].RebirthLevel == 1, "Ambiguous save rolled back in memory")
		-- Simulate crash without Close: a new owner gets either whole old or whole new state.
		e.Store.Before, e.Store.After = nil, nil
		e.Now += 181
		local _, rejoined = e:Join(203)
		assert(rejoined.RebirthLevel == disk.RebirthLevel and rejoined.Coins == disk.Coins)
	end)
end
test("rebirth: lost committed response retries same snapshot, never grants a second starter bonus", function()
	local e = server()
	local player = rebirthReady(e, 204)
	e.Store.After = function()
		error("commit response lost")
	end
	local resetting = e:Spawn(function()
		e:Fire("Rebirth", player, 0)
	end)
	assert(e.Store.Records.Player_204.Data.RebirthLevel == 1)
	e.Store.After = nil
	e:Resume(resetting)
	assert(e.Data:Get(player).Coins == 2500 and rebirthSuccesses(e) == 1)
	e.Data:Close(player)
	local _, p = e:Join(204)
	assert(p.RebirthLevel == 1 and p.Coins == 2500)
end)
test("rebirth: lease takeover or expiry during callback replay never overwrites the new owner", function()
	for _, takeover in ipairs({ false, true }) do
		local e = server()
		local player = rebirthReady(e, 205)
		e.Data:Save(player, false)
		e.Store.Replay = function(key)
			if takeover then
				e.Store.Records[key].Lock.Session = "foreign"
			else
				e.Now += 181
			end
		end
		e:Fire("Rebirth", player, 0)
		assert(not e.Data:Get(player) and player.Kicked and rebirthSuccesses(e) == 0)
		assert(
			e.Store.Records.Player_205.Data.RebirthLevel == 0
				and e.Store.Records.Player_205.Data.Coins
					== e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins
		)
	end
end)
test("rebirth: malformed requests, requirements, cap and numeric ceilings reject before any reset", function()
	local e = server()
	local player, p = rebirthReady(e, 206)
	for _, args in ipairs({ {}, { {} }, { "0" }, { 0 / 0 }, { math.huge }, { -1 }, { 0.5 }, { 1 }, { 0, true } }) do
		e.Now += 6
		e:Fire("Rebirth", player, table.unpack(args))
		assert(e.Data:Get(player) == p and p.Coins == e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins)
	end
	for _, field in ipairs({ "RunFlushes", "Coins" }) do
		local old = p[field]
		p[field] = 0
		e.Now += 6
		e:Fire("Rebirth", player, 0)
		p[field] = old
		assert(p.RebirthLevel == 0)
	end
	p.Stats.Earned = 9e15
	e.Now += 6
	e:Fire("Rebirth", player, 0)
	assert(p.RebirthLevel == 0 and p.Coins == e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins)
	p.Stats.Earned, p.RebirthLevel = 0, 15
	e.Now += 6
	e:Fire("Rebirth", player, 15)
	assert(p.RebirthLevel == 15 and p.Coins == e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins)
end)
test("rebirth: offline accrual cannot restore cleared pending; retained copies and permanent income survive", function()
	local e = server()
	local player = rebirthReady(e, 207)
	e:Fire("Rebirth", player, 0)
	local p = e.Data:Get(player)
	e:Fire("Display", player, nil, 1)
	e:Fire("Display", player, nil, 2)
	e:Fire("Sell", player, "Rat", 1)
	assert(p.Inventory.Rat == 2 and p.Coins == 2500)
	p.Inventory.Rat += 1
	e:Fire("Sell", player, "Rat", 1)
	assert(p.Inventory.Rat == 2 and p.Coins == 4500 and p.Collection.Rat == 10)
	e:Fire("ClaimIndexReward", player, "total:5")
	assert(p.Stamps == 33 and p.DisplaySlots == 6)
	e.Data:Close(player)
	e.Now += 86400
	local _, restored = e:Join(207)
	local income = e:Load("src/shared/IncomeAccrual").new(
		e:Load("src/shared/Config/Income"),
		e:Load("src/shared/Config/Items"),
		e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	)
	assert(
		income:PendingCoins(restored) == 95040,
		"Expected retained Poop at permanent Diamond/cash/rebirth rate for 480 minutes"
	)
	assert(restored.RebirthLevel == 1 and restored.RunFlushes == 0 and restored.ProtectedInventory.Rat == 2)
	local units = income:TotalUnits(restored)
	income:Settle(restored, e.Now, true)
	assert(income:TotalUnits(restored) == units)
end)
test("rebirth: flushes count once and persist; legacy profiles migrate only lifetime first-run progress", function()
	local e = server()
	local player, p = e:Join(208)
	e:Fire("Flush", player)
	e:Fire("Flush", player)
	assert(p.RunFlushes == 1 and p.Stats.Flushes == 1)
	e.Data:Close(player)
	local raw = e.Store.Records.Player_208.Data
	raw.RunFlushes, raw.RebirthLevel, raw.Stats.Flushes = nil, nil, 800
	local second, restored = e:Join(208)
	assert(restored.RunFlushes == 800 and restored.RebirthLevel == 0)
	e.Data:Close(second)
	raw = e.Store.Records.Player_208.Data
	raw.RunFlushes, raw.RebirthLevel = nil, 2
	local _, nextRun = e:Join(208)
	assert(nextRun.RunFlushes == 0 and nextRun.RebirthLevel == 2)
end)

test("rebirth: high-level announcements share drop cooldown, friend/server audiences and lifecycle cleanup", function()
	local e = environment()
	local owner, friend, stranger = e:Player(210), e:Player(211), e:Player(212)
	e.Players.List = { owner, friend, stranger }
	owner.IsFriendsWithAsync = function(_, id)
		return id == friend.UserId
	end
	local profiles = {}
	for _, player in ipairs(e.Players.List) do
		profiles[player] = { RebirthLevel = 3, Settings = {} }
	end
	local data = {
		Get = function(_, player)
			return profiles[player]
		end,
	}
	local events, remote = {}, e:Remote()
	local queue = e:Load("src/server/Services/AnnouncementService").Start(data, { DropAnnouncement = remote }, events)
	local worker = e.Threads[#e.Threads]
	events.Rebirth(owner, 3)
	e:Resume(worker)
	assert(#e.Results == 1 and e.Results[1].Player == friend and e.Results[1].Payload[1].Kind == "Rebirth")
	local item = e:Load("src/shared/Config/Items")[9]
	events.Observe(owner, item, 1)
	assert(#queue.Pending == 0, "Rebirth and drops used separate rate limits")
	e.Now += 6
	events.Rebirth(owner, 3)
	assert(#queue.Pending == 0, "Same rebirth announced twice")
	profiles[owner].RebirthLevel = 5
	profiles[stranger].Settings.ChatAnnouncements = false
	events.Rebirth(owner, 5)
	e:Resume(worker)
	assert(
		#e.Results == 4
			and e.Results[2].Player == owner
			and e.Results[2].Payload[1].Self
			and e.Results[3].Player == owner
			and e.Results[4].Player == friend
	)
	e.Players.PlayerRemoving:Fire(owner)
	assert(queue.RebirthSeen[owner] == nil and queue.Seen[owner] == nil and queue.Busy[owner] == nil)
end)

test("rebirth: saturated coin/index slots, high-water clocks and high-level income round-trip consistently", function()
	local e = server()
	local player, p = rebirthReady(e, 213)
	p.Upgrades.DisplaySlots, p.DisplaySlots = 7, 10
	p.Income.UpdatedAt = e.Now + 100
	e:Fire("Rebirth", player, 0)
	p = e.Data:Get(player)
	assert(p.DisplaySlots == 10 and e.Store.Records.Player_213.Data.DisplaySlots == 10)
	assert(p.Income.UpdatedAt == e.Now + 100)
	p.RebirthLevel, p.ToiletTier, p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 15, 7, 10, 10
	p.Inventory.Mystery, p.Displays = 3, { ["1"] = "Mystery", ["2"] = "Mystery", ["3"] = "Mystery" }
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"), u)
	income:Settle(p, e.Now + 86400, true)
	local pending = income:TotalUnits(p)
	assert(pending > 403200 * 6000)
	e.Data:Close(player)
	local _, restored = e:Join(213)
	assert(income:TotalUnits(restored) == pending, "Sanitize applied level-zero pending cap")
end)

test("rebirth: remote spam bounds rejection responses and store writes", function()
	local e = server()
	local player, p = rebirthReady(e, 214)
	local before, writes = #e.Results, e.Store.Writes
	for _ = 1, 1000 do
		e:Fire("Rebirth", player, -1)
	end
	assert(#e.Results == before + 1 and e.Store.Writes == writes and p.RebirthLevel == 0)
	e.Now += 5
	for _ = 1, 1000 do
		e:Fire("Rebirth", player, 0)
	end
	assert(e.Store.Writes == writes + 1 and rebirthSuccesses(e) == 1)
end)
