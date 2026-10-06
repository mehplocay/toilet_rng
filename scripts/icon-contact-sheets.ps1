# Contact sheets deliberately show every alpha image on both light and dark UI.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$iconRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw (Join-Path $iconRoot 'assets/icons/manifest.json') | ConvertFrom-Json
foreach ($category in @('items', 'toilets', 'ui', 'art', 'small', 'passes', 'passes_small')) {
    $entries = if ($category -eq 'passes_small') {
        @($manifest.assets | Where-Object { $_.size[0] -eq 128 -and $_.category -eq 'passes' })
    } elseif ($category -eq 'small') {
        @($manifest.assets | Where-Object { $_.size[0] -eq 128 -and $_.category -ne 'art' })
    } elseif ($category -eq 'art') {
        @($manifest.assets | Where-Object { $_.category -eq 'art' -and $_.size[0] -ne 128 -and $_.file -notlike '*Logo_1024*' })
    } else {
        @($manifest.assets | Where-Object { $_.category -eq $category -and $_.size[0] -eq 512 })
    }
    $isSmall = $category -in @('small', 'passes_small')
    $columns = if ($category -eq 'art') { 2 } elseif ($isSmall) { 5 } else { 4 }
    $cell = if ($category -eq 'art') { 640 } elseif ($isSmall) { 256 } else { 320 }
    $rowHeight = if ($category -eq 'art') { 410 } elseif ($isSmall) { 183 } else { 225 }
    $rows = [int][math]::Ceiling($entries.Count / $columns)
    $bitmap = New-Object System.Drawing.Bitmap ($columns * $cell), ($rows * $rowHeight + 70)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.Clear([System.Drawing.Color]::FromArgb(229, 237, 250))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $font = New-Object System.Drawing.Font 'Segoe UI', 11, ([System.Drawing.FontStyle]::Bold)
    $title = New-Object System.Drawing.Font 'Segoe UI', 23, ([System.Drawing.FontStyle]::Bold)
    $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(18, 25, 47))
    $dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 39, 65))
    $light = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(248, 251, 255))
    $g.DrawString(('TOILET RNG  /  ' + $category.ToUpper()), $title, $ink, 15, 12)
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $x = ($i % $columns) * $cell
        $y = [int][math]::Floor($i / $columns) * $rowHeight + 70
        $path = Join-Path $iconRoot $entry.file
        if (Test-Path -LiteralPath $path) {
            $img = [System.Drawing.Image]::FromFile($path)
            if ($category -eq 'art') {
                $g.FillRectangle($dark, $x + 6, $y, 628, 354)
                $factor = [math]::Min(628 / $img.Width, 354 / $img.Height)
                $w = [int]($img.Width * $factor); $h = [int]($img.Height * $factor)
                $g.DrawImage($img, $x + 6 + [int]((628 - $w)/2), $y + [int]((354 - $h)/2), $w, $h)
            } else {
                $sz = [int]($cell/2)
                $g.FillRectangle($light, $x, $y, $sz, $sz)
                $g.FillRectangle($dark, $x+$sz, $y, $sz, $sz)
                $g.DrawImage($img, $x, $y, $sz, $sz)
                $g.DrawImage($img, $x+$sz, $y, $sz, $sz)
            }
            $img.Dispose()
        }
        $labelY = if ($category -eq 'art') { $y+359 } else { $y+[int]($cell/2)+5 }
        $label = if ($entry.display_name) { $entry.display_name } else { $entry.name }
        $g.DrawString($label, $font, $ink, $x + 10, $labelY)
    }
    $sheet = Join-Path $iconRoot ("assets/icons/_sheet_{0}.png" -f $category)
    $bitmap.Save($sheet, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bitmap.Dispose(); $font.Dispose(); $title.Dispose(); $ink.Dispose(); $dark.Dispose(); $light.Dispose()
    Write-Host $sheet
}
