# Index rewards and safe selling

Checked 2026-10-05 before implementation.

- [Creator Hub: client/server security](https://create.roblox.com/docs/scripting/security/client-server-boundary): validate types, values, context and progression on the server; use server token buckets. ClaimIndexReward accepts only a known config ID; server lifetime Collection determines eligibility. Sell checks retained/displayed counts again on the server.
- [RemoteEvent reference](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent): OnServerEvent supplies the sending Player; do not accept a client-supplied owner or reward amount.
- [GlobalDataStore reference](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore) and [data stores](https://create.roblox.com/docs/cloud-services/data-stores): UpdateAsync callbacks can run again and cannot yield. Migration only constructs sanitized data; it never awards Stamps. Claims mutate marker/grant together without yielding and use the existing session-locked Save before returning success.
- [DevForum repeated UpdateAsync discussion](https://devforum.roblox.com/t/updateasync-fires-multiple-times/3069656) and [callback repetition report](https://devforum.roblox.com/t/updateasync-very-rarely-calls-the-transformfunction-twice-on-different-versions-of-stored-data/1130596/1) reinforce retry testing. Official API reference is authoritative; no callback side effects were added.
- [GuiButton](https://create.roblox.com/docs/reference/engine/classes/GuiButton) supports Activated for mouse/touch/gamepad; [ScrollingFrame](https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame) supports AutomaticCanvasSize. Reuse existing Components and Interactable styling, with scrolling rewards and rarity tabs.
- [Release notes](https://create.roblox.com/docs/release-notes) checked, but its web extraction contains no usable release entries. No release-specific new API behavior is assumed; current reference contracts above are used.
- [Luau library](https://luau.org/library/) checked for math/table functions; reject NaN/infinity and sanitize nonnegative integer counts.
- [Rojo project build documentation source](https://github.com/rojo-rbx/rojo.space/blob/master/docs/getting-started/new-game.mdx) and [StyLua](https://github.com/JohnnyMorganz/StyLua) checked for build and formatting. Direct Rojo commands page was unavailable to the web reader; local CLI help verifies flags.

## Scope and tuning assumptions

- “Coins/luck-free” means index rewards grant neither Coins nor luck. Total milestones use progression.md exactly: Stamps, earned display capacity and cosmetic ownership. Rarity completion amounts are provisional 2/3/5/8/10/15/20/25 Stamps, in Config/IndexRewards. No world rewards/pages until worlds ship.
- Only the 11 shipped items count. Milestones above that count stay hidden, not rescaled; Founding Flush is the original 11-item completion reward. Earned claim IDs survive future denominator growth.
- Aggregated inventory has no per-copy identity: one retained copy represents the automatically locked first copy; displayed copies overlap that protection. No manual last-copy unlock is exposed in this task. A legacy sold-out discovery remains discovered and claimable; migration never manufactures replacement inventory.
- Cosmetic rewards persist in IndexCosmetics and are shown as claimed unlocks in My Collection. Equipping/rendering titles/trophies and a Stamp shop are separate features; no placeholder asset IDs are used. Stamp balance is persisted for the future deterministic catalog.
- Existing session lease/autosave semantics remain. Claim marker/grant share one saved profile; no external reward side effects. Studio must verify live saves/rejoins and failure handling, concurrent client requests, touch layout and earned pedestal capacity.

## Verification

`scripts/check-index.luau` covers sold-out lifetime discoveries, malformed/default data, reload sanitization, claim deduplication, expanded content denominators, Stamp/coin limits, earned-slot monotonicity, cosmetic ownership, displayed/first-copy overlap, single/all duplicate sales and the actual remote handler with rate limits and failed saves. All `scripts/check-*.luau` pass. Changed Luau files pass StyLua; `rojo build -o build.rbxl` passes. Selene is installed but cannot run because the configured Roblox standard library is missing. No Studio tests were performed.
