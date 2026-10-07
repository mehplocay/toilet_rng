# Creator Hub monetization IDs

Experience **10769513431**, group **Dreadlight Studio**. Owner-reported creation/settings, recorded 2026-10-07; this task did not change or independently verify Hub settings. The experience was private at creation.

Production config: src/shared/Config/Monetization.luau. **20 wired offers: 15 passes and five developer products.** The task's reference to 19 wired offers is a counting mismatch; every supplied positive ID is retained. VIPStar has been renamed **Star Tag** in the Hub; its config key and ID remain stable.

| Config key | Hub name | Type | Created Hub ID | Production Id | Base Robux | Sale / wiring state |
|---|---|---|---|---|---|---|
| SparkleTrail | Sparkle Trail | Pass | 2008550322 | 2008550322 | 49 | wired; for sale in Hub |
| VIPStar | Star Tag | Pass | 2008628314 | 2008628314 | 59 | wired; for sale in Hub |
| CustomPlotColor | Custom Plot Color | Pass | 2006679679 | 2006679679 | 79 | wired; for sale in Hub |
| FastFlush | Fast Flush | Pass | 2005125786 | 2005125786 | 99 | wired; for sale in Hub |
| DoubleCash | Double Cash | Pass | 2014052290 | 2014052290 | 249 | wired; for sale in Hub |
| AutoCollect | Auto Collect | Pass | 2014760290 | 2014760290 | 149 | wired; for sale in Hub |
| OfflinePlus | Offline Plus | Pass | 2013200307 | 2013200307 | 129 | wired; for sale in Hub |
| VIPPack | VIP | Pass | 2013872290 | 2013872290 | 399 | wired; for sale in Hub |
| RainbowName | Rainbow Name | Pass | 2014136291 | 2014136291 | 39 | wired; for sale in Hub |
| ConfettiReveal | Confetti Reveal | Pass | 2013332295 | 2013332295 | 39 | wired; for sale in Hub |
| GoldenName | Golden Name | Pass | 2012846305 | 2012846305 | 49 | wired; for sale in Hub |
| DancePack | Dance Pack | Pass | 2012936292 | 2012936292 | 49 | wired; for sale in Hub |
| ToiletGlow | Toilet Glow | Pass | 2013494299 | 2013494299 | 69 | wired; for sale in Hub |
| Companion | Companion | Pass | 2013812281 | 2013812281 | 99 | wired; for sale in Hub |
| UltimateBundle | Ultimate Bundle | Pass | 2013272293 | 2013272293 | 799 | wired; for sale in Hub |
| Coins10Minutes | Coin Pack Mini | Developer product | 3716998619 | 3716998619 | 10 | wired; for sale in Hub |
| Coins1Hour | Coin Pack Small | Developer product | 3716998683 | 3716998683 | 49 | wired; for sale in Hub |
| Coins6Hours | Coin Pack Large | Developer product | 3716998719 | 3716998719 | 249 | wired; for sale in Hub |
| PathBoost10Minutes | Path Boost: 10 Minutes | Developer product | 3716998748 | 3716998748 | 29 | wired; for sale in Hub |
| Coins24Hours | Coin Pack Huge | Developer product | 3716998799 | 3716998799 | 799 | wired; for sale in Hub |
| LuckyFlush1 | Lucky Flush | Developer product | 3716998840 | 0 | 25 | created, not wired; Coming soon; Hub Item for sale on |
| LuckyFlush5 | Lucky Flush 5-Pack | Developer product | 3716998876 | 0 | 99 | created, not wired; Coming soon; Hub Item for sale on |
| LuckyFlush20 | Lucky Flush 20-Pack | Developer product | 3716998923 | 0 | 349 | created, not wired; Coming soon; Hub Item for sale on |

All **eight developer products** were created with **Managed Pricing off** and **Item for sale on**, including the three Lucky products. Item for sale is a Hub setting, not evidence that an offer is enabled in this build. The in-game shop reads the current platform price rather than using the configured base price as a purchase price.

LuckyFlush1/5/20 are **created, not wired**. Keep their production Id = 0 until the owner completes Roblox's experience questionnaire and isolated published purchase/receipt/PolicyService tests described in [the Lucky Flush release contract](monetization-catalog.md#lucky-flush-release-contract). These three created IDs are recorded in documentation only. The owner must set Lucky products' **external sales off** if the Hub offers that control; where Monetization > Shop listing is available, leave them **Unlisted / Hide from Shop**. Their external-sales/listing state has not been verified in this task. A config ID of zero cannot disable an external Hub sale.

Ultimate Bundle includes all 14 other passes, with no consumables or display-slot grants. Display slots remain free; do not create or enable the retired slot pass. Existing valid saved capacity is retained; see [the slot migration contract](design/monetization.md).

Pass management: https://create.roblox.com/dashboard/creations/experiences/10769513431/monetization/passes

Product management: https://create.roblox.com/dashboard/creations/experiences/10769513431/monetization/developer-products
