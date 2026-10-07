local Config = require("../src/shared/Config/SocialBoosts")
local Rules = require("../src/shared/SocialBoostRules")
local U = require("../src/shared/UpgradeRules").new(require("../src/shared/Config/Upgrades"))
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Income = require("../src/shared/IncomeAccrual").new(require("../src/shared/Config/Income"), Items, U)
local p = {
	Upgrades = U:Sanitize(nil),
	RebirthLevel = 0,
	Monetization = { Passes = {} },
	Social = Rules.Sanitize(nil),
	DisplaySlots = 1,
	Displays = { ["1"] = "Poop" },
}
print("SOCIAL BOOSTS: fixed loadout, unchanged base economy; continuous rates before whole-coin rounding")
print("Scenario | Free social factor | Relative coin-gated time (fixed rates)")
for _, row in ipairs({
	{ "Typical", false, 0, false },
	{ "Group", true, 0, false },
	{ "3 friends", false, 3, false },
	{ "Group + 3 friends + active invite", true, 3, true },
	{ "Group + 11 friends + active invite", true, 11, true },
}) do
	p.SocialRuntime = { GroupMember = row[2], FriendCount = row[3] }
	p.Social.InviteExpires = if row[4] then os.time() + Config.InviteSeconds else 0
	local factor = U:Cash(p)
	print(string.format("%s | %.3fx | %.2f%%", row[1], factor, 100 / factor))
end
print("Tier | Typical single Poop display coins/min | Group + 3 friends + active invite coins/min")
for _, tier in ipairs({ 1, 4, 7, #Toilets }) do
	p.ToiletTier = tier
	p.SocialRuntime, p.Social.InviteExpires = nil, 0
	local base = Income:Rates(p)["1"] / 6000 * 60
	p.SocialRuntime, p.Social.InviteExpires = { GroupMember = true, FriendCount = 3 }, os.time() + 1800
	local boosted = Income:Rates(p)["1"] / 6000 * 60
	assert(math.abs(boosted / base - 1.518) < 0.01)
	print(string.format("%s | %.3f | %.3f", Toilets[tier].Name, base, boosted))
end
print(
	"Invite example assumes the boost is active; actual expiry, qualification, daily limits, flush gates, RNG and collection caps affect elapsed progression."
)
