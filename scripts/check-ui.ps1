param([string]$SnapshotDirectory)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
& luau (Join-Path $PSScriptRoot 'check-monetization-ids.luau')
if ($LASTEXITCODE -ne 0) { throw 'Production monetization ID checks failed' }
$generatedPath = Join-Path $workspaceRoot '.ui-check.generated.luau'
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('local sources = {}')
$parts.Add('local expectedIcons = {}')
$parts.Add('local expectedPlaceholderIcons = {}')
$parts.Add('local expectedAudio = {}')
$audioCount = 0
$audioSeen = @{}
foreach ($batchName in @('uploaded-ids.json', 'uploaded-ids-2.json')) {
    $batch = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot "assets/audio/$batchName") | ConvertFrom-Json
    foreach ($section in @('music', 'sounds')) {
        foreach ($slot in $batch.$section.PSObject.Properties) {
            $id = [string]$slot.Value
            if ($id -notmatch '^[1-9][0-9]{11,16}$') { throw "Invalid uploaded audio ID: $($slot.Name)" }
            if ($audioSeen.ContainsKey($id)) { throw "Duplicate uploaded audio ID: $($slot.Name) / $($audioSeen[$id])" }
            $audioSeen[$id] = $slot.Name
            $audioCount++
            $parts.Add("expectedAudio['$($slot.Name)'] = 'rbxassetid://$id'")
        }
    }
}
if ($audioCount -ne 53) { throw "Expected 53 uploaded audio IDs, got $audioCount" }
$parts.Add('local previewIcons = ' + ([bool]$SnapshotDirectory).ToString().ToLower())
$manifest = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'assets/icons/manifest.json') | ConvertFrom-Json
$uploads = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'assets/icons/uploaded-ids.json') | ConvertFrom-Json
foreach ($asset in $manifest.assets) {
    if ($asset.config_key -and $asset.size[0] -eq 512) {
        $section, $key = $asset.config_key.Split('.')
        $id = $uploads.($asset.category).($asset.name)
        if (!$id -and $asset.category -in @('passes', 'products')) {
            $parts.Add("table.insert(expectedPlaceholderIcons, { Group = '$section', Key = '$key' })")
            continue
        }
        if (!$id) { throw "Missing uploaded icon: $($asset.name)" }
        $parts.Add("table.insert(expectedIcons, { Group = '$section', Key = '$key', Id = 'rbxassetid://$id' })")
    }
}
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'src') -Recurse -Filter '*.luau')) {
    $relative = $file.FullName.Substring($workspaceRoot.Length + 1).Replace('\', '/')
    $moduleName = $relative.Substring(0, $relative.Length - 5)
    $source = [IO.File]::ReadAllText($file.FullName)
    $parts.Add("sources['$moduleName'] = [====[`n$source`n]====]")
}
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-harness.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'rebirth-click-ui-checks.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'check-ui-runtime.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'presentation-ui-checks.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'reveals2-ui-checks.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-upgrades.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-rebirth.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-economy-v2.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-path-catalog.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-catalog2.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'audit-cosmetic-merge.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'audio-coverage-checks.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-admin.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-flushanywhere.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-wave1.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-toast.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-wire-ids.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'purchase-ui-checks.luau')))
$parts.Add('H.CheckPurchaseUI(); print("Purchase UI regressions passed")')
try {
    [IO.File]::WriteAllText($generatedPath, ($parts -join "`n"), [Text.UTF8Encoding]::new($false))
    $output = & luau $generatedPath
    $code = $LASTEXITCODE
    foreach ($line in $output) {
        if ($line.StartsWith('UI_SNAPSHOT ')) {
            if ($SnapshotDirectory) {
                $null = New-Item -ItemType Directory -Force -Path $SnapshotDirectory
                $name, $json = $line.Substring(12).Split(' ', 2)
                [IO.File]::WriteAllText((Join-Path $SnapshotDirectory "$name.json"), $json, [Text.UTF8Encoding]::new($false))
            }
        } else { Write-Output $line }
    }
    if ($code -ne 0) { throw 'UI runtime checks failed' }
    & luau (Join-Path $PSScriptRoot 'check-ui-layout.luau')
    if ($LASTEXITCODE -ne 0) { throw 'UI layout checks failed' }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
