# Emit independent canonical acceptance data into the audit bundle; no runtime import.
$data = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot '../docs/design/wave1-data.json') | ConvertFrom-Json
function ConvertTo-WaveLiteral($value) {
    if ($null -eq $value) { return 'nil' }
    if ($value -is [bool]) { return $value.ToString().ToLowerInvariant() }
    if ($value -is [string]) { return '"' + $value.Replace('\','\\').Replace('"','\"') + '"' }
    if ($value -is [System.Array]) { return '{' + (($value | ForEach-Object { ConvertTo-WaveLiteral $_ }) -join ',') + '}' }
    if ($value -is [System.Management.Automation.PSCustomObject]) {
        $fields = foreach ($p in $value.PSObject.Properties) { '[' + (ConvertTo-WaveLiteral $p.Name) + ']=' + (ConvertTo-WaveLiteral $p.Value) }
        return '{' + ($fields -join ',') + '}'
    }
    return $value.ToString([Globalization.CultureInfo]::InvariantCulture)
}
'local wave1Spec = ' + (ConvertTo-WaveLiteral $data)
