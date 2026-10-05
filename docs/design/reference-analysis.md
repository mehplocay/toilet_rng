# Reference analysis: top RNG/collect game screenshots

Files: docs/reference/quality-reference-1..7.webp (owner-provided screenshots of a leading Roblox roll/collect game). Use for look, layout and scale; never copy assets.

## Scale (owner's key point)
The reference map is HUGE: large hub, very large player plots with a lot of space around, long distances between stations, wide paths, water and layered background. Ours is small. Make hub and plots several times larger, with real walking distance between areas (several seconds on foot), and use StreamingEnabled plus LOD/simple far meshes to keep it mobile-safe.

## What they do that we do not yet
1. Cohesive palette and surface language: saturated teal/green lawn, sand-yellow plaza, cobalt blue structures, hot pink/red accents, white highlights; classic Roblox stud texture on big surfaces; strong blue colored shadows. Define ONE palette (hex) and one material treatment for all world geometry and UI.
2. Stations with floating signs: each feature is a themed booth with a striped awning and a big floating billboard with icon (TRAITS, GRADES, TRADE, QUESTS, FUSING). For us: Shop, Upgrades, Index/Collection, Daily, Passes, Portals, later Rebirth.
3. Giant central landmark (huge tower/statue) visible from everywhere plus "BEST ROLL EVER" billboard with aura. Ours: huge golden toilet tower with beams and aura.
4. Glowing chevron arrows on the ground and in the air for wayfinding; curved sand paths with clear edges.
5. Leaderboards as hero props: three large tilted boards (Rarest, Rolls, Money) with lightning-shaped header banners, faceted crystal pillars, glowing arrows, rows with avatar, name and value. Ours: Rarest find, Total flushes, Coins.
6. Player base layout: large rectangular platform with frame; red/pink carpet lane down the middle; rows of raised pedestals on both sides each with a green "$" collect pad; side stairs/pillars for rebirth; pavilions; units on pedestals have rarity-colored auras/outlines, lightning and sparks for rare ones, and a floating nametag stack: Name, Rarity, "1 in X", "$N/s" income. Matches our passive income design.
7. Background depth: giant blocky palms in the foreground, layered mountains/clouds, ocean, distant towers; always at least three depth layers.
8. Heavy VFX language: rarity auras, lightning, sparkles, bursts, outline highlights; something moving or glowing everywhere in view.
9. HUD: bottom bar with three big buttons (Backpack, big ROLL dice with pointer hand, Upgrades), center instruction text ("Place the unit in an empty slot!"), contextual red "Put Back" button, big green money number bottom-left, "Friend Boost" chip, right-side offer stickers with burst rays (OP!, 999x luck, Double Roll), top tabs Hub/Home/Shop.
10. Shop window (reference 7): rainbow-gradient title bar with big red X, blurred background behind the window, dark cards with a colored border per offer, 3D icon overflowing above the card top, big outlined colored title, one-line description, big green Robux price button and a purple gift button next to it (buy for a friend).

## Decisions for Toilet RNG
- Palette + stud-style surfaces + colored shadows on all world geometry.
- Hub: huge sand plaza with curved paths, central giant golden toilet tower, 6-8 stations with billboards and awnings, three leaderboards with crystal pillars, chevron wayfinding, portals to future worlds.
- Plot: large platform with carpet lane, 2 x 5+ pedestals with collect pads and income nametags, frame, pavilions, player's toilet at the head of the lane.
- Everything visible is a Blender mesh from the shared kit; code only assembles, lights and animates.
- Shop/Passes UI: cards with colored borders, overflowing 3D icons, green price + gift buttons (gifting later).
