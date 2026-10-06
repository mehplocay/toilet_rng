# Rare drop presentation review

## Tiered reveals 2 — current implementation

2026-10-06, `feature/reveals2`; uncommitted. This section supersedes the shared Legendary/Mythic and Godly/Secret visuals described below. [API review](../research/tiered-reveals2.md), [headless previews](reveals2-previews/README.md).

| Rarity | Full signature | Duration | Existing audio hook |
|---|---|---|---|
| Legendary | Golden rays, confetti, small camera shake | 2 s | Legendary |
| Mythic | Magenta crystal explosion, large tier banner, rapid expansion → suspended tween → release; item turn also slows | 3.2 s | Mythic fanfare |
| Godly | Red/gold rays, connected screen fractures, heavier short shake, dusk sky | 3.4 s | Godly bass/stinger |
| Celestial | White/cyan falling stars, item halo, connected constellation, shimmering item name, native starry night | 4.2 s | Mythic at 65% gain pending a choir/chime asset |
| Secret | Dimmed reality glitch, black hole/accretion rings, orbiting stars; name/model/odds concealed for 1.45 s, then two short RGB split flickers | 4.8 s | Secret (existing unique 2.4 s sound) |

`Config/Reveals.luau` keys everything by rarity name, including signature, sound, duration, color and sky. Celestial is guarded by `Config.Rarities` membership: its config is unused until the parallel data task adds the rarity. No new rarity/item/economy data is introduced here. Secret works at order 8 or 9; the collection UI already enumerates/sorts the rarity table without an eight-tier limit. The shared tier lookup and checks now accept nine names. Server audience/index reward/data changes remain owned by the data session.

`NEW!` is a golden stamp on the first natural discovery, based on the existing lifetime `State.Collection` snapshot, plus accepted results seen this session. The current natural protocol sends Result before the updated State. No stamp is inferred before the first snapshot, and admin previews never mark discoveries. Repeated/replayed results and sold/reset inventory cannot recreate a first discovery. Compact results carry a golden rich-text `NEW!` prefix with escaped item names; coalescing shows the retained best find's discovery state, not every suppressed find.

One active reveal plus at most two pending big reveals. Lower tiers and overflow reuse one toast and do not interrupt the active stinger. Far auto-flush retains its quiet coalesced toast; it cannot cancel a big reveal already playing. All animation exits restore the camera/Lighting and destroy local models/effects. Tap/click, B and Escape skip immediately; no modal backdrop, camera mode change, movement binding or physics/time-scale change is installed. Full uses signatures; Reduced uses a static short pop; Off uses compact text. Quick reveals remains a Reduced override. Audio follows existing SFX settings independently of visual intensity.

Secret's shared banner still comes exclusively from the existing server `Event` pipeline. Its client consumer also acquires a five-second night sky, respecting Reduced/Off. A shared sky lease prevents local skip/timeout from restoring another active event. No new remote, broadcasting rule, reward or server service changed. Recipient eligibility and event rate limits remain exactly as before. Default project chat configuration was restored to match `chat-native-list.md` and the pre-existing audit gate.

The finder receives its reveal stinger only; the generic higher-priority ServerEvent cue is suppressed for that account so it cannot preempt the unique tier cue. Other Secret event recipients use Secret; other event rarities retain ServerEvent. The existing event duck and bounded AudioService mixer remain in charge of audio lifetime/priority.

Secret shared events also reach the far auto-flushing finder: its private result remains compact, while the shared banner/night still appears (night only in Full). Lower shared events retain the existing far-finder suppression.

### Budgets and remaining engine review

- Fixed caps: 24 animated UI particles on desktop, 14 on touch devices; up to 10 ray strips or 8 crack segments, or 7 constellation lines + 7 stars + 2 halo rings. Secret has 3 accretion rings. Zero new ParticleEmitters, world parts, uploaded textures or asset requests for decoration.
- One viewport/model; at most one local ColorCorrectionEffect and one blur (size 4, desktop only). Sky reuses the existing instance. UI/model animation runs at most 30 Hz; camera shake lasts 0.5 s and uses constant work at render priority 199/201. No allocations inside the visual tick except ordinary math values; no per-particle connections/timers.
- Target incremental presentation CPU: under 1 ms per 30 Hz update on a representative low-end phone, with total frame time under 33.3 ms. These are acceptance targets, **not measured results**. Profile full, Reduced, minimum graphics, consecutive jackpots and rotation/resizing in Studio/device play. Check model fit, halo visibility through the real viewport, night stars with Atmosphere, source loudness/permissions and two-client event overlap.
- No distinct Celestial choir/chime asset exists; the nearest existing Mythic cue is quieter as a documented fallback. Secret retains its current 2.4 s unique asset, shorter than the 4.8 s visual. No sound is synthesized or stretched and no asset ID is invented.
- Extended production-controller checks cover all supported safe areas, ninth-tier activation/deactivation, signatures, discovery/admin/repeats, conceal/reveal, mobile caps, queue pressure, modes, timing, overlapping sky restoration and teardown. Headless PNGs omit viewport contents and engine Lighting, and approximate gradients/rotation; they are layout evidence only.

Validation: all standalone `scripts/check-*.luau` (bundle-dependent audit/runtime checks through their PS1 runners), `check-audit.ps1` (173 passed), `check-ui.ps1` (including 972 layout cases), `check-visuals.ps1`, all six `check-world.ps1` modes, Rojo build and StyLua with the Windows checkout line-ending override. Selene attempted: missing `roblox` standard library. No Studio/device performance or live multiplayer rendering claim.

