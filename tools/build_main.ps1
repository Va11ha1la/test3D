param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$SourceDir = Join-Path $ProjectRoot "scripts\src"
$OutputFile = Join-Path $ProjectRoot "scripts\main.generated.lua"

if (!(Test-Path -LiteralPath $SourceDir)) {
    throw "Source directory not found: $SourceDir"
}

$parts = Get-ChildItem -LiteralPath $SourceDir -Filter "*.lua" -File | Sort-Object Name
if ($parts.Count -eq 0) {
    throw "No Lua source chunks found in $SourceDir"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$builder = New-Object System.Text.StringBuilder

[void]$builder.AppendLine("-- AUTO-GENERATED FILE. Do not edit directly.")
[void]$builder.AppendLine("-- Edit scripts/src/*.lua, then run tools/build_main.ps1.")
[void]$builder.AppendLine("")

foreach ($part in $parts) {
    $relative = "scripts/src/$($part.Name)"
    [void]$builder.AppendLine("-- ============================================================================")
    [void]$builder.AppendLine("-- BEGIN $relative")
    [void]$builder.AppendLine("-- ============================================================================")
    [void]$builder.Append([System.IO.File]::ReadAllText($part.FullName, [System.Text.Encoding]::UTF8))
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("-- ============================================================================")
    [void]$builder.AppendLine("-- END $relative")
    [void]$builder.AppendLine("-- ============================================================================")
    [void]$builder.AppendLine("")
}

[System.IO.File]::WriteAllText($OutputFile, $builder.ToString(), $utf8NoBom)
Write-Host "Built $OutputFile from $($parts.Count) source chunks."
