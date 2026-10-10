# Task 65: Tutorial start does not work properly on mobile

Owner report: "the tutorial does not fully work on mobile, right at the beginning". No further detail. Investigate and fix the FIRST steps on a touch phone (landscape + portrait):

Flow to verify end to end (src/client/UI/Tutorial.luau, Progress, FlushPrompt.luau, HUD.luau, PlotGuidance.luau, hud.Navigation.Home, GO TO TOILET button, Flush button):
1. Player spawns in the hub. Step 1 "1/5 Find your toilet / Tap Home to return to your toilet." The Home button must be highlighted/pointed at and tapping it must teleport the player to their plot and advance to step 2. Check the highlight/pointer target exists and is visible and not covered by other UI (the pointer/arrow, Roblox top-left menu, the new bottom-left coins+luck group, safe areas).
2. Step advance conditions: `prompts.Near()` on touch (no keyboard E prompt): make sure the near-toilet detection also works for touch and that the on-screen Flush / "GO TO TOILET" button flow advances the tutorial correctly. Check Progress.Step conditions for step 1 -> 2 -> 3 on touch.
3. Check the hint card on all phone sizes: readable, does not cover the character/Home button, Skip reachable (>= 44 px), card hidden/shown correctly when a window opens.
4. Check late join/spawn edge cases: respawn, plot assignment delay, hud hidden at start, replay from Settings, tutorial restarting wrongly after rebirth.
5. Check any stuck state: step 1 never advancing, highlight on a hidden button, pointer pointing at (0,0), Skip not working.

## Owner follow-up (must fix)
On phones the tutorial card looks odd: the step counter ("1/5", "2/5", ... "4/5") is not visible. Always show a clear step indicator on phones: title with the "n/5" prefix (e.g. "1/5 Find your toilet") plus small step dots or a thin progress bar, fully visible (no truncation or clipping on any phone size, text >= 14 px). The card should look polished and consistent: icon/pointer, title, one short sentence, Skip button. Keep it compact and not covering the character, Home button or Flush button. Add a test that fails if the "n/5" text is missing or truncated on any phone viewport.

Fix what you find with minimal changes; no gameplay/economy changes. Add runtime tests in scripts/ that simulate the touch flow (TouchEnabled true) for steps 1->2->3 on several phone sizes. Document findings (what was wrong) in docs/research/tutorial-start-mobile.md. Follow AGENTS.md; branch feature/tutorial-mobile, do not push (Git may be sandbox-blocked; leave uncommitted and say so). Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl.
