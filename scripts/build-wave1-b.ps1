param(
    [string]$Blender = 'C:\Users\mehme\tools\blender\blender-4.5.10-windows-x64\blender.exe',
    [string[]]$Only,
    [switch]$NoRender,
    [switch]$VerifyOnly,
    [switch]$SheetsOnly
)
$ErrorActionPreference = 'Stop'
$assetRoot = Split-Path -Parent $PSScriptRoot
if (-not $SheetsOnly) {
    if (-not (Test-Path -LiteralPath $Blender)) { throw "Blender not found: $Blender" }
    $blenderArgs = @('--background', '--factory-startup', '--threads', '6', '--python-exit-code', '1', '--python', (Join-Path $assetRoot 'assets/blender/build_wave1_b.py'), '--')
    if ($Only) { $blenderArgs += '--only'; $blenderArgs += $Only }
    if ($NoRender) { $blenderArgs += '--no-render' }
    if ($VerifyOnly) { $blenderArgs += '--verify-only' }
    & $Blender @blenderArgs
    if ($LASTEXITCODE -ne 0) { throw "Wave 1 B failed ($LASTEXITCODE)" }
}
if (-not $NoRender -and -not $VerifyOnly) {
    Add-Type -AssemblyName System.Drawing
    $manifest = Get-Content -Raw (Join-Path $assetRoot 'assets/manifest-wave1-b.json') | ConvertFrom-Json
    foreach ($front in @($false, $true)) {
        $entries = @($manifest.assets)
        $bitmap = New-Object System.Drawing.Bitmap 1280, 1190
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::FromArgb(234, 239, 255))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $font = New-Object System.Drawing.Font 'Segoe UI', 13, ([System.Drawing.FontStyle]::Bold)
        $small = New-Object System.Drawing.Font 'Segoe UI', 10
        $title = New-Object System.Drawing.Font 'Segoe UI', 24, ([System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(25, 33, 63))
        $heading = if ($front) { 'TOILET RNG / WAVE 1 B / FRONT' } else { 'TOILET RNG / WAVE 1 B' }
        $graphics.DrawString($heading, $title, $brush, 16, 12)
        for ($i = 0; $i -lt $entries.Count; $i++) {
            $entry = $entries[$i]
            $x = ($i % 4) * 320
            $y = [int][math]::Floor($i / 4) * 374 + 68
            $previewPath = if ($front) { $entry.front_preview } else { $entry.preview }
            $preview = Join-Path $assetRoot $previewPath
            if (-not (Test-Path -LiteralPath $preview)) { throw "Missing preview: $preview" }
            $img = [System.Drawing.Image]::FromFile($preview)
            $graphics.DrawImage($img, $x + 6, $y, 308, 308)
            $img.Dispose()
            $graphics.DrawString($entry.name, $font, $brush, $x + 12, $y + 310)
            $graphics.DrawString(("{0} / {1} tris  |  {2}" -f $entry.tris, $entry.budget, $entry.rarity), $small, $brush, $x + 12, $y + 338)
        }
        $suffix = if ($front) { '_front' } else { '' }
        $sheet = Join-Path $assetRoot "assets/previews/wave1/_sheet_b$suffix.png"
        $bitmap.Save($sheet, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()
        $font.Dispose()
        $small.Dispose()
        $title.Dispose()
        $brush.Dispose()
        Write-Host $sheet
    }
}
Write-Host 'Wave 1 B complete. Studio import acceptance remains a separate step.'
