local function catalogPlayer(id)
	local e = server()
	local config = e:Load("src/shared/Config/Monetization")
	for index, key in ipairs(config.ProductOrder) do
		config.DeveloperProducts[key].Id = 9000 + index
	end
	local player, profile = e:Join(id)
	local commerce = e:Load("src/server/Services/MonetizationService").Commerce
	return e, player, profile, commerce, config
end
local function receipt(player, id, product)
	return { PlayerId = player.UserId, ProductId = product or 9001, PurchaseId = id }
end
test("catalog receipts: malformed identity and saturated balances defer without partial grants", function()
	local e, player, p = catalogPlayer(420)
	for _, bad in ipairs({ false, "420", 0, -1, 0 / 0, math.huge, 1.5, {} }) do
		local info = receipt(player, "bad-player")
		info.PlayerId = bad
		assert(e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
	end
	assert(e.Marketplace.ProcessReceipt(nil) == "NotProcessedYet")
	assert(e.Marketplace.ProcessReceipt({ ProductId = 9001, PurchaseId = "missing-player" }) == "NotProcessedYet")
	p.Coins = 9e15
	assert(e.Marketplace.ProcessReceipt(receipt(player, "full-wallet")) == "NotProcessedYet")
	assert(p.Coins == 9e15 and p.Stats.Earned == 0 and #p.Monetization.Receipts == 0)
	p.Coins, p.Stats.Earned = 0, 9e15
	assert(e.Marketplace.ProcessReceipt(receipt(player, "full-earned")) == "NotProcessedYet")
	assert(p.Coins == 0 and #p.Monetization.Receipts == 0)
end)
test("catalog receipts: grant and PurchaseId save atomically; replay and rejoin never double grant", function()
	local e, player, _, commerce = catalogPlayer(401)
	local info = receipt(player, "purchase-1")
	assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
	local p = e.Data:Get(player)
	assert(p.Coins == 100 and p.Stats.Earned == 100 and #p.Monetization.Receipts == 1)
	assert(e.Store.Records.Player_401.Data.Coins == 100)
	for _ = 1, 30 do
		assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
	end
	assert(p.Coins == 100)
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(401)
	assert(restored.Coins == 100 and commerce.Receipts:Process(receipt(joined, "purchase-1")) == "PurchaseGranted")
	assert(restored.Coins == 100)
end)
test("catalog receipts: concurrent receipt, leaving during save and rejoin", function()
	local e, player = catalogPlayer(402)
	local info, decision = receipt(player, "yielded"), nil
	e.Store.Before = function()
		coroutine.yield("receipt save")
	end
	local grant = e:Spawn(function()
		decision = e.Marketplace.ProcessReceipt(info)
	end)
	assert(e.Data:Get(player) == nil and e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
	player.Parent = nil
	local closing = e:Spawn(function()
		e.Data:Close(player)
	end)
	e.Store.Before = nil
	e:Resume(grant)
	e:Resume(closing)
	assert(decision == "NotProcessedYet")
	local joined, p = e:Join(402)
	assert(e.Marketplace.ProcessReceipt(receipt(joined, "yielded")) == "PurchaseGranted" and p.Coins == 100)
end)
for _, committed in ipairs({ false, true }) do
	test("catalog receipts: exhausted save failure and rejoin, committed=" .. tostring(committed), function()
		local e, player = catalogPlayer(if committed then 403 else 404)
		local info, decision = receipt(player, "ambiguous"), nil
		local field = if committed then "After" else "Before"
		e.Store[field] = function()
			error("backend unavailable")
		end
		local grant = e:Spawn(function()
			decision = e.Marketplace.ProcessReceipt(info)
		end)
		while coroutine.status(grant) ~= "dead" do
			e:Resume(grant)
		end
		assert(decision == "NotProcessedYet" and not e.Data:Get(player))
		-- Simulate a crashed process without its final save, then lease expiry.
		player.Parent = nil
		e.Now += 181
		e.Store[field] = nil
		local joined, p = e:Join(player.UserId)
		assert(p.Coins == (if committed then 100 else 0))
		assert(e.Marketplace.ProcessReceipt(receipt(joined, "ambiguous")) == "PurchaseGranted")
		assert(e.Data:Get(joined).Coins == 100)
	end)
end
test("catalog receipts: response loss retries same grant and callback takeover fails closed", function()
	local e, player = catalogPlayer(405)
	local once = true
	e.Store.After = function()
		if once then
			once = false
			error("lost reply")
		end
	end
	local grant = e:Spawn(function()
		assert(e.Marketplace.ProcessReceipt(receipt(player, "retry")) == "PurchaseGranted")
	end)
	e:Resume(grant)
	assert(e.Data:Get(player).Coins == 100)
	e.Store.Replay = function(key)
		e.Store.Records[key] = { Data = { Coins = 777 }, Lock = { Session = "other", Expires = e.Now + 180 } }
	end
	assert(e.Marketplace.ProcessReceipt(receipt(player, "takeover")) == "NotProcessedYet")
	assert(e.Store.Records.Player_405.Data.Coins == 777)
end)
test("catalog receipts: bounded history archives before eviction; very old replay and archive failure", function()
	local e, player, _, _, config = catalogPlayer(406)
	config.ReceiptHistoryLimit = 2
	for i = 1, 3 do
		assert(e.Marketplace.ProcessReceipt(receipt(player, "old-" .. i)) == "PurchaseGranted")
	end
	local p = e.Data:Get(player)
	assert(#p.Monetization.Receipts == 2 and e.Archive.Records["old-1"].PlayerId == player.UserId)
	assert(e.Marketplace.ProcessReceipt(receipt(player, "old-1")) == "PurchaseGranted" and p.Coins == 300)
	e.Archive.Before = function(key)
		if key == "old-2" then
			error("archive write failed")
		end
	end
	assert(e.Marketplace.ProcessReceipt(receipt(player, "old-4")) == "NotProcessedYet" and p.Coins == 300)
	e.Archive.Before = nil
	assert(e.Marketplace.ProcessReceipt(receipt(player, "old-4")) == "PurchaseGranted")
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(406)
	assert(e.Marketplace.ProcessReceipt(receipt(joined, "old-1")) == "PurchaseGranted" and restored.Coins == 400)
end)
test("catalog receipts: disconnect during archive lookup, unknown/id-zero and nonpersistent profiles defer", function()
	local e, player, profile, _, config = catalogPlayer(407)
	e.Archive.Before = function()
		player.Parent = nil
	end
	assert(e.Marketplace.ProcessReceipt(receipt(player, "gone")) == "NotProcessedYet" and profile.Coins == 0)
	e.Archive.Before = nil
	player.Parent = e.Players
	config.DeveloperProducts.Coins10Minutes.Id = 0
	assert(e.Marketplace.ProcessReceipt(receipt(player, "zero", 0)) == "NotProcessedYet")
	assert(e.Marketplace.ProcessReceipt(receipt(player, "unknown", 98765)) == "NotProcessedYet")
	config.DeveloperProducts.Coins10Minutes.Id = 9001
	e.Data.NoPersistence[player] = true
	assert(e.Marketplace.ProcessReceipt(receipt(player, "studio")) == "NotProcessedYet" and profile.Coins == 0)
end)
test("catalog products: server quote survives rebirth and rejoin; client cannot supply coins", function()
	local e, player, p, commerce = catalogPlayer(408)
	p.Inventory.Rat, p.Displays["1"] = 1, "Rat"
	local amount = commerce.Receipts:Quote(p, "Coins6Hours")
	e:Fire("BuyProduct", player, "Coins6Hours", 9e15)
	assert(not e.Marketplace.LastProduct and not p.Monetization.Quote)
	e.Now += 11
	e:Fire("BuyProduct", player, "Coins6Hours", amount)
	assert(e.Marketplace.LastProduct.Id == 9003 and e.Store.Records.Player_408.Data.Monetization.Quote.Coins == amount)
	p = e.Data:Get(player)
	p.ToiletTier, p.RunFlushes = 4, e:Load("src/shared/Config/Rebirth").RequiredFlushes
	p.Coins = e:Load("src/shared/Config/Rebirth").Levels[1].RequiredCoins
	e:Fire("Rebirth", player, 0)
	assert(e.Data:Get(player).RebirthLevel == 1 and e.Data:Get(player).Monetization.Quote.Coins == amount)
	e.Data:Close(player)
	player.Parent = nil
	local joined, before = e:Join(408)
	local coins = before.Coins
	assert(e.Marketplace.ProcessReceipt(receipt(joined, "quoted", 9003)) == "PurchaseGranted")
	assert(e.Data:Get(joined).Coins == coins + amount and not e.Data:Get(joined).Monetization.Quote)
end)
test("catalog products: path timer extends once per receipt, persists, and zero-id prompts are inert", function()
	local e, player, _, _, config = catalogPlayer(409)
	local info = receipt(player, "speed", 9004)
	assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
	assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
	assert(e.Data:Get(player).Monetization.PathExpires == e.Now + 600)
	assert(e.Marketplace.ProcessReceipt(receipt(player, "speed-two", 9004)) == "PurchaseGranted")
	assert(e.Data:Get(player).Monetization.PathExpires == e.Now + 1200)
	config.DeveloperProducts.PathBoost10Minutes.Id = 0
	e:Fire("BuyProduct", player, "PathBoost10Minutes", 0)
	assert(not e.Marketplace.LastProduct)
end)
test("catalog entitlements: API refresh, callback replay and cached failure apply extra slots once", function()
	local e, player, p, commerce, config = catalogPlayer(410)
	config.Gamepasses.ExtraSlots.Id = 8001
	e.Marketplace.Lookup = function()
		return true
	end
	local service = e:Load("src/server/Services/MonetizationService")
	service:Load(player)
	assert(p.DisplaySlots == 6 and p.Monetization.Passes.ExtraSlots)
	for _ = 1, 10 do
		service:Load(player)
		e.Marketplace.PromptGamePassPurchaseFinished:Fire(player, 8001, true)
	end
	e.Marketplace.Lookup = function()
		error("ownership outage")
	end
	assert(not service:Load(player) and p.DisplaySlots == 6)
	p.Upgrades.DisplaySlots = 4
	p.DisplaySlots = 10
	commerce:Apply(player, service.Owned[player])
	assert(p.DisplaySlots == 10)
	e.Data:Close(player)
	player.Parent = nil
	local _, restored = e:Join(410)
	assert(restored.DisplaySlots == 10 and restored.Monetization.AppliedSlots == 3)
end)
test("catalog cash: sales, service, passive, daily and offline caps honor paid factors without luck", function()
	local e, player, p, _, config = catalogPlayer(411)
	local service = e:Load("src/server/Services/MonetizationService")
	for i, key in ipairs({ "DoubleCash", "VIPPack", "OfflinePlus" }) do
		config.Gamepasses[key].Id = 8000 + i
		service.Owned[player][key] = true
	end
	-- No visual double needed to test entitlement arithmetic.
	service.Commerce:Apply(player, service.Owned[player])
	local rules = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local paid = e:Load("src/shared/PaidBenefits")
	assert(rules:Cash(p) == 3 and service:Luck(player) == 1 and paid.Cash(p, 1e300) == config.CashMultiplierCap)
	p.RebirthLevel, p.Upgrades.CashBoost = 15, 10
	assert(math.abs(rules:Cash(p) - 10) < 1e-9)
	p.Inventory.Rat = 3
	local item
	for _, candidate in ipairs(e:Load("src/shared/Config/Items")) do
		if candidate.Id == "Rat" then
			item = candidate
		end
	end
	assert(e:Load("src/server/Services/EconomyService").Sell(p, "Rat", 1))
	assert(p.Coins == math.floor(item.Value * 10 + 1e-9))
	local serviceCoins = e:Load("src/server/Services/ServiceCoinService")
		.Grant(p, e:Load("src/shared/Config/Toilets")[1], rules:Cash(p))
	assert(serviceCoins > 0)
	local daily = e:Load("src/server/Services/RewardService")
		.new(e:Load("src/shared/Config/Rewards"), e:Load("src/shared/RewardSchedule"), function()
			return e.Now
		end)
	local base = daily.Schedule.Coins(1, p.ToiletTier, daily.Config)
	assert(daily:Claim(p).Coins == math.floor(base * 3))
	local income = service.Commerce.Income
	p.Displays["1"] = "Rat"
	local rate = income:Rates(p)["1"]
	p.Monetization.Passes.DoubleCash, p.Monetization.Passes.VIPPack = false, false
	assert(math.abs(rate / income:Rates(p)["1"] - 1) < 0.01)
	local baseMinutes = rules:OfflineMinutes(p, income.Config.OfflineMinutes)
	p.Monetization.Passes.OfflinePlus = false
	assert(baseMinutes == 2 * rules:OfflineMinutes(p, income.Config.OfflineMinutes))
end)
test("catalog VIP chest: yielding save, replay, rejoin and day boundary grant once", function()
	local e, player, p, commerce, config = catalogPlayer(412)
	config.Gamepasses.VIPPack.Id = 8001
	p.Monetization.Passes.VIPPack = true
	-- Keep geometry irrelevant; the actual VIP handler and durable transaction execute.
	e:Load("src/server/Services/MonetizationService").Cosmetics = nil
	e.Store.Before = function()
		coroutine.yield("VIP save")
	end
	local thread = e:Spawn(function()
		e:Fire("ClaimVIP", player)
	end)
	e:Fire("ClaimVIP", player)
	e.Store.Before = nil
	e:Resume(thread)
	local after = e.Data:Get(player)
	assert(after.Coins == 100 and after.Monetization.VIPDay == math.floor(e.Now / 86400))
	e.Now += 6
	e:Fire("ClaimVIP", player)
	assert(after.Coins == 100)
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(412)
	e:Fire("ClaimVIP", joined)
	assert(restored.Coins == 100)
	assert(commerce.Receipts:Quote(restored, "Coins10Minutes") == 100)
	e.Data:Close(joined)
	joined.Parent = nil
	e.Now += 86400
	local nextDay = e:Join(412)
	e:Fire("ClaimVIP", nextDay)
	assert(e.Data:Get(nextDay).Coins == 200, "VIP chest did not unlock on the next UTC day")
end)
test("rebirth displays: highest slot, gaps, reservations, settlement, rejoin and replay remain intact", function()
	local e = server()
	local player, before = rebirthReady(e, 413)
	before.Inventory.Rat, before.Inventory.Poop = 10, 10
	before.DisplaySlots, before.Upgrades.DisplaySlots = 10, 7
	before.Displays = { ["2"] = "Rat", ["9"] = "Rat", ["10"] = "Poop" }
	before.Income.UpdatedAt = e.Now - 30
	e:Fire("Rebirth", player, 0)
	local p = e.Data:Get(player)
	assert(before.Income.Pending["9"] > 0 and not next(p.Income.Pending))
	assert(
		p.DisplaySlots == 10
			and p.Displays["1"] == nil
			and p.Displays["2"] == "Rat"
			and p.Displays["9"] == "Rat"
			and p.Displays["10"] == "Poop"
	)
	assert(p.Inventory.Rat == 2 and p.ProtectedInventory.Rat == 2)
	local safe = e:Load("src/shared/SafeInventory")
	assert(safe.Displayable(p, "Rat") == 0 and safe.Sellable(p, "Rat") == 0)
	e.Now += 60
	e.Data:Get(player)
	assert(p.Income.Pending["9"] > 0 and p.Income.Pending["10"] > 0)
	e:Fire("Rebirth", player, 0)
	assert(p.RebirthLevel == 1)
	e.Data:Close(player)
	player.Parent = nil
	local _, loaded = e:Join(413)
	assert(loaded.Displays["9"] == "Rat" and loaded.Displays["10"] == "Poop" and loaded.Inventory.Rat == 2)
end)
test("path zones: actual authored route centers, all rotated plots and off-map positions", function()
	local e = environment()
	local rules, config, layout =
		e:Load("src/shared/PathBoostRules"),
		e:Load("src/shared/Config/PathBoost"),
		e:Load("src/shared/Config/MapLayout")
	local zones = rules.Zones(layout, e:Load("src/shared/Config/MeshCatalog"), config)
	assert(#zones > 40)
	for _, zone in ipairs(zones) do
		assert(rules.Find(zones, zone.X, zone.Y + 3, zone.Z, config.RootHeight))
	end
	assert(not rules.Find(zones, 10000, 3, 10000, config.RootHeight))
	assert(rules.Find(zones, -114, 3, -200, config.RootHeight))
	assert(not rules.Find(zones, -114, 100, -200, config.RootHeight))
end)

test("catalog auto collect: inside owned living plot only; fractional/manual ledgers cannot double credit", function()
	local e, player, p, commerce, config = catalogPlayer(414)
	config.Gamepasses.AutoCollect.Id = 8001
	p.Monetization.Passes.AutoCollect = true
	local localPosition = { X = 0, Y = 3, Z = 0 }
	e.World.Assigned[player].LayoutCFrame = {
		PointToObjectSpace = function()
			return localPosition
		end,
	}
	p.Income.Pending = { ["1"] = commerce.Income.Config.UnitsPerCoin * 10 + 1 }
	local writes = e.Store.Writes
	commerce:Collect(player)
	assert(p.Coins == 10 and p.Income.Pending["1"] == 1 and e.Store.Writes == writes)
	commerce:Collect(player)
	assert(p.Coins == 10)
	p.Income.Pending["1"] = commerce.Income.Config.UnitsPerCoin * 5
	for _, position in ipairs({ { X = 25, Y = 3, Z = 0 }, { X = 0, Y = 30, Z = 0 }, { X = 0 / 0, Y = 3, Z = 0 } }) do
		localPosition = position
		commerce:Collect(player)
		assert(p.Coins == 10)
	end
	localPosition = { X = 0, Y = 3, Z = 0 }
	player.Health = 0
	commerce:Collect(player)
	assert(p.Coins == 10)
	player.Health = 100
	e.World.Assigned[player].Owner = e:Player(999)
	commerce:Collect(player)
	assert(p.Coins == 10)
	e.World.Assigned[player].Owner = player
	e.Data.Saving[player] = true
	commerce:Collect(player)
	assert(p.Coins == 10)
	e.Data.Saving[player] = nil
	e:Fire("CollectIncome", player)
	commerce:Collect(player)
	assert(p.Coins == 15)
end)
test("catalog prompts: cancellation, failed prompt, saved-offer rejoin and spoofed completion never grant", function()
	local e, player, _, commerce = catalogPlayer(415)
	e:Fire("BuyProduct", player, "Coins10Minutes", 100)
	assert(e.Data:Get(player).Monetization.Quote and e.Data:Get(player).Coins == 0)
	e.Marketplace.PromptProductPurchaseFinished:Fire(player.UserId, 9001, false)
	assert(not e.Data:Get(player).Monetization.Quote and e.Data:Get(player).Coins == 0)
	e.Now += 11
	e.Marketplace.PromptError = true
	e:Fire("BuyProduct", player, "Coins10Minutes", 100)
	assert(not e.Data:Get(player).Monetization.Quote)
	e.Now += 11
	e.Marketplace.PromptError = false
	e:Fire("BuyProduct", player, "Coins10Minutes", 100)
	e.Data:Close(player)
	player.Parent = nil
	e.Players.PlayerRemoving:Fire(player)
	local joined, restored = e:Join(415)
	assert(commerce:Snapshot(restored, joined).CanResume)
	e:Fire("BuyProduct", joined, "Coins10Minutes", 100)
	e.Marketplace.PromptProductPurchaseFinished:Fire(joined.UserId, 9001, true)
	assert(e.Data:Get(joined).Coins == 0, "Prompt close granted a consumable")
	assert(e.Marketplace.ProcessReceipt(receipt(joined, "after-resume")) == "PurchaseGranted")
	assert(e.Data:Get(joined).Coins == 100)
end)
test("catalog receipts: early join delivery waits for the lease; no default/in-memory grant", function()
	local e = server()
	e:Load("src/shared/Config/Monetization").DeveloperProducts.Coins10Minutes.Id = 9001
	local player, result = e:Player(416), nil
	local thread = e:Spawn(function()
		result = e.Marketplace.ProcessReceipt(receipt(player, "before-load"))
	end)
	assert(not result and not e.Data.Profiles[player])
	e.Data:Load(player)
	e:Resume(thread)
	assert(result == "PurchaseGranted" and e.Store.Records.Player_416.Data.Coins == 100)
end)
test("path service: base restore, VIP/product cap, expiry, overrides, death, respawn and cleanup", function()
	local e = environment()
	local player = e:Player(417)
	e.Players.List = { player }
	local humanoid = { Health = 100, WalkSpeed = 16, Parent = true }
	local vector = e.Globals.Vector3.new
	local root = { Position = vector(-114, 3, -200) }
	player.Character = {
		FindFirstChild = function()
			return root
		end,
		FindFirstChildWhichIsA = function()
			return humanoid
		end,
	}
	local p = { Monetization = { Passes = {}, PathExpires = 0 } }
	local data = {
		Replacing = {},
		Get = function()
			return p
		end,
		Stopping = false,
	}
	e:Load("src/server/Services/PathBoostService").Start(data)
	local tick = e.Threads[#e.Threads]
	local function step()
		e.Now += 0.2
		e:Resume(tick)
	end
	step()
	assert(humanoid.WalkSpeed == 48 and player:GetAttribute("PathSpeedMultiplier") == 3)
	for _ = 1, 20 do
		step()
	end
	assert(humanoid.WalkSpeed == 48)
	p.Monetization.Passes.VIPPack = true
	step()
	assert(humanoid.WalkSpeed == 64)
	p.Monetization.PathExpires = e.Now + 10
	step()
	assert(humanoid.WalkSpeed == 80)
	data.Replacing[player] = true
	local retained = p
	p = nil
	step()
	assert(humanoid.WalkSpeed == 80, "An exclusive save interrupted verified path benefits")
	p = retained
	data.Replacing[player] = nil
	player:SetAttribute("ServerSpeedMultiplier", 10)
	step()
	assert(humanoid.WalkSpeed == 80)
	player:SetAttribute("ServerSpeedMultiplier", nil)
	player:SetAttribute("AdminWalkSpeed", 120)
	step()
	assert(humanoid.WalkSpeed == 120)
	player:SetAttribute("AdminWalkSpeed", nil)
	root.Position = vector(10000, 3, 10000)
	step()
	assert(humanoid.WalkSpeed == 16)
	root.Position = vector(-114, 3, -200)
	p.Monetization.PathExpires = 0
	step()
	assert(humanoid.WalkSpeed == 64)
	humanoid.Health = 0
	step()
	assert(humanoid.WalkSpeed == 16 and player:GetAttribute("PathSpeedMultiplier") == 1)
	humanoid = { Health = 100, WalkSpeed = 20, Parent = true }
	step()
	assert(humanoid.WalkSpeed == 80)
	player.CharacterRemoving:Fire()
	assert(humanoid.WalkSpeed == 20)
	step()
	e.Players.PlayerRemoving:Fire(player)
	assert(humanoid.WalkSpeed == 20)
	e.Players.List = {}
	data.Stopping = true
	e:Resume(tick)
	assert(coroutine.status(tick) == "dead")
end)

test("rebirth capacity: capped paid slots and index minima survive empty and sparse displays", function()
	for _, indexed in ipairs({ false, true }) do
		local e = server()
		e:Load("src/shared/Config/Monetization").Gamepasses.ExtraSlots.Id = 8001
		local player, before = rebirthReady(e, if indexed then 419 else 418)
		before.Monetization.Passes.ExtraSlots = true
		before.Monetization.AppliedSlots = 3
		before.Upgrades.DisplaySlots, before.DisplaySlots = 7, 10
		before.Displays, before.IndexClaims = {}, {}
		local expected = 10
		if indexed then
			for _, reward in ipairs(e:Load("src/shared/Config/IndexRewards").Milestones) do
				if reward.DisplaySlots then
					before.IndexClaims["total:" .. reward.Count] = true
					expected = math.max(expected, math.min(10, reward.DisplaySlots + 3))
				end
			end
			before.Inventory.Rat = 3
			before.Displays["2"] = "Rat"
		end
		e:Fire("Rebirth", player, 0)
		local after = e.Data:Get(player)
		assert(after.RebirthLevel == 1 and after.DisplaySlots == expected and after.Upgrades.DisplaySlots == 7)
		assert(not indexed or after.Displays["2"] == "Rat")
		e.Data:Close(player)
		player.Parent = nil
		local _, loaded = e:Join(player.UserId)
		assert(loaded.DisplaySlots == expected, "Save/rejoin changed retained paid capacity")
	end
end)
