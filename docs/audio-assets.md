# Original Toilet RNG audio assets

Branch: `feature/sound-assets`. All 21 slots are delivered as original **32 kHz OGG Vorbis** in [assets/audio/final](../assets/audio/final). No `src/` changes, uploaded assets, assigned Roblox IDs, commits or pushes.

Open [the local review player](../assets/audio/review.html) to audition every file. [manifest.json](../assets/audio/manifest.json) is the machine-readable inventory and exact `Assets.luau` mapping; [quality-report.md](../assets/audio/quality-report.md) contains measurements and upload batches. Each file has its own waveform/spectrogram PNG in [previews](../assets/audio/previews).

## Music and effects

| File | Original title | Key / BPM | Duration | Arrangement |
| --- | --- | --- | ---: | --- |
| Music1.ogg | Porcelain Sunrise | C major / 80 | 120.000 s | Warm lo-fi electric keys, swung soft kit, rounded bass |
| Music2.ogg | Palm Bubble Bay | D major / 96 | 100.000 s | Tropical plucks, syncopated congas, light shakers |
| Music3.ogg | Cloud Pool | A major / 72 | 133.333 s | Dreamy pads, breathy sine lead, gentle half-time groove |
| Music4.ogg | Velvet Coin Cafe | F major / 86 | 111.628 s | Jazz-hop extended chords, muted kit, vibraphone |
| Music5.ogg | Marimba Float Parade | G major / 100 | 96.000 s | Playful marimba, soft pads and wooden percussion |

Each track has 40 bars: eight-bar theme, theme variation, contrasting contour, sparse interlude and theme return. Voiced seventh/ninth chords, bass approaches, call/response, melodic rests and timing/velocity variation provide structure. All instruments and percussion are synthesized from oscillators and seeded noise. No external samples, recordings, MIDI arrangements or melodies were imported.

The 16 one-shots are `Click`, `Hover`, `Open`, `Close`, `CoinCollect`, `Flush`, `FlushRumble`, `Epic`, `Legendary`, `Mythic`, `Godly`, `Secret`, `ServerEvent`, `PurchaseSuccess`, `Error` and `AutoFlushTick`. UI, coin, confirmation, error, rumble and tick are mono. Flush and the reveal/event cues use restrained stereo. Enveloped noise supplies swooshes/water; harmonic and lightly inharmonic partials supply bubbles, keys and sparkles. Rarity cues gain orchestration and harmonic color; ServerEvent has a separate rhythmic fanfare. Secret moves from C-sharp minor shimmer into C-sharp major celebration.

All one-shot durations meet [audio-sourcing.md](audio-sourcing.md). Stingers measure approximately -14 LUFS; UI is deliberately quieter. Music decoded peaks are about -6.2 to -6.1 dBFS, estimated loudness -21.4 to -18.2 LUFS. Sources retain headroom for the existing 25% music / 70% SFX default mix. Short clips under 400 ms have no meaningful standard integrated measurement here: their manifest LUFS field is null, with an explicitly labeled K-weighted proxy instead.

## Regenerate and check

No pip packages or network access are needed on this machine. Use the existing Blender Python (the ordinary `python` alias is broken):

```powershell
$audioPython = 'C:/Users/mehme/tools/blender/blender-4.5.10-windows-x64/4.5/python/bin/python.exe'
& $audioPython scripts/build-audio.py
& $audioPython scripts/build-audio.py --check
```

To iterate selected assets **after a complete build**:

```powershell
& $audioPython scripts/build-audio.py --only Epic Secret
```

On another machine, use Python 3.11 with NumPy 1.26.4 and an existing libsndfile 1.2.2 library, optionally supplied with `--sndfile PATH`. The generator locates Blender's DLL through the interpreter's ancestor directories, or accepts `SNDFILE_LIBRARY`. It does not install anything. `scripts/audio_support.py` supplies the codec, estimated meter and PNG diagnostics. Seeds, complete scores, instruments and mix choices are in `scripts/build-audio.py`.

Music releases and the full finite reverb tail are rendered beyond the exact 40-bar length and wrapped into the start. Periodic filtering and a sub-8-ms circular boundary rotation preserve the frame count and rhythm. Vorbis preserves exact decoded frame counts; no end silence or beat-shortening crossfade is used. A per-file deterministic Ogg serial and checksum make bytes repeatable with the same local toolchain. Floating-point/library changes can affect cross-machine hashes.

`--check` decodes the final files, verifies hashes against the manifest and returns nonzero on failure. It refreshes diagnostics without replacing the authoritative manifest. Checks cover slot duration, exact frames, supported format/rate/stream count, import limits, clipping, estimated true peak, silence, DC, high-band energy, level ranges, one-shot endpoints and music boundary step **< 0.003 full scale**. Thresholds and all measurements are recorded in the report/manifest.

