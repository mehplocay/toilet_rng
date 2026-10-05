# Social systems and events

Proposal, 2026-10-05. Uses [progression](progression.md) rewards, pools and luck formula. Evidence: [genre research](../research/genre-analysis.md). Target: a player can understand somebody else's achievement in 3 seconds and join an activity without buying or chatting.

## Shared event schedule

Use UTC event IDs shared across servers. Server hopping never repeats personal rewards for the same ID. Event UI shows local display time plus UTC details. Schedule is deterministic; joining a new server does not restart timers. A quiet server gets the same opportunities.

| Event | Cadence / duration | Action / reward | Limits |
|---|---|---|---|
| Luck Hour | Every 3 hours at 00:00, 03:00, etc. UTC; 60 minutes | Free E=1.5 for every player's eligible pool; mint-green sky tint | Honest one-hour duration; no attendance-exclusive item; suppress unnecessary common VFX |
| Toilet Paper Rain | Every hour at :15; 90 seconds | Each player has 10 personal visible pickups; each gives 1 Toilet Paper, fixed, no RNG; 10/10 gives 2 Stamps | Max 10 pickups and 2 Stamps per account/event ID; no racing other players for stock |
| Giant Clog | Every hour at :30; 3 minutes + 1-minute warning | Co-op plunger taps clear a shared clog; 3 Stamps on success, 1 on timeout for qualified contributors | First 3 rewarded bosses per UTC day; further runs social only; no rare random boss loot |
| Big discovery | Actual self-flushed base X>=100,000; effect 8s, luck 5 minutes | Unpaid-origin result grants server E=2; every finder gets display/photo celebration | Server-wide cooldown 10 minutes for new buff; paid-origin finds give cosmetic celebration only; no buff stacking or recursive retrigger |
| Weekly Flush Party | Saturday 16:00 UTC, 15 minutes; repeats Sunday 08:00 UTC | Theme reveal, Giant Clog variant and 6-Stamps weekly participation reward | Reward once per week ID, obtainable in either replay or a 10-minute solo task through Friday |

E is always max(active server effects), never multiplication. Lucky Flush uses P from progression; purchasing another server boost during E=2 must not waste duration or raise E above 2. See monetization for queue/eligibility handling. Seasonal events replace one boss/rain presentation, never add a second overlapping activity to the schedule.

## Giant Clog specification

- An inflated paper-and-slime mound appears in the plaza bowl; no combat damage or gear stats. Join button moves the player to the ring voluntarily; their Auto-Flush pauses and resumes on return.
- After a 20-second join period, freeze participant count N (minimum 1). Required valid plunges = `40 * N`; 160 seconds remain. Each player can contribute at most one accepted plunger action/second. Target completion 60-120 seconds with movement and missed taps.
- Every 20 seconds a 5-second foam sweep asks players to step aside; being hit delays their next tap by 2 seconds. No item/coin loss. Mobile has one large Plunge button and an accessible low-motion setting.
- Reward eligibility: >=10 valid contributions and >=30 seconds in the ring. Joiners after count freeze may help without increasing health; late joining alone does not qualify for a reward.
- Leaving never increases health; at 80 seconds remaining, reduce remaining required hits by 20 per departed original participant, floor 10. No purchased damage, revive or finishing blow reward.
- Solo: 40 accepted taps is feasible; if a server empties, remaining player can finish. Timeout awards participation Stamp and a funny deflated-clog animation, never a sales prompt.
- No tradeable boss item at launch. Five lifetime wins grant Plunger Pal trophy; 20 give Flush Crew title. Practice clog awards nothing and can be replayed anytime.

## Friends and visible ownership

