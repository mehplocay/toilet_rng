# Full linear luck validation

> Historical cash/balance snapshot. The 2026-10-07 owner decision removes all cash multiplier caps; see [current uncapped contract](../design/no-cash-cap.md). Earlier measurements below are retained as dated evidence, not runtime limits.

2026-10-06, `feature/luck-linear`. No commit or push. This report supersedes earlier luck formulas and balance measurements; historical task briefs are unchanged.

Every non-fallback check now uses `min(1, min(totalLuck, 10) / item.Chance)`, regardless of rarity. The three obsolete luck settings are removed from `Config/Upgrades`. Independent checks still run rarest first, with stable ID tie-breaking and unconditional Poop fallback. Each successful flush awards exactly one item. The final probability of an item is its check times the probability of reaching that check. Common outcomes can therefore become impossible when an earlier check reaches 100%.

`LuckyService:Odds` already shares `RollService.Distribution` with gameplay, so the disclosure now receives the new exact item and rarity probabilities. Lucky Flush descriptions, the odds explanation and the upgrade cap explanation describe full luck. Policy restrictions, purchase review and charge consumption are unchanged. [Official-source research](../research/luck-linear.md).

## Balance and configuration decision

No gate, price, reward or curve retune was needed: **all existing balance assertions pass without relaxed targets**. The starting branch already contains R1=4M, R5=450M, R10=60B and R15=6.5T gates; this task leaves them unchanged. Early progression uses less than 5x luck and its timing is unchanged. Later rare drops accelerate progression while remaining in the requested ranges.

The existing cohort assumptions are retained: paid/offline/daily/event benefits off; casual/normal/grinder flush uptime 30/75/100%; online displays accrue continuously. First-seven-toilet results use 200 seeds and defer rebirth. Rebirth and later-toilet cohorts use 64 seeds, 2-second batches in hour one and 30-second batches later, with a 300-hour horizon. These are cumulative simulated online times under the documented purchase policy, not guarantees or wall-clock retention predictions.

| Normal milestone | Requested target | Measured p50 | Measured p90 |
|---|---:|---:|---:|
| Dirty | 1.5 min | 1.47 min | 1.57 min |
| Golden | 3 min | 3.01 min | 3.27 min |
| Diamond | 6 min | 6.12 min | 6.63 min |
| Radioactive | 12 min | 11.85 min | 13.90 min |
| Demon | 20 min | 20.09 min | 23.73 min |
| Galaxy | about 36 min | 35.47 min | 44.24 min |
| R1 | about 24 min | about 24.5 min | about 30.5 min |
| R5 | about 2 h | 2.17 h | 2.62 h |
| R10 | 25-40 h | 25.26 h | 31.65 h |
| R15 | 90-100 h | 90.83 h | 103.59 h |

Fresh-account later-toilet results, rebirth deferred, cumulative p50 / p90 minutes:

| Toilet | Casual | Normal | Grinder |
|---|---:|---:|---:|
| Coral Commode | 144.50 / 188.00 | 86.50 / 108.50 | 74.50 / 92.50 |
| Cloud Cushion | 195.50 / 238.00 | 125.00 / 151.50 | 108.00 / 134.00 |
| Clockwork Closet | 332.00 / 390.00 | 217.00 / 258.50 | 187.50 / 228.50 |
| Dragon Kiln | 526.00 / 624.00 | 345.50 / 425.50 | 297.50 / 363.00 |
| Aurora Throne | 794.00 / 948.00 | 513.50 / 611.00 | 457.00 / 529.50 |
| Astral Altar | 1500.00 / 1834.00 | 1088.50 / 1265.50 | 947.50 / 1103.00 |
| Paradox Potty | 2126.00 / 2562.00 | 1473.50 / 1734.00 | 1252.00 / 1542.50 |
| Infinity Flush | 2792.00 / 3294.00 | 1886.00 / 2222.00 | 1598.50 / 2027.50 |

