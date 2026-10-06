param([switch]$WriteOutput)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dataPath = Join-Path $root 'docs/design/wave1-data.json'
$data = Get-Content -LiteralPath $dataPath -Raw | ConvertFrom-Json
$culture = [Globalization.CultureInfo]::InvariantCulture
function ConvertTo-Luau($value) {
    if ($null -eq $value) { return 'nil' }
    if ($value -is [bool]) { return $value.ToString().ToLowerInvariant() }
    if ($value -is [string]) {
        # Escape Luau literals directly; PowerShell JSON also emits unsupported \uNNNN escapes.
        if ($value -match '[^\x20-\x7e]') { throw 'Expected printable ASCII data' }
        return '"' + $value.Replace('\', '\\').Replace('"', '\"') + '"'
    }
    if ($value -is [System.Management.Automation.PSCustomObject]) {
        $fields = foreach ($property in $value.PSObject.Properties) {
            '[' + (ConvertTo-Luau $property.Name) + '] = ' + (ConvertTo-Luau $property.Value)
        }
        return '{' + ($fields -join ',') + '}'
    }
    if ($value -is [System.Array]) {
        $entries = foreach ($entry in $value) { ConvertTo-Luau $entry }
        return '{' + ($entries -join ',') + '}'
    }
    if ($value -is [System.ValueType]) { return $value.ToString($culture) }
    throw ('Unsupported value: ' + $value.GetType().FullName)
}
$scratch = Join-Path $PSScriptRoot ('.wave1-balance-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $scratch
try {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $scratch 'wave1-input.luau'), ('return ' + (ConvertTo-Luau $data)), $utf8)
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'wave1-balance.luau') -Destination (Join-Path $scratch 'run.luau')
    $output = & luau (Join-Path $scratch 'run.luau') 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($output -join "`n") }
    if ($WriteOutput) {
        [IO.File]::WriteAllText((Join-Path $root 'docs/design/wave1-balance.txt'), (($output -join "`n") + "`n"), $utf8)
    }
    $output
} finally {
    # Delete only this invocation's verified child directory, with PowerShell end-to-end.
    $resolvedScratch = [IO.Path]::GetFullPath($scratch)
    $allowedParent = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\') + '\'
    if (-not $resolvedScratch.StartsWith($allowedParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Scratch path escaped scripts directory'
    }
    if (-not ([IO.Path]::GetFileName($resolvedScratch) -match '^\.wave1-balance-[0-9a-f]{32}$')) {
        throw 'Unexpected scratch directory'
    }
    Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
}
