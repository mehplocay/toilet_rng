# Toilet RNG: Flush Resort map redesign

Status: **proposed, docs only**. Date: 2026-10-05. Evidence and qualifications: [map-quality research](../research/map-quality.md). No source, assets, uploaded content or gameplay were changed by this task.

Build a bright coastal collection resort: **ten open toilet pavilions, two promenades, one enormous crowned toilet and a layered island horizon**. Keep the existing toilets/items and make them look valuable through architecture, placement and contrast. Retain ten-player capacity, five visible display positions with pagination, existing Home/Hub travel, server-authoritative flushes and the current economy. Future gates remain “Coming soon”; this plan adds no new worlds or progression.

All numbers and colors below are **our proposed production specifications**, not measured competitor settings. Lighting values are starting presets that require in-engine approval. The local images are the directly inspected visual targets. [Quality reference](../reference/quality-reference-1.webp), [mockup](../reference/mockups.png), [style guide](ui-style-guide.md), [GDD](../GDD.md).

## 1. What changes and why

The current implementation already has imported meshes, foreground foliage, coast decoration and post-processing. Its documented counts are 627 hub BaseParts and 225,340 hub mesh triangles; a largest populated plot uses 184 BaseParts and 57,536 mesh triangles. [Current implementation](../world-models.md). A current in-engine screenshot was not available, so the following is a composition diagnosis from the specification and builders, not a rendered-quality verdict.

| Current risk — inference | Concrete change | Keep |
| --- | --- | --- |
| Ten radial paths and multiple colors distribute attention across the whole hub. | Two navy promenades, a central spine and a small number of crosswalks; one consistent path material. | Recognizable colored reward items and rarity cues. |
| Fountain/trophy, previews, boards, banner and gates compete in the same central area. | Crowned toilet becomes the hero; shop/leaderboard become low kiosks; previews live on the shop counter; gates move to the north end. | BEST FLUSH EVER, shop and leaderboard functions. |
| Small fenced plots can resemble pens. | Open-front pavilions with a dark architectural frame, pink rug and raised collection display. | The seven toilet tiers, seat datum and five display positions. |
| Added props preserve an undirected island silhouette. | Shape a north headland, lower side beaches and two asymmetric mountain bands. | Terrain, sea and useful imported plants/rocks. |
| Repeated decorative meshes consume more geometry than their screen importance warrants. | Simplify common vegetation, rail corners and display stands; reserve detail for toilets/items and the hero. | Existing uploaded item/toilet content and working template normalization. |

Do not commission a wholesale replacement kit first. Approve a greybox camera view, then one finished pavilion and a hub corner. Roblox's curriculum supports this blockout-to-kit workflow; our resort composition is a design choice. [Official kit workflow](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets).

## 2. Plan, coordinate system and circulation

World X runs west/east; +Z is north in this document. Floor walking surface is Y=0. Coordinates describe ground placement datums; character travel destinations need the existing safe character-height offset. The diagram is schematic; the coordinate table is authoritative.

```text
                         NORTH / +Z
           far mountain band: centers 260–300 from origin
            middle headlands: centers 180–230 from origin
       ~~~~~~~~~~~~~ water / sand / uneven coast ~~~~~~~~~~~~~
       |       rounded island envelope 280 X x 352 Z       |
 z=160 |            raised scenic bank, Y=8..18            |
 z=144 |        [SEWER]       [SPACE]        [HELL]         |
       |          x=-26        x=0           x=26         |
 z=132 |        -------- 8-wide gate apron --------        |
 z=120 |        ======= 10-wide crosswalk =======          |
       |                 |     |     |                   |
 z=96  | [W5 32x36] -->   P     S     P   <-- [E5 32x36]  |
 z=72  |        ======= 10-wide crosswalk =======          |
 z=48  | [W4 32x36] -->   P     S     P   <-- [E4 32x36]  |
 z=24  |        ====== north edge of hub =======           |
 z=0   | [W3 32x36] -->   P  [CROWN]  P   <-- [E3 32x36]  |
       |                 P [60x64 HUB]P                   |
 z=-24 |        ====== south edge of hub =======           |
 z=-48 | [W2 32x36] -->   P     S     P   <-- [E2 32x36]  |
 z=-72 |        ======= 10-wide crosswalk =======          |
 z=-96 | [W1 32x36] -->   P     S     P   <-- [E1 32x36]  |
 z=-120|        ======= 10-wide crosswalk =======          |
 z=-140|            small seaside arrival terrace         |
       |       ~~~~~~~~~ south beach ~~~~~~~~~~~~         |
 z=-176|_________________________________________________|

                 x=-62  -36    0    +36   +62
                          P = promenade, 12 wide
                          S = spine, 14 wide
           plots: 32 frontage along Z x 36 depth along X
           plot centers: 48 apart along Z; 16 garden gaps
           clear gap between opposing plot fronts: 88
```

