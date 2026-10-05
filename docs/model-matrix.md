# Codex model assignment (manager decision, by difficulty)

Source: `codex debug models`. Run with `codex exec -m <model> -c model_reasoning_effort=<effort>`.
I judge every task on difficulty and risk, not on its type:

| Difficulty | Examples | Model | Effort |
|---|---|---|---|
| Easy | web research / doc lookup, summaries, text and config edits, formatting, small fixes, README | gpt-6-luna | low-medium |
| Medium | normal features, UI screens, world building, refactors, tests | gpt-6.1-sol | medium |
| Hard | server logic where bugs cost money/data (saving, purchases, events, anti-exploit), multi-system changes, debugging after Studio tests | gpt-6.1-sol | high |
| Very hard | tricky architecture, hard-to-find bugs, security review, anything Sol failed once | gpt-6-astra | high |

Rules: start with the cheapest model that can do the task well; escalate one step only if the result fails my review. Any task mixing easy research with hard coding is split in two sessions. Update this table when results show a model over- or underperforming.
