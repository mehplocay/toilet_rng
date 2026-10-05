-- Pool is cumulative. Tuning below is provisional where the GDD gives no numbers.
return {
	{
		Id = "Basic",
		Name = "Basic Toilet",
		Price = 0,
		Cooldown = 3,
		Luck = 1,
		Pool = { "Poop", "ToiletPaper", "Rat", "Fish" },
	},
	{ Id = "Dirty", Name = "Dirty Toilet", Price = 190, Cooldown = 2.8, Luck = 1.05, Pool = { "Duck" } },
	{ Id = "Golden", Name = "Golden Toilet", Price = 970, Cooldown = 2.6, Luck = 1.1, Pool = { "GoldenPoop" } },
	{ Id = "Diamond", Name = "Diamond Toilet", Price = 3070, Cooldown = 2.4, Luck = 1.15, Pool = { "ToiletBaby" } },
	{
		Id = "Radioactive",
		Name = "Radioactive Toilet",
		Price = 9590,
		Cooldown = 2.2,
		Luck = 1.2,
		Pool = { "SewerShark", "KingPoop" },
	},
	{ Id = "Demon", Name = "Demon Toilet", Price = 33890, Cooldown = 2, Luck = 1.25, Pool = { "AlienToilet" } },
	{ Id = "Galaxy", Name = "Galaxy Toilet", Price = 85860, Cooldown = 1.8, Luck = 1.3, Pool = { "Mystery" } },
}
