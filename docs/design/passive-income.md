2026-10-06 permanent progression update: [Economy v2](economy-v2.md) supersedes the historical tuning below. Toilets and upgrades now survive rebirth; only uncollected pending and loose inventory reset. Current tier factors are 1 / 1.5 / 2.2 / 3.3 / 5.25 / 8.5 / 13, base storage 37.44B per slot / 374.4B total, and Offline Tank spans 8-24h before paid factors and storage caps. The 6,000-unit ledger and 9e15-subcoin ceiling are unchanged.

# Passive display income

## Offline return window (2026-10-06)

Offline accrual is now **50% of the active display rate**, configured by `Config/Income.OfflineRate` and clamped to 0..1 before per-slot subcoin quantization. The permanent allowance is eight hours plus 24 minutes per level through L10, then eight minutes per level through L100 (24 hours). A verified Offline Plus doubles the allowance up to the same 24-hour maximum. `MaxOfflineMinutes` hard-caps accrual at 24 hours even if later entitlement configuration grows. Existing storage limits and the 9e15-subcoin global ceiling still apply; active income rates and progression prices do not change.

The lease acquisition's existing UpdateAsync transform consumes capped time and persists both pending units and `Income.Offline` in one record. The latter holds bounded remaining offline units, original earned units, cumulative time away and time for which income could no longer accrue. Sanitization bounds remaining offline credit by actual pending units. It is a designation of existing coins, never a second balance. Stored reports survive callback replay, lost responses and uncollected rejoins. Multiple uncollected absences combine their report; full-tank time accounts for both time allowance and storage exhaustion to whole-second precision. Missing timestamps, empty displays and backward clocks grant no retroactive credit.

Migration assumption: existing unlabelled pending units remain collectable on pads. Their historical online/offline origin cannot be reconstructed, so only newly settled offline earnings populate the new window designation. A fraction-only offline remainder waits for enough future offline credit or ordinary pooled collection.

The responsive **While you were away** window shows time away, available earnings, original earnings after partial collection and the full-tank upgrade message. It opens once per client session when at least one whole offline coin is available. Dismissing it leaves coins on the pads; repeated State updates do not reopen it. Collect waits for authoritative State/Result, disables duplicate clicks, and requests fresh State after a 15-second timeout without retrying automatically. Successful transfers use the existing five-coin fly animation and collect sounds.

`CollectOffline()` accepts no client amount, timestamp, slot or position. It requires the living owner, assigned plot and live lease, and shares CollectIncome's 1/2 input and 10/0.2 durable-save budgets. The window can transfer the remaining whole **offline portion** without proximity; fresh active income still requires normal pads/jar/authorized Auto Collect. Ordinary pad/jar collections consume the same offline credit first because wallet coins are fungible, including when the touched pad contains newer income. Fractional tails remain in pending storage and do not advertise an uncollectable window.

Debit pending, reduce offline designation, credit wallet/Earned and save one immutable snapshot before success. Busy saves reject, failed/ambiguous saves fail closed, and post-yield identity checks prevent stale success. Rebirth clears the complete income ledger/report. Headless tests cover window/pad races, replay, acquisition response loss, pre/post-commit outages, overlapping rejoin, foreign lease takeover, caps and exact fractions. This preserves the audit's existing crash/outage durability limits rather than promising exactly-once notifications or unlimited backend recovery. Retire older server binaries on rollout: their sanitizer cannot preserve this report. [Research](../research/offline-window.md).

2026-10-06, income-first economy. [Economy v2](economy-v2.md) owns current tuning and measured progression. [Display/collect](display-collect.md) records the unchanged placement, authorization and durable collection contract. [Research](../research/income-first-economy.md).

## Rates and presentation

Each displayed copy earns its rarity rate per second, multiplied by its owner's current toilet tier and additive cash bonuses:

rate = rarityRate * toiletMultiplier * (1 + 0.1 * CashBoostLevel + rebirthCashBonus).

