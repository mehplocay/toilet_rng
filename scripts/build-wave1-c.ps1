param(
    [string]$Blender = 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe',
    [string[]]$Only,
    [switch]$NoRender,
    [switch]$VerifyOnly,
    [switch]$Draft,
    [switch]$SheetsOnly
)
$ErrorActionPreference = 'Stop'
$assetRoot = Split-Path -Parent $PSScriptRoot
if (-not $SheetsOnly) {
    if (-not (Test-Path -LiteralPath $Blender)) { throw "Blender not found: $Blender" }
    $blenderArgs = @('--background', '--factory-startup', '--threads', '4', '--python-exit-code', '1', '--python', (Join-Path $assetRoot 'assets/blender/build_wave1_c.py'), '--')
    if ($Only) {
        $blenderArgs += '--only'
        $blenderArgs += @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
    }
    if ($NoRender) { $blenderArgs += '--no-render' }
    if ($VerifyOnly) { $blenderArgs += '--verify-only' }
    if ($Draft) { $blenderArgs += '--draft' }
    & $Blender @blenderArgs
    if ($LASTEXITCODE -ne 0) { throw "Group C build failed ($LASTEXITCODE)" }
}
if (-not $NoRender -and -not $VerifyOnly) {
    Add-Type -AssemblyName System.Drawing
    $manifest = Get-Content -Raw (Join-Path $assetRoot 'assets/manifest-wave1-c.json') | ConvertFrom-Json
    $entries = @($manifest.assets)
    foreach ($front in @($false, $true)) {
        $bitmap = New-Object System.Drawing.Bitmap 1280, ([int][math]::Ceiling($entries.Count / 4) * 374 + 68)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::FromArgb(234,239,255))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $font = New-Object System.Drawing.Font 'Segoe UI', 13, ([System.Drawing.FontStyle]::Bold)
        $small = New-Object System.Drawing.Font 'Segoe UI', 10
        $title = New-Object System.Drawing.Font 'Segoe UI', 23, ([System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(25,33,63))
        $graphics.DrawString('TOILET RNG  /  WAVE 1 C  /  GODLY - CELESTIAL - SECRET', $title, $brush, 16, 12)
        for ($i=0; $i -lt $entries.Count; $i++) {
            $entry = $entries[$i]
            $x = ($i % 4) * 320
            $y = [int][math]::Floor($i / 4) * 374 + 68
            $preview = if ($front) { $entry.front_preview } else { $entry.preview }
            $previewPath = Join-Path $assetRoot $preview
            if ($Draft) { $previewPath = Join-Path (Join-Path (Split-Path -Parent $previewPath) 'draft') (Split-Path -Leaf $previewPath) }
            if (-not (Test-Path -LiteralPath $previewPath)) { throw "Missing preview: $previewPath" }
            $img = [System.Drawing.Image]::FromFile($previewPath)
            $expected = if ($Draft) { 320 } else { 768 }
            if ($img.Width -ne $expected -or $img.Height -ne $expected) { throw "Wrong preview dimensions: $previewPath" }
            $graphics.DrawImage($img, $x+6, $y, 308, 308)
            $img.Dispose()
            $graphics.DrawString($entry.name, $font, $brush, $x+12, $y+310)
            $graphics.DrawString(("{0}  |  {1} / {2} tris" -f $entry.rarity,$entry.tris,$entry.budget), $small, $brush, $x+12, $y+338)
        }
        $suffix = if ($front) { '_front' } else { '' }
        if ($Draft) { $suffix += '_draft' }
        $sheet = Join-Path $assetRoot ("assets/previews/wave1/_sheet_c{0}.png" -f $suffix)
        $bitmap.Save($sheet, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose(); $bitmap.Dispose(); $font.Dispose(); $small.Dispose(); $title.Dispose(); $brush.Dispose()
        Write-Host $sheet
    }
}
Write-Host 'Group C finished. See docs/wave1-art-c.md for the Studio acceptance boundary.'
