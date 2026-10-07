# Progression expansion

> All-pools supersession (2026-10-07): this is an archived world/pool proposal. Every toilet now rolls all 47 current items; there are no selected-world, item-unlock or tier-pool gates. Use [the current contract](all-pools.md). The historical proposal below must not drive gameplay or player-facing copy.


Proposal, 2026-10-05. Companion: [research](../research/genre-analysis.md), [social/events](social-and-events.md), [monetization](monetization.md), [delivery order](roadmap.md). Numbers are initial tuning inputs, not measured outcomes. Preserve the mockup's bright plaza, ten plots, large FLUSH button, three starting pedestals and readable collection cards.

## Decisions relative to the current game

- Preserve FLUSH -> one RNG item -> SELL or DISPLAY -> upgrade. Poop is always the fallback; no empty flush, paid-only rarity or required rare roll.
- Use current Config prices (190 through 85,860), not the older GDD's 500 through 5,000,000. Add deterministic service Coins so unlucky players still progress. No code/config changes in this task.
- Preserve cumulative legacy pools and existing item IDs/rarities/values. World pools are an explicit extension: a selected world's unlocked additions join the legacy pool; other worlds' additions do not. Existing items retain their unlock tier.
- Reuse one plaza with themed portal rooms and the player's assigned toilet. Visiting changes the selected drop pool, not ownership of the plot. Public displays remain in the plaza; returning is free.
- All formulas, pool membership, prices and rewards must eventually live in `src/shared/Config/`. Numbers below are canonical for this proposal.

## Economy and pace

Each successful flush grants exactly one item plus deterministic service Coins `floor(B_t * M_r)`. Item sales grant `floor(base value * M_r)`; an item's acquisition-time multiplier is recorded and used on sale, so keeping stock through a rebirth cannot raise its sale multiplier. World/paid luck never multiplies service Coins. M_r is defined under rebirth.

Auto-Flush is earned at 100 lifetime flushes, free, same cooldown and pool. It works at the assigned toilet in the active session only; no auto-rejoin. Inventory does not block flushing. Free filters sell only duplicates below a selected rarity; default OFF, keep >=1, exclude locked/displayed items. First copy is locked automatically.

| Tier | Toilet / upgrade cost Coins | Cooldown | Base luck | Service Coins B_t | Legacy pool addition | World addition unlocked |
|---|---|---|---|---|---|---|
| 0 | Basic / owned | 3.0s | 1.00 | 1 | Poop, Toilet Paper, Rat, Fish | Plaza only |
| 1 | Dirty / 190 | 2.8s | 1.05 | 3 | Duck | None |
| 2 | Golden / 970 | 2.6s | 1.10 | 7 | Golden Poop | Sewer A; free portal |
| 3 | Diamond / 3,070 | 2.4s | 1.15 | 15 | Toilet Baby | Sewer B |
| 4 | Radioactive / 9,590 | 2.2s | 1.20 | 30 | Sewer Shark, King Poop (Mythic) | None |
| 5 | Demon / 33,890 | 2.0s | 1.25 | 65 | Alien Toilet | Hell A; free portal |
| 6 | Galaxy / 85,860 | 1.8s | 1.30 | 140 | Mystery (existing ???) | Space A; first rebirth eligible |
| 7 | Sludge Throne / 300,000 | 1.8s | 1.40 | 350 | None | Sewer mastery visuals |
| 8 | Rocket Bidet / 900,000 | 1.8s | 1.50 | 800 | None | Space B |
| 9 | Inferno Outhouse / 2,500,000 | 1.8s | 1.60 | 1,800 | None | Hell B |
| 10 | Porcelain Singularity / 7,000,000 | 1.8s | 1.75 | 4,000 | None | Animated endgame throne |

Prices are incremental purchases, sequential, not cumulative totals. Tier unlocks remain prerequisites even in older visited worlds after rebirth. Players may return to Plaza to target the smaller legacy pool. Do not promise every world by launch; see roadmap.

**Conservative pacing check:** At 75% flush uptime, zero item-sale income and no rebirth, service income/minute is approximately 15 / 48 / 121 / 281 / 614 / 1,463 / 3,500 / 8,750 / 20,000 / 45,000 / 100,000. With the one-time 100-Coin tutorial award, Dirty takes ~6 minutes with service alone and normally <5 with sales; Golden needs ~20 more service-only minutes, Diamond ~25 more. Sales from common drops and Sewer shorten this. Thus Golden at 15-25 minutes and Radioactive at 50-75 minutes are **test targets**, not guarantees. New content cannot depend on hitting a rare item.

