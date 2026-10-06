# Audio sourcing handoff

This is the complete generator inventory: **53 slots = 5 music tracks + 48 SFX slots**. The original 21 slots are unchanged in name and source brief; **32 NEW** SFX slots are specified below and in [audio-new-slots.md](audio-new-slots.md). This audit does not edit `assets/audio/` or `scripts/build-audio.py`. Coordinate the new batch with the existing generator session; do not replace its 21 outputs.

Assign approved IDs only in `src/shared/Config/Assets.luau`; every audio ID remains an empty string. Positive numeric IDs, numeric strings and `rbxassetid://` IDs are supported. Empty/zero/invalid IDs skip allocation and playback. See [sound map](design/sound-map.md) for triggers and exact mix budgets.

## Complete source list

Durations are seconds including the decay tail. Stay within the upper limit: the client expires stale one-shot voices at that duration adjusted for playback speed, plus 0.15 s. Deliver clean attacks, no leading silence, no clipping, and a click-free end. Loops must join seamlessly. Original/licensed, no speech or recognizable copyrighted melody. Use consistent perceived level and leave headroom; the runtime supplies relative gain. Do not bake runtime pitch randomness or volume ducking into files.

| Config key | Status | Style / character | Duration (s) | Loop |
| --- | --- | --- | --- | --- |
| Music[1] | Existing | Warm lo-fi keys and a soft beat; instrumental | 90–180 | Seamless loop |
| Music[2] | Existing | Relaxed tropical plucks and light percussion; instrumental | 90–180 | Seamless loop |
| Music[3] | Existing | Dreamy ambient synths and gentle groove; instrumental | 90–180 | Seamless loop |
| Music[4] | Existing | Cozy jazz-hop chords and muted drums; instrumental | 90–180 | Seamless loop |
| Music[5] | Existing | Playful chill marimba and soft pads; instrumental | 90–180 | Seamless loop |
| Sounds.Click | Existing | Rounded tactile pop. Dry, soft attack; no sharp click. | 0.08–0.15 | One-shot |
| Sounds.Hover | Existing | Very quiet airy blip. Lighter than Click; no tonal tail. | 0.05–0.10 | One-shot |
| Sounds.Open | Existing | Upward bubble whoosh. Soft upward motion. | 0.20–0.35 | One-shot |
| Sounds.Close | Existing | Downward bubble whoosh. Soft downward motion. | 0.15–0.30 | One-shot |
| Sounds.CoinCollect | Existing | Bright soft coin ping. Rounded metallic ping; tolerate rising combo pitch. | 0.20–0.45 | One-shot |
| Sounds.Flush | Existing | Cartoon water swoosh. Clean watery sweep with short tail, no loud splash. | 0.60–1.00 | One-shot |
| Sounds.FlushRumble | Existing | Gentle plumbing rumble. Low, rounded bubbling; no sub-bass blast. | 0.50–0.90 | One-shot |
| Sounds.Epic | Existing | Magical sparkle chord. First celebratory chord in the rarity ladder. | 0.60–1.00 | One-shot |
| Sounds.Legendary | Existing | Golden ascending flourish. Warm chimes, more harmonic lift than Epic. | 1.00–1.50 | One-shot |
| Sounds.Mythic | Existing | Layered synth/chime flourish. Dreamy, wider than Legendary. | 1.20–1.80 | One-shot |
| Sounds.Godly | Existing | Playful orchestral/synth impact. Grand, controlled low end, no harsh brass. | 1.50–2.00 | One-shot |
| Sounds.Secret | Existing | Cosmic shimmer resolving into celebration. Most special rarity cue, mysterious then joyful. | 1.80–2.40 | One-shot |
| Sounds.ServerEvent | Existing | Server celebration fanfare. Broad communal celebration distinct from personal rarity. | 2.00–3.00 | One-shot |
| Sounds.PurchaseSuccess | Existing | Positive three-note confirmation. Friendly, final resolution; never a sales pressure alarm. | 0.40–0.80 | One-shot |
| Sounds.Error | Existing | Gentle low two-note buzz. Informative, soft, never punitive. | 0.15–0.30 | One-shot |
| Sounds.AutoFlushTick | Existing | Rounded clock/water tick. Almost subliminal metronome accent. | 0.04–0.10 | One-shot |
| Sounds.FlushStart | **NEW** | Ceramic handle clunk with one small water plip. Dry toy-like physical onset, no swoosh baked in. | 0.12–0.16 | One-shot |
| Sounds.Common | **NEW** | Single low rounded discovery plop. Small, neutral-positive, not a failure cue. | 0.12–0.18 | One-shot |
| Sounds.Uncommon | **NEW** | Two light ascending bubble notes. Slightly brighter and more melodic than Common. | 0.20–0.30 | One-shot |
| Sounds.Rare | **NEW** | Three-note glass-and-bubble discovery chirp. Clear positive lift with short sparkle tail. | 0.35–0.50 | One-shot |
| Sounds.DropLanding | **NEW** | Soft rubbery plop with tiny water bead. Quick settling accent, no heavy impact or second flourish. | 0.12–0.20 | One-shot |
| Sounds.Sell | **NEW** | Single coin exchange ping with tiny register tap. Dry positive transaction; remain clean at 1.24x speed. | 0.25–0.35 | One-shot |
| Sounds.SellAll | **NEW** | Compact handful-of-coins cascade ending in a ping. One baked cascade, no long coin shower; tolerate 1.24x. | 0.45–0.60 | One-shot |
| Sounds.CoinPopup | **NEW** | Tiny soft coin glint. Very understated tick for frequent service-coin popup. | 0.08–0.14 | One-shot |
| Sounds.DisplayPlace | **NEW** | Soft pedestal clack and a tiny glass sparkle. Tactile placement with modest positive resolution. | 0.25–0.35 | One-shot |
| Sounds.DisplayReturn | **NEW** | Gentle suction pop with short downward note. Light pickup/put-back motion, no negative buzz. | 0.18–0.28 | One-shot |
| Sounds.DisplayLocked | **NEW** | Muted hollow wooden double knock. Kind obstruction cue; distinguish from purchase failure. | 0.15–0.22 | One-shot |
| Sounds.ToiletUpgrade | **NEW** | Large upward water-air whoosh resolving into a glowing chord. Whoosh onset with warm sustained shimmer; include purchase confirmation in one cue. | 1.20–1.60 | One-shot |
| Sounds.UpgradeBuy | **NEW** | Compact ascending level-up triad. Satisfying incremental progress, smaller than toilet upgrade. | 0.35–0.55 | One-shot |
| Sounds.UpgradeMax | **NEW** | Ascending triad finishing in a bright crown sparkle. Completion accent; also free Auto-Flush unlock. | 0.80–1.10 | One-shot |
| Sounds.RebirthHold | **NEW** | Stable pulsing magical water charge. Seamless restrained sustain; no final hit, no baked climax; clean stop at any phase. | 1.00 | Seamless loop |
| Sounds.RebirthSuccess | **NEW** | Triumphant ascending crown fanfare with sparkling resolution. Largest personal progression celebration, positive and warm. | 2.20–2.80 | One-shot |
| Sounds.IndexClaim | **NEW** | Stamp tap followed by crystalline reward arpeggio. Collectible achievement; crisp stamp and gentle sparkle. | 0.50–0.75 | One-shot |
| Sounds.DailyClaim | **NEW** | Gift-box pop followed by warm bell pair. Friendly daily gift, modest celebration. | 0.45–0.70 | One-shot |
| Sounds.DailyStreak | **NEW** | Seven quick soft chimes ascending to a luck shimmer. Week milestone, more celebratory than DailyClaim but below RebirthSuccess. | 1.20–1.60 | One-shot |
| Sounds.TutorialStep | **NEW** | Light ascending two-note success cue. Encouraging, small and unobtrusive under other rewards. | 0.25–0.40 | One-shot |
| Sounds.TabSwitch | **NEW** | Short sideways papery bubble tick. Clear navigation movement, distinct from generic Click. | 0.08–0.12 | One-shot |
| Sounds.PurchaseStart | **NEW** | Soft opening bell with airy lift. Neutral invitation, unresolved; must not sound like success. | 0.20–0.30 | One-shot |
| Sounds.PurchaseFail | **NEW** | Soft descending two-note pluck. Calm cancel/unavailable acknowledgement, no buzzer aggression. | 0.20–0.30 | One-shot |
| Sounds.AutoFlushToggle | **NEW** | Two rounded mechanical switch notes. Neutral on/off switch, one asset for both directions. | 0.12–0.20 | One-shot |
| Sounds.Teleport | **NEW** | Air-and-water travel sweep. Fast lift and gentle arrival, no impact; plays on actual local pivot. | 0.45–0.65 | One-shot |
| Sounds.PortalLocked | **NEW** | Soft comic rubber bonk with short descending wobble. Playful coming-soon feedback; no punishment or alarm. | 0.20–0.30 | One-shot |
| Sounds.ChatAnnouncement | **NEW** | Tiny warm two-note notification chime. Readable without competing with server event or rare finds. | 0.30–0.45 | One-shot |
| Sounds.LuckStart | **NEW** | Light ascending magical shimmer. A fresh boost begins; no long sustain. | 0.45–0.70 | One-shot |
| Sounds.LuckEnd | **NEW** | Gentle descending shimmer. Natural settling, never a failure signal. | 0.35–0.50 | One-shot |
| Sounds.LeaderboardUpdate | **NEW** | Barely audible rounded glass tick. Background informational change; no fanfare. | 0.05–0.08 | One-shot |
| Sounds.SpawnArrival | **NEW** | Soft welcoming air bloom and warm chime. Brief comfortable arrival, no cinematic impact. | 0.55–0.80 | One-shot |
| Sounds.Ambience | **NEW** | Soft ocean wash, coastal wind and sparse distant birds. Seamless quiet bed; no music, speech, sharp gull cries, identifiable cadence or close waves. | 30.00–45.00 | Seamless loop |

