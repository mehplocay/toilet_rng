# Display/audio merge

Checked 2026-10-06 while resolving Collection's merge conflict.

- [RemoteEvent](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent): FireServer is asynchronous and does not confirm success. Preserve the existing Feedback.State audio: slot additions play DisplayPlace, slot removals play DisplayReturn, and confirmed inventory/coin deltas play Sell/SellAll. This handles additional copies and either card or per-slot returns without duplicate optimistic success cues.
- [GuiButton](https://create.roblox.com/docs/reference/engine/classes/GuiButton) and [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject): Activated handles cross-platform activation; Interactable=false blocks clicking. Preserve shared panel/tab/button sounds and DisplayLocked disabled feedback on both display actions.
- [Rojo build](https://rojo.space/docs/v7/getting-started/new-game/) and [StyLua](https://github.com/JohnnyMorganz/StyLua): retain binary build and Luau formatting validation.
- [Release notes](https://devforum.roblox.com/c/updates/release-notes/62): checked; browser returned the verification wall. No changed platform behavior is assumed. Existing mixer cue gaps and voice limits remain unchanged.
