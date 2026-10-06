# Admin runtime and tooling

Checked 2026-10-06.

- [LinearVelocity](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity): attachment-based velocity constraint for local flight, with world-relative velocity and finite configured speed. No deprecated BodyVelocity. The server authorizes short-lived enable/renew commands; this is an owner convenience, not a general anti-cheat solution for network-owned avatars.
- [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid): movement tests explicitly set JumpPower mode and preserve WalkSpeed, JumpPower and UseJumpPower for restoration. God mode uses a ForceField and health refill; destroying the character or immediately setting health to zero can still kill it.
- [Stats](https://create.roblox.com/docs/reference/engine/classes/Stats): `GetTotalMemoryUsageMb` reports server memory. Heartbeat delta measures elapsed interval, not script CPU time. Instance/part counts are on-demand Workspace snapshots, not whole-server instance totals or performance guarantees.
- [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting): ClockTime/Brightness previews run on the authorized client and restore their original values. They do not change every player's lighting.
- [Rojo project format](https://rojo.space/docs/v7/project-format/): explicitly map `src/admin-client` under ServerStorage, outside StarterPlayer and ReplicatedStorage. The private delivery path is checked with actual runtime code in the audit harness.
- [Instance.WaitForChild](https://create.roblox.com/docs/reference/engine/classes/Instance#WaitForChild): descendants can replicate after their parent. The private bootstrap waits for all three admin modules before constructing the window; receiving the folder alone is not a readiness guarantee. Rechecked alongside the official client/server boundary, Player, GroupService, ServerStorage and PlayerGui references during interruption recovery.
- [StyLua](https://github.com/JohnnyMorganz/StyLua) and [Selene Roblox setup](https://kampfkarren.github.io/selene/roblox.html): this checkout uses Windows line endings; format changed sources and check the full tree. Selene was attempted but the installed tool cannot find the configured Roblox standard library; do not describe that as a lint pass.

Headless harnesses exercise actual Luau modules with engine doubles. Raster UI review uses the existing approximate renderer. Native replication, physics, touch input, group/backend freshness and performance still require an isolated published/Studio multi-client test.

Recovery validation on 2026-10-06 found no connected Studio instances. A guarded profile replacement is now distinguished from an expired data session when maintaining temporary movement/test-pass leases: a pending save preserves effects only while both leases remain valid. Held-save and data-lease-expiry regression cases cover that distinction.
