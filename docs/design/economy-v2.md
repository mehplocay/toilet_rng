# Economy v2: permanent progression

2026-10-06, `feature/permanent`. This owner decision supersedes the old reset-to-Basic, ten-level tracks, 5x luck and 60/90-minute pacing in earlier audits and merge notes. No commit or push. [Research](../research/permanent-economy.md), [rebirth contract](rebirth.md), [upgrades](upgrades.md), [full measured output](economy-v2-balance.txt), [odds output](permanent-odds.txt).

## Stronger rewards review (2026-10-06)

The catalog/rebirth integration retains the nominal stronger reward table under the existing 10x total cash cap, as required by the merge task. R3/R4/R5/R15 coin gates are now 100M/400M/900M/7.5T to restore pacing without loosening balance assertions. See [the latest merge report](catalog2-rebirth-merge.md). Earlier tables and timing measurements below are historical; they predate this gate retuning. The [reward-only validation](rebirth-values-validation.md) records the failures that motivated it.


## Historical reward-only seeded medians (hours)

| Archetype | R1 | R5 | R10 | R15 |
|---|---:|---:|---:|---:|
| Casual | 0.700 | 2.967 | 34.967 | 95.592 |
| Normal | 0.400 | 1.725 | 24.042 | 65.250 |
| Grinder | 0.332 | 1.450 | 20.950 | 56.050 |

Each archetype has 64 seeds, with a 300-hour censoring horizon. These are cumulative continuously online hours. Normal R15 p90 is 91.608h; casual 144.025h; grinder 82.292h. No paid passes or temporary luck are included. Normal Galaxy is independently measured at 36.43min p50 / 47.26min p90 while deferring rebirth, unchanged by reward-only tuning.

## Permanent progression and rates

Rebirth preserves toilet tier, every upgrade level, all display capacity/placements, lifetime index, passes, cosmetics and settings. It clears the wallet to a configured starter grant, **all non-displayed inventory** (including first/protected loose copies), uncollected pending coins and the run flush counter. Settle the old pending ledger before the complete replacement; settlement does not collect it or count toward the coin gate. Only displayed quantities survive, with their existing protection. Lifetime discovery is never spendable inventory.

Base rarity income remains Common 1, Uncommon 3, Rare 10, Epic 40, Legendary 200, Mythic 1K, Godly 6K, Secret 100K coins/second. Multiply by toilet factor and bounded cash. King Poop remains Mythic. Sales and service use per-copy/per-award integer rounding; collection never multiplies already-earned coins again.

| Toilet | Price | Display factor | Service coins/flush | Normal p50 / p90 minutes |
|---|---:|---:|---:|---:|
| Basic | Owned | 1 | 40 | 0 |
| Dirty | 6.5K | 1.5 | 60 | 1.50 / 1.57 |
| Golden | 14K | 2.2 | 80 | 3.10 / 3.52 |
| Diamond | 65K | 3.3 | 100 | 6.37 / 7.16 |
| Radioactive | 300K | 5.25 | 1.2K | 12.36 / 14.63 |
| Demon | 2.4M | 8.5 | 2.4K | 20.60 / 25.23 |
| Galaxy | 16M | 13 | 4.5K | 36.43 / 47.26 |

These cumulative tier timings defer rebirth. The separate continuous rebirth cohort resets as soon as eligible, so buying Galaxy can occur later. Prices, income factors and rate caps are in Config/Toilets and Config/Income. Existing sale values stay unchanged.

Cash is `min(10, (1 + trackEffect + rebirthBonus) * DoubleCash * VIP)`. The first ten Cash levels keep +10% each; levels 11-100 add +2.5% each. The new R15 bonus is +1500%; with Cash Boost L100, the uncapped factor is 19.25x. The existing formula clips both unpaid and paid cash to 10x; R15 alone is nominally 16x but currently delivers 10x. Double Cash and VIP still multiply by 2 and 1.25 before that cap. Resolving this conflict requires an explicit cap decision. Daily rewards retain their separate schedule and paid factors. No paid luck is introduced.

