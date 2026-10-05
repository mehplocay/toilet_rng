# Audit 2: passes, replay and future receipts

Checked 2026-10-05.

- [Official passes guide](https://create.roblox.com/docs/production/monetization/passes) uses server-side `UserOwnsGamePassAsync` and `PromptGamePassPurchaseFinished`. Passes are persistent entitlements. The guide also records the May 30, 2026 removal of cross-experience pass sales; use passes belonging to this experience when IDs are configured.
- [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService): developer-product completion must use `ProcessReceipt`, not a prompt-close signal. With no receipt callback purchases can be acknowledged without a grant. Receipt delivery can repeat/concur across servers; `NotProcessedYet` does not cause periodic time-based retries.
- [June 2026 replay report, with Roblox staff response](https://devforum.roblox.com/t/users-are-able-to-call-promptgamepasspurchasefinished-with-waspurchased-true-multiple-times/4663387): repeated completion for an owned pass is expected. Never infer another payment or mint consumable currency from each callback. Older community claims that the event is impossible to repeat are insufficient.

Current four passes have ID zero, no products exist, and paid luck is disabled. Retained monotonic entitlement merging and departure checks. Added idempotent completion side effects and a receipt callback that always defers unimplemented products. This is a guard, not a product implementation: before selling products, persist PurchaseId dedupe and the grant atomically, then acknowledge only after durable success. A mock event is not evidence of a platform purchase.
