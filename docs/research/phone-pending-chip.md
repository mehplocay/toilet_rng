# Phone pending and luck chips (Task 62)

Checked 2026-10-10:

- ScreenGui CoreUISafeInsets keeps descendants within the core UI/device safe root. Continue using root AbsoluteSize; do not subtract a second set of insets. https://create.roblox.com/docs/reference/engine/classes/ScreenGui
- GuiObject input properties and GuiButton Activated remain the relevant APIs. Pending is a passive Frame/TextLabel, explicitly Active=false and Selectable=false. Luck/Friends retains its existing button and details handler, with a 44 px target. https://create.roblox.com/docs/reference/engine/classes/GuiObject
- Roblox's notch-support platform announcement recommends safe insets for visible controls. A later home-bar issue report reinforces checking bottom margins rather than treating device insets as jump-control reservations. https://devforum.roblox.com/t/notched-screen-support-full-release/2074324 and https://devforum.roblox.com/t/devicesafeinsets-does-not-account-for-iphone-ipad-home-bar/3936416

Placement: Pending is 110x28 at the left safe margin (above the action row in portrait, alongside it in landscape). Luck/Friends is 136x44, above the jump reservation: bottom 96 px in portrait, existing conservative lower-right 35% in landscape. Its width preserves readable extreme luck values. Narrow landscape hint/reveal bounds stop before the status chip. The optional landscape admin entry moves alongside the celebration entry to avoid the new status location. These are conservative offline reservations, not measurements of Roblox CoreGui controls.
