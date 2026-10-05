# Visual overhaul

The hub uses lavender checkerboard paving, radial plot paths, a gold crowned King Poop trophy/fountain, toy trees, flowers, bushes, benches, lamps, fences and cloud puffs. A cyan pad marks spawn. Ten fenced lawns have wood-framed name boards, central paths, greenery and navy display stands with rarity rings.

Seven toilet tiers share detailed bowl, open seat, lid, tank, base and flush handle geometry. Their materials are white plastic, stained cream plastic, gold metal, blue glass/ice, green Neon, black plastic/red Neon, and purple Neon. Diamond sparkles, reactor bubbles, Demon embers and Galaxy orbiting stars distinguish the later tiers. All eleven drops have recognizable geometry, eyes where appropriate, and rarity rings; Legendary+ add particles.

The UI uses FredokaOne, navy panels, rounded borders/shadows, gradient buttons, shape icons, a coin badge, shared model previews and a custom keyboard/gamepad/touch FLUSH prompt. Native server prompt triggering and request validation remain intact. Sound hooks still ignore empty IDs.

## Files

- `src/server/World/Builders/`: hub, plot, scenery and lighting builders.
- `src/shared/Visuals/`: reusable primitives, toilet and item builders for world/viewport previews.
- `src/shared/Config/Visuals.luau`, `World.luau`, `Assets.luau`: palette, materials, budgets, lighting and engine-bundled sparkle texture.
- `src/server/World/Models.luau`, `WorldService.luau`: model adapters, display integration, existing flush animation and budget checks.
- `src/client/UI/`: polished components/cards, viewport previews and FLUSH prompt.
- `src/client/VisualIdle.luau`, `Effects.luau`, `init.client.luau`: distance-limited idle tweens/effects and HUD. Rare-drop UI pulses replace the persistent render-step camera callback.
- `default.project.json`: Soft lighting with prioritized quality, the current equivalent of ShadowMap.
- `docs/research/visuals.md`: current Creator Docs/DevForum references and implementation decisions.
- `scripts/check-visuals.ps1`: headless construction/budget verification against the actual builder sources.

## Performance and assumptions

Hub: 840 parts. Worst headless plot including five populated stands and one transient drop: 332 parts. Parts are anchored; decoration has collision/touch/query disabled. Small local lights do not cast shadows. Nearby clients enable low-rate, short-lived particle effects and tween water/bubbles/stars/lights; no server idle animation loop or permanent per-frame client callback. The headless mock verifies construction, flags and counts, not engine API behavior, geometry placement, rendering or physics.

Built-in block/ball/cylinder Parts and WedgeParts are assumed permitted because the task also explicitly requests them. No MeshParts, SpecialMesh, runtime unions, marketplace models or external asset IDs are used. The sole texture path is Roblox's documented engine-bundled sparkle sprite. DepthOfField is deliberately omitted to keep the playable scene sharp on mobile.

Saved capacities above five paginate physical stands every ten seconds to honor the part budget; the normal three slots are always visible. Collection ownership, reservations, display IDs and remotes are unchanged.

## Verification

Run `rojo build -o build.rbxl`, both `scripts/check-*.luau`, and `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-visuals.ps1`. StyLua was applied and checked; original CRLF endings were restored on unchanged files to keep the diff limited to this task. A per-file StyLua check with the corresponding `--line-endings Windows`/`Unix` option passes on all sources. All 39 Luau files also compile through `luau-compile`. The existing one-million-roll simulation retains guaranteed Poop fallback and no empty drops. Selene is installed but cannot run with the repository's missing `roblox` standard library.

No Studio instance was connected during this task. Before release, verify the hub/plot camera composition, lowest/highest graphics quality, blue atmosphere and Neon/Glass appearance, keyboard/gamepad/touch prompt activation, flushing while idle tweens run, repeated tier changes/displays/player departures, and mobile frame time with ten occupied plots. Persistence and live multiplayer need their existing Studio checks as well. Nothing is committed or pushed.
