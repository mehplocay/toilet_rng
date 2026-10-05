# Audit 2: persistence and session ownership

Checked 2026-10-05.

- [Player data and purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing): atomic whole-profile updates, session ownership, ordered requests and retries are application responsibilities. Durable receipt deduplication must accompany the granted benefit.
- [Roblox staff implementation article](https://devforum.roblox.com/t/implementing-player-data-and-purchasing-systems/2839941): session locking prevents separate servers from concurrently treating a profile as writable; expiry handles dead sessions. This is not a promise that every shutdown save succeeds.
- [Data stores](https://create.roblox.com/docs/cloud-services/data-stores): Studio API access can reach the experience's real stores. Use isolated test data.

Retained the existing per-player GUID token, 180-second lease, atomic snapshot and callback ownership checks. Tests exercise ambiguous commits, callback replay, expiry, concurrent departure, takeover and rebirth replacement. Studio now uses `ToiletRNG_Studio_v1`; production remains `ToiletRNG_v1`. No production migration or data reset occurs. Crash loss since the last successful snapshot and a permanently stalled backend remain explicit limitations.
