test("merge commerce: admin reset/import preserve receipts, quotes, passes and VIP claim identity", function()
	local e, player, p, commerce, config = catalogPlayer(430)
	-- These fixtures mock profile/world boundaries, not cosmetic geometry.
	e:Load("src/server/Services/MonetizationService").Cosmetics = nil
	config.Gamepasses.VIPPack.Id = 8430
	p.Monetization.Passes.VIPPack = true
	p.Monetization.VIPDay = math.floor(e.Now / 86400)
	p.Monetization.PathExpires = e.Now + 600
	assert(e.Marketplace.ProcessReceipt(receipt(player, "before-admin")) == "PurchaseGranted")
	p = e.Data:Get(player)
	p.Monetization.Quote = { Key = "Coins6Hours", Coins = 123456789 }
	local mutations = e:Load("src/server/Admin/Mutations")
	for _, action in ipairs({ "Reset", "Import" }) do
		local imported = e.Data.DefaultProfile()
		imported.Monetization.Passes.DoubleCash = true
		imported.Monetization.PathExpires = 9e15
		local replacement = mutations.Build(e.Data, p, action, {}, e.Now, imported)
		assert(e.Data:ReplaceAndSave(player, p, replacement))
		p = e.Data:Get(player)
		assert(p.Monetization.Passes.VIPPack and not p.Monetization.Passes.DoubleCash)
		assert(p.Monetization.VIPDay == math.floor(e.Now / 86400))
		assert(p.Monetization.PathExpires == e.Now + 600 and p.Monetization.Quote.Coins == 123456789)
		assert(#p.Monetization.Receipts == 1 and p.Monetization ~= imported.Monetization)
		local coins = p.Coins
		assert(e.Marketplace.ProcessReceipt(receipt(player, "before-admin")) == "PurchaseGranted")
		assert(p.Coins == coins, "Admin replacement reopened a paid receipt")
		e:Fire("ClaimVIP", player)
		assert(e.Data:Get(player).Coins == coins, "Admin replacement reopened today's VIP chest")
	end
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(430)
	assert(commerce.Receipts:Process(receipt(joined, "before-admin")) == "PurchaseGranted")
	assert(restored.Coins == p.Coins and restored.Monetization.Quote.Coins == 123456789)
end)

for _, beforePath in ipairs({ false, true }) do
	test(
		"merge movement: actual admin speed and expiry coexist with paths, starts first=" .. tostring(beforePath),
		function()
			local e = environment()
			local data = e:Load(dataPath)
			local player = e:Player(1212975135)
			data:Load(player)
			e.Players.List = { player }
			local model = {}
			local humanoid =
				{ Parent = model, Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, UseJumpPower = false }
			local root = { Position = e.Globals.Vector3.new(-114, 3, -200) }
			function model:FindFirstChild()
				return root
			end
			function model:FindFirstChildWhichIsA()
				return humanoid
			end
			player.Character = model
			local runtime = e:Load("src/server/Admin/Runtime").new(data, {}, {}, {})
			runtime:Start({
				Remove = function(_, owner)
					runtime:Remove(owner)
				end,
			})
			if beforePath then
				assert(runtime:Execute(player, data:Get(player), "Speed", { Amount = 96 }))
			end
			e:Load("src/server/Services/PathBoostService").Start(data)
			local tick = e.Threads[#e.Threads]
			local function step()
				e.Now += 0.2
				e:Resume(tick)
			end
			step()
			if not beforePath then
				assert(humanoid.WalkSpeed == 48)
				assert(runtime:Execute(player, data:Get(player), "Speed", { Amount = 96 }))
			end
			for _ = 1, 5 do
				step()
			end
			assert(humanoid.WalkSpeed == 96 and player:GetAttribute("PathSpeedMultiplier") == 1)
			e.Now += 16
			e.Services.RunService.Heartbeat:Fire(1 / 60)
			step()
			assert(player:GetAttribute("AdminWalkSpeed") == nil and player:GetAttribute("AdminBaseWalkSpeed") == nil)
			assert(humanoid.WalkSpeed == 48 and player:GetAttribute("PathSpeedMultiplier") == 3)
			root.Position = e.Globals.Vector3.new(10000, 3, 10000)
			step()
			assert(humanoid.WalkSpeed == 16, "Admin speed became the permanent path baseline")
			data.Stopping = true
			e:Resume(tick)
		end
	)
end

test("merge economy: maximum paid offline ledger round-trips exact fractions and collects only once", function()
	local e, player, p, commerce, config = catalogPlayer(431)
	e:Load("src/server/Services/MonetizationService").Cosmetics = nil
	for i, key in ipairs({ "DoubleCash", "VIPPack", "OfflinePlus" }) do
		config.Gamepasses[key].Id = 8430 + i
		p.Monetization.Passes[key] = true
	end
	p.ToiletTier, p.RebirthLevel, p.DisplaySlots = 7, 15, 10
	p.Upgrades.CashBoost, p.Upgrades.OfflineTank = 10, 10
	p.Inventory.Mystery = 10
	for slot = 1, 10 do
		p.Displays[tostring(slot)] = "Mystery"
	end
	local income = commerce.Income
	assert(income.Upgrades:Cash(p) == 9)
	assert(income.Upgrades:OfflineMinutes(p, income.Config.OfflineMinutes) == 1440)
	assert(income:Rates(p)["1"] == 1200000 * 9 * 6000)
	p.Income.UpdatedAt = e.Now - 86400
	income:Settle(p, e.Now, true)
	assert(income:TotalUnits(p) == 9e15 and income:StorageUnits(p, false) == 9e15)
	p.Income.Pending["1"] -= 1
	assert(e.Data:Save(player, false))
	e.Data:Close(player)
	player.Parent = nil
	local joined, restored = e:Join(431)
	assert(income:TotalUnits(restored) == 9e15 - 1, "Paid load/save clipped or rounded the ledger")
	local before = restored.Coins
	assert(income:Collect(restored) == 1499999999999)
	assert(restored.Coins == before + 1499999999999 and income:TotalUnits(restored) == 5999)
	assert(income:Collect(restored) == 0, "Collection multiplied already boosted pending coins")
	assert(e.Data:Get(joined) == restored)
end)
