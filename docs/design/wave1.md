# Wave 1 content specification

> Current validation: [full linear luck and regenerated pacing tables](luck-linear.md). Total luck applies in full to every item check, capped at 10x; this supersedes earlier luck formulas and measured balance snapshots below.

Integration update (2026-10-06): [Wave 1 integration](wave1-integration.md) records the actual 47-item/15-toilet implementation, saved-profile behavior and capped balance results. The long proof embedded below is historical: its uncapped cash assumptions do not describe the merged economy. Use [the regenerated production-config proof](wave1-balance.txt). Four conditional targets in the JSON now preserve their historical values separately and reflect the 40x free cash cap.

2026-10-06 · `docs/wave1-spec` · proposal for application **after `feature/permanent` merges**.

**36 new items, four in each of nine rarities; 11 retained items; 47 total. Eight new toilet tiers after Galaxy; 15 total. No mutations, Divine rarity, new worlds, asset uploads or runtime changes.** The requested standalone proof is the only executable addition. No commit or push.

The authoritative proposal is [wave1-data.json](wave1-data.json); this document renders its tables and explains the rules. All coin amounts are base Coins, odds are independent **base checks**, income is Coins/second before toilet/cash factors, and toilet tiers are **1-based**. JSON `Items` contains all 47 items; `New` distinguishes the 36 commissions. `Toilets.Pool` contains additions, not complete pools. Descriptive/model/icon fields are authoring metadata, not fields to blindly insert into runtime item records.

## Decisions and merge boundary

Read against AGENTS.md, GDD and mockup, progression, economy-v2, upgrades, rebirth, reference-analysis, UI style guide, asset manifest and both model sheets, asset/icon pipeline, Items/Rarities/Toilets/Income/Visuals/World/TemplateEffects/Presentation/Audio configs, RollService, and the balance/cohort scripts.

Precedence: this task's owner decisions override historical progression/world proposals; merged permanent-upgrade rules own upgrade/rebirth behavior; economy-v2 remains the source for the existing rarity-income ladder, sales, numeric bounds and income-first philosophy. The old progression document's zero-based numbering, world pools, 50x luck and cheap prices are not Wave 1 inputs.

There is a real timing conflict: economy-v2 measured normal Galaxy at **89.37 minutes** with a 90-minute target; the owner now wants **about 35 minutes**. The parallel branch owns that retune. This proposal neither claims 95M currently buys Galaxy in 35 minutes nor rewrites its price. Tiers 1–7 in JSON are explicitly labeled economy-v2 snapshots for reproducible calculations. Apply their **pool additions only**, retaining the merged price, cooldown, luck and service settings. The proof's post-Galaxy experiment starts at a synthetic minute-35 Galaxy state and therefore cannot validate the first 35 minutes.

The proposal originally used a **5x** luck ceiling and **0.4-second** cooldown floor. Current production caps total luck at **10x**, applying it in full to every item check; the cooldown floor is still **0.4 seconds**. Luck in the regenerated tables is total luck, not an additional factor multiplied by toilet luck.

### Data application recipe

1. Merge permanent upgrades/rebirth first. Append the eight new toilet records in order; keep all existing item and toilet IDs.
2. Import item `Id, Name, Rarity, Chance, Value, Event`; use `Rarities.IncomePerSecond` to populate `Income.RarityRates`. Append pool additions at the exact `FirstToiletTier`. No new selected-world state.
3. New toilet price is `160000000 * 2.5^(tier-8)`, charged as a sequential incremental purchase. Use the table's concrete values when Galaxy's baseline remains 0.8s / 1.3 luck / 12x display.
4. If the merged Galaxy baseline changes, derive new cooldown as `max(mergedFloor, mergedGalaxyCooldown * candidateCooldown / 0.8)`; luck as `min(mergedCap, mergedGalaxyLuck * candidateLuck / 1.3)`; display multiplier as `mergedGalaxyIncome * candidateIncome / 12`. Then replace the proof inputs and rerun; these ratios are a rebase recipe, not permission to skip balance verification. Preserve the merged upgrade formulas and all total caps.
5. Extend parallel per-tier arrays, append art mappings, and apply the rarity presentation/index migration below. Nothing may index a seven-entry array with a tier of 8–15.
6. After integrating the content, rerun the merged fresh-account and rebirth cohorts with actual permanent upgrades, purchased slots, retained displays and all new pools. Recalibrate first-seven prices to the owner's Galaxy target in that branch if needed. Do not copy economy-v2's historical first-session metrics as new results.

## The ladder

Strictly disjoint bands remove the old Mythic/Godly inversion. Gaps between bands are intentional room for future additions. Uncommon stops at 24 so existing Rare Rat at 25 remains strictly beyond it.

| Tier | Order | Base check denominator band | Base income/s | Final item count | Reveal | Chat audience |
|---|---:|---:|---:|---:|---|---|
| Common | 1 | 2–6 | 1 | 5 | Pop | None |
| Uncommon | 2 | 8–24 | 3 | 5 | Pop | None |
| Rare | 3 | 25–120 | 10 | 6 | Burst | None |
| Epic | 4 | 250–900 | 40 | 5 | Sparkle | Friends |
| Legendary | 5 | 1,000–4,500 | 200 | 5 | Banner | Friends |
| Mythic | 6 | 5,000–30,000 | 1,000 | 5 | Banner | Server |
| Godly | 7 | 50,000–250,000 | 6,000 | 6 | Cinematic | Server |
| Celestial | 8 | 300,000–900,000 | 25,000 | 4 | Cinematic | Server |
| Secret | 9 | 1,000,000–unbounded | 100,000 | 6 | Cinematic | Server |

Celestial fills the income gap with **25,000/s** between Godly 6,000/s and Secret 100,000/s. All other rarity rates exactly match economy-v2. Equal-rarity items have equal income; different sale values reward collection without silently making one member a superior income variant. New Common values remain near the existing 80-Coin fallback; most later sale values are approximately 30–40 Coins per base denominator, consistent with the v2 scale. Existing sale values are retained even where retiering makes them exceptions.

### Retained catalog and migration

| Existing ID / name | Proposed rarity | Old → new base denominator | Sale | Income/s | First tier |
|---|---|---:|---:|---:|---:|
| `Poop` / Poop | Common | 2 → 2 | 80 | 1 | 1 |
| `ToiletPaper` / Toilet Paper | Uncommon | 8 → 8 | 280 | 3 | 1 |
| `Rat` / Rat | Rare | 25 → 25 | 1,000 | 10 | 1 |
| `Fish` / Fish | Rare | 80 → 80 | 2,480 | 10 | 1 |
| `Duck` / Duck | Epic | 250 → 250 | 8,000 | 40 | 2 |
| `GoldenPoop` / Golden Poop | Legendary | 1,000 → 1,000 | 30,000 | 200 | 3 |
| `ToiletBaby` / Toilet Baby | Mythic | 5,000 → 5,000 | 150,000 | 1,000 | 4 |
| `SewerShark` / Sewer Shark | Godly | 25,000 → 50,000 | 800,000 | 6,000 | 5 |
| `KingPoop` / King Poop | Godly (was Mythic) | 100,000 → 100,000 | 5,000,000 | 6,000 | 5 |
| `AlienToilet` / Alien Toilet | Secret | 1,000,000 → 1,000,000 | 40,000,000 | 100,000 | 6 |
| `Mystery` / ??? | Secret | 10,000,000 → 10,000,000 | 500,000,000 | 100,000 | 7 |

King Poop keeps its 1:100,000 check and event prestige; its tier becomes Godly and income rises from 1,000 to 6,000/s. Sewer Shark remains Godly but changes 1:25,000 → 1:50,000. Alien Toilet and Mystery remain Secret. Existing unlock tiers remain intact even though early pools can still contain a very rare Secret; toilet ownership is a pool gate, not a rarity guarantee.

Inventory, lifetime collection, protected counts and display assignments are keyed by **item ID**. No rename, deletion, wipe, compensation item or inventory remap is needed. Re-resolve displayed rarity/color/income from current definitions and invalidate cached sort/odds data. Do not reinterpret a cached Secret order of 8 as Celestial: resolve by rarity name/item ID; any persisted derived order must be recomputed. Settle outstanding income at the old rate before an in-session config switch; preferably deploy immutable config with old servers retired. On reconnect, document that the deployed config determines subsequent accrual, including the existing offline settlement policy.

Keep all index claims, permanent cosmetics, FoundingItems and previously granted stamps. A player who claimed `rarity:Mythic` keeps that claim after King Poop moves and the denominator grows. Current completion percentage may decrease as the catalog grows; no reward clawback and no second payment of an old claim. Godly can become claimable under its new membership if its still-unclaimed group is actually complete. Celestial adds a new `rarity:Celestial` group and 22-Stamp completion award. Keep the historical Count=35 milestone and its identity/reward, changing its misleading “Full-index” label to “Veteran index plaque”; add Count=47 with a new cosmetic-only `WaveOneComplete` plaque. Do not move an existing milestone ID from 35 to 47.

### Exact probability rule

Build the cumulative eligible pool. Remove Poop from the tested list, sort by `Chance` descending and then `Id` ascending on a tie. For each candidate, independently test `q_i = min(1, L / X_i)`, stopping on the first success. If all fail, return Poop:

```text
p_i = q_i * product(1 - q_j, for every earlier candidate j)
p_Poop = product(1 - q_j, for all tested candidates j)
sum(p_i) + p_Poop = 1
```

Do not add raw 1/X values and normalize them as weights. Raw checks can sum above one without creating an invalid distribution. There is exactly one item per roll. Poop's legacy Chance=2 is an index/base-label convention; it is **not** a separate 50% test. Label it “Fallback” in odds details and show its actual remaining probability.

“Higher tiers are rarer” is enforced for the **base-check ladder**. A stronger universal claim about final outcome probabilities is mathematically incompatible with the required sequential, clamped luck algorithm: at 5x the 1:5 Common check is certain if reached, so later Common checks and Poop have probability zero. A Rare can also overtake a particular Uncommon after earlier checks absorb probability. The proof does not hide this by asserting monotonic final probabilities. If the owner later requires that stronger rule, it needs a separate RNG-design decision, not different labels alone. Display “Base check 1 in X” separately from “Current outcome chance”; never say every item is exactly L times likelier.

Exactly the existing three `Event=true` items retain the server-luck event effect. New Mythic/Godly/Celestial/Secret items get their rarity announcement/reveal, but **do not** all create extra luck events. This keeps content expansion from silently multiplying event uptime.

## The 36 new characters

Common: familiar one-joke silhouettes. Uncommon: accessories and creature/object mashups. Rare: distinct roles and stronger poses. Epic: dynamic shapes and visual gags. Legendary: chunky gold accents and ceremonial bathroom nonsense. Mythic: larger visual complexity, multiple limbs or a transformation. Godly: powerful red-accented guardians. Celestial: serene white/silver/cyan starlight, halos and constellation motifs. Secret: impossible compositions and conspicuous story hooks, recognizable with particles off.

| ID / display name | Rarity | Base 1:X | Sale Coins | Income/s | First toilet |
|---|---|---:|---:|---:|---|
| `SudsSlug` / Suds Slug | Common | 3 | 90 | 1 | 1: Basic Toilet |
| `PocketPuddle` / Pocket Puddle | Common | 4 | 120 | 1 | 1: Basic Toilet |
| `LoopyLoofah` / Loopy Loofah | Common | 5 | 150 | 1 | 2: Dirty Toilet |
| `SoggySock` / Soggy Sock | Common | 6 | 180 | 1 | 2: Dirty Toilet |
| `TubTadpole` / Tub Tadpole | Uncommon | 10 | 360 | 3 | 1: Basic Toilet |
| `BrushBristle` / Brush Bristle | Uncommon | 14 | 480 | 3 | 2: Dirty Toilet |
| `RollMole` / Roll Mole | Uncommon | 18 | 640 | 3 | 2: Dirty Toilet |
| `CapybaraCap` / Capybara Cap | Uncommon | 24 | 840 | 3 | 3: Golden Toilet |
| `DrainCrab` / Drain Crab | Rare | 35 | 1,200 | 10 | 3: Golden Toilet |
| `ToothpasteGoose` / Toothpaste Goose | Rare | 50 | 1,760 | 10 | 3: Golden Toilet |
| `SpongeKnight` / Sponge Knight | Rare | 100 | 3,200 | 10 | 4: Diamond Toilet |
| `BubbleBeard` / Bubble Beard | Rare | 120 | 4,000 | 10 | 4: Diamond Toilet |
| `PlungerPogo` / Plunger Pogo | Epic | 350 | 11,200 | 40 | 4: Diamond Toilet |
| `BathMatBat` / Bath Mat Bat | Epic | 450 | 14,400 | 40 | 5: Radioactive Toilet |
| `DiscoBidet` / Disco Bidet | Epic | 650 | 20,800 | 40 | 5: Radioactive Toilet |
| `TowelTornado` / Towel Tornado | Epic | 900 | 28,800 | 40 | 6: Demon Toilet |
| `PorcelainPoodle` / Porcelain Poodle | Legendary | 1,500 | 45,000 | 200 | 6: Demon Toilet |
| `FaucetPharaoh` / Faucet Pharaoh | Legendary | 2,200 | 66,000 | 200 | 7: Galaxy Toilet |
| `RoyalFlushFrog` / Royal Flush Frog | Legendary | 3,200 | 96,000 | 200 | 8: Coral Commode |
| `GoldenGargler` / Golden Gargler | Legendary | 4,500 | 135,000 | 200 | 8: Coral Commode |
| `Clogtopus` / Clogtopus | Mythic | 7,500 | 225,000 | 1,000 | 7: Galaxy Toilet |
| `LaundryYeti` / Laundry Yeti | Mythic | 12,000 | 360,000 | 1,000 | 8: Coral Commode |
| `SteamGenie` / Steam Genie | Mythic | 20,000 | 600,000 | 1,000 | 9: Cloud Cushion |
| `BathBombBehemoth` / Bath Bomb Behemoth | Mythic | 30,000 | 900,000 | 1,000 | 9: Cloud Cushion |
| `DrainKraken` / Drain Kraken | Godly | 75,000 | 2,400,000 | 6,000 | 9: Cloud Cushion |
| `GeyserGorilla` / Geyser Gorilla | Godly | 125,000 | 4,000,000 | 6,000 | 10: Clockwork Closet |
| `ThroneColossus` / Throne Colossus | Godly | 180,000 | 5,760,000 | 6,000 | 10: Clockwork Closet |
| `PlungerPaladin` / Plunger Paladin | Godly | 250,000 | 8,000,000 | 6,000 | 11: Dragon Kiln |
| `HaloHamster` / Halo Hamster | Celestial | 300,000 | 12,000,000 | 25,000 | 11: Dragon Kiln |
| `CometCommode` / Comet Commode | Celestial | 450,000 | 18,000,000 | 25,000 | 12: Aurora Throne |
| `ConstellationClam` / Constellation Clam | Celestial | 650,000 | 26,000,000 | 25,000 | 12: Aurora Throne |
| `StarlightSeraph` / Starlight Seraph | Celestial | 900,000 | 36,000,000 | 25,000 | 13: Astral Altar |
| `TheLastToilet` / The Last Toilet | Secret | 1,500,000 | 60,000,000 | 100,000 | 13: Astral Altar |
| `EmergencyUniverse` / Emergency Universe | Secret | 2,500,000 | 100,000,000 | 100,000 | 14: Paradox Potty |
| `InfiniteOccupied` / Infinite Occupied | Secret | 5,000,000 | 200,000,000 | 100,000 | 14: Paradox Potty |
| `CosmicCourtesy` / Cosmic Courtesy | Secret | 15,000,000 | 600,000,000 | 100,000 | 15: Infinity Flush |

