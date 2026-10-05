param(
    [string]$Blender = 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe',
    [string[]]$Only,
    [switch]$NoRender,
    [switch]$Showcase
)
$ErrorActionPreference = 'Stop'
$assetRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $Blender)) { throw "Blender not found: $Blender" }
$blenderArgs = @('--background', '--factory-startup', '--threads', '8', '--python-exit-code', '1', '--python', (Join-Path $assetRoot 'assets/blender/build_env.py'), '--')
if ($Only) { $blenderArgs += '--only'; $blenderArgs += $Only }
if ($NoRender) { $blenderArgs += '--no-render' }
& $Blender @blenderArgs
if ($LASTEXITCODE -ne 0) { throw "Environment build failed ($LASTEXITCODE)" }
& $Blender --background --factory-startup --threads 8 --python-exit-code 1 --python (Join-Path $assetRoot 'assets/blender/verify.py') -- --manifest assets/manifest-env.json --output assets/validation-env.json
if ($LASTEXITCODE -ne 0) { throw 'Environment FBX round-trip validation failed' }
if (-not $NoRender) {
    & (Join-Path $PSScriptRoot 'env-contact-sheets.ps1')
    & (Join-Path $PSScriptRoot 'env-contact-sheets.ps1') -Front
}
if ($Showcase) {
    & $Blender --background --factory-startup --threads 8 --python-exit-code 1 --python (Join-Path $assetRoot 'assets/blender/env_showcase.py')
    if ($LASTEXITCODE -ne 0) { throw 'Environment showcase render failed' }
    if (-not $NoRender) {
        & $Blender --background --factory-startup --python-exit-code 1 --python (Join-Path $assetRoot 'assets/blender/check_env.py')
        if ($LASTEXITCODE -ne 0) { throw 'Environment delivery audit failed' }
    }
}
Write-Host 'Environment pack complete. Studio acceptance remains required; see docs/envkit.md.'
