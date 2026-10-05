# Bundle unmodified production modules for the Luau CLI's mocked Roblox environment.
param([switch]$Baseline)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$generatedPath = Join-Path $workspaceRoot '.audit-check.generated.luau'
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('local sources = {}')
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'src') -Recurse -Filter '*.luau')) {
    $relative = $file.FullName.Substring($workspaceRoot.Length + 1).Replace('\', '/')
    $moduleName = $relative.Substring(0, $relative.Length - 5)
    if ($moduleName -eq 'src/server/init.server') { $moduleName = 'src/server' }
    if ($Baseline) {
        $source = (& git show "b08b852:$relative") -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Cannot read baseline $relative" }
    } else {
        $source = Get-Content -Raw -LiteralPath $file.FullName
    }
    $parts.Add("sources['$moduleName'] = [====[`n$source`n]====]")
}
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'audit-harness.luau')))
$parts.Add((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'check-audit.luau')))
try {
    [System.IO.File]::WriteAllText($generatedPath, ($parts -join "`n"), [System.Text.UTF8Encoding]::new($false))
    & luau $generatedPath
    if ($LASTEXITCODE -ne 0) { throw 'Security audit regression checks failed' }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
