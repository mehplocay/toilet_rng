param(
    [string]$Blender = 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe',
    [string[]]$Only,
    [switch]$NoRender,
    [switch]$Turntable,
    [switch]$SkipRoundTrip
)
$ErrorActionPreference = 'Stop'
$assetRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $Blender)) { throw "Blender not found: $Blender" }
$blenderArgs = @('--background', '--factory-startup', '--python-exit-code', '1', '--python', (Join-Path $assetRoot 'assets/blender/build.py'), '--')
if ($Only) { $blenderArgs += '--only'; $blenderArgs += $Only }
if ($NoRender) { $blenderArgs += '--no-render' }
if ($Turntable) { $blenderArgs += '--turntable' }
& $Blender @blenderArgs
if ($LASTEXITCODE -ne 0) { throw "Blender asset build failed ($LASTEXITCODE)" }
if (-not $NoRender) {
    & (Join-Path $PSScriptRoot 'asset-contact-sheets.ps1')
    & (Join-Path $PSScriptRoot 'asset-contact-sheets.ps1') -Front
}
if (-not $SkipRoundTrip) {
    & $Blender --background --factory-startup --python-exit-code 1 --python (Join-Path $assetRoot 'assets/blender/verify.py')
    if ($LASTEXITCODE -ne 0) { throw 'FBX round-trip validation failed' }
}
Write-Host 'Asset build complete. Studio import acceptance is still required; see docs/asset-pipeline.md.'
