# Economy v2: permanent progression and two-layer cash

> Current validation: [full linear luck and regenerated pacing tables](luck-linear.md). Total luck applies in full to every item check, capped at 10x; this supersedes earlier luck formulas and measured balance snapshots below.

## Wave 1 integration update (2026-10-06)

The current catalog has nine rarities, 47 items and 15 toilets. Celestial adds 25,000 base coins/s between Godly 6,000 and Secret 100,000. The cash formula below and 10x luck cap with full luck on every item check are retained. New display factors rebase from Galaxy 13x and remain inside the 40x free cap.

Expanded early pools required toilet prices of 7.5K/16K/90K/420K/3M/16.5M to preserve original pacing. Measured normal fresh-account p50 arrivals are 1.47/3.01/6.12/11.85/20.09/35.47 minutes. All eight new prices and service awards follow the Wave 1 JSON. Capped fresh-account arrivals, conditional arrivals for all three archetypes, the four corrected late-tier targets and the unresolved rebirth-gate conflict are documented in [Wave 1 integration](wave1-integration.md). The unchanged rebirth gates currently reach R15 in 57.725 hours; the older 96.83-hour result below describes the previous seven-toilet catalog and is not a current Wave 1 proof.

Use [the integrated Wave 1 output](wave1-balance.txt) and `scripts/balance.luau` for current evidence. Historical numbers below are retained as the pre-Wave-1 baseline; the new catalog does not multiply nominal late toilet factors outside the cash cap.

2026-10-06, feature/rebirth-balance. This retune replaces the previous single 10x cash cap and historical pacing numbers. See [rebirth contract](rebirth.md), [validation](rebirth-values-validation.md), [full balance output](rebirth-values-balance.txt), [rebirth cohorts](rebirth-values-simulations.txt), [upgrade definitions](upgrades.md) and [source/numeric review](../research/rebirth-cash-layers.md). No commit or push.

## Cash and permanent progression

`totalCash = min(40, (1 + CashBoostEffect + RebirthCash) * displayToiletFactor) * min(3, paidCashFactors)`.

The toilet factor is 1 for service/sales and the tier's display factor for passive income. Double Cash is 2x, VIP is 1.5x; future paid cash pass entries share the paid cap. Milestone titles add no numeric effect. R15 alone supplies 16x service/sales cash. Cash L100 plus R15 supplies 19.25x free, or 57.75x with both passes. Galaxy displays hit the free 40x cap; paid factors lift it to 120x. Toilet factors sit inside the free cap, so capped free displays do not multiply by 13 again.

Ordinary daily coins keep the existing paid-only rule. Starter/stamp/admin grants are not boosted income. Sale/service awards round once per copy/award; collected pending coins and product/VIP-chest quotes never receive a second multiplier. UI explanations appear in Cash Boost, the rebirth review and Passes.

Rebirth retains toilet tier, all upgrade levels, display capacity and exact placements, lifetime collection/index, passes, cosmetics and settings. It resets the wallet to starter coins, all loose inventory including protected/first loose copies, pending income and the run counter. Only displayed inventory survives; lifetime discovery is not reconstructed as spendable inventory. Eligibility still requires wallet coins and 300 fresh successful flushes. R5 free Auto Collect uses the normal guarded ledger path, R10 grants two slots once up to ten, and R15 adds the Legend skin/title/aura without changing toilet economics.

Base rarity rates stay 1/3/10/40/200/1000/6000/100000 coins per second. Toilet prices stay 6.5K/14K/65K/300K/2.4M/16M; display factors stay 1/1.5/2.2/3.3/5.25/8.5/13. Service awards, upgrade prices/effects and all 15 reward rows are unchanged. Only rebirth coin gates were tuned; the 300-flush minimum and starter grants were retained.

## Measured rebirth pacing

64 seeds per archetype, cumulative continuously online hours; p50 / p90. These are policy-dependent estimates, not guarantees. Normal R1 remains 24 minutes, R5 is 2.025 hours, R10 is 32.00 hours and R15 is 96.83 hours. Normal Galaxy remains 36.43 minutes in the independent cohort that defers rebirth.

