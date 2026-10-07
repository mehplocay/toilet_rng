# Third defensive hardening review

2026-10-06. Reviewed and changed only this worktree on `feature/audit3`. No commit or push. No live purchases, production data writes or Studio certification.

## Scope and method

Read `AGENTS.md`, `docs/GDD.md`, the reference mockup, the first two audit reports, admin-panel documentation, monetization design/catalog, Wave 1 integration, linear luck, rebirth and economy-v2 documents. Reviewed all **147 Luau files in src**, including server startup/services/admin/world builders, shared rules/configuration/visuals, client UI/audio/presentation/effects and private admin client. Generated map placements were included. Inspected remote creation and consumers, not just names in configuration.

Current production configuration takes precedence over superseded historical report tables: 47 items, 15 toilets, nine rarities including Celestial; full linear luck capped at 10x; uncapped multiplicative cash factors; single-click, coin-gated rebirth plus 300 fresh flushes; permanent tiers/upgrades/displays. No balance values or earlier test expectations were changed.

Started with the existing executable suite: **293 passed, 0 failed**. Added ten finding-focused scenarios before fixes: **298 passed, 5 failed**. The failing scenarios reproduced collection work before rate rejection (36,000 profile lookups), arbitrary index-ID reflection, unrelated product completion clearing the prompt lock, exclusive-save auto cancellation, and permissive metatable validation. After fixes those ten passed. Added two further whole-remote negative matrices; final audit result is **305 passed, 0 failed**. Existing tests were neither deleted nor weakened.

The harness executes production modules with controlled time, engine doubles, UpdateAsync callback replay, errors before/after commit, held yields, departure and session takeover. New cases live in `scripts/audit3-server.luau`, included by `scripts/check-audit.ps1`. A fresh live session per malformed value prevents expired leases or depleted buckets from hiding validation failures. This is deterministic defensive QA of our code, not evidence of attacks against another game.

## Findings and fixes

| ID / severity | Description and failure scenario | Fix | Executable regression |
|---|---|---|---|
| A3-01 / Medium, resource abuse | CollectIncome, CollectOffline and limb/touch collection performed character/plot queries and Data:Get before the existing action bucket. Twelve players sending 1,000 rounds of each trigger caused 36,000 lookups even with no collectible balance. This is avoidable handler work, not 36,000 DataStore requests. | Shared `CollectIncomeRequest` admission bucket (20 burst, 10/s) before geometry and ledger access. Existing action and durable-save limits remain in force; empty contacts still do not consume the action/save buckets. | `audit3: twelve-player collection flood...`: bounded profile calls across all three entry paths, no writes. Existing pad sweep, empty-contact, distance and retry scenarios still pass. |
| A3-02 / Low, malformed response amplification | ClaimIndexReward accepted arbitrary strings and reflected them as RewardId alongside a State refresh; a 100,000-byte or markup ID was not a catalog request. No cross-player injection or reward duplication was demonstrated. | Reject IDs longer than 64 bytes or absent from IndexProgress.ById before profile access/results. | `audit3: unknown index IDs...`: no result/state for huge or forged IDs; a real catalog ID still reaches eligibility handling. |
| A3-03 / Low, purchase state isolation | Completion for a different product cleared the current prompt's boolean lock. That could allow overlapping prompts or disrupt saved-offer UX. The callback itself never grants a product; no free paid grant was demonstrated. | Store the active server-configured product ID and require a matching completion before clearing the lock. | `audit3: unrelated product completion...`: negative/zero/other configured IDs with both completion outcomes cannot unlock; matching cancellation clears the saved quote normally. |
| A3-04 / Medium, reliability | A replacement save lasting a 0.1s auto scheduler tick made Data:Get unavailable and permanently disabled Auto Flush. Quote/receipt/rebirth/paid-flush saves could unnecessarily erase the enabled mode and activity session. | CanAuto may inspect only unlock eligibility in the hidden profile while a replacement is in progress and its session remains valid. Flush awards still require Data:Get and cannot mutate during the save. | `audit3: exclusive saves pause auto awards...`: ten held ticks, zero awards, same activity state, exactly one award on resumption. Five separate death/expiry/closing/departure/shutdown cases still fail closed. |
| A3-05 / Informational, internal defense | Settings/admin validators accepted tables carrying metatables, including inherited admin argument values. Ordinary Roblox remoting strips metatables, so this is not classified as a remotely exploitable privilege escalation. | Explicitly reject metatables in both settings schemas, admin argument schemas and bounded JSON-tree validation. Existing cycle/depth/node checks remain. | `audit3: table validators...`: metatables, inherited Give fields and cyclic nested values reject. |

