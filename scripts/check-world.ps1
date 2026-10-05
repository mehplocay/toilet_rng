# Offline success/failure integration checks. Synthetic IDs stay inside the mock.
$ErrorActionPreference = 'Stop'
foreach ($mode in @('Empty', 'Ready', 'Mixed', 'Denied', 'TextureFailure', 'Timeout')) {
    & (Join-Path $PSScriptRoot 'check-visuals.ps1') -World -MeshMode $mode
    if ($LASTEXITCODE -ne 0) { throw "World check failed: $mode" }
}
