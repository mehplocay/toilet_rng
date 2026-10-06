# Catalog / rebirth cosmetic integration

Checked 2026-10-06 against current sources.

- https://create.roblox.com/docs/chat/chat-window and https://create.roblox.com/docs/reference/engine/classes/ChatWindowMessageProperties: customize native prefixes with one `OnChatWindowAdded` callback, derived message properties and `PrefixTextProperties`. Keep filtered prefix content and message bodies intact. Our earned tag and VIP/Star tag have explicit rich-text colors; Rainbow Name takes precedence over Golden Name on the remaining prefix.
- https://create.roblox.com/docs/reference/engine/classes/Trail: trails connect two attachments; reuse the active trail and update its color. Rebirth and paid builders must not leave parallel trail instances or attachments behind.
- https://create.roblox.com/docs/reference/engine/classes/Player and https://create.roblox.com/docs/reference/engine/classes/Instance: use `CharacterRemoving` / `PlayerRemoving` for cleanup, destroy owned instances, and disconnect per-player connections. A delayed character-ready callback must recheck player and character identity.
- https://create.roblox.com/docs/reference/engine/classes/UIStroke and https://devforum.roblox.com/t/full-release-uistroke-improvements-scaling-offsets-and-more/3958036/1: released border strokes support multiple strokes, inner/outer positioning, offsets and ZIndex. Rebirth uses an inner border; VIP uses an outer gold border with a 2px gap and distinct ZIndex. Native visual QA remains necessary; mocks cannot verify rasterization.
- https://github.com/JohnnyMorganz/StyLua: supports Luau formatting/check mode. https://kampfkarren.github.io/selene/roblox.html: Roblox linting needs Roblox standard-library definitions and a Roblox-enabled build. This environment's Selene lacks the definitions and Roblox generation subcommands; its attempted run is not a lint pass.

The PowerShell audit bundler must read UTF-8 explicitly. Windows PowerShell's default encoding otherwise corrupts literal stars and other non-ASCII production strings before tests execute.
