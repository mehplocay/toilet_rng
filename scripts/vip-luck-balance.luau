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
print(
	"\nUncapped heavy stacking: Infinity Flush, Luck L50, with/without R15. Sustained paid luck requires a separately reviewed charge for EVERY flush. Times assume a theoretical 0.4s cadence and exclude review time; temporary boosts must remain active."
)
print(
	"\n| Stack | Luck | Outcome | Chance % | Mean flushes | p50 flushes / minutes | p90 flushes / minutes | 20-flush chance % |"
)
print("|---|---:|---|---:|---:|---:|---:|---:|")
local function quantile(probability, target)
	if probability == 1 then
		return 1
	end
	if probability == 0 then
		return math.huge
	end
	return math.ceil(math.log(1 - target) / math.log(1 - probability))
end
local function report(label, rebirth, factor, temporary)
	p.RebirthLevel, p.Upgrades.LuckBoost = rebirth, 50
	local luck = U:Luck(p, Toilets[15].Luck, factor, temporary)
	local entries = Roll.Distribution(Items, Toilets, 15, luck)
	local outcomes = { Secret = 0, Celestial = 0 }
	for _, entry in ipairs(entries) do
		if outcomes[entry.Item.Rarity] then
			outcomes[entry.Item.Rarity] += entry.Probability
		end
	end
	local cases = {
		{ "Any Secret", outcomes.Secret },
		{ "Any Celestial", outcomes.Celestial },
		{ entries[1].Item.Name, entries[1].Probability },
	}
	for _, entry in ipairs(entries) do
		if entry.Item.Rarity == "Celestial" then
			table.insert(cases, { entry.Item.Name, entry.Probability })
			break
		end
	end
	for _, case in ipairs(cases) do
		local probability = case[2]
		local median, tail = quantile(probability, 0.5), quantile(probability, 0.9)
		print(
			string.format(
				"| %s | %.4g | %s | %.9f | %.2f | %.0f / %.2f | %.0f / %.2f | %.6f |",
				label,
				luck,
				case[1],
				probability * 100,
				1 / probability,
				median,
				median * 0.4 / 60,
				tail,
				tail * 0.4 / 60,
				(1 - (1 - probability) ^ 20) * 100
			)
		)
	end
	assert(luck == U:Luck(p, Toilets[15].Luck) * factor * temporary)
end
report("Free L50/R15", 15, 1, 1)
report("VIP + 2x L50/R15", 15, 2.5, 1)
report("VIP + 2x + charge L50/R0", 0, 25, 1)
report("VIP + 2x + charge L50/R15", 15, 25, 1)
report("Above + daily x2 + server x2", 15, 25, 4)
print(
	"\nEvery independent check scales linearly until probability 1. Earlier rare checks can suppress later outcomes. With total luck >=15,000,000, Cosmic Courtesy is certain and every later item (including Celestial and Poop) has zero outcome probability. No total or per-source luck cap is introduced."
)
