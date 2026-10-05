# Audit 2: system chat and identity

Checked 2026-10-05.

- [TextChannel official source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/TextChannel.yaml): `DisplaySystemMessage` runs on the client, displays locally and does not automatically filter/localize its content. An exploiter can change their own display; that does not authorize messages to other players.
- [Chat window formatting](https://create.roblox.com/docs/chat/chat-window): rich-text formatting is supported. Escape interpolated markup rather than relying on the display layer to strip it.
- [Rich-text regression report](https://devforum.roblox.com/t/rich-text-is-currently-non-functional-in-textchatservice/3426768): historical formatting regressions were reported. This is a reason to test the actual engine rendering, not to remove application escaping or assume a current platform defect.

Existing chat uses server-chosen catalog IDs, bounded account names and escaped catalog text; no arbitrary user message is relayed. Added an injection regression through the production client renderer. Event banners now also identify `Player.Name`, sanitized through the same helper, instead of impersonable DisplayName. Ordinary plot/leaderboard display names remain literal, non-rich text. Any future free-form announcement text will require the appropriate Roblox filtering flow in addition to escaping.
