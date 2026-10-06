# Wave 1 integration

2026-10-06, `feature/wave1-integration`. Uncommitted worktree delivery. The item IDs, names, odds, rarity bands, values, base income, first unlocks and cumulative pools follow [wave1-data.json](wave1-data.json). The 36 new items and eight new toilets bring the game to 47 items, 15 toilets and nine rarities.

## Runtime and assets

- `Config/Items`, `Rarities`, `Toilets`, `Income`, `Rewards` and `IndexRewards` carry the expanded data. Celestial is order 8, RGB 160/240/255, 25,000 base coins/s; Secret is order 9. King Poop now resolves Godly income; Sewer Shark has 1/50,000 base odds. All drops still use independent rare-to-common checks, with Poop as the unconditional final fallback. Stable ID tie-breaking makes equal-odds checks deterministic.
- `default.project.json` maps the supplied `assets/rbxm/Wave1Templates.rbxm` to `ReplicatedStorage.Wave1Templates`. `MeshCatalog` uses the four actual Wave 1 manifests for dimensions and triangle counts. The loader explicitly routes all three template folders, normalizes once, preserves the imported toilet foot pivot, anchors/non-collides the visible meshes and retains primitive fallbacks. No mesh/texture IDs were invented or reuploaded.
- `WorldModels`, `World`, `Visuals`, `TemplateEffects`, `TemplateAccents` and the item/toilet builders cover all IDs. Each new toilet has at most one shadowless light and one 3/s sparkle emitter. Color transitions and slow cloud/star motes distinguish the themes; existing distance/Reduced/Off control applies. Static mesh details supply gear/halo/portal shapes; effects reuse the existing sparkle texture. No idle animation loops or additional audio IDs were added.
- `Assets` has 44 blank icon entries. `UI/Preview` renders static, effect-free normalized model previews for these entries until real icon IDs are supplied. It does not wait for or modify the separate icon-rendering session.
- Collection cards sort by rarity then odds and ID; nine filters and scrolling cover all 47 cards. The shop exposes all 15 tiers with abbreviated prices, nominal display factors and the 40x free/3x paid cap explanation. Lucky Flush odds report base checks separately from actual outcome probabilities, including the Poop remainder. The admin item picker uses Items and the toilet picker cycles Toilets.
- Celestial uses the existing configured cinematic/reduced reveal paths, server announcement audience and the Godly stinger at the same cue settings. Native Rarest ranking uses canonical item odds. Existing pool-driven automatic flush, offline accrual, nametags and stairs requirement rendering need no fixed-count extension.

## Saved profiles and index rewards

Migration stays keyed by item ID. No inventory, collection, display slot, protected copy, owned toilet tier or rebirth reset is performed. The existing sanitizer inserts zero counts for new IDs and clamps toilets using `#Toilets` (1..15). Saved rarest chances are recalculated from the canonical item ID. Rates and rarity labels resolve from current config, including already displayed King Poop/Sewer Shark. Existing pending subcoins retain their stored amount; elapsed offline time is consumed once at the current catalog rates.

Existing index claim IDs stay stable. `total:35` continues to grant the same `FullIndexPlaque`, now labelled Veteran index plaque; `total:47` grants the new Wave One plaque. Celestial completion gives 22 stamps. Founding Flush still refers to the original eleven IDs. Retiered and expanded rarity groups do not revoke or repay a previously claimed reward.

## Balance decisions and specification differences

The merged cash formula remains `min(40, freeCash * toiletDisplayFactor) * min(3, paidCash)`. Total luck remains capped at 10x; for base odds above 25,000, the portion above 5x is halved. These explicit task requirements supersede the historical Wave 1 proof's 5x production cap, linear 10x stress column and uncapped toilet factors.

New tier prices, service awards, cooldowns and luck follow the JSON. Its integration recipe rebases the new display factors from historical Galaxy 12x to the merged 13x: 19.5/29.25/43.3333/65/97.5/146.25/216.6667/325. Slot/player nominal caps follow the same factors, but never bypass the combined 40x/3x cap.

The expanded early pools speed up acquisition. To preserve the requested original progression, only the first seven toilet prices were retuned: Dirty 7,500; Golden 16,000; Diamond 90,000; Radioactive 420,000; Demon 3,000,000; Galaxy 16,500,000. Their service awards, cooldowns, luck and display factors are unchanged. The 200-seed normal fresh-account p50 arrivals are 1.47/3.01/6.12/11.85/20.09/35.47 minutes; Galaxy p90 is 44.24 minutes. Paid, offline, daily, event and rebirth benefits are excluded from that short cohort.

`scripts/balance.luau` additionally runs 64 fresh-account seeds per archetype through all toilets while continuing to buy upgrades and deferring rebirth. These are cumulative online minutes, p50 / p90:

| Toilet | Casual | Normal | Grinder |
|---|---:|---:|---:|
| Coral Commode | 144.5 / 188 | 86.5 / 108.5 | 74.5 / 92.5 |
| Cloud Cushion | 195.5 / 238 | 125 / 151.5 | 108 / 134 |
| Clockwork Closet | 332 / 390 | 217 / 258.5 | 187.5 / 228.5 |
| Dragon Kiln | 526 / 624 | 345.5 / 425.5 | 297.5 / 363 |
| Aurora Throne | 794 / 948 | 518 / 611 | 457 / 529.5 |
| Astral Altar | 1576 / 1854 | 1088.5 / 1293.5 | 947.5 / 1165.5 |
| Paradox Potty | 2166 / 2616 | 1481.5 / 1849 | 1255.5 / 1571 |
| Infinity Flush | 2896 / 3468 | 1889.5 / 2363.5 | 1627 / 2164.5 |

