# Creator Hub monetization catalog

2026-10-06. Authoritative creation list for feature/catalog2; supersedes earlier catalog prices and benefits in historical design/audit notes. **15 passes and 8 developer products.** Keep all existing config keys and enabled ID mappings stable. VIPStar is the existing **2008628314** pass: rename it **Star Tag** manually in Creator Hub; its price stays 59 Robux. Every other ID remains **0** (Coming soon).

Create/update the passes in the order below, then the products. Prices are base Robux targets; in-game enabled buttons show MarketplaceService's current price (including regional pricing). VIP must never be priced below 250 Robux; target 399. No gifting implementation is included.

Icon paths below are creation targets for the separate art session, not claims of present/uploaded files. The in-game keys already have vector fallbacks. Upload the matching finished PNG when available; do not invent asset IDs. For existing Sparkle Trail, Custom Plot Color and Fast Flush, current Gem/Home/Flush art remains available in game.

| Order | Type | Exact name | Exact description | Price | Config key | Icon file / Assets.Icons key |
|---:|---|---|---|---:|---|---|
| 1 | Pass | Sparkle Trail | A sparkling trail follows your character. Cosmetic only. | 49 | Gamepasses.SparkleTrail | assets/icons/passes/Gem.png / Gem |
| 2 | Pass | Star Tag | A gold star in chat and above your name. Cosmetic only; included in VIP. | 59 | Gamepasses.VIPStar | assets/icons/passes/StarTag.png / StarTag |
| 3 | Pass | Custom Plot Color | Choose your plot lawn and border color. Cosmetic only. | 79 | Gamepasses.CustomPlotColor | assets/icons/passes/Home.png / Home |
| 4 | Pass | Fast Flush | 20% shorter flush cooldown. Same items and odds. | 99 | Gamepasses.FastFlush | assets/icons/passes/Flush.png / Flush |
| 5 | Pass | Double Cash | 2x coin income. Paid factors stack up to 3x on top of free bonuses. | 249 | Gamepasses.DoubleCash | assets/icons/passes/DoubleCash.png / DoubleCash |
| 6 | Pass | Auto Collect | Collect display coins every 5 seconds while inside your plot. | 149 | Gamepasses.AutoCollect | assets/icons/passes/AutoCollect.png / AutoCollect |
| 7 | Pass | Offline Plus | Double your offline tank time and storage. | 129 | Gamepasses.OfflinePlus | assets/icons/passes/OfflinePlus.png / OfflinePlus |
| 8 | Pass | VIP | 1.5x cash, +1 path speed step, +50% offline tank, daily chest, VIP hub pad, gold star, trail and sign trim. No luck. | 399 | Gamepasses.VIPPack | assets/icons/passes/VIP.png / VIP |
| 9 | Pass | Rainbow Name | Animated rainbow overhead name and rainbow chat name color. Cosmetic only. | 39 | Gamepasses.RainbowName | assets/icons/passes/RainbowName.png / RainbowName |
| 10 | Pass | Confetti Reveal | A colorful confetti burst celebrates your reveals. Cosmetic only. | 39 | Gamepasses.ConfettiReveal | assets/icons/passes/ConfettiReveal.png / ConfettiReveal |
| 11 | Pass | Golden Name | A golden overhead and chat name. Rainbow Name takes priority when both are owned. | 49 | Gamepasses.GoldenName | assets/icons/passes/GoldenName.png / GoldenName |
| 12 | Pass | Dance Pack | Four toggleable celebration effects in a small menu. Cosmetic effects; no animation assets required. | 49 | Gamepasses.DancePack | assets/icons/passes/DancePack.png / DancePack |
| 13 | Pass | Toilet Glow | An extra glowing aura around your toilet. Cosmetic only. | 69 | Gamepasses.ToiletGlow | assets/icons/passes/ToiletGlow.png / ToiletGlow |
| 14 | Pass | Companion | A cute little duck companion follows your character. Cosmetic only. | 99 | Gamepasses.Companion | assets/icons/passes/Companion.png / Companion |
| 15 | Pass | Ultimate Bundle | Includes all 14 other passes: Sparkle Trail, Star Tag, Custom Plot Color, Fast Flush, Double Cash, Auto Collect, Offline Plus, VIP, Rainbow Name, Confetti Reveal, Golden Name, Dance Pack, Toilet Glow and Companion. No consumables. | 799 | Gamepasses.UltimateBundle | assets/icons/passes/UltimateBundle.png / UltimateBundle |
| 16 | Developer product | Coin Pack Mini | 10 minutes of current display income, quoted before purchase. | 10 | DeveloperProducts.Coins10Minutes | assets/icons/passes/CoinPackMini.png / CoinPackMini |
| 17 | Developer product | Coin Pack Small | 1 hour of current display income, quoted before purchase. | 49 | DeveloperProducts.Coins1Hour | assets/icons/passes/CoinPackSmall.png / CoinPackSmall |
| 18 | Developer product | Coin Pack Large | 6 hours of current display income, quoted before purchase. | 249 | DeveloperProducts.Coins6Hours | assets/icons/passes/CoinPackLarge.png / CoinPackLarge |
| 19 | Developer product | Path Boost: 10 Minutes | 4x speed on blue paths for 10 minutes. VIP: 5x. Timer runs offline. | 29 | DeveloperProducts.PathBoost10Minutes | assets/icons/passes/PathBoost.png / PathBoost |
| 20 | Developer product | Coin Pack Huge | 24 hours of current display income, quoted before purchase. | 799 | DeveloperProducts.Coins24Hours | assets/icons/passes/CoinPackHuge.png / CoinPackHuge |
| 21 | Developer product | Lucky Flush | 1 single-use 10x luck charge. Total luck capped at 10x with rare diminishing returns. Review all odds before purchase and use. | 25 | DeveloperProducts.LuckyFlush1 | assets/icons/passes/LuckyFlush1.png / LuckyFlush1 |
| 22 | Developer product | Lucky Flush 5-Pack | 5 single-use 10x luck charges. Total luck capped at 10x with rare diminishing returns. Review all odds before purchase and use. | 99 | DeveloperProducts.LuckyFlush5 | assets/icons/passes/LuckyFlush5.png / LuckyFlush5 |
| 23 | Developer product | Lucky Flush 20-Pack | 20 single-use 10x luck charges. Total luck capped at 10x with rare diminishing returns. Review all odds before purchase and use. | 349 | DeveloperProducts.LuckyFlush20 | assets/icons/passes/LuckyFlush20.png / LuckyFlush20 |

