-- Fourth defensive review: adversarial requests and held backend operations against production code.
for _, backend in ipairs({ "policy", "ownership", "friends" }) do
	test("audit4: slow " .. backend .. " lookups cannot accumulate departed-player workers", function()
		local e = socialServer()
		local held = {}
		local function lookup()
			table.insert(held, coroutine.running())
			coroutine.yield("platform lookup held")
			return if backend == "policy" then { ArePaidRandomItemsRestricted = false } else true
		end
		local lucky = e:Load("src/server/Services/LuckyService")
		local monetization = e:Load("src/server/Services/MonetizationService")
		local anchor
		if backend == "friends" then
			anchor = e:Join(4700)
			e.FriendLookup = lookup
		elseif backend == "policy" then
			e.PolicyLookup = lookup
		else
			e.Marketplace.Lookup = lookup
		end
		for i = 1, 40 do
			local player
			if backend == "friends" then
				player = e:Join(4700 + i)
			else
				player = e:Player(4700 + i)
				e:Spawn(function()
					if backend == "policy" then
						lucky:Refresh(player)
					else
						monetization:Load(player)
					end
				end)
			end
			e.Players.PlayerRemoving:Fire(player)
			player.Parent = nil
		end
		assert(#held <= 12, "Retained " .. #held .. " " .. backend .. " workers")
		for _, thread in ipairs(held) do
			e:Resume(thread)
		end
		assert(lucky.Lookups == 0 and monetization.Lookups == 0 and e.Data.Social.Lookups == 0)
		if anchor then
			assert(next(e.Data.Social.Sessions[anchor].Pairs) == nil)
		else
			assert(next(lucky.Policies) == nil and next(monetization.Owned) == nil)
		end
	end)
end
test("audit4: frequent settlement cannot inflate a huge pending balance through upward rounding", function()
	local e = environment()
	local p = e:Load("src/server/Services/DataService").DefaultProfile()
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"))
	p.Displays, p.DisplaySlots = { ["1"] = "Poop" }, 1
	p.Income = { UpdatedAt = 1000, Pending = { ["1"] = 2 ^ 65 } }
	local before = p.Income.Pending["1"]
	local rate = income:Rates(p)["1"]
	for now = 1001, 1100 do
		income:Settle(p, now, false)
	end
	assert(p.Income.Pending["1"] - before <= 100 * rate, "Frequent settlement created more than the configured income")
end)
test("audit4: representable wallet steps never undercharge a price or overcredit an award", function()
	local e = environment()
	local cash = e:Load("src/shared/CashMath")
	for exponent = 54, 994, 20 do
		local balance = 2 ^ exponent
		local step = 2 ^ (exponent - 52)
		for _, fraction in ipairs({ 0.25, 0.75, 1.25, 1.75, 3.25 }) do
			local amount = step * fraction
			local after = cash.Debit(balance, amount)
			assert(balance - after >= math.ceil(amount), "Price rounded down")
			if cash.CanCredit(balance, amount) then
				assert(cash.Credit(balance, amount) - balance <= amount, "Award rounded up")
			end
		end
	end
end)

test("audit4: crafted monetary fields and numeric JSON tags cannot poison loaded profiles", function()
	local e = environment()
	local data = e:Load("src/server/Services/DataService")
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"))
	local format = e:Load("src/shared/NumberFormat")
	for _, bad in ipairs({ 0 / 0, math.huge, -math.huge, -1, "1e300", { t = "numeric", v = "inf" } }) do
		local p = data.Sanitize({
			Coins = bad,
			Stats = { Earned = bad },
			Income = { Pending = { ["1"] = bad } },
			Monetization = { Quote = { Key = "Coins10Minutes", Coins = bad } },
		})
		assert(p.Coins == 0 and p.Stats.Earned == 0 and income:TotalUnits(p) == 0)
		assert(p.Monetization.Quote == nil and format.Compact(bad) == "0")
	end
	for _, amount in ipairs({ 2 ^ 53, 1e19, 1.84e19, 1e100, 1e299, 1e300 }) do
		local player = e:Player(4400)
		e.Store.Records.Player_4400 = { Data = { Coins = amount, Stats = { Earned = amount } } }
		data:Load(player)
		assert(data:Get(player).Coins == amount and #format.Compact(amount) < 16)
		assert(data:Save(player, false))
		data:Close(player)
		player.Parent = nil
	end
	assert(data.Sanitize({ Coins = 1e301, Stats = { Earned = 1e301 } }).Coins == 0)
end)

test("audit4: every toilet retains 47 independent checks and exactly one fallback outcome", function()
	local e = environment()
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	local roll = e:Load("src/server/Services/RollService")
	local upgrades = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local p = e:Load("src/server/Services/DataService").DefaultProfile()
	for tier = 1, #toilets do
		local entries = roll.Distribution(items, toilets, tier, 1)
		assert(#entries == 47)
		local survival = 1
		for i, entry in ipairs(entries) do
			local calls = 0
			local item = roll.Sample(entries, function()
				calls += 1
				return if calls == i then 0 else 1 - 2 ^ -52
			end)
			assert(item.Id == entry.Item.Id and calls == i)
			assert(entry.Probability == survival * entry.Check)
			survival *= 1 - entry.Check
		end
		assert(survival == 0 and entries[47].Item.Id == "Poop")
		local huge = upgrades:Luck(p, toilets[tier].Luck, 1e300, 1e300, 1e300)
		assert(huge == 10)
		for _, entry in ipairs(roll.Distribution(items, toilets, tier, huge)) do
			assert(entry.Check >= 0 and entry.Check <= 1 and entry.Probability >= 0)
		end
	end
end)

test("audit4: policy revocation during receipt archive lookup preserves Lucky quote and defers", function()
	local e = server()
	local player, p = e:Join(4403)
	local lucky = e:Load("src/server/Services/LuckyService")
	local config = e:Load("src/shared/Config/Monetization")
	p.Monetization.Quote = { Key = "LuckyFlush5", Coins = 0 }
	assert(e.Data:Save(player, false))
	e.Archive.Before = function()
		coroutine.yield("receipt archive held")
	end
	local info = receipt(player, "audit4-policy", config.DeveloperProducts.LuckyFlush5.Id)
	local result
	local thread = e:Spawn(function()
		result = e.Marketplace.ProcessReceipt(info)
	end)
	lucky.Policies[player].Allowed = false
	e.Archive.Before = nil
	e:Resume(thread)
	assert(result == "NotProcessedYet" and p.Monetization.LuckyFlushes == 0 and p.Monetization.Quote)
	lucky:Refresh(player)
	assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
	p = e.Data:Get(player)
	assert(p.Monetization.LuckyFlushes == 5 and not p.Monetization.Quote)
	lucky.Policies[player].Allowed = false
	assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted" and p.Monetization.LuckyFlushes == 5)
end)

test("audit4: tiny paid credits defer intact instead of vanishing into a huge wallet", function()
	local e = server()
	local player, p = e:Join(4404)
	local config = e:Load("src/shared/Config/Monetization")
	p.Coins = 1e100
	p.Monetization.Quote = { Key = "Coins10Minutes", Coins = 100 }
	local info = receipt(player, "audit4-small-paid", config.DeveloperProducts.Coins10Minutes.Id)
	assert(e.Marketplace.ProcessReceipt(info) == "NotProcessedYet")
	assert(p.Monetization.Quote.Coins == 100 and #p.Monetization.Receipts == 0)
	p.Coins = 0
	assert(e.Marketplace.ProcessReceipt(info) == "PurchaseGranted")
	p = e.Data:Get(player)
	assert(p.Coins == 100 and e.Marketplace.ProcessReceipt(info) == "PurchaseGranted" and p.Coins == 100)
end)

test("audit4: forged tutorial results, replay flood and reward dismissal cannot grant progression", function()
	local e = server()
	local player, p = e:Join(4405)
	local writes = e.Store.Writes
	for _ = 1, 1000 do
		e:Fire("Result", player, "Flush", { Success = true, ItemId = "Mystery" })
		e:Fire("TutorialReplay", player, 1212975135)
		e:Fire("TutorialDone", player, { TutorialStep = 5, Reward = 1e300 })
	end
	assert(p.TutorialStep == 1 and p.TutorialRun == 0 and not p.TutorialDone)
	e:Fire("TutorialDone", player)
	for _ = 1, 1000 do
		e:Fire("TutorialReplay", player)
	end
	assert(p.TutorialRun <= 2 and p.TutorialStep == 1 and p.Coins == 0 and p.Stats.Flushes == 0)
	assert(e.Store.Writes == writes)
end)

test("audit4: owner-only tutorial reset and huge-money commands deny copied endpoint requests", function()
	local e = adminFixture()
	local owner, p = e:JoinAdmin()
	local intruder = e:JoinAdmin(1212975136)
	local endpoint = e.Admin.Endpoints[owner]
	for i, request in ipairs({
		{ "ResetTutorial", {} },
		{ "SetCoins", { Amount = 1e300 } },
		{ "Pending", { Slot = 1, Amount = 1e299 } },
		{ "TestPasses", { Enabled = true } },
	}) do
		endpoint.Remote.OnServerEvent:Fire(intruder, i, request[1], request[2])
	end
	assert(p.Coins == 0 and p.TutorialRun == 0 and not e.Admin.Endpoints[intruder])
	e.Config.UserIds[owner.UserId] = nil
	endpoint.Remote.OnServerEvent:Fire(owner, 100, "ResetTutorial", {})
	assert(p.TutorialRun == 0 and not e.Admin.Endpoints[owner])
end)

test("audit4: many live friends and join-leave churn never stack beyond eleven verified peers", function()
	local e = socialServer()
	local players = {}
	for a = 4601, 4612 do
		for b = a + 1, 4612 do
			e.Friends[a .. ":" .. b] = true
		end
	end
	for id = 4601, 4612 do
		table.insert(players, (e:Join(id)))
	end
	assert(e.FriendCalls == 66)
	for _, player in ipairs(players) do
		assert(e.Data:Get(player).SocialRuntime.FriendCount == 11)
	end
	for _ = 1, 10 do
		local old = players[12]
		e.Players.PlayerRemoving:Fire(old)
		old.Parent = nil
		assert(e.Data:Get(players[1]).SocialRuntime.FriendCount == 10)
		players[12] = e:Join(4612)
		assert(e.Data:Get(players[1]).SocialRuntime.FriendCount == 11)
	end
	for _, player in ipairs(players) do
		e.Players.PlayerRemoving:Fire(player)
		player.Parent = nil
	end
	assert(next(e.Data.Social.Sessions) == nil)
end)

test("audit4: referral spoof payloads and oversized lifetime history fail closed", function()
	local e = socialServer()
	local rules = e:Load("src/shared/SocialBoostRules")
	local inviter, p = e:Join(4620)
	for _, payload in ipairs({
		{ LaunchData = '{"ReferredByPlayerId":4620}' },
		{ TeleportData = { ReferredByPlayerId = 4620 } },
		{ FollowUserId = 4620 },
		{ ReferredByPlayerId = 0 / 0 },
		{ ReferredByPlayerId = 1e300 },
		{ ReferredByPlayerId = 4621 },
	}) do
		assert(rules.Referrer(payload, 4621) == nil)
		e:Fire("PromptInvite", inviter, payload)
	end
	assert(p.Social.InviteExpires == 0)
	local history = {}
	for i = 1, 4097 do
		history[i] = 5000 + i
	end
	p.Social = rules.Sanitize({ Version = 1, Rewarded = history, DailyCount = 0 }, e.Now)
	assert(p.Social.HistoryFull and #p.Social.Rewarded <= 4096)
	assert(not rules.Award(p, inviter.UserId, 99999, e.Now))
	assert(e.Data:Save(inviter, false) and e.Data.Sanitize(p).Social.HistoryFull)
end)
test("audit4: repeated small collections cannot round a huge wallet upward beyond the debited income", function()
	local e = server()
	local player, p = e:Join(4401)
	local income = e:Load("src/shared/IncomeAccrual")
		.new(e:Load("src/shared/Config/Income"), e:Load("src/shared/Config/Items"))
	p.Coins = 2 ^ 53
	local before = p.Coins
	for _ = 1, 100 do
		p.Income.Pending = { ["1"] = 3 * 6000 }
		assert(income:Collect(p, 1) > 0)
		assert(income:TotalUnits(p) == 0)
	end
	assert(p.Coins - before <= 300, "100 three-coin debits minted " .. (p.Coins - before) .. " wallet coins")
	assert(e.Data:Save(player, false))
end)

test("audit4: splitting sales cannot repeatedly round three coins up to four", function()
	local e = environment()
	local p = e:Load("src/server/Services/DataService").DefaultProfile()
	p.Coins, p.Inventory.Poop = 2 ^ 53, 101
	local before = p.Coins
	local inventory = e:Load("src/shared/SafeInventory")
	for _ = 1, 100 do
		assert(inventory.Sell(p, { { Id = "Poop", Value = 3 } }, "Poop", 1, 1))
	end
	assert(p.Coins - before <= 300 and p.Inventory.Poop == 1)
end)

test("audit4: product floods have bounded rejection traffic including surplus arguments", function()
	local e = server()
	local player = e:Join(4402)
	e.Results = {}
	local writes = e.Store.Writes
	for _ = 1, 1000 do
		e:Fire("BuyProduct", player, "unknown", 0)
		e:Fire("BuyProduct", player, "unknown", 0, nil, "extra")
	end
	assert(#e.Results <= 3, "Rejected product traffic amplified into " .. #e.Results .. " replies")
	assert(e.Store.Writes == writes and not e.Marketplace.LastProduct)
end)

test("audit4: departed social lookups have a server-wide in-flight bound under join churn", function()
	local e = socialServer()
	local held = {}
	e.GroupLookup = function()
		table.insert(held, coroutine.running())
		coroutine.yield("group backend held")
		return true
	end
	for i = 1, 40 do
		local player = e:Join(4500 + i)
		e.Players.PlayerRemoving:Fire(player)
		player.Parent = nil
	end
	assert(#held <= 12, "Departed sessions retained " .. #held .. " backend calls")
	assert(next(e.Data.Social.Sessions) == nil)
	for _, thread in ipairs(held) do
		e:Resume(thread)
	end
	local live, p = e:Join(4599)
	assert(#held > 0 and not p.SocialRuntime.GroupMember)
	e:Resume(held[#held])
	assert(e.Data:Get(live).SocialRuntime.GroupMember)
end)