Changed production files: `Services/IncomeService`, `Services/IndexService`, `Services/CommerceService`, `Services/MonetizationService`, `Admin/Rules`, shared `AudioSettings`, `PresentationSettings`, and `Config/Remotes`. No new remotes or client authority were introduced. The auto-save pause behavior above supersedes the older rebirth document's note that an exclusive save can stop the toggle.

## Remote and authority inventory

All 29 public endpoints are RemoteEvents; no RemoteFunction exists in src. Each inbound action has server admission limits, with collection sharing its internal admission/action/save budgets. Unknown IDs are dictionary/allowlist lookups rather than keys stored in unbounded player maps. The two added matrices cover surplus arguments on every public endpoint and NaN, infinities, negative/huge/fractional numbers, oversized/invalid-byte strings, empty/cyclic/metatable tables at their argument positions. Existing action-specific tests cover valid-shaped adversarial state transitions.

| Endpoint(s) | Accepted intent / server checks |
|---|---|
| Flush | No arguments; live session, living owner, own plot/range for manual use, shared cooldown, server RNG/luck, numeric room and paid-charge authorization. Prompt and auto call the same authority. |
| Sell, Display | Catalog item IDs; finite bounded integer count/slot; available copies/reservations, protected copies, physical/schema capacity and wallet/Earned room. No client price. |
| BuyToilet, BuyUpgrade | Known next toilet / known track and expected level; affordability, cap, generation and busy-save checks. |
| Rebirth | One expected integer level; current generation, wallet gate and fresh run flushes. Complete reset/reward replacement before any yield; no client duration, reward or inventory accepted. |
| CollectIncome, CollectOffline | Zero or one bounded slot for normal collection; no offline payload. Own living plot, valid pad/range, offline remainder and shared debit/credit ledger. |
| ClaimReward, ClaimVIP | No arguments; server UTC claim state, eligibility/entitlement, cap and serialized persistent marker plus reward. |
| ClaimIndexReward | Known bounded reward ID; server collection eligibility, durable claim and one-time stamp/slot/cosmetic grant. |
| BuyPass, RefreshPasses | Known pass key / no arguments; configured positive IDs, serialized server ownership lookup, bounded prompt state; no supplied numeric ID or entitlement accepted. |
| BuyProduct, LuckyFlush | Known product, exact server quote and reviewed odds token / bounded current odds token. Persistence, policy, capacity and busy checks. Receipt processing is a platform callback, not a remote. |
| AutoFlush, PlayerActivity | Boolean enable / no arguments; lifetime unlock, living owner, server clocks and activity session. Activity cannot supply duration/awards. |
| Settings, PresentationSettings, AnimationSkip, PlotColor | Strict supported preference schemas/boolean/allowlisted palette; color ownership checked server-side. Presentation settings cannot change RNG or accounting. |
| State, TutorialDone | No arguments; bounded snapshot requests / onboarding dismissal only. No progression reward for dismissing. |
| DevGrant | Studio-only guard plus fixed grant keys and limits. Unavailable in a live server. |
| Result, Event, ServerLuck, IncomePending, DropAnnouncement | Outbound only: FireServer has no authority or relay handler. |
| Private admin Command (additional endpoint) | Owner UserId **1212975135**, endpoint bound to its recipient, authorization on each request, bounded sequence/action/schema and rate budgets. Group authorization disabled. Owner modules reside in ServerStorage until authorized delivery. |

## Economy, persistence and lifecycle review

