# Audit 3: paid RNG and disclosure (2026-10-06)

ArePaidRandomItemsRestricted is a field returned by GetPolicyInfoForPlayerAsync, not a PolicyService method. Restricted users must not interact with paid random generators. A failed lookup must not become permission. Paid random item outcomes require numerical odds disclosure, including the effect of paid luck.

LuckyService checks policy before purchase, arming and consumption; charge consumption and item grant share one durable replacement. Odds use the same rare-first RollService distribution as awards: each check is min(1, luck / denominator), actual outcome probability also includes earlier misses, and Poop receives the remainder. Full linear luck has no ceiling. Base item labels alone are not the paid disclosure. Policy and native purchase UX still require live testing before enabling product IDs.

Sources:
- https://create.roblox.com/docs/reference/engine/classes/PolicyService
- https://create.roblox.com/docs/production/monetization/paid-random-items
