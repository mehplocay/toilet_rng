# UI overhaul review

Branch: `feature/ui-overhaul`. No commits or pushes. Research and source links: [ui-quality.md](../research/ui-quality.md).

## Screens and components

- `src/client/UI/Components.luau`: shared outlined, gradient/gloss buttons with hover/press tweens and optional sound hook; centered animated panels, pills/chips, rarity cards/glow, count badges, progress bars, scrollable tabs, toasts. FredokaOne headings and BuilderSansBold supporting text; 44px minimum action heights.
- `HUD.luau`, `Layout.luau`: square navigation, Hub/Home/Shop travel tabs, Settings, coin count-up, FLUSH with idle hand/bounce and a segmented cooldown ring, adjacent free Auto-Flush, timed luck chips, responsive offers and best-flush display hook.
- `Collection.luau`, `IndexRewards.luau`, `Upgrades.luau`, `Passes.luau`, `Rewards.luau`: all existing browsing, filtering, selling, displays, tier purchases, index claims, daily claims, pass ownership/price lookup and plot colors remain wired to existing remotes.
- `Tutorial.luau`, `CoinPopup.luau`, `Reveal.luau`, `FlushPrompt.luau`, `Effects.luau`: heavy center guidance, animated reward amounts, rarity reveals/shine, custom world prompt, event banners. Settings and Studio-only developer panel use the same panel/card system in `init.client.luau`. The own-plot billboard also uses shared chrome.
- `IconArt.luau` and `Preview.luau`: layered frame/glyph illustrations for navigation, every item and every toilet. UI previews no longer construct ViewportFrame models. Assets are optional; `ImageLabel.IsLoaded` controls fallback visibility.

## Asset handoff

All image and sound values live in `src/shared/Config/Assets.luau`. UI uses `Icons` (Coins, Shop, Collection, Upgrades, Daily, Home, Hub, Teleport, Settings, Flush, Luck, Crown, Passes, Pointer), `ItemIcons[item.Id]`, `ToiletIcons[toilet.Id]`, and optional `Sounds.Click`. Numeric IDs or Roblox content strings work. Zero/empty/missing values retain the fallback; unavailable images also retain it. No external IDs were invented. Model builders and mesh hooks were not changed by this UI task.

## Layout grid

All measurements are inside the full-size child of a `CoreUISafeInsets` ScreenGui. There is no extra camera-inset subtraction or global downscale. `Layout.Compute` is used by HUD, event and reveal positioning; the same module is executed in tests.

| Viewport | Tested safe content | HUD | Collection columns |
| --- | --- | --- | --- |
| 1920 × 1080 | 1920 × 1044 | Left column, right offers, bottom action | 5 |
| 1280 × 720 | 1280 × 684 | Left column, right offers, bottom action | 5 |
| 375 × 812 | 375 × 690 | 56px left icons; separate coin/boost/action rows; offers hidden | 2 |
| 812 × 375 | 724 × 318 | 50px icon row below travel; center action between thumb corners | 4 |
| 1024 × 768 | 1024 × 712 | Tablet column; action/currency above touch controls | 5 |
| 768 × 1024 | 768 × 968 | Tablet column; offers hidden | 4 |
| 1170 × 540 | 1116 × 483 | 19.5:9 landscape, asymmetric notch, compact navigation | 5 |

Desktop navigation uses a 12px gap. Grid cards use 14px gaps and at least 132px width for collection cards. Passes and daily rewards cap at four columns. Panels use 12px outer margins, at most 1060 × 730px, a pinned 58px title bar/44px close button, and a scrollable body of at least 540px content height. Short landscape scrolls this body instead of shrinking actions. Touch layouts reserve bottom-left 130 × 120px and bottom-right 110 × 120px for Roblox movement/jump controls.

Opening a modal hides the HUD and adds a click-blocking dim backdrop. Backdrop/close and gamepad B dismiss it. A reveal temporarily replaces the center hint/best board; an event banner replaces travel/best board. Coin animation travel is clamped to its available space so it cannot cross the reveal. These transient states are checked as well as the idle HUD.

## Audit fixes and behavior

- **M3 client:** cards are created lazily on opening/filtering and cached by item ID. Snapshots update only changed card state; previews change only when discovery changes. Callbacks resolve sell amounts and display slots from the latest snapshot. Hidden collections do not create/update item cards. No per-State workspace sound traversal: one startup registration plus DescendantAdded; snapshots set SoundGroup.Volume only. Progress bars avoid restarting unchanged tweens.
- **M2:** already fixed in this branch before this task: FlushService uses MonetizationRules.InRange (finite and nonnegative) and MonetizationService.Distance requires a living Humanoid. Existing audit regressions verify invalid/foreign distances. No server files changed.
- FLUSH sends only the existing no-argument Flush remote. E/gamepad retain the proximity-prompt path, avoiding duplicate keyboard dispatch. Cooldown UI follows server Result.Cooldown; it does not award items or currency. Auto-Flush still uses the existing server toggle/unlock.
- Top Shop travels to the replicated showcase and opens Upgrades; left Shop opens that same existing shop without moving the character. Home uses PlotCFrame; Hub uses Hub.SpawnPad.
- The luck offer opens existing Daily Rewards; no new paid randomness, fabricated price or sale countdown was added. Zero-ID passes remain unavailable. The best-flush board tracks observations since this client joined (local results plus existing server event broadcasts), with no persistence or historical server query.

## Verification and limits

Run `scripts/check-ui.ps1` to bundle the actual UI modules against the UI test double and execute `check-ui-layout.luau`. Runtime coverage includes full client boot, every screen constructor, hidden/diffed collection updates, current sell callbacks, disabled inputs, image-loaded fallback changes, Flush remote/cooldown, sound registration without State scans, claim badge, Settings, DEV panel, tutorial, events, coin/reveal presentation and modal suppression.

Optional offline review: `scripts/check-ui.ps1 -SnapshotDirectory .ui-review`, then `scripts/render-ui-review.ps1 -SnapshotDirectory .ui-review -FontDirectory <Roblox content/fonts>`. The ignored PNGs are drawn from the generated UI trees and were visually reviewed and iterated. They are explicitly labeled **headless approximations**, not Studio screenshots: engine clipping, font fitting, opacity compositing, tween timing and GPU behavior may differ.

Verified: StyLua check on changed Luau; compilation of changed client scripts with `luau-compile`; `rojo build -o build.rbxl`; every existing `check-*.luau` (audit/runtime files through their bundling runners); all 28 `check-audit.ps1` regressions; `check-visuals.ps1` (hub 840 parts, worst plot plus transient drop 333, largest item/toilet 30); new full-client UI runtime tests and all seven layout cases; `git diff --check`. Selene was attempted but this environment lacks its configured Roblox standard library, so no Selene pass is claimed.

Studio execution was unavailable: automatic approval rejected `execute_luau` under approval policy `never`. Browser preview surfaces were also unavailable, so local offline rasterization was used. Still untested in Studio/on devices: actual text and image rasterization, image fetch failures, touch and nested scrolling, safe-area/platform variations, live purchase prompts, network delay/respawn behavior, animation smoothness and target-phone performance. Final top-game visual signoff needs that engine/device pass.
