# Resolving the uploaded icons

`Assets.Icons`, `ItemIcons` and `ToiletIcons` retain 105 unique uploaded **Decal** IDs: the original 37 UI/item/toilet IDs, 44 Wave 1 item/toilet IDs, and 24 unique pass/product IDs. The 26 new pass/product keys include two shared-ID aliases. `IconResolver` loads their wrappers on the server, reads the nested Decal's Image content, destroys each unparented container, and replicates `ResolvedIcons` attributes. Four workers limit requests. Errors preserve vector art. Client startup waits at most two seconds in a background task; late results update existing icons and enter one deduplicated preload queue. `IsLoaded` still gates replacing the vector art.

For personal uploads used in the group experience, runtime insertion is permission-dependent. Shared assets can load; public free Creator Store assets additionally require **Allow Loading Third Party Assets** in Studio Experience Settings for `AssetService:LoadAssetAsync`. InsertService is a compatibility fallback, not a permission bypass. Restricted underlying Images need permission for the target experience too. See [research](research/icons-spawn-ui.md). No credentials, proxy service, guessed ID offsets, or automatic permission changes are used.

If runtime resolution fails, run this in the **Studio command bar in Edit mode**, signed in as the uploader. It reads only the configured allowlist and prints a pasteable override table. Editor `GetObjects` is the fallback when the experience-context loader cannot insert the personal Decal. Inspect warnings: failed entries are omitted, never guessed.

```lua
local A = require(game.ReplicatedStorage.Shared.Config.Assets)
local C = require(game.ReplicatedStorage.Shared.IconContent)
local lines = { "IconImages = {" }
for _, id in ipairs(C.Ids(A)) do
    local model
    local ok, result = pcall(function()
        local loaded, object = pcall(function()
            return game:GetService("InsertService"):LoadAsset(tonumber(id))
        end)
        model = if loaded then object else game:GetObjects("rbxassetid://" .. id)[1]
        local decal = model:FindFirstChildWhichIsA("Decal", true)
        local image = decal and C.Image(decal.Texture)
        assert(image and C.Id(image) ~= id, "No Image content")
        return image
    end)
    if model then model:Destroy() end
    if ok then table.insert(lines, string.format('    ["%s"] = "%s",', id, result))
    else warn(id, result) end
end
table.insert(lines, "},")
print(table.concat(lines, "\n"))
```

Paste the printed table over `IconImages = {}` in `src/shared/Config/Assets.luau`. Keys are **Decal ID strings**, values are **Image content strings**; aliases such as Coin/Coins share an entry. Overrides take precedence on server and client and skip wrapper loading. Do not replace `uploaded-ids.json`: it records the actual uploaded Decals. A direct Image override still cannot bypass Image permissions/moderation.

Verify in the published group experience using an account other than the uploader. Inspect `ReplicatedStorage.ResolvedIcons`: `Complete` means all requests finished, not that all succeeded. A missing `Image_<decalId>` attribute means fallback art is expected. A present attribute with vector art still visible means the client has not successfully loaded that Image.
