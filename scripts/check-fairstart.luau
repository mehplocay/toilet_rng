local ServiceCoins = require("../src/server/Services/ServiceCoinService")
local Roll = require("../src/server/Services/RollService")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")

local expectedAwards = { 1, 3, 7, 15, 30, 65, 140 }
for tier, toilet in ipairs(Toilets) do
	assert(toilet.ServiceCoins == expectedAwards[tier], "Service award differs from the progression design")
	local profile = { Coins = 10, Stats = { Earned = 20 }, Inventory = { Poop = 1 } }
	for _, luck in ipairs({ toilet.Luck, toilet.Luck * 4 }) do
		-- Both an unlucky fallback and a boosted rare result earn exactly the tier award.
		for _, sample in ipairs({ 0, 0.999999999 }) do
			local item = Roll.Roll(Items, Toilets, tier, function()
				return sample
			end, luck)
			assert(item and (sample == 0 or item.Id == "Poop"))
			local before, earned = profile.Coins, profile.Stats.Earned
			assert(ServiceCoins.Grant(profile, toilet) == expectedAwards[tier])
			assert(profile.Coins == before + expectedAwards[tier])
			assert(profile.Stats.Earned == earned + expectedAwards[tier])
			assert(profile.Inventory.Poop == 1) -- Currency grant does not alter items.
		end
	end
	local full = { Coins = 9e15, Stats = { Earned = 0 } }
	assert(ServiceCoins.Grant(full, toilet) == nil and full.Coins == 9e15 and full.Stats.Earned == 0)
	local earnedFull = { Coins = 0, Stats = { Earned = 9e15 } }
	assert(ServiceCoins.Grant(earnedFull, toilet) == nil and earnedFull.Coins == 0 and earnedFull.Stats.Earned == 9e15)
	local boundary = { Coins = 9e15 - toilet.ServiceCoins, Stats = { Earned = 9e15 - toilet.ServiceCoins } }
	assert(ServiceCoins.Grant(boundary, toilet) == toilet.ServiceCoins)
	assert(boundary.Coins == 9e15 and boundary.Stats.Earned == 9e15)
end
for _, invalid in ipairs({ 0, -1, 1.5, math.huge, 0 / 0, "1" }) do
	local profile = { Coins = 0, Stats = { Earned = 0 } }
	assert(not pcall(ServiceCoins.Grant, profile, { ServiceCoins = invalid }))
	assert(profile.Coins == 0 and profile.Stats.Earned == 0)
end

-- Buy all first four upgrades using only service income, retaining every fallback item.
local profile = { Coins = 0, Stats = { Earned = 0, Flushes = 0 }, Inventory = {}, Collection = {} }
local minutes = 0
for tier = 1, 4 do
	local toilet, price = Toilets[tier], Toilets[tier + 1].Price
	local before = profile.Stats.Flushes
	local limit = math.ceil(price / toilet.ServiceCoins)
	while profile.Coins < price do
		local item = Roll.Roll(Items, Toilets, tier, function()
			return 0.999999999
		end)
		assert(item.Id == "Poop")
		assert(ServiceCoins.Grant(profile, toilet) == toilet.ServiceCoins)
		profile.Stats.Flushes += 1
		profile.Inventory[item.Id] = (profile.Inventory[item.Id] or 0) + 1
		profile.Collection[item.Id] = (profile.Collection[item.Id] or 0) + 1
		minutes += toilet.Cooldown / 60 / 0.75
		assert(profile.Stats.Flushes - before <= limit, "Service-only progression failed to reach the next upgrade")
	end
	profile.Coins -= price
	assert(profile.Coins >= 0)
end
assert(minutes <= 95)
assert(profile.Inventory.Poop == profile.Stats.Flushes and profile.Collection.Poop == profile.Stats.Flushes)
assert(
	profile.Stats.Earned == profile.Coins + Toilets[2].Price + Toilets[3].Price + Toilets[4].Price + Toilets[5].Price
)
print(
	"Fair start checks passed: fixed tier awards, luck independence, currency accounting, bounds and four upgrades without sales"
)
