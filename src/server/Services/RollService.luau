local RollService = {}
function RollService.Distribution(items, toilets, tier, luckOverride)
	assert(toilets[tier], "Invalid toilet tier")
	local luck = luckOverride or toilets[tier].Luck
	assert(luck >= 1 and luck < math.huge, "Invalid luck")
	local pool, sorted = {}, {}
	for index = 1, tier do
		for _, id in ipairs(toilets[index].Pool) do
			pool[id] = true
		end
	end
	for _, item in ipairs(items) do
		if pool[item.Id] then
			table.insert(sorted, item)
		end
	end
	table.sort(sorted, function(a, b)
		return a.Chance > b.Chance
	end)
	local entries, remaining = {}, 1
	for _, item in ipairs(sorted) do
		local chance = if item.Id == "Poop" then 1 else math.min(1, luck / item.Chance)
		table.insert(entries, { Item = item, Check = chance, Probability = remaining * chance })
		remaining *= 1 - chance
	end
	assert(#entries > 0 and entries[#entries].Item.Id == "Poop", "Pool requires Poop")
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
		local cumulative = 0
		for _, entry in ipairs(entries) do
			cumulative += entry.Probability
			if sample < cumulative then
				return entry.Item
			end
		end
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
