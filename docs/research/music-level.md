# Music level and playback audit — 2026-10-07

Branch: `fix/music-level`. All changes remain uncommitted. Source OGGs and uploaded IDs are unchanged.

## Measurement

`scripts/measure-audio-mix.py` decodes **all 53 shipped OGGs**, rather than reading old manifest levels. It uses the existing libsndfile 1.2.2 decoder and NumPy meter in `audio_support.py`: K-weighting, 400 ms windows, 100 ms steps, absolute/relative gates. These are **integrated LUFS estimates**, not certified BS.1770 readings. Clips shorter than 400 ms have no integrated value; the JSON labels their ungated K-weighted proxy separately. Peaks are decoded sample peaks, not true peaks. No standalone ffmpeg is installed here. Raw measurements and runtime gain projections are in [music-levels.json](music-levels.json).

Reproduce from the repository root:

```powershell
$musicPython = 'C:/Users/mehme/tools/blender/blender-4.5.10-windows-x64/4.5/python/bin/python.exe'
& $musicPython scripts/measure-audio-mix.py
```

Runtime projections add `20*log10(gain)` to the measured source. They exclude Roblox EQ, fades, simultaneous sources, platform transcoding and device/master volume. Source numbers are identical before/after because no mastering or uploads changed.

| Track | Source LUFS estimate | Source peak dBFS | Old default LUFS estimate | New default LUFS estimate | New track gain |
| --- | ---: | ---: | ---: | ---: | ---: |
| Music1 | -21.38 | -6.19 | -33.42 | -29.97 | 0.62 |
| Music2 | -19.33 | -6.22 | -31.38 | -29.97 | 0.49 |
| Music3 | -18.21 | -6.13 | -30.26 | -29.98 | 0.43 |
| Music4 | -19.69 | -6.11 | -31.73 | -29.98 | 0.51 |
| Music5 | -20.30 | -6.10 | -32.34 | -29.93 | 0.55 |

Music's old default was 25%, with a 40% duck multiplier: **-41.38 to -38.22** estimated LUFS during a cue. The new default is 60%, balanced by track trims, with a 60% duck multiplier: **-34.42 to -34.37** estimated LUFS. Unducked improvements are **0.28–3.45 dB**, ducked improvements **3.80–6.97 dB**. Playlist spread falls from 3.17 dB to 0.06 dB. Default output sample peaks are approximately -17.90 to -14.78 dBFS.

| Foreground cue | Source LUFS estimate | Source peak dBFS | Default runtime LUFS estimate (unchanged) |
| --- | ---: | ---: | ---: |
| Flush | -18.14 | -6.60 | -29.20 |
| Epic | -14.47 | -3.74 | -29.70 |
| Legendary | -13.97 | -4.37 | -28.15 |
| Godly | -13.97 | -2.90 | -26.85 |
| Secret | -14.01 | -4.05 | -26.42 |
| ServerEvent | -13.96 | -3.52 | -27.87 |
| RebirthSuccess | -14.98 | -3.66 | -27.87 |

The stable music bed stays below the main Flush and rarity fanfares; ducking provides approximately 4.7–8 dB separation during rarity fanfares. Tiny hover, background notifications and plumbing accents intentionally remain quieter. Short SFX do not support a fair integrated-LUFS comparison; see their proxy/peaks in the JSON. These numbers support the mix choice, but cannot establish subjective audibility or fatigue without listening.

## Playback and settings decisions

