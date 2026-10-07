test("uncapped luck: full free/paid/temporary products, extreme disclosure and policy expiry", function()
	local e, player, p, service, lucky = luckPlayer(1850)
	local u = service.Commerce.Income.Upgrades
	service.Owned[player] = { VIPPack = true, DoubleLuck = true }
	p.ToiletTier, p.RebirthLevel, p.Upgrades.LuckBoost = 15, 15, 50
	lucky.Events.Multiplier = function()
		return 2
	end
	lucky.Rewards.Luck = function()
		return 2
	end
	local odds = lucky:Odds(p, player)
	assert(math.abs(odds.BaseLuck - 133.4) < 1e-10 and math.abs(odds.Luck - 1334) < 1e-10)
	assert(u.Config.LuckCap == nil and u.Config.Rebirth.LuckBonusCap == nil)
	-- Future configured bonuses are honored, even beyond the previous per-source ceiling.
	u.Config.Rebirth.Levels[15].Luck = 20
	assert(u:Luck(p, 1) == 23.6)
	u.Config.Rebirth.Levels[15].Luck = 1
	p.ToiletTier, p.RebirthLevel, p.Upgrades.LuckBoost = 1, 0, 0
	lucky.Rewards.Luck = function()
		return 1
	end
	for _, target in ipairs({ 1e3, 1e6, 1e12 }) do
		lucky.Events.Multiplier = function()
			return target / 2.5
		end
		odds = lucky:Odds(p, player)
		assert(odds.BaseLuck == target and odds.Luck == target * 10)
		assert(#odds.Token <= 100)
		local sums = { Normal = 0, Boosted = 0 }
		for _, row in ipairs(odds.Items) do
			for key in pairs(sums) do
				assert(row[key] >= 0 and row[key] <= 1)
				sums[key] += row[key]
			end
		end
		assert(math.abs(sums.Normal - 1) < 1e-12 and math.abs(sums.Boosted - 1) < 1e-12)
	end
	p.Monetization.LuckyFlushes = 1
	e:Fire("LuckyFlush", player, odds.Token)
	e:Fire("Flush", player)
	p = e.Data:Get(player)
	assert(p.Stats.Flushes == 1 and p.Inventory.CosmicCourtesy == 1 and p.Monetization.LuckyFlushes == 0)
	lucky.Policies[player] = { Allowed = true, Expires = e.Now - 1 }
	assert(service:Luck(player) == 1)
	local snapshot = lucky:Snapshot(player, p)
	assert(not snapshot.Allowed and snapshot.Odds == nil and next(snapshot.PassOdds) == nil)
	assert(snapshot.FreeLuck == 1e12 / 2.5)
end)

test("uncapped luck: reject NaN/infinity and true overflow, preserve finite huge multipliers", function()
	local e = server()
	local u = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local p = e.Data.DefaultProfile()
	for _, value in ipairs({ 1e3, 1e6, 1e12, 1e300, 1e308 }) do
		assert(u:Luck(p, 1, value) == value)
	end
	for _, value in ipairs({ 0 / 0, math.huge, -math.huge, -1, "10", {} }) do
		assert(not pcall(u.Luck, u, p, 1, value))
		assert(not pcall(u.Luck, u, p, value))
	end
	assert(not pcall(u.Luck, u, p, 1, 1e308, 10))
	local _, player, profile, _, lucky = luckPlayer(1851)
	lucky.Events.Multiplier = function()
		return 1e308
	end
	assert(not pcall(lucky.Odds, lucky, profile, player), "Overflow must never enter disclosure or the roll")
	assert(profile.Stats.Flushes == 0 and profile.Monetization.LuckyFlushes == 0)
end)

test("uncapped luck: saved progression recomputes luck and discards stale capped snapshots on rejoin", function()
	local e, player, p = catalogPlayer(1852)
	local service = e:Load("src/server/Services/MonetizationService")
	local lucky = service.Lucky
	p.ToiletTier, p.RebirthLevel, p.Upgrades.LuckBoost = 15, 15, 50
	p.Monetization.LuckyFlushes = 20
	p.LuckCap, p.LuckCapped, p.LuckMultiplier = 10, true, 10
	p.UpgradeStats = { LuckCap = 10, LuckCapped = true, LuckMultiplier = 10 }
	p.Monetization.Passes = { VIPPack = true, DoubleLuck = true }
	local clean = e.Data.Sanitize(p)
	assert(clean.LuckCap == nil and clean.LuckCapped == nil and clean.UpgradeStats == nil)
	assert(clean.Upgrades.LuckBoost == 50 and clean.RebirthLevel == 15 and clean.UpgradeVersion == 2)
	assert(clean.Monetization.LuckyFlushes == 20)
	local u = service.Commerce.Income.Upgrades
	assert(math.abs(u:Luck(clean, 2.9) - 13.34) < 1e-12)
	e.Data:Close(player)
	player.Parent = nil
	e.Players.PlayerRemoving:Fire(player)
	local joined, restored = e:Join(1852)
	assert(restored.ToiletTier == 15 and restored.Upgrades.LuckBoost == 50 and restored.RebirthLevel == 15)
	assert(restored.Monetization.LuckyFlushes == 20 and not lucky.Armed[joined])
	assert(math.abs(u:Luck(restored, 2.9) - 13.34) < 1e-12)
	-- Legacy pre-version saves retain the existing content-level migration, never free purchases.
	local legacy = e.Data.DefaultProfile()
	legacy.UpgradeVersion, legacy.Upgrades.LuckBoost = nil, 999
	assert(e.Data.Sanitize(legacy).Upgrades.LuckBoost == 10)
end)
