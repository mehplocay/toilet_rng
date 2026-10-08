# Independent visual and UX review

Date: 2026-10-07. Worktree: `toilet-visrev`; branch: `feature/visual-review`. Changes are intentionally uncommitted. Scope: the player-facing results already implemented, reviewed against `docs/GDD.md`, `docs/reference/mockups.png`, and `docs/design/ui-style-guide.md`.

The review rendered and visually inspected the headless UI outputs, including scrolled content, all 47 collection icons, every tutorial step, all nine reveal rarities, and four Blender world views. This is a **headless review**, not a Roblox Studio/device playtest. No live purchases were made. Official API/tool research is recorded in [visual-review research](../research/visual-review.md).

## Findings and fixes

| ID | Finding | Fix and regression coverage | Final state |
| --- | --- | --- | --- |
| V01 | Passes tabs (40 px), collection search (42 px), Slots (36 px), and the portrait/short-landscape luck target (34/42 px) were below the requested 44 px minimum. | Raise these controls to 44 px; inspect actual `AbsoluteSize` for visible buttons/text boxes across 12 viewports in `ui-visual-review.luau`; extend layout assertions. | Fixed. |
| V02 | Collection filters, Slots, and the first card row needed more separation after increasing touch sizes. | Move Slots and the grid down; assert Slots ends before the grid begins. | Fixed; cards remain scrollable. |
| V03 | The luck disclosure could escape the safe area, draw behind wallet/travel siblings, and coexist with the full odds dialog. | Make it a direct HUD child with explicit stacking and responsive bounds; eligible users open the read-only odds dialog alone. Assert parent/stacking, safe bounds, and separation from social/flush controls. | Fixed, including 360x518 and 640x303. |
| V04 | The luck chip did not show the 10x cap below the cap, contrary to the style guide. | Show a second `Cap 10x` line; preserve the compact capped state and update exact-text regressions. | Fixed. |
| V05 | The celebration toggle used a fixed position that competed with HUD content and remained above unrelated overlays. | Give it a layout rectangle; reserve portrait space beside Pending; hide it during tutorial/hints, luck disclosure, other modals, toasts and reveals. Add bounds/pairwise layout coverage; retain existing celebration lifecycle tests. | Fixed. |
| V06 | Touch tutorial step 2 instructed players to press E. | Use touch-specific copy and assert that it contains no E-key instruction. | Fixed. |
| V07 | Tutorial positioning lagged modal/toast visibility changes until the polling interval. | Refresh immediately on HUD and toast visibility signals; regression checks inspect the immediate modal transition. | Fixed. |
| V08 | The portrait tutorial panel extended into the social boosts target by 8 px. | Use an 88 px panel at y=192; assert a gap before Social Boosts at portrait sizes. | Fixed at all tutorial steps. |
| V09 | Collection ownership/available counts bypassed the shared compact number formatter. | Use `C.Commas` consistently; inspect huge-value fixtures alongside existing coin-bound tests. | Fixed. |
| V10 | Poop's reveal advertised `Base check • 1 in 2`, although Poop is the guaranteed fallback after the independent rolls. | Display `Fallback drop`; add a production-controller assertion. RNG is unchanged. | Fixed. |
| V11 | The tutorial/farewell could cover the HUD-opened luck odds dialog because that dialog leaves the HUD visible. | Treat this dialog as a modal for tutorial placement/highlighting; react immediately to its visibility. Add active-step and farewell regressions at all 12 sizes. | Fixed; guide stays above the dialog. |
| T01 | Offline previews omitted Wave 1 images and some text properties; GDI's rectangle text path could drop the final glyph (observed on VIP's “luck”). | Resolve the Wave 1 manifest through centralized runtime IDs; capture/render placeholders, scaling, wrapping, minimum font size and top alignment; position unwrapped glyph paths by their measured bounds. | Preview corrected; VIP copy needs no shortening. |
| T02 | The map renderer assumed every source mesh lived at the generated-assets root, missing the Wave 1 Suds Slug mesh. | Resolve a unique nested `.blend` candidate when the root file is absent. | Four current world views rendered and inspected. |

