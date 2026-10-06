-- Engine-independent scheduling and gain math, exercised by check-audio.luau.
local Mix = {}
function Mix.Volume(volume, muted, duck)
	return if muted then 0 else math.clamp(volume, 0, 1) * math.clamp(duck or 1, 0, 1)
end
function Mix.Crossfade(length, requested)
	local duration = math.min(requested, math.max(0, length / 2))
	return math.max(0, length - duration), duration
end
function Mix.DuckUntil(deadlines, key, now, duration)
	deadlines[key] = math.max(deadlines[key] or 0, now + duration)
end
function Mix.DuckGain(deadlines, now, gain)
	local active = false
	for key, deadline in pairs(deadlines) do
		if deadline > now then
			active = true
		else
			deadlines[key] = nil
		end
	end
	return if active then gain else 1
end
function Mix.Shuffle(tracks, previous, random)
	local bag = table.clone(tracks)
	for i = #bag, 2, -1 do
		local j = random(1, i)
		bag[i], bag[j] = bag[j], bag[i]
	end
	if #bag > 1 and bag[1] == previous then
		bag[1], bag[2] = bag[2], bag[1]
	end
	return bag
end
function Mix.Pitch(combo, variation)
	return (1 + math.clamp(combo or 0, 0, 8) * 0.035) * (1 + math.clamp(variation, -0.05, 0.05))
end
-- Decide admission without mutating clocks or voices. Rejected cues are never queued.
function Mix.Admit(config, key, now, last, voices)
	local cue = config.Cues[key]
	if not cue or now - (last[key] or -math.huge) < cue.Gap then
		return false
	end
	local total, same, class = 0, 0, 0
	local victim, weakest, oldest = nil, math.huge, math.huge
	local classVictim, classPriority, classOldest = nil, math.huge, math.huge
	for sound, voice in pairs(voices) do
		total += 1
		same += if voice.Key == key then 1 else 0
		local priority = config.Cues[voice.Key].Priority
		if priority < weakest or (priority == weakest and voice.Started < oldest) then
			victim, weakest, oldest = sound, priority, voice.Started
		end
		if config.Cues[voice.Key].Class == cue.Class then
			class += 1
			if priority < classPriority or (priority == classPriority and voice.Started < classOldest) then
				classVictim, classPriority, classOldest = sound, priority, voice.Started
			end
		end
	end
	if same >= cue.MaxVoices then
		return false
	end
	if class >= config.ClassLimits[cue.Class] then
		-- A stronger stinger can replace a lesser one, never the reverse.
		return cue.Priority > classPriority, classVictim
	end
	if total >= config.MaxVoices then
		return cue.Priority > weakest, victim
	end
	return true
end
function Mix.AmountPitch(amount)
	local value = if type(amount) == "number" and amount == amount then math.clamp(amount, 0, 9e15) else 0
	return 1 + math.min(0.24, math.log10(1 + value) * 0.04)
end
return Mix
