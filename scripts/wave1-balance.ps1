param([switch]$WriteOutput)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$output = & luau --codegen -O2 (Join-Path $PSScriptRoot 'wave1-balance.luau')
if ($LASTEXITCODE -ne 0) {
    $output
    throw 'Integrated Wave 1 balance proof failed'
}
if ($WriteOutput) {
    [IO.File]::WriteAllText((Join-Path $root 'docs/design/wave1-balance.txt'), (($output -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
}
$output
