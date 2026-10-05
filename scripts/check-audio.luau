local Mix = require("../src/client/Audio/Mix")
local Settings = require("../src/shared/AudioSettings")
local Audio = require("../src/shared/Config/Audio")
local Assets = require("../src/shared/Config/Assets")
local function near(a, b)
	assert(math.abs(a - b) < 1e-10, tostring(a) .. " != " .. tostring(b))
end
local defaults = Settings.Sanitize(nil, Audio.Defaults)
near(defaults.MusicVolume, 0.25)
near(defaults.SFXVolume, 0.7)
assert(not defaults.MusicMuted and not defaults.SFXMuted)
local legacy = Settings.Sanitize({ Sound = false }, Audio.Defaults)
assert(legacy.MusicMuted and legacy.SFXMuted)
local bad = Settings.Sanitize({ MusicVolume = 0 / 0, SFXVolume = math.huge, MusicMuted = "yes" }, Audio.Defaults)
near(bad.MusicVolume, 0.25)
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
near(Mix.Volume(0.25, false, 0.4), 0.1)
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
	near(Mix.Volume(0.25, false, 0.4) * ((1 - alpha) + alpha), 0.1)
end
local deadlines = {}
Mix.DuckUntil(deadlines, "Reveal", 10, 2.4)
Mix.DuckUntil(deadlines, "Event", 11, 5)
Mix.DuckUntil(deadlines, "Event", 12, 5)
Mix.DuckUntil(deadlines, "Event", 12, 1)
near(Mix.DuckGain(deadlines, 12.5, 0.4), 0.4)
near(Mix.DuckGain(deadlines, 16.9, 0.4), 0.4)
near(Mix.DuckGain(deadlines, 17, 0.4), 1)
assert(next(deadlines) == nil)
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
assert(#Assets.Music == 5)
for _, id in ipairs(Assets.Music) do
	assert(id == "")
end
for key in pairs(Audio.Cues) do
	assert(Assets.Sounds[key] == "", key)
end
print(
	"Audio logic checks passed: profile migration, validation, gains, crossfade scheduling, overlapping ducks, shuffle and pitch"
)