- Global music Sounds are parented to SoundService and explicitly assigned to the Music SoundGroup. Sound.Volume carries only track gain/fade; SoundGroup.Volume carries the slider and one duck multiplier. No double application was found.
- Preserve the 2.5 s initial fade and complementary linear crossfades of up to 3 s. With trims ≤1, the summed deck gain cannot exceed the louder deck's trim. Independent tracks can have a short power dip; equal-power fades would add an overlap boost, so no fade-law change is needed for this fix.
- Duck requests overlap as deadlines, never multiply. Music ducks to 60% of its selected level with a 0.15 s sine attack and 1.5 s sine release. Mute/zero remains respected, including preview.
- A hung PreloadAsync previously left MusicPreloadBusy set forever and prevented every later track attempt. Timeout now cancels the single suspended worker, frees the gate and retries with a five-second delay after a playlist failure. Preload success waits for IsLoaded and positive TimeLength until the deadline; errors/timeouts are reported once per attempt. A looping current deck remains audible while replacement loads/fails.
- Settings now show named percentage labels, full-width mute controls, a Test sound button (existing PurchaseSuccess cue) and Preview music (auditions the actual playing playlist at the selected mix, without adding a second bed). Buttons report mute/zero/loading instead of overriding preferences. No preview sends a settings remote.
- AudioSettingsVersion=2 and MusicVolumeCustomized are server-owned persisted fields. Only profile loading runs Migrate; client Sanitize and the four-field remote contract do not accept metadata. Requests changing MusicVolume mark it customized. Save, reload, respawn and rebirth retain the migrated/current schema.
- **Legacy assumption:** previous saves contain no edit history. An unversioned, unmarked exact 0.25 is assumed to be the old default and migrates once. Other values, explicit customized flags and version-2 values—including deliberate 0.25—stay unchanged. It is impossible to distinguish a deliberately selected legacy 0.25 from the old default using the available data. This limitation was raised with the owner during implementation.

## Current sources checked before implementation

- [SoundGroup](https://create.roblox.com/docs/reference/engine/classes/SoundGroup): volume is a multiplier; assign Sound.SoundGroup explicitly; nested groups also contribute.
- [Sound](https://create.roblox.com/docs/reference/engine/classes/Sound): non-part/attachment parenting gives global audio; check IsLoaded and TimeLength; Pause/Resume preserve playback position.
- [ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider): PreloadAsync yields, per-asset callbacks report final status, and asset failures do not necessarily throw.
- [TweenService](https://create.roblox.com/docs/reference/engine/classes/TweenService) and [task](https://create.roblox.com/docs/reference/engine/libraries/task): tween cancellation and thread cancellation support bounded work and clean teardown.
- [DevForum SoundService loading report](https://devforum.roblox.com/t/sounds-in-soundservice-no-longer-respect-isloaded-or-preloading/3604543): an engine bug report describes failed preload/IsLoaded behavior; Roblox staff could not initially reproduce it. Do not assume this report proves the owner's issue or bypass asset permissions.
- [Release notes 737](https://create.roblox.com/docs/release-notes/release-notes-737): audio metering changes concern PlaybackLoudness/AudioAnalyzer; no stated replacement for Sound's volume/loading contract. This fix retains the existing Sound pipeline.
- [FFmpeg filters](https://www.ffmpeg.org/ffmpeg-filters.html): ebur128/loudnorm provide an independent future verification path. The local estimate is explicitly labeled instead of claiming FFmpeg measurements.
- [Rojo binary builds](https://rojo.space/docs/v7/getting-started/new-game/), [StyLua options](https://github.com/JohnnyMorganz/StyLua), [Selene](https://github.com/Kampfkarren/selene): binary build.rbxl output and explicit Windows/CRLF formatting are retained.

## Verification boundary

Passed: all 23 standalone `scripts/check-*.luau` files plus the bundled `check-audit.luau` (329 regressions, zero failures) and `check-ui-runtime.luau` through their PowerShell runners; `check-ui.ps1` including coverage and 972 viewport cases; `check-visuals.ps1`; `check-world.ps1` in Empty/Ready/Mixed/Invalid/Scaled/Late modes; `stylua --check --syntax Luau --line-endings Windows` on every changed Luau file; `rojo build -o build.rbxl`; `git diff --check`. The JSON mix was checked against the -30 LUFS ±0.15 target and the unchanged Flush level. Selene was attempted but could not run: its configured Roblox standard-library definition is missing locally. No network download or fabricated lint definition was substituted.

Automated checks execute production loading, retry recovery, bus/deck gain ownership, overlapping duck floor/release, previews, mute/unmute, crossfades, schema migration and save/rejoin. Music remains global across area movement; character removal/replacement and rebirth Settings refreshes preserve the current deck. The UI harness does not render Roblox or simulate spatial audio acoustics. No Roblox Studio is connected (`list_roblox_studios` returned an empty list), so hub/plot/path listening, production permissions, device interruptions and subjective comfort require an owner Studio/published-device retest. Do not treat mocked area labels as an in-engine walkthrough.
