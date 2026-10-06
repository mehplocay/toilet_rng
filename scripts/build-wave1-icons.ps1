param(
    [string]$Blender = 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe',
    [string[]]$Only,
    [ValidateRange(8, 4096)][int]$Samples = 64,
    [switch]$Draft,
    [switch]$ValidateOnly,
    [switch]$SheetsOnly
)
$ErrorActionPreference = 'Stop'
$iconRoot = Split-Path -Parent $PSScriptRoot
if (-not $SheetsOnly) {
    if (-not (Test-Path -LiteralPath $Blender)) { throw "Blender not found: $Blender" }
    $blenderArgs = @('--background', '--factory-startup', '--python-exit-code', '1', '--python', (Join-Path $iconRoot 'assets/blender/render_wave1_icons.py'), '--', '--samples', "$Samples")
    if ($Only) { $blenderArgs += '--only'; $blenderArgs += $Only }
    if ($Draft) { $blenderArgs += '--draft' }
    if ($ValidateOnly) { $blenderArgs += '--validate-only' }
    & $Blender @blenderArgs
    if ($LASTEXITCODE -ne 0) { throw "Wave 1 icon build failed ($LASTEXITCODE)" }
}

# Keep contact sheets isolated from the existing icon manifest and sheet script.
Add-Type -AssemblyName System.Drawing
$sheetRoot = if ($Draft) { 'assets/icons/.scratch/wave1/draft' } else { 'assets/icons' }
$manifest = Get-Content -Raw (Join-Path $iconRoot "$sheetRoot/manifest-wave1.json") | ConvertFrom-Json
foreach ($category in @('items', 'toilets', 'small')) {
    $isSmall = $category -eq 'small'
    $entries = if ($isSmall) {
        @($manifest.assets | Where-Object { $_.size[0] -eq 128 })
    } else {
        @($manifest.assets | Where-Object { $_.size[0] -eq 512 -and $_.category -eq $category })
    }
    $columns = 4
    $cell = if ($isSmall) { 256 } else { 320 }
    $rowHeight = if ($isSmall) { 170 } else { 205 }
    $rows = [int][math]::Ceiling($entries.Count / $columns)
    $bitmap = New-Object System.Drawing.Bitmap ($columns * $cell), ($rows * $rowHeight + 70)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.Clear([System.Drawing.Color]::FromArgb(229, 237, 250))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $font = New-Object System.Drawing.Font 'Segoe UI', 10, ([System.Drawing.FontStyle]::Bold)
    $title = New-Object System.Drawing.Font 'Segoe UI', 22, ([System.Drawing.FontStyle]::Bold)
    $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(18, 25, 47))
    $dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 39, 65))
    $light = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(248, 251, 255))
    try {
        $g.DrawString(('TOILET RNG  /  WAVE 1 ' + $category.ToUpper()), $title, $ink, 15, 12)
        for ($i = 0; $i -lt $entries.Count; $i++) {
            $entry = $entries[$i]
            $x = ($i % $columns) * $cell
            $y = [int][math]::Floor($i / $columns) * $rowHeight + 70
            $sz = [int]($cell / 2)
            $g.FillRectangle($light, $x, $y, $sz, $sz)
            $g.FillRectangle($dark, $x + $sz, $y, $sz, $sz)
            $path = Join-Path $iconRoot $entry.file
            if (Test-Path -LiteralPath $path) {
                $img = [System.Drawing.Image]::FromFile($path)
                try {
                    if ($isSmall) {
                        $g.DrawImageUnscaled($img, $x, $y)
                        $g.DrawImageUnscaled($img, $x + $sz, $y)
                    } else {
                        $g.DrawImage($img, $x, $y, $sz, $sz)
                        $g.DrawImage($img, $x + $sz, $y, $sz, $sz)
                    }
                } finally { $img.Dispose() }
            } else {
                $g.DrawString('MISSING', $font, $ink, $x + 10, $y + 40)
            }
            $g.DrawString($entry.display_name, $font, $ink, $x + 8, $y + $sz + 5)
        }
        $sheet = Join-Path $iconRoot "$sheetRoot/_sheet_wave1_$category.png"
        $bitmap.Save($sheet, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host $sheet
    } finally {
        $g.Dispose(); $bitmap.Dispose(); $font.Dispose(); $title.Dispose()
        $ink.Dispose(); $dark.Dispose(); $light.Dispose()
    }
}
Write-Host "Wave 1 sheets finished. Manifest complete: $($manifest.complete); validated: $($manifest.validated)/88."
