# Bundle unmodified production modules for the Luau CLI's mocked Roblox environment.
param([switch]$Baseline, [switch]$Audit2Baseline, [switch]$DisplayCollectBaseline)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    & luau (Join-Path $PSScriptRoot 'check-monetization-ids.luau')
    if ($LASTEXITCODE -ne 0) { throw 'Production monetization ID checks failed' }
}
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    $chatConfig = (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $workspaceRoot 'default.project.json') | ConvertFrom-Json).tree.TextChatService
    if ($chatConfig.'$properties'.ChatVersion -ne 'TextChatService' -or !$chatConfig.'$properties'.CreateDefaultTextChannels -or !$chatConfig.ChatWindowConfiguration.'$properties'.Enabled) {
        throw 'Modern default chat channels and window must be enabled in the built place'
    }
}
$generatedPath = Join-Path $workspaceRoot '.audit-check.generated.luau'
$parts = [System.Collections.Generic.List[string]]::new()
$revision = if ($DisplayCollectBaseline) { 'b91a3bb82be41ef7507f88ef46b0f8b50caf3404' } elseif ($Audit2Baseline) { 'f0597c1ee64279a462d1ce25380c7e96de798ee1' } else { 'b08b852' }
$baselinePaths = @()
if ($Baseline -or $Audit2Baseline -or $DisplayCollectBaseline) {
    $baselinePaths = @(& git ls-tree -r --name-only $revision -- src)
    if ($LASTEXITCODE -ne 0) { throw "Cannot enumerate baseline $revision" }
}
$parts.Add('local sources = {}')
$parts.Add((& (Join-Path $PSScriptRoot 'wave1-spec-fixture.ps1')))
$parts.Add('local displayCollectBaseline = ' + $DisplayCollectBaseline.IsPresent.ToString().ToLower())
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'src') -Recurse -Filter '*.luau')) {
    $relative = $file.FullName.Substring($workspaceRoot.Length + 1).Replace('\', '/')
    $moduleName = $relative.Substring(0, $relative.Length - 5)
    if ($moduleName -eq 'src/server/init.server') { $moduleName = 'src/server' }
    if ($Baseline -or $Audit2Baseline -or $DisplayCollectBaseline) {
        # New v2-only helpers are not dependencies of the pinned baseline source.
        if ($relative -notin $baselinePaths) { continue }
        $source = (& git show "${revision}:$relative") -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Cannot read baseline $relative" }
    } else {
        $source = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
    }
    $parts.Add("sources['$moduleName'] = [====[`n$source`n]====]")
}
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-harness.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'presentation-audit.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'check-audit.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-upgrades.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-rebirth.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit2-server.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-display-collect.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-economy-v2.luau')))
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-admin.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-chat-native.luau')))
}
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-path-catalog.luau')))
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-merge-catalog.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-flushanywhere.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-autoflush-animation.luau')))
}
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-permanent.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-rebirth-values.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-catalog2.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-free-slots.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-rebirth-balance.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-wave1.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-luck-linear.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-wire-ids.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit3-server.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-autocollect-anywhere.luau')))
}
$parts.Add('do')
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'ui-harness.luau')))
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'rebirth-click-ui-checks.luau')))
    $parts.Add('test("rebirth click: UI gates and pending lock", H.CheckRebirthClick)')
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-rebirth-click.luau')))
}
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit2-client.luau')))
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-display-client.luau')))
if (!$Baseline -and !$Audit2Baseline -and !$DisplayCollectBaseline) {
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'ui-flushanywhere.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'ui-autocollect-anywhere.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-chat-client.luau')))
    $parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-cosmetic-merge.luau')))
}
$parts.Add('end')
$parts.Add('print(string.format("Audit regressions: %d passed, %d failed", passed, #failures)); assert(#failures == 0, table.concat(failures, "\n"))')
try {
    [System.IO.File]::WriteAllText($generatedPath, ($parts -join "`n"), [System.Text.UTF8Encoding]::new($false))
    & luau $generatedPath
    if ($LASTEXITCODE -ne 0) { throw 'Security audit regression checks failed' }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
