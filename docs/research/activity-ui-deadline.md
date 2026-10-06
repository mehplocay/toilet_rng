# Activity report deadline (2026-10-06)

The merged audit reproduced 292 passes and one failure at the existing
`calls == 2` assertion after advancing the UI clock by 1 and 14 seconds.
The earlier rebirth click checks change the shared clock's fractional baseline:
`lastSent = 2035.0199999999998`, `now = 2050.0199999999995`, and subtraction
produces `14.999999999999773`. The clock has reached the representable deadline
`lastSent + 15`, but subtracting the timestamps postpones the report. Neither
the result toast nor an input listener leak caused this failure.

Store the next absolute send deadline and sample the clock once per heartbeat.
Keep the 15-second interval, dirty-input requirement, focus gate and disconnects.
The original assertions remain; additional checks cover idle after a report,
stationary/sensor noise, input release, pending-input cancellation on focus loss,
thumbstick resume and destruction while a report is pending. Server-side idle
tracking, argument validation and rate limits are unchanged.

Sources checked:

- Luau documents `os.clock()` as a high-precision duration clock with an undefined
  baseline; numeric arithmetic uses IEEE 754 doubles. Avoid assumptions about
  exact subtraction at a fractional timestamp boundary.
  https://luau.org/library/#os-library
  https://luau.org/lint/#integerparsing-27
- Creator Hub's official source describes InputBegan/Changed/Ended and focus
  events. UI-consumed input is still user input; focus gain alone is not input.
  InputObject documents wheel Position.Z and movement Delta.
  https://create.roblox.com/docs/reference/engine/classes/UserInputService
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/UserInputService.yaml
  https://create.roblox.com/docs/reference/engine/classes/InputObject
- DevForum AFK guidance combines input and window focus tracking. Recent input
  discussions/release references concern Input Action System and server-authority
  prediction; they do not establish a changed UserInputService activity contract.
  https://devforum.roblox.com/t/how-would-i-make-an-afk-detection-system/1132617
  https://devforum.roblox.com/t/server-authority-mispredictions-scale-with-client-fps-under-high-latency/4739385
- Tool references: StyLua supports check mode and Windows line endings; Rojo can
  build binary places; Selene requires the Roblox standard library. Installed
  Selene still cannot find that library, as previously recorded in audit2-tools.md.
  https://github.com/JohnnyMorganz/StyLua
  https://github.com/rojo-rbx/rojo.space/blob/master/docs/getting-started/new-game.mdx
  https://kampfkarren.github.io/selene/roblox.html

Validation: audit 293/293; all 22 standalone `scripts/check-*.luau` checks;
the audit/UI bundled checks via their PowerShell runners; UI runtime and 972
viewport cases; visuals and all six world modes; Rojo binary build;
`stylua --check --line-endings Windows src scripts`; and `git diff --check`.
Changed Luau files retain CRLF. No Studio/live engine session was used.
Assumption: the existing activity interval and input/focus contract are intended
to remain unchanged. No commit or push was made.
