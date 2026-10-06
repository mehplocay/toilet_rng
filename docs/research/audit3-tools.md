# Audit 3: tool contracts (2026-10-06)

Rojo build produces the place from the project mapping; it does not exercise Roblox engine execution. StyLua supports Windows line endings, check mode and AST verification. Use these without replacing tests. Selene needs the Roblox standard library; missing definitions are a tooling limitation, not a clean lint result.

Current local attempt: StyLua verification/check and Rojo build succeed. Installed Selene cannot find the configured roblox standard library (same environment limitation recorded in audit 2). Headless fixtures run production module source with mocked engine services; they cannot certify billing, filtering, replication or DataStore quotas.

Sources:
- https://rojo.space/docs/v7/
- https://github.com/JohnnyMorganz/StyLua
- https://kampfkarren.github.io/selene/roblox.html