## Upload handoff

**Batch 1: all 21 `.ogg` files in `assets/audio/final`, 5,785,365 bytes (5.785 MB).** This is below the requested 9,000,000-byte budget. Include only the OGG files in the audio upload; PNGs, scripts and reports are review material. The batch budget is a handoff rule, not a claim about Creator Hub multi-select support. Upload individually if the current uploader requires it.

1. Audition the local review player at comfortable volume, including repeated UI/coin cues and music boundaries. Approve the creative result before upload.
2. In [Creator Hub](https://create.roblox.com/dashboard/creations), select the game-owning user/group, then **Creations → Development Items → Audio → Upload Asset** (labels may vary). Creator Dashboard and Studio Asset Manager both support audio uploads. Confirm available quota; this package needs 21 audio uploads. [Current audio requirements](https://create.roblox.com/docs/audio/assets).
3. Upload the exact final OGGs. Suggested titles: `Toilet RNG - Porcelain Sunrise` for Music1 and the other original track titles above; `Toilet RNG - UI Click`, `Toilet RNG - Cartoon Flush`, etc. Suggested description: `Original instrumental/sound effect synthesized for Toilet RNG from authored oscillators and seeded noise. No third-party recordings or samples.` Keep this repository and manifest as provenance.
4. Wait for each asset to pass moderation, then configure permissions for the production **experience/universe** and confirm the correct group ownership. Audio is private by default; uploading/previewing does not prove in-game access. [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy).
5. The manager assigns approved IDs in `src/shared/Config/Assets.luau`: `Music1.ogg` → `Music[1]`, through `Music5.ogg` → `Music[5]`; every SFX basename → `Sounds.<basename>`. Record each assigned ID alongside its original-synthesis provenance in the eventual integration change. No IDs are invented or prefilled here.
6. Test a published private server: initial playback, each of the five music loops, shuffled transitions, rapid coin pitch combos, repeated hover/ticks, reveal ducking, event+reveal overlap, nearby other-player flushes, mute/settings persistence and mobile interruption/resume. Check desktop headphones and iOS/Android speakers. Recheck transitions after Roblox transcoding; local seamlessness is not a platform playback guarantee.

## Review and honest limitations

- All 21 decoded-file checks pass. The music boundary steps range from 0.000640 to 0.002120 FS, below the 0.003 threshold. No clipped samples; DC below 0.000041 FS. All five music durations fall within the task's narrower 90–150 second range.
- All 21 waveform/spectrogram plots were visually inspected. UI envelopes taper; water energy forms a smooth mid-band swell; rumble is concentrated below about 200 Hz; stingers show staggered harmonic entries and decaying tails. Music shows chord/phrase changes, a quieter interlude and restrained upper-band percussion without a sustained near-Nyquist stripe. These are visual observations, not proof of subjective pleasantness or absence of every alias.
- Iteration: a larger ServerEvent attack reduced its decoded boundary artifact. Score review caught a generic closing-chord calculation that could conflict with the preceding arpeggio; Epic, Legendary, Mythic and Secret now use explicit matching cadences, with Secret's minor color released before the major answer.
- **No human listening approval was available.** The timbres are intentionally synthetic; brass/keys/bass are stylizations, not realistic acoustic performances. Although each track has its own key, tempo, motif, harmony and groove, they share a compact instrument palette and five-section arrangement. Extended play may reveal repetitive or bass-heavy passages that need taste-based adjustment. Music3 is roughly 3 LU louder than Music1; both keep similar peak headroom, and the difference needs review in the actual playlist.
- Tiny-speaker rumble audibility, repeated coin brightness, stereo summation during overlapping events and actual Roblox balance remain unverified. Spectrograms sample windows across the file; the estimated loudness/true-peak meters are not certified reference analyzers. No moderation, upload or live device pass was performed.
- Tool findings, authoritative requirements and source URLs are in [sound-synthesis research](research/sound-synthesis.md). NumPy plus the already installed bundled codec was the chosen fallback after package installation was blocked by network restrictions. No external services or audio generators were used.

Validation: a complete second render produced identical SHA-256 hashes for all 21 OGGs, synthesis PCM and decoded PCM. Meter sanity checks passed (1 kHz mono tone about -23.05 LUFS estimate, dual-mono +3.0103 dB, sub-400-ms LUFS null). Python compilation, `rojo build -o build.rbxl` and `git diff --check` pass. No Luau was edited, so StyLua/Selene checks are not applicable to these Python/assets/docs changes. Files are intentionally uncommitted for manager review. The unsuccessful local pip environment and codec probes are ignored build-work files, not deliverables.
