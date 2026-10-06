local Feedback = require("../src/client/Audio/Feedback")
local Upgrades = require("../src/shared/Config/Upgrades")
local Rewards = require("../src/shared/Config/Rewards")
local calls = {}
local observer = Feedback.new({
	Play = function(_, key, amount)
		table.insert(calls, { Key = key, Amount = amount })
	end,
}, Upgrades, Rewards)
local function state(patch)
	local value = {
		Coins = 100,
		ToiletTier = 1,
		RebirthLevel = 0,
		DisplaySlots = 3,
		AutoFlush = false,
		Inventory = { Poop = 10 },
		Displays = {},
		Upgrades = {},
		ServerLuckExpires = 0,
		RewardLuckExpires = 0,
	}
	for key, entry in pairs(patch or {}) do
		value[key] = entry
	end
	return value
end
local function expect(key, amount)
	assert(#calls == 1 and calls[1].Key == key, key .. ": wrong/multiple feedback")
	if amount then
		assert(calls[1].Amount == amount, "Used wallet balance instead of award")
	end
	table.clear(calls)
end
observer:State(state(), 100)
observer:State(state(), 100)
assert(#calls == 0, "Profile load/redundant State made noise")
observer:State(state({ Coins = 102, Inventory = { Poop = 9 } }), 100)
expect("Sell", 2)
observer:Result("Sell", { Success = true, Coins = 102 })
assert(#calls == 0, "State and Result doubled the sale")
observer:State(state({ Coins = 114, Inventory = { Poop = 3 } }), 100)
expect("SellAll", 12)
observer:State(state({ Coins = 0, RebirthLevel = 1, Inventory = {} }), 100)
assert(#calls == 0, "Rebirth inventory reset was treated as a sale")
observer:Result("Rebirth", { Success = true, Level = 1 })
expect("RebirthSuccess")
observer:State(state(), 100)
observer:State(state({ Displays = { ["1"] = "Poop" } }), 100)
expect("DisplayPlace")
observer:Result("Display", { Success = true })
assert(#calls == 0)
observer:State(state(), 100)
expect("DisplayReturn")
observer:State(state({ ToiletTier = 2 }), 100)
expect("ToiletUpgrade")
observer:Result("BuyToilet", { Success = true })
assert(#calls == 0)
observer:State(state({ ToiletTier = 2, Upgrades = { CashBoost = 1 } }), 100)
expect("UpgradeBuy")
observer:State(state({ ToiletTier = 2, Upgrades = { CashBoost = 10 } }), 100)
expect("UpgradeMax")
observer:State(state({ ToiletTier = 2, Upgrades = { CashBoost = 10 }, AutoFlush = true }), 100)
expect("AutoFlushToggle")
observer:State(state({ ToiletTier = 2, Upgrades = { CashBoost = 10 }, AutoFlush = false }), 100)
expect("AutoFlushToggle")
for _, action in ipairs({
	"Sell",
	"BuyToilet",
	"BuyUpgrade",
	"ClaimReward",
	"ClaimIndexReward",
	"CollectIncome",
	"Rebirth",
	"RefreshPasses",
	"PlotColor",
}) do
	observer:Result(action, { Success = false })
	expect("Error")
end
observer:Result("Display", { Success = false })
expect("DisplayLocked")
observer:Result("BuyPass", { Success = false })
expect("PurchaseFail")
observer:Result("BuyPass", { Success = true, Message = "You already own this pass." })
assert(#calls == 0, "Existing ownership celebrated a purchase")
observer:Result("BuyPass", { Success = true, Message = "Complete or close the Roblox purchase prompt." })
expect("PurchaseStart")
observer:Result("BuyPass", { Success = true, Message = "Pass unlocked!" })
expect("PurchaseSuccess")
for action, cue in pairs({ CollectIncome = "CoinCollect", ClaimIndexReward = "IndexClaim", ClaimReward = "DailyClaim" }) do
	observer:Result(action, { Success = true, Day = 1 })
	expect(cue)
end
observer:Result("ClaimReward", { Success = true, Day = 7 })
expect("DailyStreak")
assert(observer:Result("Flush", { FlushId = 10 }))
assert(not observer:Result("Flush", { FlushId = 10 }))
assert(not observer:Result("Flush", { FlushId = 9 }))
for _, bad in ipairs({ 0 / 0, math.huge, -1, 10.5 }) do
	assert(not observer:Result("Flush", { FlushId = bad }))
end
assert(observer:Result("Flush", { FlushId = 11 }), "Malformed replay poisoned the flush counter")
observer:ServerLuck(110, 100)
expect("LuckStart")
observer:ServerLuck(120, 101)
observer:Tick(119)
assert(#calls == 0, "Boost extension repeated start")
observer:Tick(120)
expect("LuckEnd")
observer:Tick(125)
assert(#calls == 0, "Boost end repeated")
observer = Feedback.new({
	Play = function(_, key)
		table.insert(calls, { Key = key })
	end,
}, Upgrades, Rewards, require("../src/shared/Config/Monetization"))
observer:State(state({ LifetimeFlushes = 99, RewardLuckExpires = 200 }), 100)
assert(#calls == 0, "Restored personal boost made a start sound")
observer:State(state({ LifetimeFlushes = 100, RewardLuckExpires = 200 }), 100)
expect("UpgradeMax")
observer:Tick(200)
expect("LuckEnd")
print(
	"Sound feedback checks passed: confirmed outcomes, replay suppression, reset silence, pass protocol, claims and boost edges"
)
