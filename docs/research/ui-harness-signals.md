# Roblox UI harness service signals

The UI harness doubles both `RunService.Heartbeat` and `RunService.RenderStepped`, and exposes `UserInputService.InputBegan`, `InputChanged`, and `InputEnded` for client UI/presentation modules.

Sources checked 2026-10-05:
- https://create.roblox.com/docs/reference/engine/classes/RunService
- https://create.roblox.com/docs/reference/engine/classes/UserInputService
