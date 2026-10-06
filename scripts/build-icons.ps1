param(
    [string]$Blender = 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe',
    [string[]]$Only,
    [ValidateRange(8, 4096)][int]$Samples = 64,
    [switch]$ValidateOnly,
    [switch]$PassesOnly
)
$ErrorActionPreference = 'Stop'
$iconRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $Blender)) { throw "Blender not found: $Blender" }
$blenderArgs = @('--background', '--factory-startup', '--python-exit-code', '1', '--python', (Join-Path $iconRoot 'assets/blender/render_icons.py'), '--', '--samples', "$Samples")
if ($Only) { $blenderArgs += '--only'; $blenderArgs += $Only }
if ($ValidateOnly) { $blenderArgs += '--validate-only' }
if ($PassesOnly) { $blenderArgs += '--passes-only' }
& $Blender @blenderArgs
if ($LASTEXITCODE -ne 0) { throw "Icon build failed ($LASTEXITCODE)" }
& (Join-Path $PSScriptRoot 'icon-contact-sheets.ps1')
Write-Host 'Icon validation and contact sheets finished. See docs/icon-pipeline.md for upload and integration.'
