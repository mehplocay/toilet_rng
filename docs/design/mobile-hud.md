# Dedicated phone HUD

Branch: `feature/mobile-hud`. No commit or push. English game UI. No changes to `Passes.luau`, server economy, RNG, purchases, or asset IDs.

## Layout

The existing `CoreUISafeInsets` root supplies the usable viewport. Phone mode uses width below 600, height below 400, or a touch viewport below 1000 wide and 500 high. This preserves the existing desktop and tablet cases, including 768×1024 and the wide 1170×540 touch case. Very short portrait roots use two navigation columns; ordinary phone portraits use one left rail and landscapes use a 3×2 rail. Targets are 44–56 px, with 12 px labels (`Upg.` is the short Upgrades label).

The left bottom 28% × 40% and right bottom 22% × 35% are reserved for Roblox controls. Tests check both safe-root rectangles and physical screen rectangles after restoring the simulated insets, including a 2 px stroke and 5 px shadow allowance. The rail uses additional clearance so top insets do not push its chrome into the physical thumb zone. Geometry tests include owner Admin and owned Dance Pack slots, result/reveal bounds, and coin popups. Flush and AUTO occupy the center gap with 76 px height; the AUTO button is 74 px wide. Flush/AUTO text has a 14 px floor. AUTO uses the existing Flush icon, a readable AUTO heading, unlock progress or ON/OFF, and COLLECT ON/WAIT/PAUSED. Detailed uptime/idle countdown remains in Boost details. The paused resume target retains its activity remote and uses “Still there? Tap”.

Hub/Home/Shop form a compact 44 px travel row. Coins and Pending form one compact two-line wallet area below it. Promo cards are hidden; Passes shows STYLE and Daily shows READY or the countdown. The duplicate Daily count badge is hidden on phones. The three separate boost chips become a 44 px button showing total luck and friends; it hides for a neutral state and opens scrollable luck/social/automation details. Dance Pack is ownership-gated and uses a small crown button. Owner Admin uses ADM to prevent narrow-label wrapping.

Tutorial and result/reveal presentation use the central free area. A result during a tutorial modal uses the free strip above the shifted window title bar, leaving room for Skip. This avoids the short-landscape header collision found by the complete toast regression.

## Windows and compatibility

Passes, Upgrades/Shop, Index, Rebirth, Daily and Settings retain their existing outer scrolling and safe-area close button. The shared panel component raises phone fixed button heights to 44 px, search fields to 44 px, and text floors to 12 px. Original dimensions and text floors are restored when returning to a desktop/tablet layout. This fixes the 40 px Passes tabs without editing the parallel session's file. Inner card lists remain scrollable; a short landscape shows part of the first card until the content is scrolled. A second preview shows that state, and a production test scrolls an upgrade action into the visible content area.

Interpretation: reserved thumb rectangles apply to the gameplay HUD. An open modal uses the safe screen as before. The requested small tablet is a compatibility regression, retaining its original layout and existing control reservation; changing it to the new percentage zones would conflict with the explicit instruction to keep tablets exactly unchanged.

## Verification and reproduction

- `scripts/check-mobile-hud.luau`: seven phone geometries, safe bounds, percentage thumb zones, pairwise overlap, travel/action/navigation target sizes, toast/reveal/coin separation; unchanged small tablet.
- `scripts/ui-mobile-hud.luau`: production UI constructors for all eight sizes; real HUD overlap and thumb tests; wallet/status/action text floors; owner/Dance ownership; window button targets, safe Close, scrolling, tutorial and bootstrap Settings. Existing 12-viewports harness and its 972-case layout sweep remain.
- Existing automation, celebration and toast regressions accept the short phone labels while retaining desktop expectations and state/remote assertions.
- Generate trees: `powershell -ExecutionPolicy Bypass -File scripts/check-ui.ps1 -MobileOnly -SnapshotDirectory docs/review/mobile-hud`.
- Render: `powershell -ExecutionPolicy Bypass -File scripts/render-ui-review.ps1 -SnapshotDirectory docs/review/mobile-hud`.
- Mandatory full validation: all standalone `scripts/check-*.luau`; audit/runtime checks via their PowerShell bundlers; `check-audit.ps1`, `check-ui.ps1`, `check-visuals.ps1`, `check-world.ps1`; `stylua --check --line-endings Windows`; `rojo build -o build.rbxl`.
- Selene was attempted but the installed configuration cannot resolve its `roblox` standard library. No lint-success claim is made.

