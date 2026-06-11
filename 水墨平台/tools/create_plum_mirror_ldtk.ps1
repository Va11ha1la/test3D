param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "ldtk\ink_plum_mirror.ldtk")
)

$ErrorActionPreference = "Stop"

function New-Iid() { ([guid]::NewGuid()).ToString() }

function New-FieldDef([int]$uid, [string]$identifier, [string]$type) {
    [ordered]@{
        identifier = $identifier
        doc = $null
        uid = $uid
        type = $type
        isArray = $false
        canBeNull = $false
        arrayMinLength = $null
        arrayMaxLength = $null
        editorDisplayMode = "ValueOnly"
        editorDisplayScale = 1
        editorDisplayPos = "Above"
        editorLinkStyle = "ZigZag"
        editorDisplayColor = $null
        editorAlwaysShow = $false
        editorShowInWorld = $true
        editorCutLongValues = $true
        editorTextSuffix = $null
        editorTextPrefix = $null
        useForSmartColor = $false
        exportToToc = $false
        searchable = $true
        min = $null
        max = $null
        regex = $null
        acceptFileTypes = $null
        defaultOverride = $null
        textLanguageMode = $null
        symmetricalRef = $false
        autoChainRef = $false
        allowOutOfLevelRef = $true
        allowedRefs = "OnlySame"
        allowedRefsEntityUid = $null
        allowedRefTags = @()
        tilesetUid = $null
    }
}

function New-FieldInstance([object]$def, $value) {
    $valueId = switch ($def.type) {
        "F_Int" { "V_Int" }
        "F_Float" { "V_Float" }
        default { "V_String" }
    }

    [ordered]@{
        __identifier = $def.identifier
        __value = $value
        __tile = $null
        defUid = $def.uid
        realEditorValues = @(
            [ordered]@{
                id = $valueId
                params = @($value)
            }
        )
    }
}

function New-EntityDef([int]$uid, [string]$identifier, [string]$color, [int]$width, [int]$height, [object[]]$fieldDefs, [string]$renderMode = "Rectangle", [bool]$resizable = $false, [bool]$showName = $true) {
    [ordered]@{
        identifier = $identifier
        uid = $uid
        tags = @()
        exportToToc = $false
        allowOutOfBounds = $false
        doc = $null
        width = $width
        height = $height
        resizableX = $resizable
        resizableY = $resizable
        minWidth = $null
        maxWidth = $null
        minHeight = $null
        maxHeight = $null
        keepAspectRatio = $false
        tileOpacity = 1
        fillOpacity = 0.35
        lineOpacity = 1
        hollow = $false
        color = $color
        renderMode = $renderMode
        showName = $showName
        tilesetId = $null
        tileRenderMode = "FitInside"
        tileRect = $null
        uiTileRect = $null
        nineSliceBorders = @()
        maxCount = $null
        limitScope = "PerLevel"
        limitBehavior = "DiscardOldOnes"
        pivotX = 0.5
        pivotY = 0.5
        fieldDefs = @($fieldDefs)
    }
}

function New-LayerDef([int]$uid, [string]$identifier, [string]$type, [string]$color, [int]$gridSize) {
    [ordered]@{
        identifier = $identifier
        type = $type
        uid = $uid
        doc = $null
        uiColor = $color
        gridSize = $gridSize
        guideGridWid = 0
        guideGridHei = 0
        displayOpacity = 1
        inactiveOpacity = 1
        hideInList = $false
        hideFieldsWhenInactive = $false
        canSelectWhenInactive = $true
        renderInWorldView = $true
        pxOffsetX = 0
        pxOffsetY = 0
        parallaxFactorX = 0
        parallaxFactorY = 0
        parallaxScaling = $true
        requiredTags = @()
        excludedTags = @()
        autoTilesKilledByOtherLayerUid = $null
        uiFilterTags = @()
        useAsyncRender = $false
        intGridValues = @()
        intGridValuesGroups = @()
        autoRuleGroups = @()
        autoSourceLayerDefUid = $null
        tilesetDefUid = $null
        tilePivotX = 0
        tilePivotY = 0
        biomeFieldUid = $null
    }
}

