# Monetary doubles and persistence (2026-10-07)

Decision: `Config/Economy.MaxAmount = 1e300` is the single monetary technical bound. It leaves eight orders of magnitude below binary64 overflow. This is an implementation choice, not a Roblox-documented DataStore maximum.

Sources checked:

- https://luau.org/syntax/ and https://luau.org/compatibility/ — Luau numbers are IEEE 754 binary64; integer precision is exact only through 2^53. Above that, approximate units are intentional.
- https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching — standard DataStores serialize numbers as JSON; Roblox advises against NaN and infinities and recommends JSONEncode for serialization diagnosis. No smaller finite-number ceiling is specified. This game uses standard profile DataStores, not OrderedDataStore values.
- https://create.roblox.com/docs/reference/engine/classes/HttpService#JSONEncode — engine JSON encoding API. Finite numeric JSON is the persistence format; no live cloud roundtrip at 1e300 has been verified by the CLI mocks.
- https://create.roblox.com/docs/reference/engine/classes/NumberValue — NumberValue stores a double-precision number; retain it for native coin leaderstats. Monetary sanitization must not reuse the exact-ID sanitizer.
- https://devforum.roblox.com/t/double-not-allowed-in-datastore/2770003 — search result concerns GetOrderedDataStore integer restrictions; full page was blocked by anti-bot verification. It is not evidence of a standard DataStore double limit.
- https://create.roblox.com/updates — checked platform updates; no documented alternative numeric representation was found. Do not infer an exact-integer guarantee from absence of a release note.
- https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt — paid grants remain pending until their durable receipt transaction succeeds. A full/unrepresentable wallet returns NotProcessedYet, preserves the saved quote and reports how to recover.
- https://rojo.space/docs/v7/getting-started/new-game/ — `rojo build -o build.rbxl` builds a binary place.
- https://github.com/JohnnyMorganz/StyLua and https://github.com/JohnnyMorganz/StyLua/releases — use Windows line endings and Luau syntax. Selene documentation at https://kampfkarren.github.io/selene/usage.html was inaccessible; local CLI help/config are used for validation.

Arithmetic policy: reject nonfinite inputs; saturate products before multiplication; round prices upward and wallets downward before strict affordability comparison. A debit too small to change a huge wallet charges a conservative representable step, preventing free purchases. Credits that cannot change a wallet defer without consuming a paid grant or pending ledger. Relative tolerance is for quote matching and approximate test comparisons, never permission to overspend.

The persisted income scale remains 6000 subcoins per coin. The ledger bound is 1e300 subcoins (about 1.67e296 pending coins); no migration or reinterpretation of existing saves occurs. Ordinary fractional accrual remains exact where binary64 can represent its subcoins. Technical saturation is the only remaining monetary ceiling. Time windows, exact inventory/counter/ID bounds, rate limits, level counts and progression prices are independent of this monetary limit.

Runtime availability: the Studio connector returned no connected instances, so engine JSONEncode/JSONDecode and a live standard DataStore roundtrip could not be executed. Headless save/rejoin tests verify the application's sanitizers and transactions, not Roblox's cloud serialization. Selene 0.31.0 is installed but its `roblox` standard library is absent; it fails before linting.
