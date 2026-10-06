# Permanent/main integration review

2026-10-06. Public primary sources checked for the merge:

- https://create.roblox.com/docs/ui/size-modifiers and https://create.roblox.com/docs/reference/engine/classes/UIScale: constraints override layout sizing; UIScale multiplies absolute sizes. Keep the existing safe-area geometry and check actual constructor bounds. The idle-resume action now occupies the manual-flush area while paused, leaving Auto-Flush visible without an extra overlapping row.
- https://devforum.roblox.com/t/uiscale-causes-weird-behaviour-with-uilayout-absolutecontentsize-properties/1644122: the engine reply explains that absolute sizes include scaling while authored Size/CanvasSize do not. No new scaling workaround is introduced.
- https://create.roblox.com/docs/production/monetization/developer-products and https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing: server ProcessReceipt remains the purchase-grant authority. Preserve receipt identity, atomic persistence and replay tests; only new progression expectations change.
- https://create.roblox.com/docs/reference/engine/classes/TextChatService: default channels are created at runtime, and system messages are client-facing. Keep main's default-channel project configuration, delayed-channel handling and native PlayerList behavior.
- https://create.roblox.com/docs/release-notes/release-notes-678: historical default-chat startup UI fix; no new dependency on startup timing. Existing retry tests remain required.
- https://rojo.space/docs/v7/getting-started/new-game/: `rojo build -o build.rbxl` builds the binary place; retain the installed project/tool format.
- https://github.com/JohnnyMorganz/StyLua/discussions/924: formatter syntax must support Luau. Use the installed StyLua with `--syntax luau` on changed Luau files.

Integration decisions: permanent toilet tiers, upgrades and displayed copies persist; loose inventory and pending income reset. Rebirth requires coins plus fresh flushes. Preserve main's 50% offline income and 24-hour hard limit. Clamp reported offline minutes as well as accrual so Level 100 plus Offline Plus cannot advertise 48 hours. Keep 10x total cash cap and 10x luck cap with rare-item diminishing returns. Admin level edits obey each track's new cap and cannot mint a thirteenth normal display slot; existing legacy capacity remains addressable.
