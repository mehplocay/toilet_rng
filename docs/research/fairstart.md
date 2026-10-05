# Fair start: server awards and floating coin feedback

Checked 2026-10-05 before implementation. No external assets or new request remotes.

- Server validation must cover context, timing and rate limits before changing progression. The existing Flush handler already checks profile availability, assigned plot proximity, cooldown, rate limit and empty remote arguments. Service Coins use the server's current toilet configuration after those checks; no client-supplied amount or luck multiplier participates.
  https://create.roblox.com/docs/scripting/security/client-server-boundary
- `RemoteEvent:FireClient(player, arguments)` supplies the recipient's `OnClientEvent`. Extend the existing Flush result with `ServiceCoins`, and keep the existing State snapshot authoritative for the wallet. The popup never changes currency locally.
  https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
- Create tweens with `TweenService:Create`, then `Play`. `TweenBase.Completed` fires on finish or cancellation; `Pause` does not fire it. Separate labels prevent overlapping awards from cancelling one another. Completion removes each transient label. `RBXScriptSignal:Once` disconnects its handler after the first notification.
  https://create.roblox.com/docs/reference/engine/classes/TweenService
  https://create.roblox.com/docs/reference/engine/classes/TweenBase/Completed
  https://create.roblox.com/docs/scripting/events
- DevForum's GUI completion discussion distinguishes TweenService completion from legacy GuiObject tween callbacks. Use TweenService and `Destroy`, not its old `Remove` example. The search-indexed discussion was readable; direct browsing encountered a JavaScript verification page.
  https://devforum.roblox.com/t/how-would-i-check-if-this-gui-tween-has-been-completed/517268
- Release-note index and release 727 were checked alongside current API references. The release pages supplied limited text, and direct DevForum release browsing encountered verification; no release-specific behavior is assumed.
  https://create.roblox.com/docs/release-notes/release-notes-727
  https://devforum.roblox.com/c/updates/release-notes/62
  https://devforum.roblox.com/t/release-notes-for-727/4701561
- Tool references: Rojo documents `rojo build -o build.rbxl`; StyLua supports Luau formatting and `--check`. Selene needs the configured Roblox standard library, which is missing locally; its attempted lint run cannot complete.
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua
  https://github.com/JohnnyMorganz/StyLua/releases
  https://kampfkarren.github.io/selene/usage/std.html
