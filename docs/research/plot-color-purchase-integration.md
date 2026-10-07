# Plot color / purchase UI merge (2026-10-07)

- Checked the current GuiObject and UIStroke references before merging visibility and selection controls. Preserve the Lucky eligibility/deadline checks and use a separate StyleFeedback label in the scrolling style section; purchase refusals and the 10-second timeout retain PurchaseMessage. Neither result should overwrite the other feature's feedback.
  https://create.roblox.com/docs/reference/engine/classes/GuiObject
  https://create.roblox.com/docs/reference/engine/classes/UIStroke
- MarketplaceService still documents GetProductInfoAsync as yielding and GetProductInfo as deprecated. Preserve the existing protected asynchronous metadata refresh, server-derived ownership, Owned marks and purchase flow. PolicyService documents ArePaidRandomItemsRestricted; preserve fail-closed eligibility and policy expiry.
  https://create.roblox.com/docs/reference/engine/classes/MarketplaceService
  https://create.roblox.com/docs/reference/engine/classes/PolicyService
- Checked MeshPart and the existing solid-finish research. Retain the incoming reversible tint implementation and imported geometry. The DevForum tint release body and release-notes index did not expose usable additional contract details in this session.
  https://create.roblox.com/docs/reference/engine/classes/MeshPart
  https://devforum.roblox.com/t/full-release-surfaceappearance-tinting/3129960
  https://create.roblox.com/docs/release-notes
- Rojo documents binary place builds; StyLua documents Windows/CRLF line endings. Both are used for this merge's validation.
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua
- Audit and UI runners retain both branches' suites; the audit runner also executes the plot-color UI integration checks. Added coverage for color confirmation during a pending purchase, timeout/result message isolation, tab visibility and restoration after Lucky-policy expiry.
- User explicitly requested preserving the current merge on main, without committing or aborting. Git cannot stage resolutions in this sandbox: its worktree index resolves outside the writable workspace and creating index.lock is denied. Content resolutions are complete; index marking requires the manager's writable Git session. Selene cannot load the configured roblox standard library. Headless checks do not replace a live Studio/multi-client acceptance test.

Verification: StyLua --line-endings Windows and --check on all 11 changed Luau files; rojo build -o build.rbxl; all 25 check-*.luau files (23 standalone, audit/UI-runtime via their PowerShell harnesses); balance.luau; check-audit.ps1 (351 regressions plus plot-color UI checks); check-ui.ps1 (both feature suites and 972 viewport cases); check-visuals.ps1; check-world.ps1 (Empty/Ready/Mixed/Invalid/Scaled/Late). All passed. Both runners retain every Luau suite/helper reference from both merge stages. Conflict-marker and git diff --check scans are clean. Only index staging and Selene are blocked by the environment.
