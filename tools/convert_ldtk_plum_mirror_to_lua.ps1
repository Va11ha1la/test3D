param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$LdtkPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "ldtk\ink_plum_mirror.ldtk"),
    [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "scripts\src\29_ldtk_plum_mirror_data.lua")
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -LiteralPath $LdtkPath)) {
    throw "LDtk file not found: $LdtkPath"
}

function FieldValue($entity, [string]$name) {
    $field = $entity.fieldInstances | Where-Object { $_.__identifier -eq $name } | Select-Object -First 1
    if ($null -eq $field) {
        throw "Entity '$($entity.__identifier)' is missing field '$name'."
    }
    return $field.__value
}

function Escape-LuaString([string]$text) {
    return (($text -replace "\\", "\\") -replace '"', '\"')
}

function Lua-Number($value) {
    $d = [double]$value
    return $d.ToString("0.############", [System.Globalization.CultureInfo]::InvariantCulture)
}

function QBez([double]$a, [double]$b, [double]$c, [double]$t) {
    $it = 1.0 - $t
    return $it * $it * $a + 2.0 * $it * $t * $b + $t * $t * $c
}

function Frac([double]$v) {
    return $v - [math]::Floor($v)
}

function Hash01([double]$seed) {
    return Frac([math]::Sin($seed * 12.9898) * 43758.5453)
}

function Sample-BranchNode([object]$b, [int]$i) {
    $t = $i / [double]$b.pointsNum
    $cpX = ($b.x1 + $b.x2) * 0.5 + $b.curveX
    $cpY = ($b.y1 + $b.y2) * 0.5 + $b.curveY
    $x = QBez $b.x1 $cpX $b.x2 $t
    $y = QBez $b.y1 $cpY $b.y2 $t
    $r = $b.startR + ($b.endR - $b.startR) * $t
    if ($b.jitter -gt 0) {
        $r += ((Hash01 ($i * 19 + $x * 0.013 + $y * 0.017)) - 0.5) * ($b.startR * $b.jitter)
    }
    $diameter = [int][math]::Max(8, [math]::Round($r * 2))
    [pscustomobject]@{
        t = $t
        x = $x
        y = $y
        r = $r
        diameter = $diameter
        pxX = [int][math]::Round($x - $diameter * 0.5)
        pxY = [int][math]::Round($y - $diameter * 0.5)
    }
}

function Assert-Nearly([string]$label, [double]$actual, [double]$expected, [double]$epsilon) {
    if ([math]::Abs($actual - $expected) -gt $epsilon) {
        throw "$label changed. Expected $(Lua-Number $expected), got $(Lua-Number $actual)."
    }
}

function Assert-Material([hashtable]$actual, [string]$name, [string]$expected) {
    if (!$actual.ContainsKey($name)) {
        throw "Material swatch '$name' is missing from LDtk."
    }
    if ($actual[$name] -ne $expected) {
        throw "Material '$name' changed. Expected $expected, got $($actual[$name])."
    }
}

$project = Get-Content -LiteralPath $LdtkPath -Raw -Encoding UTF8 | ConvertFrom-Json
$level = $project.levels | Select-Object -First 1
if ($null -eq $level) {
    throw "No levels found in $LdtkPath"
}

$branchLayer = $level.layerInstances | Where-Object { $_.__identifier -eq "Branch_Curves" } | Select-Object -First 1
$branchNodeLayer = $level.layerInstances | Where-Object { $_.__identifier -eq "Branch_Nodes" } | Select-Object -First 1
$targetLayer = $level.layerInstances | Where-Object { $_.__identifier -eq "Blossom_Targets" } | Select-Object -First 1
$gameplayLayer = $level.layerInstances | Where-Object { $_.__identifier -eq "Gameplay" } | Select-Object -First 1
$materialLayer = $level.layerInstances | Where-Object { $_.__identifier -eq "Material_Lock" } | Select-Object -First 1

foreach ($required in @(
    @{ name = "Branch_Curves"; layer = $branchLayer },
    @{ name = "Branch_Nodes"; layer = $branchNodeLayer },
    @{ name = "Blossom_Targets"; layer = $targetLayer },
    @{ name = "Gameplay"; layer = $gameplayLayer },
    @{ name = "Material_Lock"; layer = $materialLayer }
)) {
    if ($null -eq $required.layer) {
        throw "Layer '$($required.name)' not found in $LdtkPath."
    }
}

