# Audit 2: remote trust boundary

Checked 2026-10-05.

- [Creator security boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary): server checks must cover types, values, permissions, context and request frequency. NaN requires an explicit check; comparisons alone are insufficient. Client prompt visibility and cooldowns are not authorization.
- [Security tactics](https://create.roblox.com/docs/scripting/security/security-tactics): keep authoritative state and decisions on the server. Replicated scripts/configuration are public information.

Applied to all 19 inbound handlers, prompts, manual/auto flush and presentation messages. Existing token buckets and finite integer/catalog checks were retained. Yielding economic handlers now refuse additional purchases/claims while a save is pending. No client-provided prices, RNG samples, elapsed offline time or ownership booleans are accepted. See `docs/audit2.md` for the complete handler matrix and tests.
