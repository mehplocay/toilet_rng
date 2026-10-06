# Audit 3: remote admission (2026-10-06)

Creator guidance requires server validation of type, value and context, including NaN/infinity, and server rate limits before expensive work. ProximityPrompt and touch events are also untrusted triggers. Engine transport limits do not replace application limits.

Applied: collection now has a shared admission bucket before character queries/profile settlement; unknown index reward IDs are rejected before response construction. Existing mutation/save buckets remain separate. Metatable rejection in settings/admin schemas is internal defense in depth: Roblox does not transport Lua metatables. Cyclic/nested input is tested directly in the harness, beyond ordinary wire serialization.

Sources:
- https://create.roblox.com/docs/scripting/security/client-server-boundary
- https://create.roblox.com/docs/scripting/events/remote
- https://luau.org/library/
