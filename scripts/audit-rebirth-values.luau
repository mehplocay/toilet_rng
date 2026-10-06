-- Additional production-module scenarios; all earlier audit cases still execute.
test("merged rebirth/catalog: bundle and overlapping VIP grant only the free R10 capacity exactly once", function()
	for _, bundle in ipairs({ false, true }) do
		local e, player, p, commerce, config = catalogPlayer(if bundle then 727 else 726)
		local service = e:Load("src/server/Services/MonetizationService")
		-- Geometry is covered by audit-cosmetic-merge; this fixture exercises server entitlements and saves.
		service.Cosmetics = nil
		local owned = if bundle then { UltimateBundle = true, VIPPack = true } else { VIPPack = true }
		for key in pairs(owned) do
			config.Gamepasses[key].Id = 8800 + table.find(config.PassOrder, key)
		end
		service.Owned[player] = owned
		commerce:Apply(player, owned)
		assert(p.DisplaySlots == 3)
		local rebirth = e:Load("src/shared/Config/Rebirth")
		p.RebirthLevel, p.RunFlushes, p.Coins = 9, rebirth.RequiredFlushes, rebirth.Levels[10].RequiredCoins
		p.Inventory.Rat, p.Displays["3"] = 1, "Rat"
		e:Fire("Rebirth", player, 9)
		p = e.Data:Get(player)
		assert(p.RebirthLevel == 10 and p.DisplaySlots == 5 and p.RebirthAppliedSlots == 2)
		for _ = 1, 10 do
			commerce:Apply(player, owned)
		end
		assert(p.DisplaySlots == 5 and p.Displays["3"] == "Rat")
		e.Data:Close(player)
		player.Parent = nil
		local _, restored = e:Join(player.UserId)
		assert(restored.DisplaySlots == 5 and restored.RebirthAppliedSlots == 2 and restored.Displays["3"] == "Rat")
	end
end)

