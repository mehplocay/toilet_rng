# Rare-find chat and native player list

2026-10-06. Branch feature/chat-native-list. No commit or push.

## Behavior

- Default preference is **Chat messages: Rare+**. Every accepted natural Rare-or-better result has a finder-only line: **You found Fish (Rare, 1 in 80)!** Colored rich text uses the catalog rarity color; Secret uses the existing readable purple substitute. The displayed denominator is the catalog base check, not the luck-adjusted outcome probability.
- **All** additionally reports Common/Uncommon to their finder. **Off** suppresses incoming drop/rebirth lines. These preferences are persisted as Settings.ChatMessages through the existing profile sanitizer/save path; legacy ChatAnnouncements=false becomes Off, true/missing becomes Rare+. The compatibility boolean remains synchronized. The existing rate-limited patch cannot write economy/audio fields; conflicting boolean/enum requests are rejected.
- The first low-rarity result appears immediately once chat is ready. Subsequent Common/Uncommon/Rare results within four seconds form one bounded counter/best-item entry, e.g. **You found 7 items (best: Rare Fish)!** Each result is counted once. Epic+ self lines are individual. No per-flush friendship wait or spawned timer delays the finder.
- Epic/Legendary additionally reach in-server friends; Mythic/Godly/Secret reach the other eligible server players. The finder gets one private line, never an additional broadcast copy. The existing cross-player five-second sender gaps, high-water dedupe, 16-entry cap, 15-second TTL and single yielding worker remain. Rebirth retains its previous friend/server audience and shares the broadcast limiter.
- Forced previews retain **[ADMIN TEST]**, independent dedupe and separate low-rarity aggregates. They do not record natural Rarest. Account identity is bounded/sanitized; catalog names are escaped. No client payload can announce a drop to another client.
- Finder aggregates also cap at 16 pending entries with 15-second TTL. Opt-out, preference changes, profile replacement, expiry, removal and shutdown invalidate delayed delivery. Lower-rarity traffic is at most one finder line per four seconds in a continuous stream; exceptionally rare Epic+ results remain individual.

## Native UI

The custom ServerPlayers GUI, custom Tab listener, row sorting/formatting loop and Settings open button are removed. The small PlayerList module only enables CoreGui PlayerList once, with retries for up to 15 seconds if CoreScripts are unavailable. Roblox owns Tab, topbar, controller/touch support, collapse state and layout. Settings contains an informational native-list hint. No new HUD frame or input interception is added.

Server PlayerListService publishes, in this order:

| Stat | Type | Source |
|---|---|---|
| Coins | NumberValue; IsPrimary=true; Priority=3 | Sanitized numeric wallet, 0..9e15 |
| Rebirths | IntValue; Priority=2 | Existing sanitized rebirth level |
| Rarest | StringValue; Priority=1 | Saved natural best item's rarity, or None |

Only changed values are assigned, with one-second polling. Missing/expired profiles and departing players release the folder/cache. Coins remains numeric for primary-stat sorting; native compact formatting is left to Roblox. NumberValue represents every integer through 9e15 exactly (below 2^53). IntValue is int64 and would also hold this cap; no int32 limitation is assumed. Native suffix case/rounding/very-large labels are not a stable documented API. No inventory, income, admin, settings or session data is published. The project has no Teams and neutral plot spawns, so no custom grouping is required.

## Files and integration

- src/server/Services/AnnouncementService.luau, PresentationService.luau, PlayerListService.luau.
- src/client/Presentation/ChatAnnouncements.luau, Controller.luau, PlayerList.luau, SettingsUI.luau; four additive startup/wiring lines in src/client/init.client.luau.
- New src/shared/SelfAnnouncementQueue.luau; additive enum/audience/timing changes in PresentationSettings, PresentationRules and Config/Presentation.
- default.project.json explicitly configures modern chat, default channels and enabled chat window/input. No runtime server DisplaySystemMessage call or duplicate TextChannel is created.
- scripts/check-audit.ps1 adds audit-chat-native.luau and audit-chat-client.luau plus a project-configuration gate. Existing presentation/rebirth/UI tests now assert finder delivery and the native-list contract. The UI double gained actual StarterGui state and FindFirstChildOfClass behavior.

Economy, RNG, luck, upgrade/rebirth/auto/offline configuration, DataService and FlushService are untouched. Existing persistence integration automatically preserves the new setting.

## Validation

- StyLua full src/scripts check, rojo build -o build.rbxl, git diff --check.
- All 21 standalone scripts/check-*.luau pass; the two bundle-dependent checks run through their PS1 runners.
- check-audit.ps1: **150 passed, 0 failed** (ten added cases, existing regressions retained).
- check-ui.ps1: all runtime suites and **972 layout cases** pass.
- check-visuals.ps1 and check-world.ps1: imported binaries and all six world modes pass.
- Selene attempted; configured roblox standard library is missing, so no clean lint claim.

The harness exercises actual grant → EventService observer → private remote payload → production client → colored DisplaySystemMessage call, including Studio-style single-player recipients, missing/default channels, startup failure/retry, TTL, cap, opt-out and teardown. It does **not** run Roblox CoreScripts or render their UI. Studio discovery found build.rbxl in Play; execute_luau was rejected by automatic approval because approval policy is never. Live chat rendering, exact native abbreviations/sort and overlay behavior remain unverified.

## Remaining Studio acceptance

1. Open the new build.rbxl or sync this branch; start solo Play. Check TextChatService modern chat, default channels, enabled chat window and CoreGui Chat/PlayerList. There must be no ServerPlayers GUI.
2. Use the existing private admin forced-drop control for Fish/Duck/Golden Poop/Mythic/Secret. Verify one colored finder line with ADMIN TEST, and no Rarest change. Flush naturally to verify an untagged line and natural Rarest.
3. Cycle All → Rare+ → Off and rejoin. Test rapid low finds, opt-out during a pending summary, and chat startup. Check no duplicate lines from the Event VFX route.
4. In a two/three-player server, verify Epic/Legendary friend-only additions, Mythic+ server recipients and recipient opt-out. Finder must never get the broadcast copy.
5. Use existing Studio admin currency/rebirth tools to inspect native Coins values 1,200,000; 3,400,000,000; 9e15. Confirm actual compact labels, three-column order and numeric Coins sorting. Press Tab twice; verify native collapse behavior and HUD usability on desktop/phone safe areas.

Research: [chat](../research/chat-native-system-messages.md), [native list](../research/native-player-list.md), [tools](../research/chat-native-tools.md).
