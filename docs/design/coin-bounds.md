# Coin bounds: technical limit, not progression tuning

2026-10-07, `fix/raise-bounds`. No commit or push. Source of truth: `src/shared/Config/Economy.luau`, `MaxAmount = 1e300`.

| Bound / consumer | Previous limit | New limit |
|---|---|---|
| Rebirth / Upgrades / Income `MaxBalance` | 9e15 coins | 1e300 coins |
| DataService wallet and LeaderboardStats Earned / coin rankings | 9e15 | 1e300 |
| Native player-list wallet sanitizer | 9e15 | 1e300 |
| SafeInventory per-item sale value, batch room, service awards | 9e15 | 1e300 |
| EconomyService toilet affordability and UpgradeRules cost curves | No shared overflow-safe policy; wallet limited to 9e15 | Rounded strict affordability, safe curves through 1e300 |
| CashMath default product / paid cash factor | ~1.7976931348623157e308 | 1e300 (shared safe bound) |
| Income slot rate caps, per tier | 6M–1.95B coins/minute | 1e300 for every tier; aggregate subcoin rate bound applies |
| Income player rate caps, per tier | 60M–19.5B coins/minute; legacy plots shared ten slots | 1e300 for every tier; legacy slots earn individually |
| SlotPendingCap / PlayerPendingCap | 37,440,000,000 / 374,400,000,000 coins, scaled by bonuses | 1e300; no bonus-dependent storage restriction |
| MaxLedgerUnits, online / offline pending and offline report | 9e15 subcoins | 1e300 subcoins |
| CoinGrantMax, paid pack quotes / quote sanitizer / receipt credit / VIP chest | 1B coins | 1e300 technical bound; no product design maximum |
| VIP pad grant | 10,000 coins | 1e300; existing 10-coin floor |
| Daily reward schedule products and daily credit / preview | 9e15 credit; unchecked schedule product | 1e300 |
| Rebirth starter grant / receipt / VIP / Studio grant wallet and earned room | 9e15 | 1e300 |
| Owner admin SetCoins / AddCoins / Pending inputs and profile import numeric validation | 1e12 input / 9e15 imported number | 1e300; server authorization and validation retained |
| Coin audio amount normalization | 9e15 | 1e300 (pitch still has its existing audio limit) |
| Shared HUD / cards / index / world / popup / admin formatting | Suffixes through Dc, scientific `e+NN` thereafter | Same familiar suffixes, compact `1.23e45` through the technical bound and beyond for finite display inputs |

Packs use the existing display rate with its multipliers already applied: Mini ×600, Small ×3,600, Large ×21,600, Huge ×86,400. Quotes floor to whole coins, with a floor of 100. For example, at 265.2M coins/s they show 159.1B, 954.7B, 5.7T and 22.9T, alongside the duration on each card. Only values that actually reach the technical bound can converge there. Zero/very low income can also share the required 100-coin floor.

Saved quotes remain authoritative across income changes, rebirth and rejoin. New purchases are refused when room is insufficient. A paid receipt that cannot fit returns `NotProcessedYet`, retains its quote and receipt identity, and tells the player to make room and rejoin. Grants are never clipped to remaining wallet room. Unquoted external receipts retain the existing processing-time-rate behavior.

Precision policy: ordinary balances and subcoin tails remain exact within binary64 precision. Above 2^53, exact integer units are deliberately relinquished. Affordability floors balances and ceils prices, then compares strictly; tolerance never authorizes insufficient funds. If a price is too small to change a huge wallet, a conservative representable step is charged. A tiny collect that cannot debit its source returns zero. Approximate conversion dust is consumed only at large magnitudes; exact small tails remain pending. Lifetime Earned may round away tiny statistical increments; this does not credit extra wallet money.

The ledger retains 6000 subcoins per coin, so 1e300 ledger units represent approximately 1.6667e296 pending coins. This is a derived technical limit, not another configured cap. Admin Pending rejects coin amounts beyond representable ledger room. Online/offline accrual, sanitization and reporting use the same ledger limit. Offline duration remains eight hours at base, up to the existing 24-hour maximum at its existing half-rate; this task changes monetary bounds, not time benefits.

Audited but retained: exact inventory/collection/flush counters, receipt/user/sequence IDs and timestamps (their existing 9e15 or narrower limits), stamps, Lucky charge capacity, request budgets, display capacity, upgrade/rebirth level counts, uncapped luck stacking and speed/cooldown limits and all catalog progression values. Items and toilets have values/prices, not separate monetary ceilings to retune. The price and pacing tables are unchanged.

`check-coin-bounds.luau` covers 101 magnitudes through 1e300 and formatting through 1e303; the server audit covers huge persisted quotes, all four receipt products, deferral/retry/deduplication, admin, toilet purchases, VIP pad and daily/VIP chests. The UI harness covers distinct pack amounts and duration text at all 12 existing viewports, plus huge wallet, pending, shop, popup, rebirth and admin fixtures.

## Validation

- `rojo build -o build.rbxl`: passed.
- StyLua, Luau syntax, Windows line endings: all changed/new Luau files passed `--check`.
- All 24 standalone `scripts/check-*.luau` entry points: passed. `check-audit.luau` and `check-ui-runtime.luau` run through their required PowerShell harnesses.
- `scripts/check-audit.ps1`: 377 passed, 0 failed.
- `scripts/check-ui.ps1` with Luau `--codegen -O2`: passed, including five huge-value fixtures at all 12 viewports and 972 layout cases. The new isolated huge-coin UI suite also passed.
- `scripts/check-world.ps1`: all six modes passed; it runs `check-visuals.ps1` in Empty, Ready, Mixed, Invalid, Scaled and Late modes, plus world/layout checks.
- `luau scripts/balance.luau`: passed. [Complete output](coin-bounds-balance.txt) is byte-identical to the captured pre-change baseline (SHA-256 `C004019FD190C673C9A0EE1E819EA1AF529197E3E9AEBBE3C800D217BB46B9D4`). No pacing target or price table was retuned. A redundant optimized repeat was stopped after the complete ordinary run matched the baseline.
- `wave1-balance.luau` and the `Print()` entry points of `rebirth-balance.luau` / `income-balance.luau`, with `--codegen -O2`: passed. Normal R15 remains 98.53h p50 / 111.79h p90.
- `git diff --check`: passed. No commit or push.

Limitations: Selene 0.31.0 cannot lint because its `roblox` standard library is missing. Headless geometry checks do not establish native-device font rasterization or a live DataStore roundtrip; no Studio is connected. See [numeric sources and limitations](../research/coin-bounds.md). Existing exact counter/ID limits and offline time windows intentionally remain separate from monetary bounds.
