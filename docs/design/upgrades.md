# Permanent upgrade tracks

> Current cash validation: [uncapped cash](no-cash-cap.md). Luck validation: [full linear luck and regenerated pacing tables](luck-linear.md). Total luck applies in full to every item check without a total ceiling; this supersedes earlier luck formulas and measured balance snapshots below.

2026-10-06, `feature/permanent`. This replaces the old run-reset and ten-level-track design. [Measured economy and all archetype tables](economy-v2.md), [rebirth contract](rebirth.md), [research](../research/permanent-economy.md).

All six coin tracks and toilet tiers **survive every rebirth**. Config/Upgrades owns piecewise exponential cost anchors, level caps, effects, milestone titles, physical capacity, uncapped luck stacking and speed floor. Coins only; server-authoritative pricing; paid permanent luck is separately policy-gated.

| Track | Levels | Effect |
|---|---:|---|
| Cash Boost | 100 | L1-10 +10% each; L11-100 +2.5% each; +325% at max before rebirth/passes |
| Offline Tank | 100 | 8h base; first ten levels +24min each, then +8min each; 24h maximum before Offline Plus/storage limits |
| Luck | 50 | First ten levels +10% each, then +4% each; tier/daily/server factors multiply without a total luck ceiling |
| Flush Speed | 10 | 5% shorter cooldown per level; additive rebirth reduction, final floor 0.4s |
| Auto-Flush Speed | 10 | Auto interval decreases from 2x to 1x shared cooldown; free lifetime unlock unchanged |
| Display Slots | 10 configured | +1 per purchase; stop at ten physical slots, normally after seven purchases |

The first ten legacy levels keep their effects. Larger caps do not multiply legacy levels, mint coins, refund costs or repeatedly add slots. New `UpgradeVersion=2` profiles accept the new bounds; missing/older marker clamps saved levels to the previous maxima (ten, or seven slot levels) before adopting the marker. Negative, fractional, nonfinite and unknown fields are rejected. Valid new over-cap levels clamp to current maxima. Existing paged 100-slot capacity is retained.

Purchase number n interpolates exponentially between explicit level/cost anchors, then rounds upward to an integer. Every configured price is validated as strictly increasing and <=9e15. No generic exponential over 100 levels can overflow. Balance enforces front-loaded milestone timing with all spending and permanent rebirth/display income included; early five Cash levels also have a service-only affordability proof.

`BuyUpgrade(trackId, expectedLevel)` retains the 3-token/1-per-second bucket, exact argument/type/track checks, saved expected-level replay check, physical slot capacity check and server wallet debit. Get settles income at the old effect before the non-yielding purchase. Pending saves reject another purchase/rebirth; save acknowledgment and same-profile/lease validation precede success. A lost committed response retries the same snapshot. Existing crash/outage durability limits are unchanged.

UI cards show N / cap, a progress bar, current effect, abbreviated price, next milestone and its earned title. Titles progress through Apprentice, Adept, Specialist, Expert, Veteran, Elite, Champion, Grandmaster and Legend at ten-level boundaries; max is Master. They are derived from permanent levels and add no undocumented bonus. The capacity-limited display track shows PLOT FULL, a completed bar and Master at physical capacity, rather than charging for unavailable slots.

Confirmed level changes pop the existing card; existing audio feedback plays UpgradeBuy or UpgradeMax, with UpgradeMax reused for milestone crossings. Initial/repeated snapshots are silent. Luck is shown as `Luck xN`, with scientific notation for large values. The card explains uncapped stacking and the 100% ceiling on each probability. Upgrade levels remain a content limit; every configured level effect is retained.

Verification: all configured levels/prices/caps, one-coin-short failures, invalid inputs, replay/race safety, old/new save migration, milestone titles, numeric ceilings, exact rare-first odds, cash rounding, offline ledger fractions, responsive UI and persistent rebirth behavior. The audit includes the committed-response-loss purchase at level 100. Studio/native-device and live backend QA remain outside headless evidence. Retire old server binaries before rollout.

Cash stacking (2026-10-07): Cash Boost, rebirth, display toilet factors and owned paid cash factors multiply without a multiplier cap. Milestone titles add no numerical bonus. Late cost anchors are retuned in Config/Upgrades to retain pacing; level counts and effects are unchanged. Daily coins remain paid-only; collection and quoted receipts never multiply again. See [current balance and before/after tables](no-cash-cap.md).

Permanent luck update (2026-10-07): VIP +25% luck and 2x Luck are random-item odds boosts, preserved through rebirth as pass entitlements, and usable only with current policy eligibility. Free upgrade/rebirth luck values are unchanged. Total luck is uncapped; each Lucky Flush charge multiplies the current total by ten. Individual checks still stop at probability 1, and earlier certain outcomes suppress later items. Pass cards expose Info: all item odds; the HUD and odds breakdown identify "VIP +25% luck" and "2x Luck pass", or "unavailable in your region". Percentage rounding is disclosed. [Details and balance](vip-luck-balance.md).
