# Audit 2: streaming and visual lifetime

Checked 2026-10-05.

- [Instance streaming](https://create.roblox.com/docs/workspace/streaming): stream-out reparents replicas to nil; removal signals fire, but this is not `Destroy()`. Persistent models stay resident; atomic models stream together. Streaming applies to Workspace, not the ReplicatedStorage template library.
- [Roblox StreamOutBehavior announcement](https://devforum.roblox.com/t/stream-out-behavior-new-property-for-streaming-enabled/1439473): Opportunistic permits distant regions to leave without waiting for memory pressure. The promised future default is not a reason to assume a particular rollout; the project now selects it explicitly.
- [Performance guidance](https://create.roblox.com/docs/performance-optimization/improve): memory, rendering and replication must be profiled on target devices; reducing persistent content helps streaming.
- [TweenBase official source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/TweenBase.yaml): Completed fires after completion and cancellation, but not Pause. Cleanup must not clear a newer replacement tween when an older callback runs.

Added removal cleanup to VisualIdle, explicit completion cleanup to the shared UI tween registry, distance culling before billboard projection, and removed redundant descendant counting from ordinary State refresh. Kept streaming radii 128/512 and the 25 small skyline models persistent to preserve composition. Counted geometry/effects/UI with the existing harnesses; these counts and the CLI benchmark are not engine FPS, draw-call or device-memory measurements.
