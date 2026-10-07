# Coin-gated rebirth with permanent progression

> Current cash validation: [uncapped cash](no-cash-cap.md). Luck validation: [full linear luck and regenerated pacing tables](luck-linear.md). Total luck applies in full to every item check without a total ceiling; this supersedes earlier luck formulas and measured balance snapshots below.

2026-10-06, `feature/rebirth-balance`; supersedes the earlier flush/tier gate and reset-to-Basic contract. [Economy tables and assumptions](economy-v2.md), [cash/source review](../research/rebirth-cash-layers.md). No commit/push.

## Rebirth balance retune (2026-10-06)

The owner removed every cash multiplier cap on 2026-10-07. Cash Boost and rebirth now multiply. Coin requirements are retuned in Config/Rebirth; reward rows, starter grants, 300 fresh flushes, luck and speed rules remain unchanged. See [uncapped cash before/after tables](no-cash-cap.md).

## Click interaction (2026-10-06)

Implemented on `feature/rebirth-click`, without commit/push. The server already accepted exactly one expected-level argument and never required a client duration. That contract, coin/flush checks, five-second token bucket and atomic save remain unchanged. `scripts/check-audit.ps1` now runs the shared click UI checks plus actual button-to-handler double-click, payload rejection, missing-gate and spam regressions. Tutorial and hint sources contain no Rebirth holding instructions.

## Reset contract

**Keep:** every toilet tier and upgrade level; all display slots, exact pedestal positions and displayed copies; lifetime collection/index/rarest find/lifetime flushes; index claims, stamps, cosmetics, daily claims, tutorial state, passes/commerce receipt history and settings. Copies retained on display remain protected from sale. An empty purchased slot is also permanent.

**Reset:** wallet to the next level's starter coins; all non-displayed inventory, including loose first copies and previously protected copies; all uncollected pending income; successful-flushes-since-rebirth counter. No first-copy inventory is reconstructed from lifetime discoveries. The UI explicitly says ALL loose inventory resets.

`DataService:Get` settles the old income state before eligibility/build. This records elapsed pending earnings, but does not transfer them to the wallet; uncollected pending cannot satisfy the coin gate and is then discarded. Collected coins are part of the wallet that resets. The new ledger retains `max(now, old UpdatedAt)` to prevent replay/clock rollback. New income uses retained toilets, tracks and displays plus the new rebirth bonus.

## Requirements and rewards

`Rebirth(expectedLevel)` accepts exactly one finite integer generation. Server rules require the current saved level, sufficient wallet coins, and at least **300 successful flushes since the last rebirth**. No toilet-tier requirement remains. Maximum is 15. The entire wallet resets, rather than deducting the gate and retaining excess coins; the window discloses the current wallet and pending loss above its single-click REBIRTH! button.

Current coin requirements and measured normal/casual/grinder times are maintained in the [uncapped cash report](no-cash-cap.md).

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

Cash stacking is `(1 + CashBoostEffect) * (1 + RebirthCash) * displayToiletFactor * paidCashFactors`. The toilet factor is 1 for sales/service. Milestone titles have no hidden numeric reward. Double Cash is 2x and VIP 1.5x; future paid cash factors multiply further. No cash multiplier cap applies. Config/Cash owns the shared UI explanation.

R15 alone is 16x; Cash L100 multiplies that to 68x free or 204x with both cash passes. Galaxy displays multiply by 13; Infinity Flush by 325. Daily coins keep the paid-only rule. Starter grants are unboosted; collection and quoted receipts never multiply twice. Luck is uncapped; the cooldown floor remains 0.4s. Late prices and coin gates are retuned; reward effects stay unchanged.

R5 grants free Auto Collect through the same server method, five-second scheduler, living-owner/assigned-plot ownership checks anywhere on the map and the shared 30-minute PlayerActivity idle guard, save guard and fractional ledger used by the pass. It never marks the pass owned or grants coins independently. R10 adds two slots once, up to the ten-slot physical capacity; already-full and legacy larger plots retain capacity without refunds. The saved RebirthAppliedSlots marker prevents repeated grants on rejoin or rebirth. Existing R10+ saves receive the slot allowance on migration while retaining their level.

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

