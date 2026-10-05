# Run production builders with engine-boundary mocks; never contacts Roblox.
param(
    [ValidateSet('Empty','Ready','Mixed','Invalid','Scaled','Late')][string]$MeshMode = 'Ready',
    [switch]$World,
    [switch]$Snapshot
)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$generatedPath = Join-Path $workspaceRoot '.visual-check.generated.luau'
$harness = "local testMode = '$MeshMode'`nlocal checkWorld = $($World.IsPresent.ToString().ToLower())`nlocal snapshot = $($Snapshot.IsPresent.ToString().ToLower())`n"
$harness += Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'world-harness.luau')
$modulePaths = @(
    'src/shared/Config/Assets.luau', 'src/shared/Config/MeshCatalog.luau', 'src/shared/Config/WorldModels.luau',
    'src/shared/Config/Visuals.luau', 'src/shared/Config/World.luau',
    'src/shared/Config/Items.luau', 'src/shared/Config/Toilets.luau', 'src/shared/Config/Rarities.luau',
    'src/shared/Config/PlotGuidance.luau', 'src/shared/PlotChooser.luau', 'src/server/World/PlotSpawn.luau',
    'src/shared/Visuals/Primitives.luau', 'src/shared/Visuals/Items.luau', 'src/shared/Visuals/Toilets.luau',
    'src/shared/Visuals/TemplateLoader.luau', 'src/shared/Visuals/TemplateAccents.luau', 'src/shared/Config/TemplateEffects.luau',
    'src/server/World/MeshLoader.luau', 'src/server/World/Models.luau', 'src/server/World/Builders/Decor.luau',
    'src/server/World/Builders/Island.luau', 'src/server/World/Builders/Lighting.luau',
    'src/server/World/Builders/Hub.luau', 'src/server/World/Builders/Plot.luau',
    'src/server/World/WorldService.luau'
)
foreach ($modulePath in $modulePaths) {
    $source = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot $modulePath)
    $moduleName = $modulePath.Substring(0, $modulePath.Length - 5)
    $harness += "`nnode('$moduleName')`nsources['$moduleName'] = [====[`n$source`n]====]`n"
}
# Verify the actual runtime catalog against the independent Blender manifest.
$manifest = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot 'assets/manifest.json') | ConvertFrom-Json
$harness += "`nlocal manifest = {`n"
foreach ($asset in $manifest.assets) {
    $size = ($asset.size_studs | ForEach-Object { $_.ToString([Globalization.CultureInfo]::InvariantCulture) }) -join ', '
    $harness += "['$($asset.name)'] = { Size = Vector3.new($size), Triangles = $($asset.tris) },`n"
}
$harness += "}`n"
$harness += & (Join-Path $PSScriptRoot 'read-model-templates.ps1')
$harness += Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'world-checks.luau')
try {
    [IO.File]::WriteAllText($generatedPath, $harness, [Text.UTF8Encoding]::new($false))
    if ($Snapshot) {
        $output = & luau $generatedPath
        if ($LASTEXITCODE -ne 0) { throw 'Headless visual construction checks failed' }
        $output | Where-Object { $_.StartsWith('SCENE|') } | Set-Content -LiteralPath (Join-Path $workspaceRoot '.world-scene.txt') -Encoding UTF8
        $output | Where-Object { -not $_.StartsWith('SCENE|') } | Write-Output
    } else {
        & luau $generatedPath
        if ($LASTEXITCODE -ne 0) { throw 'Headless visual construction checks failed' }
    }
} finally {
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
