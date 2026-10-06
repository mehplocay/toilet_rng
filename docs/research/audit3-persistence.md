# Audit 3: leases, budgets and shutdown (2026-10-06)

UpdateAsync may rerun its non-yielding transform and consumes read/write budgets. Throttling queues and per-key throughput remain finite; an error can follow a committed write. Session ownership must be checked inside every transform, not just before the request. Whole-profile snapshots preserve debit/credit and receipt atomicity.

The 2025 storage announcement and 2026 Extended Services rollout describe changing experience-wide quotas. Do not certify production capacity using an old per-server formula. This game serializes durable player actions, rate-limits their entry and fails closed on exhausted save retries; it does not dynamically schedule against GetRequestBudgetForRequestType. Real multi-server budgets and shutdown latency remain release checks. Ordinary autosave can lose recent free progress after a crash; this differs from duplicating a paid receipt.

Sources:
- https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
- https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing
- https://create.roblox.com/docs/cloud-services/data-stores/observability
- https://devforum.roblox.com/t/datastores-access-and-storage-updates/3597255
- https://devforum.roblox.com/t/extended-services-for-data-stores-is-now-available/4504347
