local Rules = {}

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Rules.AutoUnlocked(profile, config)
	local count = profile and profile.Stats and profile.Stats.Flushes
	return finite(count) and count >= config.AutoFlushUnlock
end

function Rules.InRange(distance, config)
	return finite(distance) and distance >= 0 and distance <= config.FlushRange
end

function Rules.AutoEnabled(requested, profile, distance, config)
	return requested == true and Rules.AutoUnlocked(profile, config) and Rules.InRange(distance, config)
end

function Rules.Cooldown(base, owned, config)
	return base * (if owned.FastFlush == true then config.Gamepasses.FastFlush.CooldownMultiplier else 1)
end

-- Shared reservation for manual and automatic calls; no yields before the award.
function Rules.TryFlush(nextFlush, player, now, distance, cooldown, config)
	if not Rules.InRange(distance, config) or now < (nextFlush[player] or 0) then
		return false
	end
	nextFlush[player] = now + cooldown
	return true
end

function Rules.Pass(config, key)
	return if type(key) == "string" then config.Gamepasses[key] else nil
end

function Rules.PassKey(config, id)
	for _, key in ipairs(config.PassOrder) do
		if config.Gamepasses[key].Id > 0 and config.Gamepasses[key].Id == id then
			return key
		end
	end
	return nil
end

-- Never erase a verified grant on an API error or a stale negative cache result.
function Rules.MergeOwnership(owned, key, succeeded, result)
	if succeeded and result == true then
		owned[key] = true
	elseif succeeded and owned[key] ~= true then
		owned[key] = false
	end
end

function Rules.PlotColor(config, id)
	if type(id) == "string" then
		for _, color in ipairs(config.PlotColors) do
			if color.Id == id then
				return color
			end
		end
	end
	return nil
end

function Rules.SetPlotColor(profile, owned, id, config)
	if not profile or owned.CustomPlotColor ~= true or not Rules.PlotColor(config, id) then
		return false
	end
	profile.Settings.PlotColor = id
	return true
end

function Rules.RestoreSettings(settings, raw, config)
	settings.SkipAnimation = type(raw) == "table" and raw.SkipAnimation == true
	settings.PlotColor = if type(raw) == "table" and Rules.PlotColor(config, raw.PlotColor)
		then raw.PlotColor
		else "Default"
end

return Rules