No further visible typo, missing collection icon, wrong rarity color, or requested stale feature wording was found in the inspected states. “Star Tag” is consistent. Locked toilet **tiers** remain valid; shop copy correctly says all 47 items can drop from every toilet. No server RNG, rewards, prices, remote validation, policy rules, or asset IDs were changed.

## Final state by window

| Surface | States inspected and final result |
| --- | --- |
| HUD | Shop, Rebirth, Index, Upgrades, Passes, Daily, Pending, coin counter, luck/cap, social boosts, auto-flush/auto-collect running/waiting/paused, and result toast. No unresolved overlap in reviewed states. Offers collapse at small sizes. Huge wallet/Pending values stay bounded. |
| Shop / Upgrades | Real HUD buttons select the correct tab/title. Toilet cards, permanent upgrades, prices, ownership/locked states and scrolled purchase actions remain reachable. Cash text describes multiplication without the removed 40x/3x cap. |
| Passes & Style | Passes/Boosts/Lucky tabs, owned marks, disabled/coming-soon states, VIP +25% luck, 2x Luck, plot color swatches and all four coin packs inspected. Existing regional restrictions remain intact. Mock purchase prices in review fixtures are not live prices. |
| Lucky / odds | Top explanation, rarity totals, all 47 wrapped item rows, bottom Poop fallback row and scroll access inspected. Eligible HUD disclosure is read-only. Unavailable-policy fallback stays within the HUD safe area. |
| Index / Collection | All 47 cards/icons and nine rarity groups checked, including Star Tag naming and the intentional `???` item name. Search, rarity filters, Slots, first/last cards, ownership and display actions remain separated and reachable. |
| Rebirth | Explanation, current/next cash multiplier and confirmation action inspected. Existing mouse/touch/gamepad tests verify immediate single-click behavior and pending-request protection; no hold instruction remains. |
| Tutorial | Steps 1, 2, 3, display guidance, 4 and 5 captured at every size. Highlights and overlay reposition on modal changes; touch copy is appropriate; Skip remains available under the existing reveal/toast rules. |
| Settings | Music and SFX sliders with 60%/70% fixture values, previews, reveal controls and Replay tutorial inspected, including scrolled content. |
| Daily | Seven reward cards, ready/up-next states, reset countdown and Claim action inspected at all sizes, including scrolled Claim on short screens. |
| Celebration | Responsive toggle placement inspected in HUD captures; overlay visibility corrected. Existing effect start/stop, ownership, intensity and cleanup tests pass. |
| Reveals | Common, Uncommon, Rare, Epic, Legendary, Mythic, Godly, Celestial and Secret frames inspected at all 12 sizes. Presentation tests exercise timing, skipping, reduced/off settings and cleanup. Poop now says `Fallback drop`. |
| Numbers | Existing suffix/scientific-bound tests plus rendered huge fixtures cover wallet, Pending, shop, upgrades, passes/coin packs, collection and rebirth. Review fixtures include `1.23e100` coins and values above Qa. Shared formatter retained. |
| World | Overview, hub, plot and boards rendered with current scene data. Saturated environment, signs, paths, plots and surrounding props inspected. Six asset-readiness modes pass world checks. |

## Final state by viewport

Dimensions below are the **usable UI root after insets**, matching the harness snapshots, not physical display resolutions. `OK/S` means visually checked, with long content reachable by scrolling; it does not mean every row appears simultaneously. `OK*` is subject to the headless limitations below.

| Safe viewport | HUD / toast | Shop / Upgrades | Passes / Lucky / odds | Collection | Rebirth | Settings / Daily | Tutorial, every step | Reveals, 9 rarities |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1920x1044 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 1280x684 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 375x690 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 724x318 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 1024x712 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 768x968 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 1116x483 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 711x751 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 711x731 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 360x518 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 390x722 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |
| 640x303 | OK | OK/S | OK/S | OK/S | OK/S | OK/S | OK | OK* |

The 640x303/724x318 layouts intentionally scroll the modal body while keeping the close button available. A partially visible row at a scroll boundary is not inaccessible text. No redesign of that established behavior was attempted.

## Evidence and reproduction

Selected reviewed images are preserved in [visual-review/](visual-review/): item contact sheets (all 47), tutorial sheets (all 12 viewports), representative window and reveal sheets, native-size HUD/luck/VIP images, Daily and routing sheets, and a world overview. Images are labeled as headless approximations. Snapshot generation and image rendering are separate steps.

