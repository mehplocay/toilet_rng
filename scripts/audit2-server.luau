-- Full-game follow-up: actual production handlers, controlled backend yields.
test("audit2: all tier/track/rebirth/boost combinations obey the total luck and cooldown caps", function()
	local e = environment()
	local rules = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local profile = e:Load(dataPath).DefaultProfile()
	for _, toilet in ipairs(e:Load("src/shared/Config/Toilets")) do
		for level = 0, 50 do
			profile.Upgrades.LuckBoost, profile.Upgrades.FlushSpeed = level, math.min(level, 10)
			for rebirth = 0, 15 do
				profile.RebirthLevel = rebirth
				for daily = 1, 2 do
					for event = 1, 2 do
						for pass = 1, 2 do
							local luck = rules:Luck(profile, toilet.Luck, event, pass, daily)
							assert(luck >= 1 and luck <= 10)
							local expected = math.min(
								10,
								toilet.Luck
									* (1 + math.min(level, 10) * 0.1 + math.max(0, level - 10) * 0.04 + rules:RebirthBonus(
										profile,
										"Luck"
									))
									* event
									* pass
									* daily
							)
							assert(math.abs(luck - expected) < 1e-12)
							assert(rules:Cooldown(profile, toilet.Cooldown * 0.8) >= 0.4)
						end
					end
				end
			end
		end
	end
end)

test("audit2: twelve-player capped flush traffic remains two direct messages per award", function()
	local e = server()
	local players = {}
	for i = 1, 12 do
		local player, profile = e:Join(300 + i)
		profile.ToiletTier, profile.RebirthLevel = 7, 15
		profile.Upgrades.FlushSpeed, profile.Upgrades.LuckBoost, profile.Upgrades.CashBoost = 10, 10, 10
		players[i] = player
	end
	table.clear(e.Results)
	local started = os.clock()
	for _ = 1, 100 do
		e.Now += 0.401
		for _, player in ipairs(players) do
			e:Fire("Flush", player)
		end
	end
	local elapsed = os.clock() - started
	assert(#e.Results == 2400)
	local function jsonSize(value)
		if type(value) == "table" then
			local size, count = 2, 0
			for key, child in pairs(value) do
				size += #tostring(key) + 3 + jsonSize(child)
				count += 1
			end
			return size + math.max(0, count - 1)
		end
		return #tostring(value) + (if type(value) == "string" then 2 else 0)
	end
	local state, award
	for _, message in ipairs(e.Results) do
		if type(message.Payload[1]) == "table" then
			state = message.Payload[1]
		end
		if message.Payload[1] == "Flush" then
			award = message.Payload[2]
		end
	end
	assert(state and award)
	print(
		string.format(
			"Audit2 payload proxy: State %d + Flush result %d JSON-equivalent bytes (not Roblox wire encoding)",
			jsonSize(state),
			jsonSize(award)
		)
	)
	for _, player in ipairs(players) do
		assert(e.Data:Get(player).Stats.Flushes == 100)
	end
	print(
		string.format(
			"Audit2 headless CPU: 1200 real handler flushes in %.4fs; %.3fms/flush (mock world/network; not engine frame time)",
			elapsed,
			elapsed * 1000 / 1200
		)
	)
end)
test("audit2: Studio persistence is isolated from production", function()
	for _, studio in ipairs({ false, true }) do
		local e = environment({ Studio = studio })
		e:Load(dataPath)
		assert(e.StoreName == (if studio then "ToiletRNG_Studio_v1" else "ToiletRNG_v1"))
	end
end)

test("audit2: Studio grants reject Earned saturation atomically", function()
	local e = server({ Studio = true })
	local player, profile = e:Join(201)
	profile.Stats.Earned = 9e15
	e:Fire("DevGrant", player, "1000")
	assert(profile.Coins == 0 and profile.Stats.Earned == 9e15)
end)

test("audit2: yielding saves cannot accumulate upgrade/index/daily save waiters", function()
	local e = server()
	local player, profile = e:Join(202)
	profile.Coins = 1000000
	profile.Collection.Poop = 1
	e.Store.Before = function()
		coroutine.yield("backend held")
	end
	local save = e:Spawn(function()
		e.Data:Save(player, false)
	end)
	local calls = e.Store.Calls
	for i = 1, 40 do
		e.Now += 1
		for _, request in ipairs({
			{ "BuyUpgrade", "CashBoost", 0 },
			{ "ClaimIndexReward", "rarity:Common" },
			{ "ClaimReward" },
		}) do
			local thread = e:Spawn(function()
				e:Fire(request[1], player, table.unpack(request, 2))
			end)
			assert(coroutine.status(thread) == "dead", "Remote created a queued save waiter")
		end
	end
	assert(profile.Coins == 1000000 and profile.Upgrades.CashBoost == 0 and profile.Stamps == 0 and profile.Streak == 0)
	assert(e.Store.Calls == calls)
	e.Store.Before = nil
	e:Resume(save)
	e:Fire("BuyUpgrade", player, "CashBoost", 0)
	assert(profile.Upgrades.CashBoost == 1)
end)

test("audit2: daily save completion after departure sends no stale success", function()
	local e = server()
	local player = e:Join(203)
	e.Store.After = function()
		coroutine.yield("response held")
	end
	local claim = e:Spawn(function()
		e:Fire("ClaimReward", player)
	end)
	local close = e:Spawn(function()
		e.Data:Close(player)
	end)
	local count = #e.Results
	e.Store.After = nil
	e:Resume(claim)
	assert(#e.Results == count, "Departed session received success")
	e:Resume(close)
	assert(e.Store.Records.Player_203.Data.Coins == 25)
end)

test("audit2: unexpected/replayed product receipts defer without granting", function()
	local e = server()
	local _, profile = e:Join(204)
	assert(type(e.Marketplace.ProcessReceipt) == "function", "Missing receipt guard auto-acknowledges products")
	for _ = 1, 3 do
		assert(
			e.Marketplace.ProcessReceipt({ PlayerId = 204, ProductId = 123, PurchaseId = "unimplemented" })
				== "NotProcessedYet"
		)
	end
	assert(profile.Coins == 0 and profile.Stats.Flushes == 0)
end)

test("audit2: zero/unknown passes never query, prompt or grant", function()
	local e = server({ ZeroCommerceIds = true })
	local service = e:Load("src/server/Services/MonetizationService")
	local queries, prompts = 0, 0
	e.Marketplace.Lookup = function()
		queries += 1
		return false
	end
	e.Marketplace.PromptGamePassPurchase = function()
		prompts += 1
	end
	local raw = e.Data.DefaultProfile()
	raw.Monetization.Passes = { VIPStar = true, FastFlush = true }
	e.Store.Records.Player_205 = { Data = raw }
	local player, profile = e:Join(205)
	local keys = table.clone(e:Load("src/shared/Config/Monetization").PassOrder)
	for _, key in ipairs({ "Unknown", {}, 0 / 0, string.rep("A", 10000) }) do
		table.insert(keys, key)
	end
	for _, key in ipairs(keys) do
		e.Now += 5
		e:Fire("BuyPass", player, key)
	end
	e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 0, true)
	e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 123, true)
	assert(service.Owned[player].VIPStar == false and service.Owned[player].FastFlush == false)
	assert(profile.Coins == 0 and service:Luck(player) == 1)
	assert(queries == 0 and prompts == 0)
end)

