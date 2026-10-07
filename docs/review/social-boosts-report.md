# Social boosts review

Branch: `feature/social-boosts`. No commit or push.

Implemented server-verified group and in-server friendship bonuses; native friend invites; activity-qualified, durable, once-per-invitee rewards; coin-layer integration; HUD/Boosts UI; owner-only read-only status; migration, documentation and proposed experience description.

| Scenario | Social coin factor |
|---|---:|
| Typical: no group, no friends, no active invite | 1.000x |
| Group + 3 friends + active invite | **1.518x (+51.8%)** |
| Group + 11 friends + active invite | 2.046x |

No prices, base rates, luck or speed were retuned. Cash caps were already removed on this branch. The [rate table](../design/social-boosts-balance.txt) uses actual production math and distinguishes rate comparisons from end-to-end pacing.

| Typical archetype, social bonuses off | Dirty p50 / p90 minutes | Galaxy p50 / p90 minutes |
|---|---:|---:|
| Normal | 1.47 / 1.57 | 35.47 / 44.24 |
| Casual | 3.42 / 3.92 | 60.27 / 74.62 |
| Grinder | 1.07 / 1.25 | 29.51 / 36.09 |

Full [base balance](social-boosts-base-balance.txt), [Wave 1](social-boosts-wave1-balance.txt) and [all-pass cohort](social-boosts-payer.txt) outputs are retained. All target assertions and deterministic replays passed. Long simulations used the existing Luau native-code options (`--codegen -O2`); unoptimized duplicate attempts were stopped.

## Files

| Area | Files |
|---|---|
| New config / pure rules / server service | `src/shared/Config/SocialBoosts.luau`, `src/shared/SocialBoostRules.luau`, `src/server/Services/SocialBoostService.luau` |
| Persistence, cash, qualification, wiring | `DataService`, `UpgradeRules`, `IncomeAccrual`, `FlushService`, `Config/Remotes`, server/client init |
| UI | New `src/client/UI/SocialBoosts.luau`; `HUD`, `Layout`, `Passes`, `UpgradeTracks` |
| Owner admin | `src/server/Admin/Runtime.luau`, `Mutations.luau`, `src/admin-client/Window.luau` |
| Documentation | [Research](../research/social-boosts.md), [design](../design/social-boosts.md), [marketing description](../marketing-description.md) |
| Test integration | [Patch for 11 scripts](social-boosts-tests.patch): audit and UI harness extensions, 24th standalone check, social balance report, visual dependency bundle |

## Validation

**Filesystem limitation:** Windows denies all access to the original `scripts/` directory, including known individual files. This was already present at the start; Git consequently reports its tracked files as deleted. This task did not delete or modify that directory. The user was notified while implementation continued.

For verification, the readable Git HEAD versions were materialized in `.social-validation/`, extended there, and run against this worktree's actual `src/`. The script changes are supplied as a normal `scripts/...` patch. `git apply --check` passed against a separate HEAD fixture. **Restore access and apply/review that patch before merging; original-script integration remains blocked.** It cannot be checked against any inaccessible uncommitted edits in the original directory.

| Check | Result |
|---|---|
| `rojo build -o build.rbxl` | PASS |
| StyLua verification / whole `src` check, Windows line endings | PASS |
| Standalone `check-*.luau` (bundled entry points run below) | 24 PASS |
| `check-audit.ps1` | 383 PASS, 0 failures |
| `check-ui.ps1` + targeted social / invite / authoritative cash UI cases | PASS |
| UI geometry | All 12 named viewports + 960 additional combinations PASS |
| Offline raster review | 12 social views rendered; mobile/desktop and scrolled invite views inspected; invite-button scroll reachability checked at all 12 viewports |
| `check-world.ps1` / nested `check-visuals.ps1` | All 6 modes PASS |
| All-pass normal/casual/grinder cohort | PASS |
| Normal/casual/grinder base balance and Wave 1 balance | PASS, including target assertions and seeded replay |
| Selene | Blocked: installed tool cannot find the configured `roblox` standard library |

Coverage includes group true/false/error, cooldowns, friendship join/leave and stale callbacks, actual flush qualification, spoofed prompt/launch results, inviter return and invitee departure, UTC limits, duration/expiry, migration/corrupt history, dedupe across rejoin, in-flight and ambiguous committed saves, and immutable history through owner import/reset.

Headless fixtures do not certify live Roblox invite delivery, group backend cache freshness, engine-rendered pixels or production DataStore availability. No connected Studio session or Creator Hub configuration was changed.

Review images: [mobile](social-boosts-mobile.png), [desktop](social-boosts-desktop.png), [invite conditions](social-boosts-invite-mobile.png).

Automatic approval review rejected cleanup of the temporary validation directory with “blocked by policy”, without a more specific reason. `.social-validation/`, `.social-ui.generated.luau` and `.social-preview.generated.luau` therefore remain as temporary, uncommitted validation artifacts; do not include them in the feature commit. Permanent review outputs and the script patch are under `docs/review/`.

## Deliberate assumptions / limits

- Roblox documents referral currency rewards. No rewards for merely opening/sending invites, no Robux incentives, and no client claims. The native capability check gates restricted accounts/devices; no invented PolicyService age/invite flag.
- Roblox may cache group membership until rejoin. Checks deny errors/false results, but cannot guarantee a fresh backend result every 30/300 seconds. UI explains rejoining. Current docs do have `GroupService:PromptJoinAsync`; requested website instructions were retained.
- The inviter must be in the invitee's server when qualification is processed. Returning there works while the invitee remains. No cross-server/offline award mailbox. Incomplete qualification resets when the invitee leaves.
- Invite time runs offline, matching Path Boost. Only the still-active portion affects offline income; membership/friendship bonuses require verified online state.
- At 4,096 lifetime invitees, new invite rewards stop. Never evicting IDs preserves once-ever semantics with bounded profiles. Limit is disclosed in UI/description.
- `docs/marketing-description.md` was absent, so a new proposed description was created with the required opening. Owner publishing and any Creator Hub referral banner remain manual.
