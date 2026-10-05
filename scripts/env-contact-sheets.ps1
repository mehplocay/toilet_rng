param([switch]$Front)
$ErrorActionPreference = 'Stop'
[System.Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.Drawing
$assetRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw (Join-Path $assetRoot 'assets/manifest-env.json') | ConvertFrom-Json
foreach ($family in @('hub', 'plot', 'island', 'background', 'hero')) {
    $entries = @($manifest.assets | Where-Object family -eq $family)
    if (-not $entries.Count) { continue }
    $columns = 4; $cell = 320; $rowHeight = 388
    $rows = [int][math]::Ceiling($entries.Count / $columns)
    $bitmap = New-Object System.Drawing.Bitmap ($columns * $cell), ($rows * $rowHeight + 80)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::FromArgb(234, 239, 255))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $font = New-Object System.Drawing.Font 'Segoe UI', 12, ([System.Drawing.FontStyle]::Bold)
    $small = New-Object System.Drawing.Font 'Segoe UI', 10
    $title = New-Object System.Drawing.Font 'Segoe UI', 23, ([System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(25, 33, 63))
    $graphics.DrawString(('TOILET RNG  /  ENVIRONMENT  /  ' + $family.ToUpper()), $title, $brush, 16, 16)
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $x = ($i % $columns) * $cell
        $y = [int][math]::Floor($i / $columns) * $rowHeight + 80
        $previewPath = if ($Front) { $entry.front_preview } else { $entry.preview }
        $preview = Join-Path $assetRoot $previewPath
        if (Test-Path -LiteralPath $preview) {
            $img = [System.Drawing.Image]::FromFile($preview)
            $graphics.DrawImage($img, $x + 6, $y, 308, 308)
            $img.Dispose()
        } else {
            $graphics.DrawString('Preview not built', $font, $brush, $x + 20, $y + 140)
        }
        $graphics.DrawString($entry.name, $font, $brush, $x + 12, $y + 310)
        $graphics.DrawString(("{0} tris / {1}" -f $entry.tris, $entry.budget), $small, $brush, $x + 12, $y + 336)
        $graphics.DrawString(("{0:0.#} x {1:0.#} x {2:0.#} studs" -f $entry.size_studs[0], $entry.size_studs[1], $entry.size_studs[2]), $small, $brush, $x + 12, $y + 356)
    }
    $suffix = if ($Front) { '_front' } else { '' }
    $sheet = Join-Path $assetRoot ("assets/previews/_sheet_env_{0}{1}.png" -f $family, $suffix)
    $bitmap.Save($sheet, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose(); $font.Dispose(); $small.Dispose(); $title.Dispose(); $brush.Dispose()
    Write-Host $sheet
}
