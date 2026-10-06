# Removing paid display capacity
2026-10-06, feature/remove-extraslots.

- Creator Docs assigns pass privileges through server-side PlayerAdded ownership checks and PromptGamePassPurchaseFinished. Removing a config/order entry prevents the existing lookup, prompt and callback dispatcher from granting it. Keep the remaining pass verification unchanged.
  https://create.roblox.com/docs/production/monetization/passes
  https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#UserOwnsGamePassAsync
- DevForum reports stale ownership responses; release 350 introduced caching. Do not use a negative lookup or retired ownership flag to subtract saved capacity. The new migration drops obsolete commerce metadata while retaining valid DisplaySlots (existing 1-100 schema).
  https://devforum.roblox.com/t/promptgamepasspurchaseuserownsgamepassasync-not-working/3785874
  https://devforum.roblox.com/t/release-notes-for-350/168280
- Reviewed the release-notes index and current engine reference. No new Marketplace API or cache-duration dependency is introduced by this removal.
  https://devforum.roblox.com/c/updates/release-notes/62
- Rojo documents rojo build -o build.rbxl for a binary place. StyLua documents --check as a non-writing format verification.
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua#--check-checking-files-for-formatting

All ten physical display slots remain available through coin upgrades, index rewards and rebirth. VIP and the bundle grant no slots; the bundle retains the other fourteen passes and no consumables. Headless fixtures verify handlers and saved profiles, not live billing.