-- Permanent bonuses are additive with coin tracks, never exponential.
local levels = {}
local cash, luck, speed = 0, 0, 0
local titles = {
	"Fresh Start",
	"Bowl Apprentice",
	"Porcelain Keeper",
	"Royal Cleaner",
	"Diamond Janitor",
	"Pipe Guardian",
	"Flush Captain",
	"Bowl Champion",
	"Porcelain Hero",
	"Cosmic Janitor",
	"Starlight Keeper",
	"Royal Plumber",
	"Galaxy Guardian",
	"Eternal Cleaner",
	"Flush Legend",
}
local gates = {
	3000000,
	12000000,
	35000000,
	100000000,
	500000000,
	1500000000,
	5000000000,
	15000000000,
	40000000000,
	80000000000,
	150000000000,
	250000000000,
	400000000000,
	650000000000,
	2500000000000,
}
for level = 1, 15 do
	cash += if level <= 3 then 0.25 elseif level <= 8 then 0.10 else 0.05
	luck = math.min(0.30, luck + 0.02)
	speed = math.min(0.20, speed + (if level <= 3 then 0.04 else 0.01))
	levels[level] = {
		RequiredCoins = gates[level],
		Cash = math.min(1.60, cash),
		Luck = luck,
		Speed = speed,
		StarterCoins = 2500 + (level - 1) * 250,
		Title = titles[level],
		Badge = "Rebirth " .. level,
		Perks = { "Rebirth Token " .. level, titles[level] .. " title", "Rebirth " .. level .. " profile badge" },
	}
end
return {
	-- Coin gates set the pace; every run also requires fresh successful flushes.
	RequiredFlushes = 300,
	BaseDisplaySlots = 3,
	HoldSeconds = 2,
	ResponseTimeout = 15,
	MaxBalance = 9e15,
	CashCap = 1.60,
	LuckBonusCap = 0.30,
	SpeedBonusCap = 0.20,
	-- Shares the existing announcement queue and its per-player cooldown.
	FriendAnnouncementLevel = 3,
	ServerAnnouncementLevel = 5,
	Levels = levels,
	ResetList = {
		"Wallet -> starter coins",
		"ALL loose inventory",
		"Uncollected pending coins",
		"Flushes this run",
	},
	KeepList = {
		"All toilet tiers + upgrades",
		"All display slots + items",
		"Lifetime index + best finds",
		"Passes, cosmetics + settings",
		"Tutorial, daily + index claims",
		"Permanent rebirth bonuses",
	},
}
