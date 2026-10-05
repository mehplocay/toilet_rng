# Roblox map quality: evidence and decisions

Research date: **2026-10-05**. Scope: RNG, collection, farming, idle and tower hubs; construction, visual composition and delivery. Companion: [Toilet RNG redesign](../design/map-redesign.md). This is research and a design proposal, not an implemented map or a Studio performance report.

## 1. Evidence rules and limits

- **Verified — primary:** a statement actually available in official documentation, an official game update, an author's breakdown or a tool repository. Documentation establishes supported techniques; it does not establish that a named game uses them.
- **Reported — secondary:** a wiki or hands-on article reports a layout. This verifies the report, not the current live place or its private production pipeline.
- **Observed — local:** directly visible in the supplied reference images or recorded in this repository. The quality reference's game title is unconfirmed.
- **Inference:** our interpretation or recommended transfer to Toilet RNG. **Proposal:** our own dimensions, budgets and settings; these are not competitor measurements.

The two supplied images were opened and inspected. External image searches supplied image descriptions, but no external screenshot was directly inspected: the browser inventory was empty and direct image download failed. Fandom pages often returned HTTP 402 on opening; their facts below come from search-indexed excerpts. Several DevForum pages blocked direct retrieval; those entries explicitly say indexed. Video titles/descriptions were available, but playback and transcripts were not. Do not treat these as watched videos, pixel measurements or live-server audits.

**No credible public source located here discloses scene-wide part counts, triangle budgets, stud dimensions, exact lighting settings or the complete Terrain/mesh/part split of the named genre leaders.** Those fields remain unknown. A screenshot cannot distinguish Terrain grass from a textured mesh, or prove Blender, a purchased kit, streaming settings or team size.

## 2. What genre leaders actually demonstrate

