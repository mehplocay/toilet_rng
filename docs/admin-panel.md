# Owner admin panel

Implemented on `feature/admin-panel`; no commit or push. Economy/income configuration and accounting services are not rebalanced by this feature.

## Access and use

UserId **1212975135** is enabled in `src/shared/Config/Admin.luau`. The associated account name is documentation only: changing or copying a name never changes authorization. This works in published servers as well as Studio when the player's real UserId is allowlisted. Negative mock Studio player IDs have no implicit access.

After the profile loads, an authorized owner receives an **Admin** button and **F2** shortcut. Tabs are built on first visit. Scroll the tab strip horizontally on a phone and the active form vertically. Buttons are at least 44 pixels tall. Inputs support exact catalog IDs, number presets and custom whole numbers. All profile actions affect **only your own profile**; a target UserId is used only as a teleport destination.

| Tab | Tools |
| --- | --- |
| Items | Spawn by exact item ID; 1/10/100/1000 presets and custom counts through 10,000; spawn one directly into an empty display slot; remove unreserved copies; set lifetime collection count (0 hides discovery); give every shipped item x1. |
| Economy | Add/set coins with 1K through 1T presets; set slot pending income; fill current display capacity to configured pending caps; clear server flush cooldown; set toilet tier, each upgrade track, rebirth level, and run/lifetime flush counts. |
| Player | Hub/home/plot/online UserId teleport; bounded speed/jump; fly with normal movement plus Space/Ctrl or touch UP/DOWN; noclip; god mode; temporary pass/cosmetic test unlocks; two-step profile reset. |
| Events | Force a chosen item through the real flush presentation/reveal pipeline; test announcements; activate the configured server luck boost; local Day/Sunset/Night or clock-hour previews and restore. |
| Map / Debug | Server player/memory/heartbeat readings and Workspace instance/part counts; capped local collision/wayfinding overlays; refresh server display/leaderboard labels and rescan the local label registry; eight-second visual dummy reward. |
| Tools | Export the sanitized current profile, including the latest reset backup, into a selectable text box; paste and import JSON through the same sanitizer; refresh the summary. Roblox does not expose an ordinary game-script clipboard API, so copy/paste uses the text box. |

Profile edits are limited to one every five seconds; expensive world tests to one every eight seconds. A shared request bucket allows four immediate requests and refills at two/second. Rejected malformed requests do not perform work. The UI permits one outstanding request and never automatically retries a mutation; after a timeout, refresh before deciding whether to retry.

## Authorization and replication

Add another administrator by adding `[numericUserId] = true` to `Admin.UserIds`, then deploy and replace running servers. Never add username checks. `AllowGroupOwner = true` optionally enables **only the numeric owner of group 711692751**, using `GroupService:GetGroupInfoAsync().Owner.Id`. It does not admit group members, managers or arbitrary role labels. Group access is disabled by default.

The server checks identity on every accepted command, including snapshots, export, visual previews and movement renewals. It checks the Roblox-supplied sender against the private endpoint owner, not a payload. Group lookup runs inside pcall, caches both allow/deny results for 60 seconds, deduplicates in-flight lookups and discards results after departure. Missing owner/error results deny. Platform caching can outlive the application cache; instant external group-revocation is not promised.

Admin LocalScripts/ModuleScripts live in **ServerStorage.AdminClient**. Nothing under `src/admin-client` is placed in StarterPlayer/ReplicatedStorage. Only after authorization and a live profile check does the server clone the folder and its private Command RemoteEvent into that player's PlayerGui, connecting the listener before parenting. Non-admins receive neither this code nor admin State fields, metadata, backups or private responses. The shared Admin configuration is intentionally readable and confers no client authority. Public forced-drop messages carry an explicit admin tag so other players can recognize a test.

Every command has an exact argument whitelist; extra/missing keys and arguments, unknown IDs, NaN/infinity, fractions and out-of-range values reject. Clients cannot choose another profile, object path, asset, script, price, save key, entitlement or RNG chance. Accepted actions log `[ADMIN] accountName (UserId) action arguments` to server output. Import logs its byte length rather than dumping a whole profile. These are operational logs, not a permanent audit database.

## Transactions, provenance and resets

All profile edits construct a separate candidate with `DataService.Sanitize`, use normal Display/SafeInventory and upgrade/index/rebirth/income sanitization rules, sanitize the result again, and commit through `DataService:ReplaceAndSave`. Get settles old income first. Profile identity and save-busy guards prevent concurrent admin transactions; the existing replacing guard blocks gameplay through the lease-checked save. Success follows save and authorization/profile rechecks. There is no rollback after an ambiguous write. Studio `NoPersistence` uses the same sanitizer but makes no store writes and reports **MEMORY ONLY**. Movement, previews, cooldown and server event timers are intentionally session effects rather than durable profile edits.

Coin input is at most 1T per command; the existing 9e15 stored balance ceiling still applies. Item grants cap at 10,000 per request, counters at 1 billion, speed at 100 and jump power at 150. Tier/track/rebirth limits and pending income caps come from the current gameplay configs; no economy values are copied into an admin balance table. Setting a tier/level is an admin override, not a paid purchase or a rebirth reset. Display placement calls the normal reservation API. Removing items may remove protected/first copies deliberately, but cannot remove displayed reservations; the sanitizer clamps protected/provenance counts. Collection state is independent of inventory, and existing index claims are not revoked by hiding a discovery.

