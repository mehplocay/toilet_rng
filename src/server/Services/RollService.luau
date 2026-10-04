-- Pure, portable functions: caller supplies config and a uniform sample in [0, 1).
local RollService = {}

function RollService.Distribution(items, toilets, tier, luckOverride)
	assert(toilets[tier], "Invalid toilet tier")
	local luck = luckOverride or toilets[tier].Luck
	assert(luck >= 1 and luck < math.huge, "Invalid luck")
	local pool = {}
	for index = 1, tier do
		for _, id in ipairs(toilets[index].Pool) do
			pool[id] = true
		end
	end
	local entries, total = {}, 0
	for _, item in ipairs(items) do
		if pool[item.Id] then
			local weight = (if item.Rarity == "Common" then 1 else luck) / item.Chance
			total += weight
			table.insert(entries, { Item = item, Probability = weight })
		end
	end
	-- Preserve exact 1/X at luck 1; normalize only if boosts exceed total mass 1.
	local divisor = math.max(1, total)
	for _, entry in ipairs(entries) do
		entry.Probability /= divisor
	end
	return entries, math.max(0, 1 - total)
end

function RollService.Sample(entries, sample)
	assert(sample >= 0 and sample < 1, "Invalid random sample")
	local cumulative = 0
	for _, entry in ipairs(entries) do
		cumulative += entry.Probability
		if sample < cumulative then
			return entry.Item
		end
	end
	return nil
end

function RollService.Roll(items, toilets, tier, sample, luckOverride)
	local entries = RollService.Distribution(items, toilets, tier, luckOverride)
	return RollService.Sample(entries, sample)
end

return RollService
