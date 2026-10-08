do
	local clock = H.Services.Workspace.GetServerTimeNow
	local now = 1800000000
	H.Services.Workspace.GetServerTimeNow = function()
		return now
	end
	local SocialUI = H.Load("src/client/UI/SocialBoosts")
	assert(SocialUI.ChipText({ FriendCount = 3, InviteRemaining = 1800 }):find("Invite luck +20% 30:00", 1, true))
	for _, size in
		ipairs(H.Viewports or {
			{ 1920, 1044 },
			{ 1280, 684 },
			{ 375, 690 },
			{ 724, 318 },
			{ 1024, 712 },
			{ 768, 968 },
			{ 1116, 483 },
			{ 711, 751 },
			{ 711, 731 },
			{ 360, 518 },
			{ 390, 722 },
			{ 640, 303 },
		})
	do
		local root, remotes = H.Root(size[1], size[2]), H.Remotes()
		local ui = H.Load("src/client/UI/LuckyOdds").Create(root, remotes)
		local items, toilets = H.Load("src/shared/Config/Items"), H.Load("src/shared/Config/Toilets")
		local roll = H.Load("src/server/Services/RollService")
		local u = H.Load("src/shared/UpgradeRules").new(H.Load("src/shared/Config/Upgrades"))
		local p = { Upgrades = { LuckBoost = 50 }, RebirthLevel = 15, Social = { InviteExpires = os.time() + 1800 } }
		local luck = u:Luck(p, toilets[15].Luck, 2, 2, 1.25, 2)
		local odds = {
			Token = "invite",
			BaseLuck = luck,
			Luck = luck * 10,
			VIPLuck = true,
			DoubleLuck = true,
			InviteLuck = 1.2,
			InviteExpires = now + 3,
			InviteRemaining = 3,
			Items = {},
			Rarities = {},
		}
		local normal, charged =
			roll.Distribution(items, toilets, 15, luck), roll.Distribution(items, toilets, 15, luck * 10)
		for i, entry in ipairs(normal) do
			local item = entry.Item
			odds.Items[i] = {
				Id = item.Id,
				Name = item.Name,
				Rarity = item.Rarity,
				BaseChance = item.Chance,
				Fallback = item.Id == "Poop",
				Normal = entry.Probability,
				Boosted = charged[i].Probability,
			}
			local sum = odds.Rarities[item.Rarity] or { Normal = 0, Boosted = 0 }
			sum.Normal += entry.Probability
			sum.Boosted += charged[i].Probability
			odds.Rarities[item.Rarity] = sum
		end
		ui.Show({ Allowed = true, Count = 1, Odds = odds })
		H.StartTasks()
		H.Layout(root)
		assert(ui.Panel.ContentScroll.Body.LuckBreakdown.Text:find("Invite luck x1.2: 00:03", 1, true))
		for _, row in ipairs(odds.Items) do
			local label = ui.Panel.ContentScroll.Body:FindFirstChild(row.Id)
			local shown = assert(tonumber(label.Text:match("Normal ([%d%.]+)%%")))
			assert(math.abs(shown / 100 - row.Normal) <= 1.1e-14)
		end
		now += 3
		H.Advance(3)
		H.ResumeTasks()
		assert(not ui.Panel.Visible, "Expired invite odds must close before server refresh")
		ui.Show({ Allowed = true, Count = 1, Odds = odds })
		assert(not ui.Panel.Visible, "Stale odds cannot reopen")
		root:Destroy()
	end
	-- Receiving the same snapshot again must not restart the countdown.
	do
		local root, remotes = H.Root(390, 722), H.Remotes()
		local ui = H.Load("src/client/UI/LuckyOdds").Create(root, remotes)
		local odds = { Token = "delayed", InviteLuck = 1.2, InviteRemaining = 3 }
		local lucky = { Allowed = true, Count = 1, Odds = odds }
		ui.Invalidate(lucky)
		H.Advance(4)
		ui.Invalidate(lucky)
		ui.Show(lucky)
		assert(not ui.Panel.Visible, "Delayed first open must not revive expired invite odds")
		root:Destroy()
	end
	for _, allowed in ipairs({ false, true }) do
		local root, remotes = H.Root(390, 722), H.Remotes()
		local hud = H.Load("src/client/UI/HUD").Create(root, remotes, function() end, {
			Near = function()
				return true
			end,
		})
		local lucky = {
			Allowed = allowed,
			PolicyRemaining = 120,
			Count = 0,
			FreeLuck = 1.2,
			InviteLuck = 1.2,
			InviteExpires = now + 3,
			InviteRemaining = 3,
			Odds = if allowed
				then {
					BaseLuck = 3,
					Luck = 30,
					Items = {},
					Rarities = {},
					VIPLuck = true,
					DoubleLuck = true,
					InviteLuck = 1.2,
					InviteExpires = now + 3,
				}
				else nil,
		}
		hud.Update({
			Coins = 100,
			ToiletTier = 1,
			RebirthLevel = 0,
			RunFlushes = 0,
			LifetimeFlushes = 0,
			LastClaimDay = 0,
			Streak = 0,
			Social = { FriendCount = 3, InviteRemaining = 3 },
			Commerce = { Lucky = lucky },
			UpgradeStats = { LuckMultiplier = 1.2 },
		})
		H.StartTasks()
		H.Advance(1.01)
		H.ResumeTasks()
		local chip = root.HUD:FindFirstChild("TotalLuck", true)
		local breakdown = root.HUD:FindFirstChild("LuckBreakdown", true)
		assert(chip.Text == (if allowed then "Luck x3" else "Luck x1.2"))
		assert(breakdown.Text:find("Invite luck x1.2: 00:02", 1, true))
		local wallet = root.HUD.Wallet:FindFirstChildWhichIsA("TextLabel", true).Text
		now += 3
		H.Advance(3)
		H.ResumeTasks()
		assert(chip.Text == (if allowed then "Luck x2.5" else "Luck x1"))
		assert(breakdown.Text:find("Invite luck: inactive", 1, true))
		assert(root.HUD.Wallet:FindFirstChildWhichIsA("TextLabel", true).Text == wallet)
		root:Destroy()
	end
	H.Services.Workspace.GetServerTimeNow = clock
	print(
		"Invite luck UI: exact roll odds, disclosure across 12 viewports, free/restricted HUD and local expiry passed"
	)
end
