local Items = require("../src/shared/Config/Items")
local Stats = require("../src/shared/LeaderboardStats").new(Items)
for _, value in ipairs({ false, "0", -1, math.huge, 0 / 0, 2e300 }) do
	local result = Stats:Sanitize({ Flushes = value, Earned = value, RarestChance = value, RarestItemId = value })
	assert(result.Flushes == 0 and result.Earned == 0 and result.RarestChance == 0 and result.RarestItemId == "")
end
local item = Items[#Items]
local restored = Stats:Sanitize({ Flushes = 12.9, Earned = 8, RarestItemId = item.Id, RarestChance = 9e15 })
assert(restored.Flushes == 12 and restored.RarestChance == item.Chance)
local profile = { Stats = Stats:Sanitize(nil), Coins = 100 }
assert(Stats:Record(profile, item))
assert(profile.Stats.RarestItemId == item.Id and profile.Stats.Flushes == 1)
assert(Stats:Record(profile, Items[1]) and profile.Stats.RarestItemId == item.Id)
local spoof = table.clone(item)
assert(not Stats:Record(profile, spoof) and profile.Stats.Flushes == 2)
local entries = {
	{ Name = "<b>A</b>", UserId = 3, Profile = profile },
	{ Name = "B", UserId = 1, Profile = { Coins = 100, Stats = { Flushes = 500 } } },
}
assert(Stats:Rank(entries, "Coins")[1].UserId == 1)
assert(Stats:Rank(entries, "Rarest")[1].UserId == 3)
assert(Stats:Rank(entries, "Flushes")[1].UserId == 1)
assert(#Stats:Rank({}, "Coins") == 0)
print(
	"Leaderboard checks passed: finite bounds, migration, known-item rarity, forged definitions, ties, three ranking fields and empty server"
)
