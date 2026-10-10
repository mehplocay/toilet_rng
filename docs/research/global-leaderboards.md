# Global leaderboards (Task 64)

Checked 2026-10-10 against current official documentation.

## APIs and limits

- OrderedDataStore stores integers, offers descending `GetSortedAsync(false, pageSize)` and `GetCurrentPage()`, and does not support metadata/versioning. Each board gets its own store, keyed by `tostring(UserId)`.
  https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore
- Page size is 1–100. Current default server budgets: OrderedList 5 + 2/player/min, OrderedWrite and OrderedRemove 30 + 5/player/min; StandardRead/Write 60 + 40/player/min. Universe limits also apply. Calls can fail or throttle; protect them with pcall. An error does not prove that a write did not commit.
  https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
- Modern request types replace legacy names. **OrderedList budget introspection always returns 0**; do not gate sorted reads on that value. Implementation uses a three-token local bucket replenished every 20s, including retries. Other operations check their modern budgets; standard requests leave ten requests available for profile persistence. Three top reads run every 90s, each fetching only the board's actual row count. Failures retry at most three times with 2s/4s backoff.
  https://create.roblox.com/docs/reference/engine/enums/DataStoreRequestType
  https://create.roblox.com/docs/reference/engine/classes/DataStoreService
- Studio requires a published experience and Security → Enable Studio Access to API Services. There is no documented server-script-readable toggle. A successful read-only probe enables this service's writes; failed probes leave local fallback active. Studio uses `ToiletRNG_Studio_Leaderboards_v1_*`; live uses `ToiletRNG_Leaderboards_v1_*`. NoPersistence profiles never publish.
  https://create.roblox.com/docs/cloud-services/data-stores
- `Players:GetNameFromUserIdAsync` yields and can fail. Cache usernames across boards for an hour and failed lookups for five minutes; online rows use live DisplayName. Lookups run only in the background reader, never in rendering.
  https://create.roblox.com/docs/reference/engine/classes/Players#GetNameFromUserIdAsync
- Platform updates reviewed: datastore access/storage announcement, current docs above take precedence over historical budget tables; the removed six-second key cooldown is not used as a scheduling assumption.
  https://devforum.roblox.com/t/datastores-access-and-storage-updates/3597255/
  https://devforum.roblox.com/t/removal-of-6s-cool-down-for-data-stores/2436230

## Encoding and consistency

All three indexes use `floor(log(1 + value) * 1e6)`. This is monotonic (nondecreasing), finite for every nonnegative finite binary64 number and at most about 710 million, safely below both binary64's exact integer boundary and signed 64-bit limits. Negative, NaN and infinite values are rejected. Quantization can tie nearby scores; exact values then sort descending with UserId ascending inside the fetched top page. As with the requested log encoding, ties at the top-N cutoff can omit a slightly higher exact value in the same bucket; strict injective ordering of all binary64 values into this finite integer range is impossible. No gameplay cap is introduced. Existing LeaderboardStats sanitization remains authoritative (including its existing coin rounding and flush counter rules); Rarest always comes from the item catalog, never a supplied chance.

The regular `*_Details` store holds a minimal sanitized profile (Coins, Stats, Admin.Touched, UpdatedAt, Token), retaining the actual binary64 ranking values and item ID instead of decoding an approximation for display. Metadata publishes with UpdateAsync before ordered indexes. A server timestamp fences delayed old-server snapshots. An uncached read after index writes detects a handoff during yielding requests and reconciles to the newer publication. UpdateAsync checks both StandardRead and StandardWrite budgets. Readers validate against LeaderboardStats and require the stored index score to match the exact value's encoding. Missing/partial entries are skipped; API errors switch that board to local ranking until a successful poll. Successful results cache offline players, merged by UserId with live server profiles on the existing world refresh. Live balances override cached ones even after spending coins.

API sources for fencing and fresh reads:
https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow
https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore#UpdateAsync
https://create.roblox.com/docs/reference/engine/classes/DataStoreGetOptions

The existing `Admin.CountAdminProfilesInRankings` flag is honored unchanged (currently true in this checkout). When false, touched profiles publish a persistent metadata exclusion and remove all three index keys. Their live IDs also mask cached old entries. Changing this flag to false excludes them without new ranking rules.

Changed profiles publish at most once per 90s; a final immutable snapshot is queued on leave/shutdown. Jobs serialize per UserId; shutdown waits up to 25s independently from profile saving. The profile Close hook does not yield. Retries are bounded; failed writes remain dirty for the next periodic attempt. Leaderboards are eventually consistent, not the source of truth for profiles. Separate stores cannot commit atomically; abrupt termination/backend failures may hide a row until a later publication. Old offline profiles first enter these new stores when they next join; there is no bulk migration. Timestamp fencing assumes Roblox's server clock across servers; profile session locks still protect player saves. An ordered operation interrupted before reconciliation can leave an index mismatch, hidden instead of showing the wrong exact value.

## Tool validation references

- Rojo binary build: https://rojo.space/docs/v7/getting-started/new-game/
- StyLua Luau formatting: https://github.com/JohnnyMorganz/StyLua
- Selene CLI: https://kampfkarren.github.io/selene/cli/usage.html
- Luau math library: https://luau.org/library

Tests use injected stores, budgets, clock, scheduler, retries and names; no production API requests occur during audits. Owner acceptance: publish to a test experience, enable Studio API access there, test two live servers with different users, then verify an offline user's row after the 90s poll. Live servers need no Studio toggle.

## Checkout validation

- `check-global-leaderboards.ps1`: all 11 fake-store tests passed, including real adapter Studio gating, fallback, huge values, retries, partial writes, close-hook isolation and two server-handoff races.
- `check-audit.ps1`: 442 passed, zero failed.
- `check-visuals.ps1` and `check-world.ps1`: passed, including actual hub row/scope rendering of an offline entry and all six world fixture modes.
- `rojo build -o build.rbxl`, StyLua check and git diff whitespace check: passed.
- `check-ui.ps1`: invoked normally but exited with `UI runtime checks failed` without a specific assertion in its captured output. A second invocation using the same script with only `--codegen` removed ran for several minutes; many UI suites passed, but it did not complete and was stopped after reaching `PASS auto HUD: far confirmed cycles pulse on`. No UI production modules were changed. Standalone mobile HUD and UI layout checks passed (972 viewport cases). Full UI validation remains open.
- Selene attempted; blocked by missing Roblox standard library (`std = "roblox"`); its generation command failed for the same reason.
- Already on `feature/global-leaderboards`. Git staging failed because the sandbox cannot create the worktree's `index.lock`; changes remain uncommitted. No push attempted.
- Live Roblox cross-server acceptance was not performed from this sandbox.
