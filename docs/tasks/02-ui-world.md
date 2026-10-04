Task 2 (branch feature/ui-world is already checked out; do NOT commit, the manager commits). Read AGENTS.md, docs/GDD.md, docs/foundation.md and LOOK at docs/reference/mockups.png. ALL in-game text must be English.

PART A - fixes to the foundation (small):
1. RollService must never return nil: roll from rarest to most common (independent 1/X with luck), Poop is the fallback. Update scripts/check-foundation.luau so it still passes and asserts a drop on every roll.
2. Toilets.luau pools: Basic Poop/ToiletPaper/Rat/Fish; Dirty +Duck; Golden +GoldenPoop; Diamond +ToiletBaby; Radioactive +SewerShark +KingPoop; Demon +AlienToilet; Galaxy +Mystery.
3. Add a "Display" remote (server validated): put an owned item into a free display slot / remove it. Add "Teleport" not needed. Add a DataStore-saved Settings flag later - not now.

PART B - world, built by a server script at startup (no Studio-made assets, only Parts/Models/SurfaceGuis/ParticleEmitters, cartoony bright look like the mockup):
- Spawn hub: bright plaza floor, banner "TOILETS MAKE DREAMS COME TRUE!", SpawnLocation, decorative toilets/plants, a shop area sign.
- 10 plots in a ring/grid. Each player is assigned a free plot on join (released on leave). Plot has a name sign "<Player>'s Plot", the player's toilet model (look differs per tier: Basic white, Dirty brownish, Golden gold, Diamond light blue, Radioactive green neon, Demon black/red, Galaxy purple neon) with a ProximityPrompt "FLUSH" owned only by the plot owner, and display pedestals (DisplaySlots) showing item model + "Name 1/X" label.
- Item models: simple Part-based placeholders per item (colored shapes) with a BillboardGui showing name + rarity in the rarity color. Drop appears above the toilet, floats, then goes to the collection.
- Flush animation: toilet shake (tween), water/sparkle particles, sound hooks via Assets.luau (no invented IDs; skip silently if empty). Client shows a result popup (item name, rarity color, "1 in X"). Rare+ (Epic and up) get a bigger effect.
- Top Toilets leaderboard board in the hub (SurfaceGui) ranking players by collection value, updated every 10s.

PART C - client UI in src/client (created from code, ScreenGui, use UICorner/UIStroke/gradients, dark navy panels with rarity colors like the mockup):
- HUD: left button column (Shop, Collection, Upgrades, Teleport, Settings) and a coins display top-right.
- My Collection: grid of cards, rarity filter tabs, search box, undiscovered items as silhouette "???", per-item count, Sell 1 / Sell All and Display buttons for owned items.
- Toilet Upgrades: horizontal cards for the 7 toilets with price, Owned/Buy state, text "Better toilets = new drops + higher odds!".
- Teleport button: teleports to the player's own plot. Settings: placeholder panel (sound on/off toggle stored locally).
- Mobile friendly (scale-based sizes, UIScale).
Keep modules small and separated (UI components in src/client/UI/). Server remains authoritative; client only sends requests and renders Result events. Add a server->client state sync remote so the client can show coins/inventory/tier on join and after changes.

Verify: rojo build -o build.rbxl passes, stylua formatted, scripts pass. Final report short, with assumptions and what could not be tested (Studio).
