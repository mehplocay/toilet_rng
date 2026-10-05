# Daily rewards: UTC time and persistence

Checked 2026-10-05 before implementation.

- `os.time()` defaults to UTC time. Calendar rewards use `floor(os.time() / 86400)` on the server, rather than a rolling 24-hour cooldown or a client timestamp.
  https://create.roblox.com/docs/reference/engine/libraries/os
- DataStores are server-only, calls can fail, and `UpdateAsync` callbacks cannot yield and may run again when another server updates the key. Reward mutations happen outside the callback, then the existing session-leased DataService saves a copied profile. Coins, LastClaimDay, Streak and the personal boost expiry remain in one record.
  https://create.roblox.com/docs/cloud-services/data-stores
  https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore
- The client countdown uses `Workspace:GetServerTimeNow()` as a server-time estimate; claiming is always checked against server `os.time()`.
  https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow
- Existing UI components use `GuiButton.Activated` for mouse, touch and gamepad input.
  https://create.roblox.com/docs/reference/engine/classes/GuiButton#Activated
- DevForum daily-system discussion confirms timestamp-based tracking. Its older rolling-cooldown/SetAsync examples are not the UTC-calendar/session-lock design used here.
  https://devforum.roblox.com/t/how-do-people-make-daily-systems/386871
- Current API references were checked for behavior changes; no release-dependent API is introduced. Tool references for the required build/format checks:
  https://create.roblox.com/docs/release-notes/release-notes-727
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua

Design assumptions: the seven-day cycle repeats after day 7; coin previews use the current tier, and the actual amount uses the tier at claim time. Day 7 automatically activates a personal 2x luck boost for 600 wall-clock seconds, including time offline. Its expiry is persisted. Studio's existing in-memory fallback does not persist rewards. Claims save immediately through the existing DataService; abrupt crashes before a successful write have the same durability limits as other profile mutations.
