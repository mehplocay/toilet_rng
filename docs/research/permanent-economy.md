# Permanent economy API and tool review

2026-10-06. Current primary sources checked before changing production math/UI:

- https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore — UpdateAsync may replay its callback on a conflicting write. Keep the existing immutable complete snapshot, session ownership check and no-yield callback. A lost response is not evidence of a failed commit; do not roll back a rebirth or purchase.
- https://create.roblox.com/docs/cloud-services/data-stores — callbacks cannot yield. This task adds no new DataStore calls; purchases and rebirth construction remain synchronous before the existing guarded save.
- https://luau.org/library/ — bounded math, floor/ceil and table copies support the pure cost and odds calculations. Retain the repository's 9e15 integer ceiling and separate 6,000-subcoin ledger; costs remain far below it.
- https://create.roblox.com/docs/reference/engine/classes/TweenService — use existing Components.Pop/ProgressBar and lifecycle cleanup rather than introduce an animation registry. Milestones reuse the existing UpgradeMax audio slot; no invented assets.
- https://github.com/rojo-rbx/rojo/releases and https://github.com/rojo-rbx/rojo/blob/master/CHANGELOG.md — reviewed current tool release information. No project-format change or tool upgrade is required for these Luau/config edits.
- https://github.com/JohnnyMorganz/StyLua/releases — retain installed formatter and project line-ending convention; no formatting/API migration required.
- https://devforum.roblox.com/t/session-locking-explained-datastore/846799 — consulted session-lock discussion; browser returned no substantive body, so correctness claims rely on Creator Docs and the repository's controlled-yield regressions, not an unread community workaround.

No new engine behavior is assumed. Existing announcement queues, cooldowns, receipt paths and session lease mechanisms are retained. Published-server outages, native UI rendering and input still need Studio/device QA. All web requests contained public documentation identifiers only.

Validation environment: Studio MCP `list_roblox_studios` returned `studios: []`. Installed Selene could not load the configured Roblox standard library. Native engine and lint limitations are recorded separately from passing headless/runtime checks.
