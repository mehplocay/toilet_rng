# Codex model matrix (manager decision)

Source: `codex debug models` (local catalog). Adjust when results suggest it. Pass with `codex exec -m <model> -c model_reasoning_effort=<effort>`.

| Task type | Model | Effort |
|---|---|---|
| Config/data edits, text, tiny fixes, formatting | gpt-6-luna (fast, cheap) | medium |
| Standard features, UI, world building, refactors | gpt-6.1-sol | medium |
| Server logic: data saving, purchases, events, anti-exploit | gpt-6.1-sol | high |
| Hard bugs after Studio testing, tricky architecture, security review | gpt-6-astra (frontier) | high |
| Spec/design docs and roadmaps | gpt-6.1-sol | medium |

Rules: start with the cheapest model that fits; escalate one step only if a result fails review. Default (config) is gpt-6.1-sol / low, used for tasks 1-3 without issues.