These are not directly comparable to the historical JSON targets: those came from a conditional synthetic Galaxy-at-minute-35 cohort with no subsequent upgrades and uncapped displays. `scripts/wave1-balance.luau` now executes actual production config, distribution, upgrade rules, inventory sales and the capped accrual ledger for that conditional policy, for all three archetypes. Its generated [output](wave1-balance.txt) records the revised conditional estimates alongside each historical target. The authoritative item/model data and new toilet prices are not changed to hide the cap discrepancy.

Only four JSON arrival targets fell outside the original +/-20% tolerance under the production cap. Their explicit corrections are Aurora 285 -> 350, Astral 365 -> 530, Paradox 460 -> 770 and Infinity 570 -> 1,150 minutes. `HistoricalUncappedTargetMinutes` preserves each prior number. Actual normal conditional p50 values are 348.70/526.94/765.82/1,149.51. The earlier four targets remain 85/130/175/225 (actual 84.49/124.72/168.22/235.80). The runner now asserts the corrected +/-20% ranges. The fresh-account runner independently checks +/-20% around the three-archetype baselines above. Settlement at collect/tier/display-change boundaries produces byte-identical cohort output to per-flush settlement.

The capped fixed-tier showcase has 61.30%, 49.80% and 39.47% passive shares at tiers 13..15. Consequently the old 70–90% showcase assertion applies through tier 12; later tiers assert the actual maximum-rate bound. Ten Secrets at tier 15 produce at most 40M/s free or 120M/s paid. The existing 1.5T pending ledger fills in 625 or 208.33 online minutes respectively. This replaces the historical 300M/s and 3B/s estimates that multiplied outside the cap.

### Rebirth gate decision pending

The original fifteen reward rows and all bonuses remain unchanged. With the expanded actual pools and permanent access to new toilets, unchanged coin gates yield normal p50 R1 20 minutes, R5 2.292 hours, R10 24.825 hours and R15 57.725 hours. `balance.luau` deliberately retains the requested pacing assertions and reports those four failures.

The merged [coin-gate rebirth contract](rebirth.md) explicitly supersedes toilet-tier gates. Therefore the historical Wave 1 minimum-toilet table and 3,300-flush snapshot are not reinstated: current eligibility remains coins plus 300 fresh flushes, and stairs show those actual requirements. Saved rebirth levels are never downgraded.

A separate in-memory 64-seed proposal changes only R1 3M -> 4M, R5 500M -> 450M, R10 40B -> 60B and R15 1.25T -> 6.5T. It measures 24.5 minutes / 2.167 hours / 27.167 hours / 98.517 hours. Applying these gates requires resolution of the task's simultaneous unchanged-rebirth-table and pacing requirements; production gates have not been edited. The 300 fresh flushes, bonuses, resets, permanent progression and caps are unchanged in the proposal.

The [complete proposal output](wave1-rebirth-proposal.txt) passes all three archetypes, original-toilet and permanent-upgrade timing assertions and seeded replay, using those four in-memory overrides before running the otherwise unchanged balance script. It is labelled as a proposal and is not evidence that the currently unchanged production coin gates pass.

## Verification and limits

- Passed: `stylua --check src scripts`, `rojo build -o build.rbxl`, `git diff --check`, all 22 standalone `check-*.luau` entrypoints, the audit/UI runtime entrypoints through their required PowerShell harnesses, `check-visuals.ps1`, `check-world.ps1`, and `wave1-balance.ps1 -WriteOutput`. `balance.luau` reports only the four unchanged-gate pacing failures described above. Its assertions have not been weakened to conceal them.
- `check-wave1.luau` verifies all canonical item fields and unlocks, nine disjoint rarity bands, index totals, all pools, 60 independent capped distributions and guaranteed drops. `check-audit.ps1` independently reads the JSON through `wave1-spec-fixture.ps1`, avoiding dependence on the Lua acceptance fixture alone.
- Audit cases exercise old-profile sanitization, save/rejoin/offline settlement, retained displays and rebirth, new late-tier persistence, stable claims, every admin forced drop, all toilet tiers, Celestial audio/audience and Rarest order. Latest audit: 251 passed, zero failed.
- UI tests include the expanded catalog at twelve viewports, all nine filters, scrolling, final-tier purchase, data-driven admin selection and actual Celestial cinematic/reduced/disabled/queue paths. The complete layout suite passes 972 viewport cases. World tests cover all three serialized template folders, all item/toilet paths, six template/fallback modes, late recovery, all 16 rebirth stairs states and bounded effects.
- The binary validator covers 119 total template models/MeshParts and 238 mesh/texture references, including all 44/88 Wave 1 additions. Real published-client asset permissions/downloads, actual Studio rendering and mobile frame time still require live acceptance; headless geometry and UI layout checks do not establish those outcomes.
- Selene was attempted but the configured `roblox` standard library is unavailable. No lint-pass claim. Research sources and API/tool findings are in [the integration research note](../research/wave1-integration.md).

Primary changed files are the configuration modules listed above; `UI/Collection`, `UI/Upgrades`, `UI/LuckyOdds`, `UI/Preview`, admin `Window`, `LuckyService`, `RollService`, `PresentationRules`, the visual loader/builders, and the audit/UI/world/balance runners and fixtures. Existing server authorization/rate limits, premium products and rebirth reward effects are retained.
