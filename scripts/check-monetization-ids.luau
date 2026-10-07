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
	LuckyFlush1 = 0,
	LuckyFlush5 = 0,
	LuckyFlush20 = 0,
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
			assert(group == "DeveloperProducts" and offer.LuckyCharges, "Unexpected disabled offer: " .. key)
		end
	end
	assert(count == (if group == "Gamepasses" then 15 else 8), "Wrong catalog size: " .. group)
	for key in pairs(expected) do
		assert(config[group][key], "Missing production offer: " .. key)
	end
end
assert(wired == 20 and held == 3)
assert(config.Gamepasses.VIPStar.Name == "Star Tag")
print("Production monetization IDs passed: 15 passes + 5 products wired; 3 Lucky products held at zero")
