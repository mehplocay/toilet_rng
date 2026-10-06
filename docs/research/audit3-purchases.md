# Audit 3: receipts and passes (2026-10-06)

ProcessReceipt can repeat, arrive out of order and execute for the same purchase on two servers. Returning PurchaseGranted is not itself a durable grant. Store the benefit and PurchaseId together under the profile session lock before acknowledgement. NotProcessedYet has no periodic retry guarantee; rejoin/another purchase can trigger delivery.

Reviewed the existing atomic replacement, bounded receipt history and archive-before-eviction. Unknown/disabled products defer. Product prompt completion grants nothing; its active lock now matches the product ID. Passes use server UserOwnsGamePassAsync and the server-only completion signal; ownership queries are cached, so external purchases can appear later. No gift recipient remote exists; bundle benefits derive from verified ownership.

Sources:
- https://create.roblox.com/docs/reference/engine/classes/MarketplaceService
- https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing
- https://devforum.roblox.com/t/implementing-player-data-and-purchasing-systems/2839941
