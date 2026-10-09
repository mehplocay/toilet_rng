# Task 61: Phone-first review of every window (after task 60 is merged)

The owner says the UI is poor on phones. Task 60 fixed the main HUD. Now review and fix EVERY window and popup for phone landscape (and portrait if supported): Toilet Shop (Shop + Upgrades tabs), Passes (Passes/Coins/Lucky tabs), Index/Collection, Rebirth, Upgrades, Daily reward, Settings, Hub teleports, reveal popups, tutorial, toasts, offer buttons on the right, status chips.

For each window on typical phone sizes (e.g. 844x390, 932x430, 667x375, 740x360, 568x320, plus 1170x540) check and fix:
- Content fits without clipping; scrolling where needed; close button >= 44 px and reachable, nothing under the Roblox top-left menu/notch/home-indicator safe areas.
- Touch targets >= 44 px, spacing >= 8 px, no overlapping buttons or text.
- Text readable (>= 12 px equivalent at phone scale), no truncated names/prices, price and buy buttons obvious.
- Windows are not larger than the screen; tabs fit on one row or scroll cleanly.
- One consistent style (same close button, header height, padding).
- Never cover the Flush button or the character longer than necessary.

Rules: no gameplay/economy/luck/audio changes, no new caps, keep the real icon pipeline (Assets.IconImages). Extend scripts/check-ui-runtime.luau with phone cases for every window so regressions fail. Follow AGENTS.md; branch feature/mobile-windows, commit, do not push. Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl. Report per window what was wrong and what you changed.
