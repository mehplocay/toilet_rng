# Roblox remotes and project tooling

Checked 2026-10-07 for the all-pools merge.

- Roblox RemoteEvents provide asynchronous one-way communication across the client/server boundary; gameplay outcomes remain server-owned. Creator Docs: https://create.roblox.com/docs/scripting/events/remote
- Roblox's security guidance covers validating requests at the client/server boundary: https://create.roblox.com/docs/scripting/security/client-server-boundary
- StyLua accepts `--line-endings Windows` to write CRLF files: https://github.com/JohnnyMorganz/StyLua
- Rojo's official project guide documents `rojo build` as the place-file build command: https://rojo.space/docs/getting-started/new-game/