function New-EntityInstance([object]$def, [int]$x, [int]$y, [object[]]$fieldInstances, [int]$width = 0, [int]$height = 0) {
    $entityW = if ($width -gt 0) { $width } else { $def.width }
    $entityH = if ($height -gt 0) { $height } else { $def.height }
    [ordered]@{
        __identifier = $def.identifier
        __grid = @([math]::Floor($x / 16), [math]::Floor($y / 16))
        __pivot = @($def.pivotX, $def.pivotY)
        __tags = @()
        __tile = $null
        __smartColor = $def.color
        iid = New-Iid
        width = $entityW
        height = $entityH
        defUid = $def.uid
        px = @($x, $y)
        fieldInstances = @($fieldInstances)
        __worldX = $x
        __worldY = $y
    }
}

function New-EntityLayer([object]$def, [int]$levelId, [int]$worldW, [int]$worldH, [object[]]$entities) {
    [ordered]@{
        __identifier = $def.identifier
        __cWid = [math]::Ceiling($worldW / $def.gridSize)
        __cHei = [math]::Ceiling($worldH / $def.gridSize)
        __gridSize = $def.gridSize
        __opacity = 1
        __pxTotalOffsetX = 0
        __pxTotalOffsetY = 0
        __tilesetDefUid = $null
        __tilesetRelPath = $null
        iid = New-Iid
        levelId = $levelId
        layerDefUid = $def.uid
        pxOffsetX = 0
        pxOffsetY = 0
        visible = $true
        optionalRules = @()
        intGridCsv = @()
        autoLayerTiles = @()
        seed = 1
        overrideTilesetUid = $null
        gridTiles = @()
        entityInstances = @($entities)
    }
}

function QBez([double]$a, [double]$b, [double]$c, [double]$t) {
    $it = 1.0 - $t
    return $it * $it * $a + 2.0 * $it * $t * $b + $t * $t * $c
}

function Sample-Branch([object]$b, [double]$t) {
    $cpX = ($b.x1 + $b.x2) * 0.5 + $b.curveX
    $cpY = ($b.y1 + $b.y2) * 0.5 + $b.curveY
    [pscustomobject]@{
        x = [int][math]::Round((QBez $b.x1 $cpX $b.x2 $t))
        y = [int][math]::Round((QBez $b.y1 $cpY $b.y2 $t))
    }
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
    [pscustomobject]@{
        branchId = $b.id
        index = $i
        t = $t
        x = $x
        y = $y
        r = $r
    }
}

$designW = 1280
$designH = 720
$worldW = [int]($designW * 3.5)
$worldH = [int]($designH * 2.2)

$materials = [ordered]@{
    paper = @(246, 237, 225)
    paper2 = @(220, 207, 190)
    ink = @(42, 30, 24)
    wash = @(114, 82, 69)
    accent = @(142, 35, 42)
    bloom = @(195, 18, 18)
    water = @(204, 165, 68)
}

$physics = [ordered]@{
    radius = 11
    gravity = 0.46
    jumpForce = -16.5
    dashSpeed = 21
    friction = 0.84
}

