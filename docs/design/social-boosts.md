# Social boosts

All values are in `src/shared/Config/SocialBoosts.luau`. Group and friends boost coins; qualified invites grant free luck. Base prices and speed are unchanged. Luck has no design cap; only technical finiteness checks remain.

| Bonus | Factor | Applies to | Conditions |
|---|---:|---|---|
| Group | 1.10x | Coins | Server verifies membership in Dreadlight Studio, 711692751 |
| Friends | 1 + 0.05 x count | Coins | Server-verified friends present in this server; max 11 / +55% |
| Qualified invite | 1.20x | Luck | Invited user joins via Roblox referral, stays 300 seconds and completes 20 successful flushes in that visit |

Group and friend factors multiply together, then with existing free upgrade/rebirth/toilet factors and paid cash factors. They apply through the common cash layer to flush service coins, sales, display income and income-based commerce quotes. Invite luck never changes these coin factors, online or offline. It multiplies with the other free luck sources in the shared server formula: `toiletLuck * (1 + luckUpgrades + rebirthLuck) * invite1.20 * server * daily * eligibleVIP1.25 * eligibleDoubleLuck2 * reviewedCharge10`. Invite luck is free and stays active with restricted, missing, failed or expired paid-random-items policy results. The roll path reads only the cached profile expiry and current server time, with no yields or platform lookups. Fixed milestone/daily grants keep their existing definitions. Display storage capacities keep their existing base/upgrade/paid rules, so ending a social boost cannot truncate stored earnings during save. Whole-coin rounding follows existing rules.

## Membership and friendship

On profile load, check `IsInGroupAsync` with `pcall`. Recheck every 300 seconds or after the Check again action (30-second budget shared with the cached next-check time). Errors and false results remove the bonus. Successful first detection shows “Group bonus unlocked!”. Membership and friend state are never restored from the saved profile.

Roblox documents a server-side membership cache which can persist until rejoin. **A membership change is removed/applied at the next check that reflects that change; immediate freshness cannot be guaranteed by this API.** The UI explicitly mentions rejoining. Current Roblox actually has `GroupService:PromptJoinAsync`, despite the original task premise; the requested group name, ID and roblox.com/groups instructions are retained, with no client-reported membership accepted. See the research file.

One cached friendship record per live unordered pair; at most 66 pairs for 12 players. Use current `IsFriendsWithAsync`, not its deprecated predecessor. Successful results last until either player leaves; failed checks deny the factor and retry after 60 seconds. In-flight work checks both original session objects after yielding. Removing a player immediately updates the remaining players and removes pair entries. Friendship changes while both players remain may need a rejoin due to Roblox's cache. No per-frame network work or yielding during economy math.

Studio group/friend network lookups default off. API-enabled tests can opt in with `StudioLookups`, and mocks exercise both outcomes/errors without platform calls.

## Referrals, durability and bounds

The button requests a rate-limited server acknowledgement, then the local client calls `CanSendGameInviteAsync` and `PromptGameInvite`, both protected. No payload is accepted for either new remote. The standard platform modal handles account, privacy and device restrictions. There is no invented age check or PolicyService invite flag. Closing the modal resets UI only. Its recipient list is deprecated/empty; there is no client reward-completion endpoint.

Only the server's `GetJoinData().ReferredByPlayerId` identifies an inviter. Six attempts, two seconds apart, accommodate delayed join metadata. `LaunchData`, teleport data, FollowUserId and client assertions never authorize rewards. The same invitee session must reach five minutes and twenty actual successful server flushes; admin grant/edit counters do not count. Leaving resets incomplete qualification.

**Scope refinement: inviter and invitee must be in the same server when qualification is processed.** If the inviter is absent, the candidate waits while the invitee remains in that server; an inviter rejoining it can receive the reward. No cross-server/offline reward mailbox is introduced. This condition appears in the UI and marketing text. Referral users do not need a pre-existing Roblox friendship (Roblox supports this); the stay/flush conditions and limits provide the anti-spam constraints.

