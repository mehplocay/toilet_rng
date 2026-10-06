-- Real persistence and remote regression scenarios for the permanent economy.
test("permanent: old caps migrate once without coins, levels or slots being minted", function()
	local e = server()
	local raw = e.Data.DefaultProfile()
	raw.UpgradeVersion = nil
	raw.Upgrades =
		{ CashBoost = 999, LuckBoost = 999, OfflineTank = 999, DisplaySlots = 999, FlushSpeed = 999, Unknown = 99 }
	raw.Coins, raw.DisplaySlots = 12345, 10
	local p = e.Data.Sanitize(raw)
	assert(p.UpgradeVersion == 2 and p.Upgrades.CashBoost == 10 and p.Upgrades.LuckBoost == 10)
	assert(p.Upgrades.OfflineTank == 10 and p.Upgrades.DisplaySlots == 7 and p.Upgrades.Unknown == nil)
	assert(p.Coins == 12345 and p.DisplaySlots == 10)
	for _ = 1, 10 do
		p = e.Data.Sanitize(p)
	end
	assert(p.Upgrades.CashBoost == 10 and p.Coins == 12345 and p.DisplaySlots == 10)
end)

test("permanent: extended caps and malformed numbers round-trip without inflation", function()
	local e = server()
	local player, p = e:Join(601)
	p.Upgrades.CashBoost, p.Upgrades.OfflineTank, p.Upgrades.LuckBoost = 100, 100, 50
	p.Coins = 100
	e.Data:Close(player)
	local _, q = e:Join(601)
	assert(q.Upgrades.CashBoost == 100 and q.Upgrades.OfflineTank == 100 and q.Upgrades.LuckBoost == 50)
	assert(q.Coins == 100 and q.UpgradeVersion == 2)
	for _, bad in ipairs({ -1, 0.5, 0 / 0, math.huge, "100", {} }) do
		q.Upgrades.CashBoost = bad
		assert(e.Data.Sanitize(q).Upgrades.CashBoost == 0)
	end
	q.Upgrades.CashBoost = 1000
	assert(e.Data.Sanitize(q).Upgrades.CashBoost == 100)
end)

test("permanent: rebirth retains all permanent state and only displayed inventory copies", function()
	local e = server()
	local player, before = rebirthReady(e, 602)
	before.ToiletTier = 7
	before.Upgrades.CashBoost, before.Upgrades.OfflineTank, before.Upgrades.LuckBoost = 85, 60, 43
	before.DisplaySlots = 10
	before.Inventory.Fish, before.ProtectedInventory.Fish = 9, 9
	before.Collection.Fish = 9
	before.Income.UpdatedAt = e.Now - 10
	before.Settings.SkipAnimation = true
	e:Fire("Rebirth", player, 0)
	local p = e.Data:Get(player)
	assert(p ~= before and p.ToiletTier == 7 and p.DisplaySlots == 10)
	assert(p.Upgrades.CashBoost == 85 and p.Upgrades.OfflineTank == 60 and p.Upgrades.LuckBoost == 43)
	assert(p.Inventory.Fish == nil and p.ProtectedInventory.Fish == nil and p.Collection.Fish == 9)
	assert(p.Inventory.Rat == 2 and p.Inventory.Poop == 1 and p.Settings.SkipAnimation)
	assert(before.Income.Pending["1"] > 600000 and next(p.Income.Pending) == nil)
	assert(p.Coins == 2500 and p.RunFlushes == 0)
	e.Data:Close(player)
	local _, q = e:Join(602)
	assert(q.ToiletTier == 7 and q.Upgrades.CashBoost == 85 and q.DisplaySlots == 10)
	assert(q.Inventory.Fish == 0 and q.Collection.Fish == 9 and q.Inventory.Rat == 2)
end)

test("permanent: every coin gate rejects one coin short, pending income and stale generations", function()
	local e = server()
	local rules = e:Load("src/shared/RebirthRules").new(e:Load("src/shared/Config/Rebirth"))
	local config = e:Load("src/shared/Config/Rebirth")
	local p = e.Data.DefaultProfile()
	local previous = 0
	for level, reward in ipairs(config.Levels) do
		assert(reward.RequiredCoins > previous and reward.RequiredCoins < 9e15)
		previous = reward.RequiredCoins
		p.RebirthLevel, p.RunFlushes = level - 1, config.RequiredFlushes
		p.Coins = reward.RequiredCoins - 1
		p.Income.Pending["1"] = 9e15
		assert(not rules:Build(p, level - 1, e.Now))
		p.Coins += 1
		p.RunFlushes -= 1
		assert(not rules:Build(p, level - 1, e.Now))
		p.RunFlushes += 1
		local q = assert(rules:Build(p, level - 1, e.Now))
		assert(q.Coins == reward.StarterCoins and q.RebirthLevel == level and q.RunFlushes == 0)
		assert(not rules:Build(q, level - 1, e.Now))
	end
end)

