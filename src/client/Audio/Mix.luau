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
return Mix
