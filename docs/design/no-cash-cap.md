# Uncapped cash: implementation and balance review

2026-10-07, feature/no-cash-cap. No commit or push. Baseline: ea0d3feb039de37a4a1b8eff9eb7e835803da03f.

Cash Boost, rebirth, toilet display and every owned paid cash factor multiply without a gameplay multiplier cap. Removed FreeCap, PaidCap, TotalCap, CashMultiplierCap and Rebirth.CashCap. Assumption: the explicit multiplicative-stacking instruction also replaces the old addition of Cash Boost and rebirth bonuses; milestone titles remain cosmetic. Upgrade/rebirth level counts stay unchanged.

Technical safety remains: finite factors, 9e15 Coins each for wallet/Earned, 9e15 integer subcoins for pending income, 6000 subcoins/Coin, fractional carry and exact final-tail collection. Products are checked before multiplication, large rates apportioned from base weights, oversized sales rejected atomically, and NaN/inf rejected. Cash itself only saturates at the finite-double representation limit. No new design cap is introduced. Luck 10x, path speed 5x and cooldown floor 0.4s are unchanged.

## Normal acceptance and payer comparison

Times are seeded cohort medians, not guarantees. Early toilets use 200 fresh-account seeds with rebirth deferred; rebirths use 64 seeds with rebirth-first spending. All-pass means Ultimate Bundle/all entitlements from account creation, including Fast Flush and Auto Collect, with no consumable coin purchases.

| Milestone | Requested normal target | Before | Uncapped, original prices | Final normal | All-pass normal | Speedup |
|---|---:|---:|---:|---:|---:|---:|
| Dirty | ~1.5 min | 1.47 min | 1.47 min | 1.47 min | 0.53 min | 2.76x |
| Golden | ~3 min | 3.01 min | 3.01 min | 3.01 min | 1.10 min | 2.74x |
| Diamond | ~6 min | 6.12 min | 6.12 min | 6.12 min | 2.14 min | 2.86x |
| Radioactive | ~12 min | 11.85 min | 11.85 min | 11.85 min | 4.50 min | 2.64x |
| Demon | ~20 min | 20.09 min | 20.09 min | 20.09 min | 7.86 min | 2.56x |
| Galaxy | 35-38 min | 35.47 min | 35.47 min | 35.47 min | 14.55 min | 2.44x |
| R1 | 23-25 min | 24.60 min | 24.60 min | 24.60 min | 9.80 min | 2.51x |
| R5 | 2-2.2 h | 2.17 h | 1.32 h | 2.05 h | 0.95 h | 2.16x |
| R10 | 25-40 h | 25.26 h | 3.43 h | 28.45 h | 15.01 h | 1.90x |
| R15 | 90-100 h | 90.83 h | 5.08 h | 98.53 h | 48.98 h | 2.01x |

Normal R15 p90 is 111.79h; all-pass p90 is 59.60h. Payer R15 takes 50.29% less median time. The all-pass cash factor remains 3x because the catalog currently contains 2x and 1.5x factors; a future factor stacks further. Bundle overlap never double-counts ownership.

## Before/after by archetype

Each cell is before -> final p50, cumulative online time. Complete p50/p90 outputs: [baseline](no-cash-cap-before.txt), [without retuning](no-cash-cap-unretuned.txt), [final balance](no-cash-cap-balance.txt), [rebirth-only simulation](no-cash-cap-rebirth.txt), [all passes](no-cash-cap-payer-final.txt), [Wave 1 conditional proof](no-cash-cap-wave1-final.txt). The unretuned run intentionally fails the old balance expectations; it is diagnostic evidence, not a passing build.

| Toilet | Casual minutes | Normal minutes | Grinder minutes |
|---|---:|---:|---:|
| Dirty | 3.42 -> 3.42 | 1.47 -> 1.47 | 1.07 -> 1.07 |
| Golden | 6.13 -> 6.13 | 3.01 -> 3.01 | 2.30 -> 2.30 |
| Diamond | 12.16 -> 12.16 | 6.12 -> 6.12 | 4.78 -> 4.78 |
| Radioactive | 22.23 -> 22.23 | 11.85 -> 11.85 | 9.73 -> 9.73 |
| Demon | 37.35 -> 37.35 | 20.09 -> 20.09 | 16.41 -> 16.41 |
| Galaxy | 60.27 -> 60.27 | 35.47 -> 35.47 | 29.51 -> 29.51 |
| CoralCommode | 144.50 -> 138.00 | 86.50 -> 84.00 | 74.50 -> 72.00 |
| CloudCushion | 195.50 -> 178.00 | 125.00 -> 109.50 | 108.00 -> 95.50 |
| ClockworkCloset | 332.00 -> 220.00 | 217.00 -> 146.50 | 187.50 -> 128.00 |
| DragonKiln | 526.00 -> 324.00 | 345.50 -> 214.00 | 297.50 -> 184.50 |
| AuroraThrone | 794.00 -> 488.00 | 513.50 -> 315.50 | 457.00 -> 270.00 |
| AstralAltar | 1500.00 -> 702.00 | 1088.50 -> 455.00 | 947.50 -> 402.50 |
| ParadoxPotty | 2126.00 -> 1036.00 | 1473.50 -> 711.00 | 1252.00 -> 626.50 |
| InfinityFlush | 2792.00 -> 1486.00 | 1886.00 -> 1027.50 | 1598.50 -> 909.00 |

