# Blender-rendered icons and game art

All artwork is original Blender geometry. Item and toilet designs reuse `assets/blender/builders.py`; the icon build increases render geometry density and assigns glossy enamel materials in memory. It does not modify the original builders, FBX models, palette, previews, or `src/`.

## Outputs

- `assets/icons/items/`: all 11 collectibles, transparent 512x512 and 128x128 PNGs.
- `assets/icons/toilets/`: all seven tiers, transparent 512x512 and 128x128 PNGs.
- `assets/icons/ui/`: 19 new Blender icons, transparent 512x512 and 128x128 PNGs.
- `assets/icons/passes/`: 25 pass/product symbols at both sizes: 21 new sculptures and four byte-identical copies of existing UI icons.
- `assets/icons/art/`: a text-free game icon (512 and 128), three text-free thumbnails (1920x1080), and a transparent stacked TOILET RNG logo (2048x1024 and 1024x512).
- `assets/icons/manifest.json`: 131 PNG records, names, dimensions, intended Config keys, transparency, and integration status. Pass records also carry catalog display names, offer kinds, and provisional/integration notes.
- `assets/icons/validation.json`: file dimensions, alpha checks, thumbnail byte limits, and completeness.
- `assets/icons/_sheet_{items,toilets,ui,small,art}.png`: labeled review sheets. Icons appear on both light and dark backgrounds; the small sheet displays native 128px exports.
- `assets/icons/_sheet_passes.png` and `_sheet_passes_small.png`: complete pass/product review on light and dark cards, including a native 128px sheet.

The manager normally uploads the 512px icon variants. The 128px versions are available for inspection or a deliberately smaller download budget; they do not need duplicate Config keys. Contact sheets are review artifacts, not game textures.

## Rebuild

Requires Blender 4.5, Windows PowerShell, and Windows' bundled Arial Bold font. NumPy comes with Blender; contact sheets use bundled System.Drawing. No pip packages, plugins, external asset IDs, or downloads are required.

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-icons.ps1

# Focused iteration; use -Command so PowerShell preserves the array of names.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ./scripts/build-icons.ps1 -Only Shop,Coin,GameIcon -Samples 32"

# Recheck the complete output set and rebuild contact sheets without rendering.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-icons.ps1 -ValidateOnly

# Render just the pass/product set (including copies of the four existing icons).
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-icons.ps1 -PassesOnly

# Focused pass iteration, with complete validation afterwards.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ./scripts/build-icons.ps1 -Only VIPPack,UltimateBundle,LuckyFlush20 -Samples 32"

