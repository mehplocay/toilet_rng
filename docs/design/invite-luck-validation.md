# Invite luck validation - 2026-10-08

Branch: feature/invite-luck. No commit, push or Creator Hub publication.

## Behavior and changed files

- SocialBoostRules separates group/friend coin factors from free x1.20 invite luck. UpgradeRules:Luck applies the free factor centrally, covering FlushService, LuckyService, server snapshots and shared balance callers. No roll-path yield or API lookup; no total luck cap.
- IncomeAccrual removes invite interval averaging from online and offline coin accrual. Config/SocialBoosts retains every reward value, duration and anti-abuse limit. SocialBoostService changes its award message only; qualification, lease guard, atomic award/save and dedupe are preserved.
- LuckyService adds invite factor/timer metadata to real odds and free-luck snapshots. UI/LuckyOdds, HUD, SocialBoosts and Passes disclose Invite luck with a countdown and invalidate expired review windows. Client countdowns consume cached server remaining time, so reopening the same snapshot cannot restart its timer. Admin Window labels the existing timer as luck and the coin factor as group/friends.
- Existing v1 Social.InviteExpires works as luck without changing schema, minting coins/charges/duration or altering reward history. Offline time continues to consume the timer.
- scripts/check-social, audit-social, new audit-invite-luck and ui-invite-luck cover qualified awards, cash separation, every tier/pass combination, true sequential odds, no cap/overflow, exact expiry, stale charge review, restricted/error/missing/expired policy, rejoin migration and unchanged sales/display/offline/commerce quotes. check-audit.ps1 and check-ui.ps1 bundle the new checks; ui-social expects the new button copy. social-balance prints separate coin/luck factors and rarest-item comparisons.
- Updated design/social-boosts, no-luck-cap and monetization; monetization-catalog; marketing-description and morning-report copy; research/invite-luck. No existing tutorial/hint text mentioned invite rewards, so no tutorial scope was added.

## Balance

Group + three friends: 1.265x coins and 79.05% fixed-rate coin-gate time, independently of invite. Group + eleven friends: 1.705x and 58.65%. Invite alone is 1.00x coins and 1.20x luck. Compared with the previous invite-coin implementation, the old 1.518x / 2.046x social coin stacks lose their invite factor; progression prices are unchanged.

For a fixed toilet, collection and other boosts, invite activation never changes service coins, per-item sale values, display rates, offline accrual or coin-pack quotes. Better random drops can indirectly improve later collection/sale value; that is not a direct coin-rate boost or a claim of identical end-to-end RNG pacing.

Expected flushes use actual rare-first probabilities, including failure of earlier checks. All modeled rolls assume the invite stays active; these are expectations, not guarantees within a 30-minute reward.

| Loadout | Item | Without invite | With invite |
|---|---|---:|---:|
| Basic, otherwise unboosted | Cosmic Courtesy | 15,000,000 | 12,500,000 |
| Basic, otherwise unboosted | Mystery (???) | 10,000,000.667 | 8,333,334.000 |
| Basic, otherwise unboosted | Infinite Occupied | 5,000,000.833 | 4,166,667.500 |
| Max free + server + daily + VIP + 2x Luck | Cosmic Courtesy | 112,443.778 | 93,703.148 |
| Same + reviewed Lucky charge | Cosmic Courtesy | 11,244.378 | 9,370.315 |

The first rarest outcome improves by exactly 16.6667% in expected flushes in these unsaturated cases. Later rarest outcomes improve by almost the same amount (slightly less due to earlier checks). Full comparisons and raw pacing outputs are in [invite-luck-results](invite-luck-results/social-balance.txt).

Baseline balance: Galaxy p50 is 37.52 minutes normal, 60.19 casual, 32.28 grinder. Rebirth 15 p50 is 90.61 hours normal. The no-invite baseline uses unchanged source values/prices and passed the existing pacing/replay targets. Its complete output exactly matches docs/design/no-luck-cap-results/balance.txt after newline normalization.

## Validation

- Passed: `rojo build -o build.rbxl`; StyLua formatting/check with `--line-endings Windows`; `git diff --check`.
- Passed: all 27 standalone `scripts/check-*.luau`. The two embedded entries (check-audit.luau and check-ui-runtime.luau) run through their PowerShell wrappers.
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-audit.ps1`: **431 passed, 0 failed**, including the new server and UI invite regressions.
- Passed: focused UI bundle using the unchanged production harness and current sources: actual roll odds, 12 viewports, free/restricted HUD and local expiry.
- Passed: the prescribed PowerShell invocations of check-visuals.ps1 and check-world.ps1.
- Passed: balance.luau, rebirth-balance.Print(), income-balance.Print(), vip-luck-balance.luau, social-balance.luau and wave1-balance.ps1. Complete outputs are in [invite-luck-results](invite-luck-results/social-balance.txt).
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-ui.ps1`, including the new invite checks and 972 layout cases. Earlier attempts terminated with Luau exit -1; the final run completed successfully with the unchanged harness/runner plus the requested new test inclusion. No cause for the earlier native exits is claimed.
- Selene 0.31.0 was attempted; it cannot load the repository's roblox standard library and has no Roblox generation subcommands. This is a previously documented environment limitation. No clean lint result is claimed and no lint rules were disabled.

Headless mocks exercise real production rules/services/UI; no live Roblox invitation, purchase or Creator Hub description publishing was performed. Owner must publish the updated experience description separately.