## Runtime mix contract

Music defaults to 25%, SFX to 70%, with independent saved sliders and mutes. Ambience belongs to SFX and starts only when settings and the local character root are ready; its source gain is just 0.055 (0.0385 after the default SFX slider). Leave Ambience empty to disable the optional bed. No footsteps are added.

The five music tracks use the existing shuffle bag, no adjacent repeat, up to three-second crossfades and two decks. One assigned track loops on its own. SFX use 12 managed voices total: UI 3, action 4, reward 3, stinger 1, ambient 1; every slot also has a cooldown and voice cap. Replicated flushes within 65 studs of the camera have a separate two-voice cap, 0.7 s global spacing and 20% bus gain under the SFX slider; the owner's replicated flush is muted to avoid doubling local playback.

Stingers automatically duck music to 40% and ambience to 25% of their selected mix, with 0.15 s attack / 1.2 s release. Priority rises through Epic, Legendary, Mythic, Godly, Secret, ServerEvent and RebirthSuccess; equal/lower stingers cannot stack. Ending, stopping or replacing a voice removes its duck; independent event-banner ducking lasts five seconds and overlaps correctly. Music mute stays zero throughout. Visual intensity Off still allows rarity audio; the SFX mute controls audio.

One-shot pitch varies by the per-slot range in Config/Audio (at most +/-5%). Musical stingers vary little or not at all. CoinCollect has a four-second combo window, stable jitter per combo and up to eight rising steps. Sell/SellAll use actual confirmed coin delta: `1 + min(0.24, log10(1 + coins) * 0.04)`; no random jitter can reverse amount ordering. Single-copy Sell All shares Sell; multi-copy sales use SellAll. RebirthHold and Ambience loop at exactly 1x. Hold cancels on release, pointer leave, focus/selection loss, scroll, panel close, submit, result, destruction and mute; a five-second watchdog also bounds it.

Accepted flush results start handle/rumble, then a swoosh at 0.08 s and a soft settle at the configured world-animation duration. The server model flies upward and disappears rather than colliding: DropLanding is this presentation settle, not a physical impact detector. The sequence is spaced by at least 0.7 s; at the 0.4 s gameplay floor, some sound sequences intentionally skip while all rewards remain visible. Slot/class budgets can suppress secondary layers. No delayed audio backlog builds up.

## Permissions and validation

Use Roblox Creator Store audio licensed for experience use or original/licensed uploads the owner can use. Confirm moderation and production universe permissions (especially group-owned games); record source/license alongside each assignment. Test in a published private server on desktop, iOS and Android. See [current audio research](research/audio-coverage.md) and [base audio research](research/audio.md).

Pure checks cover scheduler budgets, priorities, pitch, ducks and confirmed-result routing. `check-ui.ps1` exercises the production mixer, loop cancellation, controls, crossfades, muted playback and placeholder silence. `check-audit.ps1` retains server validation/persistence coverage. Audible source balance, engine spatial replication timing, touch hit-testing and device interruptions still require Studio/published-device testing once licensed IDs are assigned.
