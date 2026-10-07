-- Real service calls; policy and ownership API answers are the only doubles.
local function luckPlayer(id)
	local e, player, p, commerce, config = catalogPlayer(id)
	local service = e:Load("src/server/Services/MonetizationService")
	service.Cosmetics = nil
	e.Marketplace.PromptGamePassPurchase = function(_, who, id)
		e.Marketplace.LastPrompt = { Player = who, Id = id }
	end
	config.Gamepasses.VIPPack.Id = 18001
	config.Gamepasses.DoubleLuck.Id = 18002
	config.Gamepasses.UltimateBundle.Id = 18003
	return e, player, p, service, service.Lucky, config
end

test(
	"paid luck: verified cache, restricted, failed, missing and expired fail closed without losing VIP perks",
	function()
		local e, player, p, service, lucky = luckPlayer(1800)
		service.Owned[player] = { VIPPack = true, DoubleLuck = true }
		service:Apply(player)
		assert(service:Luck(player) == 2.5)
		service.Owned[player].DoubleLuck = false
		assert(service:Luck(player) == 1.25)
		local writes = e.Store.Writes
		e.PolicyLookup = function()
			error("Roll path must not yield or query policy")
		end
		assert(lucky:BaseLuck(p, player) == 1.25 and e.Store.Writes == writes)
		for _, mode in ipairs({ "restricted", "failed", "missing field", "missing cache", "expired" }) do
			if mode == "missing cache" then
				lucky.Policies[player] = nil
			elseif mode == "expired" then
				lucky.Policies[player] = { Allowed = true, Expires = e.Now - 1 }
			else
				e.PolicyLookup = function()
					if mode == "failed" then
						error("outage")
					end
					return if mode == "restricted" then { ArePaidRandomItemsRestricted = true } else {}
				end
				lucky:Refresh(player)
			end
			assert(service:Luck(player) == 1 and lucky:BaseLuck(p, player) == 1, mode)
			assert(service.Commerce.Income.Upgrades:Cash(p) == 1.5)
			assert(service:EffectiveOwned(player).VIPPack)
		end
	end
)

test("paid luck: bundle, zero ID, owner test unlocks and no persistent luck fields", function()
	local e, player, p, service, lucky, config = luckPlayer(1801)
	service.Owned[player] = { UltimateBundle = true }
	assert(service:Luck(player) == 2.5)
	config.Gamepasses.DoubleLuck.Id = 0
	assert(service:Luck(player) == 1.25 and not service:EffectiveOwned(player).DoubleLuck)
	e:Fire("BuyPass", player, "DoubleLuck")
	e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 0, true)
	assert(not e.Marketplace.LastPrompt and not service.Owned[player].DoubleLuck)
	service.Owned[player] = {}
	local unlocks = e:Load("src/server/Admin/TestUnlocks").new(e:Load("src/shared/Config/Admin"), config, function()
		return e.Now
	end)
	service.AdminTestOwnership = function(who, real)
		return unlocks:Owned(who, real)
	end
	unlocks:Set(player, true)
	assert(service:Luck(player) == 1.25)
	config.Gamepasses.DoubleLuck.Id = 18002
	assert(service:Luck(player) == 2.5)
	lucky.Policies[player] = nil
	assert(service:Luck(player) == 1, "Owner cannot bypass policy")
	for _, owned in pairs(p.Monetization.Passes) do
		assert(owned ~= true, "Admin entitlement persisted")
	end
	assert(p.VipLuckBonus == nil and p.DoubleLuck == nil)
	local clean = e.Data.Sanitize(p)
	assert(clean.VipLuckBonus == nil and clean.DoubleLuck == nil and clean.UpgradeVersion == p.UpgradeVersion)
end)

