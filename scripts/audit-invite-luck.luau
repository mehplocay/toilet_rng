test(
	"invite luck: free factor stacks with every tier, VIP, double luck and reviewed charge; odds equal rolls",
	function()
		local e, player, p, service, lucky = luckPlayer(1900)
		local u = service.Commerce.Income.Upgrades
		local toilets, items = e:Load("src/shared/Config/Toilets"), e:Load("src/shared/Config/Items")
		local roll = e:Load("src/server/Services/RollService")
		p.Social.InviteExpires = e.Now + 1800
		e.PolicyLookup = function()
			error("Roll must use cached policy")
		end
		for _, owned in ipairs({ {}, { VIPPack = true }, { DoubleLuck = true }, { VIPPack = true, DoubleLuck = true } }) do
			service.Owned[player] = owned
			for tier = 1, #toilets do
				p.ToiletTier, p.RebirthLevel, p.Upgrades.LuckBoost = tier, 15, 50
				lucky.Events.Multiplier = function()
					return 2
				end
				lucky.Rewards.Luck = function()
					return 2
				end
				local expected = toilets[tier].Luck
					* (1 + u:Effect(p, "LuckBoost") + u:RebirthBonus(p, "Luck"))
					* 2
					* 2
					* 1.2
					* (if owned.VIPPack then 1.25 else 1)
					* (if owned.DoubleLuck then 2 else 1)
				local odds = lucky:Odds(p, player)
				assert(math.abs(odds.BaseLuck - expected) < 1e-10 and math.abs(odds.Luck - expected * 10) < 1e-9)
				assert(odds.InviteLuck == 1.2 and odds.InviteRemaining == 1800)
				local normal, charged =
					roll.Distribution(items, toilets, tier, expected),
					roll.Distribution(items, toilets, tier, expected * 10)
				for i, row in ipairs(odds.Items) do
					assert(
						math.abs(row.Normal - normal[i].Probability) < 1e-12
							and math.abs(row.Boosted - charged[i].Probability) < 1e-12
					)
				end
				for key, preview in pairs(lucky:Snapshot(player, p).PassOdds) do
					local dist = roll.Distribution(items, toilets, tier, lucky:BaseLuck(p, player, key))
					for i, row in ipairs(preview.Items) do
						assert(row.Boosted == dist[i].Probability)
					end
				end
			end
		end
		assert(lucky:Odds(p, player).Luck > 1000)
		local original, used = roll.Roll, nil
		roll.Roll = function(a, b, c, d, luck)
			used = luck
			return original(a, b, c, d, luck)
		end
		p.Monetization.LuckyFlushes = 1
		local odds = lucky:Odds(p, player)
		e:Fire("LuckyFlush", player, odds.Token)
		e:Fire("Flush", player)
		assert(used == odds.Luck and e.Data:Get(player).Monetization.LuckyFlushes == 0)
	end
)

test("invite luck: restricted, failed, absent and expired paid policy leave free invite luck active", function()
	for index, mode in ipairs({ "restricted", "failed", "absent", "expired" }) do
		local e, player, p, service, lucky = luckPlayer(1910 + index)
		service.Owned[player] = { VIPPack = true, DoubleLuck = true }
		p.Social.InviteExpires = e.Now + 1800
		if mode == "absent" then
			lucky.Policies[player] = nil
		elseif mode == "expired" then
			lucky.Policies[player].Expires = e.Now - 1
		else
			e.PolicyLookup = function()
				if mode == "failed" then
					error("outage")
				end
				return { ArePaidRandomItemsRestricted = true }
			end
			lucky:Refresh(player)
		end
		e.PolicyLookup = function()
			error("No roll lookup")
		end
		assert(service:Luck(player) == 1 and lucky:BaseLuck(p, player) == 1.2)
		assert(lucky:Snapshot(player, p).FreeLuck == 1.2 and not lucky:Snapshot(player, p).Allowed)
		local roll, used = e:Load("src/server/Services/RollService"), nil
		local original = roll.Roll
		roll.Roll = function(a, b, c, d, luck)
			used = luck
			return original(a, b, c, d, luck)
		end
		e:Fire("Flush", player)
		assert(used == 1.2 and p.Stats.Flushes == 1)
	end
end)

