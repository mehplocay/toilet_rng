# Phone coins and luck group (Task 63)

Checked 2026-10-10 against current sources:

- Continue placing controls relative to the existing CoreUISafeInsets root AbsoluteSize; do not subtract device insets again. Keep an additional 12px bottom margin for wallet text/chrome. https://create.roblox.com/docs/reference/engine/enums/ScreenInsets and https://create.roblox.com/docs/reference/engine/classes/ScreenGui
- Hide Pending with Visible=false and a zero-size phone rectangle, retaining updates and the non-phone rectangle. GuiObject visibility and geometry are presentation properties. https://create.roblox.com/docs/reference/engine/classes/GuiObject
- Use offset dimensions for the phone coin icon and a single-line label with a 16px minimum; TextScaled constraints still require sufficient label dimensions. https://create.roblox.com/docs/ui/position-and-size
- The platform notch-support announcement directs visible text/buttons to safe-inset ScreenGuis. The existing conservative inset fixtures include the home indicator. https://devforum.roblox.com/t/notched-screen-support-full-release/2074324

Owner decision supersedes Task 62 placement: 136px-wide stack at x=8, Luck/Friends 44px high, 8px gap, coins 28px high. In portrait it sits just above the action row; landscape places it alongside the action row. The requested left thumb region is allowed for this group only; the right jump reservation and all HUD/overlay collision checks remain. Neutral luck stays visible and opens the existing details dialog. No server or economy changes.

Validation uses production constructors and offline geometry/text approximations, including 320x568, all prior phone cases, rotations to tablet/desktop, nested scroll checks, and finite coin magnitudes through 1e300. Roblox Studio device emulation remains the final engine-rendering check.

The 320x568 fixture also exposed existing hint/reveal height and result-toast/Skip collisions. Limit portrait hint/reveal height to the thumb reservation, and put the result toast above the hint only when its width is below 170px. Other phone sizes retain their overlay geometry.

Tooling: StyLua supports Luau and direct file formatting/checks (https://github.com/JohnnyMorganz/StyLua). Selene needs its configured standard library (https://kampfkarren.github.io/selene/usage/std.html); this environment has the executable but cannot find the `roblox` library, so linting could not start. Git staging cannot create the linked worktree index.lock outside the writable sandbox; leave the task uncommitted for manager review.

Results: check-audit (431 passed), full check-ui (including 15 mobile viewports and 972 geometry cases), check-visuals, all six check-world modes, StyLua --check, git diff --check, and rojo build -o build.rbxl passed. Offline HUD previews at 320x568 portrait and 568x320 landscape were rendered and inspected.
