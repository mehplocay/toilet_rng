# Permanent/main merge validation

2026-10-06. File conflicts resolved without committing, aborting or switching away from the in-progress merge.

## Integration

- All seven conflict files have no markers: scripts/audit-economy-v2.luau, scripts/audit-rebirth.luau, scripts/audit-upgrades.luau, scripts/check-economy-v2.luau, scripts/check-income.luau, scripts/check-upgrades.luau, src/client/UI/HUD.luau.
- Permanent toilet tiers, upgrades, display capacity and exact occupied positions survive rebirth. Coin gates and fresh-flush requirements remain authoritative. Loose inventory and pending income reset under the incoming rules.
- Preserve main's 50% offline rate, away-window ledger, auto-flush anywhere/idle guard, chat/native player list, catalog/receipt security, admin tools and path speed boost. Conflicting numeric expectations use the new tier factors and retained offline rate. No security assertions removed.
- HUD idle resume replaces the manual action while paused and leaves Auto-Flush visible, avoiding the old extra row crossing navigation/hints on small screens. Luck percentages, upgrade levels and milestone UI remain. Inspected offline raster previews for 360x518 / 640x303 HUD and 390x722 upgrades/rebirth. These are headless approximations: [phone](permanent-previews/merged-idle-phone.png), [landscape](permanent-previews/merged-idle-landscape.png).
- src/shared/UpgradeRules.luau: cap reported/effective Offline Plus minutes to Config/Income's existing 24-hour limit at new L100. The regression checks L0..100, both entitlement states, exact half-rate credit and no replay.
- src/server/Admin/Mutations.luau: setting DisplaySlots L10 cannot create 13 ordinary slots; existing legacy capacity survives. Added persistence/gate coverage for extended tracks, display items and R15, plus real admin UI button tests for caps and rebirth.
- Paid checks cover CashBoost L0..100 and R0..15 with no passes, Double Cash, VIP and both. Maximum progression is 5.85x before passes; combined cash clamps to 10x. Actual sell/flush/display collection and quoted receipt replay tests verify no second multiplication. Luck remains independent of paid cash, capped at 10x with rare diminishing returns.
- Updated merge/offline design notes and [API research](../research/permanent-main-merge.md).

## Verification

| Check | Result |
| --- | --- |
| StyLua format + check, Luau syntax | 43 changed Luau files pass |
| rojo build -o build.rbxl | Pass |
| scripts/check-*.luau | All 23 run: 21 directly, check-audit/check-ui-runtime via PowerShell harnesses |
| check-audit.ps1 | 184 passed, 0 failed: 173 main + 8 permanent + 3 integration scenarios |
| check-ui.ps1 | Pass, including admin/milestones/away/idle; 972 layout cases |
| check-visuals.ps1 | Pass |
| check-world.ps1 | Pass: Empty, Ready, Mixed, Invalid, Scaled, Late |
| luau scripts/balance.luau | Full normal/casual/grinder cohorts and replay pass |
| Marker scan / git diff --check HEAD | No source markers or whitespace errors |
| Selene | Cannot start: configured roblox standard library missing |

Normal medians: Galaxy **36.43 minutes**, R1 **about 24 minutes**, R15 **95.67 hours**. Corresponding p90: 47.26 minutes, 0.52 hours, 133.84 hours. Incoming simulation policies retained: Galaxy defers rebirth; long cohorts rebirth at each coin gate. No live backend, Studio rendering or native device run was performed.

## Remaining Git limitation

Staging the seven resolved files failed: permission denied creating the linked-worktree index.lock outside the writable workspace. Git still reports seven UU paths despite clean resolved working files. The manager must stage those paths and other reviewed integration edits from a writable environment. No commit, push or merge abort was attempted.
