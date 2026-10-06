# Economy v2: income first

2026-10-06; feature/income-first; no commit or push. Supersedes historical active-only stage medians and passive/active ceilings in passive-income, display-collect, upgrades and rebirth design notes. Existing RNG, protection, remote and persistence contracts stay in force. [API/numeric research](../research/income-first-economy.md).

## Intended loop

Flush to find better units; display the best owned copies; collect meaningful income; buy toilets to multiply every display. Flushes still award guaranteed service coins and sellable surplus copies. No empty drops, new rarity odds, paid power or new item catalog.

Targets are cumulative wall-clock minutes from a fresh account. Galaxy timing defers rebirth; first-rebirth timing uses a separate cohort that resets as soon as eligible. Treating Galaxy 90 and rebirth 60 as milestones on one uninterrupted run would be contradictory.

## Per-item income

Coins per second before Cash Boost and rebirth. All values live in Config/Income.

| Rarity | Basic x1 | Dirty x1.5 | Golden x2.2 | Diamond x3.3 | Radioactive x5 | Demon x8 | Galaxy x12 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Common | 1 | 1.5 | 2.2 | 3.3 | 5 | 8 | 12 |
| Uncommon | 3 | 4.5 | 6.6 | 9.9 | 15 | 24 | 36 |
| Rare | 10 | 15 | 22 | 33 | 50 | 80 | 120 |
| Epic | 40 | 60 | 88 | 132 | 200 | 320 | 480 |
| Legendary | 200 | 300 | 440 | 660 | 1K | 1.6K | 2.4K |
| Mythic | 1K | 1.5K | 2.2K | 3.3K | 5K | 8K | 12K |
| Godly | 6K | 9K | 13.2K | 19.8K | 30K | 48K | 72K |
| Secret | 100K | 150K | 220K | 330K | 500K | 800K | 1.2M |

Multiply by 1 + 0.1 * CashBoostLevel + rebirthCashBonus, capped by the existing maximum 3.6x. Example: a Diamond Common at Cash L1 and rebirth 1 earns exactly $4.455/s (26,730 subcoins/s); its two-decimal nametag conservatively shows $4.45/s. Storage/collection retain the fraction.

King Poop remains Mythic, so its display earns less than Godly Sewer Shark. It retains its event prestige and higher sale value. Sell-value ordering is not an income ordering.

## Prices and direct income

| Toilet | Purchase price | Guaranteed coins/flush |
|---|---:|---:|
| Basic | Owned | 40 |
| Dirty | 6.5K | 60 |
| Golden | 14K | 80 |
| Diamond | 105K | 100 |
| Radioactive | 1.1M | 1.2K |
| Demon | 14M | 2.4K |
| Galaxy | 95M | 4.5K |

Sale values: Poop 80; Toilet Paper 280; Rat 1K; Fish 2.48K; Duck 8K; Golden Poop 30K; Toilet Baby 150K; Sewer Shark 800K; King Poop 5M; Alien Toilet 40M; Mystery 500M. These are 40x the preceding values, with odds unchanged. Larger late-tier service awards keep active coins meaningful alongside valuable displays. Service/sales round per award/copy; sale batches cannot improve rounding.

Upgrade price at current level L is ceil(BaseCost * Growth^L). Effects and level caps remain as before.

| Track | First cost | Growth | Levels | Last cost |
|---|---:|---:|---:|---:|
| Cash Boost | 400 | 5 | 10 | 781.25M |
| Luck Boost | 600 | 5 | 10 | 1.171875B |
| Flush Speed | 400 | 5 | 10 | 781.25M |
| Auto-Flush Speed | 800 | 5 | 10 | 1.5625B |
| Display Slots | 600 | 2 | 7 | 38.4K |
| Offline Tank | 1K | 5 | 10 | 1.953125B |

