-- Runs against actual bundled source using audit-harness.luau's controlled scheduler.
local failures, passed = {}, 0
local function test(name, callback)
	local ok, err = pcall(callback)
	if ok then
		passed += 1
		print("PASS " .. name)
	else
		table.insert(failures, name .. ": " .. tostring(err))
		print("FAIL " .. failures[#failures])
	end
end
local dataPath = "src/server/Services/DataService"

test("H1: overlapping same-server rejoin cannot acquire the departing session", function()
	local e = environment()
	local data = e:Load(dataPath)
	local old = e:Player(1)
	data:Load(old)
	data:Get(old).Coins = 100
	old.Parent = nil
	e.Store.Before = function()
		coroutine.yield("save held")
	end
	local close = e:Spawn(function()
		data:Close(old)
	end)
	e.Store.Before = nil
	local replacement = e:Player(1)
	data:Load(replacement)
	assert(data:Get(replacement) == nil and replacement.Kicked, "replacement bypassed the live lock")
	e:Resume(close)
	assert(e.Store.Records.Player_1.Data.Coins == 100 and e.Store.Records.Player_1.Lock == nil)
	local joined = e:Player(1)
	data:Load(joined)
	assert(data:Get(joined).Coins == 100)
end)

test("H1: duplicate Load cannot replace active unsaved progress", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(2)
	data:Load(player)
	local profile = data:Get(player)
	profile.Coins = 123
	local calls = e.Store.Calls
	data:Load(player)
	assert(data:Get(player) == profile and profile.Coins == 123 and e.Store.Calls == calls)
end)

test("H2: expired lease denies gameplay while a save is yielded", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(3)
	data:Load(player)
	local expiry = e.Store.Records.Player_3.Lock.Expires
	e.Store.Before = function()
		coroutine.yield("save held")
	end
	local save = e:Spawn(function()
		data:Save(player, false)
	end)
	e.Now = expiry - 1
	assert(data:Get(player))
	e.Now = expiry
	assert(data:Get(player) == nil and player.Kicked, "expired profile remained writable")
	e.Store.Before = nil
	e:Resume(save)
end)

test("H2: an expired save cannot revive its own lease", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(4)
	data:Load(player)
	data:Get(player).Coins = 999
	e.Now = e.Store.Records.Player_4.Lock.Expires
	assert(not data:Save(player, false), "save renewed an expired lock")
	assert(e.Store.Records.Player_4.Data.Coins == 0)
end)

test("H2: delayed load response cannot expose an expired profile", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(5)
	e.Store.After = function()
		coroutine.yield("load response held")
	end
	local load = e:Spawn(function()
		data:Load(player)
	end)
	e.Now = e.Store.Records.Player_5.Lock.Expires
	e.Store.After = nil
	e:Resume(load)
	assert(data:Get(player) == nil, "expired load became playable")
end)

for _, release in ipairs({ false, true }) do
	test("ownership rechecked on UpdateAsync callback replay, release=" .. tostring(release), function()
		local e = environment()
		local data, player = e:Load(dataPath), e:Player(6)
		data:Load(player)
		data:Get(player).Coins = 99
		e.Store.Replay = function(key)
			e.Store.Records[key] = { Data = { Coins = 777 }, Lock = { Session = "new-owner", Expires = e.Now + 180 } }
		end
		assert(not data:Save(player, release))
		assert(e.Store.Records.Player_6.Data.Coins == 777 and e.Store.Records.Player_6.Lock.Session == "new-owner")
	end)
end

test("save snapshot and simultaneous close preserve later mutations exactly once", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(7)
	data:Load(player)
	local profile = data:Get(player)
	profile.Coins = 10
	e.Store.Before = function()
		coroutine.yield("save held")
	end
	local save = e:Spawn(function()
		data:Save(player, false)
	end)
	profile.Coins = 20
	local close = e:Spawn(function()
		data:Close(player)
	end)
	local duplicateClose = e:Spawn(function()
		data:Close(player)
	end)
	assert(data:Get(player) == nil)
	e.Store.Before = nil
	e:Resume(save)
	assert(e.Store.Records.Player_7.Data.Coins == 10, "save snapshot mutated across yield")
	e:Resume(close)
	if coroutine.status(duplicateClose) ~= "dead" then
		e:Resume(duplicateClose)
	end
	assert(e.Store.Records.Player_7.Data.Coins == 20 and e.Store.Records.Player_7.Lock == nil)
	assert(e.Store.Writes == 3, "duplicate release")
	for _, name in ipairs({ "Profiles", "Saving", "Closing", "NoPersistence", "Sessions", "LeaseExpires", "Loading" }) do
		assert(not data[name] or data[name][player] == nil, name .. " retained player")
	end
end)

test("M1: shutdown waits for a load and its release", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(8)
	data:Start()
	e.Store.After = function()
		coroutine.yield("load held")
	end
	local load = e:Spawn(function()
		data:Load(player)
	end)
	local shutdown = e:Spawn(e.Shutdown)
	assert(coroutine.status(shutdown) == "suspended", "shutdown ignored the pending load")
	e.Store.After = nil
	e.Store.Before = function()
		coroutine.yield("release held")
	end
	e:Resume(load)
	e:Resume(shutdown)
	assert(coroutine.status(shutdown) == "suspended", "shutdown ignored the late load's release")
	e.Store.Before = nil
	e:Resume(load)
	e:Resume(shutdown)
	assert(coroutine.status(shutdown) == "dead" and e.Store.Records.Player_8.Lock == nil)
	assert(data:Get(player) == nil)
end)

test("duplicate in-flight load and leave during load cannot revive a profile", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(9)
	local loaded = 0
	data.Loaded = function()
		loaded += 1
	end
	e.Store.Before = function()
		coroutine.yield("load held")
	end
	local load = e:Spawn(function()
		data:Load(player)
	end)
	data:Load(player)
	assert(e.Store.Calls == 1)
	data:Close(player) -- PlayerRemoving can run before Parent is cleared.
	e.Store.Before = nil
	e:Resume(load)
	assert(loaded == 0 and data:Get(player) == nil and e.Store.Records.Player_9.Lock == nil)
	for _, name in ipairs({ "Profiles", "Loading", "Saving", "Closing", "Sessions", "LeaseExpires", "NoPersistence" }) do
		assert(data[name][player] == nil, name .. " retained departed load")
	end
end)

test("new session token survives an old save resuming after takeover", function()
	local e = environment()
	local data, old = e:Load(dataPath), e:Player(10)
	data:Load(old)
	local token = e.Store.Records.Player_10.Lock.Session
	data:Get(old).Coins = 99
	e.Store.Before = function()
		coroutine.yield("old save held")
	end
	local save = e:Spawn(function()
		assert(not data:Save(old, true))
	end)
	e.Store.Before = nil
	e.Now = e.Store.Records.Player_10.Lock.Expires
	local replacement = e:Player(10)
	data:Load(replacement)
	local replacementToken = e.Store.Records.Player_10.Lock.Session
	assert(replacementToken ~= token)
	data:Get(replacement).Coins = 777
	assert(data:Save(replacement, false))
	e:Resume(save)
	assert(e.Store.Records.Player_10.Data.Coins == 777 and e.Store.Records.Player_10.Lock.Session == replacementToken)
end)

test("load retry after ambiguous commit retains one ownership token", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(11)
	e.Store.After = function()
		error("Mock committed write with lost response")
	end
	local load = e:Spawn(function()
		data:Load(player)
	end)
	local token = e.Store.Records.Player_11.Lock.Session
	e.Store.After = nil
	e:Resume(load)
	assert(data:Get(player) and data.Sessions[player] == token)
	assert(e.Store.Records.Player_11.Lock.Session == token)
end)

test("save retries use an immutable snapshot and fail closed after exhaustion", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(12)
	data:Load(player)
	local profile = data:Get(player)
	profile.Coins = 100
	e.Store.Before = function()
		error("Mock request failed")
	end
	local save = e:Spawn(function()
		assert(not data:Save(player, false))
	end)
	profile.Coins = 200
	for _ = 1, 3 do
		e:Resume(save)
	end
	assert(data:Get(player) == nil and player.Kicked and e.Store.Records.Player_12.Data.Coins == 0)
	e.Store.Before = nil
	data:Close(player)
	assert(e.Store.Records.Player_12.Data.Coins == 200 and e.Store.Records.Player_12.Lock == nil)
end)

test("successful retry and renewal retain mutations for final close", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(13)
	data:Load(player)
	local profile = data:Get(player)
	profile.Coins = 100
	e.Now += 60
	e.Store.Before = function()
		error("Mock transient failure")
	end
	local save = e:Spawn(function()
		assert(data:Save(player, false))
	end)
	profile.Coins = 200
	e.Store.Before = nil
	e:Resume(save)
	assert(e.Store.Records.Player_13.Data.Coins == 100 and data:Get(player).Coins == 200)
	assert(data.LeaseExpires[player] == e.Now + 180)
	data:Close(player)
	assert(e.Store.Records.Player_13.Data.Coins == 200)
end)

for _, options in ipairs({ { Studio = true, NoStore = true }, { Studio = false, NoStore = true } }) do
	test("store unavailable, Studio=" .. tostring(options.Studio), function()
		local e = environment(options)
		local data, player = e:Load(dataPath), e:Player(14)
		data:Load(player)
		if options.Studio then
			assert(data:Get(player) and data.NoPersistence[player])
			data:Get(player).Coins = 55
			assert(data:Save(player, false) and e.Store.Calls == 0)
			data:Close(player)
			assert(data.Profiles[player] == nil and data.NoPersistence[player] == nil)
		else
			assert(data:Get(player) == nil and player.Kicked and next(data.Loading) == nil)
		end
	end)
end

test("shutdown deadline stays bounded when the backend never returns", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(15)
	data:Start()
	e.Store.Before = function()
		coroutine.yield("backend held")
	end
	e:Spawn(function()
		data:Load(player)
	end)
	local shutdown = e:Spawn(e.Shutdown)
	e.Now += 25
	e:Resume(shutdown)
	assert(coroutine.status(shutdown) == "dead")
end)

local function server(options)
	local e = environment(options)
	local world = { Assigned = {}, Start = function() end, Refresh = function() end, Animate = function() end }
	e:Override("src/server/World/WorldService", world)
	e:Load("src/server")
	e.Remotes = {}
	for _, remote in ipairs(e.CreatedRemotes) do
		e.Remotes[remote.Name] = remote
	end
	e.Data = e:Load(dataPath)
	e.World = world
	function e:Join(id)
		local player = self:Player(id)
		local position = setmetatable({}, {
			__sub = function()
				return { Magnitude = player.Distance or 0 }
			end,
		})
		player.Character = {
			FindFirstChild = function()
				return { Position = position }
			end,
		}
		world.Assigned[player] = { CFrame = { Position = position } }
		self.Data:Load(player)
		return player, self.Data:Get(player)
	end
	function e:Fire(name, player, ...)
		self.Remotes[name].OnServerEvent:Fire(player, ...)
	end
	return e
end

test("all actual inbound handlers reject extra arguments and outbound remotes do nothing", function()
	local e = server()
	local player, profile = e:Join(20)
	local inputs = {
		Flush = {},
		Sell = { "Poop", 1 },
		BuyToilet = { "Dirty" },
		Display = { "Poop", 1 },
		ClaimReward = {},
		AutoFlush = { true },
		DevGrant = { "1000" },
		State = {},
		TutorialDone = {},
		Settings = { false },
	}
	local results = #e.Results
	for name, args in pairs(inputs) do
		table.insert(args, "unexpected")
		e:Fire(name, player, table.unpack(args))
	end
	for _, name in ipairs({ "Result", "Event", "ServerLuck" }) do
		e:Fire(name, player, { Coins = 9e15, Luck = 1e9 })
	end
	assert(#e.Results == results and profile.Coins == 0 and profile.Stats.Flushes == 0 and not profile.TutorialDone)
	assert(profile.Settings.Sound)
end)

test("economic argument fuzzing cannot change balances or reserved copies", function()
	local e = environment()
	local economy = e:Load("src/server/Services/EconomyService")
	local display = e:Load("src/server/Services/DisplayService")
	local profile = e:Load(dataPath).DefaultProfile()
	profile.Inventory.Poop = 3
	for _, bad in ipairs({ 0 / 0, math.huge, -math.huge, -1, 0, 1.5, 1000001, "1", {}, true }) do
		assert(not economy.Sell(profile, "Poop", bad))
		assert(not display.Set(profile, "Poop", bad))
	end
	for _, bad in ipairs({ {}, 0 / 0, 42, true, "Unknown", string.rep("A", 10000), "\255" }) do
		assert(not economy.Sell(profile, bad, 1))
		assert(not economy.BuyToilet(profile, bad))
		assert(not display.Set(profile, bad, 1))
	end
	assert(not economy.Sell(profile, nil, 1) and not economy.Sell(profile, "Poop", nil))
	assert(not display.Set(profile, "Poop", nil))
	assert(display.Set(profile, "Poop", 1) and display.Set(profile, "Poop", 2))
	assert(not economy.Sell(profile, "Poop", 2))
	assert(economy.Sell(profile, "Poop", 1))
	assert(not economy.Sell(profile, "Poop", 1))
	assert(display.Set(profile, nil, 1) and economy.Sell(profile, "Poop", 1))
	assert(profile.Inventory.Poop == 1 and profile.Coins == 10 and profile.Stats.Earned == 10)
	profile.Coins = 190
	assert(not economy.BuyToilet(profile, "Golden") and economy.BuyToilet(profile, "Dirty"))
	assert(not economy.BuyToilet(profile, "Dirty") and profile.Coins == 0 and profile.ToiletTier == 2)
end)

test("server handlers enforce token limits and preference types", function()
	local e = server()
	local player, profile = e:Join(21)
	profile.Inventory.Poop = 20
	for _ = 1, 100 do
		e:Fire("Sell", player, "Poop", 1)
	end
	assert(profile.Inventory.Poop == 15 and profile.Coins == 25)
	local count = #e.Results
	for _ = 1, 100 do
		e:Fire("State", player)
	end
	assert(#e.Results == count + 2)
	for _, bad in ipairs({ {}, 0, "false", 0 / 0 }) do
		e:Fire("Settings", player, bad)
		e:Fire("AutoFlush", player, bad)
	end
	assert(profile.Settings.Sound)
	e:Fire("Settings", player, false)
	e:Fire("TutorialDone", player)
	assert(not profile.Settings.Sound and profile.TutorialDone and profile.Coins == 25)
	e:Fire("AutoFlush", player, true)
	assert(not e:Load("src/server/Services/MonetizationService").Auto[player])
end)

test("manual, prompt and auto flush share cooldown and server-owned RNG", function()
	local e = server()
	local player, profile = e:Join(22)
	local monetization = e:Load("src/server/Services/MonetizationService")
	monetization.Owned[player] = { AutoFlush = true } -- Mock a trusted entitlement for the existing stub.
	e:Fire("AutoFlush", player, true)
	e:Fire("Flush", player)
	e.World.Flush(player)
	local autoThread = e.Threads[1]
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 1 and profile.Inventory.Poop == 1)
	e.Now += 3
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 2 and profile.Inventory.Poop == 2)
	e.Now += 3
	player.Distance = 100
	e:Fire("Flush", player)
	assert(profile.Stats.Flushes == 2)
	player.Distance = 0
	e.Now += 3
	e:Fire("Flush", player, "Mystery", 1e9)
	assert(profile.Stats.Flushes == 2)
	e.Data:Close(player)
	e.Now += 3
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 2)
end)

test("duplicate daily claim during a yielding save credits only once", function()
	local e = server()
	local player, profile = e:Join(23)
	e.Store.Before = function()
		coroutine.yield("claim save held")
	end
	local claim = e:Spawn(function()
		e:Fire("ClaimReward", player)
	end)
	e:Fire("ClaimReward", player)
	assert(profile.Coins == 25 and profile.Streak == 1 and e.Store.Calls == 2)
	e.Store.Before = nil
	e:Resume(claim)
	assert(e.Store.Records.Player_23.Data.Coins == 25)
	local successes = 0
	for _, result in ipairs(e.Results) do
		if result.Payload[1] == "ClaimReward" and result.Payload[2].Success then
			successes += 1
		end
	end
	assert(successes == 1)
end)

for _, studio in ipairs({ false, true }) do
	test("developer grant guard, Studio=" .. tostring(studio), function()
		local e = server({ Studio = studio })
		local player, profile = e:Join(24)
		e:Fire("DevGrant", player, 10000000)
		e:Fire("DevGrant", player, "10000000", "extra")
		e:Fire("DevGrant", player, "1000")
		e:Fire("DevGrant", player, "1000")
		e:Fire("DevGrant", player, "1000")
		assert(profile.Coins == (if studio then 2000 else 0))
	end)
end

test("PlayerRemoving cleans service tables and late entitlement lookup", function()
	local e = server()
	local player = e:Join(25)
	e:Fire("Flush", player)
	local monetization = e:Load("src/server/Services/MonetizationService")
	local config = e:Load("src/shared/Config/Monetization")
	config.Gamepasses.AutoFlush.Id = 1 -- Test-only value, never written to production config.
	e.Marketplace.Lookup = function()
		coroutine.yield("lookup held")
		return true
	end
	local lookup = e:Spawn(function()
		monetization:Load(player)
	end)
	e.Players.PlayerRemoving:Fire(player)
	player.Parent = nil
	e:Resume(lookup)
	assert(monetization.Owned[player] == nil and monetization.Auto[player] == nil)
	for _, name in ipairs({ "Profiles", "Saving", "Closing", "Loading", "Sessions", "LeaseExpires", "NoPersistence" }) do
		assert(e.Data[name][player] == nil, name .. " retained player")
	end
end)

print(string.format("Audit regressions: %d passed, %d failed", passed, #failures))
assert(#failures == 0, table.concat(failures, "\n"))
