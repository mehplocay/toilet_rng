-- The runner reads the authoritative JSON independently of the production catalog.
test("wave1: JSON parity, rarity colors/order, pool membership and icon/template coverage", function()
	local e = environment()
	local items, toilets = e:Load("src/shared/Config/Items"), e:Load("src/shared/Config/Toilets")
	local rarities, assets = e:Load("src/shared/Config/Rarities"), e:Load("src/shared/Config/Assets")
	local passIconKeys = {
		"StarTag",
		"VIP",
		"VIPPack",
		"RainbowName",
		"ConfettiReveal",
		"GoldenName",
		"DancePack",
		"ToiletGlow",
		"Companion",
		"UltimateBundle",
		"CoinPackMini",
		"CoinPackSmall",
		"CoinPackLarge",
		"CoinPackHuge",
		"CoinPack",
		"LuckyFlush1",
		"LuckyFlush5",
		"LuckyFlush20",
		"DoubleCash",
		"DoubleLuck",
		"AutoCollect",
		"OfflinePlus",
		"PathBoost",
		"SparkleTrail",
		"CustomPlotColor",
		"FastFlush",
	}
	for _, key in ipairs(passIconKeys) do
		assert(assets.Icons[key]:match("^rbxassetid://%d+$") ~= nil, "Missing uploaded pass/product icon: " .. key)
	end
	assert(#passIconKeys == 26)
	local meshes = e:Load("src/shared/Config/MeshCatalog")
	local income = e:Load("src/shared/Config/Income")
	local byId = {}
	assert(#items == 47 and #toilets == 15)
	for _, item in ipairs(items) do
		byId[item.Id] = item
	end
	for tier, toilet in ipairs(toilets) do
		assert(toilet.Id == wave1Spec.Toilets[tier].Id)
		assert(toilet.Pool == nil)
		if tier > 7 then
			assert(toilet.Price == wave1Spec.Toilets[tier].Price)
			assert(
				assets.ToiletIcons[toilet.Id]:match("^rbxassetid://%d+$") ~= nil
					and meshes[toilet.Id].Folder == "Wave1Templates"
			)
		end
	end
	for _, expected in ipairs(wave1Spec.Items) do
		local item = assert(byId[expected.Id])
		for _, key in ipairs({ "Name", "Rarity", "Chance", "Value", "Event" }) do
			assert(item[key] == expected[key], item.Id .. "." .. key)
		end
		assert(income.RarityRates[item.Rarity] == expected.IncomePerSecond)
		if expected.New then
			assert(
				assets.ItemIcons[item.Id]:match("^rbxassetid://%d+$") ~= nil
					and meshes[item.Id].Folder == "Wave1Templates"
			)
		end
	end
	local count = 0
	for _ in pairs(rarities) do
		count += 1
	end
	assert(count == 9)
	for _, expected in ipairs(wave1Spec.Rarities) do
		local rarity = rarities[expected.Id]
		assert(rarity.Order == expected.Order)
		assert(math.abs(rarity.Color.R * 255 - expected.ColorRGB[1]) < 1e-6)
		assert(math.abs(rarity.Color.G * 255 - expected.ColorRGB[2]) < 1e-6)
		assert(math.abs(rarity.Color.B * 255 - expected.ColorRGB[3]) < 1e-6)
	end
end)

test("wave1: legacy profile migration preserves counts, retiered displays, tiers, rebirth and claims", function()
	local e = environment()
	local data = e:Load(dataPath)
	local raw = data.DefaultProfile()
	raw.ToiletTier, raw.RebirthLevel, raw.DisplaySlots = 7, 7, 10
	raw.Inventory = { KingPoop = 3, SewerShark = 2, AlienToilet = 1 }
	raw.Collection = { KingPoop = 8, SewerShark = 5, AlienToilet = 4 }
	raw.ProtectedInventory = { KingPoop = 2 }
	raw.Displays = { ["2"] = "KingPoop", ["7"] = "SewerShark", ["10"] = "AlienToilet" }
	raw.Stats.RarestItemId, raw.Stats.RarestChance = "AlienToilet", 1000000
	raw.IndexClaims = { ["rarity:Mythic"] = true, ["total:35"] = true, founding = true }
	raw.Stamps, raw.RunFlushes, raw.Coins = 71, 123, 987654
	local migrated = data.Sanitize(raw)
	assert(
		migrated.ToiletTier == 7
			and migrated.RebirthLevel == 7
			and migrated.RunFlushes == 123
			and migrated.Coins == 987654
	)
	assert(
		migrated.Stamps == 71
			and migrated.IndexClaims["rarity:Mythic"]
			and migrated.IndexCosmetics.FullIndexPlaque
			and migrated.IndexCosmetics.FoundingFlush
	)
	for id, count in pairs(raw.Inventory) do
		assert(migrated.Inventory[id] == count and migrated.Collection[id] == raw.Collection[id])
	end
	for slot, id in pairs(raw.Displays) do
		assert(migrated.Displays[slot] == id)
	end
	assert(migrated.ProtectedInventory.KingPoop == 2)
	for _, item in ipairs(wave1Spec.Items) do
		if item.New then
			assert(migrated.Inventory[item.Id] == 0 and migrated.Collection[item.Id] == 0)
		end
	end
	local items = e:Load("src/shared/Config/Items")
	local upgrades = e:Load("src/shared/UpgradeRules").new(e:Load("src/shared/Config/Upgrades"))
	local income = e:Load("src/shared/IncomeAccrual").new(e:Load("src/shared/Config/Income"), items, upgrades)
	local rates = income:Rates(migrated)
	assert(rates["2"] == rates["7"] and rates["10"] > rates["2"], "King Poop must resolve its new Godly rate")
	local stats = e:Load("src/shared/LeaderboardStats").new(items)
	assert(stats:Sanitize({ RarestItemId = "SewerShark", RarestChance = 25000 }).RarestChance == 50000)
	for tier = 1, 15 do
		raw.ToiletTier = tier
		assert(data.Sanitize(raw).ToiletTier == tier)
	end
	raw.ToiletTier = 999
	assert(data.Sanitize(raw).ToiletTier == 15)
	raw.ToiletTier = 0
	assert(data.Sanitize(raw).ToiletTier == 1)
	local again = data.Sanitize(migrated)
	assert(again.Stamps == 71 and again.Displays["2"] == "KingPoop" and again.RebirthLevel == 7)
end)

test("wave1: legacy save/rejoin settles retiered displays once and persists new late-tier items", function()
	local e = server()
	local raw = e.Data.DefaultProfile()
	raw.ToiletTier, raw.RebirthLevel, raw.DisplaySlots = 7, 7, 10
	raw.Inventory, raw.Collection = { KingPoop = 2, SewerShark = 3 }, { KingPoop = 5, SewerShark = 9 }
	raw.Displays = { ["1"] = "KingPoop", ["10"] = "SewerShark" }
	raw.Income = { UpdatedAt = e.Now - 60, Pending = { ["1"] = 1234 } }
	e.Store.Records.Player_970 = { Data = raw }
	local player, p = e:Join(970)
	assert(p.ToiletTier == 7 and p.RebirthLevel == 7 and p.Collection.SewerShark == 9)
	assert(p.Income.Pending["1"] == 53352000000 + 1234)
	assert(p.Income.Pending["10"] == 53352000000)
	assert(p.Inventory.HaloHamster == 0 and p.Collection.CosmicCourtesy == 0)
	e.Data:Close(player)
	local joined, restored = e:Join(970)
	assert(restored.Income.Pending["1"] == p.Income.Pending["1"], "Offline income replayed")
	restored.ToiletTier, restored.Inventory.HaloHamster, restored.Collection.HaloHamster = 15, 2, 4
	restored.Displays["2"] = "HaloHamster"
	e.Data:Close(joined)
	e.Now += 60
	local _, late = e:Join(970)
	assert(late.ToiletTier == 15 and late.RebirthLevel == 7 and late.Inventory.HaloHamster == 2)
	assert(late.Displays["2"] == "HaloHamster" and late.Collection.HaloHamster == 4)
	assert(late.Income.Pending["2"] == 8336250000000)
end)

test("wave1: complete index grants Celestial and new plaque once without re-awarding legacy claims", function()
	local e = environment()
	local data = e:Load(dataPath)
	local p = data.DefaultProfile()
	local items = e:Load("src/shared/Config/Items")
	local index = e:Load("src/shared/IndexProgress").new(items, e:Load("src/shared/Config/IndexRewards"))
	for _, item in ipairs(items) do
		p.Collection[item.Id] = 1
	end
	p.IndexClaims["rarity:Mythic"], p.IndexClaims["total:35"] = true, true
	local count, groups = index:Progress(p)
	assert(count == 47 and groups.Celestial.Total == 4 and groups.Godly.Total == 6 and groups.Secret.Total == 6)
	assert(not index:Claim(p, "rarity:Mythic").Success and not index:Claim(p, "total:35").Success)
	assert(index:Claim(p, "rarity:Celestial").Success and p.Stamps == 22)
	assert(index:Claim(p, "total:47").Success and p.IndexCosmetics.WaveOneComplete)
	local migrated = data.Sanitize(p)
	assert(not index:Claim(migrated, "rarity:Celestial").Success and not index:Claim(migrated, "total:47").Success)
	assert(migrated.Stamps == 22 and migrated.IndexCosmetics.WaveOneComplete)
end)

test("wave1: every item supports authorized admin forced drops and all fifteen toilet tiers", function()
	local e = adminFixture()
	local player = e:JoinAdmin()
	for _, item in ipairs(e:Load("src/shared/Config/Items")) do
		e:Advance()
		e:Command(player, "ForceDrop", { ItemId = item.Id })
		assert(e:Last().Success, item.Id)
		assert(e.Data:Get(player).Inventory[item.Id] == 1)
	end
	assert(e.Runtime.Forced == 47)
	for tier = 1, 15 do
		e:Advance()
		e:Command(player, "Toilet", { Level = tier })
		assert(e:Last().Success and e.Data:Get(player).ToiletTier == tier)
	end
	e:Advance()
	e:Command(player, "Toilet", { Level = 16 })
	assert(e.Data:Get(player).ToiletTier == 15)
end)

test("wave1: Celestial announcement, audio reuse and nine-tier rarity ranking", function()
	local e = environment()
	local items = e:Load("src/shared/Config/Items")
	local rules = e:Load("src/shared/PresentationRules")
	assert(rules.Audience("Celestial") == "Server" and rules.Tier("Celestial", "Full") == "Cinematic")
	local assets, audio = e:Load("src/shared/Config/Assets"), e:Load("src/shared/Config/Audio")
	assert(assets.Sounds.Celestial == assets.Sounds.Godly)
	for key, value in pairs(audio.Cues.Godly) do
		assert(audio.Cues.Celestial[key] == value)
	end
	local stats = e:Load("src/shared/LeaderboardStats").new(items)
	local rows = stats:Rank({
		{ Name = "Godly", UserId = 1, Profile = { Stats = { RarestItemId = "PlungerPaladin" } } },
		{ Name = "Celestial", UserId = 2, Profile = { Stats = { RarestItemId = "StarlightSeraph" } } },
		{ Name = "Secret", UserId = 3, Profile = { Stats = { RarestItemId = "AlienToilet" } } },
	}, "Rarest")
	assert(rows[1].UserId == 3 and rows[2].UserId == 2 and rows[3].UserId == 1)
end)
