local Spec = require("./wave1-contract")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Income = require("../src/shared/Config/Income")
local Upgrades = require("../src/shared/Config/Upgrades")
local Roll = require("../src/server/Services/RollService")
local IndexConfig = require("../src/shared/Config/IndexRewards")
local Index = require("../src/shared/IndexProgress").new(Items, IndexConfig)
assert(#Items == 47 and #Toilets == 15 and #IndexConfig.RarityOrder == 9)
local byId, bands, first, counts = {}, {}, {}, {}
for order, rarity in ipairs(Spec.Rarities) do
	assert(IndexConfig.RarityOrder[order] == rarity.Id)
	assert(Income.RarityRates[rarity.Id] == rarity.IncomePerSecond)
	assert(IndexConfig.RarityStamps[rarity.Id] == rarity.IndexStamps)
	bands[rarity.Id] = rarity
	if order > 1 then
		assert(Spec.Rarities[order - 1].MaxChance < rarity.MinChance)
	end
end
for _, item in ipairs(Items) do
	assert(not byId[item.Id], "Duplicate item ID")
	byId[item.Id] = item
	local band = assert(bands[item.Rarity])
	assert(item.Chance >= band.MinChance and item.Chance <= (band.MaxChance or math.huge))
	counts[item.Rarity] = (counts[item.Rarity] or 0) + 1
end
for tier, toilet in ipairs(Toilets) do
	local spec = Spec.Toilets[tier]
	assert(toilet.Id == spec.Id and toilet.Name == spec.Name)
	assert(#toilet.Pool == #spec.Pool)
	for index, id in ipairs(toilet.Pool) do
		assert(id == spec.Pool[index] and byId[id] and not first[id], "Invalid pool addition")
		first[id] = tier
	end
	assert(Income.TierMultipliers[tier] and Income.SlotRateCaps[tier] and Income.PlayerRateCaps[tier])
	if tier > 7 then
		assert(toilet.Price == spec.Price and toilet.ServiceCoins == spec.ServiceCoins)
		assert(
			math.abs(toilet.Cooldown - math.max(Upgrades.CooldownFloor, Toilets[7].Cooldown * spec.Cooldown / 0.8))
				< 1e-12
		)
		assert(math.abs(toilet.Luck - math.min(Upgrades.LuckCap, Toilets[7].Luck * spec.Luck / 1.3)) < 1e-12)
		assert(math.abs(Income.TierMultipliers[tier] - Income.TierMultipliers[7] * spec.IncomeMultiplier / 12) < 1e-10)
	end
	for _, luck in ipairs({ 1, 5, 10, 1000 }) do
		local entries, remaining = Roll.Distribution(Items, Toilets, tier, luck)
		local mass, product = 0, 1
		for i, entry in ipairs(entries) do
			local item = entry.Item
			if luck == 1 then
				assert(entry.Probability > 0, "Unreachable at base luck: " .. item.Id)
			end
			local effective = math.min(Upgrades.LuckCap, luck)
			if item.Chance > Upgrades.RareLuckThreshold then
				effective = math.min(effective, Upgrades.FullLuck)
					+ math.max(0, effective - Upgrades.FullLuck) * Upgrades.RareLuckScale
			end
			local check = if item.Id == "Poop" then 1 else math.min(1, effective / item.Chance)
			assert(math.abs(entry.Probability - product * check) < 1e-14)
			product *= 1 - check
			mass += entry.Probability
			if i > 1 and item.Id ~= "Poop" then
				assert(entries[i - 1].Item.Chance >= item.Chance)
			end
		end
		assert(math.abs(mass - 1) < 1e-12 and remaining == 0 and product == 0)
		assert(entries[#entries].Item.Id == "Poop")
		for _, sample in ipairs({ 0, 0.2, 0.5, 0.999999999999 }) do
			assert(byId[Roll.Sample(entries, sample).Id])
			assert(byId[Roll.Sample(entries, function()
				return sample
			end).Id])
		end
	end
end
for _, expected in ipairs(Spec.Items) do
	local item = assert(byId[expected.Id])
	for _, field in ipairs({ "Name", "Rarity", "Chance", "Value", "Event" }) do
		assert(item[field] == expected[field], expected.Id .. "." .. field)
	end
	assert(first[item.Id] == expected.FirstToiletTier, "Unreachable/wrong unlock: " .. item.Id)
end
for rarity, count in pairs(counts) do
	assert(Index.ById["rarity:" .. rarity].Required == count)
end
assert(Index.ById["rarity:Celestial"].Stamps == 22)
assert(Index.ById["total:35"].Cosmetic == "FullIndexPlaque")
assert(Index.ById["total:47"].Cosmetic == "WaveOneComplete")
assert(require("../src/shared/PresentationRules").Audience("Celestial") == "Server")
assert(require("../src/shared/PresentationRules").Tier("Celestial", "Full") == "Cinematic")
print(
	"Wave 1 contract passed: 47 exact items, 15 cumulative pools, 9 disjoint bands, 60 capped probability distributions, guaranteed drops and stable index claims"
)
return true
