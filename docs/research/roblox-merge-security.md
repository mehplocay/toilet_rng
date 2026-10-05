# Auto-Flush merge security

Checked 2026-10-05 while resolving `feature/autoflush` into `main`.

- [Player data/session locking](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing): a rejoin can precede the previous session's final save. Preserve per-Player ownership tokens, load tracking, lease expiry checks and shutdown waiting.
- [GlobalDataStore](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore): `UpdateAsync` callbacks can replay after concurrent updates; keep ownership and lease validation inside the callback and snapshot data before yielding.
- [DataModel shutdown](https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose): shutdown callbacks have a bounded completion window. Keep the existing 25-second wait covering pending loads and saves.
- [Client/server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary): server validation must cover permissions, proximity, rate limiting and non-finite numbers, including prompt-triggered actions. Manual, prompt and automatic flushes use one award path, owner/range validation, shared limiter and shared effective cooldown.
- [StyLua](https://github.com/JohnnyMorganz/StyLua): format the merged Luau files with the installed CLI, then run build and regression checks.
- [Rojo builds](https://rojo.space/docs/v7/getting-started/new-game/): `rojo build -o build.rbxl` produces the binary place.
- [Selene Roblox support](https://github.com/Kampfkarren/selene/blob/main/docs/src/roblox.md): Roblox analysis requires its standard library/generation support. The installed 0.31.0 binary lacks Roblox commands/capabilities and no `roblox.yml` is available; the configured lint cannot run in this environment.
- [DevForum session-lock discussion](https://devforum.roblox.com/t/session-locking-explained-datastore/846799): supplementary discussion of atomic `UpdateAsync` session ownership; the official player-data documentation above is the basis for this merge.
