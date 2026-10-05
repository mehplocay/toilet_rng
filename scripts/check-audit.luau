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

test("merged profile fields survive sanitize, save and rejoin", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(16)
	e.Store.Records.Player_16 = {
		Data = {
			TutorialDone = true,
			Settings = { Sound = false, SkipAnimation = true, PlotColor = "Mint", AutoFlush = true },
			Coins = 321,
			LastClaimDay = 20000,
			Streak = 2,
			RewardLuckExpires = e.Now + 60,
			Inventory = { Poop = 2, Unknown = 99 },
			Collection = { Poop = 10, Rat = 4 },
			Stamps = 12,
			IndexClaims = { ["total:5"] = true, ["total:8"] = true, founding = true, Unknown = true },
			IndexCosmetics = { Unverified = true },
			ToiletTier = 3,
			DisplaySlots = 3,
			Displays = { ["1"] = "Poop", ["2"] = "Poop", ["3"] = "Poop", ["4"] = "Unknown" },
			Stats = { Flushes = 150, Earned = 600 },
		},
	}
	local function verify(profile)
		assert(profile.TutorialDone and not profile.Settings.Sound and profile.Settings.SkipAnimation)
		assert(profile.Settings.PlotColor == "Mint" and profile.Settings.AutoFlush == nil)
		assert(profile.Coins == 321 and profile.LastClaimDay == 20000 and profile.Streak == 2)
		assert(profile.RewardLuckExpires == e.Now + 60 and profile.ToiletTier == 3)
		assert(profile.Inventory.Poop == 2 and profile.Inventory.Unknown == nil)
		assert(profile.Collection.Poop == 10 and profile.Collection.Rat == 4)
		assert(profile.Stamps == 12 and profile.IndexClaims["total:5"] and profile.IndexClaims["total:8"])
		assert(profile.IndexClaims.founding and profile.IndexClaims.Unknown == nil)
		assert(profile.IndexCosmetics.PipeApprentice and profile.IndexCosmetics.FoundingFlush)
		assert(profile.IndexCosmetics.Unverified == nil and profile.DisplaySlots == 4)
		local displayed = 0
		for slot, id in pairs(profile.Displays) do
			assert(tonumber(slot) <= 3 and id == "Poop")
			displayed += 1
		end
		assert(displayed == 2 and profile.Displays["4"] == nil)
		assert(profile.Stats.Flushes == 150 and profile.Stats.Earned == 600)
	end
	data:Load(player)
	verify(data:Get(player))
	data:Close(player)
	local rejoined = e:Player(16)
	data:Load(rejoined)
	verify(data:Get(rejoined))
end)

local function server(options)
	local e = environment(options)
	local world = {
		Assigned = {},
		Start = function() end,
		Refresh = function() end,
		RefreshIncome = function() end,
		Animate = function() end,
	}
	e:Override("src/server/World/WorldService", world)
	-- Geometry is outside this security harness; retain the actual cosmetic/ownership service.
	e:Override("src/shared/Visuals/Primitives", {})
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
			FindFirstChild = function(_, name)
				return if name == "HumanoidRootPart" then { Position = position } else nil
			end,
			FindFirstChildWhichIsA = function()
				return { Health = player.Health or 100 }
			end,
		}
		world.Assigned[player] = {
			Owner = player,
			IncomePoint = { Position = position },
			CFrame = { Position = position },
			Model = {
				GetChildren = function()
					return {}
				end,
			},
		}
		self.Players.PlayerAdded:Fire(player)
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
		CollectIncome = {},
		ClaimReward = {},
		ClaimIndexReward = { "rarity:Common" },
		AutoFlush = { true },
		AnimationSkip = { true },
		PlotColor = { "Mint" },
		BuyPass = { "VIPStar" },
		RefreshPasses = {},
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
	for _, name in ipairs({ "Result", "Event", "ServerLuck", "IncomePending" }) do
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
	profile.Stats.Flushes = 100 -- Free unlock uses successful lifetime flushes, not a pass.
	monetization.Owned[player] = { FastFlush = true }
	local cooldown = e:Load("src/shared/Config/Toilets")[1].Cooldown * 0.8
	e:Fire("AutoFlush", player, true)
	e:Fire("Flush", player)
	e.World.Flush(player)
	local autoThread = e.Threads[1]
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 101 and profile.Inventory.Poop == 1 and profile.Coins == 1)
	e.Now += cooldown - 0.01
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 101)
	e.Now += 0.02
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 102 and profile.Inventory.Poop == 2 and profile.Coins == 2)
	assert(profile.Stats.Earned == 2 and profile.Collection.Poop == 2)
	local results = 0
	for _, result in ipairs(e.Results) do
		if result.Payload[1] == "Flush" then
			results += 1
			assert(result.Payload[2].ServiceCoins == 1 and result.Payload[2].Cooldown == cooldown)
		end
	end
	assert(results == 2)
	e.Now += 3
	player.Distance = 100
	e:Fire("Flush", player)
	assert(profile.Stats.Flushes == 102)
	player.Distance = 0
	e.Now += 3
	e:Fire("Flush", player, "Mystery", 1e9)
	assert(profile.Stats.Flushes == 102)
	e.Data:Close(player)
	e.Now += 3
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 102)
end)

