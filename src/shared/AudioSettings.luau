-- Pure profile migration and remote validation. Only audio fields are writable here.
local Settings = {}
Settings.Version = 2
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
-- Only the server's profile loader migrates persisted settings. Client slider
-- values use Sanitize directly, so an intentional 25% selection stays 25%.
function Settings.Migrate(raw, defaults)
	raw = if type(raw) == "table" then raw else {}
	local result = Settings.Sanitize(raw, defaults)
	local version = raw.AudioSettingsVersion
	local current = finite(version) and version % 1 == 0 and version >= Settings.Version
	local customized = raw.MusicVolumeCustomized == true
	-- Legacy profiles did not record intent: an unmarked old default is assumed
	-- untouched. All other values, explicit flags and current schemas are kept.
	if not current and not customized and raw.MusicVolume == 0.25 then
		result.MusicVolume = defaults.MusicVolume
	end
	result.AudioSettingsVersion = Settings.Version
	result.MusicVolumeCustomized = customized or (finite(raw.MusicVolume) and raw.MusicVolume ~= 0.25 and not current)
	return result
end
function Settings.ValidRequest(raw)
	if type(raw) == "boolean" then
		return true -- Older clients can still set the master preference.
	end
	if type(raw) ~= "table" or getmetatable(raw) ~= nil then
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
		if request.MusicVolume ~= target.MusicVolume then
			target.MusicVolumeCustomized = true
		end
		for key in pairs(fields) do
			target[key] = request[key]
		end
		target.Sound = not (target.MusicMuted and target.SFXMuted)
	end
	target.AudioSettingsVersion = Settings.Version
end
return Settings
