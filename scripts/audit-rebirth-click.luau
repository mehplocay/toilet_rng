-- Bridge the production button to the production server handler with delayed results.
test("rebirth click: double click commits exactly one rebirth before its delayed result", function()
	local e = server()
	local player = rebirthReady(e, 230)
	local C = H.Load("src/client/UI/Components")
	local soundHook = C.SoundHook
	C.SoundHook = function() end
	local root, remotes = H.Root(1280, 684), H.Remotes()
	local ui = H.Load("src/client/UI/Rebirth").Create(root, remotes)
	ui.Panel.Visible = true
	local config = e:Load("src/shared/Config/Rebirth")
	ui.Update({ Coins = config.Levels[1].RequiredCoins, RunFlushes = config.RequiredFlushes, RebirthLevel = 0 })
	local button, requests = ui.Panel.ContentScroll.Body.Confirm, 0
	remotes.Rebirth.FireServer = function(_, expected, ...)
		assert(not button.Interactable and select("#", ...) == 0)
		requests += 1
		e:Fire("Rebirth", player, expected)
	end
	local writes = e.Store.Writes
	button.Activated:Fire()
	button.Activated:Fire()
	assert(requests == 1 and rebirthSuccesses(e) == 1 and e.Store.Writes == writes + 1)
	assert(e.Data:Get(player).RebirthLevel == 1 and e.Store.Records.Player_230.Data.RebirthLevel == 1)
	assert(not button.Interactable)
	for _, result in ipairs(e.Results) do
		if result.Payload[1] == "Rebirth" then
			remotes.Result.OnClientEvent:Fire(table.unpack(result.Payload))
		end
	end
	assert(not ui.Panel.Visible and not button.Interactable)
	ui.Panel:Destroy()
	root:Destroy()
	C.SoundHook = soundHook
end)

test("rebirth click: one click accepts no client timing or reward claims", function()
	local e = server()
	local player = rebirthReady(e, 231)
	local writes = e.Store.Writes
	for _, extra in ipairs({ 2, true, { HoldSeconds = 2, Coins = 9e15, RunFlushes = 99999, Success = true } }) do
		e:Fire("Rebirth", player, 0, extra)
		e.Now += 5
	end
	assert(e.Data:Get(player).RebirthLevel == 0 and e.Store.Writes == writes)
	e:Fire("Rebirth", player, 0)
	assert(e.Data:Get(player).RebirthLevel == 1 and rebirthSuccesses(e) == 1 and e.Store.Writes == writes + 1)
	-- Refill and make the next level eligible: old clicks must still reject.
	local p = e.Data:Get(player)
	local config = e:Load("src/shared/Config/Rebirth")
	p.Coins, p.RunFlushes = config.Levels[2].RequiredCoins, config.RequiredFlushes
	e.Now += 5
	e:Fire("Rebirth", player, 0)
	assert(p.RebirthLevel == 1 and rebirthSuccesses(e) == 1 and e.Store.Writes == writes + 1)
end)

test("rebirth click: missing coins or flushes cannot rebirth and spam is rate limited", function()
	for _, field in ipairs({ "Coins", "RunFlushes" }) do
		local e = server()
		local player, p = rebirthReady(e, 232)
		local old = p[field]
		p[field] = old - 1
		local writes, results = e.Store.Writes, #e.Results
		for _ = 1, 1000 do
			e:Fire("Rebirth", player, 0)
		end
		assert(e.Data:Get(player) == p and p.RebirthLevel == 0)
		assert(e.Store.Writes == writes and #e.Results == results + 1 and rebirthSuccesses(e) == 0)
		p[field] = old
		e.Now += 4.9
		e:Fire("Rebirth", player, 0)
		assert(p.RebirthLevel == 0 and e.Store.Writes == writes, "Rebirth bypassed the five-second server bucket")
		e.Now += 0.2
		e:Fire("Rebirth", player, 0)
		assert(e.Data:Get(player).RebirthLevel == 1 and rebirthSuccesses(e) == 1)
	end
end)
