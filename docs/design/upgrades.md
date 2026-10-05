# Permanent upgrades and faster flushes

Implemented on `feature/upgrades`, 2026-10-05; no commit or push. This task supersedes the older cooldown, price and 50x luck proposals. [API research](../research/upgrade-tracks.md).

## Upgrade contract

`Config/Upgrades.luau` owns every price curve, level limit, step, luck cap, speed floor and physical slot limit. Price at current level L is `ceil(BaseCost * 3^L)`; coins only, independent of toilet ownership and passes.

| Track | Levels | First price | Effect at maximum |
|---|---:|---:|---|
| Cash Boost | 10 | 30 | +100% sale, service and display income |
| Luck Boost | 10 | 40 | +100% luck before the total 5x cap |
| Flush Speed | 10 | 25 | 50% shorter cooldown, final floor 0.4s |
| Auto-Flush Speed | 10 | 60 | Auto interval falls from 2x shared cooldown to 1x |
| Display Slots | 7 | 100 | One extra slot per purchase, maximum ten physical slots |
| Offline Tank | 10 | 80 | +24 minutes/level; 240 to 480 minutes |

**Capacity assumption:** three starting slots plus seven purchases fills the actual ten-slot map. Seven is the deliberate exception to the requested 8–12 levels: no paid level gives an unusable slot. Index rewards remain additive to purchased levels up to ten, independent of purchase/claim order. At capacity, further slot purchases are rejected even if the track is below level seven. Legacy capacities up to 100 retain their paged displays and cannot buy more capacity.

`BuyUpgrade(trackId, expectedLevel)` accepts exactly two arguments. Its independent token bucket permits three requests immediately, then one/second. The server resolves the definition, price, current level, wallet and physical capacity. A stale expected level cannot debit again. `DataService:Get` checks the lease and settles existing passive earnings; validation, debit and level/slot increment then execute without yielding. Save takes an immutable sanitized snapshot of coins and levels, followed by State and Result only if the same live profile still exists. Existing save-failure/crash durability limits still apply; this is not an exactly-once durable ledger across arbitrary outages.

Profiles add a whitelist-only `Upgrades` map, defaulting every missing field to zero. Negative, fractional, nonnumeric, nonfinite and oversized numbers are rejected; valid over-level integers clamp to the configured maximum. Save/rejoin cannot add display levels twice. Coins, Earned, inventory, discoveries and flush counts remain bounded by 9e15. A flush at a full relevant counter is rejected before any currency or item mutation.

State adds `Upgrades` and `UpgradeStats` (cash, capped luck/cap flag, cooldown, auto interval, offline minutes, display limit). The existing Upgrades window gets a `Coin Upgrades` tab through the separate `UI/UpgradeTracks` module, with existing Components and Assets icons, level/effect/price, Buy, Save up and Max states. Luck reports `5x CAP REACHED` from the server snapshot. No asset IDs or new paid entitlements were introduced.

## Income and rounding

Sales use the **current** permanent Cash Boost and round each copy's value down before multiplying by quantity. Splitting/batching a sale gives the same coins. Service awards round down per flush; Basic's 1-Coin service award therefore stays 1 until the 2x maximum. These upgrades never reset in this feature; acquisition-time stamping remains a future rebirth requirement.

Display income uses the existing 6,000 units/Coin ledger. Rates round down to integer units/second (0.01 Coin/minute resolution); small percentage increments can share a rounded rate. Cash multiplies both item rates and tier caps. Get settles the old rate before buying, preventing retroactive credit. Offline Tank changes elapsed-time allowance; it does not mint items or grant time twice. Pending capacities scale by `cash * offlineMinutes / 240`, up to 134,400 Coins/slot and 403,200/player, so upgraded tanks are not silently clipped by the old pending cap. Old pending units and timestamp high-water marks are retained. Daily Coins and index Stamps are not multiplied by Cash Boost.

## Pace and balance evidence

Toilet cooldowns are 1.50 / 1.40 / 1.30 / 1.15 / 1.00 / 0.90 / 0.80 seconds. Guaranteed service awards are 1 / 2 / 4 / 8 / 15 / 33 / 70 Coins. Item values are halved and rounded down from the previous catalog (Poop 2, Paper 7, Rat 25, Fish 62); rarity checks/pools are unchanged.

The seeded 2,000-player cohort uses 75% **manual** cooldown uptime, sequential tier purchases, wallet carryover and actual first-copy protection. Assumption: buy one level of Flush Speed, Cash Boost and Luck Boost per tier through level four, each as soon as affordable, before buying the next toilet. Spending per stage is 95 / 285 / 855 / 2,565 / 0 / 0 Coins. Optional auto, slot and tank purchases are excluded; those utility preferences can delay active progression. No daily/tutorial/index/offline starting balance, temporary luck or pass is assumed. All rarity rolls use independent rare-first checks and an actual fallback.

