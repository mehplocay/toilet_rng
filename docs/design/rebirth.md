# Coin-gated rebirth with permanent progression

2026-10-06, `feature/permanent`; supersedes the earlier flush/tier gate and reset-to-Basic contract. [Economy tables and assumptions](economy-v2.md), [source review](../research/permanent-economy.md). No commit/push.

## Stronger rewards review (2026-10-06)

The catalog/rebirth integration retains the nominal stronger reward table under the existing 10x total cash cap, as required by the merge task. R3/R4/R5/R15 coin gates are now 100M/400M/900M/7.5T to restore pacing without loosening balance assertions. See [the latest merge report](catalog2-rebirth-merge.md). Earlier tables and timing measurements below are historical; they predate this gate retuning. The [reward-only validation](rebirth-values-validation.md) records the failures that motivated it.

## Reset contract

**Keep:** every toilet tier and upgrade level; all display slots, exact pedestal positions and displayed copies; lifetime collection/index/rarest find/lifetime flushes; index claims, stamps, cosmetics, daily claims, tutorial state, passes/commerce receipt history and settings. Copies retained on display remain protected from sale. An empty purchased slot is also permanent.

**Reset:** wallet to the next level's starter coins; all non-displayed inventory, including loose first copies and previously protected copies; all uncollected pending income; successful-flushes-since-rebirth counter. No first-copy inventory is reconstructed from lifetime discoveries. The UI explicitly says ALL loose inventory resets.

`DataService:Get` settles the old income state before eligibility/build. This records elapsed pending earnings, but does not transfer them to the wallet; uncollected pending cannot satisfy the coin gate and is then discarded. Collected coins are part of the wallet that resets. The new ledger retains `max(now, old UpdatedAt)` to prevent replay/clock rollback. New income uses retained toilets, tracks and displays plus the new rebirth bonus.

## Requirements and rewards

`Rebirth(expectedLevel)` accepts exactly one finite integer generation. Server rules require the current saved level, sufficient wallet coins, and at least **300 successful flushes since the last rebirth**. No toilet-tier requirement remains. Maximum is 15. The entire wallet resets, rather than deducting the gate and retaining excess coins; the window discloses the current wallet and pending loss before its review/hold action.

| Next rebirth | Historical wallet coin gate | Previous-reward normal cumulative p50 / p90 hours |
|---|---:|---:|
| 1 | 3M | 0.40 / 0.52 |
| 2 | 12M | 0.57 / 0.76 |
| 3 | 35M | 0.96 / 1.30 |
| 4 | 100M | 1.29 / 1.66 |
| 5 | 500M | 2.03 / 2.62 |
| 6 | 1.5B | 3.94 / 5.13 |
| 7 | 5B | 7.73 / 9.36 |
| 8 | 15B | 18.57 / 21.70 |
| 9 | 40B | 27.69 / 35.90 |
| 10 | 80B | 34.65 / 52.52 |
| 11 | 150B | 38.28 / 63.77 |
| 12 | 250B | 43.13 / 74.58 |
| 13 | 400B | 52.23 / 84.26 |
| 14 | 650B | 63.11 / 94.37 |
| 15 | 2.5T | 95.67 / 133.84 |

All gates and rewards live in an explicit 15-row Config/Rebirth table. Cumulative bonuses are:

| Rebirth | Cash bonus | Luck bonus | Speed reduction |
|---|---:|---:|---:|
| 1 | +50% | +5% | 3% |
| 2 | +110% | +10% | 5% |
| 3 | +180% | +15% | 7% |
| 4 | +240% | +20% | 9% |
| 5 | +300% | +25% | 10% |
| 6 | +380% | +32% | 13% |
| 7 | +470% | +39% | 16% |
| 8 | +570% | +46% | 19% |
| 9 | +680% | +53% | 22% |
| 10 | +800% | +60% | 25% |
| 11 | +930% | +68% | 30% |
| 12 | +1070% | +76% | 35% |
| 13 | +1210% | +84% | 40% |
| 14 | +1350% | +92% | 45% |
| 15 | +1500% | +100% | 50% |

Cash adds to Cash Boost before paid factors: `min(10, (1 + CashBoostEffect + RebirthCash) * DoubleCash * VIP)`. Toilet display factors multiply this result; collection never applies another multiplier. The current 10x total cap clips the upper rewards, including the requested R15 x16. Luck retains the 10x global cap and diminishing returns beyond 5x for odds strictly rarer than 1/25K. Speed retains the 0.4s floor, including Fast Flush. Starter coins are unchanged; the four retuned gates are listed in the latest merge report.