| Rebirth | Coin gate before -> final | Casual hours | Normal hours | Grinder hours |
|---|---:|---:|---:|---:|
| R1 | 4M -> 4M | 0.73 -> 0.73 | 0.41 -> 0.41 | 0.34 -> 0.34 |
| R2 | 12M -> 15M | 0.97 -> 1.00 | 0.54 -> 0.56 | 0.46 -> 0.47 |
| R3 | 35M -> 70M | 1.50 -> 1.53 | 0.87 -> 0.89 | 0.72 -> 0.75 |
| R4 | 100M -> 400M | 2.00 -> 2.10 | 1.18 -> 1.27 | 0.99 -> 1.08 |
| R5 | 450M -> 3.8B | 3.33 -> 3.17 | 2.17 -> 2.05 | 1.88 -> 1.78 |
| R6 | 1B -> 18B | 5.29 -> 4.72 | 3.52 -> 3.22 | 2.99 -> 2.78 |
| R7 | 2B -> 100B | 7.97 -> 6.76 | 5.22 -> 4.36 | 4.41 -> 3.92 |
| R8 | 4B -> 700B | 10.92 -> 9.86 | 7.18 -> 7.02 | 6.04 -> 6.10 |
| R9 | 15B -> 4.5T | 23.73 -> 21.04 | 16.20 -> 13.69 | 14.30 -> 11.93 |
| R10 | 60B -> 60T | 38.76 -> 41.89 | 25.26 -> 28.45 | 22.48 -> 25.12 |
| R11 | 120B -> 100T | 47.14 -> 48.46 | 30.55 -> 32.72 | 27.47 -> 29.41 |
| R12 | 200B -> 200T | 50.77 -> 57.52 | 33.32 -> 39.82 | 29.84 -> 34.91 |
| R13 | 320B -> 400T | 56.75 -> 73.27 | 37.36 -> 49.52 | 32.89 -> 44.18 |
| R14 | 520B -> 700T | 64.78 -> 91.33 | 42.47 -> 63.64 | 38.06 -> 56.77 |
| R15 | 6.5T -> 2.4Qa | 133.86 -> 138.63 | 90.83 -> 98.53 | 79.95 -> 90.37 |

| Upgrade checkpoint | Casual hours | Normal hours | Grinder hours | All-pass normal hours |
|---|---:|---:|---:|---:|
| CashBoost/35 | 3.62 -> 2.93 | 2.37 -> 1.84 | 2.04 -> 1.58 | - |
| CashBoost/60 | 14.82 -> 11.28 | 10.07 -> 7.92 | 8.89 -> 6.98 | - |
| CashBoost/85 | 28.13 -> 23.32 | 19.50 -> 15.18 | 17.15 -> 13.41 | - |
| CashBoost/100 | 43.12 -> 38.80 | 28.02 -> 26.01 | 25.18 -> 23.07 | 14.02 |
| OfflineTank/35 | 3.68 -> 2.97 | 2.41 -> 1.87 | 2.08 -> 1.60 | - |
| OfflineTank/60 | 15.01 -> 11.49 | 10.16 -> 8.03 | 9.03 -> 7.10 | - |
| OfflineTank/85 | 28.36 -> 23.59 | 19.61 -> 15.32 | 17.27 -> 13.54 | - |
| OfflineTank/100 | 43.56 -> 39.64 | 28.28 -> 26.64 | 25.47 -> 23.58 | 14.28 |
| LuckBoost/50 | 22.68 -> 18.48 | 15.51 -> 12.14 | 13.89 -> 10.68 | 6.25 |
| FlushSpeed/10 | 4.02 -> 3.58 | 2.63 -> 2.29 | 2.25 -> 2.01 | 1.06 |
| AutoFlushSpeed/10 | 4.10 -> 3.60 | 2.69 -> 2.30 | 2.29 -> 2.02 | 1.07 |
| DisplaySlots/7 | 3.07 -> 3.10 | 1.95 -> 1.98 | 1.65 -> 1.75 | 0.93 |

