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
local Events = require("../src/server/Services/EventService")
local Config = require("../src/shared/Config/Events")
local now, broadcasts, updates = 100, 0, 0
local event = Events.new(Config, function()
	return now
end, function()
	broadcasts += 1
end, function()
	updates += 1
end)
local owner = { DisplayName = "Tester" }
assert(event:Multiplier() == 1)
assert(not event:Trigger(owner, Items[1], 1))
assert(event:Trigger(owner, Items[9], 2))
assert(event.Expires == 400 and event:Multiplier() == 2 and broadcasts == 1)
assert(not event:Trigger(owner, Items[9], 2))
now = 101
assert(event:Trigger(owner, Items[10], 3))
assert(event.Expires == 401 and broadcasts == 1 and updates == 2)
now = 109
assert(event:Trigger(owner, Items[11], 4))
assert(broadcasts == 2 and event:Multiplier() == 2)
now = 117
event:Drain()
assert(broadcasts == 3 and #event.Pending == 0)
assert(not event:Trigger(owner, Items[9], 2))
local base = Roll.Distribution(Items, Toilets, 7, Toilets[7].Luck)
local boosted = Roll.Distribution(Items, Toilets, 7, Toilets[7].Luck * event:Multiplier() * 2)
assert(math.abs(boosted[1].Check - 5.1 / Items[11].Chance) < 1e-12)
assert(Roll.Sample(boosted, function()
	return 0.999999
end).Id == "Poop")
now = event.Expires
assert(event:Multiplier() == 1)
event:Remove(owner)
assert(event.Seen[owner] == nil)
print("Event checks passed: dedupe, cooldown, refresh, expiry, multiplicative luck and fallback")
