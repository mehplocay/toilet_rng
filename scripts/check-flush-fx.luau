-- Pure flush-presentation rules: tier escalation, settings, cadence collapse, budgets, envelopes.
local Rules = require("../src/shared/FlushFxRules")
local Config = require("../src/shared/Config/FlushFx")
local Reveals = require("../src/shared/Config/Reveals")
local Items = require("../src/shared/Config/Items")
local Toilets = require("../src/shared/Config/Toilets")
local Upgrades = require("../src/shared/Config/Upgrades")
local Assets = require("../src/shared/Config/Assets")
local passed = 0
local function check(name, fn)
	fn()
	passed += 1
	print("ok " .. name)
end

-- Catalog order (Rarities.Order); Rarities itself needs engine Color3 values.
local order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly", "Celestial", "Secret" }
for _, item in ipairs(Items) do
	assert(table.find(order, item.Rarity), "Unknown catalog rarity " .. tostring(item.Rarity))
end
for rarity in pairs(Reveals.Tiers) do
	assert(table.find(order, rarity), rarity)
end

check("every catalog rarity has a flush plan matching its reveal tier", function()
	assert(#order >= 9)
	for _, rarity in ipairs(order) do
		assert(Config.Rarities[rarity], rarity)
		local plan = Rules.Plan(Config, rarity, { Intensity = "Full" })
		local tier = Reveals.Tiers[rarity].Tier
		assert(plan.Big == (tier == "Banner" or tier == "Cinematic"), rarity .. " big mismatch")
		assert(plan.Rarity == rarity and plan.Comet and not plan.Underlay and not plan.Collapsed)
	end
end)

check("escalation is monotonic by rarity and big tiers are full-screen", function()
	local previous
	for _, rarity in ipairs(order) do
		local plan = Rules.Plan(Config, rarity, { Intensity = "Full" })
		if previous then
			for _, key in ipairs({ "Rank", "Duration", "Splash", "Sparks", "Fov", "Flash", "Light", "Coins" }) do
				assert(plan[key] >= previous[key], rarity .. " regressed on " .. key)
			end
		end
		if plan.Rank >= 4 then
			assert(plan.Flash > 0 and plan.Vignette > 0 and plan.ScreenConfetti > 0 and plan.FanBeams > 0)
			assert(plan.Shake == 0, "Big tiers leave CFrame shake to the reveal")
		end
		if plan.Rank >= 2 then
			assert(plan.Pillar, rarity .. " needs a light pillar")
		end
		previous = plan
	end
	local common = Rules.Plan(Config, "Common", { Intensity = "Full" })
	assert(common.Rays == 0 and common.Duration <= 1.5 and not common.RarityText and not common.Big)
end)

check("Common is action-packed: geyser, bubbles, foam, stars, comic burst, camera punch", function()
	for _, rarity in ipairs({ "Common", "Uncommon" }) do
		for _, style in ipairs(Config.StyleOrder) do
			for _, mobile in ipairs({ false, true }) do
				local plan = Rules.Plan(Config, rarity, { Intensity = "Full", Style = style, Mobile = mobile })
				assert(plan and plan.Style == style and plan.Comet and plan.Motion, rarity .. " " .. style)
				for _, key in ipairs({ "Geyser", "Splash", "Bubbles", "Foam", "Stars", "Pieces", "Sparks", "Coins" }) do
					assert(plan[key] > 0, rarity .. " " .. style .. " lacks " .. key)
				end
				assert(plan.Comic and plan.EmojiPops > 0 and plan.Fov >= 5 and plan.Shake > 0 and plan.Flash > 0)
				assert(plan.GeyserHeight >= 1.5 and plan.BounceTime > 0 and plan.ScreenRings > 0)
				if Config.Styles[style].Special then
					assert(plan.Special == Config.Styles[style].Special)
				end
			end
		end
	end
end)

check("at least 8 styles, each with motion, words, emojis, palette and engine textures", function()
	assert(#Config.StyleOrder >= 8)
	local motions, seen = {}, {}
	for _, name in ipairs(Config.StyleOrder) do
		local style = assert(Config.Styles[name], name)
		assert(not seen[name], "duplicate style " .. name)
		seen[name] = true
		assert(#style.Words >= 2 and #style.Emojis >= 2 and #style.Palette >= 1, name)
		for _, word in ipairs(style.Words) do
			assert(word == string.upper(word), name .. " comic words are upper case English")
		end
		assert(Assets.Textures[style.Pieces.Texture], name .. " unknown texture")
		motions[style.Motion] = true
		local pose = Rules.ToiletPose(style.Motion, 0.3, 1)
		assert(pose.SquashY ~= 1 or pose.Lift > 0 or pose.Spin ~= 0 or pose.TiltZ ~= 0, name .. " motion is static")
	end
	for name in pairs(Config.Styles) do
		assert(seen[name], name .. " missing from StyleOrder")
	end
	local count = 0
	for _ in pairs(motions) do
		count += 1
	end
	assert(count >= 6, "toilet motions need variety")
	assert(Config.Styles[Config.DefaultStyle])
end)

check("style picker: weighted, never repeats, poop party only for poop items", function()
	local last
	local counts = {}
	local seed = 12345
	local function roll()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	for _ = 1, 20000 do
		local name = Rules.PickStyle(Config, last, "Rat", roll())
		assert(Config.Styles[name] and name ~= last, "style repeated: " .. name)
		assert(name ~= "PoopParty", "poop party for a non-poop item")
		counts[name] = (counts[name] or 0) + 1
		last = name
	end
	for _, name in ipairs(Config.StyleOrder) do
		if name ~= "PoopParty" then
			assert((counts[name] or 0) > 500, name .. " never shows up")
		end
	end
	-- Heavier weight shows up more often than a lighter one.
	assert(counts.Geyser > counts.LightningZap)
	local poop, last2 = 0, nil
	for _ = 1, 4000 do
		local name = Rules.PickStyle(Config, last2, "Poop", roll())
		assert(name ~= last2)
		if name == "PoopParty" then
			poop += 1
		end
		last2 = name
	end
	assert(poop > 800, "poop party should be likely for Poop: " .. poop)
	-- Bounds and odd inputs.
	assert(Config.Styles[Rules.PickStyle(Config, nil, nil, 0)])
	assert(Config.Styles[Rules.PickStyle(Config, nil, nil, 1)])
	assert(Config.Styles[Rules.PickStyle(Config, "Geyser", nil, 0 / 0)])
	assert(Rules.PickStyle(Config, "Geyser", nil, 0.999999) ~= "Geyser")
	assert(Rules.StyleWeight(Config.Styles.PoopParty, "Rat") == 0)
	assert(Rules.StyleWeight(Config.Styles.PoopParty, "Poop") > Config.Styles.Geyser.Weight)
	assert(Rules.StyleWeight(Config.Styles.DuckParade, "Duck") > Config.Styles.DuckParade.Weight)
	-- Unknown styles in a plan fall back to the default.
	assert(Rules.Plan(Config, "Common", { Style = "Nope" }).Style == Config.DefaultStyle)
end)

check("toilet poses and item bounce stay bounded and settle at the end", function()
	local names = { "Unknown" }
	for _, name in ipairs(Config.StyleOrder) do
		table.insert(names, Config.Styles[name].Motion)
	end
	for _, motion in ipairs(names) do
		for _, power in ipairs({ 0, 1, 1.6, 2, 5, 0 / 0 }) do
			for i = -5, 105 do
				local pose = Rules.ToiletPose(motion, i / 100, power)
				assert(pose.Lift >= 0 and pose.Lift <= 0.9, motion)
				assert(pose.SquashY >= 0.45 and pose.SquashY <= 1.7, motion)
				assert(math.abs(pose.TiltX) <= 0.35 and math.abs(pose.TiltZ) <= 0.35, motion)
				assert(pose.Lid >= 0 and pose.Lid <= 2.2)
			end
			local final = Rules.ToiletPose(motion, 1, power)
			assert(final.Lift == 0 and final.SquashY == 1 and final.TiltX == 0 and final.TiltZ == 0 and final.Lid == 0)
			assert(math.abs(math.sin(final.Spin)) < 1e-9 and math.abs(math.cos(final.Spin) - 1) < 1e-9)
		end
	end
	for i = -5, 105 do
		local h, squash = Rules.Bounce(i / 100)
		assert(h >= 0 and h <= 1 and squash >= 0.5 and squash <= 1.35)
	end
	local h0 = Rules.Bounce(0)
	local h1 = Rules.Bounce(1)
	assert(h0 == 0 and math.abs(h1) < 1e-9)
end)

check("settings: Off and compact show nothing, Reduced keeps calm one-shots", function()
	for _, rarity in ipairs(order) do
		assert(Rules.Plan(Config, rarity, { Intensity = "Off" }) == nil)
		assert(Rules.Plan(Config, rarity, { Intensity = "Full", Compact = true }) == nil)
		local plan = Rules.Plan(Config, rarity, { Intensity = "Reduced" })
		assert(plan.Reduced and plan.Duration <= Config.ReducedDuration + 1e-9, rarity)
		for _, key in ipairs({ "Fov", "Shake", "Flash", "Grade", "Vignette", "Rays", "ScreenRings", "ScreenConfetti" }) do
			assert(plan[key] == 0, rarity .. " reduced kept " .. key)
		end
		assert(not plan.RarityText and not plan.Pillar and plan.FanBeams == 0 and plan.WindUp == 0)
		assert(not plan.Comic and plan.EmojiPops == 0 and not plan.Motion and not plan.Special)
		assert(plan.Props == 0 and plan.BounceTime == 0)
	end
	assert(Rules.Plan(Config, "Forged", { Intensity = "Full" }) == nil)
	assert(Rules.Intensity("Off", true) == "Off" and Rules.Intensity("Full", true) == "Reduced")
	assert(Rules.Intensity("Reduced", false) == "Reduced" and Rules.Intensity("Full", false) == "Full")
	assert(Rules.Intensity(nil, nil) == "Full")
end)

check("rapid and auto flushing always fit inside the cooldown", function()
	local cooldowns = { Upgrades.CooldownFloor, 0.45, 0.5, 0.6, 0.75, 0.9, 1.2 }
	for _, toilet in ipairs(Toilets) do
		table.insert(cooldowns, toilet.Cooldown)
		table.insert(cooldowns, math.max(Upgrades.CooldownFloor, toilet.Cooldown * 0.5))
	end
	for _, cooldown in ipairs(cooldowns) do
		for _, rarity in ipairs(order) do
			for _, mobile in ipairs({ false, true }) do
				local plan = Rules.Plan(Config, rarity, { Intensity = "Full", Cooldown = cooldown, Mobile = mobile })
				if not plan.Big then
					assert(plan.Duration <= math.max(cooldown, 0.3) + 1e-9, rarity .. " overruns cooldown " .. cooldown)
					assert(plan.Land <= plan.Duration and plan.WindUp <= plan.Land)
					if cooldown < Config.WindUpMinGap then
						assert(plan.WindUp == 0, "fast flushes skip the wind-up")
					end
				else
					assert(not plan.Collapsed, "rare moments keep their full length")
				end
			end
		end
	end
	-- Observed gap collapses too, even without a cooldown hint.
	local plan = Rules.Plan(Config, "Common", { Intensity = "Full", Gap = 0.2 })
	assert(plan.Collapsed and plan.Duration < 0.7 and plan.Shake == 0)
end)

check("a running bigger moment turns smaller flushes into underlays", function()
	local plan = Rules.Plan(Config, "Rare", { Intensity = "Full", ActiveRank = 5, ActiveRemaining = 1 })
	assert(plan.Underlay and not plan.Comet and plan.Light == 0 and plan.Fov == 0 and plan.Flash == 0)
	assert(plan.ScreenConfetti == 0 and plan.Coins >= 0 and not plan.Pillar)
	local same = Rules.Plan(Config, "Mythic", { Intensity = "Full", ActiveRank = 5, ActiveRemaining = 1 })
	assert(not same.Underlay, "equal rank replaces")
	local expired = Rules.Plan(Config, "Common", { Intensity = "Full", ActiveRank = 5, ActiveRemaining = 0 })
	assert(not expired.Underlay)
end)

check("caps and mobile budgets bound every count", function()
	for _, rarity in ipairs(order) do
		for _, mobile in ipairs({ false, true }) do
			local plan = Rules.Plan(Config, rarity, { Intensity = "Full", Mobile = mobile })
			for _, key in ipairs(Config.CountKeys) do
				local value = plan[key]
				assert(type(value) == "number" and value >= 0 and value % 1 == 0, key)
				assert(value <= Config.Caps[key], rarity .. " exceeds cap " .. key)
				if mobile and Config.MobileCaps[key] then
					assert(value <= Config.MobileCaps[key], rarity .. " exceeds mobile cap " .. key)
				end
			end
			if mobile then
				local desktop = Rules.Plan(Config, rarity, { Intensity = "Full" })
				for _, key in ipairs(Config.ParticleKeys) do
					assert(plan[key] <= desktop[key], key)
				end
			end
		end
	end
	assert(Config.MobileParticleBudget < Config.ParticleBudget)
end)

check("live particle ledger never exceeds its budget under auto-flush spam", function()
	local ledger = Rules.Ledger(Config.MobileParticleBudget)
	local now = 0
	for _ = 1, 400 do
		local plan = Rules.Plan(Config, "Secret", { Intensity = "Full", Mobile = true, Gap = 0.1 })
		for _, key in ipairs(Config.ParticleKeys) do
			ledger:Grant(now, plan[key], 2.6)
			assert(ledger:Live(now) <= ledger.Cap)
		end
		now += 0.1
	end
	assert(ledger:Grant(now, 5, 1) == 0, "budget saturated")
	assert(ledger:Grant(now + 3, 5, 1) == 5, "expired reservations free capacity")
	assert(ledger:Grant(now + 3, -4, 1) == 0 and ledger:Grant(now + 3, 0 / 0, 1) == 0)
	ledger:Clear()
	assert(ledger:Live(now) == 0)
end)

check("every rarity x style plans, fits auto cadence and stays inside desktop/phone budgets", function()
	assert(Config.ParticleBudget == 400 and Config.MobileParticleBudget == 150)
	for _, mobile in ipairs({ false, true }) do
		local ledger = Rules.Ledger(if mobile then Config.MobileParticleBudget else Config.ParticleBudget)
		local now = 0
		for _, rarity in ipairs(order) do
			for _, style in ipairs(Config.StyleOrder) do
				local plan = Rules.Plan(Config, rarity, { Intensity = "Full", Style = style, Mobile = mobile })
				assert(plan and plan.Style == style and plan.Duration > 0, rarity .. " " .. style)
				assert(plan.Land + plan.BounceTime <= plan.Duration + 1e-9)
				local auto =
					Rules.Plan(Config, rarity, { Intensity = "Full", Style = style, Cooldown = 0.4, Mobile = mobile })
				if not auto.Big then
					assert(auto.Duration <= 0.4 + 1e-9, rarity .. " " .. style .. " overruns auto cadence")
				end
				for _, key in ipairs(Config.ParticleKeys) do
					ledger:Grant(now, plan[key], 2.6)
					assert(ledger:Live(now) <= ledger.Cap)
				end
				now += 0.05
			end
		end
	end
end)
check("envelopes, slow-motion remap and FOV punch are bounded", function()
	for i = -10, 200 do
		local t = i / 100
		local pulse = Rules.Pulse(t, 0.05, 0.5)
		assert(pulse >= 0 and pulse <= 1)
	end
	assert(
		Rules.Pulse(-0.01, 0.05, 0.5) == 0 and Rules.Pulse(0.05, 0.05, 0.5) == 1 and Rules.Pulse(0.56, 0.05, 0.5) == 0
	)
	for _, hang in ipairs({ 0, 0.3, 0.75, 0.95, 2 }) do
		local last = -1
		for i = 0, 100 do
			local u = Rules.Hang(i / 100, hang)
			assert(u >= last - 1e-9 and u >= 0 and u <= 1 + 1e-9, "remap must be monotonic")
			last = u
		end
		assert(math.abs(Rules.Hang(1, hang) - 1) < 1e-9 and Rules.Hang(0, hang) == 0)
	end
	assert(Rules.Hang(0.55, 0.75) - Rules.Hang(0.45, 0.75) < 0.1 * 0.5, "apex is suspended")
	assert(Rules.ArcHeight(0.5, 10) == 10 and Rules.ArcHeight(0, 10) == 0 and Rules.ArcHeight(1, 10) == 0)
	for _, rarity in ipairs(order) do
		local plan = Rules.Plan(Config, rarity, { Intensity = "Full" })
		local sawGulp, sawPunch = false, false
		for i = 0, math.ceil(plan.Duration * 100) do
			local offset = Rules.FovOffset(plan, i / 100, Config.Camera)
			assert(math.abs(offset) <= plan.Fov + 1e-9 and plan.Fov <= 12)
			sawGulp = sawGulp or offset < 0
			sawPunch = sawPunch or offset > 0
		end
		assert(sawPunch and (sawGulp or plan.Burst == 0))
		assert(Rules.FovOffset(plan, plan.Duration + 1, Config.Camera) == 0)
	end
end)

check("engine textures are bundled paths, never uploaded IDs", function()
	for name, path in pairs(Assets.Textures) do
		assert(type(path) == "string" and path:match("^rbxasset://textures/particles/"), name)
	end
end)

print(string.format("Flush FX rules: %d passed", passed))
