local Roll = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Limiter = require("../src/server/Services/RateLimiter")
local Remotes = require("../src/shared/Config/Remotes")

assert(#Items == 11 and #Toilets == 7)
for tier = 1, #Toilets do
	local entries, empty = Roll.Distribution(Items, Toilets, tier, 1)
	local total = empty
	for _, entry in ipairs(entries) do
		assert(entry.Probability == 1 / entry.Item.Chance)
		total += entry.Probability
	end
	assert(math.abs(total - 1) < 1e-12)
	assert(Roll.Sample(entries, 0).Id == "Poop")
	assert(Roll.Sample(entries, 0.99999999) == nil)
end
local basic = Roll.Distribution(Items, Toilets, 1)
assert(#basic == 4)
local boosted, empty = Roll.Distribution(Items, Toilets, 7, 2)
assert(boosted[1].Probability == 0.5 and boosted[2].Probability == 0.25)
assert(empty > 0)
local saturated, saturatedEmpty = Roll.Distribution(Items, Toilets, 7, 100)
local total = saturatedEmpty
for _, entry in ipairs(saturated) do
	total += entry.Probability
end
assert(saturatedEmpty == 0 and math.abs(total - 1) < 1e-12)
assert(not pcall(Roll.Distribution, Items, Toilets, 0))
assert(not pcall(Roll.Distribution, Items, Toilets, 7, 0 / 0))
assert(not pcall(Roll.Sample, basic, 1))
local limiter = Limiter.new(Remotes.Limits)
local player = {}
assert(limiter:Allow(player, "Flush"))
assert(limiter:Allow(player, "Flush"))
assert(not limiter:Allow(player, "Flush"))
assert(not limiter:Allow(player, "Unknown"))
assert(limiter:Allow({}, "Flush"))
limiter:Remove(player)
assert(limiter.Players[player] == nil)
print("Foundation checks passed: config, probabilities, pools, luck, boundaries, rate limits")
