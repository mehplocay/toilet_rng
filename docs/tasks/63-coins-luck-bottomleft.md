# Task 63: Phone HUD: remove Pending, coins + luck bottom-left

Owner decision (phone landscape and portrait only; desktop/tablet unchanged):
- REMOVE the Pending income display on phones entirely (hidden, no space reserved). Keep the underlying income logic and the desktop display untouched.
- Move the coin counter (coin icon + amount) and the Luck/Friends chip ("Luck x1 / Friends +0%") together into the BOTTOM-LEFT corner as one compact group: coins on one line, Luck chip next to or directly above it. Inside the safe area above the home indicator.
- It must not overlap the left menu block, the Go To Toilet / Flush button, the AUTO chip, the Collect-All hint, the tutorial hint or reveal toasts. Remove the Luck chip from the bottom-right (it moves left).
- Coin amount text >= 16 px and must not clip for huge numbers (existing huge-coin tests, up to 1e300 formatting). Luck chip keeps its click to open details (touch target >= 44 px).
- The top bar keeps only Hub, Home and Settings.

Files: src/client/UI/Layout.luau, HUD.luau, IncomeChip.luau. No gameplay/economy changes. Update the phone tests (scripts/check-mobile-hud, ui-mobile-hud, check-ui-runtime) for the new placement on all phone sizes, including the nested-scroll and overlap checks. Follow AGENTS.md; branch feature/coins-luck-left, do not push (Git may be sandbox-blocked; leave uncommitted and say so). Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl.
