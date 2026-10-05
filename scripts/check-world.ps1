# Offline integration checks use the actual Rojo-serialized imported templates.
$ErrorActionPreference = 'Stop'
foreach ($mode in @('Empty', 'Ready', 'Mixed', 'Invalid', 'Scaled', 'Late')) {
    & (Join-Path $PSScriptRoot 'check-visuals.ps1') -World -MeshMode $mode
    if ($LASTEXITCODE -ne 0) { throw "World check failed: $mode" }
}
