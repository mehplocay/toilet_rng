# Task 65: mobile tutorial start

## Findings and fixes

- The phone title reserved 76 px for Skip even on a 158 px card. A fixed
  14 px minimum inside a 20 px-high, wrapping title could hide/truncate `n/5`.
  The title now has its own portrait row and two-line allowance; landscape
  uses a wide strip beside Home. Phone titles include `1/5` through `5/5`,
  with a thin progress bar. Instructions are one short sentence at 14 px.
- The old portrait card started at y=218; its center-column position could
  cover the character. Portrait now starts at y=64 beside navigation, and
  landscape uses the top strip. Skip remains at least 54x44. During reveals
  the existing Skip-only card is retained, with Skip positioned inside it.
- Home previously discarded taps when PlotCFrame or Character was absent
  and awaited streaming in the activation callback. It now retains a tap
  for up to 10 seconds, checks for a living, ready character, and streams
  asynchronously before teleporting. Choosing Hub/TravelShop cancels a
  pending Home retry. A character replaced during streaming is not moved.
- Highlights now reject hidden ancestors and zero-size buttons. The hand
  pointer lives inside the highlighted button, rather than using the HUD's
  phone Pointer rectangle (which is intentionally zero-sized). Decorations
  do not handle taps. The safe-area root remains CoreUISafeInsets.
- FlushPrompt.Near is already input-independent: own enabled FLUSH prompt,
  living Humanoid, root part, BasePart target, and distance <= min(prompt
  range, configured flush range). The Home offset (0, 2.65, -9) is within the
  10-stud prompt range. Delayed ownership is rechecked through the existing
  attribute signal. No FlushPrompt/PlotGuidance gameplay change is needed.
- Progress.Step intentionally reads the saved server checkpoint. Step 1
  displays step 2 while Near() is true; moving away restores Home guidance.
  A successful authoritative flush records step 3, including when the saved
  checkpoint is still 1. Result events cannot advance locally. Respawn and
  rebirth do not reset saved progress; Settings replay explicitly starts a
  new TutorialRun. No new remote or economy/progress reward was introduced.
- Existing modal behavior is retained: short-phone windows hide the card;
  taller phones reserve the guide strip. Closing restores it. Hidden HUD
  navigation is never highlighted, while relevant visible modal actions can
  still receive the highlight. Skip retries a missing acknowledgement.

## Runtime regression coverage

`scripts/check-tutorial-mobile.ps1` executes the real client bootstrap,
HUD, Tutorial, FlushPrompt and shared Progress using the UI engine double,
with TouchEnabled=true. check-ui invokes a fresh harness to isolate bootstrap
from earlier UI fixtures; check-audit includes the same suite.
It covers 14 physical phone viewports, portrait/landscape and notch/top/
bottom inset reservations (320x568 through 1170x540). It checks early Home
taps, missing character/plot assignment, delayed prompt ownership, Home and
GO TO TOILET -> Near -> Flush -> saved step 3, death, hidden HUD, Skip,
Settings replay and completed suppression after rebirth. All five phone
titles must start with n/5 and fit their allocated bounds at >=14 px;
geometry/font-metric checks fail on missing text, overflow, clipping,
control overlap or occupation of the central character region.

Native glyph metrics, Roblox core-menu hit testing and real network/streaming
timing are not simulated. Offline snapshots are approximate previews, not
device screenshots; an actual Studio/device pass remains a review limitation.
The central character reservation assumes the normal centered game camera.

## Sources checked (2026-10-10)

- GuiButton.Activated is the shared activation event; keep the existing
  Activated handlers for touch navigation and Flush:
  https://create.roblox.com/docs/reference/engine/classes/GuiButton
- Custom prompt input and activation distance:
  https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
- TextScaled/TextWrapped, TextFits and TextBounds; size constraints cannot
  create missing layout space:
  https://create.roblox.com/docs/reference/engine/classes/TextLabel
  https://create.roblox.com/docs/ui/size-modifiers
- ScreenGui safe insets and streaming requests:
  https://create.roblox.com/docs/reference/engine/classes/ScreenGui
  https://create.roblox.com/docs/reference/engine/classes/Player
- Gui visibility/input, character pivot and living-character checks:
  https://create.roblox.com/docs/reference/engine/classes/GuiObject
  https://create.roblox.com/docs/reference/engine/classes/PVInstance
  https://create.roblox.com/docs/reference/engine/classes/Humanoid
- DevForum discussion of TextScaled/UITextSizeConstraint:
  https://devforum.roblox.com/t/making-text-size-consistent/2700490
- Release notes were checked, but the index returned no readable notes and
  DevForum's release category required JavaScript verification; no changed
  platform behavior is assumed:
  https://create.roblox.com/docs/release-notes
  https://devforum.roblox.com/c/updates/release-notes/62
- Build/format tool sources:
  https://github.com/rojo-rbx/rojo.space/blob/master/docs/getting-started/new-game.mdx
  https://github.com/JohnnyMorganz/StyLua

## Validation

- Rojo build and StyLua checks pass.
- check-world and check-visuals pass (run sequentially; both use the same
  temporary model-template build path).
- Selene was invoked but cannot run: this installed version cannot find its
  configured `roblox` standard library. No project lint configuration changed.
- check-audit: 442 passed, 0 failed. check-ui passes with its normal native
  codegen flags, including the fresh touch suite. Layout covers 972 cases;
  touch onboarding/counter/pointer coverage passes all 14 phone viewports.
- Offline portrait 320x511 and landscape 568x263 previews were rendered and
  visually reviewed. Native Studio/device QA remains outstanding.
- Work is on feature/tutorial-mobile. Git staging failed because the
  worktree index.lock is outside the writable sandbox; changes are left
  uncommitted. Nothing was pushed.
- Temporary `.tutorial-*.log` files and `.tutorial-mobile-review/` remain:
  automatic approval review rejected both recursive and non-recursive shell
  cleanup with "blocked by policy". These are review artifacts, not source.
