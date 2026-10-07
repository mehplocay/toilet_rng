local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Config = require("../src/shared/Config/Upgrades")
local U = require("../src/shared/UpgradeRules").new(Config)
local Roll = require("../src/server/Services/RollService")
local p = { Upgrades = { LuckBoost = 0 }, RebirthLevel = 0 }
print("# Paid luck balance (2026-10-07)")
print(
	"\nAt each unlock tier, no free upgrades, rebirth, daily or server boost. Eligible policy; DoubleLuck assumed released. Expected flushes = 1 / actual sequential outcome probability, not a guarantee."
)
print("\n| Tier / rarest item | Free | VIP | 2x Luck | Both | Both + Lucky charge |")
print("|---|---:|---:|---:|---:|---:|")
for tier, t in ipairs(Toilets) do
	local entries = {}
	for _, factor in ipairs({ 1, 1.25, 2, 2.5, 25 }) do
		local luck = U:Luck(p, t.Luck, factor)
		table.insert(entries, (Roll.Distribution(Items, Toilets, tier, luck)))
	end
	if tier >= 6 then
		print(
			string.format(
				"| %s / %s | %.0f | %.0f | %.0f | %.0f | %.0f |",
				t.Name,
				entries[1][1].Item.Name,
				1 / entries[1][1].Probability,
				1 / entries[2][1].Probability,
				1 / entries[3][1].Probability,
				1 / entries[4][1].Probability,
				1 / entries[5][1].Probability
			)
		)
	end
	assert(math.abs(entries[2][1].Probability / entries[1][1].Probability - 1.25) < 1e-12)
end
print("\nRarest six items at Infinity Flush, free Luck L0 / R0, no temporary boosts:")
print("\n| Item | Free expected flushes | VIP | Both permanent passes |")
print("|---|---:|---:|---:|")
local normal = Roll.Distribution(Items, Toilets, #Toilets, U:Luck(p, Toilets[#Toilets].Luck))
local vip = Roll.Distribution(Items, Toilets, #Toilets, U:Luck(p, Toilets[#Toilets].Luck, 1.25))
local both = Roll.Distribution(Items, Toilets, #Toilets, U:Luck(p, Toilets[#Toilets].Luck, 2.5))
for i = 1, 6 do
	print(
		string.format(
			"| %s | %.0f | %.0f | %.0f |",
			normal[i].Item.Name,
			1 / normal[i].Probability,
			1 / vip[i].Probability,
			1 / both[i].Probability
		)
	)
end
print("\nBoth passes reach the cap when free total luck reaches 4x; 2x Luck alone at 5x; VIP alone at 8x.")
print("\n| Toilet | Both passes, no rebirth | Both passes, R15 | Both + server/daily x2, no rebirth |")
print("|---|---:|---:|---:|")
local function capLevel(t, rebirth, boost)
	p.RebirthLevel = rebirth
	for level = 0, 50 do
		p.Upgrades.LuckBoost = level
		if U:Luck(p, t.Luck, 2.5, boost) >= 10 then
			return tostring(level)
		end
	end
	return "Not reached by L50"
end
for _, tier in ipairs({ 1, 7, 15 }) do
	local t = Toilets[tier]
	print(string.format("| %s | %s | %s | %s |", t.Name, capLevel(t, 0, 1), capLevel(t, 15, 1), capLevel(t, 0, 2)))
end
print(
	"\nAt the 10x cap, a Lucky Flush charge adds zero probability benefit and is still consumed if reviewed and used. Below the cap, it raises total luck to 10x; e.g. both passes at Basic L0 start at 2.5x, so a charge improves rarest-item odds only 4x. VIP alone reduces expected rarest flushes by 20% before the cap; both passes by 60%. No diminishing returns beyond the existing cap and sequential survival probabilities."
)