| Element | Exact proposed specification |
| --- | --- |
| Plots | **10 total**, five west/five east. Centers X=-62/+62; Z=-96,-48,0,48,96. West entrances face +X; east entrances face -X. Store explicit transforms rather than an angle/radius loop. |
| Plot floors | 36 along X × 32 along Z. West bounds X=-80..-44; east X=44..80. Z bounds center±16. Center pitch 48 leaves **16 studs** between neighboring floor edges. |
| Promenades | Centers X=-36/+36; 12 wide, Z=-120..132. Their outer edges at ±42 leave 2 studs to plot fronts at ±44; bridge this with an entrance lip. |
| Central spine | 14 wide, X=-7..7, Z=-140..132. Inside the hub merge its paving into the plaza and route around the basin. Do not stack duplicate floor colliders. |
| Crosswalks | 10 wide along Z at Z=-120,-72,-24,24,72,120; stretch X=-42..42. At ±24 merge into the plaza. No garden props in these strips. |
| Hub plaza | 60 X × 64 Z, bounds X=-30..30, Z=-32..32; continuous with promenade edges. Decorative paving modules follow a 2-stud grid, while long path slabs are at most 48 studs long. |
| Gate apron | Z=132, 8 wide along Z, X=-36..36; three 8-wide approach stubs end at Z=141. Spine and promenades connect into the apron. |
| Hero circulation | Basin centered (0,0,8), diameter 24. An 8-wide walking ring occupies radii 12..20; join spine south/north and hub crosswalks. Maximum ring extent: X±20, Z=-12..28. |
| Hub travel arrival | Ground datum (0,0,-24), facing the crown. Owner arrival stays inside the owned plot. Arrival pads and prompts use existing travel logic and collision-safe character offsets. |
| Terrain envelope | Rounded, asymmetric main land within X±140, Z±176. Level district contains X±84, Z±116. Coast taper begins outside it; gate terrace reaches Z=156. Keep the finite 640×640 Terrain field for sea/backdrop margins, not 640 studs of walkable lawn. |
| Scenic heights | Floors Y=0; planter tops 1–2; scenic grass banks 3–8; north headland 8–18; beach -4..-6; sea surface -8. No unintended walkable moat between plots and paths. |

At nominal 16-stud/second walking speed, 48-stud plot pitch is three seconds along the promenade. This is a design calculation; avatar speed and actual routed distances must be checked against the game. Near plots are close to services, far plots retain Home/Hub travel. Do not enlarge this map further without a concrete gameplay reason.

## 3. One plot: contents and readable hierarchy

Use local plot coordinates **u** across frontage (-16..16), **v** inward from the entrance (0..36), and Y above the floor. Apply one rotation for each row; never independently stretch a toilet to fit.

```text
                       rear, v=36
        +--------------------------------+  32 frontage
        | palm   low rail / dark frame   |
        |             TOILET             |  toilet datum (0,25)
        |        clear flush zone        |
        |                                |
        | D    D    D    D    D           |  stands v=11
        |        pink collection rug     |
        |          10-wide entry         |
        +---post------------------post---+  entrance v=0
                    promenade
                   36 depth
```

| Component | Proposed count and dimension |
| --- | --- |
| Floor | One 32×36 collision floor; top at world Y=0, visual fascia 0.6 high below it. Perimeter trim 0.5 wide; no full-Neon outline. |
| Pavilion frame | Four corner posts, 0.8×12×0.8, positioned at u±15, v=1/35. Two side beams and rear beam at Y=11.5. One shallow rear canopy: 30×8 over v=28..36, underside Y=10.5. Front stays open; no roof over displayed items. |
| Toilet | One current tier at (u=0,v=25), original uniform scale/foot datum. Keep the authored 2.08-stud seat relationship, including tier ornaments. Reserve a 10×10 interaction region around it. [Normalization contract](../world-models.md). |
| Collection | **Five visible stands**, centers u=-10,-5,0,5,10, v=11. Stand width 3.2, height 1.2; displayed item silhouette ≤3 studs unless existing behavior requires otherwise. This leaves **4.4-stud side passages** between the outer stands and floor edges. Preserve pagination and server-selected items. Labels face the entrance. |
| Rug and guidance | One opaque pink rug 28×8 centered (0,11); small non-Neon pale arrow at the entry. Eight-stud clear approach depth before the stands; access toilet through side passages and a gap after the stands. |
| Ownership sign | One frame above entry, text face 18×2.5 with bottom at Y=8. Owner name and plot number only. Long-name fit tested; keep it below the dominant hub silhouette. |
| Rails | Rear rail plus short back-half side rails, top Y=2.5. No front fence or gate. Invisible simple collision only where needed. |
| Landscaping | **12 placements total per plot:** 1 palm, 2 shrubs, 2 flower clumps, 2 rocks and 5 small groundcover clumps. Rear/outer corners and two outer planting pockets; no prop or canopy leaf in the item-label sight cone. Vegetation can overhang the floor; its trunk cannot block circulation. |
| Local light | At most one shadowless low-range light on a special toilet, following current effects. Ordinary posts have colored trim, not ten additional point lights. |