- **Money/items/RNG:** Existing suites cover double sell, duplicate display reservations, legacy sparse 100-slot capacity, first-copy/protected-copy rules, reward reclaims, integer/subcoin boundaries at 9e15, final fractional tails and saturation without discarding unpaid pending coins. Cash multipliers are applied once at the source; collection and quoted products do not multiply again. Linear luck tests compare every production pool and disclosure distribution, including saturation, Celestial/Secret outcomes and unconditional Poop fallback. A rejected flush is not a successful empty roll. Admin forced drops use catalog IDs and exclude natural flush/rarest-find credit.
- **Rebirth/migrations:** Expected-generation replay, double click, missing/spent gate, held reset versus collection/purchase/flush, callback replay and departure are covered by the retained rebirth suites. The entire copied reset is published only through guarded persistence. Wave 1, UpgradeVersion, removed Extra Slots, preserved paid legacy capacity, RebirthAppliedSlots and Celestial fields are sanitized and round-tripped. Rebirth does not rewind receipts, daily claims or Lucky charges. Old binaries must be retired before rollout.
- **Purchases:** Receipt benefit and PurchaseId share a durable profile write; acknowledgements follow successful persistence. In-memory receipt history is capped at 128; eviction first writes a permanent tombstone. Errors/unknown products/lease failure/capacity defer. Existing tests cover commit-with-lost-response, retry, duplicate delivery, archived replay, held save/leave, unquoted receipts, bundles and every product's grant. Bundle ownership implies passes without consumables or duplicate cash factors; gifting is unavailable. Server pass queries and platform server completion signals are the ownership sources. Saved verified true ownership is intentionally retained on stale/failed lookups; this is not a refund/revocation reconciliation system.
- **Paid RNG:** Failed/missing/expired/restricted policy fails closed at prompt/arming/use and new receipt grant. Already-saved receipts can be acknowledged without granting again. Odds token binds current tier/luck; charge and rolled item/service reward persist together before presentation. One review authorizes one flush; 0.2/s arming limits paid-flush saves. Developer products currently all have ID 0, so actual billing paths were exercised with fixture-only IDs. The only enabled pass is VIPStar, ID 2008628314.
- **Data:** Unique per-load tokens, 180s leases and callback-time ownership/expiry checks prevent an old session overwriting a new one. Save snapshots are immutable; ambiguous writes are retried without rollback. Ordinary autosave is every 60s. Guarded economic handlers do not enqueue unbounded save waiters. Shutdown freezes mutations and waits up to 25s for loads/saves. Receipt storage grows durably with purchase history by design; it is not an unbounded per-player RAM queue.
- **Admin/client trust/chat:** Private UI is not the authorization boundary. Every command is checked server-side; imports retain bounded JSON/schema sanitation and cannot import Marketplace entitlements or natural rarity credit. Runtime test ownership is separate and expiring. No client module decides authoritative RNG, coins, purchases or claims. No credentials or live-client path to Studio grants were found. Rare announcements originate from server awards with deduplication, queue limits, TTL and sender cooldown; account names/catalog text are bounded/escaped. Ordinary chat uses TextChatService; plot signs have no user-editable free text and non-chat labels do not enable RichText.
- **Load/cleanup:** Auto uses one scheduler; path and auto-collect check live player/plot/entitlement state. Cosmetic precedence creates one trail/tag combination; companions are local, capped and distance culled. Player/death/respawn cleanup and delayed lookup completion are exercised by retained tests. Reveal queues, sound voices, idle effects and transient world/UI instances are bounded. TemplateLoader allows only the expected MeshPart/SurfaceAppearance structure. Streaming-aware registries release removed entries and rebuild on return. Valid display toggling can still cause bounded but substantial allocation; headless bounds are not frame-time measurements.

Relevant regression groups retained: `check-audit.luau`, `audit2-server/client`, `audit-admin`, `audit-path-catalog`, `audit-catalog2`, `audit-free-slots`, `audit-display-collect/client`, `audit-economy-v2`, `audit-rebirth*`, `audit-wave1`, `audit-luck-linear`, `audit-autoflush-animation`, `audit-cosmetic-merge`, `audit-chat-*`, plus pure/UI/world/balance checks.