### Shared art acceptance

Follow [asset-pipeline.md](../asset-pipeline.md). All briefs are original static toy sculptures, one joined mesh, one material, UV-mapped to the existing ToyPalette atlas. No text-dependent joke, real brand, borrowed character, gore, detailed waste texture or exposed anatomy. Use broad glossy highlights, closed thick components, readable white eyes with dark pupils and a 64px-readable face. No extra moving parts are implied by “comet,” “tornado,” “floating,” “glow” or “disco.”

Sizes below are **target bounding boxes in Roblox X/Y/Z studs**. The largest dimension of every item is 2–3 studs, not necessarily every axis. Individual triangle budgets include face, accessory, undersides and all joined geometry and never exceed 2,500. Minimum height is zero; pivot at the horizontal center of the grounded bounds. Author Z-up/front -Y and export using the existing pipeline's Y-up/Z-forward mapping. Starlight/silver is painted with white, gray and ice, not a new palette swatch or unsupported shader.

All named colors refer to these exact existing atlas values:

| Color | Hex | Color | Hex | Color | Hex | Color | Hex |
|---|---|---|---|---|---|---|---|
| cream | #FFF3D1 | white | #F4FAFF | ink | #19213F | black | #101326 |
| brown | #AE572A | caramel | #DC893C | gold | #FFC51C | goldLight | #FFE67A |
| orange | #FF821E | pink | #FF699F | red | #EF3359 | peach | #FFC098 |
| blue | #278DF1 | cyan | #34DFFF | ice | #A0F0FF | navy | #314B9D |
| purple | #8850EC | violet | #C174FF | magenta | #F74FE7 | mint | #80FFBE |
| green | #26BD54 | lime | #ACF52E | leaf | #10A276 | teal | #078D9C |
| wood | #B66B3C | woodLight | #F3B969 | mud | #76503B | gray | #8499C3 |
| slate | #4C6091 | yellow | #FFE331 | water | #29BCD9 | glow | #DBFFAC |

### Common model briefs

**Suds Slug — `SudsSlug`**

A slug who calls three bubbles a luxury bath.

Model: Long mint bean body with a lifted tail, three white foam lobes down its back, two thick stalk eyes; ink pupils stare in opposite directions and a tiny pink tongue sticks out. One cream soap-chip saddle; no slime transparency. Target size **2.5 × 1.45 × 1.65 studs**; budget **1,500 tris**.

Icon: Show the side curl and all three bubbles; leave a gap between eye stalks.

**Pocket Puddle — `PocketPuddle`**

A spilled puddle proudly wearing its own tiny bucket.

Model: Flat water-blue three-lobed puddle with two stubby splash arms; oversized white eyes and a worried ink mouth on its raised center. An orange upside-down pail with a chunky cream handle is its hat. Target size **2.6 × 1.65 × 2.2 studs**; budget **1,600 tris**.

Icon: Low three-quarter view so the face clears the puddle rim and the bucket handle reads.

**Loopy Loofah — `LoopyLoofah`**

A bath puff that has tied itself in a knot.

Model: Pink squat ball assembled from six broad scalloped lobes, cream loop arch over its head and two peach mitten feet. White oval eyes with ink pupils, one eyebrow higher; broad ink grin. Use solid lobes, no woven microgeometry. Target size **2.3 × 2.5 × 2 studs**; budget **1,800 tris**.

Icon: Frame the hanging loop as a clear empty arch above the pink body.

**Soggy Sock — `SoggySock`**

The missing sock returns with a dramatic wet hairdo.

Model: Bent blue boot-shaped sock, white cuff, orange heel patch, three chunky ice droplets as a forelock and two tiny folded-toe feet. Droopy white eyes with ink pupils and a sideways mouth on the ankle; seams are atlas color blocks. Target size **1.8 × 2.6 × 1.5 studs**; budget **1,400 tris**.

Icon: Turn the bent toe sideways; preserve the silhouette of cuff, heel and forelock.

### Uncommon model briefs

**Tub Tadpole — `TubTadpole`**

A tadpole practicing for the bathtub swimming finals.

Model: Lime pear-shaped head tapering to one wide teal paddle tail; two peach nubs as feet. Huge white eyes with ink pupils behind thick cyan swim-goggle rings, an orange whistle at the neck, pleased ink smile. Target size **2.6 × 1.8 × 2 studs**; budget **1,700 tris**.

Icon: Keep tail on one side and goggles front; whistle is one large accent.

**Brush Bristle — `BrushBristle`**

A toothbrush with bedhead and very serious brushing advice.

Model: Tall teal rounded toothbrush handle with two short arms, cream brush block at top and five oversized white bristle clumps swept like hair. Squinting white eyes and ink pupils on the block; pink toothpaste quiff and orange slippers. Target size **1.6 × 2.8 × 1.2 studs**; budget **1,600 tris**.

Icon: Use front three-quarter framing; five bristle clumps must read as hair at 64px.

**Roll Mole — `RollMole`**

A shy mole who has mistaken a paper tube for a tunnel.

Model: Brown oval mole emerging horizontally from a cream cardboard cylinder; one white paper flap on top and two peach digging paws. Tiny white eyes with ink pupils, round pink nose, one cheek raised; cylinder hole is dark ink geometry. Target size **2.7 × 1.7 × 1.8 studs**; budget **1,900 tris**.

Icon: Show the dark tunnel opening and both paws; paper flap must not cover the nose.

**Capybara Cap — `CapybaraCap`**

A capybara convinced its shower cap is a royal crown.

Model: Caramel rectangular bean body, broad peach muzzle, four stub legs, tiny round ears; enormous pink scalloped shower cap with three white spots. Half-closed white eyes with ink pupils and a relaxed ink smile. No bathrobe or brand markings. Target size **2.7 × 2.1 × 1.6 studs**; budget **2,100 tris**.

Icon: Cap overhang and flat muzzle distinguish it from Rat; use a calm frontal glance.

### Rare model briefs

**Drain Crab — `DrainCrab`**

A crab collecting drain covers like fancy hats.

Model: Orange squat crab shell with six short folded legs, two oversized cream faucet-knob claws and gray domed drain-cover hat. Four broad ink drain slots, white eyes on short stalks, ink pupils and a stubborn grin. Target size **2.8 × 1.8 × 2 studs**; budget **2,200 tris**.

Icon: Raise one knob claw; show the four-slot drain hat without tiny perforations.

**Toothpaste Goose — `ToothpasteGoose`**

A goose honking out one perfectly striped toothpaste curl.

Model: White flattened toothpaste-tube body with cyan stripe, long curved cream goose neck and orange beak; two orange paddle feet and folded white wings. Unequal white eyes with ink pupils; pink-and-mint solid paste curl forms the tail; no label. Target size **2.6 × 2.5 × 1.6 studs**; budget **2,300 tris**.

Icon: Neck and paste tail face opposite sides; stripe must remain visible behind wing.

**Sponge Knight — `SpongeKnight`**

A tiny knight defending the sink from imaginary crumbs.

Model: Yellow beveled rectangular sponge body with six dark caramel inset-looking spots painted by atlas patches. Gray bucket helmet with open face, blue dish-brush lance, round cream soap-dish shield. Large determined white eyes with ink pupils; peach mitten hands. Target size **2.4 × 2.7 × 1.5 studs**; budget **2,200 tris**.

Icon: Shield left and brush lance right; leave the sponge face exposed.

**Bubble Beard — `BubbleBeard`**

A soap bar whose magnificent foam beard is mostly air.

Model: Cream squat rectangular soap head over a triangular beard made of seven white foam lobes. Mint towel turban, peach slippers, two raised white eyes with ink pupils and a tiny ink smile above the beard. One pink comb tucked sideways into the foam. Target size **2.2 × 2.6 × 1.8 studs**; budget **2,100 tris**.

Icon: Keep the triangular beard and horizontal comb legible; avoid merging with a white background.

### Epic model briefs

**Plunger Pogo — `PlungerPogo`**

A plunger that insists it is a champion pogo stick.

Model: Red bell-shaped suction cup foot with a wood shaft, purple rounded spring sleeve and two cyan handlebar arms. Two enormous white eyes with ink pupils attach to the shaft below an orange crash helmet; ink grin on helmet rim, no thin real spring. Target size **2.2 × 2.9 × 1.6 studs**; budget **2,000 tris**.

Icon: Capture a tilted pogo stance while keeping the suction cup fully in frame.

**Bath Mat Bat — `BathMatBat`**

A bath mat trying to become a bat before laundry day.

Model: Purple folded rectangular mat body with two scalloped towel wings, pink broad underside panels and cream hem. White eyes with ink pupils above two tiny cream felt fangs, orange clothespin nose; no fabric fibers. Target size **3 × 1.8 × 1.1 studs**; budget **1,800 tris**.

Icon: Wings form a wide zigzag outline; eyes and clothespin must clear the central fold.

**Disco Bidet — `DiscoBidet`**

A pocket bidet hosting a dance party for exactly one.

Model: White hemispherical mini-bidet bowl on two blue platform shoes, short gray nozzle shaped like a microphone and pink rounded rectangular visor with two white eye ovals and ink pupils. Six large cyan/purple checker panels on tank; one raised gold glove. Target size **2.4 × 2.5 × 2 studs**; budget **2,400 tris**.

Icon: Show both shoes and the microphone nozzle; use one static cyan sparkle, no bloom washout.

**Towel Tornado — `TowelTornado`**

A rolled towel spinning furiously to avoid being folded.

Model: Mint tapered spiral formed by three thick folded towel bands, cream hems, orange bath-slipper base and a pink towel corner sticking out like a flag. White eyes with ink pupils and a dizzy offset ink mouth on the upper band. Target size **2.3 × 2.8 × 2 studs**; budget **2,300 tris**.

Icon: Keep the flag corner separate from the spiral and the slipper visible below.

### Legendary model briefs

**Porcelain Poodle — `PorcelainPoodle`**

A poodle made of porcelain who refuses to get its paws wet.

Model: White toy poodle assembled from a teapot-like round chest, four thick gold-cuffed legs and three spherical white fur puffs. Cream faucet spout snout, gold curled tail and pink bow. Large white eyes with ink pupils edged in gray, prim ink smile. Target size **2.7 × 2.5 × 1.6 studs**; budget **2,400 tris**.

Icon: Profile shows the faucet snout and curled tail; gold cuffs must contrast with white body.

**Faucet Pharaoh — `FaucetPharaoh`**

A faucet ruler who commands precisely one drip at a time.

Model: Gold inverted-U faucet body on a wide pedestal, blue-and-gold striped fan headdress, two chunky cross-handle arms and a cyan solid water-drop beard. White eyes with ink pupils beneath the headdress, confident ink smile; no historical symbols copied. Target size **2.6 × 2.9 × 1.6 studs**; budget **2,400 tris**.

Icon: Front three-quarter view exposes the arch hole, fan crown and drop beard.

**Royal Flush Frog — `RoyalFlushFrog`**

A frog surveying its kingdom from a golden toilet seat.

Model: Green pear-bodied frog sitting within a gold oval seat ring; two wide webbed feet, puffed cheeks, cream belly and three-point goldLight crown tipped with pink balls. Tall white eyes with ink pupils and a content ink smile; no toilet bowl body. Target size **2.8 × 2.5 × 2 studs**; budget **2,300 tris**.

Icon: Seat ring stays visibly open around the frog; crown is broad rather than tall.

**Golden Gargler — `GoldenGargler`**

A mouthwash cup warming up for a very bubbly opera.

Model: Gold tapered rinsing cup with broad goldLight rim, two blue mitten arms, purple bow tie and cream feet. White eyes with ink pupils sit on rim above an open ink singing mouth; three cyan bubble spheres arc over one side. Target size **2.3 × 2.8 × 1.8 studs**; budget **2,100 tris**.

Icon: Open singing mouth and three-bubble arc carry the joke; no readable product label.

### Mythic model briefs

**Clogtopus — `Clogtopus`**

An octopus with eight plungers and no idea which drain is blocked.

Model: Magenta dome head with eight thick curled purple tentacles ending in red suction-cup bells. White eyes with ink pupils, raised brow and tiny worried mouth; cream plumber cap and one gold wrench held in the front tentacle. Use six-sided tube sections. Target size **3 × 2.5 × 2.5 studs**; budget **2,500 tris**.

Icon: Three-quarter overhead view separates all eight cup tips; the front wrench stays large.

**Laundry Yeti — `LaundryYeti`**

A shaggy laundry monster terrified of a single missing sock.

Model: White trapezoid body built from six large towel tufts, cyan face panel, huge peach mitten hands and purple slipper feet. Wide white eyes with ink pupils and open worried mouth; pink sock stuck to head, gray laundry-basket belt with four broad openings. Target size **2.8 × 2.9 × 2 studs**; budget **2,400 tris**.

Icon: Broad shoulders, basket belt and lone pink sock are the three readable landmarks.

**Steam Genie — `SteamGenie`**

A steam genie offering three wishes and one warm towel.

Model: Violet bulb upper body tapering into a single white steam curl rooted in a teal bath tap. Two large floating-looking but joined sleeves, gold cuff bands and cream towel turban. White eyes with ink pupils, curled pink eyebrow strips and a wide ink grin. Target size **2.8 × 2.9 × 1.8 studs**; budget **2,400 tris**.

Icon: Use an S-shaped silhouette with a clearly visible tap base; sleeves leave negative space.

**Bath Bomb Behemoth — `BathBombBehemoth`**

A giant bath bomb patiently waiting to become a tiny fizz.

Model: Magenta faceted sphere body with four chunky mint stone-like feet, violet shoulder fins and cream fizz-cloud crown of five lobes. Tiny white eyes with ink pupils beside an absurdly small ink smile; gold bath scoop tucked under one arm. Target size **2.8 × 2.8 × 2.6 studs**; budget **2,200 tris**.

