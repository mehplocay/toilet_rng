# Original Toilet RNG audio assets

## Runtime integration — 2026-10-06

All 53 IDs from `assets/audio/uploaded-ids.json` and `uploaded-ids-2.json` are now wired into `Assets.Music[1..5]` and the 48 exact `Assets.Sounds` keys on `feature/audio-wiring`. Both manifests identify Dreadlight Studio as uploader; the synthesis manifest remains the source/provenance inventory. No audio files were regenerated or changed. Checks report no missing IDs, orphan uploads or duplicates, including the Ambience/RebirthHold loops.

The mixer preloads Music1 and short SFX without blocking startup, warms UI first, reuses the first deck and loads later music near transitions. Loop attacks and cancelled voices have a 20 ms runtime fade; music fades before pause and retains its position. Ambience is a quiet SFX bed that requires Music and SFX to be unmuted. Default class gains and effective mix values are in the [sound map](design/sound-map.md#default-runtime-volume-sanity); [current API research](research/audio-wiring.md) records privacy/access requirements. Generation-only reports below describe the earlier handoff and are retained for provenance.

Studio/published-device validation remains necessary for actual audible fades and mix, Roblox transcoding/seams, moderation, effective production universe permissions, and desktop/iOS/Android interruption behavior. Numeric ID coverage does not establish any of those.

Integration validation: all 20 `check-*.luau` files pass (18 standalone; audit/runtime files through their PowerShell harnesses), `check-audit.ps1` passes 93 regressions, and `check-ui.ps1`, `check-visuals.ps1`, all six `check-world.ps1` modes, `rojo build -o build.rbxl`, StyLua on edited Luau files and `git diff --check` pass. A full-repository default StyLua check reports pre-existing CRLF differences outside this change. Selene was attempted but its configured `roblox` standard library is missing locally. Integration changes remain uncommitted as requested.

Branch: `feature/sound-assets-2`. **53 files: 48 SFX slots plus five music tracks**, in [assets/audio/final](../assets/audio/final). The original 21 **32 kHz OGG Vorbis** files remain byte-identical; the additional 32 are **48 kHz mono OGG Vorbis**. No `src/` changes, uploads, assigned Roblox IDs, commits or pushes.

Open [the local review player](../assets/audio/review.html) to audition every file. [manifest.json](../assets/audio/manifest.json) is the machine-readable inventory and exact `Assets.luau` mapping; [quality-report.md](../assets/audio/quality-report.md) contains measurements and upload batches. Each file has its own waveform/spectrogram PNG in [previews](../assets/audio/previews).

## Additional 32 effects

These basenames exactly match both `Assets.Sounds` and `Audio.Cues` and the [new-slot brief](audio-new-slots.md). All original plus new SFX keys exhaust the 48 runtime slots. The task explicitly requests existing OGG delivery instead of WAV; Roblox accepts it. Vorbis has no 16-bit PCM storage-depth setting. The shared original instruments run at 32 kHz internally and the new band-limited signals are interpolated to 48 kHz before encoding. No original delivered file is resampled.

| Key | Seconds | Target K level (dB) | Playback |
| --- | ---: | ---: | --- |
| FlushStart | 0.145 | -25 | One-shot |
| Common | 0.160 | -26 | One-shot |
| Uncommon | 0.260 | -24 | One-shot |
| Rare | 0.440 | -21 | One-shot |
| DropLanding | 0.170 | -27 | One-shot |
| Sell | 0.310 | -20 | One-shot |
| SellAll | 0.560 | -20 | One-shot |
| CoinPopup | 0.110 | -33 | One-shot |
| DisplayPlace | 0.310 | -24 | One-shot |
| DisplayReturn | 0.235 | -27 | One-shot |
| DisplayLocked | 0.195 | -29 | One-shot |
| ToiletUpgrade | 1.480 | -15 | One-shot |
| UpgradeBuy | 0.480 | -20 | One-shot |
| UpgradeMax | 0.980 | -17 | One-shot |
| RebirthHold | 1.000 | -30 | Loop |
| RebirthSuccess | 2.620 | -14 | One-shot |
| IndexClaim | 0.650 | -20 | One-shot |
| DailyClaim | 0.600 | -21 | One-shot |
| DailyStreak | 1.440 | -17 | One-shot |
| TutorialStep | 0.340 | -27 | One-shot |
| TabSwitch | 0.100 | -28 | One-shot |
| PurchaseStart | 0.260 | -27 | One-shot |
| PurchaseFail | 0.260 | -29 | One-shot |
| AutoFlushToggle | 0.170 | -27 | One-shot |
| Teleport | 0.580 | -23 | One-shot |
| PortalLocked | 0.260 | -28 | One-shot |
| ChatAnnouncement | 0.390 | -28 | One-shot |
| LuckStart | 0.610 | -24 | One-shot |
| LuckEnd | 0.460 | -27 | One-shot |
| LeaderboardUpdate | 0.070 | -36 | One-shot |
| SpawnArrival | 0.720 | -25 | One-shot |
| Ambience | 36.000 | -33 | Loop |

Targets describe source mastering, before runtime gains/settings. Quiet informational accents are -36 to -33; tactile navigation/obstruction -29 to -24; ordinary rewards near -20; milestones -17 to -14. Common → Uncommon → Rare grows in note count, register and level toward existing Epic. Air/water uses the Flush noise bands; glass uses the existing chime/vibes partials; physical taps extend the rounded Click palette; confirmations reuse PurchaseSuccess's C-major keys. Sell/SellAll share an identical final ping recipe. DailyStreak has seven authored ascending chimes. RebirthSuccess uses the ServerEvent instruments with a different ascending phrase and glass resolution. No pitch variation or ducking is baked in.

RebirthHold uses integer-Hz partials, a stable two-pulse envelope and circular water texture; it contains no success hit. Ambience is a nonmusical 36-second circular coastal noise bed with irregular slow swells and three distant synthesized bird gestures. Neither loop fades to silence on each repeat. Decoded boundary steps are **0.000891 FS** and **0.000580 FS** respectively; slope errors are **0.000327** and **0.000580 FS/sample**, with nearby RMS differences below 0.52 dB.

**Clean arbitrary stops require a runtime release.** Read-only inspection shows the current `AudioService:Stop` cleanup destroys voices immediately. A nonzero file cannot be click-free at every possible hard-cut phase. Both loops pass offline tests at 64 stop phases with a **20 ms cosine release**, but that release is not implemented here because `src/` edits are excluded. The manager should apply a short attack/release during integration and validate cancellation, mute and teardown. Manifest fields distinguish abrupt-stop worst-case amplitude from the successful faded-stop probe. Seamlessness of the authored loop does not imply click-free abrupt cancellation.

New-file checks all pass: 48 kHz mono, specified duration, exact frame count, original-key preservation, no clipped samples, estimated true peak at most **-3.653 dBTP**, maximum DC **0.000082 FS**, onset within **2 ms**, and smooth one-shot endpoints below 0.001 FS. Sell/SellAll pass decoded speed probes at 1.00, 1.06, 1.12, 1.18 and 1.24x. Tests enforce each authored loudness target within 1.5 dB; linear peak-headroom protection puts ToiletUpgrade around -16.13 and RebirthSuccess around -14.98 estimated LUFS rather than forcing their nominal targets with a limiter.

Visual review: [contact sheets 1](../assets/audio/previews/contact-1.png), [2](../assets/audio/previews/contact-2.png), [3](../assets/audio/previews/contact-3.png), [4](../assets/audio/previews/contact-4.png) cover all 32 additions; [5](../assets/audio/previews/contact-5.png) compares eight existing palette references. Reviewed note counts/contours, envelopes, upper-band rolloff, sustaining loop beds and reward layering. Three initial endpoint overshoots were corrected with 7 ms attacks, the fanfare chord was rebalanced, and codec-aware loop cuts replaced the initial weaker boundaries. These are numerical/visual observations, not a listening approval.

## Original music and effects (unchanged)

| File | Original title | Key / BPM | Duration | Arrangement |
| --- | --- | --- | ---: | --- |
| Music1.ogg | Porcelain Sunrise | C major / 80 | 120.000 s | Warm lo-fi electric keys, swung soft kit, rounded bass |
| Music2.ogg | Palm Bubble Bay | D major / 96 | 100.000 s | Tropical plucks, syncopated congas, light shakers |
| Music3.ogg | Cloud Pool | A major / 72 | 133.333 s | Dreamy pads, breathy sine lead, gentle half-time groove |
| Music4.ogg | Velvet Coin Cafe | F major / 86 | 111.628 s | Jazz-hop extended chords, muted kit, vibraphone |
| Music5.ogg | Marimba Float Parade | G major / 100 | 96.000 s | Playful marimba, soft pads and wooden percussion |

Each track has 40 bars: eight-bar theme, theme variation, contrasting contour, sparse interlude and theme return. Voiced seventh/ninth chords, bass approaches, call/response, melodic rests and timing/velocity variation provide structure. All instruments and percussion are synthesized from oscillators and seeded noise. No external samples, recordings, MIDI arrangements or melodies were imported.

The 16 one-shots are `Click`, `Hover`, `Open`, `Close`, `CoinCollect`, `Flush`, `FlushRumble`, `Epic`, `Legendary`, `Mythic`, `Godly`, `Secret`, `ServerEvent`, `PurchaseSuccess`, `Error` and `AutoFlushTick`. UI, coin, confirmation, error, rumble and tick are mono. Flush and the reveal/event cues use restrained stereo. Enveloped noise supplies swooshes/water; harmonic and lightly inharmonic partials supply bubbles, keys and sparkles. Rarity cues gain orchestration and harmonic color; ServerEvent has a separate rhythmic fanfare. Secret moves from C-sharp minor shimmer into C-sharp major celebration.

All one-shot durations meet [audio-sourcing.md](audio-sourcing.md). Stingers measure approximately -14 LUFS; UI is deliberately quieter. Music decoded peaks are about -6.2 to -6.1 dBFS, estimated loudness -21.4 to -18.2 LUFS. Sources retain headroom; the 2026-10-07 runtime mix now uses 60% music / 70% SFX with measured track trims. See [music level measurements](research/music-level.md). Short clips under 400 ms have no meaningful standard integrated measurement here: their manifest LUFS field is null, with an explicitly labeled K-weighted proxy instead.

## Regenerate and check

No pip packages or network access are needed on this machine. Use the existing Blender Python (the ordinary `python` alias is broken):

```powershell
$audioPython = 'C:/Users/mehme/tools/blender/blender-4.5.10-windows-x64/4.5/python/bin/python.exe'
& $audioPython scripts/build-audio.py
& $audioPython scripts/build-audio.py --check
& $audioPython scripts/check-audio-regression.py
& $audioPython scripts/audio-contact-sheets.py
```

A normal build renders the 32 additions and retains the existing original batch. `--new` explicitly selects those 32. The frozen [original-21-hashes.json](../assets/audio/original-21-hashes.json) is checked before and after generation. To iterate selected assets **after a complete build**:

```powershell
& $audioPython scripts/build-audio.py --only Sell RebirthHold
& $audioPython scripts/check-audio-regression.py --only Sell RebirthHold
```

On another machine, use Python 3.11 with NumPy 1.26.4 and an existing libsndfile 1.2.2 library, optionally supplied with `--sndfile PATH`. The generator locates Blender's DLL through the interpreter's ancestor directories, or accepts `SNDFILE_LIBRARY`. It does not install anything. `scripts/audio_support.py` supplies the codec, rate-aware estimated meter and PNG diagnostics. The unchanged instrument recipes are in `scripts/build-audio.py`; new scores, stable key-derived seeds, interpolation and extra contract/loop/speed checks are in `scripts/audio_new.py`. `check-audio-regression.py` regenerates into a temporary directory, comparing synthesis PCM, encoded bytes and decoded PCM without replacing final files. The contact-sheet assembler also uses only NumPy and the Python standard library.

Music releases and the full finite reverb tail are rendered beyond the exact 40-bar length and wrapped into the start. Periodic filtering and a sub-8-ms circular boundary rotation preserve the frame count and rhythm. Vorbis preserves exact decoded frame counts; no end silence or beat-shortening crossfade is used. A per-file deterministic Ogg serial and checksum make bytes repeatable with the same local toolchain. Floating-point/library changes can affect cross-machine hashes.

`--check` decodes all 53 final files, verifies hashes against the manifest and original baseline, and returns nonzero on failure. It refreshes diagnostics without replacing the authoritative manifest. Checks cover exact filenames/key sets, spec/runtime agreement, duration, frames, supported format/rate/channels/stream count, batch limits, clipping, estimated true peak, silence, DC, high-band energy and level ranges. Original thresholds remain intact; new one-shot endpoints and loop amplitude/slope boundaries have the stricter 0.001 FS limits described above. Manifest schema 2 uses top-level `sample_rates: [32000, 48000]` plus an exact per-file `sample_rate`. Short clips retain `lufs_estimate: null` and the labeled proxy, rather than inventing integrated LUFS values.

## Upload handoff

**Batch 1: original 21 files, 5,785,365 bytes (5.785 MB), unchanged. Batch 2: new 32 files, 399,746 bytes (0.400 MB).** The manifest lists the exact keys in each batch. Both are below 9,000,000 bytes; the complete 53-file package is 6,185,111 bytes. New files range from 4,418 to 189,180 bytes. Upload only the new batch if the first batch was already handled; do not re-upload the originals unnecessarily. Include only OGG files, not PNGs/scripts/reports. The budget is a handoff rule, not a claim about Creator Hub multi-select support.

1. Audition the local review player at comfortable volume, including repeated UI/coin cues and music boundaries. Approve the creative result before upload.
2. In [Creator Hub](https://create.roblox.com/dashboard/creations), select the game-owning user/group, then **Creations → Development Items → Audio → Upload Asset** (labels may vary). Creator Dashboard and Studio Asset Manager both support audio uploads. Confirm available quota; this addition needs 32 uploads (53 only for a completely fresh installation). [Current audio requirements](https://create.roblox.com/docs/audio/assets).
3. Upload the exact final OGGs. Suggested titles: `Toilet RNG - Porcelain Sunrise` for Music1 and the other original track titles above; `Toilet RNG - UI Click`, `Toilet RNG - Cartoon Flush`, etc. Suggested description: `Original instrumental/sound effect synthesized for Toilet RNG from authored oscillators and seeded noise. No third-party recordings or samples.` Keep this repository and manifest as provenance.
4. Wait for each asset to pass moderation, then configure permissions for the production **experience/universe** and confirm the correct group ownership. Audio is private by default; uploading/previewing does not prove in-game access. [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy).
5. The manager assigns approved IDs in `src/shared/Config/Assets.luau`: `Music1.ogg` → `Music[1]`, through `Music5.ogg` → `Music[5]`; every SFX basename → `Sounds.<basename>`. Record each assigned ID alongside its original-synthesis provenance in the eventual integration change. No IDs are invented or prefilled here.
6. Test a published private server: initial playback, each of the five music loops, shuffled transitions, rapid coin pitch combos, repeated hover/ticks, reveal ducking, event+reveal overlap, nearby other-player flushes, mute/settings persistence and mobile interruption/resume. Check desktop headphones and iOS/Android speakers. Recheck transitions after Roblox transcoding; local seamlessness is not a platform playback guarantee.

## Review and honest limitations

- **No human listening or live Roblox/device pass was available for the new batch.** Numerical and visual QA cannot establish that a sound is pleasant or that closely related notifications are distinct enough in play. Review repeated Common/Uncommon, daily/tutorial/chat similarities, sale pitch combinations and the large fanfare against the actual game mix.
- The source palette is intentionally synthetic. The ocean is shaped noise and the birds are soft oscillator gestures, not field recordings; their realism and audibility need listening. Very quiet CoinPopup/LeaderboardUpdate/Ambience may disappear on phone speakers, especially after their already small runtime gains. Do not compensate automatically before hearing the intended mix.
- Loop joins pass local Vorbis tests, but **arbitrary hard stops are not solved by asset files**. Apply the documented 20 ms runtime release during integration. Roblox transcoding, mobile interruption/resume, overlapping cues and moderation/access remain unverified. No claim of completed runtime clean-stop behavior is made.
- New meters use the existing estimated approach, extended to 48 kHz. The 4x true-peak and short-clip K proxies are not certified meters. Speed probes are offline interpolation tests, not a reproduction of Roblox's resampler. Loudness targets are class/design choices with modest variation, not proof of equal subjective loudness.

Original-batch review retained for context:

- All 21 decoded-file checks pass. The music boundary steps range from 0.000640 to 0.002120 FS, below the 0.003 threshold. No clipped samples; DC below 0.000041 FS. All five music durations fall within the task's narrower 90–150 second range.
- All 21 waveform/spectrogram plots were visually inspected. UI envelopes taper; water energy forms a smooth mid-band swell; rumble is concentrated below about 200 Hz; stingers show staggered harmonic entries and decaying tails. Music shows chord/phrase changes, a quieter interlude and restrained upper-band percussion without a sustained near-Nyquist stripe. These are visual observations, not proof of subjective pleasantness or absence of every alias.
- Iteration: a larger ServerEvent attack reduced its decoded boundary artifact. Score review caught a generic closing-chord calculation that could conflict with the preceding arpeggio; Epic, Legendary, Mythic and Secret now use explicit matching cadences, with Secret's minor color released before the major answer.
- **No human listening approval was available.** The timbres are intentionally synthetic; brass/keys/bass are stylizations, not realistic acoustic performances. Although each track has its own key, tempo, motif, harmony and groove, they share a compact instrument palette and five-section arrangement. Extended play may reveal repetitive or bass-heavy passages that need taste-based adjustment. Music3 is roughly 3 LU louder than Music1; both keep similar peak headroom, and the difference needs review in the actual playlist.
- Tiny-speaker rumble audibility, repeated coin brightness, stereo summation during overlapping events and actual Roblox balance remain unverified. Spectrograms sample windows across the file; the estimated loudness/true-peak meters are not certified reference analyzers. No moderation, upload or live device pass was performed.
- Tool findings, authoritative requirements and source URLs are in [sound-synthesis research](research/sound-synthesis.md) and the new [additional-SFX research](research/sound-additional-sfx.md). No external audio services, sample downloads or new packages were used for this extension.

Validation: the regression runner reproduced all 53 OGGs and both PCM hashes, including every original file against the frozen baseline. Following the final bird-level adjustment, Ambience was re-rendered and compared again. Meter sanity fixtures pass at 32 and 48 kHz (1 kHz mono about -23.05 LUFS estimate, dual-mono +3.0103 dB, sub-400-ms LUFS null); Fourier interpolation matches an analytic tone within 1e-7 FS. Full decoded-file QA, Python syntax compilation, `rojo build -o build.rbxl` and `git diff --check` pass. No Luau was edited, so StyLua/Selene are not applicable. All work is intentionally uncommitted for manager review.
