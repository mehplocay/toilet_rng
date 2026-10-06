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
for level = 1, 15 do
	cash += if level <= 3 then 0.25 elseif level <= 8 then 0.10 else 0.05
	luck = math.min(0.30, luck + 0.02)
	speed = math.min(0.20, speed + (if level <= 3 then 0.04 else 0.01))
	levels[level] = {
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
	-- Income-first cohort: about 60 minutes; currency cannot bypass fresh flushes.
	RequiredFlushes = 3300,
	RequiredTier = 4, -- Diamond (one-based runtime tiers).
	ResetTier = 1,
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
		"Toilet -> Basic",
		"All coin upgrade levels",
		"Pending display coins",
		"Unprotected extra items",
		"Coin-bought display capacity",
	},
	KeepList = {
		"First copies + displayed items",
		"Kept copies stay unsellable",
		"Lifetime index + best finds",
		"Passes, cosmetics + settings",
		"Tutorial, daily + index claims",
		"Index / legacy / paid capacity",
	},
}
