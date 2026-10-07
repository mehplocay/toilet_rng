# All items from every toilet — implementation and balance

2026-10-07, `feature/all-pools`. Worktree delivery; no commit or push. This owner decision supersedes historical pool/unlock rules. All 47 stable item IDs and all nine rarities are eligible at each of the 15 toilets.

## Rules and economy decisions

`RollService` clones the complete item catalog. Independent checks remain rare-first, ordered by descending denominator then ID, with Poop as the final fallback. `check = min(1, totalLuck / baseDenominator)`; total luck caps at 10x with no diminishing returns or extra odds multiplier. Actual outcome probability is `check * product(1 - earlierCheck)`.

Toilet-only luck rises from 1x to 2.9x. Staying below the smallest non-fallback denominator (Suds Slug, 3) keeps all 47 outcomes positive on every unboosted toilet. At boosted luck, saturated earlier checks can make later common outcomes zero; this is the required clamped roll rule, not a tier lock. Every independent check and every cumulative rare threshold improves monotonically with toilet tier; individual common outcome probabilities need not increase. At the 10x cap, higher toilet luck cannot further improve RNG.

Economy retuning is confined to configuration: toilet prices and luck; Mythic display income 1,000 → 500/s; Godly 6,000 → 4,000/s; selected rebirth coin gates below. Other rarity rates, item IDs/base odds/sale values, service awards, cooldowns, toilet display factors, upgrade prices/effects, rebirth bonuses and 300 fresh flushes are unchanged. Early rare displays are still valuable, but their ordinary progression impact is smaller.

| Changed rebirth gate | Before Coins | After Coins |
|---|---:|---:|
| R1 | 4,000,000 | 6,500,000 |
| R4 | 400,000,000 | 2,300,000,000 |
| R5 | 3,800,000,000 | 5,000,000,000 |
| R8 | 700,000,000,000 | 1,000,000,000,000 |
| R9 | 4,500,000,000,000 | 30,000,000,000,000 |

R9 also keeps the existing Cash/Offline level-100 timing checks in range. No acceptance range was relaxed. Raising gates affects only future rebirth actions; saved rebirth levels are preserved.

## Before/after pacing

Identical deterministic seed sets and purchase policies: 200 fresh-account seeds per archetype for early toilets; 64 per archetype for permanent progression/rebirths and extended toilets. Casual/normal/grinder flush uptime is 30/75/100%, collection every 120/30/15 seconds. Paid, offline, daily and server-event boosts are off. Displays continue earning while online. Early Galaxy measurement defers rebirth; rebirth progression purchases and resets at each eligible coin gate.

Early toilets, cumulative **minutes**, each cell **p50 / p90**:

| Archetype | Toilet | Before | After |
|---|---|---:|---:|
| Normal | Dirty | 1.47 / 1.57 | 1.47 / 1.63 |
| Normal | Golden | 3.01 / 3.27 | 3.01 / 3.39 |
| Normal | Diamond | 6.12 / 6.63 | 6.13 / 7.30 |
| Normal | Radioactive | 11.85 / 13.90 | 11.36 / 13.92 |
| Normal | Demon | 20.09 / 23.73 | 19.60 / 24.23 |
| Normal | Galaxy | 35.47 / 44.24 | 37.52 / 45.75 |
| Casual | Dirty | 3.42 / 3.92 | 3.42 / 4.00 |
| Casual | Golden | 6.13 / 7.46 | 6.12 / 7.50 |
| Casual | Diamond | 12.16 / 13.78 | 12.14 / 14.39 |
| Casual | Radioactive | 22.23 / 26.22 | 20.24 / 26.26 |
| Casual | Demon | 37.35 / 44.00 | 34.16 / 42.46 |
| Casual | Galaxy | 60.27 / 74.62 | 60.19 / 74.35 |
| Grinder | Dirty | 1.07 / 1.25 | 1.07 / 1.25 |
| Grinder | Golden | 2.30 / 2.55 | 2.32 / 2.59 |
| Grinder | Diamond | 4.78 / 5.14 | 4.86 / 5.88 |
| Grinder | Radioactive | 9.73 / 11.10 | 9.48 / 11.60 |
| Grinder | Demon | 16.41 / 19.45 | 16.64 / 20.54 |
| Grinder | Galaxy | 29.51 / 36.09 | 32.28 / 39.01 |

Rebirth milestones, cumulative **hours**, each cell **p50 / p90** (rounded). Normal R1 is 25.00 minutes in the final 64-seed cohort; the rounded hours table displays 0.42.