test("manual and automatic flush reject foreign plots and non-finite distances", function()
	local e = server()
	local player, profile = e:Join(26)
	profile.Stats.Flushes = 100
	local plot = e.World.Assigned[player]
	for _, distance in ipairs({ -1, 15, 0 / 0, math.huge, -math.huge }) do
		player.Distance = distance
		e.Now += 3
		e:Fire("Flush", player)
		e.World.Flush(player, true)
	end
	player.Distance = 0
	plot.Owner = e:Player(27)
	e.Now += 3
	e:Fire("Flush", player)
	e.World.Flush(player, true)
	plot.Owner = player
	player.Health = 0
	e.Now += 3
	e:Fire("Flush", player)
	e.World.Flush(player, true)
	player.Health = 100
	local character = player.Character
	player.Character = nil
	e.Now += 3
	e:Fire("Flush", player)
	e.World.Flush(player, true)
	player.Character = character
	e.World.Assigned[player] = nil
	e.Now += 3
	e:Fire("Flush", player)
	e.World.Flush(player, true)
	assert(profile.Stats.Flushes == 100 and profile.Coins == 0 and profile.Inventory.Poop == 0)
	e.World.Assigned[player] = plot
	e.Now += 3
	e:Fire("Flush", player)
	assert(profile.Stats.Flushes == 101 and profile.Coins == 1 and profile.Inventory.Poop == 1)
end)

test("auto flush shares manual rate limits and stops on character removal", function()
	local e = server()
	local player, profile = e:Join(28)
	profile.Stats.Flushes = 100
	local monetization = e:Load("src/server/Services/MonetizationService")
	e:Fire("AutoFlush", player, true)
	assert(monetization.Auto[player])
	player.Distance = 15
	e:Fire("Flush", player)
	e.World.Flush(player) -- Both manual entry points consume the shared bucket.
	player.Distance = 0
	local autoThread = e.Threads[1]
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 100 and profile.Coins == 0)
	e.Now += 1
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 101 and profile.Coins == 1)
	player.CharacterRemoving:Fire(player.Character)
	assert(not monetization.Auto[player])
	e.Now += 3
	e:Resume(autoThread)
	assert(profile.Stats.Flushes == 101 and profile.Coins == 1)
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
	config.Gamepasses.VIPStar.Id = 1 -- Test-only value, never written to production config.
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

test("income migration, offline cap and ambiguous acquisition consume time once", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(50)
	local start = e.Now
	e.Store.Records.Player_50 = { Data = { Inventory = { Fish = 1 }, Displays = { ["1"] = "Fish" } } }
	data:Load(player)
	local p = data:Get(player)
	assert(p.Income.UpdatedAt == start and next(p.Income.Pending) == nil, "Migration granted retroactive income")
	data:Close(player)
	e.Now += 86400 * 30
	local joined = e:Player(50)
	e.Store.After = function()
		error("committed load response lost")
	end
	local load = e:Spawn(function()
		data:Load(joined)
	end)
	e.Store.After = nil
	e:Resume(load)
	p = data:Get(joined)
	assert(p.Income.Pending["1"] == 240 * 6000 and p.Income.UpdatedAt == e.Now)
	data:Close(joined)
	local third = e:Player(50)
	data:Load(third)
	assert(data:Get(third).Income.Pending["1"] == 240 * 6000, "Reconnect duplicated offline credit")
end)

test("income settles before display removal, replacement and tier change; reservations remain", function()
	local e = server()
	local player, p = e:Join(51)
	p.Inventory.Fish, p.Inventory.Poop = 1, 2
	e:Fire("Display", player, "Fish", 1)
	e.Now += 60
	e:Fire("Display", player, nil, 1)
	assert(p.Income.Pending["1"] == 6000)
	e:Fire("Display", player, "Poop", 1)
	e.Now += 60
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == 6300)
	e:Fire("Sell", player, "Poop", 2)
	assert(p.Inventory.Poop == 2, "Sale consumed reserved/first copy")
	e:Fire("Sell", player, "Poop", 1)
	assert(p.Inventory.Poop == 1)
	e:Fire("Display", player, nil, 1)
	e.Now += 10
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == 6300, "Empty slot earned income")
	e:Fire("Sell", player, "Poop", 1)
	assert(p.Inventory.Poop == 1, "First-copy protection changed")
	e:Fire("Display", player, "Fish", 1)
	p.Coins = 1000
	e.Now += 10
	e:Fire("BuyToilet", player, "Dirty")
	assert(p.ToiletTier == 2 and p.Income.Pending["1"] == 7300)
	e.Now += 20
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == 9800, "New tier cap applied retroactively")
end)