At tier 6 the next upgrade costs ~86 service-only minutes at that uptime. Later gaps are ~103/125/156 minutes before sales, rebirth or offline income. Tune costs/B_t if median next-goal time exceeds 30 active minutes before Galaxy or 120 after it. Do not inflate rare-item values to fix ordinary progression.

Tutorial award: after first flush + first sale + first display, grant 100 Coins once per account. Daily checklist: 50 flushes, sell 10 duplicates, display any item (own plot always works); each gives `20 * B_best` Coins and 2 Stamps, capped at 3 tasks/day. B_best uses highest lifetime tier; cash awards receive no rebirth multiplier. No social task is mandatory.

From v1.1: offline tank earns `2 * B_best` Coins per completed offline minute, capped at 240 minutes; no random items, no paid boost, no compounding. At Basic: max 480 Coins; at Galaxy: max 67,200. Claim once from server timestamps; reconnecting adds no time twice. Passive rewards support catch-up but do not satisfy active rebirth flush requirements.

## First session: every minute, 0-60

This is the intended screen/goal sequence for a player who stays. Trigger lessons by completed action, not elapsed time. Late players retain their actual next goal; never fake a rare drop or force an upgrade. Every row is a one-minute interval beginning at that minute. A player can leave at any point with saved progress. At minute 60 show the recap if still present; no attendance reward requires staying an hour.

| Minute | Player sees / does |
|---|---|
| 0 | Spawns facing own toilet; one arrow, FLUSH; first real result within 15 seconds. |
| 1 | Item card shows KEEP / SELL; a duplicate can be sold; service Coins appear separately. |
| 2 | Places a kept item on a pedestal; one-time 100-Coin lesson reward. |
| 3 | Dirty preview shows price, next item Duck and faster flush; continue earning. |
| 4 | Buys Dirty if affordable; otherwise exact Coins remaining stays visible. |
| 5 | Opens index with permanent discoveries; pins Toilet Paper/Rat as a reachable goal. |
| 6 | Returns to flushing; next unlock Golden/Sewer preview in one small card. |
| 7 | Locks best item; sees free duplicate-sale filter, initially off. |
| 8 | Optional look at neighboring plots; no visit requirement or purchase prompt. |
| 9 | Returns via Own Plot button; next flush counter approaches 100. |
| 10 | Auto-Flush unlocks at 100 total flushes, whenever reached; toggle explained. |
| 11 | Watches real drops; can skip common animation without speeding server rolls. |
| 12 | Sees the daily checklist; first task progress is retroactive for this UTC day. |
| 13 | Claims completed task; sees fixed tomorrow reward without a streak threat. |
| 14 | Golden upgrade meter; sell duplicates confirmation lists what is retained. |
| 15 | Golden/Sewer portal if affordable; otherwise keeps Dirty earning goal. |
| 16 | Sewer preview shows Slippery Sock and Rat in Crocs silhouettes, with odds details. |
| 17 | Selects Sewer after Golden; learns pool choice persists until changed. |
| 18 | First Sewer rolls use real RNG; every fallback still awards Poop. |
| 19 | Compares one new item with current pedestal; replace/revert freely. |
| 20 | Optional personal practice clog: three taps, zero loot; explains future co-op. |
| 21 | Sees actual server-event countdown; timing depends on UTC, not tutorial clock. |
| 22 | Returns to next toilet progress; no modal tutorial now. |
| 23 | Pins Diamond; preview shows Sewer B and Toilet Baby. |
| 24 | Checks index threshold; discovery progress survives selling. |
| 25 | Claims first earned index reward or sees exact missing count. |
| 26 | Chooses Plaza/Sewer using full item-list comparison; no switching fee. |
| 27 | Flushes and accumulates service income; best-item lock remains visible. |
| 28 | Edits pedestal order; cosmetic expression has no stat penalty. |
| 29 | Optional event invitation; declining leaves the earning loop intact. |
| 30 | Optional session recap: discoveries, Coins, next upgrade; safe stopping point. |
| 31 | Resumes or continues with the same pinned next goal. |
| 32 | Diamond target; if short, shows estimated flush count for service-only income. |
| 33 | Buys Diamond when ready; no countdown or paid shortcut modal. |
| 34 | New Sewer B silhouettes revealed; not claimed as already discovered. |
| 35 | Adds a Sewer drop to plot; visitors see item name and base rarity label. |
| 36 | Free photo frame preview; can hide HUD locally. |
| 37 | Opens daily progress; 50-flush task should now be complete. |
| 38 | Claims remaining earned daily tasks; no bonus for buying. |
| 39 | Sees permanent return-day reward track; skipped dates do not reset it. |
| 40 | Optional friend comparison; no friend online means ordinary solo goals. |
| 41 | Flushes toward Radioactive; King Poop preview is explicitly a long-term chase. |
| 42 | Opens Odds Details; base denominator and current effective chance differ. |
| 43 | Tries reduced-effects setting; common rolls remain fast to read. |
| 44 | Changes auto-sell threshold if desired; best copy cannot be accidentally sold. |
| 45 | Optional co-op/event if live; otherwise ordinary earning continues. |
| 46 | After event, sees contribution reward separated from flush drops. |
| 47 | Uses completed-task Stamps in deterministic cosmetic catalog. |
| 48 | Previews 20-Stamp pipe trim; can save currency without expiry. |
| 49 | Reorders collection by missing/common; avoids a wall of Secret silhouettes. |
| 50 | Checks Radioactive price; purchases only if affordable. |
| 51 | Radioactive owners see King Poop + Sewer Shark unlock; others see next-tier preview. |
| 52 | Continues flushing; no rare result is scripted. |
| 53 | Optional neighbor cheer/emote; no reward for repeatedly clicking it. |
| 54 | Sees personal best discovery timestamp and photo card. |
| 55 | Pins next-session goal: Radioactive or Demon, based on actual tier. |
| 56 | Previews cartoon Hell room; portal requirements are explicit. |
| 57 | Rebirth preview explains what is kept; action locked until eligible. |
| 58 | Checks saved collection and locked items; no fabricated save-success claim. |
| 59 | Recap card: actual next cost, daily refresh time, next weekly event. |
| 60 | Optional continue or leave; future offline tank preview only if that feature has shipped. |

