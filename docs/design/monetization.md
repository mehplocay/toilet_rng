# Fair monetization

Proposal, 2026-10-05. Prices are base Robux design suggestions, not configured products or revenue forecasts. Display the actual platform price in purchase UI; never invent asset/product IDs. Policy research: [genre analysis](../research/genre-analysis.md#policy-findings-and-design-implications).

## Principles and offer catalog

All 35 collection items, all toilets/worlds, Auto-Flush, six earned display slots and capped rebirth power are obtainable for free. Purchases buy known cosmetics or disclosed temporary probability modifiers. Luck is still an advantage; do not call it purely cosmetic or claim spending guarantees rarity. No permanent 2x luck/speed pass and no Robux-to-Coin conversion.

| Type / offer | Base price | Exact benefit | Release |
|---|---|---|---|
| Pass: Confetti Flush | 49 R$ | Choose 3 confetti colors; client effect only | v1 |
| Pass: Golden Nameplate | 79 R$ | Gold plot border + nameplate skin, no official/admin badge | v1 |
| Pass: Showcase Plus | 99 R$ | +3 display slots above earned capacity (3-6 becomes 6-9); no item power | v1 |
| Pass: VIP Bathroom | 249 R$ | Chrome toilet skin, VIP title, 3 photo frames; free preview | v1.1 |
| Pass: Porcelain Patron | 499 R$ | 5 animated toilet skins, 3 pedestal skins, 2 emotes; no future-content promise | v1.2 |
| Product: Lucky Flush | 5 R$ | P=10 for exactly 1 successful flush | v1.2, after odds/policy gate |
| Product: Lucky Flush x5 | 19 R$ | 5 individually armed charges; same P=10, one charge/flush | v1.2, after odds/policy gate |
| Product: Server Luck | 49 R$ | E=2 for 10 minutes for eligible recipients in current server | v1.2, after mixed-policy tests |
| Product: Rebirth Restart | 29 R$ | Fixed credit of 100 service-only flush awards at Basic: `100*floor(M_r)` Coins, no RNG or luck | v1.2; low priority, test demand |

Passes are one-time entitlements, VIP is **not** a subscription. Patron has no overlap discount trap: its cosmetics are distinct from cheaper passes. Item storage/first-copy protection and accessible controls are never monetized. Do not ship a paid Auto-Flush simply because the older GDD listed it.

Rebirth Restart is available only after at least one earned rebirth, at current Basic, at most once per rebirth. Coin grant is exactly 100 at r=1, 200 at r=5 and 300 at r=10; deliberately modest, shown before purchase. It does not add flush count, items, best tier, luck or rebirth eligibility. Credit cannot buy random products because Coins have no random-purchase sink. If that changes, reassess indirect paid randomness before release. Recommendation: cosmetics and optional luck first; drop this product if users find its benefit unclear.

## Lucky Flush contract and probability disclosure

- Bought charges enter a persistent wallet; no expiry. Player arms one explicitly; Auto-Flush pauses before arming and resumes only after confirmation/result. A rejected/failed flush consumes nothing. Item award and charge consumption are one durable operation with retry-safe identity.
- Rebirth, toilet, pool, strongest event and charge form L as specified in [progression](progression.md#exact-luck-and-outcome-math). Luck cap 50; each eligible item receives its own rarest-first check. Boosting the parameter 10x is not a guarantee or ten independent rolls.
- Before buying, show `5 R$ / 1 charge` or `19 R$ / 5 charges`, exact duration by uses, current pool/tier, before/after effective percentages for **every** possible item including Poop, and a labeled `Odds Details` control. Before arming, show updated values again.
- Probability display uses the full sequence formula; no nominal denominator masquerading as actual chance. Internal outcomes sum to 100%; retain enough decimal digits for the rarest outcome and use the policy's rounding notice when displayed sums differ.
- Example validation fixture, not a live pool: Rat check 1/25, Paper 1/8, Poop fallback. At L=1: Rat 4%, Paper 12%, Poop 84%. At L=10: Rat 40%, Paper 60%, Poop 0%. Paper did not become 10x more likely. Live pools have additional earlier checks and need their own full calculation.
- No hidden pity meter, near-miss animation, secret boosted first purchase or “you're due” wording. Ordinary free drops use the same generator with P=1.

Roblox explicitly covers purchased luck/probability modifiers and indirect random purchases in its [paid random items policy](https://create.roblox.com/docs/production/monetization/paid-random-items). This catalog cannot ship paid luck as an unregulated “boost.”

## Eligibility and paid server luck

Implementation decision: server obtains per-user policy via [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService), validates before a purchase prompt and rechecks before consuming a charge or applying a paid modifier. On failure/unknown status, paid RNG is disabled while free play and deterministic cosmetics remain available.

| State | Required product behavior |
|---|---|
| Paid randomness restricted | Hide/disable Lucky Flush and Server Luck purchasing; never apply another player's paid modifier to this user. Free scheduled events still work. |
| Eligible buyer, mixed server | Purchase states “2x server luck for eligible players for 10 minutes”; restricted users receive the same visual celebration plus a temporary zero-power pipe glow, no modified random reward. |
| User becomes restricted with charges | Retain unused charges; prevent consumption. Explain unavailability and provide support route; do not exchange for undisclosed random rewards. |
| Free E=2 already active | Paid 10 minutes start after current free E=2 ends; show scheduled start/end before prompt. Free E=1.5 does not delay paid E=2. |
| Another paid boost active | Allow at most one 10-minute extension queued; disable further purchases until capacity returns. No E>2 stacking. |
| Event arrives during paid boost | Freeze paid remaining time during free E=2 overlap; restore remaining time afterward. Paid duration is preserved. |
| Last player leaves/server closes | Persist unused paid seconds as a buyer-owned activation credit; reactivation requires a live eligible server and cannot duplicate the original session. |

Server Luck requires durable ownership of the timer/credit and receipt identity, not just a local countdown. If exact time recovery is not implemented and tested, postpone this product. Buyer leaving alone does not reclaim time already benefiting their server. All paid-influenced item copies retain paid provenance even when recipients did not pay. As a conservative design choice, paid-origin rare finds trigger cosmetic celebrations only; only unpaid-origin finds trigger the free statistical discovery buff. This avoids routing purchased randomness into a second unrestricted modifier.

Trading launches with paid-origin copies excluded. Any future paid-item trading must honor `IsPaidItemTradingAllowed` for both participants and preserve provenance through onward transfers; see [trading](social-and-events.md#trading-v2-after-persistence-and-provenance). Do not sell tradable random eggs, gift luck charges or enable secondary markets initially.

## Offer timing and limits

| Moment | Allowed presentation |
|---|---|
| First 10 minutes | Ordinary shop button available; no automatic purchase modal |
| First display / minute 10+ | One dismissible Confetti/Nameplate preview card; only after completed action |
| Earned fourth display slot | Showcase Plus in customization panel, alongside free next-index-slot goal |
| First Sewer visit | VIP skin preview in cosmetic catalog; no blocking world gate |
| Player opens Odds Details / minute 20+ | Optional Lucky Flush tile with before/after odds; never triggered by a run of bad rolls |
| Earned rebirth | Explain free permanent bonus first; Restart listed only in voluntarily opened shop |
| Shared event panel | Server Luck tile explains eligible audience, exact time and strongest-only stacking |

At most 1 unsolicited cosmetic suggestion/session, 2/account/day; dismiss hides suggestions for 7 days. Random offers never auto-prompt. No upsell after canceled purchase, loss, failed boss or trading dispute. Client prompt closing is not proof of payment: receipt fulfillment must be server-authoritative, idempotent and recoverable before any product launch.

Product safety limits (our design, not platform mandates): at most 20 paid Lucky Flush charges purchased/UTC day and 2 Server Luck purchases/UTC day; no bulk pack beyond five. Enforce limits before prompting and honor already-completed legitimate receipts. No streak-protection sales, fake stock, fake discounts or resetting countdowns. This follows [Roblox monetization guidance](https://create.roblox.com/docs/production/monetization) on honest promotions and avoiding pressure on minors.

## ARPPU: planning model, not a promise

Measure monthly **gross Robux spent / unique payers**; separately report creator-earned Robux after actual platform adjustments. No USD/DevEx conversion assumed. Regional/platform pricing and eligibility will change realized results.

| Illustrative first-30-day payer group | Share of 100 payers | Spend per payer | Contribution |
|---|---|---|---|
| Small cosmetic | 60% | 79 R$ | 4,740 R$ |
| Mid-tier / combination | 30% | 249 R$ | 7,470 R$ |
| Premium cosmetic | 10% | 499 R$ | 4,990 R$ |
| Optional repeat consumables | 25 of the same 100 payers | 38 R$ extra (two five-packs) | 950 R$ |
| Total | 100 unique payers | **181.5 R$ ARPPU** | **18,150 R$ gross** |

Sensitivity: all payers buying only 49-R$ cosmetic => 49 ARPPU; 50% at 79 + 35% at 249 + 15% at 499 + 19 average add-on => 220.5 ARPPU. Use 80-220 as an initial planning band, not a KPI to force through pressure.

At assumed 2% monthly payer conversion, 10,000 monthly unique players -> 200 payers -> 36,300 gross R$ at 181.5 ARPPU (3.63 R$/monthly user). At 0.5% conversion it is 9,075 R$; at 4%, 72,600 R$. None is a forecast, and costs are not subtracted. Pass-heavy revenue is front-loaded: existing owners cannot buy the same pass next month. Retention and occasional new original cosmetics must support later revenue.

Track product impressions -> voluntary opens -> successful purchases, 7-day return by payer/nonpayer, ARPPU median and distribution, refunds/support complaints, policy exclusions and time-to-next-free-upgrade. Stop an offer test if it produces a material retention decline or credible confusion about odds; never solve low conversion by slowing free progress.
