# Studio-only developer remotes

- `RunService:IsStudio()` reports whether code is running in Studio. The server must enforce this check because a client-side Studio-only UI is not a security boundary.
  Source: https://create.roblox.com/docs/reference/engine/classes/RunService
- `RemoteEvent.OnServerEvent` receives the originating `Player` followed by client arguments; server handlers should validate those arguments before mutating server-owned state.
  Source: https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
- Remote events provide one-way client/server messaging; `FireServer()` invokes the server event and does not grant authority to the client.
  Source: https://create.roblox.com/docs/scripting/events/remote
