# Leave popup (Task 66)

Reviewed 2026-10-10. No third-party image/audio assets are used; Door is original IconArt geometry.

- RemoteEvent.OnServerEvent supplies the sending Player. Accept no payload or target; verify current Players membership and identity, then use the shared per-player token bucket (one request per five seconds). https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
- Player:Kick disconnects the caller. Players.PlayerRemoving is the existing departure hook; keep DataService.Close, session release, leaderboard snapshots and income settlement there, with existing BindToClose fallback. Do not release a live player's profile before kicking. https://create.roblox.com/docs/reference/engine/classes/Player and https://create.roblox.com/docs/reference/engine/classes/Players
- DevForum save discussion corroborates the need for the shutdown fallback; forum answers are not a substitute for engine docs. https://devforum.roblox.com/t/does-plrplayerremoving-detect-plrkick/2213223
- ScreenGui.CoreUISafeInsets and ClipToDeviceSafeArea already establish the safe root. Size the dialog against that root. GuiService.SelectedObject selects Stay on open. ContextActionService handles Escape/ButtonB through the existing close route. https://create.roblox.com/docs/reference/engine/classes/ScreenGui and https://create.roblox.com/docs/reference/engine/classes/GuiService and https://create.roblox.com/docs/reference/engine/classes/ContextActionService
- Current Creator Updates were reviewed; this uses existing primitives and no newly announced UI APIs. https://create.roblox.com/updates
- Rojo supports binary place output through `rojo build -o build.rbxl`. https://rojo.space/docs/v7/getting-started/new-game/
- StyLua supports Luau and `--check` verifies formatting. https://github.com/JohnnyMorganz/StyLua/blob/main/README.md
- Selene's Roblox checks require its Roblox standard library support. The local 0.31.0 executable cannot load `std = "roblox"` and does not expose Roblox generation subcommands; report linting unavailable rather than changing the project's lint configuration. https://github.com/Kampfkarren/selene/blob/main/docs/src/roblox.md

Daily readiness uses the existing RewardSchedule and latest authoritative client snapshot, recomputed on open. Roblox's native menu Leave remains outside this dialog's routing.

GuiService.MenuOpened fires for the CoreGui escape menu. Dismiss the Leave dialog as Stay on this event too, so Escape remains safe when CoreGui consumes the key before the game's binding. https://create.roblox.com/docs/reference/engine/classes/GuiService