Rebirth requires Diamond and 3,300 NEW successful flushes (previously 3,600), with no monetary fee. Starter grants remain 2,500 + 250 per subsequent rebirth; count thresholds are tuned for timing rather than inflated to currency scale. Permanent bonuses, fifteen-level cap, retained protected copies, run-track reset and pending-income reset remain unchanged. This preserves the existing no-fee design instead of adding an unrequested coin gate. Even with unlimited coins, the 0.4s floor requires 22 minutes of fresh flushes.

## Reproducible cohort

Run luau scripts/balance.luau. [Checked output](economy-v2-balance.txt). Two hundred independently seeded accounts per archetype, production distribution/service/sale/upgrade/accrual/reset math. Cash is never granted by the simulator outside the normal service/sale/collect/reset paths. Stable item order and explicit seed replay are checked.

Start with zero coins/items and three slots. Display best owned copies, preserving first/displayed/protected reservations; sell only surplus. Buy Dirty first, then five slots. Purchase ten slots at Diamond. Buy one Cash/Luck/Flush Speed level per attained tier starting at Dirty, stopping at L4, before the next toilet. All purchases debit real costs. No free ten-slot showcase, starting offline bank, daily/index/tutorial rewards, paid passes or temporary event boosts. Rare event items may drop; their temporary server luck effects are excluded so external server activity cannot change this experiment.

Casual flush uptime is 30%, normal 75%, grinder 100%. Passive runs through the entire online session; collect every 120/30/15 seconds. This averages interruptions into flush intervals, and assumes the player can visit the jar on that cadence. It does not model physical walking, latency, long disconnected periods, or players who forget displays/collection. The steady-state table is a separate upper-showcase comparison using floored expected copies after 60 minutes at a fixed tier; it is NOT the progression cohort.

### Cumulative time to tier (p50 / p90 minutes)

| Milestone | Normal target | Casual | Normal | Grinder |
|---|---:|---:|---:|---:|
| Dirty | 1-1.5 | 3.42 / 4.00 | 1.50 / 1.57 | 1.10 / 1.23 |
| Golden | 3 | 6.14 / 8.14 | 3.10 / 3.52 | 2.48 / 2.78 |
| Diamond | 8 | 14.32 / 16.27 | 7.84 / 9.17 | 6.39 / 7.27 |
| Radioactive | 20 | 34.38 / 44.32 | 20.17 / 25.45 | 16.89 / 21.24 |
| Demon | 45 | 74.97 / 98.98 | 45.46 / 57.84 | 38.45 / 49.33 |
| Galaxy (rebirth deferred) | 90 | 146.22 / 198.95 | 89.37 / 111.43 | 76.21 / 96.76 |
| First rebirth | ~60 | 146.91 / 151.18 | 61.94 / 63.88 | 47.23 / 48.86 |
| Second rebirth (duration of second run) | Faster | 119.31 / 125.07 | 50.76 / 53.21 | 39.18 / 40.35 |

Normal second rebirth is 18.1% faster. Normal tier median assertions allow 1-1.5 minutes for Dirty and +/-20% for later approximate targets; first rebirth allows 54-66 minutes. All archetypes must improve second rebirth by >8%, without becoming instant. These ranges replace obsolete active-only stage assertions explicitly; the old 40%-of-active passive ceiling directly conflicts with income first.

### Passive share of total earnings

Share means passive / (passive + service + actual protected-safe sales), including pending accrued income, not passive divided by active. Acquisition and purchases are modeled; spending does not reduce earned-income totals.

| Scenario | Casual | Normal | Grinder |
|---|---:|---:|---:|
| First ten minutes, natural slot policy | 59.74% | 57.85% | 59.65% |
| Ten minutes following Diamond purchase | 86.28% | 80.38% | 77.02% |

Separate normal cohort restricted to FIVE purchased slots: **53.62%** passive in the first ten minutes (asserted 40-60%). Normal Diamond window is asserted 70-90%. Ten-slot steady-state showcases are 89.97% at Diamond, 87.01% Radioactive, 85.56% Demon and 82.95% Galaxy, including identical cash/luck/speed state for active comparison. Late rewards therefore remain meaningful without overtaking typical display income. Jackpot-heavy plots may exceed 90%; that is intentional, not an absolute passive ceiling.

