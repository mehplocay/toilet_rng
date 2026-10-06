-- Numeric oracles include both sides of the former odds boundary and every rarity.
test("linear luck: 1x, 5x and 10x checks, sequential outcomes, probability clamp and fallback", function()
	local e = server()
	local roll = e:Load("src/server/Services/RollService")
	local items = {
		{ Id = "Secret", Chance = 10000000 },
		{ Id = "Celestial", Chance = 900000 },
		{ Id = "Godly", Chance = 25001 },
		{ Id = "Boundary", Chance = 25000 },
		{ Id = "Mythic", Chance = 5000 },
		{ Id = "Legendary", Chance = 1000 },
		{ Id = "Epic", Chance = 250 },
		{ Id = "Rare", Chance = 25 },
		{ Id = "Uncommon", Chance = 8 },
		{ Id = "Common", Chance = 5 },
		{ Id = "Poop", Chance = 2 },
	}
	local pool = {}
	for _, item in ipairs(items) do
		table.insert(pool, item.Id)
	end
	for _, luck in ipairs({ 1, 5, 10, 1000000 }) do
		local entries, empty = roll.Distribution(items, { { Pool = pool, Luck = 1 } }, 1, luck)
		local remaining, total = 1, 0
		for i, entry in ipairs(entries) do
			local check = if i == #items then 1 else math.min(1, math.min(luck, 10) / items[i].Chance)
			assert(entry.Item.Id == items[i].Id and entry.Check == check)
			assert(entry.Probability >= 0 and entry.Probability <= 1)
			assert(math.abs(entry.Probability - remaining * check) < 1e-14)
			remaining *= 1 - check
			total += entry.Probability
		end
		assert(empty == 0 and remaining == 0 and math.abs(total - 1) < 1e-12)
		assert(entries[1].Check == math.min(luck, 10) / 10000000)
		assert(entries[2].Check == math.min(luck, 10) / 900000)
	end
	local entries = roll.Distribution(items, { { Pool = pool, Luck = 1 } }, 1, 1)
	for chosen = 1, #entries do
		local calls = 0
		local item = roll.Sample(entries, function()
			calls += 1
			return if calls == chosen then 0 else 0.999999999999
		end)
		assert(calls == chosen and item.Id == entries[chosen].Item.Id)
	end
end)

test("linear luck: every production pool has unit mass, capped checks and identical 10x/overflow outcomes", function()
	local e = server()
	local roll = e:Load("src/server/Services/RollService")
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	for tier = 1, #toilets do
		local capped = roll.Distribution(items, toilets, tier, 10)
		for _, luck in ipairs({ 1, 5, 10, 1e300 }) do
			local entries = roll.Distribution(items, toilets, tier, luck)
			local total, remaining, rarities = 0, 1, {}
			for i, entry in ipairs(entries) do
				local check = if entry.Item.Id == "Poop" then 1 else math.min(1, math.min(luck, 10) / entry.Item.Chance)
				assert(entry.Check == check and math.abs(entry.Probability - remaining * check) < 1e-14)
				assert(entry.Probability >= 0 and entry.Probability <= 1)
				remaining *= 1 - check
				total += entry.Probability
				rarities[entry.Item.Rarity] = (rarities[entry.Item.Rarity] or 0) + entry.Probability
				if luck >= 10 then
					assert(entry.Check == capped[i].Check and entry.Probability == capped[i].Probability)
				end
			end
			local rarityTotal = 0
			for _, probability in pairs(rarities) do
				rarityTotal += probability
			end
			assert(remaining == 0 and math.abs(total - 1) < 1e-12 and math.abs(rarityTotal - 1) < 1e-12)
		end
	end
	for _, invalid in ipairs({ 0, -1, 0 / 0, math.huge }) do
		assert(not pcall(roll.Distribution, items, toilets, 15, invalid))
	end
end)
