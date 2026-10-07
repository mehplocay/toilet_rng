local Roll = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
for tier = 1, #Toilets do
	for _, luck in ipairs({ Toilets[tier].Luck, 1, 5, 10, 1000 }) do
		local entries = Roll.Distribution(Items, Toilets, tier, luck)
		assert(#entries == 47)
		local function linear(sample)
			local sum = 0
			for _, entry in ipairs(entries) do
				sum += entry.Probability
				if sample < sum then
					return entry.Item.Id
				end
			end
			return entries[#entries].Item.Id
		end
		for _, entry in ipairs(entries) do
			for _, delta in ipairs({ -1e-15, 0, 1e-15 }) do
				local sample = math.clamp(entry.Cumulative + delta, 0, 1 - 1e-15)
				assert(Roll.Sample(entries, sample).Id == linear(sample), "Numeric sampler changed a boundary")
			end
		end
		for i = 0, 1000 do
			local sample = i / 1001
			assert(Roll.Sample(entries, sample).Id == linear(sample))
		end
	end
end
print("All-pools numeric sampler: exact linear-scan equivalence at every boundary, all tiers and five luck settings")
