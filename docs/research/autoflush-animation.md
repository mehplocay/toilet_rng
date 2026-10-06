# Auto-flush animation and streaming (2026-10-06)

- Root cause: `FlushPresentation.Publish` treated compact owner reveals as a reason to skip the replicated world animation. Compact UI and world animation must be independent.
- Creator Hub: `PersistentPerPlayer` retains the model for players added by `AddPersistentPlayer`; other clients get atomic streaming. Set it server-side. Persist only the assigned toilet (including its burst), not the plot or map. The HUD remains useful before streaming completes.
  https://create.roblox.com/docs/reference/engine/classes/Model
  https://create.roblox.com/docs/workspace/streaming
- Platform announcements describe atomic arrival and persistence; adding new descendants is not atomic. A late viewer may miss an emitted burst but sees replicated movement and subsequent cycles. No client animation replay loop is needed.
  https://devforum.roblox.com/t/new-improvements-to-streaming-enabled/2185535/1
  https://devforum.roblox.com/t/upgrades-to-model-streaming/2699921
- A 2025 Opportunistic streaming bug report has a Roblox staff reply saying a fix was queued for the next release; this is not proof of current engine behavior. Keep the distance-independent HUD fallback and verify actual streaming in Studio separately.
  https://devforum.roblox.com/t/opportunistic-streamoutbehavior-bugged-with-streaming-behavior-mode-persistentperplayer-models/3659000/4
- `TweenBase.Cancel` fires completion and does not reset animated properties. Disconnect completion before cancellation and explicitly restore the toilet pivot. Release connections, tweens, value objects and emitters together; repeated cleanup is inert.
  https://create.roblox.com/docs/reference/engine/classes/TweenBase
- `ParticleEmitter.Emit` is a bounded burst; `Clear` removes live particles. Retain the existing 24-particle budget and cooldown-derived duration. Automatic cycles add no spatial sound; manual spatial sound has explicit low volume and rolloff bounds.
  https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
  https://create.roblox.com/docs/reference/engine/classes/Sound
- Tool reference checked: StyLua supports Luau formatting and `--check`. Rojo command documentation was requested but unavailable through the browser; use installed CLI help and the existing build command.
  https://github.com/JohnnyMorganz/StyLua
  https://rojo.space/docs/v7/commands/

Headless checks cover service scheduling/stop paths, production world animation with engine doubles, persistence registration and HUD expiry/deduplication. They do not simulate Roblox network/streaming or mobile rendering.

Validation: 22 standalone `scripts/check-*.luau` passed; the two bundled checks ran through their PowerShell runners. Audit: 258 passed. Visuals and all six world modes passed. `rojo build -o build.rbxl`, `stylua --check --line-endings Windows src scripts`, and `git diff --check` passed. `check-ui.ps1` passed its core UI runtime checks then stopped at the unchanged `scripts/ui-rebirth.luau:46` coin-label assertion. Selene could not load its configured `roblox` standard library (same environment limitation recorded in `audit2-tools.md`).

Scope assumption: retain the existing whole-toilet wobble and bounded burst rather than introduce a new water/lid rig. Quick reveals still receive this short automatic world animation. Owner persistence lasts for the assigned toilet's lifetime, including upgrades/replacement; removal destroys the model and its effects. A late stream-in can miss the current one-shot burst; the next successful cycle runs normally and the HUD remains available independently.
