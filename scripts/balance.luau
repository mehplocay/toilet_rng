local RollService = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")

local targets = { 1, 4, 10, 25, 60, 120 }
local expectedValues = {}
for tier, toilet in ipairs(Toilets) do
	local entries = RollService.Distribution(Items, Toilets, tier, toilet.Luck)
	local expected = 0
	for _, entry in ipairs(entries) do
		expected += entry.Probability * entry.Item.Value
	end
	expectedValues[tier] = expected
	local nextToilet = Toilets[tier + 1]
	if nextToilet then
		local minutes = nextToilet.Price / expected * toilet.Cooldown / 60
		print(
			string.format(
				"%-12s %10.2f coins/flush %8.2f min to %-12s (%d coins)",
				toilet.Id,
				expected,
				minutes,
				nextToilet.Id,
				nextToilet.Price
			)
		)
		assert(
			math.abs(minutes - targets[tier]) <= targets[tier] * 0.02,
			"Upgrade time outside 2% target for " .. nextToilet.Id
		)
	else
		print(string.format("%-12s %10.2f coins/flush", toilet.Id, expected))
	end
end