`luau scripts/balance.luau` reports and enforces ±5% around the previous stage medians. The first four targets come from the prior checked-in script; the last two extend that same old cohort to all six purchases. This replaces the obsolete sales-only timing assertion: the selected target is now actual sale + service + upgrade spending.

| Next toilet | Price | Previous target, min | Stage p50 | Stage p90 | Cumulative p50 | No-track p50 |
|---|---:|---:|---:|---:|---:|---:|
| Dirty | 70 | 1.40 | 1.41 | 1.63 | 1.41 | 0.73 |
| Golden | 850 | 4.48 | 4.47 | 5.12 | 5.81 | 4.39 |
| Diamond | 3,800 | 9.36 | 9.38 | 10.49 | 15.13 | 12.08 |
| Radioactive | 15,500 | 17.87 | 17.94 | 19.46 | 32.87 | 28.47 |
| Demon | 67,300 | 37.11 | 37.08 | 39.04 | 69.79 | 68.98 |
| Galaxy | 172,000 | 47.29 | 47.12 | 48.74 | 116.65 | 85.28 |

Players can skip the tracks; that is faster at Basic and substantially slower later. With no purchases or sales, the first four tiers still have a 92.53-minute cumulative service-only upper bound (previous bound 95). Poop-duplicate-only is at most 65.47 minutes; the prior 51-minute Poop-only bound is superseded, explicitly rather than silently retained. Index rewards still grant once, preserve protected/displayed copies and grant no Coins or luck. Daily day-one/day-seven values remain 25/250 at Basic through 1,600/16,000 at Galaxy; balance prints every tier and the separate daily/index tests verify replay protection.

Passive checks cover realistic 3/10-slot collections and absolute jackpot caps. Across all tiers and Cash/Flush Speed levels 0–10, passive is <=20% of guaranteed active service income at 75% manual uptime, so it shortens that empty-wallet bound by at most one sixth. Offline starting wallets deliberately accelerate return visits and are excluded from the stage targets.

## Luck and scheduling proof

`L = min(5, toiletLuck * (1 + 0.1*LuckLevel) * serverEvent * personalPass * dailyLuck)`; every factor is validated, and positive factors clamp before multiplication to avoid overflow. The personal-pass multiplier is currently 1 because paid luck is disabled. Event and daily boosts can still stack, but their final product cannot bypass the total cap.

At L=5, King Poop's outcome probability across its eligible pools is 0.000049999725..0.00005 (approximately 1 in 20,000). All Event items combined are 0.00005..0.0000554997225, or **0.0050–0.00555% per roll**. Earlier rare checks account for the small difference from the base-check probability. Five million seeded cap rolls returned exactly five million known items: **266 Event drops**, against 277.50 expected; the six-sigma regression count range is 177.6–377.4. King Poop alone appeared 224 times. The separate analytical tests verify probability sum 1, zero empty probability, cap composition and Poop fallback at every tier.

The Flush bucket remains capacity 2 and now refills 3 tokens/second, allowing the 0.4s floor while the shared server cooldown prevents extra awards. Auto ticks use the existing 0.1s scheduler with per-player deadlines; no catch-up loop or second RNG path. At level zero auto waits 2x cooldown (Basic 3s, matching the former Basic auto pace), and at level ten it uses the same cooldown as manual. Manual actions restart the auto deadline. Upgrades affect the next reserved interval, not an already committed cooldown. Scheduler/frame delays can make an interval longer; they never award faster.

Flush reveal, rare burst and world drop duration are `min(0.9, cooldown*0.8)`; the reversing bowl tween divides that duration across twelve segments. Quick reveal lasts at most 0.15s. These effects do not hold the server transaction open or delay the next roll.

## Integration and verification

Main new modules: `Config/Upgrades`, `UpgradeRules`, `Services/UpgradeService`, `UI/UpgradeTracks`. Integrations are additive State/remote wiring, profile sanitation, income/economy/flush effects, a small IndexProgress hook for order-independent slots, and bounded animation timings. New test modules are `check-upgrades`, `audit-upgrades`, `ui-upgrades`, `upgrade-cohort`; the existing runners include them. The map check asserts upgrade capacity matches actual map slots.

Verified: StyLua over src/scripts; every standalone `check-*.luau`; audit and UI runtime files through their PS1 bundlers; **48 audit scenarios**; UI layout/runtime including tab callbacks, affordability/max/cap, desktop/phone cards and reveal expiry; `simulate.luau`; `balance.luau`; `check-visuals.ps1`; all six `check-world.ps1` modes; Rojo build. Offline raster previews were inspected at desktop, phone portrait and landscape using Roblox fonts. These are headless approximations, not engine screenshots.

Selene is installed but cannot run because the repository's configured `roblox` standard library is missing. Live Studio multiplayer, backend outage behavior, target-phone rendering/scrolling, network latency and animation smoothness still need an engine/device pass. No live backend durability claim is made. No commits or pushes.
