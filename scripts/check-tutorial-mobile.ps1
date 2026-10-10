param([string]$SnapshotDirectory)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$generatedPath = Join-Path $workspaceRoot ('.tutorial-mobile-' + $PID + '.generated.luau')
$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('local sources, expectedIcons = {}, {}; local captureSnapshots = ' + ([bool]$SnapshotDirectory).ToString().ToLower())
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $workspaceRoot 'src') -Recurse -Filter '*.luau') {
    $moduleName = $file.FullName.Substring($workspaceRoot.Length + 1).Replace('\', '/') -replace '\.luau$', ''
    $parts.Add("sources['$moduleName'] = [====[`n$([IO.File]::ReadAllText($file.FullName))`n]====]")
}
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-harness.luau')))
$parts.Add([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ui-tutorial-mobile.luau')))
try {
    [IO.File]::WriteAllText($generatedPath, ($parts -join "`n"), [Text.UTF8Encoding]::new($false))
    & luau $generatedPath | ForEach-Object {
        if ($_.StartsWith('UI_SNAPSHOT ')) {
            if ($SnapshotDirectory) {
                $null = New-Item -ItemType Directory -Force -Path $SnapshotDirectory
                $name, $json = $_.Substring(12).Split(' ', 2)
                [IO.File]::WriteAllText((Join-Path $SnapshotDirectory "$name.json"), $json, [Text.UTF8Encoding]::new($false))
            }
        } else { Write-Output $_ }
    }
    if ($LASTEXITCODE -ne 0) { throw 'Touch tutorial runtime checks failed' }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
