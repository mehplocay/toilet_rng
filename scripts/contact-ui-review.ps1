param([string]$SnapshotDirectory = '.ui-review-final', [string]$Pattern = '*.png', [string]$OutputName = 'contact')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$files = @(Get-ChildItem -LiteralPath $SnapshotDirectory -Filter $Pattern | Where-Object { $_.Name -notlike 'contact*' } | Sort-Object Name)
$font = [Drawing.Font]::new('Arial', 12)
for ($offset = 0; $offset -lt $files.Count; $offset += 6) {
    $bitmap = [Drawing.Bitmap]::new(1800, 1000)
    $g = [Drawing.Graphics]::FromImage($bitmap)
    $g.Clear([Drawing.Color]::FromArgb(22, 27, 39))
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($i = 0; $i -lt 6 -and ($offset + $i) -lt $files.Count; $i++) {
        $file = $files[$offset + $i]
        $image = [Drawing.Image]::FromFile($file.FullName)
        $scale = [Math]::Min(580 / $image.Width, 460 / $image.Height)
        $x = ($i % 3) * 600 + 10
        $y = [Math]::Floor($i / 3) * 500 + 28
        $g.DrawImage($image, [single]$x, [single]$y, [single]($image.Width * $scale), [single]($image.Height * $scale))
        $g.DrawString($file.BaseName, $font, [Drawing.Brushes]::White, [single]$x, [single]($y - 24))
        $image.Dispose()
    }
    $path = Join-Path $SnapshotDirectory ($OutputName + '-' + [int]($offset / 6) + '.png')
    $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bitmap.Dispose()
    Write-Output $path
}
$font.Dispose()
