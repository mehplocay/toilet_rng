test("tutorial: real outcomes, failed requests, first-copy display and upgrade checkpoints", function()
	local e = server()
	local player, p = e:Join(2701)
	assert(not p.TutorialDone and p.TutorialStep == 1)
	e:Fire("Sell", player, "Poop", 1)
	e:Fire("BuyToilet", player, "Dirty")
	assert(p.TutorialStep == 1)
	e:Fire("Flush", player)
	assert(p.TutorialStep == 3)
	e:Fire("Display", player, nil, 1)
	assert(p.TutorialStep == 3, "Returning a display is not collection progress")
	local id
	for itemId, count in pairs(p.Inventory) do
		if count > 0 then
			id = itemId
			break
		end
	end
	e:Fire("Sell", player, id, 1)
	assert(p.TutorialStep == 3, "The protected first copy cannot satisfy a sale")
	e.Now += 3
	e:Fire("Display", player, id, 1)
	assert(p.TutorialStep == 4 and not p.TutorialDone)
	e:Fire("BuyUpgrade", player, "CashBoost", 0)
	assert(p.TutorialStep == 4, "Unaffordable upgrade advanced onboarding")
	p.Coins = 10000
	e.Now += 3
	e:Fire("BuyUpgrade", player, "CashBoost", 0)
	assert(p.TutorialStep == 5 and p.TutorialDone)
	assert(e.Store.Records.Player_2701.Data.TutorialDone, "Upgrade save omitted the tutorial checkpoint")
end)
test("tutorial: sale/toilet branch, automatic flush, admin preview exclusion and existing upgrades", function()
	local e = server()
	local player, p = e:Join(2702)
	local progress = e:Load("src/shared/TutorialProgress")
	progress.Record(p, "Flush", { ItemId = "Poop", Admin = true })
	assert(p.TutorialStep == 1)
	p.Stats.Flushes = 100
	e:Fire("AutoFlush", player, true)
	player.Distance = 1000
	e.World.Flush(player, true)
	assert(p.TutorialStep == 3, "Automatic flush anywhere did not advance")
	p.Inventory.Poop = 3
	e:Fire("Sell", player, "Poop", 1)
	assert(p.TutorialStep == 4)
	p.Coins = 100000
	e:Fire("BuyToilet", player, "Dirty")
	assert(p.TutorialDone and p.TutorialStep == 5)
	e.Now += 5
	e:Fire("TutorialReplay", player)
	assert(not p.TutorialDone and p.TutorialStep == 1)
	progress.Record(p, "Flush", { ItemId = "Poop" })
	e.Now += 5
	e:Fire("Sell", player, "Poop", 1)
	assert(p.TutorialDone, "A returning player must not need a second permanent upgrade")
end)
test("tutorial: rejoin every checkpoint, skip, replay and malformed/rate-limited requests", function()
	local e = server()
	local player, p = e:Join(2703)
	for _, step in ipairs({ 1, 2, 3, 4 }) do
		p.TutorialStep, p.TutorialDone = step, false
		e.Data:Close(player)
		player, p = e:Join(2703)
		assert(p.TutorialStep == step and not p.TutorialDone)
	end
	e:Fire("TutorialDone", player, true)
	e:Fire("TutorialReplay", player, 3)
	assert(p.TutorialStep == 4 and not p.TutorialDone)
	e:Fire("TutorialDone", player)
	assert(p.TutorialDone and p.TutorialStep == 5)
	e.Data:Close(player)
	player, p = e:Join(2703)
	assert(p.TutorialDone)
	local coins, tier = p.Coins, p.ToiletTier
	e:Fire("TutorialReplay", player)
	e:Fire("TutorialReplay", player)
	local run = p.TutorialRun
	e:Fire("TutorialReplay", player)
	assert(p.TutorialRun == run and p.TutorialStep == 1 and not p.TutorialDone)
	assert(p.Coins == coins and p.ToiletTier == tier)
	e.Data:Close(player)
	player, p = e:Join(2703)
	assert(p.TutorialStep == 1 and not p.TutorialDone and p.TutorialRun == run)
	for _, bad in ipairs({ -1, 0, 6, 1.5, math.huge, "3" }) do
		local clean = e.Data.Sanitize({ TutorialDone = "true", TutorialStep = bad })
		assert(not clean.TutorialDone and clean.TutorialStep == 1)
	end
	assert(e.Data.Sanitize({ TutorialDone = true, TutorialStep = 3 }).TutorialStep == 5)
end)
test("tutorial: rebirth preserves checkpoints and owner reset is self-only and saved", function()
	local e = server()
	local player, p = e:Join(2704)
	p.TutorialStep, p.Coins, p.RunFlushes = 4, 1000000000, 300
	e:Fire("Rebirth", player, 0)
	assert(e.Data:Get(player).TutorialStep == 4 and not e.Data:Get(player).TutorialDone)
	local a = adminFixture()
	local owner, profile = a:JoinAdmin()
	local stranger, other = a:JoinAdmin(2705)
	profile.TutorialDone, profile.TutorialStep, profile.Coins = true, 5, 1234
	a.Admin:Request(owner, stranger, 1, "ResetTutorial", {})
	assert(profile.TutorialDone and not other.TutorialDone)
	a:Command(owner, "ResetTutorial", { Target = stranger.UserId })
	assert(profile.TutorialDone)
	a:Advance()
	a:Command(owner, "ResetTutorial")
	local reset = a.Data:Get(owner)
	assert(a:Last().Success and not reset.TutorialDone and reset.TutorialStep == 1 and reset.Coins == 1234)
	a.Data:Close(owner)
	local joined, restored = a:JoinAdmin()
	assert(not restored.TutorialDone and restored.TutorialStep == 1 and restored.TutorialRun == 1)
end)
