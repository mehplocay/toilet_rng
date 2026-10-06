-- Check shipped configuration, independently of runtime's optional empty-safe IDs.
return function(assets, audio)
	local errors, seen, slots = {}, {}, 0
	local function check(key, id)
		slots += 1
		local digits = type(id) == "string" and id:match("^rbxassetid://(%d+)$")
		if not digits or #digits < 12 or #digits > 17 or digits:sub(1, 1) == "0" then
			table.insert(errors, "Slot without valid 12-17 digit ID: " .. key)
		elseif
			seen[digits]
			and not (
				(key == "Celestial" and seen[digits] == "Godly") or (key == "Godly" and seen[digits] == "Celestial")
			)
		then
			table.insert(errors, "Duplicate ID: " .. key .. " / " .. seen[digits])
		else
			seen[digits] = key
		end
	end
	assert(#assets.Music == 5, "Expected five music slots")
	for index, id in ipairs(assets.Music) do
		check("Music" .. index, id)
	end
	for key in pairs(audio.Cues) do
		check(key, assets.Sounds[key])
	end
	for key in pairs(assets.Sounds) do
		if not audio.Cues[key] then
			table.insert(errors, "ID without runtime slot: " .. key)
		end
	end
	assert(#errors == 0, table.concat(errors, "\n"))
	assert(slots == 54, "Expected 54 logical audio slots (53 unique assets)")
	assert(audio.Cues.Ambience.Looped and audio.Cues.RebirthHold.Looped)
	assert(audio.StopFade >= 0.02 and audio.StopFade <= 0.03)
	assert(audio.LoopAttack >= 0.02 and audio.LoopAttack <= 0.03)
	assert(audio.ClassGains.stinger < audio.ClassGains.reward)
	assert(audio.Cues.Ambience.Gain <= 0.055)
	print("Audio ID coverage passed: 53 unique numeric IDs; no missing slots or orphan IDs; loop/fade/mix contract")
end
