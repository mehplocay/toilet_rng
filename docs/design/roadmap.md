# Expansion roadmap

Proposal, 2026-10-05. Scope: extend the working loop; daily rewards/tutorial are already in progress and should be completed, not replaced. Dependencies and release gates take priority over the tentative seasonal dates. [Research](../research/genre-analysis.md), [progression](progression.md), [social/events](social-and-events.md), [monetization](monetization.md).

## Delivery rules

- Order below is priority within each milestone. Existing legacy toilets/items remain usable at launch. New portal previews say “Coming in a future update” until implemented; no inaccessible content in completion denominators or paid offers.
- The full 60-minute script describes the expanded experience. Before Sewer ships, replace Sewer lesson rows with Plaza collection/display tasks; never present a functioning portal or a reward that is not implemented.
- Effort: S = roughly 0.5-2 engineering days, M = 3-5 days, L = 6-12 days including review/QA. Estimates assume existing code is sound; content art, manager review and platform validation can add time. These are not a promise to ship four versions in 12 weeks.
- Impact: H = direct early retention, return reason or revenue/trust protection; M = useful depth/identity; L = optional polish. Ratings are hypotheses to measure.
- Model assignments follow the manager's [model matrix](../model-matrix.md): **Luna = gpt-6-luna**, **Sol 6.1 = gpt-6.1-sol**, **Astra = gpt-6-astra**. They are task assignments, not measured model benchmarks. Use Luna for isolated copy/config work, Sol for implementation, Astra for hard architecture/security review. No sub-agents are requested or launched by this document.
- Every implementation task: official docs/release-note check, server-authoritative validation, required build/checks and mobile/multiplayer QA. This design task changes no code.

## v1 — launch: make the first visit work

| Priority | Feature / deliverable | Impact | Effort | Recommended model / reasoning effort | Dependency / acceptance |
|---|---|---|---|---|---|
| 1 | Complete action-led tutorial and 100-Coin once-only reward | H | M | Sol 6.1 / medium | First real flush <15s target; sell/display understood; no fake RNG; restart cannot duplicate award |
| 2 | Deterministic service Coins + tune first four upgrades | H | M | Sol 6.1 / high | Economy simulation plus unlucky cohort; median Dirty <=5 active minutes target; no rare required |
| 3 | Permanent index rewards, first-copy lock and safe duplicate sell | H | M | Sol 6.1 / high | Existing lifetime discoveries migrate; one-time grants; displayed copies never sold accidentally |
| 4 | Finish non-punitive daily track/checklist already underway | H | M | Sol 6.1 / high | UTC/date boundary tests, no reconnect repeats, skip day does not erase progress |
| 5 | Funnel/economy instrumentation and one small dashboard spec | H | M | Sol 6.1 / medium | First flush, first sale, display, upgrades, exit minute, daily claim and currency source/sink visible |
| 6 | Free Auto-Flush at 100 flushes + animation skip | H | M | Sol 6.1 / high | Same cooldown/proximity checks, no auto-rejoin, zero duplicate grants |
| 7 | Polish existing big-drop event, accurate rarity labels, free photo framing | M | M | Sol 6.1 / medium | Use real outcome snapshot; skip/reduced effects; replay never awards another buff |
| 8 | Three cosmetic passes (49 / 79 / 99 R$) and reliable fulfillment | M | M | Sol 6.1 / high | Receipt/entitlement validation and interrupted-purchase recovery; known benefits; no paid RNG yet |
| 9 | English catalog/help/odds terminology review | M | S | Luna / medium | UI has no German strings, fake scarcity or false 1/X claim |

**Exit gate:** no known item/currency loss or duplication; Rojo build and applicable checks pass; ten-player server and touch UI smoke tests pass. With >=1,000 new players and mature cohorts, aim for >=85% first flush by 30s, >=65% Dirty by 5 active minutes, D1 >=20%. Failure triggers onboarding/balance work before acquisition spend. Thresholds are internal hypotheses; investigate confidence intervals, not one day's noise.

