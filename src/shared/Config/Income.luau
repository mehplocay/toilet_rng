local Limit = require(if script then script.Parent.Economy else "./Economy").MaxAmount
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
		Celestial = 25000,
		Secret = 100000,
	},
	TierMultipliers = {
		1,
		1.5,
		2.2,
		3.3,
		5.25,
		8.5,
		13,
		19.5,
		29.25,
		43.333333333333336,
		65.0,
		97.5,
		146.25,
		216.66666666666666,
		325.0,
	},
	OfflineMinutes = 480,
	OfflineRate = 0.5,
	MaxOfflineMinutes = 24 * 60,
	-- Coins/minute including the toilet factor. Rates applies that factor once,
	-- then multiplies all cash bonuses without a gameplay multiplier ceiling.
	-- No design rate or storage caps, including legacy displays.
	SlotRateCaps = table.create(15, Limit),
	PlayerRateCaps = table.create(15, Limit),
	-- Compatibility aliases for tooling; actual storage is governed by MaxLedgerUnits.
	SlotPendingCap = Limit,
	PlayerPendingCap = Limit,
	MaxLedgerUnits = Limit, -- Persisted subcoins; approximate above 2^53.
	MaxSlots = 100, -- Includes legacy saved capacities.
	UnitsPerCoin = 6000, -- Persisted scale: do not change without a ledger migration.
	MaxBalance = Limit,
	MaxTimestamp = 4102444800,
	RefreshSeconds = 1,
	CollectRange = 10,
	PadRange = 6,
	TouchRange = 4.5,
	GlowThreshold = 1,
	CollectOffset = { X = 0, Y = 1, Z = -12 },
}
