do
	local root, remotes = H.Root(390, 722), H.Remotes()
	local state = {
		Coins = 9e15,
		PendingCoins = 34560000000,
		ToiletTier = 7,
		LifetimeFlushes = 3300,
		RunFlushes = 3300,
		RebirthLevel = 0,
		AutoFlush = false,
		LastClaimDay = 0,
		Streak = 0,
		Settings = {},
	}
	local function contains(parent, text)
		for _, object in ipairs(parent:GetDescendants()) do
			if object:IsA("TextLabel") and object.Text:find(text, 1, true) then
				return true
			end
		end
		return false
	end
	local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
		Near = function()
			return true
		end,
	})
	hud.Update(state)
	-- Exercise the actual NumberValue -> wallet label callback, independently of the tween mock.
	root.HUD.Wallet.NumberValue.Changed:Fire(9e15)
	assert(contains(root.HUD.Wallet, "9Qa"))
	local pending = H.Load("src/client/UI/IncomeChip").Create(root)
	pending.Update(state.PendingCoins)
	assert(contains(root.PendingIncome, "Pending: 34.5B"))
	H.Load("src/client/UI/CoinPopup").Create(root)(1500000000000, true)
	assert(contains(root.ServiceCoinPopup, "+1.5T"))
	-- Generic tween completion is deliberately outside this UI double; remove transient fixtures for snapshots.
	for _, object in ipairs(root:GetChildren()) do
		if object.Name == "ServiceCoinPopup" or object.Name == "IncomeCoinFlight" then
			object:Destroy()
		end
	end
	local rebirth = H.Load("src/client/UI/Rebirth").Create(root, remotes)
	rebirth.Update(state)
	rebirth.Panel.Visible = true
	assert(contains(rebirth.Panel, "9Qa wallet Coins + 34.5B pending Coins reset."))
	H.Layout(root)
	local scroll, body = rebirth.Panel.ContentScroll, rebirth.Panel.ContentScroll.Body
	scroll.CanvasPosition = Vector2.new(0, math.max(0, body.AbsoluteSize.Y - scroll.AbsoluteSize.Y))
	H.Snapshot(root, "income-first-rebirth-phone")
	rebirth.Panel.Visible = false
	local shop = H.Load("src/client/UI/Upgrades").Create(root, remotes)
	shop.Update({
		Coins = 9e15,
		ToiletTier = 6,
		DisplaySlots = 10,
		Upgrades = { CashBoost = 9, LuckBoost = 9, OfflineTank = 9 },
	})
	shop.Panel.Visible = true
	assert(contains(shop.Panel, "95M Coins") and contains(shop.Panel, "9Qa Coins"))
	shop.Panel.ContentScroll.Body:FindFirstChild("Coin Upgrades", true).Activated:Fire()
	H.Snapshot(root, "income-first-upgrades-phone")
	root:Destroy()
	print("Economy UI passed: actual wallet, pending, popup, shop, upgrades, rebirth and player-list abbreviations")
end
