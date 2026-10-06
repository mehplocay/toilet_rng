-- One light and one low-rate emitter per special model; managed by VisualIdle.
local gold = Color3.fromRGB(255, 209, 76)
local ice = Color3.fromRGB(109, 226, 255)
local violet = Color3.fromRGB(181, 100, 255)
return {
	GoldenToilet = { Color = gold, At = Vector3.new(0, 2.1, -0.24), Particles = "GoldenSparkles" },
	DiamondToilet = { Color = ice, At = Vector3.new(0, 2.1, -0.24), Particles = "DiamondGlint" },
	RadioactiveToilet = {
		Color = Color3.fromRGB(114, 255, 67),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "RadioactiveGlow",
	},
	DemonToilet = { Color = Color3.fromRGB(255, 62, 48), At = Vector3.new(0, 2.1, -0.24), Particles = "Embers" },
	GalaxyToilet = { Color = violet, At = Vector3.new(0, 3.2, 0), Particles = "GalaxyStars" },
	GoldenPoop = { Color = gold, At = Vector3.new(0, 1.8, 0), Particles = "GoldenSparkles" },
	KingPoop = { Color = gold, At = Vector3.new(0, 2.5, 0), Particles = "CrownSparkle" },
	Mystery = { Color = violet, At = Vector3.new(0, 1.3, 0), Particles = "MysteryGlow" },
	CoralCommode = {
		Color = Color3.fromRGB(41, 188, 217),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "CoralCommodeAura",
		Rate = 3,
	},
	CloudCushion = {
		Color = Color3.fromRGB(160, 240, 255),
		Speed = NumberRange.new(0.2, 0.5),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "CloudCushionAura",
		Rate = 3,
	},
	ClockworkCloset = {
		Color = Color3.fromRGB(255, 130, 30),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "ClockworkClosetAura",
		Rate = 3,
	},
	DragonKiln = {
		Color = Color3.fromRGB(255, 130, 30),
		SecondaryColor = Color3.fromRGB(239, 51, 89),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "DragonKilnAura",
		Rate = 3,
	},
	AuroraThrone = {
		Color = Color3.fromRGB(128, 255, 190),
		SecondaryColor = Color3.fromRGB(52, 223, 255),
		Speed = NumberRange.new(0.2, 0.5),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "AuroraThroneAura",
		Rate = 3,
	},
	AstralAltar = {
		Color = Color3.fromRGB(52, 223, 255),
		Speed = NumberRange.new(0.2, 0.5),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "AstralAltarAura",
		Rate = 3,
	},
	ParadoxPotty = {
		Color = Color3.fromRGB(247, 79, 231),
		SecondaryColor = Color3.fromRGB(52, 223, 255),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "ParadoxPottyAura",
		Rate = 3,
	},
	InfinityFlush = {
		Color = Color3.fromRGB(52, 223, 255),
		SecondaryColor = Color3.fromRGB(255, 197, 28),
		LightColor = Color3.fromRGB(165, 65, 255),
		At = Vector3.new(0, 2.1, -0.24),
		Particles = "InfinityFlushAura",
		Rate = 3,
	},
}
