# Audit 4: platform and tool checks

Checked 2026-10-07.

- Checked the [release index](https://devforum.roblox.com/c/updates/release-notes/62) and [release 741](https://devforum.roblox.com/t/release-notes-for-741/4906281), dated 2026-09-30. No undocumented cache, serialization or receipt guarantee is inferred from a release number. The 2026 JSON change is recorded separately in `audit4-numbers.md`.
- [Rojo build documentation](https://rojo.space/docs/v7/getting-started/new-game/) supports binary `.rbxl` output through `rojo build -o build.rbxl`.
- [StyLua](https://github.com/JohnnyMorganz/StyLua) documents Windows/Unix line endings and verification/check modes. Preserve Windows line endings for this repository.
- [Selene Roblox guide](https://kampfkarren.github.io/selene/roblox.html) requires the Roblox standard library and describes its generation. An installed executable alone does not establish that the configured `std = "roblox"` can load. Record the actual lint result; do not disable lint rules to claim a pass.

Headless tests do not measure native instance/connection retention, scheduler load, engine serializing or actual billing. Those remain explicit Studio/published-universe checks.
