# UI and visual quality guide

Reference: `docs/reference/quality-reference-1.webp` (a top roll-style Roblox game) and `docs/reference/mockups.png`. Target: this level of polish.

## What makes the reference look professional
1. Chunky buttons: large, rounded, thick dark outline (UIStroke 3-4 px), vertical gradient (light top, saturated bottom), glossy highlight strip, 3D-rendered icon on or beside the label, subtle drop shadow, press/hover scale tween.
2. One dominant main action: big center-bottom button (FLUSH) with an animated hand/pointer and bounce, doubles as mobile action (E does not exist on touch). Secondary buttons flank it (Backpack/Collection, Upgrades).
3. Heavy outlined text: white fill, black stroke 2-3 px, GothamBlack/FredokaOne-like font, slight rotation or pop tween on event texts ("Roll a unit!" style hints, "<Name> found ...!" banners).
4. Left column: big square icon buttons with a short label under the icon (Shop, Rebirth, Index). Top center: tab buttons (Hub / Home / Shop style) for teleports.
5. Offer cards on the right edge: icon, title, price pill, timer, "OP!" sticker; collapses on small screens.
6. Currency: very large green/gold number bottom-left with coin icon; counts up with a tween when it changes.
7. Luck/boost status chips with timers (e.g. "Server Luck x2 04:51").
8. World: strongly saturated palette, colored sky with distant mountains, ocean/water, palm trees, many small props, bloom. Never large flat gray or beige surfaces.

## Asset plan
- Icons (Coin, Shop, Collection, Upgrades, Daily, Teleport, Settings, Flush, Luck, Crown, item icons x11, toilet icons x7): generated as 3D-rendered style PNG (transparent, 256-512 px), uploaded to Roblox as Decals/Images, IDs stored in `src/shared/Config/Assets.luau`.
- 3D meshes: items, toilets and props modelled in Blender (low-poly, saturated), exported and uploaded as MeshParts, IDs in Assets.luau; code builders fall back to primitives when an id is 0 or missing.
- Audio: free Creator Store sounds and generated music, ids in Assets.luau.

## Additional observations (second screenshot of the reference)
- "BEST ROLL EVER" billboard above the plaza showing the server's rarest find with its 1/X odds: map to our server events (best flush of the server, with player name and odds, updated live).
- Large foreground foliage (huge palm trunks and leaves) and long colored shadows give depth; use big props near the spawn, sun angle low-ish for dramatic shadows.
- Portal gates with glowing frames and animated arrow chevrons mark entrances to other areas: use for the future Sewer/Space/Hell worlds ("Coming soon" until implemented).
- Glowing aura effects (purple/blue energy, crystals, sparkles) around special spots and rare things; plazas have tile patterns and colored path strips.
- Offer cards on the right ("More Cash 199", "Jackpot Roll 79", "999x luck") use sticker labels ("OP!"), big outlined numbers and a coin icon; claim indicator with a red count badge on the Daily button.
- Prompt text pulses at screen center ("Roll a unit!") to tell the player what to do next: use for the FLUSH tutorial hint.
