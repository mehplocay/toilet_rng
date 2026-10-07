# Wave 1 integration

Current owner decision, 2026-10-07: **every toilet can drop every item**. The catalog contains 47 stable IDs, 15 toilets and nine rarities. [The all-pools report](all-pools.md) records the current configuration, before/after pacing, jackpot risk, expected flushes and verification. Earlier integration and balance outputs are historical measurements.

## Runtime contract

- `Config/Items.luau` supplies all candidates to `RollService.Distribution` for every valid toilet tier. There are no runtime pool fields. JSON `FirstToiletTier` is uniformly 1 and is informational only.
- Checks run in descending base denominator order, with stable ID tie-breaking. Every successful flush returns one item; Poop is the fallback. Check probability is `min(1, totalLuck / Chance)`, with uncapped total luck and no diminishing returns. Actual outcome probability includes all preceding failures.
- Better toilets increase configured luck, speed and existing income factors. Only prices, luck, rarity income and rebirth coin gates are retuned for all-pools. Existing service awards, cooldowns, display multipliers, upgrade prices/effects, rebirth bonuses and the 300-fresh-flush requirement remain intact.
- The Lucky disclosure uses the same server distribution as flushing. Every tier discloses all 47 outcomes and all nine rarity totals. Its review token invalidates on tier or luck changes. The fixed-size readable text wraps in one scroll viewport, with measured row heights and a separate confirmation button.
- Index cards show base checks even when undiscovered, with Poop labelled as the fallback. Shop, tutorial, hub and admin copy explain universal eligibility. The admin selector derives IDs from Config.Items.

## Saved data and presentation

No schema migration is introduced. Item/toilet IDs, inventory and collection counts, protected copies, display assignments, pending subcoins, currencies, upgrade levels, rebirth levels and claimed index rewards remain valid. Existing pending income is retained; future accrual uses the current configured rates. Save/rejoin tests include a Basic profile owning and displaying late catalog items.

All existing meshes, icons, reveals, audio mappings and announcements remain. Celestial uses the configured Godly audio alias and existing cinematic/reduced/off behavior. The 15-tier visuals continue to use data-driven mappings. No new asset IDs are introduced.

## Validation

- `check-wave1.luau` checks canonical item fields, rarity bands, index totals, all 15 complete catalogs and capped unit-mass distributions. `check-audit.ps1` independently reads `wave1-data.json` and includes universal reachability, monotone rare outcomes, current-tier disclosure and saved-profile regressions.
- `check-all-pools.luau` compares the accelerated numeric cohort sampler with the previous ordered linear scan at every probability boundary and evenly spaced samples, for every tier and five luck settings. Live server rolls still use independent random checks.
- `ui-all-pools.luau` checks 47 text rows, nine rarity totals, wrapping, top alignment, scroll reachability, confirmation placement and stale-token invalidation at all twelve viewports. Headless font metrics approximate engine text measurement; they do not certify native Studio/mobile glyph rendering.
- `balance.luau` runs fresh-account and permanent/rebirth cohorts for casual, normal and grinder policies. `wave1-balance.luau` separately retains the conditional Galaxy-at-minute-35 experiment. Original acceptance windows remain enforced. The short cohort now stops purchasing beyond its requested observation tier, preventing an early jackpot from overshooting that tier and stalling the simulation.

See [research](../research/all-pools-odds-layout.md) for official API, DevForum, release and tool sources; see the current report for exact command results and remaining limits.
