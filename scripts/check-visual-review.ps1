# Focused repeatable review captures; the full UI runner includes the same assertions.
param([string]$SnapshotDirectory = '.ui-review-focused', [switch]$HUDOnly, [switch]$RevealsOnly, [switch]$TutorialOnly)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('local sources, expectedIcons = {}, {}; local captureSnapshots, previewIcons = true, true')
$parts.Add('local reviewHUDOnly = ' + $HUDOnly.IsPresent.ToString().ToLower())
foreach ($file in Get-ChildItem (Join-Path $root 'src') -Recurse -Filter '*.luau') {
    $name = $file.FullName.Substring($root.Length + 1).Replace('\', '/') -replace '\.luau$', ''
    $parts.Add("sources['$name'] = [====[`n$([IO.File]::ReadAllText($file.FullName))`n]====]")
}
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-harness.luau')))
$parts.Add(@'
local assets = H.Load("src/shared/Config/Assets")
for _, group in ipairs({ "Icons", "ItemIcons", "ToiletIcons" }) do
    for _, id in pairs(assets[group]) do
        if id ~= "" then
            assets.IconImages[id:match("%d+")] = id
            table.insert(expectedIcons, { Id = id, Image = id })
        end
    end
end
H.Viewports = {{1920,1044},{1280,684},{375,690},{724,318},{1024,712},{768,968},{1116,483},{711,751},{711,731},{360,518},{390,722},{640,303}}
local state = { Coins = 12450, PendingCoins = 1234, Collection = {}, Inventory = {}, Displays = {},
    DisplaySlots = 5, ToiletTier = 3, Settings = {}, Stamps = 12, IndexClaims = {}, IndexCosmetics = {},
    OwnedPasses = {}, LifetimeFlushes = 134, RunFlushes = 134, RebirthLevel = 0, AutoFlush = false,
    LastClaimDay = -1, Streak = 0, TutorialDone = true, TutorialStep = 5 }
local bootRemotes = H.Remotes()
local clientRoot = H.BootClient(bootRemotes)
'@)
if ($RevealsOnly) {
    $parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'presentation-ui-checks.luau')))
    $parts.Add(@'
local catalog = H.Load("src/shared/Config/Items")
local controller = H.Load("src/client/Presentation/RevealController")
for _, viewport in ipairs(H.Viewports) do
    H.Services.UserInputService.TouchEnabled = viewport[1] < 1200
    local root = H.Root(viewport[1], viewport[2])
    local reveal = controller.Create(root, { Frame = root, SetHintVisible = function() end }, { Play = function() end, Duck = function() end })
    for _, rarity in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly", "Celestial", "Secret" }) do
        for _, item in ipairs(catalog) do
            if item.Rarity == rarity then
                reveal:Show(item)
                H.Advance(if rarity == "Secret" then 1.6 else 0.25)
                H.Layout(root)
                H.Snapshot(root, "review-reveal-" .. rarity .. "-" .. viewport[1] .. "x" .. viewport[2])
                reveal:Skip()
                H.Advance(0.3)
                break
            end
        end
    end
    reveal:Destroy()
    root:Destroy()
end
print("Independent reveal captures: all nine rarities at 12 viewports")
'@)
} else {
    if (!$TutorialOnly) { $parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-visual-review.luau'))) }
    if (!$HUDOnly) { $parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-tutorial.luau'))) }
}
$generated = Join-Path $root '.visual-review.generated.luau'
try {
    [IO.File]::WriteAllText($generated, ($parts -join "`n"), [Text.UTF8Encoding]::new($false))
    $null = New-Item -ItemType Directory -Force -Path $SnapshotDirectory
    & luau --codegen -O2 $generated | ForEach-Object {
        if ($_.StartsWith('UI_SNAPSHOT ')) {
            $name, $json = $_.Substring(12).Split(' ', 2)
            [IO.File]::WriteAllText((Join-Path $SnapshotDirectory "$name.json"), $json, [Text.UTF8Encoding]::new($false))
        } else { Write-Output $_ }
    }
    if ($LASTEXITCODE -ne 0) { throw 'Independent visual review failed' }
} finally { if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated } }
