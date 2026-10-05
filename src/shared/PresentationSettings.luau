-- Independent patches cannot overwrite audio, currency or other profile fields.
local Settings = {}
local modes = { Full = true, Reduced = true, Off = true }
function Settings.Sanitize(raw)
	raw = if type(raw) == "table" then raw else {}
	return {
		RevealIntensity = if type(raw.RevealIntensity) == "string" and modes[raw.RevealIntensity]
			then raw.RevealIntensity
			else (if raw.SkipAnimation == true then "Reduced" else "Full"),
		ChatAnnouncements = raw.ChatAnnouncements ~= false,
	}
end
function Settings.ValidRequest(raw)
	if type(raw) ~= "table" then
		return false
	end
	local count = 0
	for key, value in pairs(raw) do
		count += 1
		if count > 2 then
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
end
return Settings
