# Passive display income

Implemented on `feature/income`; uncommitted as requested. Research: [timestamp and persistence findings](../research/passive-income.md).

Displayed copies earn `Value * 0.01` Coins/minute before the per-slot and per-player tier caps in `src/shared/Config/Income.luau`. Both online and offline time use server `os.time()`. Offline accrual is limited to 240 minutes per absence; pending storage is capped at 33,600 Coins per slot and 100,800 per player. Full storage stops earning; elapsed excess time is consumed, not banked for a later collect.

Each plot has one central **Collect** pedestal by the display row, with three primitive coins appearing at 1/10/100 pending Coins. Use F, gamepad Y or the native touch prompt. The small pending chip receives server updates every five seconds; successful durable collection uses the existing toast component. Collect transfers whole Coins across all slots, retaining fractions. This avoids charging the full UI refresh path for income ticks.

The ledger stores integer 1/6000-Coin units per slot plus a high-water timestamp. That serialization scale must not be changed without migration. Unknown/malformed fields default safely; finite oversized balances are capped. Missing timestamps start now, with no retroactive pre-feature award. Removed items and reduced display capacities retain already-pending earnings. Changes settle the old display/tier before mutation through the lease-gated `DataService:Get` path; saves settle too. Departure freezes its timestamp before waiting for a final save.

The no-argument `CollectIncome` remote validates ownership, a living character, finite distance <=10 studs and the current lease. Its bucket allows one request per five seconds. Collection rejects an already-running save, atomically debits pending/credits Coins and Earned, then saves before announcing success. Wallet/stat ceiling pressure retains uncollected units. Offline settlement runs inside the replay-safe lease-acquisition transform. Existing session tokens, save serialization, retries and expiry rejection remain intact.

## Balance evidence

`luau scripts/balance.luau` prints all tiers for 3 and 10 slots. A realistic upper showcase uses the most valuable copies from the floored expected drops over 60 minutes at the current tier and 75% flush uptime. It ignores acquisition/retention costs, so it overstates immediate availability. Runtime item Values (currently five times the old GDD table) and existing prices are used. No item prices, service awards or upgrade prices changed.

| Tier | 3-slot passive / active | 10-slot passive / active | Absolute cap / service-only active |
|---|---:|---:|---:|
| Basic | 1.91% | 1.91% | 20.00% |
| Dirty | 3.91% | 3.91% | 18.67% |
| Golden | 4.28% | 5.99% | 17.33% |
| Diamond | 4.04% | 7.03% | 16.00% |
| Radioactive | 2.22% | 3.86% | 14.67% |
| Demon | 1.15% | 2.14% | 13.33% |
| Galaxy | 0.55% | 1.08% | 12.00% |

The stronger absolute bound covers even 100 legacy slots containing retained jackpots. Active means 75% cooldown uptime with no boost. Even against guaranteed service-only earnings, passive stays below one third; the cap shortens that empty-wallet upgrade bound by at most one sixth. Existing legacy timing assertions and the 2,000-player cohort still pass (median Dirty 1.40 minutes); realistic display income reduces each expected stage duration by at most 6.6%. Stored offline earnings intentionally accelerate return visits and are excluded from empty-wallet timing comparisons.

## Changed files and validation

- Accounting/config: `src/shared/IncomeAccrual.luau`, `Config/Income.luau`, `Config/Remotes.luau`.
- Server: `Services/IncomeService.luau`, `Services/DataService.luau`, `init.server.luau`; only a small world hook plus new `World/IncomeDisplay.luau`. No Builders or MeshLoader edits.
- Client: `init.client.luau`, additive `UI/IncomeChip.luau`, four layout lines and one FlushPrompt filter so collection prompts cannot become flush targets.
- Checks: new `scripts/check-income.luau`; extended balance, audit, UI and world harness coverage.

Passed: all `scripts/check-*.luau` (audit/UI runtime through their PS1 bundlers); 35 audit scenarios; `check-ui.ps1` including seven safe-area layouts; `check-visuals.ps1` through all six `check-world.ps1` modes; `rojo build -o build.rbxl`; `stylua --check --line-endings Windows src scripts`; `git diff --check`. Headless phone portrait/landscape images were also inspected. The full primitive world stays within its part budget (worst plot plus drop: 352).

Selene was attempted but cannot run without the repository's missing `roblox` standard library. Live Studio multiplayer/DataStore/device QA was not available; headless mocks do not establish live backend durability. Existing crash/outage loss of unsaved progress remains (audit L3); this feature does not claim exactly-once durability across an indefinite backend failure.

Assumptions: use the requested displayed-item formula in place of the proposal's separate `2 * B_best` offline tank; add no second offline faucet. Display slots do not bypass the shared cap, including legacy capacities. Future purchasable display capacity would now have a bounded income benefit and must be described truthfully before release. Rewards, Auto-Flush, events, first-copy protection and display reservations retain their existing behavior.
