test("all pools: every tier reaches all 47 items, normalized odds and monotone rare outcomes", function()
	local e = environment()
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	local roll = e:Load("src/server/Services/RollService")
	local previous
	for tier, toilet in ipairs(toilets) do
		local entries = roll.Distribution(items, toilets, tier)
		assert(#entries == 47 and toilet.Pool == nil)
		local total, cumulative, rarities = 0, 0, {}
		for i, entry in ipairs(entries) do
			assert(entry.Probability > 0, "Unreachable at toilet's unboosted luck: " .. entry.Item.Id)
			total += entry.Probability
			cumulative += entry.Probability
			rarities[entry.Item.Rarity] = true
			if previous then
				assert(entry.Check >= previous[i].Check)
				-- Individual common outcomes can fall as earlier checks win more often.
				assert(cumulative + 1e-12 >= previous[i].Cumulative)
				if entry.Item.Chance >= 25 then
					assert(entry.Probability > previous[i].Probability, entry.Item.Id)
				end
			end
			entry.Cumulative = cumulative
			local calls = 0
			assert(roll.Sample(entries, function()
				calls += 1
				return if calls == i then 0 else 0.999999999999
			end).Id == entry.Item.Id)
		end
		local count = 0
		for _ in pairs(rarities) do
			count += 1
		end
		assert(count == 9 and math.abs(total - 1) < 1e-12)
		previous = entries
	end
end)

test("all pools: Lucky disclosure matches current tier rolls and every rarity", function()
	local e = server()
	local player, p = e:Join(9821)
	local lucky, roll = e:Load("src/server/Services/LuckyService"), e:Load("src/server/Services/RollService")
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	local previousToken
	for tier = 1, #toilets do
		p.ToiletTier = tier
		local odds = lucky:Odds(p)
		assert(#odds.Items == 47 and odds.Token ~= previousToken)
		local normal = roll.Distribution(items, toilets, tier, odds.BaseLuck)
		local boosted = roll.Distribution(items, toilets, tier, odds.Luck)
		local sums = {}
		for i, row in ipairs(odds.Items) do
			assert(row.Id == normal[i].Item.Id and row.Normal == normal[i].Probability)
			assert(row.Boosted == boosted[i].Probability)
			local sum = sums[row.Rarity] or { Normal = 0, Boosted = 0 }
			sum.Normal += row.Normal
			sum.Boosted += row.Boosted
			sums[row.Rarity] = sum
		end
		for rarity, sum in pairs(sums) do
			assert(sum.Normal == odds.Rarities[rarity].Normal and sum.Boosted == odds.Rarities[rarity].Boosted)
		end
		previousToken = odds.Token
	end
	e.Data:Close(player)
end)

test("all pools: Basic profiles retain late items, balances, displays and claims across save/rejoin", function()
	local e = server()
	local player, p = e:Join(9822)
	local items = e:Load("src/shared/Config/Items")
	for _, item in ipairs(items) do
		p.Inventory[item.Id], p.Collection[item.Id] = 3, 7
	end
	p.Displays["1"], p.Displays["3"] = "CosmicCourtesy", "StarlightSeraph"
	p.ProtectedInventory.CosmicCourtesy = 1
	p.Coins, p.Stamps, p.RunFlushes = 123456, 37, 19
	p.IndexClaims["rarity:Secret"] = true
	p.Income.Pending["1"] = 1234
	e.Data:Close(player)
	local _, restored = e:Join(9822)
	assert(restored.ToiletTier == 1 and restored.Coins == 123456 and restored.RunFlushes == 19)
	assert(restored.Stamps == 37 and restored.IndexClaims["rarity:Secret"])
	assert(restored.ProtectedInventory.CosmicCourtesy == 1 and restored.Income.Pending["1"] == 1234)
	assert(restored.Displays["1"] == "CosmicCourtesy" and restored.Displays["3"] == "StarlightSeraph")
	for _, item in ipairs(items) do
		assert(restored.Inventory[item.Id] == 3 and restored.Collection[item.Id] == 7)
	end
end)
