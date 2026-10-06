# New audio slots — generator specification

**32 new SFX assets only.** Existing 21-slot generation remains owned by the other session. No music revisions, audio IDs or source-file changes are part of this audit. Keys below map exactly to `Assets.Sounds` and `Config.Audio.Cues`. Use a separate new-output batch; do not overwrite the old assets. [Full inventory](audio-sourcing.md) and [trigger map](design/sound-map.md).

Produce one file per key, named `<Key>.wav` (for example `FlushStart.wav`). WAV, 48 kHz, 16-bit PCM, mono for these SFX including ambience; no leading silence. Normalize comparable one-shots consistently with at least 3 dB true-peak headroom; avoid aggressive limiting. Exact duration may vary within the range, never above its upper bound (tail included). Short start/end fades prevent clicks. Loop endpoints must match in amplitude and slope. Music/ambience ducking and playback-speed variation are runtime effects: do not pre-render them. No voice, lyrics, recognizable borrowed melody, harsh highs or exaggerated sub-bass.

| Key | Description | Duration (s) | Character / envelope | Loop | Consistency reference |
| --- | --- | --- | --- | --- | --- |
| FlushStart | Ceramic handle clunk with one small water plip | 0.12–0.16 | Dry toy-like physical onset, no swoosh baked in | One-shot | Flush + FlushRumble; same water texture |
| Common | Single low rounded discovery plop | 0.12–0.18 | Small, neutral-positive, not a failure cue | One-shot | CoinCollect softness + Flush water texture |
| Uncommon | Two light ascending bubble notes | 0.20–0.30 | Slightly brighter and more melodic than Common | One-shot | Epic harmonic palette, much smaller |
| Rare | Three-note glass-and-bubble discovery chirp | 0.35–0.50 | Clear positive lift with short sparkle tail | One-shot | Epic palette, reduced weight and length |
| DropLanding | Soft rubbery plop with tiny water bead | 0.12–0.20 | Quick settling accent, no heavy impact or second flourish | One-shot | Flush water texture + Click rounded transient |
| Sell | Single coin exchange ping with tiny register tap | 0.25–0.35 | Dry positive transaction; remain clean at 1.24x speed | One-shot | CoinCollect metal and PurchaseSuccess positivity |
| SellAll | Compact handful-of-coins cascade ending in a ping | 0.45–0.60 | One baked cascade, no long coin shower; tolerate 1.24x | One-shot | CoinCollect and Sell timbre; same final ping |
| CoinPopup | Tiny soft coin glint | 0.08–0.14 | Very understated tick for frequent service-coin popup | One-shot | CoinCollect upper shimmer, much shorter/quieter |
| DisplayPlace | Soft pedestal clack and a tiny glass sparkle | 0.25–0.35 | Tactile placement with modest positive resolution | One-shot | Click attack + Epic sparkle |
| DisplayReturn | Gentle suction pop with short downward note | 0.18–0.28 | Light pickup/put-back motion, no negative buzz | One-shot | Close downward contour + Click softness |
| DisplayLocked | Muted hollow wooden double knock | 0.15–0.22 | Kind obstruction cue; distinguish from purchase failure | One-shot | Error low register + Click transient |
| ToiletUpgrade | Large upward water-air whoosh resolving into a glowing chord | 1.20–1.60 | Whoosh onset with warm sustained shimmer; include purchase confirmation in one cue | One-shot | Flush texture + Legendary golden flourish |
| UpgradeBuy | Compact ascending level-up triad | 0.35–0.55 | Satisfying incremental progress, smaller than toilet upgrade | One-shot | PurchaseSuccess three-note language |
| UpgradeMax | Ascending triad finishing in a bright crown sparkle | 0.80–1.10 | Completion accent; also free Auto-Flush unlock | One-shot | PurchaseSuccess motif + Epic sparkle |
| RebirthHold | Stable pulsing magical water charge | 1.00 | Seamless restrained sustain; no final hit, no baked climax; clean stop at any phase | Seamless loop | FlushRumble pulse + Mythic airy pad |
| RebirthSuccess | Triumphant ascending crown fanfare with sparkling resolution | 2.20–2.80 | Largest personal progression celebration, positive and warm | One-shot | ServerEvent instrumentation + Secret shimmer; distinct melody |
| IndexClaim | Stamp tap followed by crystalline reward arpeggio | 0.50–0.75 | Collectible achievement; crisp stamp and gentle sparkle | One-shot | PurchaseSuccess motif + Epic crystals |
| DailyClaim | Gift-box pop followed by warm bell pair | 0.45–0.70 | Friendly daily gift, modest celebration | One-shot | Click pop + PurchaseSuccess notes |
| DailyStreak | Seven quick soft chimes ascending to a luck shimmer | 1.20–1.60 | Week milestone, more celebratory than DailyClaim but below RebirthSuccess | One-shot | Legendary flourish + DailyClaim bells |
| TutorialStep | Light ascending two-note success cue | 0.25–0.40 | Encouraging, small and unobtrusive under other rewards | One-shot | PurchaseSuccess notes at smaller scale |
| TabSwitch | Short sideways papery bubble tick | 0.08–0.12 | Clear navigation movement, distinct from generic Click | One-shot | Click transient + Open airy body |
| PurchaseStart | Soft opening bell with airy lift | 0.20–0.30 | Neutral invitation, unresolved; must not sound like success | One-shot | Open movement + PurchaseSuccess instrument |
| PurchaseFail | Soft descending two-note pluck | 0.20–0.30 | Calm cancel/unavailable acknowledgement, no buzzer aggression | One-shot | Error contour + Close softness |
| AutoFlushToggle | Two rounded mechanical switch notes | 0.12–0.20 | Neutral on/off switch, one asset for both directions | One-shot | Click and AutoFlushTick |
| Teleport | Air-and-water travel sweep | 0.45–0.65 | Fast lift and gentle arrival, no impact; plays on actual local pivot | One-shot | Open envelope + Flush airy sweep |
| PortalLocked | Soft comic rubber bonk with short descending wobble | 0.20–0.30 | Playful coming-soon feedback; no punishment or alarm | One-shot | Error low register + Flush cartoon character |
| ChatAnnouncement | Tiny warm two-note notification chime | 0.30–0.45 | Readable without competing with server event or rare finds | One-shot | PurchaseSuccess instrument, quieter and smaller |
| LuckStart | Light ascending magical shimmer | 0.45–0.70 | A fresh boost begins; no long sustain | One-shot | Mythic airy texture + Epic sparkle |
| LuckEnd | Gentle descending shimmer | 0.35–0.50 | Natural settling, never a failure signal | One-shot | LuckStart / Mythic texture with Close contour |
| LeaderboardUpdate | Barely audible rounded glass tick | 0.05–0.08 | Background informational change; no fanfare | One-shot | Hover softness + CoinCollect glass |
| SpawnArrival | Soft welcoming air bloom and warm chime | 0.55–0.80 | Brief comfortable arrival, no cinematic impact | One-shot | Open air + PurchaseSuccess warmth |
| Ambience | Soft ocean wash, coastal wind and sparse distant birds | 30.00–45.00 | Seamless quiet bed; no music, speech, sharp gull cries, identifiable cadence or close waves | Seamless loop | Music[2] tropical setting; soft texture under all five tracks |

RebirthHold is a one-second loop played only during the two-second confirmation hold; do not include the success fanfare. RebirthSuccess is a separate confirmed-outcome cue. Ambience is optional and stays extremely quiet in the runtime. Sell/SellAll must remain clean from 1.00x through 1.24x playback speed. Common is a positive fallback discovery, never a no-drop/failure sound.

Use the existing generated Click, CoinCollect, Flush, rarity ladder and PurchaseSuccess as the shared palette when available. References to new keys (Sell, DailyClaim, LuckStart) mean keep those siblings in the same batch consistent. Every key remains an empty asset placeholder until moderation, licensing and experience access are confirmed.