## Return goals

| Horizon | Free-player target and assumed activity | Guaranteed route / collection stretch |
|---|---|---|
| Day 1 | 60-120 active minutes across visits: Radioactive/Demon; 8-12 discoveries is a stretch | First Sewer visit, 3 displayed items, daily track started; Galaxy may take another day |
| Day 7 | 20-30 minutes/day after day 1: Galaxy, Space A, first rebirth | 7 return-day rewards, 12+ discoveries; never require King Poop |
| Day 30 | 20-30 minutes/day, ~12-16 cumulative hours: tier 8-10, 3-5 rebirths | 20+ discoveries and 1 completed cosmetic season; 35/35 remains aspirational |

Return-day track: first qualifying visit per UTC day, after 10 flushes. Rewards for claim days 1-7: 2 / 2 / 3 / 3 / 4 / 4 / 6 Stamps; seventh also grants Rubber Crown cosmetic once. Repeat Stamp track every 7 claimed days; no missed-day reset. Stamps cannot be purchased/traded/sold: 20 trim, 40 flush color, 60 pedestal skin, 100 title. No random rewards in this shop.

## 24 new items and pools

Base check odds below are **not final outcome odds**. Original 11 items remain, giving 35 total. Each world has A = first four rows and B = last four rows. A stays available when B unlocks. Themed pools merge with eligible legacy items; Poop remains the sole fallback at value 1. Base values are Coins; no extra sell multiplier by world.

| World / group | Item | Rarity | Base check 1/X | Value |
|---|---|---|---|---|
| Sewer A | Slippery Sock | Uncommon | 12 | 4 |
| Sewer A | Rat in Crocs | Rare | 40 | 15 |
| Sewer A | Noodle Eel | Rare | 120 | 45 |
| Sewer A | Emotional Support Plunger | Epic | 400 | 140 |
| Sewer B | Drain Goblin | Legendary | 1,500 | 500 |
| Sewer B | Fatberg CEO | Mythic | 7,500 | 2,500 |
| Sewer B | Sewer Wiener Dragon | Godly | 50,000 | 16,000 |
| Sewer B | The Forbidden Meatball | Secret | 250,000 | 80,000 |
| Space A | Orbiting Toilet Roll | Uncommon | 15 | 6 |
| Space A | Moon Cheese Nugget | Rare | 60 | 24 |
| Space A | Astro Duck | Rare | 180 | 70 |
| Space A | UFO Unclogger | Epic | 600 | 220 |
| Space B | Saturn's Seat | Legendary | 2,000 | 700 |
| Space B | Comet Burrito | Mythic | 10,000 | 3,500 |
| Space B | Black Hole Bidet | Godly | 75,000 | 25,000 |
| Space B | Cosmic Flush Father | Secret | 500,000 | 160,000 |
| Hell A | Toasted Toilet Paper | Uncommon | 18 | 8 |
| Hell A | Spicy Imp Nugget | Rare | 75 | 30 |
| Hell A | Lava Rubber Duck | Rare | 225 | 90 |
| Hell A | Screaming Hot Seat | Epic | 750 | 280 |
| Hell B | Infernal Air Freshener | Legendary | 2,500 | 900 |
| Hell B | Three-Headed Plunger | Mythic | 12,500 | 4,500 |
| Hell B | Lord of the Rims | Godly | 100,000 | 35,000 |
| Hell B | The Final Courtesy Flush | Secret | 750,000 | 240,000 |

