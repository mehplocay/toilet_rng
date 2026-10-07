# Shop / Upgrades tab routing (2026-10-07)

- Keep the existing `GuiButton.Activated` handlers for mouse, touch and GUI navigation. Controller navigation uses selectable buttons; the 2025 directional-navigation update is enabled by default. No new input bindings are needed for routing.
  - https://create.roblox.com/docs/reference/engine/classes/GuiButton
  - https://create.roblox.com/docs/reference/engine/classes/GuiObject
  - https://create.roblox.com/docs/reference/engine/classes/GuiService
  - https://devforum.roblox.com/t/introducing-improvements-to-directional-ui-selection-on-gamepad/3864317
- `ZIndex` controls rendering order. Move the actual Shop/Upgrades HUD buttons into the shared panel while it is open, above the modal backdrop; restore their HUD layout on close. Retain their existing activation connections and selectable behavior.
  - https://create.roblox.com/docs/building-and-visuals/ui/positioning-and-sizing-guiobjects
- `ScrollingFrame.CanvasPosition` is a Vector2 scroll offset. Reset the outer content offset on each entry so the tab/navigation controls start in view.
  - https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame
- The local `C.TabBar.Select` updates only the selected border, so the Upgrades API must also apply visibility, title and hint changes. Track the last opening entry separately from manual tab selection. Travel Shop forces the Toilets entry.
- Tool references: Rojo builds the project into a place file; StyLua supports `--syntax Luau --line-endings Windows`. Its v2.0 CLI-override issue is documented, so verify CRLF bytes as well as formatter output. Use the installed tools without upgrading dependencies.
  - https://rojo.space/docs/v7/getting-started/new-game/
  - https://github.com/JohnnyMorganz/StyLua
  - https://github.com/JohnnyMorganz/StyLua/issues/925
  - https://luau.org/syntax/

Headless harness checks activation callbacks and geometry; it cannot prove hardware focus navigation or actual Roblox rendering.