test("income collect validates geometry, ownership, life, arguments and shared rate limit", function()
	local e = server()
	local player, p = e:Join(52)
	p.Income.Pending["1"] = 60000
	local calls = e.Store.Calls
	for _, distance in ipairs({ -1, 11, 0 / 0, math.huge, -math.huge }) do
		player.Distance = distance
		e.Now += 5
		e:Fire("CollectIncome", player)
	end
	player.Distance, player.Health = 0, 0
	e.Now += 5
	e:Fire("CollectIncome", player)
	player.Health = 100
	local plot = e.World.Assigned[player]
	plot.Owner = e:Player(999)
	e.Now += 5
	e:Fire("CollectIncome", player)
	plot.Owner = player
	e.Now += 5
	e:Fire("CollectIncome", player, 99999)
	e:Fire("CollectIncome", player) -- Invalid request consumed the token.
	assert(p.Coins == 0 and e.Store.Calls == calls)
	e.Now += 5
	e:Fire("CollectIncome", player)
	assert(p.Coins == 10 and next(p.Income.Pending) == nil and e.Store.Calls == calls + 1)
	p.Income.Pending["1"] = 6000
	e:Fire("CollectIncome", player)
	assert(p.Coins == 10 and p.Income.Pending["1"] == 6000)
	e.Now += 5
	e:Fire("CollectIncome", player)
	assert(p.Coins == 11 and e.Store.Records.Player_52.Data.Coins == 11)
end)

test("income delayed collect save, duplicate requests and overlapping rejoin cannot duplicate", function()
	local e = server()
	local player, p = e:Join(53)
	p.Income.Pending["1"] = 60000
	e.Store.Before = function()
		coroutine.yield("collect held")
	end
	local collect = e:Spawn(function()
		e:Fire("CollectIncome", player)
	end)
	assert(p.Coins == 10 and next(p.Income.Pending) == nil)
	e.Now += 5
	e:Fire("CollectIncome", player)
	assert(p.Coins == 10 and e.Store.Calls == 2)
	e.Store.Before = nil
	local replacement = e:Player(53)
	e.Data:Load(replacement)
	assert(e.Data:Get(replacement) == nil)
	e:Resume(collect)
	e.Data:Close(player)
	local nextPlayer = e:Join(53)
	local nextProfile = e.Data:Get(nextPlayer)
	e:Fire("CollectIncome", nextPlayer)
	assert(nextProfile.Coins == 10 and next(nextProfile.Income.Pending) == nil)
end)

test("income load/save callback replay and takeover preserve atomic wallet/pending", function()
	local e = server()
	local player, p = e:Join(54)
	p.Income.Pending["1"] = 60000
	assert(e.Data:Save(player, false))
	e.Store.Before = function()
		coroutine.yield("collect held")
	end
	local collect = e:Spawn(function()
		e:Fire("CollectIncome", player)
	end)
	e.Store.Before = nil
	e.Now += 180
	assert(e.Data:Get(player) == nil)
	local joined = e:Join(54)
	e:Fire("CollectIncome", joined)
	e:Resume(collect)
	assert(e.Store.Records.Player_54.Data.Coins == 10)
	assert(next(e.Store.Records.Player_54.Data.Income.Pending) == nil)
	local success = 0
	for _, result in ipairs(e.Results) do
		if result.Payload[1] == "CollectIncome" and result.Payload[2].Success then
			success += 1
		end
	end
	assert(success == 1, "Old session announced success after losing its lease")
end)

test("income collect retry after committed response loss cannot credit twice", function()
	local e = server()
	local player, p = e:Join(55)
	p.Income.Pending["1"] = 60000
	e.Store.After = function()
		error("collect committed response lost")
	end
	local collect = e:Spawn(function()
		e:Fire("CollectIncome", player)
	end)
	assert(e.Store.Records.Player_55.Data.Coins == 10)
	e.Store.After = nil
	e.Store.Replay = function() end
	e:Resume(collect)
	e.Now += 5
	e:Fire("CollectIncome", player)
	assert(p.Coins == 10 and e.Store.Records.Player_55.Data.Coins == 10)
	assert(next(e.Store.Records.Player_55.Data.Income.Pending) == nil)
end)

test("income departure timestamp freezes before a queued final save yields", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(56)
	data:Load(player)
	local p = data:Get(player)
	p.Inventory.Fish, p.Displays["1"] = 1, "Fish"
	e.Store.Before = function()
		coroutine.yield("autosave held")
	end
	local save = e:Spawn(function()
		data:Save(player, false)
	end)
	e.Now += 30
	local departure = e.Now
	local close = e:Spawn(function()
		data:Close(player)
	end)
	e.Now += 60
	e.Store.Before = nil
	e:Resume(save)
	e:Resume(close)
	local saved = e.Store.Records.Player_56.Data.Income
	assert(saved.UpdatedAt == departure and saved.Pending["1"] == 3000)
	e.Now += 86400
	local joined = e:Player(56)
	data:Load(joined)
	assert(data:Get(joined).Income.Pending["1"] == 3000 + 240 * 6000)
end)

print(string.format("Audit regressions: %d passed, %d failed", passed, #failures))
assert(#failures == 0, table.concat(failures, "\n"))