| Feature | Rule | Reason |
|---|---|---|
| Ten visible plots | Nameplate, three starting items, toilet tier, one pinned discovery goal | Keep other players' progress readable like the mockup |
| Visit / cheer | One click to view a plot; canned cheer emotes, per-target 10-second cooldown, mute option | Social feedback works without free-text chat |
| Friend session | Optional friend presence/join affordance using supported Roblox UI at implementation | No invite spam, invite-for-reward or forced group membership |
| Buddy checklist | Once/day: complete 50 personal flushes while a friend is present for >=5 minutes -> 2 Stamps; solo alternative 75 personal flushes -> same 2 | Social nudge with equal solo access; no luck stacking or alt-account power |
| Plot likes | One like/account/plot/day, owner-only count, no rewards/global ranking | Appreciation without a bot-farm economy |
| Compare index | Show mutual discoveries and missing silhouettes; hide inventories by preference | Enables conversation without exposing trade pressure |
| Consensual prank, v2 optional | Both opt in; harmless foam hat for 5 seconds; 60-second target immunity | Never interrupts flushing, removes loot or sells protection |

Do not add theft, ransom, paid protection, involuntary clogging or PvP inventory loss. No outside social account or voice chat is needed to complete any feature.

## A 1/100,000 drop becomes a moment

1. Server commits the item before animation. Camera choice: short reveal or ordinary card; skip and reduced motion always available.
2. 0-2s: bowl glow and rising silhouette. 2-5s: original item model, large name and `BASE CHECK 1 IN 100,000`. Add readable `Your outcome chance: ...%` from the actual roll snapshot, including paid/free modifier labels.
3. 5-8s: gold confetti at finder plot and small server banner: `<display name> discovered KING POOP!`. Never falsely call a boosted outcome a natural 1/100,000 chance.
4. Two buttons: DISPLAY and PHOTO. Free photo mode frames toilet + item + discovery card, hides unrelated HUD; user chooses capture/sharing via available platform tools. No automatic external posting or reward for posting.
5. Discovery card records item, UTC date, world, base denominator and effective percentage; optionally hide player identity. It does not show chat, friends list or real-world information.
6. A 60-second beacon invites spectators without teleporting them. An unpaid-origin find grants free E=2 for 5 minutes under the event cooldown above; paid-origin finds celebrate cosmetically without creating another random modifier. A replayable local trophy animation can be viewed later without retriggering luck.

Queue server banners at most once per 10 seconds; aggregate rapid discoveries. Only the actual self-flush creates a moment; trades, reconnects, displays and photo replays cannot. No paid cutscene priority. Original GDD's global “1 in X” wording is revised to separate base rarity from actual probability.

## Trading: v2, after persistence and provenance

**Scope:** same-server, two-player, item-for-item only, maximum 4 individual copies/side. No Coins, Stamps, passes, charges, paid cosmetics, external currency, loans, auctions or off-platform value claims. Unlock after 60 active minutes and 200 lifetime flushes; complete a 30-second practice trade. These friction gates reduce spam, not proof of identity.

| Risk | Required behavior / launch gate |
|---|---|
| Bait-and-switch | Full item names, rarity, copy count and origin shown. Every edit clears both approvals. Step 1 review; then immutable 5-second countdown; then both confirm final exact contents. |
| Fake value | Show configured NPC sale value labeled “NPC sell value”; never call it a market appraisal or Robux value. Warn once when a side gives its last copy. |
| Impersonation | Show Roblox username alongside display name, no trusted/admin badge from player text; accept only through trade UI. No trade links in chat. |
| Spam/coercion | Default friends-only requests; users can select everyone or off; max 1 request/target/minute, 3 total/minute; cancel/block available throughout. |
| Paid provenance | Mark every copy affected by a paid modifier at acquisition, preserving origin through transfers. Initial launch excludes all paid-origin copies for everyone. If later enabled, both parties must pass paid-item trading policy checks. |
| Unknown history | Legacy/ambiguous origin copies are untradeable until verified; remain sellable/displayable. Do not guess origin from rarity or current owner. |
| Dupes / disconnects | Unique copy IDs, escrow locks, transaction ID and durable journal; recover to exactly one owner per copy. No “success” before durable completion. |
| Inventory races | Cannot sell/display/retrade locked copies. Revalidate ownership and both policy states at final commit. Disconnect before commit cancels/unlocks; after commit recover the committed result. |
| Support | Both users receive receipt listing before/after copies and transaction ID; keep server audit record 30 days. In-game report action; staff review verified fraud/bugs. No automatic reversal that duplicates onward-traded items. |

