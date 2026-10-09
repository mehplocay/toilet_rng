local Mix = require("../src/client/Audio/Mix")
local Settings = require("../src/shared/AudioSettings")
local Audio = require("../src/shared/Config/Audio")
local Assets = require("../src/shared/Config/Assets")
local function near(a, b)
	assert(math.abs(a - b) < 1e-10, tostring(a) .. " != " .. tostring(b))
end
local defaults = Settings.Sanitize(nil, Audio.Defaults)
near(defaults.MusicVolume, 0.6)
near(defaults.SFXVolume, 0.7)
assert(not defaults.MusicMuted and not defaults.SFXMuted)
local migrated = Settings.Migrate({ MusicVolume = 0.25, SFXVolume = 0.4, MusicMuted = true }, Audio.Defaults)
assert(migrated.MusicVolume == 0.6 and migrated.SFXVolume == 0.4 and migrated.MusicMuted)
assert(migrated.AudioSettingsVersion == Settings.Version and not migrated.MusicVolumeCustomized)
assert(Settings.Migrate(migrated, Audio.Defaults).MusicVolume == 0.6, "Migration was not idempotent")
for _, volume in ipairs({ 0, 0.1, 0.35, 0.8, 1 }) do
	local custom = Settings.Migrate({ MusicVolume = volume }, Audio.Defaults)
	near(custom.MusicVolume, volume)
	assert(custom.MusicVolumeCustomized)
end
for _, raw in ipairs({
	{ MusicVolume = 0.25, MusicVolumeCustomized = true },
	{ MusicVolume = 0.25, AudioSettingsVersion = Settings.Version },
}) do
	near(Settings.Migrate(raw, Audio.Defaults).MusicVolume, 0.25)
end
local malformed = Settings.Migrate(
	{ MusicVolume = 0 / 0, AudioSettingsVersion = math.huge, MusicVolumeCustomized = "yes" },
	Audio.Defaults
)
assert(malformed.MusicVolume == 0.6 and malformed.AudioSettingsVersion == 2 and not malformed.MusicVolumeCustomized)
for _, version in ipairs({ -1, 1.5, 0 / 0, "2", {} }) do
	assert(Settings.Migrate({ MusicVolume = 0.25, AudioSettingsVersion = version }, Audio.Defaults).MusicVolume == 0.6)
end
local legacy = Settings.Sanitize({ Sound = false }, Audio.Defaults)
assert(legacy.MusicMuted and legacy.SFXMuted)
local bad = Settings.Sanitize({ MusicVolume = 0 / 0, SFXVolume = math.huge, MusicMuted = "yes" }, Audio.Defaults)
near(bad.MusicVolume, 0.6)
near(bad.SFXVolume, 0.7)
local clamped = Settings.Sanitize({ MusicVolume = -1, SFXVolume = 99 }, Audio.Defaults)
assert(clamped.MusicVolume == 0 and clamped.SFXVolume == 1)
assert(Settings.ValidRequest(defaults))
for _, value in ipairs({
	{},
	{ MusicVolume = 0.5 },
	{ MusicVolume = 0 / 0, SFXVolume = 0.7, MusicMuted = false, SFXMuted = false },
	"true",
	1,
}) do
	assert(not Settings.ValidRequest(value))
