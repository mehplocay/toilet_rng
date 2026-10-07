-- Actual outcome expectations, not inverse independent checks.
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Rarities = require("../src/shared/Config/IndexRewards").RarityOrder
local Roll = require("../src/server/Services/RollService")
local rarest = {}
for _, item in ipairs(Items) do
	if not rarest[item.Rarity] or item.Chance > rarest[item.Rarity].Chance then
		rarest[item.Rarity] = item
	end
end
print("Unboosted toilet luck only; mean flushes to each named item's actual outcome (1 / probability).")
print("Common | Uncommon | Rare | Epic | Legendary | Mythic | Godly | Celestial | Secret")
for _, rarity in ipairs(Rarities) do
	print(rarity .. ": " .. rarest[rarity].Name .. " (base check 1/" .. rarest[rarity].Chance .. ")")
end
print("| Toilet | Luck | Common | Uncommon | Rare | Epic | Legendary | Mythic | Godly | Celestial | Secret |")
print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
for tier, toilet in ipairs(Toilets) do
	local byId = {}
	for _, entry in ipairs(Roll.Distribution(Items, Toilets, tier)) do
		byId[entry.Item.Id] = entry.Probability
	end
	local cells = { toilet.Name, tostring(toilet.Luck) .. "x" }
	for _, rarity in ipairs(Rarities) do
		table.insert(cells, string.format("%.2f", 1 / byId[rarest[rarity].Id]))
	end
	print("| " .. table.concat(cells, " | ") .. " |")
end
print("Basic at 1x, 300 flushes (10 minutes at 75% uptime): chance of at least one outcome in each rarity.")
local sums = {}
for _, entry in ipairs(Roll.Distribution(Items, Toilets, 1, 1)) do
	sums[entry.Item.Rarity] = (sums[entry.Item.Rarity] or 0) + entry.Probability
end
for _, rarity in ipairs(Rarities) do
	print(rarity, string.format("%.8f%%", 100 * (1 - (1 - sums[rarity]) ^ 300)))
end
print("Cosmic Courtesy in 300 Basic flushes:", 100 * (1 - (1 - 1 / 15000000) ^ 300), "%")