Icon: Very round heavy body and tiny face; keep scoop separate from the feet.

### Godly model briefs

**Drain Kraken — `DrainKraken`**

A drain guardian pulling six entire pipes out of its hat.

Model: Red armored pear head above six navy squared pipe-loop tentacles with orange flanged ends. Gray drain-cover crown, gold handlebar mustache, two white eyes with ink pupils and theatrical ink scowl. Mouth is toothless; broad red shell plates, no gore. Target size **3 × 2.8 × 2.5 studs**; budget **2,500 tris**.

Icon: Six angular pipe arms distinguish it from round Clogtopus; crown sits fully above eyes.

**Geyser Gorilla — `GeyserGorilla`**

A gorilla powered by shower pressure and spectacular bad hair.

Model: Navy trapezoid torso, oversized red barrel forearms, gray knuckle pads, peach flat muzzle and two thick squat legs. Three cyan solid water jets form a crown; white eyes with ink pupils under heavy brows, pleased ink grin; orange shower-knob belt. Target size **2.9 × 3 × 2 studs**; budget **2,500 tris**.

Icon: Low camera emphasizes square fists and three water spikes; keep the friendly grin visible.

**Throne Colossus — `ThroneColossus`**

A walking bathroom throne politely asking where to sit.

Model: White blocky cistern chest on two red pedestal legs; thick gray pipe arms ending in gold seat-shaped fists, navy lid shoulder armor. Two white eyes with ink pupils in a black visor, tiny courteous ink smile; red triangular cape fixed to back. Target size **2.8 × 3 × 2 studs**; budget **2,450 tris**.

Icon: Broad square shoulders and two ring fists must remain distinct; cape shows as one red wedge.

**Plunger Paladin — `PlungerPaladin`**

A solemn plunger knight sworn to protect the last clean tile.

Model: Red bell-shaped helmet over a gold cylindrical torso, white rectangular tile shield, gray pipe boots and long wood staff with a gold suction cup tip. Two luminous-looking ice eyes with ink pupils in helmet opening, cheerful white moustache; three red crest fins. Target size **2.6 × 3 × 1.8 studs**; budget **2,400 tris**.

Icon: Tile shield, cup helmet and upright cup staff form three different-sized silhouettes.

### Celestial model briefs

**Halo Hamster — `HaloHamster`**

A starry hamster using a halo as an emergency towel rail.

Model: White round hamster, gray silver-painted cheek patches, cream mitten feet and tiny cyan star nose. Two large white eyes with ink pupils, soft ink smile; horizontal ice torus halo supports a folded cyan towel, three star studs on belly. Target size **2.5 × 2.8 × 2 studs**; budget **2,300 tris**.

Icon: Halo hole and hanging towel must read at 64px; face stays darker than white fur.

**Comet Commode — `CometCommode`**

A miniature toilet comet always late for its own orbit.

Model: White egg-shaped bowl with a gray silver tank, thin cyan seat rim and tapered three-prong ice comet tail curling up behind it. White eyes with ink pupils on tank, surprised ink mouth; one tilted white halo around tail root, five blue constellation dots. Target size **2.9 × 2.6 × 2 studs**; budget **2,400 tris**.

Icon: Side three-quarter framing makes the long three-prong tail and bowl opening unmistakable.

**Constellation Clam — `ConstellationClam`**

A cosmic clam polishing a pearl shaped suspiciously like soap.

Model: Open two-fan white clam shells with gray silver ribs and ice edges, cyan soap-bar pearl inside. Pearl has white eyes with ink pupils and a smug ink grin; five thick cyan constellation links on upper shell and a white halo above the hinge. Target size **2.9 × 2.5 × 2 studs**; budget **2,400 tris**.

Icon: Keep shell gap dark enough to outline the soap pearl; five-point constellation is large.

**Starlight Seraph — `StarlightSeraph`**

A six-winged towel angel assigned to the night-shift hand dryer.

Model: White folded towel body with six broad fan wings in three stacked pairs, gray silver hem blocks, cyan belt and ice ring halo. Two large cyan eye disks with ink pupils and tiny ink smile; constellation stars as three white raised diamonds. No religious symbols. Target size **3 × 2.9 × 1.8 studs**; budget **2,500 tris**.

Icon: Six separated wing tips and one clean halo; cyan waist gives a focal point without gold.

### Secret model briefs

**The Last Toilet — `TheLastToilet`**

The final bathroom in the universe has a very nervous door attendant.

Model: Black squat toilet bowl beneath a broken-looking but solid white arch, thick magenta inner portal rim and gold star-shaped flush handle. Two white eyes with ink pupils peek over rim, alarmed pink mouth; three cyan floating-look tiles connect behind with hidden thick struts. Target size **2.8 × 3 × 2.3 studs**; budget **2,500 tris**.

Icon: White arch frames the dark bowl; show three suspended tiles and enormous star handle.

**Emergency Universe — `EmergencyUniverse`**

An emergency bathroom cabinet containing one spare universe.

Model: Red rounded cabinet box opened at a fixed angle on cream feet; black circular interior with cyan and gold spiral galaxy bands, violet orb planets. Cabinet has huge white eyes with ink pupils and a panicked ink mouth above opening; white plunger symbol, no medical cross. Target size **2.7 × 2.9 × 2 studs**; budget **2,500 tris**.

Icon: Open door to the left; visible galaxy fills the right two-thirds without particle haze.

**Infinite Occupied — `InfiniteOccupied`**

An occupied sign guarding a door inside a door inside a door.

Model: Three nested navy rounded doorframes, alternating pink and cyan rims, shrinking toward one black center. Front frame has two huge white eyes with ink pupils and a sheepish white smile; red oval status plaque, orange slipper feet. No text required on mesh. Target size **2.4 × 3 × 1.8 studs**; budget **2,300 tris**.

Icon: Front perspective shows all three nested openings; red plaque reads as a bold oval, no tiny letters.

**Cosmic Courtesy — `CosmicCourtesy`**

A tiny gloved hand giving the entire universe one last courtesy flush.

Model: Black spherical micro-universe split by a broad gold toilet-seat orbit; giant white glove presses a red flush lever on the side, cyan crescent grin and two white star eyes with ink pupils on sphere. Three thick magenta comet ribbons arch behind; no detached thin geometry. Target size **3 × 2.9 × 2.7 studs**; budget **2,500 tris**.

Icon: Glove, lever and golden orbit are the hero shapes; show the grin between the rings.

## Eight new permanent toilets

Every toilet is a sequential purchase and remains owned and equipped through rebirth. All previous pools stay unlocked. Ownership does not require a particular item, a new world, a paid product or a rebirth reset.

Cooldown multipliers below are relative to the unupgraded Basic baseline of 1.5s. Apply the merged Flush Speed and rebirth reductions afterward, with the authoritative 0.4s floor. Luck is the toilet's base factor before merged upgrades/events; clamp **total** luck to 5x. Display multipliers affect all placed items and use the existing cash factor, not a new multiplicative upgrade track.

| Tier / ID | Name / theme | Incremental price | Target cumulative active minutes | Cooldown factor / seconds | Toilet luck | Display income | Service/flush |
|---|---|---:|---:|---|---:|---:|---:|
| 8 / `CoralCommode` | Coral Commode: A reef throne assembled by overenthusiastic bathtub crabs. | 160,000,000 | 85 | 0.506667 / 0.76s | 1.40x | 18x | 6,500 |
| 9 / `CloudCushion` | Cloud Cushion: A plush sky bathroom with a permanently fluffy seat. | 400,000,000 | 130 | 0.480000 / 0.72s | 1.50x | 27x | 9,000 |
| 10 / `ClockworkCloset` | Clockwork Closet: An absurdly punctual brass bathroom. | 1,000,000,000 | 175 | 0.453333 / 0.68s | 1.60x | 40x | 12,500 |
| 11 / `DragonKiln` | Dragon Kiln: A ceramic dragon warming the seat just a little too proudly. | 2,500,000,000 | 225 | 0.426667 / 0.64s | 1.70x | 60x | 23,000 |
| 12 / `AuroraThrone` | Aurora Throne: A frosty seat under a tiny indoor northern sky. | 6,250,000,000 | 285 | 0.400000 / 0.60s | 1.80x | 90x | 35,000 |
| 13 / `AstralAltar` | Astral Altar: A starlit porcelain shrine to immaculate plumbing. | 15,625,000,000 | 365 | 0.373333 / 0.56s | 1.90x | 135x | 70,000 |
| 14 / `ParadoxPotty` | Paradox Potty: A bathroom doorway folded around the wrong side of itself. | 39,062,500,000 | 460 | 0.346667 / 0.52s | 2.00x | 200x | 105,000 |
| 15 / `InfinityFlush` | Infinity Flush: An endless cosmic flushing machine that still needs a handle. | 97,656,250,000 | 570 | 0.320000 / 0.48s | 2.10x | 300x | 155,000 |

Targets are rounded design targets with a ±20% **conditional cohort** tolerance. The first new toilet is targeted well after Galaxy's owner target of 35 minutes; the last is about 9.5 hours of cumulative active play. See the measured conditional p50/p90 output below. They exclude offline time/grants, paid boosts, events, further upgrades and rebirths; strong rare discoveries, permanent rebirth bonuses or offline balances can shorten the path. They are not hard time gates or guaranteed acquisition times.

### Pool additions, including early tiers

| Tier / toilet | Existing additions retained | New additions |
|---|---|---|
| 1: Basic Toilet | `Poop`, `ToiletPaper`, `Rat`, `Fish` | `SudsSlug`, `PocketPuddle`, `TubTadpole` |
| 2: Dirty Toilet | `Duck` | `LoopyLoofah`, `SoggySock`, `BrushBristle`, `RollMole` |
| 3: Golden Toilet | `GoldenPoop` | `CapybaraCap`, `DrainCrab`, `ToothpasteGoose` |
| 4: Diamond Toilet | `ToiletBaby` | `SpongeKnight`, `BubbleBeard`, `PlungerPogo` |
| 5: Radioactive Toilet | `SewerShark`, `KingPoop` | `BathMatBat`, `DiscoBidet` |
| 6: Demon Toilet | `AlienToilet` | `TowelTornado`, `PorcelainPoodle` |
| 7: Galaxy Toilet | `Mystery` | `FaucetPharaoh`, `Clogtopus` |
| 8: Coral Commode | — | `RoyalFlushFrog`, `GoldenGargler`, `LaundryYeti` |
| 9: Cloud Cushion | — | `SteamGenie`, `BathBombBehemoth`, `DrainKraken` |
| 10: Clockwork Closet | — | `GeyserGorilla`, `ThroneColossus` |
| 11: Dragon Kiln | — | `PlungerPaladin`, `HaloHamster` |
| 12: Aurora Throne | — | `CometCommode`, `ConstellationClam` |
| 13: Astral Altar | — | `StarlightSeraph`, `TheLastToilet` |
| 14: Paradox Potty | — | `EmergencyUniverse`, `InfiniteOccupied` |
| 15: Infinity Flush | — | `CosmicCourtesy` |

### Toilet model briefs and effects

Reuse the existing foot-centered pivot at ground Y=0, **seat center Y=2.08 studs**, core lid top Y=4.79 studs and the existing bowl/seat geometry. Decorations change bounds, not seat height. Never normalize all toilets to the same overall bounding-box height. Preserve the foot datum when importing and when creating MeshCatalog centers. All models remain one static joined mesh, one atlas material, at most 5,000 triangles; decorative loops must be thick, attached and non-colliding.

Use at most one local light and one low-rate emitter per special model, matching the current VisualIdle contract: 3 particles/s while nearby, up to 24 per bounded burst; reduced/off settings and distance culling stay authoritative. “Aura” is a color treatment around that toilet, not a new global sky effect. All geometry must read with VFX disabled.

**Tier 8: Coral Commode — `CoralCommode`**

Model: White standard bowl with orange branch-coral armrests, teal scalloped shell lid and three cream pearl knobs on tank; two gray shell ridges frame a cyan water disk. Six thick coral tips, no fine branches; no face on toilet. Target bounds **3.6 × 5 × 3.2 studs**; budget **4,600 tris**.