`Admin.Touched` marks edited profiles. `Admin.Items[itemId]` records bounded admin-origin inventory counts. Copies are fungible: normal sales/rebirths can make this conservative provenance rather than an exact per-copy ledger. `CountAdminProfilesInRankings` defaults to true. Set it false to omit marked profiles from the physical Top Toilets ranking boards; it does not erase normal player-list identity or rewrite historical landmarks. This profile-level policy also covers coin/import testing. It is not a retroactive item-value subtraction system.

Forced drops award a tagged item and collection discovery, then call the **same FlushPresentation** used by gameplay. They never increment natural flush/run counters, earned service coins, rarest-find stats, best-flush landmark or natural event deduplication. They use separate admin announcement deduplication, show `[ADMIN]`/`[ADMIN TEST]`, and do not implicitly grant luck. Normal audience/opt-out/cooldown rules still apply: common drops have no rare announcement; friends-only Legendary announcements do not become server-wide. Natural presentation sequences remain monotonic when admin edits lower the saved counters.

Reset requires Prepare followed by a matching server-generated, single-use token within 30 seconds, plus typing RESET in the UI. A replaced profile invalidates the confirmation. The reset transaction stores a sanitized pre-reset profile in `Admin.Backup` and its timestamp in `Admin.BackupAt`. Exactly one backup is retained; it excludes nested admin metadata/backups. Another reset replaces it. Export before resetting again. To restore gameplay fields, extract the exported `Admin.Backup` object into the JSON input and import it; the natural rarest-find record is intentionally retained from the current server profile rather than trusted from imported JSON.

Import is capped at 100,000 bytes, 4,096 nodes and depth 10; non-dictionary shapes/cycles/non-finite numbers reject. Known gameplay fields then pass through the load/save sanitizer; unknown fields and imported admin metadata are discarded. Existing backup/provenance protection stays server-controlled, imported inventory is tagged, and the income timestamp is reset to the live high-water mark so import cannot mint offline time.

## Session tools and limits

Flight uses local LinearVelocity only after a server response. Noclip is applied/restored on the server to avoid collision-replication races. Movement/god/test-pass authority expires after 15 seconds without an authorized renewal; the client renews every five seconds, including while the window is closed. A guarded profile save preserves these effects only while the movement and data leases remain valid. Respawn clears movement. God mode is a ForceField plus health refill, not protection from character deletion or every possible instant-death script.

Test unlocks use a separate expiring session flag and a copy of effective pass/cosmetic flags. They never modify Marketplace ownership, receipts, pass IDs, purchases or persisted index claims. They enable the existing pass effects (including FastFlush's configured cooldown and plot-color controls), while the owner sees a local admin-test label. Current index cosmetics are unlock metadata; this feature does not invent unimplemented cosmetic art/equipment. Switch tests off or rejoin to return to actual ownership. Real paid ownership is preserved. Local preview labels/debug overlays are not authoritative.

Lighting previews affect only the owner and restore on request/UI teardown. Overlays inspect currently streamed parts and cap at 300 adornments; toggle again after moving to refresh them. Instance counts cover Workspace, memory covers the server, and heartbeat measures interval rather than CPU time. Dummy models create no economic awards and expire after eight seconds. Group failure on initial join requires rejoining after recovery. Revoking code that a formerly authorized client already received cannot make that code secret again; the server still denies further commands and effects expire.

The existing DataService outage/crash/ambiguous-write durability limits remain. Save acknowledgement is not exactly-once durability across external restores. Keep old profile-sanitizer binaries out of a rollout because they cannot retain new metadata. This admin panel is not a general movement anti-cheat or an offline account editor.

## Verification

Pure checks: `luau scripts/check-admin.luau`. Admin cases are appended by `scripts/check-audit.ps1`; UI constructors/layout/callbacks by `scripts/check-ui.ps1`. Coverage includes allow/deny and name spoofing, private delivery, sender binding, cache/departure, schemas and numeric bounds, token buckets/replay, sanitize/save for every profile command, no normal-State leakage, reset backup/import, held saves/lease loss/NoPersistence, forced natural-board exclusion, movement expiry and separate test entitlements.

Recovery validation (2026-10-06): all **19 standalone** `scripts/check-*.luau` checks pass (audit and UI-runtime files run through their PS1 bundlers); `check-audit.ps1` passes **110 cases**, including 17 admin cases; `check-ui.ps1` passes admin callbacks and **972 layout cases**; `check-visuals.ps1` and `check-world.ps1` pass all six template modes. `stylua --check --line-endings Windows src scripts`, `git diff --check` and `rojo build -o build.rbxl` pass. Run PS1 checks with `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/<check>.ps1` when the shell's default execution policy disables local scripts. Selene was attempted but the installed Roblox standard library is missing; this is not a lint pass.

Desktop (1280x720), portrait (390x722) and short-landscape (640x303) admin layouts were inspected with the existing approximate raster renderer. Numeric input tests cover both fields of pending-income edits, missing/invalid values and cap violations without leaving the UI awaiting a silently rejected request. These are headless engine-double tests, not proof of native rendering, replication isolation or physics. No Studio instances were connected during recovery. Before deployment, run an isolated owner + non-owner session and verify F2/touch/keyboard focus, actual PlayerGui visibility, flight/noclip restoration, all cosmetics, group failures, persistent reset/import/rejoin and a real rare-drop announcement. No live production profile was modified during implementation.

Research: [authorization](research/admin-authorization.md), [runtime and tools](research/admin-runtime.md).

All-pools update (2026-10-07): the item picker uses Config.Items directly. All 47 IDs are available independently of the selected toilet; no per-tier item lists or pool gates exist.
