# Catalog 2 + rebirth merge

The existing merge into main is retained at the user's explicit request. No commit, push, abort or branch switch is performed.

## Cosmetic composition

- Chat order: configured earned rebirth tag, one VIP/Star tag, native filtered name prefix. Premium VIP replaces the cheap Star Tag's star with the VIP label, including when both or Ultimate Bundle are owned. Rainbow Name wins over Golden Name. Each tag retains its own color; repeated callbacks start from the original message and cannot duplicate our tags. Chat bodies are untouched.
- Trails: highest unlocked rebirth trail (Legend color at R15) > VIP gold > Sparkle Trail. There is no trail selection UI or saved trail preference in either branch. Exactly one trail and two attachments are active; only a selected paid trail has the single sparkle emitter. Changing level/ownership updates or removes effects, rather than accumulating instances.
- Plot trim: earned rebirth color on the inner border; VIP gold on the outer border, separated by 2px. VIP's plot badge remains. Legend toilet skin and Toilet Glow coexist because they decorate separate objects.
- Character effects and hidden native name distance are cleared/restored on respawn and leave. Client companions, celebration selection and confetti are cleared on character removal; per-player event connections are disconnected on leave. Plot effects and custom colors reset on leave. A stale owner's removal cannot erase a reassigned plot.

## Economy and validation

Both audit registries execute: rebirth rewards and extended catalog. Preserve premium VIP's 1.5x cash multiplier and the shared 10x cash cap, including R15, as well as the free R5 Auto Collect and permanent R10 slots. Bundle/individual ownership grants no slots; all ten slots remain free, and saved legacy capacity is retained. Existing receipt, policy, odds, RNG, remote-validation and rate-limit coverage remains enabled.

Added shared UI/audit regressions cover all 16 rebirth levels across eight paid-trail ownership combinations, bounded/repeated construction, both trim layers, revocation, respawn, leave, reassignment and 48 chat combinations. A server scenario covers R10 together with overlapping VIP and Ultimate Bundle across reset/rejoin. Catalog effect tests also verify respawn clears companions and confetti.

UI icon checks retain all 37 existing upload mappings. Unuploaded catalog artwork uses the existing empty/vector fallback or an already verified upload; tests reject invented IDs. The audit bundler now reads UTF-8 explicitly.

## Pacing integration

The requested `balance.luau` initially reproduced the failure already documented by the rebirth-rewards branch: normal R5 at 1.725h (minimum 2h) and R15 at 65.25h (minimum 80h). Stronger rewards also accelerated early upgrade milestones. The instruction to fix every failure was interpreted as authorization to retune coin gates while retaining the full reward table, cash/luck stacking, speed floors, toilet/upgrade prices, permanent progression and existing balance assertions.

| Gate | Before | Merged |
| --- | ---: | ---: |
| R3 | 35M | 100M |
| R4 | 100M | 400M |
| R5 | 500M | 900M |
| R15 | 2.5T | 7.5T |

All other gates and starter grants remain unchanged. This changes future eligibility, not saved rebirth levels or already earned perks. Short diagnostic cohorts were used to choose gates; they do not replace the required full `scripts/balance.luau` run. No production balance assertion was loosened or removed. The stairs regression reads the configured coin gate while still checking the exact rendered sentence and bonuses.

The full normal/casual/grinder balance run and deterministic replay passed. Normal p50: Galaxy 36.43 minutes, R1 24 minutes, R5 2.58 hours, R15 96.01 hours (R15 p90 135.01 hours). All upgrade-milestone and passive-income bounds also passed. [Full measured output and cohort assumptions](catalog2-rebirth-balance.txt).

## Runtime limits

Headless tests exercise production modules through engine doubles; native chat rendering, layered UIStroke appearance, live Marketplace/PolicyService and mobile performance still require Roblox Studio/published-place QA. No live Roblox session is asserted here.

## Files and verification

Conflict resolutions: `scripts/audit-path-catalog.luau`, `scripts/check-audit.ps1`, `src/client/VIPChat.luau`, `src/server/Services/CosmeticService.luau`. Integration changes: `src/client/CatalogEffects.luau`, `src/server/World/RebirthCosmetics.luau`, `src/shared/Config/Rebirth.luau`; both PowerShell test registries, UI/security fixtures and regression scripts; this report and linked research/economy notes. Incoming catalog implementation remains included.

| Check | Result |
| --- | --- |
| StyLua format and `--check` | All changed Luau files pass |
| `rojo build -o build.rbxl` | Pass |
| All `scripts/check-*.luau` | 21 standalone passes; audit and UI runtime run through PowerShell |
| `scripts/check-audit.ps1` | 239 passed, 0 failed: 235 retained union scenarios plus four integration scenarios |
| `scripts/check-ui.ps1` | Pass, including merged cosmetics, catalog, rebirth and 972 viewport/layout cases |
| `scripts/check-visuals.ps1` | Pass |
| `scripts/check-world.ps1` | Pass: Empty, Ready, Mixed, Invalid, Scaled, Late |
| `luau scripts/balance.luau` | Pass: full normal/casual/grinder cohorts, original timing bounds and deterministic replay |
| Source conflict markers / `git diff --check HEAD` | None / pass |
| Selene | Attempted; unavailable Roblox standard library/build support, no lint pass claimed |

## Git index limitation

All four conflicted working files are marker-free. `git add` failed with permission denied creating `C:/Users/mehme/Toilet rng/.git/worktrees/toilet-balance/index.lock`, outside the writable workspace. Git therefore still lists four unmerged index entries. The manager must stage the resolved files and reviewed integration edits from a writable environment. MERGE_HEAD remains present; no commit, push or abort was performed. Unrelated files arriving during this session were left untouched.
