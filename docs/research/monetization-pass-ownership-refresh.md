# Roblox pass ownership refresh

Checked 2026-10-07 for the 2x Luck wiring and yielded ownership refresh tests.

- `https://create.roblox.com/docs/reference/engine/classes/MarketplaceService` documents `UserOwnsGamePassAsync` as a yielding query and says the server-side `PromptGamePassPurchaseFinished` event updates its ownership cache. Production must query only positive pass IDs and preserve verified in-session ownership when a query fails or returns a stale negative.
- The refresh regression harness starts with all configured passes verified owned, then yields each refresh lookup and returns false. The expected state remains owned for all 16 passes, including DoubleLuck. The previous test excluded DoubleLuck due to its former ID 0; the production merge behavior was already correct.
- Disabled-ID behavior remains covered with a fixture whose DoubleLuck ID is set to 0; that ID must not be queried, prompted, or granted, including through bundle implications.
