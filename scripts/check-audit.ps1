# Bundle unmodified production modules for the Luau CLI's mocked Roblox environment.
param([switch]$Baseline, [switch]$Audit2Baseline)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$generatedPath = Join-Path $workspaceRoot '.audit-check.generated.luau'
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('local sources = {}')
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'src') -Recurse -Filter '*.luau')) {
    $relative = $file.FullName.Substring($workspaceRoot.Length + 1).Replace('\', '/')
    $moduleName = $relative.Substring(0, $relative.Length - 5)
    if ($moduleName -eq 'src/server/init.server') { $moduleName = 'src/server' }
    if ($Baseline -or $Audit2Baseline) {
        $revision = if ($Audit2Baseline) { 'f0597c1ee64279a462d1ce25380c7e96de798ee1' } else { 'b08b852' }
        $source = (& git show "${revision}:$relative") -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Cannot read baseline $relative" }
    } else {
        $source = Get-Content -Raw -LiteralPath $file.FullName
    }
    $parts.Add("sources['$moduleName'] = [====[`n$source`n]====]")
}
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'audit-harness.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'presentation-audit.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'check-audit.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'audit-upgrades.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'audit-rebirth.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'audit2-server.luau')))
$parts.Add('do')
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'ui-harness.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'audit2-client.luau')))
$parts.Add('end')
$parts.Add('print(string.format("Audit regressions: %d passed, %d failed", passed, #failures)); assert(#failures == 0, table.concat(failures, "\n"))')
try {
    [System.IO.File]::WriteAllText($generatedPath, ($parts -join "`n"), [System.Text.UTF8Encoding]::new($false))
    & luau $generatedPath
    if ($LASTEXITCODE -ne 0) { throw 'Security audit regression checks failed' }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
