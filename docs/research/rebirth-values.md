# Stronger rebirth rewards: API and numeric review

2026-10-06. No asset IDs or paid luck added.

- Luau uses IEEE-754 doubles; exact integers end at 2^53. Retain the stricter 9e15 ceiling, the saved 6000 subcoins/coin scale and compare-before-multiply ledger settlement. https://luau.org/syntax/
- Highlight exposes Adornee, FillColor, OutlineColor and Occluded depth mode. Use one static character aura and one toilet skin glow per Legend, with no frame worker or economic effect. https://create.roblox.com/docs/reference/engine/classes/Highlight
- The platform raised the Highlight limit to 255 in November 2025; this implementation still creates at most two per Legend. https://devforum.roblox.com/t/lights-camera-more-highlights/4061534
- Trails join two Attachments; Color updates existing segments. Reuse one free rebirth trail and attachments, and destroy them when the level is removed; paid effects retain their own identity. https://create.roblox.com/docs/reference/engine/classes/Trail
- Keep the existing single OnChatWindowAdded callback. Add a fixed config tag using a server-published level; retain the filtered original PrefixText and independent VIP prefix. https://create.roblox.com/docs/chat/in-experience-text-chat
- Rojo build serializes the place; StyLua supports check and Windows line endings. Neither establishes native engine rendering. https://rojo.space/docs/v7/getting-started/new-game/ and https://github.com/JohnnyMorganz/StyLua

Baseline issue: this worktree omitted the explicit TextChatService configuration that check-audit.ps1 requires before running scenarios. Restored the default channels and enabled chat window additively; no custom chat system added.