## v1.1 — give players a reason to return together

| Priority | Feature / deliverable | Impact | Effort | Recommended model / reasoning effort | Dependency / acceptance |
|---|---|---|---|---|---|
| 10 | Sewer room, pool selection and 8 themed drops | H | M | Sol 6.1 / medium | Explicit legacy + selected-world merge; all 8 appear at correct tier; no loss on world switch |
| 11 | Capped offline tank | H | M | Sol 6.1 / high | Server timestamps, 240-minute cap, reconnect/clock exploit tests, deterministic income only |
| 12 | Giant Clog co-op, solo scaling and fixed rewards | H | L | Sol 6.1 / high | Contribution validation, join/leave scaling, daily cap, low-population success |
| 13 | Scheduled luck/rain + shared UTC reward IDs | H | M | Sol 6.1 / high | Server hopping cannot duplicate claims; event stacking follows strongest-only rule |
| 14 | Visit/cheer, buddy checklist + equal solo route | M | M | Sol 6.1 / medium | No mandatory social/invite gate; spam limits and mute work |
| 15 | VIP known cosmetic bundle | M | S | Sol 6.1 / medium | Reuse v1 entitlements; no RNG or subscription implied |
| 16 | First reusable seasonal palette/reward catalog | M | S | Luna / medium | Data/copy task only; existing reward framework validated by Sol implementation |

**Exit gate:** compare D7 >=8% planning target with mature v1 cohort; >=20% of active players voluntarily join one event in a week; no degradation of upgrade time or mobile stability. Validate offline faucet stays within planned progression; if inflation rises, tune future accrual transparently, never confiscate earned balances.

## v1.2 — add durable medium-term goals, then optional paid luck

| Priority | Feature / deliverable | Impact | Effort | Recommended model / reasoning effort | Dependency / acceptance |
|---|---|---|---|---|---|
| 17 | Rebirth keep/reset transaction, caps and preview | H | L | Sol 6.1 / high | All reset/keep rules tested, crash-safe, 1,200 new-flush requirement; existing collection retained |
| 18 | Space room + 8 items + Sludge Throne/Rocket Bidet tiers 7-8 | H | M | Sol 6.1 / medium | Expand odds UI and free world access; both sequential tiers ship together |
| 19 | Acquisition-time sale multiplier and per-copy paid provenance | H | L | Sol 6.1 / high | Migration keeps inventory counts; unknown origins quarantined for future trading, never deleted |
| 20 | Full odds/policy system + Lucky Flush charge wallet | M | L | Sol 6.1 / high | Normal/boosted/pool/cap fixtures sum to 100%; unknown policy blocks paid RNG; atomic charge/item grant |
| 21 | Paid-RNG/provenance architecture audit | H | M | Astra / high | Review mixed-policy servers, retry/receipt abuse and migration; block sales until findings resolved |
| 22 | Paid Server Luck with durable remaining-time credits | M | L | Sol 6.1 / high | Overlap, restart, eligible/ineligible joins, duplicate receipt recovery pass; can defer independently |
| 23 | Patron cosmetic bundle + catalog previews | M | S | Sol 6.1 / medium | Known owned benefits, no content IOUs; original art only |
| 24 | Rebirth Restart deterministic product experiment | L | S | Sol 6.1 / high | No bought flush-count progress; truthful fixed amount; remove offer if poorly understood |
| 25 | Weekly co-op/friend/natural-discovery boards | M | M | Sol 6.1 / high | Verified records, capped rewarded activity, no spend ranking or exploitable rewards |

**Exit gate:** paid products remain feature-flagged off until audited. Rebirth improves repeat-run pacing without invalidating free discovery. Evaluate 7-day return and complaints alongside conversion; a revenue increase does not excuse confused odds or worse retention. No published ARPPU commitment.

## v2 — social economy and final worlds, only when justified