## Entitlements and limits

Display slots are never sold. All ten slots remain free through coin upgrades, index rewards and rebirth. Existing valid saved DisplaySlots capacity (including legacy purchases and above-ten profiles up to the existing 100-slot schema limit) is retained without subtraction on load, refresh, save or rebirth. Retired ownership and the obsolete AppliedSlots marker are discarded; they no longer grant slots. Unused retired icon files may remain in assets.

Ultimate Bundle implies every other pass listed above (14 entitlements). It grants **no coins, Lucky Flush charges or timed Path Boost products**. Direct and bundle ownership combine without duplicate multipliers. Rainbow Name takes priority over Golden Name. VIP includes the Star Tag and its own gold trail without requiring Sparkle Trail. Owning overlapping passes does not grant a refund or extra copy.

VIP multiplies coin income by 1.5, stacks with Double Cash under the separate 3x paid cap on top of the 40x free progression cap (120x maximum), adds one path step under the 5x total speed cap, and 50% offline tank time/storage. Offline Plus multiplies that tank factor by two; the existing 24-hour and ledger caps still apply. Legacy above-ten capacities are preserved. Daily VIP chest grants 600 seconds of current display income once per server UTC day, with its marker and coins saved atomically. Minimum 100, maximum 1,000,000,000 coins; no second cash multiplier at credit.

