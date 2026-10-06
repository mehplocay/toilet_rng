-- Extended catalog exercises actual handlers and persistence, with all IDs mocked locally.
for index, key in ipairs({
	"Coins10Minutes",
	"Coins1Hour",
	"Coins6Hours",
	"PathBoost10Minutes",
	"Coins24Hours",
	"LuckyFlush1",
	"LuckyFlush5",
	"LuckyFlush20",
}) do
	test("extended product replay, double grant and rejoin: " .. key, function()
		local e, player, p, commerce, config = catalogPlayer(600 + index)
		local product = config.DeveloperProducts[key]
		local info = receipt(player, "extended-" .. key, product.Id)
		local quote = commerce.Receipts:Quote(p, key)
		assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
		p = e.Data:Get(player)
		assert(p.Coins == (if product.IncomeSeconds then quote else 0))
		assert(p.Monetization.LuckyFlushes == (product.LuckyCharges or 0))
		assert(p.Monetization.PathExpires == (if product.Duration then e.Now + product.Duration else 0))
		for _ = 1, 5 do
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
		end
		assert(#p.Monetization.Receipts == 1)
		e.Data:Close(player)
		player.Parent = nil
		e.Players.PlayerRemoving:Fire(player)
		local joined, restored = e:Join(600 + index)
		assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
		assert(
			restored.Coins == p.Coins
				and restored.Monetization.LuckyFlushes == p.Monetization.LuckyFlushes
				and restored.Monetization.PathExpires == p.Monetization.PathExpires
		)
		assert(e.Marketplace.ProcessReceipt(receipt(joined, "second-" .. key, product.Id)) == "PurchaseGranted")
		local twice = e.Data:Get(joined)
		assert(twice.Coins == p.Coins * 2 and twice.Monetization.LuckyFlushes == p.Monetization.LuckyFlushes * 2)
	end)
	for _, committed in ipairs({ false, true }) do
		test("extended product interrupted save/rejoin: " .. key .. " committed=" .. tostring(committed), function()
			local e, player, _, commerce, config = catalogPlayer(620 + index)
			local product = config.DeveloperProducts[key]
			local info = receipt(player, "interrupted-" .. key, product.Id)
			local field = if committed then "After" else "Before"
			e.Store[field] = function()
				error("backend failure")
			end
			local decision
			local thread = e:Spawn(function()
				decision = e.Marketplace.ProcessReceipt(info)
			end)
			while coroutine.status(thread) ~= "dead" do
				e:Resume(thread)
			end
			assert(decision == "NotProcessedYet" and not e.Data:Get(player))
			player.Parent = nil
			e.Now += 181
			e.Store[field] = nil
			local joined = e:Join(620 + index)
			assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
			local result = e.Data:Get(joined)
			assert(#result.Monetization.Receipts == 1)
			assert(result.Monetization.LuckyFlushes == (product.LuckyCharges or 0))
			assert(result.Coins == (if product.IncomeSeconds then 100 else 0))
			assert(
				result.Monetization.PathExpires
					== (if product.Duration then (if committed then e.Now - 181 else e.Now) + 600 else 0)
			)
		end)
	end
end
test("extended policy: restricted, error, missing flag, stale cache and leave fail closed", function()
	for _, mode in ipairs({ "restricted", "error", "missing", "expired" }) do
		local e, player, p, commerce, config = catalogPlayer(650)
		local lucky = e:Load("src/server/Services/LuckyService")
		local product = config.DeveloperProducts.LuckyFlush5
		if mode == "error" then
			e.PolicyError = true
		elseif mode == "missing" then
			e.PolicyLookup = function()
				return {}
			end
		elseif mode == "restricted" then
			e.PolicyLookup = function()
				return { ArePaidRandomItemsRestricted = true }
			end
		end
		lucky:Refresh(player)
		if mode == "expired" then
			e.Now += config.PolicySeconds
		end
		assert(not lucky:Allowed(player) and not lucky:Snapshot(player, p).Odds)
		e:Fire("BuyProduct", player, "LuckyFlush5", 0, "forged")
		assert(not e.Marketplace.LastProduct)
		assert(e.Marketplace.ProcessReceipt(receipt(player, "restricted", product.Id)) == "NotProcessedYet")
		assert(p.Monetization.LuckyFlushes == 0)
		p.Monetization.LuckyFlushes = 1
		e:Fire("LuckyFlush", player, "forged")
		e:Fire("Flush", player)
		assert(
			p.Monetization.LuckyFlushes == 1 and p.Stats.Flushes == 1,
			"Restricted player lost a charge or could not free-flush"
		)
		player.Parent = nil
		e.Players.PlayerRemoving:Fire(player)
		assert(lucky.Policies[player] == nil and lucky.Armed[player] == nil and lucky.Loading[player] == nil)
	end
end)
test("extended policy: delayed lookup after departure cannot reinsert eligibility", function()
	local e, player = catalogPlayer(651)
	local lucky = e:Load("src/server/Services/LuckyService")
	e.PolicyLookup = function()
		coroutine.yield("policy")
		return { ArePaidRandomItemsRestricted = false }
	end
	local thread = e:Spawn(function()
		lucky:Refresh(player)
	end)
	player.Parent = nil
	e.Players.PlayerRemoving:Fire(player)
	e:Resume(thread)
	assert(not lucky.Policies[player] and not lucky.Loading[player])
end)
test("extended odds: every tier and multiplier matches roll entries and exact rarity sums", function()
	local e, player, p = catalogPlayer(652)
	local lucky = e:Load("src/server/Services/LuckyService")
	local roll = e:Load("src/server/Services/RollService")
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	for tier = 1, #toilets do
		for _, level in ipairs({ 0, 10, 50 }) do
			p.ToiletTier, p.Upgrades.LuckBoost = tier, level
			local odds = lucky:Odds(p)
			assert(odds.Luck == 10 and odds.BaseLuck <= 10)
			local boosted = roll.Distribution(items, toilets, tier, odds.Luck)
			local normal = roll.Distribution(items, toilets, tier, odds.BaseLuck)
			local sums = { Normal = 0, Boosted = 0 }
			for i, row in ipairs(odds.Items) do
				assert(
					row.Id == normal[i].Item.Id
						and row.Normal == normal[i].Probability
						and row.Boosted == boosted[i].Probability
				)
				sums.Normal += row.Normal
				sums.Boosted += row.Boosted
			end
			assert(math.abs(sums.Normal - 1) < 1e-12 and math.abs(sums.Boosted - 1) < 1e-12)
			local rsum = 0
			for rarity, r in pairs(odds.Rarities) do
				local n, b = 0, 0
				for _, row in ipairs(odds.Items) do
					if row.Rarity == rarity then
						n += row.Normal
						b += row.Boosted
					end
				end
				assert(r.Normal == n and r.Boosted == b)
				rsum += b
			end
			assert(math.abs(rsum - 1) < 1e-12)
			for _, entry in ipairs(boosted) do
				local check = if entry.Item.Id == "Poop" then 1 else math.min(1, 10 / entry.Item.Chance)
				assert(math.abs(entry.Check - check) < 1e-14)
			end
		end
	end
end)
test("extended Lucky use: review, stale odds, malformed request, atomic award and rejoin", function()
	local e, player, p, _, config = catalogPlayer(653)
	assert(
		e.Marketplace.ProcessReceipt(receipt(player, "lucky-use", config.DeveloperProducts.LuckyFlush5.Id))
			== "PurchaseGranted"
	)
	p = e.Data:Get(player)
	local lucky = e:Load("src/server/Services/LuckyService")
	e:Fire("Flush", player)
	assert(p.Stats.Flushes == 0 and p.Monetization.LuckyFlushes == 5)
	local token = lucky:Odds(p).Token
	e:Fire("LuckyFlush", player, token, true)
	assert(not lucky.Armed[player])
	e:Fire("LuckyFlush", player, token)
	p.ToiletTier = 2
	e.Now += 5
	e:Fire("Flush", player)
	assert(p.Stats.Flushes == 0)
	e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
	e.Store.Before = function()
		coroutine.yield("use save")
	end
	local thread = e:Spawn(function()
		e:Fire("Flush", player)
	end)
	assert(not e.Data:Get(player))
	e:Fire("Flush", player)
	e:Fire("Rebirth", player, 0)
	e.Store.Before = nil
	e:Resume(thread)
	p = e.Data:Get(player)
	assert(p.Stats.Flushes == 1 and p.Monetization.LuckyFlushes == 4)
	assert(e.Store.Records.Player_653.Data.Monetization.LuckyFlushes == 4)
	local found = 0
	for _, count in pairs(p.Inventory) do
		found += count
	end
	assert(found == 1)
	e.Data:Close(player)
	player.Parent = nil
	e.Players.PlayerRemoving:Fire(player)
	local joined, restored = e:Join(653)
	assert(restored.Monetization.LuckyFlushes == 4 and restored.Stats.Flushes == 1 and not lucky.Armed[joined])
	assert(
		e.Marketplace.ProcessReceipt(receipt(joined, "lucky-use", config.DeveloperProducts.LuckyFlush5.Id))
			== "PurchaseGranted"
	)
	assert(restored.Monetization.LuckyFlushes == 4, "Receipt replay refilled spent charges")
end)
for _, committed in ipairs({ false, true }) do
	test("extended Lucky use save failure is all-or-nothing: " .. tostring(committed), function()
		local e, player, p, _, config = catalogPlayer(654)
		local lucky = e:Load("src/server/Services/LuckyService")
		assert(
			e.Marketplace.ProcessReceipt(receipt(player, "use-failure", config.DeveloperProducts.LuckyFlush1.Id))
				== "PurchaseGranted"
		)
		p = e.Data:Get(player)
		e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
		local field = if committed then "After" else "Before"
		e.Store[field] = function()
			error("outage")
		end
		local thread = e:Spawn(function()
			e:Fire("Flush", player)
		end)
		while coroutine.status(thread) ~= "dead" do
			e:Resume(thread)
		end
		assert(not e.Data:Get(player))
		player.Parent = nil
		e.Now += 181
		e.Store[field] = nil
		local _, restored = e:Join(654)
		assert(restored.Monetization.LuckyFlushes == (if committed then 0 else 1))
		assert(restored.Stats.Flushes == (if committed then 1 else 0))
	end)
end
test("extended counters: sanitize, capacity, id-zero and admin preservation", function()
	local e, player, p, _, config = catalogPlayer(655)
	local sanitizer = e:Load("src/shared/CommerceProfile")
	for _, bad in ipairs({ -1, 1.5, 0 / 0, math.huge, "20", config.LuckyFlushCap + 1 }) do
		assert(sanitizer.Sanitize({ LuckyFlushes = bad }).LuckyFlushes == 0)
	end
	p.Monetization.LuckyFlushes = config.LuckyFlushCap
	local info = receipt(player, "full-lucky", config.DeveloperProducts.LuckyFlush20.Id)
	assert(e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
	assert(#p.Monetization.Receipts == 0 and p.Monetization.LuckyFlushes == config.LuckyFlushCap)
	local replacement = e:Load("src/server/Admin/Mutations").Build(e.Data, p, "Reset", {}, e.Now)
	assert(replacement.Monetization.LuckyFlushes == config.LuckyFlushCap)
	assert(
		e:Load("src/server/Admin/Runtime").new(e.Data, {}, {}, {}):Snapshot(player, p).LuckyFlushes
			== config.LuckyFlushCap
	)
	for _, key in ipairs(config.ProductOrder) do
		config.DeveloperProducts[key].Id = 0
		e.Now += 11
		e:Fire("BuyProduct", player, key, 0)
	end
	assert(not e.Marketplace.LastProduct)
end)
test("extended bundle: implies all 15 passes, no consumables, slots applied once and persists", function()
	local e, player, p, commerce, config = catalogPlayer(656)
	local service = e:Load("src/server/Services/MonetizationService")
	service.Cosmetics = nil
	config.Gamepasses.UltimateBundle.Id = 8656
	e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 8656, true)
	local effective = service:EffectiveOwned(player)
	for _, key in ipairs(config.PassOrder) do
		assert(effective[key] == true)
	end
	assert(p.DisplaySlots == 8 and p.Monetization.AppliedSlots == 5 and p.Monetization.LuckyFlushes == 0)
	assert(commerce.Income.Upgrades:Cash(p) == 3)
	assert(commerce.Income.Upgrades:OfflineMinutes(p, 480) == 1440)
	for _ = 1, 10 do
		commerce:Apply(player, service.Owned[player])
	end
	assert(p.DisplaySlots == 8)
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(656)
	assert(restored.DisplaySlots == 8 and restored.Monetization.Passes.UltimateBundle)
	e:Fire("BuyPass", joined, "VIPStar")
	assert(not e.Marketplace.LastPrompt)
end)
test("extended VIP pad: ownership, health, finite distance, cooldown/rejoin and ledger caps", function()
	local e, player, p, commerce, config = catalogPlayer(657)
	local pad = e:Load("src/server/Services/VIPPadService")
	e:Load("src/server/Services/MonetizationService").Cosmetics = nil
	assert(not pad.Claim(commerce, player))
	config.Gamepasses.VIPPack.Id = 8657
	p.Monetization.Passes.VIPPack = true
	for _, distance in ipairs({ 9, math.huge, 0 / 0 }) do
		player.Distance = distance
		assert(not pad.Claim(commerce, player))
	end
	player.Distance = 0
	player.Health = 0
	assert(not pad.Claim(commerce, player))
	player.Health = 100
	assert(pad.Claim(commerce, player))
	p = e.Data:Get(player)
	assert(p.Coins == config.VIPPad.Min and not pad.Claim(commerce, player))
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(657)
	assert(not pad.Claim(commerce, joined) and restored.Coins == config.VIPPad.Min)
	e.Now += config.VIPPad.Cooldown
	-- Refresh lease before testing the next claim; ordinary autosave renews it in production.
	e.Data:Close(joined)
	joined.Parent = nil
	joined, restored = e:Join(657)
	restored.Coins = 9e15
	assert(not pad.Claim(commerce, joined) and restored.Monetization.VIPPadAt == p.Monetization.VIPPadAt)
end)

for index, key in ipairs({
	"Coins10Minutes",
	"Coins1Hour",
	"Coins6Hours",
	"PathBoost10Minutes",
	"Coins24Hours",
	"LuckyFlush1",
	"LuckyFlush5",
	"LuckyFlush20",
}) do
	test("extended receipt departure during durable grant: " .. key, function()
		local e, player, _, _, config = catalogPlayer(680 + index)
		local info = receipt(player, "departure-" .. key, config.DeveloperProducts[key].Id)
		e.Store.Before = function()
			coroutine.yield("departing grant")
		end
		local decision
		local thread = e:Spawn(function()
			decision = e.Marketplace.ProcessReceipt(info)
		end)
		assert(not e.Data:Get(player) and e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
		player.Parent = nil
		local closing = e:Spawn(function()
			e.Data:Close(player)
		end)
		e.Store.Before = nil
		e:Resume(thread)
		e:Resume(closing)
		assert(decision == "NotProcessedYet")
		e.Players.PlayerRemoving:Fire(player)
		local _, restored = e:Join(680 + index)
		assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
		assert(
			#restored.Monetization.Receipts == 1
				and restored.Monetization.LuckyFlushes == (config.DeveloperProducts[key].LuckyCharges or 0)
		)
	end)
end
test("extended policy changes across prompt-save and receipt-archive yields reject without grant", function()
	local e, player, p, _, config = catalogPlayer(690)
	local lucky = e:Load("src/server/Services/LuckyService")
	e.Store.Before = function()
		coroutine.yield("quote")
	end
	local thread = e:Spawn(function()
		e:Fire("BuyProduct", player, "LuckyFlush1", 0, lucky:Odds(p).Token)
	end)
	e.PolicyError = true
	lucky:Refresh(player)
	e.Store.Before = nil
	e:Resume(thread)
	assert(not e.Marketplace.LastProduct and not e.Data:Get(player).Monetization.Quote)
	e.PolicyError = false
	lucky:Refresh(player)
	e.Archive.Before = function()
		coroutine.yield("archive")
	end
	local decision
	thread = e:Spawn(function()
		decision =
			e.Marketplace.ProcessReceipt(receipt(player, "policy-yield", config.DeveloperProducts.LuckyFlush1.Id))
	end)
	e.PolicyError = true
	lucky:Refresh(player)
	e.Archive.Before = nil
	e:Resume(thread)
	assert(decision == "NotProcessedYet" and e.Data:Get(player).Monetization.LuckyFlushes == 0)
end)
test("extended paid auto save cannot block other players or spawn another save for its owner", function()
	local e, player, _, _, config = catalogPlayer(691)
	assert(
		e.Marketplace.ProcessReceipt(receipt(player, "auto-charge", config.DeveloperProducts.LuckyFlush1.Id))
			== "PurchaseGranted"
	)
	local p = e.Data:Get(player)
	local other, free = e:Join(692)
	p.Stats.Flushes, free.Stats.Flushes = 100, 100
	e:Fire("AutoFlush", player, true)
	e:Fire("AutoFlush", other, true)
	local lucky = e:Load("src/server/Services/LuckyService")
	e:Fire("LuckyFlush", player, lucky:Odds(p).Token)
	local held
	e.Store.Before = function(key)
		if key == "Player_691" then
			held = coroutine.running()
			coroutine.yield("paid auto")
		end
	end
	e:Resume(e.Threads[1])
	assert(held and not e.Data:Get(player) and free.Stats.Flushes == 101)
	local writes = e.Store.Writes
	e.Now += 4
	e:Resume(e.Threads[1])
	assert(e.Store.Writes == writes and free.Stats.Flushes == 102)
	e.Store.Before = nil
	e:Resume(held)
	assert(e.Data:Get(player).Monetization.LuckyFlushes == 0 and e.Data:Get(player).Stats.Flushes == 101)
end)

test("extended early Lucky receipt waits for join-time policy eligibility", function()
	local e = server()
	local config = e:Load("src/shared/Config/Monetization")
	config.DeveloperProducts.LuckyFlush1.Id = 8693
	e.PolicyLookup = function()
		coroutine.yield("join policy")
		return { ArePaidRandomItemsRestricted = false }
	end
	local loading = e:Spawn(function()
		e:Join(693)
	end)
	local player = e.Players:GetPlayerByUserId(693)
	local decision
	local waiting = e:Spawn(function()
		decision = e.Marketplace.ProcessReceipt(receipt(player, "early-policy", 8693))
	end)
	assert(decision == nil and e.Data:Get(player).Monetization.LuckyFlushes == 0)
	e:Resume(loading)
	e:Resume(waiting)
	assert(decision == "PurchaseGranted" and e.Data:Get(player).Monetization.LuckyFlushes == 1)
end)
