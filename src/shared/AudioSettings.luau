-- Pure profile migration and remote validation. Only audio fields are writable here.
local Settings = {}
local fields = { MusicVolume = "number", SFXVolume = "number", MusicMuted = "boolean", SFXMuted = "boolean" }
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Settings.Sanitize(raw, defaults)
	raw = if type(raw) == "table" then raw else {}
	local result = {}
	for key, kind in pairs(fields) do
		local value = raw[key]
		result[key] = if kind == "number"
			then (if finite(value) then math.clamp(value, 0, 1) else defaults[key])
			else (if type(value) == "boolean" then value else (raw.Sound == false or defaults[key]))
	end
	return result
end
function Settings.ValidRequest(raw)
	if type(raw) == "boolean" then
		return true -- Older clients can still set the master preference.
	end
	if type(raw) ~= "table" then
		return false
	end
	local count = 0
	for key, value in pairs(raw) do
		local kind = fields[key]
		if not kind or type(value) ~= kind or (kind == "number" and (not finite(value) or value < 0 or value > 1)) then
			return false
		end
		count += 1
	end
	return count == 4
end
function Settings.Apply(target, request)
	if type(request) == "boolean" then
		target.Sound = request
		target.MusicMuted, target.SFXMuted = not request, not request
	else
		for key in pairs(fields) do
			target[key] = request[key]
		end
		target.Sound = not (target.MusicMuted and target.SFXMuted)
	end
end
return Settings
