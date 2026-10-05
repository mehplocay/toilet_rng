# Reference analysis: top RNG/collect game screenshots (quality-reference-1..7)

Files: docs/reference/quality-reference-1.webp ... quality-reference-7.webp (owner-provided screenshots of a leading Roblox roll/collect game; reference for look and layout, never copy assets).

## What they do that we do not yet
1. **One cohesive palette and surface language.** Everything is built from the same few colors (saturated teal/green lawn, sand-yellow plaza, deep cobalt blue structures, hot-pink/red accent carpets, white highlights) and the classic Roblox stud texture on large surfaces (grass, sand, platforms) so big areas never look flat. Strong colored shadows (blue) under big props. Rule for us: define one palette (hex) and one material/texture treatment, apply to ALL world geometry and UI.
2. **Stations with floating signs.** Each feature is a small themed booth/stall with a striped colorful awning/roof and a big floating 3D-looking billboard label with an icon (TRAITS, GRADES, TRADE, QUESTS, FUSING). Players learn the hub by walking past stations. Rule for us: Shop, Upgrades, Index/Collection, Daily, Passes, Teleport/Portals, Rebirth (later) each get a booth + billboard with an icon; labels are big, outlined, readable from afar.
3. **A giant central landmark** (huge blue tower/statue) visible from everywhere, plus a "BEST ROLL EVER" aura statue/billboard. Rule: the golden toilet trophy/tower must be huge (tens of studs) with aura, beams and the best-flush billboard.
4. **Wayfinding by glowing chevron arrows** on the ground and in the air leading to leaderboards and areas; curved sand paths with a clear edge.
5. **Leaderboards as hero props:** three large tilted boards (Rarest, Rolls/Flushes, Money) with angular lightning-shaped header banners, faceted crystal pillars on both sides, glowing arrows, ranked rows with avatar head, name, value. Rule: our Top Toilets board becomes three boards (Rarest find, Total flushes, Coins) in the hub.
6. **Player base ("Home") layout:** a large rectangular platform with an edge frame; a red/pink carpet lane down the middle; rows of raised display pedestals on both sides with a green "$ collect pad" in front of each; a side wall of stairs/pillars for progression (rebirth); pavilions/shelters around. Pedestal units have glowing auras/outlines in rarity color, lightning/sparks for rare ones, and a floating nametag stack: Name, Rarity, "1 in X", "$N/s" (income per second). Rule: our plot follows this structure (central lane, 5 to 10 pedestals per side with collect pads, income label per item); this matches our passive-income design.
7. **Background depth:** giant blocky palm trees in the foreground (huge trunks, low-poly fronds) framing the camera, layered mountains and clouds as a skybox, ocean around, distant towers. Rule: foreground foliage and distant silhouettes in at least three layers.
8. **Heavy VFX/aura language:** rarity-colored auras, lightning, sparkles, bursts; unit highlights (outline) in rarity color. Rule: every Epic+ item on a pedestal gets aura particles and an outline.
9. **HUD:** three-button bottom bar (Backpack, big ROLL/dice with pointer hand, Upgrades), small tutorial instruction text in the center ("Place the unit in an empty slot!"), contextual red "Put Back" button, big green money number bottom-left, "Friend Boost" chip, right-side offer stickers (OP!, 999x luck, Double Roll), top tabs Hub/Home/Shop.
10. **Always something moving or glowing in view**: rotating, bobbing, pulsing props; never a static empty area.

## Decisions for Toilet RNG
- Switch the world to the cohesive palette + stud-style surface textures (SurfaceAppearance or Texture/Decal on large slabs) and colored shadows.
- Hub = sand plaza with curved paths, central giant golden toilet tower, six to eight themed stations with floating billboards and awnings, three leaderboards with crystal pillars, chevron wayfinding, portals to future worlds.
- Plot = platform with carpet lane, 2 x 5 pedestals with collect pads and income nametags, frame, pavilions, the player's toilet at the head of the lane.
- Everything visible is a Blender mesh from a shared kit; code only assembles, lights and animates.
