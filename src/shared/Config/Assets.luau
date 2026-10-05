return {
	-- UI art can be assigned numeric IDs or content strings. Zero keeps the primitive fallback.
	Icons = {
		Coins = 0,
		Shop = 0,
		Collection = 0,
		Upgrades = 0,
		Daily = 0,
		Home = 0,
		Hub = 0,
		Teleport = 0,
		Settings = 0,
		Flush = 0,
		Luck = 0,
		Crown = 0,
		Passes = 0,
		Pointer = 0,
	},
	ItemIcons = {
		Poop = 0,
		ToiletPaper = 0,
		Rat = 0,
		Fish = 0,
		Duck = 0,
		GoldenPoop = 0,
		ToiletBaby = 0,
		SewerShark = 0,
		KingPoop = 0,
		AlienToilet = 0,
		Mystery = 0,
	},
	ToiletIcons = { Basic = 0, Dirty = 0, Golden = 0, Diamond = 0, Radioactive = 0, Demon = 0, Galaxy = 0 },
	Models = {}, -- All visual models are generated from built-in primitives.
	Textures = { Sparkle = "rbxasset://textures/particles/sparkles_main.dds" }, -- Engine-bundled texture; no external ID.
	Sounds = { Flush = "", Epic = "", Legendary = "", ServerEvent = "", Click = "" },
	Gamepasses = {}, -- No real asset/product IDs configured yet.
	DeveloperProducts = {},
}
