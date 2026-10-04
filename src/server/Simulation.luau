local Simulation = {}

function Simulation.Run(rollService, items, toilets, nextNumber, iterations, tier, luck)
	iterations = iterations or 1000000
	tier = tier or #toilets
	luck = luck or 1
	local entries, emptyProbability = rollService.Distribution(items, toilets, tier, luck)
	local counts = {}
	for _ = 1, iterations do
		local item = rollService.Sample(entries, nextNumber)
		local id = if item then item.Id else "NoDrop"
		counts[id] = (counts[id] or 0) + 1
	end
	print(string.format("%d rolls; tier %d; luck %.2f", iterations, tier, luck))
	for _, entry in ipairs(entries) do
		local count = counts[entry.Item.Id] or 0
		print(
			string.format(
				"%s | GDD 1/%d | target %.9f | observed %.9f | count %d | expected %.2f",
				entry.Item.Name,
				entry.Item.Chance,
				entry.Probability,
				count / iterations,
				count,
				entry.Probability * iterations
			)
		)
	end
	print(string.format("NoDrop | target %.9f | observed %.9f", emptyProbability, (counts.NoDrop or 0) / iterations))
	return counts
end

return Simulation