Offline Tank retains +24 minutes for each legacy level 1-10, then +8 minutes/level through 100: 8 hours base, 12 at L10, 24 at L100; Offline Plus doubles these. Storage can fill earlier. Base storage is 37.44B coins/slot and 374.4B/player, scaled by cash and tank; the entire ledger still caps at **9e15 subcoins = 1.5T coins**. The saved scale remains 6,000 units/coin. Wallet/Earned remain <=9e15 coins. Fraction retention, bounded products, old-rate settlement and timestamp high-water rules are unchanged.

## Purchase curves and previous measured upgrade pace

Config/Upgrades gives each track strictly increasing piecewise exponential cost anchors. For purchase number n between anchors (a,A) and (b,B), cost is `ceil(A * (B/A)^((n-a)/(b-a)))`. Endpoints are included, server-authoritative and validated under the integer ceiling. Every ten levels unlocks a named title; maximum unlocks Master. Titles add no hidden economic multiplier.

| Track | Cap | First / last price | Normal milestone p50 hours |
|---|---:|---:|---|
| Cash Boost | 100 | 400 / 20B | L35 1.93; L60 9.89; L85 23.45; L100 36.59 |
| Offline Tank | 100 | 1K / 20B | L35 1.99; L60 10.05; L85 23.79; L100 36.90 |
| Luck | 50 | 600 / 3.5B | L18 0.80; L30 2.81; L43 9.72; L50 17.60 |
| Flush Speed | 10 | 400 / 140M | L7 0.87; L10 2.38 |
| Auto-Flush Speed | 10 | 800 / 140M | L7 0.99; L10 2.43 |
| Display Slots | 10 configured | 600 / 300M theoretical | Seven purchases fill the starting three-slot plot: 1.84h |

Display purchases stop at physical capacity ten. Levels 8-10 are not sold to an already-full plot; no useless slot or currency refund is minted. The full plot receives its Master title and completed bar at that effective cap. Index/paid slots can make capacity arrive earlier. This is the explicit bounded-capacity exception to the ten-level presentation. Legacy capacities up to 100 remain intact.

At the very start, the first five Cash levels are affordable within four active minutes **from service coins alone**, with no sales or displays. The main cohort instead prioritizes toilets and reaches L10 around 44 minutes; it does not pretend every player immediately purchases the cheapest possible level. The complete tables contain every requested checkpoint for all three archetypes, including p90 tails. Cash L100 p90 is 57.53h, so these are typical timing targets rather than hard completion deadlines.

| Milestone (p50 hours) | Casual | Normal | Grinder |
|---|---:|---:|---:|
| Cash L35 / L60 / L85 / L100 | 3.43 / 14.57 / 30.53 / 58.80 | 1.93 / 9.89 / 23.45 / 36.59 | 1.68 / 8.74 / 20.27 / 31.49 |
| Tank L35 / L60 / L85 / L100 | 3.57 / 14.87 / 30.87 / 60.07 | 1.99 / 10.05 / 23.79 / 36.90 | 1.75 / 8.90 / 20.41 / 31.92 |
| Luck L50 | 23.97 | 17.60 | 16.15 |
| Flush / Auto max | 3.83 / 3.90 | 2.38 / 2.43 | 2.05 / 2.08 |
| Full ten-slot plot | 3.20 | 1.84 | 1.60 |
| Rebirth 1 | 0.70 | 0.40 | 0.33 |
| Rebirth 5 | 3.30 | 2.03 | 1.77 |
| Rebirth 15 | 140.00 | 95.67 | 84.62 |

## Reproducibility and limitations (previous tuning targets)

`luau scripts/balance.luau` uses 200 independently seeded short accounts per archetype for toilet timings; the long cohort uses 64 per archetype through 300 online hours, or all upgrades/R15 completed. Unfinished accounts are explicitly censored as infinity, never excluded from percentiles. Normal checks enforce tier targets within 20%, R1 20-25 minutes, R5 2-3h, R15 80-150h; long tracks enforce the milestone bands (L35 and full plot allow approximately 2h via a 1.8h lower tolerance).

Casual/normal/grinder use 30%/75%/100% manual cooldown uptime, collect every 120/30/15 seconds, and earn passive income throughout online time. Buy Dirty first, five slots, then affordable slots and one Cash/Luck/Speed per tier through L4, while buying each next toilet. After Galaxy, buy the cheapest available track only when its price is <=25% of the wallet, keeping the rest toward rebirth. Best owned displays are reserved and only legitimate surplus is sold. All spending, permanent effects, rebirth losses and starter grants are included. No initial inventory, free showcase slots, index/daily rewards, paid modifiers, temporary server luck or offline windfalls.

