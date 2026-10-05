param([switch]$Front)
# Uses Windows' bundled System.Drawing; no Python packages or downloads required.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assetRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw (Join-Path $assetRoot 'assets/manifest.json') | ConvertFrom-Json
foreach ($category in @('items', 'toilets', 'props')) {
    $entries = @($manifest.assets | Where-Object category -eq $category)
    $columns = 4
    $cell = 320
    $rowHeight = 374
    $rows = [int][math]::Ceiling($entries.Count / $columns)
    $bitmap = New-Object System.Drawing.Bitmap ($columns * $cell), ($rows * $rowHeight + 68)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::FromArgb(234, 239, 255))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $font = New-Object System.Drawing.Font 'Segoe UI', 13, ([System.Drawing.FontStyle]::Bold)
    $small = New-Object System.Drawing.Font 'Segoe UI', 10
    $title = New-Object System.Drawing.Font 'Segoe UI', 24, ([System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(25, 33, 63))
    $graphics.DrawString(('TOILET RNG  /  ' + $category.ToUpper()), $title, $brush, 16, 12)
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $x = ($i % $columns) * $cell
        $y = [int][math]::Floor($i / $columns) * $rowHeight + 68
        $previewPath = if ($Front) { $entry.front_preview } else { $entry.preview }
        $preview = Join-Path $assetRoot $previewPath
        if (Test-Path -LiteralPath $preview) {
            $img = [System.Drawing.Image]::FromFile($preview)
            $graphics.DrawImage($img, $x + 6, $y, 308, 308)
            $img.Dispose()
        }
        $graphics.DrawString($entry.name, $font, $brush, $x + 12, $y + 310)
        $graphics.DrawString(("{0} tris  /  {1}" -f $entry.tris, $entry.budget), $small, $brush, $x + 12, $y + 338)
    }
    $suffix = if ($Front) { '_front' } else { '' }
    $sheet = Join-Path $assetRoot ("assets/previews/_sheet_{0}{1}.png" -f $category, $suffix)
    $bitmap.Save($sheet, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose(); $font.Dispose(); $small.Dispose(); $title.Dispose(); $brush.Dispose()
    Write-Host $sheet
}
