# Auto-flush anywhere and idle guard

2026-10-06; `feature/flushanywhere`. Supersedes the proximity restriction in older audits/design notes. No changes to item odds, prices, the 100 lifetime-flush unlock or manual/prompt proximity.

Auto-flush is an explicit session toggle, off on join. A connected living character with its assigned owned plot can auto-flush anywhere, including hub and paths. There is no auto distance requirement or new island-boundary geometry check. Death, character removal, missing ownership or invalid data session stops the toggle; respawn does not silently re-enable it. Manual and auto reserve the same cooldown and consume the same Flush bucket (2 burst / 3 per second). Existing Auto-Flush Speed progression remains 2x to 1x the manual cooldown, never faster; the floor is 0.4s. No delayed/catch-up rolls occur.

`Config/AutoFlush` owns the 1,800-second guard, final-five-minute countdown, 15-second input coalescing and compact presentation tuning. Input notifications carry no arguments. Server rate limit is 1 burst / 0.1 per second. The server stores last accepted activity, active uptime and paused state. Missing guard state denies awards. Accepted input resumes a paused toggle, while an absent client heartbeat eventually pauses it. Repeated enable requests do not reset activity; explicitly switching off/on is treated as input. Client input is telemetry, not a human-presence security boundary.

The HUD switch beside FLUSH shows state and running uptime; the final five minutes show an idle countdown. Pausing shows **Still there? Tap to continue**. Input from keyboard, touch, mouse or meaningful analog movement resumes; UI-consumed input counts. Stationary stick drift, focus changes and timer ticks do not count. Focus loss discards queued input. Activity may be coalesced by up to 15 seconds, so pause timing is approximately 30 minutes after the last actual input. No passive display income is paused.

Far auto results are compact: no world toilet animation/water audio, service-coin popup, cinematic viewport or camera shake. One reused toast shows a found item and the additional-find count, retaining the rarest item in each three-second batch. A trailing batch is displayed even when flushing stops. Class sounds use quarter gain and existing admission limits. The owner's far-away event effect is suppressed; existing rare/friend/server chat rules and authoritative server-luck awards remain. Near results retain existing presentation.

Roblox's documented native idle disconnection can happen at 20 minutes, before this 30-minute prompt. The implementation does not prevent that disconnection. This and the client telemetry limitation are intentional assumptions; see [research](../research/flushanywhere-idle.md).

Regression modules: `scripts/audit-flushanywhere.luau` and `scripts/ui-flushanywhere.luau`, included by the audit/UI runners. They cover real auto/manual handlers, travel, cooldown/token sharing, unlocks, death, lease loss, idle transitions, input coalescing, cleanup and bounded compact presentation. Studio must still verify physical touch/gamepad input, idle disconnect behavior, streaming traversal, near/far audio and mobile rendering.

## Verification

- `check-audit.ps1`: **162 passed, 0 failed** (140 existing plus 22 new scenarios). Historical full-rate offline fixtures now explicitly expect 50%; the manual/auto merge fixture enables the actual lifetime unlock before invoking auto.
- All 21 standalone `check-*.luau` pass; the audit/UI runtime files pass through their PS1 bundlers. `check-ui.ps1` includes the new window/input/audio tests and all 972 existing safe-area layouts.
- `scripts/balance.luau` passes every income-first target with paid modifiers off. Online progression is unchanged; the intentional offline-rate reduction is separately covered across all eleven tank levels with and without Offline Plus.
- `check-visuals.ps1`, all six `check-world.ps1` modes, `stylua --check --line-endings Windows src scripts`, `rojo build -o build.rbxl` and `git diff --check` pass.
- Selene was attempted; its configured `roblox` standard library is unavailable. No lint-pass claim. No Studio/live DataStore/device session was used. All changes remain uncommitted on the requested branch.

Reviewed headless UI approximations: [phone return window](flushanywhere-previews/away-360x518.png), [desktop](flushanywhere-previews/away-1280x684.png), [landscape scrolled to Collect](flushanywhere-previews/away-640x303.png), [idle prompt](flushanywhere-previews/idle-390x722.png). These are rendered from the actual UI fixture trees, not engine screenshots. Reproduce with `check-ui.ps1 -SnapshotDirectory <directory>` and `render-ui-review.ps1`.

Primary changes: `MonetizationService`, `FlushService`/`FlushPresentation`, `IncomeService`, `IncomeAccrual`, `PlayerActivity`, `UI/OfflineIncome`, HUD, reveal/audio controllers, two config additions and additive State/remote wiring. No map builders, catalog prices, receipt/lease implementation or asset IDs were changed. The offline designation passes through the existing income sanitizer and lease-protected save without a new datastore.
