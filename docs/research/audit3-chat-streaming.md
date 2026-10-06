# Audit 3: chat and streaming (2026-10-06)

TextChatService filters ordinary chat. DisplaySystemMessage is local and does not automatically filter arbitrary supplied text. Our rare-find/rebirth messages originate on the server, use bounded account names and catalog data, and escape RichText. Plot signs accept no custom text. Adding custom player text later requires filtering, not merely escaping markup.

Streaming can remove Workspace descendants without destroying them; replication order is not guaranteed. Client registries need removal/rearrival handling, and clients cannot establish authoritative ownership/distance from what is currently loaded. Reviewed prompt/label/effect registries, persistent owned toilets and bounded navigation retries. Streaming recovery, avatar replication and actual GPU/memory costs require Studio/device traversal.

Sources:
- https://create.roblox.com/docs/reference/engine/classes/TextChannel/DisplaySystemMessage
- https://create.roblox.com/docs/chat/in-experience-text-chat
- https://create.roblox.com/docs/workspace/streaming
- https://devforum.roblox.com/t/is-displaysystemmessage-automatically-filtered/3074392