$branches = @(
    [pscustomobject]@{ id = "main_trunk"; x1 = $worldW * 0.05; y1 = $worldH * 0.60; x2 = $worldW * 0.42; y2 = $worldH * 0.66; startR = 46; endR = 32; curveX = 80; curveY = 50; pointsNum = 60; jitter = 0.10 },
    [pscustomobject]@{ id = "hanging_branch"; x1 = $worldW * 0.42; y1 = $worldH * 0.66; x2 = $worldW * 0.62; y2 = $worldH * 0.74; startR = 32; endR = 20; curveX = 60; curveY = 30; pointsNum = 50; jitter = 0.10 },
    [pscustomobject]@{ id = "right_crescent"; x1 = $worldW * 0.42; y1 = $worldH * 0.66; x2 = $worldW * 0.72; y2 = $worldH * 0.50; startR = 30; endR = 16; curveX = 100; curveY = -80; pointsNum = 60; jitter = 0.10 },
    [pscustomobject]@{ id = "upright_young_shoot"; x1 = $worldW * 0.35; y1 = $worldH * 0.60; x2 = $worldW * 0.56; y2 = $worldH * 0.24; startR = 18; endR = 8; curveX = 30; curveY = -100; pointsNum = 70; jitter = 0.10 },
    [pscustomobject]@{ id = "poetry_col_1"; x1 = $worldW * 0.82; y1 = $worldH * 0.28; x2 = $worldW * 0.82; y2 = $worldH * 0.62; startR = 4; endR = 4; curveX = 0; curveY = 0; pointsNum = 20; jitter = 0.0 },
    [pscustomobject]@{ id = "poetry_col_2"; x1 = $worldW * 0.86; y1 = $worldH * 0.28; x2 = $worldW * 0.86; y2 = $worldH * 0.62; startR = 4; endR = 4; curveX = 0; curveY = 0; pointsNum = 20; jitter = 0.0 },
    [pscustomobject]@{ id = "poetry_col_3"; x1 = $worldW * 0.90; y1 = $worldH * 0.28; x2 = $worldW * 0.90; y2 = $worldH * 0.62; startR = 4; endR = 4; curveX = 0; curveY = 0; pointsNum = 20; jitter = 0.0 },
    [pscustomobject]@{ id = "poetry_col_4"; x1 = $worldW * 0.94; y1 = $worldH * 0.28; x2 = $worldW * 0.94; y2 = $worldH * 0.62; startR = 4; endR = 4; curveX = 0; curveY = 0; pointsNum = 20; jitter = 0.0 }
)

$targets = @(
    [pscustomobject]@{ branchId = "main_trunk"; progress = 0.5; radius = 38 },
    [pscustomobject]@{ branchId = "hanging_branch"; progress = 0.4; radius = 38 },
    [pscustomobject]@{ branchId = "hanging_branch"; progress = 0.9; radius = 38 },
    [pscustomobject]@{ branchId = "upright_young_shoot"; progress = 0.4; radius = 38 },
    [pscustomobject]@{ branchId = "upright_young_shoot"; progress = 0.9; radius = 38 },
    [pscustomobject]@{ branchId = "right_crescent"; progress = 0.35; radius = 38 },
    [pscustomobject]@{ branchId = "right_crescent"; progress = 0.8; radius = 38 },
    [pscustomobject]@{ branchId = "poetry_col_1"; progress = 0.6; radius = 38 }
)

$branchFieldDefs = @(
    New-FieldDef 101 "branchId" "F_String"
    New-FieldDef 102 "x1" "F_Float"
    New-FieldDef 103 "y1" "F_Float"
    New-FieldDef 104 "x2" "F_Float"
    New-FieldDef 105 "y2" "F_Float"
    New-FieldDef 106 "startR" "F_Int"
    New-FieldDef 107 "endR" "F_Int"
    New-FieldDef 108 "curveX" "F_Int"
    New-FieldDef 109 "curveY" "F_Int"
    New-FieldDef 110 "pointsNum" "F_Int"
    New-FieldDef 111 "jitter" "F_Float"
    New-FieldDef 112 "material" "F_String"
)

$targetFieldDefs = @(
    New-FieldDef 121 "branchId" "F_String"
    New-FieldDef 122 "progress" "F_Float"
    New-FieldDef 123 "radius" "F_Int"
    New-FieldDef 124 "material" "F_String"
)

$nodeFieldDefs = @(
    New-FieldDef 151 "branchId" "F_String"
    New-FieldDef 152 "nodeIndex" "F_Int"
    New-FieldDef 153 "t" "F_Float"
    New-FieldDef 154 "radius" "F_Float"
    New-FieldDef 155 "material" "F_String"
)