Full results: [balance and all three archetypes](luck-linear-balance.txt), [rebirth runner](luck-linear-rebirth-balance.txt), [Wave 1 conditional cohorts and first-sighting tables](wave1-balance.txt). The Wave 1 conditional cohort starts at Galaxy at minute 35 and buys no subsequent upgrades; its times are not directly comparable to fresh-account results above. `income-balance.Print()` runs as part of `balance.luau`.

## Rare outcomes at 10x

Full tier-15 pool, fixed 10x total luck. Expected flushes are `1 / final outcome probability`; they are means, not guarantees. All entries receive the full 10x check multiplier and remain well below probability 1.

| Item | Rarity | Independent check | Final outcome | Expected flushes |
|---|---|---:|---:|---:|
| Cosmic Courtesy | Secret | 0.0000666667% | 0.0000666667% | 1,500,000.000 |
| ??? (Mystery) | Secret | 0.0001000000% | 0.0000999999% | 1,000,000.667 |
| Infinite Occupied | Secret | 0.0002000000% | 0.0001999997% | 500,000.833 |
| Emergency Universe | Secret | 0.0004000000% | 0.0003999985% | 250,000.917 |
| The Last Toilet | Secret | 0.0006666667% | 0.0006666616% | 150,001.150 |
| Alien Toilet | Secret | 0.0010000000% | 0.0009999857% | 100,001.433 |
| Starlight Seraph | Celestial | 0.0011111111% | 0.0011110841% | 90,002.190 |
| Constellation Clam | Celestial | 0.0015384615% | 0.0015384070% | 65,002.304 |
| Comet Commode | Celestial | 0.0022222222% | 0.0022221093% | 45,002.287 |
| Halo Hamster | Celestial | 0.0033333333% | 0.0033330898% | 30,002.192 |
| Any Secret | Secret | — | 0.0024333120% | 41,096.250 |
| Any Celestial | Celestial | — | 0.0082046902% | 12,188.151 |

The rarest Secret is still a long-term chase: at a sustained 0.4-second interval and 10x luck, its mean is 166.67 active hours; any Secret averages 4.57 active hours. The rarest Celestial averages 10.00 active hours and any Celestial 1.35. This is not an assumption that every free player sustains 10x luck. Base odds and item values remain unchanged. [Analytical output plus three million seeded rolls](permanent-odds.txt).

## Checks and limits

- `check-audit.ps1`: 253 passed, 0 failed. Added fixed numeric cases at 1x/5x/10x, both sides of the former odds boundary, probability saturation, rare-first callback stop, Poop fallback, invalid luck, exact outcome/rarity sums and cap equivalence across all 15 production pools. Existing Lucky disclosure tests compare all rows and rarity sums against production distributions.
- Paid cash logic is unchanged. Existing exhaustive cash-layer scenarios still cover all rebirth levels, cash levels, toilet tiers and paid combinations, fractional accrual, quote/replay behavior and no second multiplication. Caps remain 40x free, 3x paid, 120x combined.
- All 22 standalone `scripts/check-*.luau` entrypoints pass; `check-audit.luau` and `check-ui-runtime.luau` require their PowerShell harnesses. Foundation/upgrade/event simulation numeric expectations were updated to full luck.
- `balance.luau`, `wave1-balance.luau`, `rebirth-balance.Print()`, `rebirth-values-simulations.luau` and the three-million-roll `simulate.luau` pass. `rojo build -o build.rbxl`, `check-visuals.ps1`, `check-world.ps1` and `stylua --check --line-endings Windows src scripts` pass. The line-ending option matches this Windows checkout.
- The unmodified `check-ui.ps1` stops at `scripts/ui-rebirth.luau:46`, which expects `3M / 3M Coins required` although the existing R1 gate is 4M. Both values are present in HEAD; this is pre-existing and left to the other session as requested. A supplemental temporary copy of the UI harness omitting only `ui-rebirth.luau` passes the remaining suites and 972 layout cases. It includes the new `ui-catalog2.luau` check that all 47 real tier-15 item rows display production outcome percentages at 5x / 10x, including Celestial and Secret. This supplemental pass does not turn the full UI suite green.
- Selene was attempted but cannot load its missing local `roblox` standard library. No live Studio/device test was performed; visual/world results are headless checks.