test("rebirth rewards: exact targets, all rows, lookup and existing-level migration", function()
	local e = server()
	local config = e:Load("src/shared/Config/Rebirth")
	local rules = e:Load("src/shared/RebirthRules").new(config)
	local targets =
		{ [1] = { 0.5, 0.05, 0.03 }, [5] = { 3, 0.25, 0.10 }, [10] = { 8, 0.60, 0.25 }, [15] = { 15, 1, 0.50 } }
	assert(#config.Levels == 15)
	for level = 0, 15 do
		local raw = e.Data.DefaultProfile()
		raw.RebirthLevel, raw.Coins, raw.ToiletTier = level, 123, 7
		raw.Upgrades.CashBoost = 50
		local p = e.Data.Sanitize(raw)
		local bonus = rules:Bonus(p)
		assert(p.RebirthLevel == level and p.Coins == 123 and p.ToiletTier == 7 and p.Upgrades.CashBoost == 50)
		if level > 0 then
			assert(bonus == config.Levels[level])
		end
		if targets[level] then
			local expected = targets[level]
			assert(bonus.Cash == expected[1] and bonus.Luck == expected[2] and bonus.Speed == expected[3])
		end
		for _ = 1, 4 do
			p = e.Data.Sanitize(p)
		end
		assert(p.RebirthLevel == level and p.Coins == 123)
	end
	for level = 2, 14, 2 do
		local found = false
		for _, cosmetic in ipairs(config.Cosmetics) do
			found = found or cosmetic.Level == level
		end
		assert(found, "Missing even-level visible perk")
	end
end)

test("rebirth rewards: R10 slots apply once at migration and preserve occupied and legacy capacity", function()
	local e = server()
	for _, capacity in ipairs({ 3, 8, 9, 10, 100 }) do
		local raw = e.Data.DefaultProfile()
		raw.RebirthLevel, raw.DisplaySlots = 10, capacity
		raw.Inventory.Poop, raw.Displays[tostring(capacity)] = 1, "Poop"
		local p = e.Data.Sanitize(raw)
		local expected = math.max(capacity, math.min(10, capacity + 2))
		assert(p.DisplaySlots == expected and p.RebirthAppliedSlots == 2)
		for _ = 1, 10 do
			p = e.Data.Sanitize(p)
		end
		assert(p.DisplaySlots == expected and p.Displays[tostring(capacity)] == "Poop")
	end
end)

test("rebirth rewards: free Auto Collect has the same living-owner, save and ledger guards", function()
	local e, player, p, commerce = catalogPlayer(720)
	local position = { X = 0, Y = 3, Z = 0 }
	e.World.Assigned[player].LayoutCFrame = {
		PointToObjectSpace = function()
			return position
		end,
	}
	p.RebirthLevel = 4
	p.Income.Pending = { ["1"] = 60001 }
	commerce:Collect(player)
	assert(p.Coins == 0)
	p.RebirthLevel = 5
	commerce:Collect(player)
	assert(p.Coins == 10 and p.Income.Pending["1"] == 1 and not p.Monetization.Passes.AutoCollect)
	p.Income.Pending["1"] += 30000
	for _, invalid in ipairs({ { X = 25, Y = 3, Z = 0 }, { X = 0 / 0, Y = 3, Z = 0 }, { X = 0, Y = 30, Z = 0 } }) do
		position = invalid
		commerce:Collect(player)
		assert(p.Coins == 10)
	end
	position = { X = 0, Y = 3, Z = 0 }
	player.Health = 0
	commerce:Collect(player)
	assert(p.Coins == 10)
	player.Health = 100
	e.Data.Saving[player] = true
	commerce:Collect(player)
	assert(p.Coins == 10)
	e.Data.Saving[player] = nil
	e:Fire("CollectIncome", player)
	commerce:Collect(player)
	assert(p.Coins == 15 and p.Income.Pending["1"] == 1)
	e.Data:Close(player)
	local _, q = e:Join(720)
	assert(q.RebirthLevel == 5 and q.Coins == 15 and not q.Monetization.Passes.AutoCollect)
end)

test("rebirth rewards: R10 response loss, reset replay and rejoin grant only two slots", function()
	local e = server()
	local player, p = rebirthReady(e, 721)
	local config = e:Load("src/shared/Config/Rebirth")
	p.RebirthLevel, p.Coins, p.DisplaySlots = 9, config.Levels[10].RequiredCoins, 3
	p.Upgrades.DisplaySlots = 0
	e.Store.After = function()
		error("committed R10 response lost")
	end
	local reset = e:Spawn(function()
		e:Fire("Rebirth", player, 9)
	end)
	local replacement = e.Data.Profiles[player]
	assert(replacement.RebirthLevel == 10 and replacement.DisplaySlots == 5 and replacement.RebirthAppliedSlots == 2)
	e:Fire("Rebirth", player, 9)
	e.Store.After = nil
	e:Resume(reset)
	e.Data:Close(player)
	local joined, q = e:Join(721)
	assert(q.RebirthLevel == 10 and q.DisplaySlots == 5 and q.RebirthAppliedSlots == 2)
	e:Fire("Rebirth", joined, 9)
	assert(e.Data:Get(joined).DisplaySlots == 5)
end)

test("rebirth rewards: additive upgrades, toilet multiplication, paid cap, luck cap and speed floor", function()
	local e = server()
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local config = e:Load("src/shared/Config/Rebirth")
	for level = 0, 15 do
		for cash = 0, 100 do
			for _, passes in ipairs({
				{},
				{ DoubleCash = true },
				{ VIPPack = true },
				{ DoubleCash = true, VIPPack = true },
			}) do
				local p = {
					RebirthLevel = level,
					Upgrades = { CashBoost = cash, FlushSpeed = 10, LuckBoost = 50 },
					Monetization = { Passes = passes },
				}
				local base = 1
					+ math.min(cash, 10) * 0.1
					+ math.max(0, cash - 10) * 0.025
					+ (if level == 0 then 0 else config.Levels[level].Cash)
				local factor = (if passes.DoubleCash then 2 else 1) * (if passes.VIPPack then 1.5 else 1)
				assert(math.abs(u:Cash(p) - math.min(40, base) * factor) < 1e-10)
				assert(u:Luck(p, 1.3, 2, 2, 1e300) == 10 and u:Cooldown(p, 1.8 * 0.8) >= 0.4)
			end
		end
	end
end)

test("rebirth rewards: R15 with both cash passes stays inside exact ledger and wallet ceilings", function()
	local e, player, p, commerce, config = catalogPlayer(722)
	config.Gamepasses.DoubleCash.Id, config.Gamepasses.VIPPack.Id = 8801, 8802
	p.Monetization.Passes = { DoubleCash = true, VIPPack = true }
	p.RebirthLevel, p.ToiletTier, p.DisplaySlots = 15, 7, 100
	p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 100, 100
	for slot = 1, 100 do
		p.Displays[tostring(slot)] = "Mystery"
	end
	p.Inventory.Mystery = 100
	p.Income.UpdatedAt = 1
	commerce.Income:Settle(p, 9e12, false)
	assert(commerce.Income:TotalUnits(p) == 9e15)
	for _, rate in pairs(commerce.Income:Rates(p)) do
		assert(rate % 1 == 0 and rate < 9e15)
	end
	p.Coins, p.Stats.Earned = 9e15 - 7, 9e15 - 5
	assert(commerce.Income:Collect(p) == 5)
	assert(p.Coins == 9e15 - 2 and p.Stats.Earned == 9e15 and commerce.Income:TotalUnits(p) == 9e15 - 30000)
	assert(commerce.Income:Collect(p) == 0)
	local q = e.Data.Sanitize(p)
	assert(q.Coins == p.Coins and q.Stats.Earned == p.Stats.Earned and q.RebirthLevel == 15)
	assert(commerce.Income:TotalUnits(q) == commerce.Income:TotalUnits(p))
end)

test("rebirth rewards: configured chat tag composes with VIP and preserves filtered prefix", function()
	local e = environment()
	local player = e:Player(725)
	local configuration = {
		DeriveNewMessageProperties = function()
			return {}
		end,
	}
	local chat = {
		FindFirstChildOfClass = function()
			return configuration
		end,
	}
	e.Services.TextChatService = chat
	e:Load("src/client/VIPChat").Start()
	local message = { TextSource = { UserId = 725 }, PrefixText = "FilteredName:" }
	assert(chat.OnChatWindowAdded(message) == nil)
	player:SetAttribute("RebirthChatLevel", 8)
	local free = chat.OnChatWindowAdded(message).PrefixText
	assert(free:find("Bowl Champion", 1, true) and free:sub(-13) == "FilteredName:")
	player:SetAttribute("VIPStar", true)
	player:SetAttribute("VIPPack", true)
	local both = chat.OnChatWindowAdded(message).PrefixText
	assert(
		both:find("Bowl Champion", 1, true) and both:find(e:Load("src/shared/Config/Monetization").VIPLabel, 1, true)
	)
	player:SetAttribute("RebirthChatLevel", "<font>spoof</font>")
	assert(not chat.OnChatWindowAdded(message).PrefixText:find("spoof", 1, true))
	player:SetAttribute("VIPStar", false)
	assert(chat.OnChatWindowAdded(message) == nil)
	assert(chat.OnChatWindowAdded({ PrefixText = "system" }) == nil)
end)
