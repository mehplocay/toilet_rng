# Task 60: Mobile UI cleanup (phone landscape)

Owner screenshot (iPhone, landscape) shows problems. Fix them without changing game logic, economy, luck, icons or audio.

1. Duplicate Shop button: the top bar has "Shop" and the left menu has "Shop" too. Keep ONE (the left menu one that opens the Toilet Shop; keep top Hub/Home).
2. Top bar is crowded next to the Roblox menu buttons. Reduce it: keep Hub, Home, and the Luck/Friends chip; move Settings into a smaller icon; keep touch targets >= 44 px and clear of the Roblox top-left menu safe area.
3. Tutorial hint ("Find your toilet / Tap Home to return") sits on the character in the screen center. Move it to the top-center under the top bar or bottom-center above the Flush button, smaller, semi-transparent card.
4. Left menu block (6 buttons) is too large on phones: make the buttons smaller on short/landscape phones (e.g. 2 columns of smaller buttons, or 1 compact column) while keeping touch size >= 44 px.
5. Small texts ("Pending: 0", "Friends +0%", button labels) must be readable: raise minimum text size on phones.

Constraints: no gameplay changes; all 12 viewport sizes in scripts/check-ui.ps1 must still pass (add cases if needed); follow AGENTS.md; commit on branch feature/mobile-ui2, do not push. Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl.
