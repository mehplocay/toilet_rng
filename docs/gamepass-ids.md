# Gamepass ids (experience Toilet RNG 10769513431, group Dreadlight Studio)

Created and priced through the Creator Hub on 2026-10-06 (experience is private, nothing visible to players until it is made public).

| Config key (src/shared/Config/Monetization.luau) | Name | Pass id | Price (Robux) | Status |
|---|---|---|---|---|
| SparkleTrail | Sparkle Trail | 2008550322 | 49 | created, for sale |
| VIPStar | VIP Star (cheap cosmetic tag; to be renamed "Star Tag" because the real VIP is a premium pass) | 2008628314 | 59 | created, for sale |
| CustomPlotColor | Custom Plot Color | 2006679679 | 79 | created, for sale |
| FastFlush | Fast Flush | 2005125786 | 99 | created, for sale |

Current catalog: 15 passes, including Ultimate Bundle with all 14 other passes. Display slots are never sold; VIP grants no slots. Do not create or enable the retired slot pass. Existing valid saved capacity is retained; see [the slot migration contract](design/monetization.md).

Next: wire these ids into Config/Monetization.luau (the manager does it after the catalog session is merged) and create the new catalog passes/products from docs/monetization-catalog.md.
Pass management: https://create.roblox.com/dashboard/creations/experiences/10769513431/monetization/passes

Creator Hub automation notes: the Chrome window must be in the foreground (otherwise the page does not render and clicks are lost); toggles and Save need real mouse clicks at coordinates after the page loaded (Sales page: switch (935,128), price field (700,170), Save (615,368) in a 1568x772 frame; Create pass button on the create form about (530,712)).
