# Task 61: phone windows and single scrolling ownership

Checked 2026-10-09 after task 60 merge dc4351b.

- [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui): retain CoreUISafeInsets and the existing safe root. Window bounds use the safe root, without adding Roblox's inset a second time.
- [ScrollingFrame](https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame): AutomaticCanvasSize and CanvasPosition belong to the scrolling viewport. A fixed shell uses Frame; each active page owns one vertical ScrollingFrame. Horizontal tabs are siblings of that viewport, never descendants.
- [UIGridLayout](https://create.roblox.com/docs/reference/engine/classes/UIGridLayout): CellSize and CellPadding control responsive card placement. Non-scrolling grids use automatically sized Frames within the single content list.
- [TextService](https://create.roblox.com/docs/reference/engine/classes/TextService): retain GetTextSize measurement for the complete Lucky rarity disclosure and grow the containing card, rather than embedding another scrolling viewport or shrinking odds text.
- [Notched-screen release](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324): announcement rechecked; forum retrieval is verification-blocked. No speculative safe-area workaround or platform behavior change.
- [Rojo build](https://rojo.space/docs/v7/getting-started/new-game/): build.rbxl remains the binary build output.

The 44 px targets, 8 px control spacing and 12 px minimum text are task requirements. Production constructors fail when creating a ScrollingFrame under any ScrollingFrame; tests additionally walk completed trees so reparenting cannot evade the check. Offline snapshots and mocked layout checks do not establish physical-device or Studio rendering parity.
