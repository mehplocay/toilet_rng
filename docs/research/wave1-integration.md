# Wave 1 runtime integration research

2026-10-06. Checked current official sources before extending the existing paths.

- [Model API](https://create.roblox.com/docs/reference/engine/classes/Model) and [pivot tools](https://create.roblox.com/docs/studio/pivot-tools): a PrimaryPart supplies a model's pivot. Keep the imported foot datum through PivotOffset; normalize once, then clone and use ScaleTo/PivotTo. Wave 1 follows the existing loader and never writes protected mesh IDs.
- [MeshPart API](https://create.roblox.com/docs/reference/engine/classes/MeshPart): reuse the supplied serialized mesh/texture references. The binary check verifies content, hierarchy, dimensions and orientation; successful normalization does not prove published-client asset permissions or download success.
- [ViewportFrame](https://create.roblox.com/docs/reference/engine/classes/ViewportFrame): a dedicated Camera renders local 3D children. New blank icon slots use static, effect-free template previews with a bounds-based camera; no emoji/vector icon substitutes or animation loop.
- [ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter): Rate controls continuous emission. New toilets use one emitter at 3/s and one shadowless light, under the existing distance/Reduced/Off lifecycle; bursts retain the 24-particle budget.
- [Official performance guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md): dense objects and effect property changes have costs. Headless counts are budgets, not measured phone performance.
- [Roblox updates/release notes index](https://devforum.roblox.com/c/updates/45/l/latest?page=3): reviewed current notices including mesh streaming/LoD changes. No new opt-in streaming or importer behavior is assumed. Rebuild and inspect the serialized models; keep existing streaming settings.
- [Rojo sync details](https://rojo.space/docs/v7/sync-details/): map the supplied binary root via `$path`; build the full place to verify mesh content. No runtime asset insertion/upload API is required.
- [Luau standard library](https://luau.org/library/) and [StyLua](https://github.com/JohnnyMorganz/StyLua): use explicit deterministic table-sort ties and the installed formatter/CLI. Proofs execute production Luau configs and pure economy rules, not a separately normalized weighted distribution.

Design inference: the historical Wave 1 proof's uncapped toilet income cannot establish current pacing because the merged free cash cap includes the toilet factor. The replacement proof uses IncomeAccrual and UpgradeRules and reports this difference explicitly.