R5 grants free Auto Collect through the same server method, five-second scheduler, living-owner plot bounds, save guard and fractional ledger used by the pass. It never marks the pass owned or grants coins independently. R10 adds two slots once, up to the ten-slot physical capacity; already-full and legacy larger plots retain capacity without refunds. The saved RebirthAppliedSlots marker prevents repeated grants on rejoin or rebirth. Existing R10+ saves receive the slot allowance on migration while retaining their level.

Config cosmetics unlock at R2 (overhead title), R4 (violet trail), R6 (emerald sign trim), R8 (chat tag), R10 (cyan trail), R12 (gold sign trim), R14 (Eternal chat tag), and R15 (Legend toilet glow, golden title and character aura). The latest unlocked style per category is automatic. They do not modify the toilet tier or economic stats. Effects are reused on refresh and removed on reset/reassignment; respawn uses the existing cosmetic lifecycle. No new assets, remote requests or animation loops are introduced.

Each gate is much larger than its starter grant, so resets cannot print money. Fresh flushes provide a separate minimum even for inherited jackpot displays/offline wallets. The previous p50 95.67h result is superseded by the reward-only 65.25h normal median with the earlier gates. The latest merge report measures the retuned gates. See the 64-seed/archetype simulation and its discretization limits in economy-v2.md.

## Transaction, replay and migration

The existing remote bucket stays one token, refill 0.2/s. Reject while an ordinary save is pending. Build one complete copied profile without yielding; compare-and-swap it through `ReplaceAndSave` only when the current profile and lease still match. All gameplay reads fail closed during that exclusive replacement save. Save retains immutable snapshots, ownership/lease checks on every UpdateAsync callback, retry backoff and post-save identity validation before success/sync/celebration.

Do not roll back on an ambiguous response: the replacement may already be committed. Retry the same complete state; exhausted failures block/kick, and Close can only retry while its lease remains valid. Replays use the saved rebirth generation, never a client-supplied price or arbitrary inventory. Concurrent collection, purchases, flushes and departure cannot observe a half-reset profile.

| Failure point | Permitted durable state |
|---|---|
| Crash before write | Entire last saved old profile; unsaved progress may be lost |
| Commit then lost response | Entire new profile, one level and starter grant |
| Callback replay or foreign takeover | Owned/unexpired transform only; never overwrite foreign state |
| Disconnect during save | Serialized final save of complete replacement; no stale success effect |
| Old request after rejoin | Generation mismatch rejects it |
| Backend never returns/deadline | Existing outage durability limit; no unlimited retry or exactly-once guarantee |

Existing saved rebirth levels automatically read the new bonus table; no coin compensation or level reset is performed. Malformed levels retain the existing sanitizer behavior. Profiles still migrate lifetime flushes into the first run only when no run counter exists; later missing run counters become zero. The separate UpgradeVersion=2 migration clamps old levels under old maxima before preserving new caps on future saves. Rebirth does not rewind the commerce ledger, product quotes, paid slots or VIP daily claim. The active auto-flush toggle can stop while Get is unavailable during the exclusive save; its lifetime unlock and saved preferences remain.

## UI/world and verification

The window shows wallet/coin-gate progress, run flush progress, current/next permanent bonuses, starter coins, and separate reset/keep lists. Existing two-second hold, focus/release/panel/scroll cancellation, pending lock and response timeout stay intact. Stairs reuse their geometry and display each milestone's cumulative cash/luck/speed bonuses alongside the next coin gate and 300 fresh flushes. The scrolling window lists cumulative free and cosmetic perks; nominal cash bonuses are labelled before caps. Upgrade footer explicitly says toilets and upgrades are permanent. All coins use compact notation.

Drop/rebirth announcement cooldowns, bounded queues, friend lookup worker, deduplication and preferences are unchanged. Levels 3-4 notify friends and 5+ the server within that same budget. Higher luck is measured against the existing event drain in simulate.luau, not justified by increasing queue capacity.

The audit suite now covers permanence at extended levels, first/protected loose-item deletion, empty/sparse paid/index capacity, old/new schema round-trips, every coin boundary, pending exclusion, spent-wallet races, level-100 ambiguous purchase saves, rebirth callback replay, held reset/collection/purchase races, lease loss, rejoin, ceilings and spam. All retained earlier security scenarios still execute with updated expected reset behavior.

Headless UI/previews and world checks do not establish real touch/gamepad behavior, mobile FPS, service availability or crash durability. Retire older binaries before rollout; their sanitizers would truncate extended levels. Keep billing tests isolated; no new paid luck or IDs are added.
