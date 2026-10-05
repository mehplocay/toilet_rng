# Verify the actual binary import through Rojo XML and return Luau fixtures.
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$xmlPath = Join-Path $workspaceRoot '.template-check.rbxlx'
try {
    & rojo build (Join-Path $workspaceRoot 'default.project.json') -o $xmlPath | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Template XML build failed' }
    [xml]$place = [IO.File]::ReadAllText($xmlPath)
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('local importedTemplates = {')
    foreach ($batch in @(@('ModelTemplates','assets/manifest.json',31), @('EnvTemplates','assets/manifest-env.json',44))) {
    $folderName, $manifestFile, $expectedCount = $batch
    $root = $place.SelectSingleNode("//Item[@class='ReplicatedStorage']/Item[Properties/string[@name='Name']='$folderName']")
    if (-not $root -or $root.class -ne 'Model' -or @($root.Item).Count -ne $expectedCount) { throw "Expected $folderName with $expectedCount direct models" }
    $manifest = Get-Content -Raw (Join-Path $workspaceRoot $manifestFile) | ConvertFrom-Json
    foreach ($asset in $manifest.assets) {
        $name = $asset.name
        $models = $root.SelectNodes("Item[@class='Model'][Properties/string[@name='Name']='$name']")
        if ($models.Count -ne 1) { throw "Missing/duplicate model: $name" }
        $meshes = $models[0].SelectNodes(".//Item[@class='MeshPart']")
        if ($meshes.Count -ne 1 -or $models[0].SelectNodes('.//Item').Count -ne 1) { throw "Unexpected descendants: $name" }
        $props = $meshes[0].Properties
        $size = $props.SelectSingleNode("Vector3[@name='size']")
        $frame = $props.SelectSingleNode("CoordinateFrame[@name='CFrame']")
        $pivot = $props.SelectSingleNode("CoordinateFrame[@name='PivotOffset']")
        $mesh = $props.SelectSingleNode("Content[@name='MeshContent']/uri").InnerText
        $texture = $props.SelectSingleNode("Content[@name='TextureContent']/uri").InnerText
        if ($mesh -notmatch '^rbxassetid://[1-9][0-9]*$' -or $texture -notmatch '^rbxassetid://[1-9][0-9]*$') { throw "Missing content references: $name" }
        if ($props.SelectSingleNode("token[@name='RenderFidelity']").InnerText -ne '0') { throw "RenderFidelity must be Automatic: $name" }
        $axes = @('X','Y','Z')
        for ($i = 0; $i -lt 3; $i++) {
            $value = [double]::Parse($size.($axes[$i]), [Globalization.CultureInfo]::InvariantCulture)
            if ([Math]::Abs($value - $asset.size_studs[$i]) -gt 0.001) { throw "Imported size mismatch: $name" }
        }
        if ($pivot.R11 -ne '1' -or $pivot.R00 -ne '-1' -or $pivot.R22 -ne '-1') { throw "Review changed import orientation: $name" }
        $sizeValues = ($axes | ForEach-Object { $size.$_ }) -join ', '
        $components = @('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22')
        $frameValues = ($components | ForEach-Object { $frame.$_ }) -join ', '
        $pivotValues = ($components | ForEach-Object { $pivot.$_ }) -join ', '
        $lines.Add("['$name'] = { Size = Vector3.new($sizeValues), CFrame = CFrame.new($frameValues), PivotOffset = CFrame.new($pivotValues), MeshContent = '$mesh', TextureID = '$texture' },")
    }
    if ($root.SelectNodes(".//Item[@class='MeshPart']").Count -ne $expectedCount) { throw 'Wrong MeshPart count' }
    }
    $lines.Add('}')
    Write-Host 'Verified binary import: 75 models (31 original + 44 environment), 75 MeshParts, 150 content references, manifest sizes, Y-up pivots, Automatic rendering.'
    return (($lines -join "`n") + "`n")
} finally {
    if (Test-Path -LiteralPath $xmlPath) { Remove-Item -LiteralPath $xmlPath }
}
