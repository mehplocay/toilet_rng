-- Pool is cumulative. Tuning below is provisional where the GDD gives no numbers.
return {
	{ Id = "Basic", Price = 0, Cooldown = 3, Luck = 1, Pool = { "Poop", "ToiletPaper", "Rat", "Fish" } },
	{ Id = "Dirty", Price = 500, Cooldown = 2.8, Luck = 1.05, Pool = { "Duck" } },
	{ Id = "Golden", Price = 5000, Cooldown = 2.6, Luck = 1.1, Pool = { "GoldenPoop" } },
	{ Id = "Diamond", Price = 50000, Cooldown = 2.4, Luck = 1.15, Pool = { "ToiletBaby" } },
	{ Id = "Radioactive", Price = 250000, Cooldown = 2.2, Luck = 1.2, Pool = { "SewerShark" } },
	{ Id = "Demon", Price = 1000000, Cooldown = 2, Luck = 1.25, Pool = { "KingPoop" } },
	{ Id = "Galaxy", Price = 5000000, Cooldown = 1.8, Luck = 1.3, Pool = { "AlienToilet", "Mystery" } },
}
