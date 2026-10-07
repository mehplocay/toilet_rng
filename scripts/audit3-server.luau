-- Third review: production handlers with mocked engine services and a controlled scheduler.
test("audit3: every public remote rejects surplus arguments without relaying payloads", function()
	local e = server()
	local player, p = e:Join(2998)
	local cycle = {}
	cycle.Self = cycle
	local before, writes, count = #e.Results, e.Store.Writes, 0
	for name in pairs(e.Remotes) do
		count += 1
		e:Fire(name, player, cycle, cycle, cycle, cycle)
	end
	assert(count == 32, "Update the audit inventory when public remotes change")
	assert(#e.Results == before + 1 and e.Store.Writes == writes)
	local rejection = e.Results[#e.Results].Payload
	assert(rejection[1] == "BuyProduct" and rejection[2].Success == false)
	assert(
		rejection[2].Message == "Invalid purchase request. Please reopen the offer and try again.",
		"Rejected request relayed client payload"
	)
	assert(p.Coins == 0 and p.Stats.Flushes == 0 and not p.TutorialDone)
end)

test("audit3: malformed scalar and cyclic payload matrix never mutates player progression", function()
	local cycle = {}
	cycle.Self = cycle
	for _, bad in ipairs({
		0 / 0,
		math.huge,
		-math.huge,
		-1,
		9e15,
		1.25,
		string.rep("x", 100000),
		"\255",
		{},
		cycle,
		setmetatable({}, {}),
	}) do
		-- Fresh session: full admission buckets and an unexpired lease for every value.
		local e = server()
		local player, p = e:Join(2999)
		p.Coins, p.Inventory.Poop, p.Stats.Flushes, p.RunFlushes = 1e12, 10, 300, 300
		local writes = e.Store.Writes
		for name in pairs(e.Remotes) do
			if name == "BuyProduct" then
				e:Fire(name, player, bad, bad, bad)
			elseif name == "Sell" or name == "Display" or name == "BuyUpgrade" then
				e:Fire(name, player, bad, bad)
			else
				e:Fire(name, player, bad)
			end
		end
		assert(e.Data:Get(player) == p and e.Store.Writes == writes)
		assert(p.Coins == 1e12 and p.Inventory.Poop == 10 and p.Stats.Flushes == 300 and p.RunFlushes == 300)
		assert(p.ToiletTier == 1 and p.RebirthLevel == 0 and p.Stamps == 0 and next(p.Displays) == nil)
		assert(not p.TutorialDone and p.Settings.Sound and p.Monetization.LuckyFlushes == 0)
	end
end)

test("audit3: twelve-player collection flood is rejected before profile settlement", function()
	local e = server()
	local players = {}
	for i = 1, 12 do
		players[i] = e:Join(3000 + i)
	end
	local get, reads = e.Data.Get, 0
	e.Data.Get = function(self, player)
		reads += 1
		return get(self, player)
	end
	local writes = e.Store.Writes
	for _ = 1, 1000 do
		for _, player in ipairs(players) do
			e:Fire("CollectIncome", player)
			e:Fire("CollectOffline", player)
			e.World.CollectIncome(player, nil, true)
		end
	end
	assert(reads <= 12 * 24, "Rate-rejected requests still reach income settlement: " .. reads)
	assert(e.Store.Writes == writes)
end)

test("audit3: unknown index IDs never echo arbitrary client text or build State", function()
	local e = server()
	local player, p = e:Join(3020)
	local before = #e.Results
	e:Fire("ClaimIndexReward", player, string.rep("x", 100000))
	e:Fire("ClaimIndexReward", player, "<font>forged reward</font>")
	assert(#e.Results == before and p.Stamps == 0, "Unknown index ID reflected to client")
	e.Now += 5
	p.Collection.Poop = 1
	-- A catalog ID continues through the ordinary eligibility path.
	local indexConfig = e:Load("src/shared/Config/IndexRewards")
	local index = e:Load("src/shared/IndexProgress").new(e:Load("src/shared/Config/Items"), indexConfig)
	e:Fire("ClaimIndexReward", player, index.Rewards[1].Id)
	assert(#e.Results > before)
end)

test("audit3: unrelated product completion cannot unlock an active quoted prompt", function()
	local e, player, p, commerce, config = catalogPlayer(3021)
	local key = "Coins10Minutes"
	e:Fire("BuyProduct", player, key, commerce.Receipts:Quote(p, key))
	local pending = commerce.Prompting[player]
	assert(pending)
	for _, id in ipairs({ -1, 0, config.DeveloperProducts.Coins1Hour.Id }) do
		for _, purchased in ipairs({ false, true }) do
			e.Marketplace.PromptProductPurchaseFinished:Fire(player.UserId, id, purchased)
			assert(commerce.Prompting[player] == pending, "Unrelated completion cleared prompt")
		end
	end
	e.Marketplace.PromptProductPurchaseFinished:Fire(player.UserId, config.DeveloperProducts[key].Id, false)
	assert(not commerce.Prompting[player] and not e.Data:Get(player).Monetization.Quote)
end)

test("audit3: exclusive saves pause auto awards without deleting its activity session", function()
	local e, player, p = catalogPlayer(3022)
	p.Stats.Flushes = 100
	e:Fire("AutoFlush", player, true)
	local auto = e:Load("src/server/Services/MonetizationService")
	local activity = auto.Activity[player]
	local replacement = e:Load("src/shared/CommerceProfile").Copy(p)
	e.Store.Before = function()
		coroutine.yield("exclusive save")
	end
	local saving = e:Spawn(function()
		assert(e.Data:ReplaceAndSave(player, p, replacement))
	end)
	for _ = 1, 10 do
		e.Now += 0.1
		e:Resume(e.Threads[1])
	end
	assert(auto.Auto[player] and auto.Activity[player] == activity, "Exclusive save disabled auto")
	assert(replacement.Stats.Flushes == 100 and not e.Data:Get(player))
	e.Store.Before = nil
	e:Resume(saving)
	e:Resume(e.Threads[1])
	assert(replacement.Stats.Flushes == 101, "Auto did not resume exactly one award")
end)

for _, cause in ipairs({ "death", "expiry", "closing", "leave", "stopping" }) do
	test("audit3: auto exclusive-save pause still fails closed on " .. cause, function()
		local e, player, p = catalogPlayer(3023)
		p.Stats.Flushes = 100
		e:Fire("AutoFlush", player, true)
		e.Data.Replacing[player] = true
		if cause == "death" then
			player.Health = 0
		elseif cause == "expiry" then
			e.Now += 181
		elseif cause == "closing" then
			e.Data.Closing[player] = true
		elseif cause == "leave" then
			player.Parent = nil
		else
			e.Data.Stopping = true
		end
		local auto = e:Load("src/server/Services/MonetizationService")
		assert(not auto:CanAuto(player))
		e.World.Flush(player, true)
		assert(p.Stats.Flushes == 100)
	end)
end

test("audit3: table validators reject metatables and cyclic nested payloads", function()
	local e = environment()
	local audio = e:Load("src/shared/AudioSettings")
	local presentation = e:Load("src/shared/PresentationSettings")
	local raw = { MusicVolume = 1, SFXVolume = 1, MusicMuted = false, SFXMuted = false }
	assert(not audio.ValidRequest(setmetatable(raw, {})))
	assert(not presentation.ValidRequest(setmetatable({ ChatMessages = "All" }, {})))
	local cycle = {}
	cycle.ChatMessages = cycle
	assert(not presentation.ValidRequest(cycle) and not audio.ValidRequest(cycle))
	local rules = e:Load("src/server/Admin/Rules")
	local config = e:Load("src/shared/Config/Admin")
	assert(not rules.JsonTree(cycle, config))
	assert(not rules.JsonTree(setmetatable({}, {}), config))
	local schema = rules.new(
		config,
		e:Load("src/shared/Config/Items"),
		e:Load("src/shared/Config/Toilets"),
		e:Load("src/shared/Config/Upgrades"),
		e:Load("src/shared/Config/Rebirth")
	)
	assert(not schema:Valid("Give", setmetatable({}, { __index = { ItemId = "Poop", Count = 10000 } })))
end)
