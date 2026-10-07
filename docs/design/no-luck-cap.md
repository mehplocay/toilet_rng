# Uncapped luck ? 2026-10-07

Branch: fix/no-luck-cap. No commit or push. No Creator Hub edits or publication.

## Implemented and removed limits

1. Removed Config/Upgrades.LuckCap = 10, the initial free-layer clamp, every factor clamp and every running-product clamp in UpgradeRules:Luck.
2. Removed the independent total-luck clamp and cap-config dependency in RollService.Distribution.
3. Removed Config/Monetization.LuckyLuckCap and both ceilings in LuckyService:Odds. A reviewed Lucky charge multiplies current total luck by ten even above the former boundary.
4. Removed Config/Rebirth.LuckBonusCap = 1 (an unused configuration ceiling); future configured bonuses above 1 are explicitly tested. Current reward numbers are unchanged.
5. Removed LuckCap/LuckCapped payload fields, the HUD's >=10 cap marker, upgrade cap/+900% copy, and obsolete cap expectations. Updated pass/product cards, odds/tooltip, tutorial, rebirth text, catalog and design/research documentation. Historical task briefs remain unchanged.

The formula is toiletLuck * (1 + luckUpgradeEffect + rebirthLuckBonus) * server * daily * eligibleVIP1.25 * eligibleDoubleLuck2 * reviewedCharge10. Existing additive/multiplicative rules, all source values, upgrade/rebirth content levels and all prices are unchanged. Speed, cooldown, money rules and charge-storage capacity are unchanged.

Only positive finite luck is accepted; NaN, infinity and actual multiplication overflow are rejected, never silently clipped to a finite ceiling. Per-item check = min(1, totalLuck / baseDenominator), with rare-first independent checks, stable ID ordering and unconditional Poop fallback. Every accepted flush awards one item. At total luck >=15,000,000, Cosmic Courtesy is certain and all later outcomes, including Celestial and Poop, have probability zero.

Paid sources still require the existing eligible, unexpired PolicyService result. Missing/error/restricted/expired answers fail closed. Odds tokens still become stale when source values or ownership change; each charged flush still needs review and atomic charge/item persistence.

## UI and saved profiles

HUD and upgrade cards show multipliers with significant digits/scientific notation; very large HUD values use two lines. The odds dialog uses true sequential outcome probabilities, 12-decimal percentage rounding with integer largest-remainder allocation so each full column totals 100%, and explicit 100% (certain). Subprecision nonzero outcomes also expose their raw percentage. Rarity aggregation corrects floating-point sum overshoot only at probability 1. All 47 rows wrap at 17px without truncation; Lucky-card rarity lists scroll at the same readable size.

No schema/version bump: saved source levels are already authoritative. Current saves retain Luck L50, R15, tiers, purchases and unused charges; luck recomputes immediately without clipping. Stale derived luck/cap fields are discarded. Existing pre-version content-level migration and malformed-number sanitization remain in force; no levels or charges are minted.

Primary implementation files: src/shared/UpgradeRules.luau, NumberFormat.luau, Config/{Upgrades,Rebirth,Monetization,Shop,Toilets}.luau; src/server/Services/{RollService,LuckyService,FlushService}.luau and Admin/Runtime.luau; src/client/UI/{HUD,LuckyOdds,UpgradeTracks,Passes,Rebirth,Tutorial}.luau. Regression changes include audit-no-luck-cap.luau, ui-no-luck-cap.luau, the audit/UI runners and existing luck-related assertions. Current source research: [official API and numeric findings](../research/no-luck-cap.md).

## Balance consequence

Production prices, source effects and cohorts are unchanged. Normal p50: Dirty 1.47m, Golden 3.01m, Diamond 6.13m, Radioactive 11.36m, Demon 19.60m, Galaxy 37.52m; R1 about 25m, R5 2.12h, R10 26.40h, R15 90.61h. The original toilet/rebirth acceptance ranges still apply.

| Archetype | R5 p50 / p90 hours | R10 p50 / p90 hours | R15 p50 / p90 hours |
|---|---:|---:|---:|
| Normal | 2.125 / 3.133 | 26.400 / 33.608 | 90.608 / 101.725 |
| Casual | 3.367 / 4.567 | 38.192 / 50.367 | 123.742 / 150.008 |
| Grinder | 1.850 / 2.542 | 24.150 / 29.392 | 84.483 / 93.317 |

**Explicit assumption / test adjustment:** removing the ceiling advances normal Cash L100 to 24.433h and Offline Tank L100 to 24.85h, against the former hard 25h lower bound. To preserve production prices and source values, only these two test minima now allow 5% early tolerance (23.75h); the nominal 25h goal and 45h upper bound remain. This is a changed acceptance bound, not an unchanged-test pass. No other balance target was relaxed.

Infinity Flush, Luck L50, R15, VIP, 2x Luck, and a fresh charged flush yield 333.5x. Adding daily x2 and server x2 yields 1334x. Quantiles use the actual sequential distribution:

| Luck | Outcome | Per-flush probability | 50% chance by | 90% chance by | Chance within 20 charged flushes |
|---|---|---:|---:|---:|---:|
| 333.5x | Any Secret | 0.081127967% | 855 flushes / 5.70m | 2838 / 18.92m | 1.6101% |
| 333.5x | Any Celestial | 0.273154233% | 254 / 1.69m | 842 / 5.61m | 5.3236% |
| 1334x | Any Secret | 0.324227623% | 214 / 1.43m | 710 / 4.73m | 6.2887% |
| 1334x | Any Celestial | 1.086793997% | 64 / 25.6s | 211 / 1.41m | 19.6316% |

These times assume sustained 0.4s cadence, a separately reviewed charge for **every** flush and constant boosts; actual review time makes them longer. They do not describe one charge lasting for the entire interval. Without rebirth, L50 + both passes + charge yields 261x. The rarest individual Secret (Cosmic Courtesy) reaches 50% after 31,176 charged flushes at 333.5x, or 7,794 at 1334x. [Full free/paid/charged tables](vip-luck-balance.md).

## Validation

- Server audit: 407 passed, 0 failed, including current/pre-version saves, future rebirth bonus above 1, full stacks, invalid factors, true overflow rejection, policy expiry and a certain-item charged flush persisted exactly once.
- All 26 standalone check-*.luau entrypoints passed; check-audit.luau and check-ui-runtime.luau execute inside their PowerShell harnesses.
- Extreme UI cases 1e3, 1e6, 1e12, 1e300 and near-maximum finite luck passed at all 12 viewports, including parsed percentages, integer sums of exactly 100%, certainty, HUD bounds and readable scrolling cards.
- Final check-ui.ps1 passed with all new extreme/scrolling-card cases integrated, plus 972 layout cases.
- balance.luau (including income-balance.Print()), Wave 1, all-archetype rebirth simulations, rebirth-balance.Print(), social-balance and the three-million-roll simulate.luau passed. The two changed L100 acceptance minima are documented above.
- Rojo build passed. Visuals and all six world modes passed. StyLua --check --verify --line-endings Windows src scripts passed, as did git diff --check.
- Automatic approval rejected cleanup of the generated .no-luck-* logs/scripts and preview directories with "blocked by policy", including explicit verified workspace paths. These untracked temporary artifacts remain; no tracked/user files were deleted.
- Selene was attempted but this installed build cannot load the missing Roblox standard library. No source lint result is claimed.
- docs/research/audit3-purchases.md was unreadable in this sandbox; its contents could not be checked.
- No live Roblox Studio/device/billing/PolicyService test. [HUD](no-luck-cap-previews/hud-extreme.png) and [certain odds](no-luck-cap-previews/certain-odds.png) are inspected headless approximations, not native screenshots.

Raw rerun outputs: [balance](no-luck-cap-results/balance.txt), [Wave 1](no-luck-cap-results/wave1-balance.txt), [rebirth runner](no-luck-cap-results/rebirth-balance.txt), [all-archetype rebirth](no-luck-cap-results/rebirth-values.txt), [social](no-luck-cap-results/social-balance.txt), [seeded roll simulation](no-luck-cap-results/simulate.txt).

## Exact replacement Creator Hub descriptions

The following text matches Config/Monetization and the catalog. Apply it manually in Creator Hub; this task has not changed Hub metadata.

### VIP

1.5x cash, +1 path speed step, +50% offline tank, daily chest, VIP hub pad, gold star, trail and sign trim. +25% luck, a permanent random-item odds boost. Multiplies with other luck sources without a total luck cap. Luck unavailable in restricted regions.

### 2x Luck

Permanent 2x luck: a random-item odds boost for rare items. Multiplies with other luck sources without a total luck cap. Unavailable in restricted regions. Review Info: all item odds before purchase.

### Ultimate Bundle

Includes all 15 other passes: Sparkle Trail, Star Tag, Custom Plot Color, Fast Flush, Double Cash, Auto Collect, Offline Plus, VIP, Rainbow Name, Confetti Reveal, Golden Name, Dance Pack, Toilet Glow, Companion and 2x Luck. Includes permanent random-item odds boosts: VIP +25% luck and 2x Luck. Luck sources multiply without a total luck cap. Luck unavailable in restricted regions. No consumables.

### Lucky Flush

1 single-use 10x luck charge. Each charge multiplies your current luck by 10 for one flush without a total luck cap. Each item check is at most 100%. Unavailable in restricted regions. Review all item odds before purchase and use.

### Lucky Flush 5-Pack

5 single-use 10x luck charges. Each charge multiplies your current luck by 10 for one flush without a total luck cap. Each item check is at most 100%. Unavailable in restricted regions. Review all item odds before purchase and use.

### Lucky Flush 20-Pack

20 single-use 10x luck charges. Each charge multiplies your current luck by 10 for one flush without a total luck cap. Each item check is at most 100%. Unavailable in restricted regions. Review all item odds before purchase and use.