Hell is a cartoon lava bathroom: smiling imps, orange foam, no gore, torture or frightening jump scares. All names/models are original placeholders; no copied branded brainrot characters or invented asset IDs.

## Exact luck and outcome math

`L = min(50, T * (1 + 0.05 * min(r,10)) * E * P)`.

- T = toilet base luck above; r = rebirth count; E = strongest active free/paid server event, never their product (1, 1.5 or 2); P = 10 only for a manually armed Lucky Flush charge, otherwise 1.
- Friends, VIP, cosmetics, index and offline tank do not modify luck. This keeps the disclosed probability surface small.
- Sort eligible non-Poop checks by X descending; equal X uses stable item ID ascending. For each, independently test `q_i=min(1,L/X_i)`, stop at first success. `p_i=q_i*product(1-q_j)` over earlier checks. Poop's p is the product of all failures. These sum to 1.
- The 50x cap limits inflation; some common checks can still reach 100%, making later outcomes including Poop impossible for that roll. There is still exactly one item. A lower-tier item can become LESS likely when earlier rare checks improve; advertise a luck modifier, not “every item is 10x likelier.”
- UI: `Base check 1/100,000`; separate `Current outcome chance: ...%`. Snapshot tier, pool, rebirth and modifiers at flush start. No hidden pity or probability changes inside the animation.
- A top-of-pool 1/100,000 result at L=1 has ~0.997% probability of appearing in 1,000 rolls, not a promise at roll 100,000. With earlier checks it is slightly lower. Index goals must not depend on these tails.

## Rebirth: Flush the Universe

Available at current Galaxy or above, >=1,200 successful flushes since last rebirth and sufficient Coins. No item sacrifice or paid requirement. For current rebirth count r, fee is `ceil(20,000 * 1.6^min(r,10))` Coins. New r = old r + 1.

| Property | Exact behavior |
|---|---|
| Reset | Spend fee, then set remaining Coins to 0, current toilet to Basic, run flush count to 0. No refund of upgrades. |
| Keep | All items, item acquisition multipliers, lifetime index, cosmetics, Stamps, display slots/layout, daily progress, best tier, portal discovery, paid charges/passes and offline system |
| Earnings | `M_r = 1 + 0.25 * min(r,10)`; r=1:1.25x, r=5:2.25x, r=10:3.5x. Applies only to service Coins and acquisition-stamped item sale values. |
| Luck | `1+0.05*min(r,10)`; r=1:1.05x, r=5:1.25x, r=10:1.5x |
| Visible reward | r=1 swirling bowl skin; r=3 floating pedestal skin; r=5 rainbow plumbing; r=10 Cosmic Janitor title; later rebirths only add a cosmetic counter |
| Recovery | Higher-tier worlds remain visitable; their roll additions re-lock until current tier qualifies. Old displayed items remain visible. |
| Confirmation | Side-by-side current/after values and kept/reset lists; hold 2 seconds, then confirm. No Robux prompt. |

No multiplicative exponential power, no paid rebirth skip. First-run tutorial Coins and index rewards never repeat. Offline income from best tier deliberately accelerates subsequent runs; the 1,200 new-flush requirement prevents instant repeated rebirths from retained inventory. Preview loss of wallet before confirmation.

## Index rewards and duplicate purpose

Lifetime **self-earned** discoveries count once even after sale. Traded items fill a separate “Owned via Trade” view and do not unlock discovery rewards or boards. Seasonal cosmetics are outside the 35-item index.

| Unique discoveries | Permanent reward |
|---|---|
| 3 | 10 Stamps |
| 5 | Fourth display slot |
| 8 | 20 Stamps + Pipe Apprentice title |
| 12 | Fifth display slot |
| 18 | Sixth display slot + 40 Stamps |
| 24 | Hologram pedestal skin |
| 30 | Royal Flush title |
| 35 | Full-index animated plaque; no power |

Per world: 4/8 gives themed trim, 6/8 gives a themed photo frame, 8/8 gives a trophy. No world-completion power required to progress. Original 11/11 gives Founding Flush trophy. Thresholds grant once, including migration of existing lifetime collection. Only shipped items appear in completion denominators; new world pages announce their own additions and never revoke earned rewards.

Duplicates: sell for upgrades; optional daily duplicate task; eventually trade. Do not introduce crafting, random mutations or an additional power currency at launch. Sell confirmation defaults to keeping first and displayed copies; a player may explicitly unlock their last copy, with the loss of its physical display explained.
