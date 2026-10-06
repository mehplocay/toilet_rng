# Stronger rebirth rewards validation

2026-10-06, feature/rebirthvalues. Historical reward-only validation; see [the later catalog/rebirth integration](catalog2-rebirth-merge.md) for gate retuning and merged checks. Uncommitted; no push.

## Unresolved owner decisions

1. R15 +1500% implies x16 before Cash Boost; the existing catalog clips all cash to x10. Free progression above x10 needs a revised interpretation of the paid cap. PaidBenefits and monetization config remain unchanged.
2. Reward-only tuning accelerates normal R5 to 1.73h and R15 to 65.25h with the existing cap and gates. R1 remains about 24min and Galaxy remains 36.43min. Preserving 2h/96h requires authorization to retune rebirth gates. Toilet and upgrade prices/effects remain unchanged.

The existing scripts/balance.luau was run and FAILS its R5 lower bound (1.725h versus 2h); the printed R15 median also fails its 80h lower bound. These tests have not been weakened. The separate rebirth-values-simulations.luau reports all 64-seed casual/normal/grinder cohorts even when pacing fails. Its production rules include free Auto Collect; long batches limit collection precision to 30 seconds after hour one. Existing online, no-paid, no-offline cohort assumptions remain.


## Current seeded medians (hours)

| Archetype | R1 | R5 | R10 | R15 |
|---|---:|---:|---:|---:|
| Casual | 0.700 | 2.967 | 34.967 | 95.592 |
| Normal | 0.400 | 1.725 | 24.042 | 65.250 |
| Grinder | 0.332 | 1.450 | 20.950 | 56.050 |

Each archetype has 64 seeds, with a 300-hour censoring horizon. These are cumulative continuously online hours. Normal R15 p90 is 91.608h; casual 144.025h; grinder 82.292h. No paid passes or temporary luck are included. Normal Galaxy is independently measured at 36.43min p50 / 47.26min p90 while deferring rebirth, unchanged by reward-only tuning.

## Implementation and checks

- Explicit rewards, migration by saved level, idempotent capped R10 slots, free R5 collection, config cosmetics, window/perk previews and stairs.
- 191 audit scenarios pass (184 retained + seven added): all-level migration, slot migration, free collection guards, R10 committed response loss/rejoin/replay, exhaustive stacking/caps, saturated R15 ledger, and VIP/chat composition.
- All 21 standalone check-*.luau files pass; check-audit and check-ui-runtime run via their bundlers. UI/runtime and all 972 layout cases pass, including all-level reward and perk previews. StyLua passes. Visuals and all six world modes pass, including actual cosmetic creation/reuse/cleanup. Rojo build passes.
- Selene cannot run because its configured roblox standard library is missing. No Studio, native-device or live billing test is claimed.

At maximum current cash x10, Galaxy Secret income is 13M coins/s per slot, with a ten-slot player rate cap of 130M coins/s (780B subcoins/s). A legacy 100-slot plot shares that same player cap. The saved ledger saturates at 9e15 integer subcoins = 1.5T coins; wallet and lifetime Earned independently cap at 9e15 coins. At a saturated ledger with only five Earned coins of room, collection transfers exactly five coins, preserves the remainder and rejects another credit. Double Cash plus VIP at R15 cannot increase the cap or multiply a quoted receipt/collected ledger twice.

Pre-existing validation issue: default.project.json lacked the explicit modern chat configuration required by check-audit.ps1. Restored it additively. No existing security scenario was removed. Economic expected values changed only where the reward table changes the result. Cosmetic geometry runs in the world harness; the security fixture retains its existing geometry boundary.
