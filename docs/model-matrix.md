# Codex model assignment (manager decision): QUALITY FIRST

Owner decision: always go for quality. Token cost is not a constraint. Source: `codex debug models`. Run with `codex exec -m <model> -c model_reasoning_effort=<effort>`.

| Task | Model | Effort |
|---|---|---|
| Anything players see: UI, world, 3D assets, effects, game feel | gpt-6-astra | high |
| Server logic touching coins/items/data/purchases, event systems | gpt-6.1-sol or gpt-6-astra | high |
| Security / exploit audits, architecture, hard bugs | gpt-6-astra | high (xhigh if still failing) |
| Game design, research, roadmaps | gpt-6-astra | medium-high |
| Merge-conflict resolution, formatting, trivial config/text edits | gpt-6-luna | medium |

Rules:
1. Quality over savings. Do not shrink or skip work to save tokens; iterate until the result passes the manager's review (inspect screenshots/previews, run checks).
2. Every visual deliverable goes through a render/preview-and-critique loop; send it back for another round if it is not clearly good.
3. Risky systems get an independent second review by a different session before merge.
4. Parallel sessions run in separate git worktrees/branches; the manager merges one by one and keeps main always building.
5. Update this table when results show a model over- or underperforming.
