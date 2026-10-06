2026-10-06 follow-up: [Permanent economy](economy-v2.md) and [coin-gate rebirth](rebirth.md) supersede the reset/timing/upgrade limits in this historical merge report. Commerce receipt/pass preservation and paid caps remain unchanged.

# Income-first, admin and path/catalog merge

2026-10-06. Resolves the existing merge into main without committing or aborting it. This note supersedes conflicting historical branch-specific counts and tuning statements in the linked design notes.

Working files contain no conflict markers. Staging was attempted but Git could not create `C:/Users/mehme/Toilet rng/.git/worktrees/toilet-balance/index.lock` (permission denied outside the writable workspace). Consequently the five conflict paths remain `UU` in the index; the manager must stage the resolved files and new integration fixes before completing the merge. No commit, push or merge abort was performed.

## Merged economy and rewards

All [income-first v2](economy-v2.md) item values, toilet/upgrade prices, rarity rates, abbreviations, 3,300-flush rebirth threshold and numeric bounds remain. Rebirth retains every occupied display at its original slot, including sparse coin-bought slots; it resets pending income and resumes at Basic rates with retained bonuses. Owner admin, rare reveal, audio and upgrade functionality remain registered and tested.

Cash for service, sales and new passive income is `min(10, (1 + cashUpgradeBonus + rebirthBonus) * DoubleCash * VIP)`. Double Cash is 2 and VIP is 1.25 when verified, otherwise 1. Current maximum progression plus both passes is 9x; 10x is the configurable safety cap. Paid luck stays disabled. Collection and Auto Collect transfer already-boosted subcoins and never apply cash again. Product quotes and VIP chests already use boosted display rates, then clamp to 100..1B coins; wallet credit does not multiply them again.

Ordinary daily rewards deliberately retain Config/Rewards' separate tier schedule: Basic 25..250 coins, Galaxy 1,600..16,000 coins across seven days. Both passes give floored 2.5x amounts (Basic 62..625; Galaxy 4K..40K). Cash upgrades/rebirth do not multiply these daily rewards, nor do large display rates feed their calculation. This preserves both branches' tuning and keeps daily claims bounded at the new economy scale. Server and UI use the same schedule/factors. Rejected wallet/Earned overflow leaves the day, streak and luck expiry untouched.

Wallet and Earned each remain at most 9e15 **coins**. The complete passive ledger remains at most 9e15 **subcoins**, or 1.5T coins, even with all passes/upgrades/rebirth. Offline Plus doubles the 8..12-hour allowance to 16..24 hours, but storage limits still apply. Maximum paid/offline saves preserve the final fractional subcoin and cannot credit it twice.

## Integration corrections

- The audit runner includes economy, all owner-admin cases, catalog/path cases and four new merge cases. UI runs economy and catalog checks together; world/visual bundles load NumberFormat, Admin and paid dependencies together. The product quote fixture now expects the shared compact text `4.3K Coins`, while the remote still sends the exact 4321 quote.
- Admin Speed now publishes the absolute override used by PathBoostService and clears it when its lease expires. Initialization during an active admin override retains the unmodified speed baseline, so it cannot become the permanent base. Both startup orders are tested.
- Owner Reset/Import retain the current account's commerce data: verified passes, AppliedSlots, receipt history, saved quote, path expiry and VIP day. Reset still clears progression and saves its backup; imports still replace sanitized test progression. Old exports cannot rewind purchase deduplication or reopen today's VIP chest. External DataStore rollback remains outside this guarantee.

## Verification

- 140 audit scenarios pass (116 main cases, 20 incoming catalog/path cases, four merge cases).
- All 21 standalone `scripts/check-*.luau` pass; the other two run through the audit/UI PowerShell harnesses. Daily tests cover every day/tier/paid combination at exact wallet and Earned ceilings and one-coin overflow.
- UI including 972 layout geometries, visuals and all six world modes pass. Rojo build and StyLua checks pass.
- `scripts/balance.luau` passes all v2 targets with paid modifiers OFF: normal Galaxy p50 89.37 minutes, first rebirth 61.94, second run 50.70. Retaining exact display slots slightly accelerates the second run (previous 50.76); no base economy retuning was needed. Casual second run is 119.17 and grinder 39.09 minutes.
- Selene was attempted but cannot load the configured `roblox` standard library. No lint pass is claimed. Tests are headless; no live Studio, DataStore or real billing validation was performed. Catalog IDs remain disabled at zero.
