# Wiring validation tools

Checked 2026-10-07.

- https://github.com/JohnnyMorganz/StyLua — line_endings supports Windows (CRLF); use --line-endings Windows for formatting/checks to preserve this workspace's convention.
- https://github.com/rojo-rbx/rojo.space/blob/master/docs/getting-started/new-game.mdx — rojo build serializes the configured project into a place file; validate the existing default.project.json with rojo build -o build.rbxl.
- https://kampfkarren.github.io/selene/usage/std.html — Roblox linting depends on the generated Roblox standard library. Attempt the installed Selene binary; report a missing library/network failure instead of treating it as a successful lint.
