-- Check shipped IDs independently of the audit/UI fixtures. No Roblox calls.
local config = require("../src/shared/Config/Monetization")
local passes = {
	SparkleTrail = 2008550322,
	VIPStar = 2008628314,
	CustomPlotColor = 2006679679,
	FastFlush = 2005125786,
	DoubleCash = 2014052290,
	AutoCollect = 2014760290,
	OfflinePlus = 2013200307,
	VIPPack = 2013872290,
	DoubleLuck = 0,
	RainbowName = 2014136291,
	ConfettiReveal = 2013332295,
	GoldenName = 2012846305,
	DancePack = 2012936292,
	ToiletGlow = 2013494299,
	Companion = 2013812281,
	UltimateBundle = 2013272293,
}
local products = {
	Coins10Minutes = 3716998619,
	Coins1Hour = 3716998683,
	Coins6Hours = 3716998719,
	PathBoost10Minutes = 3716998748,
	Coins24Hours = 3716998799,
	LuckyFlush1 = 3716998840,
	LuckyFlush5 = 3716998876,
	LuckyFlush20 = 3716998923,
}
local seen, wired, held = {}, 0, 0
for group, expected in pairs({ Gamepasses = passes, DeveloperProducts = products }) do
	local count = 0
	for key, offer in pairs(config[group]) do
		assert(expected[key] ~= nil and offer.Id == expected[key], "Wrong production ID: " .. group .. "." .. key)
		count += 1
		if offer.Id > 0 then
			assert(not seen[offer.Id], "Duplicate production ID: " .. key)
			seen[offer.Id], wired = true, wired + 1
		else
			held += 1
			assert(group == "Gamepasses" and key == "DoubleLuck", "Unexpected disabled offer: " .. key)
		end
	end
	assert(count == (if group == "Gamepasses" then 16 else 8), "Wrong catalog size: " .. group)
	for key in pairs(expected) do
		assert(config[group][key], "Missing production offer: " .. key)
	end
end
assert(wired == 23 and held == 1)
assert(config.LuckyFlushCap == 1000 and config.LuckyMultiplier == 10 and config.LuckyLuckCap == 10)
for key, charges in pairs({ LuckyFlush1 = 1, LuckyFlush5 = 5, LuckyFlush20 = 20 }) do
	assert(config.DeveloperProducts[key].LuckyCharges == charges)
end
assert(config.Gamepasses.VIPStar.Name == "Star Tag")
print(
	"Production monetization IDs passed: 15 passes + 8 products wired, 2x Luck pending; Lucky charges and caps preserved"
)
