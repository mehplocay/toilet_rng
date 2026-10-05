# Rendered icons and image upload

Checked 2026-10-05 for the art-only `feature/icons` task.

- Blender 4.5 `RenderSettings.film_transparent` excludes the world background from the render. Use RGBA PNG output, keep studio illumination, and composite the outline/shadow behind the rendered alpha. Source: https://docs.blender.org/api/4.5/bpy.types.RenderSettings.html
- Blender's color management distinguishes the scene/view transform from image output. This pipeline deliberately uses Standard with controlled exposure for saturated toy colors, rather than relying on default scene settings. Source: https://docs.blender.org/manual/en/4.0/render/color_management.html (the 4.5 manual page failed to fetch; actual settings were checked against Blender 4.5.10 locally).
- Roblox recommends a 512x512 game icon and checking readability at smaller sizes. PNG is an accepted icon format. Source: https://create.roblox.com/docs/production/publishing/experience-icons
- Roblox recommends 1920x1080, 16:9 thumbnail images. PNG is accepted. The Home Page uploader instructions specify images under 3 MB; the pipeline validates that limit. Current documented navigation is game > Configure > Places > select place > Thumbnails. Source: https://create.roblox.com/docs/production/publishing/thumbnails
- Image assets and wrapper decals are different asset types. Use the content ID appropriate for the target UI, and check the owning creator and experience permissions. Source: https://create.roblox.com/docs/projects/assets
- Creator Hub still has a web decal/image upload route. A February 2026 uploader report links `https://create.roblox.com/dashboard/creations/upload?assetType=Decal`; its wording bug was reported fixed in March. This corroborates the UI route, not a new dependency on a 20 MB limit. Source: https://devforum.roblox.com/t/4414109
- An August 2026 DevForum report describes approved decals displaying white while their image assets display correctly. Treat this as a reported platform issue, not guaranteed behavior: check moderation, image ID, and experience permissions before changing source PNGs or repeatedly uploading. Source: https://devforum.roblox.com/t/uploaded-decals-show-up-as-static-white-images-even-if-the-decal-itself-is-approved/4819460

No Roblox APIs, credentials, uploads, or runtime source changes are used by the art build. The manager performs web uploads and Config integration after review.
