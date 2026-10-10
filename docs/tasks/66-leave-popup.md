# Task 66: "Leave?" confirmation popup (original design)

Inspiration only: a TikTok "Leave popup" (red/white rounded card, door icon, Cancel + Leave buttons). Do NOT copy any third-party asset; draw an ORIGINAL popup with our existing UI components (C.Panel/C.Button/IconArt vector icons) in the game's style (rounded, bright, bold outlined text, gold/red/blue palette used in src/client/UI).

Roblox limitation: the Roblox menu "Leave" cannot be intercepted. Add an in-game way to trigger it:
- A "Leave game" button at the bottom of the Settings window (src/client/UI/... Settings is built in src/client/init.client.luau). Tapping it opens the popup.
- Popup content (English): title "Leave already?"; door icon; text that matches the real game ("Your displays keep earning while you're away!" plus, if available from the client state, a short line like "Daily reward ready!" when the daily is claimable); buttons "Stay" (primary, big, green/blue, default focus) and "Leave" (secondary, red). Close X = Stay.
- "Leave" asks the server to leave via a validated, rate-limited remote (e.g. LeaveRequest) that calls player:Kick("See you soon! Your displays keep earning.") after the normal save runs (do not skip DataService save/close; kick only after Close/save is triggered or let Kick fire PlayerRemoving normally). No gameplay change, no rewards or pressure tricks (no guilt-tripping text, no fake timers).
- Phone-first: popup fits all phone sizes (844x390, 667x375, 568x320, 390x844, 320x568...), buttons >= 44 px, text >= 14 px, exactly ONE scroll area at most (prefer none), safe areas respected, modal backdrop like other windows, works with the existing open/close routing (HUD open("Leave") or from Settings), closes other modals consistently, ESC/back closes = Stay.
- Sound: reuse existing UI sounds (open/click); no new audio IDs.
- Tests: extend scripts/check-ui-runtime.luau (window matrix, 44 px targets, no nested scroll) and add a small server check that the remote validates the caller and is rate-limited; wire into check-audit if server logic is added.
- Follow AGENTS.md; branch feature/leave-popup, do not push (Git may be sandbox-blocked; leave uncommitted and say so). Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl.
