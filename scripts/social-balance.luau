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
print("Scenario | Social coin factor | Invite luck factor | Relative coin-gated time (fixed rates)")
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
	print(string.format("%s | %.3fx | %.2fx | %.2f%%", row[1], factor, Rules.Luck(p), 100 / factor))
end
print("Tier | Typical single Poop display coins/min | Group + 3 friends + active invite coins/min")
for _, tier in ipairs({ 1, 4, 7, #Toilets }) do
	p.ToiletTier = tier
	p.SocialRuntime, p.Social.InviteExpires = nil, 0
	local base = Income:Rates(p)["1"] / 6000 * 60
	p.SocialRuntime, p.Social.InviteExpires = { GroupMember = true, FriendCount = 3 }, os.time() + 1800
	local boosted = Income:Rates(p)["1"] / 6000 * 60
	assert(math.abs(boosted / base - 1.265) < 0.01)
	print(string.format("%s | %.3f | %.3f", Toilets[tier].Name, base, boosted))
end
print(
	"Invite example assumes the boost is active; actual expiry, qualification, daily limits, flush gates, RNG and collection caps affect elapsed progression."
)

local Roll = require("../src/server/Services/RollService")
print("\nInvite-only pacing: fixed loadout coin factors are exactly equal")
p.SocialRuntime = nil
p.Social.InviteExpires = 0
local cash = U:Cash(p)
p.Social.InviteExpires = os.time() + Config.InviteSeconds
assert(U:Cash(p) == cash)
print("Coin-gated time: 100% with or without invite. Changed RNG can indirectly change later collection value.")
print("\nLoadout | Item | Baseline luck | Invite luck | Expected flushes baseline | Expected flushes invite | Change")
for _, loadout in ipairs({
	{ "Basic", 1, 0, 0, 1 },
	{ "Infinity Flush", 15, 0, 0, 1 },
	{ "Max free + server + daily", 15, 50, 15, 4 },
	{ "Max free + server + daily + VIP + 2x", 15, 50, 15, 10 },
	{ "Max free + server + daily + VIP + 2x + charge", 15, 50, 15, 100 },
}) do
	p.ToiletTier, p.Upgrades.LuckBoost, p.RebirthLevel = loadout[2], loadout[3], loadout[4]
	p.Social.InviteExpires = 0
	local baseLuck = U:Luck(p, Toilets[p.ToiletTier].Luck, loadout[5])
	p.Social.InviteExpires = os.time() + Config.InviteSeconds
	local inviteLuck = U:Luck(p, Toilets[p.ToiletTier].Luck, loadout[5])
	local baseline = Roll.Distribution(Items, Toilets, p.ToiletTier, baseLuck)
	local invited = Roll.Distribution(Items, Toilets, p.ToiletTier, inviteLuck)
	for i = 1, 3 do
		local base, withInvite = 1 / baseline[i].Probability, 1 / invited[i].Probability
		print(
			string.format(
				"%s | %s | %.4g | %.4g | %.3f | %.3f | %.4f%%",
				loadout[1],
				baseline[i].Item.Name,
				baseLuck,
				inviteLuck,
				base,
				withInvite,
				(withInvite / base - 1) * 100
			)
		)
	end
end
print(
	"Expected flushes use actual sequential outcome probabilities with invite active on every modeled roll; finite awards can expire earlier."
)
