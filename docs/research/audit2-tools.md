# Audit 2: tool validation

Checked 2026-10-05.

- [Rojo project format](https://rojo.space/docs/v7/project-format/): instance properties are serialized through `$properties`; the updated streaming enum is validated by the actual binary build and XML import checks.
- [StyLua](https://github.com/JohnnyMorganz/StyLua): format changed Luau and run check mode across src/scripts; this Windows checkout uses Windows line endings.
- [Selene Roblox guide](https://kampfkarren.github.io/selene/roblox.html): Roblox linting requires the Roblox standard library. The installed 0.31.0 binary reports the missing `roblox` library and its help exposes no Roblox generation/update subcommands. Linting did not run successfully; no replacement global stub was used to claim a clean result.

Standalone Luau checks and the audit/UI/world bundlers run real project modules with controlled engine doubles. Builders also validate the real Rojo-serialized 75 imported templates. No Studio session was connected, so native rendering, service permissions, backend timing and engine profiling remain unverified.