end
local extra = table.clone(defaults)
extra.Coins = 999
assert(not Settings.ValidRequest(extra))
local profile = { PlotColor = "Mint", SkipAnimation = true }
Settings.Apply(profile, defaults)
assert(profile.PlotColor == "Mint" and profile.SkipAnimation)
Settings.Apply(profile, false)
assert(profile.MusicMuted and profile.SFXMuted and profile.Sound == false)
assert(profile.AudioSettingsVersion == Settings.Version)
Settings.Apply(profile, { MusicVolume = 0.25, SFXVolume = 0.7, MusicMuted = false, SFXMuted = false })
assert(profile.MusicVolumeCustomized and Settings.Migrate(profile, Audio.Defaults).MusicVolume == 0.25)
assert(not Settings.ValidRequest(migrated), "Clients can forge migration metadata")
near(Mix.Volume(0.6, false, 0.6), 0.36)
assert(Audio.Defaults.MusicVolume == 0.6 and Audio.DuckGain == 0.6 and Audio.DuckRelease == 1.5)
assert(#Audio.MusicTrackGains == #Assets.Music)
for _, gain in ipairs(Audio.MusicTrackGains) do
	assert(gain > 0 and gain <= 10) -- Roblox Sound.Volume maximum
end
near(Mix.Volume(0.7, true), 0)
local start, fade = Mix.Crossfade(120, 3)
assert(start == 117 and fade == 3)
start, fade = Mix.Crossfade(1, 3)
assert(start == 0.5 and fade == 0.5)
start, fade = Mix.Crossfade(0, 3)
assert(start == 0 and fade == 0)
-- Linear complementary deck gains never increase the summed gain above one.
for i = 0, 100 do
	local alpha = i / 100
	near(Mix.Volume(0.6, false, 0.6) * ((1 - alpha) + alpha), 0.36)
end
local deadlines = {}
Mix.DuckUntil(deadlines, "Reveal", 10, 2.4)
Mix.DuckUntil(deadlines, "Event", 11, 5)
Mix.DuckUntil(deadlines, "Event", 12, 5)
Mix.DuckUntil(deadlines, "Event", 12, 1)
near(Mix.DuckGain(deadlines, 12.5, 0.6), 0.6)
near(Mix.DuckGain(deadlines, 16.9, 0.6), 0.6)
near(Mix.DuckGain(deadlines, 17, 0.6), 1)
assert(next(deadlines) == nil)
for i = 1, 100 do
	Mix.DuckUntil(deadlines, i, 20, 5)
end
near(Mix.Volume(Audio.Defaults.MusicVolume, false, Mix.DuckGain(deadlines, 24, Audio.DuckGain)), 0.36)
near(Mix.Volume(Audio.Defaults.MusicVolume, true, Mix.DuckGain(deadlines, 24, Audio.DuckGain)), 0)
for _ = 1, 50 do
	local bag = Mix.Shuffle({ "a", "b", "c", "d", "e" }, "a", math.random)
	assert(#bag == 5 and bag[1] ~= "a")
	local seen = {}
	for _, track in ipairs(bag) do
		assert(not seen[track])
		seen[track] = true
	end
end
assert(Mix.Shuffle({ "a" }, "a", math.random)[1] == "a")
near(Mix.Pitch(0, -0.05), 0.95)
near(Mix.Pitch(0, 0.05), 1.05)
assert(Mix.Pitch(4, 0) > Mix.Pitch(3, 0))
near(Mix.Pitch(99, 0), Mix.Pitch(8, 0))
require("./audio-id-checks")(Assets, Audio)
-- Admission is shared by production playback. A hover storm cannot steal a stinger.
local voices = { epic = { Key = "Epic", Started = 0 } }
local allowed, victim = Mix.Admit(Audio, "Secret", 1, {}, voices)
assert(allowed and victim == "epic")
voices = { secret = { Key = "Secret", Started = 0 } }
assert(not Mix.Admit(Audio, "Epic", 10, {}, voices))
assert(not Mix.Admit(Audio, "Secret", 10, {}, voices), "Per-slot cap ignored")
assert(not Mix.Admit(Audio, "Click", 1, { Click = 0.98 }, {}), "Cooldown ignored")
assert(Mix.Admit(Audio, "Click", 1, { Click = 0.5 }, {}))
local tiny = table.clone(Audio)
tiny.MaxVoices = 1
assert(not Mix.Admit(tiny, "Hover", 10, {}, voices), "UI stole a high-priority voice")
allowed, victim = Mix.Admit(tiny, "Secret", 10, {}, { hover = { Key = "Hover", Started = 0 } })
assert(allowed and victim == "hover")
local previousPitch = 0
for _, amount in ipairs({ 0, 1, 10, 100, 1000, 1000000, 9e15, math.huge }) do
	local pitch = Mix.AmountPitch(amount)
	assert(pitch >= previousPitch and pitch <= 1.24)
	previousPitch = pitch
end
assert(Mix.AmountPitch(0 / 0) == 1 and Mix.AmountPitch(-1) == 1)
-- Stress every slot at 20 Hz and realistic fast/normal flush intervals for a minute.
for _, cadence in ipairs({ 0.05, 0.4, 1.5 }) do
	local active, last, nextId = {}, {}, 0
	for tick = 0, math.floor(60 / cadence) do
		local now = tick * cadence
		for id, voice in pairs(active) do
			if voice.Until <= now then
				active[id] = nil
			end
		end
		for key, cue in pairs(Audio.Cues) do
			local admit, steal = Mix.Admit(Audio, key, now, last, active)
			if admit then
				if steal then
					active[steal] = nil
				end
				nextId += 1
				active[nextId] = { Key = key, Started = now, Until = now + cue.Length / 0.95 + 0.15 }
				last[key] = now
			end
			local total, slots, classes = 0, {}, {}
			for _, voice in pairs(active) do
				local class = Audio.Cues[voice.Key].Class
				total += 1
				slots[voice.Key] = (slots[voice.Key] or 0) + 1
				classes[class] = (classes[class] or 0) + 1
			end
			assert(total <= Audio.MaxVoices)
			for slot, count in pairs(slots) do
				assert(count <= Audio.Cues[slot].MaxVoices)
			end
			for class, count in pairs(classes) do
				assert(count <= Audio.ClassLimits[class])
			end
		end
	end
end
for key, cue in pairs(Audio.Cues) do
	assert(cue.Gap > 0 and cue.MaxVoices >= 1 and cue.Length > 0 and cue.Variation <= 0.05, key)
	assert(cue.Class ~= "stinger" or cue.Duck, key)
end
for key in pairs(Assets.Sounds) do
	assert(Audio.Cues[key], key)
end
print("Audio admission checks passed: cooldowns, slot/class/global caps, priority, rapid stress and amount pitch")
print(
	"Audio logic checks passed: profile migration, validation, gains, crossfade scheduling, overlapping ducks, shuffle and pitch"
)