# Override Blender's path if needed.
./scripts/build-icons.ps1 -Blender 'D:\Tools\Blender\blender.exe'
```

The execution policy flag applies only to this child process. The default executable is `C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe`. Default quality is 64 Cycles samples with denoising. Icons render at 1024px before reduction. A partial build updates selected outputs and reports overall completeness; it never silently declares missing files complete. A complete build is needed after a shared material, lighting, or compositing change.

`render_icons.py` contains the lighting, framing, scene compositions, output mapping and verification. `icon_models.py` contains the new UI sculptures. `icon_pixels.py` implements lossless PNG I/O, dark contours, a subtle offset alpha shadow, and resizing with premultiplied alpha. Final PNGs use straight alpha with no white matte; fully transparent pixels have zero RGB. Scratch beauty renders are ignored under `assets/icons/.scratch/`. Shadow is a restrained graphic silhouette shadow, not an opaque studio floor.

`pass_models.py` contains the pass/product sculptures, working catalog metadata and reuse mapping. It uses the same enamel, studio lights and silhouette outline as the UI set. Nested sculpture groups retain their local scale and tilt when placed in the render scene. `-PassesOnly` does not render or overwrite existing UI/item/toilet artwork; its four reuse records copy the existing local PNG bytes into the pass folder.

## Pass/product catalog mapping

This art batch follows the user's extended working list. The checked-in catalog still has nine passes and four products. Existing exact display names take precedence; new offers remain marked `working-list; pending extended catalog`. No runtime catalog, IDs, purchases or odds are changed by this task. Lucky Flush renders are artwork only, while the checked-in monetization design continues to exclude paid luck.

| Working-list name | PNG stem / display name | Intended Assets key |
| --- | --- | --- |
| VIP | `VIPPack` / VIP Pack | `Assets.Icons.VIPPack` |
| Coin Pack Mini | `Coins10Minutes` / Coin Pack: 10 Minutes | `Assets.Icons.CoinPack` |
| Coin Pack Small | `Coins1Hour` / Coin Pack: 1 Hour | proposed `Assets.Icons.CoinPackSmall` |
| Coin Pack Large | `Coins6Hours` / Coin Pack: 6 Hours | proposed `Assets.Icons.CoinPackLarge` |
| Coin Pack Huge | `CoinPackHuge` / Coin Pack Huge | proposed `Assets.Icons.CoinPackHuge` |
| Path Boost | `PathBoost` / Path Boost: 10 Minutes | `Assets.Icons.PathBoost` |
| Fast Flush | `FastFlush`, copied from `ui/Flush` | `Assets.Icons.Flush` |
| Sparkle Trail | `SparkleTrail`, copied from `ui/Gem` | `Assets.Icons.Gem` |
| VIP Star | `VIPStar`, copied from `ui/Crown` | `Assets.Icons.Crown` |
| Custom Plot Color | `CustomPlotColor`, copied from `ui/Home` | `Assets.Icons.Home` |

All other new stems map to `Assets.Icons.<stem>`; see the manifest's explicit `intended_assets_key`. Small/Large currently share `Icons.CoinPack` in the catalog: dedicated keys are proposals so the manager can wire the distinct silhouettes without overwriting Mini. The three current timed packs are mapped in ascending size; no duration is invented for Huge. Filename `name` remains a stable machine identifier; `display_name` is the exact human-facing name used on contact sheets.

The existing four pass icons require no duplicate image upload for in-game use. Their copies make this delivery self-contained. New 512px variants are upload candidates after manager review; 128px variants are inspection/download-budget alternatives. Roblox's pass uploader uses circular previews, so keep the main silhouette inside that crop and check the preview separately from the rectangular shop card. See [pass rendering source checks](research/pass-icon-rendering.md).

`preview_icon_art.py` is an optional 32-sample campaign review pass. Run it with Blender's `--background --factory-startup --python-exit-code 1 --python assets/blender/preview_icon_art.py`; optional names follow `--`. It writes only to the ignored `.scratch/art-review/` directory. The delivered files come from the 64-sample final pass. Native Blender PNG decoding was compared against the independent reader and matched within floating-point precision; final output validation still uses the independent reader.

The icon build is separate from `build-assets.ps1`: it does not regenerate mesh exports. Reopen or rerun these Python sources in Blender for editable geometry; generated icon `.blend` duplicates are not required.

## Upload through Creator Hub

The manager uploads the PNG files through the **Creator Hub web uploader** after art review. No upload is performed by these scripts.

1. Open [Creator Hub](https://create.roblox.com/dashboard/creations) and select the intended owning user or group.
2. Under **Creations > Development Items > Decals**, choose **Upload Asset**. The [web upload route](https://create.roblox.com/dashboard/creations/upload?assetType=Decal) accepts PNG; choose a `*_512.png` from `items`, `toilets`, `ui`, or `passes`. Give it a clear English name, such as `Toilet RNG - Shop`. Repeat using the uploader's supported selection flow. Preserve PNG transparency; do not convert to JPEG.
3. Wait for processing/moderation. Inspect the resulting image, not only a cached catalog preview. If the UI presents an image asset separately from its decal wrapper, copy the image content ID intended for UI use. Verify it in the target experience with its real permissions before entering the entire batch.
4. In the manager's integration branch, put real IDs into `src/shared/Config/Assets.luau` according to `manifest.json`. `Coin` maps to `Icons.Coins`; `RubberDuck` maps to `ItemIcons.Duck`; toilet filenames map to tier keys such as `ToiletIcons.Basic`.
5. The original UI keys now exist in `Assets.Icons`. Proposed pass/product keys that still need integration are marked `config_key_exists: false`. The manager adds these keys and consumer wiring when needed. No runtime Config or asset IDs are edited by this art-only task.
6. Check the real UI on light/dark cards and at 64–128px. Confirm that player accounts other than the uploader can load the assets. Keep the zero-ID fallback until an image is approved and accessible.

For the **game icon**, select the experience in Creator Hub and use its icon upload control with `art/GameIcon_512.png`. For **thumbnails**, current documentation points to **Configure > Places > select place > Thumbnails**; upload the three `*_1920x1080.png` files to the appropriate Home Page / Experience Detail Page tabs. These campaign images are already opaque and text-free. The transparent logo is a separate brand/UI asset; its placement and Config key are left to the manager.

See [source checks and current uploader notes](research/rendered-icons-and-image-upload.md). Roblox's official [icon guidance](https://create.roblox.com/docs/production/publishing/experience-icons) and [thumbnail guidance](https://create.roblox.com/docs/production/publishing/thumbnails) are the source for publication dimensions. No Studio upload acceptance is claimed by the local image validation.

## Art assumptions and review limits

`Gem/Stamp` is interpreted as one faceted magenta gem. `Daily` uses a calendar with a reward star. `Flush` is a porcelain/chrome handle. `OfferBurst` includes the requested OP! lettering; only the game icon and three thumbnails are text-free. The logo follows the mockup's stacked white/cyan chunky lettering and paper-roll motif, using locally available Arial Bold with sculpted bevels.

The three thumbnail scenes are promotional Blender compositions using the game's asset designs, not captures of the live hub. They need the manager's final brand and in-experience review before publication. Fine details such as whiskers, calendar cells, and crown gems naturally simplify at HUD size.

## Visual review record

The render/inspect loop covered individual 512px icons, the native 128px set, light/dark contact sheets, and full campaign compositions. Refinements included smoother bevel normals, darker basket slots, a visible page block and stronger book angle, continuous keyhole geometry, separated auto-flush arrow arcs, corrected scene transform preservation, tighter logo spacing, reduced campaign exposure, a floating rare reward with fading rays, and rising tier podiums. Existing item/toilet model designs were preserved.

The delivered direction is deliberately a glossy toy sculpture style. The low-poly palm leaves and crystal facets remain visible; the hub thumbnail uses an isometric composition, while the supplied mockup is more cinematic. Gold has strong broad specular highlights, and the smallest engraved details lose definition below 128px. These are the main remaining art differences to review in the real UI.

### Pass/product review, 2026-10-06

The pass batch uses the existing UI sheet and all seven `quality-reference-*.webp` screenshots, especially the oversized shop-card symbols in reference 7. Review refinements include preserving nested model transforms, a tilted popper, separated stacked cash, more circular-crop margin for Companion/Double Cash, a soft transparent Toilet Glow aura, matte velvet beneath the VIP crown, pointed gem cuts, and visible coins in both sack openings. Lucky Flush handles are separated from their quantity badges so both remain readable at 128px. Large has a physically larger sack as well as extra stacks. Miniature coins omit the original coin's subpixel milled-edge spheres while retaining the raised rim and currency face.

The new icons are deliberately simple toy sculptures: the cushion has a soft material without a fabric texture, the aura is a static halo, and the nameplates use generic `NAME` lettering rather than a real player name. Tiny gem facets, clock ticks, confetti and laurel leaves simplify below 128px. Final placement and relative scale still need review in the live shop after integration; no in-game screenshot or upload acceptance is claimed.

Final pass checks: 21 new sculptures rendered at 64 Cycles samples, 1024px before reduction; four existing symbols copied unchanged. All **131/131** manifest PNG records validate, including all **50** pass/product PNGs and eight byte-identical reuse variants. Dimensions, transparent borders, straight alpha and zero RGB at zero alpha pass. The native 128px and larger light/dark sheets were inspected after the final revisions. The circular-crop diagnostic reports only the outer tip of Lucky Flush x1's decorative gold sparkle (72 pixels at 512px, four at 128px); the main clover, quantity and handle remain inside. Square UI exports are not clipped. Check Creator Hub's circular preview before publication.

Repository checks for this task on `feature/passicons`: `rojo build -o build.rbxl`, `stylua --check --line-endings Windows src scripts`, Python syntax checks, manifest coverage/key checks and `git diff --check` pass. Selene was attempted but cannot run because its `roblox` standard library is missing. Changes are restricted to assets, docs and scripts; `src/` was not edited. No commit, push, upload or live integration was performed, as requested.

Original UI/art batch checks on `feature/icons`: `rojo build -o build.rbxl` succeeded. Selene's configured `roblox` standard library was missing. That batch's `stylua --check src` reported formatting/line-ending differences; no runtime files were formatted. Its Git staging attempt was denied by worktree permissions. This is historical context, not a commit attempt in the pass-icon task.
