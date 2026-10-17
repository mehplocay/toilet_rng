-- Pure flush-presentation rules: tier plans, cadence collapse, budgets and envelopes.
-- No engine access, so the CLI tests exercise exactly what the client runs.
local Rules = {}

local function positive(value)
	return if type(value) == "number" and value == value and value > 0 and value < math.huge then value else nil
end

local function round(value)
	return math.max(0, math.floor(value + 0.5))
end

-- Weight of a style for an item, or 0 when it may not play.
function Rules.StyleWeight(style, itemId)
	local boost = style.Items and itemId and style.Items[itemId]
	if boost then
		return boost
	end
	return if style.Exclusive then 0 else (style.Weight or 0)
end

-- Weighted style pick that never repeats the previous style when another one is eligible.
-- roll is a number in [0, 1); the caller owns randomness so this stays deterministic.
function Rules.PickStyle(config, last, itemId, roll)
	local total, eligible = 0, {}
	for _, name in ipairs(config.StyleOrder) do
		local weight = Rules.StyleWeight(config.Styles[name], itemId)
		if weight > 0 and name ~= last then
			total += weight
			table.insert(eligible, { Name = name, Weight = weight })
		end
	end
	if total <= 0 then
		return if last and config.Styles[last] then last else config.DefaultStyle
	end
	roll = if type(roll) == "number" and roll == roll then math.clamp(roll, 0, 1) else 0
	local target = roll * total
	for _, entry in ipairs(eligible) do
		target -= entry.Weight
		if target < 0 then
			return entry.Name
		end
	end
	return eligible[#eligible].Name
end

-- Returns a fresh plan table or nil when nothing should play.
-- options: Intensity ("Full"/"Reduced"/"Off"), Compact, Cooldown, Gap, Mobile,
-- ActiveRank and ActiveRemaining (the running effect, if any), Style (a Styles key).
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
	local styleName = if config.Styles[options.Style] then options.Style else config.DefaultStyle
	local style = config.Styles[styleName]
	plan.Style, plan.Motion, plan.Special = styleName, style.Motion, style.Special
	plan.CometApex = style.CometApex or config.CometApex
	plan.GeyserHeight *= style.GeyserMul or 1
	plan.Flash += style.FlashAdd or 0
	local scale = {}
	for _, key in ipairs(config.CountKeys) do
		scale[key] = (entry.Boost or 1) * ((style.Emit and style.Emit[key]) or 1)
	end
	scale.Coins *= style.CoinMul or 1
	local function multiply(keys, factor)
		for _, key in ipairs(keys) do
			scale[key] *= factor
		end
	end
	local function screenOff()
		plan.Fov, plan.Shake, plan.Flash, plan.Grade, plan.Vignette = 0, 0, 0, 0, 0
		plan.Rays, plan.ScreenRings, plan.ScreenConfetti, plan.RarityText = 0, 0, 0, false
		plan.Comic, plan.EmojiPops = false, 0
	end
	if options.Intensity == "Reduced" then
		-- Reduced motion / quick reveals: brief world one-shots and coins only.
		plan.Reduced = true
		screenOff()
		plan.WindUp, plan.Hang, plan.Confetti, plan.FanBeams, plan.Pillar = 0, 0, 0, 0, false
		plan.Motion, plan.Special, plan.Props = nil, nil, 0
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
		plan.Motion, plan.Special, plan.Props = nil, nil, 0
		plan.WindUp = 0
	end
	if plan.Comet == nil then
		plan.Comet = true
	end
	plan.BounceTime = if plan.Comet and not plan.Reduced then config.BounceTime * plan.TimeScale else 0
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
	plan.Duration = math.max(plan.Duration, plan.Land + plan.BounceTime + 0.02)
	return plan
end

local function damped(u, cycles, decay)
	return math.sin(u * cycles * 2 * math.pi) * math.exp(-decay * u)
end

-- Local toilet pose for motion name at normalized time u in [0, 1], scaled by power.
-- Lift is a fraction of the toilet height; angles are radians; SquashY scales height
-- (the footprint scales by 1 / sqrt(SquashY) to keep volume); Lid is a hinge angle.
function Rules.ToiletPose(motion, u, power)
	u = math.clamp(if type(u) == "number" and u == u then u else 1, 0, 1)
	power = math.clamp(if type(power) == "number" and power == power then power else 1, 0, 2)
	local lift, spin, tiltX, tiltZ, squash, lid = 0, 0, 0, 0, 0, 0
	if motion == "Hop" then
		if u < 0.15 then
			squash = -0.35 * math.sin(u / 0.15 * math.pi * 0.5)
		elseif u < 0.55 then
			local x = (u - 0.15) / 0.4
			lift = 0.45 * 4 * x * (1 - x)
			squash = 0.3 * (1 - x) - 0.05
		elseif u < 0.7 then
			squash = -0.3 * math.sin((u - 0.55) / 0.15 * math.pi)
		else
			squash = 0.12 * damped((u - 0.7) / 0.3, 2, 3)
		end
	elseif motion == "Spin" then
		local e = u * u * (3 - 2 * u)
		spin = e * 4 * math.pi
		lift = 0.25 * math.sin(u * math.pi)
		squash = 0.15 * math.sin(u * math.pi)
	elseif motion == "Squash" then
		squash = 0.4 * damped(u, 3, 2.2)
	elseif motion == "Shake" then
		local fade = 1 - u
		tiltZ = 0.14 * math.sin(u * 47) * fade
		tiltX = 0.09 * math.sin(u * 33) * fade
		lift = 0.04 * math.abs(math.sin(u * 53)) * fade
	elseif motion == "Jelly" then
		squash = 0.45 * damped(u, 2.5, 3)
		tiltZ = 0.1 * damped(u, 2, 3)
	elseif motion == "Recoil" then
		if u < 0.2 then
			squash = -0.35 * (u / 0.2)
		elseif u < 0.35 then
			local x = (u - 0.2) / 0.15
			squash = -0.35 + 0.7 * x
			lift = 0.15 * x
		else
			local x = (u - 0.35) / 0.65
			squash = 0.35 * damped(x, 2, 4)
			lift = 0.15 * (1 - x) * (1 - x)
		end
	elseif motion == "LidFlap" then
		local fade = 1 - u
		lift = 0.08 * math.abs(math.sin(u * math.pi * 4)) * fade
		lid = 1.6 * math.abs(math.sin(u * math.pi * 5)) * fade
		squash = 0.1 * math.sin(u * math.pi * 8) * fade
	elseif motion == "Popcorn" then
		local fade = 1 - u * 0.6
		local hop = math.abs(math.sin(u * math.pi * 5))
		lift = 0.18 * hop * fade
		squash = (0.25 * hop - 0.12) * fade
	else
		return { Lift = 0, Spin = 0, TiltX = 0, TiltZ = 0, SquashY = 1, Lid = 0 }
	end
	if u >= 1 then
		lift, spin, tiltX, tiltZ, squash, lid = 0, if motion == "Spin" then 4 * math.pi else 0, 0, 0, 0, 0
	end
	return {
		Lift = math.clamp(lift * power, 0, 0.9),
		Spin = spin,
		TiltX = math.clamp(tiltX * power, -0.35, 0.35),
		TiltZ = math.clamp(tiltZ * power, -0.35, 0.35),
		SquashY = math.clamp(1 + squash * power, 0.45, 1.7),
		Lid = math.clamp(lid * power, 0, 2.2),
	}
end

-- Item bounce after landing: two shrinking hops with squash on contact. Returns the
-- height fraction (of the configured bounce height) and the vertical squash factor.
function Rules.Bounce(u)
	u = math.clamp(if type(u) == "number" and u == u then u else 1, 0, 1)
	local height, squash
	if u < 0.12 then
		height, squash = 0, 1 - 0.45 * math.sin(u / 0.12 * math.pi)
	elseif u < 0.62 then
		local x = (u - 0.12) / 0.5
		height, squash = 4 * x * (1 - x), 1 + 0.3 * math.abs(1 - 2 * x)
	elseif u < 0.7 then
		height, squash = 0, 1 - 0.3 * math.sin((u - 0.62) / 0.08 * math.pi)
	else
		local x = (u - 0.7) / 0.3
		height, squash = 0.35 * 4 * x * (1 - x), 1 + 0.12 * math.abs(1 - 2 * x)
	end
	if u >= 1 then
		height, squash = 0, 1
	end
	return math.max(0, height), squash
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