| Example | Evidence and concrete finding | Construction/count evidence | Transfer — inference |
| --- | --- | --- | --- |
| Sol's RNG | **Reported, indexed wiki:** its map includes an obby, mountain destinations and Stella's cave; biomes alter the surroundings, including weather and landscape effects. [Map](https://sol-rng.fandom.com/wiki/Map), [NPC routes](https://sol-rng.fandom.com/wiki/NPC), [Biomes](https://sol-rng.fandom.com/wiki/Biomes). | Terrain/meshes, dimensions, instances and triangles: unknown. Wiki-era details may change. | Give an otherwise repetitive action a recognizable world and optional destinations. A biome is a coherent environment treatment, not merely a recolored portal. |
| Grow a Garden | **Reported, indexed wiki:** the current page describes four garden plots, formerly six, shops on the sides and a central event hub. Its community map contains a historical Zen-event view. [Map](https://growagarden.fandom.com/wiki/Map), [community map](https://growagarden.fandom.com/wiki/Map:Grow_A_Garden). | Four is the wiki's current report, not a verified live count. Do not reuse old six-plot claims. Materials and budgets: unknown. | Put productive personal space beside communal services; reserve one readable event space. |
| Grow a Garden production | **Verified, creator interview:** Jandel discusses simple farming, offline progress and frequent updates. The interview does not disclose its actual map asset pipeline. [GamesBeat interview, September 2025](https://gamesbeat.com/janzen-madsen-interview/). | Blender usage, map team size and geometry budget: not established by this interview. | Build swappable event scenery rather than a unique monolithic map for every update. This is our workflow recommendation. |
| Steal a Brainrot | **Reported:** a September 2025 hands-on article describes eight bases around a square with a runway through it. The base wiki describes collection storage, added floors and base skins; its maximum-floor statements are inconsistent. [Historical hands-on account](https://www.pcgamer.com/games/sim/one-of-robloxs-biggest-experiences-right-now-is-a-bizarre-italian-brainrot-character-stealing-simulator-and-lord-help-me-i-now-understand-why-its-so-popular/), [Base wiki, indexed](https://stealabrainrot.fandom.com/wiki/Base). | Eight is historical, not a promised current server capacity. No verified stud sizes or part counts. | Repeated open-front architecture makes other players' collections readable. Preserve sightlines and unmistakable ownership. |
| Fisch | **Reported:** Moosewood is described with docks, an uphill village route, merchant buildings, a pond and an elevated lighthouse. The page warns of outdated information. [Moosewood](https://fisch.wiki/wiki/moosewood/). | Qualitative geography only; no construction pipeline or reliable current world total established. | Use coast, height changes and a skyline landmark to make navigation memorable. Keep functional paths flatter than scenic edges. |
| Pet Simulator 99 | **Verified, official:** Update 1 adds named areas with distinct village/garden/castle themes, assigns services to specific areas, and introduces pictorial area icons. This is a dated 2023 update, not a current area count. [BIG Games Update 1](https://www.biggames.io/post/pet-simulator-99-update-1). | Official images show the delivered game, but no mesh/part budget or production tool disclosure was found. | Give each destination a silhouette and consistent theme; icons reinforce names instead of making text signs do all the work. |
| Pet Simulator 99 visual references | **Image-index descriptions only:** the Nightmare map image is described with rectilinear play areas, cyan structures, bamboo and a purple horizon; Good vs Evil imagery with white arches, pastel foliage, waterfalls and a fountain. [Nightmare update](https://www.biggames.io/post/pet-simulator-99-update-8), [Good vs Evil update](https://www.biggames.io/post/pet-simulator-99-update-17). | Not a direct visual audit; do not infer technical construction from these descriptions. | Candidate references for framed arenas and a themed perimeter. Confirm visually in the next art review before copying a treatment. |
| Tower Defense Simulator | **Reported, official wiki:** its Indoor 2026 lobby entry lists six main areas, an elevated spawn, a lower crate shop, mode-specific decoration and signs, and windows framing the exterior. [Main Lobby](https://tds.wiki/w/Main_Lobby). | A wiki description of a versioned lobby, not measured geometry or current engine settings. | Different functions can share one lobby while having distinct entrances, elevations and visual cues. |
| Supplied roll/tower reference | **Observed:** dark marked paths contrast with bright grass; open display bases have pink floors and dark structural trim. Large foreground palms overlap the view; smaller palms, turquoise water, hazy blue mountains and clouds form successive layers. A large TOWERS sign anchors a destination. [Local image](../reference/quality-reference-1.webp). | Game identity and construction method unknown. Camera view is not a stud ruler. | Borrow scale hierarchy, framed bases and depth. Do not copy its UI or assume its exact palette is right for toilets. |
| Toilet RNG mockup | **Observed:** a central avenue, side plots and an oversized crowned gold toilet establish the theme; plot frames, ownership signs and visible collections make the loop legible. [Local mockup](../reference/mockups.png). | Concept imagery is a design target, not evidence of a working Roblox render. | Build this hierarchy first; props should support it. |

**Inference:** there is no evidence here for a universal “top games use imported meshes only” rule. Common visible outcomes are readable repeated player spaces, a dominant destination and deliberately bounded backgrounds. The medium should serve those outcomes.

## 3. Terrain, parts, imported meshes and modular kits

**Verified — primary:** Roblox's environmental-art curriculum starts with style references and blockout, then builds a coordinated reusable kit. It recommends consistent modular dimensions and pivots; trims and tileable treatments reduce unique asset work. The modular-environment tutorial demonstrates assembly from a kit, rather than treating an entire map as one mesh. [Develop polished assets](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets), [Assemble modular environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments).

**Verified — primary:** Terrain tools support sculpted land and water. Meshes can be authored in external tools such as Blender or Maya and imported. These are complementary building systems, not mutually exclusive map categories. [Terrain curriculum](https://create.roblox.com/docs/tutorials/curriculums/core/building/create-an-environment-with-terrain), [Meshes](https://create.roblox.com/docs/parts/meshes).

**Verified — primary:** the asset-library tutorial separates mesh components during import and demonstrates reusable materials, packages, anchoring and collision configuration. [Assemble an asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library).

**Verified — primary:** current import specifications permit up to **20,000 triangles per mesh**. That is an import limit, not a recommendation to spend 20,000 triangles on every palm and not a scene-wide mobile allowance. [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications).

**Inference / recommendation:** use Terrain for the island mass, sand and sea; simple parts or a small mesh kit for precise walkways and collision; imported meshes for the hero toilet, architectural trim, palms and distinctive silhouette props. Build a clean paved district above the Terrain rather than asking 4-stud voxels to produce sharp pavilion floors. Replace a few expensive repeated pieces, not all 31 useful existing templates.

## 4. Art direction, depth and prop density

**Verified — artist breakdown:** ebur1n's Roblox article demonstrates blockout-to-final environment work, restricted color treatments, forced perspective and atmosphere. It specifically identifies XAXA's Brushtool as part of foliage placement for Bad Business. This is actual attributed production evidence for that game, not evidence that Sol's RNG or Fisch uses the plugin. [Creating immersive environments, 2021](https://medium.com/roblox-developer/creating-immersive-environments-2506729f62bb).

**Reported — indexed creator tutorial:** the DevForum scene-building tutorial discusses player viewpoint, arrangement and varied scale/angles/colors when reusing nature props. It is historical composition advice, not current engine guidance. [Map design and scene building, 2020](https://devforum.roblox.com/t/map-design-and-scene-building-fantasy-medieval-and-nature-maps/709866/1).

**Verified — artist breakdown, different engine:** Angelo Ciervo describes blockout, Blender modular assets, painted tree gradients and foreground/middle/background organization for a painterly Unreal scene. Contrast is concentrated around the focal building. [80 Level breakdown, August 2026](https://80.lv/articles/turning-2d-concept-art-into-a-detailed-painterly-3d-world). **Inference:** composition and gradient painting transfer; Unreal shader features and that scene's performance do not.

**Inference from the local references and these workflows:**

| Design issue | Better treatment for Toilet RNG | Measurable review |
| --- | --- | --- |
| Everything equally colorful or equally tall | Navy paths, green ground, warm hero, limited pink/cyan accents; one dominant silhouette. | Grayscale thumbnail still identifies the crowned toilet and the avenue. |
| Props scattered uniformly | Cluster foliage at corners, transitions and shoreline; leave interaction fronts open. | Every plot has a clear entrance and uninterrupted view of its five visible items. |
| Empty horizon or a continuous wall | Near shore details, middle-distance headlands, two lighter mountain layers and sky. | Three landscape depth bands remain distinguishable at low graphics. |
| Identical mirrored garden props | Reuse a kit with bounded size/yaw variation and two garden cluster variants. | A repeated pavilion reads as intentional architecture; its landscaping does not look stamped. |
| Flat ground carries all the interest | Raise scenic banks and lower the shore; keep walking floors predictable. | Path gradients stay shallow; silhouettes change at the coast. |
| Signs compete with scenery | One hero banner, smaller service signs, owner signs on each pavilion. | Spawn view has one first-read landmark and two second-read services. |

These are proposed art-review criteria, not verified competitor rules or published density formulas.

## 5. Textures, materials and mesh reuse

**Verified — primary:** MeshParts support texture content; SurfaceAppearance supplies color, normal, roughness and metalness maps, while MaterialVariant supports reusable material treatments. The mesh documentation explains the precedence of SurfaceAppearance texture maps. [Meshes](https://create.roblox.com/docs/parts/meshes), [asset-library material workflow](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library).

**Reported — indexed builder tutorial:** the historical low-poly tutorial describes palette-based UV coloring. It does not prove that a low-poly mesh always renders faster than parts. [Low-poly basics](https://devforum.roblox.com/t/low-polying-tutorial-for-beginners-low-poly-basics/235354/).

**Verified — primary:** Roblox can instance repeated meshes that share mesh content and compatible texture/SurfaceAppearance content. Reimporting repeated geometry as separate assets can lose that benefit; excessive draw calls, density and transparent overdraw can matter more than a raw triangle total. [Performance optimization](https://create.roblox.com/docs/performance-optimization/improve).

**Inference / proposal:** retain the current shared uploaded templates. Use one coordinated 512-pixel palette/gradient atlas for new toy props and a small 512–1024-pixel trim atlas for architecture. Reserve PBR treatment for the hero gold/ceramic and perhaps water-adjacent trim, after checking delivery cost. Avoid unique 2K–4K textures on each shrub. Painted gradients can add form without heavy normal maps. Do not silently add SurfaceAppearance descendants to templates: the current loader has a restricted one-MeshPart contract; any extension requires explicit validation. [Repository contract](../world-models.md).

## 6. Lighting, atmosphere, sky and motion

**Verified — current engine documentation:** LightingStyle now expresses Soft or Realistic intent. The lighting guide says ShadowSoftness is valid with Realistic; it is not a reliable tuning lever for a Soft setup. PrioritizeLightingQuality controls the quality-versus-view-distance tradeoff as graphics quality drops. Older Technology-based recipes need translation. [Global lighting](https://create.roblox.com/docs/environment/lighting), [Lighting API](https://create.roblox.com/docs/reference/engine/classes/Lighting). **Reported, indexed release discussion:** Unified Lighting was fully released in July 2025. [Release thread](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-is-fully-live/3401512/368).

**Verified — primary:** Atmosphere changes scattering and distance obscuration; Glare depends on Haze, and Decay interacts with Haze/Glare. Density and Offset are not a direct pair of fog distances in studs. [Atmosphere guide](https://create.roblox.com/docs/environment/atmosphere).

**Verified — primary:** Bloom responds to bright pixels; ColorCorrection changes the image's color treatment; SunRays depend on occlusion. Their appearance varies with quality settings. [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects). **Inference:** restrained values preserve colorful objects and legible labels better than making every Neon strip bloom.

**Verified — primary:** Sky exposes sun/moon size, stars and skybox faces. Dynamic Clouds render under Terrain and respond to global wind; lighting and atmosphere affect their appearance. [Sky API](https://create.roblox.com/docs/reference/engine/classes/Sky), [Clouds](https://create.roblox.com/docs/environment/clouds). Terrain exposes water color, transparency, reflectance and waves. [Terrain API](https://create.roblox.com/docs/reference/engine/classes/Terrain). **Proposal:** begin with the built-in sky, not invented skybox IDs; compose the recognizable horizon with actual low-cost silhouettes.

**Verified — primary:** Neon appearance is separate from local illumination; Roblox has PointLight, SpotLight and SurfaceLight for emitted lighting. [Light sources](https://create.roblox.com/docs/effects/light-sources). **Proposal:** glow trims can work without a light on every segment.

**Verified — primary:** particle cost includes screen footprint and overlapping transparency. The documented per-emitter ceiling is 400 particles/second, or 100 on mobile; neither is a sensible target for ambient garden particles. [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters).

**Verified — tool source:** WindShake has distance and refresh-rate controls and an MIT license. Its published desktop demonstration is not a mobile capacity guarantee. [WindShake source](https://github.com/boatbomber/WindShake), [author's indexed implementation discussion](https://devforum.roblox.com/t/wind-shake-high-performance-wind-effect-for-leaves-and-foliage/1039806/31). **Inference:** animate a small leaf subset locally; do not move every tree Model or assume GlobalWind animates arbitrary MeshParts.

## 7. Mobile performance, streaming and 2026 platform changes

**Verified — primary:** Automatic RenderFidelity allows distance-dependent mesh detail. The enum also offers Precise and Performance; asset silhouette still needs visual testing. [Meshes](https://create.roblox.com/docs/parts/meshes), [RenderFidelity enum](https://create.roblox.com/docs/reference/engine/enums/RenderFidelity).

**Verified — primary:** Workspace streaming does not make ReplicatedStorage templates stream out. Streaming radii influence delivery, not guaranteed residency. Atomic models stream as units; persistent models should be exceptional. The guide documents Improved model behavior, Opportunistic stream-out and teleport prefetch. [Instance streaming](https://create.roblox.com/docs/workspace/streaming). **Inference:** marking the entire hub or all plots Atomic would defeat useful spatial granularity. Keep nearby services independently available and retain correct gameplay when distant decoration is absent.

**Verified — new primary documentation:** SLIM provides combined static-model representations. Its workflow requires a Roblox-saved place with Team Create and streaming enabled; animated/runtime-modified models are outside its supported static workflow. [SLIM](https://create.roblox.com/docs/workspace/streaming/slim). **Inference for this repo:** runtime-cloned templates cannot simply be declared a proven SLIM optimization. Test an authored static backdrop separately; keep a normal low-detail fallback.

**Reported, indexed release announcement:** April 2026 introduced opt-in mesh streaming and improved cloud LODs. [Announcement](https://devforum.roblox.com/t/introducing-mesh-streaming-and-improved-cloud-lods-in-published-experiences-opt-in-phase/4601232). **Verified — current API:** the property is spelled `Workspace.MeshStreamingAndImprovedLods`, has type `Enum.RolloutState`, and is Not Scriptable. The announcement uses different capitalization. [Workspace API](https://create.roblox.com/docs/reference/engine/classes/Workspace). Use the current API spelling, verify installed Studio/Rojo support, and test in a published private place before depending on it.

**Verified — primary:** Rojo's project format supports authored instance properties; its knowledge of property types depends on its API database, including recently added fields. [Rojo project format](https://rojo.space/docs/v7/project-format/). **Proposal:** preserve a known buildable project before adopting new engine flags; do not add protected runtime writes to the world loader.

**Inference / acceptance method:** measure loaded BaseParts, unique mesh/texture content, draw calls, rendered triangles, memory, CPU/GPU frame time, streaming stalls and particle overdraw separately. A serialized triangle count excludes generated Terrain, primitives, avatars and effects. A 2,000-part scene can still be slow if transparent layers or asset delivery dominate. Use actual low-end hardware plus Studio diagnostics; an emulator alone does not establish device performance.

## 8. Team workflow and useful tools

| Tool/workflow | Evidence | Recommended use and caveat |
| --- | --- | --- |
| Blender + Studio | **Verified video metadata:** RoBuilder advertises both tools for simulator-map building. No transcript or procedural steps were verified. [Building a Simulator Map, 2021](https://www.youtube.com/watch?v=lesDFRam2mk). Official Roblox tutorials document external mesh import and modular assembly. [Asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library). | Reference resource, not proof a whole polished map takes 30 minutes or that any named leader uses its exact workflow. Author a small kit, then assemble and review in-engine. |
| Blockbench | **Verified tool homepage:** free low-poly modeling and texture-editing tools with export support. [Blockbench](https://www.blockbench.net/). | Simple signs, bins and blocky props; Blender remains preferable for the existing pipeline. No evidence found of target games using Blockbench. |
| Brushtool 2.1, XAXA | **Reported listing/indexed author thread:** brushes clone/place models; the artist breakdown above attributes actual Bad Business use. [Creator Store](https://create.roblox.com/store/asset/2268520847/Brushtool-21), [author thread](https://devforum.roblox.com/t/brushtool-20-plugin-clone-and-place-models-onto-your-map-with-ease/255053). | Paint bounded foliage clusters, then export explicit placement transforms into our data-driven configuration. A historical incomplete-model report means smoke-test full templates before mass painting. [Indexed issue](https://devforum.roblox.com/t/solved-brushtool-21-not-duplicating-all-parts-of-model/1901643). No unverified fix claimed. |
| F3X Building Tools | **Verified repository:** provides move/resize/rotate, increments, selection and grouping tools. [Official repository](https://github.com/F3XTeam/RBX-Building-Tools). | Studio greybox convenience; no need to insert runtime building permissions into the game. |
| Archimedes, Scriptos | **Reported indexed listing/community usage:** repeated rotation helps curved assemblies. [Listing](https://create.roblox.com/store/asset/144938633/Archimedes-v319), [community example](https://devforum.roblox.com/t/how-do-i-make-a-part-curve/1642150). | Fountain rim and curved waterfront blockout; inspect the result and replace excessive segments with a designed mesh. Verify publisher/version before installation. |
| Packages and Team Create | **Verified primary:** packages support reusable asset updates; collaboration supports shared Studio work with permissions. [Packages](https://create.roblox.com/docs/projects/assets/packages), [Collaboration](https://create.roblox.com/docs/projects/collaboration). | One builder owns layout, one artist owns the kit, one developer integrates. Record an approved version and export at a deliberate handoff; do not let unreviewed package updates overwrite Rojo-controlled templates. |

**Proposal:** use a one-page kit sheet with palette, stud scale, pivot, front direction, collision proxy and triangle allowance. Approve one plot and one hub corner before producing ten copies. Studio mock placement is the visual reference; Luau configuration is the reproducible placement authority. Preserve the existing uniform normalization and toilet seat datum. [Current handoff](../world-models.md).

## 9. Free and licensed asset sources

No evidence found that the named leaders use the following packs. They are **available options**, not attributed production sources. Inspect rights, author and the exact asset version before importing; no purchases or installations occurred in this task.

| Source | Verified terms or capability | Appropriate use here |
| --- | --- | --- |
| Roblox Creator Store | Free and paid models, materials and plugins; model details expose geometry/script information and workflows permit disabling scripts. Availability does not prove a submitter owns all underlying rights. [Creator Store guide](https://create.roblox.com/docs/production/creator-store). | Blockout and evaluated props; inspect code and dependencies before integration. Avoid miscellaneous unrelated packs as the final art direction. |
| Roblox uploaded content | Open Use versus Restricted permissions affect access; permission must cover the experience. [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy). | Verify our actual mesh/texture delivery in the intended place. Existing IDs stay intact; new verified IDs follow the centralized configuration policy. |
| Kenney Nature Kit | The asset page lists 330 files and CC0. Kenney confirms commercial use without required attribution for its asset-page assets; branding is separate. [Nature Kit](https://kenney.nl/assets/nature-kit), [license explanation](https://kenney.nl/support). | Prototype shrubs/rocks and recolored background pieces. A coordinated subset, not an automatic replacement for the whole map. |
| Quaternius Ultimate Stylized Nature | The specified pack lists 63 models, multiple exchange formats and CC0. This does not establish the license of all other or PRO packs. [Exact pack](https://quaternius.com/packs/ultimatestylizednature.html). | Candidate stylized vegetation; validate scale, triangles, palette and alpha overdraw. |
| Poly Haven | Asset files are CC0; website content has separate conditions. [License](https://polyhaven.com/license). | Texture reference and selected materials. Photoreal scans need style adaptation; an HDRI is not automatically a Roblox six-face skybox. |
| ambientCG | Assets are distributed under CC0. [License](https://docs.ambientcg.com/license/). | Subtle tiling surface detail at restrained resolution; do not import an unnecessary full-resolution PBR set. |
| Poly Pizza | Licenses differ per item: the cited Shop 01 by sugamo is attribution-licensed. [Example asset](https://poly.pizza/m/5w9AIhTCLMS). | Check the exact entry; maintain required attribution. Do not label the entire site CC0. |
| Synty | Its current FAQ permits licensed assets in a developer-controlled Roblox game, with restrictions on redistribution/sublicensing; operating a platform is treated separately. [Current FAQ](https://syntystore.com/community/faq). | Optional paid kit only after checking the applicable purchase license and team access. Not a free source, and not a blanket permission to publish the raw pack. |

**Proposal:** store provenance as source URL, author, exact license/version, modifications, texture/mesh dimensions and triangle count for each adopted asset. Build distinctive toilet-themed architecture ourselves; generic nature can remain a supporting layer.

## 10. Critical audit of our current approach

**Verified — repository, not a live render:** [world-model handoff](../world-models.md) reports 31 imported one-MeshPart templates, a 627-BasePart / 225,340-mesh-triangle hub, and a largest populated plot of 184 BaseParts / 57,536 mesh triangles before transient drops. RenderFidelity Automatic is authored; mesh CollisionFidelity Box is still unverified, while invisible Box proxies already provide walking collision. Ten plots lie on an 85-stud ring. The 640-by-640 number is the finite Terrain field, not the playable island diameter.

**Verified — configuration/builders inspected read-only:** [WorldModels](../../src/shared/Config/WorldModels.luau) and [Hub](../../src/server/World/Builders/Hub.luau) define a 72-by-72 tiled plaza, ten colored radial paths, repeated seating/foliage, three gates near the hub, a trophy/fountain, toilet previews and multiple large boards. Foreground palms, shoreline clusters, cloud meshes and atmosphere already exist. [Plot](../../src/server/World/Builders/Plot.luau) builds 30-by-28 plot floors with fences, five display positions and symmetric decoration. [Lighting](../../src/server/World/Builders/Lighting.luau) already includes Atmosphere, Bloom, ColorCorrection, SunRays and Clouds. The current approach is more than primitive props on bare Terrain.

**Inference — composition risks, not claims from a current screenshot:**

1. Mesh integration improved silhouettes, but kept the ring, repeated radial stripes and central competing objects. Imported props alone do not resolve a weak scene hierarchy.
2. Five path colors plus rarity accents, gate colors and large signs risk distributing contrast everywhere. Paths should carry navigation; rarity should carry reward emphasis.
3. Fences and paired landscaping can read as tiny pens rather than collectible showrooms. Open, framed pavilions better explain “my toilet, my collection.”
4. Existing foreground/coast decoration is useful, but a designed, asymmetric skyline and intermediate headlands would give it stronger depth. Simply adding more clouds would not do that.
5. The existing 2,499 hub / 399 plot part ceilings are permissive compared with the reported imported counts. They do not constrain repeated triangle cost or draw calls. Ten copies of the reported worst plot plus the hub would total **800,700 mesh triangles**, before the exclusions above. This is arithmetic capacity planning, not an observed loaded scene.
6. A fallback hub at 1,536 BaseParts is materially heavier than the imported hub. A degraded mode should preserve readable routes and prompts with fewer decorative primitives, not reproduce every ornamental detail.
7. Spending first on replacement toilets would discard functioning assets and preserved seat geometry. Spend first on composition, architectural framing, common low-cost props and the skyline.

## 11. What must be confirmed during implementation

- A rendered baseline in the intended Roblox experience: spawn, owner plot, opposite plot and coastline, at low and high quality. None was available for this research.
- Asset delivery, mesh collision fidelity and silhouettes; public API research cannot establish our uploaded content permissions.
- Real device performance with ten populated plots, simultaneous cosmetic effects and repeated Home/Hub travel; competitor counts are not a substitute.
- Installed Studio/Rojo support for the 2026 streaming flags, and whether an authored static backdrop benefits from SLIM.
- The final art review of external screenshots and any candidate packs. Indexed images, old wikis and video metadata remain qualified evidence.

The concrete proposal, including dimensions and budgets, follows in [map-redesign.md](../design/map-redesign.md).
