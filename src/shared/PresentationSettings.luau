-- Independent patches cannot overwrite audio, currency or other profile fields.
local Settings = {}
local modes = { Full = true, Reduced = true, Off = true }
local chatModes = { All = true, ["Rare+"] = true, Off = true }
function Settings.ChatMode(raw)
	raw = if type(raw) == "table" then raw else {}
	return if type(raw.ChatMessages) == "string" and chatModes[raw.ChatMessages]
		then raw.ChatMessages
		else (if raw.ChatAnnouncements == false then "Off" else "Rare+")
end
function Settings.Allows(raw, rarity)
	local mode = Settings.ChatMode(raw)
	return mode ~= "Off" and (mode == "All" or (rarity ~= "Common" and rarity ~= "Uncommon"))
end
function Settings.Sanitize(raw)
	raw = if type(raw) == "table" then raw else {}
	return {
		RevealIntensity = if type(raw.RevealIntensity) == "string" and modes[raw.RevealIntensity]
			then raw.RevealIntensity
			else (if raw.SkipAnimation == true then "Reduced" else "Full"),
		ChatMessages = Settings.ChatMode(raw),
		ChatAnnouncements = Settings.ChatMode(raw) ~= "Off",
	}
end
function Settings.ValidRequest(raw)
	if type(raw) ~= "table" then
		return false
	end
	local count = 0
	for key, value in pairs(raw) do
		count += 1
		if count > 2 or (raw.ChatMessages ~= nil and raw.ChatAnnouncements ~= nil) then
			return false
		end
		if key == "RevealIntensity" then
			if type(value) ~= "string" or not modes[value] then
				return false
			end
		elseif key == "ChatAnnouncements" then
			if type(value) ~= "boolean" then
				return false
			end
		elseif key == "ChatMessages" then
			if type(value) ~= "string" or not chatModes[value] then
				return false
			end
		else
			return false
		end
	end
	return count > 0
end
function Settings.Apply(target, patch)
	for key, value in pairs(patch) do
		target[key] = value
	end
	-- Older boolean requests still migrate; the enum is authoritative once saved.
	if patch.ChatMessages ~= nil then
		target.ChatAnnouncements = patch.ChatMessages ~= "Off"
	elseif patch.ChatAnnouncements ~= nil then
		target.ChatMessages = if patch.ChatAnnouncements then "Rare+" else "Off"
	end
end
return Settings
