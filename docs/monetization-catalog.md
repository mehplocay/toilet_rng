# Creator Hub monetization catalog

2026-10-06 manager decision. Source: `Config/Monetization.luau`; icon presentation: `Config/Shop.luau` and `Assets.Icons`. Every runtime ID is **0**, so all purchase buttons are disabled as **Coming soon**. Existing IDs documented in `gamepass-ids.md` are deliberately not activated by this task. Prices below are creation targets in Robux; enabled UI uses the actual platform price, including regional pricing.

| Kind / config key | Exact name | Description | Price | Icon key / fallback |
| --- | --- | --- | ---: | --- |
| Pass / SparkleTrail | Sparkle Trail | A sparkling trail follows your character. Cosmetic only. | 49 | Gem / gem |
| Pass / VIPStar | VIP Star | A VIP star in chat and above your name. Cosmetic only. | 59 | Crown / crown |
| Pass / CustomPlotColor | Custom Plot Color | Choose your plot's lawn and border color. Cosmetic only. | 79 | Home / house |
| Pass / FastFlush | Fast Flush | 20% shorter flush cooldown. Same items and odds. | 99 | Flush / toilet |
| Pass / DoubleCash | Double Cash | 2x coin income. Stacks with bonuses, up to the cash cap. | 249 | DoubleCash / coins |
| Pass / AutoCollect | Auto Collect | Collect display coins every 5 seconds while inside your plot. | 149 | AutoCollect / basket |
| Pass / ExtraSlots | Extra Slots | +3 display slots, up to 10 total. | 149 | ExtraSlots / collection book |
| Pass / OfflinePlus | Offline Plus | Double your offline tank time and storage. | 129 | OfflinePlus / daily gift |
| Pass / VIPPack | VIP Pack | +50% cash, +1 path speed, gold trail, VIP sign and daily coins. No luck. | 399 | VIPPack / gold crown |
| Product / Coins10Minutes | Coin Pack: 10 Minutes | 10 minutes of display income, quoted before purchase. | 49 | CoinPack / coins |
| Product / Coins1Hour | Coin Pack: 1 Hour | 1 hour of display income, quoted before purchase. | 149 | CoinPack / coins |
| Product / Coins6Hours | Coin Pack: 6 Hours | 6 hours of display income, quoted before purchase. | 399 | CoinPack / coins |
| Product / PathBoost10Minutes | Path Boost: 10 Minutes | 4x speed on blue paths for 10 minutes. VIP: 5x. Timer runs offline. | 29 | PathBoost / arrows |

New icon keys have empty asset strings and rendered vector fallbacks, not invented upload IDs. Existing four use their already-uploaded art. Creator Hub requires uploading suitable icon images separately; these vector fallbacks are in-game artwork, not upload IDs.

VIP includes the existing VIP name/chat star, exclusive gold trail with star particles, a permanent VIP plot sign, +50% cash, one extra path speed step and one claimable chest per UTC day. The sign has a monthly-club visual theme but **is not a subscription and does not expire**. VIP grants its trail without needing Sparkle Trail. VIP's star overlaps VIP Star; buying both does not add a second star or a discount.

Coin packs use current server display income/second, including applicable upgrades/rebirth/pass bonuses, multiplied by 600/3,600/21,600, floored and clamped to **100–1,000,000,000 Coins**. There is no second multiplier at wallet credit. An in-game quote is saved before prompting and survives disconnect/rebirth. Unquoted external purchases use income at processing time because receipts contain no historical income timestamp; use in-experience sales for quoted amounts. VIP chest uses the same rate and clamps for 600 seconds, once per UTC day. Empty displays therefore receive the stated minimum, not a fabricated passive rate.

Path purchases extend the saved expiry by 600 seconds per distinct receipt. They replace the free path factor 3 with 4; VIP adds one step, then any other server multiplier applies under the **5x total** cap. Leaving paths removes the path benefit; the timer continues. Cash has a **10x total** cap. Paid luck, odds changes and random items are absent. Auto-Flush and animation skip remain free.

Before enabling IDs: publish this profile schema to all servers, assign this experience's passes/products, verify live ownership/receipts and asset permissions in an isolated test experience, then set sales/prices. Never delete or rotate enabled product mappings or the receipt archive while receipts remain recoverable. Full implementation and recovery details: [monetization design](design/monetization.md).