Effects: Bubble glints at bowl; soft water-blue aura. Body accent: orange (#FF821E); aura: water (#29BCD9).

Icon: Keep the orange branching arms separate from the scalloped teal lid.

**Tier 9: Cloud Cushion — `CloudCushion`**

Model: White bowl nested in three broad cloud lobes at the foot, blue tank shaped as a stepped raincloud, ice padded oval lid and cyan droplet handle. GoldLight towel ring on one side; lid has a white smiling cloud motif with ink closed eyes. Target bounds **3.7 × 5.1 × 3.3 studs**; budget **4,300 tris**.

Effects: Slow ice motes; pale blue halo at cloud base. Body accent: white (#F4FAFF); aura: ice (#A0F0FF).

Icon: Low three-quarter view preserves cloud foot and stepped tank silhouette.

**Tier 10: Clockwork Closet — `ClockworkCloset`**

Model: Gold and woodLight square cabinet tank surrounding the standard white oval bowl; large navy clock disk behind the raised lid, three thick gold gear teeth on each side, red plunger pendulum fixed at back. Cream clock hands; no numbers needed, no movable parts. Target bounds **3.7 × 5.2 × 3.3 studs**; budget **4,800 tris**.

Effects: Sparse warm gear-like sparkles using existing sparkle texture; amber bowl glow. Body accent: gold (#FFC51C); aura: orange (#FF821E).

Icon: Expose clock hands above the oval seat and the red pendulum on one side.

**Tier 11: Dragon Kiln — `DragonKiln`**

Model: Red kiln bowl on black three-lobed foot, orange scaled dragon tail wrapping outside the pedestal, white oval seat unchanged. Two broad red wings behind the standard-height lid and a friendly dragon head atop tank; cream horns, white eyes with ink pupils, toothless grin. Target bounds **3.8 × 5.3 × 3.4 studs**; budget **5,000 tris**.

Effects: Low-rate embers, red-orange rim light; no flame occlusion of the seat. Body accent: red (#EF3359); aura: orange (#FF821E).

Icon: Dragon head, two broad wings and curled tail remain outside bowl opening.

**Tier 12: Aurora Throne — `AuroraThrone`**

Model: White porcelain core and gray silver-painted foot; three thick folded fan panels in ice, mint and cyan rise behind the unchanged oval lid, each ending in a different stepped height. Blue faceted side buttresses and one cyan star knob; opaque panels, no transparent sheets. Target bounds **3.8 × 5.4 × 3.3 studs**; budget **4,700 tris**.

Effects: Slow cyan/mint star motes with static ice rim glow. Body accent: white (#F4FAFF); aura: mint (#80FFBE).

Icon: Three different-height fan panels form the silhouette; avoid Galaxy's circular orbit.

**Tier 13: Astral Altar — `AstralAltar`**

Model: White standard bowl on a gray silver six-sided plinth; two thick white crescent columns behind tank hold a cyan halo above the 4.79-stud lid. Ice inlaid five-point constellation on lid, gray stepped arms and white star handle. No gold, red, symbols or thin floating pieces. Target bounds **3.7 × 5.5 × 3.3 studs**; budget **4,900 tris**.

Effects: White/cyan starlight, one slow halo shimmer; reduced mode keeps static constellation. Body accent: white (#F4FAFF); aura: cyan (#34DFFF).

Icon: Crescent columns and high halo frame the white lid; dark icon shadow preserves edges.

**Tier 14: Paradox Potty — `ParadoxPotty`**

Model: Black bowl with white seat, three thick navy offset rectangular doorframes behind tank, alternating magenta/cyan inset edges. A gold upside-down faucet handle hangs from the smallest frame; cream stepped pedestal remains grounded. Nested frames are joined at back, no actual portals. Target bounds **3.8 × 5.4 × 3.4 studs**; budget **4,800 tris**.

Effects: Sparse violet/cyan particles; magenta portal-edge glow. Body accent: black (#101326); aura: magenta (#F74FE7).

Icon: Offset rectangular frames must show three distinct apertures and the upside-down handle.

**Tier 15: Infinity Flush — `InfinityFlush`**

Model: White bowl on a black hourglass pedestal; two thick gold and cyan elliptical infinity loops rise behind and beside the standard lid, crossing above tank. Purple starfield tank inset, magenta lever with oversized white glove finial. All loops joined, widest decoration at back. Target bounds **4 × 5.5 × 3.5 studs**; budget **5,000 tris**.

Effects: Alternating cyan/gold stars, restrained violet aura; no screen-wide idle effect. Body accent: black (#101326); aura: cyan (#34DFFF).

Icon: Both infinity loops and white glove must fit inside the frame; bowl remains the anchor.

### Rebirth interplay

Use this table to gate the **next** rebirth level. Existing saved levels never decrease; raised requirements apply only to the next action. Retain the merged permanent branch's toilet/upgrade reset contract, protection rules, exact display slots and cash/luck/speed caps. The toilet tier and its cumulative pool never reset. Keep the merged fresh-flush requirement; the snapshot baseline is 3,300 new successful flushes, so its minimum at the 0.4s floor is still 22 minutes. No rare-item sacrifice, extra fee or forced toilet repurchase.

| Next rebirth level | Minimum permanent toilet |
|---:|---|
| 1 | 4: Diamond Toilet |
| 2 | 5: Radioactive Toilet |
| 3 | 6: Demon Toilet |
| 4 | 7: Galaxy Toilet |
| 5 | 8: Coral Commode |
| 6 | 8: Coral Commode |
| 7 | 9: Cloud Cushion |
| 8 | 9: Cloud Cushion |
| 9 | 10: Clockwork Closet |
| 10 | 10: Clockwork Closet |
| 11 | 11: Dragon Kiln |
| 12 | 12: Aurora Throne |
| 13 | 13: Astral Altar |
| 14 | 14: Paradox Potty |
| 15 | 15: Infinity Flush |

The repeated tier gates at levels 5–6, 7–8 and 9–10 allow a second prestige goal while saving for a larger next toilet purchase. Levels 11–15 each require the next late toilet. These are eligibility inputs, not a simulation claiming the old reset-era first/second rebirth times still apply. The parallel branch must expose a per-next-level requirement lookup in both server eligibility and UI.

### Rate/storage and other per-tier arrays

Populate `Income.TierMultipliers` through tier 15. For each tier, `SlotRateCaps[t] = 60 * 100000 * multiplier[t]` Coins/minute and `PlayerRateCaps[t] = 10 * SlotRateCaps[t]`; merged cash factors then scale both, as before. The JSON includes concrete caps. Do not leave late arrays missing: IncomeAccrual would otherwise treat their rate as zero.

Preserve 6,000 subcoins/Coin, 9e15 integer-subcoin global ledger maximum and 9e15-Coin wallet/Earned maximum. Keep the existing pending caps and tank rules in this wave; do not silently enlarge storage to promise twelve hours at arbitrary rates. At tier 15, ten Secrets earn 300M/s before cash, reaching the **global** 1.5T-Coin storage ceiling in 83.33 online minutes; at the cash hard cap 10x, that is 8.33 minutes. Per-slot pending caps can bind earlier. These global-ceiling figures are upper bounds on storage duration, not guaranteed time until full. Offline accrual uses the merged offline factor and the same storage caps. Keep capacity/remaining-storage feedback visible.

Extend `Rewards.TierMultipliers` to 15 entries, holding tiers 8–15 at **64**, the existing Galaxy multiplier. This prevents daily-reward indexing errors without inventing an exponentially growing extra source. These values also appear per toilet in JSON. No new audio or world systems are tied to those tiers.

## Celestial presentation and integration inventory

Proposed data for `src/shared/Config/Rarities.luau` (specification only):

```luau
Godly = { Order = 7, Color = Color3.fromRGB(240, 50, 50) },
Celestial = { Order = 8, Color = Color3.fromRGB(160, 240, 255) },
Secret = { Order = 9, Color = Color3.fromRGB(20, 20, 20) },
```

Celestial's primary UI color is **#A0F0FF** (icy cyan), with **#F4FAFF** white, **#8499C3** painted silver and **#34DFFF** cyan accent. Use a dark navy backing/outline for legibility. Godly stays red, Secret stays black with the existing purple/rainbow contrast treatment. The palette is cosmic and haloed; it introduces no Divine rarity.

- Chat to the whole server for **Mythic, Godly, Celestial and Secret**, respecting existing preferences, cooldown, TTL, replay suppression and queue bounds. Epic/Legendary retain friends announcements.
- Celestial gets the **Cinematic** full-screen reveal like Godly/Secret, with its own white/cyan rays and constellation/halo motif. Keep the existing 3s cinematic budget and bounded queue; reveals do not delay server flush cooldown. Reduced gives the existing compact Pop and Off gives Toast.
- Collection/index filter order is Common, Uncommon, Rare, Epic, Legendary, Mythic, Godly, **Celestial**, Secret. Celestial group total is four; overall denominator is 47. Counts are generated from Items, not a hardcoded count of eight rarity groups.
- Reuse the existing **Godly** sound file for Celestial. Because current callers use `audio:Play(item.Rarity)`, add a **logical Celestial alias** in both Audio.Cues and Assets.Sounds, copying Godly's current cue settings and uploaded ID by reference at config construction. This is one new mapping, **zero new sound uploads/files**. Alternatively a centralized cue resolver can read the JSON AudioCue mapping; do not modify every callsite independently.

The following inventory is based on the current worktree's rarity-name/order and tier-array search. Re-scan after the parallel merge; file names below are current paths, not a claim that dynamic consumers each need hardcoded Celestial branches.

| Apply/change file | Required action |
|---|---|
| `src/shared/Config/Rarities.luau` | Add Celestial Order 8 and move Secret to 9; RGB above. |
| `src/shared/Config/Items.luau` | Append 36 entries; change King Poop rarity and Sewer Shark odds; preserve IDs, legacy values/events. |
| `src/shared/Config/Toilets.luau` | Add pools at all 15 tiers and append eight new tier records; preserve merged first-seven pacing. |
| `src/shared/Config/Income.luau` | Add Celestial=25000; extend multiplier and both rate-cap arrays. |
| `src/shared/Config/IndexRewards.luau` | Extend explicit RarityOrder and RarityStamps, keep FoundingItems/claims; 35-label/47-milestone change above. |
| `src/shared/PresentationRules.luau` | Explicit reveal tier map and Audience whitelist both need Celestial. |
| `src/shared/Config/Audio.luau` | Add Celestial cue alias to Godly settings, preserving voice/gain bounds. |
| `src/shared/Config/Assets.luau` | Celestial sound alias, 36 ItemIcons, eight ToiletIcons and real approved mesh/texture/model references. |
| `src/shared/Config/World.luau` | Add 36 ItemColors and extend seven-entry ToiletColors to 15 using palette. |
| `src/shared/Config/Visuals.luau` | Extend ToiletMaterials to 15; use SmoothPlastic atlas surfaces for new opaque toy models, accents provide glow. |
| `src/shared/Config/TemplateEffects.luau` | Add new toilet effect records and Celestial/Secret item accents, reusing sparkle texture and existing effect budgets. |
| `src/shared/Config/MeshCatalog.luau` | Add all 44 model records with measured imported bounds/tris and toilet Center datum. Targets here are not measured exports. |
| `src/shared/Config/WorldModels.luau` | Extend ToiletNames in exact tier order; add explicit item/model mappings if needed (new item IDs already match stems). |
| `src/shared/Visuals/Items.luau`, `src/shared/Visuals/Toilets.luau` | Ensure all new IDs/tiers have safe recognizable primitive/text fallback; currently toilet decoration branches end at tier 7. |
| `src/shared/Config/Rewards.luau` | Extend TierMultipliers with eight 64 entries. |
| `src/shared/Config/Rebirth.luau`, `src/shared/RebirthRules.luau`, `src/client/UI/Rebirth.luau` | Apply per-next-level minimum tier data/lookup after permanent branch; preserve permanent toilets and server/client agreement. |
| `src/server/Services/RollService.luau` | Add stable ID tie-break and explicit Poop-last handling when applying proposal; retain independent rare-first checks and authoritative callers. |
| `src/client/Presentation/RevealController.luau` | Wire a Celestial-specific palette/motif if cinematic visuals are not yet data-driven; keep intensity/queue behavior. |
| `assets/blender/builders.py`, `build.py`, icon render mapping; manifests and ModelTemplates | Future art branch: register/build/import 44 new models and icons using pipeline. No changes in this spec worktree. |

Dynamic consumers to verify, with **no new rarity enumeration required**: `src/shared/IndexProgress.luau`, `IncomeAccrual.luau`, `PresentationSettings.luau`; `src/client/UI/Collection.luau`, `IndexRewards.luau`, `Reveal.luau`, `Upgrades.luau`; `src/client/Effects.luau`, `Presentation/ChatAnnouncements.luau`, `Audio/AudioService.luau`; `src/server/Services/AnnouncementService.luau`, `DataService.luau`, `IncomeService.luau`; and `src/server/World/Models.luau`, `WorldService.luau`, `DisplayRows.luau`, `RebirthStairs.luau`. Their current order thresholds or Secret-specific contrast are intentional; do not replace every “Secret” occurrence with Celestial. Check collection scrolling and all 15 shop cards on phone.

Explicit fixtures/enumerations to extend in the implementation branch: `scripts/balance.luau`'s rarity list and seven-stage targets; `income-balance.luau`, `economy-cohort.luau`, `display-cohort.luau`; `check-presentation.luau`, `presentation-audit.luau`, `presentation-ui-checks.luau`, `audit-chat-native.luau`; `check-audio.luau`, `audio-coverage-checks.luau`; `check-economy-v2.luau`, `audit-economy-v2.luau`; index, rebirth, upgrade, visual, world and UI tests that assume 11 items/seven toilets/eight rarities. Audio build/contact-sheet scripts may keep eight **distinct source recordings**; annotate the alias rather than commissioning a ninth recording. No change to `Config/Events` tints is required while Event flags remain legacy-only.

## Asset production plan: exactly 44 commissions

Every row below names one Blender model. New model stem equals ID for both items and toilets, unlike legacy Duck → RubberDuck and Basic → BasicToilet aliases, which stay intact. For each stem produce editable `assets/blender/generated/<ID>.blend`, the listed FBX, front/three-quarter previews and validated imported template. No models or icons are built in this task.

| Model ID | FBX file | 512px icon file | Config icon key |
|---|---|---|---|
| `SudsSlug` | `assets/models/items/SudsSlug.fbx` | `assets/icons/items/SudsSlug_512.png` | `Assets.ItemIcons.SudsSlug` |
| `PocketPuddle` | `assets/models/items/PocketPuddle.fbx` | `assets/icons/items/PocketPuddle_512.png` | `Assets.ItemIcons.PocketPuddle` |
| `LoopyLoofah` | `assets/models/items/LoopyLoofah.fbx` | `assets/icons/items/LoopyLoofah_512.png` | `Assets.ItemIcons.LoopyLoofah` |
| `SoggySock` | `assets/models/items/SoggySock.fbx` | `assets/icons/items/SoggySock_512.png` | `Assets.ItemIcons.SoggySock` |
| `TubTadpole` | `assets/models/items/TubTadpole.fbx` | `assets/icons/items/TubTadpole_512.png` | `Assets.ItemIcons.TubTadpole` |
| `BrushBristle` | `assets/models/items/BrushBristle.fbx` | `assets/icons/items/BrushBristle_512.png` | `Assets.ItemIcons.BrushBristle` |
| `RollMole` | `assets/models/items/RollMole.fbx` | `assets/icons/items/RollMole_512.png` | `Assets.ItemIcons.RollMole` |
| `CapybaraCap` | `assets/models/items/CapybaraCap.fbx` | `assets/icons/items/CapybaraCap_512.png` | `Assets.ItemIcons.CapybaraCap` |
| `DrainCrab` | `assets/models/items/DrainCrab.fbx` | `assets/icons/items/DrainCrab_512.png` | `Assets.ItemIcons.DrainCrab` |
| `ToothpasteGoose` | `assets/models/items/ToothpasteGoose.fbx` | `assets/icons/items/ToothpasteGoose_512.png` | `Assets.ItemIcons.ToothpasteGoose` |
| `SpongeKnight` | `assets/models/items/SpongeKnight.fbx` | `assets/icons/items/SpongeKnight_512.png` | `Assets.ItemIcons.SpongeKnight` |
| `BubbleBeard` | `assets/models/items/BubbleBeard.fbx` | `assets/icons/items/BubbleBeard_512.png` | `Assets.ItemIcons.BubbleBeard` |
| `PlungerPogo` | `assets/models/items/PlungerPogo.fbx` | `assets/icons/items/PlungerPogo_512.png` | `Assets.ItemIcons.PlungerPogo` |
| `BathMatBat` | `assets/models/items/BathMatBat.fbx` | `assets/icons/items/BathMatBat_512.png` | `Assets.ItemIcons.BathMatBat` |
| `DiscoBidet` | `assets/models/items/DiscoBidet.fbx` | `assets/icons/items/DiscoBidet_512.png` | `Assets.ItemIcons.DiscoBidet` |
| `TowelTornado` | `assets/models/items/TowelTornado.fbx` | `assets/icons/items/TowelTornado_512.png` | `Assets.ItemIcons.TowelTornado` |
| `PorcelainPoodle` | `assets/models/items/PorcelainPoodle.fbx` | `assets/icons/items/PorcelainPoodle_512.png` | `Assets.ItemIcons.PorcelainPoodle` |
| `FaucetPharaoh` | `assets/models/items/FaucetPharaoh.fbx` | `assets/icons/items/FaucetPharaoh_512.png` | `Assets.ItemIcons.FaucetPharaoh` |
| `RoyalFlushFrog` | `assets/models/items/RoyalFlushFrog.fbx` | `assets/icons/items/RoyalFlushFrog_512.png` | `Assets.ItemIcons.RoyalFlushFrog` |
| `GoldenGargler` | `assets/models/items/GoldenGargler.fbx` | `assets/icons/items/GoldenGargler_512.png` | `Assets.ItemIcons.GoldenGargler` |
| `Clogtopus` | `assets/models/items/Clogtopus.fbx` | `assets/icons/items/Clogtopus_512.png` | `Assets.ItemIcons.Clogtopus` |
| `LaundryYeti` | `assets/models/items/LaundryYeti.fbx` | `assets/icons/items/LaundryYeti_512.png` | `Assets.ItemIcons.LaundryYeti` |
| `SteamGenie` | `assets/models/items/SteamGenie.fbx` | `assets/icons/items/SteamGenie_512.png` | `Assets.ItemIcons.SteamGenie` |
| `BathBombBehemoth` | `assets/models/items/BathBombBehemoth.fbx` | `assets/icons/items/BathBombBehemoth_512.png` | `Assets.ItemIcons.BathBombBehemoth` |
| `DrainKraken` | `assets/models/items/DrainKraken.fbx` | `assets/icons/items/DrainKraken_512.png` | `Assets.ItemIcons.DrainKraken` |
| `GeyserGorilla` | `assets/models/items/GeyserGorilla.fbx` | `assets/icons/items/GeyserGorilla_512.png` | `Assets.ItemIcons.GeyserGorilla` |
| `ThroneColossus` | `assets/models/items/ThroneColossus.fbx` | `assets/icons/items/ThroneColossus_512.png` | `Assets.ItemIcons.ThroneColossus` |
| `PlungerPaladin` | `assets/models/items/PlungerPaladin.fbx` | `assets/icons/items/PlungerPaladin_512.png` | `Assets.ItemIcons.PlungerPaladin` |
| `HaloHamster` | `assets/models/items/HaloHamster.fbx` | `assets/icons/items/HaloHamster_512.png` | `Assets.ItemIcons.HaloHamster` |
| `CometCommode` | `assets/models/items/CometCommode.fbx` | `assets/icons/items/CometCommode_512.png` | `Assets.ItemIcons.CometCommode` |
| `ConstellationClam` | `assets/models/items/ConstellationClam.fbx` | `assets/icons/items/ConstellationClam_512.png` | `Assets.ItemIcons.ConstellationClam` |
| `StarlightSeraph` | `assets/models/items/StarlightSeraph.fbx` | `assets/icons/items/StarlightSeraph_512.png` | `Assets.ItemIcons.StarlightSeraph` |
| `TheLastToilet` | `assets/models/items/TheLastToilet.fbx` | `assets/icons/items/TheLastToilet_512.png` | `Assets.ItemIcons.TheLastToilet` |
| `EmergencyUniverse` | `assets/models/items/EmergencyUniverse.fbx` | `assets/icons/items/EmergencyUniverse_512.png` | `Assets.ItemIcons.EmergencyUniverse` |
| `InfiniteOccupied` | `assets/models/items/InfiniteOccupied.fbx` | `assets/icons/items/InfiniteOccupied_512.png` | `Assets.ItemIcons.InfiniteOccupied` |
| `CosmicCourtesy` | `assets/models/items/CosmicCourtesy.fbx` | `assets/icons/items/CosmicCourtesy_512.png` | `Assets.ItemIcons.CosmicCourtesy` |
| `CoralCommode` | `assets/models/toilets/CoralCommode.fbx` | `assets/icons/toilets/CoralCommode_512.png` | `Assets.ToiletIcons.CoralCommode` |
| `CloudCushion` | `assets/models/toilets/CloudCushion.fbx` | `assets/icons/toilets/CloudCushion_512.png` | `Assets.ToiletIcons.CloudCushion` |
| `ClockworkCloset` | `assets/models/toilets/ClockworkCloset.fbx` | `assets/icons/toilets/ClockworkCloset_512.png` | `Assets.ToiletIcons.ClockworkCloset` |
| `DragonKiln` | `assets/models/toilets/DragonKiln.fbx` | `assets/icons/toilets/DragonKiln_512.png` | `Assets.ToiletIcons.DragonKiln` |
| `AuroraThrone` | `assets/models/toilets/AuroraThrone.fbx` | `assets/icons/toilets/AuroraThrone_512.png` | `Assets.ToiletIcons.AuroraThrone` |
| `AstralAltar` | `assets/models/toilets/AstralAltar.fbx` | `assets/icons/toilets/AstralAltar_512.png` | `Assets.ToiletIcons.AstralAltar` |
| `ParadoxPotty` | `assets/models/toilets/ParadoxPotty.fbx` | `assets/icons/toilets/ParadoxPotty_512.png` | `Assets.ToiletIcons.ParadoxPotty` |
| `InfinityFlush` | `assets/models/toilets/InfinityFlush.fbx` | `assets/icons/toilets/InfinityFlush_512.png` | `Assets.ToiletIcons.InfinityFlush` |

Reuse [asset-pipeline.md](../asset-pipeline.md) for geometry/export/Studio upload and [icon-pipeline.md](../icon-pipeline.md) for rendering and image upload. Produce **44 transparent 512×512 icons**, plus 128px review reductions. Use the existing orthographic three-quarter studio rig, fill roughly 80–85% of frame, leave all halos/ears/loops inside safe padding, and inspect against light/dark cards at 128px and 64px. Follow each character/toilet's icon note. No text baked into icons; cyan silhouettes need a dark contour. Add the 44 mappings to the icon manifest, preserve existing icons and collection IDs.

Future artist/integrator sequence:

1. Build a Common, a Celestial, a Secret and one toilet as vertical slices; review silhouettes, toy palette, face readability, pivot and triangle budget before producing the rest.
2. Use existing `build-assets.ps1 -Only ...` after registering new builders. Reimport exported FBX files for bounds, UV/material, closed-component, triangle and foot-pivot checks. Refresh manifest, validation and item/toilet contact sheets.
3. Import one toilet into the intended owning experience using Stud / Scale Factor 1 and current pipeline settings. Compare seat center 2.08 and lid 4.79 to Basic; preserve front orientation and foot datum. Then batch the other 43. Wait for moderation and verify texture/mesh permissions in that experience.
4. Serialize accepted Models into the existing `ModelTemplates` integration layout, keeping a single MeshPart plus supported texture appearance children. Use existing pipeline/template docs for .rbxm integration; do not add a second competing template folder from an older example. Record measured MeshCatalog bounds/centers; the artist may refine target decoration dimensions while retaining gameplay datums.
5. Render the 44 icons through the existing icon builder; upload approved 512px images through the owner/group's Creator Hub workflow, verify decal/image resolution and populate the listed Assets keys. Leave missing assets empty/zero with the established fallback until approved. Never invent an ID.
6. Build/reopen through Rojo and review real lighting, world/display sizing, the 15-tier shop and all collection rarities on desktop and phone. Test missing/unavailable assets and reduced/off VFX.

No new sound recordings, voices, toilet loops or per-character stingers. Reuse Flush, reveal tier stingers, coin/display cues and the Godly alias for Celestial. New server announcements use the existing bounded chat cue; new drops do not add extra world-event music.

## Balance proof and reproducibility

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/wave1-balance.ps1 -WriteOutput
stylua --check --line-endings Windows scripts/wave1-balance.luau
rojo build -o build.rbxl
```

The execution-policy option applies only to that child process. The wrapper parses **the canonical JSON**, serializes a temporary data-only Luau module, copies/runs [wave1-balance.luau](../../scripts/wave1-balance.luau) and cleans up its own verified scratch directory. Standalone Luau lacks ordinary file I/O; there is no checked-in duplicate balance table and no engine dependency. Running the .luau directly without the wrapper does not provide its input module. `-WriteOutput` saves [wave1-balance.txt](wave1-balance.txt). The complete captured output is embedded below.

The proof checks 47/36 items, four new per rarity, 15/8 toilets, unique IDs/pool membership, band/income monotonicity, 45 normalized outcome distributions, an independently calculated fallback product, triangle/size limits, sequential exponential prices, cooldown/luck bounds, income caps, rebirth gates and deterministic cohort replay. Typical mid/late display-income share is asserted within economy-v2's 70–90% comparison band. Conditional toilet p50 targets have ±20% tolerance.

Three different measurements are deliberately separated:

- **First sight:** for each of all 47 items, at its first eligible toilet, E[flushes]=1/p and E[online minutes]=cooldown/(60×0.75×p), using unupgraded speed and the three total-luck scenarios. Unlock time is excluded. Infinite means a zero-probability outcome under saturation; it is not an empty flush. The per-pool tables also let reviewers compute later-toilet first-sight times. Geometric expectation is not a guarantee or median.
- **Ten-slot income:** reproduce economy-v2's typical 60-minute fixed-tier showcase using floored expected copies, selecting best income first, cash/luck factor 1.4 and speed factor 0.8. Slots and inventory acquisition costs are excluded, so this is not first-session progress. Separately compute the **exact expected best-ten rate** after that many fixed-pool rolls: for each rarity threshold, K is Binomial(N, probability of that rarity or better), and E[min(10,K)] weights successive rate differences. This includes jackpot tails and can be much higher than the typical showcase. Active comparator assumes every drop sells; protected-safe actual sales are used in the cohort instead.
- **Conditional pacing:** 200 seeded accounts begin at minute-35 Galaxy, zero wallet, ten available slots, eight Ducks and two Golden Poops. Retain first/displayed copies, display highest income, sell surplus, collect every 30 seconds and buy sequential toilets with real earned coins. Income continues through the 25% manual downtime. No further upgrades, rebirths, offline/daily/index gifts, events or paid power. This is an intentionally stated starting portfolio, **not** a fabricated fresh-account run. It estimates post-Galaxy price feasibility only; the merged branch must validate the actual full journey.

The exact-mean calculation is an uncapped gross income rate at the specified cash factor, not a stored offline payout. The conditional cohort is a lightweight economic model, not production transaction/persistence validation; continuous accrual and floor-to-whole collection preserve fractional pending amounts, but do not exercise the live 6,000-subcoin ledger or backend. Travel, latency, manual collection misses, device FPS and global event uptime require later integration/play testing.

### Captured output

<details>
<summary>Complete checked Luau output: pool probabilities, all first-sight estimates, incomes and pacing</summary>

```text
WAVE 1 | JSON-derived data | 47 items / 36 new / 9 rarities / 15 toilets / 8 new
1x and 5x are total effective luck overrides; 10x is uncapped stress-only, production cap remains 5x.
Base odds ordering is strict between rarity bands. Effective outcomes may invert under sequential checks/saturation.
RARITY | order | total/new | base income/s
Common | 1 | 5/4 | 1
Uncommon | 2 | 5/4 | 3
Rare | 3 | 6/4 | 10
Epic | 4 | 5/4 | 40
Legendary | 5 | 5/4 | 200
Mythic | 6 | 5/4 | 1000
Godly | 7 | 6/4 | 6000
Celestial | 8 | 4/4 | 25000
Secret | 9 | 6/4 | 100000
POOL PROBABILITIES: unconditional fractions, columns 1x / 5x / 10x stress; Poop is remainder.
T01 Basic | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.373275 | 0 | 0
  ToiletPaper            0.10665 | 0.234375 | 0
  Rat                    0.0395 | 0.1875 | 0.35
  Fish                   0.0125 | 0.0625 | 0.125
  SudsSlug               0.1866375 | 0 | 0
  PocketPuddle           0.1866375 | 0.140625 | 0
  TubTadpole             0.0948 | 0.375 | 0.525
T02 Dirty | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.21736455 | 0 | 0
  ToiletPaper            0.0931562357 | 0.106640625 | 0
  Rat                    0.039342 | 0.18375 | 0.336
  Fish                   0.01245 | 0.06125 | 0.12
  Duck                   0.004 | 0.02 | 0.04
  SudsSlug               0.108682275 | 0 | 0
  PocketPuddle           0.108682275 | 0 | 0
  LoopyLoofah            0.108682275 | 0.0106640625 | 0
  SoggySock              0.108682275 | 0.0533203125 | 0
  TubTadpole             0.0828055429 | 0.170625 | 0.064
  BrushBristle           0.0636965714 | 0.189583333 | 0.16
  RollMole               0.052456 | 0.204166667 | 0.28
T03 Golden | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.198110616 | 0 | 0
  ToiletPaper            0.0849045495 | 0.0648013184 | 0
  Rat                    0.0374161304 | 0.14104125 | 0.19008
  Fish                   0.01243755 | 0.06094375 | 0.1188
  Duck                   0.003996 | 0.0199 | 0.0396
  GoldenPoop             0.001 | 0.005 | 0.01
  SudsSlug               0.0990553078 | 0 | 0
  PocketPuddle           0.0990553078 | 0 | 0
  LoopyLoofah            0.0990553078 | 0.00648013184 | 0
  SoggySock              0.0990553078 | 0.0324006592 | 0
  TubTadpole             0.0754707107 | 0.103682109 | 0.02112
  BrushBristle           0.0580543928 | 0.115202344 | 0.0528
  RollMole               0.0478095 | 0.124064063 | 0.0924
  CapybaraCap            0.0374161304 | 0.117534375 | 0.1188
  DrainCrab              0.0275118606 | 0.117534375 | 0.19008
  ToothpasteGoose        0.019651329 | 0.091415625 | 0.16632
T04 Diamond | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.193900609 | 0 | 0
  ToiletPaper            0.0831002608 | 0.058095244 | 0
  Rat                    0.0366210081 | 0.126445357 | 0.152030872
  Fish                   0.0121732422 | 0.0546368826 | 0.0950192949
  Duck                   0.00398378594 | 0.0195960986 | 0.0383916343
  GoldenPoop             0.0009998 | 0.004995 | 0.00998
  ToiletBaby             0.0002 | 0.001 | 0.002
  SudsSlug               0.0969503043 | 0 | 0
  PocketPuddle           0.0969503043 | 0 | 0
  LoopyLoofah            0.0969503043 | 0.0058095244 | 0
  SoggySock              0.0969503043 | 0.029047622 | 0
  TubTadpole             0.0738668985 | 0.0929523904 | 0.0168923191
  BrushBristle           0.0568206912 | 0.103280434 | 0.0422307977
  RollMole               0.0467935104 | 0.111225083 | 0.073903896
  CapybaraCap            0.0366210081 | 0.105371131 | 0.0950192949
  DrainCrab              0.0269272119 | 0.105371131 | 0.152030872
  ToothpasteGoose        0.0192337228 | 0.081955324 | 0.133027013
  SpongeKnight           0.00983696343 | 0.0460100064 | 0.0844615954
  BubbleBeard            0.00826635583 | 0.0400087013 | 0.0767832686
  PlungerPogo            0.00285371486 | 0.0142000714 | 0.0282291429
T05 Radioactive | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.193166278 | 0 | 0
  ToiletPaper            0.0827855475 | 0.0569992693 | 0
  Rat                    0.0364823188 | 0.124059948 | 0.146321541
  Fish                   0.0121271403 | 0.0536061504 | 0.0914509632
  Duck                   0.00396869874 | 0.0192264155 | 0.0369498841
  GoldenPoop             0.000999770006 | 0.00499425077 | 0.0099770062
  ToiletBaby             0.000199994 | 0.000999850005 | 0.00199940004
  SewerShark             1.99998e-05 | 9.9995e-05 | 0.00019998
  KingPoop               1e-05 | 5e-05 | 0.0001
  SudsSlug               0.0965831388 | 0 | 0
  PocketPuddle           0.0965831388 | 0 | 0
  LoopyLoofah            0.0965831388 | 0.00569992693 | 0
  SoggySock              0.0965831388 | 0.0284996347 | 0
  TubTadpole             0.0735871534 | 0.0911988309 | 0.016257949
  BrushBristle           0.0566055026 | 0.101332034 | 0.0406448725
  RollMole               0.0466162962 | 0.109126806 | 0.0711285269
  CapybaraCap            0.0364823188 | 0.10338329 | 0.0914509632
  DrainCrab              0.0268252344 | 0.10338329 | 0.146321541
  ToothpasteGoose        0.0191608817 | 0.0804092256 | 0.128031348
  SpongeKnight           0.00979970936 | 0.0451420214 | 0.0812897451
  BubbleBeard            0.00823504988 | 0.0392539317 | 0.0738997682
  PlungerPogo            0.00284290741 | 0.0139321851 | 0.0271690324
  BathMatBat             0.00221607481 | 0.0109578984 | 0.0216117304
  DiscoBidet             0.00153656959 | 0.00764504542 | 0.0151957479
T06 Demon | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192822821 | 0 | 0
  ToiletPaper            0.0826383519 | 0.0564933822 | 0
  Rat                    0.0364174519 | 0.122958876 | 0.143729671
  Fish                   0.0121055778 | 0.0531303784 | 0.0898310441
  Duck                   0.00396164225 | 0.0190557748 | 0.0362953714
  GoldenPoop             0.000999102494 | 0.00497757838 | 0.00991039372
  ToiletBaby             0.0001999938 | 0.000999845006 | 0.00199938005
  SewerShark             1.999978e-05 | 9.99945e-05 | 0.000199978
  KingPoop               9.99999e-06 | 4.999975e-05 | 9.9999e-05
  AlienToilet            1e-06 | 5e-06 | 1e-05
  SudsSlug               0.0964114105 | 0 | 0
  PocketPuddle           0.0964114105 | 0 | 0
  LoopyLoofah            0.0964114105 | 0.00564933822 | 0
  SoggySock              0.0964114105 | 0.0282466911 | 0
  TubTadpole             0.0734563128 | 0.0903894115 | 0.0159699634
  BrushBristle           0.056504856 | 0.100432679 | 0.0399249085
  RollMole               0.0465334108 | 0.10815827 | 0.0698685899
  CapybaraCap            0.0364174519 | 0.10246573 | 0.0898310441
  DrainCrab              0.0267775382 | 0.10246573 | 0.143729671
  ToothpasteGoose        0.019126813 | 0.0796955675 | 0.125763462
  SpongeKnight           0.00978228513 | 0.0447413712 | 0.079849817
  BubbleBeard            0.00822040767 | 0.0389055402 | 0.0725907427
  PlungerPogo            0.00283785262 | 0.0138085325 | 0.0266877731
  BathMatBat             0.00221213456 | 0.0108606435 | 0.0212289104
  DiscoBidet             0.00153383752 | 0.00757719315 | 0.0149265776
  TowelTornado           0.00110900377 | 0.00550298944 | 0.0109014331
  PorcelainPoodle        0.000666512671 | 0.00332948387 | 0.00665127095
T07 Galaxy | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192709457 | 0 | 0
  ToiletPaper            0.0825897673 | 0.0563273833 | 0
  Rat                    0.0363960415 | 0.122597576 | 0.142885443
  Fish                   0.0120984608 | 0.0529742613 | 0.0893034016
  Duck                   0.00395931313 | 0.0189997817 | 0.0360821825
  GoldenPoop             0.000998515103 | 0.00496295238 | 0.00985218283
  ToiletBaby             0.000199967114 | 0.000999177943 | 0.00199671221
  SewerShark             1.9999778e-05 | 9.999445e-05 | 0.0001999778
  KingPoop               9.999989e-06 | 4.9999725e-05 | 9.99989e-05
  AlienToilet            9.999999e-07 | 4.9999975e-06 | 9.99999e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0963547285 | 0 | 0
  PocketPuddle           0.0963547285 | 0 | 0
  LoopyLoofah            0.0963547285 | 0.00563273833 | 0
  SoggySock              0.0963547285 | 0.0281636917 | 0
  TubTadpole             0.0734131265 | 0.0901238133 | 0.0158761603
  BrushBristle           0.0564716358 | 0.10013757 | 0.0396904007
  RollMole               0.046506053 | 0.10784046 | 0.0694582012
  CapybaraCap            0.0363960415 | 0.102164647 | 0.0893034016
  DrainCrab              0.0267617952 | 0.102164647 | 0.142885443
  ToothpasteGoose        0.019115568 | 0.0794613919 | 0.125024762
  SpongeKnight           0.00977653395 | 0.0446099042 | 0.0793808014
  BubbleBeard            0.00821557474 | 0.0387912211 | 0.0721643649
  PlungerPogo            0.00283618419 | 0.0137679578 | 0.0265310165
  BathMatBat             0.002210834 | 0.0108287308 | 0.0211042177
  DiscoBidet             0.00153293575 | 0.00755492849 | 0.0148389031
  TowelTornado           0.00110835176 | 0.00548681958 | 0.0108374011
  PorcelainPoodle        0.000666120816 | 0.00331970059 | 0.00661220324
  FaucetPharaoh          0.00045437982 | 0.0022685881 | 0.00452890633
  Clogtopus              0.000133329187 | 0.000666563004 | 0.0013329187
T08 CoralCommode | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192590374 | 0 | 0
  ToiletPaper            0.0825387317 | 0.0561534766 | 0
  Rat                    0.0363735508 | 0.122219065 | 0.142003959
  Fish                   0.0120909846 | 0.052810707 | 0.0887524745
  Duck                   0.00395686651 | 0.0189411213 | 0.0358595857
  GoldenPoop             0.000997898079 | 0.00494762962 | 0.00979140313
  ToiletBaby             0.00019995045 | 0.000998761619 | 0.00199504828
  SewerShark             1.9999778e-05 | 9.999445e-05 | 0.0001999778
  KingPoop               9.999989e-06 | 4.9999725e-05 | 9.99989e-05
  AlienToilet            9.999999e-07 | 4.9999975e-06 | 9.99999e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962951869 | 0 | 0
  PocketPuddle           0.0962951869 | 0 | 0
  LoopyLoofah            0.0962951869 | 0.00561534766 | 0
  SoggySock              0.0962951869 | 0.0280767383 | 0
  TubTadpole             0.0733677615 | 0.0898455625 | 0.0157782177
  BrushBristle           0.0564367396 | 0.0998284028 | 0.0394455442
  RollMole               0.046477315 | 0.107507511 | 0.0690297024
  CapybaraCap            0.0363735508 | 0.101849221 | 0.0887524745
  DrainCrab              0.026745258 | 0.101849221 | 0.142003959
  ToothpasteGoose        0.0191037557 | 0.0792160605 | 0.124253464
  SpongeKnight           0.00977049262 | 0.0444721743 | 0.0788910885
  BubbleBeard            0.008210498 | 0.0386714559 | 0.0717191714
  PlungerPogo            0.00283443159 | 0.0137254502 | 0.0263673424
  BathMatBat             0.00220946784 | 0.0107952979 | 0.0209740224
  DiscoBidet             0.00153198848 | 0.00753160319 | 0.0147473595
  TowelTornado           0.00110766687 | 0.00546987941 | 0.0107705434
  PorcelainPoodle        0.000665709192 | 0.00330945125 | 0.00657141149
  FaucetPharaoh          0.00045409904 | 0.002261584 | 0.00450096678
  RoyalFlushFrog         0.000312290681 | 0.00155727224 | 0.00310411502
  GoldenGargler          0.000222122734 | 0.0011086254 | 0.00221228687
  Clogtopus              0.000133318076 | 0.000666285269 | 0.00133180793
  LaundryYeti            8.33307417e-05 | 0.000416601877 | 0.000833074186
T09 CloudCushion | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192571757 | 0 | 0
  ToiletPaper            0.0825307532 | 0.0561263396 | 0
  Rat                    0.0363700348 | 0.122160001 | 0.141866728
  Fish                   0.0120898159 | 0.0527851855 | 0.0886667051
  Duck                   0.00395648402 | 0.0189319677 | 0.0358249314
  GoldenPoop             0.000997801619 | 0.00494523861 | 0.00978194082
  ToiletBaby             0.000199931122 | 0.000998278953 | 0.00199312029
  SewerShark             1.99995113e-05 | 9.99877837e-05 | 0.000199951137
  KingPoop               9.999989e-06 | 4.9999725e-05 | 9.99989e-05
  AlienToilet            9.999999e-07 | 4.9999975e-06 | 9.99999e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962858787 | 0 | 0
  PocketPuddle           0.0962858787 | 0 | 0
  LoopyLoofah            0.0962858787 | 0.00561263396 | 0
  SoggySock              0.0962858787 | 0.0280631698 | 0
  TubTadpole             0.0733606695 | 0.0898021434 | 0.0157629698
  BrushBristle           0.0564312842 | 0.0997801593 | 0.0394074245
  RollMole               0.0464728223 | 0.107455556 | 0.0689629929
  CapybaraCap            0.0363700348 | 0.101800001 | 0.0886667051
  DrainCrab              0.0267426727 | 0.101800001 | 0.141866728
  ToothpasteGoose        0.0191019091 | 0.0791777783 | 0.124133387
  SpongeKnight           0.00976954817 | 0.0444506825 | 0.078814849
  BubbleBeard            0.00820970434 | 0.0386527674 | 0.0716498627
  PlungerPogo            0.00283415761 | 0.0137188172 | 0.0263418613
  BathMatBat             0.00220925426 | 0.0107900809 | 0.0209537533
  DiscoBidet             0.0015318404 | 0.00752796344 | 0.0147331078
  TowelTornado           0.0011075598 | 0.00546723602 | 0.0107601349
  PorcelainPoodle        0.000665644842 | 0.00330785191 | 0.00656506096
  FaucetPharaoh          0.000454055145 | 0.00226049106 | 0.00449661709
  RoyalFlushFrog         0.000312260493 | 0.00155651966 | 0.00310111524
  GoldenGargler          0.000222101262 | 0.00110808964 | 0.00221014894
  Clogtopus              0.000133305189 | 0.000665963278 | 0.00133052089
  LaundryYeti            8.33226866e-05 | 0.000416400549 | 0.000832269112
  SteamGenie             4.99961118e-05 | 0.000249902805 | 0.000499611273
  BathBombBehemoth       3.33318522e-05 | 0.000166629642 | 0.000333185244
  DrainKraken            1.33331853e-05 | 6.66629667e-05 | 0.000133318533
T10 ClockworkCloset | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192569147 | 0 | 0
  ToiletPaper            0.0825296344 | 0.0561225356 | 0
  Rat                    0.0363695418 | 0.122151721 | 0.141847498
  Fish                   0.012089652 | 0.0527816079 | 0.0886546863
  Duck                   0.00395643039 | 0.0189306846 | 0.0358200753
  GoldenPoop             0.000997788093 | 0.00494490344 | 0.00978061487
  ToiletBaby             0.000199928412 | 0.000998211293 | 0.00199285012
  SewerShark             1.99992402e-05 | 9.99810069e-05 | 0.000199924033
  KingPoop               9.99985345e-06 | 4.99963362e-05 | 9.9985345e-05
  AlienToilet            9.999999e-07 | 4.9999975e-06 | 9.99999e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962845735 | 0 | 0
  PocketPuddle           0.0962845735 | 0 | 0
  LoopyLoofah            0.0962845735 | 0.00561225356 | 0
  SoggySock              0.0962845735 | 0.0280612678 | 0
  TubTadpole             0.073359675 | 0.0897960569 | 0.0157608331
  BrushBristle           0.0564305193 | 0.0997733966 | 0.0394020828
  RollMole               0.0464721923 | 0.107448273 | 0.0689536449
  CapybaraCap            0.0363695418 | 0.101793101 | 0.0886546863
  DrainCrab              0.0267423102 | 0.101793101 | 0.141847498
  ToothpasteGoose        0.0191016501 | 0.0791724119 | 0.124116561
  SpongeKnight           0.00976941573 | 0.0444476698 | 0.0788041656
  BubbleBeard            0.00820959305 | 0.0386501477 | 0.0716401505
  PlungerPogo            0.00283411919 | 0.0137178874 | 0.0263382906
  BathMatBat             0.00220922431 | 0.0107893496 | 0.020950913
  DiscoBidet             0.00153181963 | 0.00752745322 | 0.0147311107
  TowelTornado           0.00110754478 | 0.00546686547 | 0.0107586764
  PorcelainPoodle        0.000665635819 | 0.00330762772 | 0.00656417105
  FaucetPharaoh          0.00045404899 | 0.00226033785 | 0.00449600757
  RoyalFlushFrog         0.000312256261 | 0.00155641417 | 0.00310069488
  GoldenGargler          0.000222098252 | 0.00110801454 | 0.00220984936
  Clogtopus              0.000133303382 | 0.000665918141 | 0.00133034053
  LaundryYeti            8.33215571e-05 | 0.000416372327 | 0.000832156297
  SteamGenie             4.99954341e-05 | 0.000249885867 | 0.00049954355
  BathBombBehemoth       3.33314004e-05 | 0.000166618348 | 0.00033314008
  DrainKraken            1.33330046e-05 | 6.66584485e-05 | 0.000133300462
  GeyserGorilla          7.99994676e-06 | 3.99986689e-05 | 7.99946756e-05
  ThroneColossus         5.55554944e-06 | 2.7777625e-05 | 5.55549444e-05
T11 DragonKiln | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192567735 | 0 | 0
  ToiletPaper            0.0825290292 | 0.0561204778 | 0
  Rat                    0.0363692751 | 0.122147242 | 0.141837096
  Fish                   0.0120895633 | 0.0527796726 | 0.088648185
  Duck                   0.00395640137 | 0.0189299905 | 0.0358174485
  GoldenPoop             0.000997780776 | 0.00494472213 | 0.00977989764
  ToiletBaby             0.000199926946 | 0.000998174692 | 0.00199270398
  SewerShark             1.99990936e-05 | 9.9977341e-05 | 0.000199909372
  KingPoop               9.99978011e-06 | 4.9994503e-05 | 9.99780129e-05
  AlienToilet            9.999999e-07 | 4.9999975e-06 | 9.99999e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962838674 | 0 | 0
  PocketPuddle           0.0962838674 | 0 | 0
  LoopyLoofah            0.0962838674 | 0.00561204778 | 0
  SoggySock              0.0962838674 | 0.0280602389 | 0
  TubTadpole             0.0733591371 | 0.0897927644 | 0.0157596773
  BrushBristle           0.0564301054 | 0.0997697383 | 0.0393991934
  RollMole               0.0464718515 | 0.107444334 | 0.0689485884
  CapybaraCap            0.0363692751 | 0.101789369 | 0.088648185
  DrainCrab              0.0267421141 | 0.101789369 | 0.141837096
  ToothpasteGoose        0.01910151 | 0.0791695089 | 0.124107459
  SpongeKnight           0.00976934409 | 0.0444460401 | 0.0787983867
  BubbleBeard            0.00820953285 | 0.0386487305 | 0.071634897
  PlungerPogo            0.00283409841 | 0.0137173844 | 0.0263363592
  BathMatBat             0.00220920811 | 0.010788954 | 0.0209493766
  DiscoBidet             0.0015318084 | 0.00752717722 | 0.0147300304
  TowelTornado           0.00110753666 | 0.00546666502 | 0.0107578874
  PorcelainPoodle        0.000665630938 | 0.00330750644 | 0.00656368969
  FaucetPharaoh          0.00045404566 | 0.00226025497 | 0.00449567787
  RoyalFlushFrog         0.000312253971 | 0.0015563571 | 0.0031004675
  GoldenGargler          0.000222096623 | 0.00110797391 | 0.0022096873
  Clogtopus              0.000133302404 | 0.000665893724 | 0.00133024298
  LaundryYeti            8.33209461e-05 | 0.00041635706 | 0.000832095274
  SteamGenie             4.99950674e-05 | 0.000249876705 | 0.000499506918
  BathBombBehemoth       3.3331156e-05 | 0.000166612239 | 0.00033311565
  DrainKraken            1.33329068e-05 | 6.66560044e-05 | 0.000133290687
  GeyserGorilla          7.99988809e-06 | 3.99972023e-05 | 7.99888094e-05
  ThroneColossus         5.5555087e-06 | 2.77766065e-05 | 5.55508705e-05
  PlungerPaladin         3.99998227e-06 | 1.99995567e-05 | 3.99982267e-05
  HaloHamster            3.33332967e-06 | 1.6666575e-05 | 3.33329667e-05
T12 AuroraThrone | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192567011 | 0 | 0
  ToiletPaper            0.0825287188 | 0.0561194225 | 0
  Rat                    0.0363691383 | 0.122144946 | 0.141831762
  Fish                   0.0120895178 | 0.0527786802 | 0.0886448513
  Duck                   0.0039563865 | 0.0189296345 | 0.0358161015
  GoldenPoop             0.000997777023 | 0.00494462915 | 0.00977952985
  ToiletBaby             0.000199926194 | 0.000998155923 | 0.00199262904
  SewerShark             1.99990184e-05 | 9.9975461e-05 | 0.000199901854
  KingPoop               9.99974251e-06 | 4.99935629e-05 | 9.99742531e-05
  AlienToilet            9.999999e-07 | 4.9999975e-06 | 9.99999e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962835053 | 0 | 0
  PocketPuddle           0.0962835053 | 0 | 0
  LoopyLoofah            0.0962835053 | 0.00561194225 | 0
  SoggySock              0.0962835053 | 0.0280597113 | 0
  TubTadpole             0.0733588612 | 0.089791076 | 0.0157590847
  BrushBristle           0.0564298932 | 0.0997678622 | 0.0393977117
  RollMole               0.0464716768 | 0.107442313 | 0.0689459955
  CapybaraCap            0.0363691383 | 0.101787455 | 0.0886448513
  DrainCrab              0.0267420135 | 0.101787455 | 0.141831762
  ToothpasteGoose        0.0191014382 | 0.0791680202 | 0.124102792
  SpongeKnight           0.00976930735 | 0.0444452043 | 0.0787954234
  BubbleBeard            0.00820950198 | 0.0386480038 | 0.0716322031
  PlungerPogo            0.00283408775 | 0.0137171265 | 0.0263353688
  BathMatBat             0.0022091998 | 0.0107887511 | 0.0209485888
  DiscoBidet             0.00153180264 | 0.00752703568 | 0.0147294765
  TowelTornado           0.0011075325 | 0.00546656223 | 0.0107574828
  PorcelainPoodle        0.000665628435 | 0.00330744425 | 0.00656344285
  FaucetPharaoh          0.000454043953 | 0.00226021247 | 0.0044955088
  RoyalFlushFrog         0.000312252796 | 0.00155632784 | 0.0031003509
  GoldenGargler          0.000222095788 | 0.00110795308 | 0.0022096042
  Clogtopus              0.000133301903 | 0.000665881203 | 0.00133019295
  LaundryYeti            8.33206328e-05 | 0.000416349231 | 0.000832063982
  SteamGenie             4.99948794e-05 | 0.000249872006 | 0.000499488133
  BathBombBehemoth       3.33310306e-05 | 0.000166609106 | 0.000333103123
  DrainKraken            1.33328567e-05 | 6.6654751e-05 | 0.000133285674
  GeyserGorilla          7.999858e-06 | 3.99964502e-05 | 7.99858013e-05
  ThroneColossus         5.55548781e-06 | 2.77760842e-05 | 5.55487814e-05
  PlungerPaladin         3.99996722e-06 | 1.99991806e-05 | 3.99967225e-05
  HaloHamster            3.33331713e-06 | 1.66662616e-05 | 3.33317131e-05
  CometCommode           2.22221636e-06 | 1.11109645e-05 | 2.22216359e-05
  ConstellationClam      1.53845985e-06 | 7.69226538e-06 | 1.53844462e-05
T13 AstralAltar | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192566668 | 0 | 0
  ToiletPaper            0.0825285721 | 0.0561189237 | 0
  Rat                    0.0363690737 | 0.12214386 | 0.141829241
  Fish                   0.0120894964 | 0.052778211 | 0.0886432754
  Duck                   0.00395637946 | 0.0189294662 | 0.0358154648
  GoldenPoop             0.00099777525 | 0.0049445852 | 0.00977935599
  ToiletBaby             0.000199925839 | 0.000998147051 | 0.00199259362
  SewerShark             1.99989828e-05 | 9.99745724e-05 | 0.0001998983
  KingPoop               9.99972473e-06 | 4.99931186e-05 | 9.99724758e-05
  AlienToilet            9.99999233e-07 | 4.99998083e-06 | 9.99992333e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962833341 | 0 | 0
  PocketPuddle           0.0962833341 | 0 | 0
  LoopyLoofah            0.0962833341 | 0.00561189237 | 0
  SoggySock              0.0962833341 | 0.0280594618 | 0
  TubTadpole             0.0733587308 | 0.0897902779 | 0.0157588045
  BrushBristle           0.0564297929 | 0.0997669754 | 0.0393970113
  RollMole               0.0464715941 | 0.107441358 | 0.0689447698
  CapybaraCap            0.0363690737 | 0.10178655 | 0.0886432754
  DrainCrab              0.0267419659 | 0.10178655 | 0.141829241
  ToothpasteGoose        0.0191014042 | 0.0791673165 | 0.124100586
  SpongeKnight           0.00976928999 | 0.0444448093 | 0.0787940226
  BubbleBeard            0.00820948738 | 0.0386476602 | 0.0716309296
  PlungerPogo            0.00283408271 | 0.0137170045 | 0.0263349006
  BathMatBat             0.00220919588 | 0.0107886552 | 0.0209482164
  DiscoBidet             0.00153179991 | 0.00752696877 | 0.0147292146
  TowelTornado           0.00110753053 | 0.00546651363 | 0.0107572916
  PorcelainPoodle        0.000665627251 | 0.00330741485 | 0.00656332617
  FaucetPharaoh          0.000454043145 | 0.00226019238 | 0.00449542888
  RoyalFlushFrog         0.000312252241 | 0.001556314 | 0.00310029578
  GoldenGargler          0.000222095393 | 0.00110794323 | 0.00220956492
  Clogtopus              0.000133301666 | 0.000665875284 | 0.0013301693
  LaundryYeti            8.33204846e-05 | 0.00041634553 | 0.000832049189
  SteamGenie             4.99947905e-05 | 0.000249869785 | 0.000499479253
  BathBombBehemoth       3.33309714e-05 | 0.000166607625 | 0.000333097201
  DrainKraken            1.3332833e-05 | 6.66541585e-05 | 0.000133283305
  GeyserGorilla          7.99984378e-06 | 3.99960947e-05 | 7.99843794e-05
  ThroneColossus         5.55547793e-06 | 2.77758373e-05 | 5.55477939e-05
  PlungerPaladin         3.99996011e-06 | 1.99990028e-05 | 3.99960114e-05
  HaloHamster            3.33331121e-06 | 1.66661135e-05 | 3.33311206e-05
  CometCommode           2.22221241e-06 | 1.11108658e-05 | 2.22212409e-05
  ConstellationClam      1.53845711e-06 | 7.69219701e-06 | 1.53841727e-05
  StarlightSeraph        1.11110915e-06 | 5.55550648e-06 | 1.11109148e-05
  TheLastToilet          6.666666e-07 | 3.33333167e-06 | 6.66666e-06
T14 ParadoxPotty | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.192566553 | 0 | 0
  ToiletPaper            0.0825285226 | 0.0561187553 | 0
  Rat                    0.0363690519 | 0.122143493 | 0.14182839
  Fish                   0.0120894891 | 0.0527780527 | 0.0886427435
  Duck                   0.00395637709 | 0.0189294095 | 0.0358152499
  GoldenPoop             0.000997774651 | 0.00494457036 | 0.00977929732
  ToiletBaby             0.000199925719 | 0.000998144057 | 0.00199258166
  SewerShark             1.99989708e-05 | 9.99742725e-05 | 0.000199897101
  KingPoop               9.99971873e-06 | 4.99929686e-05 | 9.99718759e-05
  AlienToilet            9.99998633e-07 | 4.99996583e-06 | 9.99986333e-06
  Mystery                1e-07 | 5e-07 | 1e-06
  SudsSlug               0.0962832764 | 0 | 0
  PocketPuddle           0.0962832764 | 0 | 0
  LoopyLoofah            0.0962832764 | 0.00561187553 | 0
  SoggySock              0.0962832764 | 0.0280593777 | 0
  TubTadpole             0.0733586867 | 0.0897900085 | 0.01575871
  BrushBristle           0.056429759 | 0.0997666761 | 0.0393967749
  RollMole               0.0464715663 | 0.107441036 | 0.0689443561
  CapybaraCap            0.0363690519 | 0.101786244 | 0.0886427435
  DrainCrab              0.0267419499 | 0.101786244 | 0.14182839
  ToothpasteGoose        0.0191013928 | 0.079167079 | 0.124099841
  SpongeKnight           0.00976928412 | 0.0444446759 | 0.0787935498
  BubbleBeard            0.00820948246 | 0.0386475443 | 0.0716304998
  PlungerPogo            0.00283408101 | 0.0137169634 | 0.0263347426
  BathMatBat             0.00220919455 | 0.0107886229 | 0.0209480907
  DiscoBidet             0.00153179899 | 0.00752694619 | 0.0147291263
  TowelTornado           0.00110752986 | 0.00546649724 | 0.010757227
  PorcelainPoodle        0.000665626852 | 0.00330740493 | 0.00656328679
  FaucetPharaoh          0.000454042873 | 0.0022601856 | 0.00449540191
  RoyalFlushFrog         0.000312252054 | 0.00155630933 | 0.00310027718
  GoldenGargler          0.00022209526 | 0.0011079399 | 0.00220955167
  Clogtopus              0.000133301586 | 0.000665873287 | 0.00133016132
  LaundryYeti            8.33204346e-05 | 0.000416344281 | 0.000832044197
  SteamGenie             4.99947605e-05 | 0.000249869036 | 0.000499476256
  BathBombBehemoth       3.33309514e-05 | 0.000166607125 | 0.000333095203
  DrainKraken            1.3332825e-05 | 6.66539586e-05 | 0.000133282505
  GeyserGorilla          7.99983898e-06 | 3.99959747e-05 | 7.99838995e-05
  ThroneColossus         5.5554746e-06 | 2.7775754e-05 | 5.55474606e-05
  PlungerPaladin         3.99995771e-06 | 1.99989428e-05 | 3.99957715e-05
  HaloHamster            3.33330921e-06 | 1.66660635e-05 | 3.33309206e-05
  CometCommode           2.22221108e-06 | 1.11108324e-05 | 2.22211075e-05
  ConstellationClam      1.53845619e-06 | 7.69217393e-06 | 1.53840803e-05
  StarlightSeraph        1.11110848e-06 | 5.55548982e-06 | 1.11108482e-05
  TheLastToilet          6.666662e-07 | 3.33332167e-06 | 6.66662e-06
  EmergencyUniverse      3.9999988e-07 | 1.999997e-06 | 3.999988e-06
  InfiniteOccupied       1.9999998e-07 | 9.999995e-07 | 1.999998e-06
T15 InfinityFlush | sum 1.000000000000 / 1.000000000000 / 1.000000000000
  Poop                   0.19256654 | 0 | 0
  ToiletPaper            0.0825285171 | 0.0561187366 | 0
  Rat                    0.0363690494 | 0.122143453 | 0.141828295
  Fish                   0.0120894883 | 0.0527780351 | 0.0886426844
  Duck                   0.00395637682 | 0.0189294031 | 0.035815226
  GoldenPoop             0.000997774584 | 0.00494456872 | 0.0097792908
  ToiletBaby             0.000199925705 | 0.000998143724 | 0.00199258033
  SewerShark             1.99989695e-05 | 9.99742391e-05 | 0.000199896968
  KingPoop               9.99971806e-06 | 4.99929519e-05 | 9.99718093e-05
  AlienToilet            9.99998567e-07 | 4.99996417e-06 | 9.99985667e-06
  Mystery                9.99999933e-08 | 4.99999833e-07 | 9.99999333e-07
  SudsSlug               0.0962832699 | 0 | 0
  PocketPuddle           0.0962832699 | 0 | 0
  LoopyLoofah            0.0962832699 | 0.00561187366 | 0
  SoggySock              0.0962832699 | 0.0280593683 | 0
  TubTadpole             0.0733586819 | 0.0897899786 | 0.0157586995
  BrushBristle           0.0564297553 | 0.0997666429 | 0.0393967486
  RollMole               0.0464715632 | 0.107441 | 0.0689443101
  CapybaraCap            0.0363690494 | 0.101786211 | 0.0886426844
  DrainCrab              0.0267419481 | 0.101786211 | 0.141828295
  ToothpasteGoose        0.0191013915 | 0.0791670526 | 0.124099758
  SpongeKnight           0.00976928347 | 0.0444446611 | 0.0787934973
  BubbleBeard            0.00820948191 | 0.0386475314 | 0.0716304521
  PlungerPogo            0.00283408082 | 0.0137169588 | 0.026334725
  BathMatBat             0.0022091944 | 0.0107886193 | 0.0209480767
  DiscoBidet             0.00153179889 | 0.00752694368 | 0.0147291164
  TowelTornado           0.00110752979 | 0.00546649541 | 0.0107572199
  PorcelainPoodle        0.000665626808 | 0.00330740382 | 0.00656328241
  FaucetPharaoh          0.000454042843 | 0.00226018484 | 0.00449539891
  RoyalFlushFrog         0.000312252033 | 0.00155630881 | 0.00310027511
  GoldenGargler          0.000222095245 | 0.00110793953 | 0.00220955019
  Clogtopus              0.000133301577 | 0.000665873065 | 0.00133016044
  LaundryYeti            8.33204291e-05 | 0.000416344142 | 0.000832043642
  SteamGenie             4.99947572e-05 | 0.000249868953 | 0.000499475923
  BathBombBehemoth       3.33309492e-05 | 0.00016660707 | 0.000333094981
  DrainKraken            1.33328241e-05 | 6.66539363e-05 | 0.000133282416
  GeyserGorilla          7.99983845e-06 | 3.99959614e-05 | 7.99838461e-05
  ThroneColossus         5.55547423e-06 | 2.77757447e-05 | 5.55474236e-05
  PlungerPaladin         3.99995745e-06 | 1.99989362e-05 | 3.99957448e-05
  HaloHamster            3.33330898e-06 | 1.66660579e-05 | 3.33308984e-05
  CometCommode           2.22221093e-06 | 1.11108287e-05 | 2.22210927e-05
  ConstellationClam      1.53845609e-06 | 7.69217137e-06 | 1.53840701e-05
  StarlightSeraph        1.11110841e-06 | 5.55548796e-06 | 1.11108407e-05
  TheLastToilet          6.66666156e-07 | 3.33332056e-06 | 6.66661556e-06
  EmergencyUniverse      3.99999853e-07 | 1.99999633e-06 | 3.99998533e-06
  InfiniteOccupied       1.99999967e-07 | 9.99999167e-07 | 1.99999667e-06
  CosmicCourtesy         6.66666667e-08 | 3.33333333e-07 | 6.66666667e-07
FIRST SIGHT AT FIRST UNLOCK: expected flushes / online minutes, 75% uptime, speed level 0, no unlock time.
For any later pool use p above: E[N]=1/p; E[minutes]=cooldown/(60*0.75*p). Zero p => infinite.
Item | first tier | 1x N/min | 5x N/min | 10x stress N/min
Poop | 1 | 2.68 / 0.09 | inf / inf | inf / inf
ToiletPaper | 1 | 9.38 / 0.31 | 4.27 / 0.14 | inf / inf
Rat | 1 | 25.32 / 0.84 | 5.33 / 0.18 | 2.86 / 0.10
Fish | 1 | 80.00 / 2.67 | 16.00 / 0.53 | 8.00 / 0.27
Duck | 2 | 250.00 / 7.78 | 50.00 / 1.56 | 25.00 / 0.78
GoldenPoop | 3 | 1000.00 / 28.89 | 200.00 / 5.78 | 100.00 / 2.89
ToiletBaby | 4 | 5000.00 / 127.78 | 1000.00 / 25.56 | 500.00 / 12.78
SewerShark | 5 | 50000.50 / 1111.12 | 10000.50 / 222.23 | 5000.50 / 111.12
KingPoop | 5 | 100000.00 / 2222.22 | 20000.00 / 444.44 | 10000.00 / 222.22
AlienToilet | 6 | 1000000.00 / 20000.00 | 200000.00 / 4000.00 | 100000.00 / 2000.00
Mystery | 7 | 10000000.00 / 177777.78 | 2000000.00 / 35555.56 | 1000000.00 / 17777.78
SudsSlug | 1 | 5.36 / 0.18 | inf / inf | inf / inf
PocketPuddle | 1 | 5.36 / 0.18 | 7.11 / 0.24 | inf / inf
LoopyLoofah | 2 | 9.20 / 0.29 | 93.77 / 2.92 | inf / inf
SoggySock | 2 | 9.20 / 0.29 | 18.75 / 0.58 | inf / inf
TubTadpole | 1 | 10.55 / 0.35 | 2.67 / 0.09 | 1.90 / 0.06
BrushBristle | 2 | 15.70 / 0.49 | 5.27 / 0.16 | 6.25 / 0.19
RollMole | 2 | 19.06 / 0.59 | 4.90 / 0.15 | 3.57 / 0.11
CapybaraCap | 3 | 26.73 / 0.77 | 8.51 / 0.25 | 8.42 / 0.24
DrainCrab | 3 | 36.35 / 1.05 | 8.51 / 0.25 | 5.26 / 0.15
ToothpasteGoose | 3 | 50.89 / 1.47 | 10.94 / 0.32 | 6.01 / 0.17
SpongeKnight | 4 | 101.66 / 2.60 | 21.73 / 0.56 | 11.84 / 0.30
BubbleBeard | 4 | 120.97 / 3.09 | 24.99 / 0.64 | 13.02 / 0.33
PlungerPogo | 4 | 350.42 / 8.96 | 70.42 / 1.80 | 35.42 / 0.91
BathMatBat | 5 | 451.25 / 10.03 | 91.26 / 2.03 | 46.27 / 1.03
DiscoBidet | 5 | 650.80 / 14.46 | 130.80 / 2.91 | 65.81 / 1.46
TowelTornado | 6 | 901.71 / 18.03 | 181.72 / 3.63 | 91.73 / 1.83
PorcelainPoodle | 6 | 1500.35 / 30.01 | 300.35 / 6.01 | 150.35 / 3.01
FaucetPharaoh | 7 | 2200.80 / 39.13 | 440.80 / 7.84 | 220.80 / 3.93
RoyalFlushFrog | 8 | 3202.14 / 54.08 | 642.15 / 10.85 | 322.15 / 5.44
GoldenGargler | 8 | 4502.02 / 76.03 | 902.02 / 15.23 | 452.02 / 7.63
Clogtopus | 7 | 7500.23 / 133.34 | 1500.23 / 26.67 | 750.23 / 13.34
LaundryYeti | 8 | 12000.37 / 202.67 | 2400.37 / 40.54 | 1200.37 / 20.27
SteamGenie | 9 | 20001.56 / 320.02 | 4001.56 / 64.02 | 2001.56 / 32.02
BathBombBehemoth | 9 | 30001.33 / 480.02 | 6001.33 / 96.02 | 3001.33 / 48.02
DrainKraken | 9 | 75000.83 / 1200.01 | 15000.83 / 240.01 | 7500.83 / 120.01
GeyserGorilla | 10 | 125000.83 / 1888.90 | 25000.83 / 377.79 | 12500.83 / 188.90
ThroneColossus | 10 | 180000.20 / 2720.00 | 36000.20 / 544.00 | 18000.20 / 272.00
PlungerPaladin | 11 | 250001.11 / 3555.57 | 50001.11 / 711.13 | 25001.11 / 355.57
HaloHamster | 11 | 300000.33 / 4266.67 | 60000.33 / 853.34 | 30000.33 / 426.67
CometCommode | 12 | 450001.19 / 6000.02 | 90001.19 / 1200.02 | 45001.19 / 600.02
ConstellationClam | 12 | 650000.72 / 8666.68 | 130000.72 / 1733.34 | 65000.72 / 866.68
StarlightSeraph | 13 | 900001.59 / 11200.02 | 180001.59 / 2240.02 | 90001.59 / 1120.02
TheLastToilet | 13 | 1500000.15 / 18666.67 | 300000.15 / 3733.34 | 150000.15 / 1866.67
EmergencyUniverse | 14 | 2500000.75 / 28888.90 | 500000.75 / 5777.79 | 250000.75 / 2888.90
InfiniteOccupied | 14 | 5000000.50 / 57777.78 | 1000000.50 / 11555.56 | 500000.50 / 5777.78
CosmicCourtesy | 15 | 15000000.00 / 160000.00 | 3000000.00 / 32000.00 | 1500000.00 / 16000.00
TYPICAL SHOWCASE: 60 min at fixed tier; floor(expected copies), best income first, 10 slots.
This is economy-v2's steady showcase estimator, NOT a stochastic mean or a fresh-account acquisition cohort.
Cash 1.4, luck min(5,toilet*1.4), speed factor 0.8; active includes every drop sale (optimistic comparator).
Tier | typical display/s | exact mean best-10/s | active/s | typical passive share | typical composition
01 Basic             | 140.00 | 140.00 | 251.88 | 35.72% | 10xFish
02 Dirty             | 840.00 | 827.06 | 413.59 | 67.01% | 10xDuck
03 Golden            | 2710.40 | 3199.37 | 636.85 | 80.97% | 3xGoldenPoop,7xDuck
04 Diamond           | 4804.80 | 9489.87 | 975.43 | 83.12% | 4xGoldenPoop,6xDuck
05 Radioactive       | 15120.00 | 23645.17 | 2878.20 | 84.01% | 1xToiletBaby,5xGoldenPoop,4xBathMatBat
06 Demon             | 31360.00 | 53443.68 | 5252.40 | 85.65% | 1xToiletBaby,6xGoldenPoop,3xPorcelainPoodle
07 Galaxy            | 60480.00 | 104542.33 | 9745.95 | 86.12% | 1xClogtopus,1xToiletBaby,3xFaucetPharaoh,5xGoldenPoop
08 CoralCommode      | 90720.00 | 185642.01 | 14176.72 | 86.49% | 1xClogtopus,1xToiletBaby,3xFaucetPharaoh,1xGoldenGargler,4xGoldenPoop
09 CloudCushion      | 136080.00 | 357615.69 | 20064.63 | 87.15% | 1xClogtopus,1xToiletBaby,4xFaucetPharaoh,2xGoldenGargler,2xGoldenPoop
10 ClockworkCloset   | 246400.00 | 630372.45 | 28502.48 | 89.63% | 1xClogtopus,2xToiletBaby,5xFaucetPharaoh,2xGoldenGargler
11 DragonKiln        | 436800.00 | 1150000.67 | 52422.88 | 89.28% | 1xClogtopus,1xLaundryYeti,2xToiletBaby,5xFaucetPharaoh,1xGoldenGargler
12 AuroraThrone      | 655200.00 | 2062308.33 | 82903.23 | 88.77% | 1xClogtopus,1xLaundryYeti,2xToiletBaby,6xFaucetPharaoh
13 AstralAltar       | 1285200.00 | 3683361.89 | 171692.97 | 88.22% | 2xClogtopus,1xLaundryYeti,3xToiletBaby,4xFaucetPharaoh
14 ParadoxPotty      | 1904000.00 | 6299804.71 | 274197.12 | 87.41% | 2xClogtopus,1xLaundryYeti,3xToiletBaby,4xFaucetPharaoh
15 InfinityFlush     | 2856000.00 | 10136330.04 | 417156.93 | 87.26% | 2xClogtopus,1xLaundryYeti,3xToiletBaby,4xFaucetPharaoh
CONDITIONAL POST-GALAXY COHORT: 200 seeds; synthetic Galaxy at minute 35; 8 Ducks + 2 GoldenPoops, 10 slots.
Zero wallet, cash/luck 1.4, speed .8, 75% uptime, collect 30s; retain first/displayed copies, sell surplus.
No offline/daily/events/passes/rebirth/further upgrades. Pending accrual continuous; no travel or latency model.
These are conditional estimates, not a proof of the owner's 35-minute Galaxy target.
Tier | price | p50 cumulative min | p90 cumulative min
08 CoralCommode      | 160000000 | 86.71 | 101.56
09 CloudCushion      | 400000000 | 129.33 | 156.49
10 ClockworkCloset   | 1000000000 | 172.33 | 209.25
11 DragonKiln        | 2500000000 | 224.20 | 267.49
12 AuroraThrone      | 6250000000 | 284.18 | 357.03
13 AstralAltar       | 15625000000 | 365.05 | 454.12
14 ParadoxPotty      | 39062500000 | 457.77 | 575.97
15 InfinityFlush     | 97656250000 | 568.42 | 717.31
MAX RATE: T15 ten Secrets = 300000000 coins/s at cash 1, 3000000000 at hard cash 10.
Global 9e15-subcoin storage lasts 83.33 / 8.33 online minutes for those plots (cash 1 / 10).
PASS: counts, IDs, 9 ordered bands, exact income ladder, unique cumulative pools, 45 unit-mass distributions, independent fallback products, model budgets, price growth, floor/cap bounds, rebirth gates, seeded replay.
```

</details>

## Validation and remaining work

- **Passed:** JSON-derived Luau proof, including all 45 probability sums, income/share checks, conditional pacing tolerances and seeded replay.
- **Passed:** StyLua check on the added Luau script; `rojo build -o build.rbxl`; `git diff --check`.
- **Unavailable:** Selene was attempted but the repository's configured `roblox` standard library is missing. No lint-pass claim.
- **Scope:** only the Wave 1 documents/research and proof scripts are added; `src/` and `assets/` remain unchanged. No commit or push. Build output is ignored by the existing project.
- **Assumptions:** owner Galaxy target is an input to the conditional experiment, not a tested first-run result; 10x is stress-only; merged permanent-upgrade tuning must be rerun with the actual expanded pools.

The short [research note](../research/wave1-collectibles.md) links the official collect-game examples and current technical sources. Funny/shareable character criteria are design inferences, not a claimed retention study. Final art quality, imported dimensions/pivots, uploaded permissions, live UI effects and fresh-account permanent-upgrade timing remain implementation/art acceptance work. This delivery intentionally implements no production catalog, mutation, Divine tier or world.
