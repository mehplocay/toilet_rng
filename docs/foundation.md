# Foundation

No UI or world geometry is included. `src/server/init.server.luau` creates the
configured RemoteEvents, starts profile persistence and connects services.

## Remote contract

All names and token-bucket limits are in `src/shared/Config/Remotes.luau`.
Client requests: `Flush()`; `Sell(itemId, integerCount)`; `BuyToilet(toiletId)`.
Purchases must be the next tier and use its server-configured full price.
`Result(action, payload)` returns the accepted flush or the sell/purchase outcome.
Malformed, throttled, cooling-down or not-yet-loaded requests are ignored.
All mutations run without yielding; the client never supplies RNG, value or luck.

## Probability and tuning assumptions

The GDD probabilities sum to 0.6827511. Remaining mass means no drop, rather
than changing the advertised 1/X probabilities. Pools are cumulative; Basic
unlocks through Fish, then each upgrade unlocks the next item, with Galaxy
unlocking both Secret items. Luck multiplies non-Common weights. If total
weight exceeds one, all weights are normalized. The simulation defaults to
Galaxy's full pool with luck 1 to compare directly against the GDD.

Upgrade cooldowns and luck values are provisional. King Poop is Mythic as in
the mockup. Default display slots are 3. Collection is a lifetime discovery
counter, separate from sellable inventory. Event flags are metadata only;
server-event effects belong to the later events task. Asset/product maps are
empty placeholders with no invented IDs.

## Persistence

DataStore `ToiletRNG_v1`, keys `Player_<UserId>`, stores `{ Data, Lock }`.
UpdateAsync acquires a session lease for 180 seconds. Autosave every 60 seconds
refreshes it; leave/shutdown saves release it. Four attempts use exponential
backoff. Load/save failure stops gameplay rather than substituting fresh data.
Shutdown waits at most 25 seconds. This is a light lease, not a guarantee against
platform outages; enable Studio API access in a published test place to test
DataStore integration and multi-server lease contention.

## Validation

Run `rojo build -o build.rbxl`, `stylua --check src scripts`,
`luau scripts/check-foundation.luau`, and `luau scripts/simulate.luau`.
The simulation prints one million measured rolls, target probabilities and
expected counts. Ultra-rare items require many more rolls for meaningful
statistical comparisons. Selene is configured for Roblox; this environment's
Selene binary lacks its Roblox standard library, so lint cannot currently run.
Live Roblox RemoteEvent/DataStore behavior remains a Studio integration check.