The requested early/rebirth targets and existing upgrade timing bands are retained. The fresh-account, rebirth-deferred late-toilet snapshots in balance.luau are rebased to the measured uncapped results above: these optional longer-play regression baselines were not owner pacing targets. The independent conditional Wave 1 targets retain their original tolerances and values. Two steady showcase shares rise above the old 90% ceiling (Clockwork 90.35%, Dragon 90.03%); the diagnostic band is now 70-91%, explicitly reflecting uncapped display cash rather than changing service/item income.

## Config-only price and gate retuning

No RNG, income base rate, service award, reward effect, upgrade effect, luck, speed or level maximum is retuned. Toilet/upgrade prices and rebirth requirements are the only economy tuning inputs changed. Historical task briefs and dated raw reports remain evidence. Current economy/rebirth/upgrade/monetization text points here.

| Toilet | Old price | Final price |
|---|---:|---:|
| CoralCommode | 160M | 160M |
| CloudCushion | 400M | 400M |
| ClockworkCloset | 1B | 1.025B |
| DragonKiln | 2.5B | 3.8B |
| AuroraThrone | 6.25B | 14.2188B |
| AstralAltar | 15.625B | 53.4375B |
| ParadoxPotty | 39.0625B | 200B |
| InfinityFlush | 97.6563B | 741.2109B |

Cash/Tank cost anchors at L35/L60/L85/L100 become 600M/240B/1.5T/10T (was 120M/2B/5B/20B). Luck L30/L43/L50 becomes 4B/240B/800B (was 200M/2B/3.5B). Speed/Auto L10 becomes 1B (was 140M); Display Slots L7/L10 becomes 800M/2.4B (was 100M/300M). Early Cash prices and the first seven toilet prices are unchanged. Interpolation, purchase validation, migration and permanent ownership remain intact.

## Payer and extreme-stack risks

- Casual: R15 138.63h free versus 69.93h with all passes (1.98x faster).
- Normal: R15 98.53h free versus 48.98h with all passes (2.01x faster).
- Grinder: R15 90.37h free versus 44.59h with all passes (2.03x faster).

Early prices become very small for a heavy payer: normal Dirty takes 32 seconds, Golden about 66 seconds, and Galaxy 14.55 minutes. Max Cash Boost still takes 14.02h; R10 takes 15.01h and R15 48.98h. Later progression is not instant under this fresh-account policy, but early cost tiers are trivial once large stacks/rare displays are established. Existing 1B coin-pack/chest amounts also become negligible at the theoretical maximum (about 0.015 seconds of paid income); their separate product bounds were not changed. No replacement cash cap was added.

All passes + R15 + max upgrades gives 204x service/sales and 66,300x Infinity Flush displays. Ten Secrets yield 66.3B/s, filling the technical 1.5T pending storage in 22.62 seconds (free: 22.1B/s, 67.87 seconds). Extreme future passes are tested beyond the old limits and beyond finite-product range. Technical wallet/Earned saturation can eventually stop new credit; that existing safety is intentional. Ordinary oversized sale batches reject before consuming inventory.

## Verification and handoff

Changed areas: Config/Cash, Income, Monetization, Rebirth, Toilets, Upgrades; CashMath, PaidBenefits, UpgradeRules, IncomeAccrual, SafeInventory and service/reward credit; Upgrades/Rebirth/Passes/Rewards UI and NumberFormat; balance cohorts, independent numeric/UI/world assertions, new audit-no-cash-cap, check-audit.ps1 and visual harness dependencies; current docs/catalog and numeric research. IncomeService/EconomyService already delegate to these shared production rules, so their remote/rate-limit contracts are unchanged.

The audit covers every configured cash/rebirth/tier/pass combination, future paid factors, all-pass R15/max-upgrade stacks at every tier, 100 legacy slots, fractional partitioning, NaN/inf rejection, safe saturation, final integer/subcoin tails, save/rejoin and oversized sales. Number labels extend K/M/B/T/Qa/Qi/Sx/Sp/Oc/No/Dc then scientific notation.

Checks: 330 audit scenarios; 23 standalone check-*.luau files, with check-audit.luau and check-ui-runtime.luau exercised through their PowerShell bundles; UI and 972 layouts; visual checks and all six world modes; StyLua with Windows line endings; rojo build -o build.rbxl. Final balance, Wave 1 and rebirth simulation outputs are linked above. Selene 0.31.0 was invoked but cannot run because its local roblox standard library is missing. Rojo 7.7.0, StyLua 2.5.2. Native Studio/device/billing tests were not performed.

Simulation assumptions: 30/75/100% flush uptime, continuous online display earnings, no offline/daily/event grants, first-hour 2s and later 30s batches, 300h censoring. Auto Collect assumes the living player stays in their plot; later 30s batching limits collection timing resolution. Prices include all purchases and rebirth wallet loss. These are policy-dependent pacing estimates, not elapsed real-life retention predictions.

**Owner action:** edit the Roblox Creator Hub Double Cash description to exactly **2x coin income.** The repository config/catalog are updated; the external Hub listing was not edited.
