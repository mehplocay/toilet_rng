-- Appended by check-audit.ps1; executes real remotes, saves, sanitizers and clock gates.
test("merge: capped RNG odds, cash, lifetime collection and animation survive manual/auto reveals", function()
	local e = server()
	local player, p = e:Join(101)
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	local roll = e:Load("src/server/Services/RollService")
	local animations = {}
	e.World.Animate = function(_, owner, item, skip, duration)
		assert(owner == player and skip == false)
		table.insert(animations, { Item = item, Duration = duration })
	end
	local lastId = 0
	for _, upgraded in ipairs({ false, true }) do
		if upgraded then
			p.ToiletTier = 7
			p.Upgrades.CashBoost, p.Upgrades.LuckBoost = 10, 10
			p.Upgrades.FlushSpeed, p.Upgrades.AutoFlushSpeed = 10, 10
			p.RewardLuckExpires = e.Now + 60
		end
		local luck, cooldown = if upgraded then 5 else 1, if upgraded then 0.4 else 1.5
		local expected = {}
		for _, entry in ipairs(roll.Distribution(items, toilets, p.ToiletTier, luck)) do
			expected[entry.Item.Id] = entry.Probability
		end
		for _, automatic in ipairs({ false, true }) do
			e.Now += 3.01
			local before, coins = #e.Results, p.Coins
			e.World.Flush(player, automatic)
			local payload
			for i = before + 1, #e.Results do
				if e.Results[i].Payload[1] == "Flush" then
					assert(not payload, "One flush emitted multiple reveal results")
					payload = e.Results[i].Payload[2]
				end
			end
			assert(payload and payload.FlushId == lastId + 1)
			lastId = payload.FlushId
			local animation = animations[#animations]
			assert(payload.Rarity == animation.Item.Rarity and payload.Chance == animation.Item.Chance)
			assert(payload.Probability == expected[payload.ItemId] and payload.LuckMultiplier == luck)
			assert(payload.LuckCapped == upgraded and payload.Cooldown == cooldown)
			assert(animation.Duration > 0 and animation.Duration < cooldown)
			assert(payload.ServiceCoins == toilets[p.ToiletTier].ServiceCoins * (if upgraded then 2 else 1))
			assert(p.Coins == coins + payload.ServiceCoins and p.Stats.Earned == p.Coins)
			assert(p.Inventory.Poop == lastId and p.Collection.Poop == lastId)
			e.World.Flush(player, not automatic)
			assert(p.Stats.Flushes == lastId and #animations == lastId, "Manual/auto overlap awarded twice")
		end
	end
	e:Fire("Sell", player, "Poop", p.Inventory.Poop)
	assert(p.Inventory.Poop == lastId, "Upgrade cash bypassed first-copy protection")
	e:Fire("Sell", player, "Poop", p.Inventory.Poop - 1)
	assert(p.Inventory.Poop == 1 and p.Collection.Poop == lastId, "Sale erased lifetime index progress")
end)

test("upgrades: remote fuzz, server price and token bucket", function()
	local e = server()
	local player, p = e:Join(70)
	p.Coins = 9e15
	for _, args in ipairs({
		{},
		{ "CashBoost" },
		{ "CashBoost", 0, 0 },
		{ {}, 0 },
		{ "Unknown", 0 },
		{ "CashBoost", 0 / 0 },
		{ "CashBoost", math.huge },
		{ "CashBoost", -1 },
		{ "CashBoost", 0.5 },
		{ "CashBoost", "0" },
	}) do
		e.Now += 2
		e:Fire("BuyUpgrade", player, table.unpack(args))
		assert(p.Coins == 9e15 and p.Upgrades.CashBoost == 0)
	end
	e.Now += 2
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local debit = 0
	for i = 1, 100 do
		local level = p.Upgrades.CashBoost
		if i <= 3 then
			debit += u:Price("CashBoost", level)
		end
		e:Fire("BuyUpgrade", player, "CashBoost", level)
	end
	assert(p.Upgrades.CashBoost == 3 and p.Coins == 9e15 - debit)
	assert(e.Store.Records.Player_70.Data.Upgrades.CashBoost == 3)
end)

test("upgrades: delayed save and duplicate purchase cannot double debit or level", function()
	local e = server()
	local player, p = e:Join(71)
	p.Coins = 1000
	e.Store.Before = function()
		coroutine.yield("purchase save held")
	end
	local buy = e:Spawn(function()
		e:Fire("BuyUpgrade", player, "CashBoost", 0)
	end)
	assert(p.Coins == 970 and p.Upgrades.CashBoost == 1)
	e:Fire("BuyUpgrade", player, "CashBoost", 0)
	assert(p.Coins == 970 and p.Upgrades.CashBoost == 1)
	local second = e:Spawn(function()
		e:Fire("BuyUpgrade", player, "CashBoost", 1)
	end)
	assert(p.Coins == 880 and p.Upgrades.CashBoost == 2)
	e.Store.Before = nil
	e:Resume(buy)
	assert(e.Store.Records.Player_71.Data.Coins == 970 and e.Store.Records.Player_71.Data.Upgrades.CashBoost == 1)
	e:Resume(second)
	assert(e.Store.Records.Player_71.Data.Coins == 880 and e.Store.Records.Player_71.Data.Upgrades.CashBoost == 2)
	e.Data:Close(player)
	local rejoined = e:Join(71)
	assert(e.Data:Get(rejoined).Coins == 880 and e.Data:Get(rejoined).Upgrades.CashBoost == 2)
end)

test("upgrades: committed response loss retries one immutable transaction", function()
	local e = server()
	local player, p = e:Join(72)
	p.Coins = 1000
	e.Store.After = function()
		error("lost purchase response")
	end
	local buy = e:Spawn(function()
		e:Fire("BuyUpgrade", player, "FlushSpeed", 0)
	end)
	assert(e.Store.Records.Player_72.Data.Coins == 975 and p.Upgrades.FlushSpeed == 1)
	e:Fire("BuyUpgrade", player, "FlushSpeed", 0)
	e.Store.After = nil
	e:Resume(buy)
	assert(p.Coins == 975 and e.Store.Records.Player_72.Data.Upgrades.FlushSpeed == 1)
end)

test("upgrades: expired lease and foreign takeover reject purchases and save success", function()
	local e = server()
	local player, p = e:Join(73)
	p.Coins = 1000
	e.Store.Before = function()
		coroutine.yield("held")
	end
	local buy = e:Spawn(function()
		e:Fire("BuyUpgrade", player, "CashBoost", 0)
	end)
	e.Now += 181
	e.Store.Records.Player_73 = { Data = { Coins = 123 }, Lock = { Session = "foreign", Expires = e.Now + 180 } }
	e:Fire("BuyUpgrade", player, "CashBoost", 1)
	assert(p.Coins == 970 and p.Upgrades.CashBoost == 1)
	e.Store.Before = nil
	e:Resume(buy)
	assert(e.Store.Records.Player_73.Data.Coins == 123)
	for _, result in ipairs(e.Results) do
		assert(not (result.Payload[1] == "BuyUpgrade" and result.Payload[2].Success), "Announced an unowned purchase")
	end
end)

test("upgrades: migration sanitizes new fields and preserves legacy displays through save", function()
	local e = environment()
	local data, player = e:Load(dataPath), e:Player(74)
	e.Store.Records.Player_74 = {
		Data = {
			DisplaySlots = 100,
			Upgrades = {
				CashBoost = 999,
				LuckBoost = 0 / 0,
				FlushSpeed = -1,
				AutoFlushSpeed = 1.5,
				DisplaySlots = 2,
				OfflineTank = 10,
				Unknown = 10,
			},
			Income = { UpdatedAt = e.Now, Pending = { ["1"] = 134400 * 6000 } },
		},
	}
	data:Load(player)
	local p = data:Get(player)
	assert(
		p.DisplaySlots == 100
			and p.Upgrades.CashBoost == 10
			and p.Upgrades.OfflineTank == 10
			and p.Upgrades.Unknown == nil
	)
	assert(p.Upgrades.LuckBoost == 0 and p.Upgrades.FlushSpeed == 0 and p.Upgrades.AutoFlushSpeed == 0)
	assert(p.Income.Pending["1"] == 134400 * 6000)
	data:Close(player)
	local second = e:Player(74)
	data:Load(second)
	assert(data:Get(second).DisplaySlots == 100 and data:Get(second).Income.Pending["1"] == 134400 * 6000)
end)

test("upgrades: cash settles past income before changing rates; index and slots stay bounded", function()
	local e = server()
	local player, p = e:Join(75)
	p.Coins = 1000
	p.Inventory.Poop = 10
	e:Fire("Display", player, "Poop", 1)
	e.Now += 60
	e:Fire("BuyUpgrade", player, "CashBoost", 0)
	local before = p.Income.Pending["1"]
	assert(before == 120, "Past income used new boost")
	e.Now += 60
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == before + 120, "Fixed-point income must round fractional units down")
	p.Upgrades.CashBoost = 10
	e.Now += 60
	e:Fire("State", player)
	assert(p.Income.Pending["1"] == before + 120 + 240)
	e:Fire("Sell", player, "Poop", 1)
	assert(p.Coins == 974 and p.Inventory.Poop == 9)
	p.DisplaySlots = 9
	e:Fire("BuyUpgrade", player, "DisplaySlots", 0)
	assert(p.DisplaySlots == 10)
	e:Fire("BuyUpgrade", player, "DisplaySlots", 1)
	assert(p.DisplaySlots == 10 and p.Upgrades.DisplaySlots == 1)
	local index = e:Load("src/shared/IndexProgress")
		.new(e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/IndexRewards"))
	for _, item in ipairs(e:Load("src/shared/Config/Items")) do
		p.Collection[item.Id] = 1
	end
	assert(index:Claim(p, "total:5").Success and p.DisplaySlots == 10)
	assert(not index:Claim(p, "total:5").Success)
end)

test("upgrades: 0.4s shared cooldown admits legitimate requests and rejects bursts", function()
	local e = server()
	local player, p = e:Join(76)
	p.ToiletTier = 7
	p.Upgrades.FlushSpeed, p.Upgrades.AutoFlushSpeed, p.Upgrades.LuckBoost = 10, 10, 10
	p.RewardLuckExpires = e.Now + 60
	p.Stats.Flushes = 100
	e:Fire("AutoFlush", player, true)
	for _ = 1, 20 do
		e:Fire("Flush", player)
		e.World.Flush(player, true)
		e.Now += 0.401
	end
	assert(p.Stats.Flushes == 120 and p.Inventory.Poop == 20)
	for _ = 1, 100 do
		e:Fire("Flush", player)
	end
	assert(p.Stats.Flushes == 121)
	for _, result in ipairs(e.Results) do
		if result.Payload[1] == "Flush" then
			assert(
				result.Payload[2].Cooldown == 0.4
					and result.Payload[2].LuckMultiplier == 5
					and result.Payload[2].LuckCapped
			)
		end
	end
	local state
	for _, result in ipairs(e.Results) do
		if type(result.Payload[1]) == "table" and result.Payload[1].UpgradeStats then
			state = result.Payload[1]
		end
	end
	-- The existing State wire exposes both levels and derived server stats.
	assert(state and state.Upgrades.FlushSpeed == 10 and state.UpgradeStats.LuckCapped)
end)

test("upgrades: all auto levels use slower intervals than the shared cooldown and never catch up", function()
	local e = server()
	local player, p = e:Join(77)
	p.Stats.Flushes = 100
	e:Fire("AutoFlush", player, true)
	e.World.Flush(player, true)
	e.Now += 1.51
	e.World.Flush(player, true)
	assert(p.Stats.Flushes == 101)
	e:Fire("Flush", player)
	assert(p.Stats.Flushes == 102, "Auto delay leaked into manual cooldown")
	e.Now += 10
	e:Resume(e.Threads[1])
	assert(p.Stats.Flushes == 103, "Auto scheduler issued catch-up rolls")
end)

test("upgrades: numeric ceilings reject the entire flush before currency or inventory changes", function()
	for _, field in ipairs({ "Coins", "Earned", "Flushes", "Inventory", "Collection" }) do
		local e = server()
		local player, p = e:Join(78)
		if field == "Coins" then
			p.Coins = 9e15
		elseif field == "Earned" or field == "Flushes" then
			p.Stats[field] = 9e15
		else
			p[field].Poop = 9e15
		end
		local before = copy(p)
		e:Fire("Flush", player)
		assert(
			p.Coins == before.Coins
				and p.Stats.Earned == before.Stats.Earned
				and p.Stats.Flushes == before.Stats.Flushes
				and p.Inventory.Poop == before.Inventory.Poop
				and p.Collection.Poop == before.Collection.Poop
		)
	end
end)

test("upgrades: display purchases and index claims commute and survive migration", function()
	for _, indexFirst in ipairs({ true, false }) do
		local e = server()
		local player, p = e:Join(79)
		p.Coins = 1000
		for _, item in ipairs(e:Load("src/shared/Config/Items")) do
			p.Collection[item.Id] = 1
		end
		if indexFirst then
			e:Fire("ClaimIndexReward", player, "total:5")
		end
		e:Fire("BuyUpgrade", player, "DisplaySlots", 0)
		if not indexFirst then
			e:Fire("ClaimIndexReward", player, "total:5")
		end
		assert(p.DisplaySlots == 5 and p.Upgrades.DisplaySlots == 1 and p.Coins == 900)
		e:Fire("ClaimIndexReward", player, "total:5")
		assert(p.DisplaySlots == 5)
		e.Data:Close(player)
		local second = e:Join(79)
		assert(e.Data:Get(second).DisplaySlots == 5 and e.Data:Get(second).Upgrades.DisplaySlots == 1)
	end
end)

test("upgrades: maximum offline tank survives ambiguous load and cannot be reclaimed", function()
	local e = server()
	local player, p = e:Join(80)
	p.ToiletTier = 7
	p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 10, 10
	p.Inventory.Mystery = 3
	for slot = 1, 3 do
		p.Displays[tostring(slot)] = "Mystery"
	end
	e.Data:Close(player)
	e.Now += 86400 * 30
	local second = e:Player(80)
	e.Store.After = function()
		error("offline acquisition response lost")
	end
	local load = e:Spawn(function()
		e.Data:Load(second)
	end)
	e.Store.After = nil
	e:Resume(load)
	local income = e:Load("src/shared/IncomeAccrual").new(
		e:Load("src/shared/Config/Income"),
		e:Load("src/shared/Config/Items"),
		e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	)
	local restored = e.Data:Get(second)
	assert(income:PendingCoins(restored) == 403200 and restored.Upgrades.OfflineTank == 10)
	e.Data:Close(second)
	local third = e:Player(80)
	e.Data:Load(third)
	assert(income:PendingCoins(e.Data:Get(third)) == 403200, "Reconnect repeated maximum tank")
end)
