# Chat/native-list validation tools

Checked 2026-10-06.

- [Rojo project format](https://rojo.space/docs/v7/project-format/): serialized service configuration uses $properties. rojo build validates modern chat configuration, including the legacy-compatible ChatVersion setting.
- [StyLua](https://github.com/JohnnyMorganz/StyLua): format changed Luau with Windows line endings, then check src/scripts.
- [Selene Roblox guide](https://kampfkarren.github.io/selene/roblox.html): Roblox lint needs its standard library. Installed Selene cannot find roblox; no clean lint result is claimed.
- Audit/UI bundlers execute unchanged production source in engine doubles. The task adds audience, aggregation, settings persistence, numeric leaderstat and client startup regressions; these do not certify CoreScript rendering.
- Studio MCP tool descriptions require discovery plus the target studio_id/datamodel type. Discovery/state succeeded; arbitrary Luau execution was denied by automatic approval with approval policy never. No alternate execution path was used.