`Social` profile v1 stores `InviteExpires`, UTC `Day`/`DailyCount`, sorted `Rewarded` IDs and `HistoryFull`. A missing old field migrates to no reward. Existing v1 InviteExpires timestamps retain their exact expiry and now activate luck; no coins, charges, new duration, daily awards or history entries are minted. Numbers are finite and bounded; invalid/oversized history fails closed. The permanent dedupe history holds at most 4,096 IDs and **never evicts**. Once full, new awards stop, which preserves “once ever” rather than allowing old invitees to earn again. Both daily (5) and lifetime (4,096) limits appear in UI/text.

Award dedupe, daily count and expiry are changed in one replacement profile, then saved under the existing session lease/exclusive mutation guard. No yield occurs between validation and mutation. Duplicate requests cannot independently save a reward. Uncertain writes use the existing fail-closed DataService behavior; rejoin loads the complete committed profile or the prior profile. Rebirth preserves the social record, and owner reset/import preserve social award history just like commerce history. Admin display is read-only and uses existing owner authorization.

Each award adds 1,800 seconds to `max(now, InviteExpires)`, capped at 86,400 seconds ahead. It extends duration, not bonus strength. At a full duration cap the candidate waits rather than consuming an ID. A full daily budget waits for a later UTC day while the invitee remains. Backward time never resets that budget.

## Time, offline income and UI

As with existing Path Boost (`Monetization.PathExpires`), invite expiry is an absolute Unix timestamp: **offline time counts down**. Every roll checks expiry directly, so a flush at or after expiry loses invite luck even before the periodic social sync. Group and friends apply only to verified online earnings; offline accrual never trusts a persisted membership/friend cache. Invite expiry has no effect on display settlement, offline income or coin quotes. Offline time still consumes invite luck duration; no offline rolls or reward mailbox are introduced.

The HUD chip shows `Friends +15% (3)` and `Invite luck +20%` with the active timer. The HUD luck breakdown and Lucky Flush odds window list `Invite luck x1.2` with the same expiry. All displayed outcome probabilities come from the production roll distribution including invite luck. Expiry changes review tokens and invalidates armed charges without consuming them; stale windows close and must be reviewed again. It remains visible outside drop/coin presentation and opens the Passes & Style window. The window contains no social bonus explanation or status block; its only social control is the small, muted `Invite friends for extra luck` text button beside Refresh passes. The button is shown only when `SocialService:CanSendGameInviteAsync` permits invites, then requests the rate-limited server acknowledgement before opening `PromptGameInvite`. The server still validates the request, and referral qualification and rewards remain server-authoritative. Roblox documents capability checks as platform/player dependent and recommends checking before prompting: https://create.roblox.com/docs/production/promotion/invite-prompts and https://create.roblox.com/docs/reference/engine/classes/SocialService. No tutorial popup interrupts onboarding.

`docs/marketing-description.md` did not exist in this worktree, so a new proposed description starts exactly “Welcome to Toilet RNG!”. The owner must paste/publish it in Creator Hub. Optional referral banner copy must include the same qualification and limit conditions; no Creator Hub publishing was performed.

## Balance expectations

| Scenario | Social coin factor | Invite luck factor | Fixed-rate coin-gate time vs typical |
|---|---:|---:|---:|
| No group, 0 friends, no invite | 1.000x | 1.00x | 100.00% |
| Active invite only | 1.000x | 1.20x | 100.00% |
| Group only | 1.100x | 1.00x | 90.91% |
| 3 friends only | 1.150x | 1.00x | 86.96% |
| Group + 3 friends + active invite | **1.265x** | **1.20x** | **79.05%** |
| Group + 11 friends + active invite | 1.705x | 1.20x | 58.65% |

The time column is an analytical constant-loadout comparison, not a simulated end-to-end pacing claim: rounding, flush gates, RNG, expiry, storage and purchases affect progression. No base economy retuning. The normal/casual/grinder baseline suites and the social rate table are recorded with validation results.

Invite changes rare-first item outcomes only. With a fixed collection/loadout, service coins, sales per item, display rates, offline accrual and coin packs are unchanged by invite activation. Better drops can indirectly improve later collection/sale income. Expected flush comparisons assume invite remains active for each modeled roll, not that a 30-minute award lasts until the rarest drop. See [invite luck validation and balance](invite-luck-validation.md).