Long-horizon rolls sample the exact equivalent rare-first probability distribution, in 2-second batches during hour one and 30-second batches later. Income settles at the previous display/rate before mutations; new finds enter the following interval. Purchase/cooldown decisions have at most one batch of timing discretization. This avoids hundreds of millions of profile rebuilds, but is not an engine scheduling benchmark. The per-flush short cohort independently exercises production grants and settlement. Both replay seeds deterministically.

Normal passive share is 60.95% over the first ten minutes and 62.04% over the ten minutes following Diamond. Earlier 40-60%/70-90% assertions are superseded: faster tier changes and optional slots shift the measurement window. Displays still lead midgame income; steady ten-slot showcases range 84-90% at Diamond and above. Rare jackpots broaden both tails.

These estimates assume continuously online play, efficient display/sale choices and regular collection. Auto-only play, travel, latency, missed collections, passes and actual time away change outcomes. Old saved inventories and offline tanks can skip early coin gates; the fresh-flush minimum remains. There is no economy compensation or wallet wipe.

## Luck and migration

Total luck is capped at 10x. The UI says `Luck +N%`, so 10x is +900% (1000% total). The first 5x applies fully; for base odds strictly rarer than 1/25,000, additional luck is halved: `min(luck,5) + max(0,luck-5)/2`. Sewer Shark at exactly 1/25K uses full luck. Maximum untimed Galaxy luck is now 5.98x (+498%); late-game 4-6x total is typical. Daily/server boosts can reach the cap, paid luck cannot.

`simulate.luau` prints each item's effective sequential odds and checks one million independent rolls at each of 1x, 5x and 10x. Expected first Secret at one flush/second: 252.53h / 50.51h / 33.67h. At 10x, total event probability is 0.000083249 per roll: about 8.99 arrivals/hour at the worst 12-player, 0.4s floor, far below one broadcast per 8 seconds. Existing bounded queue, deduplication and announcement limits are unchanged. Every accepted roll returns an item. At 10x Toilet Paper's check reaches certainty if all rarer checks fail, so Poop has zero effective probability, while remaining the structural fallback.

`UpgradeVersion=2` preserves saved valid old levels and their first-ten-level effects; legacy over-cap values clamp to the old maxima before adopting the new schema. New profiles and repeated saves preserve new maxima without multiplying slots or refunding coins. Nonfinite, negative and fractional upgrade levels are rejected. Retire older server binaries before rollout: their sanitizers cannot preserve these extended levels or larger pending capacity. No mixed-version downgrade guarantee.

Verification includes the extended audit harness, all standalone checks, UI/runtime and 972 layout cases, visuals, all six world modes, odds, balance, StyLua and Rojo. Native touch/gamepad rendering, device performance, live DataStore outages/lease timing and paid receipts still require isolated Studio/published-server QA. Existing crash/ambiguous-save durability limits remain; no exactly-once outage guarantee is claimed.

Previous baseline verification: 21 standalone checks, 148 audit scenarios, UI plus 972 layout cases, visual checks and all six world modes passed. Balance, three-million-roll odds, StyLua and `rojo build -o build.rbxl` passed. Selene was attempted but could not load its configured `roblox` standard library; no Selene pass is claimed. Representative [upgrade phone](permanent-previews/upgrades-phone.png), [rebirth overview](permanent-previews/rebirth-desktop.png) and [rebirth phone review](permanent-previews/rebirth-phone.png) images are headless approximations, not Studio screenshots.

Runtime files: Config/Upgrades, Config/Rebirth, Config/Toilets, Config/Income; UpgradeRules/RebirthRules; DataService schema marker and RollService rare odds; HUD/UpgradeTracks/Upgrades/Rebirth UI, Audio/Feedback, and the existing RebirthStairs labels. The admin validator only expands its numeric envelope to the new configured track maxima. New audit-permanent and permanent-cohort modules extend the existing harness; affected old tests now assert the permanent contract rather than historical reset behavior. Studio MCP was checked and returned `studios: []`; no native engine test is claimed.
