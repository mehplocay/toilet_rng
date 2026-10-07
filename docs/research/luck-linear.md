# Linear luck and disclosure research (2026-10-06)

- Luau standard library: https://luau.org/library/ documents `math.min` and numeric probability operations. Keep finite, positive luck validation and keep total luck uncapped when calculating `min(1, luck / odds)` for every non-fallback check.
- Roblox Random reference: https://create.roblox.com/docs/reference/engine/datatypes/Random describes the existing uniform generator. No RNG API or seeding change is needed; keep separate rare-first checks and unconditional Poop fallback.
- Creator Hub paid random items: https://create.roblox.com/docs/production/monetization/paid-random-items requires actual numerical outcome percentages before purchase and disclosure of luck effects. Keep `LuckyService:Odds` sourced from the same `RollService.Distribution` as gameplay. Inference from the sequential algorithm: an item's final probability is its check multiplied by the failure probabilities of all preceding checks; it is not simply its base outcome multiplied by luck. Exact item and rarity distributions sum to one; the UI retains its existing precision and rounding notice.
- Current platform clarification, May 26, 2026: https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622 explicitly includes luck boosts and requires per-item disclosure plus policy eligibility. Existing fail-closed PolicyService restrictions and review-token validation stay intact.
- Tool references: https://github.com/rojo-rbx/rojo and https://github.com/JohnnyMorganz/StyLua . Use local `rojo build -o build.rbxl` and StyLua formatting/checks; no tool-version migration is needed for this arithmetic change.

No API additions, paid-cash formula changes, or client authority changes are involved.
