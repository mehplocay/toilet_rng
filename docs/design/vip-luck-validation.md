# VIP and 2x Luck implementation report

2026-10-07, feature/vip-luck. No commit or push. The pre-existing docs/tasks/32-vip-luck.md was not edited.

## Delivered

- VIP adds a permanent x1.25 luck factor when the shared LuckyService policy cache is eligible. Config/Upgrades owns VipLuckBonus = 0.25 and DoubleLuckMultiplier = 2. Free/rebirth luck and rare-first RollService checks retain their existing linear behavior without a total luck ceiling.
- DoubleLuck is a 399 Robux permanent pass, wired as ID 2014088425. The catalog has 16 passes; Ultimate Bundle still costs 799 and includes all 15 others. An explicit ID-zero fixture verifies disabled passes cannot query, prompt or grant, even through a bundle or owner test unlock. The icon upload remains pending.
- The existing server ownership/creator/bundle path supplies entitlements. Missing, failed, restricted and expired policy lookups remove paid luck only. All other VIP benefits survive. The roll path reads cached eligibility without yielding. No new profile schema, version or migration.
- VIP, DoubleLuck and Bundle require eligible policy and a reviewed odds token before an in-game prompt; eligibility and odds are rechecked after yielding ownership refresh. Cards expose Info: all item odds, including current/with-pass percentages. HUD and Lucky Flush show active multipliers and regional unavailability, with rounding disclosure. Buying a pass invalidates a stale armed-charge review so the new odds can be reviewed.
- New glossy golden clover/ribbon icons at 512 and 128 px, plus a golden clover/2x vector fallback. Existing image files and Blender pipeline files are unchanged. Reproduce with Blender background mode, --python assets/blender/render_double_luck.py.

Primary implementation files: src/shared/Config/{Upgrades,Monetization,Shop,Assets}.luau; src/shared/{MonetizationRules,PaidBenefits}.luau; src/server/Services/{MonetizationService,LuckyService,FlushService,CommerceService}.luau; src/client/UI/{Passes,LuckyOdds,HUD,IconArt,Tutorial}.luau. New regressions: scripts/audit-vip-luck.luau, scripts/ui-vip-luck.luau, scripts/vip-luck-balance.luau. Existing runners/catalog fixtures were updated for the new ID, count, disclosure and HUD window.

## Balance and interpretation

The final additional requirement is implemented as `free luck * VIP 1.25 * DoubleLuck 2 * Lucky charge 10`. This interprets the earlier “additive” wording as `1 + VipLuckBonus`, applied to the whole free layer. The ID-zero fixture overrides bundle implication. All DoubleLuck balance scenarios assume its wired ID and eligible policy.

[Current expected flushes and heavy-stacking consequences](vip-luck-balance.md) use the production sequential distribution. VIP multiplies total luck by 1.25, both permanent passes by 2.5, and a reviewed charge by another ten at every finite multiplier. Each check stops only at probability 1; earlier rare checks can suppress later items. Free source values and prices are unchanged. See [uncapped luck validation](no-luck-cap.md) for current pacing and checks.

## Validation

- Rojo build -o build.rbxl: passed.
- StyLua --check --verify --line-endings Windows: passed; all 30 changed/new Luau files use CRLF.
- All 23 standalone check-*.luau scripts: passed. The remaining check-audit.luau and check-ui-runtime.luau run inside their engine-mock PowerShell harnesses.
- check-audit.ps1: 381 passed, 0 failed; includes cache failure/expiry, bundle, ID 0, creator API ownership, owner test unlocks, stale review, cap/charge/free upgrade stacking, every-tier distribution equality and schema preservation.
- Targeted UI/HUD tests: passed; purchase review, policy expiry, bundle, pending ID, real displayed multipliers and charge cap.
- check-visuals.ps1 and check-world.ps1: passed, all six mesh modes.
- scripts/balance.luau: existing pacing targets and seeded replay passed.
- check-ui.ps1: passed, including the 13-window toast matrix and 972 viewport/layout cases. Paid-luck HUD/card tests and production-ID/Coming-soon tests pass.
- scripts/wave1-balance.luau: all three 200-seed conditional cohorts, independent odds, first sight, probability checks and seeded replay passed. scripts/vip-luck-balance.luau regenerated the expected-flush and stacking tables.
- Both PNG dimensions/RGBA and appearance at 512/128 px inspected. Phone pass-card rendering inspected using the existing offline raster approximation.

Selene was attempted but cannot run: this installed 0.31.0 build has no Roblox standard library or Roblox generation command, the same limitation already recorded in audit2-tools.md. No clean Selene result is claimed. Headless tests do not establish real published billing/PolicyService behavior or Roblox mobile rendering.

## Owner actions

See [the exact Hub descriptions and release actions](../monetization-catalog.md#permanent-paid-luck-release-contract-2026-10-07). Edit VIP and Ultimate Bundle descriptions; upload DoubleLuck_512.png and wire Assets.Icons.DoubleLuck. Review paid-random questionnaire/external sales settings and published eligibility/purchase/rejoin tests before release. [Official-source research](../research/vip-luck.md).
