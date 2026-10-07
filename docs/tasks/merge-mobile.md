Task: RESOLVE MERGE CONFLICTS in this worktree (a `git merge feature/mobile-hud` into main is in progress; do not abort, do not commit, do not push).
Conflicted files: src/client/UI/HUD.luau and scripts/check-ui.ps1 (find the markers with grep -n "<<<<<<<\|>>>>>>>").
Intent of each side:
- main (HEAD) came from fix/social-text: the old social text block/panel (SocialBoosts big text) was removed; the Passes window has one small muted "Invite friends for extra coins" link; HUD keeps the small social chip. Luck has no cap anywhere (no cap markers).
- feature/mobile-hud: compact phone rail, free thumb zones, readable FLUSH/AUTO, promo badges, collapsible status chip, window/tutorial fits.
Keep BOTH intents: take the mobile-HUD layout work and keep the social-text removal and no-luck-cap behaviour. For check-ui.ps1 keep both sides' test-runner entries. Do not drop any test.
Then run: stylua --line-endings Windows on the touched files, rojo build -o build.rbxl, all scripts/check-*.luau that exist, scripts/check-audit.ps1, scripts/check-ui.ps1, scripts/check-visuals.ps1, scripts/check-world.ps1. Fix only fallout caused by the merge. Short honest report: what you resolved, results of each check, anything failing.
