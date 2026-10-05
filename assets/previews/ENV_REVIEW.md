# Environment kit visual review

Art direction: `docs/reference/quality-reference-1.webp`, the spawn/plot panels of `docs/reference/mockups.png`, and the existing `_sheet_props.png`. Review date: 2026-10-05.

## First render and critique

- The plaza palette and compass pattern fit the existing navy/cyan/gold props. The initial center sun projected too far above the paving, so its thickness was reduced to an inlay and the trophy fountain datum adjusted.
- The gate silhouette was clear, but its arch and luminous line crossed the blank nameplate. Move the plate forward so a future English/player label has an uninterrupted face.
- Initial cliff shells used independently colored triangles. They read as a noisy patchwork instead of broad carved rock. Remove the random face colors and let geometry/normals define the facets. Keep brown soil and a bright grass lip as the intentional color layers.
- Initial sand was too close to white paving under the studio lights. Change the beach and cove ledges to warm atlas woodLight with a caramel lower edge.
- The corner planter's flowers initially read as berries. Replace them with five-petal flowers and small stalks.
- The book's graphic lines hovered above its sloping pages, and its crest partly intersected the tapered column. Match each line's tilt to the page and bring the crest forward.
- The castle, kiosk and coin jar have distinct, readable silhouettes: crowned toilet/turrets, striped awning/coin sign, and an overflowing golden jar. Keep these proportions. Their first draft renders are retained in `env-drafts/`; those 512px images are iteration evidence, not final acceptance previews.
- The bridge and pier have thick warm planks, pegs, capped posts and rope bindings that match the original bench/fence palette. The lighthouse echoes the original lamp's navy roof and warm lens, using larger red/white navigation stripes.

## Review scope

Final local review: all ten family sheets, both views of the corrected designs, and the three assembled studies were inspected. The second pass resolved the sign/crest intersections, raised emblem, floating book lines, noisy cliff colors and pale sand. The assembled view confirmed the ten-sector plaza and radial plot spacing. A final placement pass moved the book and coin jar onto clear lawn beside the approach, preventing their feet from intersecting the raised plaza curb; the delivery audit now checks this clearance. The castle reads as the principal backdrop at the documented 1.5 scale.

Review individual main/front views, all ten final contact sheets and the assembled/spawn/plot studies. The front sheet uses elevated views for shallow tiles so their patterns and sockets can be assessed; it is not a second identical camera angle.

Blender renders are evidence of local geometry, framing and palette assignments. They do not prove Roblox moderation, uploaded permissions, engine normals, pivot correction, lighting, automatic LOD or mobile frame rate. The source meshes carry actual UV color, not preview-only colored shader nodes. Only the assembled study's white-atlas mountains receive a preview tint, corresponding to the intended Studio Color tint.

## Deliberate limitations

- Blank sign/name faces need English text overlays in Studio. Static portal trim and fountain water do not emit light or animate.
- Per-asset meshes contain intersecting closed shells and require separate gameplay collision. Castle doors/windows are shallow reliefs; no interior is supplied.
- Shared fence/deck endpoints overlap when repeated. The documentation explains the post pitch and small cap-offset option; an assembly-specific merge can later remove duplicate posts.
- The assembly study keeps a square turf grid visible for seam and scale review. A shipped coastline should use more cove/corner dressing. Its dock and beach require a later shoreline access route and collision assembly.
- No device performance or in-game visual acceptance is claimed. See `docs/envkit.md` for import steps and the remaining acceptance work.
