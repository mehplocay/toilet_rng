# Rebirth cash layers: numeric and platform review

> Historical cash/balance snapshot. The 2026-10-07 owner decision removes all cash multiplier caps; see [current uncapped contract](../design/no-cash-cap.md). Earlier measurements below are retained as dated evidence, not runtime limits.

Reviewed 2026-10-06 for feature/rebirth-balance.

- Luau has one IEEE-754 double number type; integers through 2^53 are exact. Keep both wallet/lifetime coins and persisted subcoins at 9e15, separately. Clamp before potentially oversized multiplication; preserve the 6000-unit scale and corrected whole-coin division. Source: https://luau.org/syntax/ and https://luau.org/compatibility/ . The Roblox precision discussion agrees: https://devforum.roblox.com/t/difference-between-a-number-value-and-int-value/1525821/2 .
- UpdateAsync callbacks can run repeatedly and cannot yield. A failed response is not evidence that a write never committed. Preserve the existing immutable replacement, lease checks and saved generation; this retune adds no datastore calls or entitlement API changes. Source: https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore and https://create.roblox.com/docs/cloud-services/data-stores .
- Reviewed the current platform update index and datastore access announcement; no change to the numeric or callback assumptions above was identified. Do not claim live service behavior from the headless harness. Sources: https://create.roblox.com/updates and https://devforum.roblox.com/t/datastores-access-and-storage-updates/3597255 .
- Rojo build serializes the project; StyLua supports Luau and check mode. Use the installed CLI help to verify flags. Sources: https://github.com/rojo-rbx/rojo and https://github.com/JohnnyMorganz/StyLua .

Contract: min(40, free factors including the display toilet factor) times min(3, all verified paid cash factors). Cash Boost and rebirth bonuses add before the toilet factor. Milestone titles currently have no numeric bonus. Paid factors are enumerated from catalog cash entries, so future paid cash passes share the cap. Daily coins keep their existing paid-only rule; starter grants, ledger collection and quoted receipts are never multiplied again.

At 120x: Secret = 12M coins/s per slot, ten-slot player cap = 120M coins/s = 720B subcoins/s; 100 legacy slots share that same cap. The largest unscaled legacy sum is 7.2T subcoins/s, safely below 9e15. Storage saturates at 9e15 subcoins = 1.5T coins. The largest configured per-copy sale is 60B coins; a million-copy request would exceed exact range, so reject against remaining room before multiplying. Maximum configured service award is 540K coins. No RNG, luck, speed floor, persistence schema or ledger scale changes.
