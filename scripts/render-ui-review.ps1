# Approximate, offline raster review of actual UI trees. Not a Roblox renderer.
param([string]$SnapshotDirectory = '.ui-review', [string]$FontDirectory, [string]$Pattern = '*.json')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'assets/icons/manifest.json') | ConvertFrom-Json
$uploads = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'assets/icons/uploaded-ids.json') | ConvertFrom-Json
$iconImages = @{}
foreach ($asset in $manifest.assets) {
    if ($asset.config_key -and $asset.size[0] -eq 512) {
        $id = $uploads.($asset.category).($asset.name)
        $iconImages["rbxassetid://$id"] = [Drawing.Image]::FromFile((Join-Path $workspaceRoot $asset.file))
    }
}
# Wave 1 art uses the centralized runtime IDs and its own local manifest.
$waveManifest = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'assets/icons/manifest-wave1.json') | ConvertFrom-Json
$assetSource = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'src/shared/Config/Assets.luau')
foreach ($asset in $waveManifest.assets) {
    if ($asset.size[0] -eq 512) {
        $key = $asset.config_key.Split('.')[1]
        $match = [regex]::Match($assetSource, '\b' + [regex]::Escape($key) + '\s*=\s*"(rbxassetid://[0-9]+)"')
        if (!$match.Success) { throw "Missing Wave 1 icon mapping: $key" }
        $iconImages[$match.Groups[1].Value] = [Drawing.Image]::FromFile((Join-Path $workspaceRoot $asset.file))
    }
}
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
            $brush = [Drawing.Drawing2D.LinearGradientBrush]::new($r, (Get-Color $n.gradient[0] $n.alpha), (Get-Color $n.gradient[1] $n.alpha), [single]$n.gradientRotation)
        } elseif ($n.gradient -and $n.gradient[0].Count -gt 2) {
            $stops = $n.gradient[0]
            $brush = [Drawing.Drawing2D.LinearGradientBrush]::new($r, [Drawing.Color]::White, [Drawing.Color]::White, [single]$n.gradientRotation)
            $blend = [Drawing.Drawing2D.ColorBlend]::new($stops.Count)
            $blend.Colors = [Drawing.Color[]]@($stops | ForEach-Object { Get-Color $_[1] $n.alpha })
            $blend.Positions = [single[]]@($stops | ForEach-Object { $_[0] })
            $brush.InterpolationColors = $blend
        } else { $brush = [Drawing.SolidBrush]::new((Get-Color $n.color $n.alpha)) }
        $g.FillPath($brush, $path); $brush.Dispose()
    }
    if ($n.stroke -and $n.stroke.mode -ne 'ApplyStrokeMode.Contextual') {
        $pen = [Drawing.Pen]::new((Get-Color $n.stroke.color $n.stroke.alpha), [single]$n.stroke.width)
        $g.DrawPath($pen, $path); $pen.Dispose()
    }
    if ($n.image -and $iconImages.ContainsKey($n.image)) {
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($iconImages[$n.image], $r)
    }
    if ($n.text -and $n.textAlpha -gt 0) {
        $family = [Drawing.FontFamily]::GenericSansSerif
        if ($fontCollection.Families.Count) {
            $family = $fontCollection.Families | Where-Object { $_.Name -match $(if ($n.font -match 'Builder') { 'Builder' } else { 'Fredoka' }) } | Select-Object -First 1
            if (!$family) { $family = $fontCollection.Families[0] }
        }
        $format = [Drawing.StringFormat]::new()
        $format.Alignment = if ($n.left) { [Drawing.StringAlignment]::Near } else { [Drawing.StringAlignment]::Center }
		$format.LineAlignment = if ($n.top) { [Drawing.StringAlignment]::Near } else { [Drawing.StringAlignment]::Center }
		if ($n.textWrapped -eq $false) { $format.FormatFlags = [Drawing.StringFormatFlags]::NoWrap -bor [Drawing.StringFormatFlags]::NoClip }
        $fontStyle = if ($family.IsStyleAvailable([Drawing.FontStyle]::Regular)) { [Drawing.FontStyle]::Regular } else { [Drawing.FontStyle]::Bold }
		$size = if ($n.textScaled -eq $false) { $n.textSize } else { [Math]::Min($(if ($n.maxFont) { $n.maxFont } else { 28 }), $n.h * 0.86) }
        do {
            $font = [Drawing.Font]::new($family, [single]$size, $fontStyle, [Drawing.GraphicsUnit]::Pixel)
            $measure = if ($n.textWrapped -eq $false) {
                $g.MeasureString($n.text, $font, [Drawing.SizeF]::new(100000, 100000), $format)
            } else { $g.MeasureString($n.text, $font, [int]$n.w, $format) }
            $font.Dispose()
			if ($n.textScaled -eq $false -or ($measure.Height -le $n.h + 2 -and $measure.Width -le $n.w + 2)) { break }
            $size -= 1
		} while ($size -gt $(if ($n.minFont) { $n.minFont } else { 10 }))
        $textPath = [Drawing.Drawing2D.GraphicsPath]::new()
        if ($n.textWrapped -eq $false) {
            # GDI's rectangle overload can omit the last glyph even after measurement.
            $textPath.AddString($n.text, $family, [int]$fontStyle, [single]$size, [Drawing.PointF]::Empty, $format)
            $bounds = $textPath.GetBounds()
            $transform = [Drawing.Drawing2D.Matrix]::new()
            $tx = $r.X - $bounds.X + $(if ($n.left) { 0 } else { ($r.Width - $bounds.Width) / 2 })
            $ty = $r.Y - $bounds.Y + $(if ($n.top) { 0 } else { ($r.Height - $bounds.Height) / 2 })
            $transform.Translate([single]$tx, [single]$ty)
            $textPath.Transform($transform); $transform.Dispose()
        } else { $textPath.AddString($n.text, $family, [int]$fontStyle, [single]$size, $r, $format) }
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
foreach ($file in (Get-ChildItem -LiteralPath $SnapshotDirectory -Filter $Pattern)) {
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
foreach ($icon in $iconImages.Values) { $icon.Dispose() }
