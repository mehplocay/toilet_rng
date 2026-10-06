# Pass/product icon rendering checks

Checked 2026-10-06 for the art-only `feature/passicons` task.

- Roblox's official pass guide specifies an image no larger than 512x512, accepts PNG, and asks creators to keep important details inside the circular boundary. Delivered transparent squares are UI art; review the circular preview before publishing a pass. No asset upload or Roblox API call is part of the renderer. https://create.roblox.com/docs/production/monetization/passes
- Blender 4.5 `RenderSettings.film_transparent` makes the world transparent for compositing. Preserve RGBA through outline/shadow and premultiplied-alpha reduction, then write straight-alpha PNGs with zero RGB at zero alpha. https://docs.blender.org/api/4.5/bpy.types.RenderSettings.html
- The Principled BSDF remains the supported shader node used by the shared enamel material. Existing local Blender 4.5 material sockets are retained, rather than migrating the working pipeline to a different Blender release. https://docs.blender.org/api/main/bpy.types.ShaderNodeBsdfPrincipled.html
- Rojo supports binary place output by using the `.rbxl` extension: `rojo build -o build.rbxl`. This verifies the unchanged runtime still builds; it does not upload or integrate these PNGs. https://rojo.space/docs/v7/getting-started/new-game/

The shorter checked-in catalog deliberately excludes paid luck. The user's extended working list explicitly requests Lucky Flush art. Its manifest records are provisional artwork, not an entitlement or sales change; final offer policy/names belong to the manager's separate catalog session.
