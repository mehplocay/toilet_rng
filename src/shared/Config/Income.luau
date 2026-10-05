return {
	PassiveRate = 0.01, -- Item sell value per minute, before caps.
	OfflineMinutes = 240,
	-- Tier order matches Toilets. These bound even retained jackpot items.
	SlotRateCaps = { 1, 3, 7, 15, 30, 65, 140 },
	PlayerRateCaps = { 3, 9, 21, 45, 90, 195, 420 },
	SlotPendingCap = 33600,
	PlayerPendingCap = 100800,
	MaxSlots = 100, -- Includes legacy saved capacities.
	UnitsPerCoin = 6000, -- Persisted scale: do not change without a ledger migration.
	MaxBalance = 9e15,
	MaxTimestamp = 4102444800,
	RefreshSeconds = 5,
	CollectRange = 10,
	CollectOffset = { X = 0, Y = 1, Z = -12 },
}
