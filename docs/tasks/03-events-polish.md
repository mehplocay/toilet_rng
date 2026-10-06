Task 3 (branch feature/events is checked out; do NOT commit, the manager commits). Read AGENTS.md, docs/GDD.md, docs/foundation.md and look at docs/reference/mockups.png (bottom-left panel "rare drop server event"). ALL in-game text English.

1. Server events: any drop with Event=true (1/100,000 and rarer) triggers (server-wide, all players):
   - Chat-like announcement banner on every client: "<Name> just flushed a 1 in 100,000 KING POOP!" with rarity color, plus "Server Luck increased for 5 minutes!".
   - Short Lighting change (sky/colorcorrection tint yellow for King Poop, purple for Alien, dark red/black for Mystery) with tween back to normal after ~8s; big golden full-screen popup like the mockup ("KING POOP 1/100,000 MYTHIC").
   - Server Luck boost: x2 luck for 5 minutes for ALL players (RollService luckOverride/multiplier hook), does not stack, timer refreshed to max; show a small "Server Luck x2 - mm:ss" label on the HUD.
2. Rare-flush juice: Legendary+ drops get camera shake + confetti particles on the client; Epic+ get sound hooks (Assets.luau, empty-safe).
3. Display/flex polish: show owned item count and a "Discovered X/11" counter in My Collection; plot sign shows toilet name.
4. Monetization stubs only (no real IDs): src/shared/Config/Monetization.luau with placeholder Gamepass/DevProduct ids = 0 (2x Luck, Auto Flush, VIP Toilet, Server Luck 10min product). A MonetizationService that checks ownership safely (skip if id 0) and applies 2x personal luck / auto flush when owned. Implement the Auto Flush toggle button in HUD (only works if owned; with id 0 it shows "Coming soon").
5. Settings: persist Sound on/off in the DataStore profile (sanitized) and apply on join.
6. Add docs/README-setup.md in English: how to run (rojo serve, Studio plugin, enable Studio API Services for DataStore, Game Settings notes, how to publish) and how to tweak odds/prices in Config.
7. Anti-abuse: server-side event dedupe, cooldown for event broadcast, make sure nothing trusts the client.
Verify with rojo build, stylua, existing scripts (extend check scripts for the luck boost). Short final report with assumptions and untested-in-Studio items.
