# Rebirth implementation and review

2026-10-06 income-first update: [Economy v2](economy-v2.md) supersedes the historical rates, prices, offline cap and timing assertions below. Collection, protection, lease and reset contracts remain.

2026-10-06: [Display/collection follow-up](display-collect.md) retunes passive income and extends balance cohorts with retained displays. Reset/protection rules and the 60–90-minute first-rebirth target remain; the old passive fraction below is superseded.

2026-10-05, `feature/rebirth`. Uncommitted; no pushes. This implementation supersedes the old Galaxy/fee/all-inventory proposal in progression.md. [Current API research](../research/rebirth.md).

## Eligibility and tuning

The server requires Diamond (runtime tier **4**) or better and **3,600 successful flushes since the last rebirth**, with a maximum of 15 rebirths. No fee, rare drop, paid product or time gate. Config lives in `src/shared/Config/Rebirth.luau`. The requested starting proposal of 1,200 flushes was measured at only 27.89 minutes with the current faster upgrade economy; the count was tuned to meet the requested 60–90 active-minute target. Set `RequiredFlushes = 1200` to restore that faster option; the balance target assertion will intentionally flag it.

`luau scripts/balance.luau` runs a seeded 500-player, two-run cohort using actual roll distributions, purchases, first-copy protection and the real reset builder. Assumptions: 75% manual cooldown uptime; sell all unprotected duplicates; buy one Cash/Luck/Flush Speed level per tier through level four before buying the next toilet; continue buying toilets while accumulating flushes. No daily, tutorial, offline, passive or pass income. Auto-Flush is slower unless its separate speed track is purchased. Utility purchases and collection choices can delay progression.

The complete checked output is in [rebirth-balance.txt](rebirth-balance.txt), including the unchanged toilet cohort and income bounds.

| Run | p50 minutes | p90 minutes |
| --- | ---: | ---: |
| First rebirth | 71.06 | 71.66 |
| Second rebirth, including starter coins and permanent bonuses | 62.29 | 62.83 |

Second-run median is **12.3% faster**. At the absolute 0.4-second floor, 3,600 new flushes still require at least 24 minutes of uninterrupted cooldown-perfect activity, regardless of wallet/offline rewards. These are simulated estimates, not live retention measurements or a guarantee for every play style.

## Exact reset contract

| Field or source | Result |
| --- | --- |
| Coins | Replace with the next level's fixed starter grant: 2,500 at level 1, +250 per level, 6,000 at level 15 |
| Current toilet | Basic, tier 1 |
| All six coin upgrade tracks | Level zero; no refund |
| Pending passive coins | Empty ledger; timestamp is `max(now, previous high-water timestamp)` |
| RunFlushes | Zero; only successful server flushes increment it |
| Inventory | Keep the greatest of one owned first copy, displayed copies, and previously protected copies of each known item; remove other copies |
| ProtectedInventory | All kept copies become permanently unsellable; they remain freely displayable. New duplicates can be sold. Removing a display never unlocks a carried copy for sale |
| Displays | Pack existing assignments in ascending old slot order into retained capacity. Excess displayed copies go to protected inventory, never disappear |
| Display capacity | Remove only tracked coin-bought levels; preserve index minima and remaining legacy/unknown/paid-origin capacity. Current paid slot products do not exist |
| Lifetime collection / best finds / total flushes / Earned | Keep. Starter coins increase Earned once; reject the whole reset if this would exceed 9e15 |
| Index claims/cosmetics, Stamps, daily state/boost, tutorial dismissal, settings | Keep, with no repeated claim or tutorial award |
| Pass entitlements | Existing server pass cache/platform ownership is untouched; cosmetic settings remain |
| RebirthLevel | Increment once, maximum 15; saved level is the permanent badge/title/token entitlement |

Permanent protection is a deliberate scope decision. The game has no acquisition-price/provenance ledger yet. No carried copy can be sold at a higher rebirth multiplier; future unlocking/trading requires that ledger first. No item is created to replace a previously sold lifetime discovery. The UI states this protection explicitly before confirmation.

Legacy saves without rebirth fields start at level zero and use lifetime flushes as first-run progress. Missing run counts at a nonzero rebirth level start at zero. Integer/nonfinite validation, inventory-bounded protected counts and a maximum level whitelist are applied on every load/save. Rebirth level is restored **before income capacity sanitation** to avoid clipping legitimate high-level pending balances.

## Bonuses and cosmetic tokens

Cash adds 25 percentage points per level for levels 1–3, 10 for 4–8, then 5 for 9–15; capped at **+160%**. It adds to the coin Cash Boost, so maximum total cash is **3.6x**, not an exponential product. Applies to service, new sellable copies and passive income/rate/storage caps. Whole service/sale coins round down per copy; batching cannot improve rounding. Daily rewards and index Stamps are unchanged.

Luck adds 2 percentage points per level, capped at +30%, in the same additive factor as the coin luck track. All temporary modifiers then pass through the existing **5x total cap**. Speed subtracts 4 percentage points of base cooldown per level for levels 1–3, then 1 per level, capped at 20%; the shared **0.4-second floor** and auto/manual cooldown remain authoritative.

`check-rebirth.luau` enumerates all 15 levels, all seven toilet tiers and every Cash/Speed level combination. It proves bounded nonincreasing cash increments, the luck/floor bounds, one-item probability sum and passive income below one third of guaranteed active service income at 75% uptime. Upgraded lifetime earnings/stat ceilings remain enforced.

Each config level defines a permanent title, in-game profile badge and a free numbered **Rebirth Token**, with a fixed cosmetic-only perk list. Token count is derived from saved level; tokens are not spendable, tradeable or a random/paid currency. The current title/token count is visible in the Rebirth window; the player list displays `[R<n>]`. No Roblox BadgeService asset IDs, skins or promised future gameplay powers are invented.