$startFieldDefs = @(
    New-FieldDef 131 "facing" "F_String"
)

$materialFieldDefs = @(
    New-FieldDef 141 "role" "F_String"
    New-FieldDef 142 "rgb" "F_String"
)

$branchDef = New-EntityDef 201 "BranchCurve" "#554B3F" 72 28 $branchFieldDefs
$targetDef = New-EntityDef 202 "PlumBudTarget" "#E6D7C2" 42 42 $targetFieldDefs
$startDef = New-EntityDef 203 "PlayerStart" "#3BB273" 42 42 $startFieldDefs
$materialDef = New-EntityDef 204 "MaterialSwatch" "#B3483E" 120 28 $materialFieldDefs
$nodeDef = New-EntityDef 205 "BranchNode" "#2A1E18" 18 18 $nodeFieldDefs "Ellipse" $true $false

$branchLayerDef = New-LayerDef 301 "Branch_Curves" "Entities" "#554B3F" 16
$targetLayerDef = New-LayerDef 302 "Blossom_Targets" "Entities" "#E6D7C2" 16
$gameplayLayerDef = New-LayerDef 303 "Gameplay" "Entities" "#3BB273" 16
$materialLayerDef = New-LayerDef 304 "Material_Lock" "Entities" "#B3483E" 16
$nodeLayerDef = New-LayerDef 305 "Branch_Nodes" "Entities" "#2A1E18" 16

$branchEntities = foreach ($b in $branches) {
    $fields = @(
        New-FieldInstance $branchFieldDefs[0] $b.id
        New-FieldInstance $branchFieldDefs[1] $b.x1
        New-FieldInstance $branchFieldDefs[2] $b.y1
        New-FieldInstance $branchFieldDefs[3] $b.x2
        New-FieldInstance $branchFieldDefs[4] $b.y2
        New-FieldInstance $branchFieldDefs[5] $b.startR
        New-FieldInstance $branchFieldDefs[6] $b.endR
        New-FieldInstance $branchFieldDefs[7] $b.curveX
        New-FieldInstance $branchFieldDefs[8] $b.curveY
        New-FieldInstance $branchFieldDefs[9] $b.pointsNum
        New-FieldInstance $branchFieldDefs[10] $b.jitter
        New-FieldInstance $branchFieldDefs[11] "plum_mirror_ink"
    )
    New-EntityInstance $branchDef ([int][math]::Round($b.x1)) ([int][math]::Round($b.y1)) $fields
}

$branchNodeEntities = foreach ($b in $branches) {
    for ($i = 0; $i -le $b.pointsNum; $i++) {
        $n = Sample-BranchNode $b $i
        $diameter = [int][math]::Max(8, [math]::Round($n.r * 2))
        $fields = @(
            New-FieldInstance $nodeFieldDefs[0] $n.branchId
            New-FieldInstance $nodeFieldDefs[1] $n.index
            New-FieldInstance $nodeFieldDefs[2] $n.t
            New-FieldInstance $nodeFieldDefs[3] $n.r
            New-FieldInstance $nodeFieldDefs[4] "plum_mirror_ink"
        )
        New-EntityInstance $nodeDef ([int][math]::Round($n.x - $diameter * 0.5)) ([int][math]::Round($n.y - $diameter * 0.5)) $fields $diameter $diameter
    }
}

$targetEntities = foreach ($t in $targets) {
    $branch = $branches | Where-Object { $_.id -eq $t.branchId } | Select-Object -First 1
    $p = Sample-Branch $branch $t.progress
    $fields = @(
        New-FieldInstance $targetFieldDefs[0] $t.branchId
        New-FieldInstance $targetFieldDefs[1] $t.progress
        New-FieldInstance $targetFieldDefs[2] $t.radius
        New-FieldInstance $targetFieldDefs[3] "plum_mirror_bloom"
    )
    New-EntityInstance $targetDef ($p.x - 21) ($p.y - 21) $fields
}