## Verification

| Gate | Result |
|---|---|
| StyLua `--verify` on changed Luau; `--check --line-endings Windows src scripts` | Pass; Windows line endings retained. |
| `rojo build -o build.rbxl` | Pass. |
| All 22 standalone `scripts/check-*.luau` | Pass. `check-audit.luau` and `check-ui-runtime.luau` execute through their PS1 bundlers. |
| `scripts/check-audit.ps1` | 305 passed, 0 failed. |
| `scripts/check-ui.ps1` | Pass, including all 972 layout cases and existing callbacks/lifecycle suites. |
| `scripts/check-visuals.ps1`, `scripts/check-world.ps1` | Pass; 119 template paths, six template modes, geometry/effect budgets, 49,152 plot-choice cases and 15,542 reachable samples. |
| `balance.luau`, `wave1-balance.luau`, `rebirth-values-simulations.luau`, `rebirth-balance.Print()`, `simulate.luau` | Pass with `luau --codegen -O2`; `income-balance.Print()` is exercised by `balance.luau`. Three million seeded RNG rolls and all retained balance assertions pass. |
| `git diff --check` | Pass. |
| Selene | Attempted; cannot load configured `roblox` standard library. No clean lint claim. |

## Residual risks and owner acceptance

Headless mocks do not establish engine billing, actual cross-server DataStore consistency/quotas, shutdown timing, native chat filtering, streaming or GPU/physics behavior. No new duplication or owner-authorization bypass was reproduced. That is a review result, not a guarantee that no exploit exists.

Ordinary free gameplay can lose unsaved progress on a crash; no arbitrary-outage exactly-once claim is made. Runtime budgeting is based on bounded application traffic and retry/fail-closed behavior, not a dynamic DataStore budget scheduler. Many legitimate simultaneous durable actions can still throttle. Receipt tombstones must not be deleted; external rollback of profile/archive data can break purchase recovery. Product mappings must remain stable. External unquoted coin receipts use processing-time income; disable external sales when exact advance quotes are required. Lucky external sales must remain disabled.

Activity reports can be automated: the AFK guard is a pacing/UX feature, not proof of a human. Network-owned character position is not a general movement anti-cheat; range/plot checks protect these actions, but teleport/speed manipulation needs live evaluation. Client-only visual tampering cannot be prevented from changing the exploiter's own screen. Adding custom sign/name input later requires TextService filtering; escaping alone is insufficient.

Owner manual checklist:

1. In an isolated published universe, test real receipt redelivery, disconnect after payment, failed/ambiguous saves and same-account server hops. Verify one grant, eventual recovery, no stale-session write and bounded shutdown. Inspect DataStore budget/queue dashboards under 12-player durable-action load.
2. Before enabling product/pass IDs, verify creator ownership, prices, external-sales settings and stable mappings. Test bundle overlaps, owned/canceled/external pass purchases, Lucky restricted/failed/expired policy, precise normal/boosted odds and one charge per reviewed use. Current ID-0 products were not purchased.
3. With owner and non-owner accounts, verify private admin delivery, denial of copied commands, lease expiry/respawn restoration and tagged forced-drop behavior. Confirm production servers cannot reach Studio grants.
4. Run a 12-player, 30-minute Studio/device traversal with streaming, respawns, far auto flush, display toggling and effects. Measure MicroProfiler frame times, heap/instance/tween/sound growth and bandwidth; confirm UI/prompt recovery and one cosmetic set after respawn.
5. Verify native chat audiences/opt-outs and account labels, single-click rebirth reset/keep disclosure and double-click behavior, offline partial collection at wallet limits, then retire all older profile-schema servers before rollout.

Research checked current Creator API/docs, Roblox staff platform-change discussions and relevant tool documentation. Topic notes: [remote admission](research/audit3-remotes.md), [purchases](research/audit3-purchases.md), [persistence/2026 quota changes](research/audit3-persistence.md), [paid randomness](research/audit3-paid-random.md), [chat/streaming](research/audit3-chat-streaming.md), [tools](research/audit3-tools.md).
