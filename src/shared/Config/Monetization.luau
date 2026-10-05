return {
	AutoFlushUnlock = 100,
	FlushRange = 14,
	AutoTick = 0.1,
	OwnershipRefresh = 120,
	PromptTimeout = 120,
	PassOrder = { "SparkleTrail", "VIPStar", "CustomPlotColor", "FastFlush" },
	Gamepasses = {
		SparkleTrail = {
			Id = 0,
			Name = "Sparkle Trail",
			Price = 49,
			Description = "A sparkling trail follows your character. Cosmetic only.",
		},
		VIPStar = {
			Id = 0,
			Name = "VIP Star",
			Price = 59,
			Description = "A VIP star in chat and above your name. Cosmetic only.",
		},
		CustomPlotColor = {
			Id = 0,
			Name = "Custom Plot Color",
			Price = 79,
			Description = "Choose your plot's lawn and border color. Cosmetic only.",
		},
		FastFlush = {
			Id = 0,
			Name = "Fast Flush",
			Price = 99,
			Description = "20% shorter flush cooldown. Same items and odds.",
			CooldownMultiplier = 0.8,
		},
	},
	PlotColors = {
		{ Id = "Default", Name = "Default" },
		{ Id = "Sky", Name = "Sky", RGB = { 85, 175, 240 } },
		{ Id = "Mint", Name = "Mint", RGB = { 85, 210, 155 } },
		{ Id = "Rose", Name = "Rose", RGB = { 235, 115, 170 } },
		{ Id = "Gold", Name = "Gold", RGB = { 235, 185, 70 } },
		{ Id = "Lavender", Name = "Lavender", RGB = { 170, 125, 230 } },
	},
	SparkleRGB = { 255, 225, 100 },
	SparkleRate = 8,
	TrailLifetime = 0.5,
	VIPLabel = "★ VIP",
	DeveloperProducts = {}, -- Paid randomness is not enabled.
}
