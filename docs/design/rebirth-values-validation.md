# Rebirth reward retune validation

2026-10-06, feature/rebirth-balance. Worktree only; no commit or push. This replaces the previous report's two unresolved manager decisions.

## Implemented result

Config/Cash defines a 40x free cap and a separate 3x paid cap. Cash Boost and rebirth bonuses add, display toilet factors multiply inside the free layer, then verified paid factors multiply on top. Double Cash remains 2x; VIP is now 1.5x. Future paid cash pass entries automatically share the paid cap. Milestone titles have no numeric bonus. R15 alone produces 16x sales/service income; maximum Cash Boost makes it 19.25x free / 57.75x paid. Capped Galaxy display income reaches 40x free / 120x paid. Collection, quoted products, the VIP chest and starter grants are not multiplied again; daily coins retain their paid-only rule.

Only R6-R15 coin gates changed, to 1B, 2B, 4B, 15B, 40B, 120B, 200B, 320B, 520B and 1.25T. R1-R5 gates, 300 fresh flushes per rebirth, all 15 reward rows, starter grants, toilets, upgrade prices/effects, luck and speed floors are unchanged. The later curve remains steep. Free Auto Collect, two once-only slots and the Legend cosmetic remain unlocked at R5/R10/R15.

## Pacing

Cumulative online hours, 64 seeds per archetype, p50 / p90. Normal R1 = 24 minutes; Galaxy = 36.43 / 47.26 minutes in the independent 200-seed no-rebirth cohort. All 15 rebirth rows, toilet and upgrade tables are in [economy-v2.md](economy-v2.md), with [full balance output](rebirth-values-balance.txt) and [independent rebirth report](rebirth-values-simulations.txt).

| Archetype | R1 | R5 | R10 | R15 |
|---|---:|---:|---:|---:|
| Casual | 0.70 / 0.93 | 3.37 / 4.57 | 51.11 / 60.15 | 147.17 / 209.21 |
| Normal | 0.40 / 0.52 | 2.025 / 2.75 | 32.00 / 48.61 | 96.83 / 138.50 |
| Grinder | 0.33 / 0.43 | 1.77 / 2.27 | 28.10 / 44.33 | 86.22 / 116.38 |

These are continuously online no-paid/no-offline cohorts with the existing purchasing policy, not guaranteed elapsed playtime. Long runs use two-second batches during hour one and 30-second batches thereafter; R5 Auto Collect assumes a living owner inside the plot and remains limited to batch precision. The horizon is 300 hours; censored observations remain infinity. Paid passes, travel and different display choices change results.

**Assumption requiring manager review:** the newly specified cap/pacing and unchanged upgrade economics take precedence over three older upgrade timing ceilings. Cash L85 now measures 27.075h, Tank L85 27.292h, and Luck L50 21.425h. Their upper regression bands were explicitly rebased from 25/25/20h to 28/28/22h. Other upgrade bands and all lower bounds remain. Requested rebirth bands were tightened to R1 23-25min, Galaxy 35-38min, R5 2-2.2h, R10 25-40h and R15 90-100h. A clarification was asked asynchronously; this is an implementation assumption, not a claimed additional approval. The simulator now prints every archetype before reporting timing failures; failed assertions still exit nonzero.

## Arithmetic and persistence evidence

At 120x, Secret income is 12M coins/s per slot; the player cap is 120M coins/s = 720B subcoins/s, shared even by legacy 100-slot plots. Storage caps at 9e15 integer subcoins = 1.5T coins; wallet and lifetime Earned separately cap at 9e15 coins. The persisted 6000-unit scale is unchanged.

The largest item sale is 60B per copy at 120x; a million-copy batch would reach 6e16. SafeInventory now rejects oversized batches against remaining wallet/lifetime room before multiplying. Configured service awards top out at 540K. Audit cases verify every item/toilet award at both coin ceilings, exact 150K-copy saturation, reject million-copy overflow, preserved one-subcoin tails, partition-invariant fractional paid income, online/offline saturation, save/rejoin, corrected division and one-time collection. Existing quote/receipt tests still prove no second multiplier.

The retained tests cover all-level save migration, R5 living-owner/plot/save guards, R10 migration/committed-response-loss/rejoin/replay/idempotent capacity and unchanged permanent state. New actual R5/R15 reset/save/rejoin cases verify perks and economic identity. The world harness creates the R15 LegendSkin Highlight on the retained toilet, verifies its Adornee and unchanged tier, reuses it on refresh and removes it on lower-level/reassigned plots. Character title/aura thresholds and cleanup also pass. No live billing or engine durability guarantee is inferred from these tests.

## Validation and files

- Expanded check-audit.ps1: 196 passed, 0 failed; all 191 prior scenarios retained, five added.
- All 21 standalone check-*.luau pass; bundled check-audit.luau and check-ui-runtime.luau run through their PS1 harnesses.
- check-ui.ps1 passes, including 972 layout cases and both cash-cap explanations. [Phone upgrade card](rebirth-balance-previews/upgrade-tracks-360x518.png), [phone rebirth review](rebirth-balance-previews/rebirth-confirm-360x518.png) and [desktop review](rebirth-balance-previews/rebirth-confirm-1280x684.png) were rendered and inspected. These are headless approximations.
- check-visuals.ps1 and all six check-world.ps1 modes pass, including 120x income labels and real cosmetic geometry.
- StyLua, rojo build -o build.rbxl and git diff --check pass.
- scripts/balance.luau and the independent rebirth-values-simulations.luau both pass via luau --codegen -O2 with the unchanged seeded production rules. All 192 long-cohort accounts and 600 short-cohort accounts are included; see the generated reports for tails.
- Selene was attempted; its configured Roblox standard library is missing, so no Selene pass is claimed. No Studio/native-device or live purchase test was performed.

Main production files: Config/Cash, Config/Rebirth, Config/Monetization, Config/Shop, UpgradeRules, PaidBenefits, IncomeAccrual, SafeInventory and the Upgrades/Rebirth/Passes UI. Config/Income changes only explanatory comments. Tests add audit-rebirth-balance and retain/update affected cash expectations; check-visuals bundles the new config. No RollService or Lucky Flush code changed.

The local art manifest contains unuploaded future catalog entries. check-ui now permits them only when the runtime asset is absent, an empty vector fallback, or an already-verified existing upload for the same key. All 37 existing upload mappings remain mandatory and exact; no assets or IDs were changed. This is a harness compatibility fix, not a runtime catalog change.

[Current source and numeric findings](../research/rebirth-cash-layers.md). Retire older binaries before rollout; existing session-lease, backend-outage and ambiguous-save limitations remain.
