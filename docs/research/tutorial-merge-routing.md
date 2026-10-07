# Tutorial merge routing (2026-10-07)

Checked current official references while resolving the tutorial integration:

- Hidden GuiObject parents hide their descendants; keep the tutorial on the safe-area
  root while Shop/Upgrades navigation moves into the visible modal.
  https://create.roblox.com/docs/reference/engine/classes/GuiObject
- GuiButton.Activated supports mouse, touch and gamepad. Keep existing activation
  handlers when reparenting the actual navigation buttons.
  https://create.roblox.com/docs/reference/engine/classes/GuiButton
- CanvasPosition controls scroll offsets. Tutorial highlights continue to reveal
  actions inside nested scrolling frames after tab changes.
  https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame
- StyLua supports Windows line endings; retain the requested formatter option.
  https://github.com/JohnnyMorganz/StyLua

Shop opens Toilets with the title "Toilet Shop"; Upgrades opens Coin Upgrades.
Retain affordable toilet and coin-upgrade targets, tab fallback and close fallback.

Integration finding: reserving the tutorial banner's space clipped the shop tab row
on the 640x303 safe-area layout. On short screens, place tabs before the wallet
to keep both navigation rows reachable. The routing regression now uses the real
client bootstrap with server checkpoints and tests both affordable purchase paths.

Validation: StyLua Windows formatting/check, Rojo build, all 25 check-*.luau
(two through their PowerShell harnesses), balance.luau, audit (382 passed), full UI
(including 972 layout cases), visuals, and all six world modes passed. Selene could
not load the installed binary's missing Roblox standard library. No live Studio
run was performed. Git staging was denied at the shared worktree index outside
the writable workspace; the six resolved files still have unmerged index entries.
No commit, push, or merge abort.
