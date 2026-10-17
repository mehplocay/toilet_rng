-- Pure flush-presentation rules: tier plans, cadence collapse, budgets and envelopes.
-- No engine access, so the CLI tests exercise exactly what the client runs.
local Rules = {}

local function positive(value)
	return if type(value) == "number" and value == value and value > 0 and value < math.huge then value else nil
end

local function round(value)
	return math.max(0, math.floor(value + 0.5))
end

-- Returns a fresh plan table or nil when nothing should play.
-- options: Intensity ("Full"/"Reduced"/"Off"), Compact, Cooldown, Gap, Mobile,
-- ActiveRank and ActiveRemaining (the running effect, if any).
function Rules.Plan(config, rarity, options)
	options = options or {}
	local entry = config.Rarities[rarity]
	if not entry or options.Intensity == "Off" or options.Compact then
		return nil
	end
	local plan = table.clone(config.Levels[entry.Level])
	plan.Level, plan.Rarity = entry.Level, rarity
	plan.WindUp = entry.WindUp or plan.WindUp
	plan.TimeScale, plan.Collapsed, plan.Underlay, plan.Reduced = 1, false, false, false
	local scale = {}
	for _, key in ipairs(config.CountKeys) do
		scale[key] = entry.Boost or 1
	end
	local function multiply(keys, factor)
		for _, key in ipairs(keys) do
			scale[key] *= factor
		end
	end
	local function screenOff()
		plan.Fov, plan.Shake, plan.Flash, plan.Grade, plan.Vignette = 0, 0, 0, 0, 0
		plan.Rays, plan.ScreenRings, plan.ScreenConfetti, plan.RarityText = 0, 0, 0, false
	end
	if options.Intensity == "Reduced" then
		-- Reduced motion / quick reveals: brief world one-shots and coins only.
		plan.Reduced = true
		screenOff()
		plan.WindUp, plan.Hang, plan.Confetti, plan.FanBeams, plan.Pillar = 0, 0, 0, 0, false
		plan.Light *= 0.5
		plan.Duration = math.min(plan.Duration, config.ReducedDuration)
		plan.CometTime = math.min(plan.CometTime, plan.Duration * 0.6)
		multiply(config.ParticleKeys, config.ReducedScale)
	end
	local cadence = math.min(positive(options.Cooldown) or math.huge, positive(options.Gap) or math.huge)
	if not plan.Big and cadence < plan.Duration then
		-- Faster than the effect: compress time and thin particles; the next flush always fits.
		local timeScale = math.clamp(cadence * config.CadenceFill / plan.Duration, config.MinTimeScale, 1)
		plan.Collapsed, plan.TimeScale = true, timeScale
		plan.WindUp = if cadence < config.WindUpMinGap then 0 else plan.WindUp * timeScale
		plan.Duration *= timeScale
		plan.CometTime *= timeScale
		plan.Hang = 0
		plan.Fov *= 0.5
		plan.Shake, plan.Vignette = 0, 0
		plan.Flash *= 0.5
		plan.Grade *= 0.5
		multiply(config.ParticleKeys, config.CollapsedScale)
		multiply({ "Coins", "ScreenRings" }, config.CollapsedScale)
	end
	local activeRemaining = positive(options.ActiveRemaining) or 0
	if (options.ActiveRank or 0) > plan.Rank and activeRemaining > 0 then
		-- A bigger moment is still playing: add only world one-shots beneath it.
		plan.Underlay = true
		screenOff()
		plan.Pillar, plan.FanBeams, plan.Light, plan.Comet = false, 0, 0, false
		plan.WindUp = 0
	end
	if plan.Comet == nil then
		plan.Comet = true
	end
	if options.Mobile then
		multiply(config.ParticleKeys, config.MobileScale)
	end
	for _, key in ipairs(config.CountKeys) do
		local value = round((plan[key] or 0) * scale[key])
		local cap = config.Caps[key] or math.huge
		if options.Mobile and config.MobileCaps[key] then
			cap = math.min(cap, config.MobileCaps[key])
		end
		plan[key] = math.min(value, cap)
	end
	plan.Burst = plan.WindUp
	plan.Land = plan.WindUp + plan.CometTime
	plan.Duration = math.max(plan.Duration, plan.Land + 0.05)
	return plan
end

-- Attack/release envelope in [0, 1]: linear rise, quadratic fall, zero outside.
function Rules.Pulse(t, attack, release)
	if t < 0 or t >= attack + release then
		return 0
	end
	if t < attack then
		return if attack > 0 then t / attack else 1
	end
	local u = 1 - (t - attack) / release
	return u * u
end

-- Monotonic time remap with a slow middle ("hang" in [0, 1)): fast launch, suspended apex.
function Rules.Hang(u, hang)
	u = math.clamp(u, 0, 1)
	hang = math.clamp(hang or 0, 0, 0.95)
	return u + hang * math.sin(2 * math.pi * u) / (2 * math.pi)
end

-- Parabolic arc height for normalized time u, peaking at apex when u = 0.5.
function Rules.ArcHeight(u, apex)
	u = math.clamp(u, 0, 1)
	return apex * 4 * u * (1 - u)
end

-- Bounded FOV offset (degrees): a short inward "gulp" before the burst, then a punch out.
function Rules.FovOffset(plan, t, cameraConfig)
	if plan.Fov <= 0 or t < 0 then
		return 0
	end
	local release = cameraConfig.PunchRelease * math.max(plan.TimeScale, 0.5)
	if t < plan.Burst and plan.Burst > 0 then
		return -plan.Fov * cameraConfig.GulpFraction * (t / plan.Burst)
	end
	return plan.Fov * Rules.Pulse(t - plan.Burst, 0.05, release)
end

-- Live-particle ledger: each emit reserves capacity until its particles expire.
function Rules.Ledger(cap)
	local self = { Cap = cap, Entries = {} }
	function self:Live(now)
		local live = 0
		for i = #self.Entries, 1, -1 do
			local entry = self.Entries[i]
			if entry.Until <= now then
				table.remove(self.Entries, i)
			else
				live += entry.Count
			end
		end
		return live
	end
	function self:Grant(now, count, lifetime)
		count = math.max(0, math.floor(count or 0))
		local granted = math.min(count, math.max(0, self.Cap - self:Live(now)))
		if granted > 0 then
			table.insert(self.Entries, { Until = now + math.max(0, lifetime or 0), Count = granted })
		end
		return granted
	end
	function self:Clear()
		table.clear(self.Entries)
	end
	return self
end

-- Settings precedence shared with the reveal: Off > Reduced (or quick reveals) > Full.
function Rules.Intensity(revealIntensity, skipAnimation)
	if revealIntensity == "Off" then
		return "Off"
	end
	if revealIntensity == "Reduced" or skipAnimation == true then
		return "Reduced"
	end
	return "Full"
end

return Rules
