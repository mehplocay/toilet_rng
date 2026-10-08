local Rules = require("../src/shared/SocialBoostRules")
local Config = require("../src/shared/Config/SocialBoosts")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Income = require("../src/shared/IncomeAccrual").new(
	require("../src/shared/Config/Income"),
	require("../src/shared/Config/Items"),
	U
)
local function profile()
	return {
		Social = Rules.Sanitize(nil, 1000),
		Upgrades = U:Sanitize(nil),
		RebirthLevel = 0,
		Monetization = { Passes = {} },
		ToiletTier = 1,
		DisplaySlots = 1,
		Displays = { ["1"] = "Poop" },
		Income = { UpdatedAt = 1000, Pending = {} },
		Coins = 0,
		Stats = { Earned = 0 },
	}
end
local p = profile()
assert(Rules.Multiplier(p, 1000) == 1 and U:Cash(p) == 1)
assert(not Rules.GroupResult(false, true) and not Rules.GroupResult(true, "true") and Rules.GroupResult(true, true))
p.SocialRuntime = { GroupMember = true, FriendCount = 3 }
p.Social.InviteExpires = os.time() + Config.InviteSeconds
assert(math.abs(U:Cash(p) - 1.265) < 1e-12)
p.Monetization.Passes.DoubleCash, p.Monetization.Passes.VIPPack = true, true
assert(math.abs(U:Cash(p) - 3.795) < 1e-12)
assert(U:Luck(p, 1) == 1.2 and U:Cooldown(p, 3) == 3)
local originalCapacity = Income:StorageUnits(p, false)
p.SocialRuntime, p.Social.InviteExpires = nil, 0
assert(Income:StorageUnits(p, false) == originalCapacity)
for _, value in ipairs({ -1, math.huge, 0 / 0, "yes", {} }) do
	local safe = Rules.Sanitize({ InviteExpires = value, Day = value, DailyCount = value }, 1000)
	assert(safe.InviteExpires == 0 and safe.Day == 0)
end
assert(Rules.Sanitize({ InviteExpires = 30000000000 }, 1000).InviteExpires == 1000 + Config.InviteMaxSeconds)
assert(Rules.Sanitize({ Rewarded = { 1, 1 } }, 1000).HistoryFull)
assert(Rules.Sanitize({ Rewarded = { ["oops"] = 1 } }, 1000).HistoryFull)
assert(Rules.Sanitize({ Rewarded = "corrupt" }, 1000).HistoryFull)
assert(Rules.Sanitize({ Version = Config.Version }, 1000).HistoryFull)
local large = {}
for i = 1, Config.InviteHistoryLimit + 1 do
	large[i] = i
end
local safe = Rules.Sanitize({ Rewarded = large }, 1000)
assert(safe.HistoryFull and #safe.Rewarded <= Config.InviteHistoryLimit)
p = profile()
assert(Rules.Referrer({ LaunchData = "123" }, 1) == nil)
assert(Rules.Referrer({ ReferredByPlayerId = 1 }, 1) == nil)
assert(Rules.Referrer({ ReferredByPlayerId = 2 }, 1) == 2)
local candidate = { Referrer = 2, JoinedAt = 1000, Flushes = 19 }
assert(not Rules.Qualified(candidate, 1300))
candidate.Flushes = 20
assert(not Rules.Qualified(candidate, 1299) and Rules.Qualified(candidate, 1300))
for id = 2, 6 do
	assert(Rules.Award(p, 1, id, 1300))
end
assert(p.Social.InviteExpires == 1300 + Config.InviteSeconds * 5)
assert(not Rules.Award(p, 1, 7, 1300))
assert(not Rules.Award(p, 1, 2, 86400))
assert(Rules.Award(p, 1, 7, 86400))
assert(not Rules.Award(p, 1, 1, 86400))
assert(Rules.Luck(p, p.Social.InviteExpires) == 1)
p = profile()
p.Social.InviteExpires = 1050
assert(Rules.Luck(p, 1049) == 1.2 and Rules.Luck(p, 1050) == 1)
local baseline = profile()
Income:Settle(baseline, 1100, false)
Income:Settle(p, 1100, false)
assert(p.Income.Pending["1"] == baseline.Income.Pending["1"])
for _, expires in ipairs({ 0, 1050, 2000 }) do
	p = profile()
	p.Social.InviteExpires = expires
	Income:Settle(p, 1100, true)
	local offline = profile()
	Income:Settle(offline, 1100, true)
	assert(p.Income.Pending["1"] == offline.Income.Pending["1"])
end
p = profile()
p.SocialRuntime = { GroupMember = true, FriendCount = 11 }
assert(Rules.Base(p, true) == 1, "Offline time cannot retain in-server friends or cached group status")
print(
	"Social rules: separate coin/luck stacking, unaffected speed/offline coins, migration, corruption, bounded history, daily limits, duplicate referrals and interval expiry passed"
)

p = profile()
p.Social.InviteExpires = os.time() + Config.InviteSeconds
assert(U:Luck(p, 1, 1e300) == 1.2e300, "Invite luck must preserve finite uncapped products")
assert(not pcall(U.Luck, U, p, 1, 1e308, 10), "Reject true overflow instead of clipping luck")
