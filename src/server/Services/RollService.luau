local Luck = require(if script then game.ReplicatedStorage.Shared.Config.Upgrades else "../../shared/Config/Upgrades")
local RollService = {}
function RollService.Distribution(items, toilets, tier, luckOverride)
	assert(toilets[tier], "Invalid toilet tier")
	local luck = luckOverride or toilets[tier].Luck
	assert(luck >= 1 and luck < math.huge, "Invalid luck")
	luck = math.min(luck, Luck.LuckCap)
	-- Every toilet uses the complete catalog; tier changes luck, never eligibility.
	local sorted = table.clone(items)
	table.sort(sorted, function(a, b)
		return if a.Id == "Poop"
			then false
			elseif b.Id == "Poop" then true
			elseif a.Chance == b.Chance then a.Id < b.Id
			else a.Chance > b.Chance
	end)
	local entries, remaining, cumulative = {}, 1, 0
	for _, item in ipairs(sorted) do
		local chance = if item.Id == "Poop" then 1 else math.min(1, luck / item.Chance)
		local probability = remaining * chance
		cumulative += probability
		table.insert(entries, { Item = item, Check = chance, Probability = probability, Cumulative = cumulative })
		remaining *= 1 - chance
	end
	assert(#entries > 0 and entries[#entries].Item.Id == "Poop", "Catalog requires Poop")
	return entries, 0
end
function RollService.Sample(entries, sample)
	-- Callbacks make independent checks; numeric samples use the equivalent distribution.
	if type(sample) == "function" then
		for _, entry in ipairs(entries) do
			local value = sample()
			assert(value >= 0 and value < 1, "Invalid random sample")
			if value < entry.Check then
				return entry.Item
			end
		end
	else
		assert(sample >= 0 and sample < 1, "Invalid random sample")
		-- Equivalent numeric sampling for long balance cohorts, using the same ordered sums.
		local low, high = 1, #entries
		while low < high do
			local middle = math.floor((low + high) / 2)
			if sample < entries[middle].Cumulative then
				high = middle
			else
				low = middle + 1
			end
		end
		return entries[low].Item
	end
	return entries[#entries].Item
end
function RollService.Roll(items, toilets, tier, sample, luckOverride)
	local entries = RollService.Distribution(items, toilets, tier, luckOverride)
	local item = RollService.Sample(entries, sample)
	for _, entry in ipairs(entries) do
		if entry.Item == item then
			return item, entry.Probability
		end
	end
	return item
end
return RollService
