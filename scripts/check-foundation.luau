local Roll = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Limiter = require("../src/server/Services/RateLimiter")
local Remotes = require("../src/shared/Config/Remotes")
for tier = 1, #Toilets do
	local entries, empty = Roll.Distribution(Items, Toilets, tier, 1)
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.Probability
	end
	assert(empty == 0 and math.abs(total - 1) < 1e-12)
	assert(entries[#entries].Item.Id == "Poop")
	assert(Roll.Sample(entries, 0.99999999).Id == "Poop")
	for _ = 1, 1000 do
		assert(Roll.Sample(entries, math.random))
	end
end
assert(#Roll.Distribution(Items, Toilets, 1) == 4)
assert(#Roll.Distribution(Items, Toilets, 5) == 9)
assert(#Roll.Distribution(Items, Toilets, 6) == 10)
assert(Roll.Roll(Items, Toilets, 7, function()
	return 0
end).Id == "Mystery")
assert(Roll.Roll(Items, Toilets, 7, function()
	return 0.99
end).Id == "Poop")
assert(not pcall(Roll.Distribution, Items, Toilets, 0))
assert(not pcall(Roll.Distribution, Items, Toilets, 7, 0 / 0))
local limiter = Limiter.new(Remotes.Limits)
local player = {}
assert(limiter:Allow(player, "Flush"))
assert(limiter:Allow(player, "Flush"))
assert(not limiter:Allow(player, "Flush"))
assert(not limiter:Allow(player, "Unknown"))
limiter:Remove(player)
assert(limiter.Players[player] == nil)
print("Foundation checks passed: guaranteed drops, rare-first pools, luck, rate limits")
