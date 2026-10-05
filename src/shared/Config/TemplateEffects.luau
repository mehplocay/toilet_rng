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
}