## Previous implementation record

2026-10-06 follow-up: [rare-find chat and native player list](chat-native-list.md) supersedes the chat audience, boolean chat setting and custom player-list sections below. Rare+ now reaches the finder, Epic/Legendary adds friends, Mythic+ adds the server; the native Roblox PlayerList replaces ServerPlayers and its custom Tab binding. Original reveal behavior is unchanged.

Task branch: `feature/reveal`. No commits/pushes. [API research](../research/rare-drop-presentation.md).

## Implementation

- New client modules in `src/client/Presentation/`: quick Common/Uncommon pop, Rare burst, Epic sparkles, Legendary/Mythic full-width colored banner/rays/confetti and brief camera shake; Godly/Secret three-second dimmed reveal with shared item template in a rotating ViewportFrame and a local Lighting tint fading to neutral. All reveals can be skipped by tap/click or B/Escape. The cinematic does not capture movement or change camera type. The single animation controller releases models, effects and render callbacks on completion, skip, setting changes or teardown.
- At most one active reveal plus **two waiting big reveals**. Lower rarities and overflow replace one compact toast; no unlimited task/tween/model queue. Duplicated authoritative FlushId values are ignored. Full/Reduced/Off select animated effects, a static short pop, or compact results only. The existing Quick reveals option overrides Full to Reduced for compatibility.
- Stingers use AudioService's existing empty-safe Assets hooks and bounded voices. No asset IDs added. Base rarity is labeled `Base check • 1 in X`; the Godly/Secret cinematic additionally shows the actual outcome probability captured by the server roll before the event changes luck.
- `AnnouncementService` observes the existing EventService Trigger once. Legendary goes only to other in-server friends; Mythic/Godly/Secret goes to all eligible recipients. `DropAnnouncement` is outbound-only; clients display one rich-text RBXGeneral system message. Existing Event remains VFX-only. Account username (ASCII allowlist, 20-character cap) is used instead of DisplayName; markup/catalog strings are escaped. This is authored game text, not a user free-text relay.
- Per-player flush high-water dedupe, five-second acceptance/delivery gaps, one pending/in-flight announcement per sender, 16-entry global cap and 15-second TTL. One serial worker bounds yielding friendship queries. Failure/expiry/departure/session replacement suppresses delivery; recipient opt-out and session are checked immediately before each FireClient. A hung friendship backend can pause cosmetic delivery, but cannot grow threads or affect grants. Old world-event queue is also capped at 16; luck still refreshes immediately.
- `PlayerListService` publishes exactly two numeric/string leaderstats: Coins (primary) and Rarest (rarity of the saved best self-flushed item). Values are polled/diffed at most once per second; missing/expired profiles are removed. The custom client player list sorts exact numeric Coins descending, ties by UserId, and renders K/M/B/T/Qa without rounding up. Open with **Tab** or **Settings → Open player list**; close by its X or Tab. This replaces CoreGui PlayerList and restores it on teardown. It starts collapsed, including on mobile, to preserve HUD space.
- New rate-limited `PresentationSettings` accepts only a nonempty subset of `RevealIntensity = Full/Reduced/Off`, `ChatAnnouncements = boolean`; 3-token bucket, 1/s refill. No extra args, unknown keys or access without a live profile. Audio and economy fields cannot be patched. DataService has three additive lines to default/migrate/persist these preferences. Init scripts only wire new modules/remotes.
- The flush path refuses saturated inventory, collection or lifetime-flush counters before awarding any service Coins. This closes the numeric-boundary partial-grant case for the touched reveal/event path; it does not change persistence guarantees.

## Validation and limitations

Passed: Rojo build, full StyLua check, all standalone `scripts/check-*.luau`, 43 audit regressions, UI runtime/layout checks, default visual checks, all six world/template scenarios and `git diff --check`. Audit/UI runtime files execute through their bundling runners.

`check-presentation.luau`: all tiers/modes, saturation, queue caps, rate/dedupe boundaries, abbreviation thresholds, name/settings sanitization and capped EventService observation.

`check-audit.ps1` now includes `presentation-audit.luau`: real flush-to-chat integration, authoritative odds, setting fuzz/limits/profile round-trip, ceiling atomicity, forged item rejection, exact friend/server audience, yielded friendship failure/leave/session/TTL/opt-out races and public leaderstats data allowlist. Existing audit cases remain in the same runner.

`check-ui.ps1` now includes `presentation-ui-checks.luau`: actual production controller construction, model preview call, camera restoration, touch skip, queue overflow, modes/replay/timeout/teardown cleanup, chat toggle, numeric list ordering and departing row removal. Layout checks include full cinematic name/odds/model/44px skip separation across the seven supported safe-area sizes. Shared template builders remain covered by the existing visual/world runners.

Offline PNG review is a **headless approximation**, not a Roblox rendering pass; its renderer cannot draw ViewportFrame contents or faithfully render ray gradients. No connected Studio was available (`studios: []`). Actual GPU effects, model framing/asset permissions, chat/platform behavior, multiplayer friendship/cache behavior and device performance remain engine QA. Selene is installed but its configured `roblox` library is missing. Existing crash/outage persistence limits remain unchanged.