test("permanent: spending gate coins before rebirth prevents reset; collection races serialize", function()
	local e = server()
	local player, p = rebirthReady(e, 603)
	e:Fire("BuyUpgrade", player, "CashBoost", 5)
	e:Fire("Rebirth", player, 0)
	assert(e.Data:Get(player) == p and p.RebirthLevel == 0)
	p.Coins = e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins
	e.Now += 6
	e.Store.Before = function()
		coroutine.yield("reset held")
	end
	local reset = e:Spawn(function()
		e:Fire("Rebirth", player, 0)
	end)
	local replacement = e.Data.Profiles[player]
	e:Fire("CollectIncome", player)
	e:Fire("BuyUpgrade", player, "CashBoost", 6)
	assert(replacement.Coins == 2500 and replacement.Upgrades.CashBoost == 6)
	e.Store.Before = nil
	e:Resume(reset)
	assert(e.Data:Get(player) == replacement and rebirthSuccesses(e) == 1)
end)

test("permanent: new cost boundaries, milestone titles and caps cannot be replayed", function()
	local e = server()
	local config = e:Load("src/shared/Config/Upgrades")
	local u = e:Load("src/shared/UpgradeRules").new(config)
	for _, track in ipairs(config.Tracks) do
		for level = 0, track.MaxLevel - 1 do
			local p = e.Data.DefaultProfile()
			p.Upgrades[track.Id] = level
			local price = u:Price(track.Id, level)
			p.Coins = price - 1
			assert(not u:Buy(p, track.Id, level))
			p.Coins = price
			assert(u:Buy(p, track.Id, level) and p.Coins == 0)
			assert(not u:Buy(p, track.Id, level))
			if level + 1 == track.MaxLevel then
				local title, nextLevel = u:Milestone(p, track.Id)
				assert(title == track.Name .. " Master" and nextLevel == nil)
			elseif (level + 1) % 10 == 0 then
				local title, nextLevel = u:Milestone(p, track.Id)
				assert(title == track.Name .. " " .. config.MilestoneTitles[(level + 1) / 10] and nextLevel > level + 1)
			end
		end
	end
end)

test("permanent: full luck applies to every rarity under the 10x cap", function()
	local e = server()
	local roll = e:Load("src/server/Services/RollService")
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local late = { RebirthLevel = 15, Upgrades = { LuckBoost = 50, CashBoost = 100, OfflineTank = 100 } }
	assert(math.abs(u:Luck(late, 1.3) - 5.98) < 1e-12)
	assert(math.abs(u:Cash(late) - 19.25) < 1e-12 and u:OfflineMinutes(late, 480) == 1440)
	for _, luck in ipairs({ 1, 5, 10, 1000000 }) do
		local entries, empty = roll.Distribution(items, toilets, 7, luck)
		local total = 0
		for _, entry in ipairs(entries) do
			local effective = math.min(luck, 10)
			assert(entry.Check == (if entry.Item.Id == "Poop" then 1 else math.min(1, effective / entry.Item.Chance)))
			total += entry.Probability
		end
		assert(empty == 0 and math.abs(total - 1) < 1e-12)
		assert(roll.Sample(entries, 0) and roll.Sample(entries, 0.99999999))
	end
end)

test("permanent: level 100 purchase survives committed response loss and rejects both replay generations", function()
	local e = server()
	local player, p = e:Join(604)
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	p.Upgrades.CashBoost, p.Coins = 99, u:Price("CashBoost", 99) + 123
	e.Store.After = function()
		error("lost response after level 100 commit")
	end
	local purchase = e:Spawn(function()
		e:Fire("BuyUpgrade", player, "CashBoost", 99)
	end)
	assert(p.Upgrades.CashBoost == 100 and p.Coins == 123)
	e:Fire("BuyUpgrade", player, "CashBoost", 99)
	e:Fire("BuyUpgrade", player, "CashBoost", 100)
	e.Store.After = nil
	e:Resume(purchase)
	e.Data:Close(player)
	local joined, q = e:Join(604)
	assert(q.Upgrades.CashBoost == 100 and q.Coins == 123 and q.UpgradeVersion == 2)
	e:Fire("BuyUpgrade", joined, "CashBoost", 99)
	e:Fire("BuyUpgrade", joined, "CashBoost", 100)
	assert(q.Upgrades.CashBoost == 100 and q.Coins == 123)
end)
