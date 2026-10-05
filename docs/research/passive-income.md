# Passive display income research

Checked 2026-10-05 before implementation. No secrets or profile data sent to research tools.

- Server `os.time()` supplies a Unix timestamp that survives server restarts. `os.clock()` has no defined epoch and remains appropriate for the existing in-session rate limiter. Persist only server timestamps; keep a high-water mark across backward clock adjustments.
  https://luau.org/library/#os-library
  https://create.roblox.com/docs/reference/engine/libraries/os
- `GetServerTimeNow()` provides smoothed, monotonic approximate server time for synchronized presentation. The reference explicitly cautions against client timed rewards. Income uses server `os.time()` exclusively; clients receive already-calculated pending integers.
  https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow
  https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/Workspace.yaml
- DataStore best practices recommend one object per player for related data and atomic updates. `UpdateAsync` yields, can repeat its transform, and forbids yielding inside it. Compute offline accrual on the sanitized record inside lease acquisition; save wallet, pending amounts and timestamp together. Preserve the audit's unique session tokens and immutable save snapshots.
  https://create.roblox.com/docs/cloud-services/data-stores/best-practices
  https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore#UpdateAsync
- Roblox staff explains why a new session may overlap the previous session's final save and why locks must be acquired atomically. The indexed staff excerpt was available; the full DevForum page was blocked. No community workaround replaces ownership checks.
  https://devforum.roblox.com/t/implementing-player-data-and-purchasing-systems/2839941
- Prompt properties can be manipulated by clients. The collect remote accepts no payload and independently validates the assigned plot, living character, finite distance, rate limit and active lease. Native prompt input is only a request; it supplies no amount, timestamp, slot or player identity.
  https://create.roblox.com/docs/scripting/security/client-server-boundary
  https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
- Platform/tool check: Creator Updates and release notes 727 were checked; no newly introduced API behavior is required. Retain the existing Rojo, StyLua and Luau workflow. Windows checkout uses CRLF, so whole-tree format verification passes with `--line-endings Windows` without rewriting unrelated files. Selene's configured Roblox standard library remains missing locally.
  https://create.roblox.com/updates
  https://create.roblox.com/docs/release-notes/release-notes-727
  https://rojo.space/docs/v7/getting-started/new-game/
  https://github.com/JohnnyMorganz/StyLua