Base rates: Common $1/s, Uncommon $3/s, Rare $10/s, Epic $40/s, Legendary $200/s, Mythic $1K/s, Godly $6K/s, Secret $100K/s. Tier factors: 1 / 1.5 / 2.2 / 3.3 / 5 / 8 / 12. King Poop follows its existing Mythic classification; Rat/Fish and both Secrets share their respective rarity rates. Sell value no longer determines income.

Config/Income owns the ladder, factors, rate/storage caps, timestamp bound and offline allowance. Cash Boost and rebirth affect both rates and capacities. Nametags show actual post-cap $/s, including proportional sharing for legacy displays. Coins use a shared K/M/B/T/Qa/Qi formatter across HUD, collection, shops/upgrades, rebirth, player list, boards, pending jar/pads and popups. Qi is supported by presentation but is unreachable under the wallet's 9Qa ceiling. The Offline Tank card clearly reports hours: 8 at base, 24 at maximum, including the hard limit after Offline Plus.

## Accounting and limits

- Keep the persisted 6,000 integer units per coin; no schema conversion. Each per-second rate is quantized once to the nearest unit. Existing rates/factors are representable at this scale. Settle/collect retain all fractional units.
- Wallet/Earned remain bounded by 9e15 coins. Separately, the ENTIRE pending ledger is bounded by 9e15 subcoins = 1.5T coins. Multiplying a 9e15-coin bound by 6,000 would be unsafe.
- A single Secret sets the per-slot rate ceiling at each tier; ten such slots set the player's rate ceiling. Extra legacy slots proportionally share that same total, with deterministic integer residual allocation. Divide before multiplying to avoid oversized intermediate products.
- Base storage is 37.44B coins/slot and 374.4B/player, multiplied by cash * offlineMinutes / 480 and then limited by the subcoin ceiling. At maximum cash and tank, the total hard limit clips a ten-Secret Galaxy tank before 12 hours. Full storage stops earning.
- Offline time uses server os.time, limited to 480 minutes per absence, +24 minutes per Offline Tank level. Capped elapsed time is consumed. Backward clock adjustments retain the high-water timestamp. New/missing timestamps grant no retroactive time.
- Before multiplying a rate by elapsed seconds, compare against available room. Storage, additions and totals stay within the exact-integer range. Collection corrects division that could otherwise round (9e15 - 1)/6000 up to a whole coin.
- Settle the OLD display, toilet and cash state before mutations via DataService:Get. Save and departure settle too. Removing items or capacity leaves earned pending units available to Collect All. Rebirth deliberately clears the ledger and retains its timestamp high-water mark.

## Durable collection

CollectIncome() collects all slots; CollectIncome(integerSlot) collects that visible unlocked pad. Whole coins only; per-pad fractions remain and Collect All may pool fractions. Server ownership, lease, living-character, finite-distance, argument and shared rate-limit checks remain. Input capacity/refill is 1/2 per second; durable write capacity/refill is 10/0.2 per second. Empty contacts do not consume either budget.

Debit pending, credit Coins/Earned and capture the immutable save snapshot without yielding. Busy saves reject additional collections. Announce success only after acknowledgement and a current profile. Retries and rejoin cannot repeat a committed transfer; ambiguous failures remain fail-closed. Wallet/Earned ceiling pressure leaves unpaid pending intact. Existing outage/crash loss of unsaved progress is not eliminated.

## Evidence and deployment

The normal fresh-account cohort earns 53.62% of its first-ten-minute income passively when limited to five purchased slots. With ten slots purchased at Diamond, passive accounts for 80.38% of the following ten minutes. Full tables, archetypes and assumptions are in [economy-v2.md](economy-v2.md) and [reproducible output](economy-v2-balance.txt).

Tests cover exact units near the ledger ceiling, fractional cash/rebirth/tier rates, partitioned settlement, malformed saved data, offline/storage caps, clock rollback, billion-coin save retries, idempotent collect, rejoin, lease loss and unchanged remote protections. No live backend/device guarantee is implied by headless checks.

Deploy by retiring old binaries before enabling this economy. Old sanitizers have much smaller pending caps and would truncate v2 savings. Existing pending units retain their value; an absence first settled by v2 uses v2 rates and the new offline allowance. No compensation, reset of existing wallets, or cross-version rollback migration is included.
