# Approximate, offline raster review of actual UI trees. Not a Roblox renderer.
param([string]$SnapshotDirectory = '.ui-review', [string]$FontDirectory)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$fontCollection = [Drawing.Text.PrivateFontCollection]::new()
if ($FontDirectory) {
    $fontCollection.AddFontFile((Join-Path $FontDirectory 'FredokaOne-Regular.ttf'))
    $fontCollection.AddFontFile((Join-Path $FontDirectory 'BuilderSans-Bold.otf'))
}
function Get-Color($value, [double]$alpha = 1) {
    if (!$value) { return [Drawing.Color]::Transparent }
    return [Drawing.Color]::FromArgb([int](255 * [Math]::Max(0, [Math]::Min(1, $alpha))), [int]($value.R * 255), [int]($value.G * 255), [int]($value.B * 255))
}
function New-RoundedPath([Drawing.RectangleF]$r, [single]$radius) {
    $p = [Drawing.Drawing2D.GraphicsPath]::new()
    $d = [Math]::Min([Math]::Min($r.Width, $r.Height), $radius * 2)
    if ($d -lt 1) { $p.AddRectangle($r); return ,$p }
    $p.AddArc($r.X, $r.Y, $d, $d, 180, 90)
    $p.AddArc($r.Right - $d, $r.Y, $d, $d, 270, 90)
    $p.AddArc($r.Right - $d, $r.Bottom - $d, $d, $d, 0, 90)
    $p.AddArc($r.X, $r.Bottom - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return ,$p
}
function Draw-Node($g, $n) {
    if (!$n.class -or $n.w -le 0 -or $n.h -le 0) { return }
    $saved = $g.Save()
    $r = [Drawing.RectangleF]::new($n.x, $n.y, $n.w, $n.h)
    if ($n.rotation) {
        $cx, $cy = ($n.x + $n.w / 2), ($n.y + $n.h / 2)
        $g.TranslateTransform($cx, $cy); $g.RotateTransform($n.rotation); $g.TranslateTransform(-$cx, -$cy)
    }
    $path = New-RoundedPath $r $n.corner
    if ($n.alpha -gt 0 -and $n.color) {
        if ($n.gradient -and $n.gradient.Count -eq 2) {
            $brush = [Drawing.Drawing2D.LinearGradientBrush]::new($r, (Get-Color $n.gradient[0] $n.alpha), (Get-Color $n.gradient[1] $n.alpha), [single]90)
        } else { $brush = [Drawing.SolidBrush]::new((Get-Color $n.color $n.alpha)) }
        $g.FillPath($brush, $path); $brush.Dispose()
    }
    if ($n.stroke -and $n.stroke.mode -ne 'ApplyStrokeMode.Contextual') {
        $pen = [Drawing.Pen]::new((Get-Color $n.stroke.color $n.stroke.alpha), [single]$n.stroke.width)
        $g.DrawPath($pen, $path); $pen.Dispose()
    }
    if ($n.text -and $n.textAlpha -gt 0) {
        $family = [Drawing.FontFamily]::GenericSansSerif
        if ($fontCollection.Families.Count) {
            $family = $fontCollection.Families | Where-Object { $_.Name -match $(if ($n.font -match 'Builder') { 'Builder' } else { 'Fredoka' }) } | Select-Object -First 1
            if (!$family) { $family = $fontCollection.Families[0] }
        }
        $format = [Drawing.StringFormat]::new()
        $format.Alignment = if ($n.left) { [Drawing.StringAlignment]::Near } else { [Drawing.StringAlignment]::Center }
        $format.LineAlignment = [Drawing.StringAlignment]::Center
        $fontStyle = if ($family.IsStyleAvailable([Drawing.FontStyle]::Regular)) { [Drawing.FontStyle]::Regular } else { [Drawing.FontStyle]::Bold }
        $size = [Math]::Min($(if ($n.maxFont) { $n.maxFont } else { 28 }), $n.h * 0.86)
        do {
            $font = [Drawing.Font]::new($family, [single]$size, $fontStyle, [Drawing.GraphicsUnit]::Pixel)
            $measure = $g.MeasureString($n.text, $font, [int]$n.w, $format)
            $font.Dispose()
            if ($measure.Height -le $n.h + 2 -and $measure.Width -le $n.w + 2) { break }
            $size -= 1
        } while ($size -gt 10)
        $textPath = [Drawing.Drawing2D.GraphicsPath]::new()
        $textPath.AddString($n.text, $family, [int]$fontStyle, [single]$size, $r, $format)
        if ($n.stroke -and $n.stroke.mode -eq 'ApplyStrokeMode.Contextual') {
            $pen = [Drawing.Pen]::new((Get-Color $n.stroke.color $n.stroke.alpha), [single]($n.stroke.width * 2))
            $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
            $g.DrawPath($pen, $textPath); $pen.Dispose()
        }
        $brush = [Drawing.SolidBrush]::new((Get-Color $n.textColor $n.textAlpha))
        $g.FillPath($brush, $textPath)
        $brush.Dispose(); $textPath.Dispose(); $format.Dispose()
    }
    if ($n.clip) { $g.SetClip($r, [Drawing.Drawing2D.CombineMode]::Intersect) }
    foreach ($child in $n.children) { Draw-Node $g $child }
    $path.Dispose(); $g.Restore($saved)
}
foreach ($file in (Get-ChildItem -LiteralPath $SnapshotDirectory -Filter '*.json')) {
    $tree = [IO.File]::ReadAllText($file.FullName) | ConvertFrom-Json
    $bitmap = [Drawing.Bitmap]::new([int]$tree.w, [int]$tree.h)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([Drawing.Color]::FromArgb(37, 82, 100))
    Draw-Node $graphics $tree
    $captionFont = [Drawing.Font]::new('Arial', 9)
    $graphics.DrawString('Headless UI approximation - ' + $file.BaseName, $captionFont, [Drawing.Brushes]::LightSteelBlue, 6, [single]($tree.h - 16))
    $bitmap.Save((Join-Path $file.DirectoryName ($file.BaseName + '.png')), [Drawing.Imaging.ImageFormat]::Png)
    $captionFont.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
    Write-Output ('Rendered ' + $file.BaseName)
}
$fontCollection.Dispose()
