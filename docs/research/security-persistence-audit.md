# Security and persistence audit research

Checked 2026-10-05, before source edits.

- Validate remote permissions, types, finite numeric ranges and server cooldowns. Prompts also need server checks; only `Triggered` has a built-in distance check. Network-owned character position is not proof of legitimate movement. This audit keeps RNG and economic mutations on the server.
  https://create.roblox.com/docs/scripting/security/client-server-boundary
- `UpdateAsync` yields; its transform cannot yield, may be called repeatedly after conflicts, and returning nil cancels the write. A lock must be checked inside every transform; a successful pcall alone is not proof of ownership. Use a distinct token for each player session, not just a server identifier. The token recommendation is this audit's inference from the documented conflict semantics.
  https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/GlobalDataStore.yaml
- Roblox staff's persistence guidance describes atomically acquiring a session lock with the initial UpdateAsync. DevForum full-page access was robot-blocked here; the indexed staff excerpt was available. No community workaround overrides the Engine documentation.
  https://devforum.roblox.com/t/implementing-player-data-and-purchasing-systems/2839941
- Shutdown callbacks run concurrently; Roblox waits at most 30 seconds. A bounded close cannot promise recovery from an indefinite backend outage. Track loads as well as saves if shutdown must release newly acquired locks.
  https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/DataModel.yaml
- DataStore throttling can prolong a yielding request; UpdateAsync uses both read and write budgets. An expired local lease must stop gameplay even while a request remains pending. This fail-closed rule is an audit inference, not an API guarantee.
  https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
- Studio can access production data in the same experience. Use a separate test experience when enabling Studio API access and developer grants.
  https://create.roblox.com/docs/cloud-services/data-stores
- Platform-change check: reviewed the DataStore access/storage announcement and current limits, plus release notes 727. The announcement's historical numbers are not used as current limits. DevForum full-page access was blocked; no unverified new API behavior is required by the fixes.
  https://devforum.roblox.com/t/datastores-access-and-storage-updates/3597255
  https://create.roblox.com/docs/release-notes/release-notes-727
- Tool references checked for the existing CLI workflow (Rojo 7.7.0, StyLua 2.5.2, Selene 0.31.0); regression mocks use Luau coroutines to control yield ordering.
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua
  https://github.com/Kampfkarren/selene
  https://luau.org/library/
