# Focused fake-store tests; the same checks also run in check-audit.
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$generatedPath = Join-Path $workspaceRoot '.global-check.generated.luau'
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('local sources = {}')
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'src') -Recurse -Filter '*.luau')) {
    $relative = $file.FullName.Substring($workspaceRoot.Length + 1).Replace('\', '/')
    $moduleName = $relative.Substring(0, $relative.Length - 5)
    $source = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
    $parts.Add("sources['$moduleName'] = [====[`n$source`n]====]")
}
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-harness.luau')))
$parts.Add('local function test(name, callback) callback() print("PASS " .. name) end')
$parts.Add((Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'audit-global-leaderboards.luau')))
try {
    [IO.File]::WriteAllText($generatedPath, ($parts -join "`n"), [Text.UTF8Encoding]::new($false))
    & luau $generatedPath
    if ($LASTEXITCODE -ne 0) { throw 'Global leaderboard checks failed' }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
