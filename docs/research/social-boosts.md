# Social boosts research — 2026-10-07

Checked current Creator Docs, official Roblox announcements, Community Standards, Terms and tool documentation before implementation.

## Supported incentives and privacy

- Roblox explicitly supports in-experience referral rewards, including currency. Use server `GetJoinData().ReferredByPlayerId`; all players can earn referral rewards. Invitations also support users who are not yet Roblox friends. One-time awards and cooldowns are recommended. The experience must have been live for at least one day for the referral feature. Creator Hub referral banners are separate publishing work and must describe actual conditions accurately.
  https://create.roblox.com/docs/production/promotion/referral-system
- Native invite flow: first `CanSendGameInviteAsync` in `pcall`, then `PromptGameInvite` in `pcall`, only after an explicit button press. Optional `ExperienceInviteOptions.LaunchData` is limited to 200 characters and may arrive late. We do not need launch data and never accept a client-supplied inviter or award based on opening/sending an invite.
  https://create.roblox.com/docs/production/promotion/invite-prompts
- `GameInvitePromptClosed` only closes UI state; its `recipientIds` array is **no longer populated**. It is not proof that a friend accepted an invitation.
  https://create.roblox.com/docs/reference/engine/classes/SocialService
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/SocialService.yaml
- `PolicyService` describes policy-specific features; there is no documented `CanInviteFriends` / under-13 flag to invent. `AllowedExternalLinkReferences` is now a legacy empty array, not permission to show external social links. Use the native invite capability check for account/platform restrictions. No custom friend picker, external sharing, chat, contacts access or inferred age is implemented. Account age is not a player's age.
  https://create.roblox.com/docs/reference/engine/classes/PolicyService
- Official DevForum platform change: online-status privacy affects `GetFriendsOnline`; Roblox recommends native invite prompts and the referral program. In-server friendship checks do not enumerate absent friends' presence.
  https://devforum.roblox.com/t/upcoming-changes-to-the-getfriendsonline-api/3632813
  https://devforum.roblox.com/t/connecting-with-confidence-on-roblox-introducing-trusted-connections-age-estimation-and-privacy-tools/3820020
- Community Standards and Terms prohibit scams, misleading content and spam. This implementation offers transparent, optional, free game-coin benefits, not Robux, money, paid random items or off-platform incentives. No reward for likes/favorites, bulk auto-invites or payment requirement. No blanket prohibition on the requested free membership perk was found in the reviewed rules; that is a scoped interpretation, not a Roblox approval.
  https://about.roblox.com/community-standards
  https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use
  https://about.roblox.com/en-au/youth-guide-to-community-standards

## Server APIs, caches and limits

- `Player:IsInGroupAsync` and `Player:IsFriendsWithAsync` yield; the older non-Async names are deprecated. Cache results outside economy mutations and protect calls with `pcall`. Roblox itself caches these methods. In particular the documented group cache can retain membership after leaving a group until the player rejoins. Repeated server calls cannot promise fresh membership; our UI states the rejoin limitation, removes the perk when a check returns false, and fails closed on errors.
  https://create.roblox.com/docs/reference/engine/classes/Player#IsInGroupAsync
  https://create.roblox.com/docs/reference/engine/classes/Player#IsFriendsWithAsync
  https://create.roblox.com/docs/reference/engine/classes/Player#GetJoinData
- Contrary to the task's premise, current `GroupService` does provide `PromptJoinAsync`. It clears relevant caches only on the prompting client. We keep the requested group-name/ID + roblox.com/groups instructions and server Check again flow, rather than treating a client prompt response as membership evidence. Docs recommend `IsInGroupAsync` for membership instead of fetching the entire `GetGroupsAsync` list. No proxy endpoints or client-authoritative refresh workaround.
  https://create.roblox.com/docs/reference/engine/classes/GroupService
- `Players:GetFriendsAsync` returns paginated friends, requiring more yielding requests. With only 12 players, pair checks need at most 66 unique pairs, removed on leave. We do not fetch an entire friends list or poll every frame.
  https://create.roblox.com/docs/reference/engine/classes/Players#GetFriendsAsync
- No numeric per-minute quota for these group/friend/invite methods is promised in the consulted references. App limits are conservative local budgets, not claimed Roblox quotas: group check 30 s / periodic 300 s, failed friendship retry 60 s, native invite request 30 s. Only one lookup per player/pair can be in flight. Join data retries are bounded. Studio lookups default off via config.

## Tool verification

Rojo build verifies project assembly; it does not replace engine integration tests. StyLua supports Windows line endings and verification. Selene requires Roblox standard-library definitions. Headless UI harnesses validate geometry and callbacks, not Roblox-rendered screenshots or real invite delivery.

- https://rojo.space/docs/v7/
- https://github.com/JohnnyMorganz/StyLua
- https://kampfkarren.github.io/selene/roblox.html