| Archetype | Rebirth | Before | After |
|---|---|---:|---:|
| Normal | R1 | 0.41 / 0.51 | 0.42 / 0.52 |
| Normal | R5 | 2.05 / 2.48 | 2.12 / 3.13 |
| Normal | R10 | 28.45 / 35.83 | 27.56 / 36.14 |
| Normal | R15 | 98.53 / 111.79 | 92.97 / 106.80 |
| Casual | R1 | 0.73 / 0.90 | 0.67 / 0.90 |
| Casual | R5 | 3.17 / 3.83 | 3.37 / 4.57 |
| Casual | R10 | 41.89 / 53.29 | 40.58 / 53.07 |
| Casual | R15 | 138.63 / 165.90 | 129.49 / 161.49 |
| Grinder | R1 | 0.34 / 0.43 | 0.35 / 0.45 |
| Grinder | R5 | 1.78 / 2.09 | 1.85 / 2.54 |
| Grinder | R10 | 25.12 / 31.22 | 24.73 / 31.69 |
| Grinder | R15 | 90.37 / 101.55 | 86.17 / 96.52 |

Full results, including every R1–R15 level, every later toilet, upgrade milestones, passive shares and p90 tails: [before](all-pools-before-balance.txt), [after](all-pools-after-balance.txt). Conditional Wave 1 (synthetic Galaxy at minute 35, ten slots, 8 Ducks + 2 Golden Poops, fixed L4 upgrades) is a separate experiment: [before](all-pools-before-wave1.txt), [after](all-pools-after-wave1.txt). All original early, extended, rebirth, upgrade and conditional acceptance windows pass.

## Jackpot risk

Pacing targets are medians, not minimum acquisition times. At fixed Basic 1x luck, 300 flushes (ten minutes at 75% uptime) have a 13.9292% chance of at least one Mythic, 1.8101% Godly, 0.2459% Celestial and 0.0730% Secret; Cosmic Courtesy alone is about 0.0020%. These fixed-tier probabilities exclude upgrades/events and are not predictions for a progressing player.

A first-flush Secret still intentionally can shortcut progression: one Cosmic Courtesy on Basic earns 3,000,000 Coins in 30 seconds, before toilet/cash boosts. Lowering Mythic/Godly rates addresses the much more frequent early windfalls; this change does not claim to eliminate exceptional jackpots. Rare base odds and Secret/Celestial rates are retained.

| Toilet | p01 | p10 | p50 | p90 | p99 minutes |
|---|---:|---:|---:|---:|---:|
| Dirty Toilet | 1.00 | 1.13 | 1.47 | 1.63 | 1.83 |
| Golden Toilet | 2.00 | 2.03 | 3.01 | 3.39 | 3.71 |
| Diamond Toilet | 3.07 | 4.58 | 6.13 | 7.30 | 8.70 |
| Radioactive Toilet | 4.57 | 8.73 | 11.36 | 13.92 | 16.54 |
| Demon Toilet | 7.67 | 14.55 | 19.60 | 24.23 | 28.35 |
| Galaxy Toilet | 11.87 | 24.23 | 37.52 | 45.75 | 53.40 |

[Risk experiment](all-pools-risk.txt) uses the same 200 normal seeds; p01 is only two players and is not a stable population estimate. The simulator observation-tier fix prevents fast jackpots from buying beyond the requested terminal tier and stalling the measurement.

## Per-toilet odds and prices

For each rarity, the selected item has the **largest configured base denominator**: Soggy Sock (6), Capybara Cap (24), Bubble Beard (120), Towel Tornado (900), Golden Gargler (4,500), Bath Bomb Behemoth (30,000), Plunger Paladin (250,000), Starlight Seraph (900,000), Cosmic Courtesy (15,000,000). Poop is a fallback, not a 1/2 independent check.

Cells show **mean flushes to the actual outcome, `1 / probability`**, using toilet luck alone. They are not guarantees or inverse check probabilities. No upgrades, rebirth, daily/event or Lucky boosts. At Infinity, Cosmic Courtesy is 2.9x more likely per flush and about 9.06x more frequent per unit of continuously flushing time than Basic (1.5s → 0.48s cooldown).

