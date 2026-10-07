# Purchase UI and policy sync (2026-10-07)

- Policy lookup yields and must be wrapped in pcall. Only an explicit `ArePaidRandomItemsRestricted == false` permits Lucky; failed/missing/restricted/expired results fail closed. Keep a verified, unexpired cache during refresh, renew before its deadline, and sync after lookup completion.
  https://create.roblox.com/docs/reference/engine/classes/PolicyService
  https://create.roblox.com/docs/production/monetization/paid-random-items
- Current Roblox policy guidance requires disclosure of every possible outcome before paid random item purchase, and eligibility enforcement through PolicyService.
  https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622/1
- `PromptProductPurchaseFinished` only reports prompt closure. It must never grant benefits; only durable `ProcessReceipt` processing does so. Closure should release and sync UI prompt state, irrespective of receipt/closure ordering. `UserOwnsGamePassAsync` and server gamepass completion provide verified ownership; preserve verified positive grants during refresh.
  https://create.roblox.com/docs/reference/engine/classes/MarketplaceService
- Checked the release notes index; no accessible entry established a changed contract for these APIs. Use the current Engine API reference above as the contract.
  https://create.roblox.com/docs/release-notes
- Rojo supports `rojo build -o build.rbxl` for binary places; StyLua supports Windows line endings; Selene checks the configured Roblox library.
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua
  https://kampfkarren.github.io/selene/cli/usage.html