| Rebirth | Coin gate | Casual p50 / p90 h | Normal p50 / p90 h | Grinder p50 / p90 h |
|---|---:|---:|---:|---:|
| R1 | 3M | 0.70 / 0.93 | 0.40 / 0.52 | 0.33 / 0.43 |
| R2 | 12M | 1.00 / 1.30 | 0.56 / 0.73 | 0.47 / 0.60 |
| R3 | 35M | 1.57 / 2.13 | 0.93 / 1.20 | 0.76 / 1.02 |
| R4 | 100M | 2.03 / 2.83 | 1.26 / 1.62 | 1.06 / 1.33 |
| R5 | 500M | 3.37 / 4.57 | 2.02 / 2.75 | 1.77 / 2.27 |
| R6 | 1B | 5.22 / 6.86 | 3.36 / 4.46 | 2.98 / 3.73 |
| R7 | 2B | 7.80 / 10.50 | 5.21 / 6.38 | 4.61 / 5.53 |
| R8 | 4B | 11.71 / 14.74 | 7.64 / 9.36 | 6.59 / 7.99 |
| R9 | 15B | 30.11 / 37.08 | 23.17 / 26.99 | 19.78 / 25.17 |
| R10 | 40B | 51.11 / 60.15 | 32.00 / 48.61 | 28.10 / 44.33 |
| R11 | 120B | 67.95 / 96.54 | 46.83 / 64.94 | 40.92 / 56.80 |
| R12 | 200B | 76.19 / 118.04 | 52.48 / 73.75 | 46.46 / 65.55 |
| R13 | 320B | 87.47 / 135.04 | 61.59 / 87.21 | 52.48 / 77.28 |
| R14 | 520B | 106.72 / 157.33 | 72.02 / 104.42 | 62.73 / 89.68 |
| R15 | 1.25T | 147.17 / 209.21 | 96.83 / 138.50 | 86.22 / 116.38 |

## Toilet acquisition with rebirth deferred

200 seeds per archetype; cumulative minutes. The rebirth-first cohort can buy Galaxy later because wallet resets spend its savings.

| Toilet | Casual p50 / p90 min | Normal p50 / p90 min | Grinder p50 / p90 min |
|---|---:|---:|---:|
| Dirty | 3.42 / 4.00 | 1.50 / 1.57 | 1.10 / 1.23 |
| Golden | 6.14 / 8.14 | 3.10 / 3.52 | 2.48 / 2.78 |
| Diamond | 12.16 / 14.18 | 6.37 / 7.16 | 5.13 / 5.66 |
| Radioactive | 22.20 / 26.25 | 12.36 / 14.63 | 10.11 / 12.16 |
| Demon | 36.31 / 44.49 | 20.60 / 25.23 | 16.96 / 20.51 |
| Galaxy | 62.21 / 80.64 | 36.43 / 47.26 | 30.74 / 39.23 |

## Upgrade milestones and legacy target interpretation

All six tracks remain permanent. Cash/Tank cap at 100, Luck at 50, Speed/Auto at 10; display purchases stop at ten physical slots, normally seven purchases from the three-slot start. Piecewise exponential cost anchors and all effects remain unchanged. Every ten levels earns a title; maximum is Master. Index/free-rebirth slots can fill the plot earlier without selling useless capacity or minting refunds; legacy 100-slot plots remain valid.

| Track / level | Casual p50 / p90 h | Normal p50 / p90 h | Grinder p50 / p90 h |
|---|---:|---:|---:|
| CashBoost/35 | 3.50 / 4.57 | 1.95 / 2.66 | 1.68 / 2.17 |
| CashBoost/60 | 16.73 / 21.25 | 11.09 / 13.31 | 9.88 / 11.66 |
| CashBoost/85 | 38.36 / 45.61 | 27.07 / 35.68 | 22.59 / 33.62 |
| CashBoost/100 | 64.38 / 87.60 | 43.42 / 61.54 | 38.38 / 53.30 |
| OfflineTank/35 | 3.62 / 4.84 | 1.98 / 2.70 | 1.73 / 2.23 |
| OfflineTank/60 | 17.12 / 21.52 | 11.32 / 13.53 | 10.10 / 11.88 |
| OfflineTank/85 | 38.92 / 46.17 | 27.29 / 36.23 | 22.82 / 34.16 |
| OfflineTank/100 | 65.27 / 89.74 | 44.17 / 62.42 | 38.79 / 54.17 |
| LuckBoost/50 | 28.53 / 34.90 | 21.43 / 25.13 | 19.19 / 23.14 |
| FlushSpeed/10 | 3.92 / 5.38 | 2.42 / 3.12 | 2.08 / 2.70 |
| AutoFlushSpeed/10 | 3.98 / 5.45 | 2.47 / 3.17 | 2.13 / 2.75 |
| DisplaySlots/7 | 3.24 / 4.20 | 1.84 / 2.54 | 1.59 / 2.09 |