Existing saved rebirth levels automatically read the new bonus table; no coin compensation or level reset is performed. Malformed levels retain the existing sanitizer behavior. Profiles still migrate lifetime flushes into the first run only when no run counter exists; later missing run counters become zero. The separate UpgradeVersion=2 migration clamps old levels under old maxima before preserving new caps on future saves. Rebirth does not rewind the commerce ledger, product quotes, saved legacy slot capacity or VIP daily claim. The active auto-flush toggle can stop while Get is unavailable during the exclusive save; its lifetime unlock and saved preferences remain.

## UI/world and verification

The window shows wallet/coin-gate progress, run flush progress, current/next permanent bonuses, starter coins, and separate reset/keep lists. A single click/tap on REBIRTH! sends the expected level immediately. The button disables before the request and stays locked until the Rebirth server result, including across closing/reopening, state updates and response timeouts. A timeout requests state once without retrying or unlocking the transaction. Success prevents a stale generation from enabling the button until an updated snapshot arrives. After a rejection, local retry pacing uses the existing Rebirth remote refill rate and briefly shows PLEASE WAIT, without a countdown or automatic retry; this prevents a rapid retry from consuming a silently rejected request. Disabled labels name missing coins, flushes, or both; progress labels show exact requirements. Reset/keep lists, reward/perk preview and the wallet/pending loss disclosure remain above the button. No countdown or confirmation dialog is used. Stairs reuse their geometry and display each milestone's cumulative cash/luck/speed bonuses alongside the next coin gate and 300 fresh flushes. The scrolling window lists cumulative free and cosmetic perks; cash bonuses multiply the other cash factors without a cap. Both the Cash Boost card and the rebirth window explain this stacking. Upgrade footer explicitly says toilets and upgrades are permanent. All coins use compact notation.

Drop/rebirth announcement cooldowns, bounded queues, friend lookup worker, deduplication and preferences are unchanged. Levels 3-4 notify friends and 5+ the server within that same budget. Higher luck is measured against the existing event drain in simulate.luau, not justified by increasing queue capacity.

The audit suite now covers permanence at extended levels, first/protected loose-item deletion, empty/sparse paid/index capacity, old/new schema round-trips, every coin boundary, pending exclusion, spent-wallet races, level-100 ambiguous purchase saves, rebirth callback replay, held reset/collection/purchase races, lease loss, rejoin, ceilings and spam. All retained earlier security scenarios still execute with updated expected reset behavior.

Headless UI/previews and world checks do not establish real touch/gamepad behavior, mobile FPS, service availability or crash durability. Retire older binaries before rollout; their sanitizers would truncate extended levels. Keep billing tests isolated; permanent paid luck now follows the policy-gated VIP/2x Luck contract.
Click task validation (2026-10-06): StyLua check and `rojo build -o build.rbxl` pass. All 22 standalone `scripts/check-*.luau` pass; `check-audit.luau` and `check-ui-runtime.luau` run through their PowerShell bundles. `check-audit.ps1`: 255 passed, 0 failed. `check-ui.ps1`: production constructors/callbacks and 972 layout cases pass, including reset/keep/reward content above the button; its initial hardcoded 3M Rebirth gate assertion now reads the unchanged Config gate. `check-visuals.ps1` and `check-world.ps1` pass, including all six world template modes. Selene was invoked but cannot load the missing local roblox standard-library file. No live Studio/device test was performed. RebirthHold assets and their generic mixer checks remain dormant for upload provenance; the Rebirth UI never starts them. No tutorial/hint holding text existed. No commit or push.

Permanent luck update (2026-10-07): VIP +25% luck and 2x Luck are random-item odds boosts, preserved through rebirth as pass entitlements, and usable only with current policy eligibility. Free upgrade/rebirth luck values are unchanged. Total luck is uncapped; each Lucky Flush charge multiplies the current total by ten. Individual checks still stop at probability 1, and earlier certain outcomes suppress later items. Pass cards expose Info: all item odds; the HUD and odds breakdown identify "VIP +25% luck" and "2x Luck pass", or "unavailable in your region". Percentage rounding is disclosed. [Details and balance](vip-luck-balance.md).
