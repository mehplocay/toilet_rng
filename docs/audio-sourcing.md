# Audio sourcing handoff

Assign approved IDs only in `src/shared/Config/Assets.luau`; all 21 placeholders are intentionally empty. Numeric IDs, numeric ID strings or `rbxassetid://` strings are accepted. Empty, zero and malformed IDs silently skip playback. Music plays at 25% and SFX at 70% by default; normalize sources consistently, leave headroom and avoid harsh peaks. Pitch changes apply only to SFX (up to +/-5%, with extra rising coin-combo pitch).

| Config key | Desired sound, length and looping |
| --- | --- |
| Music[1] | Warm lo-fi keys with a soft beat, 90-180 seconds, seamless loop, instrumental. |
| Music[2] | Relaxed tropical plucks with light percussion, 90-180 seconds, seamless loop, instrumental. |
| Music[3] | Dreamy ambient synths with a gentle groove, 90-180 seconds, seamless loop, instrumental. |
| Music[4] | Cozy jazz-hop chords and muted drums, 90-180 seconds, seamless loop, instrumental. |
| Music[5] | Playful chill marimba and soft pads, 90-180 seconds, seamless loop, instrumental. |
| Sounds.Click | Rounded tactile pop, 0.08-0.15 seconds, one-shot. |
| Sounds.Hover | Very quiet airy blip, 0.05-0.1 seconds, one-shot. |
| Sounds.Open | Soft upward bubble/whoosh, 0.2-0.35 seconds, one-shot. |
| Sounds.Close | Soft downward bubble/whoosh, 0.15-0.3 seconds, one-shot. |
| Sounds.CoinCollect | Bright soft coin ping that tolerates rising pitch, 0.2-0.45 seconds, one-shot. |
| Sounds.Flush | Cartoon water swoosh with a quick clean tail, 0.6-1 seconds, one-shot. |
| Sounds.FlushRumble | Low gentle plumbing rumble below the swoosh, 0.5-0.9 seconds, one-shot. |
| Sounds.Epic | Short magical sparkle chord, 0.6-1 seconds, one-shot. |
| Sounds.Legendary | Warm golden ascending flourish, 1-1.5 seconds, one-shot. |
| Sounds.Mythic | Dreamy layered synth/chime flourish, 1.2-1.8 seconds, one-shot. |
| Sounds.Godly | Grand playful orchestral/synth impact without harsh bass, 1.5-2 seconds, one-shot. |
| Sounds.Secret | Mysterious cosmic shimmer resolving into celebration, 1.8-2.4 seconds, one-shot. |
| Sounds.ServerEvent | Exciting server celebration fanfare distinct from rarity cues, 2-3 seconds, one-shot. |
| Sounds.PurchaseSuccess | Friendly positive three-note confirmation, 0.4-0.8 seconds, one-shot. |
| Sounds.Error | Gentle low two-note buzz, 0.15-0.3 seconds, one-shot. |
| Sounds.AutoFlushTick | Quiet rounded clock/drop tick, 0.04-0.1 seconds, one-shot. |

Use Roblox Creator Store audio licensed for experience use, or original/licensed uploads for which the game owner has the necessary rights. Confirm moderation and production universe usage permissions in Creator Dashboard (especially for group-owned games). Record the source/license with each assignment and test a published private server on desktop, iOS and Android; Studio previews alone do not prove access. See [research](research/audio.md).

The playlist uses a shuffle bag without adjacent repeats, overlapping fades up to three seconds, and loops the current track while waiting for the next. A single assigned track loops by itself. Source all five for the intended variety. Major reveals and the five-second event banner duck music to 40% of the selected volume; overlapping moments extend ducking. Quick reveals still play their short cue and duck for their actual one-second duration.

The existing replicated flush cue is muted locally under the owner's `OwnerUserId` plot to avoid doubling the result sound; other players retain positional audio through their SFX mix. Volume edits preview immediately and save through the rate-limited Settings remote, coalesced at 1.1-second intervals. Legacy Sound=false profiles migrate to both channels muted.

Verification includes the pure `scripts/check-audio.luau`, production-client audio tests in `check-ui.ps1`, and persistence/remote validation in `check-audit.ps1`. The offline Settings previews are layout approximations. Audible balance, permissions, mobile interruptions and actual TweenService timing still need a Studio/published-device pass once the manager assigns licensed assets; empty placeholders produce no audio requests.
