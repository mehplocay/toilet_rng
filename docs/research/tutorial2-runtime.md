# Tutorial runtime and persistence (2026-10-07)

- `GuiObject.Visible = false` hides descendants. The old hint and Skip were inside
  the HUD; opening any modal hid that parent. Keep onboarding under the safe-area
  root, above the backdrop, and reserve space above modal content.
  https://create.roblox.com/docs/reference/engine/classes/GuiObject
  https://devforum.roblox.com/t/how-do-i-check-if-a-ui-is-truly-visible/1582405
- Reliable RemoteEvents preserve order across remotes in one direction. They queue
  before a listener connects; a yielding handler can still overlap later handlers.
  Do not claim startup events are inherently lost. Bootstrap already requests State
  after subscribing; use server checkpoints rather than locally counting Results.
  https://create.roblox.com/docs/scripting/events/remote
- Validate arity, loaded profile, rate limits and engine sender. Tutorial replay is
  a self-only preference reset with no rewards. Private admin reset uses the existing
  owner authorization and guarded profile save, with no target-user argument.
  https://create.roblox.com/docs/scripting/security/client-server-boundary
- `UpdateAsync` transforms saved records on the server. Tutorial fields use the
  existing lease, sanitizer, autosave and departure-save pipeline. Studio API access
  permits persistence; this project uses a separate Studio store.
  https://create.roblox.com/docs/cloud-services/data-stores
- Activated supports touch, mouse and gamepad. Safe-area coordinates come from the
  existing root using CoreUISafeInsets. CanvasPosition scrolls to highlighted actions.
  https://create.roblox.com/docs/reference/engine/classes/GuiButton
  https://create.roblox.com/docs/reference/engine/classes/ScreenGui
  https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame
- The root's local TutorialActive attribute coordinates modal sizing through
  GetAttributeChangedSignal; no attribute is treated as gameplay authority.
  https://create.roblox.com/docs/reference/engine/classes/Instance
  Luau if-expressions and guarded table access use the current syntax reference.
  https://luau.org/syntax/
- Checked the release-notes index (latest listed 741, October 6). The fetched index
  exposes no detailed change text; no new release-specific behavior is assumed.
  https://devforum.roblox.com/c/updates/release-notes/62
- Existing Rojo project/build workflow is retained; StyLua supports Windows line
  endings via `--line-endings Windows`. No new tool dependency.
  https://rojo.space/docs/v7/getting-started/installation/
  https://github.com/JohnnyMorganz/StyLua

The installed Selene 0.31.0 build has no Roblox generation subcommands and cannot
load `std = "roblox"`; lint is unavailable with this binary. The documented Roblox
build normally generates/cache-loads that library automatically.
https://kampfkarren.github.io/selene/roblox.html

Headless baseline: fresh hint visible; after six seconds invisible; opening a modal
sets the tutorial's HUD parent invisible. The old runtime suite explicitly asserted
that repeated tutorial snapshots must stay invisible, so it missed this failure.