The hub VIP pad grants five seconds of current display income, clamped to 10–10,000 coins. It requires a living eligible player within eight studs and has a persistent five-minute cooldown, a one-token/0.2-per-second prompt limiter, ledger checks and an atomic save. Rejoining cannot clear its cooldown. This small reward and cooldown are implementation assumptions where the owner specified no exact values.

Coin packs use **display income only**, including already-applicable tier/cash multipliers: Mini x600, Small x3,600, Large x21,600, Huge x86,400. Server-saved pre-prompt quotes survive rejoin and rebirth. Each quote floors/clamps to 100–1,000,000,000 coins; full wallet/Earned caps defer receipts without dropping the purchase. External unquoted receipts cannot reconstruct purchase-time income; they use processing-time display income. Disable external sales for exact advance-quoted amounts.

## Lucky Flush release contract

One receipt grants 1/5/20 charges to a sanitized integer counter capped at 1,000. Counter, receipt marker and any quote removal are one durable profile transaction. At capacity the offer is disabled/server-rejected; already-paid excess receipts stay pending until space exists. Never rotate enabled product mappings or delete receipt tombstones.

The Lucky tab, offers and prompts are hidden for restricted, failed, missing or expired policy lookups. Server prompts, charge arming, charge use and new receipt grants also fail closed. Already-durable receipts can still be acknowledged without a second grant. Restricted users retain prior charges and can continue free flushing. No trading exists.

Before purchasing, each Lucky card displays normal/boosted rarity percentages and an **Info: all item odds** button. Purchasing first opens the full outcome dialog, then requires Continue to Roblox purchase. Before use, review that dialog and choose Use on next flush. This authorizes exactly one next manual/prompt/automatic flush; subsequent charges need another review. Automatic flushing waits for review while eligible charges exist. Tier/luck changes invalidate the authorization; rejected attempts do not spend a charge. The charge and rolled item/service coins are persisted together before reveal. Rebirth preserves charges.

Normal and enhanced item/rarity probabilities derive from RollService.Distribution, also used by the independent rare-first roll. The boost multiplies current free luck by ten under its own 10x and the global cap. Every non-fallback check is min(1, total luck / base odds), including Celestial and Secret. Final outcome probabilities include earlier failed checks. Percentages retain at least four decimal places beyond the first nonzero digit; the rounding disclaimer is visible. There are no urgency countdowns or random bundle rewards.

Keep Lucky product **external sales disabled**: external purchase pages cannot show this player's live odds or policy eligibility. Complete Roblox's experience questionnaire and isolated published purchase/receipt/PolicyService tests before enabling IDs. Current policy research: [paid random items](research/catalog2-policy.md).

## Presentation and rollout

Rebirth/catalog composition: earned rebirth trail > VIP gold > Sparkle Trail, with one active trail; rebirth chat tag then one VIP/Star tag; Rainbow Name > Golden Name. Rebirth's inner sign trim and VIP's outer gold trim remain visible together. No trail selector exists. See [the merged cosmetic lifecycle and validation](design/catalog2-rebirth-merge.md).

Dance Pack uses the owner-permitted fallback: four selectable/toggleable client celebration effects, not imported animation assets. The menu explicitly says Celebration effects; no animation IDs were invented. Confetti respects Reduced/Off reveal settings. Companion is a seven-part duck rendered locally, bounded to 12 nearby pets within 150 studs at 10 Hz, with death/distance/departure/UI teardown cleanup. Name color and pet ownership are replicated server attributes; no cosmetic changes RNG or grants coins.

Retire old servers before enabling this schema. Older sanitizers discard the new counter/cooldown and can corrupt receipt recovery. Receipt archive and profile durability retain the existing backend/lease limitations; this is not a promise of exactly-once behavior across arbitrary external data rollback. No real purchase or native device certification is implied by the CLI regressions.