$safe = Sample-Branch $branches[0] (14.0 / 60.0)
$startX = $safe.x
$startY = $safe.y - 32 - $physics.radius - 25
$startEntity = New-EntityInstance $startDef ([int]$startX) ([int]$startY) @(
    New-FieldInstance $startFieldDefs[0] "right"
)

$materialEntities = @()
$mx = 48
$my = 48
foreach ($key in $materials.Keys) {
    $rgb = ($materials[$key] -join ",")
    $materialEntities += New-EntityInstance $materialDef $mx $my @(
        New-FieldInstance $materialFieldDefs[0] $key
        New-FieldInstance $materialFieldDefs[1] $rgb
    )
    $my += 40
}

$levelId = 1
$level = [ordered]@{
    identifier = "UrhoX_Level_12_Plum_Mirror"
    iid = New-Iid
    uid = $levelId
    worldX = 0
    worldY = 0
    worldDepth = 0
    pxWid = $worldW
    pxHei = $worldH
    __bgColor = "#F6EDE1"
    bgColor = "#F6EDE1"
    useAutoIdentifier = $false
    bgRelPath = $null
    bgPos = $null
    bgPivotX = 0.5
    bgPivotY = 0.5
    __smartColor = "#F6EDE1"
    __bgPos = $null
    externalRelPath = $null
    fieldInstances = @()
    layerInstances = @(
        New-EntityLayer $materialLayerDef $levelId $worldW $worldH $materialEntities
        New-EntityLayer $gameplayLayerDef $levelId $worldW $worldH @($startEntity)
        New-EntityLayer $targetLayerDef $levelId $worldW $worldH $targetEntities
        New-EntityLayer $nodeLayerDef $levelId $worldW $worldH $branchNodeEntities
        New-EntityLayer $branchLayerDef $levelId $worldW $worldH $branchEntities
    )
}

$project = [ordered]@{
    __header__ = [ordered]@{
        fileType = "LDtk Project JSON"
        app = "LDtk"
        doc = "https://ldtk.io/json"
        schema = "https://ldtk.io/files/JSON_SCHEMA.json"
        appAuthor = "Deepnight Games"
    }
    iid = New-Iid
    jsonVersion = "1.5.3"
    appBuildId = 473
    nextUid = 500
    identifierStyle = "Capitalize"
    toc = @()
    worldLayout = "Free"
    worldGridWidth = 256
    worldGridHeight = 256
    defaultLevelWidth = $worldW
    defaultLevelHeight = $worldH
    defaultPivotX = 0
    defaultPivotY = 0
    defaultGridSize = 16
    defaultEntityWidth = 32
    defaultEntityHeight = 32
    bgColor = "#F6EDE1"
    defaultLevelBgColor = "#F6EDE1"
    minifyJson = $false
    externalLevels = $false
    exportTiled = $false
    simplifiedExport = $false
    imageExportMode = "None"
    exportLevelBg = $true
    pngFilePattern = $null
    backupOnSave = $false
    backupLimit = 10
    backupRelPath = $null
    levelNamePattern = "Level_%idx"
    tutorialDesc = "UrhoX level 12 plum mirror. Branch curves, targets, physics, and material lock are authored for lossless export back to UrhoX."
    customCommands = @()
    flags = @()
    defs = [ordered]@{
        layers = @($materialLayerDef, $gameplayLayerDef, $targetLayerDef, $nodeLayerDef, $branchLayerDef)
        entities = @($branchDef, $targetDef, $startDef, $materialDef, $nodeDef)
        tilesets = @()
        enums = @()
        externalEnums = @()
        levelFields = @()
    }
    levels = @($level)
    worlds = @()
    dummyWorldIid = New-Iid
}

$outDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputPath, ($project | ConvertTo-Json -Depth 100), $utf8NoBom)

Write-Host "Created $OutputPath"
Write-Host "  branches: $($branches.Count)"
Write-Host "  branch nodes: $($branchNodeEntities.Count)"
Write-Host "  targets: $($targets.Count)"
Write-Host "  material swatches: $($materials.Count)"
