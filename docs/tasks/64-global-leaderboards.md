# Task 64: Cross-server (global) leaderboards

Problem (owner): on the hub leaderboards you only see players currently in the same server. Other players' flushes (and offline players) never appear. Boards: Coins, Rarest, Flushes (see World:RefreshLeaderboards in src/server/World/WorldService.luau, src/shared/LeaderboardStats.luau, Hub builder in src/server/World/Builders/Hub.luau).

Build real global leaderboards:
- Use Roblox OrderedDataStores (check current official docs, Roblox "ordered data stores" and GetSortedAsync limits; research mandatory, write findings with URLs to docs/research/global-leaderboards.md). One ordered store per board (Flushes, Coins, Rarest) with the player's UserId as key.
- Server writes only server-authoritative values (never client values). Reuse the existing sanitize/rank rules (LeaderboardStats): admin-touched profiles stay excluded from rankings as today.
- Throttle writes: update a player's scores at most about once per 60-120 seconds while they play (only when changed) plus once on leave/shutdown, respecting DataStore budgets (use pcall, retry with backoff, never block the player's own save).
- Read top N (the number of rows the board shows, currently Layout.Boards) with GetSortedAsync about every 60-120 seconds in a background loop, cache the result, and render it on the hub boards; keep the existing local ranking as fallback when the DataStore API is unavailable (e.g. Studio without API access, errors/throttling). Merge the current server's live players over the cached global list so own progress shows immediately.
- Display names: resolve UserId -> name/display name with a cached, pcall'd lookup (Players:GetNameFromUserIdAsync or UserService), no per-refresh spam.
- Integer constraint: ordered stores hold integers only. Coins and Rarest can be huge or fractional (rarest is a "1 in N" chance, coins may exceed 2^63; there are no design caps). Design a monotonic order-preserving integer encoding (e.g. floor(log-scaled value * 1e6)) and keep the exact value in a separate regular DataStore entry or profile if the board must show it; document the choice. No design caps on the game values themselves; only this storage encoding must stay finite and safe.
- Studio/test safety: do not write in Studio unless API access is on; test with injected fakes (add Luau tests in scripts/ and wire into check-audit: encoding order, throttling, fallback, admin exclusion, huge values, retry).
- Security: no new remotes needed; if you add any, validate and rate-limit.

Follow AGENTS.md; branch feature/global-leaderboards, do not push (Git may be sandbox-blocked; leave uncommitted and say so). Run check-audit, check-ui, check-visuals, check-world and rojo build -o build.rbxl. Report what you built and what the owner must enable (e.g. Studio API access / published place).
