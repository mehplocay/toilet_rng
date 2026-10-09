# Task 61 — phone window review

Base: task 60 merge `dc4351b`. Branch: `feature/mobile-windows`. No server, economy, luck, audio or asset-ID changes. `Assets.IconImages` and the resolved-image pipeline remain intact.

| Window / surface | Problem and change |
| --- | --- |
| Toilet Shop — Toilets | Outer window and card grid both scrolled; two navigation rows wasted height. Fixed shell and one tab strip, one vertical grid, compact toilet cards with name, stats, price and action. |
| Toilet Shop — Coin Upgrades / Upgrades entry | Same nested scrolling; Buy was below extensive explanatory text. One vertical grid; price and Buy now immediately follow the heading. Both HUD entries still route to their respective tab. |
| Passes | Outer/inner scrolling, a different close-button size, long unwrapped descriptions, unavailable gift clutter. Shared 44 px close; fixed tabs; one list; wrapped descriptions; full-width Buy; hidden unavailable Gift. |
| Coins tab | Shares the single offer list and fixed tabs. Purchase feedback, refresh and invite no longer occupy overlapping footer coordinates. |
| Lucky tab | A third scrolling viewport existed inside each offer. Rarity disclosures now grow the card and grid at their measured 17 px text height. Complete odds remain available, with the existing review-before-purchase behavior. |
| Collection / Index | Outer, grid and horizontal filters were nested. Filters and Rewards/Items stay fixed; search, counters, slot entry and a non-scrolling item grid share one vertical list. Wider cards, taller names and 8 px action gaps. |
| Index rewards | Nested list and cramped progress beside Claim. One list; full-width progress and Claim in each card. |
| Display slots | Removed the redundant outer scrolling shell. Slot choices share one grid. |
| Rebirth | Two narrow disclosure columns and fixed oversized text regions. Disclosures stack on narrow screens; subsequent sections are measured and spaced before the unchanged confirmation action. Phone success uses the existing toast rather than a second overlapping celebration. |
| Daily reward | Two scrolling areas separated reward cards from the claim controls. One continuous list, with countdown and Claim near the top, then the reward grid. |
| Settings | Removed the outer scrolling viewport. All preferences, slider targets, replay and presentation controls remain in one list. No audio settings behavior changed. |
| Offline income | Existing single scroll retained; explicit recentering prevents the custom window size from inheriting an offset from tutorial layout. |
| Luck / Lucky odds dialogs | Already used one measured text list and fixed confirmation. Included full item disclosures and final-action reachability in the new phone matrix. |
| Boost details / status chips | Existing single-list details retained and reviewed. Collapsed phone chip remains the entry point; short-phone top-row placement corrected. |
| Celebration effects | Existing single content list retained and covered with an owned-pass fixture. |
| Hub / Home | These are direct teleport buttons, not a separate window. Existing handlers retained; touch targets and safe bounds covered by the expanded HUD matrix. |
| Right-side offer buttons | Existing phone behavior hides the decorative offer rail; Passes and Daily remain reachable from navigation. Regression coverage retains this behavior. |
| Tutorial | On short phones an open window now takes priority over the guide card. The target highlight remains; closing the window restores the guide and Skip. Taller screens retain the guide strip. |
| Reveals / result toasts | Corrected collapsed reveal geometry and toast/Flush overlap on very short screens. Short reveal text uses a compact odds line; cinematic discovery badges have a readable fixed height. Existing durations and skip behavior retained. |
| Developer / admin UI | Developer Tools uses the fixed shell. Admin preset choices use a wrapping grid instead of a horizontal scroll nested in the vertical page. |

Shared components reject creation of any ScrollingFrame below another ScrollingFrame, including a horizontal one. Tests also inspect completed trees for nested scrolling. Each active window page has exactly one vertical viewport; tab strips, where horizontally scrollable, are siblings outside it. The shared header remains 58 px with a 44 × 44 px close button; text starts at 12 px without window-scale shrinking.

Validation matrix: landscape 844×390, 932×430, 667×375, 740×360, 568×320 and 1170×540; portrait 390×844, 430×932, 375×667, 360×740 and 320×568. Tests subtract conservative Roblox/device/home-indicator insets before laying out the production UI. `check-ui-runtime.luau` checks 16 window pages at all 11 sizes, fixed close/header placement, a single vertical viewport, reachable final actions, 44 px targets, 8 px sibling-control spacing and text fit at the 12 px minimum. All nine reveal rarities are also constructed at each size. The existing phone HUD suite adds 932×430, 667×375 and 568×320.

Review uses production constructors with mocked engine boundaries plus offline raster snapshots. It does not replace a Roblox Studio device emulator or physical-device touch/scroll review. Font measurements are approximate in the harness; native line wrapping, notch variations and inertial scrolling remain device QA items. Selene is installed but cannot load the workspace's missing `roblox` standard-library definition; StyLua is used for the changed Luau files.

Changed implementation files: shared UI construction/layout; Shop/UpgradeTracks, Collection/IndexRewards, Passes, Rebirth, Rewards, OfflineIncome, HUD, Tutorial and Reveal; presentation layout/controller/signature; client bootstrap and admin preset layout. Regression files cover the new runtime matrix and the affected purchase, routing, tutorial, luck, social, rebirth and mobile HUD hierarchies. Official API findings are in `docs/research/mobile-windows.md`.

Verification:

- `check-audit`: 431 passed, 0 failed.
- `check-visuals`: passed.
- `check-world`: passed, including 49,152 friend cases and 15,542 reachable samples.
- `rojo build -o build.rbxl`: passed.
- StyLua on all changed Luau files and `git diff --check`: passed.
- Focused phone matrix, all nine reveal rarities, purchase/social/plot-color, tutorial, huge coin values and mobile HUD checks: passed.
- Full `check-ui`: passed, including the 16-page/11-size phone matrix, nine reveal rarities, existing behavioral regressions and 972 layout cases.

Git: the workspace is on `feature/mobile-windows`. Staging is blocked by the sandbox: Git cannot create `C:/Users/mehme/Toilet rng/.git/worktrees/toilet-mobilewin/index.lock` (permission denied). Changes remain uncommitted for the manager to review and commit. Nothing was pushed.

Temporary `.task61-*` logs, focused runners and offline snapshots remain untracked. Automatic approval review rejected their cleanup, including an explicit list of workspace-contained directories, with `blocked by policy`; no more specific reason was supplied. These files are review artifacts, not implementation files to commit.
