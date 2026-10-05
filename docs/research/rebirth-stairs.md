# Rebirth stairs runtime (2026-10-05)

- Official Material enum still includes Neon and SmoothPlastic: https://create.roblox.com/docs/reference/engine/enums/Material . Reuse the ten existing terrace/trim meshes, with static Neon for unlocked and next milestones; no extra lights, particles, tweens or animation workers.
- BillboardGui exposes MaxDistance and LightInfluence: https://create.roblox.com/docs/reference/engine/classes/BillboardGui . Keep the authored 35-stud cutoff and occlusion; labels live in the replicated world so visitors see the same state.
- Integration uses the existing server `sync -> World:Refresh` call after profile readiness and acknowledged RebirthService saves. Cache owner/level to avoid repeated stairs property writes on unrelated syncs. Release restores locked scenery.
- Five terraces show a rolling window of the fifteen configured milestones, always including the next level; at cap all five are unlocked. Requirements come from Config/Rebirth and Config/Toilets. Colors reuse Config/Rarities (Uncommon through Godly, avoiding unreadable Secret black).

Engine visual legibility and phone performance still require Studio/device testing; the headless world checks enforce unchanged geometry/instance budgets.