test("audit2: verified pass grant survives a yielded stale lookup and callback replay", function()
	local e = server({ ZeroCommerceIds = true })
	local player = e:Join(206)
	local service = e:Load("src/server/Services/MonetizationService")
	local config = e:Load("src/shared/Config/Monetization")
	config.Gamepasses.VIPStar.Id = 123 -- Only this fixture pass is enabled.
	e.Marketplace.Lookup = function()
		coroutine.yield("ownership held")
		return false
	end
	local lookup = e:Spawn(function()
		service:Load(player)
	end)
	local before = #e.Results
	for _ = 1, 3 do
		e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 123, true)
	end
	e:Resume(lookup)
	assert(coroutine.status(lookup) == "dead", "Fixture lookup did not finish")
	assert(service.Owned[player].VIPStar == true)
	e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 123, false)
	assert(service.Owned[player].VIPStar == true)
	assert(#e.Results == before + 2, "Pass completion replay amplified result/state traffic")
end)

test("audit2: event banners use bounded account identity instead of display-name impersonation", function()
	local e = environment()
	local sent
	local events = e:Load("src/server/Services/EventService").new(e:Load("src/shared/Config/Events"), function()
		return e.Now
	end, function(payload)
		sent = payload
	end, function() end)
	events:Trigger(
		{ Name = "Account_123", DisplayName = "<b>Admin</b>\nFREE ROBUX" },
		e:Load("src/shared/Config/Items")[9],
		1
	)
	assert(sent.PlayerName == "Account_123")
end)
