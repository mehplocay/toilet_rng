# Permanent upgrade tracks

2026-10-06, `feature/permanent`. This replaces the old run-reset and ten-level-track design. [Measured economy and all archetype tables](economy-v2.md), [rebirth contract](rebirth.md), [research](../research/permanent-economy.md).

All six coin tracks and toilet tiers **survive every rebirth**. Config/Upgrades owns piecewise exponential cost anchors, level caps, effects, milestone titles, physical capacity, total luck cap and speed floor. Coins only; server-authoritative pricing and no paid luck.

| Track | Levels | Effect |
|---|---:|---|
| Cash Boost | 100 | L1-10 +10% each; L11-100 +2.5% each; +325% at max before rebirth/passes |
| Offline Tank | 100 | 8h base; first ten levels +24min each, then +8min each; 24h maximum before Offline Plus/storage limits |
| Luck | 50 | First ten levels +10% each, then +4% each; tier/daily/server factors multiply under 10x total cap |
| Flush Speed | 10 | 5% shorter cooldown per level; additive rebirth reduction, final floor 0.4s |
| Auto-Flush Speed | 10 | Auto interval decreases from 2x to 1x shared cooldown; free lifetime unlock unchanged |
| Display Slots | 10 configured | +1 per purchase; stop at ten physical slots, normally after seven purchases |

The first ten legacy levels keep their effects. Larger caps do not multiply legacy levels, mint coins, refund costs or repeatedly add slots. New `UpgradeVersion=2` profiles accept the new bounds; missing/older marker clamps saved levels to the previous maxima (ten, or seven slot levels) before adopting the marker. Negative, fractional, nonfinite and unknown fields are rejected. Valid new over-cap levels clamp to current maxima. Existing paged 100-slot capacity is retained.

Purchase number n interpolates exponentially between explicit level/cost anchors, then rounds upward to an integer. Every configured price is validated as strictly increasing and <=9e15. No generic exponential over 100 levels can overflow. Balance enforces front-loaded milestone timing with all spending and permanent rebirth/display income included; early five Cash levels also have a service-only affordability proof.

`BuyUpgrade(trackId, expectedLevel)` retains the 3-token/1-per-second bucket, exact argument/type/track checks, saved expected-level replay check, physical slot capacity check and server wallet debit. Get settles income at the old effect before the non-yielding purchase. Pending saves reject another purchase/rebirth; save acknowledgment and same-profile/lease validation precede success. A lost committed response retries the same snapshot. Existing crash/outage durability limits are unchanged.

UI cards show N / cap, a progress bar, current effect, abbreviated price, next milestone and its earned title. Titles progress through Apprentice, Adept, Specialist, Expert, Veteran, Elite, Champion, Grandmaster and Legend at ten-level boundaries; max is Master. They are derived from permanent levels and add no undocumented bonus. The capacity-limited display track shows PLOT FULL, a completed bar and Master at physical capacity, rather than charging for unavailable slots.

Confirmed level changes pop the existing card; existing audio feedback plays UpgradeBuy or UpgradeMax, with UpgradeMax reused for milestone crossings. Initial/repeated snapshots are silent. Luck is shown as `Luck +N%`: +900% means 10x/1000% total, and the card explains that extra luck above 5x is halved for odds rarer than 1/25K. Maximum untimed Galaxy luck is 5.98x, within the requested usual late-game band.

Verification: all configured levels/prices/caps, one-coin-short failures, invalid inputs, replay/race safety, old/new save migration, milestone titles, numeric ceilings, exact rare-first odds, cash rounding, offline ledger fractions, responsive UI and persistent rebirth behavior. The audit includes the committed-response-loss purchase at level 100. Studio/native-device and live backend QA remain outside headless evidence. Retire old server binaries before rollout.

Cash stacking (2026-10-06 rebirth-balance): Cash Boost and rebirth cash add, then any display toilet factor multiplies within the 40x free cap. Paid cash factors multiply on top under their own 3x cap (120x maximum). Milestone titles add no numerical bonus. Daily coins remain paid-only; collection and quoted receipts never multiply again. See [current measured tables](economy-v2.md).
