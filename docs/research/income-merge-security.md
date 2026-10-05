# Income merge persistence review

Checked 2026-10-05 while resolving `feature/income` into `main`.

- Keep audio migration and income sanitization together. Income pending values use integer units (6000 per coin), not rounded whole coins; reject non-finite/negative values, cap each slot and the total, bound timestamps, and migrate missing ledgers without retroactive awards. Luau numeric operations: https://luau.org/library/
- Keep per-player session ownership and lease checks inside every save transform, snapshot before yielding, and track loading/closing/saving through shutdown. `UpdateAsync` can replay its callback and nil cancels the write: https://create.roblox.com/docs/cloud-services/data-stores and https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore#UpdateAsync
- Studio fallback profiles must never overwrite persisted data. Atomic session locking and fallback guidance: https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing
- Staff guidance confirms that a new session can overlap the previous final save: https://devforum.roblox.com/t/implementing-player-data-and-purchasing-systems/2839941
- Preserve the bounded shutdown wait for pending loads and saves: https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose
- Checked Creator Updates; no new engine API is introduced by this resolution: https://create.roblox.com/updates
- Formatting and binary build commands: https://github.com/JohnnyMorganz/StyLua and https://rojo.space/docs/v7/getting-started/new-game/