## Caps, persistence and UI

[Passive accounting contract](passive-income.md). Base offline allowance is eight hours; Offline Tank adds 24 minutes/level up to twelve hours. UI reports the current hour cap and that storage limits apply. Pending base storage is 34.56B/slot and 345.6B/player, scaled by cash and tank, with a hard total of 9e15 subcoins (1.5T coins). Rate caps accommodate one Secret per slot and ten per player at every tier; legacy 100-slot plots share the player cap. Wallet and Earned remain 9e15 coins.

Fixed 6,000-subcoin units, integer sums, high-water timestamps, division correction, bounded multiplication and retained collection fractions prevent tiny earnings from disappearing in large balances. Collect ownership/distance/life/lease validation, durable-save budgets, immutable retry snapshots and replay-safe updates are retained. RNG remains server-owned with exactly one item, 5x luck ceiling and unchanged rare event probabilities.

One shared formatter supports K/M/B/T/Qa/Qi throughout economy UI. The wallet cannot reach Qi under its safe ceiling. Toilet cards now disclose their display-income multiplier. Existing assets and map geometry are unchanged.

## Risks, limits and rollout

- Inflation is intentional: old inventories have far larger resale/display value. Eight-hour offline payouts can skip coin gates; existing players will not follow fresh-account timings. New rates apply to the whole capped absence when v2 first settles it. No compensation or wallet wipe is applied.
- Rare drops drive a broad tail: normal Galaxy p90 is 111.43 minutes; casual p90 is 198.95. Normal means manual 75% uptime, not slow unupgraded auto-only play. Display choice, optional upgrades and missed collection materially change these estimates.
- Rebirth remains flush-count limited for many players, particularly casuals. Strong retained displays and offline balances speed purchases but cannot bypass fresh flushes. At fully upgraded cash/tank, ten Galaxy Secrets hit the 1.5T global tank cap before twelve hours. Future currencies/prices beyond 9Qa require a different numeric representation.
- Retire older servers before rollout: their smaller ledger caps would truncate v2 balances. Persisted units/schema are unchanged, but rolling back to old economy code is not financially safe. Existing session locks do not solve mixed-version sanitizer incompatibility.
- Headless tests do not establish real Roblox DataStore availability, outage durability, device text rendering or actual walking cadence. Published multiplayer/device QA remains necessary before release. Selene 0.31.0 cannot run with the missing roblox standard library; no lint-pass claim is made.

## Verification and files

Config: Income, Items, Toilets, Upgrades, Rebirth. Accounting: IncomeAccrual, SafeInventory, IncomeService, RewardService. Formatting: NumberFormat, Components/PresentationRules and world income/board/stairs labels; toilet and Offline Tank cards. Evidence: economy-cohort, balance/income-balance, check-economy-v2, audit-economy-v2, ui-economy-v2, existing upgraded fixtures, this document and research notes.

All standalone check-*.luau run directly; audit/UI runtime files run through their PS1 bundlers. Extended check-audit.ps1 has 98 passing scenarios including billion-coin ambiguous saves/rejoins and exact last-subcoin handling. check-ui.ps1 covers actual wallet/pending/popup/shop/upgrade/rebirth/player-list text plus 972 safe-area layouts. check-world.ps1 covers all six template modes; check-visuals.ps1 verifies real builders. Passed: all 19 standalone check scripts, the 98-scenario audit, UI suite, check-visuals.ps1, all six check-world.ps1 modes, scripts/simulate.luau (including five million 5x-luck rolls), deterministic balance targets, stylua --check --line-endings Windows src scripts, rojo build -o build.rbxl, and git diff --check. Reviewed headless phone previews: [rebirth with large balances](economy-v2-previews/income-first-rebirth-phone.png), [upgrade prices](economy-v2-previews/income-first-upgrades-phone.png). These approximate the UI tree and do not replace live-device QA.