Validation results: all 27 standalone `check-*.luau` suites passed, the bundled audit reported 404 passed / 0 failed, and the visual and world checks passed. The latest full `check-ui.ps1` runtime/regression bundle and phone snapshot run passed, including all eight production viewports and the existing 972-case geometry sweep. Rojo build, StyLua with Windows line endings, and `git diff --check` passed. The status tests explicitly advance the harness's waiting task coroutines to verify both neutral-state hiding and group-boost visibility. [Validation record](../review/mobile-hud/validation.txt).

These PNGs are headless approximations of actual production UI trees using local icon PNGs, not Roblox/Studio screenshots or a real-device input test. Canvas dimensions exclude the simulated notch/topbar/home-indicator insets. Actual device controls, font metrics, asset loading and touch ergonomics still need Studio/device review. [Research](../research/mobile-ui-safe-areas.md) records the API and platform findings.

## Reviewed PNGs

I inspected each viewport's HUD, window, tutorial, scrolled window and Settings. Iterations corrected coin-popup thumb intrusion, landscape tutorial bounds, Daily badge crowding, unreadable automation, short Admin wrapping and undersized window tabs. Modal scrolling is intentional; Close remains fixed and visible.

| Screen | Safe canvas | HUD | Window | Tutorial | Additional views |
|---|---|---|---|---|---|
| 375×812 | 375×690 | [PNG](../review/mobile-hud/mobile-375x812-hud.png) | [PNG](../review/mobile-hud/mobile-375x812-window.png) | [PNG](../review/mobile-hud/mobile-375x812-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-375x812-window-scrolled.png), [Settings](../review/mobile-hud/mobile-375x812-settings.png) |
| 390×844 | 390×722 | [PNG](../review/mobile-hud/mobile-390x844-hud.png) | [PNG](../review/mobile-hud/mobile-390x844-window.png) | [PNG](../review/mobile-hud/mobile-390x844-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-390x844-window-scrolled.png), [Settings](../review/mobile-hud/mobile-390x844-settings.png) |
| 360×740 | 360×618 | [PNG](../review/mobile-hud/mobile-360x740-hud.png) | [PNG](../review/mobile-hud/mobile-360x740-window.png) | [PNG](../review/mobile-hud/mobile-360x740-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-360x740-window-scrolled.png), [Settings](../review/mobile-hud/mobile-360x740-settings.png) |
| 430×932 | 430×810 | [PNG](../review/mobile-hud/mobile-430x932-hud.png) | [PNG](../review/mobile-hud/mobile-430x932-window.png) | [PNG](../review/mobile-hud/mobile-430x932-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-430x932-window-scrolled.png), [Settings](../review/mobile-hud/mobile-430x932-settings.png) |
| 812×375 | 724×318 | [PNG](../review/mobile-hud/mobile-812x375-hud.png) | [PNG](../review/mobile-hud/mobile-812x375-window.png) | [PNG](../review/mobile-hud/mobile-812x375-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-812x375-window-scrolled.png), [Settings](../review/mobile-hud/mobile-812x375-settings.png) |
| 844×390 | 756×333 | [PNG](../review/mobile-hud/mobile-844x390-hud.png) | [PNG](../review/mobile-hud/mobile-844x390-window.png) | [PNG](../review/mobile-hud/mobile-844x390-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-844x390-window-scrolled.png), [Settings](../review/mobile-hud/mobile-844x390-settings.png) |
| 740×360 | 652×303 | [PNG](../review/mobile-hud/mobile-740x360-hud.png) | [PNG](../review/mobile-hud/mobile-740x360-window.png) | [PNG](../review/mobile-hud/mobile-740x360-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-740x360-window-scrolled.png), [Settings](../review/mobile-hud/mobile-740x360-settings.png) |
| 768×1024 tablet | 768×968 | [PNG](../review/mobile-hud/mobile-768x1024-hud.png) | [PNG](../review/mobile-hud/mobile-768x1024-window.png) | [PNG](../review/mobile-hud/mobile-768x1024-tutorial.png) | [Scrolled](../review/mobile-hud/mobile-768x1024-window-scrolled.png), [Settings](../review/mobile-hud/mobile-768x1024-settings.png) |