$materials = @{}
foreach ($e in @($materialLayer.entityInstances | Where-Object { $_.__identifier -eq "MaterialSwatch" })) {
    $materials[[string](FieldValue $e "role")] = [string](FieldValue $e "rgb")
}

Assert-Material $materials "paper" "246,237,225"
Assert-Material $materials "paper2" "220,207,190"
Assert-Material $materials "ink" "42,30,24"
Assert-Material $materials "wash" "114,82,69"
Assert-Material $materials "accent" "142,35,42"
Assert-Material $materials "bloom" "195,18,18"
Assert-Material $materials "water" "204,165,68"

$branches = @(
    $branchLayer.entityInstances |
        Where-Object { $_.__identifier -eq "BranchCurve" } |
        ForEach-Object {
            [pscustomobject]@{
                id = [string](FieldValue $_ "branchId")
                x1 = [double](FieldValue $_ "x1")
                y1 = [double](FieldValue $_ "y1")
                x2 = [double](FieldValue $_ "x2")
                y2 = [double](FieldValue $_ "y2")
                startR = [int](FieldValue $_ "startR")
                endR = [int](FieldValue $_ "endR")
                curveX = [int](FieldValue $_ "curveX")
                curveY = [int](FieldValue $_ "curveY")
                pointsNum = [int](FieldValue $_ "pointsNum")
                jitter = [double](FieldValue $_ "jitter")
                material = [string](FieldValue $_ "material")
            }
        }
)

if ($branches.Count -ne 8) {
    throw "Expected 8 BranchCurve entities, got $($branches.Count)."
}

$branchOrder = @("main_trunk", "hanging_branch", "right_crescent", "upright_young_shoot", "poetry_col_1", "poetry_col_2", "poetry_col_3", "poetry_col_4")
$branches = @(
    foreach ($id in $branchOrder) {
        $match = $branches | Where-Object { $_.id -eq $id } | Select-Object -First 1
        if ($null -eq $match) {
            throw "Branch '$id' is missing from LDtk."
        }
        $match
    }
)

foreach ($b in $branches) {
    if ($b.material -ne "plum_mirror_ink") {
        throw "Branch '$($b.id)' material changed. Expected plum_mirror_ink, got $($b.material)."
    }
}

$expectedNodeCount = 0
foreach ($b in $branches) {
    $expectedNodeCount += $b.pointsNum + 1
}

$branchNodes = @(
    $branchNodeLayer.entityInstances |
        Where-Object { $_.__identifier -eq "BranchNode" } |
        ForEach-Object {
            $pxX = [int]$_.px[0]
            $pxY = [int]$_.px[1]
            $w = [int]$_.width
            $h = [int]$_.height
            [pscustomobject]@{
                branchId = [string](FieldValue $_ "branchId")
                nodeIndex = [int](FieldValue $_ "nodeIndex")
                t = [double](FieldValue $_ "t")
                radius = [double](FieldValue $_ "radius")
                material = [string](FieldValue $_ "material")
                pxX = $pxX
                pxY = $pxY
                width = $w
                height = $h
            }
        }
)

if ($branchNodes.Count -ne $expectedNodeCount) {
    throw "Expected $expectedNodeCount BranchNode entities, got $($branchNodes.Count)."
}

foreach ($n in $branchNodes) {
    if ($n.material -ne "plum_mirror_ink") {
        throw "Branch node '$($n.branchId):$($n.nodeIndex)' material changed. Expected plum_mirror_ink, got $($n.material)."
    }
}

foreach ($b in $branches) {
    $nodesForBranch = @($branchNodes | Where-Object { $_.branchId -eq $b.id } | Sort-Object nodeIndex)
    $expectedCount = $b.pointsNum + 1
    if ($nodesForBranch.Count -ne $expectedCount) {
        throw "Branch '$($b.id)' expected $expectedCount BranchNode entities, got $($nodesForBranch.Count)."
    }

    for ($i = 0; $i -le $b.pointsNum; $i++) {
        $n = $nodesForBranch | Where-Object { $_.nodeIndex -eq $i } | Select-Object -First 1
        if ($null -eq $n) {
            throw "Branch '$($b.id)' is missing BranchNode index $i."
        }

        $expected = Sample-BranchNode $b $i
        Assert-Nearly "Branch '$($b.id)' node $i t" $n.t $expected.t 0.0000001
        Assert-Nearly "Branch '$($b.id)' node $i radius" $n.radius $expected.r 0.000001

        if ($n.width -ne $expected.diameter -or $n.height -ne $expected.diameter) {
            throw "Branch '$($b.id)' node $i circle size changed. Expected $($expected.diameter)x$($expected.diameter), got $($n.width)x$($n.height)."
        }
        if ($n.pxX -ne $expected.pxX -or $n.pxY -ne $expected.pxY) {
            throw "Branch '$($b.id)' node $i circle position changed. Expected ($($expected.pxX), $($expected.pxY)), got ($($n.pxX), $($n.pxY))."
        }
    }
}

