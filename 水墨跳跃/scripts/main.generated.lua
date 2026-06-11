-- AUTO-GENERATED FILE. Do not edit directly.
-- Edit scripts/src/*.lua, then run tools/build_main.ps1.

-- ============================================================================
-- BEGIN scripts/src/00_state_levels_keys.lua
-- ============================================================================
---@diagnostic disable: access-invisible, assign-type-mismatch, param-type-mismatch, missing-parameter
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
-- ============================================================================
-- UrhoXPlatformerClean
-- Faithful UrhoX/NanoVG port of the Gemini ink-painting HTML level studies.
-- The implementation keeps the HTML proportions, circle-player physics,
-- ink trails, branch/rope/eaves/cloud/crane mechanics, and blossom targets.
-- ============================================================================

local DESIGN_W = 1280
local DESIGN_H = 720
local FIXED_DT = 1 / 60
local MASTER_PLUM_IMAGE_W = 2061
local MASTER_PLUM_IMAGE_H = 3876
local MASTER_PLUM_ASPECT = MASTER_PLUM_IMAGE_W / MASTER_PLUM_IMAGE_H

local vg = nil
local masterPlumImage = nil
local masterPlumImageTried = false
local masterPlumDrawX, masterPlumDrawY, masterPlumDrawW, masterPlumDrawH = 0, 0, 0, 0
local fontReady = false
local elapsed = 0
local accumulator = 0
local showDebug = false
local showHelp = false
local showSeal = false
sealViewProgress = 0
sealStampProgress = 0
completionSealDelay = 0

local screenW, screenH = DESIGN_W, DESIGN_H
local fitScale, viewX, viewY = 1, 0, 0
local cameraX, cameraY = 0, 0

local keys = { a = false, d = false, w = false, s = false, space = false, shift = false }
local dashJustPressed = false

local currentLevelIdx = 1
local currentLevel = nil
local worldW, worldH = DESIGN_W * 3.5, DESIGN_H * 2.2

local branches = {}
local branchGroups = {}
local branchMetadata = {}
local bambooSegments = {}
local targets = {}
local blooms = {}
local trailParticles = {}
local dashFluidPoints = {}
local dashFluidDroplets = {}
local dashFluidDistance = 0
local fluidTrailEnhancedFrames = 0
local fluidTrailRecentMoveFrames = 0
fluidTrailDashBlend = 0
local bristleParticles = {}
needleCorpses = {}
local ambientParticles = {}
local glidingLeaves = {}
local willowRopes = {}
local floatingPetals = {}
local roofs = {}
local pavilions = {}
local gears = {}
local chimes = {}
local cranes = {}
local cloudPlatforms = {}
local streams = {}
local pineSprings = {}
local windWaves = {}

local collectedCount = 0
local completionTimer = 0
local waterLevel = 0

local player = {
    x = 0, y = 0, vx = 0, vy = 0,
    radius = 11,
    gravity = 0.52,
    gravityDefault = 0.52,
    friction = 0.86,
    speed = 1.6,
    jumpForce = -15.5,
    dashSpeed = 19,
    dashTime = 0,
    dashDirX = 0,
    dashDirY = 0,
    isDashing = false,
    facingRight = true,
    canDash = true,
    isGrounded = false,
    isWallClinging = false,
    wallSide = 0,
    isGliding = false,
    swingRope = nil,
    ridingCrane = nil,
    craneCooldown = 0,
    onEaves = nil,
    eavesT = 0,
    eavesSpeed = 0,
}

local function C(r, g, b)
    return { r, g, b }
end

local LEVELS = {
    {
        id = "bamboo",
        name = "幽竹飞瀑",
        title = "水墨平台跳跃 - 幽竹飞瀑图",
        seal = "竹",
        note = "跃入留白飞瀑可御风升腾。冲刺碰撞竹竿会泼墨留痕并震落竹叶，唤醒翠竹新枝。",
        wmul = 3.0,
        hmul = 2.5,
        paper = C(232, 238, 230),
        paper2 = C(205, 214, 206),
        ink = C(8, 15, 12),
        wash = C(43, 89, 63),
        accent = C(67, 106, 76),
        bloom = C(70, 132, 82),
        water = C(232, 238, 230),
        radius = 10,
        gravity = 0.55,
        jumpForce = -16.0,
        dashSpeed = 20,
        friction = 0.85,
    },
    {
        id = "pine",
        name = "松风听泉",
        title = "水墨平台跳跃 - 松风听泉图",
        seal = "松",
        note = "苍松枝干为真实曲线碰撞，山涧溪流有牵引，松针簇可弹跳。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(243, 239, 230),
        paper2 = C(229, 222, 201),
        ink = C(30, 38, 31),
        wash = C(67, 88, 70),
        accent = C(45, 68, 50),
        bloom = C(55, 123, 83),
        water = C(91, 134, 132),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "maple",
        name = "秋林红叶",
        title = "水墨平台跳跃 - 秋林红叶图",
        seal = "秋",
        note = "枫枝按 HTML 的层级骨骼生成，踩踏会下沉回弹，落叶可短暂滑翔。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(242, 230, 207),
        paper2 = C(223, 205, 176),
        ink = C(42, 36, 30),
        wash = C(128, 94, 68),
        accent = C(146, 50, 40),
        bloom = C(195, 22, 22),
        water = C(180, 96, 54),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "plum",
        name = "蟠梅长卷",
        title = "水墨平台跳跃 - 蟠梅长卷",
        seal = "梅",
        note = "王冕墨梅式横斜虬枝、直挺新梢和四列题诗字柱都参与碰撞。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(246, 237, 225),
        paper2 = C(220, 207, 190),
        ink = C(42, 30, 24),
        wash = C(114, 82, 69),
        accent = C(142, 35, 42),
        bloom = C(195, 18, 18),
        water = C(204, 165, 68),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "peach",
        name = "桃花春水",
        sourceFile = "鏌崇诞.md",
        title = "水墨平台跳跃 - 桃花春水图",
        seal = "桃",
        note = "垂柳摆绳、春水浮瓣、桃蕾和右岸古干按 HTML 原型复刻。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(236, 241, 226),
        paper2 = C(207, 222, 196),
        ink = C(38, 63, 41),
        wash = C(84, 120, 78),
        accent = C(84, 120, 78),
        bloom = C(240, 95, 120),
        water = C(120, 158, 141),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "eaves",
        name = "古阁飞檐",
        title = "水墨平台跳跃 - 古阁飞檐图",
        seal = "檐",
        note = "界画楼台、飞檐滑轨、榫卯齿轮、铜风铃与金墨冲刺为原稿机制。",
        wmul = 3.5,
        hmul = 2.2,
        backdrop = C(17, 21, 18),
        paper = C(236, 201, 149),
        paper2 = C(204, 163, 102),
        ink = C(17, 21, 18),
        wash = C(22, 33, 26),
        accent = C(28, 69, 46),
        bloom = C(218, 165, 32),
        water = C(50, 95, 75),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19.5,
        friction = 0.86,
    },
    {
        id = "huangshan",
        name = "黄山云海",
        title = "水墨平台跳跃 - 黄山云海图",
        seal = "云",
        note = "奇松节点、云团平台和可骑乘仙鹤按源稿比例生成。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(235, 240, 232),
        paper2 = C(202, 217, 210),
        ink = C(26, 47, 35),
        wash = C(78, 116, 96),
        accent = C(43, 89, 63),
        bloom = C(224, 168, 38),
        water = C(170, 190, 186),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "plum_master",
        name = "墨梅母本",
        title = "母本复刻 - 王冕《断桥香雪图》",
        seal = "梅",
        note = "以真实墨梅图为母本：关卡路径贴着梅枝走，花苞目标和题诗留白跟随画面结构。",
        wmul = 1.0,
        hmul = DESIGN_W / (MASTER_PLUM_ASPECT * DESIGN_H),
        paper = C(232, 225, 207),
        paper2 = C(196, 184, 158),
        ink = C(28, 25, 21),
        wash = C(86, 82, 70),
        accent = C(55, 63, 52),
        bloom = C(156, 42, 32),
        water = C(184, 182, 166),
        radius = 10,
        gravity = 0.53,
        jumpForce = -15.8,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "pine",
        variant = "ink_atlas",
        sourceLevelIndex = 2,
        name = "Pine InkLab",
        title = "Pine InkLab",
        seal = "P",
        note = "Pine level copy for ink atlas and image-generation style experiments.",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(243, 239, 230),
        paper2 = C(229, 222, 201),
        ink = C(30, 38, 31),
        wash = C(67, 88, 70),
        accent = C(45, 68, 50),
        bloom = C(55, 123, 83),
        water = C(91, 134, 132),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "ldtk_grand_scroll",
        sourceFile = "ldtk/ink_grand_scroll.ldtk",
        name = "World 1 Grand Scroll",
        title = "LDtk import - first grand ink scroll",
        seal = "LD",
        note = "Imported from LDtk: bamboo falls, pine spring, peach water, plum scroll, pavilion eaves, Huangshan clouds, cranes, and final plum.",
        wmul = 7.5,
        hmul = 3.0,
        paper = C(238, 234, 222),
        paper2 = C(214, 205, 184),
        ink = C(28, 25, 21),
        wash = C(88, 110, 92),
        accent = C(64, 106, 76),
        bloom = C(190, 55, 70),
        water = C(150, 178, 170),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.8,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "plum_parallax",
        sourceLevelIndex = 4,
        name = "梅影重楼",
        title = "水墨平台跳跃 - 梅影重楼图",
        seal = "楼",
        note = "多层远近景叠影，楼阁桥亭化为水墨剪影，云雾流转间梅枝隐现。",
        wmul = 4.0,
        hmul = 2.5,
        paper = C(22, 38, 62),
        paper2 = C(35, 55, 85),
        ink = C(12, 18, 32),
        wash = C(55, 85, 125),
        accent = C(80, 120, 165),
        bloom = C(195, 18, 18),
        water = C(140, 175, 210),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
        parallaxLayers = true,
    },
    {
        id = "plum_mirror",
        sourceLevelIndex = 4,
        name = "梅影倒卷",
        title = "水墨平台跳跃 - 梅影倒卷图",
        seal = "倒",
        note = "蟠梅长卷的镜像布局，从左向右攀越虬枝，题诗移至右壁。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(246, 237, 225),
        paper2 = C(220, 207, 190),
        ink = C(42, 30, 24),
        wash = C(114, 82, 69),
        accent = C(142, 35, 42),
        bloom = C(195, 18, 18),
        water = C(204, 165, 68),
        radius = 11,
        gravity = 0.46,
        jumpForce = -16.5,
        dashSpeed = 21,
        friction = 0.84,
    },
    {
        id = "plum_finale",
        sourceImage = "reference/wang_mian_twin_purities_plum.jpg",
        name = "双清梅卷",
        title = "母本复刻 - 王冕《梅竹双清卷》梅段",
        seal = "清",
        note = "复刻台北故宫《梅竹双清卷》王冕墨梅段：主枝自左缘横出、长鞭拖至右下，圈花白描不设色，右壁题诗三柱可攀。",
        -- 画芯 1045x900，比例 1.161；世界尺寸按母本比例设定（同 plum_master 先例）
        wmul = 2.0,
        hmul = 3.06,
        paper = C(214, 190, 152),
        paper2 = C(193, 168, 128),
        ink = C(56, 46, 36),
        wash = C(120, 102, 80),
        accent = C(166, 38, 38),
        bloom = C(240, 232, 212),
        water = C(196, 178, 148),
        radius = 11,
        gravity = 0.46,
        jumpForce = -16.5,
        dashSpeed = 21,
        friction = 0.84,
    },
    {
        id = "wentong_zhu",
        sourceImage = "reference/wen_tong_bamboo.jpg",
        name = "倒垂竹",
        title = "母本复刻 - 文同《墨竹图》",
        seal = "竹",
        note = "复刻台北故宫文同《墨竹图》：S 形主竿自左上倒垂入谷再扬至右缘，节节生枝、枝枝缀叶。",
        -- 画芯 1830x2880,比例 0.635;大画布精刻
        wmul = 2.2,
        hmul = 6.16,
        paper = C(172, 140, 86),
        paper2 = C(146, 116, 68),
        ink = C(26, 22, 16),
        wash = C(70, 58, 38),
        accent = C(52, 80, 44),
        bloom = C(48, 42, 30),
        water = C(140, 118, 76),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "plum_xiyan",
        sourceImage = "reference/wang_mian_ink_plum_beijing.jpg",
        name = "洗砚梅",
        title = "母本复刻 - 王冕《墨梅图》卷(故宫)",
        seal = "砚",
        note = "复刻北京故宫王冕《墨梅图》卷：主干自右缘横出渐细成长梢，两枝上扬入花团，左端回锋，『吾家洗砚池头树』题于左壁。",
        -- 画芯 3601x2226,比例 1.618;大画布精刻
        wmul = 3.8,
        hmul = 4.18,
        paper = C(206, 202, 192),
        paper2 = C(184, 178, 166),
        ink = C(48, 44, 40),
        wash = C(110, 104, 94),
        accent = C(150, 40, 44),
        bloom = C(140, 134, 126),
        water = C(176, 170, 158),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "xuwei_grape",
        sourceImage = "reference/xu_wei_grapes.jpg",
        name = "墨葡萄",
        title = "母本复刻 - 徐渭《墨葡萄图》",
        seal = "葡",
        note = "复刻北京故宫徐渭《墨葡萄图》：狂草主藤自右上横垂，两侧垂蔓飘悬，串串墨葡萄半生晾作明珠。",
        -- 画芯 509x1341,比例 0.380(立轴纵关);大画布精刻
        wmul = 1.6,
        hmul = 7.49,
        paper = C(214, 202, 176),
        paper2 = C(190, 176, 148),
        ink = C(40, 36, 30),
        wash = C(96, 86, 70),
        accent = C(88, 74, 96),
        bloom = C(118, 96, 138),
        water = C(180, 168, 144),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "molong",
        name = "墨龙行雨",
        title = "意象复刻 - 陈容《九龙图》墨龙",
        seal = "龙",
        note = "墨龙是一条活的平台：龙身游波起伏会驮着你、抛起你；踏云逐珠，冲刺碎珠可炸雷光。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(166, 158, 140),
        paper2 = C(138, 130, 112),
        ink = C(22, 20, 18),
        wash = C(82, 78, 70),
        accent = C(120, 96, 52),
        bloom = C(216, 174, 64),
        water = C(110, 112, 106),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
}

local leftKeys = { string.byte("a"), string.byte("A") }
local rightKeys = { string.byte("d"), string.byte("D") }
local upKeys = { string.byte("w"), string.byte("W") }
local downKeys = { string.byte("s"), string.byte("S") }
local jumpKeys = { string.byte(" ") }
local dashKeys = { string.byte("j"), string.byte("J") }
local debugKeys = { string.byte("c"), string.byte("C") }
local helpKeys = { string.byte("h"), string.byte("H") }
local resetKeys = { string.byte("r"), string.byte("R") }
local prevKeys = { string.byte("q"), string.byte("Q") }
local nextKeys = { string.byte("e"), string.byte("E") }
local sealKeys = { string.byte("f"), string.byte("F") }

if KEY_A then leftKeys[#leftKeys + 1] = KEY_A end
if KEY_LEFT then leftKeys[#leftKeys + 1] = KEY_LEFT end
if KEY_D then rightKeys[#rightKeys + 1] = KEY_D end
if KEY_RIGHT then rightKeys[#rightKeys + 1] = KEY_RIGHT end
if KEY_W then upKeys[#upKeys + 1] = KEY_W end
if KEY_UP then upKeys[#upKeys + 1] = KEY_UP end
if KEY_S then downKeys[#downKeys + 1] = KEY_S end
if KEY_DOWN then downKeys[#downKeys + 1] = KEY_DOWN end
if KEY_SPACE then jumpKeys[#jumpKeys + 1] = KEY_SPACE end
if KEY_J then dashKeys[#dashKeys + 1] = KEY_J end
if KEY_C then debugKeys[#debugKeys + 1] = KEY_C end
if KEY_H then helpKeys[#helpKeys + 1] = KEY_H end
if KEY_R then resetKeys[#resetKeys + 1] = KEY_R end
if KEY_Q then prevKeys[#prevKeys + 1] = KEY_Q end
if KEY_E then nextKeys[#nextKeys + 1] = KEY_E end
if KEY_F then sealKeys[#sealKeys + 1] = KEY_F end

local function keyMatches(key, set)
    for i = 1, #set do
        if key == set[i] then return true end
    end
    return false
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function dist2(x, y)
    return math.sqrt(x * x + y * y)
end

local function frac(v)
    return v - math.floor(v)
end

local function hash01(seed)
    return frac(math.sin(seed * 12.9898) * 43758.5453)
end

local function colorRGB(c)
    return nvgRGB(c[1], c[2], c[3])
end

local function colorRGBA(c, a)
    return nvgRGBA(c[1], c[2], c[3], math.floor(a))
end

local function rgba(r, g, b, a)
    return nvgRGBA(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
end

local function W(v) return worldW * v end
local function H(v) return worldH * v end

-- ============================================================================
-- END scripts/src/00_state_levels_keys.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/10_drawing_primitives_layout.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.

local function drawRect(x, y, w, h, r, color)
    nvgBeginPath(vg)
    if r and r > 0 then nvgRoundedRect(vg, x, y, w, h, r) else nvgRect(vg, x, y, w, h) end
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawStrokeRect(x, y, w, h, r, color, width)
    nvgBeginPath(vg)
    if r and r > 0 then nvgRoundedRect(vg, x, y, w, h, r) else nvgRect(vg, x, y, w, h) end
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width or 1)
    nvgStroke(vg)
end

local function drawCircle(x, y, r, color)
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, r)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawEllipse(x, y, rx, ry, color)
    nvgBeginPath(vg)
    nvgEllipse(vg, x, y, rx, ry)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawRotEllipse(x, y, rx, ry, angle, color)
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, angle)
    drawEllipse(0, 0, rx, ry, color)
    nvgRestore(vg)
end

local function strokeLine(x1, y1, x2, y2, width, color)
    nvgBeginPath(vg)
    nvgMoveTo(vg, x1, y1)
    nvgLineTo(vg, x2, y2)
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function strokeBezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2, width, color)
    nvgBeginPath(vg)
    nvgMoveTo(vg, x1, y1)
    nvgBezierTo(vg, cx1, cy1, cx2, cy2, x2, y2)
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function strokeQuad(x1, y1, cx, cy, x2, y2, width, color)
    strokeBezier(
        x1, y1,
        x1 + (cx - x1) * 0.6667, y1 + (cy - y1) * 0.6667,
        x2 + (cx - x2) * 0.6667, y2 + (cy - y2) * 0.6667,
        x2, y2, width, color
    )
end

local function fillPetalShape(len, width, color)
    nvgBeginPath(vg)
    nvgMoveTo(vg, 0, 0)
    nvgBezierTo(vg, width, len * 0.5, width * 0.5, len, 0, len)
    nvgBezierTo(vg, -width * 0.5, len, -width, len * 0.5, 0, 0)
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function fillLeafBud(x, y, r, fillColor, strokeColor, veinColor)
    nvgBeginPath(vg)
    nvgMoveTo(vg, x, y - r)
    nvgBezierTo(vg, x + r * 0.78, y - r * 0.64, x + r * 1.10, y + r * 0.10, x + r * 0.20, y + r * 0.95)
    nvgBezierTo(vg, x - r * 1.10, y - r * 0.10, x - r * 0.78, y - r * 0.64, x, y - r)
    nvgClosePath(vg)
    nvgFillColor(vg, fillColor)
    nvgFill(vg)
    if strokeColor then
        nvgStrokeColor(vg, strokeColor)
        nvgStrokeWidth(vg, 2.5)
        nvgStroke(vg)
    end
    if veinColor then
        strokeQuad(x, y - r, x - r * 0.25, y + r * 0.2, x + r * 0.1, y + r * 0.85, 2, veinColor)
    end
end

local function fillPoly(points, color)
    if #points < 3 then return end
    nvgBeginPath(vg)
    nvgMoveTo(vg, points[1][1], points[1][2])
    for i = 2, #points do nvgLineTo(vg, points[i][1], points[i][2]) end
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawText(x, y, size, color, text, align)
    if not fontReady then return end
    nvgFontFace(vg, "sans")
    nvgFontSize(vg, size)
    nvgTextAlign(vg, align or (NVG_ALIGN_LEFT + NVG_ALIGN_TOP))
    nvgFillColor(vg, color)
    nvgText(vg, x, y, text)
end

local function utf8Chars(text)
    local chars = {}
    for ch in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    return chars
end

local function addBranchNode(n)
    branches[#branches + 1] = n
    if not branchGroups[n.branchId] then branchGroups[n.branchId] = {} end
    branchGroups[n.branchId][#branchGroups[n.branchId] + 1] = n
    if not branchBounds then branchBounds = {} end
    local b = branchBounds[n.branchId]
    local pad = (n.r or 0) + 70
    if not b then
        branchBounds[n.branchId] = { minX = n.x - pad, maxX = n.x + pad, minY = n.y - pad, maxY = n.y + pad }
    else
        b.minX = math.min(b.minX, n.x - pad)
        b.maxX = math.max(b.maxX, n.x + pad)
        b.minY = math.min(b.minY, n.y - pad)
        b.maxY = math.max(b.maxY, n.y + pad)
    end
end

local function qbez(a, b, c, t)
    local it = 1 - t
    return it * it * a + 2 * it * t * b + t * t * c
end

local function createBranch(x1, y1, x2, y2, startR, endR, curveX, curveY, pointsNum, branchId, jitter)
    local cpX = (x1 + x2) * 0.5 + curveX
    local cpY = (y1 + y2) * 0.5 + curveY
    local list = {}
    for i = 0, pointsNum do
        local t = i / pointsNum
        local x = qbez(x1, cpX, x2, t)
        local y = qbez(y1, cpY, y2, t)
        local r = startR + (endR - startR) * t
        if jitter and jitter > 0 then
            r = r + (hash01(i * 19 + x * 0.013 + y * 0.017) - 0.5) * (startR * jitter)
        end
        local nt = math.min(t + 0.01, 1)
        local nx = qbez(x1, cpX, x2, nt)
        local ny = qbez(y1, cpY, y2, nt)
        local dx, dy = nx - x, ny - y
        local len = dist2(dx, dy)
        if len < 0.0001 then len = 1 end
        local normX, normY = -dy / len, dx / len
        if normY > 0 then normX, normY = -normX, -normY end
        local n = { x = x, y = y, r = r, normX = normX, normY = normY, branchId = branchId, t = t, baseX = x, baseY = y }
        addBranchNode(n)
        list[#list + 1] = n
    end
    return list
end

local function createBranchPath(points, branchId, jitter)
    if #points < 2 then return {} end
    local scaled = {}
    local totalLen = 0
    for i = 1, #points do
        local p = points[i]
        scaled[i] = { x = W(p[1]), y = H(p[2]), r = p[3] or 6 }
        if i > 1 then
            local a, b = scaled[i - 1], scaled[i]
            totalLen = totalLen + dist2(b.x - a.x, b.y - a.y)
        end
    end
    if totalLen < 0.001 then return {} end

    local list = {}
    local traveled = 0
    for i = 1, #scaled - 1 do
        local a, b = scaled[i], scaled[i + 1]
        local dx, dy = b.x - a.x, b.y - a.y
        local segLen = dist2(dx, dy)
        local steps = math.max(2, math.floor(segLen / 9))
        for s = 0, steps - 1 do
            local u = s / steps
            local x = a.x + dx * u
            local y = a.y + dy * u
            local r = a.r + (b.r - a.r) * u
            if jitter and jitter > 0 then
                r = r + (hash01(i * 31 + s * 19 + x * 0.01) - 0.5) * (a.r * jitter)
            end
            local len = segLen
            if len < 0.001 then len = 1 end
            local normX, normY = -dy / len, dx / len
            if normY > 0 then normX, normY = -normX, -normY end
            local n = { x = x, y = y, r = r, normX = normX, normY = normY, branchId = branchId, t = (traveled + segLen * u) / totalLen, baseX = x, baseY = y }
            addBranchNode(n)
            list[#list + 1] = n
        end
        traveled = traveled + segLen
    end

    local a, b = scaled[#scaled - 1], scaled[#scaled]
    local dx, dy = b.x - a.x, b.y - a.y
    local len = dist2(dx, dy)
    if len < 0.001 then len = 1 end
    local normX, normY = -dy / len, dx / len
    if normY > 0 then normX, normY = -normX, -normY end
    local n = { x = b.x, y = b.y, r = b.r, normX = normX, normY = normY, branchId = branchId, t = 1, baseX = b.x, baseY = b.y }
    addBranchNode(n)
    list[#list + 1] = n
    return list
end

local function addTarget(x, y, r, attachX, attachY, nx, ny, branchId, nodeIndex, attachOffset)
    targets[#targets + 1] = {
        x = x, y = y, r = r or 34,
        attachX = attachX, attachY = attachY,
        normX = nx or 0, normY = ny or -1,
        branchId = branchId, nodeIndex = nodeIndex, attachOffset = attachOffset,
        orientationJitter = (hash01((x or 0) * 0.017 + (y or 0) * 0.013) - 0.5) * 0.38,
        dead = false, pulse = hash01(#targets + 8) * 6.28318,
    }
end

local function addTargetOnBranch(branchId, progress, radius)
    local nodes = branchGroups[branchId]
    if not nodes or #nodes == 0 then return end
    local idx = clamp(math.floor(#nodes * progress), 1, #nodes)
    local n = nodes[idx]
    local off = n.r + 32
    addTarget(n.x + n.normX * off, n.y + n.normY * off, radius or 36, n.x, n.y, n.normX, n.normY, branchId, idx, off)
end

local function addMasterPlumFlowerTarget(xv, yv, axv, ayv, radius)
    local x, y = W(xv), H(yv)
    local ax, ay = W(axv), H(ayv)
    local dx, dy = x - ax, y - ay
    local len = dist2(dx, dy)
    if len < 0.001 then len = 1 end
    targets[#targets + 1] = {
        x = x, y = y, r = radius or 26,
        attachX = ax, attachY = ay,
        normX = dx / len, normY = dy / len,
        dead = false, pulse = hash01(#targets + 8) * 6.28318,
    }
end


-- ============================================================================
-- END scripts/src/10_drawing_primitives_layout.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/20_fluid_trail_particles.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function addTrail(x, y, r, alpha, life, kind)
    trailParticles[#trailParticles + 1] = { x = x, y = y, r = r, alpha = alpha or 0.18, life = life or 45, maxLife = life or 45, kind = kind }
end

local fluidTrailConfig = {
    normalMaxLength = 80,
    dashMaxLength = 130,
    baseWidth = 24,
    spineTension = 0.65,
    dashSpineTension = 0.93,
    pinchPropensity = 0.85,
    neckingExponent = 2.4,
    stationaryHoldFrames = 1,
    stationarySettleSpeed = 2.4,
    stationaryReflowSpacing = 1.6,
    enhancedReflowSpacing = 1.1,
    stationaryReflowConstraint = 0.86,
    enhancedReflowConstraint = 0.92,
    stationaryCollapsePull = 0.18,
    enhancedCollapsePull = 0.26,
    stationaryCullPerFrame = 3,
    enhancedCullPerFrame = 5,
    tailCollapseDistance = 2.4,
}

function fluidTrailIsEnhanced()
    return player.isDashing or keys.shift or fluidTrailEnhancedFrames > 0
end

local function fluidNoise1D(x, seed)
    local ix = math.floor(x)
    local xf = x - ix
    local u = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
    local g0 = hash01(ix * 17.37 + seed * 101.13) * 2 - 1
    local g1 = hash01((ix + 1) * 17.37 + seed * 101.13) * 2 - 1
    return (g0 * xf + u * (g1 * (xf - 1) - g0 * xf)) * 2
end

local function beginDashFluid(x, y)
    dashFluidPoints = {}
    dashFluidDistance = 0
    if x and y then
        dashFluidPoints[#dashFluidPoints + 1] = {
            x = x,
            y = y,
            dist = 0,
            velocity = dist2(player.vx or 0, player.vy or 0),
            dirX = player.facingRight and 1 or -1,
            dirY = 0,
            enhanced = false,
        }
    end
end

local function boostFluidTrail(frames)
    fluidTrailEnhancedFrames = math.max(fluidTrailEnhancedFrames, frames or 24)
end

local function spawnDashFluidDroplet(x, y, parentVel, nx, ny, seed, enhanced, dirX, dirY)
    local angle = hash01(seed + 13) * math.pi * 2
    local ejectSpeed = enhanced and (1.5 + hash01(seed + 17) * 5.0) or (0.5 + hash01(seed + 17) * 1.5)
    local tangentX, tangentY = dirX or (player.facingRight and 1 or -1), dirY or 0
    local tangentLen = dist2(tangentX, tangentY)
    if tangentLen < 0.001 then tangentX, tangentY, tangentLen = player.facingRight and 1 or -1, 0, 1 end
    tangentX, tangentY = tangentX / tangentLen, tangentY / tangentLen
    local backPull = enhanced and 0.38 or 0.15
    dashFluidDroplets[#dashFluidDroplets + 1] = {
        x = x,
        y = y,
        vx = -tangentX * parentVel * backPull + math.cos(angle) * ejectSpeed * 0.4 + nx * (hash01(seed + 23) - 0.5) * 0.7,
        vy = -tangentY * parentVel * backPull + math.sin(angle) * ejectSpeed * 0.4 + (enhanced and (-1.0 - hash01(seed + 29) * 2.0) or 0.4),
        radius = enhanced and (0.6 + hash01(seed + 31) * 1.8) or (2.0 + hash01(seed + 31) * 3.5),
        life = 1.0,
        decay = enhanced and (0.022 + hash01(seed + 37) * 0.03) or (0.015 + hash01(seed + 37) * 0.015),
        kind = enhanced and "dash_streak" or "normal_blob",
    }
    if #dashFluidDroplets > 120 then table.remove(dashFluidDroplets, 1) end
end

local function addDashFluidPoint(targetX, targetY, velocity, anchorHead, enhanced, dirX, dirY)
    local nextX, nextY = targetX, targetY
    local isEnhanced = enhanced or fluidTrailIsEnhanced()
    if #dashFluidPoints > 0 then
        local head = dashFluidPoints[#dashFluidPoints]
        if not anchorHead then
            local tension = isEnhanced and fluidTrailConfig.dashSpineTension or fluidTrailConfig.spineTension
            nextX = head.x + (targetX - head.x) * tension
            nextY = head.y + (targetY - head.y) * tension
        end
        dashFluidDistance = dashFluidDistance + dist2(nextX - head.x, nextY - head.y)
    end
    local tangentX, tangentY = dirX, dirY
    if not tangentX or not tangentY or dist2(tangentX, tangentY) < 0.001 then
        tangentX, tangentY = player.facingRight and 1 or -1, 0
    end
    dashFluidPoints[#dashFluidPoints + 1] = {
        x = nextX,
        y = nextY,
        dist = dashFluidDistance,
        velocity = velocity or 0,
        dirX = tangentX,
        dirY = tangentY,
        enhanced = isEnhanced,
    }
    local maxLength = fluidTrailIsEnhanced() and fluidTrailConfig.dashMaxLength or fluidTrailConfig.normalMaxLength
    while #dashFluidPoints > maxLength do table.remove(dashFluidPoints, 1) end
end

local function addDashStreak(x1, y1, x2, y2, kind)
    local dx, dy = x2 - x1, y2 - y1
    local len = dist2(dx, dy)
    if len < 1 then return end
    local enhanced = kind == true or kind == "enhanced" or fluidTrailIsEnhanced()
    local steps = math.max(1, math.ceil(len / (enhanced and 3 or 5)))
    local velocity = math.max(len, dist2(player.vx or 0, player.vy or 0))
    local dirX, dirY = dx / len, dy / len
    for i = 1, steps do
        local t = i / steps
        addDashFluidPoint(x1 + dx * t, y1 + dy * t, velocity, i == steps, enhanced, dirX, dirY)
    end
end

local function updateFluidTrailFromPlayer(prevX, prevY)
    prevX = prevX or player.x
    prevY = prevY or player.y
    local dx, dy = player.x - prevX, player.y - prevY
    local moveLen = dist2(dx, dy)
    local speed = math.max(moveLen, dist2(player.vx or 0, player.vy or 0))
    local enhanced = fluidTrailIsEnhanced()
    local inputActive = keys.a or keys.d or keys.w or keys.s or keys.space or keys.shift or player.isDashing
    local drivenMotion = player.onEaves or player.swingRope or player.ridingCrane or player.isGliding
    local settled = (not inputActive) and (not drivenMotion) and speed < fluidTrailConfig.stationarySettleSpeed

    if #dashFluidPoints == 0 then
        beginDashFluid(prevX, prevY)
    end

    if moveLen > 0.35 and not settled then
        fluidTrailRecentMoveFrames = fluidTrailConfig.stationaryHoldFrames
        addDashStreak(prevX, prevY, player.x, player.y, enhanced and "enhanced" or "normal")
    elseif #dashFluidPoints > 0 then
        if settled then fluidTrailRecentMoveFrames = 0 end
        local last = dashFluidPoints[#dashFluidPoints]
        last.x, last.y = player.x, player.y
        last.velocity = speed
        last.dirX = math.abs(player.vx or 0) + math.abs(player.vy or 0) > 0.001 and (player.vx / math.max(0.001, dist2(player.vx, player.vy))) or last.dirX
        last.dirY = math.abs(player.vx or 0) + math.abs(player.vy or 0) > 0.001 and (player.vy / math.max(0.001, dist2(player.vx, player.vy))) or last.dirY
        last.enhanced = last.enhanced or enhanced
    else
        addDashFluidPoint(player.x, player.y, speed, true, enhanced, player.facingRight and 1 or -1, 0)
    end

    local last = dashFluidPoints[#dashFluidPoints]
    if last then
        last.x, last.y = player.x, player.y
        last.velocity = speed
        local vLen = dist2(player.vx or 0, player.vy or 0)
        if vLen > 0.001 then
            last.dirX, last.dirY = player.vx / vLen, player.vy / vLen
        end
        last.enhanced = last.enhanced or enhanced
    end
end

function recomputeFluidTrailDistances()
    dashFluidDistance = 0
    for i = 1, #dashFluidPoints do
        local p = dashFluidPoints[i]
        if i == 1 then
            p.dist = 0
        else
            local prev = dashFluidPoints[i - 1]
            dashFluidDistance = dashFluidDistance + dist2(p.x - prev.x, p.y - prev.y)
            p.dist = dashFluidDistance
        end
    end
end

function reflowFluidTrailToPlayer()
    local count = #dashFluidPoints
    if count <= 1 then return end

    local enhanced = fluidTrailIsEnhanced()
    local spacing = enhanced and fluidTrailConfig.enhancedReflowSpacing or fluidTrailConfig.stationaryReflowSpacing
    local constraint = enhanced and fluidTrailConfig.enhancedReflowConstraint or fluidTrailConfig.stationaryReflowConstraint
    local collapsePull = enhanced and fluidTrailConfig.enhancedCollapsePull or fluidTrailConfig.stationaryCollapsePull
    local head = dashFluidPoints[count]
    head.x, head.y = player.x, player.y
    head.velocity = 0

    for i = count - 1, 1, -1 do
        local p = dashFluidPoints[i]
        local next = dashFluidPoints[i + 1]
        local dx, dy = p.x - next.x, p.y - next.y
        local d = dist2(dx, dy)
        if d > spacing then
            local targetX = next.x + dx / d * spacing
            local targetY = next.y + dy / d * spacing
            p.x = p.x + (targetX - p.x) * constraint
            p.y = p.y + (targetY - p.y) * constraint
        else
            p.x = p.x + (next.x - p.x) * collapsePull
            p.y = p.y + (next.y - p.y) * collapsePull
        end
        p.velocity = (p.velocity or 0) * 0.55
        p.dirX, p.dirY = next.x - p.x, next.y - p.y
    end

    local cull = enhanced and fluidTrailConfig.enhancedCullPerFrame or fluidTrailConfig.stationaryCullPerFrame
    local removed = 0
    while #dashFluidPoints > 1 and removed < cull do
        local tail = dashFluidPoints[1]
        local next = dashFluidPoints[2]
        if dist2(tail.x - next.x, tail.y - next.y) > fluidTrailConfig.tailCollapseDistance then break end
        table.remove(dashFluidPoints, 1)
        removed = removed + 1
    end

    recomputeFluidTrailDistances()
end

local function addBristle(x, y, vx, vy, kind)
    bristleParticles[#bristleParticles + 1] = {
        x = x, y = y,
        vx = -(vx or 0) * 0.18 + (hash01(elapsed * 50 + x) - 0.5) * 5,
        vy = -(vy or 0) * 0.18 + (hash01(elapsed * 70 + y) - 0.5) * 5,
        life = 28 + hash01(x * 0.03 + y) * 18,
        maxLife = 46,
        kind = kind,
    }
end

-- ============================================================================
-- END scripts/src/20_fluid_trail_particles.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/29_ldtk_plum_mirror_data.lua
-- ============================================================================
-- AUTO-GENERATED FILE. Do not edit directly.
-- Generated by tools/convert_ldtk_plum_mirror_to_lua.ps1 from ldtk/ink_plum_mirror.ldtk.

LDTK_PLUM_MIRROR = {
    source = "ldtk/ink_plum_mirror.ldtk",
    identifier = "UrhoX_Level_12_Plum_Mirror",
    width = 4480,
    height = 1584,
    materials = {
        paper = { 246, 237, 225 },
        paper2 = { 220, 207, 190 },
        ink = { 42, 30, 24 },
        wash = { 114, 82, 69 },
        accent = { 142, 35, 42 },
        bloom = { 195, 18, 18 },
        water = { 204, 165, 68 },
    },
    physics = { radius = 11, gravity = 0.46, jumpForce = -16.5, dashSpeed = 21, friction = 0.84 },
    start = { x = 639, y = 922, facing = "right", },
    branches = {
        { id = "main_trunk", x1 = 224, y1 = 950.4, x2 = 1881.6, y2 = 1045.44, startR = 46, endR = 32, curveX = 80, curveY = 50, pointsNum = 60, jitter = 0.1 },
        { id = "hanging_branch", x1 = 1881.6, y1 = 1045.44, x2 = 2777.6, y2 = 1172.16, startR = 32, endR = 20, curveX = 60, curveY = 30, pointsNum = 50, jitter = 0.1 },
        { id = "right_crescent", x1 = 1881.6, y1 = 1045.44, x2 = 3225.6, y2 = 792, startR = 30, endR = 16, curveX = 100, curveY = -80, pointsNum = 60, jitter = 0.1 },
        { id = "upright_young_shoot", x1 = 1568, y1 = 950.4, x2 = 2508.8, y2 = 380.16, startR = 18, endR = 8, curveX = 30, curveY = -100, pointsNum = 70, jitter = 0.1 },
        { id = "poetry_col_1", x1 = 3673.6, y1 = 443.52, x2 = 3673.6, y2 = 982.08, startR = 4, endR = 4, curveX = 0, curveY = 0, pointsNum = 20, jitter = 0 },
        { id = "poetry_col_2", x1 = 3852.8, y1 = 443.52, x2 = 3852.8, y2 = 982.08, startR = 4, endR = 4, curveX = 0, curveY = 0, pointsNum = 20, jitter = 0 },
        { id = "poetry_col_3", x1 = 4032, y1 = 443.52, x2 = 4032, y2 = 982.08, startR = 4, endR = 4, curveX = 0, curveY = 0, pointsNum = 20, jitter = 0 },
        { id = "poetry_col_4", x1 = 4211.2, y1 = 443.52, x2 = 4211.2, y2 = 982.08, startR = 4, endR = 4, curveX = 0, curveY = 0, pointsNum = 20, jitter = 0 },
    },
    targets = {
        { branchId = "main_trunk", progress = 0.5, radius = 38 },
        { branchId = "hanging_branch", progress = 0.4, radius = 38 },
        { branchId = "hanging_branch", progress = 0.9, radius = 38 },
        { branchId = "upright_young_shoot", progress = 0.4, radius = 38 },
        { branchId = "upright_young_shoot", progress = 0.9, radius = 38 },
        { branchId = "right_crescent", progress = 0.35, radius = 38 },
        { branchId = "right_crescent", progress = 0.8, radius = 38 },
        { branchId = "poetry_col_1", progress = 0.6, radius = 38 },
    },
}

-- ============================================================================
-- END scripts/src/29_ldtk_plum_mirror_data.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/30_level_generation.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.

local function resetBranchMetadata()
    branchMetadata = {
        main = { parentBranchId = nil, parentT = 0, bend = 0, targetBend = 0, springVel = 0, mass = 120, k = 0.24, damping = 0.82, maxBend = 85, deflectionCoeff = 0.0018, bounceFactor = 0.018, springBackForce = 1.7 },
        main2 = { parentBranchId = "main", parentT = 0.69, bend = 0, targetBend = 0, springVel = 0, mass = 78, k = 0.28, damping = 0.79, maxBend = 105, deflectionCoeff = 0.0035, bounceFactor = 0.045, springBackForce = 2.4 },
        side1 = { parentBranchId = "main", parentT = 0.72, bend = 0, targetBend = 0, springVel = 0, mass = 70, k = 0.31, damping = 0.77, maxBend = 120, deflectionCoeff = 0.0042, bounceFactor = 0.075, springBackForce = 3.0 },
        vertical = { parentBranchId = "main2", parentT = 1.0, bend = 0, targetBend = 0, springVel = 0, mass = 48, k = 0.34, damping = 0.73, maxBend = 150, deflectionCoeff = 0.007, bounceFactor = 0.145, springBackForce = 4.1 },
        bridge = { parentBranchId = "main2", parentT = 1.0, bend = 0, targetBend = 0, springVel = 0, mass = 58, k = 0.31, damping = 0.76, maxBend = 135, deflectionCoeff = 0.0048, bounceFactor = 0.105, springBackForce = 3.4 },
        high1 = { parentBranchId = "vertical", parentT = 1.0, bend = 0, targetBend = 0, springVel = 0, mass = 34, k = 0.38, damping = 0.70, maxBend = 170, deflectionCoeff = 0.010, bounceFactor = 0.20, springBackForce = 4.8 },
        peak = { parentBranchId = "bridge", parentT = 0.85, bend = 0, targetBend = 0, springVel = 0, mass = 30, k = 0.40, damping = 0.68, maxBend = 185, deflectionCoeff = 0.012, bounceFactor = 0.26, springBackForce = 5.3 },
    }
end

local mapleBranchOrder = { "main", "main2", "side1", "vertical", "bridge", "high1", "peak" }
local mapleReverseBranchOrder = { "peak", "high1", "bridge", "vertical", "side1", "main2", "main" }

function refreshBranchNormalsForCurrentPose(list)
    if not list or #list < 2 then return end
    for i = 1, #list do
        local a = list[math.max(1, i - 1)]
        local b = list[math.min(#list, i + 1)]
        if i == 1 then a, b = list[1], list[2] end
        if i == #list then a, b = list[#list - 1], list[#list] end
        local dx, dy = b.x - a.x, b.y - a.y
        local len = dist2(dx, dy)
        if len < 0.001 then len = 1 end
        local nx, ny = -dy / len, dx / len
        if ny > 0 then nx, ny = -nx, -ny end
        list[i].normX, list[i].normY = nx, ny
    end
end

function bindItemToBranch(item)
    if not item or not item.branchId or not item.nodeIndex then return end
    local nodes = branchGroups[item.branchId]
    local n = nodes and nodes[item.nodeIndex]
    if not n then return end
    local off = item.attachOffset or (n.r + 32)
    item.x = n.x + n.normX * off
    item.y = n.y + n.normY * off
    item.attachX, item.attachY = n.x, n.y
    item.normX, item.normY = n.normX, n.normY
end

function branchFacingAngle(item)
    local nx = (item and item.normX) or 0
    local ny = (item and item.normY) or -1
    return math.atan2(ny, nx) + math.pi * 0.5 + ((item and item.orientationJitter) or 0)
end

local function applyStaticBranchBend()
    if currentLevel.id ~= "maple" then return end

    for _, bid in ipairs(mapleReverseBranchOrder) do
        local meta = branchMetadata[bid]
        if meta and meta.parentBranchId and branchMetadata[meta.parentBranchId] then
            local parent = branchMetadata[meta.parentBranchId]
            parent.targetBend = math.min(parent.maxBend, parent.targetBend + meta.targetBend * 0.22)
        end
    end

    for _, bid in ipairs(mapleBranchOrder) do
        local meta = branchMetadata[bid]
        if branchGroups[bid] then
            local force = -meta.k * (meta.bend - meta.targetBend)
            local acc = force / meta.mass
            meta.springVel = (meta.springVel + acc) * meta.damping
            meta.bend = meta.bend + meta.springVel
            meta.targetBend = meta.targetBend * 0.90
        end
    end

    for _, bid in ipairs(mapleBranchOrder) do
        local meta = branchMetadata[bid]
        local nodes = branchGroups[bid]
        if meta and nodes and #nodes > 0 then
            local root = nodes[1]
            local inheritX, inheritY = 0, 0
            if meta.parentBranchId then
                local parentNodes = branchGroups[meta.parentBranchId]
                if parentNodes and #parentNodes > 0 then
                    local idx = clamp(math.floor(#parentNodes * meta.parentT), 1, #parentNodes)
                    local parentNode = parentNodes[idx]
                    inheritX = parentNode.x - root.baseX
                    inheritY = parentNode.y - root.baseY
                end
            end
            for _, n in ipairs(branchGroups[bid]) do
                local drop = meta.bend * n.t * n.t * 0.92
                n.x = n.baseX + inheritX
                n.y = n.baseY + inheritY + drop
            end
        end
    end

    for _, bid in ipairs(mapleBranchOrder) do
        refreshBranchNormalsForCurrentPose(branchGroups[bid])
    end

    for _, t in ipairs(targets) do
        bindItemToBranch(t)
    end
    for _, b in ipairs(blooms) do
        bindItemToBranch(b)
    end
end

local function generateBamboo()
    local function createBambooStalk(startX, startY, angle, length, radius, segmentsCount, stalkId)
        local currentX, currentY = startX, startY
        local segLen = length / segmentsCount
        for i = 0, segmentsCount - 1 do
            local bendDir = angle > -math.pi / 2 and 1 or -1
            local curAngle = angle + (i * 0.015 * bendDir)
            local nextX = currentX + math.cos(curAngle) * segLen
            local nextY = currentY + math.sin(curAngle) * segLen
            local currentR = radius * (1 - (i / segmentsCount) * 0.5)
            bambooSegments[#bambooSegments + 1] = {
                x1 = currentX, y1 = currentY,
                x2 = nextX, y2 = nextY,
                r = currentR, stalkId = stalkId,
                isNode = true, nodeX = nextX, nodeY = nextY,
                angle = curAngle,
            }
            currentX, currentY = nextX, nextY
        end
    end

    createBambooStalk(W(0.15), H(1.1), -math.pi * 0.48, H(0.8), 18, 12, "bamboo1")
    createBambooStalk(W(0.35), H(0.9), -math.pi * 0.35, H(0.7), 14, 10, "bamboo2")
    -- bamboo3/4 基部下移：原 H(0.25)/H(0.3) 时顶部目标位于世界顶以上(y<0)，
    -- 相机上界钳在 0，玩家永远看不到；下移后所有竹节目标均在镜头内
    createBambooStalk(W(0.72), H(0.50), -math.pi * 0.55, H(0.5), 12, 8, "bamboo3")
    createBambooStalk(W(0.78), H(0.55), -math.pi * 0.4, H(0.4), 8, 6, "bamboo4")

    local placements = {
        { id = "bamboo1", nodes = { 4, 8, 11 } },
        { id = "bamboo2", nodes = { 5, 9 } },
        { id = "bamboo3", nodes = { 3, 7 } },
        { id = "bamboo4", nodes = { 4 } },
    }
    for _, p in ipairs(placements) do
        local segs = {}
        for _, s in ipairs(bambooSegments) do if s.stalkId == p.id then segs[#segs + 1] = s end end
        for _, idx0 in ipairs(p.nodes) do
            local s = segs[idx0 + 1]
            if s then addTarget(s.nodeX, s.nodeY, s.r + 18, s.x1, s.y1, 0, -1) end
        end
    end
end

local function generatePine()
    createBranch(W(0.10), H(0.75), W(0.35), H(0.65), 38, 25, 80, -60, 100, "pine1", 0.15)
    createBranch(W(0.35), H(0.65), W(0.22), H(0.48), 25, 15, -80, -80, 80, "pine_return", 0.15)
    createBranch(W(0.35), H(0.65), W(0.65), H(0.58), 25, 18, 100, 80, 120, "pine2", 0.15)
    createBranch(W(0.65), H(0.58), W(0.50), H(0.32), 18, 10, -90, -100, 110, "pine_bridge", 0.15)
    createBranch(W(0.65), H(0.58), W(0.92), H(0.40), 18, 8, 120, -80, 120, "pine_peak", 0.15)
    streams[#streams + 1] = { x1 = W(0.30), y1 = H(0.20), x2 = W(0.50), y2 = H(0.80), width = 85 }
    for _, p in ipairs({
        { "pine1", 0.28 }, { "pine1", 0.45 }, { "pine1", 0.62 },
        { "pine_return", 0.35 }, { "pine_return", 0.70 },
        { "pine2", 0.22 }, { "pine2", 0.40 }, { "pine2", 0.58 }, { "pine2", 0.78 },
        { "pine_bridge", 0.32 }, { "pine_bridge", 0.66 },
        { "pine_peak", 0.25 }, { "pine_peak", 0.52 }, { "pine_peak", 0.85 },
    }) do addTargetOnBranch(p[1], p[2], 42) end
end

local function addMapleTarget(branchId, progress)
    local nodes = branchGroups[branchId]
    if not nodes then return end
    local idx = clamp(math.floor(#nodes * progress), 1, #nodes)
    local n = nodes[idx]
    local off = n.r + 32
    targets[#targets + 1] = {
        x = n.x + n.normX * off, y = n.y + n.normY * off, r = 36,
        attachX = n.x, attachY = n.y, normX = n.normX, normY = n.normY,
        dead = false, pulse = hash01(#targets + 17) * 6.28318,
        branchId = branchId, nodeIndex = idx, attachOffset = off,
        orientationJitter = (hash01(n.x * 0.017 + n.y * 0.013) - 0.5) * 0.38,
    }
end

local function generateMaple()
    resetBranchMetadata()
    createBranch(W(0.05), H(0.82), W(0.22), H(0.70), 45, 30, 50, -100, 150, "main", 0.12)
    createBranch(W(0.20), H(0.72), W(0.44), H(0.76), 26, 16, 100, 110, 110, "side1", 0.12)
    createBranch(W(0.21), H(0.69), W(0.4), H(0.48), 28, 20, -120, -100, 180, "main2", 0.12)
    createBranch(W(0.4), H(0.48), W(0.42), H(0.22), 20, 10, -150, -50, 150, "vertical", 0.12)
    createBranch(W(0.42), H(0.22), W(0.62), H(0.28), 12, 6, 100, -100, 120, "high1", 0.12)
    createBranch(W(0.42), H(0.48), W(0.72), H(0.5), 18, 12, 150, 150, 180, "bridge", 0.12)
    createBranch(W(0.68), H(0.51), W(0.96), H(0.18), 12, 4, 200, -180, 220, "peak", 0.12)
    for _, p in ipairs({
        { "main", 0.45 }, { "side1", 0.65 }, { "main2", 0.6 }, { "high1", 0.25 },
        { "high1", 0.75 }, { "bridge", 0.3 }, { "bridge", 0.75 },
        { "peak", 0.45 }, { "peak", 0.88 },
    }) do addMapleTarget(p[1], p[2]) end
    for i = 1, 18 do
        glidingLeaves[#glidingLeaves + 1] = {
            x = hash01(i * 15) * worldW,
            y = hash01(i * 25) * worldH * 0.5,
            size = 20 + hash01(i * 35) * 18,
            speed = 1.2 + hash01(i * 45) * 1.8,
            bob = hash01(i * 55) * 6.28,
        }
    end
    for i = 1, 9 do
        local row = (i - 1) % 3
        local col = math.floor((i - 1) / 3)
        glidingLeaves[#glidingLeaves + 1] = {
            x = W(0.34 + row * 0.13 + hash01(300 + i * 7) * 0.045),
            y = H(0.64 + col * 0.10 + hash01(330 + i * 11) * 0.030),
            size = 25 + hash01(360 + i * 13) * 8,
            speed = 0.36 + hash01(390 + i * 17) * 0.28,
            bob = hash01(420 + i * 19) * 6.28,
            platform = true,
        }
    end
end

local function generatePlum()
    createBranch(W(0.95), H(0.58), W(0.55), H(0.68), 42, 28, -100, 70, 120, "main_trunk", 0.12)
    createBranch(W(0.55), H(0.68), W(0.35), H(0.78), 28, 16, -80, 50, 100, "hanging_branch", 0.12)
    createBranch(W(0.55), H(0.68), W(0.25), H(0.52), 26, 12, -120, -100, 120, "left_crescent", 0.12)
    createBranch(W(0.62), H(0.62), W(0.42), H(0.22), 14, 6, -40, -120, 140, "upright_young_shoot", 0.12)
    createBranch(W(0.18), H(0.28), W(0.18), H(0.62), 4, 4, 0, 0, 40, "poetry_col_1", 0)
    createBranch(W(0.14), H(0.28), W(0.14), H(0.62), 4, 4, 0, 0, 40, "poetry_col_2", 0)
    createBranch(W(0.10), H(0.28), W(0.10), H(0.62), 4, 4, 0, 0, 40, "poetry_col_3", 0)
    createBranch(W(0.06), H(0.28), W(0.06), H(0.62), 4, 4, 0, 0, 40, "poetry_col_4", 0)
    for _, p in ipairs({
        { "main_trunk", 0.5 }, { "hanging_branch", 0.4 }, { "hanging_branch", 0.9 },
        { "upright_young_shoot", 0.45 }, { "upright_young_shoot", 0.95 },
        { "left_crescent", 0.4 }, { "left_crescent", 0.85 }, { "poetry_col_1", 0.6 },
    }) do addTargetOnBranch(p[1], p[2], 36) end
end

function generatePlumMirror()
    if LDTK_PLUM_MIRROR then
        for _, b in ipairs(LDTK_PLUM_MIRROR.branches or {}) do
            createBranch(b.x1, b.y1, b.x2, b.y2, b.startR, b.endR, b.curveX, b.curveY, b.pointsNum, b.id, b.jitter)
        end
        for _, t in ipairs(LDTK_PLUM_MIRROR.targets or {}) do
            addTargetOnBranch(t.branchId, t.progress, t.radius)
        end
        return
    end

    -- 第12关：蟠梅长卷的镜像版，从左往右行动
    -- 性能优化：减少 pointsNum（节点数减半），大幅降低每帧绘制量
    -- 原 plum 用 120/100/120/140 节点，这里减半以保持流畅
    createBranch(W(0.05), H(0.60), W(0.42), H(0.66), 46, 32, 80, 50, 60, "main_trunk", 0.10)
    createBranch(W(0.42), H(0.66), W(0.62), H(0.74), 32, 20, 60, 30, 50, "hanging_branch", 0.10)
    createBranch(W(0.42), H(0.66), W(0.72), H(0.50), 30, 16, 100, -80, 60, "right_crescent", 0.10)
    createBranch(W(0.35), H(0.60), W(0.56), H(0.24), 18, 8, 30, -100, 70, "upright_young_shoot", 0.10)
    createBranch(W(0.82), H(0.28), W(0.82), H(0.62), 4, 4, 0, 0, 20, "poetry_col_1", 0)
    createBranch(W(0.86), H(0.28), W(0.86), H(0.62), 4, 4, 0, 0, 20, "poetry_col_2", 0)
    createBranch(W(0.90), H(0.28), W(0.90), H(0.62), 4, 4, 0, 0, 20, "poetry_col_3", 0)
    createBranch(W(0.94), H(0.28), W(0.94), H(0.62), 4, 4, 0, 0, 20, "poetry_col_4", 0)
    for _, p in ipairs({
        { "main_trunk", 0.5 }, { "hanging_branch", 0.4 }, { "hanging_branch", 0.9 },
        { "upright_young_shoot", 0.4 }, { "upright_young_shoot", 0.9 },
        { "right_crescent", 0.35 }, { "right_crescent", 0.8 }, { "poetry_col_1", 0.6 },
    }) do addTargetOnBranch(p[1], p[2], 38) end
end

function generatePlumFinale()
    -- 第13关：母本复刻 - 王冕《梅竹双清卷》梅段（台北故宫，22.4x81.4cm 中画芯约 25.6x22.4cm）
    -- 坐标自 assets/reference/wang_mian_twin_purities_plum.jpg (1045x900) 网格描取，
    -- 所有枝干走向与母本一致：
    --   主枝自左缘横出，斜度逐渐加大，化作"长鞭梢"一笔拖至右下角收笔；
    --   上层弧枝与主枝同根，先扬后抑，繁花尽缀此枝（圈花白描）；
    --   交搭小枝自主枝中段挑向右上，与上弧枝成女字穿插；
    --   左下垂梢带花穗回锋；两条垂花小枝自上弧枝下挂；
    --   两条短仰枝挑出顶缘；右壁题诗满纸（化作三柱可攀字柱）。

    -- 主枝（粗入细出，长鞭拖尾）
    createBranchPath({
        { 0.000, 0.150, 24 }, { 0.060, 0.163, 23 }, { 0.130, 0.190, 21 },
        { 0.200, 0.232, 19 }, { 0.270, 0.272, 18 }, { 0.340, 0.314, 16 },
        { 0.405, 0.352, 14 }, { 0.465, 0.412, 12 }, { 0.525, 0.480, 10 },
        { 0.585, 0.555, 8 },  { 0.645, 0.652, 7 },  { 0.710, 0.748, 6 },
        { 0.780, 0.840, 5 },  { 0.850, 0.905, 4 },  { 0.920, 0.952, 3 },
        { 0.978, 0.974, 2.5 },
    }, "finale_trunk", 0.10)

    -- 上层弧枝（满花主枝，先扬后抑，末端发丝细、微微回挑）
    createBranchPath({
        { 0.012, 0.132, 12 }, { 0.060, 0.104, 11 }, { 0.120, 0.082, 10 },
        { 0.190, 0.071, 9 },  { 0.258, 0.082, 8 },  { 0.320, 0.104, 7 },
        { 0.380, 0.134, 5.5 }, { 0.440, 0.158, 4 }, { 0.498, 0.171, 3 },
        { 0.545, 0.163, 2.5 },
    }, "finale_upper", 0.10)

    -- 交搭小枝（自主枝挑向右上，与上弧枝成女字穿插）
    createBranchPath({
        { 0.300, 0.290, 5 }, { 0.345, 0.257, 4 }, { 0.385, 0.234, 3 }, { 0.418, 0.221, 2.5 },
    }, "finale_cross", 0.12)

    -- 中部细长挑枝及其下叉（自主枝沿势向右）
    createBranchPath({
        { 0.400, 0.345, 5 }, { 0.450, 0.352, 4 }, { 0.495, 0.366, 3 },
        { 0.540, 0.381, 2.5 }, { 0.578, 0.394, 2.5 },
    }, "finale_spray", 0.12)
    createBranchPath({
        { 0.432, 0.387, 4 }, { 0.470, 0.407, 3 }, { 0.506, 0.424, 2.5 },
    }, "finale_spray_fork", 0.12)

    -- 左下垂梢（带花穗，回锋收笔）
    createBranchPath({
        { 0.130, 0.205, 7 }, { 0.110, 0.264, 6 }, { 0.094, 0.330, 5 },
        { 0.085, 0.394, 4 }, { 0.082, 0.452, 3 }, { 0.091, 0.503, 2.5 },
    }, "finale_droop", 0.12)
    createBranchPath({
        { 0.075, 0.172, 5 }, { 0.048, 0.200, 4 }, { 0.026, 0.218, 3 },
    }, "finale_droop2", 0.12)

    -- 顶部短仰枝两条
    createBranchPath({
        { 0.128, 0.086, 4 }, { 0.140, 0.048, 3 }, { 0.149, 0.022, 2.5 },
    }, "finale_spur1", 0.12)
    createBranchPath({
        { 0.262, 0.078, 4 }, { 0.276, 0.040, 3 }, { 0.286, 0.017, 2.5 },
    }, "finale_spur2", 0.12)

    -- 上弧枝下挂的垂花小枝两条
    createBranchPath({
        { 0.330, 0.096, 3 }, { 0.318, 0.140, 2.5 }, { 0.309, 0.176, 2.5 },
    }, "finale_hang1", 0.12)
    createBranchPath({
        { 0.405, 0.140, 3 }, { 0.420, 0.184, 2.5 }, { 0.433, 0.219, 2.5 },
    }, "finale_hang2", 0.12)

    -- 尾段最后花枝（主枝中后段，末花所在）
    createBranchPath({
        { 0.473, 0.424, 4 }, { 0.508, 0.453, 3 }, { 0.544, 0.488, 2.5 }, { 0.572, 0.518, 2.5 },
    }, "finale_tail_twig", 0.12)

    -- 右壁题诗（母本右缘满纸行书，化作三柱可攀字柱）
    createBranchPath({ { 0.806, 0.100, 4 }, { 0.806, 0.780, 4 } }, "poetry_col_1", 0)
    createBranchPath({ { 0.866, 0.080, 4 }, { 0.866, 0.780, 4 } }, "poetry_col_2", 0)
    createBranchPath({ { 0.926, 0.100, 4 }, { 0.926, 0.780, 4 } }, "poetry_col_3", 0)

    for _, p in ipairs({
        { "finale_spur1", 0.75 }, { "finale_spur2", 0.75 },
        { "finale_upper", 0.10 }, { "finale_upper", 0.55 }, { "finale_upper", 0.93 },
        { "finale_cross", 0.70 }, { "finale_droop", 0.85 },
        { "finale_trunk", 0.40 },
        { "finale_spray", 0.72 }, { "finale_tail_twig", 0.80 },
        { "poetry_col_2", 0.55 },
    }) do addTargetOnBranch(p[1], p[2], 34) end
end

function generateWentongZhu()
    -- 第14关:母本复刻 - 文同《墨竹图》(台北故宫,绢本 1830x2880) 大画布精刻
    -- S 形主竿自左上倒垂入谷再扬至右缘;每节双向生枝,枝梢缀叶(叶扇为渲染层)。
    createBranchPath({
        { 0.050, 0.205, 24 }, { 0.115, 0.262, 23 }, { 0.180, 0.325, 21 },
        { 0.245, 0.395, 20 }, { 0.305, 0.465, 18 }, { 0.355, 0.535, 17 },
        { 0.395, 0.600, 15 }, { 0.425, 0.650, 14 }, { 0.475, 0.668, 13 },
        { 0.535, 0.668, 12 }, { 0.600, 0.655, 12 }, { 0.665, 0.632, 11 },
        { 0.730, 0.607, 10 }, { 0.795, 0.588, 9 },  { 0.860, 0.580, 8 },
        { 0.920, 0.592, 7 },  { 0.960, 0.615, 6 },
    }, "wt_cane", 0.10)
    createBranchPath({ { 0.180, 0.325, 7 }, { 0.125, 0.375, 5 }, { 0.080, 0.415, 4 } }, "wt_zhi1", 0.12)
    createBranchPath({ { 0.115, 0.262, 6 }, { 0.075, 0.300, 4 }, { 0.045, 0.330, 3 } }, "wt_zhi1b", 0.12)
    createBranchPath({ { 0.305, 0.465, 7 }, { 0.245, 0.530, 6 }, { 0.195, 0.585, 5 }, { 0.165, 0.625, 4 } }, "wt_zhi2", 0.12)
    createBranchPath({ { 0.245, 0.395, 6 }, { 0.205, 0.450, 4 }, { 0.175, 0.495, 3 } }, "wt_zhi2b", 0.12)
    createBranchPath({ { 0.425, 0.650, 7 }, { 0.380, 0.710, 5 }, { 0.345, 0.760, 4 } }, "wt_zhi3", 0.12)
    createBranchPath({ { 0.395, 0.600, 5 }, { 0.355, 0.655, 4 }, { 0.325, 0.700, 3 } }, "wt_zhi3b", 0.12)
    createBranchPath({ { 0.535, 0.668, 6 }, { 0.560, 0.730, 5 }, { 0.575, 0.775, 4 } }, "wt_zhi4", 0.12)
    createBranchPath({ { 0.475, 0.668, 5 }, { 0.448, 0.730, 4 }, { 0.430, 0.778, 3 } }, "wt_zhi4b", 0.12)
    createBranchPath({ { 0.665, 0.632, 7 }, { 0.715, 0.560, 6 }, { 0.760, 0.505, 5 }, { 0.790, 0.468, 4 } }, "wt_zhi5", 0.12)
    createBranchPath({ { 0.665, 0.632, 5 }, { 0.690, 0.690, 4 }, { 0.710, 0.738, 3 } }, "wt_zhi5b", 0.12)
    createBranchPath({ { 0.795, 0.588, 6 }, { 0.845, 0.650, 5 }, { 0.880, 0.700, 4 } }, "wt_zhi6", 0.12)
    createBranchPath({ { 0.730, 0.607, 5 }, { 0.762, 0.665, 4 }, { 0.785, 0.710, 3 } }, "wt_zhi6b", 0.12)
    createBranchPath({ { 0.920, 0.592, 6 }, { 0.950, 0.535, 5 }, { 0.968, 0.495, 4 } }, "wt_zhi7", 0.12)
    createBranchPath({ { 0.860, 0.580, 5 }, { 0.900, 0.640, 4 }, { 0.928, 0.688, 3 } }, "wt_zhi8", 0.12)
    for _, p in ipairs({
        { "wt_zhi1", 0.8 }, { "wt_zhi1b", 0.8 },
        { "wt_zhi2", 0.55 }, { "wt_zhi2", 0.92 }, { "wt_zhi2b", 0.8 },
        { "wt_zhi3", 0.8 }, { "wt_zhi3b", 0.85 },
        { "wt_zhi4", 0.85 }, { "wt_zhi4b", 0.85 },
        { "wt_zhi5", 0.6 }, { "wt_zhi5", 0.95 }, { "wt_zhi5b", 0.85 },
        { "wt_zhi6", 0.85 }, { "wt_zhi6b", 0.85 },
        { "wt_zhi7", 0.8 }, { "wt_zhi8", 0.85 }, { "wt_cane", 0.50 },
    }) do addTargetOnBranch(p[1], p[2], 36) end
end

function generatePlumXiyan()
    -- 第15关:母本复刻 - 王冕《墨梅图》卷(北京故宫) 大画布精刻
    -- 主干右出渐细成长梢、左端回锋;双枝上扬各带分梢;沿干小花枝;题诗四柱。
    createBranchPath({
        { 1.000, 0.500, 44 }, { 0.940, 0.472, 41 }, { 0.880, 0.450, 38 },
        { 0.820, 0.435, 35 }, { 0.760, 0.420, 32 }, { 0.700, 0.412, 29 },
        { 0.640, 0.416, 25 }, { 0.580, 0.428, 20 }, { 0.520, 0.448, 16 },
        { 0.460, 0.466, 13 }, { 0.400, 0.492, 10 }, { 0.340, 0.512, 9 },
        { 0.280, 0.528, 7 },  { 0.220, 0.545, 6 },  { 0.170, 0.552, 6 },
    }, "xy_trunk", 0.10)
    createBranchPath({ { 0.170, 0.552, 6 }, { 0.135, 0.512, 5 }, { 0.108, 0.462, 4 }, { 0.092, 0.418, 3.5 } }, "xy_hook", 0.12)
    createBranchPath({
        { 0.790, 0.408, 15 }, { 0.745, 0.330, 13 }, { 0.705, 0.258, 11 },
        { 0.668, 0.196, 9 },  { 0.628, 0.146, 7 },  { 0.585, 0.112, 6 },
        { 0.540, 0.098, 4 },  { 0.495, 0.105, 3.5 },
    }, "xy_up_a", 0.10)
    createBranchPath({ { 0.705, 0.258, 7 }, { 0.665, 0.232, 5 }, { 0.625, 0.218, 4 }, { 0.588, 0.214, 3 } }, "xy_up_a2", 0.12)
    createBranchPath({ { 0.745, 0.330, 7 }, { 0.778, 0.276, 5 }, { 0.800, 0.235, 4 }, { 0.818, 0.202, 3 } }, "xy_up_a3", 0.12)
    createBranchPath({
        { 0.872, 0.428, 13 }, { 0.888, 0.345, 11 }, { 0.902, 0.270, 9 },
        { 0.918, 0.205, 7 },  { 0.936, 0.152, 5 },  { 0.952, 0.118, 4 },
    }, "xy_up_b", 0.10)
    createBranchPath({ { 0.902, 0.270, 6 }, { 0.872, 0.225, 4 }, { 0.845, 0.192, 3.5 } }, "xy_up_b2", 0.12)
    createBranchPath({ { 0.560, 0.432, 9 }, { 0.532, 0.498, 7 }, { 0.512, 0.556, 6 }, { 0.500, 0.600, 4 } }, "xy_down_mid", 0.12)
    createBranchPath({
        { 0.430, 0.478, 9 }, { 0.370, 0.530, 7 }, { 0.305, 0.568, 6 },
        { 0.245, 0.588, 4 }, { 0.190, 0.595, 3.5 },
    }, "xy_down_left", 0.12)
    createBranchPath({ { 0.940, 0.474, 10 }, { 0.918, 0.530, 7 }, { 0.900, 0.578, 6 }, { 0.888, 0.615, 4 } }, "xy_right_drop", 0.12)
    createBranchPath({ { 0.700, 0.412, 8 }, { 0.682, 0.352, 6 }, { 0.668, 0.300, 4 } }, "xy_twig1", 0.12)
    createBranchPath({ { 0.640, 0.416, 7 }, { 0.615, 0.360, 5 }, { 0.595, 0.315, 4 } }, "xy_twig2", 0.12)
    createBranchPath({ { 0.400, 0.492, 6 }, { 0.378, 0.442, 4 }, { 0.362, 0.402, 3.5 } }, "xy_mid_twig", 0.12)
    createBranchPath({ { 0.280, 0.528, 6 }, { 0.258, 0.482, 4 }, { 0.242, 0.448, 3.5 } }, "xy_left_twig", 0.12)
    createBranchPath({ { 0.315, 0.060, 6 }, { 0.315, 0.420, 6 } }, "poetry_col_1", 0)
    createBranchPath({ { 0.355, 0.060, 6 }, { 0.355, 0.420, 6 } }, "poetry_col_2", 0)
    createBranchPath({ { 0.395, 0.060, 6 }, { 0.395, 0.420, 6 } }, "poetry_col_3", 0)
    createBranchPath({ { 0.435, 0.050, 6 }, { 0.435, 0.300, 6 } }, "poetry_col_4", 0)
    for _, p in ipairs({
        { "xy_up_a", 0.45 }, { "xy_up_a", 0.80 }, { "xy_up_a2", 0.8 }, { "xy_up_a3", 0.8 },
        { "xy_up_b", 0.55 }, { "xy_up_b", 0.90 }, { "xy_up_b2", 0.8 },
        { "xy_trunk", 0.30 }, { "xy_twig1", 0.8 }, { "xy_twig2", 0.8 },
        { "xy_down_mid", 0.80 }, { "xy_down_left", 0.55 }, { "xy_down_left", 0.92 },
        { "xy_mid_twig", 0.8 }, { "xy_left_twig", 0.8 },
        { "xy_hook", 0.80 }, { "xy_right_drop", 0.80 }, { "poetry_col_2", 0.50 },
    }) do addTargetOnBranch(p[1], p[2], 38) end
end

function generateXuweiGrape()
    -- 第16关:母本复刻 - 徐渭《墨葡萄图》(北京故宫) 大画布精刻
    -- 狂草主藤右上横垂;左右垂蔓各带分梢;缠绕圈藤;飘垂细蔓;葡萄串/泼墨叶为渲染层。
    createBranchPath({
        { 0.960, 0.285, 19 }, { 0.880, 0.330, 18 }, { 0.800, 0.368, 16 },
        { 0.720, 0.400, 14 }, { 0.640, 0.428, 13 }, { 0.560, 0.452, 13 },
        { 0.480, 0.478, 11 }, { 0.400, 0.500, 10 }, { 0.320, 0.522, 10 },
        { 0.240, 0.540, 8 },  { 0.160, 0.552, 8 },  { 0.090, 0.558, 6 },
    }, "xw_vine", 0.12)
    createBranchPath({
        { 0.160, 0.552, 8 }, { 0.135, 0.620, 6 }, { 0.118, 0.690, 6 },
        { 0.108, 0.760, 5 }, { 0.105, 0.825, 5 }, { 0.112, 0.880, 4 },
    }, "xw_left_drop", 0.12)
    createBranchPath({
        { 0.800, 0.368, 10 }, { 0.825, 0.440, 8 }, { 0.845, 0.515, 6 },
        { 0.858, 0.590, 6 },  { 0.862, 0.660, 5 }, { 0.855, 0.730, 5 }, { 0.840, 0.795, 4 },
    }, "xw_right_drop", 0.12)
    createBranchPath({ { 0.845, 0.515, 6 }, { 0.890, 0.560, 5 }, { 0.920, 0.610, 5 }, { 0.938, 0.660, 4 } }, "xw_right_drop2", 0.12)
    createBranchPath({ { 0.460, 0.482, 5 }, { 0.452, 0.560, 4 }, { 0.448, 0.635, 4 }, { 0.450, 0.705, 4 } }, "xw_trail1", 0)
    createBranchPath({ { 0.560, 0.455, 5 }, { 0.572, 0.535, 4 }, { 0.580, 0.610, 4 }, { 0.585, 0.680, 4 } }, "xw_trail2", 0)
    createBranchPath({ { 0.660, 0.425, 5 }, { 0.672, 0.500, 4 }, { 0.680, 0.572, 4 }, { 0.685, 0.640, 4 } }, "xw_trail3", 0)
    createBranchPath({ { 0.640, 0.428, 8 }, { 0.565, 0.392, 6 }, { 0.495, 0.372, 5 }, { 0.435, 0.368, 4 } }, "xw_top_leaf", 0.12)
    -- 狂草缠绕圈藤(近闭环)
    createBranchPath({
        { 0.480, 0.478, 7 }, { 0.508, 0.516, 6 }, { 0.500, 0.560, 5 },
        { 0.462, 0.572, 5 }, { 0.432, 0.543, 5 }, { 0.446, 0.506, 5 }, { 0.474, 0.494, 5 },
    }, "xw_curl1", 0.10)
    createBranchPath({
        { 0.320, 0.522, 6 }, { 0.348, 0.556, 5 }, { 0.336, 0.596, 4 },
        { 0.300, 0.588, 4 }, { 0.292, 0.552, 4 },
    }, "xw_curl2", 0.10)
    for _, p in ipairs({
        { "xw_vine", 0.25 }, { "xw_vine", 0.55 }, { "xw_vine", 0.85 },
        { "xw_right_drop", 0.45 }, { "xw_right_drop", 0.85 }, { "xw_right_drop2", 0.85 },
        { "xw_left_drop", 0.50 }, { "xw_left_drop", 0.90 },
        { "xw_trail1", 0.85 }, { "xw_trail2", 0.85 }, { "xw_trail3", 0.85 },
        { "xw_top_leaf", 0.80 }, { "xw_curl1", 0.45 },
    }) do addTargetOnBranch(p[1], p[2], 40) end
end


local function generatePeach()
    waterLevel = H(0.86)
    createBranch(W(0.05), H(0.82), W(0.22), H(0.68), 42, 28, 50, -80, 120, "main_trunk", 0.12)
    createBranch(W(0.42), H(0.65), W(0.55), H(0.45), 28, 20, 50, -50, 120, "middle_main", 0.12)
    createBranch(W(0.55), H(0.45), W(0.92), H(0.38), 20, 12, 100, 30, 150, "middle_bridge", 0.12)
    for _, p in ipairs({
        { "main_trunk", 0.25 }, { "main_trunk", 0.40 }, { "main_trunk", 0.62 }, { "main_trunk", 0.85 },
        { "middle_main", 0.22 }, { "middle_main", 0.42 }, { "middle_main", 0.62 }, { "middle_main", 0.82 },
        { "middle_bridge", 0.18 }, { "middle_bridge", 0.35 }, { "middle_bridge", 0.52 },
        { "middle_bridge", 0.70 }, { "middle_bridge", 0.84 }, { "middle_bridge", 0.94 },
    }) do addTargetOnBranch(p[1], p[2], 50) end
    for _, r in ipairs({
        { W(0.25), H(0.12), H(0.48) }, { W(0.30), H(0.14), H(0.52) },
        { W(0.35), H(0.11), H(0.48) }, { W(0.40), H(0.13), H(0.46) },
    }) do
        willowRopes[#willowRopes + 1] = {
            anchorX = r[1], anchorY = r[2], length = r[3],
            angle = (hash01(r[1] * 0.01) - 0.5) * 0.15,
            angularVelocity = 0,
            oscTime = hash01(r[2] * 0.02) * math.pi,
        }
    end
    for i = 1, 32 do
        floatingPetals[#floatingPetals + 1] = {
            x = hash01(i * 12) * worldW,
            y = waterLevel + (hash01(i * 22) - 0.5) * 18,
            w = 82 + hash01(i * 28) * 34, h = 22 + hash01(i * 30) * 10,
            speed = 0.7 + hash01(i * 32) * 1.35,
            bob = hash01(i * 42) * math.pi,
        }
    end
end

local function addRoof(x1, y1, x2, y2, cp)
    local r = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, cp = cp, points = {} }
    for i = 0, 40 do
        local t = i / 40
        r.points[#r.points + 1] = { x = qbez(x1, cp.x, x2, t), y = qbez(y1, cp.y, y2, t), t = t }
    end
    roofs[#roofs + 1] = r
end

local function addPavilion(x, y, w, layers, layerH)
    pavilions[#pavilions + 1] = { x = x, y = y, w = w, layers = layers, layerH = layerH }
    for i = 0, layers - 1 do
        local ly = y + i * layerH
        for bx = x - 15, x + w + 15, 8 do
            addBranchNode({ x = bx, y = ly, r = 6, branchId = "pavilion_beam_" .. tostring(i), t = 0, normX = 0, normY = -1, baseX = bx, baseY = ly })
        end
    end
end

local function generatePlumMaster()
    createBranchPath({
        { 0.50, 0.045, 34 }, { 0.47, 0.115, 33 }, { 0.43, 0.205, 32 },
        { 0.42, 0.300, 31 }, { 0.38, 0.430, 30 }, { 0.36, 0.535, 28 },
        { 0.31, 0.650, 25 }, { 0.30, 0.755, 23 }, { 0.34, 0.930, 18 },
    }, "master_trunk", 0.18)
    createBranchPath({
        { 0.43, 0.180, 17 }, { 0.36, 0.185, 15 }, { 0.26, 0.205, 12 },
        { 0.17, 0.220, 8 }, { 0.08, 0.212, 4 },
    }, "master_upper_left", 0.20)
    createBranchPath({
        { 0.47, 0.135, 16 }, { 0.56, 0.145, 14 }, { 0.66, 0.165, 11 },
        { 0.76, 0.195, 7 }, { 0.93, 0.190, 4 },
    }, "master_upper_right", 0.18)
    createBranchPath({
        { 0.40, 0.345, 20 }, { 0.32, 0.360, 17 }, { 0.23, 0.385, 12 },
        { 0.14, 0.425, 7 }, { 0.05, 0.495, 3 },
    }, "master_mid_left", 0.18)
    createBranchPath({
        { 0.42, 0.405, 22 }, { 0.52, 0.430, 20 }, { 0.63, 0.475, 15 },
        { 0.74, 0.535, 10 }, { 0.89, 0.600, 5 },
    }, "master_mid_right", 0.18)
    createBranchPath({
        { 0.35, 0.535, 20 }, { 0.27, 0.585, 17 }, { 0.18, 0.645, 12 },
        { 0.09, 0.710, 7 }, { 0.03, 0.780, 3 },
    }, "master_lower_left", 0.18)
    createBranchPath({
        { 0.33, 0.615, 25 }, { 0.45, 0.650, 22 }, { 0.57, 0.685, 18 },
        { 0.70, 0.735, 12 }, { 0.83, 0.785, 7 }, { 0.97, 0.855, 3 },
    }, "master_lower_right_sweep", 0.18)
    createBranchPath({
        { 0.31, 0.755, 18 }, { 0.40, 0.805, 15 }, { 0.50, 0.860, 11 },
        { 0.63, 0.910, 7 }, { 0.80, 0.970, 3 },
    }, "master_bottom_spray", 0.18)

    createBranchPath({ { 0.18, 0.220, 5 }, { 0.12, 0.185, 3 }, { 0.06, 0.170, 2 } }, "master_twig_ul_1", 0.22)
    createBranchPath({ { 0.22, 0.238, 5 }, { 0.27, 0.272, 3 }, { 0.32, 0.325, 2 } }, "master_twig_ul_2", 0.22)
    createBranchPath({ { 0.56, 0.145, 5 }, { 0.63, 0.105, 3 }, { 0.69, 0.085, 2 } }, "master_twig_ur_1", 0.22)
    createBranchPath({ { 0.66, 0.170, 5 }, { 0.75, 0.135, 3 }, { 0.84, 0.120, 2 } }, "master_twig_ur_2", 0.22)
    createBranchPath({ { 0.76, 0.195, 4 }, { 0.86, 0.225, 3 }, { 0.96, 0.235, 2 } }, "master_twig_ur_3", 0.22)
    createBranchPath({ { 0.23, 0.385, 6 }, { 0.16, 0.475, 3 }, { 0.10, 0.535, 2 } }, "master_twig_ml_1", 0.22)
    createBranchPath({ { 0.31, 0.360, 5 }, { 0.24, 0.315, 3 }, { 0.18, 0.295, 2 } }, "master_twig_ml_2", 0.22)
    addMasterPlumFlowerTarget(0.21, 0.23, 0.18, 0.22, 25)
    addMasterPlumFlowerTarget(0.60, 0.15, 0.55, 0.14, 25)
    addMasterPlumFlowerTarget(0.76, 0.20, 0.72, 0.19, 25)
    addMasterPlumFlowerTarget(0.22, 0.42, 0.18, 0.41, 25)
    addMasterPlumFlowerTarget(0.70, 0.45, 0.66, 0.43, 25)
    addMasterPlumFlowerTarget(0.20, 0.62, 0.17, 0.60, 25)
    addMasterPlumFlowerTarget(0.42, 0.60, 0.38, 0.58, 25)
    addMasterPlumFlowerTarget(0.65, 0.64, 0.61, 0.62, 25)
    addMasterPlumFlowerTarget(0.38, 0.80, 0.34, 0.78, 25)
    addMasterPlumFlowerTarget(0.53, 0.88, 0.49, 0.86, 25)
end

local function generateEaves()
    addPavilion(W(0.05), H(0.55), 260, 3, 110)
    addRoof(W(0.05), H(0.55), W(0.01), H(0.48), { x = W(0.03), y = H(0.56) })
    addRoof(W(0.05) + 260, H(0.55), W(0.05) + 320, H(0.48), { x = W(0.05) + 290, y = H(0.56) })
    gears[#gears + 1] = { x = W(0.24), y = H(0.62), radius = 110, speed = 0.012, teethHeight = 18, angle = 0 }
    gears[#gears + 1] = { x = W(0.35), y = H(0.52), radius = 90, speed = -0.016, teethHeight = 16, angle = 0 }
    addPavilion(W(0.45), H(0.45), 340, 4, 120)
    addRoof(W(0.45) + 340, H(0.45), W(0.68), H(0.32), { x = W(0.58), y = H(0.52) })
    addRoof(W(0.45), H(0.45), W(0.39), H(0.35), { x = W(0.42), y = H(0.47) })
    chimes[#chimes + 1] = { x = W(0.39), y = H(0.39), pulse = 0, swayAngle = 0 }
    chimes[#chimes + 1] = { x = W(0.68), y = H(0.37), pulse = 0, swayAngle = 0 }
    chimes[#chimes + 1] = { x = W(0.01), y = H(0.52), pulse = 0, swayAngle = 0 }
    addPavilion(W(0.78), H(0.35), 220, 2, 130)
    addRoof(W(0.78), H(0.35), W(0.72), H(0.26), { x = W(0.75), y = H(0.37) })
    addRoof(W(0.78) + 220, H(0.35), W(0.92), H(0.22), { x = W(0.88), y = H(0.37) })
    chimes[#chimes + 1] = { x = W(0.72), y = H(0.31), pulse = 0, swayAngle = 0 }
    for _, p in ipairs({
        { W(0.12), H(0.42) }, { W(0.18), H(0.38) }, { W(0.24), H(0.46) },
        { W(0.30), H(0.41) }, { W(0.35), H(0.35) }, { W(0.48), H(0.36) },
        { W(0.56), H(0.32) }, { W(0.62), H(0.28) }, { W(0.70), H(0.22) },
        { W(0.78), H(0.24) }, { W(0.88), H(0.18) }, { W(0.94), H(0.16) },
    }) do addTarget(p[1], p[2], 46) end
end

local function generateHuangshan()
    createBranch(W(0.12), H(0.58), W(0.35), H(0.56), 32, 20, 80, -60, 100, "pine_l1", 0.10)
    createBranch(W(0.35), H(0.56), W(0.25), H(0.42), 20, 10, -80, -80, 80, "pine_l1_spur", 0.10)
    createBranch(W(0.48), H(0.45), W(0.72), H(0.48), 25, 14, 100, 110, 110, "pine_r1", 0.10)
    createBranch(W(0.72), H(0.48), W(0.62), H(0.35), 14, 8, -80, -80, 80, "pine_r1_spur", 0.10)
    createBranch(W(0.88), H(0.35), W(0.96), H(0.28), 15, 6, 50, -50, 80, "pine_peak", 0.10)
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.25), y = H(0.75), rx = 180, ry = 50, bob = 0 }
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.45), y = H(0.65), rx = 220, ry = 55, bob = 1.7 }
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.68), y = H(0.72), rx = 190, ry = 48, bob = 3.0 }
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.82), y = H(0.62), rx = 160, ry = 42, bob = 4.2 }
    for _, p in ipairs({
        { "pine_l1", 0.25 }, { "pine_l1", 0.50 }, { "pine_l1", 0.75 },
        { "pine_l1_spur", 0.45 }, { "pine_l1_spur", 0.80 },
        { "pine_r1", 0.22 }, { "pine_r1", 0.45 }, { "pine_r1", 0.72 },
        { "pine_r1_spur", 0.45 }, { "pine_r1_spur", 0.82 },
        { "pine_peak", 0.35 }, { "pine_peak", 0.65 }, { "pine_peak", 0.90 },
    }) do
        addTargetOnBranch(p[1], p[2], 40)
    end
    for i = 0, 2 do
        cranes[#cranes + 1] = {
            x = W(0.3 + i * 0.3),
            y = H(0.2 + hash01(i + 100) * 0.3),
            startY = H(0.2 + hash01(i + 100) * 0.3),
            speed = 2.2 + hash01(i + 200) * 0.6,
            amplitude = 45 + hash01(i + 300) * 25,
            theta = hash01(i + 400) * math.pi * 2,
            wingAngle = 0,
        }
    end
end

function generateMolong()
    -- 第17关:意象复刻 - 陈容《九龙图》墨龙(波士顿美术馆)
    -- 龙身三起三伏横贯全卷,是一条"活"的平台(运行时整条做行波起伏);
    -- 龙首在右,角可攀,四爪探波;云团可踏;龙珠悬于云上与龙身。
    createBranchPath({
        { 0.040, 0.600, 14 }, { 0.085, 0.520, 18 }, { 0.130, 0.450, 22 },
        { 0.180, 0.420, 26 }, { 0.235, 0.460, 29 }, { 0.285, 0.550, 31 },
        { 0.330, 0.660, 32 }, { 0.385, 0.730, 32 }, { 0.440, 0.740, 32 },
        { 0.495, 0.680, 31 }, { 0.545, 0.570, 29 }, { 0.595, 0.460, 27 },
        { 0.645, 0.385, 25 }, { 0.700, 0.360, 23 }, { 0.755, 0.400, 21 },
        { 0.805, 0.470, 19 }, { 0.850, 0.520, 18 }, { 0.895, 0.520, 17 },
    }, "dragon_body", 0.08)
    createBranchPath({
        { 0.895, 0.520, 17 }, { 0.930, 0.480, 22 }, { 0.962, 0.450, 21 }, { 0.985, 0.440, 18 },
    }, "dragon_head", 0.08)
    createBranchPath({ { 0.940, 0.425, 7 }, { 0.922, 0.360, 5 }, { 0.905, 0.300, 4 } }, "dragon_horn", 0)
    createBranchPath({ { 0.235, 0.490, 10 }, { 0.222, 0.558, 8 }, { 0.249, 0.624, 6 }, { 0.244, 0.685, 4 } }, "dragon_leg1", 0)
    createBranchPath({ { 0.440, 0.770, 10 }, { 0.426, 0.832, 8 }, { 0.456, 0.884, 6 }, { 0.450, 0.925, 4 } }, "dragon_leg2", 0)
    createBranchPath({ { 0.645, 0.415, 10 }, { 0.631, 0.478, 8 }, { 0.659, 0.538, 6 }, { 0.654, 0.595, 4 } }, "dragon_leg3", 0)
    createBranchPath({ { 0.850, 0.550, 10 }, { 0.836, 0.614, 8 }, { 0.865, 0.674, 6 }, { 0.860, 0.740, 4 } }, "dragon_leg4", 0)
    for _, c in ipairs({
        { 0.10, 0.82, 210, 55, 0.0 }, { 0.27, 0.30, 190, 50, 1.3 },
        { 0.47, 0.30, 200, 52, 2.2 }, { 0.62, 0.80, 210, 55, 3.1 },
        { 0.80, 0.76, 190, 50, 4.0 }, { 0.93, 0.68, 160, 45, 5.0 },
    }) do
        cloudPlatforms[#cloudPlatforms + 1] = { x = W(c[1]), y = H(c[2]), rx = c[3], ry = c[4], bob = c[5] }
    end
    addTarget(W(0.27), H(0.165), 42)
    addTarget(W(0.58), H(0.150), 42)
    addTarget(W(0.74), H(0.620), 40)
    for _, p in ipairs({
        { "dragon_body", 0.30 }, { "dragon_body", 0.55 }, { "dragon_body", 0.80 },
        { "dragon_head", 0.70 },
    }) do addTargetOnBranch(p[1], p[2], 40) end
end

-- ============================================================================
-- END scripts/src/30_level_generation.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/34_ldtk_grand_scroll_data.lua
-- ============================================================================
-- AUTO-GENERATED FILE. Do not edit directly.
-- Generated by tools/convert_ldtk_grand_to_lua.ps1 from ldtk/ink_grand_scroll.ldtk.

LDTK_GRAND_SCROLL = {
    source = "ldtk/ink_grand_scroll.ldtk",
    identifier = "World_1_GrandScroll",
    width = 9600,
    height = 3200,
    gridSize = 16,
    collision = {
        { x = 0, y = 2864, w = 1200, h = 144, v = 1 },
        { x = 1440, y = 2576, w = 816, h = 128, v = 1 },
        { x = 2432, y = 2144, w = 928, h = 16, v = 1 },
        { x = 2432, y = 2160, w = 304, h = 112, v = 1 },
        { x = 2736, y = 2224, w = 624, h = 48, v = 1 },
        { x = 2944, y = 2656, w = 864, h = 112, v = 1 },
        { x = 6592, y = 2048, w = 800, h = 112, v = 1 },
        { x = 7392, y = 2336, w = 896, h = 16, v = 1 },
        { x = 7392, y = 2352, w = 736, h = 112, v = 1 },
        { x = 8128, y = 2416, w = 160, h = 48, v = 1 },
        { x = 8672, y = 2768, w = 832, h = 144, v = 1 },
        { x = 2736, y = 2160, w = 800, h = 64, v = 2 },
        { x = 3440, y = 1968, w = 864, h = 64, v = 2 },
        { x = 3728, y = 2784, w = 1408, h = 64, v = 2 },
        { x = 3968, y = 1760, w = 816, h = 48, v = 2 },
        { x = 5136, y = 2832, w = 1440, h = 64, v = 2 },
        { x = 6272, y = 1872, w = 1104, h = 64, v = 2 },
        { x = 6864, y = 1568, w = 832, h = 64, v = 2 },
        { x = 7600, y = 1824, w = 992, h = 64, v = 2 },
        { x = 8128, y = 2352, w = 960, h = 64, v = 2 },
    },
    decor = {
    },
    entities = {
        { id = "BrushPathNode", layer = "Gameplay", x = 183, y = 2800, w = 16, h = 16 },
        { id = "PlayerStart", layer = "Gameplay", x = 183, y = 2800, w = 24, h = 24 },
        { id = "InkTarget", layer = "Gameplay", x = 617, y = 2450, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 1033, y = 2700, w = 16, h = 16 },
        { id = "Checkpoint", layer = "Gameplay", x = 1467, y = 2300, w = 44, h = 72 },
        { id = "InkTarget", layer = "Gameplay", x = 1733, y = 2033, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 1733, y = 2300, w = 16, h = 16 },
        { id = "BrushPathNode", layer = "Gameplay", x = 2450, y = 1917, w = 16, h = 16 },
        { id = "InkTarget", layer = "Gameplay", x = 2833, y = 1733, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 3000, y = 2000, w = 16, h = 16 },
        { id = "Checkpoint", layer = "Gameplay", x = 3367, y = 1967, w = 44, h = 72 },
        { id = "BrushPathNode", layer = "Gameplay", x = 3533, y = 1850, w = 16, h = 16 },
        { id = "InkTarget", layer = "Gameplay", x = 3867, y = 1417, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 4100, y = 1433, w = 16, h = 16 },
        { id = "BrushPathNode", layer = "Gameplay", x = 4667, y = 1567, w = 16, h = 16 },
        { id = "InkTarget", layer = "Gameplay", x = 4833, y = 2683, w = 48, h = 48 },
        { id = "Checkpoint", layer = "Gameplay", x = 5167, y = 2767, w = 44, h = 72 },
        { id = "BrushPathNode", layer = "Gameplay", x = 5333, y = 2517, w = 16, h = 16 },
        { id = "BrushPathNode", layer = "Gameplay", x = 6133, y = 2750, w = 16, h = 16 },
        { id = "InkTarget", layer = "Gameplay", x = 6333, y = 2367, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 6900, y = 1983, w = 16, h = 16 },
        { id = "InkTarget", layer = "Gameplay", x = 7067, y = 1667, w = 48, h = 48 },
        { id = "Checkpoint", layer = "Gameplay", x = 7133, y = 1517, w = 44, h = 72 },
        { id = "BrushPathNode", layer = "Gameplay", x = 7400, y = 1567, w = 16, h = 16 },
        { id = "BrushPathNode", layer = "Gameplay", x = 7933, y = 1217, w = 16, h = 16 },
        { id = "InkTarget", layer = "Gameplay", x = 8067, y = 1167, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 8467, y = 1300, w = 16, h = 16 },
        { id = "Checkpoint", layer = "Gameplay", x = 8633, y = 2400, w = 44, h = 72 },
        { id = "InkTarget", layer = "Gameplay", x = 8967, y = 1967, w = 48, h = 48 },
        { id = "BrushPathNode", layer = "Gameplay", x = 9000, y = 1867, w = 16, h = 16 },
        { id = "BrushPathNode", layer = "Gameplay", x = 9367, y = 2083, w = 16, h = 16 },
        { id = "GrandExit", layer = "Gameplay", x = 9367, y = 2083, w = 64, h = 96 },
        { id = "RockMass", layer = "Ink_Motifs", x = 0, y = 2200, w = 1233, h = 1000 },
        { id = "BambooCluster", layer = "Ink_Motifs", x = 17, y = 900, w = 600, h = 2283 },
        { id = "BambooCluster", layer = "Ink_Motifs", x = 373, y = 783, w = 633, h = 2133 },
        { id = "MistBank", layer = "Ink_Motifs", x = 733, y = 1683, w = 2033, h = 483 },
        { id = "BambooCluster", layer = "Ink_Motifs", x = 850, y = 1217, w = 500, h = 1733 },
        { id = "RockMass", layer = "Ink_Motifs", x = 1167, y = 1783, w = 1567, h = 1067 },
        { id = "Waterfall", layer = "Ink_Motifs", x = 1240, y = 783, w = 933, h = 2067 },
        { id = "Waterfall", layer = "Ink_Motifs", x = 1950, y = 1383, w = 783, h = 1683 },
        { id = "RockMass", layer = "Ink_Motifs", x = 2000, y = 1217, w = 1300, h = 817 },
        { id = "RockMass", layer = "Ink_Motifs", x = 2167, y = 2400, w = 1233, h = 700 },
        { id = "MistBank", layer = "Ink_Motifs", x = 2333, y = 2183, w = 1867, h = 450 },
        { id = "PineBranch", layer = "Ink_Motifs", x = 2400, y = 1733, w = 2933, h = 883 },
        { id = "WaterBand", layer = "Ink_Motifs", x = 3300, y = 2533, w = 3200, h = 450 },
        { id = "MistBank", layer = "Ink_Motifs", x = 3400, y = 2167, w = 2067, h = 350 },
        { id = "PeachPetalWater", layer = "Ink_Motifs", x = 3767, y = 2667, w = 1733, h = 273 },
        { id = "WaterBand", layer = "Ink_Motifs", x = 4867, y = 2683, w = 2600, h = 400 },
        { id = "PeachPetalWater", layer = "Ink_Motifs", x = 5000, y = 2750, w = 1867, h = 260 },
        { id = "MistBank", layer = "Ink_Motifs", x = 5100, y = 2250, w = 2367, h = 367 },
        { id = "CloudPlatform", layer = "Ink_Motifs", x = 6183, y = 1683, w = 1567, h = 483 },
        { id = "RockMass", layer = "Ink_Motifs", x = 6267, y = 1967, w = 1400, h = 933 },
        { id = "CraneRide", layer = "Ink_Motifs", x = 6350, y = 973, w = 633, h = 350 },
        { id = "PeachPetalWater", layer = "Ink_Motifs", x = 6350, y = 2700, w = 2233, h = 293 },
        { id = "WaterBand", layer = "Ink_Motifs", x = 6567, y = 2583, w = 2933, h = 500 },
        { id = "EavesRail", layer = "Ink_Motifs", x = 6583, y = 1367, w = 1333, h = 300 },
        { id = "Pavilion", layer = "Ink_Motifs", x = 6750, y = 1033, w = 1667, h = 1100 },
        { id = "CloudPlatform", layer = "Ink_Motifs", x = 6833, y = 1433, w = 1433, h = 433 },
        { id = "RockMass", layer = "Ink_Motifs", x = 6867, y = 1550, w = 1833, h = 1233 },
        { id = "EavesRail", layer = "Ink_Motifs", x = 7300, y = 1340, w = 1200, h = 287 },
        { id = "CloudPlatform", layer = "Ink_Motifs", x = 7467, y = 1783, w = 1700, h = 467 },
        { id = "RockMass", layer = "Ink_Motifs", x = 7633, y = 2167, w = 1733, h = 867 },
        { id = "PlumBranch", layer = "Ink_Motifs", x = 7767, y = 533, w = 2367, h = 883 },
        { id = "PlumBlossom", layer = "Ink_Motifs", x = 7867, y = 993, w = 293, h = 293 },
        { id = "CloudPlatform", layer = "Ink_Motifs", x = 8117, y = 2300, w = 1433, h = 400 },
        { id = "PlumBranch", layer = "Ink_Motifs", x = 8300, y = 1117, w = 1800, h = 667 },
        { id = "CraneRide", layer = "Ink_Motifs", x = 8317, y = 1483, w = 567, h = 317 },
        { id = "RockMass", layer = "Ink_Motifs", x = 8333, y = 2533, w = 1167, h = 583 },
        { id = "PlumBlossom", layer = "Ink_Motifs", x = 8367, y = 793, w = 300, h = 300 },
        { id = "PlumBlossom", layer = "Ink_Motifs", x = 8817, y = 683, w = 293, h = 293 },
        { id = "PlumBlossom", layer = "Ink_Motifs", x = 9260, y = 793, w = 273, h = 273 },
        { id = "RegionLabel", layer = "Labels", x = 400, y = 367, w = 180, h = 28 },
        { id = "RegionLabel", layer = "Labels", x = 3100, y = 883, w = 180, h = 28 },
        { id = "RegionLabel", layer = "Labels", x = 4933, y = 1867, w = 180, h = 28 },
        { id = "RegionLabel", layer = "Labels", x = 6933, y = 783, w = 180, h = 28 },
    },
}

-- ============================================================================
-- END scripts/src/34_ldtk_grand_scroll_data.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/35_ldtk_grand_scroll.lua
-- ============================================================================
-- LDtk grand-scroll runtime bridge. Data is generated in 34_ldtk_grand_scroll_data.lua.

LDTK_GRAND_SCROLL_ID = "ldtk_grand_scroll"
ldtkSolidRects = {}
ldtkOneWayRects = {}
ldtkHazardRects = {}
ldtkLabels = {}
ldtkDecor = {}
ldtkMotifs = {}
ldtkCheckpoints = {}
ldtkWaterfalls = {}
ldtkStart = nil
ldtkExit = nil

function currentLevelIsLDtkGrandScroll()
    return currentLevel and currentLevel.id == LDTK_GRAND_SCROLL_ID
end

function ldtkEntityCenter(e)
    return e.x + e.w * 0.5, e.y + e.h * 0.5
end

function addLDtkRect(r)
    local out = { x = r.x, y = r.y, w = r.w, h = r.h, v = r.v }
    if r.v == 2 then
        ldtkOneWayRects[#ldtkOneWayRects + 1] = out
    elseif r.v == 3 then
        ldtkHazardRects[#ldtkHazardRects + 1] = out
    else
        ldtkSolidRects[#ldtkSolidRects + 1] = out
    end
end

function addLDtkBambooStalk(startX, startY, angle, length, radius, segmentsCount, stalkId)
    local currentX, currentY = startX, startY
    local segLen = length / segmentsCount
    for i = 0, segmentsCount - 1 do
        local bendDir = angle > -math.pi / 2 and 1 or -1
        local curAngle = angle + i * 0.018 * bendDir
        local nextX = currentX + math.cos(curAngle) * segLen
        local nextY = currentY + math.sin(curAngle) * segLen
        local currentR = radius * (1 - (i / segmentsCount) * 0.45)
        bambooSegments[#bambooSegments + 1] = {
            x1 = currentX, y1 = currentY,
            x2 = nextX, y2 = nextY,
            r = currentR, stalkId = stalkId,
            isNode = true, nodeX = nextX, nodeY = nextY,
            angle = curAngle,
        }
        currentX, currentY = nextX, nextY
    end
end

function addLDtkBambooCluster(e, index)
    local x = e.x + e.w * 0.5
    local y = e.y + e.h
    addLDtkBambooStalk(x - 30, y + 160, -math.pi * 0.48, 470, 16, 11, "ldtk_bamboo_" .. index .. "_a")
    addLDtkBambooStalk(x + 36, y + 110, -math.pi * 0.39, 390, 12, 9, "ldtk_bamboo_" .. index .. "_b")
    addLDtkBambooStalk(x + 94, y + 60, -math.pi * 0.54, 330, 9, 8, "ldtk_bamboo_" .. index .. "_c")
end

function addLDtkBranchForMotif(e, index)
    local x, y = ldtkEntityCenter(e)
    if e.id == "PineBranch" then
        createBranch(x - 80, y + 60, x + 320, y - 48, 22, 8, 96, -88, 56, "ldtk_pine_" .. index, 0.14)
        addTargetOnBranch("ldtk_pine_" .. index, 0.52, 38)
    elseif e.id == "PlumBranch" then
        createBranch(x + 110, y + 38, x - 270, y - 18, 24, 5, -82, -62, 58, "ldtk_plum_" .. index, 0.16)
        addTargetOnBranch("ldtk_plum_" .. index, 0.58, 34)
    elseif e.id == "EavesRail" then
        createBranch(e.x, y, e.x + e.w * 1.85, y - 34, 9, 7, 38, -42, 42, "ldtk_eaves_rail_" .. index, 0.04)
    end
end

function addLDtkPavilion(e, index)
    addPavilion(e.x, e.y, math.max(180, e.w * 1.5), 3, 92)
    addRoof(e.x, e.y, e.x - 90, e.y - 70, { x = e.x - 40, y = e.y + 12 })
    addRoof(e.x + math.max(180, e.w * 1.5), e.y, e.x + math.max(260, e.w * 2.0), e.y - 74, { x = e.x + math.max(220, e.w * 1.75), y = e.y + 10 })
    chimes[#chimes + 1] = { x = e.x - 90, y = e.y - 46, pulse = 0, swayAngle = 0 }
    chimes[#chimes + 1] = { x = e.x + math.max(260, e.w * 2.0), y = e.y - 50, pulse = 0, swayAngle = 0 }
end

function addLDtkCloud(e, index)
    local x, y = ldtkEntityCenter(e)
    cloudPlatforms[#cloudPlatforms + 1] = {
        x = x, y = y,
        rx = math.max(110, e.w * 0.85),
        ry = math.max(34, e.h * 0.70),
        bob = index * 1.37,
    }
end

function addLDtkCrane(e, index)
    local x, y = ldtkEntityCenter(e)
    cranes[#cranes + 1] = {
        x = x, y = y,
        startY = y,
        speed = 1.6 + (index % 3) * 0.22,
        amplitude = 38 + (index % 5) * 7,
        theta = index * 0.91,
        wingAngle = 0,
        ldtkHomeX = x,
    }
end

function addLDtkPeachWater(e, index)
    local x, y = ldtkEntityCenter(e)
    waterLevel = math.max(waterLevel, y + 80)
    for i = 1, 8 do
        floatingPetals[#floatingPetals + 1] = {
            x = x - 260 + i * 70,
            y = y + (hash01(index * 41 + i * 7) - 0.5) * 24,
            w = 72 + hash01(index * 47 + i * 11) * 34,
            h = 18 + hash01(index * 53 + i * 13) * 9,
            speed = 0.45 + hash01(index * 59 + i * 17) * 0.55,
            bob = hash01(index * 61 + i * 19) * math.pi,
        }
    end
end

function ldtkCatmull(a, b, c, d, t)
    local t2 = t * t
    local t3 = t2 * t
    return 0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
end

function ldtkSampleCatmull(nodes, i, u)
    local p0 = nodes[math.max(1, i - 1)]
    local p1 = nodes[i]
    local p2 = nodes[i + 1]
    local p3 = nodes[math.min(#nodes, i + 2)]
    return ldtkCatmull(p0.x, p1.x, p2.x, p3.x, u), ldtkCatmull(p0.y, p1.y, p2.y, p3.y, u)
end

function buildLDtkBrushRoute()
    local nodes = {}
    for _, e in ipairs(LDTK_GRAND_SCROLL.entities or {}) do
        if e.id == "BrushPathNode" then
            local x, y = ldtkEntityCenter(e)
            nodes[#nodes + 1] = { x = x, y = y }
        end
    end
    table.sort(nodes, function(a, b) return a.x < b.x end)

    local samples = {}
    for i = 1, #nodes - 1 do
        local a, b = nodes[i], nodes[i + 1]
        local len = dist2(b.x - a.x, b.y - a.y)
        local steps = math.max(10, math.floor(len / 22))
        for s = 0, steps - 1 do
            local u = s / steps
            local x, y = ldtkSampleCatmull(nodes, i, u)
            samples[#samples + 1] = { x = x, y = y }
        end
    end
    if #nodes > 0 then
        samples[#samples + 1] = { x = nodes[#nodes].x, y = nodes[#nodes].y }
    end

    local count = #samples
    if count < 2 then return end
    local branchId = "ldtk_route_scroll"
    for i, p in ipairs(samples) do
        local prev = samples[math.max(1, i - 1)]
        local next = samples[math.min(count, i + 1)]
        local dx, dy = next.x - prev.x, next.y - prev.y
        local len = dist2(dx, dy)
        if len < 0.001 then len = 1 end
        local normX, normY = -dy / len, dx / len
        if normY > 0 then normX, normY = -normX, -normY end
        local t = (i - 1) / math.max(1, count - 1)
        local taper = 1 - math.abs(t - 0.46) * 0.22
        local pulse = math.sin(t * math.pi * 7.2) * 1.9 + math.sin(t * math.pi * 17.0) * 0.8
        local dry = hash01(i * 37 + p.x * 0.009 + p.y * 0.011) - 0.5
        local r = (17.5 - 5.8 * t) * taper + pulse + dry * 2.1
        if t < 0.055 then r = r * (0.58 + t * 7.6) end
        if t > 0.93 then r = r * (1 - (t - 0.93) * 7.2) end
        r = clamp(r, 6.5, 21)
        addBranchNode({ x = p.x, y = p.y, r = r, normX = normX, normY = normY, branchId = branchId, t = t, baseX = p.x, baseY = p.y })
    end
end

function generateLDtkGrandScroll()
    if not LDTK_GRAND_SCROLL then return end

    worldW = LDTK_GRAND_SCROLL.width
    worldH = LDTK_GRAND_SCROLL.height
    ldtkSolidRects = {}
    ldtkOneWayRects = {}
    ldtkHazardRects = {}
    ldtkLabels = {}
    ldtkDecor = {}
    ldtkMotifs = {}
    ldtkCheckpoints = {}
    ldtkWaterfalls = {}
    ldtkStart = nil
    ldtkExit = nil
    waterLevel = H(0.78)

    for _, r in ipairs(LDTK_GRAND_SCROLL.collision or {}) do
        addLDtkRect(r)
    end
    for _, r in ipairs(LDTK_GRAND_SCROLL.decor or {}) do
        ldtkDecor[#ldtkDecor + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, v = r.v }
    end

    buildLDtkBrushRoute()

    local labelNames = {
        "01_Bamboo_Falls",
        "02_Pine_Rock_Ledge",
        "03_Peach_Water_Reserve",
        "04_Pavilion_Cloud_Plum",
    }
    local labelIndex = 1

    for i, e in ipairs(LDTK_GRAND_SCROLL.entities or {}) do
        local cx, cy = ldtkEntityCenter(e)
        if e.id == "PlayerStart" then
            ldtkStart = { x = cx, y = cy }
        elseif e.id == "GrandExit" then
            ldtkExit = { x = cx, y = cy, w = e.w, h = e.h }
        elseif e.id == "Checkpoint" then
            ldtkCheckpoints[#ldtkCheckpoints + 1] = { x = cx, y = cy }
        elseif e.id == "RegionLabel" then
            ldtkLabels[#ldtkLabels + 1] = { x = e.x, y = e.y, text = labelNames[labelIndex] or ("Region_" .. labelIndex) }
            labelIndex = labelIndex + 1
        elseif e.id == "InkTarget" then
            addTarget(cx, cy, math.max(30, math.min(e.w, e.h) + 14))
        elseif e.id == "BambooCluster" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkBambooCluster(e, i)
        elseif e.id == "Waterfall" then
            ldtkWaterfalls[#ldtkWaterfalls + 1] = { x = e.x, y = e.y, w = math.max(260, e.w * 3.2), h = math.max(620, e.h * 3.8) }
            streams[#streams + 1] = { x1 = e.x + e.w * 0.5, y1 = e.y - 140, x2 = e.x + e.w * 0.8, y2 = e.y + e.h * 3.4, width = 120 }
        elseif e.id == "PineBranch" or e.id == "PlumBranch" or e.id == "EavesRail" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkBranchForMotif(e, i)
        elseif e.id == "PlumBlossom" then
            blooms[#blooms + 1] = {
                x = cx, y = cy, scale = 1, progress = 1,
                normX = 0, normY = -1, kind = "plum", r = 24,
            }
        elseif e.id == "PeachPetalWater" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkPeachWater(e, i)
        elseif e.id == "Pavilion" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkPavilion(e, i)
        elseif e.id == "CloudPlatform" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkCloud(e, i)
        elseif e.id == "CraneRide" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkCrane(e, i)
        end
    end
end

function resetLDtkGrandScrollPlayer()
    if not ldtkStart then return false end
    local best = nil
    local bestScore = 999999
    local function scanRects(rects)
        for _, r in ipairs(rects) do
            local left = r.x + player.radius + 2
            local right = r.x + r.w - player.radius - 2
            local clampedX = clamp(ldtkStart.x, left, right)
            local horizontalGap = math.max(0, r.x - ldtkStart.x, ldtkStart.x - (r.x + r.w))
            if horizontalGap <= 120 then
                local verticalGap = math.abs(r.y - ldtkStart.y)
                local score = verticalGap + horizontalGap * 1.8
                if r.y > ldtkStart.y + 260 then score = score + 300 end
                if score < bestScore then
                    bestScore = score
                    best = { x = clampedX, y = r.y - player.radius - 1 }
                end
            end
        end
    end
    scanRects(ldtkSolidRects)
    scanRects(ldtkOneWayRects)
    if best then
        player.x = best.x
        player.y = best.y
    else
        player.x = ldtkStart.x
        player.y = ldtkStart.y - player.radius - 8
    end
    player.facingRight = true
    return true
end

function resolveLDtkSolidRect(r)
    local rad = player.radius
    if player.x < r.x - rad or player.x > r.x + r.w + rad or player.y < r.y - rad or player.y > r.y + r.h + rad then
        return false
    end

    local leftPen = player.x - (r.x - rad)
    local rightPen = (r.x + r.w + rad) - player.x
    local topPen = player.y - (r.y - rad)
    local bottomPen = (r.y + r.h + rad) - player.y
    local minPen = math.min(math.min(leftPen, rightPen), math.min(topPen, bottomPen))

    if minPen == topPen then
        player.y = r.y - rad
        if player.vy > 0 then player.vy = 0 end
        player.isGrounded = true
        player.canDash = true
        player.isWallClinging = false
    elseif minPen == bottomPen then
        player.y = r.y + r.h + rad
        if player.vy < 0 then player.vy = 0 end
    elseif minPen == leftPen then
        player.x = r.x - rad
        if player.vx > 0 then player.vx = 0 end
        if keys.d then
            player.isWallClinging = true
            player.wallSide = 1
        end
    else
        player.x = r.x + r.w + rad
        if player.vx < 0 then player.vx = 0 end
        if keys.a then
            player.isWallClinging = true
            player.wallSide = -1
        end
    end
    return true
end

function resolveLDtkRouteCollision()
    local nearWall, detectedWallSide = false, 0
    local closest = {}

    for branchId, list in pairs(branchGroups) do
        if branchId:find("^ldtk_route_") then
            local bounds = branchBounds and branchBounds[branchId]
            local pad = 120
            if (not bounds) or (player.x >= bounds.minX - pad and player.x <= bounds.maxX + pad and player.y >= bounds.minY - pad and player.y <= bounds.maxY + pad) then
                for _, b in ipairs(list) do
                    local hitR = b.r * 1.02
                    if math.abs(player.x - b.x) <= hitR + player.radius + 24 and math.abs(player.y - b.y) <= hitR + player.radius + 24 then
                        local dx, dy = player.x - b.x, player.y - b.y
                        local d = dist2(dx, dy)
                        if not closest[branchId] or d < closest[branchId].dist then
                            closest[branchId] = { node = b, dist = d, dx = dx, dy = dy, hitR = hitR }
                        end
                    end
                end
            end
        end
    end

    for _, item in pairs(closest) do
        local b, d = item.node, item.dist
        local minDist = player.radius + item.hitR
        if d < minDist then
            local overlap = minDist - d
            local nx, ny = item.dx / (d == 0 and 1 or d), item.dy / (d == 0 and 1 or d)
            if d == 0 then nx, ny, overlap = 0, -1, minDist end
            player.x = player.x + nx * overlap
            player.y = player.y + ny * overlap
            if ny < -0.36 then
                player.isGrounded = true
                player.canDash = true
                player.isWallClinging = false
                if player.vy > 0 then player.vy = 0 end
            elseif ny > 0.45 and player.vy < 0 then
                player.vy = 0
            end
            if not player.isGrounded and math.abs(nx) > 0.72 then
                if (keys.a and nx > 0) or (keys.d and nx < 0) then
                    nearWall = true
                    detectedWallSide = nx > 0 and -1 or 1
                end
            end
        end
    end

    if nearWall and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = detectedWallSide
    end
end

function ldtkGrandScrollCollision(prevX, prevY)
    player.isGrounded = false
    player.isWallClinging = false
    prevY = prevY or player.y

    for _, r in ipairs(ldtkSolidRects) do
        if math.abs(player.x - (r.x + r.w * 0.5)) < r.w * 0.5 + player.radius + 90 and math.abs(player.y - (r.y + r.h * 0.5)) < r.h * 0.5 + player.radius + 90 then
            resolveLDtkSolidRect(r)
        end
    end

    resolveLDtkRouteCollision()

    if player.vy >= 0 then
        for _, r in ipairs(ldtkOneWayRects) do
            local footPrev = prevY + player.radius
            local footNow = player.y + player.radius
            if player.x >= r.x - player.radius and player.x <= r.x + r.w + player.radius and footPrev <= r.y + 8 and footNow >= r.y and footNow <= r.y + math.max(24, r.h + 20) then
                player.y = r.y - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
                player.isWallClinging = false
                break
            end
        end
    end

    for _, r in ipairs(ldtkHazardRects) do
        if player.x > r.x - player.radius and player.x < r.x + r.w + player.radius and player.y > r.y - player.radius and player.y < r.y + r.h + player.radius then
            resetLDtkGrandScrollPlayer()
            break
        end
    end
end

function updateLDtkGrandScrollSpecial()
    if not currentLevelIsLDtkGrandScroll() then return false end

    for _, fall in ipairs(ldtkWaterfalls) do
        if player.x > fall.x - 70 and player.x < fall.x + fall.w and player.y > fall.y - 160 and player.y < fall.y + fall.h then
            local center = fall.x + fall.w * 0.45
            local lift = clamp(1 - math.abs(player.x - center) / (fall.w * 0.62), 0.25, 1)
            player.vy = math.max(player.vy - 1.1 * lift, -12.5)
            player.vx = player.vx + 0.06 * lift
            if hash01(elapsed * 60 + player.x) > 0.48 then addTrail(player.x, player.y + 10, player.radius * 1.25, 0.13, 32, "water") end
        end
    end

    for _, s in ipairs(streams) do
        local dx, dy = s.x2 - s.x1, s.y2 - s.y1
        local len2 = dx * dx + dy * dy
        if len2 > 0.01 then
            local t = clamp(((player.x - s.x1) * dx + (player.y - s.y1) * dy) / len2, 0, 1)
            local px, py = s.x1 + t * dx, s.y1 + t * dy
            local d = dist2(player.x - px, player.y - py)
            if d < s.width then
                local len = math.sqrt(len2)
                player.vx = player.vx + (dx / len) * 0.22
                player.vy = player.vy + (dy / len) * 0.10
                if hash01(elapsed * 80 + d) > 0.65 then addTrail(player.x, player.y, player.radius * 1.2, 0.10, 20, "water") end
            end
        end
    end

    if player.craneCooldown > 0 then player.craneCooldown = player.craneCooldown - 1 end
    if player.ridingCrane then
        player.x = player.ridingCrane.x
        player.y = player.ridingCrane.y - 12
        player.vx, player.vy = 0, 0
        player.canDash = true
        if dashJustPressed or keys.space then
            local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
            local dy = (keys.s and 1 or 0) - (keys.w and 1 or 0)
            if dx == 0 and dy == 0 then dx = player.facingRight and 1 or -1 end
            local d = dist2(dx, dy)
            if d < 0.001 then d = 1 end
            player.ridingCrane = nil
            boostFluidTrail(26)
            player.isDashing = true
            player.canDash = false
            player.dashTime = 12
            player.dashDirX, player.dashDirY = dx / d, dy / d
            player.craneCooldown = 40
            keys.space = false
            dashJustPressed = false
        end
        return true
    elseif player.craneCooldown == 0 and not player.isDashing then
        for _, c in ipairs(cranes) do
            if dist2(player.x - c.x, player.y - c.y) < player.radius + 38 then
                player.ridingCrane = c
                break
            end
        end
    end

    return false
end

-- ============================================================================
-- END scripts/src/35_ldtk_grand_scroll.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/40_gameplay_targets.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function resetCollections()
    branches = {}
    branchGroups = {}
    branchBounds = {}
    branchMetadata = {}
    bambooSegments = {}
    targets = {}
    blooms = {}
    trailParticles = {}
    dashFluidPoints = {}
    dashFluidDroplets = {}
    dashFluidDistance = 0
    fluidTrailEnhancedFrames = 0
    fluidTrailRecentMoveFrames = 0
    fluidTrailDashBlend = 0
    bristleParticles = {}
    needleCorpses = {}
    ambientParticles = {}
    glidingLeaves = {}
    willowRopes = {}
    floatingPetals = {}
    roofs = {}
    pavilions = {}
    gears = {}
    chimes = {}
    cranes = {}
    cloudPlatforms = {}
    streams = {}
    pineSprings = {}
    windWaves = {}
    collectedCount = 0
    completionTimer = 0
    completionSealDelay = 0
    waterLevel = 0
end

local function resetPlayer()
    player.radius = currentLevel.radius
    player.gravityDefault = currentLevel.gravity
    player.gravity = currentLevel.gravity
    player.jumpForce = currentLevel.jumpForce
    player.dashSpeed = currentLevel.dashSpeed
    player.friction = currentLevel.friction
    player.speed = 1.6
    player.vx, player.vy = 0, 0
    player.isDashing, player.dashTime = false, 0
    player.waterfallDashBoost = 0
    player.facingRight, player.canDash = true, true
    player.isGrounded, player.isWallClinging = false, false
    player.wallSide = 0
    player.isGliding = false
    player.swingRope, player.ridingCrane = nil, nil
    player.craneCooldown = 0
    player.onEaves = nil
    player.eavesT, player.eavesSpeed = 0, 0

    if currentLevel.id == "bamboo" then
        local nodes = {}
        for _, s in ipairs(bambooSegments) do if s.stalkId == "bamboo1" and s.isNode then nodes[#nodes + 1] = s end end
        local safe = nodes[math.max(1, #nodes - 3)]
        if safe then player.x, player.y = safe.nodeX - 25, safe.nodeY - 200 else player.x, player.y = W(0.15), H(0.3) end
    elseif currentLevel.id == "pine" then
        local ns = branchGroups.pine1 or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.10), H(0.70) end
    elseif currentLevel.id == "maple" then
        local ns = branchGroups.main or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.05), H(0.72) end
    elseif currentLevel.id == "plum" or currentLevel.id == "plum_parallax" then
        local ns = branchGroups.main_trunk or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.90), H(0.55) end
        player.facingRight = false
    elseif currentLevel.id == "plum_mirror" then
        local ns = branchGroups.main_trunk or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.10), H(0.55) end
        player.facingRight = true
    elseif currentLevel.id == "plum_finale" then
        local ns = branchGroups.finale_trunk or {}
        local safe = ns[12]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.06), H(0.78) end
        player.facingRight = true
    elseif currentLevel.id == "wentong_zhu" then
        local ns = branchGroups.wt_cane or {}
        local safe = ns[10]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.08), H(0.18) end
        player.facingRight = true
    elseif currentLevel.id == "plum_xiyan" then
        local ns = branchGroups.xy_trunk or {}
        local safe = ns[12]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.95), H(0.45) end
        player.facingRight = false
    elseif currentLevel.id == "xuwei_grape" then
        local ns = branchGroups.xw_vine or {}
        local safe = ns[8]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.92), H(0.26) end
        player.facingRight = false
    elseif currentLevel.id == "molong" then
        local ns = branchGroups.dragon_body or {}
        local safe = ns[math.max(1, math.floor(#ns * 0.45))]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.40), H(0.65) end
        player.facingRight = true
    elseif currentLevel.id == "peach" then
        local ns = branchGroups.main_trunk or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.05), H(0.72) end
    elseif currentLevel.id == "eaves" then
        local ns = branchGroups.pavilion_beam_0 or {}
        local safe = ns[math.floor(#ns / 2)]
        if safe then player.x, player.y = safe.x, safe.y - player.radius - 20 else player.x, player.y = W(0.05), H(0.60) end
    elseif currentLevel.id == "huangshan" then
        local ns = branchGroups.pine_l1 or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 15) else player.x, player.y = W(0.05), H(0.50) end
    elseif currentLevel.id == "plum_master" then
        local ns = branchGroups.master_mid_right or branchGroups.master_trunk or {}
        local safe = ns[math.max(1, math.floor(#ns * 0.22))]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 20) else player.x, player.y = W(0.50), H(0.38) end
    elseif currentLevel.id == "ldtk_grand_scroll" then
        if not resetLDtkGrandScrollPlayer() then
            player.x, player.y = W(0.02), H(0.82)
        end
    end
    fluidTrailEnhancedFrames = 0
    fluidTrailRecentMoveFrames = 0
    fluidTrailDashBlend = 0
    beginDashFluid(player.x, player.y)
    dashFluidDroplets = {}
end

local function loadLevel(index)
    if index < 1 then index = #LEVELS end
    if index > #LEVELS then index = 1 end
    currentLevelIdx = index
    currentLevel = LEVELS[currentLevelIdx]
    worldW = DESIGN_W * currentLevel.wmul
    worldH = DESIGN_H * currentLevel.hmul
    resetCollections()

    if currentLevel.id == "bamboo" then generateBamboo()
    elseif currentLevel.id == "pine" then generatePine()
    elseif currentLevel.id == "maple" then generateMaple()
    elseif currentLevel.id == "plum" then generatePlum()
    elseif currentLevel.id == "peach" then generatePeach()
    elseif currentLevel.id == "eaves" then generateEaves()
    elseif currentLevel.id == "huangshan" then generateHuangshan()
    elseif currentLevel.id == "plum_master" then generatePlumMaster()
    elseif currentLevel.id == "plum_parallax" then generatePlum() -- 视差关复用蟠梅长卷地形(sourceLevelIndex=4)
    elseif currentLevel.id == "plum_mirror" then generatePlumMirror()
    elseif currentLevel.id == "plum_finale" then generatePlumFinale()
    elseif currentLevel.id == "wentong_zhu" then generateWentongZhu()
    elseif currentLevel.id == "plum_xiyan" then generatePlumXiyan()
    elseif currentLevel.id == "xuwei_grape" then generateXuweiGrape()
    elseif currentLevel.id == "molong" then generateMolong()
    elseif currentLevel.id == "ldtk_grand_scroll" then generateLDtkGrandScroll()
    end

    resetPlayer()
    cameraX = clamp(player.x - DESIGN_W * 0.5, 0, math.max(0, worldW - DESIGN_W))
    cameraY = clamp(player.y - DESIGN_H * 0.5, 0, math.max(0, worldH - DESIGN_H))
    showSeal = false
    sealViewProgress = 0
    sealStampProgress = 0
    print(string.format("Loaded ink HTML port %d/%d: %s", currentLevelIdx, #LEVELS, currentLevel.name))
end

local function startDash()
    local inBambooFall = currentLevel and currentLevel.id == "bamboo" and player.x > W(0.32) and player.x < W(0.80) and player.y > H(0.03)
    if player.isDashing or ((not player.canDash) and (not inBambooFall)) then return end
    boostFluidTrail(26)
    player.isDashing = true
    player.canDash = false
    player.dashTime = inBambooFall and 16 or 12
    local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
    local dy = (keys.s and 1 or 0) - (keys.w and 1 or 0)
    if inBambooFall and dx == 0 and dy == 0 then
        dx, dy = 1, -0.28
    elseif dx == 0 and dy == 0 then
        dx = player.facingRight and 1 or -1
    end
    local d = dist2(dx, dy)
    if d < 0.001 then d = 1 end
    player.dashDirX, player.dashDirY = dx / d, dy / d
    player.vy = 0
    player.waterfallDashBoost = inBambooFall and 3.5 or 0
    if inBambooFall then
        player.vx = player.dashDirX * (player.dashSpeed + 3.0)
        player.vy = player.dashDirY * (player.dashSpeed + 3.0)
    end
    dashJustPressed = false
end

local function circleBranchCollision()
    player.isGrounded = false
    local nearWall, detectedWallSide = false, 0
    local closest = {}

    for branchId, list in pairs(branchGroups) do
        local bounds = branchBounds and branchBounds[branchId]
        local pad = currentLevel.id == "maple" and 260 or 90
        if (not bounds) or (player.x >= bounds.minX - pad and player.x <= bounds.maxX + pad and player.y >= bounds.minY - pad and player.y <= bounds.maxY + pad) then
            for _, b in ipairs(list) do
                if math.abs(player.x - b.x) <= b.r + 55 and math.abs(player.y - b.y) <= b.r + 55 then
                    local dx, dy = player.x - b.x, player.y - b.y
                    local d = dist2(dx, dy)
                    if not closest[b.branchId] or d < closest[b.branchId].dist then
                        closest[b.branchId] = { node = b, dist = d, dx = dx, dy = dy }
                    end
                end
            end
        end
    end

    for _, item in pairs(closest) do
        local b, d = item.node, item.dist
        local minDist = player.radius + b.r * 0.96
        if d < minDist then
            local overlap = minDist - d
            local nx, ny = item.dx / (d == 0 and 1 or d), item.dy / (d == 0 and 1 or d)
            if d == 0 then nx, ny, overlap = 0, -1, minDist end
            player.x = player.x + nx * overlap
            player.y = player.y + ny * overlap
            if ny < -0.4 then
                player.isGrounded = true
                player.canDash = true
                player.isWallClinging = false
                local impactVy = math.max(0, player.vy)
                if player.vy > 0 then player.vy = 0 end
                if currentLevel.id == "maple" and branchMetadata[b.branchId] then
                    local meta = branchMetadata[b.branchId]
                    meta.targetBend = math.min(meta.maxBend, meta.targetBend + 7.5 + impactVy * 4.2)
                end
            elseif ny > 0.4 and player.vy < 0 then
                player.vy = 0
            end
            if not player.isGrounded and math.abs(nx) > 0.72 then
                if (keys.a and nx > 0) or (keys.d and nx < 0) then
                    nearWall = true
                    detectedWallSide = nx > 0 and -1 or 1
                end
            end
        end
    end

    if nearWall and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = detectedWallSide
    else
        player.isWallClinging = false
    end
end

local function bambooCollision()
    player.isGrounded = false
    local nearWall, detectedWallSide = false, 0
    for _, seg in ipairs(bambooSegments) do
        local dx, dy = seg.x2 - seg.x1, seg.y2 - seg.y1
        local len2 = dx * dx + dy * dy
        local t = clamp(((player.x - seg.x1) * dx + (player.y - seg.y1) * dy) / len2, 0, 1)
        local px, py = seg.x1 + t * dx, seg.y1 + t * dy
        local distX, distY = player.x - px, player.y - py
        local d = dist2(distX, distY)
        local minDist = player.radius + seg.r
        if d < minDist then
            local nx, ny = distX / (d == 0 and 1 or d), distY / (d == 0 and 1 or d)
            player.x = player.x + nx * (minDist - d)
            player.y = player.y + ny * (minDist - d)
            if player.isDashing and hash01(elapsed * 88 + px) > 0.55 then
                addBristle(px, py, player.vx, player.vy, "leaf")
            end
            if math.abs(nx) > 0.7 and not player.isGrounded then
                if (keys.a and nx > 0) or (keys.d and nx < 0) then
                    nearWall = true
                    detectedWallSide = nx > 0 and -1 or 1
                end
            end
        end
        if seg.isNode and player.vy >= 0 and math.abs(player.x - seg.nodeX) < seg.r * 3 and player.y < seg.nodeY and player.y + player.radius > seg.nodeY - 5 then
            player.y = seg.nodeY - player.radius
            player.vy = 0
            player.isGrounded = true
            player.canDash = true
            player.isWallClinging = false
        end
    end
    if nearWall and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = detectedWallSide
    else
        player.isWallClinging = false
    end
end

local function updateTargets()
    for _, t in ipairs(targets) do
        if not t.dead then
            if t.hitCooldown and t.hitCooldown > 0 then t.hitCooldown = t.hitCooldown - 1 end
            local dx, dy = player.x - t.x, player.y - t.y
            local d = dist2(dx, dy)
            local isNeedleEnemy = currentLevel.id == "pine" or currentLevel.id == "huangshan"
            if d < t.r + player.radius + 20 and player.isDashing then
                t.dead = true
                collectedCount = collectedCount + 1
                if isNeedleEnemy then
                    player.vy = (player.dashDirY or 0) * currentLevel.dashSpeed * 0.24
                    player.dashTime = math.max(player.dashTime or 0, 7)
                elseif currentLevel.id == "peach" or currentLevel.id == "bamboo" then
                    -- These targets only change the scene; they should not steer the player.
                else
                    player.vy = currentLevel.id == "bamboo" and -12 or -18.5
                end
                player.canDash = true
                local bloom = {
                    x = t.x, y = t.y, attachX = t.attachX, attachY = t.attachY,
                    scale = 0, progress = 0, normX = t.normX, normY = t.normY,
                    branchId = t.branchId, nodeIndex = t.nodeIndex, attachOffset = t.attachOffset,
                    orientationJitter = t.orientationJitter,
                    kind = currentLevel.id, r = t.r,
                }
                blooms[#blooms + 1] = bloom
                if triggerTargetEffect then triggerTargetEffect(t, bloom) end
                for i = 1, 18 do addBristle(t.x, t.y, -player.vx, -player.vy, "bloom") end
                if collectedCount >= #targets then
                    completionSealDelay = 0.95
                end
            elseif isNeedleEnemy and d < t.r + player.radius + 8 and (not t.hitCooldown or t.hitCooldown <= 0) then
                local nx, ny = dx, dy
                if d < 0.001 then
                    nx = player.facingRight and -1 or 1
                    ny = -0.35
                    d = dist2(nx, ny)
                end
                nx, ny = nx / d, ny / d
                if math.abs(nx) < 0.32 then nx = player.x < t.x and -0.72 or 0.72 end
                player.x = player.x + nx * 7
                player.vx = nx * 8.2 + (t.normX or 0) * 2.0
                player.vy = math.min(player.vy, -4.2)
                player.isGrounded = false
                player.canDash = true
                t.hitCooldown = 22
                t.hitFlash = 1
                for i = 1, 10 do addBristle(t.x, t.y, -nx * 8, -ny * 3, currentLevel.id) end
            end
        end
    end
end

function spawnMapleLeafChain(t)
    local baseSeed = t.x * 0.017 + t.y * 0.013 + collectedCount * 31
    for i = 1, 3 do
        glidingLeaves[#glidingLeaves + 1] = {
            x = t.x + W(0.035 * i) + (hash01(baseSeed + i * 7) - 0.5) * 18,
            y = t.y + H(0.030 * i) + (hash01(baseSeed + i * 11) - 0.5) * 24,
            size = 22 + hash01(baseSeed + i * 13) * 7,
            speed = 0.55 + hash01(baseSeed + i * 17) * 0.35,
            bob = hash01(baseSeed + i * 19) * 6.28,
            platform = true,
            spawned = true,
        }
    end
    player.vy = math.min(player.vy, currentLevel.jumpForce * 0.82)
end

function swayNearestWillow(x, y)
    local best, bestD = nil, 999999
    for _, rope in ipairs(willowRopes) do
        local tipX = rope.anchorX + math.sin(rope.angle or 0) * rope.length
        local tipY = rope.anchorY + math.cos(rope.angle or 0) * rope.length
        local d = math.min(dist2(x - tipX, y - tipY), dist2(x - rope.anchorX, y - rope.anchorY) * 0.72)
        if d < bestD then best, bestD = rope, d end
    end
    local dir = player.facingRight and 1 or -1
    if best then
        dir = x > best.anchorX and 1 or -1
        best.angularVelocity = best.angularVelocity + dir * 0.052
        best.angle = clamp((best.angle or 0) + dir * 0.09, -1.18, 1.18)
    end
    for i = 1, 16 do addBristle(x, y, -dir * 5, -8, "bloom") end
end

function pulseNearestChime(x, y)
    local best, bestD = nil, 999999
    for _, ch in ipairs(chimes) do
        local d = dist2(x - ch.x, y - ch.y)
        if d < bestD then best, bestD = ch, d end
    end
    if best then
        best.swayAngle = (x > best.x and -1 or 1) * 0.32
        best.pulse = best.pulse + 1.6
        windWaves[#windWaves + 1] = { x = best.x, y = best.y + 16, r = 0, life = 46, maxLife = 46 }
    else
        windWaves[#windWaves + 1] = { x = x, y = y, r = 0, life = 38, maxLife = 38 }
    end
end

function launchAlongEavesRoute(t)
    local best, bestD = nil, 999999
    for _, ch in ipairs(chimes) do
        local d = dist2(t.x - ch.x, t.y - (ch.y + 26))
        if d < bestD then
            best, bestD = ch, d
        end
    end
    player.isDashing = false
    player.dashTime = 0
    player.onEaves = nil
    player.canDash = true
    if best then
        local bellX, bellY = best.x, best.y + 28
        local dx, dy = t.x - bellX, t.y - bellY
        local len = dist2(dx, dy)
        if len < 0.001 then
            dx = player.facingRight and 1 or -1
            dy = -0.45
            len = dist2(dx, dy)
        end
        dx, dy = dx / len, dy / len
        if math.abs(dx) < 0.28 then dx = player.facingRight and 0.72 or -0.72 end
        best.swayAngle = -dx * 0.58
        best.pulse = best.pulse + 2.6
        player.x = bellX + dx * (player.radius + 10)
        player.y = bellY + dy * 10
        player.vx = dx * 14.5
        player.vy = math.min(dy * 8.0 - 10.5, -7.8)
        windWaves[#windWaves + 1] = { x = bellX, y = bellY, r = 0, life = 48, maxLife = 48 }
        windWaves[#windWaves + 1] = { x = t.x, y = t.y, r = 0, life = 30, maxLife = 30 }
        for i = 1, 24 do addBristle(bellX, bellY, -player.vx, -player.vy, "gold") end
    else
        player.vx = player.vx * 0.4
        player.vy = math.min(player.vy, -7.2)
        for i = 1, 14 do addBristle(t.x, t.y, -player.vx, -player.vy, "gold") end
    end
end

MAX_NEEDLE_CORPSES = 260

function spawnNeedleCorpseScatter(t, amount)
    local nx, ny = t.normX or 0, t.normY or -1
    local tx, ty = -ny, nx
    local baseX = t.attachX and (t.attachX + nx * ((t.r or 36) * 0.42)) or t.x
    local baseY = t.attachY and (t.attachY + ny * ((t.r or 36) * 0.42)) or t.y
    local count = amount or (currentLevel.id == "huangshan" and 15 or 18)
    local branchAngle = math.atan2(ty, tx)
    for i = 1, count do
        local seed = t.x * 0.017 + t.y * 0.013 + i * 31 + collectedCount * 7
        local along = (hash01(seed + 3) - 0.5) * (t.r or 36) * 2.6
        local lift = (hash01(seed + 7) - 0.22) * (t.r or 36) * 0.58
        needleCorpses[#needleCorpses + 1] = {
            x = baseX + tx * along + nx * lift,
            y = baseY + ty * along + ny * lift,
            angle = branchAngle + (hash01(seed + 11) - 0.5) * 0.95,
            len = (t.r or 36) * (0.38 + hash01(seed + 17) * 0.48),
            width = 0.85 + hash01(seed + 19) * 0.95,
            alpha = 96 + hash01(seed + 23) * 88,
            seed = seed,
            kind = currentLevel.id,
        }
    end
    while #needleCorpses > MAX_NEEDLE_CORPSES do table.remove(needleCorpses, 1) end
end

function triggerTargetEffect(t, bloom)
    if currentLevel.id == "pine" or currentLevel.id == "huangshan" then
        bloom.springPulse = 0.65
        local dirX = player.dashDirX or (player.facingRight and 1 or -1)
        if math.abs(dirX) < 0.18 then dirX = player.facingRight and 1 or -1 end
        player.vx = player.vx + dirX * 4.8
        player.vy = player.vy * 0.35
        player.dashTime = math.max(player.dashTime or 0, 7)
        for i = 1, 28 do addBristle(t.x, t.y, -player.vx * 0.35, -player.vy * 0.2, currentLevel.id) end
        if spawnInkLabHitFeedback then spawnInkLabHitFeedback(t) end
    elseif currentLevel.id == "maple" then
        spawnMapleLeafChain(t)
    elseif currentLevel.id == "peach" then
        swayNearestWillow(t.x, t.y)
    elseif currentLevel.id == "eaves" then
        launchAlongEavesRoute(t)
    end
end

local function updatePeachRopes()
    for _, rope in ipairs(willowRopes) do
        local g = 0.3
        rope.oscTime = rope.oscTime + 0.015
        local wind = math.sin(rope.oscTime) * 0.0008
        local accel = -(g / rope.length) * math.sin(rope.angle) + wind
        rope.angularVelocity = (rope.angularVelocity + accel) * 0.995
        rope.angularVelocity = clamp(rope.angularVelocity, -0.05, 0.05)
        rope.angle = clamp(rope.angle + rope.angularVelocity, -1.3, 1.3)
    end
end

local function ropeTip(rope)
    return rope.anchorX + math.sin(rope.angle) * rope.length, rope.anchorY + math.cos(rope.angle) * rope.length
end

function mapleLeafVisualY(leaf)
    return leaf.y + math.sin(elapsed + leaf.bob) * (leaf.platform and 10 or 18)
end

function mapleLeafPlatformCollision()
    if currentLevel.id ~= "maple" or player.vy < 0 then return end
    for _, leaf in ipairs(glidingLeaves) do
        if leaf.platform then
            local y = mapleLeafVisualY(leaf)
            local topY = y - leaf.size * 0.22
            local halfW = leaf.size * 1.36
            local footY = player.y + player.radius
            if math.abs(player.x - leaf.x) < halfW + player.radius and footY >= topY and footY <= topY + math.max(24, player.vy + 14) then
                player.y = topY - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
                player.isGliding = false
                leaf.squash = 1
                if hash01(elapsed * 120 + leaf.x) > 0.62 then addBristle(player.x, player.y + player.radius, player.vx, -2, "red") end
                break
            end
        end
    end
end

function updateBloomSpringInteractions()
    return
end

local function updateSpecialBeforeMovement()
    if currentLevel.id == "ldtk_grand_scroll" then
        updateLDtkGrandScrollSpecial()
        return
    end

    if currentLevel.id == "molong" then
        -- 墨龙行波:整条龙身按行波起伏,玩家被驮起/抛出;龙首、角、爪随波同摆
        local ph = elapsed * 3.0
        local function wob(t) return math.sin(ph - t * 14.0) * 26 end
        local body = branchGroups.dragon_body
        if body then
            for _, n in ipairs(body) do n.y = n.baseY + wob(n.t) end
            refreshBranchNormalsForCurrentPose(body)
        end
        local hw = wob(1)
        for _, bid in ipairs({ "dragon_head", "dragon_horn" }) do
            local l = branchGroups[bid]
            if l then for _, n in ipairs(l) do n.y = n.baseY + hw end end
        end
        local legRoots = { 0.22, 0.42, 0.62, 0.82 }
        for i = 1, 4 do
            local l = branchGroups["dragon_leg" .. i]
            if l then
                local o = wob(legRoots[i])
                for _, n in ipairs(l) do n.y = n.baseY + o end
            end
        end
        for _, t in ipairs(targets) do bindItemToBranch(t) end
        for _, b in ipairs(blooms) do bindItemToBranch(b) end
        for _, cp in ipairs(cloudPlatforms) do
            local cy = cp.y + math.sin(elapsed * 1.2 + cp.bob) * 8
            if math.abs(player.x - cp.x) < cp.rx and math.abs((player.y + player.radius) - cy) < cp.ry * 0.75 and player.vy >= 0 then
                player.y = cy - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
            end
        end
        return
    end

    if currentLevel.id == "bamboo" then
        local x1, x2 = W(0.32), W(0.80)
        if player.x > x1 and player.x < x2 and player.y > H(0.03) then
            local center = W(0.56)
            local fallHalf = W(0.27)
            local lift = clamp(1 - math.abs(player.x - center) / fallHalf, 0.42, 1)
            player.vy = math.max(player.vy - 1.92 * lift, -14.2)
            player.vx = player.vx + 0.18 * lift
            if player.isDashing then
                player.vx = player.vx + 0.38 * lift
                player.vy = player.vy - 0.30 * lift
            end
            if hash01(elapsed * 60 + player.x) > 0.52 then addTrail(player.x, player.y + 10, player.radius * (1.1 + lift * 0.5), 0.12, 34, "water") end
        end
    elseif currentLevel.id == "pine" then
        for _, s in ipairs(streams) do
            local dx, dy = s.x2 - s.x1, s.y2 - s.y1
            local len2 = dx * dx + dy * dy
            local t = clamp(((player.x - s.x1) * dx + (player.y - s.y1) * dy) / len2, 0, 1)
            local px, py = s.x1 + t * dx, s.y1 + t * dy
            local d = dist2(player.x - px, player.y - py)
            if d < s.width then
                local l = math.sqrt(len2)
                player.vx = player.vx + (dx / l) * 0.42
                player.vy = player.vy + (dy / l) * 0.28
                if hash01(elapsed * 80 + d) > 0.6 then addTrail(player.x, player.y, player.radius * 1.5, 0.10, 20, "water") end
            end
        end
    elseif currentLevel.id == "maple" then
        if player.vy > 0 and not player.isDashing then
            for _, leaf in ipairs(glidingLeaves) do
                if dist2(player.x - leaf.x, player.y - leaf.y) < player.radius + leaf.size then
                    player.isGliding = true
                end
            end
        end
    elseif currentLevel.id == "peach" then
        updatePeachRopes()
        if player.swingRope then
            local rope = player.swingRope
            local tx, ty = ropeTip(rope)
            player.x, player.y = tx, ty
            local push = (keys.d and 1 or 0) - (keys.a and 1 or 0)
            rope.angularVelocity = rope.angularVelocity + push * 0.002
            if keys.space or dashJustPressed then
                player.swingRope = nil
                player.vx = math.cos(rope.angle) * rope.angularVelocity * rope.length * 0.9 + push * 6
                player.vy = currentLevel.jumpForce * 0.85
                player.canDash = true
                keys.space = false
            end
            return
        elseif not player.isDashing then
            for _, rope in ipairs(willowRopes) do
                local tx, ty = ropeTip(rope)
                if dist2(player.x - tx, player.y - ty) < player.radius + 36 then
                    player.swingRope = rope
                    break
                end
            end
        end
    elseif currentLevel.id == "huangshan" then
        if player.craneCooldown > 0 then player.craneCooldown = player.craneCooldown - 1 end
        if player.ridingCrane then
            player.x = player.ridingCrane.x
            player.y = player.ridingCrane.y - 12
            player.vx, player.vy = 0, 0
            player.canDash = true
            if dashJustPressed or keys.space then
                local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
                local dy = (keys.s and 1 or 0) - (keys.w and 1 or 0)
                if dx == 0 and dy == 0 then dx = player.facingRight and 1 or -1 end
                local d = dist2(dx, dy)
                player.ridingCrane = nil
                boostFluidTrail(26)
                player.isDashing = true
                player.canDash = false
                player.dashTime = 12
                player.dashDirX, player.dashDirY = dx / d, dy / d
                player.craneCooldown = 40
                keys.space = false
                dashJustPressed = false
            end
            return
        elseif player.craneCooldown == 0 and not player.isDashing then
            for _, c in ipairs(cranes) do
                if dist2(player.x - c.x, player.y - c.y) < player.radius + 36 then
                    player.ridingCrane = c
                    break
                end
            end
        end
        for _, cp in ipairs(cloudPlatforms) do
            local cy = cp.y + math.sin(elapsed * 1.2 + cp.bob) * 8
            if math.abs(player.x - cp.x) < cp.rx and math.abs((player.y + player.radius) - cy) < cp.ry * 0.75 and player.vy >= 0 then
                player.y = cy - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
            end
        end
    end
end

local function updateEavesMechanics()
    if currentLevel.id ~= "eaves" then return false end
    if player.y > H(0.84) then
        player.vy = -7.6
        player.vx = -4.5
        player.onEaves = nil
        addTrail(player.x, player.y, player.radius * 2, 0.20, 50, "gold")
    end
    if player.onEaves then
        local r = player.onEaves
        player.isGrounded = true
        player.canDash = true
        local slopeY = r.y2 - r.y1
        local slideDir = r.x2 > r.x1 and 1 or -1
        player.eavesSpeed = (player.eavesSpeed + slideDir * slopeY * 0.00065) * 0.985
        if keys.a then player.eavesSpeed = player.eavesSpeed - 0.18 end
        if keys.d then player.eavesSpeed = player.eavesSpeed + 0.18 end
        player.eavesT = player.eavesT + player.eavesSpeed * 0.0022
        if player.eavesT < 0 then player.eavesT, player.eavesSpeed = 0, -player.eavesSpeed * 0.2 end
        local t = player.eavesT
        if t >= 1 then
            t = 1
            local dx = 2 * (1 - t) * (r.cp.x - r.x1) + 2 * t * (r.x2 - r.cp.x)
            local dy = 2 * (1 - t) * (r.cp.y - r.y1) + 2 * t * (r.y2 - r.cp.y)
            local len = dist2(dx, dy)
            local finalSpd = math.max(9.5, math.abs(player.eavesSpeed) * 1.4)
            player.x = qbez(r.x1, r.cp.x, r.x2, t)
            player.y = qbez(r.y1, r.cp.y, r.y2, t) - player.radius - 5
            player.vx = (dx / len) * finalSpd
            player.vy = (dy / len) * finalSpd - 8.5
            player.onEaves = nil
            for i = 1, 16 do addBristle(player.x, player.y, player.vx, player.vy, "gold") end
        else
            player.x = qbez(r.x1, r.cp.x, r.x2, t)
            player.y = qbez(r.y1, r.cp.y, r.y2, t) - player.radius - 5
            player.vx, player.vy = 0, 0
            if math.abs(player.eavesSpeed) > 1.2 and hash01(elapsed * 90 + player.x) > 0.4 then
                addTrail(player.x, player.y, player.radius * 1.5, 0.25, 40, "gold")
                addBristle(player.x, player.y + player.radius, player.eavesSpeed * slideDir, 2, "gold")
            end
            if keys.space then
                player.onEaves = nil
                player.vy = player.jumpForce - 2
                player.vx = player.eavesSpeed * slideDir * 1.2
                keys.space = false
            end
        end
        return true
    end
    return false
end


-- ============================================================================
-- END scripts/src/40_gameplay_targets.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/50_simulation_update.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function fixedStep()
    elapsed = elapsed + FIXED_DT
    applyStaticBranchBend()

    for _, g in ipairs(gears) do g.angle = g.angle + g.speed end
    for _, ch in ipairs(chimes) do
        ch.pulse = ch.pulse + 0.04
        ch.swayAngle = math.sin(ch.pulse) * 0.08
    end
    for _, c in ipairs(cranes) do
        c.x = c.x + c.speed
        c.theta = c.theta + 0.03
        c.y = c.startY + math.sin(c.theta) * c.amplitude
        c.wingAngle = math.sin(c.theta * 3.5) * (math.pi / 4)
        if c.x > worldW + 100 then
            c.x = -100
            c.startY = H(0.2 + hash01(elapsed + c.speed) * 0.4)
        end
    end
    for _, leaf in ipairs(glidingLeaves) do
        leaf.x = leaf.x + leaf.speed
        leaf.y = leaf.y + math.sin(elapsed * 1.2 + leaf.bob) * (leaf.platform and 0.06 or 0.18)
        if leaf.platform then
            leaf.squash = math.max(0, (leaf.squash or 0) - 0.08)
            if leaf.x > worldW + 50 then
                leaf.x = -50
                leaf.y = H(0.64 + hash01(elapsed + leaf.size) * 0.26)
            end
        elseif leaf.x > worldW + 50 then
            leaf.x = -50
            leaf.y = hash01(elapsed + leaf.size) * worldH * 0.5
        end
    end
    for _, p in ipairs(floatingPetals) do
        p.x = p.x + p.speed
        p.bob = p.bob + 0.02
        if p.x > worldW + 80 then
            p.x = -80
            p.y = waterLevel + (hash01(elapsed + p.speed) - 0.5) * 15
        end
    end

    if dashJustPressed then startDash() end

    local prevX, prevY = player.x, player.y
    updateSpecialBeforeMovement()
    if updateEavesMechanics() then
        updateFluidTrailFromPlayer(prevX, prevY)
        updateTargets()
        return
    end
    if player.swingRope or player.ridingCrane then
        updateFluidTrailFromPlayer(prevX, prevY)
        updateTargets()
        return
    end

    if player.isDashing then
        player.dashTime = player.dashTime - 1
        local dashBoost = player.waterfallDashBoost or 0
        player.vx = player.dashDirX * (player.dashSpeed + dashBoost)
        player.vy = player.dashDirY * (player.dashSpeed + dashBoost)
        if player.dashTime <= 0 then
            player.isDashing = false
            player.waterfallDashBoost = 0
            player.vx = player.vx * 0.5
        end
    else
        if player.isGliding then
            player.gravity = 0.08
            player.vy = math.min(player.vy, 1.8)
            if keys.a then player.vx = player.vx - 0.6; player.facingRight = false end
            if keys.d then player.vx = player.vx + 0.6; player.facingRight = true end
            if hash01(elapsed * 99) > 0.4 then addTrail(player.x, player.y, player.radius * 1.5, 0.35, 60, "red") end
        else
            player.gravity = player.gravityDefault
            if keys.a then player.vx = player.vx - player.speed; player.facingRight = false end
            if keys.d then player.vx = player.vx + player.speed; player.facingRight = true end
        end

        if keys.space then
            if player.isGrounded then
                local extraJump = 0
                if currentLevel.id == "maple" then
                    for _, b in ipairs(branches) do
                        if dist2(player.x - b.x, player.y - b.y) < b.r + player.radius + 5 and branchMetadata[b.branchId] then
                            local meta = branchMetadata[b.branchId]
                            extraJump = meta.bend * b.t * b.t * meta.bounceFactor
                            meta.springVel = -meta.springBackForce * 1.25
                            break
                        end
                    end
                end
                player.vy = player.jumpForce - extraJump
                player.isGrounded = false
            elseif player.isWallClinging then
                player.vy = player.jumpForce * (currentLevel.id == "bamboo" and 1.05 or 0.95)
                player.vx = -player.wallSide * (currentLevel.id == "bamboo" and 14 or 11.5)
                player.canDash = true
                player.isWallClinging = false
                for i = 1, 8 do addBristle(player.x, player.y, -player.vx, -player.vy, currentLevel.id) end
            end
            keys.space = false
        end

        if player.isWallClinging then
            player.vy = math.min(player.vy, currentLevel.id == "bamboo" and 2.5 or 1.8)
        else
            player.vy = player.vy + player.gravity
        end
        player.vx = player.vx * player.friction
    end

    player.x = player.x + player.vx
    player.y = player.y + player.vy

    if player.isDashing then
        local mx, my = player.x - prevX, player.y - prevY
        local steps = math.max(math.ceil(dist2(mx, my) / 6), 1)
        boostFluidTrail(4)
        for i = 0, steps do
            local t = i / steps
            if hash01(elapsed * 80 + i) > 0.82 then addBristle(prevX + mx * t, prevY + my * t, player.vx, player.vy, "inkgas") end
        end
    end

    if currentLevel.id == "bamboo" then
        bambooCollision()
    elseif currentLevel.id == "ldtk_grand_scroll" then
        ldtkGrandScrollCollision(prevX, prevY)
    else
        circleBranchCollision()
    end
    if currentLevel.id == "maple" then mapleLeafPlatformCollision() end
    updateBloomSpringInteractions()

    if currentLevel.id == "peach" and player.vy >= 0 then
        for _, p in ipairs(floatingPetals) do
            local y = p.y + math.sin(p.bob) * 4
            if math.abs(player.x - p.x) < p.w * 0.5 + player.radius and player.y - y < 0 and player.y - y > -p.h - player.radius then
                player.y = y - player.radius - 2
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
            end
        end
    elseif currentLevel.id == "eaves" then
        if not player.onEaves and not player.isDashing and player.vy >= 0 then
            for _, r in ipairs(roofs) do
                for _, p in ipairs(r.points) do
                    if dist2(player.x - p.x, player.y - p.y) < player.radius + 15 then
                        player.onEaves = r
                        player.eavesT = p.t
                        player.eavesSpeed = math.abs(player.vx) * 0.5 + 1.2
                        break
                    end
                end
                if player.onEaves then break end
            end
        end
        for _, ch in ipairs(chimes) do
            if dist2(player.x - ch.x, player.y - (ch.y + 16)) < player.radius + 24 then
                player.vy = player.jumpForce * 1.05
                player.vx = player.vx + (player.x - ch.x) * 1.5
                player.canDash = true
                player.onEaves = nil
                ch.swayAngle = (player.vx > 0 and 1 or -1) * 0.25
                windWaves[#windWaves + 1] = { x = ch.x, y = ch.y + 16, r = 0, life = 42, maxLife = 42 }
            end
        end
        if not player.onEaves and not player.isDashing then
            for _, gear in ipairs(gears) do
                local d = dist2(player.x - gear.x, player.y - gear.y)
                if d < gear.radius + player.radius + gear.teethHeight and d > gear.radius - 30 then
                    player.isGrounded = true
                    player.canDash = true
                    local a = math.atan2(player.y - gear.y, player.x - gear.x) + gear.speed
                    player.x = gear.x + math.cos(a) * (gear.radius + player.radius - 2)
                    player.y = gear.y + math.sin(a) * (gear.radius + player.radius - 2)
                    player.vx, player.vy = 0, 0
                    if keys.space then
                        player.vx = -math.sin(a) * gear.speed * gear.radius * 12 + (keys.d and 4 or -4)
                        player.vy = player.jumpForce
                        player.isGrounded = false
                        keys.space = false
                    end
                    break
                end
            end
        end
    end

    if player.y > worldH + 100 then
        resetPlayer()
        prevX, prevY = player.x, player.y
    end
    player.x = clamp(player.x, -120, worldW + 120)
    updateFluidTrailFromPlayer(prevX, prevY)
    updateTargets()
    player.isGliding = false
end

local function updateParticles()
    if fluidTrailEnhancedFrames > 0 then
        fluidTrailEnhancedFrames = fluidTrailEnhancedFrames - 1
    end
    if fluidTrailRecentMoveFrames > 0 then
        fluidTrailRecentMoveFrames = fluidTrailRecentMoveFrames - 1
    elseif #dashFluidPoints > 1 then
        reflowFluidTrailToPlayer()
    end
    for i = #dashFluidDroplets, 1, -1 do
        local d = dashFluidDroplets[i]
        d.x = d.x + d.vx
        d.y = d.y + d.vy
        d.vy = d.vy + 0.06
        d.vx = d.vx * 0.96
        d.life = d.life - d.decay
        if d.life <= 0 or d.radius * math.max(0, d.life) <= 0.1 then table.remove(dashFluidDroplets, i) end
    end
    for i = #trailParticles, 1, -1 do
        local p = trailParticles[i]
        p.life = p.life - 1
        if p.life <= 0 then table.remove(trailParticles, i) end
    end
    for i = #bristleParticles, 1, -1 do
        local p = bristleParticles[i]
        p.life = p.life - 1
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.vx = p.vx * 0.98
        p.vy = p.vy + 0.12
        if p.life <= 0 then table.remove(bristleParticles, i) end
    end
    for _, b in ipairs(blooms) do
        b.progress = math.min(1, b.progress + 0.08)
        local t = b.progress
        b.scale = 1 + 1.5 * (t - 1) ^ 3 + 0.5 * (t - 1) ^ 2
        b.springPulse = math.max(0, (b.springPulse or 0) - 0.08)
        if b.springCooldown and b.springCooldown > 0 then b.springCooldown = b.springCooldown - 1 end
    end
    for i = #windWaves, 1, -1 do
        local w = windWaves[i]
        w.life = w.life - 1
        w.r = w.r + 5
        if w.life <= 0 then table.remove(windWaves, i) end
    end
end


-- ============================================================================
-- END scripts/src/50_simulation_update.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/60_background_render.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function updateCamera()
    local targetX = player.x - DESIGN_W * 0.5
    local targetY = player.y - DESIGN_H * 0.5
    cameraX = cameraX + (targetX - cameraX) * 0.10
    cameraY = cameraY + (targetY - cameraY) * 0.10
    cameraX = clamp(cameraX, 0, math.max(0, worldW - DESIGN_W))
    cameraY = clamp(cameraY, 0, math.max(0, worldH - DESIGN_H))
end

local function drawPaper()
    drawRect(0, 0, worldW, worldH, 0, colorRGB(currentLevel.paper))
    -- plum_parallax 关卡使用深色天空底色，跳过纸纹装饰以避免干扰视差层
    if currentLevel.parallaxLayers then return end
    for x = -worldH, worldW, 42 do
        strokeLine(x, 0, x + worldH, worldH, 1, colorRGBA(currentLevel.paper2, 38))
    end
    for i = 1, 56 do
        local x = hash01(i * 3.7) * worldW
        local y = hash01(i * 5.1) * worldH
        drawEllipse(x, y, 90 + hash01(i * 7.3) * 240, 16 + hash01(i * 11.5) * 54, colorRGBA(currentLevel.paper2, 18 + hash01(i) * 24))
    end
    for i = 1, 130 do
        local x = hash01(i * 13.1) * worldW
        local y = hash01(i * 17.9) * worldH
        local len = 12 + hash01(i * 19.3) * 44
        local a = -0.55 + (hash01(i * 23.7) - 0.5) * 0.35
        strokeLine(x, y, x + math.cos(a) * len, y + math.sin(a) * len, 0.6, colorRGBA(currentLevel.paper2, 14 + hash01(i * 29.1) * 20))
    end
end

local function tryLoadMasterPlumImage()
    if masterPlumImageTried or vg == nil then return end
    masterPlumImageTried = true
    if type(nvgCreateImage) ~= "function" then return end
    local candidates = {
        "assets/reference/wang_mian_fragrant_snow_met.jpg",
        "reference/wang_mian_fragrant_snow_met.jpg",
        "wang_mian_fragrant_snow_met.jpg",
    }
    for _, path in ipairs(candidates) do
        local ok, img = pcall(nvgCreateImage, vg, path, 0)
        if ok and img and img > 0 then
            masterPlumImage = img
            print("Loaded Wang Mian plum reference image: " .. path)
            return
        end
    end
end

local function drawMasterPlumReferenceImage()
    tryLoadMasterPlumImage()
    if not masterPlumImage or type(nvgImagePattern) ~= "function" or type(nvgFillPaint) ~= "function" then return false end
    local scale = math.min(worldW / MASTER_PLUM_IMAGE_W, worldH / MASTER_PLUM_IMAGE_H)
    local w = MASTER_PLUM_IMAGE_W * scale
    local h = MASTER_PLUM_IMAGE_H * scale
    local x = (worldW - w) * 0.5
    local y = (worldH - h) * 0.5
    masterPlumDrawX, masterPlumDrawY, masterPlumDrawW, masterPlumDrawH = x, y, w, h
    local ok, paint = pcall(nvgImagePattern, vg, x, y, w, h, 0, masterPlumImage, 1.0)
    if not ok or not paint then return false end
    nvgBeginPath(vg)
    nvgRect(vg, x, y, w, h)
    nvgFillPaint(vg, paint)
    nvgFill(vg)
    return true
end

local function drawMountainBand(seed, count, tint, alphaBase, heightBase, heightVar)
    for i = 0, count - 1 do
        local xStart = (i * (0.18 + hash01(seed + i) * 0.04)) * worldW - 260
        local mWidth = worldW * (0.42 + hash01(seed + i * 3) * 0.10)
        local mHeight = worldH * (heightBase + hash01(seed + i * 5) * heightVar)
        local peakY = worldH - mHeight
        local a = alphaBase + i * 9
        fillPoly({
            { xStart, worldH },
            { xStart + mWidth * 0.30, worldH - mHeight * (0.38 + hash01(seed + i * 7) * 0.12) },
            { xStart + mWidth * 0.52, peakY },
            { xStart + mWidth * 0.76, worldH - mHeight * (0.18 + hash01(seed + i * 11) * 0.12) },
            { xStart + mWidth, worldH },
        }, colorRGBA(tint, a))
    end
end

local function drawMountainBandAt(seed, count, tint, alphaBase, heightBase, heightVar, stepMul, widthMul, xOffset)
    local step = stepMul or 0.20
    local width = widthMul or 0.48
    local offset = xOffset or -300
    for i = 0, count - 1 do
        local xStart = i * step * worldW + offset
        local mWidth = worldW * width
        local mHeight = worldH * (heightBase + hash01(seed + i * 17) * heightVar)
        local peakY = worldH - mHeight
        local points = { { xStart, worldH } }
        points[#points + 1] = { xStart + mWidth * 0.30, worldH - mHeight * 0.42 }
        for s = 0, 8 do
            local t = s / 8
            local it = 1 - t
            local px = it * it * (xStart + mWidth * 0.30) + 2 * it * t * (xStart + mWidth * 0.50) + t * t * (xStart + mWidth * 0.75)
            local py = it * it * (worldH - mHeight * 0.42) + 2 * it * t * peakY + t * t * (worldH - mHeight * 0.22)
            points[#points + 1] = { px, py }
        end
        points[#points + 1] = { xStart + mWidth, worldH }
        fillPoly(points, colorRGBA(tint, alphaBase + i * 3.6))
    end
end

local function drawVerticalWash(y, h, tintTop, tintBottom, alphaTop, alphaBottom, bands)
    local n = bands or 18
    for i = 0, n - 1 do
        local t = i / math.max(1, n - 1)
        local r = tintTop[1] * (1 - t) + tintBottom[1] * t
        local g = tintTop[2] * (1 - t) + tintBottom[2] * t
        local b = tintTop[3] * (1 - t) + tintBottom[3] * t
        local a = alphaTop * (1 - t) + alphaBottom * t
        drawRect(0, y + h * t, worldW, h / n + 2, 0, rgba(r, g, b, a))
    end
end

local function drawMist(seed, count, tint, alpha)
    for i = 1, count do
        local cx = hash01(seed + i * 13) * worldW
        local cy = worldH * (0.08 + hash01(seed + i * 17) * 0.62)
        local rx = 150 + hash01(seed + i * 19) * 300
        local ry = 20 + hash01(seed + i * 23) * 55
        drawRotEllipse(cx, cy, rx, ry, (hash01(seed + i * 29) - 0.5) * 0.20, colorRGBA(tint, alpha + hash01(seed + i * 31) * alpha))
    end
end

local function drawMistBand(seed, count, tint, alpha, yMin, yMax, rxMin, rxMax, ryMin, ryMax)
    for i = 1, count do
        local cx = hash01(seed + i * 13) * worldW
        local cy = H(yMin + hash01(seed + i * 17) * (yMax - yMin))
        local rx = rxMin + hash01(seed + i * 19) * (rxMax - rxMin)
        local ry = ryMin + hash01(seed + i * 23) * (ryMax - ryMin)
        drawRotEllipse(cx, cy, rx, ry, (hash01(seed + i * 29) - 0.5) * 0.20, colorRGBA(tint, alpha + hash01(seed + i * 31) * alpha))
    end
end

local function drawInkBleed(x, y, rx, ry, tint, alpha, seed, layers)
    local count = layers or 4
    for i = 1, count do
        local s = seed + i * 23
        local ox = (hash01(s) - 0.5) * rx * 0.34
        local oy = (hash01(s + 3) - 0.5) * ry * 0.34
        local sx = rx * (0.72 + hash01(s + 7) * 0.48)
        local sy = ry * (0.58 + hash01(s + 11) * 0.55)
        drawRotEllipse(x + ox, y + oy, sx, sy, (hash01(s + 17) - 0.5) * 0.7, colorRGBA(tint, alpha * (0.35 + hash01(s + 19) * 0.65)))
    end
end

local function drawInkSpeckles(x, y, w, h, tint, alpha, seed, count)
    for i = 1, count do
        local s = seed + i * 37
        local px = x + hash01(s) * w
        local py = y + hash01(s + 5) * h
        local r = 1.2 + hash01(s + 9) * 4.5
        drawRotEllipse(px, py, r, r * (0.45 + hash01(s + 13) * 0.50), hash01(s + 17) * math.pi, colorRGBA(tint, alpha * (0.35 + hash01(s + 21) * 0.75)))
    end
end

local function drawDryBrushLine(x1, y1, x2, y2, width, tint, alpha, seed, passes)
    local dx, dy = x2 - x1, y2 - y1
    local len = dist2(dx, dy)
    if len < 0.001 then return end
    local nx, ny = -dy / len, dx / len
    local tx, ty = dx / len, dy / len
    local count = passes or 3
    for p = 1, count do
        local s = seed + p * 41
        local off = (hash01(s) - 0.5) * width * 0.95
        local pull1 = (hash01(s + 5) - 0.5) * width * 0.45
        local pull2 = (hash01(s + 9) - 0.5) * width * 0.45
        strokeLine(
            x1 + nx * off + tx * pull1, y1 + ny * off + ty * pull1,
            x2 + nx * (off + (hash01(s + 13) - 0.5) * width * 0.28) + tx * pull2,
            y2 + ny * (off + (hash01(s + 17) - 0.5) * width * 0.28) + ty * pull2,
            math.max(0.7, width * (0.18 + hash01(s + 21) * 0.38)),
            colorRGBA(tint, alpha * (0.42 + hash01(s + 25) * 0.58))
        )
    end
    local bristles = math.max(2, math.floor(len / 85))
    for i = 1, bristles do
        local s = seed + i * 59
        local t = hash01(s)
        local cx = x1 + dx * t
        local cy = y1 + dy * t
        local side = hash01(s + 3) > 0.5 and 1 or -1
        local blen = width * (0.8 + hash01(s + 7) * 1.8)
        strokeLine(cx, cy, cx + nx * side * blen + tx * (hash01(s + 11) - 0.5) * width, cy + ny * side * blen + ty * (hash01(s + 15) - 0.5) * width, 0.8, colorRGBA(tint, alpha * 0.34))
    end
end

local function drawInkContour(points, tint, alpha, width, seed)
    for i = 1, #points do
        local a = points[i]
        local b = points[(i % #points) + 1]
        drawDryBrushLine(a[1], a[2], b[1], b[2], width, tint, alpha, seed + i * 71, 2)
    end
end

local function fillBrushRibbon(list, tint, alpha, seed)
    if #list < 2 then return end
    nvgBeginPath(vg)
    for i = 1, #list do
        local n = list[i]
        local rough = 1 + (hash01(seed + i * 13) - 0.5) * 0.18
        local side = n.r * rough
        local x = n.x + n.normX * side
        local y = n.y + n.normY * side
        if i == 1 then nvgMoveTo(vg, x, y) else nvgLineTo(vg, x, y) end
    end
    for i = #list, 1, -1 do
        local n = list[i]
        local rough = 1 + (hash01(seed + i * 17) - 0.5) * 0.20
        local side = n.r * rough
        nvgLineTo(vg, n.x - n.normX * side, n.y - n.normY * side)
    end
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)

    local step = math.max(7, math.floor(#list / 16))
    for i = 2, #list - 1, step do
        local n = list[i]
        drawInkBleed(n.x, n.y, n.r * 1.7, n.r * 0.85, tint, 24, seed + i * 29, 3)
    end
    for i = 4, #list - 2, step + 2 do
        local n1 = list[i]
        local n2 = list[math.min(#list, i + 3)]
        drawDryBrushLine(n1.x - n1.normX * n1.r * 0.18, n1.y - n1.normY * n1.r * 0.18, n2.x - n2.normX * n2.r * 0.12, n2.y - n2.normY * n2.r * 0.12, 1.0, currentLevel.paper, 42, seed + i * 43, 1)
    end
end

local function drawRockShape(x, y, w, h, fillColor, strokeColor)
    local points = {
        { x, y + h },
        { x + w * 0.10, y + h * 0.40 },
        { x + w * 0.30, y + h * 0.10 },
        { x + w * 0.50, y + h * 0.20 },
        { x + w * 0.70, y },
        { x + w * 0.85, y + h * 0.30 },
        { x + w, y + h },
    }
    fillPoly(points, fillColor)
    drawInkBleed(x + w * 0.45, y + h * 0.55, w * 0.42, h * 0.28, currentLevel.ink, 34, x * 0.017 + y * 0.013, 5)
    nvgBeginPath(vg)
    nvgMoveTo(vg, points[1][1], points[1][2])
    for i = 2, #points do nvgLineTo(vg, points[i][1], points[i][2]) end
    nvgClosePath(vg)
    nvgStrokeColor(vg, strokeColor)
    nvgStrokeWidth(vg, 4)
    nvgStroke(vg)
    for i = 1, 16 do
        local rx = x + hash01(x * 0.01 + i * 7) * w
        local ry = y + hash01(y * 0.01 + i * 11) * h
        strokeLine(rx, ry, rx + (hash01(i * 17) - 0.5) * w * 0.30, ry + hash01(i * 19) * h * 0.30, 2, rgba(10, 8, 5, 65))
    end
    drawInkContour(points, currentLevel.ink, 150, 4.5, x * 0.021 + y * 0.019)
    drawInkSpeckles(x + w * 0.05, y + h * 0.08, w * 0.88, h * 0.80, currentLevel.ink, 120, x * 0.009 + y * 0.011, 42)
    for i = 1, 24 do
        drawRotEllipse(x + hash01(i * 23 + w) * w, y + hash01(i * 29 + h) * h * 0.8, 2 + hash01(i * 31) * 5, 1.5 + hash01(i * 37) * 3, hash01(i) * math.pi, rgba(15, 12, 10, 160))
    end
end

local function strokeWavyStream(x1, y1, x2, y2, offset, waveAmp, waveFreq, width, color)
    nvgBeginPath(vg)
    for i = 0, 44 do
        local t = i / 44
        local x = x1 + (x2 - x1) * t
        local y = y1 + (y2 - y1) * t + math.sin(t * waveFreq + offset * 0.18) * waveAmp + offset
        if i == 0 then nvgMoveTo(vg, x, y) else nvgLineTo(vg, x, y) end
    end
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function drawCascadeSpringWash(x1, y1, x2, y2, width)
    strokeWavyStream(x1, y1, x2, y2, -width * 0.5, 8, 15, 4.0, rgba(35, 45, 40, 76))
    strokeWavyStream(x1, y1, x2, y2, width * 0.5, 8, 15, 4.0, rgba(35, 45, 40, 76))
    for _, off in ipairs({ -18, -10, -3, 4, 12, 20 }) do
        strokeWavyStream(x1, y1, x2, y2, off, 6, 15, 1.7, rgba(255, 255, 255, 190))
    end
    for i = 1, 16 do
        local t = hash01(i * 27)
        local x = x1 + (x2 - x1) * t + (hash01(i * 31) - 0.5) * width
        local y = y1 + (y2 - y1) * t + math.sin(t * 15) * 10
        drawRotEllipse(x, y, 18 + hash01(i * 37) * 32, 4 + hash01(i * 41) * 8, -0.35, rgba(244, 246, 236, 62))
    end
end

local function drawWaterfallWash()
    local x, w = W(0.36), W(0.28)
    drawRect(x - 170, H(0.02), w + 340, H(0.90), 0, rgba(248, 252, 248, 70))
    strokeLine(x - 104, H(0.04), x - 140, H(0.92), 2.0, rgba(220, 232, 224, 96))
    strokeLine(x + w + 104, H(0.03), x + w + 132, H(0.90), 2.0, rgba(220, 232, 224, 88))
    for i = 1, 72 do
        local px = x - 58 + hash01(i * 14) * (w + 116)
        local yy = H(0.03) + ((elapsed * 188 + i * 37) % H(0.98))
        strokeLine(px, yy - 188, px + math.sin(elapsed * 1.55 + i) * 24, yy + 218, 1.2 + hash01(i) * 3.7, rgba(236, 244, 236, 108))
    end
    for i = 0, 12 do
        local t = i / 12
        drawRect(x - 205, H(0.50) + H(0.50) * t, w + 410, H(0.50) / 12 + 4, 0, rgba(232, 238, 230, 12 + t * 112))
    end
    for i = 1, 24 do
        local px = x - 135 + hash01(330 + i * 13) * (w + 270)
        local py = H(0.03 + hash01(340 + i * 17) * 0.15)
        drawRotEllipse(px, py, 60 + hash01(350 + i) * 145, 10 + hash01(360 + i) * 30, (hash01(370 + i) - 0.5) * 0.25, rgba(248, 252, 248, 40 + hash01(380 + i) * 56))
    end
    drawMistBand(316, 34, currentLevel.paper, 32, 0.45, 0.98, 160, 470, 18, 88)
end

local function drawAxCutCliff(baseX, baseY, topX, topY, dir)
    fillPoly({
        { baseX - dir * 300, baseY },
        { baseX, baseY },
        { topX, topY },
        { topX - dir * 300, topY },
    }, rgba(35, 42, 38, 232))
    for i = 0, 39 do
        local t = i / 39
        local edgeX = baseX + (topX - baseX) * t
        local edgeY = baseY + (topY - baseY) * t
        local len = 50 + hash01(400 + i * 7) * 150
        drawDryBrushLine(edgeX, edgeY, edgeX - dir * len * 0.7, edgeY + len, 2 + hash01(410 + i) * 6, C(10, 15, 12), 190, 410 + i * 13, 2)
        strokeLine(edgeX, edgeY, edgeX - dir * len * 0.9, edgeY + len * 0.8, 1 + hash01(430 + i) * 2, rgba(10, 15, 12, 75))
    end
    for i = 1, 36 do
        local t = hash01(470 + i * 7)
        local edgeX = baseX + (topX - baseX) * t
        local edgeY = baseY + (topY - baseY) * t
        local sx = edgeX - dir * (25 + hash01(480 + i) * 180)
        local sy = edgeY + hash01(490 + i) * 210
        drawRotEllipse(sx, sy, 8 + hash01(500 + i) * 32, 2 + hash01(510 + i) * 8, -dir * (0.65 + hash01(520 + i) * 0.35), rgba(7, 12, 9, 52 + hash01(530 + i) * 46))
    end
end

local function drawRaindropCliff(x, y, w, h, facingLeft, fillColor)
    local dir = facingLeft and -1 or 1
    local points = {
        { x, y + h },
        { x + (facingLeft and w * 0.10 or w * 0.90), y + h * 0.60 },
        { x + (facingLeft and w * 0.30 or w * 0.70), y + h * 0.35 },
        { x + (facingLeft and w * 0.15 or w * 0.85), y + h * 0.15 },
        { x + (facingLeft and 0 or w), y },
        { x + (facingLeft and -100 or w + 100), y },
        { x + (facingLeft and -100 or w + 100), y + h },
    }
    fillPoly(points, fillColor)
    drawInkSpeckles(x + w * 0.05, y + h * 0.05, w * 0.82, h * 0.82, C(12, 18, 14), 54, x * 0.011 + y * 0.019, 34)
    nvgBeginPath(vg)
    nvgMoveTo(vg, points[1][1], points[1][2])
    for i = 2, #points do nvgLineTo(vg, points[i][1], points[i][2]) end
    nvgClosePath(vg)
    nvgStrokeColor(vg, rgba(10, 12, 10, 225))
    nvgStrokeWidth(vg, 5)
    nvgStroke(vg)
    for i = 1, 70 do
        local rx = x + hash01(i * 11 + w) * w
        local ry = y + hash01(i * 13 + h) * h
        local len = 10 + hash01(i * 17) * 40
        drawDryBrushLine(rx, ry, rx + (hash01(i * 19) - 0.5) * 3, ry + len, 1.5, C(8, 10, 8), 94, i * 31 + w, 1)
    end
    drawInkContour(points, C(10, 12, 10), 152, 4.0, x * 0.017 + y * 0.013)
    drawInkSpeckles(x, y, w, h * 0.9, C(10, 12, 10), 130, x * 0.007 + h * 0.01, 46)
    for i = 1, 28 do
        drawRotEllipse(x + hash01(i * 23) * w, y + hash01(i * 29) * h * 0.9, 2 + hash01(i * 31) * 5, 1.5 + hash01(i * 37) * 3, hash01(i) * math.pi, rgba(10, 12, 10, 170))
    end
end

local function drawSpires(x, y, w, h, facingLeft)
    drawRaindropCliff(x, y, w, h, facingLeft, rgba(42, 48, 44, 215))
    local sign = facingLeft and -1 or 1
    for i = 1, 36 do
        local rx = x + hash01(i * 43 + w) * w
        local ry = y + hash01(i * 47 + h) * h
        local len = 15 + hash01(i * 53) * 45
        strokeLine(rx, ry, rx + sign * len, ry, 1.8, rgba(10, 15, 12, 85))
        strokeLine(rx + sign * len, ry, rx + sign * len * 1.2, ry + hash01(i * 59) * 20, 1.8, rgba(10, 15, 12, 70))
    end
end

local function drawAutumnLeaf(x, y, s, color)
    fillPoly({
        { x, y - s }, { x + s * 0.45, y - s * 0.25 }, { x + s, y },
        { x + s * 0.22, y + s * 0.18 }, { x + s * 0.12, y + s },
        { x - s * 0.25, y + s * 0.28 }, { x - s, y + s * 0.10 },
        { x - s * 0.34, y - s * 0.18 },
    }, color)
    strokeLine(x - s * 0.10, y - s * 0.50, x + s * 0.08, y + s * 0.72, 1.0, rgba(86, 24, 18, 85))
end

local function drawSpringWater()
    drawVerticalWash(waterLevel - H(0.06), worldH - waterLevel + H(0.06), C(206, 221, 202), currentLevel.water, 34, 96, 18)
    for i = 1, 30 do
        local y = waterLevel + i * 12
        local off = math.sin(elapsed * 1.8 + i) * 3
        strokeLine(W(0.02), y + off, W(0.98), y + off, i % 4 == 0 and 2.0 or 1.0, colorRGBA(currentLevel.water, 48 + (i % 4) * 10))
    end
    for i = 1, 42 do
        local x = (hash01(i * 42) * worldW + elapsed * (12 + i % 6)) % worldW
        local y = waterLevel + hash01(i * 77) * 58 - 18
        nvgBeginPath(vg)
        nvgEllipse(vg, x, y, 22 + hash01(i * 17) * 46, 3 + hash01(i * 9) * 7)
        nvgStrokeColor(vg, rgba(242, 236, 218, 64))
        nvgStrokeWidth(vg, 1.3)
        nvgStroke(vg)
    end
    for i = 1, 38 do
        local x = hash01(i * 101) * worldW
        local y = H(0.14) + hash01(i * 103) * H(0.46)
        strokeLine(x, y, x + 24 + hash01(i * 107) * 60, y + 5 + hash01(i * 109) * 18, 0.9, rgba(245, 239, 220, 62))
    end
end

local function drawCloudSea()
    drawVerticalWash(H(0.52), H(0.48), C(235, 240, 232), C(245, 248, 244), 18, 92, 18)
    for i = 1, 38 do
        local x = hash01(1500 + i * 11) * worldW
        local y = H(0.55 + hash01(1500 + i * 13) * 0.32)
        local rx = 170 + hash01(1500 + i * 17) * 360
        local ry = 26 + hash01(1500 + i * 19) * 72
        drawRotEllipse(x, y, rx, ry, (hash01(1500 + i * 23) - 0.5) * 0.16, rgba(244, 248, 244, 96 + hash01(i) * 70))
    end
    for i = 1, 20 do
        local y = H(0.60 + i * 0.015)
        strokeLine(0, y + math.sin(elapsed + i) * 2, worldW, y + math.sin(elapsed + i) * 2, 1.0, rgba(190, 207, 198, 28))
    end
end

local function drawMasterPlumTexture(x, y, w, h, seed, count, alpha)
    for i = 1, count do
        local s = seed + i * 17
        local px = x + hash01(s) * w
        local py = y + hash01(s + 3) * h
        local len = 8 + hash01(s + 7) * 24
        drawDryBrushLine(px, py, px + (hash01(s + 11) - 0.5) * 8, py + len, 1.0 + hash01(s + 13) * 1.8, currentLevel.ink, alpha * (0.45 + hash01(s + 19) * 0.65), s, 1)
    end
end

local function drawMasterPlumProceduralBackground()
    drawVerticalWash(0, worldH, C(224, 218, 200), C(188, 178, 154), 56, 78, 34)
    drawMistBand(1880, 18, C(232, 225, 207), 24, 0.12, 0.92, 80, 260, 24, 92)
    drawMasterPlumTexture(W(0.04), H(0.06), W(0.88), H(0.88), 1900, 130, 56)
    strokeQuad(W(0.08), H(0.82), W(0.40), H(0.62), W(0.88), H(0.48), 42, rgba(32, 26, 22, 118))
    strokeQuad(W(0.28), H(0.76), W(0.10), H(0.54), W(0.08), H(0.36), 18, rgba(32, 26, 22, 92))
    strokeQuad(W(0.50), H(0.68), W(0.68), H(0.45), W(0.75), H(0.28), 14, rgba(32, 26, 22, 86))
end

local function drawMasterPlumBackground()
    local hasImage = drawMasterPlumReferenceImage()
    if hasImage then
        return
    end
    drawMasterPlumProceduralBackground()
end

-- ============================================================================
-- 多层视差背景系统 - 梅影重楼 (plum_parallax)
-- 参考风格: 深蓝夜色水墨 + 多层建筑剪影 + 流动云雾
-- ============================================================================
do -- parallax scope (避免顶层 local 变量超200限制)

local function parallaxOffset(factor)
    -- factor: 0=固定在屏幕(不随相机动), 1=完全跟随世界(正常)
    -- 当前已经在 camera transform 内, 所以需要补偿: offset = cameraX * (1 - factor)
    return cameraX * (1 - factor), cameraY * (1 - factor)
end

local function drawParallaxPagoda(cx, baseY, w, h, tint, alpha)
    -- 宝塔剪影: 多层飞檐逐级收窄
    local floors = 5
    local floorH = h / (floors + 1)
    local topW = w * 0.25
    -- 塔身
    for f = 0, floors - 1 do
        local t = f / floors
        local fw = w * (1 - t * 0.65) -- 逐级变窄
        local fy = baseY - f * floorH
        local eaveW = fw * 1.35  -- 飞檐比塔身宽
        -- 楼层主体
        drawRect(cx - fw * 0.5, fy - floorH, fw, floorH, 0, colorRGBA(tint, alpha))
        -- 飞檐
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - eaveW * 0.5, fy)
        nvgQuadTo(vg, cx - eaveW * 0.45, fy - floorH * 0.15, cx - fw * 0.5, fy - floorH * 0.05)
        nvgLineTo(vg, cx + fw * 0.5, fy - floorH * 0.05)
        nvgQuadTo(vg, cx + eaveW * 0.45, fy - floorH * 0.15, cx + eaveW * 0.5, fy)
        nvgClosePath(vg)
        nvgFillColor(vg, colorRGBA(tint, alpha))
        nvgFill(vg)
        -- 檐角上翘
        local tipY = fy - floorH * 0.12
        strokeLine(cx - eaveW * 0.5, fy, cx - eaveW * 0.55, tipY, 2.0, colorRGBA(tint, alpha))
        strokeLine(cx + eaveW * 0.5, fy, cx + eaveW * 0.55, tipY, 2.0, colorRGBA(tint, alpha))
    end
    -- 塔顶尖刹
    local spireBase = baseY - floors * floorH
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - topW * 0.15, spireBase)
    nvgLineTo(vg, cx, spireBase - floorH * 1.2)
    nvgLineTo(vg, cx + topW * 0.15, spireBase)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 宝珠
    drawEllipse(cx, spireBase - floorH * 1.35, topW * 0.2, topW * 0.2, colorRGBA(tint, alpha))
end

local function drawParallaxArch(cx, baseY, w, h, tint, alpha)
    -- 拱桥/拱门剪影
    local pillarW = w * 0.08
    local archH = h * 0.7
    -- 左右柱子
    drawRect(cx - w * 0.5, baseY - h, pillarW, h, 0, colorRGBA(tint, alpha))
    drawRect(cx + w * 0.5 - pillarW, baseY - h, pillarW, h, 0, colorRGBA(tint, alpha))
    -- 拱形顶
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - w * 0.5, baseY - archH)
    nvgBezierTo(vg, cx - w * 0.3, baseY - h - h * 0.15, cx + w * 0.3, baseY - h - h * 0.15, cx + w * 0.5, baseY - archH)
    nvgLineTo(vg, cx + w * 0.5, baseY - archH + pillarW)
    nvgBezierTo(vg, cx + w * 0.25, baseY - h - h * 0.05, cx - w * 0.25, baseY - h - h * 0.05, cx - w * 0.5, baseY - archH + pillarW)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 横梁
    drawRect(cx - w * 0.5, baseY - archH, w, pillarW * 0.6, 0, colorRGBA(tint, alpha))
end

local function drawParallaxPavilion(cx, baseY, w, h, tint, alpha)
    -- 亭台剪影: 两层飞檐 + 柱子
    local roofH = h * 0.35
    local bodyH = h * 0.45
    local topH = h * 0.2
    local roofW = w * 1.3
    local topRoofW = w * 0.7
    -- 柱子
    local pillarCount = 4
    for i = 0, pillarCount - 1 do
        local px = cx - w * 0.4 + i * (w * 0.8 / (pillarCount - 1))
        drawRect(px - 2, baseY - bodyH - roofH, 4, bodyH, 0, colorRGBA(tint, alpha))
    end
    -- 底层大屋顶
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - roofW * 0.5, baseY - bodyH)
    nvgQuadTo(vg, cx - roofW * 0.3, baseY - bodyH - roofH * 0.8, cx, baseY - bodyH - roofH)
    nvgQuadTo(vg, cx + roofW * 0.3, baseY - bodyH - roofH * 0.8, cx + roofW * 0.5, baseY - bodyH)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 上层小顶
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - topRoofW * 0.5, baseY - bodyH - roofH)
    nvgQuadTo(vg, cx - topRoofW * 0.25, baseY - bodyH - roofH - topH * 0.7, cx, baseY - bodyH - roofH - topH)
    nvgQuadTo(vg, cx + topRoofW * 0.25, baseY - bodyH - roofH - topH * 0.7, cx + topRoofW * 0.5, baseY - bodyH - roofH)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 飞檐角翘
    strokeLine(cx - roofW * 0.5, baseY - bodyH, cx - roofW * 0.55, baseY - bodyH - roofH * 0.2, 2, colorRGBA(tint, alpha))
    strokeLine(cx + roofW * 0.5, baseY - bodyH, cx + roofW * 0.55, baseY - bodyH - roofH * 0.2, 2, colorRGBA(tint, alpha))
end

local function drawParallaxBridge(x1, x2, y, tint, alpha)
    -- 石桥剪影
    local w = x2 - x1
    local railH = 18
    local deckH = 8
    -- 桥面
    drawRect(x1, y, w, deckH, 0, colorRGBA(tint, alpha))
    -- 栏杆
    drawRect(x1, y - railH, w, 3, 0, colorRGBA(tint, alpha))
    -- 栏杆柱
    local spacing = 30
    for x = x1, x2, spacing do
        drawRect(x, y - railH, 3, railH, 0, colorRGBA(tint, alpha))
    end
    -- 拱形桥洞
    local archCount = math.max(1, math.floor(w / 120))
    local archW = w / archCount
    for i = 0, archCount - 1 do
        local acx = x1 + archW * (i + 0.5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, acx - archW * 0.35, y + deckH)
        nvgBezierTo(vg, acx - archW * 0.2, y + deckH + 40, acx + archW * 0.2, y + deckH + 40, acx + archW * 0.35, y + deckH)
        nvgStrokeColor(vg, colorRGBA(tint, alpha))
        nvgStrokeWidth(vg, 3)
        nvgStroke(vg)
    end
end

local function drawParallaxStele(cx, baseY, w, h, tint, alpha)
    -- 碑石/石柱剪影
    -- 柱身
    drawRect(cx - w * 0.5, baseY - h, w, h, 0, colorRGBA(tint, alpha))
    -- 顶部装饰（圆球或尖顶）
    drawEllipse(cx, baseY - h - w * 0.3, w * 0.4, w * 0.4, colorRGBA(tint, alpha))
    -- 基座
    drawRect(cx - w * 0.7, baseY - h * 0.05, w * 1.4, h * 0.05, 0, colorRGBA(tint, alpha))
end

local function drawParallaxSwirlCloud(cx, cy, rx, ry, tint, alpha, seed)
    -- 水墨卷云纹
    drawRotEllipse(cx, cy, rx, ry, 0, colorRGBA(tint, alpha * 0.6))
    -- 卷曲尾巴
    local arms = 2 + math.floor(hash01(seed) * 2)
    for a = 1, arms do
        local angle = (a / arms) * math.pi * 2 + hash01(seed + a) * 1.5
        local spiralLen = rx * (0.8 + hash01(seed + a * 7) * 0.6)
        nvgBeginPath(vg)
        local steps = 12
        for s = 0, steps do
            local t = s / steps
            local r = rx * 0.3 + spiralLen * t
            local th = angle + t * 2.5 * (hash01(seed + a * 11) > 0.5 and 1 or -1)
            local px = cx + math.cos(th) * r
            local py = cy + math.sin(th) * r * (ry / rx)
            if s == 0 then nvgMoveTo(vg, px, py) else nvgLineTo(vg, px, py) end
        end
        nvgStrokeColor(vg, colorRGBA(tint, alpha * 0.5))
        nvgStrokeWidth(vg, 1.5 + hash01(seed + a * 13) * 1.5)
        nvgStroke(vg)
    end
end

local function drawParallaxLayer(layerIdx, factor, tint, alpha, seed)
    -- 计算视差偏移: 在已应用camera transform的上下文中，补偿偏移实现不同速度
    local offX, offY = parallaxOffset(factor)
    nvgSave(vg)
    nvgTranslate(vg, offX, offY * 0.3) -- Y轴视差弱一些，保持水平为主

    local layerW = worldW * 1.5  -- 层宽度大于世界宽度以覆盖视差范围
    local baseX = -worldW * 0.25 -- 起始偏左

    if layerIdx == 1 then
        -- 远景层: 淡淡的山峦轮廓 + 分散的卷云
        for i = 0, 7 do
            local mh = worldH * (0.15 + hash01(seed + i * 3) * 0.2)
            local mw = layerW * (0.18 + hash01(seed + i * 5) * 0.12)
            local mx = baseX + i * layerW * 0.13
            local my = worldH
            fillPoly({
                { mx, my }, { mx + mw * 0.2, my - mh * 0.5 },
                { mx + mw * 0.45, my - mh }, { mx + mw * 0.7, my - mh * 0.6 },
                { mx + mw, my },
            }, colorRGBA(tint, alpha * 0.5))
        end
        -- 远景卷云
        for i = 1, 12 do
            local cx = baseX + hash01(seed + 100 + i * 11) * layerW
            local cy = worldH * (0.15 + hash01(seed + 100 + i * 13) * 0.45)
            drawParallaxSwirlCloud(cx, cy, 60 + hash01(seed + 100 + i * 17) * 100, 20 + hash01(seed + 100 + i * 19) * 35, tint, alpha * 0.4, seed + i * 31)
        end

    elseif layerIdx == 2 then
        -- 中景层: 建筑剪影（宝塔、拱门、碑石）
        -- 左侧宝塔
        drawParallaxPagoda(baseX + layerW * 0.12, worldH * 0.95, 110, worldH * 0.55, tint, alpha)
        -- 中间拱桥
        drawParallaxBridge(baseX + layerW * 0.25, baseX + layerW * 0.42, worldH * 0.7, tint, alpha * 0.9)
        -- 右侧亭台
        drawParallaxPavilion(baseX + layerW * 0.55, worldH * 0.92, 140, worldH * 0.38, tint, alpha)
        -- 远处碑石群
        for i = 1, 4 do
            local sx = baseX + layerW * (0.65 + i * 0.08)
            local sh = worldH * (0.2 + hash01(seed + 200 + i * 7) * 0.25)
            drawParallaxStele(sx, worldH * 0.95, 22 + hash01(seed + 200 + i * 11) * 18, sh, tint, alpha * 0.85)
        end
        -- 中景云带
        for i = 1, 8 do
            local cx = baseX + hash01(seed + 250 + i * 7) * layerW
            local cy = worldH * (0.4 + hash01(seed + 250 + i * 9) * 0.3)
            drawRotEllipse(cx, cy, 120 + hash01(seed + 250 + i * 13) * 180, 18 + hash01(seed + 250 + i * 17) * 30, (hash01(seed + 250 + i * 19) - 0.5) * 0.2, colorRGBA(tint, alpha * 0.35))
        end

    elseif layerIdx == 3 then
        -- 近景层: 更大的建筑剪影，带细节
        -- 大型拱门群
        drawParallaxArch(baseX + layerW * 0.08, worldH, 160, worldH * 0.6, tint, alpha)
        drawParallaxArch(baseX + layerW * 0.22, worldH, 130, worldH * 0.5, tint, alpha * 0.9)
        -- 宏伟宝塔
        drawParallaxPagoda(baseX + layerW * 0.45, worldH, 150, worldH * 0.7, tint, alpha)
        -- 长桥连接
        drawParallaxBridge(baseX + layerW * 0.58, baseX + layerW * 0.78, worldH * 0.55, tint, alpha * 0.9)
        -- 右侧亭台群
        drawParallaxPavilion(baseX + layerW * 0.82, worldH * 0.9, 180, worldH * 0.45, tint, alpha)
        drawParallaxPavilion(baseX + layerW * 0.95, worldH, 120, worldH * 0.35, tint, alpha * 0.8)
        -- 碑石
        drawParallaxStele(baseX + layerW * 0.35, worldH, 30, worldH * 0.32, tint, alpha * 0.9)
        drawParallaxStele(baseX + layerW * 0.38, worldH, 24, worldH * 0.26, tint, alpha * 0.85)

    elseif layerIdx == 4 then
        -- 前景雾气层: 浓重的云雾覆盖底部
        for i = 1, 18 do
            local cx = baseX + hash01(seed + 400 + i * 7) * layerW
            local cy = worldH * (0.7 + hash01(seed + 400 + i * 9) * 0.28)
            local rx = 180 + hash01(seed + 400 + i * 11) * 320
            local ry = 35 + hash01(seed + 400 + i * 13) * 65
            drawRotEllipse(cx, cy, rx, ry, (hash01(seed + 400 + i * 17) - 0.5) * 0.15, colorRGBA(tint, alpha * 0.6))
        end
        -- 顶部薄雾
        for i = 1, 8 do
            local cx = baseX + hash01(seed + 450 + i * 11) * layerW
            local cy = worldH * (0.05 + hash01(seed + 450 + i * 13) * 0.2)
            local rx = 200 + hash01(seed + 450 + i * 17) * 250
            local ry = 25 + hash01(seed + 450 + i * 19) * 40
            drawRotEllipse(cx, cy, rx, ry, 0, colorRGBA(tint, alpha * 0.4))
        end
        -- 卷云装饰
        for i = 1, 6 do
            local cx = baseX + hash01(seed + 500 + i * 13) * layerW
            local cy = worldH * (0.55 + hash01(seed + 500 + i * 17) * 0.25)
            drawParallaxSwirlCloud(cx, cy, 50 + hash01(seed + 500 + i * 19) * 80, 18 + hash01(seed + 500 + i * 23) * 25, tint, alpha * 0.5, seed + 500 + i)
        end
    end

    nvgRestore(vg)
end

function drawParallaxBackground()
    -- 天空渐变 (固定在视口, 不随相机移动)
    local skyOffX, skyOffY = parallaxOffset(0)
    nvgSave(vg)
    nvgTranslate(vg, skyOffX, skyOffY)
    -- 深蓝渐变天空
    local skyTop = C(8, 18, 42)
    local skyMid = C(22, 48, 88)
    local skyBot = C(55, 105, 155)
    drawVerticalWash(0, worldH * 0.5, skyTop, skyMid, 255, 255, 24)
    drawVerticalWash(worldH * 0.5, worldH * 0.5, skyMid, skyBot, 255, 180, 24)
    nvgRestore(vg)

    -- 层1: 远景山峦与卷云 (0.05x 视差 - 几乎不动)
    local farTint = C(40, 70, 115)
    drawParallaxLayer(1, 0.05, farTint, 90, 1100)

    -- 层2: 中景建筑剪影 (0.25x 视差)
    local midTint = C(50, 80, 130)
    drawParallaxLayer(2, 0.25, midTint, 130, 1200)

    -- 中间云雾分隔带 (0.15x 视差)
    local mistOffX, mistOffY = parallaxOffset(0.15)
    nvgSave(vg)
    nvgTranslate(vg, mistOffX, mistOffY * 0.2)
    for i = 1, 15 do
        local cx = -worldW * 0.2 + hash01(1300 + i * 11) * worldW * 1.4
        local cy = worldH * (0.35 + hash01(1300 + i * 13) * 0.2)
        local rx = 200 + hash01(1300 + i * 17) * 400
        local ry = 30 + hash01(1300 + i * 19) * 60
        drawRotEllipse(cx, cy, rx, ry, (hash01(1300 + i * 23) - 0.5) * 0.15, rgba(70, 120, 175, 55 + hash01(1300 + i) * 40))
    end
    nvgRestore(vg)

    -- 层3: 近景建筑剪影 (0.50x 视差)
    local nearTint = C(30, 50, 90)
    drawParallaxLayer(3, 0.50, nearTint, 180, 1400)

    -- 层4: 前景雾气 (0.80x 视差 - 接近跟随相机)
    local fogTint = C(100, 155, 200)
    drawParallaxLayer(4, 0.80, fogTint, 70, 1500)

    -- 游戏世界底部的纸纹（正常世界坐标，跟随相机）
    -- 轻微的纸纹质感覆盖
    for i = 1, 40 do
        local x = hash01(i * 37 + 1600) * worldW
        local y = hash01(i * 41 + 1600) * worldH
        local len = 15 + hash01(i * 43 + 1600) * 50
        local a = -0.5 + (hash01(i * 47 + 1600) - 0.5) * 0.4
        strokeLine(x, y, x + math.cos(a) * len, y + math.sin(a) * len, 0.5, rgba(80, 130, 180, 12 + hash01(i * 51 + 1600) * 14))
    end
end
end -- parallax scope

local function drawBackground()
    if currentLevel.id == "bamboo" then
        fillPoly({
            { 0, worldH }, { 0, H(0.40) },
            { W(0.20), H(0.20) }, { W(0.40), H(0.50) },
            { W(0.70), H(0.30) }, { worldW, H(0.60) },
            { worldW, worldH },
        }, rgba(120, 135, 125, 20))
        drawMountainBandAt(300, 5, C(120, 135, 125), 8, 0.24, 0.20, 0.24, 0.42, -240)
        drawAxCutCliff(W(0.20), worldH, W(0.40), H(0.20), -1)
        drawAxCutCliff(W(0.55), worldH, W(0.75), H(0.10), 1)
        drawWaterfallWash()
    elseif currentLevel.id == "pine" then
        drawMountainBandAt(510, 6, C(110, 125, 115), 8, 0.28, 0.30, 0.18, 0.45, -200)
        drawMistBand(520, 18, currentLevel.paper, 32, 0.10, 0.72, 150, 450, 20, 80)
        drawRaindropCliff(0, H(0.50), W(0.12), H(0.50), true, rgba(35, 38, 35, 220))
        drawRaindropCliff(W(0.88), H(0.40), W(0.12), H(0.60), false, rgba(35, 38, 35, 220))
        drawCascadeSpringWash(W(0.30), H(0.20), W(0.50), H(0.80), 85)
        if currentLevelIsInkLab and currentLevelIsInkLab() then drawInkLabPineBackground() end
    elseif currentLevel.id == "maple" then
        drawVerticalWash(0, H(0.75), C(225, 185, 140), C(247, 238, 219), 96, 0, 22)
        drawMountainBandAt(610, 6, C(155, 120, 95), 10, 0.28, 0.30, 0.20, 0.48, -300)
        drawMistBand(620, 15, C(235, 205, 175), 26, 0.12, 0.68, 150, 400, 20, 70)
        drawRockShape(W(-0.05), H(0.78), W(0.22), H(0.25), rgba(40, 35, 30, 185), rgba(10, 8, 5, 210))
        drawRockShape(W(0.35), H(0.72), W(0.16), H(0.30), rgba(40, 35, 30, 165), rgba(10, 8, 5, 190))
        for i = 1, 62 do
            local x = (hash01(i * 73) * worldW + elapsed * (9 + hash01(i) * 18)) % worldW
            local y = (hash01(i * 79) * worldH + elapsed * (12 + hash01(i * 3) * 26)) % worldH
            local s = 5 + hash01(i * 83) * 12
            drawAutumnLeaf(x, y, s, rgba(195, 22, 22, 42 + hash01(i) * 95))
        end
    elseif currentLevel.id == "plum" then
        drawVerticalWash(0, H(0.52), C(235, 229, 218), currentLevel.paper, 36, 0, 16)
        drawMountainBandAt(710, 6, C(135, 142, 135), 8, 0.25, 0.30, 0.20, 0.48, -300)
        drawMistBand(720, 16, C(215, 205, 185), 20, 0.12, 0.70, 150, 400, 20, 70)
        drawRect(W(0.035), H(0.12), W(0.19), H(0.60), 0, rgba(42, 30, 24, 10))
        for i = 0, 3 do
            strokeLine(W(0.06 + i * 0.04), H(0.24), W(0.06 + i * 0.04), H(0.66), 1.2, rgba(42, 30, 24, 48))
            strokeLine(W(0.06 + i * 0.04) + 7, H(0.24), W(0.06 + i * 0.04) + 7, H(0.66), 0.7, rgba(42, 30, 24, 20))
        end
    elseif currentLevel.id == "plum_mirror" then
        drawVerticalWash(0, H(0.52), C(235, 229, 218), currentLevel.paper, 36, 0, 16)
        drawMountainBandAt(710, 6, C(135, 142, 135), 8, 0.25, 0.30, 0.20, 0.48, -300)
        drawMistBand(720, 16, C(215, 205, 185), 20, 0.12, 0.70, 150, 400, 20, 70)
        drawRect(W(0.775), H(0.12), W(0.19), H(0.60), 0, rgba(42, 30, 24, 10))
        for i = 0, 3 do
            strokeLine(W(0.82 + i * 0.04), H(0.24), W(0.82 + i * 0.04), H(0.66), 1.2, rgba(42, 30, 24, 48))
            strokeLine(W(0.82 + i * 0.04) + 7, H(0.24), W(0.82 + i * 0.04) + 7, H(0.66), 0.7, rgba(42, 30, 24, 20))
        end
    elseif currentLevel.id == "plum_finale" then
        -- 母本复刻：王冕《梅竹双清卷》梅段的旧纸底——无山无雾，只有岁月斑驳的卷纸、
        -- 鉴藏朱印与右壁满纸行书。印章位置按母本描取。
        drawVerticalWash(0, worldH, C(205, 180, 140), currentLevel.paper, 26, 10, 12)
        -- 旧纸的水渍与霉斑
        for i = 1, 14 do
            local sx = hash01(i * 37.7) * worldW
            local sy = hash01(i * 53.3) * worldH
            drawInkBleed(sx, sy, 60 + hash01(i * 17) * 160, 40 + hash01(i * 23) * 90, C(168, 142, 102), 7 + hash01(i * 29) * 7, i * 7.1, 2)
        end
        -- 鉴藏印（仿乾隆鉴藏诸玺布局）：圆玺——细环 + 印泥斑点，避免大色块
        local rsX, rsY, rsR = W(0.665), H(0.095), W(0.052)
        drawCircle(rsX, rsY, rsR, rgba(186, 72, 48, 30))
        drawCircle(rsX, rsY, rsR - 4, colorRGBA(currentLevel.paper, 235))
        drawInkSpeckles(rsX - rsR * 0.8, rsY - rsR * 0.8, rsR * 1.6, rsR * 1.6, C(186, 72, 48), 64, 311.7, 22)
        -- 方玺两枚（描边 + 印文斑点）
        for _, s in ipairs({
            { 0.585, 0.275, 0.095, 0.150 },
            { 0.505, 0.455, 0.055, 0.100 },
        }) do
            local x1, y1, w1, h1 = W(s[1]), H(s[2]), W(s[3]), H(s[4])
            drawRect(x1, y1, w1, h1, 0, rgba(186, 72, 48, 9))
            strokeLine(x1, y1, x1 + w1, y1, 2.2, rgba(186, 72, 48, 46))
            strokeLine(x1 + w1, y1, x1 + w1, y1 + h1, 2.2, rgba(186, 72, 48, 46))
            strokeLine(x1 + w1, y1 + h1, x1, y1 + h1, 2.2, rgba(186, 72, 48, 46))
            strokeLine(x1, y1 + h1, x1, y1, 2.2, rgba(186, 72, 48, 46))
            drawInkSpeckles(x1 + 6, y1 + 6, w1 - 12, h1 - 12, C(186, 72, 48), 52, s[1] * 97.3, 26)
        end
        -- 边角小印（左缘与左下角，仿历代收传印记）
        for _, s in ipairs({
            { 0.006, 0.300, 0.020, 0.045 }, { 0.006, 0.360, 0.020, 0.040 },
            { 0.022, 0.800, 0.030, 0.055 }, { 0.060, 0.840, 0.026, 0.048 },
            { 0.014, 0.880, 0.034, 0.060 },
        }) do
            drawRect(W(s[1]), H(s[2]), W(s[3]), H(s[4]), 0, rgba(186, 72, 48, 26))
            drawInkSpeckles(W(s[1]), H(s[2]), W(s[3]), H(s[4]), currentLevel.paper, 150, s[2] * 131.1, 12)
        end
        -- 右壁满纸行书（题诗柱的纸面墨痕：三主柱 + 两道残柱）
        for i = 0, 4 do
            local colX = W(0.806 + i * 0.045)
            local topY, botY = H(0.080 + hash01(i * 13.7) * 0.030), H(0.780 - hash01(i * 19.3) * 0.040)
            if i == 1 then colX = W(0.866) end
            if i == 2 then colX = W(0.926) end
            if i > 2 then colX = W(0.962 + (i - 3) * 0.022) end
            strokeLine(colX + 8, topY, colX + 8, botY, 0.8, rgba(56, 46, 36, 20))
            -- 行书字团：沿柱身的浓淡墨点
            local steps = i > 2 and 9 or 14
            for k = 0, steps do
                local cy = topY + (botY - topY) * k / steps
                local seed = i * 71.3 + k * 13.9
                drawInkBleed(colX + (hash01(seed) - 0.5) * 10, cy, 7 + hash01(seed + 3) * 9, 5 + hash01(seed + 7) * 7, C(56, 46, 36), 26 + hash01(seed + 11) * 30, seed, 2)
            end
        end
        -- 极疏的飘瓣（白描花瓣偶然离枝）
        for i = 1, 12 do
            local drift = elapsed * (5 + hash01(i * 13) * 8)
            local x = (hash01(i * 67) * worldW - drift) % worldW
            local y = (hash01(i * 71) * worldH + drift * 0.55) % worldH
            local s = 3.5 + hash01(i * 77) * 4
            local a = 20 + hash01(i * 83) * 34
            drawTinyBlossom(x, y, s, C(238, 230, 212), C(222, 210, 188), C(90, 75, 58), i * 91.3, a, 5)
        end
    elseif currentLevel.id == "peach" then
        drawVerticalWash(0, worldH, C(160, 184, 163), C(242, 230, 208), 126, 0, 30)
        drawMountainBandAt(810, 5, C(85, 115, 95), 13, 0.28, 0.35, 0.22, 0.45, -200)
        drawMistBand(820, 15, C(240, 235, 215), 22, 0.10, 0.66, 150, 400, 20, 70)
        drawRockShape(W(-0.05), H(0.78), W(0.22), H(0.25), rgba(40, 35, 30, 175), rgba(10, 8, 5, 205))
        drawRockShape(W(0.35), H(0.72), W(0.16), H(0.30), rgba(40, 35, 30, 145), rgba(10, 8, 5, 180))
        drawSpringWater()
    elseif currentLevel.id == "eaves" then
        drawVerticalWash(0, worldH, C(22, 33, 26), currentLevel.paper, 92, 0, 26)
        drawMountainBandAt(910, 5, C(28, 76, 120), 16, 0.24, 0.28, 0.22, 0.46, -300)
        drawMountainBandAt(940, 5, C(38, 120, 76), 13, 0.30, 0.28, 0.20, 0.44, -220)
        drawMistBand(920, 15, C(230, 210, 180), 26, 0.12, 0.70, 150, 400, 20, 70)
        for i = 1, 30 do
            local x = hash01(950 + i * 17) * worldW
            local y = hash01(950 + i * 23) * H(0.74)
            local len = 44 + hash01(950 + i * 29) * 120
            strokeLine(x, y, x + len, y - 5 - hash01(950 + i * 31) * 20, 1.0, rgba(218, 165, 32, 24 + hash01(i) * 34))
        end
        for i = 0, 5 do
            local x = W(0.08 + i * 0.16)
            strokeLine(x, H(0.18), x + W(0.10), H(0.12 + hash01(930 + i) * 0.12), 1.0, rgba(218, 165, 32, 42))
            strokeLine(x + W(0.10), H(0.12 + hash01(930 + i) * 0.12), x + W(0.18), H(0.19), 1.0, rgba(17, 21, 18, 38))
        end
    elseif currentLevel.id == "huangshan" then
        drawVerticalWash(0, worldH, C(196, 209, 200), C(236, 240, 235), 110, 20, 28)
        drawMountainBandAt(1010, 6, C(90, 115, 100), 13, 0.30, 0.25, 0.18, 0.45, -150)
        drawSpires(W(0.00), H(0.50), W(0.15), H(0.50), true)
        drawSpires(W(0.30), H(0.45), W(0.15), H(0.55), false)
        drawSpires(W(0.48), H(0.38), W(0.16), H(0.62), true)
        drawSpires(W(0.85), H(0.30), W(0.15), H(0.70), false)
        drawCloudSea()
    elseif currentLevel.id == "plum_master" then
        drawMasterPlumBackground()
    elseif currentLevel.id == "plum_parallax" then
        drawParallaxBackground()
    elseif currentLevel.id == "molong" then
        -- 风雷烟云:旋涡云带横贯,斜雨如丝,远雷淡痕,下缘云涛
        for band = 0, 2 do
            local by = H(0.16 + band * 0.30)
            for i = 1, 16 do
                local seed = band * 97.7 + i * 13.1
                local cx2 = hash01(seed) * worldW
                local cy2 = by + (hash01(seed + 3) - 0.5) * H(0.14)
                drawRotEllipse(cx2, cy2, 160 + hash01(seed + 7) * 240, 26 + hash01(seed + 11) * 40,
                    (hash01(seed + 13) - 0.5) * 0.3, colorRGBA(currentLevel.paper2, 22 + hash01(seed + 17) * 26))
            end
            for i = 1, 10 do
                local seed = band * 71.3 + i * 17.9
                local cx2 = hash01(seed) * worldW
                local cy2 = by + (hash01(seed + 5) - 0.5) * H(0.12)
                local r0 = 36 + hash01(seed + 7) * 60
                for k = 0, 5 do
                    local a1 = k * 1.05 + hash01(seed + k) * 0.4
                    strokeLine(cx2 + math.cos(a1) * r0, cy2 + math.sin(a1) * r0 * 0.5,
                        cx2 + math.cos(a1 + 0.8) * r0 * 0.74, cy2 + math.sin(a1 + 0.8) * r0 * 0.38,
                        1.1, colorRGBA(currentLevel.wash, 30 + hash01(seed + k + 9) * 22))
                end
            end
        end
        for i = 1, 130 do
            local seed = i * 23.3
            local x = hash01(seed) * worldW
            local y = hash01(seed + 3) * worldH
            local ln = 30 + hash01(seed + 7) * 60
            strokeLine(x, y, x - ln * 0.26, y + ln, 0.7, colorRGBA(currentLevel.wash, 10 + hash01(seed + 11) * 14))
        end
        for i = 0, 1 do
            local sx = W(0.30 + i * 0.40) + hash01(i * 7.1) * W(0.06)
            local sy = H(0.04)
            local px, py = sx, sy
            for k = 1, 4 do
                local nx2 = px + (hash01(i * 31 + k * 7) - 0.5) * 90 - 20
                local ny2 = py + H(0.07 + hash01(i * 37 + k * 11) * 0.05)
                strokeLine(px, py, nx2, ny2, 1.6, rgba(232, 222, 188, 34))
                px, py = nx2, ny2
            end
        end
        for i = 1, 22 do
            local seed = i * 31.7
            local cx2 = hash01(seed) * worldW
            local cy2 = H(0.93 + hash01(seed + 3) * 0.05)
            strokeQuad(cx2 - 70, cy2, cx2, cy2 - 34 - hash01(seed + 7) * 26, cx2 + 70, cy2, 2.2, colorRGBA(currentLevel.wash, 60))
        end
    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" then
        -- 母本复刻关:素纸/素绢,不画山;只铺岁月痕迹与母本固有的纸面元素
        for i = 1, 12 do
            local sx = hash01(i * 43.7) * worldW
            local sy = hash01(i * 57.3) * worldH
            drawInkBleed(sx, sy, 50 + hash01(i * 19) * 140, 36 + hash01(i * 27) * 80, currentLevel.paper2, 8 + hash01(i * 31) * 7, i * 9.3, 2)
        end
        if currentLevel.id == "wentong_zhu" then
            -- 绢本横丝纹理 + 顶部题跋墨影带
            for i = 0, 26 do
                local y = worldH * i / 26 + hash01(i * 7.7) * 14
                strokeLine(0, y, worldW, y + (hash01(i * 11.3) - 0.5) * 8, 0.6, rgba(120, 92, 50, 14))
            end
            for i = 1, 56 do
                local cx2 = W(0.03 + hash01(i * 13.1) * 0.94)
                local cy2 = H(0.022 + hash01(i * 17.9) * 0.12)
                drawInkBleed(cx2, cy2, 5 + hash01(i * 23) * 7, 7 + hash01(i * 29) * 10, C(30, 24, 16), 30 + hash01(i * 37) * 30, i * 5.7, 2)
            end
        elseif currentLevel.id == "plum_xiyan" then
            -- 右上鉴藏圆玺 + 左下收传印群(位置按母本)
            local rx2, ry2, rr2 = W(0.835), H(0.085), W(0.030)
            drawCircle(rx2, ry2, rr2, rgba(186, 72, 48, 30))
            drawCircle(rx2, ry2, rr2 - 4, colorRGBA(currentLevel.paper, 235))
            drawInkSpeckles(rx2 - rr2 * 0.8, ry2 - rr2 * 0.8, rr2 * 1.6, rr2 * 1.6, C(186, 72, 48), 60, 411.3, 16)
            for _, s in ipairs({
                { 0.020, 0.560, 0.022, 0.045 }, { 0.024, 0.640, 0.020, 0.040 },
                { 0.018, 0.870, 0.026, 0.050 }, { 0.060, 0.900, 0.022, 0.045 },
            }) do
                drawRect(W(s[1]), H(s[2]), W(s[3]), H(s[4]), 0, rgba(186, 72, 48, 26))
                drawInkSpeckles(W(s[1]), H(s[2]), W(s[3]), H(s[4]), currentLevel.paper, 150, s[2] * 97.1, 10)
            end
        end
    else
        drawMountainBand(100, 6, currentLevel.wash, 12, 0.28, 0.30)
    end

    if currentLevel.id == "bamboo" then
        -- waterfall is drawn above with the cliffs so the central paper-white gap stays crisp
    elseif currentLevel.id == "peach" then
        -- spring water is part of the scenic background and already includes its ripple field
    end
end

-- ============================================================================
-- END scripts/src/60_background_render.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/65_inklab_render.lua
-- ============================================================================
-- Source chunk for the Pine InkLab level.
-- It uses raster brush stamps as a material layer over the existing procedural level.

inkLabImageNames = {
    dry = "pine_dry_brush_01.png",
    -- Round 01 dry-branch assets are style templates and first in-engine probes.
    -- Later passes should add context-specific variants instead of repeating only these.
    dryNode = "pine_dry_branch_02_alpha.png",
    dryMain = "pine_dry_branch_03_alpha.png",
    dryBroken = "pine_dry_branch_04_alpha.png",
    drySweep = "pine_dry_branch_06_alpha.png",
    branchMain = "pine_branch_main_long_01.png",
    branchBroken = "pine_branch_broken_long_01.png",
    branchNode = "pine_branch_node_knot_01.png",
    branchTip = "pine_branch_tip_sweep_01.png",
    branchMirror = "pine_branch_mirror_scurve_01.png",
    branchMainLight = "pine_branch_main_long_light_01.png",
    branchBrokenLight = "pine_branch_broken_long_light_01.png",
    branchNodeLight = "pine_branch_node_knot_light_01.png",
    branchTipLight = "pine_branch_tip_sweep_light_01.png",
    branchMirrorLight = "pine_branch_mirror_scurve_light_01.png",
    bleed = "pine_ink_bleed_01.png",
    needle = "pine_needle_fan_01.png",
    paper = "paper_grain_01.png",
    bristleTip = "ink_bristle_footprint_01.png",
    bristleWetA = "ink_bristle_wet_01.png",
    bristleWetB = "ink_bristle_wet_02.png",
    worldStrokes = "pine_inklab_world_strokes.png",
}
inkLabImages = nil
inkLabImagesTried = false
inkLabDryMainStamps = { "branchMain", "branchMirror", "dryMain", "dry" }
inkLabDryBrokenStamps = { "branchBroken", "dryBroken", "dry" }
inkLabDryNodeStamps = { "branchNode", "dryNode", "dry" }
inkLabDrySweepStamps = { "branchTip", "drySweep", "dryBroken", "dry" }
inkLabDryMainLightStamps = { "branchMainLight", "branchMirrorLight" }
inkLabDryBrokenLightStamps = { "branchBrokenLight" }
inkLabDryNodeLightStamps = { "branchNodeLight" }
inkLabDrySweepLightStamps = { "branchTipLight" }
inkLabSweepCoreStamps = { "branchMain", "branchMirror" }
inkLabSweepDryStamps = { "branchBroken", "dryBroken", "dryMain" }
inkLabSweepEdgeStamps = { "branchMainLight", "branchBrokenLight", "branchMirrorLight" }
inkLabWetBristleStamps = { "bristleWetA", "bristleWetB", "bristleTip" }

function currentLevelIsInkLab()
    return currentLevel ~= nil and currentLevel.variant == "ink_atlas"
end

function tryLoadInkLabImages()
    if inkLabImagesTried or vg == nil then return end
    inkLabImagesTried = true
    inkLabImages = {}
end

function inkLabLoadImage(name)
    tryLoadInkLabImages()
    if not inkLabImages or not inkLabImageNames[name] then return nil end
    local cached = inkLabImages[name]
    if cached ~= nil then return cached end
    if type(nvgCreateImage) ~= "function" then
        inkLabImages[name] = false
        return nil
    end
    local file = inkLabImageNames[name]
    local paths = {
        "assets/ink_atlas/" .. file,
        "ink_atlas/" .. file,
        file,
    }
    for _, path in ipairs(paths) do
        local ok, img = pcall(nvgCreateImage, vg, path, 0)
        if ok and img and img > 0 then
            inkLabImages[name] = img
            return img
        end
    end
    inkLabImages[name] = false
    return nil
end

function inkLabIsVisible(x, y, pad)
    pad = pad or 220
    return not (x + pad < cameraX or x - pad > cameraX + DESIGN_W or y + pad < cameraY or y - pad > cameraY + DESIGN_H)
end

function inkLabMeasureBranch(list)
    if not list or #list < 1 then return nil end
    if list._inkLabMeasureCount == #list and list._inkLabLen then return list end
    local len = 0
    local avgR = 0
    local minX, minY = list[1].x, list[1].y
    local maxX, maxY = minX, minY
    for i = 1, #list do
        local n = list[i]
        avgR = avgR + n.r
        if n.x - n.r < minX then minX = n.x - n.r end
        if n.x + n.r > maxX then maxX = n.x + n.r end
        if n.y - n.r < minY then minY = n.y - n.r end
        if n.y + n.r > maxY then maxY = n.y + n.r end
        if i < #list then
            local b = list[i + 1]
            len = len + dist2(b.x - n.x, b.y - n.y)
        end
    end
    list._inkLabMeasureCount = #list
    list._inkLabLen = len
    list._inkLabAvgR = avgR / #list
    list._inkLabMinX, list._inkLabMinY = minX, minY
    list._inkLabMaxX, list._inkLabMaxY = maxX, maxY
    return list
end

function inkLabBranchListVisible(list, pad)
    local m = inkLabMeasureBranch(list)
    if not m then return false end
    pad = pad or 260
    return not (
        m._inkLabMaxX + pad < cameraX or
        m._inkLabMinX - pad > cameraX + DESIGN_W or
        m._inkLabMaxY + pad < cameraY or
        m._inkLabMinY - pad > cameraY + DESIGN_H
    )
end

function drawInkLabStamp(name, x, y, w, h, angle, alpha)
    local img = inkLabLoadImage(name)
    if not img then return false end
    if type(nvgImagePattern) ~= "function" or type(nvgFillPaint) ~= "function" then return false end
    if not inkLabIsVisible(x, y, math.max(w, h) * 0.65) then return true end
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, angle or 0)
    local ok, paint = pcall(nvgImagePattern, vg, -w * 0.5, -h * 0.5, w, h, 0, img, alpha or 0.5)
    if ok and paint then
        nvgBeginPath(vg)
        nvgRect(vg, -w * 0.5, -h * 0.5, w, h)
        nvgFillPaint(vg, paint)
        nvgFill(vg)
    end
    nvgRestore(vg)
    return ok and paint ~= nil
end

function drawInkLabStampFirst(names, x, y, w, h, angle, alpha)
    for _, name in ipairs(names) do
        if drawInkLabStamp(name, x, y, w, h, angle, alpha) then return true end
    end
    return false
end

function drawInkLabStampChoice(names, seed, x, y, w, h, angle, alpha)
    local idx = 1 + math.floor(hash01(seed or 0) * #names)
    if idx < 1 then idx = 1 end
    if idx > #names then idx = #names end
    if drawInkLabStamp(names[idx], x, y, w, h, angle, alpha) then return true end
    return drawInkLabStampFirst(names, x, y, w, h, angle, alpha)
end

function drawInkLabWorldStrokeLayer()
    if not currentLevelIsInkLab() then return false end
    local img = inkLabLoadImage("worldStrokes")
    if not img then return false end
    if type(nvgImagePattern) ~= "function" or type(nvgFillPaint) ~= "function" then return false end
    local ok, paint = pcall(nvgImagePattern, vg, 0, 0, worldW, worldH, 0, img, 0.92)
    if not ok or not paint then return false end
    nvgBeginPath(vg)
    nvgRect(vg, cameraX - 4, cameraY - 4, DESIGN_W + 8, DESIGN_H + 8)
    nvgFillPaint(vg, paint)
    nvgFill(vg)
    return true
end

function drawInkLabBranchGrain(names, lightNames, seed, x, y, nx, ny, r, w, h, angle)
    local darkAlpha = 0.13 + hash01(seed + 23) * 0.055
    drawInkLabStampChoice(names, seed, x, y, w, h, angle, darkAlpha)

    local passCount = 3
    if r > 20 then passCount = 4 end
    for pass = 1, passCount do
        local s = seed + pass * 97
        local lane = (pass - (passCount + 1) * 0.5) / math.max(1, (passCount - 1) * 0.5)
        local offset = lane * r * (0.42 + hash01(s + 3) * 0.18)
        local jitter = (hash01(s + 5) - 0.5) * r * 0.16
        local px = x + nx * (offset + jitter)
        local py = y + ny * (offset + jitter)
        local lw = w * (0.62 + hash01(s + 7) * 0.34)
        local lh = math.max(7, h * (0.24 + hash01(s + 11) * 0.16))
        local la = 0.105 + hash01(s + 13) * 0.075
        drawInkLabStampChoice(lightNames, s, px, py, lw, lh, angle + (hash01(s + 17) - 0.5) * 0.035, la)
    end

    if hash01(seed + 29) > 0.50 then
        local side = hash01(seed + 31) > 0.5 and 1 or -1
        drawInkLabStampFirst(inkLabDryBrokenStamps, x + nx * r * side * 0.28, y + ny * r * side * 0.28, w * 0.58, math.max(9, h * 0.38), angle + (hash01(seed + 37) - 0.5) * 0.07, 0.07)
        drawInkLabStampFirst(inkLabDryBrokenLightStamps, x + nx * r * side * 0.30, y + ny * r * side * 0.30, w * 0.46, math.max(6, h * 0.22), angle + (hash01(seed + 39) - 0.5) * 0.07, 0.10)
    end
end

function inkLabBranchPressure(t, seed)
    local body = 0.94 + math.sin(t * math.pi) * 0.10
    local startPress = t < 0.16 and (1.10 - t * 0.70) or 1.0
    local tipLift = t > 0.86 and (1.0 - (t - 0.86) * 1.55) or 1.0
    local pulse = 1.0 + math.sin(t * math.pi * 3.0 + seed * 0.019) * 0.08 + (hash01(seed + math.floor(t * 13) * 31) - 0.5) * 0.075
    local p = body * startPress * tipLift * pulse
    if p < 0.58 then p = 0.58 end
    if p > 1.18 then p = 1.18 end
    return p
end

function inkLabInkLoad(t, seed)
    local wave = 0.66 + math.sin(t * math.pi * 2.0 + seed * 0.031) * 0.20 + math.sin(t * math.pi * 5.0 + seed * 0.013) * 0.11
    local pocket = hash01(seed + math.floor(t * 9) * 97)
    if pocket > 0.66 then wave = wave * 0.48 end
    if pocket < 0.14 then wave = wave * 1.16 end
    if t > 0.82 then wave = wave * (1.0 - (t - 0.82) * 0.80) end
    if wave < 0.24 then wave = 0.24 end
    if wave > 1.08 then wave = 1.08 end
    return wave
end

function inkLabDryness(t, seed)
    local dry = 0.38 + math.sin(t * math.pi * 2.7 + seed * 0.021) * 0.20 + math.sin(t * math.pi * 7.0 + seed * 0.011) * 0.12
    local pocket = hash01(seed + math.floor(t * 12) * 131)
    if pocket > 0.67 then dry = dry + 0.28 end
    if pocket < 0.16 then dry = dry - 0.16 end
    if t < 0.12 then dry = dry - (0.12 - t) * 0.55 end
    if t > 0.72 then dry = dry + (t - 0.72) * 0.95 end
    if dry < 0.08 then dry = 0.08 end
    if dry > 0.96 then dry = 0.96 end
    return dry
end

function drawInkLabOneStrokeBody(list, tint, alpha, seed, scale, fillTint)
    if not list or #list < 2 then return end
    local count = #list
    local stride = math.max(1, math.floor(count / 46))
    local first, second = list[1], list[2]
    local prevTail, tail = list[count - 1], list[count]
    local startDx, startDy = second.x - first.x, second.y - first.y
    local tailDx, tailDy = tail.x - prevTail.x, tail.y - prevTail.y
    local startLen = math.max(1, dist2(startDx, startDy))
    local tailLen = math.max(1, dist2(tailDx, tailDy))
    local startTx, startTy = startDx / startLen, startDy / startLen
    local tailTx, tailTy = tailDx / tailLen, tailDy / tailLen
    local startX = first.x - startTx * first.r * 1.35
    local startY = first.y - startTy * first.r * 1.35
    local tailX = tail.x + tailTx * tail.r * 1.75
    local tailY = tail.y + tailTy * tail.r * 1.75
    local startSide = first.r * (scale or 1.0) * 0.26
    local tailSide = tail.r * (scale or 1.0) * 0.16
    nvgBeginPath(vg)
    nvgMoveTo(vg, startX + first.normX * startSide, startY + first.normY * startSide)
    for i = 1, count, stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local rough = 1.0 + (hash01(seed + i * 19) - 0.5) * 0.018
        local side = n.r * inkLabBranchPressure(t, seed) * (scale or 1.0) * rough
        local x = n.x + n.normX * side
        local y = n.y + n.normY * side
        nvgLineTo(vg, x, y)
    end
    if ((count - 1) % stride) ~= 0 then
        local n = tail
        local rough = 1.0 + (hash01(seed + count * 19) - 0.5) * 0.018
        local side = n.r * inkLabBranchPressure(1, seed) * (scale or 1.0) * rough
        nvgLineTo(vg, n.x + n.normX * side, n.y + n.normY * side)
    end
    nvgLineTo(vg, tailX + tail.normX * tailSide, tailY + tail.normY * tailSide)
    nvgLineTo(vg, tailX - tail.normX * tailSide, tailY - tail.normY * tailSide)
    for i = count, 1, -stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local rough = 1.0 + (hash01(seed + i * 23 + 7) - 0.5) * 0.022
        local side = n.r * inkLabBranchPressure(t, seed + 3) * (scale or 1.0) * rough
        nvgLineTo(vg, n.x - n.normX * side, n.y - n.normY * side)
    end
    nvgLineTo(vg, startX - first.normX * startSide, startY - first.normY * startSide)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(fillTint or tint, alpha))
    nvgFill(vg)
end

function drawInkLabPathStroke(list, lane, width, tint, alpha, seed, step)
    if not list or #list < 2 then return end
    local count = #list
    local stride = step or math.max(2, math.floor(count / 64))
    local startIndex = math.max(2, math.floor(count * 0.055))
    local endIndex = math.min(count - 1, math.ceil(count * 0.945))
    if endIndex <= startIndex then startIndex, endIndex = 1, count end
    nvgBeginPath(vg)
    local moved = false
    for i = startIndex, endIndex, stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local drift = math.sin(t * math.pi * 2.0 + seed * 0.037) * 0.035
        local jitter = (hash01(seed + i * 29) - 0.5) * 0.045
        local off = n.r * ((lane or 0) + drift + jitter)
        local x = n.x + n.normX * off
        local y = n.y + n.normY * off
        if not moved then
            nvgMoveTo(vg, x, y)
            moved = true
        else
            nvgLineTo(vg, x, y)
        end
    end
    local last = list[endIndex]
    local off = last.r * (lane or 0)
    nvgLineTo(vg, last.x + last.normX * off, last.y + last.normY * off)
    nvgStrokeColor(vg, colorRGBA(tint, alpha))
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

function drawInkLabWideBrushStroke(list, width, tint, alpha, seed, step)
    if not list or #list < 2 then return end
    local count = #list
    local stride = step or math.max(1, math.floor(count / 56))
    local startIndex = math.max(2, math.floor(count * 0.045))
    local endIndex = math.min(count - 1, math.ceil(count * 0.955))
    if endIndex <= startIndex then startIndex, endIndex = 1, count end
    local first = list[startIndex]
    nvgBeginPath(vg)
    nvgMoveTo(vg, first.x, first.y)
    for i = startIndex, endIndex, stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local off = math.sin(t * math.pi * 2.0 + seed * 0.021) * n.r * 0.025
        nvgLineTo(vg, n.x + n.normX * off, n.y + n.normY * off)
    end
    local tail = list[endIndex]
    nvgLineTo(vg, tail.x, tail.y)
    nvgStrokeColor(vg, colorRGBA(tint, alpha))
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

function inkLabPathLength(list)
    local m = inkLabMeasureBranch(list)
    return m and m._inkLabLen or 0
end

function inkLabSampleBranch(list, t)
    local count = #list
    if count < 2 then return nil end
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    local f = 1 + t * (count - 1)
    local i = math.floor(f)
    if i >= count then i = count - 1 end
    local u = f - i
    local a, b = list[i], list[i + 1]
    local x = a.x + (b.x - a.x) * u
    local y = a.y + (b.y - a.y) * u
    local r = a.r + (b.r - a.r) * u
    local nx = a.normX + (b.normX - a.normX) * u
    local ny = a.normY + (b.normY - a.normY) * u
    local nlen = dist2(nx, ny)
    if nlen < 0.001 then nx, ny = a.normX, a.normY else nx, ny = nx / nlen, ny / nlen end
    return {
        x = x, y = y, r = r, normX = nx, normY = ny,
        angle = math.atan2(b.y - a.y, b.x - a.x),
    }
end

function drawInkLabSweepFootprint(names, seed, x, y, w, h, angle, alpha)
    local drift = (hash01(seed + 5) - 0.5) * h * 0.10
    local dx = math.cos(angle + math.pi * 0.5) * drift
    local dy = math.sin(angle + math.pi * 0.5) * drift
    return drawInkLabStampChoice(
        names,
        seed,
        x + dx,
        y + dy,
        w,
        h,
        angle + (hash01(seed + 9) - 0.5) * 0.035,
        alpha
    )
end

function inkLabAddPlannedStamp(plan, names, seed, x, y, w, h, angle, alpha)
    local drift = (hash01(seed + 5) - 0.5) * h * 0.10
    local dx = math.cos(angle + math.pi * 0.5) * drift
    local dy = math.sin(angle + math.pi * 0.5) * drift
    plan.stamps[#plan.stamps + 1] = {
        names = names,
        seed = seed,
        x = x + dx,
        y = y + dy,
        w = w,
        h = h,
        angle = angle + (hash01(seed + 9) - 0.5) * 0.035,
        alpha = alpha,
    }
end

function inkLabGetStrokePlan(list, seed)
    if not list or #list < 2 then return nil end
    local seedKey = math.floor((seed or 0) * 1000)
    if list._inkLabStrokePlan and list._inkLabStrokePlanSeed == seedKey then
        return list._inkLabStrokePlan
    end

    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return nil end
    local avgR = list._inkLabAvgR or list[1].r
    local plan = {
        stamps = {},
        fibers = {},
        accents = {},
        length = totalLen,
        avgR = avgR,
    }

    local head = inkLabSampleBranch(list, 0.02)
    local middle = inkLabSampleBranch(list, 0.50)
    local foot = inkLabSampleBranch(list, 0.98)
    if head and middle and foot then
        local fullAngle = math.atan2(foot.y - head.y, foot.x - head.x)
        inkLabAddPlannedStamp(
            plan,
            inkLabSweepCoreStamps,
            seed + 610,
            middle.x,
            middle.y,
            totalLen * 1.10 + avgR * 3.5,
            math.max(48, avgR * 3.05),
            fullAngle,
            0.40
        )
    end

    local count = math.max(1, math.min(4, math.ceil(totalLen / math.max(360, avgR * 13.0))))
    local overlap = 1.48
    for k = 1, count do
        local t0 = (k - 1) / count
        local t1 = k / count
        local tm = (t0 + t1) * 0.5
        local a = inkLabSampleBranch(list, t0)
        local b = inkLabSampleBranch(list, t1)
        local m = inkLabSampleBranch(list, tm)
        if a and b and m then
            local segLen = dist2(b.x - a.x, b.y - a.y)
            local pressure = inkLabBranchPressure(tm, seed + k * 37)
            local h = math.max(38, m.r * (2.45 + hash01(seed + k * 17) * 0.26) * pressure)
            local w = math.max(120, segLen * overlap + m.r * 2.4)
            local s = seed + k * 151
            inkLabAddPlannedStamp(plan, inkLabSweepCoreStamps, s, m.x, m.y, w, h, m.angle, 0.40)
            if hash01(s + 3) > 0.45 then
                inkLabAddPlannedStamp(plan, inkLabSweepDryStamps, s + 31, m.x, m.y, w * 0.76, h * 0.58, m.angle, 0.12)
            end
            if hash01(s + 7) > 0.52 then
                inkLabAddPlannedStamp(plan, inkLabSweepEdgeStamps, s + 53, m.x, m.y, w * 0.66, h * 0.44, m.angle, 0.09)
            end
        end
    end

    local first = inkLabSampleBranch(list, 0.025)
    local tailA = inkLabSampleBranch(list, 0.84)
    local tail = inkLabSampleBranch(list, 0.985)
    if first then
        plan.stamps[#plan.stamps + 1] = {
            names = inkLabDryNodeStamps,
            seed = seed + 811,
            x = first.x,
            y = first.y,
            w = first.r * 3.2,
            h = first.r * 2.5,
            angle = first.angle,
            alpha = 0.16,
            first = true,
        }
    end
    if tailA and tail then
        local dx, dy = tail.x - tailA.x, tail.y - tailA.y
        plan.stamps[#plan.stamps + 1] = {
            names = inkLabDrySweepStamps,
            seed = seed + 941,
            x = tail.x,
            y = tail.y,
            w = tail.r * 5.8,
            h = math.max(30, tail.r * 2.2),
            angle = math.atan2(dy, dx),
            alpha = 0.22,
            first = true,
        }
    end

    local fiberSamples = math.max(6, math.min(9, math.floor(totalLen / 170)))
    local lanes = { -0.48, 0.42 }
    for laneIndex, lane in ipairs(lanes) do
        local laneSeed = seed + 3100 + laneIndex * 257
        local points = {}
        local function flushFiber()
            if #points >= 2 then
                local tone = math.abs(lane) > 0.50 and "dark" or "body"
                plan.fibers[#plan.fibers + 1] = {
                    tone = tone,
                    points = points,
                    width = 0.75 + (1.0 - math.abs(lane)) * 1.20 + hash01(laneSeed + #plan.fibers * 13) * 0.45,
                    alpha = 22 + (1.0 - math.abs(lane)) * 28 + hash01(laneSeed + #plan.fibers * 17) * 10,
                }
            end
            points = {}
        end
        for i = 0, fiberSamples do
            local t = i / fiberSamples
            local n = inkLabSampleBranch(list, t)
            if n then
                local pressure = inkLabBranchPressure(t, laneSeed + 19)
                local dry = inkLabDryness(t, laneSeed + 43)
                local gate = 0.16 + math.abs(lane) * 0.22 + dry * 0.18
                local active = hash01(laneSeed + i * 41) > gate or (math.abs(lane) < 0.20 and dry < 0.86)
                local wob = math.sin(t * math.pi * 4.4 + laneSeed * 0.03) * n.r * 0.030 + (hash01(laneSeed + i * 47) - 0.5) * n.r * 0.070
                if active then
                    points[#points + 1] = {
                        x = n.x + n.normX * (lane * n.r * pressure + wob),
                        y = n.y + n.normY * (lane * n.r * pressure + wob),
                    }
                else
                    flushFiber()
                end
            end
        end
        flushFiber()
    end

    local samples = math.max(5, math.min(10, math.floor(totalLen / 150)))
    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local s = seed + 1700 + i * 149
            local pressure = inkLabBranchPressure(t, s)
            local load = inkLabInkLoad(t, s + 300)
            local dry = inkLabDryness(t, s + 700)
            local bend = math.abs(inkLabBranchCurvature(list, t))
            local slip = (hash01(s + 5) - 0.5) * n.r * (0.12 + bend * 0.42)
            local cx = n.x + n.normX * slip
            local cy = n.y + n.normY * slip
            plan.accents[#plan.accents + 1] = {
                kind = "ellipse",
                tone = "body",
                x = cx,
                y = cy,
                rx = n.r * (0.46 + load * 0.28 + pressure * 0.12),
                ry = n.r * (0.15 + pressure * 0.11),
                angle = n.angle + (hash01(s + 9) - 0.5) * 0.08,
                alpha = 13 + load * 24,
            }
            if i % 5 == 2 and load > 0.66 and bend > 0.16 then
                plan.accents[#plan.accents + 1] = {
                    kind = "stamp",
                    names = inkLabWetBristleStamps,
                    seed = s + 61,
                    x = cx,
                    y = cy,
                    w = n.r * (1.35 + pressure * 0.42),
                    h = n.r * (0.72 + load * 0.28),
                    angle = n.angle + (hash01(s + 63) - 0.5) * 0.16,
                    alpha = 0.048 + load * 0.030,
                }
            end
            if dry > 0.34 or bend > 0.16 then
                local lane = (hash01(s + 13) - 0.5) * n.r * 0.95
                plan.accents[#plan.accents + 1] = {
                    kind = "dryLine",
                    tone = "dark",
                    x0 = n.x + n.normX * lane - math.cos(n.angle) * n.r * 0.68,
                    y0 = n.y + n.normY * lane - math.sin(n.angle) * n.r * 0.68,
                    x1 = n.x + n.normX * lane + math.cos(n.angle) * n.r * (0.86 + dry * 0.48),
                    y1 = n.y + n.normY * lane + math.sin(n.angle) * n.r * (0.86 + dry * 0.48),
                    width = math.max(0.75, n.r * 0.13),
                    alpha = 16 + dry * 18,
                    seed = s + 19,
                }
            end
            if load > 0.58 and hash01(s + 21) > 0.58 then
                plan.accents[#plan.accents + 1] = {
                    kind = "bleed",
                    tone = "body",
                    x = cx,
                    y = cy,
                    rx = n.r * 0.30,
                    ry = n.r * 0.12,
                    alpha = 4 + load * 5,
                    seed = s + 23,
                }
            end
            if dry > 0.52 and hash01(s + 31) > 0.46 then
                plan.accents[#plan.accents + 1] = {
                    kind = "ellipse",
                    tone = "pale",
                    x = n.x + n.normX * (hash01(s + 33) - 0.5) * n.r * 0.62,
                    y = n.y + n.normY * (hash01(s + 37) - 0.5) * n.r * 0.62,
                    rx = n.r * (0.20 + hash01(s + 41) * 0.16),
                    ry = n.r * 0.045,
                    angle = n.angle,
                    alpha = 20 + hash01(s + 43) * 18,
                }
            end
        end
    end

    list._inkLabStrokePlan = plan
    list._inkLabStrokePlanSeed = seedKey
    return plan
end

function drawInkLabPlannedStamp(stamp)
    if stamp.first then
        return drawInkLabStampFirst(stamp.names, stamp.x, stamp.y, stamp.w, stamp.h, stamp.angle, stamp.alpha)
    end
    return drawInkLabStampChoice(stamp.names, stamp.seed, stamp.x, stamp.y, stamp.w, stamp.h, stamp.angle, stamp.alpha)
end

function inkLabPlanTone(tone, body)
    if tone == "dark" then return C(17, 15, 13) end
    if tone == "pale" then return currentLevel and currentLevel.paper or C(243, 239, 230) end
    return body or C(39, 35, 30)
end

function drawInkLabPlannedFiber(fiber, body)
    if not fiber or not fiber.points or #fiber.points < 2 then return end
    nvgBeginPath(vg)
    nvgMoveTo(vg, fiber.points[1].x, fiber.points[1].y)
    for i = 2, #fiber.points do
        nvgLineTo(vg, fiber.points[i].x, fiber.points[i].y)
    end
    nvgStrokeColor(vg, colorRGBA(inkLabPlanTone(fiber.tone, body), fiber.alpha))
    nvgStrokeWidth(vg, fiber.width)
    nvgStroke(vg)
end

function drawInkLabContinuousLane(list, lane, widthScale, tint, alpha, seed, samples)
    if not list or #list < 2 then return end
    local moved = false
    nvgBeginPath(vg)
    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local pressure = inkLabBranchPressure(t, seed + 17)
            local dry = inkLabDryness(t, seed + 31)
            local load = inkLabInkLoad(t, seed + 43)
            local wob = math.sin(t * math.pi * 3.6 + seed * 0.017) * n.r * 0.030 + (hash01(seed + i * 37) - 0.5) * n.r * 0.045
            local off = lane * n.r * pressure + wob
            local lift = t > 0.88 and (1.0 - (t - 0.88) * 2.6) or 1.0
            local x = n.x + n.normX * off
            local y = n.y + n.normY * off
            if dry < 0.84 or load > 0.44 or math.abs(lane) < 0.18 then
                if not moved then
                    nvgMoveTo(vg, x, y)
                    moved = true
                else
                    nvgLineTo(vg, x, y)
                end
            elseif moved then
                nvgStrokeColor(vg, colorRGBA(tint, alpha * (0.70 + load * 0.24)))
                nvgStrokeWidth(vg, math.max(0.9, widthScale * n.r * (0.22 + pressure * 0.08) * lift))
                nvgStroke(vg)
                nvgBeginPath(vg)
                moved = false
            end
        end
    end
    if moved then
        nvgStrokeColor(vg, colorRGBA(tint, alpha))
        local mid = inkLabSampleBranch(list, 0.52)
        nvgStrokeWidth(vg, math.max(0.9, (mid and mid.r or 8) * widthScale * 0.28))
        nvgStroke(vg)
    end
end

function drawInkLabContinuousBrushStroke(list, tint, seed)
    if not list or #list < 2 then return false end
    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return false end

    local body = tint or C(34, 30, 26)
    local dark = C(14, 12, 10)
    local pale = currentLevel and currentLevel.paper or C(243, 239, 230)
    local samples = math.max(8, math.min(12, math.floor(totalLen / 155)))

    -- Main body is one swept contact surface, not a sequence of pasted branch textures.
    drawInkLabOneStrokeBody(list, body, 126, seed + 1800, 0.70, C(30, 27, 23))
    drawInkLabOneStrokeBody(list, dark, 64, seed + 1817, 0.36, C(16, 14, 12))

    local depositCount = math.max(3, math.min(6, math.floor(totalLen / 260)))
    for k = 1, depositCount do
        local t = k / (depositCount + 1)
        local n = inkLabSampleBranch(list, t)
        if n then
            local s = seed + k * 211
            local pressure = inkLabBranchPressure(t, s + 17)
            local load = inkLabInkLoad(t, s + 31)
            local dry = inkLabDryness(t, s + 47)
            local lane = (hash01(s + 5) - 0.5) * n.r * (0.64 + dry * 0.22)
            local tx, ty = math.cos(n.angle), math.sin(n.angle)
            local px = n.x + n.normX * lane + tx * (hash01(s + 7) - 0.5) * n.r * 0.46
            local py = n.y + n.normY * lane + ty * (hash01(s + 11) - 0.5) * n.r * 0.46
            drawInkLabStampChoice(
                inkLabWetBristleStamps,
                s,
                px,
                py,
                n.r * (2.05 + pressure * 0.34),
                n.r * (1.08 + load * 0.18),
                n.angle + (hash01(s + 13) - 0.5) * 0.18,
                0.060 + load * 0.050
            )
        end
    end

    local edgeSamples = math.max(3, math.min(5, math.floor(totalLen / 310)))
    for i = 1, edgeSamples do
        local t0 = (i - 1) / edgeSamples
        local t1 = i / edgeSamples
        local a = inkLabSampleBranch(list, t0)
        local b = inkLabSampleBranch(list, t1)
        if a and b then
            local s = seed + i * 173
            local side = hash01(s + 3) > 0.45 and 1 or -1
            local dry = inkLabDryness((t0 + t1) * 0.5, s + 17)
            local edgeA = a.r * (0.74 + dry * 0.24 + (hash01(s + 5) - 0.5) * 0.12)
            local edgeB = b.r * (0.74 + dry * 0.24 + (hash01(s + 7) - 0.5) * 0.12)
            drawDryBrushLine(
                a.x + a.normX * edgeA * side,
                a.y + a.normY * edgeA * side,
                b.x + b.normX * edgeB * side,
                b.y + b.normY * edgeB * side,
                math.max(1.0, (a.r + b.r) * 0.075),
                dry > 0.55 and dark or body,
                34 + dry * 28,
                s + 11,
                1
            )
            if dry > 0.50 and hash01(s + 13) > 0.44 then
                local lane = (hash01(s + 19) - 0.5) * 0.50
                drawDryBrushLine(
                    a.x + a.normX * a.r * lane,
                    a.y + a.normY * a.r * lane,
                    b.x + b.normX * b.r * lane,
                    b.y + b.normY * b.r * lane,
                    math.max(0.8, (a.r + b.r) * 0.050),
                    pale,
                    24 + dry * 26,
                    s + 23,
                    1
                )
            end
        end
    end

    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local s = seed + i * 131
            local pressure = inkLabBranchPressure(t, s)
            local load = inkLabInkLoad(t, s + 300)
            local dry = inkLabDryness(t, s + 700)
            local bend = math.abs(inkLabBranchCurvature(list, t))
            local slip = (hash01(s + 5) - 0.5) * n.r * (0.10 + bend * 0.50)
            local cx = n.x + n.normX * slip
            local cy = n.y + n.normY * slip
            local contactLong = n.r * (0.50 + pressure * 0.18 + load * 0.10)
            local contactWide = n.r * (0.18 + pressure * 0.14)
            drawRotEllipse(cx, cy, contactLong, contactWide, n.angle, colorRGBA(dark, 8 + load * 10))
            if dry > 0.46 then
                local lane = (hash01(s + 17) - 0.5) * n.r * 1.15
                drawDryBrushLine(
                    cx + n.normX * lane - math.cos(n.angle) * n.r * 0.34,
                    cy + n.normY * lane - math.sin(n.angle) * n.r * 0.34,
                    cx + n.normX * lane + math.cos(n.angle) * n.r * 0.56,
                    cy + n.normY * lane + math.sin(n.angle) * n.r * 0.56,
                    math.max(0.8, n.r * 0.16),
                    pale,
                    24 + dry * 22,
                    s + 19,
                    1
                )
            end
        end
    end

    drawInkLabContinuousLane(list, -0.50, 0.28, dark, 58, seed + 2200, samples)
    drawInkLabContinuousLane(list, 0.18, 0.26, body, 44, seed + 2400, samples)

    local drySamples = math.max(4, math.min(7, math.floor(totalLen / 260)))
    for i = 1, drySamples do
        local t = i / (drySamples + 1)
        local n = inkLabSampleBranch(list, t)
        if n then
            local dry = inkLabDryness(t, seed + i * 97)
            if dry > 0.40 then
                local lane = (hash01(seed + i * 101) - 0.5) * 1.25
                local x0 = n.x + n.normX * lane * n.r - math.cos(n.angle) * n.r * (0.54 + dry * 0.18)
                local y0 = n.y + n.normY * lane * n.r - math.sin(n.angle) * n.r * (0.54 + dry * 0.18)
                local x1 = n.x + n.normX * lane * n.r + math.cos(n.angle) * n.r * (0.72 + dry * 0.35)
                local y1 = n.y + n.normY * lane * n.r + math.sin(n.angle) * n.r * (0.72 + dry * 0.35)
                drawDryBrushLine(x0, y0, x1, y1, math.max(0.8, n.r * 0.18), pale, 28 + dry * 22, seed + i * 109, 1)
            end
        end
    end
    return true
end

function drawInkLabImageBrushSweep(list, tint, alpha, seed)
    if not list or #list < 2 then return false end
    if not inkLabBranchListVisible(list, 340) then return true end
    local plan = inkLabGetStrokePlan(list, seed)
    if not plan then return false end

    drawInkLabContinuousBrushStroke(list, tint, seed)

    for _, stamp in ipairs(plan.stamps) do
        if stamp.first then
            drawInkLabPlannedStamp(stamp)
        end
    end

    return true
end

function drawInkLabFiberPath(list, lane, width, tint, alpha, seed, samples, paleMode)
    if not list or #list < 2 then return end
    local drawing = false
    local moved = false
    for i = 1, samples - 1 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local dry = inkLabDryness(t, seed)
            local noise = hash01(seed + i * 37)
            local active
            if paleMode then
                active = noise < 0.18 + dry * 0.42
            else
                active = noise > 0.22 + dry * 0.20
            end
            local jitter = math.sin(t * math.pi * 5.0 + seed * 0.023) * 0.045 + (hash01(seed + i * 41) - 0.5) * 0.075
            local off = (lane + jitter) * n.r * inkLabBranchPressure(t, seed + 19)
            local x = n.x + n.normX * off
            local y = n.y + n.normY * off
            if active then
                if not drawing then
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, x, y)
                    drawing = true
                    moved = true
                else
                    nvgLineTo(vg, x, y)
                end
            elseif drawing then
                nvgStrokeColor(vg, colorRGBA(tint, alpha))
                nvgStrokeWidth(vg, width)
                nvgStroke(vg)
                drawing = false
            end
        end
    end
    if drawing and moved then
        nvgStrokeColor(vg, colorRGBA(tint, alpha))
        nvgStrokeWidth(vg, width)
        nvgStroke(vg)
    end
end

function inkLabBranchCurvature(list, t)
    local a = inkLabSampleBranch(list, math.max(0, t - 0.035))
    local b = inkLabSampleBranch(list, t)
    local c = inkLabSampleBranch(list, math.min(1, t + 0.035))
    if not a or not b or not c then return 0 end
    local a1 = math.atan2(b.y - a.y, b.x - a.x)
    local a2 = math.atan2(c.y - b.y, c.x - b.x)
    return math.atan2(math.sin(a2 - a1), math.cos(a2 - a1))
end

function drawInkLabContactPatch(n, stepLen, tint, seed, t)
    local pressure = inkLabBranchPressure(t, seed + 1200)
    local load = inkLabInkLoad(t, seed + 2200)
    local dry = inkLabDryness(t, seed + 3200)
    local bend = inkLabBranchCurvature(currentInkLabStrokeList, t)
    local tangentX, tangentY = math.cos(n.angle), math.sin(n.angle)
    local sideSlip = math.atan2(math.sin(bend), math.cos(bend)) * n.r * 0.32
    local cx = n.x + n.normX * sideSlip
    local cy = n.y + n.normY * sideSlip
    local contactLen = math.max(stepLen * 0.78, n.r * (0.58 + pressure * 0.24))
    local contactHalf = n.r * (0.58 + pressure * 0.55 + load * 0.18)
    local inkAlpha = 7 + load * 22 + pressure * 8
    local dryAlpha = 10 + dry * 20
    local dark = C(18, 16, 14)
    local bodyTint = tint or C(34, 30, 26)

    drawRotEllipse(cx, cy, contactLen * 0.78, contactHalf * 0.82, n.angle, colorRGBA(bodyTint, inkAlpha))

    local lanes = 7
    for j = 1, lanes do
        local laneT = (j - (lanes + 1) * 0.5) / ((lanes - 1) * 0.5)
        local laneSeed = seed + j * 53
        local bristleLoad = load * (0.72 + hash01(laneSeed + math.floor(t * 97)) * 0.46)
        local laneDry = dry + math.abs(laneT) * 0.18
        if hash01(laneSeed + math.floor(t * 181)) > laneDry * 0.38 then
            local spread = contactHalf * (0.82 + dry * 0.28)
            local lx = cx + n.normX * laneT * spread + tangentX * (hash01(laneSeed + 7) - 0.5) * stepLen * 0.36
            local ly = cy + n.normY * laneT * spread + tangentY * (hash01(laneSeed + 7) - 0.5) * stepLen * 0.36
            local rx = contactLen * (0.62 + bristleLoad * 0.42)
            local ry = math.max(0.65, contactHalf * (0.12 + (1.0 - math.abs(laneT)) * 0.16) * (0.76 + pressure * 0.24))
            local a = 5 + bristleLoad * 28 + (1.0 - math.abs(laneT)) * 8
            drawRotEllipse(lx, ly, rx, ry, n.angle + (hash01(laneSeed + 11) - 0.5) * 0.05, colorRGBA(math.abs(laneT) > 0.72 and dark or bodyTint, a))
        end
    end

    if dry > 0.38 then
        local gaps = 2 + math.floor(dry * 3)
        for g = 1, gaps do
            local gapSeed = seed + g * 89
            if hash01(gapSeed + math.floor(t * 223)) < dry * 0.72 then
                local lane = (hash01(gapSeed + 3) - 0.5) * 0.92
                local gx = cx + n.normX * lane * contactHalf * 0.72 + tangentX * (hash01(gapSeed + 5) - 0.5) * contactLen * 0.50
                local gy = cy + n.normY * lane * contactHalf * 0.72 + tangentY * (hash01(gapSeed + 5) - 0.5) * contactLen * 0.50
                drawRotEllipse(gx, gy, contactLen * (0.18 + hash01(gapSeed + 7) * 0.22), contactHalf * (0.035 + hash01(gapSeed + 9) * 0.045), n.angle, colorRGBA(currentLevel.paper, dryAlpha))
            end
        end
    end
end

function drawInkLabDepositedBrushStroke(list, tint, alpha, seed)
    if not list or #list < 2 then return false end
    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return false end

    local dark = C(18, 16, 14)
    local body = tint or C(34, 30, 26)
    local samples = math.max(48, math.min(260, math.floor(totalLen / 5.2)))
    local stepLen = totalLen / samples

    currentInkLabStrokeList = list
    drawInkLabOneStrokeBody(list, body, 18, seed + 610, 0.34, C(30, 27, 24))

    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            drawInkLabContactPatch(n, stepLen, body, seed + i * 131, t)
        end
    end

    for laneIndex, lane in ipairs({ -0.72, -0.48, -0.26, -0.09, 0.08, 0.24, 0.44, 0.66 }) do
        local laneSeed = seed + laneIndex * 997
        local width = 0.85 + (1.0 - math.abs(lane)) * 1.6 + hash01(laneSeed + 5) * 0.65
        local a = 18 + (1.0 - math.abs(lane)) * 31 + hash01(laneSeed + 7) * 12
        drawInkLabFiberPath(list, lane, width, math.abs(lane) > 0.62 and dark or body, a, laneSeed, samples, false)
    end

    for laneIndex, lane in ipairs({ -0.34, -0.16, 0.12, 0.32 }) do
        local laneSeed = seed + 4100 + laneIndex * 307
        drawInkLabFiberPath(list, lane, 0.95 + hash01(laneSeed + 3) * 0.95, currentLevel.paper, 26 + hash01(laneSeed + 7) * 18, laneSeed, samples, true)
    end

    for i = 5, samples - 5, 7 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local load = inkLabInkLoad(t, seed + 2200)
            if load > 0.54 and hash01(seed + i * 67) > 0.42 then
                drawInkBleed(n.x, n.y, n.r * (0.42 + load * 0.24), n.r * (0.18 + load * 0.14), body, 5 + load * 8, seed + i * 71, 2)
            end
        end
    end

    local first = inkLabSampleBranch(list, 0.02)
    local tail = inkLabSampleBranch(list, 0.985)
    if first then
        drawInkBleed(first.x, first.y, first.r * 1.35, first.r * 0.62, dark, 32, seed + 811, 4)
    end
    if tail then
        drawDryBrushLine(
            tail.x - math.cos(tail.angle) * tail.r * 0.8,
            tail.y - math.sin(tail.angle) * tail.r * 0.8,
            tail.x + math.cos(tail.angle) * tail.r * 2.6,
            tail.y + math.sin(tail.angle) * tail.r * 2.6,
            math.max(1.1, tail.r * 0.20),
            dark,
            42,
            seed + 941,
            2
        )
    end

    currentInkLabStrokeList = nil
    return true
end

function drawInkLabVirtualBristleStroke(list, tint, alpha, seed)
    if not list or #list < 2 then return false end
    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return false end

    local dark = C(17, 15, 13)
    local wet = tint or C(38, 34, 29)
    local pale = currentLevel and currentLevel.paper or C(232, 228, 214)
    local samples = math.max(20, math.min(88, math.floor(totalLen / 14)))
    local brushLanes = { -0.78, -0.56, -0.36, -0.18, -0.04, 0.10, 0.27, 0.46, 0.66 }
    local useRepeatedFootprints = true

    drawInkLabOneStrokeBody(list, wet, 34, seed + 1800, 0.42, C(24, 21, 18))

    for i = 0, samples, 7 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local pressure = inkLabBranchPressure(t, seed + 3500)
            local load = inkLabInkLoad(t, seed + 6100)
            local s = seed + i * 71
            if useRepeatedFootprints and load > 0.72 and hash01(s + 13) > 0.48 then
                local side = (hash01(s + 3) - 0.5) * n.r * 0.18
                local w = n.r * (1.65 + hash01(s + 5) * 0.34) * pressure
                local h = n.r * (1.05 + hash01(s + 7) * 0.24) * pressure
                local a = 0.045 + load * 0.040 + hash01(s + 11) * 0.020
                drawInkLabStampChoice(
                    inkLabWetBristleStamps,
                    s,
                    n.x + n.normX * side,
                    n.y + n.normY * side,
                    w,
                    h,
                    n.angle + (hash01(s + 9) - 0.5) * 0.14,
                    a
                )
            end
        end
    end

    for laneIndex, lane in ipairs(brushLanes) do
        local laneSeed = seed + laneIndex * 389
        local laneWidthBase = 1.05 + (1.0 - math.abs(lane)) * 3.10 + hash01(laneSeed + 3) * 0.70
        local laneAlphaBase = 46 + (1.0 - math.abs(lane)) * 94 + hash01(laneSeed + 7) * 16
        local moved = false
        local drawing = false
        for i = 0, samples do
            local t = i / samples
            local n = inkLabSampleBranch(list, t)
            if n then
                local pressure = inkLabBranchPressure(t, seed + laneIndex * 17)
                local paperNoise = hash01(laneSeed + math.floor(t * 28) * 29)
                local dry = inkLabDryness(t, seed + laneIndex * 73)
                local dryGate = 0.12 + math.abs(lane) * 0.22 + dry * 0.15
                local active = paperNoise > dryGate or (math.abs(lane) < 0.20 and dry < 0.86)
                local wob = math.sin(t * math.pi * 4.0 + laneSeed * 0.17) * n.r * 0.055 + (hash01(laneSeed + i * 31) - 0.5) * n.r * 0.060
                local off = lane * n.r * pressure * 0.92 + wob
                local x = n.x + n.normX * off
                local y = n.y + n.normY * off
                if active then
                    if not drawing then
                        nvgBeginPath(vg)
                        nvgMoveTo(vg, x, y)
                        drawing = true
                        moved = true
                    else
                        nvgLineTo(vg, x, y)
                    end
                elseif drawing then
                    nvgStrokeColor(vg, colorRGBA(math.abs(lane) > 0.65 and dark or wet, laneAlphaBase * (0.62 + hash01(laneSeed + i * 37) * 0.34)))
                    nvgStrokeWidth(vg, laneWidthBase * (0.74 + pressure * 0.34))
                    nvgStroke(vg)
                    drawing = false
                end
            end
        end
        if drawing and moved then
            nvgStrokeColor(vg, colorRGBA(math.abs(lane) > 0.65 and dark or wet, laneAlphaBase * 0.98))
            nvgStrokeWidth(vg, laneWidthBase)
            nvgStroke(vg)
        end
    end

    for laneIndex, lane in ipairs({ -0.16, 0.10 }) do
        local laneSeed = seed + 2800 + laneIndex * 127
        for i = 1, samples - 1, 3 do
            local t0 = (i - 1) / (samples - 1)
            local t1 = i / (samples - 1)
            local a = inkLabSampleBranch(list, t0)
            local b = inkLabSampleBranch(list, t1)
            if a and b and hash01(laneSeed + i * 41) > 0.44 then
                local off0 = lane * a.r * inkLabBranchPressure(t0, seed)
                local off1 = lane * b.r * inkLabBranchPressure(t1, seed)
                drawDryBrushLine(
                    a.x + a.normX * off0, a.y + a.normY * off0,
                    b.x + b.normX * off1, b.y + b.normY * off1,
                    1.0 + hash01(laneSeed + i * 47) * 1.3,
                    pale,
                    18 + hash01(laneSeed + i * 53) * 20,
                    laneSeed + i * 59,
                    1
                )
            end
        end
    end

    for i = 0, samples, 8 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local pressure = inkLabBranchPressure(t, seed + 4200)
            local s = seed + i * 83
            local side = (hash01(s + 3) - 0.5) * n.r * 0.28
            local w = n.r * (1.85 + hash01(s + 5) * 0.34) * pressure
            local h = n.r * (1.15 + hash01(s + 7) * 0.24) * pressure
            if useRepeatedFootprints then
                drawInkLabStamp(
                    "bristleTip",
                    n.x + n.normX * side,
                    n.y + n.normY * side,
                    w,
                    h,
                    n.angle + (hash01(s + 9) - 0.5) * 0.18,
                    0.040 + hash01(s + 11) * 0.025
                )
            end
        end
    end

    for laneIndex, lane in ipairs({ -0.32, -0.14, 0.10, 0.30 }) do
        local laneSeed = seed + 8400 + laneIndex * 173
        drawInkLabFiberPath(list, lane, 1.25 + hash01(laneSeed + 3) * 1.15, pale, 34 + hash01(laneSeed + 7) * 22, laneSeed, samples, true)
    end
    for sideIndex, lane in ipairs({ -0.88, 0.88 }) do
        local laneSeed = seed + 6900 + sideIndex * 211
        drawInkLabFiberPath(list, lane, 0.95 + hash01(laneSeed + 3) * 1.35, dark, 30 + hash01(laneSeed + 7) * 22, laneSeed, samples, false)
    end

    for i = 1, samples - 1 do
        if i % 5 == 0 then
            local t = i / (samples - 1)
            local n = inkLabSampleBranch(list, t)
            if n and hash01(seed + i * 67) > 0.35 then
                drawInkBleed(n.x, n.y, n.r * (0.68 + hash01(seed + i * 71) * 0.34), n.r * 0.34, wet, 10 + hash01(seed + i * 73) * 14, seed + i * 79, 2)
            end
        end
    end

    local first = inkLabSampleBranch(list, 0.02)
    local tail = inkLabSampleBranch(list, 0.985)
    if first then
        drawInkBleed(
            first.x - math.cos(first.angle) * first.r * 0.45,
            first.y - math.sin(first.angle) * first.r * 0.45,
            first.r * 1.28,
            first.r * 0.58,
            dark,
            24,
            seed + 811,
            3
        )
        drawDryBrushLine(
            first.x - math.cos(first.angle) * first.r * 1.5,
            first.y - math.sin(first.angle) * first.r * 1.5,
            first.x + math.cos(first.angle) * first.r * 0.9,
            first.y + math.sin(first.angle) * first.r * 0.9,
            math.max(1.0, first.r * 0.20),
            dark,
            36,
            seed + 829,
            2
        )
    end
    if tail then
        drawDryBrushLine(
            tail.x - math.cos(tail.angle) * tail.r * 0.7,
            tail.y - math.sin(tail.angle) * tail.r * 0.7,
            tail.x + math.cos(tail.angle) * tail.r * 2.1,
            tail.y + math.sin(tail.angle) * tail.r * 2.1,
            math.max(1.1, tail.r * 0.22),
            dark,
            34,
            seed + 941,
            2
        )
    end

    return true
end

function drawInkLabRuntimeFootprintAccents(list, tint, seed)
    if not list or #list < 2 then return false end
    if not inkLabBranchListVisible(list, 220) then return true end
    local plan = inkLabGetStrokePlan(list, (seed or 0) - 1000)
    if not plan then return false end
    local body = tint or C(39, 35, 30)
    for _, accent in ipairs(plan.accents) do
        local tone = inkLabPlanTone(accent.tone, body)
        if accent.kind == "ellipse" then
            if accent.tone ~= "body" then
                drawRotEllipse(accent.x, accent.y, accent.rx, accent.ry, accent.angle, colorRGBA(tone, accent.alpha))
            end
        elseif accent.kind == "stamp" then
            drawInkLabStampChoice(accent.names, accent.seed, accent.x, accent.y, accent.w, accent.h, accent.angle, accent.alpha)
        elseif accent.kind == "dryLine" then
            drawDryBrushLine(accent.x0, accent.y0, accent.x1, accent.y1, accent.width, tone, accent.alpha, accent.seed, 1)
        elseif accent.kind == "bleed" then
            drawInkBleed(accent.x, accent.y, accent.rx, accent.ry, tone, accent.alpha, accent.seed, 1)
        end
    end

    return true
end

function drawInkLabSoftRibbon(list, tint, alpha, seed)
    if not currentLevelIsInkLab() or not list or #list < 2 then return false end
    if not inkLabBranchListVisible(list, 360) then return true end
    local body = tint or C(39, 35, 30)
    local s = seed or 0
    drawInkLabImageBrushSweep(list, body, alpha or 214, s + 700)
    drawInkLabRuntimeFootprintAccents(list, body, s + 1700)
    return true
end

function drawInkLabPineBackground()
    if not currentLevelIsInkLab() then return end
    for i = 0, 5 do
        local x = W(0.06 + i * 0.105)
        local y = H(0.18 + hash01(1600 + i * 13) * 0.52)
        drawInkLabStamp("paper", x, y, 660, 560, (hash01(1700 + i) - 0.5) * 0.08, 0.22)
    end
    for i = 1, 8 do
        local seed = 2100 + i * 37
        local x = hash01(seed) * worldW
        local y = H(0.12 + hash01(seed + 3) * 0.60)
        local s = 180 + hash01(seed + 5) * 340
        drawInkLabStamp("bleed", x, y, s * 1.6, s * 0.86, (hash01(seed + 7) - 0.5) * 0.6, 0.10 + hash01(seed + 11) * 0.08)
    end
    for i = 1, 10 do
        local seed = 2600 + i * 31
        local x = hash01(seed) * worldW
        local y = H(0.20 + hash01(seed + 2) * 0.48)
        local len = 180 + hash01(seed + 5) * 300
        if inkLabIsVisible(x + len * 0.5, y, len * 0.6) then
            drawDryBrushLine(x, y, x + len, y + (hash01(seed + 7) - 0.5) * 28, 0.8 + hash01(seed + 11) * 1.6, currentLevel.ink, 18 + hash01(seed + 13) * 26, seed, 1)
        end
    end
end

function drawInkLabBranchMaterial(id, list)
    if not currentLevelIsInkLab() or not list or #list < 2 then return end
    if id:find("poetry") or id:find("pavilion") then return end
    if not inkLabBranchListVisible(list, 220) then return end

    local step = math.max(9, math.floor(#list / 8))
    for i = 3, #list - 3, step * 2 do
        local prev, n, nextN = list[i - 2], list[i], list[i + 2]
        local a1 = math.atan2(n.y - prev.y, n.x - prev.x)
        local a2 = math.atan2(nextN.y - n.y, nextN.x - n.x)
        local bend = math.abs(math.atan2(math.sin(a2 - a1), math.cos(a2 - a1)))
        if bend > 0.18 then
            local seed = i * 59 + n.x * 0.01 + n.y * 0.02
            drawInkBleed(n.x, n.y, n.r * 0.40, n.r * 0.16, C(18, 16, 13), 4 + hash01(seed + 3) * 4, seed, 2)
            drawDryBrushLine(
                n.x - math.cos(a2) * n.r * 0.72,
                n.y - math.sin(a2) * n.r * 0.72,
                n.x + math.cos(a2) * n.r * 0.92,
                n.y + math.sin(a2) * n.r * 0.92,
                math.max(0.75, n.r * 0.12),
                C(18, 16, 13),
                18 + hash01(seed + 9) * 12,
                seed + 17,
                1
            )
        end
    end

    local first, second = list[1], list[math.min(#list, step + 1)]
    if first and second then
        local dx, dy = second.x - first.x, second.y - first.y
        local angle = math.atan2(dy, dx)
        local startSeed = (#id * 83) + first.x * 0.013 + first.y * 0.017
        drawInkBleed(first.x, first.y, first.r * 0.48, first.r * 0.20, C(18, 16, 13), 6 + hash01(startSeed) * 5, startSeed, 2)
    end

    if #list > 3 then
        local tailA = list[math.max(1, #list - step)]
        local tailB = list[#list]
        local dx, dy = tailB.x - tailA.x, tailB.y - tailA.y
        local len = dist2(dx, dy)
        if len > 4 then
            local angle = math.atan2(dy, dx)
            drawDryBrushLine(
                tailB.x - math.cos(angle) * tailB.r * 0.4,
                tailB.y - math.sin(angle) * tailB.r * 0.4,
                tailB.x + math.cos(angle) * tailB.r * 2.3,
                tailB.y + math.sin(angle) * tailB.r * 2.3,
                math.max(1.0, tailB.r * 0.18),
                C(18, 16, 13),
                28,
                tailB.x * 0.017 + tailB.y * 0.013,
                2
            )
        end
    end
end

function drawInkLabBranchOverlay()
    -- Kept for older call sites. Branch texture now belongs inside drawBranches,
    -- immediately after the branch ribbon fill and before edge lines/targets.
end

function drawInkLabNeedleTexture(x, y, nx, ny, lenBase, alpha, seed)
    if not currentLevelIsInkLab() then return end
    local base = math.atan2(ny or -1, nx or 0)
    local size = (lenBase or 36) * 2.55
    if not inkLabIsVisible(x, y, size * 0.75) then return end
    drawInkLabStamp("needle", x + (nx or 0) * size * 0.12, y + (ny or -1) * size * 0.12, size, size, base + math.pi * 0.5, 0.46)
    for i = 1, 3 do
        local s = (seed or 0) + i * 67
        local a = base + (hash01(s) - 0.5) * 1.55
        local l = (lenBase or 36) * (0.45 + hash01(s + 3) * 0.72)
        drawDryBrushLine(x, y, x + math.cos(a) * l, y + math.sin(a) * l * 0.78, 0.55 + hash01(s + 5) * 0.9, C(6, 18, 10), (alpha or 120) * 0.26, s, 1)
    end
end

function drawInkLabPineConeAura(t, r)
    if not currentLevelIsInkLab() then return end
    drawInkLabStamp("bleed", t.x, t.y, r * 3.8, r * 3.0, t.pulse or 0, 0.18)
    if hash01(t.x * 0.011 + t.y * 0.017 + elapsed * 0.6) > 0.52 then
        drawCircle(t.x, t.y, r * 1.35, rgba(92, 58, 24, 20))
    end
end

function spawnInkLabHitFeedback(t)
    if not currentLevelIsInkLab() then return end
    windWaves[#windWaves + 1] = { x = t.x, y = t.y, r = 0, life = 26, maxLife = 26 }
    for i = 1, 10 do addBristle(t.x, t.y, -player.vx * 0.2, -player.vy * 0.2, "gold") end
    for i = 1, 16 do addBristle(t.x, t.y, player.vx * 0.15, player.vy * 0.15, "inkgas") end
end

-- ============================================================================
-- END scripts/src/65_inklab_render.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/66_ldtk_grand_scroll_render.lua
-- ============================================================================
-- Rendering helpers for the LDtk grand-scroll bridge.

function ldtkVisible(x, y, w, h, pad)
    pad = pad or 160
    return x + w >= cameraX - pad and x <= cameraX + DESIGN_W + pad and y + h >= cameraY - pad and y <= cameraY + DESIGN_H + pad
end

function drawLDtkGrandScrollDecorWash()
    if not ldtkDecor then return end

    for _, r in ipairs(ldtkDecor) do
        if ldtkVisible(r.x, r.y, r.w, r.h, 220) then
            local cx, cy = r.x + r.w * 0.5, r.y + r.h * 0.5
            if r.v == 1 then
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(currentLevel.wash, 9))
                drawDryBrushLine(r.x, r.y + r.h * 0.28, r.x + r.w, r.y + r.h * 0.55, math.max(1.0, math.min(5.0, r.h * 0.16)), currentLevel.wash, 34, r.x * 0.017 + r.y * 0.011, 1)
            elseif r.v == 2 then
                drawInkBleed(cx, cy, math.max(28, r.w * 0.58), math.max(10, r.h * 1.8), currentLevel.paper, 34, r.x * 0.019 + r.y * 0.013, 2)
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(C(207, 215, 202), 10))
            elseif r.v == 3 then
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(currentLevel.water, 13))
                drawDryBrushLine(r.x, cy, r.x + r.w, cy + math.sin(r.x * 0.014) * 4, math.max(1.0, math.min(4.0, r.h * 0.22)), currentLevel.water, 45, r.x * 0.009 + r.y * 0.021, 1)
            elseif r.v == 4 then
                local x = cx + math.sin(r.y * 0.03) * 3
                drawDryBrushLine(x, r.y + r.h, x + math.sin(r.x * 0.02) * 8, r.y, math.max(1.2, math.min(4.2, r.w * 0.32)), currentLevel.accent, 58, r.x * 0.021 + r.y * 0.017, 1)
            elseif r.v == 5 then
                drawInkBleed(cx, cy, math.max(12, r.w * 1.7), math.max(8, r.h * 1.8), currentLevel.bloom, 24, r.x * 0.027 + r.y * 0.019, 2)
                drawRotEllipse(cx, cy, math.max(5, r.w * 0.62), math.max(3, r.h * 0.72), math.sin(cx * 0.01) * 0.8, colorRGBA(currentLevel.bloom, 62))
            elseif r.v == 6 then
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(currentLevel.ink, 22))
                drawDryBrushLine(r.x, r.y + r.h * 0.35, r.x + r.w, r.y + r.h * 0.56, math.max(1.0, math.min(6.0, r.h * 0.20)), currentLevel.ink, 74, r.x * 0.012 + r.y * 0.018, 1)
            end
        end
    end
end

function drawLDtkGrandScrollBackdrop()
    if not currentLevelIsLDtkGrandScroll() then return end
    drawVerticalWash(0, worldH, C(224, 231, 220), C(242, 235, 218), 54, 26, 28)
    drawMountainBandAt(1210, 7, C(92, 118, 102), 12, 0.20, 0.22, 0.18, 0.34, -220)
    drawMistBand(1220, 24, currentLevel.paper, 30, 0.08, 0.76, 160, 520, 18, 92)

    local bands = {
        { x = 0, w = 1550, tint = C(64, 106, 76), alpha = 14 },
        { x = 1550, w = 1500, tint = C(70, 88, 65), alpha = 12 },
        { x = 3050, w = 1400, tint = C(118, 150, 122), alpha = 12 },
        { x = 4450, w = 1500, tint = C(116, 82, 70), alpha = 13 },
        { x = 5950, w = 1600, tint = C(126, 98, 62), alpha = 13 },
        { x = 7550, w = 2050, tint = C(156, 180, 172), alpha = 16 },
    }
    for _, b in ipairs(bands) do
        if ldtkVisible(b.x, 0, b.w, worldH, 260) then
            drawRect(b.x, 0, b.w, worldH, 0, colorRGBA(b.tint, b.alpha))
            for i = 1, 6 do
                local x = b.x + hash01(b.x * 0.017 + i * 19) * b.w
                strokeLine(x, H(0.06), x + (hash01(i * 41 + b.x) - 0.5) * 220, H(0.86), 0.8, colorRGBA(b.tint, b.alpha * 1.8))
            end
        end
    end
    drawLDtkGrandScrollDecorWash()
end

function drawLDtkGrandScrollCollisionInk()
    if not currentLevelIsLDtkGrandScroll() then return end

    for _, r in ipairs(ldtkSolidRects) do
        if ldtkVisible(r.x, r.y, r.w, r.h, 80) then
            if r.y < worldH - 80 then
                local bodyAlpha = r.h > 70 and 8 or 3
                drawRect(r.x, r.y + math.max(6, r.h * 0.18), r.w, math.max(4, r.h * 0.70), 0, colorRGBA(currentLevel.ink, bodyAlpha))
                drawDryBrushLine(r.x, r.y + 1, r.x + r.w, r.y + math.sin(r.x * 0.01) * 3, math.max(1.0, math.min(3.0, r.h * 0.06)), currentLevel.ink, 42, r.x * 0.011 + r.y * 0.013, 1)
                if r.w > 42 and r.h > 18 then
                    drawDryBrushLine(r.x + 4, r.y + r.h * 0.48, r.x + r.w - 4, r.y + r.h * 0.45 + math.sin(r.y * 0.014) * 2, 0.65, currentLevel.paper, 18, r.x * 0.017, 1)
                end
            end
        end
    end

    for _, r in ipairs(ldtkOneWayRects) do
        if ldtkVisible(r.x, r.y, r.w, r.h, 80) then
            drawDryBrushLine(r.x, r.y + 2, r.x + r.w, r.y + math.sin(r.x * 0.02) * 4, math.max(1.4, math.min(3.8, r.h * 0.10)), currentLevel.accent, 58, r.x * 0.019 + r.y * 0.007, 1)
            drawDryBrushLine(r.x + 8, r.y + r.h * 0.45, r.x + r.w - 8, r.y + r.h * 0.42, 0.7, currentLevel.ink, 20, r.x * 0.013, 1)
        end
    end
end

function drawLDtkGrandScrollWaterAndPetals()
    if not currentLevelIsLDtkGrandScroll() then return end

    for _, fall in ipairs(ldtkWaterfalls) do
        if ldtkVisible(fall.x, fall.y, fall.w, fall.h, 220) then
            local cx = fall.x + fall.w * 0.45
            drawRect(fall.x, fall.y - 120, fall.w, fall.h + 180, 0, colorRGBA(currentLevel.paper, 24))
            for i = 1, 18 do
                local x = fall.x + hash01(i * 23 + fall.x) * fall.w
                local y1 = fall.y - 120 + hash01(i * 29 + fall.y) * 110
                local y2 = fall.y + fall.h + hash01(i * 31 + fall.x) * 120
                drawDryBrushLine(x, y1, x + math.sin(elapsed * 1.6 + i) * 20, y2, 1.2 + hash01(i * 37) * 4.2, currentLevel.paper, 84 + hash01(i * 41) * 72, i * 47 + fall.x, 2)
            end
            drawInkBleed(cx, fall.y + fall.h * 0.86, fall.w * 0.42, 38, currentLevel.water, 26, fall.x * 0.013 + fall.y * 0.019, 4)
        end
    end

    for _, p in ipairs(floatingPetals) do
        local y = p.y + math.sin(p.bob) * 4
        if ldtkVisible(p.x - p.w, y - p.h, p.w * 2, p.h * 2, 80) then
            nvgSave(vg)
            nvgTranslate(vg, p.x, y)
            nvgRotate(vg, math.sin(p.bob) * 0.16)
            fillPetalShape(p.w * 0.55, p.h * 0.70, colorRGBA(currentLevel.bloom, 170))
            nvgRestore(vg)
            drawDryBrushLine(p.x - p.w * 0.12, y + p.h * 0.10, p.x + p.w * 0.16, y + p.h * 0.46, 0.85, C(96, 55, 70), 48, p.x * 0.017 + p.y * 0.013, 1)
        end
    end
end

function drawLDtkGrandScrollLabels()
    if not currentLevelIsLDtkGrandScroll() then return end

    for _, label in ipairs(ldtkLabels) do
        if ldtkVisible(label.x, label.y, 260, 40, 120) then
            drawText(label.x, label.y, 18, colorRGBA(currentLevel.ink, 150), label.text)
            strokeLine(label.x, label.y + 26, label.x + 210, label.y + 26, 1.1, colorRGBA(currentLevel.ink, 72))
        end
    end

    for _, cp in ipairs(ldtkCheckpoints) do
        if ldtkVisible(cp.x - 20, cp.y - 36, 40, 72, 80) then
            drawDryBrushLine(cp.x, cp.y + 30, cp.x, cp.y - 30, 2.0, currentLevel.accent, 140, cp.x * 0.013, 1)
            drawRect(cp.x - 13, cp.y - 36, 26, 18, 0, rgba(150, 35, 30, 155))
        end
    end

    if ldtkExit and ldtkVisible(ldtkExit.x - 70, ldtkExit.y - 120, 160, 220, 160) then
        drawRect(ldtkExit.x - 18, ldtkExit.y - 58, 48, 92, 0, rgba(150, 35, 30, 128))
        drawStrokeRect(ldtkExit.x - 18, ldtkExit.y - 58, 48, 92, 0, rgba(35, 20, 16, 196), 2)
        drawDryBrushLine(ldtkExit.x - 62, ldtkExit.y + 36, ldtkExit.x + 88, ldtkExit.y + 36, 5, currentLevel.ink, 128, ldtkExit.x * 0.01, 2)
    end
end

-- ============================================================================
-- END scripts/src/66_ldtk_grand_scroll_render.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/70_entities_targets_render.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.

local function masterPlumBranchAlpha(id)
    if id == "master_trunk" then return 62 end
    if id:find("twig") then return 48 end
    return 54
end

function drawPineNeedleCluster(x, y, nx, ny, lenBase, count, spread, seed, alpha)
    local base = math.atan2(ny or -1, nx or 0)
    local needleTint = currentLevel.id == "huangshan" and C(32, 86, 58) or C(28, 76, 43)
    local darkTint = currentLevel.id == "huangshan" and C(11, 30, 21) or C(9, 24, 15)
    for layer = 1, 2 do
        local layerCount = math.floor((count or 18) * (layer == 1 and 1 or 0.72))
        local layerLen = (lenBase or 36) * (layer == 1 and 1.0 or 0.72)
        local layerSpread = (spread or 1.15) * (layer == 1 and 1.0 or 0.62)
        nvgBeginPath(vg)
        for i = 0, layerCount - 1 do
            local t = layerCount <= 1 and 0.5 or i / (layerCount - 1)
            local s = seed + layer * 997 + i * 37
            local a = base + (t - 0.5) * layerSpread + (hash01(s) - 0.5) * 0.23
            local len = layerLen * (0.62 + hash01(s + 5) * 0.68)
            local bend = (hash01(s + 7) - 0.5) * len * 0.18
            local tx, ty = math.cos(a), math.sin(a)
            local px = x + tx * len - ty * bend
            local py = y + ty * len + tx * bend
            nvgMoveTo(vg, x, y)
            nvgLineTo(vg, px, py)
        end
        nvgStrokeColor(vg, colorRGBA(layer == 1 and needleTint or darkTint, (alpha or 130) * (layer == 1 and 0.82 or 0.52)))
    nvgStrokeWidth(vg, layer == 1 and 1.15 or 0.75)
        nvgStroke(vg)
    end
    drawRotEllipse(x, y, (lenBase or 36) * 0.20, (lenBase or 36) * 0.08, base, colorRGBA(needleTint, (alpha or 130) * 0.12))
    if currentLevelIsInkLab and currentLevelIsInkLab() then
        drawInkLabNeedleTexture(x, y, nx or 0, ny or -1, lenBase or 36, alpha or 130, seed or 0)
    end
end

function drawTinyBlossom(x, y, r, tintA, tintB, centerTint, seed, alpha, petals)
    local n = petals or 5
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, hash01(seed + 3) * math.pi * 2)
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2 + (hash01(seed + i * 13) - 0.5) * 0.25
        nvgSave(vg)
        nvgRotate(vg, a)
        fillPetalShape(r * (0.88 + hash01(seed + i * 17) * 0.22), r * (0.33 + hash01(seed + i * 19) * 0.10), colorRGBA(i % 2 == 0 and tintA or tintB, (alpha or 150) * (0.82 + hash01(seed + i * 23) * 0.18)))
        nvgRestore(vg)
    end
    drawCircle(0, 0, r * 0.16, colorRGBA(centerTint, alpha or 150))
    nvgRestore(vg)
    drawInkSpeckles(x - r * 0.55, y - r * 0.55, r * 1.1, r * 1.1, centerTint, (alpha or 150) * 0.28, seed + 41, 7)
end

molongHeadImage = nil
molongHeadImageTried = false

-- 加载从《九龙图》真迹抠出的龙首墨迹贴图(带透明通道,朝右)
function tryLoadMolongHeadImage()
    if molongHeadImageTried or vg == nil then return molongHeadImage ~= nil end
    molongHeadImageTried = true
    if type(nvgCreateImage) ~= "function" then return false end
    for _, path in ipairs({ "assets/ink_atlas/dragon_head_chen_rong.png", "ink_atlas/dragon_head_chen_rong.png" }) do
        local ok, img = pcall(nvgCreateImage, vg, path, 0)
        if ok and img and img > 0 then
            molongHeadImage = img
            return true
        end
    end
    return false
end

-- 陈容《九龙图》式龙首精绘:分层 口腔/上颚/下颚/獠牙/金睛/火焰眉/鹿角/鬃毛/长须/颌髯
-- (hx,hy) 为颅心锚点(随龙身行波),sc 为整体缩放,面朝右
function drawMolongHead(hx, hy, sc)
    local ink = currentLevel.ink
    local paper = currentLevel.paper
    local function P(pts)
        local out = {}
        for _, q in ipairs(pts) do out[#out + 1] = { hx + q[1] * sc, hy + q[2] * sc } end
        return out
    end
    -- 口腔(张口的留白)
    fillPoly(P({ { 6, 0 }, { 78, -6 }, { 84, 18 }, { 8, 22 } }), colorRGBA(paper, 185))
    -- 上颚与颅顶:长吻,鼻端隆起
    fillPoly(P({
        { -56, 6 }, { -54, -16 }, { -34, -26 }, { -8, -32 }, { 16, -28 },
        { 40, -24 }, { 62, -18 }, { 80, -10 }, { 86, -4 }, { 74, -2 },
        { 46, 0 }, { 14, 2 }, { -22, 6 },
    }), colorRGBA(ink, 245))
    -- 鼻端上卷
    strokeQuad(hx + 84 * sc, hy - 8 * sc, hx + 94 * sc, hy - 18 * sc, hx + 86 * sc, hy - 26 * sc, 2.6 * sc, colorRGBA(ink, 230))
    -- 下颚:钩状颌尖
    fillPoly(P({
        { 4, 12 }, { 32, 16 }, { 58, 20 }, { 80, 18 }, { 88, 24 },
        { 64, 34 }, { 36, 36 }, { 8, 30 }, { -12, 20 },
    }), colorRGBA(ink, 245))
    -- 獠牙:上 4 下 3(纸色尖三角)
    for k = 0, 3 do
        local tx = (22 + k * 16) * sc
        fillPoly({ { hx + tx, hy - 1 * sc }, { hx + tx + 4 * sc, hy + 11 * sc }, { hx + tx + 8 * sc, hy - 1 * sc } }, colorRGBA(paper, 235))
    end
    for k = 0, 2 do
        local tx = (30 + k * 17) * sc
        fillPoly({ { hx + tx, hy + 17 * sc }, { hx + tx + 4 * sc, hy + 7 * sc }, { hx + tx + 8 * sc, hy + 17 * sc } }, colorRGBA(paper, 225))
    end
    -- 金睛圆瞪:眼眶留白圈 + 金珠 + 浓墨点睛
    nvgBeginPath(vg)
    nvgCircle(vg, hx - 6 * sc, hy - 16 * sc, 10.5 * sc)
    nvgStrokeWidth(vg, 2.2 * sc)
    nvgStrokeColor(vg, colorRGBA(paper, 200))
    nvgStroke(vg)
    drawCircle(hx - 6 * sc, hy - 16 * sc, 8.2 * sc, rgba(216, 174, 64, 245))
    drawCircle(hx - 4 * sc, hy - 16 * sc, 3.8 * sc, rgba(10, 8, 6, 250))
    -- 火焰眉:眼上两束后掠焰
    strokeQuad(hx + 2 * sc, hy - 26 * sc, hx - 16 * sc, hy - 38 * sc, hx - 38 * sc, hy - 40 * sc, 3.4 * sc, colorRGBA(ink, 235))
    strokeQuad(hx + 4 * sc, hy - 30 * sc, hx - 10 * sc, hy - 46 * sc, hx - 30 * sc, hy - 52 * sc, 2.2 * sc, colorRGBA(ink, 195))
    -- 鹿角双枝:主梁后掠 + 两级分叉
    for side = 0, 1 do
        local bx = hx + (-14 - side * 10) * sc
        local by = hy + (-26 - side * 3) * sc
        local a1x, a1y = bx - 26 * sc, by - 26 * sc
        local a2x, a2y = bx - 58 * sc, by - 38 * sc
        local a3x, a3y = bx - 84 * sc, by - 42 * sc
        strokeQuad(bx, by, a1x, a1y, a2x, a2y, (3.6 - side) * sc, colorRGBA(ink, 240))
        strokeQuad(a2x, a2y, (a2x + a3x) * 0.5, a2y - 6 * sc, a3x, a3y, (2.4 - side * 0.6) * sc, colorRGBA(ink, 225))
        strokeQuad(a1x, a1y, a1x - 8 * sc, a1y - 16 * sc, a1x - 10 * sc, a1y - 28 * sc, 2.0 * sc, colorRGBA(ink, 215))
        strokeQuad(a2x, a2y, a2x - 4 * sc, a2y - 14 * sc, a2x - 2 * sc, a2y - 24 * sc, 1.6 * sc, colorRGBA(ink, 200))
    end
    -- 鬃毛:颅后五束飞扬火焰
    for k = 0, 4 do
        local oy = (-18 + k * 8) * sc
        local ln = (66 + hash01(k * 7.7) * 44) * sc
        strokeQuad(hx - 30 * sc, hy + oy, hx - 30 * sc - ln * 0.5, hy + oy - 14 * sc - k * 2 * sc,
            hx - 30 * sc - ln, hy + oy + (k - 2) * 6 * sc, (3.0 - k * 0.35) * sc, colorRGBA(ink, 215 - k * 18))
    end
    -- 长须:吻端两根细长 S 须
    strokeQuad(hx + 78 * sc, hy - 8 * sc, hx + 120 * sc, hy - 30 * sc, hx + 165 * sc, hy - 22 * sc, 1.5 * sc, colorRGBA(ink, 200))
    strokeQuad(hx + 165 * sc, hy - 22 * sc, hx + 196 * sc, hy - 16 * sc, hx + 214 * sc, hy - 30 * sc, 1.1 * sc, colorRGBA(ink, 165))
    strokeQuad(hx + 80 * sc, hy + 14 * sc, hx + 124 * sc, hy + 34 * sc, hx + 170 * sc, hy + 30 * sc, 1.5 * sc, colorRGBA(ink, 200))
    strokeQuad(hx + 170 * sc, hy + 30 * sc, hx + 200 * sc, hy + 26 * sc, hx + 220 * sc, hy + 40 * sc, 1.1 * sc, colorRGBA(ink, 165))
    -- 颌髯:下颚四束短髯
    for k = 0, 3 do
        local bx = hx + (12 + k * 14) * sc
        strokeQuad(bx, hy + 30 * sc, bx - 4 * sc, hy + 44 * sc, bx - 12 * sc, hy + 54 * sc, 1.6 * sc, colorRGBA(ink, 185 - k * 12))
    end
    -- 颊纹三道
    for k = 0, 2 do
        strokeQuad(hx + (-30 + k * 6) * sc, hy + (-6 + k * 7) * sc, hx + (-14 + k * 8) * sc, hy + (-2 + k * 7) * sc,
            hx + (2 + k * 8) * sc, hy + (2 + k * 6) * sc, 1.1 * sc, colorRGBA(paper, 60))
    end
end

function drawOutlineBlossom(x, y, r, inkTint, alpha, seed)
    -- 圈花白描（王冕双钩圈花法）：空心花瓣圈 + 浓墨点蕊
    local isBud = hash01(seed + 51) > 0.66
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, hash01(seed + 3) * math.pi * 2)
    if isBud then
        nvgBeginPath(vg)
        nvgCircle(vg, 0, 0, r * 0.52)
        nvgStrokeWidth(vg, 1.5)
        nvgStrokeColor(vg, colorRGBA(inkTint, alpha))
        nvgStroke(vg)
        drawCircle(0, -r * 0.18, r * 0.16, colorRGBA(inkTint, alpha * 0.9))
    else
        for i = 0, 4 do
            local a = i / 5 * math.pi * 2 + (hash01(seed + i * 13) - 0.5) * 0.3
            local d = r * (0.55 + hash01(seed + i * 17) * 0.12)
            local pr = r * (0.40 + hash01(seed + i * 19) * 0.10)
            nvgBeginPath(vg)
            nvgCircle(vg, math.cos(a) * d, math.sin(a) * d, pr)
            nvgStrokeWidth(vg, 1.4 + hash01(seed + i * 23) * 0.5)
            nvgStrokeColor(vg, colorRGBA(inkTint, alpha * (0.78 + hash01(seed + i * 29) * 0.22)))
            nvgStroke(vg)
        end
        -- 点蕊：浓墨数点 + 细蕊丝
        for i = 1, 5 do
            local a = hash01(seed + i * 31) * math.pi * 2
            local d = r * 0.30 * hash01(seed + i * 37)
            drawCircle(math.cos(a) * d, math.sin(a) * d, 1.1 + hash01(seed + i * 41) * 0.9, colorRGBA(inkTint, math.min(255, alpha * 1.25)))
        end
        for i = 1, 3 do
            local a = hash01(seed + i * 43) * math.pi * 2
            strokeLine(0, 0, math.cos(a) * r * 0.42, math.sin(a) * r * 0.42, 0.7, colorRGBA(inkTint, alpha * 0.8))
        end
    end
    nvgRestore(vg)
end

local function drawBranches()
    local inkLabWorldLayerActive = false
    if currentLevelIsInkLab and currentLevelIsInkLab() and currentLevel.id == "pine" and drawInkLabWorldStrokeLayer then
        inkLabWorldLayerActive = drawInkLabWorldStrokeLayer()
    end
    for id, list in pairs(branchGroups) do
        local mainTint = currentLevel.id == "pine" and C(45, 38, 32) or currentLevel.ink
        local mainAlpha = 232
        local isLDtkRoute = currentLevel.id == "ldtk_grand_scroll" and id:find("^ldtk_route_") ~= nil
        local isInkLabPine = currentLevelIsInkLab and currentLevelIsInkLab() and currentLevel.id == "pine"
        local inkLabVisibleBranch = true
        if isInkLabPine and inkLabBranchListVisible then
            inkLabVisibleBranch = inkLabBranchListVisible(list, 360)
        end
        if isInkLabPine then
            mainTint, mainAlpha = C(39, 35, 30), 214
        end
        if id:find("poetry") then mainTint, mainAlpha = currentLevel.ink, 150 end
        if currentLevel.id == "plum_master" then mainTint, mainAlpha = C(34, 27, 22), masterPlumBranchAlpha(id) end
        if isLDtkRoute then mainTint, mainAlpha = C(34, 30, 24), 112 end
        local isPavilion = id:find("pavilion") ~= nil
        if isPavilion then mainTint, mainAlpha = currentLevel.ink, 95 end
        -- 墨龙关:龙首/龙角的视觉交给真迹贴图,默认色带隐藏(碰撞仍在)
        local isMolongHeadPart = currentLevel.id == "molong" and (id == "dragon_head" or id == "dragon_horn")
        if isMolongHeadPart and not showDebug then
            mainAlpha = 0
        end
        if ((not isPavilion) or showDebug) and inkLabVisibleBranch and not (isMolongHeadPart and not showDebug) then
            if (not isPavilion) and not (currentLevel.id == "plum_master" and id:find("twig")) then
                local isInkLabBranch = isInkLabPine and drawInkLabSoftRibbon
                if isLDtkRoute then
                    fillBrushRibbon(list, mainTint, mainAlpha, (#id * 37) + (list[1] and list[1].x or 0) * 0.01)
                elseif isInkLabBranch and not inkLabWorldLayerActive then
                    drawInkLabSoftRibbon(list, mainTint, mainAlpha, (#id * 37) + (list[1] and list[1].x or 0) * 0.01)
                elseif not isInkLabPine then
                    fillBrushRibbon(list, mainTint, mainAlpha, (#id * 37) + (list[1] and list[1].x or 0) * 0.01)
                end
                if isInkLabPine and (not inkLabWorldLayerActive) and drawInkLabBranchMaterial then
                    drawInkLabBranchMaterial(id, list)
                end
            end
            if not (isInkLabPine and inkLabWorldLayerActive and not showDebug) then
                for i = 1, #list - 1 do
                    local n1, n2 = list[i], list[i + 1]
                    local angle = math.atan2(n2.y - n1.y, n2.x - n1.x)
                    local showBrushNode = isPavilion or (currentLevel.id ~= "plum_master" and (i == 1 or i % 8 == 0))
                    if isInkLabPine then
                        showBrushNode = false
                    end
                    if isLDtkRoute then
                        showBrushNode = false
                    end
                    if currentLevel.id == "plum_mirror" or currentLevel.id == "plum_finale" then
                        showBrushNode = (i == 1 or i % 16 == 0)
                    end
                    if showBrushNode then
                        local nodeScale = currentLevel.id == "plum_master" and 0.56 or 1.0
                        local nodeAlpha = currentLevel.id == "plum_master" and math.min(64, mainAlpha) or math.min(190, mainAlpha)
                        if isInkLabPine then
                            nodeScale = 0.76
                            nodeAlpha = 82
                        end
                        drawRotEllipse(n1.x, n1.y, n1.r * nodeScale * (0.82 + hash01(i + n1.x) * 0.18), n1.r * nodeScale * (0.55 + hash01(i + n1.y) * 0.18), angle, colorRGBA(mainTint, isPavilion and mainAlpha or nodeAlpha))
                    end
                    if (not isLDtkRoute) and (not isPavilion) and (not isInkLabPine) and currentLevel.id ~= "plum_master" and currentLevel.id ~= "plum_mirror" and currentLevel.id ~= "plum_finale" and i % 11 == 0 then
                        drawInkBleed(n1.x, n1.y, n1.r * 1.15, n1.r * 0.68, mainTint, 28, n1.x * 0.019 + n1.y * 0.013 + i, 2)
                    end
                    if showDebug then drawCircle(n1.x, n1.y, 2, rgba(255, 220, 20, 180)) end
                    if (not isPavilion) and currentLevel.id == "plum_master" then
                        if id:find("twig") or i % 3 == 0 then
                            local w = id:find("twig") and math.max(0.65, n1.r * 0.26) or 0.95
                            local a = id:find("twig") and 70 or 54
                            drawDryBrushLine(n1.x, n1.y, n2.x, n2.y, w, C(20, 16, 13), a, i * 17 + n1.x * 0.01, 1)
                        end
                    elseif not isPavilion then
                        local edgeTint = currentLevel.id == "pine" and C(15, 12, 10) or C(18, 14, 11)
                        local edgeAlphaA = 176
                        local edgeAlphaB = 142
                        if isLDtkRoute then
                            edgeAlphaA = 54
                            edgeAlphaB = 38
                        end
                        if isInkLabPine then
                            -- Pine InkLab branches are rendered as one pre-baked world brush layer above.
                        elseif currentLevel.id == "pine" or currentLevel.id == "huangshan" or currentLevel.id == "maple" or currentLevel.id == "plum_mirror" or currentLevel.id == "plum_finale" then
                            local edgeStep = (currentLevel.id == "maple" or currentLevel.id == "plum_mirror" or currentLevel.id == "plum_finale") and 3 or 4
                            if i % edgeStep == 0 then
                                strokeLine(n1.x + n1.normX * n1.r, n1.y + n1.normY * n1.r, n2.x + n2.normX * n2.r, n2.y + n2.normY * n2.r, 1.25, colorRGBA(edgeTint, 118))
                                strokeLine(n1.x - n1.normX * n1.r, n1.y - n1.normY * n1.r, n2.x - n2.normX * n2.r, n2.y - n2.normY * n2.r, 1.0, colorRGBA(edgeTint, 92))
                            end
                            if (currentLevel.id == "maple" or currentLevel.id == "plum_mirror" or currentLevel.id == "plum_finale") and i % 21 == 0 then
                                drawInkSpeckles(n1.x - n1.r, n1.y - n1.r, n1.r * 2, n1.r * 2, edgeTint, 48, i * 23 + n1.x, 2)
                            end
                        else
                            drawDryBrushLine(n1.x + n1.normX * n1.r, n1.y + n1.normY * n1.r, n2.x + n2.normX * n2.r, n2.y + n2.normY * n2.r, 2.2, edgeTint, edgeAlphaA, i * 17 + n1.x * 0.01, 2)
                            drawDryBrushLine(n1.x - n1.normX * n1.r, n1.y - n1.normY * n1.r, n2.x - n2.normX * n2.r, n2.y - n2.normY * n2.r, 1.9, edgeTint, edgeAlphaB, i * 19 + n1.y * 0.01, 2)
                            if (not isLDtkRoute) and i % 9 == 0 then
                                drawInkSpeckles(n1.x - n1.r, n1.y - n1.r, n1.r * 2, n1.r * 2, edgeTint, 78, i * 23 + n1.x, 4)
                            end
                        end
                    end
                end
            end
        end
    end
    if currentLevel.id == "peach" then
        for id, list in pairs(branchGroups) do
            if (not id:find("pavilion")) and (not id:find("poetry")) then
                for i = 6, #list - 2, 14 do
                    local n = list[i]
                    local seed = i * 47 + n.x * 0.017 + n.y * 0.013
                    drawTinyBlossom(n.x + n.normX * (n.r + 18), n.y + n.normY * (n.r + 18), 10 + hash01(seed) * 5, C(240, 95, 120), C(255, 178, 190), C(90, 34, 48), seed, 72, 5)
                    if i % 28 == 0 then
                        drawTinyBlossom(n.x + n.normX * (n.r + 38) + (hash01(seed + 7) - 0.5) * 24, n.y + n.normY * (n.r + 34) + (hash01(seed + 11) - 0.5) * 24, 7 + hash01(seed + 13) * 4, C(255, 184, 196), C(240, 95, 120), C(95, 40, 52), seed + 811, 56, 5)
                    end
                end
            end
        end
    end
    if currentLevel.id == "plum_finale" then
        -- 圈花白描：按母本疏密布花——上弧枝繁花尽缀，主枝前段与小枝中等，
        -- 长鞭梢与题诗柱不点花
        local blossomDensity = {
            finale_upper = 3,
            finale_spur1 = 3, finale_spur2 = 3,
            finale_hang1 = 3, finale_hang2 = 3,
            finale_droop = 4, finale_droop2 = 4,
            finale_cross = 4,
            finale_spray = 8, finale_spray_fork = 7,
            finale_tail_twig = 7,
            finale_trunk = 12,
        }
        local inkTint = C(70, 58, 44)
        for id, list in pairs(branchGroups) do
            local step = blossomDensity[id]
            if step then
                local trunkLimit = id == "finale_trunk" and math.floor(#list * 0.5) or (#list - 1)
                for i = 3, trunkLimit, step do
                    local n = list[i]
                    local seed = i * 53 + n.x * 0.013 + n.y * 0.019
                    local side = hash01(seed + 61) > 0.42 and 1 or -1
                    local off = n.r + 10 + hash01(seed + 67) * 8
                    -- 团簇式圈花：主花 + 必带一朵伴花，部分再加第三朵，贴近母本繁花团
                    local bx = n.x + n.normX * off * side
                    local by = n.y + n.normY * off * side
                    drawOutlineBlossom(bx, by, 11 + hash01(seed) * 5, inkTint, 162, seed)
                    drawOutlineBlossom(bx + (hash01(seed + 7) - 0.5) * 26, by + (hash01(seed + 11) - 0.5) * 22, 8 + hash01(seed + 13) * 4, inkTint, 132, seed + 733)
                    if hash01(seed + 71) > 0.45 then
                        drawOutlineBlossom(n.x - n.normX * (off * 0.75) * side + (hash01(seed + 17) - 0.5) * 18, n.y - n.normY * (off * 0.75) * side + (hash01(seed + 19) - 0.5) * 18, 7 + hash01(seed + 23) * 4, inkTint, 116, seed + 1517)
                    end
                end
            end
        end
        -- 主枝芽刺：沿粗枝两侧的短小逆笔刺芽（母本枝身的小刺）
        local trunk = branchGroups.finale_trunk
        if trunk then
            for i = 5, #trunk - 2, 7 do
                local n = trunk[i]
                local seed = i * 29.7 + n.x * 0.011
                local side = (i % 14 < 7) and 1 or -1
                local a = math.atan2(n.normY, n.normX) + (hash01(seed) - 0.5) * 0.9
                local len = 7 + hash01(seed + 3) * 9
                strokeLine(n.x + n.normX * n.r * side, n.y + n.normY * n.r * side,
                    n.x + n.normX * n.r * side + math.cos(a) * len * side, n.y + n.normY * n.r * side + math.sin(a) * len * side,
                    1.1, colorRGBA(inkTint, 96))
            end
        end
    end
    if currentLevel.id == "molong" then
        -- 龙体:火焰背鳍 / 网纹鳞甲 / 腹甲横纹 / 龙首精绘 / 三趾钩爪
        local body = branchGroups.dragon_body
        if body then
            for i = 3, #body - 2, 4 do
                local n = body[i]
                local seed = i * 13.7
                local fl = 16 + hash01(seed) * 24
                local bx1, by1 = n.x + n.normX * n.r, n.y + n.normY * n.r
                local tx2, ty2 = n.x + n.normX * (n.r + fl) - 8, n.y + n.normY * (n.r + fl)
                fillPoly({ { bx1 - 9, by1 + 2 }, { tx2, ty2 }, { bx1 + 9, by1 - 2 } }, colorRGBA(currentLevel.ink, 215))
                strokeQuad(tx2, ty2, tx2 - 10, ty2 - 8, tx2 - 20, ty2 - 10, 1.2, colorRGBA(currentLevel.ink, 150))
            end
            -- 网纹鳞:两排交错半圆鳞 + 鳞心点,贴近真迹留白勾鳞
            for i = 2, #body - 1, 2 do
                local n = body[i]
                for row = -1, 1 do
                    local ox = n.x + n.normX * n.r * row * 0.42
                    local oy = n.y + n.normY * n.r * row * 0.42
                    nvgBeginPath(vg)
                    nvgCircle(vg, ox + (i % 4 - 2) * 3, oy, n.r * 0.30)
                    nvgStrokeWidth(vg, 1.2)
                    nvgStrokeColor(vg, colorRGBA(currentLevel.paper, row == 0 and 78 or 56))
                    nvgStroke(vg)
                end
            end
            -- 腹甲横纹:沿腹侧的节状横线
            for i = 2, #body - 2, 2 do
                local n1, n2 = body[i], body[i + 1]
                local ax = n1.x - n1.normX * n1.r * 0.74
                local ay = n1.y - n1.normY * n1.r * 0.74
                local bx2 = n2.x - n2.normX * n2.r * 0.74
                local by2 = n2.y - n2.normY * n2.r * 0.74
                strokeLine(ax, ay, bx2, by2, 2.4, colorRGBA(currentLevel.paper, 64))
                if i % 4 == 0 then
                    strokeLine(ax, ay, ax + n1.normX * n1.r * 0.34, ay + n1.normY * n1.r * 0.34, 1.6, colorRGBA(currentLevel.paper, 70))
                end
            end
        end
        local head = branchGroups.dragon_head
        if head and #head > 4 then
            local sk = head[math.floor(#head * 0.45)]
            if tryLoadMolongHeadImage() and type(nvgImagePattern) == "function" and type(nvgFillPaint) == "function" then
                -- 真迹龙首:陈容亲笔(镜像朝右),颈部左缘搭在龙身末节
                local bodyEnd = body and body[#body] or sk
                local dw, dh = 440 * 0.82, 350 * 0.82
                local x0 = bodyEnd.x - dw * 0.16
                local y0 = bodyEnd.y - dh * 0.60
                local ok, paint = pcall(nvgImagePattern, vg, x0, y0, dw, dh, 0, molongHeadImage, 1.0)
                if ok and paint then
                    nvgBeginPath(vg)
                    nvgRect(vg, x0, y0, dw, dh)
                    nvgFillPaint(vg, paint)
                    nvgFill(vg)
                end
            else
                drawMolongHead(sk.x, sk.y - sk.r * 0.2, 1.45)
            end
        end
        for li = 1, 4 do
            local l = branchGroups["dragon_leg" .. li]
            if l and #l > 1 then
                local tip = l[#l]
                local root = l[1]
                -- 肘毛火焰
                strokeQuad(root.x - 6, root.y + 10, root.x - 26, root.y + 2, root.x - 40, root.y - 10, 2.0, colorRGBA(currentLevel.ink, 170))
                strokeQuad(root.x - 4, root.y + 18, root.x - 28, root.y + 16, root.x - 44, root.y + 6, 1.6, colorRGBA(currentLevel.ink, 140))
                -- 三趾钩爪:弧形利爪
                for k = -1, 1 do
                    local spread = k * 12
                    strokeQuad(tip.x, tip.y, tip.x + spread * 0.6 - 2, tip.y + 12, tip.x + spread, tip.y + 20, 2.6, colorRGBA(currentLevel.ink, 235))
                    strokeQuad(tip.x + spread, tip.y + 20, tip.x + spread + 4, tip.y + 26, tip.x + spread + 9, tip.y + 27, 1.8, colorRGBA(currentLevel.ink, 235))
                end
            end
        end
    end
    if currentLevel.id == "wentong_zhu" then
        -- 竹叶扇(个字/介字撇叶):沿小枝每隔数节,下垂扇形 3-6 片浓淡叶
        for id, list in pairs(branchGroups) do
            local isZhi = id:find("^wt_zhi") ~= nil
            local step = isZhi and 3 or 9
            for i = 2, #list - 1, step do
                local n = list[i]
                local seed = i * 37.3 + n.x * 0.011 + n.y * 0.017
                if isZhi or hash01(seed + 91) > 0.5 then
                    local blades = 3 + math.floor(hash01(seed) * 4)
                    for b = 1, blades do
                        local a = math.pi * 0.5 + (b - (blades + 1) * 0.5) * 0.46 + (hash01(seed + b * 7) - 0.5) * 0.34
                        local len = 40 + hash01(seed + b * 11) * 34
                        local wid = 9 + hash01(seed + b * 13) * 6
                        nvgSave(vg)
                        nvgTranslate(vg, n.x + (hash01(seed + b * 3) - 0.5) * 10, n.y + (hash01(seed + b * 5) - 0.5) * 8)
                        nvgRotate(vg, a)
                        fillPetalShape(len, wid, colorRGBA(currentLevel.ink, 132 + hash01(seed + b * 17) * 96))
                        nvgRestore(vg)
                    end
                end
            end
        end
    elseif currentLevel.id == "plum_xiyan" then
        -- 淡墨点花(故宫卷花以淡墨染瓣、浓墨点蕊):上扬枝与垂枝密,主干前段疏
        local payTint = C(132, 126, 118)
        for id, list in pairs(branchGroups) do
            if not id:find("poetry") and id ~= "xy_trunk" then
                for i = 2, #list - 1, 4 do
                    local n = list[i]
                    local seed = i * 41.7 + n.x * 0.013
                    local side = hash01(seed + 61) > 0.45 and 1 or -1
                    local off = n.r + 9 + hash01(seed + 67) * 9
                    drawTinyBlossom(n.x + n.normX * off * side, n.y + n.normY * off * side,
                        9 + hash01(seed) * 6, payTint, C(160, 154, 146), C(58, 52, 46), seed, 118, 5)
                    if hash01(seed + 71) > 0.5 then
                        drawTinyBlossom(n.x - n.normX * off * 0.7 * side + (hash01(seed + 7) - 0.5) * 16,
                            n.y - n.normY * off * 0.7 * side + (hash01(seed + 11) - 0.5) * 16,
                            7 + hash01(seed + 13) * 4, C(160, 154, 146), payTint, C(64, 58, 52), seed + 733, 92, 5)
                    end
                end
            end
        end
        local xt = branchGroups.xy_trunk
        if xt then
            for i = 2, math.floor(#xt * 0.55), 9 do
                local n = xt[i]
                local seed = i * 53.1 + n.x * 0.01
                drawTinyBlossom(n.x + n.normX * (n.r + 12), n.y + n.normY * (n.r + 12),
                    8 + hash01(seed) * 5, payTint, C(160, 154, 146), C(58, 52, 46), seed, 104, 5)
            end
        end
    elseif currentLevel.id == "xuwei_grape" then
        -- 狂草泼墨叶团 + 垂串葡萄(浓淡紫黑圆珠,串作三角下垂)
        for id, list in pairs(branchGroups) do
            local leafy = id == "xw_vine" or id == "xw_top_leaf" or id == "xw_curl1" or id == "xw_curl2"
            if leafy then
                for i = 3, #list - 2, 5 do
                    local n = list[i]
                    local seed = i * 31.9 + n.x * 0.012
                    if hash01(seed + 41) > 0.35 then
                        local side = hash01(seed + 47) > 0.5 and 1 or -1
                        drawInkBleed(n.x + (hash01(seed) - 0.5) * 36, n.y - 20 - hash01(seed + 3) * 46 * side,
                            34 + hash01(seed + 7) * 46, 24 + hash01(seed + 11) * 30,
                            currentLevel.ink, 52 + hash01(seed + 13) * 46, seed, 3)
                    end
                end
            end
            if id == "xw_left_drop" or id == "xw_right_drop" or id == "xw_right_drop2"
                or id:find("^xw_trail") or id == "xw_vine" then
                for i = 4, #list - 2, 7 do
                    local n = list[i]
                    local seed = i * 43.7 + n.y * 0.012
                    if hash01(seed + 51) > 0.45 then
                        local bx, by = n.x + (hash01(seed) - 0.5) * 14, n.y + n.r + 12
                        local rows = 3 + math.floor(hash01(seed + 5) * 2)
                        for ry = 0, rows - 1 do
                            for rx = 0, rows - 1 - ry do
                                local gseed = seed + ry * 13 + rx * 7
                                local gx = bx + (rx - (rows - 1 - ry) * 0.5) * 13 + (hash01(gseed) - 0.5) * 3
                                local gy = by + ry * 12
                                local gr = 6 + hash01(gseed + 3) * 3
                                drawCircle(gx, gy, gr, rgba(70, 56, 86, 120 + hash01(gseed + 7) * 110))
                                drawCircle(gx - gr * 0.3, gy - gr * 0.3, gr * 0.3, rgba(214, 202, 176, 90))
                            end
                        end
                    end
                end
            end
        end
    end
    for _, s in ipairs(streams) do
        strokeQuad(s.x1, s.y1, (s.x1 + s.x2) * 0.5 - 45, (s.y1 + s.y2) * 0.5, s.x2, s.y2, s.width * 0.18, colorRGBA(currentLevel.water, 72))
        local streamAngle = math.atan2(s.y2 - s.y1, s.x2 - s.x1)
        for i = 1, 12 do
            local t = i / 13
            local px = s.x1 + (s.x2 - s.x1) * t + (hash01(i * 31 + s.x1) - 0.5) * s.width * 0.35
            local py = s.y1 + (s.y2 - s.y1) * t + (hash01(i * 37 + s.y1) - 0.5) * s.width * 0.18
            drawRotEllipse(px, py, s.width * (0.12 + hash01(i * 41) * 0.16), 3 + hash01(i * 43) * 8, streamAngle, colorRGBA(currentLevel.water, 30 + hash01(i * 47) * 36))
        end
        for off = -10, 10, 6 do
            strokeQuad(s.x1 + off, s.y1, (s.x1 + s.x2) * 0.5 - 30 + off, (s.y1 + s.y2) * 0.5 + math.sin(elapsed * 2 + off) * 8, s.x2 + off, s.y2, 1.5, colorRGBA(currentLevel.water, 138))
        end
    end
end

local function drawBamboo()
    for _, s in ipairs(bambooSegments) do
        local nx = math.cos(s.angle + math.pi / 2)
        local ny = math.sin(s.angle + math.pi / 2)
        fillPoly({
            { s.x1 + nx * s.r * 0.86, s.y1 + ny * s.r * 0.86 },
            { s.x2 + nx * s.r * 0.68, s.y2 + ny * s.r * 0.68 },
            { s.x2 - nx * s.r * 0.68, s.y2 - ny * s.r * 0.68 },
            { s.x1 - nx * s.r * 0.86, s.y1 - ny * s.r * 0.86 },
        }, colorRGBA(currentLevel.accent, 118))
        drawDryBrushLine(s.x1, s.y1, s.x2, s.y2, s.r * 2.05, currentLevel.accent, 205, s.x1 * 0.013 + s.y1 * 0.017, 4)
        strokeLine(s.x1 + nx * s.r * 0.38, s.y1 + ny * s.r * 0.38, s.x2 + nx * s.r * 0.22, s.y2 + ny * s.r * 0.22, 1.2, rgba(232, 238, 230, 62))
        if hash01(s.x1 * 0.015 + s.y1 * 0.019) > 0.35 then
            drawDryBrushLine(s.x1 - nx * s.r * 0.58, s.y1 - ny * s.r * 0.58, s.x2 - nx * s.r * 0.42, s.y2 - ny * s.r * 0.42, 0.8, currentLevel.paper, 45, s.x1 * 0.02 + s.y2 * 0.01, 1)
        end
        drawRotEllipse(s.nodeX, s.nodeY, s.r * 1.4, s.r * 0.6, s.angle, colorRGBA(currentLevel.ink, 245))
        drawInkBleed(s.nodeX, s.nodeY, s.r * 1.2, s.r * 0.42, currentLevel.ink, 44, s.nodeX * 0.017 + s.nodeY * 0.011, 2)
        if hash01(s.nodeX * 0.01) > 0.45 then
            drawDryBrushLine(s.nodeX, s.nodeY, s.nodeX + math.cos(s.angle + 0.7) * s.r * 4, s.nodeY + math.sin(s.angle + 0.7) * s.r * 4, s.r * 0.35, currentLevel.ink, 155, s.nodeX * 0.02, 2)
        end
        if showDebug then drawCircle(s.nodeX, s.nodeY, 3, rgba(255, 220, 20, 180)) end
    end
end

local function drawLeavesAndPetals()
    if currentLevel.id == "maple" then
        for _, leaf in ipairs(glidingLeaves) do
            local y = mapleLeafVisualY(leaf)
            if leaf.platform then
                local squash = leaf.squash or 0
                drawInkBleed(leaf.x, y + leaf.size * 0.10, leaf.size * 0.78, leaf.size * 0.24, currentLevel.bloom, 18 + squash * 12, leaf.x * 0.01 + leaf.y * 0.02, 2)
                drawAutumnLeaf(leaf.x, y, leaf.size * (0.78 + squash * 0.06), rgba(210, 24, 24, 168))
            else
                drawAutumnLeaf(leaf.x, y, leaf.size * 0.72, colorRGBA(currentLevel.bloom, 145))
                if hash01(leaf.x * 0.01) > 0.55 then
                    drawInkBleed(leaf.x, y, leaf.size * 0.45, leaf.size * 0.18, currentLevel.bloom, 22, leaf.x * 0.01 + leaf.y * 0.02, 2)
                end
            end
        end
    elseif currentLevel.id == "peach" then
        for _, p in ipairs(floatingPetals) do
            local y = p.y + math.sin(p.bob) * 4
            nvgSave(vg)
            nvgTranslate(vg, p.x, y)
            nvgRotate(vg, math.sin(p.bob) * 0.16)
            fillPetalShape(p.w * 0.55, p.h * 0.70, colorRGBA(currentLevel.bloom, 198))
            drawDryBrushLine(-p.w * 0.18, p.h * 0.10, p.w * 0.18, p.h * 0.45, 1.0, C(96, 55, 70), 58, p.x * 0.017 + p.y * 0.013, 1)
            nvgRestore(vg)
            drawInkBleed(p.x, y + p.h * 0.12, p.w * 0.32, p.h * 0.23, currentLevel.bloom, 18, p.x * 0.01 + p.y * 0.02, 2)
        end
    end
end

local function drawRopes()
    for _, rope in ipairs(willowRopes) do
        local lastX, lastY = rope.anchorX, rope.anchorY
        for i = 1, 20 do
            local ratio = i / 20
            local len = rope.length * ratio
            local a = rope.angle * (1 - (1 - ratio) * (1 - ratio) * 0.3)
            local x = rope.anchorX + math.sin(a) * len
            local y = rope.anchorY + math.cos(a) * len
            drawDryBrushLine(lastX, lastY, x, y, 2.2, currentLevel.accent, 198, rope.anchorX * 0.01 + i * 31, 2)
            if i > 3 and i % 3 == 0 then
                drawRotEllipse(x + math.cos(a) * 12, y + math.sin(a) * 4, 12, 4, a + math.pi / 2, colorRGBA(currentLevel.accent, 180))
                drawDryBrushLine(x, y, x + math.cos(a + 0.45) * 26, y + math.sin(a + 0.45) * 8, 1.0, currentLevel.accent, 118, rope.anchorY * 0.01 + i, 1)
            end
            lastX, lastY = x, y
        end
    end
end

function drawEavesFlowerSprays()
    if currentLevel.id ~= "eaves" then return end
    for _, r in ipairs(roofs) do
        for j = 1, 5 do
            local t = (j - 0.35) / 5.3
            local x = qbez(r.x1, r.cp.x, r.x2, t)
            local y = qbez(r.y1, r.cp.y, r.y2, t)
            local seed = x * 0.014 + y * 0.018 + j * 53
            local hang = 18 + hash01(seed + 3) * 34
            strokeQuad(x, y + 4, x + (hash01(seed + 5) - 0.5) * 16, y + hang * 0.58, x + (hash01(seed + 7) - 0.5) * 22, y + hang, 1.0, rgba(42, 32, 22, 82))
            drawTinyBlossom(x + (hash01(seed + 11) - 0.5) * 28, y + hang, 13 + hash01(seed + 13) * 7, C(188, 70, 70), C(218, 165, 32), C(58, 32, 14), seed, 126, 5)
            if j % 2 == 0 then
                drawTinyBlossom(x + (hash01(seed + 17) - 0.5) * 42, y + hang + 20 + hash01(seed + 19) * 16, 9 + hash01(seed + 23) * 5, C(220, 112, 84), C(240, 210, 150), C(70, 35, 18), seed + 419, 86, 5)
            end
        end
    end
    for _, ch in ipairs(chimes) do
        for i = 1, 3 do
            local seed = ch.x * 0.013 + ch.y * 0.019 + i * 71
            local a = -math.pi * 0.5 + (i - 2) * 0.62
            local d = 28 + hash01(seed) * 16
            drawTinyBlossom(ch.x + math.cos(a) * d, ch.y + 18 + math.sin(a) * d * 0.45, 10 + hash01(seed + 3) * 5, C(188, 70, 70), C(218, 165, 32), C(58, 32, 14), seed + 811, 112, 5)
        end
    end
end

local function drawRoofsAndGears()
    for _, p in ipairs(pavilions) do
        local buildingH = p.layers * p.layerH
        drawRect(p.x - 18, p.y + 10, p.w + 36, buildingH - 8, 0, rgba(126, 98, 62, 34))
        drawStrokeRect(p.x - 18, p.y + 10, p.w + 36, buildingH - 8, 0, rgba(42, 32, 22, 42), 1.0)
        for i = 0, p.layers - 1 do
            local ly = p.y + i * p.layerH
            fillPoly({
                { p.x - 34, ly + 8 },
                { p.x + p.w * 0.50, ly - 22 },
                { p.x + p.w + 34, ly + 8 },
                { p.x + p.w + 18, ly + 20 },
                { p.x - 18, ly + 20 },
            }, rgba(42, 32, 22, 112))
            for j = 0, 8 do
                local tx = p.x - 18 + j * (p.w + 36) / 8
                drawDryBrushLine(tx, ly + 17, tx + p.w / 14, ly + 2, 0.9, C(224, 188, 118), 52, tx * 0.01 + ly, 1)
            end
            drawRect(p.x - 10, ly, p.w + 20, 10, 0, colorRGBA(currentLevel.ink, 232))
            drawStrokeRect(p.x - 10, ly, p.w + 20, 10, 0, rgba(22, 18, 15, 230), 2.5)
            drawInkBleed(p.x + p.w * 0.5, ly + 6, p.w * 0.45, 9, currentLevel.ink, 28, p.x * 0.01 + ly * 0.02, 3)
            for _, f in ipairs({ 0.20, 0.48, 0.76 }) do
                drawRect(p.x + p.w * f, ly + 10, 8, p.layerH - 10, 0, colorRGBA(currentLevel.ink, 198))
                drawStrokeRect(p.x + p.w * f, ly + 10, 8, p.layerH - 10, 0, rgba(22, 18, 15, 160), 1.2)
                drawDryBrushLine(p.x + p.w * f + 4, ly + 12, p.x + p.w * f + 4, ly + p.layerH - 10, 1.1, currentLevel.ink, 108, p.x * 0.012 + f * 100 + ly, 1)
            end
            for j = 0, 7 do
                local x = p.x + j * p.w / 7
                drawDryBrushLine(x, ly + 25, x + p.w / 9, ly + 10, 1, currentLevel.ink, 92, x * 0.01 + ly * 0.02, 1)
                if i < p.layers - 1 then
                    strokeLine(x, ly + p.layerH - 18, x + p.w / 12, ly + p.layerH - 4, 0.9, rgba(42, 32, 22, 70))
                end
            end
        end
    end
    for _, r in ipairs(roofs) do
        nvgBeginPath(vg)
        nvgMoveTo(vg, r.points[1].x, r.points[1].y)
        for _, p in ipairs(r.points) do nvgLineTo(vg, p.x, p.y) end
        nvgStrokeColor(vg, rgba(42, 32, 22, 120))
        nvgStrokeWidth(vg, 17)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgMoveTo(vg, r.points[1].x, r.points[1].y)
        for _, p in ipairs(r.points) do nvgLineTo(vg, p.x, p.y) end
        nvgStrokeColor(vg, colorRGBA(currentLevel.ink, 240))
        nvgStrokeWidth(vg, 5)
        nvgStroke(vg)
        for i = 1, #r.points - 1, 2 do
            local p, q = r.points[i], r.points[i + 1]
            local a = math.atan2(q.y - p.y, q.x - p.x)
            drawDryBrushLine(p.x, p.y, p.x + math.cos(a + math.pi / 2) * 15, p.y + math.sin(a + math.pi / 2) * 15, 1.2, currentLevel.ink, 95, p.x * 0.01 + p.y * 0.01, 1)
        end
    end
    for _, gear in ipairs(gears) do
        nvgSave(vg)
        nvgTranslate(vg, gear.x, gear.y)
        nvgRotate(vg, gear.angle)
        drawCircle(0, 0, gear.radius, colorRGBA(currentLevel.ink, 95))
        drawCircle(0, 0, gear.radius - 22, colorRGB(currentLevel.paper))
        drawInkSpeckles(-gear.radius, -gear.radius, gear.radius * 2, gear.radius * 2, currentLevel.ink, 34, gear.x * 0.01 + gear.y * 0.01, 34)
        for i = 0, 15 do
            local a = i / 16 * math.pi * 2
            drawDryBrushLine(math.cos(a) * (gear.radius - 12), math.sin(a) * (gear.radius - 12), math.cos(a) * (gear.radius + gear.teethHeight), math.sin(a) * (gear.radius + gear.teethHeight), 7, currentLevel.ink, 198, gear.radius * 0.1 + i * 19, 2)
        end
        nvgRestore(vg)
    end
    for _, ch in ipairs(chimes) do
        nvgSave(vg)
        nvgTranslate(vg, ch.x, ch.y)
        nvgRotate(vg, ch.swayAngle)
        drawDryBrushLine(0, 0, 0, 24, 1.5, currentLevel.ink, 208, ch.x * 0.01 + ch.y * 0.01, 1)
        fillPoly({ { -10, 24 }, { -6, 10 }, { 6, 10 }, { 10, 24 }, { 0, 20 } }, colorRGBA(currentLevel.water, 225))
        fillPoly({ { -2, 22 }, { 2, 22 }, { 4, 38 }, { -4, 38 } }, rgba(188, 70, 70, 200))
        nvgRestore(vg)
    end
    for _, w in ipairs(windWaves) do
        local a = clamp(w.life / w.maxLife, 0, 1)
        nvgBeginPath(vg)
        nvgCircle(vg, w.x, w.y, w.r)
        nvgStrokeColor(vg, rgba(218, 165, 32, 150 * a))
        nvgStrokeWidth(vg, 2)
        nvgStroke(vg)
    end
end

local function drawCloudsAndCranes()
    -- 深底关卡(墨龙)云用亮雾色,浅纸关卡用纸色
    local cloudTint = currentLevel.id == "molong" and C(232, 226, 210) or currentLevel.paper
    local cloudEdgeA = currentLevel.id == "molong" and 110 or 58
    for _, cp in ipairs(cloudPlatforms) do
        local cy = cp.y + math.sin(elapsed * 1.2 + cp.bob) * 8
        drawInkBleed(cp.x, cy, cp.rx * 0.65, cp.ry * 0.65, cloudTint, 88, cp.x * 0.01 + cp.y * 0.017, 5)
        for i = 0, 6 do
            local k = i - 3
            drawEllipse(cp.x + k * cp.rx * 0.18, cy + math.sin(elapsed + i) * 5, cp.rx * (0.24 + hash01(i + cp.x) * 0.08), cp.ry * (0.62 + hash01(i + cp.y) * 0.25), colorRGBA(cloudTint, 150))
        end
        drawDryBrushLine(cp.x - cp.rx, cy + cp.ry * 0.55, cp.x + cp.rx, cy + cp.ry * 0.55, 2.0, currentLevel.ink, cloudEdgeA, cp.x * 0.01 + cp.y * 0.01, 2)
        drawDryBrushLine(cp.x - cp.rx * 0.62, cy + cp.ry * 0.72, cp.x + cp.rx * 0.62, cy + cp.ry * 0.72, 1.0, C(190, 207, 198), 56, cp.x * 0.02 + cp.y * 0.01, 1)
    end
    for _, c in ipairs(cranes) do
        nvgSave(vg)
        nvgTranslate(vg, c.x, c.y)
        nvgRotate(vg, math.cos(c.theta) * 0.08)
        fillPoly({ { -32, 0 }, { -62, 14 }, { -32, -4 } }, colorRGBA(currentLevel.ink, 235))
        drawRotEllipse(-5, 0, 34, 12, 0, rgba(235, 240, 235, 215))
        strokeLine(18, -4, 65, -22, 2.2, colorRGBA(currentLevel.ink, 220))
        drawCircle(70, -24, 4, colorRGBA(currentLevel.ink, 220))
        nvgSave(vg)
        nvgTranslate(-5, -6)
        nvgRotate(c.wingAngle * 0.8 - 0.15)
        fillPoly({ { 0, 0 }, { -8, -54 }, { 18, -35 }, { 10, -8 } }, rgba(235, 240, 235, 205))
        nvgRestore(vg)
        nvgSave(vg)
        nvgTranslate(-3, 6)
        nvgRotate(-c.wingAngle * 0.75 + 0.2)
        fillPoly({ { 0, 0 }, { 4, 54 }, { 25, 28 }, { 10, 7 } }, rgba(235, 240, 235, 180))
        nvgRestore(vg)
        strokeLine(-30, 2, -75, 12, 1.2, colorRGBA(currentLevel.ink, 210))
        strokeLine(-28, -1, -72, 7, 1.2, colorRGBA(currentLevel.ink, 210))
        nvgRestore(vg)
    end
end

local function drawAttachment(x1, y1, x2, y2, nx, ny, width)
    if not x1 then return end
    strokeQuad(x1, y1, (x1 + x2) * 0.5 - (ny or -1) * 12, (y1 + y2) * 0.5 + (nx or 0) * 12, x2, y2, width or 4, rgba(22, 18, 14, 205))
    drawDryBrushLine(x1, y1, x2, y2, (width or 4) * 0.55, C(22, 18, 14), 125, x1 * 0.01 + y1 * 0.02, 2)
end

local function drawPineConeTarget(t, r)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 4)
    local ang = branchFacingAngle(t)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, ang)
    drawInkBleed(0, 0, r * 0.78, r * 1.10, C(75, 55, 40), 46, t.x * 0.013 + t.y * 0.017, 4)
    drawEllipse(0, 0, r * 0.85, r * 1.15, rgba(75, 55, 40, 245))
    nvgBeginPath(vg)
    nvgEllipse(vg, 0, 0, r * 0.85, r * 1.15)
    nvgStrokeColor(vg, rgba(12, 10, 8, 245))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
    for row = -2, 2 do
        for col = -1, 1 do
            local x = col * r * 0.28 + (row % 2) * r * 0.13
            local y = row * r * 0.25
            nvgBeginPath(vg)
            nvgArc(vg, x, y, 6, math.pi, 0, NVG_CW)
            nvgStrokeColor(vg, rgba(45, 30, 18, 210))
            nvgStrokeWidth(vg, 2)
            nvgStroke(vg)
        end
    end
    drawInkSpeckles(-r * 0.58, -r * 0.78, r * 1.16, r * 1.56, C(45, 30, 18), 110, t.x * 0.01 + t.y * 0.01, 16)
    nvgRestore(vg)
    if currentLevelIsInkLab and currentLevelIsInkLab() then drawInkLabPineConeAura(t, r) end
end

local function drawLeafTarget(t, r, fillColor)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 4.5)
    if t.attachX then
        for _, a in ipairs({ 0.5, 2.2, 3.8 }) do
            drawCircle(t.x + math.cos(a) * 8, t.y + math.sin(a) * 8, 5.5, rgba(10, 8, 5, 245))
        end
    end
    local tint = currentLevel.id == "peach" and C(240, 95, 120) or currentLevel.bloom
    drawInkBleed(t.x, t.y, r * 0.78, r * 0.58, tint, 42, t.x * 0.011 + t.y * 0.017, 4)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, branchFacingAngle(t))
    fillLeafBud(0, 0, r, fillColor, rgba(40, 10, 10, 80), rgba(235, 180, 45, 215))
    nvgRestore(vg)
    drawInkSpeckles(t.x - r * 0.45, t.y - r * 0.35, r * 0.90, r * 0.75, tint, 72, t.x * 0.02 + t.y * 0.01, 8)
end

local function drawCloudRuneTarget(t, r)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 4.5)
    drawInkBleed(t.x, t.y, r * 1.05, r * 0.82, C(224, 168, 38), 48, t.x * 0.013 + t.y * 0.019, 4)
    nvgBeginPath(vg)
    nvgMoveTo(vg, t.x, t.y - r)
    nvgBezierTo(vg, t.x + r * 1.2, t.y - r * 0.5, t.x + r * 0.6, t.y + r * 1.1, t.x, t.y + r)
    nvgBezierTo(vg, t.x - r * 0.6, t.y + r * 1.1, t.x - r * 1.2, t.y - r * 0.5, t.x, t.y - r)
    nvgClosePath(vg)
    nvgFillColor(vg, rgba(224, 168, 38, 238))
    nvgFill(vg)
    nvgStrokeColor(vg, rgba(42, 30, 8, 205))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
    strokeQuad(t.x - 8, t.y - 12, t.x + 8, t.y - 8, t.x - 6, t.y, 2, rgba(255, 255, 255, 215))
    strokeQuad(t.x - 6, t.y, t.x + 10, t.y + 12, t.x - 12, t.y + 14, 2, rgba(255, 255, 255, 215))
    drawInkSpeckles(t.x - r * 0.7, t.y - r * 0.7, r * 1.4, r * 1.4, C(42, 30, 8), 66, t.x * 0.02 + t.y * 0.01, 10)
end

function drawNeedleEnemyTarget(t, r, isHuangshan)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, isHuangshan and 3.5 or 4)
    local seed = t.x * 0.017 + t.y * 0.013
    local pulse = 0.5 + math.sin(elapsed * 4.6 + t.pulse) * 0.5
    local hit = clamp((t.hitCooldown or 0) / 22, 0, 1)
    local bodyTint = isHuangshan and C(87, 61, 38) or C(75, 55, 40)
    local darkTint = isHuangshan and C(24, 17, 12) or C(18, 13, 9)
    local bodyR = r * (0.78 + pulse * 0.035 + hit * 0.06)
    drawInkBleed(t.x, t.y, bodyR * 0.92, bodyR * 1.08, bodyTint, 42 + pulse * 8 + hit * 22, seed + 29, 4)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, branchFacingAngle(t))
    nvgScale(vg, 1 + hit * 0.08, 1 - hit * 0.035)
    drawEllipse(0, 0, bodyR * 0.78, bodyR * 1.04, colorRGBA(bodyTint, 245))
    nvgBeginPath(vg)
    nvgEllipse(vg, 0, 0, bodyR * 0.78, bodyR * 1.04)
    nvgStrokeColor(vg, colorRGBA(darkTint, 228))
    nvgStrokeWidth(vg, 1.9 + hit * 0.8)
    nvgStroke(vg)
    for row = -2, 2 do
        for col = -1, 1 do
            local sx = col * bodyR * 0.25 + (row % 2) * bodyR * 0.11
            local sy = row * bodyR * 0.22
            nvgBeginPath(vg)
            nvgArc(vg, sx, sy, bodyR * 0.13, math.pi, 0, NVG_CW)
            nvgStrokeColor(vg, rgba(45, 30, 18, 190 + hit * 40))
            nvgStrokeWidth(vg, 1.65)
            nvgStroke(vg)
        end
    end
    for i = 0, 7 do
        local a = -math.pi * 0.5 + (i / 7 - 0.5) * math.pi * 0.82
        local len = bodyR * (0.42 + hash01(seed + i * 17) * 0.20 + hit * 0.10)
        strokeLine(math.cos(a) * bodyR * 0.28, math.sin(a) * bodyR * 0.45, math.cos(a) * len, math.sin(a) * len, 0.9, colorRGBA(darkTint, 136 + hit * 50))
    end
    drawDryBrushLine(-bodyR * 0.22, bodyR * 0.72, -bodyR * 0.36, bodyR * 1.08, 1.25, darkTint, 178, seed + 71, 1)
    drawDryBrushLine(bodyR * 0.22, bodyR * 0.72, bodyR * 0.36, bodyR * 1.08, 1.25, darkTint, 178, seed + 79, 1)
    local eyeX = bodyR * (0.18 + pulse * 0.025)
    drawCircle(eyeX, -bodyR * 0.15, bodyR * 0.09, colorRGB(currentLevel.paper))
    drawCircle(eyeX + bodyR * 0.02, -bodyR * 0.15, bodyR * 0.040, colorRGBA(darkTint, 245))
    nvgRestore(vg)
    if hit > 0.01 then
        drawInkSpeckles(t.x - r * 0.50, t.y - r * 0.55, r, r * 1.1, darkTint, 34 * hit, seed + 181, 8)
    end
end

local function drawMasterPlumBlossomGlyph(x, y, r, alpha)
    local a = alpha or 178
    local seed = x * 0.017 + y * 0.013
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, hash01(seed) * math.pi * 2)
    for i = 0, 4 do
        local rot = i / 5 * math.pi * 2 + (hash01(seed + i * 11) - 0.5) * 0.22
        nvgSave(vg)
        nvgRotate(vg, rot)
        local len = r * (0.72 + hash01(seed + i * 17) * 0.18)
        local wid = r * (0.18 + hash01(seed + i * 23) * 0.05)
        fillPetalShape(len, wid, rgba(226, 207, 180, a * 0.82))
        drawDryBrushLine(0, r * 0.05, 0, len * 0.88, 0.7, C(80, 54, 44), a * 0.34, seed + i * 31, 1)
        nvgRestore(vg)
    end
    drawCircle(0, 0, r * 0.15, rgba(31, 22, 18, a))
    for i = 0, 8 do
        local rot = i / 9 * math.pi * 2
        strokeLine(0, 0, math.cos(rot) * r * 0.32, math.sin(rot) * r * 0.32, 0.9, rgba(42, 27, 21, a * 0.72))
    end
    nvgRestore(vg)
    drawInkSpeckles(x - r * 0.36, y - r * 0.36, r * 0.72, r * 0.72, C(36, 25, 21), 24, seed + 19, 6)
end

local function drawMasterPlumBudTarget(t, r)
    local seed = t.x * 0.017 + t.y * 0.013
    local pulse = 0.5 + math.sin(elapsed * 2.4 + t.pulse) * 0.5
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 2.2)
    drawRotEllipse(t.x, t.y, r * (0.92 + pulse * 0.12), r * (0.62 + pulse * 0.08), (hash01(seed) - 0.5) * 0.5, rgba(226, 206, 178, 20 + pulse * 20))
    nvgBeginPath(vg)
    nvgCircle(vg, t.x, t.y, r * (0.58 + pulse * 0.08))
    nvgStrokeColor(vg, rgba(226, 206, 178, 58 + pulse * 48))
    nvgStrokeWidth(vg, 1.15)
    nvgStroke(vg)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, math.atan2(t.normY or -1, t.normX or 0) + math.pi * 0.5 + (hash01(seed) - 0.5) * 0.35)
    fillPetalShape(r * 0.44, r * 0.16, rgba(46, 33, 27, 188))
    drawDryBrushLine(0, r * 0.05, 0, r * 0.34, 0.8, C(228, 207, 176), 44, seed + 7, 1)
    nvgRestore(vg)
    drawCircle(t.x, t.y, r * 0.09, rgba(24, 18, 15, 205))
    drawInkSpeckles(t.x - r * 0.38, t.y - r * 0.38, r * 0.76, r * 0.76, C(30, 22, 18), 36, seed + 19, 7)
end

local function drawBambooBloom(b)
    local base = -math.pi * 0.5 + (hash01(b.x * 0.02) - 0.5)
    for i = 0, 6 do
        local a = base + (i - 3) * 0.38 + (hash01(b.y + i) - 0.5) * 0.18
        nvgSave(vg)
        nvgRotate(vg, a)
        fillPetalShape(50 + hash01(i * 9 + b.x) * 20, 8 + hash01(i * 11 + b.y) * 4, i % 2 == 0 and rgba(43, 89, 63, 232) or rgba(67, 106, 76, 218))
        drawDryBrushLine(0, 0, 0, 42 + hash01(i * 17 + b.x) * 18, 1.0, C(18, 45, 28), 82, b.x * 0.01 + i, 1)
        nvgRestore(vg)
    end
end

local function drawNeedleBloom(b, lenBase)
    local pulse = b.springPulse or 0
    lenBase = lenBase * (1 + pulse * 0.16)
    local spread = currentLevel.id == "huangshan" and 1.34 or 1.55
    local count = currentLevel.id == "huangshan" and 30 or 36
    local alpha = (currentLevel.id == "huangshan" and 170 or 188) + pulse * 38
    drawPineNeedleCluster(0, 0, 0, -1, lenBase * 1.55, count, spread, b.x * 0.011 + b.y * 0.017, alpha)
    drawPineNeedleCluster(-4, 2, -0.55, -0.83, lenBase * 1.18, math.floor(count * 0.72), spread * 0.78, b.x * 0.019 + 317, alpha * 0.74)
    drawPineNeedleCluster(4, 2, 0.55, -0.83, lenBase * 1.18, math.floor(count * 0.72), spread * 0.78, b.y * 0.017 + 619, alpha * 0.74)
    nvgBeginPath(vg)
    for i = 0, 33 do
        local a = -math.pi * 0.5 + (i / 33 - 0.5) * (math.pi * (currentLevel.id == "huangshan" and 0.95 or 1.08))
        local len = lenBase * 1.18 + hash01(b.x * 0.01 + i * 33) * 30
        nvgMoveTo(vg, 0, 0)
        nvgLineTo(vg, math.cos(a) * len, math.sin(a) * len * 0.76)
    end
    nvgStrokeColor(vg, currentLevel.id == "huangshan" and rgba(43, 89, 63, 235) or rgba(43, 89, 63, 230))
    nvgStrokeWidth(vg, currentLevel.id == "huangshan" and 2.1 or 1.9)
    nvgStroke(vg)
    drawInkBleed(0, 0, lenBase * 0.48, lenBase * 0.24, C(31, 82, 50), 46, b.x * 0.013 + b.y * 0.019, 4)
    drawCircle(0, 0, currentLevel.id == "huangshan" and 11 or 9, rgba(12, 15, 12, 245))
end

function drawNeedleCorpseScatter()
    if #needleCorpses == 0 then return end
    for i, n in ipairs(needleCorpses) do
        local sway = math.sin(elapsed * 0.7 + n.seed) * 0.018
        local a = n.angle + sway
        local ca, sa = math.cos(a), math.sin(a)
        local x1 = n.x - ca * n.len * 0.46
        local y1 = n.y - sa * n.len * 0.46
        local x2 = n.x + ca * n.len * 0.56
        local y2 = n.y + sa * n.len * 0.56
        local tint = n.kind == "huangshan" and C(28, 72, 50) or C(24, 58, 35)
        strokeLine(x1, y1, x2, y2, n.width, colorRGBA(i % 4 == 0 and tint or currentLevel.ink, n.alpha))
        if i % 5 == 0 then
            strokeLine(n.x, n.y, n.x + math.cos(a + 0.55) * n.len * 0.36, n.y + math.sin(a + 0.55) * n.len * 0.28, 0.7, colorRGBA(tint, n.alpha * 0.64))
        end
    end
end

local function drawFlowerBloom(b, palette)
    if palette.darkKnots then
        for _, a in ipairs({ 0.6, 2.2, 3.8 }) do
            drawCircle(math.cos(a) * 9, math.sin(a) * 9, 6, rgba(12, 10, 8, 245))
        end
    end
    local base = hash01(b.x * 0.03 + b.y * 0.01) * math.pi
    drawInkBleed(0, 0, palette.outerLen * 0.58, palette.outerLen * 0.42, currentLevel.bloom, 30, b.x * 0.017 + b.y * 0.013, 4)
    for i = 0, 4 do
        nvgSave(vg)
        nvgRotate(vg, base + i / 5 * math.pi * 2 + (hash01(i + b.x) - 0.5) * 0.15)
        fillPetalShape(palette.outerLen + hash01(i * 7 + b.y) * 8, palette.outerWidth + hash01(i * 13 + b.x) * 5, i % 2 == 0 and palette.outerA or palette.outerB)
        drawDryBrushLine(0, 4, 0, palette.outerLen * 0.70, 1.0, C(80, 18, 20), 66, b.x * 0.01 + i * 7, 1)
        nvgRestore(vg)
    end
    if palette.inner then
        for i = 0, 4 do
            nvgSave(vg)
            nvgRotate(vg, base + i / 5 * math.pi * 2 + 0.6)
            fillPetalShape(palette.innerLen + hash01(i * 17 + b.y) * 5, palette.innerWidth + hash01(i * 19 + b.x) * 4, palette.inner)
            drawDryBrushLine(0, 2, 0, palette.innerLen * 0.58, 0.8, C(110, 38, 44), 52, b.y * 0.01 + i * 11, 1)
            nvgRestore(vg)
        end
    end
    if palette.stamen then
        for i = 0, 13 do
            local a = i / 14 * math.pi * 2
            local len = palette.stamenLen + hash01(i * 23 + b.x) * 8
            strokeLine(0, 0, math.cos(a) * len, math.sin(a) * len, 1.4, rgba(42, 8, 8, 220))
            drawCircle(math.cos(a) * len, math.sin(a) * len, 2.6, rgba(224, 173, 43, 235))
        end
    end
end

local function drawTargets()
    for _, t in ipairs(targets) do
        if not t.dead then
            local r = t.r + math.sin(elapsed * 3 + t.pulse) * (currentLevel.id == "bamboo" and 2 or 3)
            if currentLevel.id == "bamboo" then
                drawInkBleed(t.x, t.y, r * 1.05, r * 0.72, currentLevel.wash, 54, t.x * 0.013 + t.y * 0.019, 5)
                strokeQuad(t.x, t.y, t.x - r, t.y + r * 0.5, t.x - r * 0.5, t.y + r, 3, rgba(40, 50, 45, 205))
                drawDryBrushLine(t.x, t.y, t.x - r * 0.5, t.y + r * 0.92, 1.1, currentLevel.ink, 98, t.x * 0.01 + t.y * 0.01, 1)
            elseif currentLevel.id == "pine" then
                drawNeedleEnemyTarget(t, r, false)
            elseif currentLevel.id == "huangshan" then
                drawNeedleEnemyTarget(t, r, true)
            elseif currentLevel.id == "plum_master" then
                drawMasterPlumBudTarget(t, r)
            elseif currentLevel.id == "molong" then
                drawCircle(t.x, t.y, r * 1.18, rgba(216, 174, 64, 46))
                drawCircle(t.x, t.y, r * 0.82, rgba(216, 174, 64, 235))
                nvgBeginPath(vg)
                nvgCircle(vg, t.x, t.y, r * 0.82)
                nvgStrokeWidth(vg, 2.2)
                nvgStrokeColor(vg, colorRGBA(currentLevel.ink, 200))
                nvgStroke(vg)
                drawCircle(t.x - r * 0.26, t.y - r * 0.30, r * 0.18, rgba(248, 240, 214, 220))
                for k = 0, 3 do
                    local a = elapsed * 1.4 + k * math.pi * 0.5
                    strokeQuad(t.x + math.cos(a) * r, t.y + math.sin(a) * r,
                        t.x + math.cos(a + 0.5) * r * 1.5, t.y + math.sin(a + 0.5) * r * 1.5,
                        t.x + math.cos(a + 0.9) * r * 1.9, t.y + math.sin(a + 0.9) * r * 1.9,
                        1.4, rgba(216, 174, 64, 110))
                end
            elseif currentLevel.id == "peach" then
                drawLeafTarget(t, r, rgba(240, 95, 120, 245))
            elseif currentLevel.id == "eaves" then
                nvgSave(vg)
                nvgTranslate(vg, t.x, t.y)
                nvgRotate(vg, branchFacingAngle(t))
                fillLeafBud(0, 0, r, rgba(188, 70, 70, 238), rgba(40, 10, 10, 90), rgba(235, 180, 45, 220))
                nvgRestore(vg)
            else
                drawLeafTarget(t, r, colorRGBA(currentLevel.bloom, 245))
            end
        end
    end
    for _, b in ipairs(blooms) do
        if b.kind == "plum_master" then
            drawAttachment(b.attachX, b.attachY, b.x, b.y, b.normX, b.normY, 2.2)
            local t = clamp(b.progress, 0, 1)
            drawMasterPlumBlossomGlyph(b.x, b.y, (b.r or 24) * (0.62 + 0.38 * t), 90 + 95 * t)
            local seed = b.x * 0.011 + b.y * 0.019
            for i = 1, 2 do
                local a = hash01(seed + i * 17) * math.pi * 2
                local d = (b.r or 24) * (0.34 + hash01(seed + i * 23) * 0.34) * t
                local rr = (b.r or 24) * (0.40 + hash01(seed + i * 29) * 0.16) * (0.72 + 0.28 * t)
                drawMasterPlumBlossomGlyph(b.x + math.cos(a) * d, b.y + math.sin(a) * d, rr, 62 + 82 * t)
            end
            drawInkSpeckles(b.x - (b.r or 24), b.y - (b.r or 24), (b.r or 24) * 2, (b.r or 24) * 2, C(32, 24, 20), 28 * (1 - t), b.x * 0.01 + b.y * 0.013, 8)
        else
        if b.kind ~= "bamboo" then
            drawAttachment(b.attachX, b.attachY, b.x, b.y, b.normX, b.normY, b.kind == "pine" and 4 or 4.5)
        end
        nvgSave(vg)
        nvgTranslate(vg, b.x, b.y)
        if b.kind ~= "bamboo" then
            nvgRotate(vg, branchFacingAngle(b))
        end
        nvgScale(vg, b.scale, b.scale)
        if b.kind == "bamboo" then
            drawBambooBloom(b)
        elseif b.kind == "pine" or b.kind == "huangshan" then
            drawNeedleBloom(b, b.kind == "huangshan" and 52 or 46)
        elseif b.kind == "plum_master" then
            drawMasterPlumBlossomGlyph(0, 0, 24, 150)
        elseif b.kind == "peach" then
            drawFlowerBloom(b, {
                outerA = rgba(240, 95, 120, 245), outerB = rgba(210, 50, 80, 245),
                inner = rgba(255, 175, 185, 245), outerLen = 74, outerWidth = 48,
                innerLen = 45, innerWidth = 29, stamen = true, stamenLen = 34,
            })
            for i = 1, 4 do
                local seed = b.x * 0.017 + b.y * 0.013 + i * 79
                local a = hash01(seed) * math.pi * 2
                local d = 42 + hash01(seed + 3) * 42
                drawTinyBlossom(math.cos(a) * d, math.sin(a) * d * 0.74, 17 + hash01(seed + 7) * 9, C(240, 95, 120), C(255, 184, 196), C(95, 40, 52), seed, 122 + 38 * clamp(b.progress or 1, 0, 1), 5)
            end
        elseif b.kind == "eaves" then
            drawFlowerBloom(b, {
                outerA = rgba(188, 70, 70, 245), outerB = rgba(218, 165, 32, 245),
                inner = rgba(240, 220, 180, 245), outerLen = 58, outerWidth = 40,
                innerLen = 34, innerWidth = 23,
            })
            for i = 1, 3 do
                local seed = b.x * 0.015 + b.y * 0.011 + i * 89
                local a = hash01(seed) * math.pi * 2
                local d = 32 + hash01(seed + 5) * 28
                drawTinyBlossom(math.cos(a) * d, math.sin(a) * d * 0.76, 12 + hash01(seed + 9) * 7, C(188, 70, 70), C(218, 165, 32), C(58, 32, 14), seed + 211, 112 + 30 * clamp(b.progress or 1, 0, 1), 5)
            end
        elseif b.kind == "molong" then
            -- 碎珠雷光:金墨电光放射 + 墨环扩散
            local pr2 = clamp(b.progress or 1, 0, 1)
            for i = 0, 7 do
                local seed = b.x * 0.013 + i * 41
                local a = i / 8 * math.pi * 2 + hash01(seed) * 0.4
                local r1 = 16 + 52 * pr2
                local mx2 = math.cos(a + 0.32) * r1 * 0.55
                local my2 = math.sin(a + 0.32) * r1 * 0.55
                local ex2 = math.cos(a) * r1 * (0.9 + hash01(seed + 7) * 0.5)
                local ey2 = math.sin(a) * r1 * (0.9 + hash01(seed + 7) * 0.5)
                strokeLine(0, 0, mx2, my2, 2.4, rgba(216, 174, 64, 235 * (1.2 - pr2)))
                strokeLine(mx2, my2, ex2, ey2, 1.7, rgba(22, 20, 18, 215 * (1.2 - pr2)))
            end
            nvgBeginPath(vg)
            nvgCircle(vg, 0, 0, 18 + 64 * pr2)
            nvgStrokeWidth(vg, 2.6 * (1.1 - pr2))
            nvgStrokeColor(vg, rgba(216, 174, 64, 190 * (1.05 - pr2)))
            nvgStroke(vg)
            drawInkSpeckles(-30, -30, 60, 60, currentLevel.ink, 90 * (1.1 - pr2), b.x * 0.01, 7)
        elseif b.kind == "wentong_zhu" then
            -- 竹叶爆扇:浓淡墨叶自枝节撇出,溅起墨点(贴合文同浓墨为面淡墨为背)
            local pr2 = clamp(b.progress or 1, 0, 1)
            for i = 1, 7 do
                local seed = b.x * 0.013 + b.y * 0.017 + i * 53
                local a = math.pi * 0.5 + (i - 4) * 0.40 + (hash01(seed) - 0.5) * 0.34
                nvgSave(vg)
                nvgRotate(vg, a)
                fillPetalShape(44 + hash01(seed + 3) * 30, 10 + hash01(seed + 7) * 6,
                    colorRGBA(currentLevel.ink, (136 + hash01(seed + 11) * 100) * pr2))
                nvgRestore(vg)
            end
            drawInkSpeckles(-34, -34, 68, 68, currentLevel.ink, 70 * pr2, b.x * 0.011 + b.y * 0.013, 8)
        elseif b.kind == "plum_xiyan" then
            -- 淡墨梅:灰墨染瓣、浓墨点蕊(『个个花开淡墨痕』)
            drawFlowerBloom(b, {
                outerA = rgba(150, 144, 136, 232), outerB = rgba(122, 116, 108, 232),
                inner = rgba(172, 166, 158, 232), outerLen = 40, outerWidth = 27,
                innerLen = 23, innerWidth = 16, darkKnots = true,
            })
            for i = 0, 11 do
                local a = i / 12 * math.pi * 2
                local len = 14 + hash01(i * 23 + b.x) * 6
                strokeLine(0, 0, math.cos(a) * len, math.sin(a) * len, 1.2, rgba(46, 40, 34, 215))
                drawCircle(math.cos(a) * len, math.sin(a) * len, 1.8, rgba(40, 34, 28, 230))
            end
            for i = 1, 2 do
                local seed = b.x * 0.017 + b.y * 0.013 + i * 79
                local a = hash01(seed) * math.pi * 2
                local d = 32 + hash01(seed + 3) * 26
                drawTinyBlossom(math.cos(a) * d, math.sin(a) * d * 0.8, 8 + hash01(seed + 7) * 4,
                    C(150, 144, 136), C(172, 166, 158), C(58, 52, 46), seed + 311, 100 * clamp(b.progress or 1, 0, 1), 5)
            end
        elseif b.kind == "xuwei_grape" then
            -- 墨葡萄串:墨紫圆珠成串显形 + 泼墨晕(『笔底明珠』)
            local pr2 = clamp(b.progress or 1, 0, 1)
            drawInkBleed(0, -10, 36, 26, currentLevel.ink, 78 * pr2, b.x * 0.012 + b.y * 0.014, 3)
            local rows = 4
            for ry = 0, rows - 1 do
                for rx = 0, rows - 1 - ry do
                    local gseed = b.x * 0.01 + ry * 13 + rx * 7
                    local gx = (rx - (rows - 1 - ry) * 0.5) * 15 + (hash01(gseed) - 0.5) * 3
                    local gy = ry * 14 + 6
                    local gr = (7.5 + hash01(gseed + 3) * 3.5) * (0.5 + 0.5 * pr2)
                    drawCircle(gx, gy, gr, rgba(70, 56, 86, (140 + hash01(gseed + 7) * 100) * pr2))
                    drawCircle(gx - gr * 0.3, gy - gr * 0.3, gr * 0.3, rgba(220, 210, 188, 110 * pr2))
                end
            end
        elseif b.kind == "plum_finale" then
            -- 白描圈花绽放：纸色花瓣、墨色勾边点蕊，呼应母本不设色的圈花法
            drawFlowerBloom(b, {
                outerA = rgba(238, 230, 212, 240), outerB = rgba(222, 210, 188, 240),
                inner = rgba(244, 238, 222, 240), outerLen = 40, outerWidth = 27,
                innerLen = 23, innerWidth = 16, stamen = true, stamenLen = 20,
                darkKnots = true,
            })
            for i = 1, 3 do
                local seed = b.x * 0.017 + b.y * 0.013 + i * 79
                local a = hash01(seed) * math.pi * 2
                local d = 30 + hash01(seed + 3) * 26
                drawOutlineBlossom(math.cos(a) * d, math.sin(a) * d * 0.8, 8 + hash01(seed + 7) * 4, C(70, 58, 44), 96 + 40 * clamp(b.progress or 1, 0, 1), seed + 211)
            end
        else
            drawFlowerBloom(b, {
                outerA = rgba(195, 18, 18, 245), outerB = rgba(148, 10, 10, 245),
                inner = rgba(228, 45, 45, 245), outerLen = 44, outerWidth = 30,
                innerLen = 25, innerWidth = 18, stamen = true, stamenLen = 22,
                darkKnots = b.kind == "plum",
            })
        end
        nvgRestore(vg)
        end
    end
end


-- ============================================================================
-- END scripts/src/70_entities_targets_render.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/80_fluid_player_render.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function fluidQuadTo(fromX, fromY, cx, cy, x, y)
    nvgBezierTo(
        vg,
        fromX + (cx - fromX) * 0.6667,
        fromY + (cy - fromY) * 0.6667,
        x + (cx - x) * 0.6667,
        y + (cy - y) * 0.6667,
        x,
        y
    )
end

-- 取当前关卡墨色的浓淡变体（mul 越小越浓黑）
function inkShade(mul, alpha)
    local c = currentLevel.ink
    return rgba(c[1] * mul, c[2] * mul, c[3] * mul, alpha)
end

local function fillFluidPath(left, right, color)
    if #left < 2 or #right < 2 then return end
    nvgBeginPath(vg)
    local curX, curY = left[1].x, left[1].y
    nvgMoveTo(vg, curX, curY)
    for i = 2, #left do
        local ctrl = left[i - 1]
        local x = (left[i].x + left[i - 1].x) * 0.5
        local y = (left[i].y + left[i - 1].y) * 0.5
        fluidQuadTo(curX, curY, ctrl.x, ctrl.y, x, y)
        curX, curY = x, y
    end
    nvgLineTo(vg, left[#left].x, left[#left].y)
    nvgLineTo(vg, right[#right].x, right[#right].y)
    curX, curY = right[#right].x, right[#right].y
    for i = #right - 1, 1, -1 do
        local ctrl = right[i + 1]
        local x = (right[i].x + right[i + 1].x) * 0.5
        local y = (right[i].y + right[i + 1].y) * 0.5
        fluidQuadTo(curX, curY, ctrl.x, ctrl.y, x, y)
        curX, curY = x, y
    end
    nvgLineTo(vg, right[1].x, right[1].y)
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawDashFluidRibbon()
    if #dashFluidPoints < 4 then return end
    local outerLeft, outerRight = {}, {}
    local innerLeft, innerRight = {}, {}
    local fiberLines = {}
    local time = elapsed * 1000
    local targetBlend = fluidTrailIsEnhanced() and 1.0 or 0.0
    fluidTrailDashBlend = fluidTrailDashBlend + (targetBlend - fluidTrailDashBlend) * 0.12

    local haloLeft, haloRight = {}, {}
    for i = 1, #dashFluidPoints do
        local curr = dashFluidPoints[i]
        local prev = dashFluidPoints[i - 1] or curr
        local next = dashFluidPoints[i + 1] or curr
        local dx, dy = next.x - prev.x, next.y - prev.y
        local len = dist2(dx, dy)
        if len < 0.001 then dx, dy, len = 1, 0, 1 end
        local nx, ny = -dy / len, dx / len
        local t = (i - 1) / math.max(1, #dashFluidPoints - 1)
        local speedScale = 1.0 + math.min(2.0, (curr.velocity or 0) * 0.05)
        local freqScale = 0.012 + fluidTrailDashBlend * 0.024
        local spineNoiseVal = fluidNoise1D(curr.dist * freqScale - time * 0.008, 17) * speedScale
        local spineWiggleAmp = (9 - fluidTrailDashBlend * 5.5) * (1 - (t - 1) * (t - 1))
        local cx = curr.x + nx * spineNoiseVal * spineWiggleAmp
        local cy = curr.y + ny * spineNoiseVal * spineWiggleAmp
        if i == #dashFluidPoints then
            cx, cy = curr.x, curr.y
        end

        local widthNoiseVal = fluidNoise1D(curr.dist * 0.014 - time * 0.006, 71)
        local normNoise = clamp((widthNoiseVal + 1.0) * 0.5, 0, 1)
        local currentNecking = fluidTrailConfig.neckingExponent + fluidTrailDashBlend * 1.1
        local liquidMod = 0.18 + 1.55 * (normNoise ^ currentNecking)
        local stateBaseWidth = fluidTrailConfig.baseWidth * (1.0 - fluidTrailDashBlend * 0.42)
        local taper = (math.max(0, t) ^ 0.45) * (1.05 - 0.15 * t)
        local shredMultiplier = 1.0
        if fluidTrailDashBlend > 0.02 then
            local shredNoise = fluidNoise1D(curr.dist * 0.08 + time * 0.01, 131)
            if shredNoise > 0.35 then
                local shredded = math.max(0.1, 1.0 - (shredNoise - 0.35) * 2.8)
                shredMultiplier = 1.0 - (1.0 - shredded) * fluidTrailDashBlend
            end
        end
        local outerHalfW = math.max(0.1, (stateBaseWidth * 0.5) * taper * liquidMod * shredMultiplier)

        local pointEnhanced = curr.enhanced or fluidTrailDashBlend > 0.35
        if pointEnhanced and outerHalfW < 2.0 and i > 5 and i < #dashFluidPoints - 8 then
            local seed = curr.dist * 0.013 + i * 41 + math.floor(elapsed * 16)
            local prob = (0.03 + 0.15 * fluidTrailDashBlend) * fluidTrailConfig.pinchPropensity
            if hash01(seed) < prob then
                spawnDashFluidDroplet(cx, cy, curr.velocity or 0, nx, ny, seed, true, curr.dirX, curr.dirY)
            end
        end

        if pointEnhanced and fluidTrailDashBlend > 0.12 and i > 2 and i < #dashFluidPoints - 2 then
            local seed = curr.dist * 0.031 + i * 19 + math.floor(elapsed * 24)
            if hash01(seed + 301) < 0.22 * fluidTrailDashBlend then
                local tx, ty = curr.dirX or dx / len, curr.dirY or dy / len
                local tl = dist2(tx, ty)
                if tl < 0.001 then tx, ty, tl = dx, dy, len end
                tx, ty = tx / tl, ty / tl
                local side = (hash01(seed + 307) - 0.5) * outerHalfW * 1.6
                local lineLen = (8 + hash01(seed + 311) * 28) * (0.65 + fluidTrailDashBlend)
                fiberLines[#fiberLines + 1] = {
                    x1 = cx + nx * side,
                    y1 = cy + ny * side,
                    x2 = cx + nx * side - tx * lineLen,
                    y2 = cy + ny * side - ty * lineLen,
                    width = 0.45 + hash01(seed + 313) * 1.2,
                    alpha = (38 + hash01(seed + 317) * 92) * fluidTrailDashBlend,
                }
            end
        end

        local innerHalfW = outerHalfW * (0.62 - fluidTrailDashBlend * 0.12)
        local haloHalfW = outerHalfW * 1.62 + 1.4
        outerLeft[#outerLeft + 1] = { x = cx + nx * outerHalfW, y = cy + ny * outerHalfW }
        outerRight[#outerRight + 1] = { x = cx - nx * outerHalfW, y = cy - ny * outerHalfW }
        innerLeft[#innerLeft + 1] = { x = cx + nx * innerHalfW, y = cy + ny * innerHalfW }
        innerRight[#innerRight + 1] = { x = cx - nx * innerHalfW, y = cy - ny * innerHalfW }
        haloLeft[#haloLeft + 1] = { x = cx + nx * haloHalfW, y = cy + ny * haloHalfW }
        haloRight[#haloRight + 1] = { x = cx - nx * haloHalfW, y = cy - ny * haloHalfW }
    end

    local outerAlpha = 115 * (1.0 - fluidTrailDashBlend) + 72 * fluidTrailDashBlend
    local innerAlpha = 238 * (1.0 - fluidTrailDashBlend) + 230 * fluidTrailDashBlend
    -- 三层水墨：最外湿晕（纸面洇开）→ 中层墨身 → 内芯浓墨
    fillFluidPath(haloLeft, haloRight, inkShade(0.92, 15 + 9 * (1.0 - fluidTrailDashBlend)))
    fillFluidPath(outerLeft, outerRight, inkShade(0.82, outerAlpha))
    fillFluidPath(innerLeft, innerRight, inkShade(0.52, innerAlpha))
    -- 尾端飞白散锋：沿两缘交替甩出干笔细丝，越近尾端越实
    local m = math.min(16, #outerLeft - 1)
    for i = 1, m do
        local fade = 1 - i / (m + 1)
        local edge = (i % 2 == 0) and outerLeft or outerRight
        local a, b = edge[i], edge[i + 1]
        strokeLine(a.x, a.y, b.x + (b.x - a.x) * 0.8, b.y + (b.y - a.y) * 0.8, 0.9 + fade * 0.5, inkShade(0.6, 86 * fade))
    end
    for _, f in ipairs(fiberLines) do
        strokeLine(f.x1, f.y1, f.x2, f.y2, f.width, inkShade(0.5, f.alpha))
    end
end

local function drawDashFluidDroplets()
    for _, d in ipairs(dashFluidDroplets) do
        local r = d.radius * math.max(0, d.life)
        if d.kind == "dash_streak" then
            strokeLine(d.x, d.y, d.x - d.vx * 1.4, d.y - d.vy * 1.4, math.max(0.4, r * 1.3), inkShade(0.62, 190 * d.life))
        else
            drawCircle(d.x, d.y, r * 1.55, inkShade(0.95, 26 * d.life))
            drawCircle(d.x, d.y, r, inkShade(0.82, 115 * d.life))
            drawCircle(d.x, d.y, r * 0.60, inkShade(0.52, 238 * d.life))
        end
    end
end

local function drawParticles()
    drawDashFluidRibbon()
    drawDashFluidDroplets()
    for _, p in ipairs(trailParticles) do
        local a = clamp(p.life / p.maxLife, 0, 1)
        local color = colorRGBA(currentLevel.ink, 200 * p.alpha * a)
        if p.kind == "gold" then color = rgba(218, 165, 32, 220 * p.alpha * a)
        elseif p.kind == "energy" or p.kind == "inkgas" then color = rgba(8, 7, 6, 180 * p.alpha * a)
        elseif p.kind == "red" or p.kind == "maple" then color = rgba(195, 22, 22, 220 * p.alpha * a)
        elseif p.kind == "water" then color = rgba(232, 238, 230, 220 * p.alpha * a) end
        drawEllipse(p.x, p.y, p.r * 1.3, p.r * 0.75, color)
    end
    for _, p in ipairs(bristleParticles) do
        local a = clamp(p.life / p.maxLife, 0, 1)
        local color = colorRGBA(currentLevel.ink, 150 * a)
        if p.kind == "gold" then color = rgba(218, 165, 32, 170 * a)
        elseif p.kind == "bloom" then color = colorRGBA(currentLevel.bloom, 180 * a)
        elseif p.kind == "inkgas" then color = rgba(6, 5, 4, 120 * a)
        elseif p.kind == "leaf" then color = colorRGBA(currentLevel.accent, 160 * a) end
        strokeLine(p.x, p.y, p.x + p.vx * 2.4, p.y + p.vy * 2.4, 1.4, color)
    end
end

-- 活体墨滴：闭合贝塞尔轮廓 + 表面波动 + 速度形变（squash & stretch）
function buildInkBlobOutline(cx, cy, baseR, spd, ang, squash, tear, wallAng)
    local pts = {}
    local n = 14
    local stretchE = player.isDashing and 0.40 or clamp(spd * 0.027, 0, 0.30)
    for k = 0, n - 1 do
        local th = k / n * math.pi * 2
        -- 三重表面波（整数倍频保证首尾无缝），墨滴永远在"呼吸"
        local wob = 0.055 * math.sin(th * 3 + elapsed * 4.1)
            + 0.040 * math.sin(th * 5 - elapsed * 3.3 + 1.7)
            + 0.028 * math.sin(th * 7 + elapsed * 5.9 + 4.2)
        local r = baseR * (1 + wob)
        -- 沿速度方向拉伸（垂直方向等量收缩，体积守恒感）
        r = r * (1 + stretchE * math.cos(2 * (th - ang)))
        -- 落地挤压：横向变宽、纵向压扁
        r = r * (1 + squash * math.cos(2 * th))
        -- 运动拖墨：尾侧微微隆起拖长
        if tear > 0.01 then
            local rear = math.cos(th - ang - math.pi)
            if rear > 0 then r = r * (1 + tear * rear * rear) end
        end
        -- 贴墙：朝墙一侧压平
        if wallAng then
            local press = math.cos(th - wallAng)
            if press > 0 then r = r * (1 - 0.24 * press * press) end
        end
        pts[#pts + 1] = { x = cx + math.cos(th) * r, y = cy + math.sin(th) * r }
    end
    return pts
end

function fillInkBlob(pts, color)
    if #pts < 3 then return end
    nvgBeginPath(vg)
    local prev = pts[#pts]
    local curX, curY = (prev.x + pts[1].x) * 0.5, (prev.y + pts[1].y) * 0.5
    nvgMoveTo(vg, curX, curY)
    for i = 1, #pts do
        local a = pts[i]
        local b = pts[i % #pts + 1]
        local mx, my = (a.x + b.x) * 0.5, (a.y + b.y) * 0.5
        fluidQuadTo(curX, curY, a.x, a.y, mx, my)
        curX, curY = mx, my
    end
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawPlayer()
    local spd = dist2(player.vx or 0, player.vy or 0)
    local r0 = player.radius

    -- 落地挤压检测（用 player 表存帧间状态，避免新增 chunk 级 local）
    if player.isGrounded and (player.blobPrevVy or 0) > 5.5 then
        player.blobSquash = math.min(0.42, (player.blobPrevVy or 0) * 0.035)
    end
    player.blobPrevVy = player.vy
    player.blobSquash = (player.blobSquash or 0) * 0.85

    local ang
    if spd > 0.6 then
        ang = math.atan2(player.vy, player.vx)
    else
        ang = player.facingRight and 0 or math.pi
    end
    local tear = player.isDashing and 0.34 or clamp(spd * 0.016, 0, 0.24)
    local wallAng = nil
    if player.isWallClinging then
        wallAng = player.wallSide > 0 and 0 or math.pi
    end

    -- 冲刺彗尾：三层拖影 + 速度线
    if player.isDashing then
        drawRotEllipse(player.x - player.vx * 0.58, player.y - player.vy * 0.58, r0 + 26, r0 * 1.05, ang, inkShade(0.95, 36))
        drawRotEllipse(player.x - player.vx * 0.40, player.y - player.vy * 0.40, r0 + 18, r0 * 0.84, ang, inkShade(0.75, 62))
        drawRotEllipse(player.x - player.vx * 0.24, player.y - player.vy * 0.24, r0 + 9, r0 * 0.58, ang, inkShade(0.45, 92))
        for i = 1, 3 do
            local seed = math.floor(elapsed * 40) * 13 + i * 57
            local side = (hash01(seed) - 0.5) * r0 * 2.6
            local nx2, ny2 = -math.sin(ang), math.cos(ang)
            local sx = player.x - math.cos(ang) * r0 * (1.2 + hash01(seed + 3) * 1.6) + nx2 * side
            local sy = player.y - math.sin(ang) * r0 * (1.2 + hash01(seed + 3) * 1.6) + ny2 * side
            local ln = 10 + hash01(seed + 7) * 22
            strokeLine(sx, sy, sx - math.cos(ang) * ln, sy - math.sin(ang) * ln, 0.8 + hash01(seed + 11) * 0.8, inkShade(0.5, 70 + hash01(seed + 13) * 60))
        end
    end

    -- 贴墙：墨珠沿墙面滑出细痕
    if player.isWallClinging then
        local wx = player.x + player.wallSide * (r0 - 2)
        strokeLine(wx, player.y - 4, wx + player.wallSide * 1.5, player.y + r0 + 10, 1.6, inkShade(0.6, 96))
        if hash01(elapsed * 80) > 0.45 then
            drawCircle(player.x + player.wallSide * 8, player.y + (hash01(elapsed * 100) - 0.5) * 10, 2.8, colorRGBA(currentLevel.ink, 110))
        end
    end

    -- 静止沉积：墨珠落定时在脚下洇出一圈淡墨（缓慢呼吸）
    if player.isGrounded and not player.isDashing and spd < 0.8 then
        local soak = 0.5 + 0.5 * math.sin(elapsed * 1.7)
        drawEllipse(player.x, player.y + r0 * 0.82, r0 * (0.9 + soak * 0.35), r0 * 0.26, inkShade(0.95, 26 + soak * 16))
    end

    -- 湿晕（随速度变大，像快速运笔时墨来不及渗）
    local bleedScale = 1.42 + math.min(0.5, spd * 0.022)
    drawInkBleed(player.x, player.y, r0 * bleedScale, r0 * (bleedScale - 0.25), currentLevel.ink, 50, elapsed * 7.1 + player.x * 0.01, 3)

    -- 墨滴本体：外层墨身 + 滞后的内芯浓墨
    local body = buildInkBlobOutline(player.x, player.y, r0 * 1.04, spd, ang, player.blobSquash, tear, wallAng)
    fillInkBlob(body, inkShade(0.78, 248))
    local coreLagX = spd > 0.6 and -math.cos(ang) * r0 * 0.20 or 0
    local coreLagY = spd > 0.6 and -math.sin(ang) * r0 * 0.20 or 0
    local core = buildInkBlobOutline(
        player.x + coreLagX, player.y + coreLagY + math.sin(elapsed * 2.3) * 0.6,
        r0 * 0.58, spd, ang, player.blobSquash * 0.6, tear * 0.5, nil)
    fillInkBlob(core, inkShade(0.42, 252))

    -- 飞白颗粒 + 行进向高光（湿亮点）
    drawInkSpeckles(player.x - r0, player.y - r0, r0 * 2, r0 * 2, currentLevel.paper, 42, elapsed * 3.7 + player.y * 0.01, 5)
    local hlA = ang
    if spd <= 0.6 then hlA = player.facingRight and -0.5 or math.pi + 0.5 end
    local hx = player.x + math.cos(hlA) * r0 * 0.36
    local hy = player.y + math.sin(hlA) * r0 * 0.36 - 1.5
    drawCircle(hx, hy, 2.6, colorRGBA(currentLevel.paper, 235))
    drawCircle(hx + 2.2, hy + 1.8, 1.2, colorRGBA(currentLevel.paper, 160))
end

local function drawPoetry()
    local poems = {
        bamboo = { x = W(0.05), y = H(0.15), lines = { "咬定青山不放松", "立根原在破岩中", "千磨万击还坚劲", "任尔东西南北风" } },
        pine = { x = W(0.05), y = H(0.22), lines = { "松风吹解带", "山泉声自流" } },
        maple = { x = W(0.08), y = H(0.28), lines = { "停车坐爱枫林晚", "霜叶红于二月花" } },
        plum = { x = W(0.18), y = H(0.28), lines = { "吾家洗砚池头树", "个个花开淡墨痕", "不要人夸好颜色", "只留清气满乾坤" } },
        eaves = { x = W(0.08), y = H(0.18), lines = { "界画楼台工整描", "金碧山水自天娇" } },
        plum_xiyan = { x = W(0.295), y = H(0.08), lines = { "吾家洗砚池头树", "个个花开淡墨痕", "不要人夸好颜色", "只留清气满乾坤" } },
        xuwei_grape = { x = W(0.06), y = H(0.07), lines = { "半生落魄已成翁", "独立书斋啸晚风", "笔底明珠无处卖", "闲抛闲掷野藤中" } },
    }
    local p = poems[currentLevel.id]
    if not p then return end
    for i = 1, #p.lines do
        local vx = p.x + (#p.lines - i) * 45
        local chars = utf8Chars(p.lines[i])
        for j = 1, #chars do
            drawText(vx, p.y + (j - 1) * 32, 28, colorRGBA(currentLevel.ink, 185), chars[j])
        end
    end
    drawRect(p.x + 45, p.y - 45, 24, 24, 0, rgba(168, 43, 43, 165))
end


-- ============================================================================
-- END scripts/src/80_fluid_player_render.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/90_world_seal_runtime.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function drawWorld()
    drawPaper()
    drawBackground()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollBackdrop() end
    drawPoetry()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollCollisionInk() end
    if currentLevel.id == "bamboo" then
        drawBamboo()
    else
        drawBranches()
        if currentLevelIsLDtkGrandScroll() then drawBamboo() end
    end
    drawLeavesAndPetals()
    drawRopes()
    drawRoofsAndGears()
    drawCloudsAndCranes()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollWaterAndPetals() end
    drawNeedleCorpseScatter()
    drawTargets()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollLabels() end
    drawParticles()
    drawPlayer()
    if showDebug then
        drawStrokeRect(cameraX, cameraY, DESIGN_W, DESIGN_H, 0, rgba(255, 255, 0, 120), 2)
        drawCircle(player.x, player.y, player.radius + 2, rgba(70, 210, 255, 140))
    end
end

function enterSealView()
    showSeal = true
    showHelp = false
    sealViewProgress = 0
    sealStampProgress = 0
    completionSealDelay = 0
    player.isDashing = false
    dashJustPressed = false
    keys.a = false
    keys.d = false
    keys.w = false
    keys.s = false
    keys.space = false
    keys.shift = false
end

function exitSealView()
    showSeal = false
    sealViewProgress = 0
    sealStampProgress = 0
    completionSealDelay = 0
end

function sealInfoForCurrentLevel()
    if currentLevel.id == "bamboo" then
        return { x = 0.94, y = 0.65, size = 100, primaryA = "风竹", primaryB = "傲骨", paper = C(232, 238, 230), wear = 60 }
    elseif currentLevel.id == "pine" then
        return { x = 0.94, y = 0.45, size = 130, primaryA = "听泉", primaryB = "破境", vertical = "清气乾坤", paper = C(242, 230, 207), wear = 80 }
    elseif currentLevel.id == "peach" then
        return { x = 0.94, y = 0.45, size = 130, primaryA = "春水", primaryB = "破境", vertical = "春江水暖", paper = C(236, 241, 226), wear = 80 }
    elseif currentLevel.id == "eaves" then
        return { x = 0.94, y = 0.45, size = 130, primaryA = "古阁", primaryB = "飞檐", vertical = "古阁金秋", paper = C(239, 230, 213), wear = 80 }
    elseif currentLevel.id == "plum_finale" then
        return { x = 0.94, y = 0.88, size = 110, primaryA = "双清", primaryB = "梅卷", vertical = "梅竹双清", paper = C(214, 190, 152), wear = 80 }
    elseif currentLevel.id == "wentong_zhu" then
        return { x = 0.06, y = 0.85, size = 110, primaryA = "与可", primaryB = "倒垂", vertical = "胸有成竹", paper = C(172, 140, 86), wear = 90 }
    elseif currentLevel.id == "plum_xiyan" then
        return { x = 0.06, y = 0.80, size = 110, primaryA = "洗砚", primaryB = "清气", vertical = "淡墨痕", paper = C(206, 202, 192), wear = 80 }
    elseif currentLevel.id == "molong" then
        return { x = 0.03, y = 0.08, size = 110, primaryA = "九龙", primaryB = "行雨", vertical = "神龙见首", paper = C(166, 158, 140), wear = 90 }
    elseif currentLevel.id == "xuwei_grape" then
        return { x = 0.80, y = 0.88, size = 110, primaryA = "青藤", primaryB = "明珠", vertical = "笔底明珠", paper = C(214, 202, 176), wear = 90 }
    else
        return { x = 0.94, y = 0.45, size = 130, primaryA = "弄梅", primaryB = "破境", vertical = "清气乾坤", paper = C(246, 237, 225), wear = 80 }
    end
end

function drawSealWear(x, y, w, h, seed, count, maxRadius, alpha, paper)
    paper = paper or currentLevel.paper
    for i = 1, count do
        local px = x + hash01(seed + i * 17.31) * w
        local py = y + hash01(seed + i * 23.17) * h
        local r = 0.7 + hash01(seed + i * 29.41) * maxRadius
        drawCircle(px, py, r, rgba(paper[1], paper[2], paper[3], 230 * alpha))
    end
end

function drawVerticalSealText(text, x, y, size, gap, color)
    local chars = utf8Chars(text)
    for i = 1, #chars do
        drawText(x, y + (i - 1) * gap, size, color, chars[i], NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
end

function drawSealImpression(alpha)
    if alpha <= 0 then return end
    local info = sealInfoForCurrentLevel()
    local stampX = worldW * info.x
    local stampY = worldH * info.y
    local size = info.size
    local red = rgba(181, 28, 28, 235 * alpha)
    local paper = info.paper or currentLevel.paper
    local paperInk = rgba(paper[1], paper[2], paper[3], 245 * alpha)

    drawRect(stampX, stampY, size, size, 0, red)
    drawStrokeRect(stampX, stampY, size, size, 0, rgba(120, 10, 10, 115 * alpha), 4)
    drawText(stampX + size * 0.5, stampY + size * 0.20, size * 0.32, paperInk, info.primaryA, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    drawText(stampX + size * 0.5, stampY + size * 0.62, size * 0.32, paperInk, info.primaryB, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    if info.vertical then
        local stamp2X = stampX - 160
        local stamp2Y = stampY + 120
        drawStrokeRect(stamp2X, stamp2Y, 110, 240, 0, red, 8)
        drawVerticalSealText(info.vertical, stamp2X + 55, stamp2Y + 26, 32, 50, red)
        drawSealWear(stamp2X, stamp2Y, 110, 240, worldW * 0.012 + worldH * 0.019 + 91, info.wear, 3, alpha, paper)
    end

    drawSealWear(stampX, stampY, size, size, worldW * 0.013 + worldH * 0.017 + 37, info.wear, size == 100 and 2 or 3, alpha, paper)
end

function drawSealGallery()
    local p = clamp(sealViewProgress, 0, 1)
    local ease = p * p * (3 - 2 * p)
    local finalScale = math.min(DESIGN_W / worldW, DESIGN_H / worldH) * 0.82
    local finalX = (DESIGN_W - worldW * finalScale) * 0.5
    local finalY = (DESIGN_H - worldH * finalScale) * 0.5
    local tx = -cameraX + (finalX + cameraX) * ease
    local ty = -cameraY + (finalY + cameraY) * ease
    local scale = 1 + (finalScale - 1) * ease
    local frameA = ease * ease
    local framePad = 24
    local frameX = tx - framePad
    local frameY = ty - framePad
    local frameW = worldW * scale + framePad * 2
    local frameH = worldH * scale + framePad * 2

    drawRect(0, 0, DESIGN_W, DESIGN_H, 0, rgba(8, 7, 6, 250))
    for i = 1, 18 do
        local bandA = 12 + i * 3
        drawRect(0, (i - 1) * DESIGN_H / 18, DESIGN_W, DESIGN_H / 18 + 2, 0, rgba(32, 24, 18, bandA * frameA))
    end

    if frameA > 0.02 then
        drawRect(frameX - 6, frameY - 6, frameW + 12, frameH + 12, 0, rgba(20, 13, 8, 230 * frameA))
        drawRect(frameX, frameY, frameW, frameH, 0, currentLevel.id == "bamboo" and rgba(36, 48, 39, 235 * frameA) or rgba(60, 42, 26, 235 * frameA))
        drawStrokeRect(frameX, frameY, frameW, frameH, 0, rgba(12, 8, 5, 245 * frameA), 6)
    end

    nvgSave(vg)
    nvgTranslate(vg, tx, ty)
    nvgScale(vg, scale, scale)
    drawWorld()
    drawSealImpression(clamp((sealStampProgress - 0.76) / 0.20, 0, 1))
    nvgRestore(vg)

    if p >= 0.98 then
        drawText(DESIGN_W * 0.5, DESIGN_H - 34, 13, rgba(230, 214, 190, 150), "F 退出雅鉴    Q/E 换卷", NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
end

local function drawHud()
    local state = "air"
    if player.isDashing then state = "dash"
    elseif player.onEaves then state = "eaves"
    elseif player.swingRope then state = "rope"
    elseif player.ridingCrane then state = "crane"
    elseif player.isWallClinging then state = "wall"
    elseif player.isGrounded then state = "ground" end
    local h = showHelp and 184 or 88
    drawRect(18, 18, 720, h, 4, rgba(8, 12, 10, 188))
    drawStrokeRect(18, 18, 720, h, 4, colorRGBA(currentLevel.accent, 170), 2)
    drawText(40, 34, 25, rgba(250, 250, 246, 240), string.format("%d/%d  %s", currentLevelIdx, #LEVELS, currentLevel.name))
    drawText(40, 66, 14, rgba(220, 226, 218, 225), currentLevel.title)
    drawText(40, 92, 13, rgba(210, 220, 210, 220), string.format("state %s  dash %s  blooms %d/%d", state, player.canDash and "ready" or "used", collectedCount, #targets))
    if showHelp then
        drawText(40, 120, 13, rgba(205, 216, 204, 220), "A/D or Arrows: move    Space/W/Up: jump    J: 8-way dash    S/Down: dash downward")
        drawText(40, 142, 13, rgba(205, 216, 204, 220), "Q/E or 1-9/0: switch scroll    C: debug nodes    F: seal    R: reload")
        drawText(40, 164, 13, rgba(178, 194, 178, 220), currentLevel.note)
    end
    if completionTimer > 0 then
        drawRect(DESIGN_W - 182, 36, 112, 112, 2, rgba(150, 20, 18, 215))
        drawStrokeRect(DESIGN_W - 182, 36, 112, 112, 2, rgba(245, 230, 205, 220), 3)
        drawText(DESIGN_W - 126, 68, 46, rgba(245, 230, 205, 235), currentLevel.seal, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        drawText(DESIGN_W - 126, 124, 13, rgba(245, 230, 205, 220), "落款", NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
end

local function loadDefaultFont()
    local fontId = nvgCreateFont(vg, "sans", "Fonts/MiSans-Regular.ttf")
    if fontId < 0 then fontId = nvgCreateFont(vg, "sans", "Fonts/Anonymous Pro.ttf") end
    fontReady = fontId >= 0
    if not fontReady then print("WARNING: failed to load NanoVG font") end
end

function Start()
    print("=== Faithful ink HTML port start ===")
    vg = nvgCreate(1)
    if vg == nil then
        print("ERROR: failed to create NanoVG")
        return
    end
    loadDefaultFont()
    loadLevel(1)
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent(vg, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("KeyUp", "HandleKeyUp")
end

function Stop()
end

function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    if dt > 0.05 then dt = 0.05 end
    accumulator = accumulator + dt
    while accumulator >= FIXED_DT do
        if showSeal then
            sealViewProgress = math.min(1, sealViewProgress + FIXED_DT / 3.8)
            sealStampProgress = math.min(1, sealStampProgress + FIXED_DT / 3.8)
        else
            fixedStep()
            updateParticles()
            updateCamera()
            if completionSealDelay > 0 then
                completionSealDelay = completionSealDelay - FIXED_DT
                if completionSealDelay <= 0 then
                    local ready = true
                    for _, b in ipairs(blooms) do
                        if (b.progress or 1) < 0.98 then
                            ready = false
                            break
                        end
                    end
                    if ready then
                        completionSealDelay = 0
                        enterSealView()
                    else
                        completionSealDelay = FIXED_DT
                    end
                end
            end
            if completionTimer > 0 then completionTimer = completionTimer - FIXED_DT end
        end
        accumulator = accumulator - FIXED_DT
    end
end

function setKeyState(key, value)
    if keyMatches(key, leftKeys) then keys.a = value end
    if keyMatches(key, rightKeys) then keys.d = value end
    if keyMatches(key, upKeys) then keys.w = value end
    if keyMatches(key, downKeys) then keys.s = value end
    if keyMatches(key, jumpKeys) or keyMatches(key, upKeys) then
        if value and not keys.space then keys.space = true elseif not value and keyMatches(key, jumpKeys) then keys.space = false end
    end
end

function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    if showSeal then
        if keyMatches(key, sealKeys) then
            exitSealView()
        elseif keyMatches(key, resetKeys) then
            loadLevel(currentLevelIdx)
        elseif keyMatches(key, prevKeys) then
            loadLevel(currentLevelIdx - 1)
        elseif keyMatches(key, nextKeys) then
            loadLevel(currentLevelIdx + 1)
        elseif KEY_ESCAPE and key == KEY_ESCAPE and engine ~= nil then
            engine:Exit()
        else
            if #LEVELS >= 10 and (key == string.byte("0") or (_G["KEY_0"] and key == _G["KEY_0"])) then
                loadLevel(10)
                return
            end
            for i = 1, #LEVELS do
                if key == string.byte(tostring(i)) or (_G["KEY_" .. tostring(i)] and key == _G["KEY_" .. tostring(i)]) then
                    loadLevel(i)
                    break
                end
            end
        end
        return
    end
    setKeyState(key, true)
    if keyMatches(key, dashKeys) then
        if not keys.shift then dashJustPressed = true end
        keys.shift = true
    elseif keyMatches(key, debugKeys) then
        showDebug = not showDebug
    elseif keyMatches(key, helpKeys) then
        showHelp = not showHelp
    elseif keyMatches(key, resetKeys) then
        loadLevel(currentLevelIdx)
    elseif keyMatches(key, prevKeys) then
        loadLevel(currentLevelIdx - 1)
    elseif keyMatches(key, nextKeys) then
        loadLevel(currentLevelIdx + 1)
    elseif keyMatches(key, sealKeys) then
        enterSealView()
    elseif KEY_ESCAPE and key == KEY_ESCAPE and engine ~= nil then
        engine:Exit()
    else
        if #LEVELS >= 10 and (key == string.byte("0") or (_G["KEY_0"] and key == _G["KEY_0"])) then
            loadLevel(10)
            return
        end
        for i = 1, #LEVELS do
            if key == string.byte(tostring(i)) or (_G["KEY_" .. tostring(i)] and key == _G["KEY_" .. tostring(i)]) then
                loadLevel(i)
                break
            end
        end
    end
end

function HandleKeyUp(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    setKeyState(key, false)
    if keyMatches(key, dashKeys) then keys.shift = false end
end

function HandleNanoVGRender(eventType, eventData)
    local physW = graphics:GetWidth()
    local physH = graphics:GetHeight()
    local dpr = graphics:GetDPR()
    screenW = physW / dpr
    screenH = physH / dpr

    nvgBeginFrame(vg, screenW, screenH, dpr)
    if currentLevel and currentLevel.backdrop then
        drawRect(0, 0, screenW, screenH, 0, colorRGB(currentLevel.backdrop))
    else
        drawRect(0, 0, screenW, screenH, 0, rgba(0, 0, 0, 255))
    end

    fitScale = math.min(screenW / DESIGN_W, screenH / DESIGN_H)
    local renderW = DESIGN_W * fitScale
    local renderH = DESIGN_H * fitScale
    viewX = (screenW - renderW) * 0.5
    viewY = (screenH - renderH) * 0.5

    nvgSave(vg)
    nvgTranslate(vg, viewX, viewY)
    nvgScale(vg, fitScale, fitScale)
    nvgScissor(vg, 0, 0, DESIGN_W, DESIGN_H)
    if showSeal then
        drawSealGallery()
    else
        nvgSave(vg)
        nvgTranslate(vg, -cameraX, -cameraY)
        drawWorld()
        nvgRestore(vg)
        drawHud()
    end
    nvgResetScissor(vg)
    nvgRestore(vg)
    nvgEndFrame(vg)
end

-- ============================================================================
-- END scripts/src/90_world_seal_runtime.lua
-- ============================================================================

