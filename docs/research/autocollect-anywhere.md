# Auto Collect anywhere (2026-10-07)

- Roblox task.wait resumes on the next Heartbeat after the requested duration; actual intervals can exceed five seconds. Keep one existing server loop, enforce 1/5s admission, and never replay missed ticks: https://create.roblox.com/docs/reference/engine/libraries/task
- Roblox requires server validation of permission/context and server rate limits. Auto collection receives no client amount, position or timestamp and uses IncomeAccrual:Collect, the manual jar ledger debit/credit: https://create.roblox.com/docs/scripting/security/client-server-boundary
- The official task rollout confirms scheduler semantics; task.wait avoids legacy wait throttling: https://devforum.roblox.com/t/task-library-now-available/1387845
- Release-note index checked; its public web response did not expose current entries. No new engine API or undocumented behavior is introduced: https://devforum.roblox.com/c/updates/release-notes/62
- Luau os.clock is the elapsed-time source for the existing activity/token budgets; ledger mutations remain synchronous: https://luau.org/library/
- Rojo build uses the existing project file: https://rojo.space/docs/v7/getting-started/installation/
- StyLua supports Windows line endings and check mode: https://github.com/JohnnyMorganz/StyLua
- Selene CLI supports checking source folders with the Roblox standard library: https://kampfkarren.github.io/selene/cli/usage.html

Implementation assumption: like Auto Flush, a living character and owned assigned plot remain required; distance is unrestricted. Auto Collect resumes automatically after respawn once those guards pass, without renewing the shared idle clock. Manual collect and offline earning rules are unchanged.

- Existing living-character guards use Player.Character, CharacterRemoving and Humanoid.Health; these engine members were checked in current references: https://create.roblox.com/docs/reference/engine/classes/Player and https://create.roblox.com/docs/reference/engine/classes/Humanoid#Health
