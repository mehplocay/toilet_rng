# Task 62: Smaller Pending chip on phones

Owner feedback (iPhone landscape screenshot): the "Pending: N" bar is a wide dark bar across the top center and is too prominent. The coin counter ("264" with coin icon) is fine and stays.

Change on PHONES only (Layout.Phone), keep desktop/tablet behavior unchanged:
- Shrink the Pending display into a small compact chip (e.g. ~110x28 px, text >= 12 px, keep the existing label text format and the existing click/collect behavior if it has one).
- Move it to the bottom-left corner of the screen, inside the safe area (above the home indicator), not overlapping the Go To Toilet / Flush button, the AUTO chip, the jump button or the left menu block, and with touch target >= 44 px if it is tappable (otherwise it may be smaller but must not block touches).
- Make sure nothing else collides: Collect All hint, tutorial hint, reveal toasts.
- Where the wide bar was, nothing remains; the coin counter keeps its position.

Source files: src/client/UI/IncomeChip.luau, src/client/UI/HUD.luau, src/client/UI/Layout.luau. No gameplay/economy changes. Update tests in scripts/ (check-mobile-hud, ui-mobile-hud, check-ui-runtime) so the new placement is covered on all phone sizes. Follow AGENTS.md; work on branch feature/pending-chip, do not push (Git may be sandbox-blocked; leave uncommitted and say so). Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl.
