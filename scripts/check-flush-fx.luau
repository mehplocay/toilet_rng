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
	assert(common.Flash == 0 and common.Rays == 0 and common.Duration <= 0.8 and not common.RarityText)
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
