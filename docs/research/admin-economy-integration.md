# Admin income capacity integration

Checked 2026-10-06.

- [Roblox numbers](https://create.roblox.com/docs/luau/numbers) documents Luau's double-precision numbers. The [Luau compatibility reference](https://luau.org/compatibility/) specifies exact integers through 2^53. Keep the existing 6000 subcoins per coin and 9e15 ledger ceiling; wallet limits and multiplied income capacity are different bounds.
- Admin Pending and IncomeCap must use IncomeAccrual.StorageUnits, the same capacity calculation used by settlement and sanitization. Multiplying the raw coin capacity by Cash Boost/rebirth/Offline Tank can exceed the ledger ceiling. Reject overflow before saving rather than reporting success for a clipped balance.
- The added audit reproduces the clipped-success bug at maximum upgrades/rebirth, then checks atomic rejection, exact slot replacement, persistence and collection conservation.
- [StyLua usage](https://github.com/JohnnyMorganz/StyLua#usage) supports explicit Luau file paths; PowerShell scripts are outside its formatting syntax. [Selene Roblox setup](https://kampfkarren.github.io/selene/roblox.html) requires Roblox definitions; this installed binary still cannot find the configured standard library.
- [Rojo's official build guide](https://github.com/rojo-rbx/rojo.space/blob/master/docs/getting-started/new-game.mdx) supports `rojo build -o build.rbxl` for a binary place. The actual merged project builds successfully.

The audit/UI entry-point Luau files require their existing PowerShell source bundlers and engine doubles. Running those files alone does not initialize the harness.
