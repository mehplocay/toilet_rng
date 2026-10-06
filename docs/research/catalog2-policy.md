# Catalog 2: paid randomness and commerce research

Checked 2026-10-06 before implementation.

- https://create.roblox.com/docs/production/monetization/paid-random-items — expressly includes probability modifiers. Disclose every possible final item and numerical percentage before purchase/use; rarity summaries alone are insufficient. A labeled Info/Details dialog may contain the itemized table. Rounded tiny probabilities need enough significant decimals and an explicit rounding disclaimer. PolicyService restrictions cover interaction, not only purchase prompts.
- https://create.roblox.com/docs/reference/engine/classes/PolicyService — GetPolicyInfoForPlayerAsync yields and may error. Use pcall and permit only an explicit ArePaidRandomItemsRestricted=false; errors/missing/expired values fail closed. Do not infer eligibility from location or age.
- https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622 and https://devforum.roblox.com/t/weekly-recap-may-25-29-2026/4659481 — current staff clarification/release communication points to expanded odds and policy requirements. Full announcement was bot-gated in this session; implementation relies on Creator Docs, not community replies.
- https://create.roblox.com/docs/reference/engine/classes/MarketplaceService and https://create.roblox.com/docs/production/monetization/developer-products — server ProcessReceipt, durable PurchaseId dedupe, defer unconfirmed grants; prompt-finished events do not establish product delivery. Receipt retries have no historical display-income snapshot. Keep saved in-experience quotes and disable Lucky external sales.
- https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt — client-facing prompt visibility/distance is not an authorization boundary. VIP pad validates server ownership, living character, finite actual distance, cooldown, caps and profile identity at commit.

No secrets were sent in web queries. Policy requirements do not create an automatic refund API; restricted/cap-saturated pending receipts remain recoverable and need operational support if eligibility never returns.