The `contact-odds-tutorial-*` sheets use an empty odds fixture specifically to prove guide/dialog separation. Populated odds tables are shown in the window sheets. Window capture setup waits for the preceding suite's six-second tutorial farewell to expire.

Run from the repository root; this machine requires `powershell -NoProfile -ExecutionPolicy Bypass -File` for `.ps1` scripts. Supply the local Roblox `content/fonts` directory to the renderer for Fredoka/BuilderSans.

```powershell
./scripts/check-ui.ps1 -SnapshotDirectory .ui-review
./scripts/check-visual-review.ps1 -SnapshotDirectory .ui-review-focused
./scripts/check-visual-review.ps1 -HUDOnly -SnapshotDirectory .ui-review-hud
./scripts/check-visual-review.ps1 -TutorialOnly -SnapshotDirectory .ui-review-tutorial
./scripts/check-visual-review.ps1 -RevealsOnly -SnapshotDirectory .ui-review-reveals
./scripts/render-ui-review.ps1 -SnapshotDirectory .ui-review-focused -FontDirectory '<Roblox content/fonts>'
./scripts/contact-ui-review.ps1 -SnapshotDirectory .ui-review-focused
./scripts/check-audit.ps1
./scripts/check-visuals.ps1 -World -Snapshot
./scripts/check-world.ps1
rojo build -o build.rbxl
```

Run focused capture modes sequentially: they share a temporary generated bundle. `render-ui-review.ps1 -Pattern` and the contact-sheet helper allow reviewing one state or viewport without rerendering everything.

## Validation and limitations

Selected successful runner output is saved in [check-results.txt](visual-review/check-results.txt).

- Rojo build: passed. Modified/new Luau formatted and checked with `stylua --line-endings Windows`.
- All 26 standalone `scripts/check-*.luau` scripts: passed. `check-audit.luau` and `check-ui-runtime.luau` are bundle fragments and were exercised through their `.ps1` runners.
- UI layout: 972 cases passed, including safe areas, pairwise HUD bounds, touch corners and modal/grid space.
- Audit: 405 passed, 0 failed (including the final tutorial/odds regression).
- Full `check-ui.ps1`: passed; focused window/HUD/tutorial/reveal runs also passed. The full runner includes the new window/control assertions; `-HUDOnly` additionally covers real routing, fallback bounds and Daily captures.
- `check-visuals.ps1 -World -Snapshot` and `check-world.ps1`: passed. World modes: Empty, Ready, Mixed, Invalid, Scaled and Late.
- Balance scripts passed: `balance`, `rebirth-balance`, `income-balance`, `social-balance`, `vip-luck-balance`, `wave1-balance`, `all-pools-risk`, `all-pools-odds`, `no-cash-cap-payer`, and `rebirth-values-simulations`. Audit balance/value fragments passed within the audit runner.
- Selene was attempted but **could not run linting**: installed 0.31.0 cannot load the configured `roblox` standard library and offers no Roblox-generation/update command. Configuration was not weakened.
- The GDI renderer approximates fonts, strokes, gradients, tween frames and clipping. It does not render the 3D model inside cinematic ViewportFrames; empty cinematic centers in these PNGs are a renderer limitation, not evidence that a live model is absent. Headless presentation/world tests cover model construction separately. Live asset permissions/loading, engine rasterization, physical touch ergonomics, sound quality and device performance remain unverified.
- The legacy `preview-world.py` did not accept the current scene format; the current `preview-map.py` produced the inspected four views. Existing tracked map-preview images were preserved; selected new evidence lives only under this review directory.
- Automatic approval review rejected recursive cleanup of the generated `.ui-review*` directories with `blocked by policy`. Temporary captures/logs remain untracked in the worktree; they are not additional production changes.

Production changes are confined to `UI/{Layout,HUD,Collection,Passes,Tutorial}.luau`, `DancePackEffects.luau`, and `Presentation/RevealController.luau`. Supporting harness/test/renderer changes are in `scripts/`; writes there succeeded, so no detached patch files are needed. No commits or pushes were made.