## Transaction and recovery

`Rebirth(expectedLevel)` accepts exactly one finite, nonnegative integer below the level cap. Its bucket is capacity 1, refill 0.2/second. Requirements use only the live lease-gated server profile. A pending ordinary save causes rejection instead of queuing a reset behind an old snapshot.

The handler deep-copies the sanitized profile and constructs the complete new state without yielding. `DataService:ReplaceAndSave` checks profile identity/lease and save availability again, installs a replacement guard, swaps `Profiles[player]` once, then immediately invokes the existing Save. While it yields, `Get` exposes neither profile for gameplay. There is no separate rebirth datastore or incremental reset write.

Save uses the existing four-attempt immutable snapshot, owned unexpired lease check on every UpdateAsync callback, backoff and fail-closed rules. It does **not** roll back the swap on error: a response may have been lost after committing. Exhausted failures kick/block the session; Close retries the same complete replacement while ownership remains valid. Close/rejoin/shutdown retain existing serialization. Success, State, celebration and milestone announcement happen only after an acknowledged save with the same live replacement.

| Failure point | Recoverable persisted state |
| --- | --- |
| Crash before reset write | Entire previous successfully saved profile; ordinary unsaved progress may be lost |
| Commit followed by lost response | Entire new profile; retries write the same level, grants and reset together |
| Callback replay / foreign lease takeover | Write aborts; never overwrites the new owner's profile |
| Disconnect while saving | Final save waits, writes/releases the complete replacement; no stale success effect |
| Replayed old request after rejoin or later eligibility | Saved level mismatch rejects it |
| Backend never returns / final save deadline | Existing audit L3 durability limit remains; no exactly-once notification or unlimited-outage guarantee |

The ledger timestamp resets with the profile, so old offline/pending earnings cannot be reclaimed. New income starts from retained displays at Basic's capped rate. Backward clock adjustments retain the high-water mark. Account-level auto unlock remains from lifetime flushes; an active auto toggle may stop during the exclusive save and can be re-enabled afterward.

## UI and world integration

Six-button responsive navigation adds Crown/Rebirth, with a ready badge and existing vector fallback. The window shows current bonuses/title/token count, flush/tier progress, two-column reset/keep lists, next bonuses, starter coins and the wallet/pending loss. Scroll to the review button, activate it, then hold for two seconds. Mouse, touch and selected gamepad/keyboard input are supported. Release, focus loss, mouse leave, selection loss, panel close and scrolling cancel the hold. A 15-second response timeout requests fresh State without automatically retrying the reset or claiming success.

Successful saves play a bounded crown celebration; reduced/off presentation settings are respected. Levels 3–4 notify online friends and 5+ the server, through the **same** bounded announcement queue, cooldown, friend lookup worker and chat preference filter as drops. Rebirth and drop replay IDs are separate, but their rate budget is shared. Milestones may be suppressed by that budget; this is intentional.

No existing World file or geometry was edited. The requested stairs placeholder is absent in this worktree. `src/server/World/RebirthHook.luau` supplies `Attach(anchor, owner)` for the polish session: call on an existing stairs BasePart/Attachment anchor when assigning a plot, and `Attach(anchor, nil)` when releasing it. It creates/reuses only one default-style prompt, tags `RebirthOwnerUserId` and `OwnerUserId`, and opens the existing panel through WorldNavigation. It cannot perform a rebirth. The hook's attach/reassign/release behavior is checked by the world harness. **Stairs placement and calling the hook remain with polish**; the left-column button works independently.

## Verification and remaining limits

Headless review images (not engine screenshots): [desktop overview](rebirth-previews/rebirth-1280x684.png), [desktop confirmation](rebirth-previews/rebirth-confirm-1280x684.png), [phone overview](rebirth-previews/rebirth-360x518.png), [phone confirmation](rebirth-previews/rebirth-confirm-360x518.png), [short landscape confirmation](rebirth-previews/rebirth-confirm-640x303.png).

- Audit runner: **68 passing scenarios**, including atomic reset, yield blocking, double-click/stale generation, malformed/1,000-request spam, pending ordinary save, old/new rejoin, callback replay, lease loss, pre/post-commit exhaustion, response-loss retry, offline cap/high-water, index capacity saturation, first-copy/display protection and announcement audiences/cleanup.
- All standalone `scripts/check-*.luau` pass; audit/UI runtime scripts run via their PS1 bundlers. UI coverage includes 972 safe-area geometries and actual confirmation reachability after scrolling on 12 viewports.
- Passed: `check-ui.ps1`, `check-visuals.ps1`, six-mode `check-world.ps1`, `balance.luau`, `rojo build -o build.rbxl`, `stylua --check --line-endings Windows src scripts`, and `git diff --check`. Headless UI renders were inspected; they approximate Roblox rendering.
- Selene was attempted but cannot find the configured `roblox` standard library. No lint-pass claim.
- Studio MCP reports `studios: []`. Published multi-client DataStore crash/latency behavior, real touch/gamepad scrolling, uploaded icon permissions and device performance remain untested. Headless tests do not prove live service availability or exactly-once durability.
- Deployment must retire older server builds before enabling rebirth for players. An older binary's whitelist sanitizer does not preserve these new profile fields; cross-version rolling-server compatibility is not provided by this patch.

Main files: `Config/Rebirth`, `RebirthRules`, `Services/RebirthService`, `DataService`, `UI/Rebirth`, shared cash/luck/speed and inventory integration, announcement/player-list wiring, the optional `World/RebirthHook`, and rebirth audit/UI/math/balance fixtures. Unrelated map builders remain untouched.
