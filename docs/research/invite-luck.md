# Qualified invite luck research - 2026-10-08

- Roblox's current paid-random-items guidelines distinguish free earned actions from direct/indirect Robux purchases. Inference for this implementation: qualified referral luck is a free factor; existing paid VIP/2x/charge checks remain unchanged. Actual paid-enhanced outcome odds must include every active factor.
  https://create.roblox.com/docs/production/monetization/paid-random-items
- Invite button copy changed only; the existing protected capability check and platform prompt remain. Current docs still recommend CanSendGameInviteAsync with pcall before PromptGameInvite.
  https://create.roblox.com/docs/production/promotion/invite-prompts
- Cached Unix expiry remains server-authoritative via os.time. Client invite disclosure uses cached server InviteRemaining minus elapsed os.clock time, matching the existing social timer. No client clock authorizes a reward or roll.
  https://luau.org/library/
  https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow
- Build/format docs checked: Rojo supports binary build.rbxl; StyLua supports Luau and configurable line endings. Installed tools are used with --line-endings Windows.
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua
- Release-note index checked; this change adds no new platform API dependency. The first DevForum topic lookup was unavailable. A follow-up search found an October 2026 live-client zero-timestamp report (full page blocked by browser verification); this is a report, not a verified platform-wide diagnosis. The invite countdown avoids depending on that estimate; absolute expiry stays server-owned.
  https://devforum.roblox.com/t/workspacegetservertimenow-returns-0-on-client-for-entire-session-in-live-servers/4909426
  https://devforum.roblox.com/t/getservertimenow-is-expensive-to-call-compared-to-datetimenow/3906060
  https://create.roblox.com/docs/release-notes

Selene was attempted with the repository configuration. Installed 0.31.0 reports a missing roblox standard library and exposes no Roblox generator in its help/capabilities. This matches the previously recorded tool limitation; no globals or lint checks were disabled.
https://kampfkarren.github.io/selene/roblox.html