$targets = @(
    $targetLayer.entityInstances |
        Where-Object { $_.__identifier -eq "PlumBudTarget" } |
        ForEach-Object {
            [pscustomobject]@{
                branchId = [string](FieldValue $_ "branchId")
                progress = [double](FieldValue $_ "progress")
                radius = [int](FieldValue $_ "radius")
                material = [string](FieldValue $_ "material")
            }
        }
)

if ($targets.Count -ne 8) {
    throw "Expected 8 PlumBudTarget entities, got $($targets.Count)."
}

foreach ($t in $targets) {
    if ($t.material -ne "plum_mirror_bloom") {
        throw "Target on '$($t.branchId)' material changed. Expected plum_mirror_bloom, got $($t.material)."
    }
}

$startEntity = $gameplayLayer.entityInstances | Where-Object { $_.__identifier -eq "PlayerStart" } | Select-Object -First 1
if ($null -eq $startEntity) {
    throw "PlayerStart entity not found in LDtk."
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$builder = New-Object System.Text.StringBuilder

[void]$builder.AppendLine("-- AUTO-GENERATED FILE. Do not edit directly.")
[void]$builder.AppendLine("-- Generated by tools/convert_ldtk_plum_mirror_to_lua.ps1 from ldtk/ink_plum_mirror.ldtk.")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("LDTK_PLUM_MIRROR = {")
[void]$builder.AppendLine("    source = ""ldtk/ink_plum_mirror.ldtk"",")
[void]$builder.AppendLine("    identifier = ""$(Escape-LuaString ([string]$level.identifier))"",")
[void]$builder.AppendLine("    width = $([int]$level.pxWid),")
[void]$builder.AppendLine("    height = $([int]$level.pxHei),")
[void]$builder.AppendLine("    materials = {")
[void]$builder.AppendLine("        paper = { 246, 237, 225 },")
[void]$builder.AppendLine("        paper2 = { 220, 207, 190 },")
[void]$builder.AppendLine("        ink = { 42, 30, 24 },")
[void]$builder.AppendLine("        wash = { 114, 82, 69 },")
[void]$builder.AppendLine("        accent = { 142, 35, 42 },")
[void]$builder.AppendLine("        bloom = { 195, 18, 18 },")
[void]$builder.AppendLine("        water = { 204, 165, 68 },")
[void]$builder.AppendLine("    },")
[void]$builder.AppendLine("    physics = { radius = 11, gravity = 0.46, jumpForce = -16.5, dashSpeed = 21, friction = 0.84 },")
[void]$builder.AppendLine("    start = { x = $([int]$startEntity.px[0]), y = $([int]$startEntity.px[1]), facing = ""$(Escape-LuaString ([string](FieldValue $startEntity "facing")))"", },")
[void]$builder.AppendLine("    branches = {")
foreach ($b in $branches) {
    [void]$builder.AppendLine("        { id = ""$(Escape-LuaString $b.id)"", x1 = $(Lua-Number $b.x1), y1 = $(Lua-Number $b.y1), x2 = $(Lua-Number $b.x2), y2 = $(Lua-Number $b.y2), startR = $($b.startR), endR = $($b.endR), curveX = $($b.curveX), curveY = $($b.curveY), pointsNum = $($b.pointsNum), jitter = $(Lua-Number $b.jitter) },")
}
[void]$builder.AppendLine("    },")
[void]$builder.AppendLine("    targets = {")
foreach ($t in $targets) {
    [void]$builder.AppendLine("        { branchId = ""$(Escape-LuaString $t.branchId)"", progress = $($t.progress.ToString([System.Globalization.CultureInfo]::InvariantCulture)), radius = $($t.radius) },")
}
[void]$builder.AppendLine("    },")
[void]$builder.AppendLine("}")

$outDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
[System.IO.File]::WriteAllText($OutputPath, $builder.ToString(), $utf8NoBom)

Write-Host "Converted $LdtkPath"
Write-Host "  branches: $($branches.Count)"
Write-Host "  visible branch nodes: $($branchNodes.Count)"
Write-Host "  targets: $($targets.Count)"
Write-Host "  output: $OutputPath"
