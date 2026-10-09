# Task 60: compact phone landscape HUD

Checked 2026-10-09.

- [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui): CoreUISafeInsets keeps interactive descendants below Roblox core controls and outside device cutouts. Keep the existing safe root; layout coordinates use its AbsoluteSize and do not add a second top inset.
- [UITextSizeConstraint](https://create.roblox.com/docs/reference/engine/classes/UITextSizeConstraint): MinTextSize limits TextScaled shrinking; MaxTextSize must be at least MinTextSize. Phone HUD labels, pending income and tutorial detail now use a 14 px floor with sufficient label height. The 44 px touch target is the task requirement.
- [Notched-screen platform announcement](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324): existing safe-area research covers the full-release behavior. Rechecked the announcement URL; direct retrieval was blocked by the forum's browser verification. No new inset workaround is introduced.
- [Rojo build](https://rojo.space/docs/v7/getting-started/new-game/): the .rbxl output extension selects the binary place format.

Landscape phones use three columns of 60 x 44 px navigation buttons, a 76 px high tutorial card directly below the top row, two travel buttons, and a separate 44 x 44 px Settings icon. Touch viewports under 1200 px wide and 500 px high include the existing 1170 x 540 physical-screen case after safe-area subtraction. Portrait buttons also reserve 60 px width for readable labels; tablet placement is unchanged. The phone action bar reserves extra horizontal space for asymmetric landscape notches.

Validation uses production constructors with mocked engine boundaries and offline UI snapshots. These checks do not replace a physical iPhone review or Roblox Studio rendering.