Architectural frame is navy/white, rug is pink, ground is green. Reward items retain their rarity appearance. Two landscaping variants alternate along each row, with seeded yaw ±20 degrees and scale 0.85–1.15. Keep entrance, posts, signs and stands aligned; randomize foliage, not functional architecture.

## 4. Hub landmarks and wayfinding

| Landmark | Coordinate / size | Purpose |
| --- | --- | --- |
| Crowned golden toilet | (0,0,8); total height **28**, maximum toilet/crown footprint 12×14, on the 24-diameter basin. Static silhouette; crown detail can be separate. | Immediately identifies Toilet RNG from spawn and most plots. First prototype: uniformly enlarge the existing Golden toilet and add a simple crown; bespoke geometry follows approval. |
| Theme banner | Pedestal front, 24×3.5, bottom Y=2.5; “TOILETS MAKE DREAMS COME TRUE!” | One integrated hero message, replacing competing floating billboards. |
| Upgrade/shop kiosk | Center (-22,0,-22), footprint 12×8, canopy height 8. Compact row of seven miniature tier previews on the counter. | Existing upgrades/shop entry. Sign: “TOILET UPGRADES”; supporting text: “Better toilets = new drops + higher odds!” |
| Leaderboard kiosk | Center (22,0,-22), footprint 12×8, canopy height 8. | Existing leaderboard; balances the shop without matching the hero's height. |
| Best record board | Center (25,0,24), frame 8 wide × 9 high × 2 deep. Bounds X=21..29 avoid the basin ring. | “BEST FLUSH EVER”, existing server record, item/player/odds. Not a second skyline landmark. |
| North gates | Centers (-26,0,144), (0,0,144), (26,0,144); each 10 wide × 14 high × 6 deep. | Sewer: pipe silhouette/green; Space: ring/cyan-purple; Hell: horn/ember. Shape plus text distinguishes them. All show “Coming soon”. |
| Arrival terrace | Z=-140; 28×16 widening around the spine, benches outside a 14-wide clear strip. | A coastal photo angle and visual end to the south axis; no new service. |

Use navy curbs and pale path dashes for routes; gold only around the hero/shop, pink around collections, gate colors at their destination. Add plot numbers W1–W5/E1–E5 as unobtrusive entrance identifiers. Gate silhouettes remain recognizable in grayscale; decorative portals never imply active travel.

At the hub arrival, the crown must be visible above both kiosks. From an owner arrival, all five stands, ownership sign and toilet remain readable. Architectural posts may frame the view; they must not cover the toilet's flush prompt or the central item. This applies the framing seen in the [local references](../reference/quality-reference-1.webp); it is not a claim about competitor camera settings.

## 5. Shore, mountains, water and depth

| Layer | Placement and count — proposal | Treatment |
| --- | --- | --- |
| Foreground | **24 foliage/rock placements** at south arrival corners and two hub-side pockets. Palm heights 18–24; lower clusters 1–4. | Darker, richer greens; overlap only the side 15% of reference views. Keep central 70% readable with the real HUD enabled. |
| Playable middle | Ten pavilions height 12, hub hero 28, clear walking district; **64 hub/promenade decorative placements** beyond required buildings/stands. | Highest local color/edge clarity. Hub clusters mark junctions and the basin, never every empty square. |
| Coast | **96 placements** in 24 clusters: each has four placements chosen from palm/shrub/rock/groundcover. Twelve distinct headland rocks and eight low cliff modules are counted within this allocation. Shore band is mostly 12–24 deep. | North coast higher, west bay lower, south beach open. Make two larger silhouettes, not a perfectly circular necklace of rocks. |
| Near background | **Eight mountain/headland meshes**, centers 180–230 from origin, heights 30–55, bases 35–70 wide. Mostly north and east; west leaves open sea. | Mid-blue/teal; terrain contact hidden by headland/sea. No collisions, touch/query or shadows. |
| Far background | **Six mountain meshes**, centers 260–300 from origin, heights 50–85, bases 55–95 wide. Keep outermost geometry inside the sea field or deliberately extend only the backdrop. | Lighter blue, weaker contrast, simple silhouettes. Avoid equal-height peaks or a continuous wall. |
| Sky | Built-in Sky, dynamic Clouds; optionally **six static cloud meshes** above the mountain band, Y=70–95. | White/warm highlights; clouds must not create a low solid ceiling or an obvious repeating ring. |

Counts are placement allocations, not BasePart counts. Foreground, hub, plot and coast allocations are disjoint: **24 + 64 + (10×12) + 96 = 304 decorative placements**. Required architecture, hero, gates, displays, mountain/cloud meshes and collision proxies are separate. Decorative instances must still fit the budgets below.

Density rule: plantable 16×16 cells contain 1–2 clusters of 3–5 small props; junction/foreground pockets can contain 2–3 clusters. Paths, entrance pads and display sight cones contain zero landscaping. At least 70% of the hub's walkable ground remains free of decorative obstruction. This is a deliberate placement rule, not a recommendation to fill every grass cell.

