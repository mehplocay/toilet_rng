return {
	-- Coins/second at Basic, before cash and toilet multipliers.
	RarityRates = {
		Common = 1,
		Uncommon = 3,
		Rare = 10,
		Epic = 40,
		Legendary = 200,
		Mythic = 1000,
		Godly = 6000,
		Secret = 100000,
	},
	TierMultipliers = { 1, 1.5, 2.2, 3.3, 5, 8, 12 },
	OfflineMinutes = 480,
	OfflineRate = 0.5,
	MaxOfflineMinutes = 24 * 60,
	-- Coins/minute; ten maximum-rate Secrets fit at each tier.
	SlotRateCaps = { 6000000, 9000000, 13200000, 19800000, 30000000, 48000000, 72000000 },
	PlayerRateCaps = { 60000000, 90000000, 132000000, 198000000, 300000000, 480000000, 720000000 },
	SlotPendingCap = 34560000000,
	PlayerPendingCap = 345600000000,
	MaxLedgerUnits = 9e15, -- Integer subcoins, NOT coins; exact accumulation.
	MaxSlots = 100, -- Includes legacy saved capacities.
	UnitsPerCoin = 6000, -- Persisted scale: do not change without a ledger migration.
	MaxBalance = 9e15,
	MaxTimestamp = 4102444800,
	RefreshSeconds = 1,
	CollectRange = 10,
	PadRange = 6,
	TouchRange = 4.5,
	GlowThreshold = 1,
	CollectOffset = { X = 0, Y = 1, Z = -12 },
}
