# Coin-gated rebirth with permanent progression

2026-10-06, `feature/rebirth-balance`; supersedes the earlier flush/tier gate and reset-to-Basic contract. [Economy tables and assumptions](economy-v2.md), [cash/source review](../research/rebirth-cash-layers.md). No commit/push.

## Rebirth balance retune (2026-10-06)

The manager approved a 40x free cash layer and a separate 3x paid layer, plus rebirth coin-gate tuning. The 15 reward rows, starter grants, 300 fresh-flush minimum, luck rules, speed floor and permanent-progression contract remain intact. See [current validation](rebirth-values-validation.md), [all measured tables](rebirth-values-balance.txt) and [three-archetype rebirth report](rebirth-values-simulations.txt). No commit or push.

## Reset contract

**Keep:** every toilet tier and upgrade level; all display slots, exact pedestal positions and displayed copies; lifetime collection/index/rarest find/lifetime flushes; index claims, stamps, cosmetics, daily claims, tutorial state, passes/commerce receipt history and settings. Copies retained on display remain protected from sale. An empty purchased slot is also permanent.

**Reset:** wallet to the next level's starter coins; all non-displayed inventory, including loose first copies and previously protected copies; all uncollected pending income; successful-flushes-since-rebirth counter. No first-copy inventory is reconstructed from lifetime discoveries. The UI explicitly says ALL loose inventory resets.

`DataService:Get` settles the old income state before eligibility/build. This records elapsed pending earnings, but does not transfer them to the wallet; uncollected pending cannot satisfy the coin gate and is then discarded. Collected coins are part of the wallet that resets. The new ledger retains `max(now, old UpdatedAt)` to prevent replay/clock rollback. New income uses retained toilets, tracks and displays plus the new rebirth bonus.

## Requirements and rewards

`Rebirth(expectedLevel)` accepts exactly one finite integer generation. Server rules require the current saved level, sufficient wallet coins, and at least **300 successful flushes since the last rebirth**. No toilet-tier requirement remains. Maximum is 15. The entire wallet resets, rather than deducting the gate and retaining excess coins; the window discloses the current wallet and pending loss before its review/hold action.

| Next rebirth | Wallet coin gate | Normal cumulative p50 / p90 hours |
|---|---:|---:|
| 1 | 3M | 0.40 / 0.52 |
| 2 | 12M | 0.56 / 0.73 |
| 3 | 35M | 0.93 / 1.20 |
| 4 | 100M | 1.26 / 1.62 |
| 5 | 500M | 2.02 / 2.75 |
| 6 | 1B | 3.36 / 4.46 |
| 7 | 2B | 5.21 / 6.38 |
| 8 | 4B | 7.64 / 9.36 |
| 9 | 15B | 23.17 / 26.99 |
| 10 | 40B | 32.00 / 48.61 |
| 11 | 120B | 46.83 / 64.94 |
| 12 | 200B | 52.48 / 73.75 |
| 13 | 320B | 61.59 / 87.21 |
| 14 | 520B | 72.02 / 104.42 |
| 15 | 1.25T | 96.83 / 138.50 |

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

Cash stacking is `min(40, (1 + CashBoostEffect + RebirthCash) * displayToiletFactor) * min(3, paidCashFactors)`. The toilet factor is 1 for sales/service and the configured tier factor for displays. Cash Boost and rebirth bonuses add; milestone titles have no hidden numeric reward. Double Cash is 2x and VIP is 1.5x. Both paid passes therefore retain their full 3x effect even when the free layer is capped. Config/Cash owns both caps and the shared UI explanation. Future paid cash pass entries share the paid cap.

R15 with no Cash Boost is really 16x for sales/service; Cash L100 makes it 19.25x free, or 57.75x with both passes. Galaxy display income reaches the free 40x cap; paid factors then lift it to 120x. The cap still applies to combined free display progression. Ordinary daily coins retain their paid-only rule. Starter grants, pending collection, receipt quotes and the VIP chest are never multiplied a second time. Luck retains its 10x cap and diminishing returns beyond 5x for odds strictly rarer than 1/25K; speed retains the 0.4s floor, including Fast Flush. Toilet and upgrade prices/effects are unchanged.

R5 grants free Auto Collect through the same server method, five-second scheduler, living-owner plot bounds, save guard and fractional ledger used by the pass. It never marks the pass owned or grants coins independently. R10 adds two slots once, up to the ten-slot physical capacity; already-full and legacy larger plots retain capacity without refunds. The saved RebirthAppliedSlots marker prevents repeated grants on rejoin or rebirth. Existing R10+ saves receive the slot allowance on migration while retaining their level.

Config cosmetics unlock at R2 (overhead title), R4 (violet trail), R6 (emerald sign trim), R8 (chat tag), R10 (cyan trail), R12 (gold sign trim), R14 (Eternal chat tag), and R15 (Legend toilet glow, golden title and character aura). The latest unlocked style per category is automatic. They do not modify the toilet tier or economic stats. Effects are reused on refresh and removed on reset/reassignment; respawn uses the existing cosmetic lifecycle. No new assets, remote requests or animation loops are introduced.

Each gate is much larger than its starter grant, so resets cannot print money. Fresh flushes provide a separate minimum even for inherited jackpot displays/offline wallets. Current pacing and cohort limitations are reported in economy-v2.md; older reward-only and pre-retune tables are superseded.

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

The window shows wallet/coin-gate progress, run flush progress, current/next permanent bonuses, starter coins, and separate reset/keep lists. Existing two-second hold, focus/release/panel/scroll cancellation, pending lock and response timeout stay intact. Stairs reuse their geometry and display each milestone's cumulative cash/luck/speed bonuses alongside the next coin gate and 300 fresh flushes. The scrolling window lists cumulative free and cosmetic perks; nominal cash bonuses are labelled before caps. Both the Cash Boost card and the rebirth review explain the 40x free / 3x paid / 120x maximum cash rule. Upgrade footer explicitly says toilets and upgrades are permanent. All coins use compact notation.

Drop/rebirth announcement cooldowns, bounded queues, friend lookup worker, deduplication and preferences are unchanged. Levels 3-4 notify friends and 5+ the server within that same budget. Higher luck is measured against the existing event drain in simulate.luau, not justified by increasing queue capacity.

The audit suite now covers permanence at extended levels, first/protected loose-item deletion, empty/sparse paid/index capacity, old/new schema round-trips, every coin boundary, pending exclusion, spent-wallet races, level-100 ambiguous purchase saves, rebirth callback replay, held reset/collection/purchase races, lease loss, rejoin, ceilings and spam. All retained earlier security scenarios still execute with updated expected reset behavior.

Headless UI/previews and world checks do not establish real touch/gamepad behavior, mobile FPS, service availability or crash durability. Retire older binaries before rollout; their sanitizers would truncate extended levels. Keep billing tests isolated; no new paid luck or IDs are added.