Water preset: `WaterColor=#28BCC8`, `WaterTransparency=0.35`, `WaterReflectance=0.05`, `WaterWaveSize=0.12`, `WaterWaveSpeed=8`; surface Y=-8. Sculpt beach into water with a shallow shelf, and hide the finite field boundary from normal owner/hub camera views. These properties exist on Terrain; values are ours. [Terrain API](https://create.roblox.com/docs/reference/engine/classes/Terrain).

Initial mountain placements below remove guesswork from the blockout. Sizes are maximum X×Y×Z bounding boxes, base Y=-8, no collision. Use three near variants and two far variants with modest yaw changes; authored bounds must remain inside X/Z±320 after rotation. Adjust shape/yaw within those bounds rather than expanding the ocean field.

| Band | Center X,Z | Maximum size X×Y×Z |
| --- | --- | --- |
| Near 1 | -118,190 | 55×45×42 |
| Near 2 | -65,218 | 45×35×38 |
| Near 3 | 0,225 | 65×55×44 |
| Near 4 | 65,210 | 50×40×40 |
| Near 5 | 120,180 | 70×50×45 |
| Near 6 | 190,85 | 60×45×44 |
| Near 7 | 198,-25 | 45×30×36 |
| Near 8 | -180,90 | 55×38×40 |
| Far 1 | -165,230 | 85×65×46 |
| Far 2 | -85,268 | 65×55×40 |
| Far 3 | 0,290 | 95×85×44 |
| Far 4 | 95,265 | 75×70×42 |
| Far 5 | 220,175 | 80×65×45 |
| Far 6 | 265,70 | 70×50×40 |

Do not build floating islands in the first pass: the coastal mountain treatment fits the supplied target and has fewer competing silhouettes. A future Space gate can have one small local hovering rock after the main composition passes; it is optional polish, not a fourth gameplay destination.

## 6. Palette and material treatment

| Role | Hex values | Use |
| --- | --- | --- |
| Main grass / light grass | `#57CE55` / `#8CE36F` | Large saturated ground masses; light patches on banks. |
| Foliage shade / leaf highlight | `#237E63` / `#70D957` | Palms and shrubs, painted gradient rather than flat neon green. |
| Path / raised trim | `#28364E` / `#172337` | Avenue and pavilion frame; contrast against green/pink. |
| Path markings / ceramic | `#EEF8F3` / `#FFF5E5` | Broad readable dashes and toilet highlights. |
| Collection rug / rug highlight | `#F45AAA` / `#FFA5D0` | Personal display floor; modest coverage. |
| Hero gold / gold shadow | `#FFCC46` / `#D18A26` | Crown, basin trims and shop accents. |
| Sand / warm bank | `#F4D9A2` / `#CFAA76` | Narrow beaches and ground contact. |
| Sea / shallow shelf | `#28BCC8` / `#63DCD3` | Terrain water plus shore material/color transitions. |
| Near mountains / far mountains | `#4D9CC0` / `#98CDE6` | Distinct distance bands. |
| Gate accents | Sewer `#80EC72`; Space `#AB82F5`; Hell `#FF8058` | Small controlled accents, with shape/text cues. |

Approximate screen-area target from the hub arrival: green/foliage 35%, sky/water/mountains 35%, dark paths/frames 20%, warm/pink accents 10%. This is an art-review guide, not texture coverage math.

Use SmoothPlastic/palette gradients on the toy kit and a subtle reusable paved material on the ground. New props share one 512×512 atlas; architectural trim may use one 1024×1024 atlas. At most two new PBR material sets, 1024×1024 each, for hero ceramic/gold if they improve the mobile render. Preserve existing TextureID/content references. SurfaceAppearance is optional and requires an explicit loader-contract extension before use. Roblox documents reusable texture/PBR treatments and content-based instancing; it does not guarantee our budgets or this palette's visual result. [Meshes](https://create.roblox.com/docs/parts/meshes), [asset-library workflow](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library), [optimization](https://create.roblox.com/docs/performance-optimization/improve).

## 7. Lighting and sun: starting preset

Use a stable afternoon; no day/night cycle in this redesign. Keep **LightingStyle Soft** as the first comparison with the current project. Author style/priority in Studio/Rojo, then apply supported runtime settings through the existing central config/lighting builder. Test an otherwise identical Realistic comparison only if the owner prefers its shadows and devices tolerate it. The guide makes ShadowSoftness a Realistic-only control; do not claim it improves Soft. [Current lighting guide](https://create.roblox.com/docs/environment/lighting).

| Object / property | Proposed value |
| --- | --- |
| Lighting.LightingStyle | `Soft` |
| Lighting.PrioritizeLightingQuality | `true` |
| Lighting.ClockTime / GeographicLatitude | `15.3` / `18` |
| Lighting.Brightness / ExposureCompensation | `2.3` / `0.00` |
| Lighting.GlobalShadows | `true` |
| Lighting.EnvironmentDiffuseScale / EnvironmentSpecularScale | `0.65` / `0.45` |
| Lighting.Ambient / OutdoorAmbient | RGB `(106,119,148)` / `(148,174,194)` |
| Lighting.ColorShift_Top / ColorShift_Bottom | RGB `(255,231,198)` / `(0,0,0)` |
| Atmosphere.Density / Offset | `0.24` / `0.10` |
| Atmosphere.Color / Decay | RGB `(173,219,242)` / `(255,225,191)` |
| Atmosphere.Haze / Glare | `1.4` / `0.10` |
| BloomEffect.Intensity / Size / Threshold | `0.10` / `18` / `1.25` |
| ColorCorrectionEffect.Brightness / Contrast / Saturation | `0` / `0.04` / `0.10` |
| ColorCorrectionEffect.TintColor | RGB `(255,251,245)` |
| SunRaysEffect.Intensity / Spread | `0.02` / `0.65` |
| Sky.CelestialBodiesShown / StarCount | `true` / `0` |
| Sky.SunAngularSize / MoonAngularSize | `10` / `0` |
| Sky skybox/sun textures | Retain verified built-in content; no fabricated custom IDs. |
| Terrain.Clouds.Cover / Density / Color | `0.25` / `0.40` / RGB `(255,247,236)` |
| Workspace.GlobalWind | Vector `(4,0,1)`; affects supported systems, not arbitrary static palms. |
| Optional Realistic comparison only | `ShadowSoftness=0.25`, all other values unchanged. |

ClockTime/latitude select the engine sun direction; they are not explicit azimuth/elevation coordinates. Inspect actual shadows and orient scenery so side foliage casts diagonal shadows without obscuring the five stands. Atmosphere is scattering, not a stud-distance fog switch. Keep the three horizon bands distinguishable; if foliage detail or owner names wash out, reduce haze/exposure before adding contrast. [Atmosphere](https://create.roblox.com/docs/environment/atmosphere), [Sky](https://create.roblox.com/docs/reference/engine/classes/Sky), [Clouds](https://create.roblox.com/docs/environment/clouds), [post-processing](https://create.roblox.com/docs/environment/post-processing-effects).

Disable ambient SunRays and halve optional particles in the low-effects comparison. Base color, geometry and signs must still carry the scene when bloom is absent. Low-quality approval is required, not a later fallback to a different art direction.

## 8. Animation and effects list

All new ambient movement is cosmetic and client-controlled; rewards, drops and coins remain server-authoritative. Reuse the existing controller/culling where possible. Proposed effects must stop cleanly when an object streams out and reattach when it returns.

| Element | Motion/effect — proposal | Visibility and cap |
| --- | --- | --- |
| Hero crown glint | One sparkle emitter, rate 2/sec, lifetime 0.8; no spinning of the entire giant toilet. | Within 100 studs; off in low-effects mode. |
| Fountain | Four existing-style Beam jets, subtle texture motion; physical basin water is static. | Within 120 studs. No chain of transparent water sheets. |
| Portal trims | Three trim pulses, 2.5-second period; one floating chevron per gate bobs ±0.25 over 3 seconds. | Within 100 studs. Pulse opacity/color, not full-model transforms. |
| Featured rare items | Existing rarity-specific effects; optional slow yaw on at most two featured display items locally. | Within 60 studs; suspend during flush and when out of view. Retain items' supported display semantics. |
| Palm leaves | Optional 12 nearby leaf groups sway ±2 degrees, 4–6-second cycles. | Within 80 studs; 20–30 Hz calculation, interpolated visual movement. Requires split static trunk/leaf assets and a deliberate loader extension. |
| Coast sparkles | At most two small emitters at decorative spots, 1/sec, lifetime 1. | Within 70 studs. No emitter on every bush. |
| Clouds / water | Engine Clouds and Terrain waves from the preset. | No additional per-cloud server Heartbeat transforms. |

New ambient caps per client: **four simultaneously active emitters, twelve live ambient particles, sixteen animated object groups and four decorative shadowless lights**. Existing special toilet/item lights remain distance-culled; add no light at each gate segment. Flush/reward effects have a separate temporary reserve; throttle ambient effects first during celebrations. These are proposed caps to implement, not already enforced behavior. Particle footprint and overdraw matter as well as rate. [Particle guidance](https://create.roblox.com/docs/effects/particle-emitters), [light types](https://create.roblox.com/docs/effects/light-sources).

## 9. Geometry, instance and delivery budgets

Targets refer to **the complete ten-plot authored map**, not only a conveniently streamed view. Count invisible collision parts. Keep a separate runtime/transient reserve. Triangle totals are mesh catalogue totals at placement scale, not Terrain or renderer triangle totals.

| Allocation | BasePart ceiling | Authored mesh-triangle ceiling | Includes |
| --- | ---: | ---: | --- |
| Hub, paths, gates and on-island landscaping | 650 | 150,000 | Hero, kiosks/previews, signs, promenade/crosswalks, 184 non-plot decorative placements. |
| Each populated plot | 100 | 25,000 | Current toilet, five displayed items, floor/frame/rails/sign, 12 landscape placements and collision proxies. |
| Ten plots subtotal | 1,000 | 250,000 | No transient flush drops. |
| Background | 150 | 40,000 | Fourteen mountain/headland meshes, six optional cloud meshes and any supporting backdrop geometry. |
| Static map total | **1,800** | **440,000** | Above allocations summed once. |
| Transient reserve | 200 | 60,000 | Overlapping drops/celebration geometry; reuse/clean up existing effects. |
| Peak map + reserve | **2,000** | **500,000** | Excludes player avatars, engine Terrain tessellation, primitive-part tessellation and particle/UI geometry. |

Additional targets: ≤4,500 map Instances including Models, labels, attachments and effects, excluding avatar/service/runtime infrastructure; ≤50 unique map mesh contents, ≤12 unique map texture contents, ≤2 new PBR sets. Inventory templates in ReplicatedStorage must be counted separately for client memory; streaming does not remove that cost. [Streaming scope](https://create.roblox.com/docs/workspace/streaming).

Plot feasibility check: five copies of the current largest item (2,460 triangles) plus the largest toilet (4,880) consume **17,180** triangles; the 25,000 budget leaves **7,820** for architecture, stands, signs and foliage. [MeshCatalog](../../src/shared/Config/MeshCatalog.luau). This is a worst-item arithmetic bound, not a claim that all players show the same item. Keep these gameplay assets; optimize the surrounding decoration.

Proposed replacement ceilings: display stand 300 triangles; palm 800; shrub 300; flower clump 250; groundcover clump 100; rail module 300; pavilion frame/rails/trim combined 2,000; ownership-sign mesh 800; hero toilet/crown ≤8,000 total; near mountain ≤2,000; far mountain ≤1,000. Use real exported counts, not polygon counts before triangulation. Any exception consumes its area's allowance. A mesh may legally import at up to 20,000 triangles, but these are intentionally lower production targets. [Import specification](https://create.roblox.com/docs/art/modeling/specifications).

At those ceilings, plot decoration/architecture consumes 7,276 triangles: palm 800 + shrubs 600 + flowers 500 + existing rocks 576 + groundcover 500 + stands 1,500 + architecture 2,000 + sign 800. With gameplay meshes, that is **24,456**, leaving 544 within the plot ceiling. The transient reserve covers twenty maximum-item meshes (two overlapping drops on each of ten plots) at **49,200**, leaving 10,800 for temporary mesh accents. Neither calculation includes particles or primitive tessellation; those still require renderer profiling.

First mobile profiling targets: ≤250,000 rendered map mesh triangles and ≤200 map-contributed draw calls in the worst normal hub view, measured with a comparable empty/avatars-only baseline. Treat those as investigation triggers, not universal Roblox capacity limits; total renderer figures also include Terrain, avatars and passes. Use shared content IDs, simple collision proxies and shadowless distant props. [Performance guidance](https://create.roblox.com/docs/performance-optimization/improve).

## 10. Streaming configuration and background residency

| Setting | Initial proposed value | Decision |
| --- | --- | --- |
| Workspace.StreamingEnabled | `true` | Preserve streaming. |
| Workspace.StreamingMinRadius | `64` | Lower current 128 after teleport/interaction validation. |
| Workspace.StreamingTargetRadius | `256` | Test compact-map buffer against current 384; custom choice, not Roblox's general recommended default. |
| Workspace.ModelStreamingBehavior | `Improved` | Small spatial models rather than one huge hub/plot atomic group. |
| Workspace.StreamOutBehavior | `Opportunistic` | Permit delivery to scale down outside target. |
| Workspace.StreamingIntegrityMode | `PauseOutsideLoadedArea` | Test existing Home/Hub travel under latency; no custom pause UI required by this plan. |
| RenderFidelity | `Automatic` on normal kit; test `Performance` on background | Author in Studio, verify silhouettes. Keep protected-property writes out of the loader. |
| CollisionFidelity | `Box` on decorative meshes in Studio | Complete the existing verification/resave requirement; walking uses current simple proxies. |

Workspace streaming settings are authored rather than runtime-scriptable; Atomic and persistent behavior needs deliberate grouping. Before a Home/Hub teleport, evaluate `RequestStreamAroundAsync` using the existing travel path, with timeout/recovery; it is not proof every asset has finished downloading. [Streaming guide](https://create.roblox.com/docs/workspace/streaming).

Use individual prop/pavilion modules as the smallest streaming units; do not mark the entire plot or resort Persistent. Initial horizon solution: **at most fourteen small non-colliding Persistent mountain Models**, one mesh each, ≤22,000 triangles total, plus ordinary streamed coast. They are a narrow visual exception so the skyline does not vanish as the player reaches the far plot. Keep them free of dynamic properties, scripts and expensive texture sets. If this residency is too costly, reduce silhouettes before increasing target radius globally.

Optional second-stage experiment: author a static background in Studio and test `Model.LevelOfDetail=SLIM` in a private Roblox-saved Team Create place. Current runtime-cloned/normalized templates and animated scenery are not a proven SLIM workflow. If SLIM passes, replace the persistent-silhouette approach for that backdrop; do not budget or enable both as invisible duplicated systems. [Current SLIM requirements](https://create.roblox.com/docs/workspace/streaming/slim).

Also test `Workspace.MeshStreamingAndImprovedLods=Enabled` only after verifying installed Studio/Rojo/API support. The current reference uses this exact spelling and `Enum.RolloutState`; older announcement capitalization differs. Predictive streaming is another optional experiment, not required for first visual approval. [Workspace API](https://create.roblox.com/docs/reference/engine/classes/Workspace). Preserve the existing configuration if these experiments regress loading or cannot round-trip through Rojo. [Rojo properties](https://rojo.space/docs/v7/project-format/).

## 11. Prioritized work packages

Order is **P0 blockout/one-corner proof → P1 kit and assembly → P2 tuning/polish**. The groups below are handoffs, not a requirement to finish all Blender work before inspecting Studio. Effort estimates assume one implementer: S up to half a day, M approximately 1–2 days, L approximately 3–5 days; revisions/uploads/device access can extend them. Model recommendation: **Luna** for bounded easy tasks, **Sol 6.1** for medium/hard implementation, **Astra** for hard art/architecture/performance decisions. These are future task recommendations, not agents launched in this research.

### Blender asset tasks

| Priority / ID | Task and concrete acceptance | Effort | Recommended model |
| --- | --- | --- | --- |
| P0 B1 | One pavilion look-development sheet and a rendered test corner: navy frame, pink rug, current toilet/items, two landscape variants. Fixed stud/pivot grid; approve before replication. | M | Astra — resolve composition and art direction. |
| P1 B2 | Crowned hero: prototype with existing Golden toilet, then one ≤8K-triangle hero/crown set, 28-stud assembled height, visible toilet silhouette at thumbnail size. | M | Sol 6.1 |
| P1 B3 | Minimal architectural kit: post/beam, rear canopy, low rail, planter lip, kiosk trim. Each mesh retains a single-MeshPart template contract; consistent front/base pivots and 2-stud-compatible lengths. | M | Sol 6.1 |
| P1 B4 | Simplify stand/palm/shrub/flower/rail to the ceilings above; keep all toilet/item meshes. Export comparison counts and check silhouettes at plot distance. | L | Sol 6.1 |
| P1 B5 | Three near-mountain silhouettes, two far variants and two coast-cliff variants; fourteen placements reuse content, not fourteen unique imports. Gradients follow the palette. | M | Sol 6.1 |
| P1 B6 | Palette/trim atlas and provenance ledger: exact source, license, count, dimensions, pivots; no fabricated IDs. Keep copyrighted logos/characters out of the kit. | S | Luna |
| P2 B7 | Optional split palm trunk/leaf set and restrained hero PBR maps, only after static/mobile acceptance. Document loader impact explicitly. | M | Sol 6.1 |

### Luau assembly tasks

| Priority / ID | Task and concrete acceptance | Effort | Recommended model |
| --- | --- | --- | --- |
| P0 L1 | Config-only coordinate blockout for the two rows, hub, paths and gate apron; data in shared Config. Build one representative plot before all ten. Avoid changes to ownership/economy/remotes. | M | Sol 6.1 |
| P0 L2 | Safe Home/Hub arrival and orientation checks; owned plot toilet remains accessible; no floor collisions/overlaps or stand blocking. Existing authority and rate limits retained. | M | Sol 6.1 |
| P1 L3 | Replace radial assembly with explicit transforms, merged collision slabs, open frames and current paginated displays. Update meaningful world regression expectations for ten rotated plots. | L | Sol 6.1 |
| P1 L4 | Deterministic cluster placement tables with area caps and two variants; implement clear path/sight-cone exclusions rather than unrestricted random scatter. | M | Sol 6.1 |
| P1 L5 | Assemble asymmetric Terrain coast, headlands and background using bounded generation; keep finite field and placement datums stable. | M | Sol 6.1 |
| P1 L6 | Add budget diagnostics: map BaseParts/Instances, triangle allocation from actual catalog, unique content references and transient cleanup. Report separately from engine Terrain/avatar statistics. | M | Sol 6.1 |
| P2 L7 | Extend existing local idle/effect controller with the limited gate/crown effects, culling and streaming reattachment. No server per-frame scenery replication. | M | Sol 6.1 |
| P2 L8 | Only if B7 approved: extend/validate template contract for leaf groups or SurfaceAppearance; preserve fallback and seat/foot normalization, add targeted contract checks. | M | Sol 6.1 |
| P2 L9 | Lightweight primitive degraded mode within the same functional layout; omit ornamental duplicates when imported assets are unavailable. | M | Sol 6.1 |

### Studio tuning and delivery tasks

| Priority / ID | Task and concrete acceptance | Effort | Recommended model |
| --- | --- | --- | --- |
| P0 S1 | Compare four fixed screenshots: hub arrival, owned plot, opposite-row view and coastline. Show owner the greybox plus one polished corner before ten copies. | S | Astra — judge hierarchy and proportions. |
| P1 S2 | Import kit, verify permissions/texture delivery and pivots, set mesh CollisionFidelity Box / RenderFidelity, resave the approved template root. Reopen Rojo build to catch handoff errors. | M | Sol 6.1 |
| P1 S3 | Paint/review clusters using Brushtool or manual placement; export approved transforms into Config so Studio-only changes are reproducible. Verify plugin publisher and model cloning first. | M | Sol 6.1 |
| P1 S4 | Apply exact starting preset; compare Soft and optional Realistic at low/high quality, then record one approved preset and screenshots. | M | Astra — lighting/composition tradeoffs. |
| P1 S5 | Profile actual low-end mobile with ten populated plots, effects and latency; choose streaming radii from evidence and eliminate the largest frame-time/overdraw offender. | L | Astra — performance diagnosis. |
| P2 S6 | Separate private-place SLIM/new mesh-streaming experiments; keep only measured improvements, with a normal fallback and Rojo round-trip validation. | M | Astra |
| P2 S7 | Final provenance, English signs, long names, prompt/readability and five-stand spot checks; report counts and capture release-review views. | S | Luna |

Dependencies: L1/S1 precede full B3/L3 production; B3–B5/S2 precede L4/L5 polish; L3/L5 precede S4/S5; optional B7/L8/S6 come last. Pack sources can help prototypes, but license availability is not a reason to change the established art style. [Asset-source research](../research/map-quality.md#9-free-and-licensed-asset-sources).

## 12. Top ten quick wins, ranked

These can begin with current templates and simple parts; no complete replacement kit is required. The avenue conversion itself is a larger task and is covered above.

1. **Make the crowned toilet the unmistakable hero.** Uniformly enlarge Golden, add a simple crown, and put it on the central basin; remove the competing trophy silhouette. S–M, Sol 6.1.
2. **Reduce path colors to navy plus pale markings.** Remove the five-color radial palette and most Neon edging. Keep reward/gate accents. S, Luna.
3. **Lower and consolidate hub signs.** Put previews on the shop counter; move BEST FLUSH EVER to a small side board; integrate the theme banner into the hero pedestal. S–M, Sol 6.1.
4. **Add two mountain bands.** Six to fourteen reused low-detail silhouettes, blue distance separation and an open west sea view. M, Sol 6.1.
5. **Open plot fronts.** Remove front clutter, add four dark posts/rear canopy and one pink collection rug; show five items clearly. M, Sol 6.1.
6. **Enlarge selected foreground palms.** Frame hub-arrival corners, with trunks outside paths and leaves outside the central sightline. S, Luna.
7. **Cluster existing foliage instead of pairing everything symmetrically.** Two bounded corner variants, seeded variation, clear entrances. S–M, Sol 6.1.
8. **Sculpt one bay and one headland.** Replace the circular-looking coast with a lower beach and taller north silhouette; retain finite Terrain generation. M, Sol 6.1.
9. **Tune light before adding effects.** Use the restrained afternoon preset; approve side shadows, gold highlights and readable low-quality colors. S–M, Astra.
10. **Simplify the highest-frequency decoration.** Start with flower clumps, rails and stands; share content, disable distant shadows and cap ambient motion. M, Sol 6.1.

## 13. Acceptance and implementation assumptions

Visual acceptance: four fixed reference views at 16:9 and phone aspect, real HUD enabled; the hero is the first read, five owner items and the flush prompt remain unobstructed, and foreground/middle/background remain distinct at low graphics. A 160-pixel-wide grayscale thumbnail must still identify the hero/avenue. Save before/after captures in the implementation review; a Blender render alone does not pass.

Spatial acceptance: all ten plots own/rotate correctly; crosswalks, lips and hero loop have continuous collision; owner arrival never lands behind a rail; two avatars can pass on the 12-wide promenade; low canopy/plant leaves never cover owner labels. Test long names, every toilet tier and overlapping flush drops.

Performance acceptance: profile a named real low-end phone and a reference desktop at documented quality/resolution for three 60-second runs after warm-up. Mobile target: p95 total frame time ≤33.3 ms and no repeatable streaming stall over 500 ms during normal walking/travel after the destination loads. Desktop target: p95 ≤16.7 ms on the chosen reference device. Log memory at warm-up and after ten Home/Hub cycles; no monotonic growth from unreleased map/effect instances. These are project targets, not guaranteed performance from the counts.

Engineering acceptance: `rojo build -o build.rbxl`; available formatting/static checks and relevant world/template/runtime tests; published-private-place asset delivery, mobile/streaming review and Studio fidelity verification. No source changes were made during this research, so these implementation gates remain future work.

Assumptions: ten plots are retained from current implementation; resort architecture is a proposed interpretation of the GDD/mockup; the owner accepts a less radial layout; lighting/budgets are provisional until engine/device review. We have no verified competitor stud or triangle counts, no external-image direct inspection, and no current rendered baseline of our own map. These limits do not prevent a concrete blockout, but they must not be disguised as measurements.