The first five Cash levels are affordable within four active minutes using only service income. The normal buying policy instead prioritizes toilets. Full level checkpoints and tails are in the balance output; rare finds and display income broaden both tails.

**Explicit assumption:** the manager's revised cash caps and specified rebirth targets take precedence over three older upgrade timing ceilings. Including the toilet multiplier in the free cap reduces maximum free Galaxy display income from 130x to 40x. With unchanged upgrade prices/effects and buying policy, Cash L85 measures 27.075h, Tank L85 27.292h and Luck L50 21.425h. Their regression upper bounds are therefore 28h, 28h and 22h, replacing 25h, 25h and 20h. Lower bounds and every other upgrade timing bound remain unchanged. The requested rebirth targets were tightened, not relaxed. These incoming branch upgrade bounds are retained as a documented assumption; this merge does not relax any additional target.

## Numeric limits

At the theoretical 120x total, one Secret earns 12M coins/s; ten slots earn 120M coins/s = 720B subcoins/s. Legacy 100-slot capacity shares the ten-slot player cap. Rate apportionment divides before multiplying; settlement checks room before multiplying elapsed time. Storage independently caps at 9e15 integer subcoins = 1.5T coins. Wallet and lifetime Earned independently cap at 9e15 coins. Existing corrected division retains one-subcoin tails at the upper bound.

The largest configured sale is 60B coins per copy at 120x. Million-copy requests would exceed exact arithmetic, so batches are checked against remaining wallet/lifetime room before multiplication. Maximum configured service award is 540K. Collection transfers only available whole coins, preserves fractions and stops at either coin ceiling. Tests include every reward/Cash-level/toilet/pass combination, future paid-factor clamping, 120x online/offline saturation, save/rejoin, fractional partition invariance, both coin ceilings and quote/receipt replay.

## Reproducibility and limitations

Run `luau scripts/balance.luau`; optional `--codegen -O2` uses the same seeded production rules with the installed CLI's native execution. Short cohorts have 200 seeds per archetype and per-flush settlement. Long cohorts have 64 seeds each, a 300-hour horizon and deterministic seed replay. Unfinished checkpoints remain infinity instead of dropping slow players. Normal target assertions cover R1 23-25min, Galaxy 35-38min, R5 2-2.2h, R10 25-40h and R15 90-100h. Reports print all cohorts before a target failure, so diagnostics never hide slower archetypes.

Casual/normal/grinder use 30%/75%/100% manual cooldown uptime, collecting every 120/30/15 seconds. Display earnings continue throughout online time. Free Auto Collect after R5 uses a five-second interval assuming the living owner remains inside the plot; the 30-second simulation step limits collection precision after hour one. Buy Dirty, five slots, then affordable slots and one Cash/Luck/Speed level per tier through L4, and each next toilet. After Galaxy, buy the cheapest available upgrade only at <=25% of wallet, reserving the rest for the coin gate. Best owned displays are reserved and genuine surplus sold; every purchase and rebirth loss is debited.

Long runs use the exact rare-first distribution with two-second batches during hour one and 30-second batches afterward. Income settles before rate/display changes; new finds earn from the next interval. These are continuously online, no-paid/no-daily/no-server-boost/no-offline cohorts; travel, input gaps, latency, auto-only play and inherited inventories change outcomes. Normal passive share remains 60.95% in the first ten minutes and 62.04% in the ten minutes after Diamond. Steady ten-slot displays lead midgame income.

Luck stays capped at 10x and applies in full to every item check. Untimed maximum Galaxy luck is 5.98x. Speed retains its 0.4s floor. UpgradeVersion=2 and saved rebirth-level migrations remain intact; no compensation or wallet wipe is introduced. Retire older binaries before rollout; headless checks do not establish native-device rendering, live billing or DataStore outage durability.