| Toilet | Luck | Common | Uncommon | Rare | Epic | Legendary | Mythic | Godly | Celestial | Secret |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Basic Toilet | 1x | 10.39 | 27.50 | 121.81 | 902.91 | 4502.57 | 30002.15 | 250002.66 | 900002.19 | 15000000.00 |
| Dirty Toilet | 1.12x | 9.93 | 24.96 | 108.96 | 806.48 | 4020.43 | 26787.86 | 223216.95 | 803573.62 | 13392857.14 |
| Golden Toilet | 1.25x | 9.60 | 22.77 | 97.81 | 722.91 | 3602.57 | 24002.15 | 200002.66 | 720002.19 | 12000000.00 |
| Diamond Toilet | 1.4x | 9.36 | 20.76 | 87.53 | 645.77 | 3216.86 | 21430.72 | 178574.09 | 642859.33 | 10714285.71 |
| Radioactive Toilet | 1.55x | 9.24 | 19.14 | 79.24 | 583.56 | 2905.80 | 19356.98 | 161292.98 | 580647.35 | 9677419.35 |
| Demon Toilet | 1.7x | 9.22 | 17.82 | 72.41 | 532.33 | 2649.63 | 17649.20 | 147061.48 | 529413.95 | 8823529.41 |
| Galaxy Toilet | 1.85x | 9.29 | 16.73 | 66.69 | 489.40 | 2435.01 | 16218.36 | 135137.79 | 486488.68 | 8108108.11 |
| Coral Commode | 2x | 9.43 | 15.80 | 61.83 | 452.92 | 2252.57 | 15002.15 | 125002.66 | 450002.19 | 7500000.00 |
| Cloud Cushion | 2.12x | 9.59 | 15.16 | 58.43 | 427.44 | 2125.22 | 14153.09 | 117927.19 | 424530.49 | 7075471.70 |
| Clockwork Closet | 2.24x | 9.80 | 14.60 | 55.40 | 404.70 | 2011.50 | 13395.00 | 111609.80 | 401787.90 | 6696428.57 |
| Dragon Kiln | 2.36x | 10.04 | 14.09 | 52.68 | 384.27 | 1909.35 | 12714.01 | 105934.86 | 381358.12 | 6355932.20 |
| Aurora Throne | 2.48x | 10.33 | 13.64 | 50.22 | 365.82 | 1817.09 | 12098.92 | 100809.11 | 362905.42 | 6048387.10 |
| Astral Altar | 2.6x | 10.67 | 13.24 | 47.99 | 349.07 | 1733.34 | 11540.61 | 96156.51 | 346156.04 | 5769230.77 |
| Paradox Potty | 2.74x | 11.11 | 12.82 | 45.63 | 331.39 | 1644.91 | 10951.05 | 91243.54 | 328469.34 | 5474452.55 |
| Infinity Flush | 2.9x | 11.71 | 12.39 | 43.22 | 313.27 | 1554.30 | 10346.97 | 86209.56 | 310347.02 | 5172413.79 |

| Toilet | Incremental Coins |
|---|---:|
| Basic Toilet | 0 |
| Dirty Toilet | 11,000 |
| Golden Toilet | 31,000 |
| Diamond Toilet | 185,000 |
| Radioactive Toilet | 1,000,000 |
| Demon Toilet | 6,000,000 |
| Galaxy Toilet | 36,000,000 |
| Coral Commode | 230,000,000 |
| Cloud Cushion | 850,000,000 |
| Clockwork Closet | 2,100,000,000 |
| Dragon Kiln | 6,000,000,000 |
| Aurora Throne | 22,000,000,000 |
| Astral Altar | 85,000,000,000 |
| Paradox Potty | 320,000,000,000 |
| Infinity Flush | 1,200,000,000,000 |

## UI, saved data and changed files

- Lucky odds still come from `LuckyService` and the same current-tier `RollService` distribution used by flushing. All 47 outcomes and nine rarity totals are shown. Existing token invalidation prevents using stale tier/boost quotes. The window now has one scrolling list, measured wrapped text at 17px, top alignment, right-side padding and a separate confirmation button.
- Collection shows base item checks even for undiscovered cards (Poop: Fallback). Shop, hub, tutorial, purchase announcement and data-driven admin picker copy describe universal eligibility. `FirstToiletTier` is uniformly 1 in authoring data and unused by gameplay.
- No DataService/schema/version migration is added. All item IDs, counts, displays, protected copies, wallet, pending units, rebirth levels and claims remain valid. A Basic save/rejoin fixture retains every item and late-item displays. Existing pending income remains payable; future accrual uses the new configured rates.
- Main production files: `Services/RollService.luau`; `Config/Toilets`, `Income`, `Rebirth`; `UI/LuckyOdds`, `Collection`, `Upgrades`, `Tutorial`; client purchase toast, hub builder and admin Window. Specs, research, contract fixtures and numeric/server/UI audits accompany them.
- Long simulations use a cumulative-threshold binary search for numeric samples. Its thresholds are formed in exactly the original addition order; boundary/grid tests compare it with the old linear scan. Production independent callback checks are unchanged.

## Verification and limits

- Passed: 24 standalone `scripts/check-*.luau` entrypoints (the audit and UI entrypoints run through their required PowerShell bundles); `check-audit.ps1` (377/377); `check-ui.ps1` (all twelve Lucky viewports and 972 layout cases); `check-world.ps1` (all six template modes, invoking `check-visuals.ps1`); both full balance runners; odds and risk scripts; StyLua with Windows line endings; Rojo binary build; `git diff --check`.
- All requested targets and the existing upgrade timing checks are kept. Balance policies are estimates, not live retention evidence. Server events, paid boosts and exceptional early drops can accelerate real players.
- Selene was attempted but cannot load the configured `roblox` standard library in this environment; no lint-pass claim. UI/visual tests use engine mocks and approximate font metrics, not native Studio/mobile screenshots. Native rendering and live economy telemetry remain review limits.
- Archived task briefs/reference artwork and historical simulation transcripts retain historical wording; current GDD, integration/economy docs and authoring catalog explicitly supersede their pool rules.

[Research and sources](../research/all-pools-odds-layout.md). No commit or push.
