local Limit = require(if script then script.Parent.Economy else "./Economy").MaxAmount
-- Cumulative rebirth cash bonus multiplies Cash Boost and display/paid factors.
local levels = {
	{
		RequiredCoins = 6500000,
		Cash = 0.5,
		Luck = 0.05,
		Speed = 0.03,
		StarterCoins = 2500,
		Title = "Fresh Start",
		Badge = "Rebirth 1",
		Perks = { "Fresh Start title" },
	},
	{
		RequiredCoins = 15000000,
		Cash = 1.1,
		Luck = 0.1,
		Speed = 0.05,
		StarterCoins = 2750,
		Title = "Bowl Apprentice",
		Badge = "Rebirth 2",
		Perks = { "Bowl Apprentice title" },
	},
	{
		RequiredCoins = 70000000,
		Cash = 1.8,
		Luck = 0.15,
		Speed = 0.07,
		StarterCoins = 3000,
		Title = "Porcelain Keeper",
		Badge = "Rebirth 3",
		Perks = { "Porcelain Keeper title" },
	},
	{
		RequiredCoins = 2300000000,
		Cash = 2.4,
		Luck = 0.2,
		Speed = 0.09,
		StarterCoins = 3250,
		Title = "Royal Cleaner",
		Badge = "Rebirth 4",
		Perks = { "Royal Cleaner title" },
	},
	{
		RequiredCoins = 5000000000,
		Cash = 3,
		Luck = 0.25,
		Speed = 0.1,
		StarterCoins = 3500,
		Title = "Diamond Janitor",
		Badge = "Rebirth 5",
		Perks = { "Diamond Janitor title" },
	},
	{
		RequiredCoins = 18000000000,
		Cash = 3.8,
		Luck = 0.32,
		Speed = 0.13,
		StarterCoins = 3750,
		Title = "Pipe Guardian",
		Badge = "Rebirth 6",
		Perks = { "Pipe Guardian title" },
	},
	{
		RequiredCoins = 100000000000,
		Cash = 4.7,
		Luck = 0.39,
		Speed = 0.16,
		StarterCoins = 4000,
		Title = "Flush Captain",
		Badge = "Rebirth 7",
		Perks = { "Flush Captain title" },
	},
	{
		RequiredCoins = 1000000000000,
		Cash = 5.7,
		Luck = 0.46,
		Speed = 0.19,
		StarterCoins = 4250,
		Title = "Bowl Champion",
		Badge = "Rebirth 8",
		Perks = { "Bowl Champion title" },
	},
	{
		RequiredCoins = 30000000000000,
		Cash = 6.8,
		Luck = 0.53,
		Speed = 0.22,
		StarterCoins = 4500,
		Title = "Porcelain Hero",
		Badge = "Rebirth 9",
		Perks = { "Porcelain Hero title" },
	},
	{
		RequiredCoins = 60000000000000,
		Cash = 8,
		Luck = 0.6,
		Speed = 0.25,
		StarterCoins = 4750,
		Title = "Cosmic Janitor",
		Badge = "Rebirth 10",
		Perks = { "Cosmic Janitor title" },
	},
	{
		RequiredCoins = 100000000000000,
		Cash = 9.3,
		Luck = 0.68,
		Speed = 0.3,
		StarterCoins = 5000,
		Title = "Starlight Keeper",
		Badge = "Rebirth 11",
		Perks = { "Starlight Keeper title" },
	},
	{
		RequiredCoins = 200000000000000,
		Cash = 10.7,
		Luck = 0.76,
		Speed = 0.35,
		StarterCoins = 5250,
		Title = "Royal Plumber",
		Badge = "Rebirth 12",
		Perks = { "Royal Plumber title" },
	},
	{
		RequiredCoins = 400000000000000,
		Cash = 12.1,
		Luck = 0.84,
		Speed = 0.4,
		StarterCoins = 5500,
		Title = "Galaxy Guardian",
		Badge = "Rebirth 13",
		Perks = { "Galaxy Guardian title" },
	},
	{
		RequiredCoins = 700000000000000,
		Cash = 13.5,
		Luck = 0.92,
		Speed = 0.45,
		StarterCoins = 5750,
		Title = "Eternal Cleaner",
		Badge = "Rebirth 14",
		Perks = { "Eternal Cleaner title" },
	},
	{
		RequiredCoins = 2400000000000000,
		Cash = 15,
		Luck = 1,
		Speed = 0.5,
		StarterCoins = 6000,
		Title = "Flush Legend",
		Badge = "Rebirth 15",
		Perks = { "Flush Legend title" },
	},
}
local cosmetics = {
	{ Level = 2, Kind = "Title", Name = "Bowl Apprentice title", RGB = { 130, 230, 255 } },
	{ Level = 4, Kind = "Trail", Name = "Royal violet trail", RGB = { 185, 105, 255 } },
	{ Level = 6, Kind = "Trim", Name = "Emerald plot sign trim", RGB = { 80, 240, 150 } },
	{ Level = 8, Kind = "ChatTag", Name = "Bowl Champion chat tag", RGB = { 100, 200, 255 } },
	{ Level = 10, Kind = "Trail", Name = "Cosmic cyan trail", RGB = { 60, 240, 255 } },
	{ Level = 12, Kind = "Trim", Name = "Royal gold plot sign trim", RGB = { 255, 205, 70 } },
	{ Level = 14, Kind = "ChatTag", Name = "Eternal chat tag", RGB = { 255, 215, 110 } },
	{ Level = 15, Kind = "Legend", Name = "Legend skin, golden title and aura", RGB = { 255, 205, 65 } },
}
for level, row in ipairs(levels) do
	row.AutoCollect = level >= 5
	row.DisplaySlots = if level >= 10 then 2 else 0
	if row.AutoCollect then
		table.insert(row.Perks, "FREE Auto Collect (every 5s anywhere on the map)")
	end
	if row.DisplaySlots > 0 then
		table.insert(row.Perks, "+2 display slots (up to plot capacity)")
	end
	for _, cosmetic in ipairs(cosmetics) do
		if cosmetic.Level <= level and cosmetic.Name ~= row.Title .. " title" then
			table.insert(row.Perks, cosmetic.Name)
		end
	end
end
return {
	RequiredFlushes = 300,
	BaseDisplaySlots = 3,
	DisplayCapacity = 10,
	Cosmetics = cosmetics,
	ResponseTimeout = 15,
	MaxBalance = Limit,
	SpeedBonusCap = 0.50,
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