test("invite luck: exact mid-session expiry invalidates review without consuming charges", function()
	local e, player, p, _, lucky = luckPlayer(1920)
	p.Social.InviteExpires, p.Monetization.LuckyFlushes = e.Now + 3, 1
	local old = lucky:Odds(p, player)
	e:Fire("LuckyFlush", player, old.Token)
	e.Now += 3
	local fresh = lucky:Odds(p, player)
	assert(fresh.BaseLuck == 1 and fresh.InviteLuck == 1 and fresh.Token ~= old.Token)
	assert(not lucky:Snapshot(player, p).Armed)
	e:Fire("Flush", player)
	assert(p.Stats.Flushes == 0 and p.Monetization.LuckyFlushes == 1)
	e.Now += 3
	e:Fire("LuckyFlush", player, fresh.Token)
	e:Fire("Flush", player)
	assert(e.Data:Get(player).Monetization.LuckyFlushes == 0)
end)

test("invite luck: coin grants, sales, quotes and online/offline display accrual ignore invite expiry", function()
	local e, player, p, service = luckPlayer(1921)
	local income, u = service.Commerce.Income, service.Commerce.Income.Upgrades
	p.Displays, p.DisplaySlots = { ["1"] = "Poop" }, 1
	p.SocialRuntime = { GroupMember = true, FriendCount = 3 }
	local cash = u:Cash(p)
	local baseQuotes = service.Commerce:Snapshot(p, player).Quotes
	for _, expires in ipairs({ 0, e.Now + 50, e.Now + 1800 }) do
		p.Social.InviteExpires = expires
		assert(u:Cash(p) == cash and math.abs(cash - 1.265) < 1e-12)
		local quotes = service.Commerce:Snapshot(p, player).Quotes
		for key, value in pairs(baseQuotes) do
			assert(quotes[key] == value)
		end
		for _, offline in ipairs({ false, true }) do
			local copy = e:Load("src/shared/CommerceProfile").Copy(p)
			copy.Income = { UpdatedAt = e.Now, Pending = {} }
			local baseline = e:Load("src/shared/CommerceProfile").Copy(copy)
			baseline.Social.InviteExpires = 0
			income:Settle(copy, e.Now + 100, offline)
			income:Settle(baseline, e.Now + 100, offline)
			assert(copy.Income.Pending["1"] == baseline.Income.Pending["1"])
		end
	end
	p.Social.InviteExpires = e.Now + 1800
	local before = p.Coins
	e:Fire("Flush", player)
	local grant = p.Coins - before
	e.Now += 3
	p.Social.InviteExpires = 0
	before = p.Coins
	e:Fire("Flush", player)
	assert(p.Coins - before == grant)
	p.Inventory.Poop = 3
	before = p.Coins
	e:Fire("Sell", player, "Poop", 1)
	local sale = p.Coins - before
	e.Now += 3
	p.Social.InviteExpires = e.Now + 1800
	before = p.Coins
	e:Fire("Sell", player, "Poop", 1)
	assert(sale > 0 and p.Coins - before == sale)
end)

test("invite luck: existing v1 timer migrates and reloads without minting rewards or coins", function()
	local e, player, p = catalogPlayer(1922)
	local service = e:Load("src/server/Services/MonetizationService")
	p.Social = {
		Version = 1,
		InviteExpires = e.Now + 100,
		Day = math.floor(e.Now / 86400),
		DailyCount = 1,
		Rewarded = { 999 },
		HistoryFull = false,
	}
	local beforeCoins, beforeCharges = p.Coins, p.Monetization.LuckyFlushes
	assert(e.Data:Save(player, false))
	e.Players.PlayerRemoving:Fire(player)
	player.Parent = nil
	e.Now += 50
	player, p = e:Join(1922)
	assert(p.Social.InviteExpires == e.Now + 50 and p.Social.DailyCount == 1 and #p.Social.Rewarded == 1)
	assert(p.Coins == beforeCoins and p.Monetization.LuckyFlushes == beforeCharges)
	assert(service.Commerce.Income.Upgrades:Luck(p, 1) == 1.2)
	e.Now += 50
	assert(service.Commerce.Income.Upgrades:Luck(p, 1) == 1)
	assert(p.Social.DailyCount == 1 and p.Social.Rewarded[1] == 999)
end)

test("invite luck: ordinary flush checks exact expiry without waiting for social tick", function()
	local e, player, p, _, lucky = luckPlayer(1923)
	p.Social.InviteExpires = e.Now + 3
	local roll, used = e:Load("src/server/Services/RollService"), {}
	local original = roll.Roll
	roll.Roll = function(a, b, c, d, luck)
		table.insert(used, luck)
		return original(a, b, c, d, luck)
	end
	e.PolicyLookup = function()
		error("No platform lookup on flush")
	end
	e:Fire("Flush", player)
	e.Now += 3
	e:Fire("Flush", player)
	assert(used[1] == 1.2 and used[2] == 1 and p.Stats.Flushes == 2)
end)