Current inventory is aggregated by item ID. Trading requires a reviewed migration to per-copy identity/provenance and a reconciled cross-player transaction protocol; a naive pair of saves is insufficient. Launch gate: zero duplication/loss in disconnect, timeout, concurrent sell and recovery tests. Keep feature disabled if the audit fails. Check official PolicyService requirements again before implementation; [policy sources](../research/genre-analysis.md#policy-findings-and-design-implications).

## Leaderboards

| Board | Score / reset | Reward / fairness |
|---|---|---|
| Local showroom | Current inventory base value including displayed copies; refresh 30s | Flex only; label ownership, not skill; no sale/rebirth multiplier |
| Friends' index | Lifetime self-earned unique count; no reset | No material reward; paid-luck participation visible as a separate filter |
| Weekly Flush Crew | Qualified Giant Clog wins, cap 3/day; UTC Monday reset | Cosmetic badge at 5 wins for everyone; top ranks get name placement only |
| Natural discoveries | Rarest effective self-flush probability with no paid modifier, top 10 | Cosmetic recognition; verify server record; free event/rebirth effects included in probability |

No Robux-spent board and no consumable prizes for total rolls. Ties on weekly board share rank; do not reward 24-hour attendance. Drop suspicious records pending review rather than publicly accusing players.

## First three months: proposed Oct-Dec 2026 calendar

Assumption: soft launch during October; shift the whole schedule if launch slips. One reusable seasonal shell, deterministic cosmetics only. Event availability uses inclusive dates 00:00 UTC through next-day 00:00 UTC after the end date. Weekly party still repeats; no single-time exclusive reward.

| Dates / release | Content | Fixed earnable reward |
|---|---|---|
| Oct 5-11 / v1 baseline | Tutorial, index thresholds, reliable daily track; no boss promise yet | Rubber Crown on seventh claimed day |
| Oct 12-18 | First rain cycle + showroom photo week | Complete 3 daily checklists during window: orange photo frame |
| Oct 19-25 / v1.1 target | Sewer A/B, offline tank, Giant Clog beta | Five qualified boss wins: Plunger Pal trophy |
| Oct 26-Nov 1 / Spooky Plumbing | Paper-ghost rain and pumpkin clog; same mechanics | 5 daily checklists: Pumpkin Seat skin |
| Nov 2-8 | Balance/bug week; optional Sewer collection tour | 50 Sewer flushes: sewer postcard cosmetic |
| Nov 9-15 | Community Clean-Up, shared progress display from capped boss contributions | 3 own boss wins: Safety Vest trim, independent of global population |
| Nov 16-22 / v1.2 target | Space A/B and rebirth release | Visit Space + 100 Space flushes: Moon Roll frame |
| Nov 23-29 / Cosmic Leftovers | Comet-themed rain, reuse boss | 5 daily checklists: Turkey Rocket toilet skin |
| Nov 30-Dec 6 | Performance and catch-up week | Earn one missed October cosmetic via 5 daily checklists |
| Dec 7-13 / v2 content target | Hell A/B, cartoon lava clog; trading only if audit passes | 100 Hell flushes: Toasty Throne trim |
| Dec 14-20 / Winter Pipes | Snowflake rain, frozen Giant Clog | 3 boss wins: Snow Plunger trophy |
| Dec 21-31 / Frosty Flush Festival | Two-week relaxed checklist; no new gameplay system | Any 7 daily checklists: Snow Globe Seat skin; no consecutive days required |

All seasonal skins are nontradeable, zero power and excluded from the permanent RNG index. Reissue via the free catch-up catalog within 90 days at 60 Stamps each; do not advertise “never returns.” Per weekly release budget: one palette/model skin + one short objective, not eight new currencies. If a world slips, reuse an unlocked-world task with the same reward, update the public calendar before its start, and avoid selling access to promised content.
