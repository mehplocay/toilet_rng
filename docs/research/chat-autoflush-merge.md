# Chat and auto-flush merge integration

Checked 2026-10-06.

- [Official TextChatService source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/TextChatService.yaml): ChatVersion can be serialized; legacy mode disables modern chat. CreateDefaultTextChannels creates RBXGeneral and RBXSystem at runtime. Explicitly configure modern chat, default channels and an enabled ChatWindowConfiguration in the Rojo project. [Rojo project format](https://rojo.space/docs/v7/project-format/) documents `$className` and `$properties` serialization.
- [TextChannel API](https://create.roblox.com/docs/reference/engine/classes/TextChannel) and [leaderboards guide](https://create.roblox.com/docs/players/leaderboards) were rechecked; retain local system-message delivery and server-authored numeric leaderstats. [Release 741](https://devforum.roblox.com/t/release-notes-for-741/4906281) was checked; its body was unavailable through the fetcher. No dependency on new chat/history behavior was introduced.
- Integration finding: finder chat arrives immediately or as a counted low-rarity summary. The audience worker must never send the finder a second drop line. Finder reveals already supply sound, so finder chat stays silent to preserve quiet batched auto-flush feedback; other players' announcements retain their sound.
- [StyLua](https://github.com/JohnnyMorganz/StyLua) documents file arguments/check mode. Local tool help is used for Selene validation; its documentation endpoint was unavailable.