| Priority | Feature / deliverable | Impact | Effort | Recommended model / reasoning effort | Dependency / acceptance |
|---|---|---|---|---|---|
| 26 | Hell room + 8 items + final two throne tiers 9-10 | H | M | Sol 6.1 / medium | Cartoon presentation; endgame cost/earnings audit; tiers 7-8 already shipped in v1.2 |
| 27 | Trading threat model and recoverable transaction protocol | H | L | Astra / high | Per-copy identity/provenance already live; durable journal, recovery and rollback semantics reviewed |
| 28 | Four-copy trade UI, escrow, receipts and report flow | M | L | Sol 6.1 / high | No paid-origin items; edit resets confirmations; disconnect never loses/duplicates copies |
| 29 | Adversarial trading/persistence audit | H | L | Astra / high | Concurrency, server crash, spoofing, policy changes and repeat retries; no unresolved critical issues |
| 30 | Trading tutorial/help and scam copy | M | S | Luna / medium | Explain exact exchange, username, value limits, no external deals; review with implementation |
| 31 | Three-month seasonal shell + catch-up catalog refinement | M | M | Sol 6.1 / medium | Same event framework, no new currencies; missed rewards return within 90 days |
| 32 | Opt-in harmless foam prank | L | S | Sol 6.1 / medium | Only after social demand; consent, immunity, no gameplay interruption |

**Exit gate:** trading can remain disabled while Hell ships. At least 30 days of live economy data before enabling exchanges; zero known dupe/loss paths in adversarial QA. D30 >=3% is an internal goal to evaluate, not a condition to hide weak cohorts. If content cadence exceeds team capacity, ship fewer palettes and keep fixes/events reliable.

## Top 10 retention and virality mistakes to avoid

| Mistake | Concrete prevention |
|---|---|
| 1. “Just keep rolling” with no short goal | Next affordable upgrade and permanent discovery progress visible; service Coins every flush |
| 2. A tutorial/store wall before the joke lands | One FLUSH action first; learn sell/display by doing; no automatic purchase modal |
| 3. Treating extreme rarity as ordinary progression | No quest, world or rebirth requires 1/100,000; guaranteed currency and fixed rewards carry progress |
| 4. Making selling feel like losing collection progress | Permanent index, first-copy locks and clear display reservations |
| 5. Calling boosted odds natural or hiding Poop | Full current effective percentages; base rarity separately labeled; validate every pool |
| 6. Inflating power until old purchases/content mean nothing | Additive capped rebirth bonuses, no permanent paid luck/speed, modest faucet review |
| 7. Punishing absence and inconvenient time zones | No streak reset, repeat event windows, capped offline reward, seasonal catch-up |
| 8. Turning the funniest feature into bullying | No theft/ransom; optional low-impact pranks only; co-op works solo |
| 9. Launching trading before data integrity | Per-copy IDs, journal, escrow and recovery audit; disable instead of hoping support can repair losses |
| 10. Mistaking AFK time/CCU spikes for a healthy game | Track active actions, mature retention cohorts and voluntary purchase outcomes; no auto-rejoin or stretched timers |

## First-build recommendation

1. **Finish the 3-action tutorial and deterministic early progression.** Players reach the joke and first upgrade even with bad luck; directly addresses first-session exits.
2. **Permanent index rewards with safe duplicate selling.** Gives every common find meaning and removes the fear of sacrificing the collection for Coins.
3. **Complete the forgiving daily track, then add the capped offline tank.** Makes a short return visit useful without demanding daily attendance or an hour-long session.
4. **Ship Sewer with eight drops and a clear pool selector.** A visible new destination turns the same flush interaction into a fresh collection goal at modest content cost.
5. **Build Giant Clog on a reusable event scheduler.** Creates an accessible shared activity, weekly themes and photo moments without requiring PvP or a risky trading economy.

Instrument these five while implementing them. Keep cosmetic monetization small at launch; defer paid randomness and trading until their policy, odds and persistence requirements are proven.