test("paid luck: every tier, free level, pass stack and charge disclose exactly the roll distribution", function()
	local e, player, p, service, lucky = luckPlayer(1802)
	local toilets, items = e:Load("src/shared/Config/Toilets"), e:Load("src/shared/Config/Items")
	local roll = e:Load("src/server/Services/RollService")
	local upgrades = service.Commerce.Income.Upgrades
	for _, owned in ipairs({
		{},
		{ VIPPack = true },
		{ DoubleLuck = true },
		{ VIPPack = true, DoubleLuck = true },
		{ UltimateBundle = true },
	}) do
		service.Owned[player] = owned
		for tier = 1, #toilets do
			for _, level in ipairs({ 0, 10, 25, 50 }) do
				p.ToiletTier, p.Upgrades.LuckBoost = tier, level
				local factor = (if owned.VIPPack or owned.UltimateBundle then 1.25 else 1)
					* (if owned.DoubleLuck or owned.UltimateBundle then 2 else 1)
				local expected = math.min(10, toilets[tier].Luck * (1 + upgrades:Effect(p, "LuckBoost")) * factor)
				local odds = lucky:Odds(p, player)
				assert(math.abs(odds.BaseLuck - expected) < 1e-12 and odds.Luck == 10)
				local normal = roll.Distribution(items, toilets, tier, expected)
				local boosted = roll.Distribution(items, toilets, tier, 10)
				for i, row in ipairs(odds.Items) do
					assert(
						math.abs(row.Normal - normal[i].Probability) < 1e-12 and row.Boosted == boosted[i].Probability
					)
				end
				for key, preview in pairs(lucky:Snapshot(player, p).PassOdds) do
					local post = lucky:BaseLuck(p, player, key)
					local distribution = roll.Distribution(items, toilets, tier, post)
					for i, row in ipairs(preview.Items) do
						assert(row.Boosted == distribution[i].Probability)
					end
				end
			end
		end
	end
	p.ToiletTier, p.Upgrades.LuckBoost = 1, 0
	p.Monetization.LuckyFlushes = 1
	e:Fire("LuckyFlush", player, lucky:Odds(p, player).Token)
	e:Fire("Flush", player)
	assert(e.Data:Get(player).Monetization.LuckyFlushes == 0)
end)

test("paid luck: purchase review token, policy after yielding refresh, expiry and ID zero", function()
	local e, player, p, service, lucky, config = luckPlayer(1803)
	e:Fire("BuyPass", player, "VIPPack")
	assert(not e.Marketplace.LastPrompt)
	e.Now += 5
	local token = lucky:Odds(p, player, "VIPPack").Token
	e:Fire("BuyPass", player, "VIPPack", token)
	assert(e.Marketplace.LastPrompt.Id == 18001)
	service.Pending[player] = nil
	e.Marketplace.LastPrompt = nil
	e.Now += 5
	e.PolicyLookup = function()
		return { ArePaidRandomItemsRestricted = true }
	end
	e:Fire("BuyPass", player, "DoubleLuck", lucky:Odds(p, player, "DoubleLuck").Token)
	assert(not e.Marketplace.LastPrompt and service:Luck(player) == 1)
	config.Gamepasses.DoubleLuck.Id = 0
	assert(
		not e:Load("src/shared/PaidBenefits")
			.Owns({ OwnedPasses = { UltimateBundle = true, DoubleLuck = true } }, "DoubleLuck")
	)
end)

test("paid luck: creator ownership API grants released passes but never bypasses policy", function()
	local e, player, _, service, lucky = luckPlayer(1804)
	e.Marketplace.Lookup = function()
		return true
	end
	assert(service:Load(player) and service:Luck(player) == 2.5)
	local queries = 0
	e.PolicyLookup = function()
		queries += 1
		return { ArePaidRandomItemsRestricted = true }
	end
	assert(service:Load(player) and queries == 1 and service:Luck(player) == 1)
	assert(service:EffectiveOwned(player).VIPPack and service:EffectiveOwned(player).DoubleLuck)
	lucky.Policies[player] = nil
	assert(service:Luck(player) == 1)
end)

test("paid luck: gaining VIP invalidates an armed charge and allows reviewing the new odds", function()
	local e, player, p, service, lucky = luckPlayer(1805)
	p.Monetization.LuckyFlushes = 1
	e:Fire("LuckyFlush", player, lucky:Odds(p, player).Token)
	assert(lucky:Snapshot(player, p).Armed)
	service.Owned[player] = { VIPPack = true }
	assert(not lucky:Snapshot(player, p).Armed)
	e.Now += 5
	e:Fire("LuckyFlush", player, lucky:Odds(p, player).Token)
	assert(lucky:Snapshot(player, p).Armed and lucky:Snapshot(player, p).Odds.BaseLuck == 1.25)
end)
