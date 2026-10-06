return {
	PassiveRate = 2, -- Item sell value per minute, before caps; UI shows coins/second.
	OfflineMinutes = 240,
	-- Tier order matches Toilets. These bound even retained jackpot items.
	SlotRateCaps = { 5, 7, 11, 18, 34, 67, 141 },
	PlayerRateCaps = { 50, 70, 110, 180, 340, 670, 1410 },
	SlotPendingCap = 33840, -- Highest slot cap * base offline minutes; never shrink old storage.
	PlayerPendingCap = 338400,
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
