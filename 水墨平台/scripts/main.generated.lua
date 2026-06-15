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
    {
        id = "trace_zhumei", trace = true, traceKey = "zhumei",
        name = "水墨竹梅", title = "水墨平台跳跃 - 竹梅画卷", seal = "梅",
        note = "触碰枝头花苞与兰芽,墨梅次第绽放。抵达卷尾,画卷将自动装裱钤印。",
        wmul = 3.4, hmul = 1.3,
        paper = C(243, 239, 229), paper2 = C(229, 225, 214),
        ink = C(25, 23, 21), wash = C(131, 129, 122), accent = C(186, 48, 40),
        bloom = C(197, 38, 64), water = C(243, 239, 229),
        radius = 10, gravity = 0.52, jumpForce = -15.5, dashSpeed = 19, friction = 0.86,
    },
    {
        id = "trace_forest", trace = true, traceKey = "forest",
        name = "金绿林行", title = "水墨平台跳跃 - 金绿林行", seal = "林",
        note = "金光林海,沿梁柱穿行。触碰交互点唤醒花苞。",
        wmul = 3.6, hmul = 3.3,
        paper = C(108, 128, 14), paper2 = C(151, 161, 25),
        ink = C(18, 26, 10), wash = C(72, 94, 12), accent = C(245, 222, 82),
        bloom = C(245, 222, 82), water = C(108, 128, 14),
        radius = 10, gravity = 0.52, jumpForce = -15.5, dashSpeed = 19, friction = 0.86,
    },
    {
        id = "trace_water", trace = true, traceKey = "water",
        name = "青蓝水城", title = "水墨平台跳跃 - 青蓝水城", seal = "水",
        note = "斜塔拱桥,青空之城。沿白点饰边前行。",
        wmul = 5.1, hmul = 3.4,
        paper = C(94, 249, 254), paper2 = C(150, 226, 238),
        ink = C(52, 44, 96), wash = C(112, 103, 201), accent = C(250, 252, 255),
        bloom = C(250, 252, 255), water = C(92, 222, 232),
        radius = 10, gravity = 0.52, jumpForce = -15.5, dashSpeed = 19, friction = 0.86,
    },
    {
        id = "trace_bamboo_scroll", trace = true, traceKey = "bamboo",
        name = "墨竹行", title = "水墨平台跳跃 - 墨竹长卷", seal = "竹",
        note = "踏节而上,触苞补笔。浓墨可踏,中墨为景;走过之处,竹叶次第展开。",
        wmul = 3.4, hmul = 1.3,
        paper = C(243, 239, 229), paper2 = C(229, 225, 214),
        ink = C(25, 23, 21), wash = C(131, 129, 122), accent = C(186, 48, 40),
        bloom = C(197, 38, 64), water = C(243, 239, 229),
        radius = 10, gravity = 0.52, jumpForce = -15.5, dashSpeed = 19, friction = 0.86,
    },
    {
        id = "trace_bamboo_scroll_v2", trace = true, traceKey = "bamboo_v2",
        name = "墨竹行", title = "水墨平台跳跃 - 墨竹长卷·大格局", seal = "竹",
        note = "七幕大格局竹卷:竖梯、链苞、垂梢、雾渡仙鹤、弹梢与长卷桥依次展开。",
        wmul = 6.56, hmul = 3.61,
        paper = C(243, 239, 229), paper2 = C(229, 225, 214),
        ink = C(25, 23, 21), wash = C(131, 129, 122), accent = C(186, 48, 40),
        bloom = C(197, 38, 64), water = C(243, 239, 229),
        radius = 10, gravity = 0.52, jumpForce = -15.5, dashSpeed = 19, friction = 0.86,
    },
    {
        id = "trace_video4", trace = true, traceKey = "video4",
        name = "参考视频4复刻", title = "逐帧描摹 - 参考视频4", seal = "映",
        note = "由参考视频4.mp4抽帧、分层、拼接生成的画面同源复刻关卡。",
        wmul = 3.8, hmul = 1.0,
        paper = C(221, 226, 220), paper2 = C(209, 212, 208),
        ink = C(33, 37, 39), wash = C(126, 132, 129), accent = C(78, 90, 83),
        bloom = C(197, 38, 64), water = C(188, 192, 188),
        radius = 10, gravity = 0.52, jumpForce = -15.5, dashSpeed = 19, friction = 0.86,
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

    if currentLevel.trace then
        player.x, player.y = TRACE_RT.spawnX, TRACE_RT.spawnY - 24
    elseif currentLevel.id == "bamboo" then
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
    elseif currentLevel.trace then generateTraceLevel()
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

    if currentLevel.trace and TRACE_RT and TRACE_RT.bamboo then
        if updateBambooScrollSpecial then
            updateBambooScrollSpecial()
            if player.swingRope or player.ridingCrane then return end
        end
    elseif currentLevel.id == "bamboo" then
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
        if not c.path then
            c.x = c.x + c.speed
            c.theta = c.theta + 0.03
            c.y = c.startY + math.sin(c.theta) * c.amplitude
            c.wingAngle = math.sin(c.theta * 3.5) * (math.pi / 4)
            if c.x > worldW + 100 then
                c.x = -100
                c.startY = H(0.2 + hash01(elapsed + c.speed) * 0.4)
            end
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

    if currentLevel.trace then
        traceCollision(prevX, prevY)
    elseif currentLevel.id == "bamboo" then
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
    if currentLevel.trace then
        traceUpdateCamera()
        return
    end
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
-- BEGIN scripts/src/85_trace_levels.lua
-- ============================================================================
TRACE_DEBUG_FIT = false
-- 描摹关运行时(第 18+ 关):多边形碰撞 + 分层视差 + 触碰开花 + 画卷终幕
-- 注意:本文件不得新增 chunk 顶级 local(bundle 已 199/200),全部用全局。

TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0, def = nil,
    goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0,
    chars = {}, pools = {}, ripples = {}, ghostGrps = {}, plumDone = 0, plumTotal = 0 }

function traceInsidePoly(poly, x, y)
    local n = #poly
    local inside = false
    for i = 1, n do
        local ax, ay = poly[i][1], poly[i][2]
        local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
        if (ay > y) ~= (by > y) then
            local ix = ax + (y - ay) / (by - ay) * (bx - ax)
            if ix > x then inside = not inside end
        end
    end
    return inside
end

function traceSnapDown(x, y)
    local bestY = nil
    for _, poly in ipairs(TRACE_RT.polys) do
        local bb = poly.bb
        if (not poly.ghostGrp) and ((not bb) or (x >= bb[1] - 4 and x <= bb[3] + 4)) then
            local n = #poly
            for i = 1, n do
                local ax, ay = poly[i][1], poly[i][2]
                local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
                if (ax < x) ~= (bx < x) and math.abs(bx - ax) > 1e-6 then
                    local t = (x - ax) / (bx - ax)
                    local iy = ay + (by - ay) * t
                    if iy >= y - 100 and iy <= y + 1500 then
                        if (bestY == nil or iy < bestY) and traceInsidePoly(poly, x, iy + 5) then
                            bestY = iy
                        end
                    end
                end
            end
        end
    end
    if bestY then return bestY - 2 end
    return y
end

function generateTraceLevel()
    if currentLevel.traceKey == "bamboo" or currentLevel.traceKey == "bamboo_v2" then
        generateBambooScroll()
        return
    end
    local def = TRACE_DEFS[currentLevel.traceKey]
    TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0, def = def,
        goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0,
        chars = {}, pools = {}, ripples = {}, ghostGrps = {}, plumDone = 0, plumTotal = 0 }
    TRACE_RT.design = TRACE_IPTS and TRACE_IPTS[currentLevel.traceKey] or nil
    worldW = def.spanx2 + def.frw
    worldH = def.spany2 + def.frh
    -- 层包围盒 + 碰撞多边形
    for _, lay in ipairs(def.layers) do
        if not lay.bb then
            lay.bb = {}
            for pi, fp in ipairs(lay.polys) do
                local x1, y1, x2, y2 = 1e9, 1e9, -1e9, -1e9
                for k = 1, #fp - 1, 2 do
                    local x, y = fp[k], fp[k + 1]
                    if x < x1 then x1 = x end
                    if x > x2 then x2 = x end
                    if y < y1 then y1 = y end
                    if y > y2 then y2 = y end
                end
                lay.bb[pi] = { x1, y1, x2, y2 }
            end
        end
        if lay.coll == 1 then
            for pi, fp in ipairs(lay.polys) do
                local poly = {}
                for k = 1, #fp - 1, 2 do poly[#poly + 1] = { fp[k], fp[k + 1] } end
                poly.bb = lay.bb[pi]
                TRACE_RT.polys[#TRACE_RT.polys + 1] = poly
            end
        end
    end
    -- 鬼阶:设计区内完整包含的碰撞体转虚影组(激活后限时实体)
    if TRACE_RT.design and TRACE_RT.design.ghosts then
        for _, gz in ipairs(TRACE_RT.design.ghosts) do
            local grp = { timer = 0, polys = {} }
            for _, poly in ipairs(TRACE_RT.polys) do
                local bb = poly.bb
                if bb and bb[1] >= gz.zone[1] and bb[2] >= gz.zone[2]
                    and bb[3] <= gz.zone[3] and bb[4] <= gz.zone[4] then
                    poly.ghostGrp = grp
                    grp.polys[#grp.polys + 1] = poly
                end
            end
            TRACE_RT.ghostGrps[#TRACE_RT.ghostGrps + 1] = grp
        end
    end
    -- 出生/存档吸附
    TRACE_RT.spawnX = def.conf.spawn[1]
    TRACE_RT.spawnY = traceSnapDown(def.conf.spawn[1], def.conf.spawn[2]) - 12
    TRACE_RT.cps = {}
    for i, cp in ipairs(def.conf.cps) do
        TRACE_RT.cps[i] = { cp[1], traceSnapDown(cp[1], cp[2]) - 12 }
        TRACE_RT.cpReached[i] = (i == 1)
    end
    -- 交互点:装饰层聚类(梅红/兰绿) + 沿顶面自动补点
    local plumPts, orchidPts = {}, {}
    for _, lay in ipairs(def.layers) do
        local oc = lay.ocol
        if oc[1] == 150 and oc[2] == 45 then
            for _, bb in ipairs(lay.bb) do
                plumPts[#plumPts + 1] = { x = (bb[1] + bb[3]) * 0.5, y = (bb[2] + bb[4]) * 0.5,
                    r = clamp(math.max(bb[3] - bb[1], bb[4] - bb[2]) * 0.5, 12, 30) }
            end
        elseif oc[1] == 72 and oc[2] == 115 then
            for pi, bb in ipairs(lay.bb) do
                orchidPts[#orchidPts + 1] = { x = (bb[1] + bb[3]) * 0.5, y = bb[4], lay = lay, pi = pi }
            end
        end
    end
    local function clusterize(pts, rad, kind)
        for _, pt in ipairs(pts) do
            local home = nil
            for _, ip in ipairs(TRACE_RT.ipoints) do
                if ip.kind == kind and (ip.x - pt.x) ^ 2 + (ip.y - pt.y) ^ 2 < rad * rad then
                    home = ip
                    break
                end
            end
            if not home then
                home = { x = pt.x, y = pt.y, kind = kind, trig = false, members = {}, n = 0 }
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] = home
            end
            pt.t = 0
            pt.delay = 0
            home.members[#home.members + 1] = pt
            home.n = home.n + 1
            home.x = home.x + (pt.x - home.x) / home.n
            home.y = home.y + (pt.y - home.y) / home.n
        end
    end
    clusterize(plumPts, 360, "plum")
    clusterize(orchidPts, 300, "orchid")
    for _, ip in ipairs(TRACE_RT.ipoints) do
        if ip.kind == "plum" then TRACE_RT.plumTotal = TRACE_RT.plumTotal + 1 end
    end
    -- 设计锚点(87_trace_ipoints):风袂/蓄墨苞/墨池/拾字
    if TRACE_RT.design then
        for _, d in ipairs(TRACE_RT.design.ipts) do
            if d.kind == "gust" then
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] =
                    { x = d.x, y = d.y, kind = "gust", arm = 0, burst = 999, members = {} }
            elseif d.kind == "key" then
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] =
                    { x = d.x, y = d.y, kind = "key", grp = TRACE_RT.ghostGrps[d.grp],
                        bloomT = 0, members = {} }
            elseif d.kind == "deco" then
                -- 石上兰:吸附到岩面再生成(沿用 sprout 触碰开兰逻辑)
                local sy2 = traceSnapDown(d.x, d.y - 120)
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] =
                    { x = d.x, y = sy2 - 14, kind = "sprout", trig = false,
                        members = { { x = d.x, y = sy2, r = 1, t = 0, delay = 0 } } }
            elseif d.kind == "char" then
                TRACE_RT.chars[#TRACE_RT.chars + 1] =
                    { x = d.x, y = d.y, ch = d.ch, got = false, fade = 0 }
            elseif d.kind == "pool" then
                local my2 = traceSnapDown((d.x1 + d.x2) * 0.5, d.y - 200)
                TRACE_RT.pools[#TRACE_RT.pools + 1] = { x1 = d.x1, x2 = d.x2, y = my2 }
            end
        end
    end
    -- 自动补点(顶面;有设计数据的关停用,避免黑地长花)
    local cands = {}
    for _, poly in ipairs(TRACE_RT.polys) do
        local n = #poly
        for i = 1, n do
            local ax, ay = poly[i][1], poly[i][2]
            local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
            if math.abs(by - ay) < 14 and math.abs(bx - ax) > 90 then
                local mx, my = (ax + bx) / 2, (ay + by) / 2
                if traceInsidePoly(poly, mx, my + 8) then
                    cands[#cands + 1] = { x = mx, y = my }
                end
            end
        end
    end
    table.sort(cands, function(a, b) return a.x < b.x end)
    local lastX = -1e9
    if TRACE_RT.design then cands = {} end
    for ci, cd in ipairs(cands) do
        if cd.x - lastX > 520 then
            local clash = false
            for _, ip in ipairs(TRACE_RT.ipoints) do
                if (ip.x - cd.x) ^ 2 + (ip.y - cd.y) ^ 2 < 360 * 360 then
                    clash = true
                    break
                end
            end
            if not clash then
                lastX = cd.x
                local kind = (hash01(ci * 5.3) > 0.45) and "plum" or "sprout"
                local ip = { x = cd.x, y = cd.y - 16, kind = kind, trig = false, members = {} }
                if kind == "plum" then
                    for k = 1, 4 + math.floor(hash01(ci) * 3) do
                        ip.members[#ip.members + 1] = { x = cd.x + (hash01(ci * 7 + k) - 0.5) * 130,
                            y = cd.y - 10 - hash01(ci * 11 + k) * 42,
                            r = 11 + hash01(ci * 13 + k) * 8, t = 0, delay = 0 }
                    end
                else
                    ip.members[#ip.members + 1] = { x = cd.x, y = cd.y, r = 1, t = 0, delay = 0 }
                end
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] = ip
            end
        end
    end
    -- 描摹关专属镜头(沿用 kingsbird 设计:广角+慢跟随)
    TRACE_RT.zoom = TRACE_DEBUG_FIT and math.min(DESIGN_W / (worldW + 80), DESIGN_H / (worldH + 80)) or (({ zhumei = 0.75, forest = 0.92, water = 0.92 })[currentLevel.traceKey] or 1.0)
    TRACE_RT.camCx = TRACE_RT.spawnX
    TRACE_RT.camCy = TRACE_RT.spawnY - 50
    print(string.format("[trace] %s polys=%d ipoints=%d world=%dx%d",
        currentLevel.traceKey, #TRACE_RT.polys, #TRACE_RT.ipoints, worldW, worldH))
end

function traceUpdateCamera()
    local RT = TRACE_RT
    if not RT.def then return end
    local z = RT.zoom or 1
    local halfW = DESIGN_W / (2 * z)
    local halfH = DESIGN_H / (2 * z)
    local tx = player.x
    local ty = player.y - 50
    RT.camCx = (RT.camCx or tx) + (tx - (RT.camCx or tx)) * 0.07
    local yFollow = 0.06
    if RT.bamboo and RT.bambooData == BAMBOO_DATA_22 and player.x > 4400 and player.x < 5050 then yFollow = 0.12 end
    RT.camCy = (RT.camCy or ty) + (ty - (RT.camCy or ty)) * yFollow
    if worldW <= halfW * 2 then RT.camCx = worldW / 2
    else RT.camCx = clamp(RT.camCx, halfW, worldW - halfW) end
    if worldH <= halfH * 2 then RT.camCy = worldH / 2
    else RT.camCy = clamp(RT.camCy, halfH, worldH - halfH) end
    cameraX = RT.camCx - DESIGN_W / 2
    cameraY = RT.camCy - DESIGN_H / 2
    -- 镜头随笔锋:触苞瞬间朝生长方向轻推
    if RT.nudge and RT.nudge.t > 0 then
        local f = RT.nudge.t / 22
        f = f * f
        cameraX = cameraX + RT.nudge.x * f
        cameraY = cameraY + RT.nudge.y * f
        RT.nudge.t = RT.nudge.t - 1
    end
end

function traceCollideOnce()
    local pr = player.radius
    local px, py = player.x, player.y
    local hitG, wallSide = false, 0
    for _, poly in ipairs(TRACE_RT.polys) do
        local bb = poly.bb
        if (poly.ghostGrp and poly.ghostGrp.timer <= 0) then
            -- 鬼阶未实体化:无碰撞
        elseif not (bb and (px + pr < bb[1] or px - pr > bb[3] or py + pr < bb[2] or py - pr > bb[4])) then
            local n = #poly
            local inside = false
            local bestD2, bestX, bestY = 1e18, 0, 0
            for i = 1, n do
                local ax, ay = poly[i][1], poly[i][2]
                local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
                if (ay > py) ~= (by > py) then
                    local ix = ax + (py - ay) / (by - ay) * (bx - ax)
                    if ix > px then inside = not inside end
                end
                local ex, ey = bx - ax, by - ay
                local L2 = ex * ex + ey * ey
                if L2 > 1e-6 then
                    local t = clamp(((px - ax) * ex + (py - ay) * ey) / L2, 0, 1)
                    local cx, cy = ax + ex * t, ay + ey * t
                    local dx, dy = px - cx, py - cy
                    local d2 = dx * dx + dy * dy
                    if d2 < bestD2 then bestD2, bestX, bestY = d2, cx, cy end
                end
            end
            if inside then
                local dx, dy = bestX - px, bestY - py
                local d = math.sqrt(dx * dx + dy * dy)
                local nx, ny
                if d > 1e-4 then nx, ny = dx / d, dy / d else nx, ny = 0, -1 end
                local vdot = nx * player.vx + ny * player.vy
                if vdot > 0.1 then
                    local spd = math.sqrt(player.vx ^ 2 + player.vy ^ 2)
                    if spd > 0.5 then nx, ny = -player.vx / spd, -player.vy / spd; bestX, bestY = px, py end
                end
                px = bestX + nx * (pr + 1)
                py = bestY + ny * (pr + 1)
                local vn = player.vx * nx + player.vy * ny
                if vn < 0 then player.vx = player.vx - nx * vn; player.vy = player.vy - ny * vn end
                if ny < -0.55 then hitG = true end
                if nx > 0.75 then wallSide = -1 end
                if nx < -0.75 then wallSide = 1 end
            elseif bestD2 < pr * pr and bestD2 > 1e-9 then
                local d = math.sqrt(bestD2)
                local nx, ny = (px - bestX) / d, (py - bestY) / d
                px = bestX + nx * pr
                py = bestY + ny * pr
                local vn = player.vx * nx + player.vy * ny
                if vn < 0 then player.vx = player.vx - nx * vn; player.vy = player.vy - ny * vn end
                if ny < -0.55 then hitG = true end
                if nx > 0.75 then wallSide = -1 end
                if nx < -0.75 then wallSide = 1 end
            end
        end
    end
    player.x, player.y = px, py
    return hitG, wallSide
end

function traceCollision(prevX, prevY)
    local RT = TRACE_RT
    if not RT.def then return end
    -- 顿笔:触苞瞬间冻结数帧(有收笔点则锁在收笔点,否则回卷上一帧)
    if RT.hitstop and RT.hitstop > 0 then
        RT.hitstop = RT.hitstop - 1
        if RT.hitstopX then
            player.x, player.y = RT.hitstopX, RT.hitstopY
            if RT.hitstop <= 0 then RT.hitstopX = nil end
        else
            player.x, player.y = prevX, prevY
        end
        return
    end
    -- 终幕:冻结
    if RT.goalDone then
        RT.vista = RT.vista + 1
        player.x, player.y = RT.gx, RT.gy
        player.vx, player.vy = 0, 0
        player.isDashing = false
        player.canDash = false
        if RT.vista == 430 then loadLevel(currentLevelIdx + 1) end
        return
    end
    -- 子步碰撞(防高速穿透):回退到 prev 再分步推进
    local mx, my = player.x - prevX, player.y - prevY
    local steps = math.max(1, math.ceil(math.sqrt(mx * mx + my * my) / 6))
    player.x, player.y = prevX, prevY
    local hitG, wallSide = false, 0
    for i = 1, steps do
        player.x = player.x + mx / steps
        player.y = player.y + my / steps
        local g, w = traceCollideOnce()
        if g then hitG = true end
        if w ~= 0 then wallSide = w end
    end
    player.isGrounded = hitG
    if hitG then
        player.canDash = true
        player.isWallClinging = false
    elseif wallSide ~= 0 and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = wallSide
    else
        player.isWallClinging = false
    end
    -- 跌落/雾渊回档
    local dead = player.y > RT.def.conf.kill
    if (not dead) and RT.bamboo and RT.bambooData and RT.bambooData.killZones then
        for _, z in ipairs(RT.bambooData.killZones) do
            if player.x >= z[1] and player.x <= z[3] and player.y >= z[2] and player.y <= z[4] then
                dead = true
                break
            end
        end
    end
    if dead then
        player.x, player.y = RT.spawnX, RT.spawnY - 24
        player.vx, player.vy = 0, 0
        player.isDashing = false
        player.swingRope, player.ridingCrane = nil, nil
        player.canDash = true
    end
    -- 存档点
    for i, cp in ipairs(RT.cps) do
        if not RT.cpReached[i] then
            local dx, dy = player.x - cp[1], player.y - cp[2]
            if dx * dx + dy * dy < 80 * 80 then
                RT.cpReached[i] = true
                RT.spawnX, RT.spawnY = cp[1], cp[2]
            end
        end
    end
    -- 终点(梅苞集满才开卷)
    local g = RT.def.conf.goal
    local dgx, dgy = player.x - g[1], player.y - g[2]
    if dgx * dgx + dgy * dgy < 95 * 95 and RT.plumDone >= RT.plumTotal then
        RT.goalDone = true
        RT.vista = 0
        RT.gx, RT.gy = player.x, player.y
    end
    -- 鬼阶计时
    for _, grp in ipairs(RT.ghostGrps) do
        if grp.timer > 0 then grp.timer = grp.timer - 1 end
    end
    -- 拾字
    for _, ch in ipairs(RT.chars) do
        if not ch.got then
            local dx, dy = player.x - ch.x, player.y - ch.y
            if dx * dx + dy * dy < 58 * 58 then
                ch.got = true
                for k = 1, 10 do
                    RT.petals[#RT.petals + 1] = { x = ch.x, y = ch.y,
                        vx = (hash01(ch.x + k * 7) - 0.5) * 2.6, vy = -0.8 - hash01(k * 3.1) * 1.4,
                        rot = hash01(k * 5.7) * 6.28, vr = (hash01(k * 9.1) - 0.5) * 0.15,
                        life = 80 + k * 4, age = 0, ph = k, col = { 176, 142, 56 } }
                end
            end
        elseif ch.fade < 1 then
            ch.fade = math.min(1, ch.fade + 0.03)
        end
    end
    -- 墨池:落入溅墨晕 + 轻滑步
    if RT.bamboo and RT.bambooData and RT.bambooData.inkPools then
        for _, pl in ipairs(RT.bambooData.inkPools) do
            if player.isGrounded and player.x > pl.x1 and player.x < pl.x2
                and math.abs(player.y - pl.y) < 130 then
                if my > 5.5 then
                    RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                        t = 0, big = math.min(my / 14, 1.4) }
                    RT.fallPenalty = math.max(RT.fallPenalty or 0, 30)
                elseif math.abs(player.vx) > 5 and hash01(elapsed * 53 + player.x) < 0.10 then
                    RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                        t = 0, big = 0.45 }
                end
                if math.abs(player.vx) > 1 and math.abs(player.vx) < 13 then
                    player.vx = player.vx * 1.05
                end
            end
        end
    end
    for _, pl in ipairs(RT.pools) do
        if player.isGrounded and player.x > pl.x1 and player.x < pl.x2
            and math.abs(player.y - pl.y) < 130 then
            if my > 5.5 then
                RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                    t = 0, big = math.min(my / 14, 1.4) }
            elseif math.abs(player.vx) > 5 and hash01(elapsed * 53 + player.x) < 0.10 then
                RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                    t = 0, big = 0.45 }
            end
            if math.abs(player.vx) > 1 and math.abs(player.vx) < 13 then
                player.vx = player.vx * 1.05
            end
        end
    end
    for i = #RT.ripples, 1, -1 do
        local rp = RT.ripples[i]
        rp.t = rp.t + 1
        if rp.t > 55 then table.remove(RT.ripples, i) end
    end
    -- 交互点
    if RT.bamboo then
        bambooBudUpdate()
        for i = #RT.petals, 1, -1 do
            local pt = RT.petals[i]
            pt.age = pt.age + 1
            pt.x = pt.x + pt.vx + math.sin(pt.age * 0.08 + pt.ph) * 0.5
            pt.y = pt.y + pt.vy
            pt.vy = math.min(pt.vy + 0.022, 1.0)
            pt.rot = pt.rot + pt.vr
            if pt.age > pt.life then table.remove(RT.petals, i) end
        end
        return
    end
    RT.plumDone = 0
    for _, ip in ipairs(RT.ipoints) do
        if ip.kind == "plum" and ip.trig then RT.plumDone = RT.plumDone + 1 end
        if ip.kind == "gust" then
            -- 风袂:可重复触发,刷新冲刺+上推
            if ip.arm > 0 then ip.arm = ip.arm - 1 end
            ip.burst = ip.burst + 1
            local dx, dy = player.x - ip.x, player.y - ip.y
            -- 站定不触发:需在空中或有明确移动意图,避免落竿后被反复弹起
            local moving = (not player.isGrounded) or math.abs(player.vx) > 1.5 or player.vy < -1
            if ip.arm <= 0 and moving and dx * dx + dy * dy < 80 * 80 then
                ip.arm = 160
                ip.burst = 0
                player.canDash = true
                if player.vy > -13 then player.vy = -13 end
                for k = 1, 14 do
                    RT.petals[#RT.petals + 1] = { x = ip.x + (hash01(k * 3.3) - 0.5) * 46,
                        y = ip.y + (hash01(k * 7.1) - 0.5) * 30,
                        vx = (hash01(k * 5.9) - 0.5) * 3.4, vy = -1.2 - hash01(k * 2.7) * 2.2,
                        rot = hash01(k * 4.3) * 6.28, vr = (hash01(k * 8.3) - 0.5) * 0.2,
                        life = 60 + k * 3, age = 0, ph = k * 1.7, col = { 56, 78, 50 } }
                end
            end
        elseif ip.kind == "key" then
            -- 蓄墨苞:触碰实体化鬼阶组(可在余时 <240 帧时续墨)
            local dx, dy = player.x - ip.x, player.y - ip.y
            if ip.grp and dx * dx + dy * dy < 72 * 72 and ip.grp.timer < 240 then
                ip.grp.timer = 300
                ip.ring = 0
                ip.bloomT = 0.01
                for k = 1, 12 do
                    RT.petals[#RT.petals + 1] = { x = ip.x, y = ip.y,
                        vx = (hash01(k * 6.1) - 0.5) * 3.0, vy = -0.6 - hash01(k * 3.7) * 1.6,
                        rot = hash01(k * 2.9) * 6.28, vr = (hash01(k * 7.7) - 0.5) * 0.18,
                        life = 70 + k * 3, age = 0, ph = k * 2.1, col = { 40, 38, 34 } }
                end
            end
            if ip.ring then ip.ring = ip.ring + 1 end
            if ip.bloomT > 0 and ip.bloomT < 1 then ip.bloomT = math.min(1, ip.bloomT + 0.05) end
        elseif not ip.trig then
            local dx, dy = player.x - ip.x, player.y - ip.y
            if dx * dx + dy * dy < 64 * 64 then
                ip.trig = true
                ip.ring = 0
                for mi, m in ipairs(ip.members) do
                    m.delay = (mi - 1) * 6 + math.floor(hash01(mi * 7.7) * 5)
                end
            end
        else
            if ip.ring then ip.ring = ip.ring + 1 end
            for _, m in ipairs(ip.members) do
                if m.delay > 0 then
                    m.delay = m.delay - 1
                elseif m.t < 1 then
                    m.t = math.min(1, m.t + 0.055)
                    if ip.kind == "plum" and m.t > 0.12 and m.t < 0.18 then
                        for _ = 1, 4 do
                            TRACE_RT.petals[#TRACE_RT.petals + 1] = {
                                x = m.x + (hash01(elapsed * 91 + m.x) - 0.5) * 28,
                                y = m.y + (hash01(elapsed * 47 + m.y) - 0.5) * 20,
                                vx = (hash01(m.x + elapsed) - 0.5) * 1.4,
                                vy = -0.5 - hash01(m.y + elapsed * 3) * 0.8,
                                rot = hash01(m.x * 3) * 6.28, vr = (hash01(m.y * 5) - 0.5) * 0.12,
                                life = 110 + math.floor(hash01(m.x + m.y) * 70), age = 0,
                                ph = hash01(m.x) * 6.28 }
                        end
                    end
                elseif ip.kind == "plum" and hash01(elapsed * 13 + ip.x) < 0.003 then
                    TRACE_RT.petals[#TRACE_RT.petals + 1] = { x = m.x, y = m.y, vx = 0.2, vy = 0.2,
                        rot = hash01(m.x) * 6.28, vr = 0.05, life = 140, age = 0, ph = hash01(m.y) * 6.28 }
                end
            end
        end
    end
    for i = #RT.petals, 1, -1 do
        local pt = RT.petals[i]
        pt.age = pt.age + 1
        pt.x = pt.x + pt.vx + math.sin(pt.age * 0.08 + pt.ph) * 0.5
        pt.y = pt.y + pt.vy
        pt.vy = math.min(pt.vy + 0.022, 1.0)
        pt.rot = pt.rot + pt.vr
        if pt.age > pt.life then table.remove(RT.petals, i) end
    end
end

TRACE_PETAL_RED = { 198, 46, 66 }

function traceDrawGust(ip)
    local ready = ip.arm <= 0
    local grow = ready and 1 or clamp((160 - ip.arm) / 160, 0.25, 1)
    local sway = math.sin(elapsed * 1.8 + ip.x * 0.02) * 0.12
    -- 竹梢叶簇(触发后凋落重生)
    for k = 0, 4 do
        local a = -1.5708 + (k - 2) * 0.42 + sway + (ready and 0 or 0.3)
        local ln = (34 + hash01(ip.x + k * 13) * 20) * grow
        nvgSave(vg)
        nvgTranslate(vg, ip.x, ip.y)
        nvgRotate(vg, a)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, -ln * 0.5, 4.6, ln * 0.5)
        nvgFillColor(vg, rgba(48, 66, 44, ready and 235 or 150))
        nvgFill(vg)
        nvgRestore(vg)
    end
    -- 就绪时的上升风纹
    if ready then
        for k = 0, 2 do
            local t = (elapsed * 0.7 + k * 0.33) % 1
            nvgStrokeColor(vg, rgba(96, 104, 92, 120 * (1 - t)))
            nvgStrokeWidth(vg, 2.2)
            nvgBeginPath(vg)
            nvgArc(vg, ip.x, ip.y - 14 - t * 64, 16 + t * 10, math.pi * 1.15, math.pi * 1.85, NVG_CW)
            nvgStroke(vg)
        end
    end
    if ip.burst < 26 then
        local t = ip.burst / 26
        nvgStrokeColor(vg, rgba(70, 90, 64, 200 * (1 - t)))
        nvgStrokeWidth(vg, 3 * (1 - t) + 0.6)
        nvgBeginPath(vg)
        nvgCircle(vg, ip.x, ip.y, 14 + t * 64)
        nvgStroke(vg)
    end
    -- 触发后的上升气流柱:让"被托起"读得见
    if ip.burst < 44 then
        local t = ip.burst / 44
        for k = 0, 3 do
            local xx = ip.x + (hash01(ip.x + k * 17.3) - 0.5) * 44
            local len = 36 + hash01(k * 7.9) * 28
            local yy = ip.y - 16 - t * 175 - k * 22
            nvgStrokeColor(vg, rgba(110, 120, 104, 155 * (1 - t)))
            nvgStrokeWidth(vg, 2.6 - k * 0.4)
            nvgBeginPath(vg)
            nvgMoveTo(vg, xx, yy)
            nvgBezierTo(vg, xx + 5, yy - len * 0.4, xx - 5, yy - len * 0.7, xx + 2, yy - len)
            nvgStroke(vg)
        end
    end
end

function traceDrawKeyBud(ip)
    local grp = ip.grp
    local act = grp and grp.timer > 0
    local ph = elapsed * 2.4 + ip.x * 0.01
    -- 触发后的墨瓣绽开
    if ip.bloomT > 0 then
        local sc = 1 - (1 - ip.bloomT) ^ 3
        for k = 0, 4 do
            local a = k * 1.2566 + 0.4
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x + math.cos(a) * 11 * sc, ip.y + math.sin(a) * 11 * sc, 6.5 * sc)
            nvgFillColor(vg, rgba(44, 42, 38, 200))
            nvgFill(vg)
        end
    end
    nvgBeginPath(vg)
    nvgCircle(vg, ip.x, ip.y, act and 10.5 or (9 + math.sin(ph) * 1.5))
    nvgFillColor(vg, rgba(34, 32, 30, act and 245 or 215))
    nvgFill(vg)
    if not act then
        nvgStrokeColor(vg, rgba(70, 66, 62, 56 + 26 * math.sin(ph)))
        nvgStrokeWidth(vg, 2.4)
        nvgBeginPath(vg)
        nvgCircle(vg, ip.x, ip.y, 26 + math.sin(ph) * 4)
        nvgStroke(vg)
    else
        -- 余墨计时弧
        local f = grp.timer / 300
        nvgStrokeColor(vg, rgba(40, 38, 34, 205))
        nvgStrokeWidth(vg, 3)
        nvgBeginPath(vg)
        nvgArc(vg, ip.x, ip.y, 19, -1.5708, -1.5708 + f * 6.2832, NVG_CW)
        nvgStroke(vg)
        -- 墨脉:苞到各鬼阶的流动墨点,标出因果
        for _, poly in ipairs(grp.polys) do
            local bb = poly.bb
            if bb then
                local tx2, ty2 = (bb[1] + bb[3]) * 0.5, bb[2]
                for k = 0, 2 do
                    local t = (elapsed * 0.8 + k * 0.34 + bb[1] * 0.001) % 1
                    local mx2 = ip.x + (tx2 - ip.x) * t
                    local my3 = ip.y + (ty2 - ip.y) * t - math.sin(t * 3.14159) * 46
                    nvgBeginPath(vg)
                    nvgCircle(vg, mx2, my3, 3.2 * (1 - t * 0.5))
                    nvgFillColor(vg, rgba(44, 42, 38, 165 * (1 - t * 0.6) * math.min(f * 4, 1)))
                    nvgFill(vg)
                end
            end
        end
    end
    if ip.ring and ip.ring < 50 then
        local t = ip.ring / 50
        nvgStrokeColor(vg, rgba(60, 56, 52, 200 * (1 - t)))
        nvgStrokeWidth(vg, 3.5 * (1 - t) + 0.6)
        nvgBeginPath(vg)
        nvgCircle(vg, ip.x, ip.y, 16 + t * 70)
        nvgStroke(vg)
    end
end

function traceDrawPlumFlower(x, y, r, t, seed)
    local sc = (1 - (1 - t) ^ 3)
    sc = sc * (1 + 0.35 * math.sin(t * 3.14159) * (1 - t * 0.6))
    local rr = r * sc
    if rr < 0.6 then return end
    local jit = hash01(seed) * 6.28
    for k = 0, 4 do
        local a = jit + k * 1.2566 + math.sin(seed * 3 + k) * 0.12
        nvgBeginPath(vg)
        nvgCircle(vg, x + math.cos(a) * rr * 0.52, y + math.sin(a) * rr * 0.52,
            rr * 0.46 * (0.92 + hash01(seed + k) * 0.16))
        nvgFillColor(vg, rgba(197, 38, 64, 232))
        nvgFill(vg)
    end
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, rr * 0.3)
    nvgFillColor(vg, rgba(140, 18, 40, 240))
    nvgFill(vg)
    if t > 0.72 then
        local fa = (t - 0.72) / 0.28
        for k = 0, 4 do
            local a = jit + k * 1.2566 + 0.6
            nvgBeginPath(vg)
            nvgCircle(vg, x + math.cos(a) * rr * 0.2, y + math.sin(a) * rr * 0.2, rr * 0.07 + 0.7)
            nvgFillColor(vg, rgba(252, 228, 150, 230 * fa))
            nvgFill(vg)
        end
    end
end

function traceDrawOrchid(x, y, t, seed)
    local sc = 1 - (1 - t) ^ 3
    if sc < 0.03 then return end
    for k = 0, 8 do
        local a = -1.5708 + (k / 8 - 0.5) * 2.5 + math.sin(elapsed * 1.6 + seed + k * 1.7) * 0.05 * t
        local ln = (30 + hash01(seed + k * 3) * 42) * sc
        local ex = x + math.cos(a) * ln
        local ey = y + math.sin(a) * ln
        nvgStrokeColor(vg, rgba(64, 94, 60, 235))
        nvgStrokeWidth(vg, 3.6 - (k % 3) * 0.8)
        nvgBeginPath(vg)
        nvgMoveTo(vg, x, y)
        nvgBezierTo(vg, x + math.cos(a) * ln * 0.4, y + math.sin(a) * ln * 0.5 - 5,
            ex - math.cos(a) * ln * 0.08, ey + 3, ex, ey)
        nvgStroke(vg)
    end
    if t > 0.8 then
        local fa = (t - 0.8) / 0.2
        nvgBeginPath(vg)
        nvgCircle(vg, x + 4, y - 40 * sc, 3.2)
        nvgFillColor(vg, rgba(240, 226, 152, 235 * fa))
        nvgFill(vg)
    end
end

function traceDrawMount(z)
    local RT = TRACE_RT
    local v = clamp((RT.vista - 50) / 90, 0, 1)
    v = 1 - (1 - v) ^ 2
    if v <= 0.01 then return end
    local bw = 26 / z * v
    nvgFillColor(vg, rgba(58, 42, 30, 245 * v))
    nvgBeginPath(vg)
    nvgRect(vg, -bw, -bw, worldW + bw * 2, bw)
    nvgRect(vg, -bw, worldH, worldW + bw * 2, bw)
    nvgRect(vg, -bw, 0, bw, worldH)
    nvgRect(vg, worldW, 0, bw, worldH)
    nvgFill(vg)
    nvgStrokeColor(vg, rgba(150, 122, 88, 200 * v))
    nvgStrokeWidth(vg, 2 / z)
    nvgBeginPath(vg)
    nvgRect(vg, 3 / z, 3 / z, worldW - 6 / z, worldH - 6 / z)
    nvgStroke(vg)
    -- 题跋 + 印章(画心右上)
    local k = clamp(worldH / 1400, 0.6, 1.6)
    nvgSave(vg)
    nvgTranslate(vg, worldW - 240 * k, worldH * 0.12)
    nvgScale(vg, k, k)
    for c2 = 0, 2 do
        local cx2 = c2 * 24
        for r2 = 0, 9 - c2 * 2 do
            local seed = c2 * 31 + r2 * 7
            nvgBeginPath(vg)
            nvgRect(vg, cx2 - 6, r2 * 22, 12 * (0.5 + hash01(seed) * 0.6), 3.2)
            nvgFillColor(vg, rgba(74, 70, 64, 130 * v))
            nvgFill(vg)
        end
    end
    -- 拾得题字成行(漏拾的字留空框)
    for i, ch in ipairs(RT.chars) do
        local cy3 = (i - 1) * 58
        if ch.got then
            drawText(-86, cy3 - 4, 46, rgba(56, 50, 44, 235 * v), ch.ch)
        else
            nvgStrokeColor(vg, rgba(120, 112, 102, 90 * v))
            nvgStrokeWidth(vg, 1.6)
            nvgBeginPath(vg)
            nvgRect(vg, -84, cy3, 40, 40)
            nvgStroke(vg)
        end
    end
    local sv = clamp((RT.vista - 150) / 26, 0, 1)
    if sv > 0 then
        local pop = 1 + (1 - sv) * 0.7
        nvgSave(vg)
        nvgTranslate(vg, 12, 270)
        nvgRotate(vg, -0.05)
        nvgScale(vg, pop, pop)
        nvgBeginPath(vg)
        nvgRect(vg, -25, -25, 50, 50)
        nvgFillColor(vg, rgba(186, 48, 40, 235 * sv))
        nvgFill(vg)
        nvgFillColor(vg, rgba(242, 236, 224, 230 * sv))
        for gx2 = 0, 1 do
            for gy2 = 0, 1 do
                nvgBeginPath(vg)
                nvgRect(vg, -18 + gx2 * 21, -18 + gy2 * 21, 14, 14)
                nvgFill(vg)
            end
        end
        nvgRestore(vg)
    end
    local sv2 = clamp((RT.vista - 185) / 26, 0, 1)
    if sv2 > 0 then
        local pop = 1 + (1 - sv2) * 0.7
        nvgSave(vg)
        nvgTranslate(vg, -42, 352)
        nvgScale(vg, pop, pop)
        nvgStrokeColor(vg, rgba(186, 48, 40, 230 * sv2))
        nvgStrokeWidth(vg, 3.4)
        nvgBeginPath(vg)
        nvgRect(vg, -14, -44, 28, 88)
        nvgStroke(vg)
        nvgFillColor(vg, rgba(186, 48, 40, 215 * sv2))
        for r2 = 0, 3 do
            nvgBeginPath(vg)
            nvgRect(vg, -7, -35 + r2 * 20, 14, 9)
            nvgFill(vg)
        end
        nvgRestore(vg)
    end
    nvgRestore(vg)
end

function drawTraceWorld()
    local RT = TRACE_RT
    if RT.bamboo then
        drawBambooScroll()
        return
    end
    local def = RT.def
    if not def then return end
    nvgSave(vg)
    nvgTranslate(vg, cameraX, cameraY)   -- 抵消外层相机
    local z = RT.zoom or 1
    local cx = RT.camCx or (cameraX + DESIGN_W / 2)
    local cy = RT.camCy or (cameraY + DESIGN_H / 2)
    if RT.goalDone then
        local fitz = math.min(DESIGN_W / (worldW + 80), DESIGN_H / (worldH + 80)) * 0.96
        local tt = math.min(RT.vista / 170, 1)
        tt = 1 - (1 - tt) ^ 3
        z = z + (fitz - z) * tt
        cx = cx + (worldW / 2 - cx) * tt
        cy = cy + (worldH / 2 - cy) * tt
    end
    nvgTranslate(vg, DESIGN_W / 2, DESIGN_H / 2)
    nvgScale(vg, z, z)
    nvgTranslate(vg, -cx, -cy)
    local halfW = DESIGN_W / (2 * z) + 80
    local halfH = DESIGN_H / (2 * z) + 80
    -- 底色
    nvgBeginPath(vg)
    nvgRect(vg, cx - halfW, cy - halfH, halfW * 2, halfH * 2)
    nvgFillColor(vg, rgba(def.base[1], def.base[2], def.base[3], 255))
    nvgFill(vg)
    -- 分层视差
    for _, lay in ipairs(def.layers) do
        if lay.hidden ~= 1 then
            local tox = (cx - def.refx) * (1 - lay.par)
            local toy = (cy - def.refy) * (1 - lay.par) * 0.5
            nvgSave(vg)
            nvgTranslate(vg, tox, toy)
            nvgFillColor(vg, rgba(lay.color[1], lay.color[2], lay.color[3], 255))
            local vx1, vx2 = cx - halfW - tox, cx + halfW - tox
            local vy1, vy2 = cy - halfH - toy, cy + halfH - toy
            for pi, fp in ipairs(lay.polys) do
                local bb = lay.bb[pi]
                if bb[3] > vx1 and bb[1] < vx2 and bb[4] > vy1 and bb[2] < vy2 then
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, fp[1], fp[2])
                    for k = 3, #fp - 1, 2 do nvgLineTo(vg, fp[k], fp[k + 1]) end
                    nvgClosePath(vg)
                    if lay.par >= 0.99 then
                        nvgStrokeColor(vg, rgba(lay.color[1], lay.color[2], lay.color[3], 42))
                        nvgStrokeWidth(vg, 9)
                        nvgStroke(vg)
                    end
                    nvgFill(vg)
                end
            end
            nvgRestore(vg)
        end
    end
    -- 鬼阶虚影:未实体化时罩宣纸色淡化 + 呼吸墨边;余时将尽时闪烁警示
    for _, grp in ipairs(RT.ghostGrps) do
        local wash
        if grp.timer <= 0 then
            wash = 205
        elseif grp.timer < 80 then
            wash = (math.floor(grp.timer / 7) % 2 == 0) and 150 or 0
        else
            wash = 0
        end
        for _, poly in ipairs(grp.polys) do
            nvgBeginPath(vg)
            nvgMoveTo(vg, poly[1][1], poly[1][2])
            for k = 2, #poly do nvgLineTo(vg, poly[k][1], poly[k][2]) end
            nvgClosePath(vg)
            if wash > 0 then
                nvgFillColor(vg, rgba(def.base[1], def.base[2], def.base[3], wash))
                nvgFill(vg)
            end
            if grp.timer <= 0 then
                nvgStrokeColor(vg, rgba(64, 60, 56, 92 + 36 * math.sin(elapsed * 2.6 + poly[1][1] * 0.01)))
                nvgStrokeWidth(vg, 2.2)
                nvgStroke(vg)
            else
                -- 墨衣:实体期描边浓度=剩余时间,台上读秒
                local f = grp.timer / 300
                nvgStrokeColor(vg, rgba(22, 20, 18, 60 + 150 * f))
                nvgStrokeWidth(vg, 2 + 4 * f)
                nvgStroke(vg)
            end
        end
    end
    -- 墨池涟漪
    for _, rp in ipairs(RT.ripples) do
        local t = rp.t / 55
        local a = (1 - t) * 150 * math.min(rp.big, 1)
        for k = 0, 1 do
            local rr = (10 + t * 56) * rp.big * (1 - k * 0.4)
            nvgStrokeColor(vg, rgba(38, 36, 33, a * (1 - k * 0.35)))
            nvgStrokeWidth(vg, 2.6 - k)
            nvgBeginPath(vg)
            nvgEllipse(vg, rp.x, rp.y, rr, rr * 0.32)
            nvgStroke(vg)
        end
    end
    -- 苔点(逃生路暗示:斜点上行,水墨皴法里的苔)
    if RT.design and RT.design.hints then
        for hi, hp in ipairs(RT.design.hints) do
            local wob = math.sin(elapsed * 1.4 + hi * 2.1) * 1.5
            nvgSave(vg)
            nvgTranslate(vg, hp.x, hp.y + wob)
            nvgRotate(vg, -0.5)
            nvgBeginPath(vg)
            nvgEllipse(vg, 0, 0, 7.5, 3)
            nvgFillColor(vg, rgba(52, 60, 48, 170))
            nvgFill(vg)
            nvgRestore(vg)
        end
    end
    -- 拾字
    for _, ch in ipairs(RT.chars) do
        if not ch.got then
            local bob = math.sin(elapsed * 2 + ch.x * 0.013) * 5
            nvgStrokeColor(vg, rgba(170, 138, 60, 70 + 30 * math.sin(elapsed * 2.4 + ch.x)))
            nvgStrokeWidth(vg, 2)
            nvgBeginPath(vg)
            nvgCircle(vg, ch.x, ch.y + bob, 30)
            nvgStroke(vg)
            drawText(ch.x - 17, ch.y + bob - 19, 34, rgba(50, 46, 42, 230), ch.ch)
        elseif ch.fade < 1 then
            drawText(ch.x - 17, ch.y - 19 - ch.fade * 46, 34,
                rgba(150, 120, 52, 220 * (1 - ch.fade)), ch.ch)
        end
    end
    -- 交互点 / 花
    for _, ip in ipairs(RT.ipoints) do
        if ip.kind == "gust" then
            traceDrawGust(ip)
        elseif ip.kind == "key" then
            traceDrawKeyBud(ip)
        elseif not ip.trig then
            local ph = elapsed * 2.2 + ip.x * 0.01
            nvgStrokeColor(vg, rgba(70, 66, 62, 56 + 26 * math.sin(ph)))
            nvgStrokeWidth(vg, 2.4)
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x, ip.y, 26 + math.sin(ph) * 4)
            nvgStroke(vg)
            for _, m in ipairs(ip.members) do
                nvgBeginPath(vg)
                nvgCircle(vg, m.x, m.y, ip.kind == "plum" and 4.2 or 3.4)
                nvgFillColor(vg, ip.kind == "plum" and rgba(132, 22, 44, 235) or rgba(60, 88, 56, 235))
                nvgFill(vg)
            end
        else
            if ip.ring and ip.ring < 50 then
                local t = ip.ring / 50
                nvgStrokeColor(vg, rgba(60, 56, 52, 200 * (1 - t)))
                nvgStrokeWidth(vg, 3.5 * (1 - t) + 0.6)
                nvgBeginPath(vg)
                nvgCircle(vg, ip.x, ip.y, 16 + t * 70)
                nvgStroke(vg)
            end
            for mi, m in ipairs(ip.members) do
                if ip.kind == "plum" then
                    if m.t > 0 then
                        traceDrawPlumFlower(m.x, m.y, m.r, m.t, mi * 13.7 + ip.x)
                    else
                        nvgBeginPath(vg)
                        nvgCircle(vg, m.x, m.y, 4.2)
                        nvgFillColor(vg, rgba(132, 22, 44, 235))
                        nvgFill(vg)
                    end
                elseif ip.kind == "sprout" then
                    traceDrawOrchid(m.x, m.y, m.t, ip.x * 0.013)
                elseif ip.kind == "orchid" then
                    -- 描摹兰叶生长:用缩放重绘该层多边形
                    if m.lay and m.t > 0.01 then
                        local sc = 1 - (1 - m.t) ^ 3
                        local bb = m.lay.bb[m.pi]
                        local bx, by = (bb[1] + bb[3]) * 0.5, bb[4]
                        nvgSave(vg)
                        nvgTranslate(vg, bx, by)
                        nvgRotate(vg, math.sin(elapsed * 1.5 + bx * 0.013) * 0.06 * m.t)
                        nvgScale(vg, sc, sc)
                        nvgTranslate(vg, -bx, -by)
                        local fp = m.lay.polys[m.pi]
                        nvgBeginPath(vg)
                        nvgMoveTo(vg, fp[1], fp[2])
                        for k = 3, #fp - 1, 2 do nvgLineTo(vg, fp[k], fp[k + 1]) end
                        nvgClosePath(vg)
                        nvgFillColor(vg, rgba(m.lay.color[1], m.lay.color[2], m.lay.color[3], 255))
                        nvgFill(vg)
                        nvgRestore(vg)
                    end
                end
            end
        end
    end
    -- 花瓣
    for _, pt in ipairs(RT.petals) do
        local a = 230 * (1 - pt.age / pt.life)
        local pc = pt.col or TRACE_PETAL_RED
        nvgSave(vg)
        nvgTranslate(vg, pt.x, pt.y)
        nvgRotate(vg, pt.rot)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, 0, 5.2, 2.8)
        nvgFillColor(vg, rgba(pc[1], pc[2], pc[3], a))
        nvgFill(vg)
        nvgRestore(vg)
    end
    -- 终点门(梅苞未集满时灰锁,苞计点亮进度)
    local g = def.conf.goal
    local locked = RT.plumTotal > 0 and RT.plumDone < RT.plumTotal
    -- 玩家靠近锁定门:苞计脉动放大 + 灰涟漪,提示去寻梅
    local nearLock = 0
    if locked then
        local ddx, ddy = player.x - g[1], player.y - g[2]
        if ddx * ddx + ddy * ddy < 230 * 230 then
            RT.gatePulse = (RT.gatePulse or 0) + 1
            nearLock = 1
            local t = (RT.gatePulse % 70) / 70
            nvgStrokeColor(vg, rgba(110, 104, 96, 130 * (1 - t)))
            nvgStrokeWidth(vg, 2.6 * (1 - t) + 0.5)
            nvgBeginPath(vg)
            nvgCircle(vg, g[1], g[2] - 40, 40 + t * 90)
            nvgStroke(vg)
        else
            RT.gatePulse = 0
        end
    end
    if locked then
        nvgStrokeColor(vg, rgba(122, 116, 108, 165))
    else
        nvgStrokeColor(vg, rgba(150, 60, 50, 190 + 40 * math.sin(elapsed * 3)))
    end
    nvgStrokeWidth(vg, 5)
    nvgBeginPath(vg)
    nvgArc(vg, g[1], g[2] - 50, 80, math.pi, 0, NVG_CW)
    nvgStroke(vg)
    if RT.plumTotal > 0 then
        for i = 1, RT.plumTotal do
            local pulse = (nearLock == 1 and i > RT.plumDone)
                and (1 + 0.45 * math.sin(elapsed * 5 + i * 1.4)) or 1
            local bx = g[1] + (i - (RT.plumTotal + 1) * 0.5) * 30
            local by = g[2] - 150
            nvgBeginPath(vg)
            nvgCircle(vg, bx, by, 7 * pulse)
            if i <= RT.plumDone then
                nvgFillColor(vg, rgba(197, 38, 64, 235))
                nvgFill(vg)
            else
                nvgStrokeColor(vg, rgba(120, 112, 104, 200))
                nvgStrokeWidth(vg, 2.2)
                nvgStroke(vg)
            end
        end
    end
    nvgStrokeColor(vg, rgba(90, 84, 78, 235))
    nvgStrokeWidth(vg, 4.5)
    nvgBeginPath(vg)
    nvgCircle(vg, g[1], g[2] - 24, 33)
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgMoveTo(vg, g[1] - 22, g[2] - 13)
    nvgBezierTo(vg, g[1] - 3, g[2] - 37, g[1] + 9, g[2] - 23, g[1] + 24, g[2] - 37)
    nvgStroke(vg)
    -- 存档灯
    for i, cp in ipairs(RT.cps) do
        nvgStrokeColor(vg, rgba(40, 36, 33, 235))
        nvgStrokeWidth(vg, 5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cp[1], cp[2] + 12)
        nvgLineTo(vg, cp[1], cp[2] - 52)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgCircle(vg, cp[1] + 16, cp[2] - 46, RT.cpReached[i] and 7 or 5)
        nvgFillColor(vg, RT.cpReached[i] and rgba(235, 180, 90, 230) or rgba(160, 152, 140, 180))
        nvgFill(vg)
    end
    -- 拖尾与角色(原生)
    drawParticles()
    drawPlayer()
    -- 终幕装裱
    if RT.goalDone then traceDrawMount(z) end
    nvgRestore(vg)
end

-- ============================================================================
-- END scripts/src/85_trace_levels.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/86_trace_data.lua
-- ============================================================================
-- 描摹关数据(tmp/emit_bundle_trace.py 生成,勿手改)
TRACE_DEFS = {}
TD = { base={243,239,229}, spanx2=2348, spany2=24, frw=1984, frh=864, refx=992, refy=444, layers={},
  conf={ spawn={120,732}, cps={{120,732}, {1480,472}, {3000,652}}, goal={4160,592}, kill=1012 } }
TD.layers[1] = { color={229,225,214}, ocol={197,194,190}, par=0.1, coll=0, hidden=0, polys={} }
TP = TD.layers[1].polys
TP[1] = {968,852,978,870,1008,862,1002,850}
TP[2] = {1654,800,1654,864,1666,864,1666,804}
TP[3] = {496,784,494,816,524,822,532,812,532,786}
TP[4] = {666,772,634,808,622,812,624,818,666,802}
TP[5] = {1330,818,1330,830,1364,870,1398,862,1480,862,1480,850,1472,844,1450,844,1432,826,1414,826,1414,816,1424,812,1410,812,1404,800,1406,764,1342,794}
TP[6] = {2132,766,2082,762,2084,788,2068,788,2042,800,2030,790,2014,794,2010,788,2002,798,2026,804,2036,814,2044,806,2076,800,2084,814,2120,816,2132,828,2132,814,2122,808,2124,802,2132,802}
TP[7] = {642,752,626,752,622,786,640,770}
TP[8] = {1696,698,1696,726,1682,734,1682,858,1706,856,1708,864,1740,858,1786,860,1766,838,1766,824,1772,820,1768,808,1744,806,1742,814,1694,810,1694,768,1706,768,1706,698}
TP[9] = {2074,686,2076,738,2104,740,2106,714,2112,712,2112,704,2106,702,2108,688}
TP[10] = {1654,668,1654,754,1666,754,1666,672}
TP[11] = {248,672,232,668,200,676,194,690,144,692,144,674,184,672,184,650,192,646,180,648,122,678,106,718,96,708,74,708,70,720,86,728,82,778,96,778,98,786,92,808,70,822,64,840,46,848,48,862,132,860,236,840,240,862,248,866,254,858,256,778}
TP[12] = {218,642,220,654,252,654,244,642}
TP[13] = {1662,622,1654,624,1654,654,1666,658}
TP[14] = {132,592,94,580,76,586,72,578,34,592,22,610,24,630,10,652,10,662,34,670,78,672,84,678,64,630}
TP[15] = {1682,532,1684,648,1686,634,1694,630,1694,610,1706,608,1706,574,1694,566,1694,538}
TP[16] = {1638,514,1624,520,1624,536,1610,548,1610,866,1638,864,1640,740,1622,738,1622,722,1630,720,1622,706,1622,688,1638,694,1642,688,1638,612,1644,606,1646,528,1638,524}
TP[17] = {690,510,692,530,700,530,702,540,756,544,740,540,740,518,736,524,714,524,712,516,696,522}
TP[18] = {1102,596,1012,596,1002,580,1002,540,1008,538,1012,544,1012,532,1004,530,1012,522,1004,516,1012,512,984,506,980,532,958,534,954,518,964,514,964,524,972,524,970,506,938,506,928,492,900,500,914,510,906,528,908,552,900,558,908,570,896,580,886,580,884,618,878,624,834,626,828,638,778,638,762,612,760,680,768,686,768,734,760,738,762,754,870,704,872,726,904,746,920,746,934,754,932,782,938,792,940,774,950,766,948,748,960,744,956,734,964,728,962,718,984,682,1026,682,1028,674,1046,680,1062,670,1080,676,1084,686,1086,664,1098,674,1104,658}
TP[19] = {728,470,722,472,722,492,714,494,718,506,732,494,728,484,734,480}
TP[20] = {2218,452,2196,500,2196,588,2206,614,2218,608}
TP[21] = {1032,432,1034,506,1048,500,1044,528,1056,526,1050,542,1034,548,1032,566,1104,566,1102,526,1094,522,1094,482,1056,482,1050,474,1054,444,1070,448,1062,464,1076,462,1074,430}
TP[22] = {690,400,706,406,710,394,696,392}
TP[23] = {722,390,734,408,754,404,760,414,790,394,772,384,738,384,736,390}
TP[24] = {726,352,748,372,752,362,744,350}
TP[25] = {2218,328,2192,338,2194,472,2210,442,2206,432,2216,428,2218,408,2208,408,2218,368}
TP[26] = {1440,282,1400,282,1400,302,1390,314,1330,316,1330,360,1338,364,1338,380,1330,384,1330,484,1338,492,1330,518,1330,572,1338,578,1338,596,1330,600,1330,656,1338,664,1330,680,1480,678,1484,664,1496,660,1496,614,1484,596,1484,486,1480,500,1424,556,1374,514,1394,488,1392,480,1410,462,1394,442,1402,430,1394,418,1396,406,1410,394,1428,390,1396,362,1388,328,1410,306,1464,302,1466,298,1444,290}
TP[27] = {588,264,508,264,506,324,494,334,492,356,484,358,486,390,492,396,484,452,492,456,494,468,492,508,486,510,484,560,492,564,484,570,484,598,492,604,492,626,502,604,502,584,520,564,526,486,574,330,576,298}
TP[28] = {246,256,230,258,226,270,246,268}
TP[29] = {1334,252,1338,270,1332,284,1370,284,1370,254}
TP[30] = {1988,226,1986,238,1996,254,1966,262,1968,246,1962,248,1958,280,1974,330,1988,346,1984,360,2030,534,2040,540,2036,556,2058,556,2060,546,2068,546,2068,570,2060,586,2064,606,2052,606,2052,618,2062,622,2064,676,2082,674,2086,630,2096,632,2094,674,2106,674,2116,668,2106,638,2118,624,2122,584,2116,244,2072,246,2070,264,2086,268,2086,258,2094,252,2106,252,2104,284,2056,286,2050,278,2050,248,2002,242}
TP[31] = {566,218,560,214,558,226,546,228,534,240,544,240,552,230,558,232,554,240,562,238,568,230}
TP[32] = {2040,186,2026,190,2026,198,2008,212,2008,226,2032,224}
TP[33] = {16,58,0,66,0,138,10,150,6,186,0,190,6,260,68,258,82,266,94,286,112,284,116,270,136,250,158,244,154,228,144,228,142,240,134,238,132,210,146,206,150,198,136,194,130,180,142,162,166,162,166,144,158,140,166,134,166,114,30,114,20,104,22,60}
TP[34] = {46,56,46,82,60,82,64,90,60,58}
TP[35] = {2002,36,1970,76,2016,70}
TP[36] = {1650,20,1648,26,1624,30,1624,358,1640,362,1640,396,1618,396,1610,308,1610,464,1618,438,1626,450,1638,450,1640,458,1654,462,1654,510,1666,522,1666,42,1652,44}
TP[37] = {220,18,210,20,208,28,190,40,174,40,168,34,160,48,138,48,126,74,114,78,112,90,118,90,120,80,144,80,152,94,166,94,166,74,174,62,190,58,196,66,198,58,220,58}
TP[38] = {1682,16,1682,372,1694,370,1704,386,1702,398,1696,398,1694,390,1682,392,1682,480,1696,480,1696,492,1682,496,1682,516,1694,502,1696,528,1706,532,1706,288,1716,286,1716,364,1718,354,1736,350,1740,338,1734,330,1738,314,1722,310,1720,304,1746,292,1746,352,1754,358,1744,362,1750,366,1744,386,1732,372,1716,372,1716,410,1730,410,1732,426,1746,430,1748,594,1784,590,1796,564,1820,554,1892,616,1910,604,1944,634,1948,646,1964,650,1952,694,1924,702,1880,688,1866,670,1830,650,1782,656,1780,650,1786,646,1764,650,1764,660,1746,668,1750,694,1742,730,1778,732,1776,722,1796,704,1826,704,1862,734,1896,750,1908,746,1926,764,1922,776,1884,756,1866,756,1886,776,1918,792,1922,804,1940,806,1954,824,1970,818,1994,826,1950,796,1956,782,1970,786,1964,754,1972,732,1984,604,1936,396,1924,386,1924,352,1888,220,1874,228,1864,212,1848,210,1854,194,1836,190,1834,176,1826,174,1824,152,1836,140,1832,134,1824,134,1772,172,1758,174,1790,124,1842,86,1842,72,1794,62,1796,56,1830,50,1826,34,1800,40,1786,34,1774,18,1754,34,1748,48,1714,50,1710,28,1694,16}
TP[39] = {1546,20,1546,176,1562,178,1560,192,1546,192,1546,200,1562,212,1560,220,1546,220,1546,288,1562,290,1562,324,1546,322,1546,494,1560,482,1560,432,1574,430,1574,418,1580,416,1588,432,1588,522,1576,524,1574,504,1562,498,1562,588,1554,590,1546,582,1546,664,1562,672,1562,710,1576,718,1576,758,1570,764,1576,782,1588,784,1588,856,1576,858,1576,868,1596,864,1596,582,1586,580,1586,540,1596,534,1596,164,1586,162,1586,112,1596,106,1600,24,1590,28,1588,16}
TP[40] = {1338,12,1338,20,1330,22,1328,104,1334,106,1330,120,1338,126,1328,130,1328,168,1330,152,1340,144,1386,144,1388,102,1374,102,1374,110,1378,104,1384,106,1384,116,1368,118,1364,94,1396,90,1400,144,1470,144,1476,150,1476,166,1486,174,1484,182,1470,188,1442,188,1440,168,1454,166,1456,172,1450,176,1460,176,1460,158,1352,160,1352,190,1342,188,1342,194,1350,196,1352,228,1392,230,1400,238,1400,258,1410,258,1412,266,1416,258,1424,258,1426,266,1432,258,1480,258,1480,242,1496,242,1496,234,1488,232,1492,220,1486,218,1484,240,1468,242,1462,234,1470,224,1464,218,1464,202,1482,194,1492,198,1496,170,1476,162,1480,126,1472,124,1472,110,1480,104,1480,80,1452,84,1454,72,1436,66,1440,48,1426,50,1404,34,1406,12}
TP[41] = {484,14,482,64,500,58,514,74,540,82,546,92,554,80,576,80,582,86,588,78,606,80,608,86,620,86,624,78,630,84,636,78,646,82,658,66,690,68,694,56,710,64,706,46,740,54,748,44,758,52,762,68,790,50,802,70,838,86,838,104,832,110,838,124,830,128,838,140,832,144,852,158,866,154,882,168,882,212,870,218,870,226,880,226,882,234,858,242,858,280,888,290,910,288,912,280,920,280,936,292,938,302,964,302,966,292,980,290,1002,320,998,346,984,360,986,378,970,392,992,422,992,446,980,468,960,472,948,486,1004,488,1002,418,1014,404,1020,410,1010,422,1024,414,1024,404,1086,404,1096,412,1102,430,1104,312,1096,296,1104,270,1104,206,1094,198,1096,154,1104,148,1104,72,1096,64,1104,28,1066,28,1042,12,942,12,942,22,926,28,918,26,918,14,924,12,902,12,896,30,866,20,784,28,772,12,770,20,760,24,712,16,650,16,646,12}
TP[42] = {240,12,238,76,228,82,198,82,196,116,206,124,230,124,252,142,252,58,244,48,252,12}
TD.layers[2] = { color={212,208,197}, ocol={181,179,174}, par=0.18, coll=0, hidden=0, polys={} }
TP = TD.layers[2].polys
TP[1] = {1484,866,1428,862,1360,872,1480,876}
TP[2] = {978,874,1006,876,1034,868,1050,874,1088,874,1092,868,1084,870,1072,862,1044,868,1010,862}
TP[3] = {1712,864,1712,876,2068,874,2036,872,2022,862,1998,866,1928,860,1888,868,1886,858,1852,858,1846,874,1818,874,1816,864,1794,864,1790,874,1768,874,1766,864}
TP[4] = {1652,858,1654,872,1688,872,1686,866,1660,870}
TP[5] = {1780,786,1772,786,1774,844,1784,816}
TP[6] = {1888,770,1888,814,1930,812,1924,800,1912,796,1914,786,1900,782,1900,768}
TP[7] = {874,728,872,806,846,818,840,840,944,842,968,850,970,836,950,834,938,812,932,754,904,748}
TP[8] = {484,726,486,754,506,754,506,730}
TP[9] = {628,724,580,724,582,778,570,786,534,786,534,812,528,824,544,828,546,822,556,822,558,828,588,830,608,824,610,814,622,820,620,810,634,806,642,794,632,788,636,778,628,788,620,786,620,764,626,760,624,748,614,746,612,732,628,732}
TP[10] = {1634,710,1626,714,1626,736,1618,738,1614,748,1626,754,1626,762,1614,760,1610,768,1600,770,1600,856,1624,856,1626,840,1660,844,1670,826,1670,784,1656,784,1644,764,1650,756,1650,718}
TP[11] = {1552,700,1552,788,1560,792,1564,714,1560,702}
TP[12] = {6,664,8,672,20,674,12,768,14,818,28,846,42,856,46,874,166,874,188,866,212,874,222,852,212,844,132,862,46,862,44,848,60,840,68,822,90,808,96,780,80,778,84,728,70,722,68,712,74,706,96,706,108,714,118,688,114,684,90,692,78,674,34,672}
TP[13] = {1490,662,1490,676,1510,680,1510,662}
TP[14] = {1892,654,1888,702,1902,706,1902,734,1924,738,1936,694,1932,670,1902,670,1900,654}
TP[15] = {1790,634,1782,636,1780,714,1788,712}
TP[16] = {2274,632,2272,674,2252,678,2256,704,2260,708,2262,684,2294,684,2302,712,2296,714,2296,738,2266,742,2268,756,2316,762,2318,742,2308,722,2316,720,2308,670,2280,674,2282,632}
TP[17] = {2170,630,2154,766,2168,764,2172,780,2178,768,2186,768,2200,782,2202,770,2214,768,2194,700,2192,676,2174,654}
TP[18] = {1660,616,1654,638,1666,662,1670,616}
TP[19] = {254,614,186,648,186,672,144,676,144,690,190,690,200,674,232,666,254,674}
TP[20] = {2406,610,2398,610,2396,624,2384,632,2392,642,2400,640,2406,628}
TP[21] = {2254,550,2246,558,2232,558,2232,566,2226,568,2232,572,2236,610,2250,608}
TP[22] = {1490,550,1490,582,1510,608,1510,550}
TP[23] = {1784,538,1786,604,1792,586,1808,596,1808,604,1816,604,1816,582,1790,570,1790,542}
TP[24] = {116,534,104,532,102,544,72,556,52,582,66,576,76,584,88,578,104,582,104,564,116,562}
TP[25] = {250,528,244,518,190,520,188,546,180,552,148,552,146,576,140,586,130,588,150,586,240,540}
TP[26] = {166,534,164,516,108,518,128,520,134,530}
TP[27] = {1792,498,1792,524,1798,526,1792,534,1800,536,1804,510}
TP[28] = {1652,496,1652,522,1670,522,1670,496}
TP[29] = {22,490,14,526,26,534,34,520,28,490}
TP[30] = {132,472,110,474,110,484,124,486}
TP[31] = {242,460,234,456,234,472,222,476,218,488,240,484}
TP[32] = {1708,380,1702,380,1696,414,1702,418,1710,400}
TP[33] = {2378,340,2372,354,2374,398}
TP[34] = {1670,284,1662,312,1652,322,1652,412,1660,406,1660,374,1666,370,1660,350,1670,342,1664,334}
TP[35] = {2306,272,2308,360,2314,362,2312,272}
TP[36] = {28,264,38,284,34,294,52,308,62,308,74,294,100,294,80,266,68,260}
TP[37] = {2090,248,2086,252,2118,356}
TP[38] = {2380,244,2378,308,2388,308,2394,300,2382,290}
TP[39] = {1896,238,1888,550,1902,552,1902,592,1910,600,1932,594,1930,522,1936,452,1932,428,1918,426,1918,412,1900,410,1900,372,1920,370,1928,380,1918,402,1932,416,1932,360,1942,356,1934,352,1934,294,1910,306,1928,314,1918,322,1928,334,1926,350,1900,354}
TP[40] = {1496,234,1490,234,1486,296,1452,308,1412,308,1392,326,1398,362,1404,362,1424,386,1424,392,1410,396,1394,416,1402,428,1396,440,1404,458,1414,460,1430,444,1442,444,1456,428,1460,398,1488,402,1488,362,1494,360,1498,366,1510,358,1510,268,1502,266,1510,260,1510,246}
TP[41] = {0,234,0,272,8,272,20,260,4,260}
TP[42] = {1482,172,1482,202,1502,212,1504,232,1510,232,1510,190,1500,198,1498,182}
TP[43] = {142,164,156,176,160,192,158,244,136,252,118,270,118,284,160,280,162,272,152,272,158,262,186,270,196,260,210,266,212,284,220,282,220,266,248,250,246,228,254,212,240,196,246,188,178,188,162,174,162,164}
TP[44] = {866,156,852,160,848,148,850,168,842,204,822,216,828,230,816,228,816,236,800,248,784,244,784,262,770,274,744,270,726,252,728,262,740,270,742,292,712,298,710,292,694,290,674,270,676,260,694,252,688,236,680,238,678,260,650,258,646,252,646,296,640,302,602,302,596,296,596,280,614,274,618,282,610,288,626,288,626,266,590,264,578,298,576,330,528,486,532,502,520,540,522,564,504,584,492,654,484,660,484,680,488,670,494,672,492,694,500,702,508,692,506,670,552,668,550,644,546,658,536,656,538,632,562,632,568,640,568,680,528,684,526,754,554,754,554,712,564,702,586,702,590,646,620,650,618,668,606,668,604,662,610,658,600,658,600,688,638,698,648,714,648,742,642,750,648,756,664,754,656,734,668,710,666,652,658,648,658,600,668,586,668,548,710,546,700,540,700,532,690,530,692,520,740,522,742,540,758,542,760,576,770,584,762,610,778,638,826,638,834,624,878,622,884,580,906,570,898,558,906,552,904,528,912,510,898,500,924,490,910,480,908,470,920,444,936,438,938,456,954,460,944,468,980,466,990,446,990,422,970,390,984,378,984,360,998,344,1000,320,980,292,966,294,964,304,938,304,934,292,916,280,910,290,894,292,858,282,856,242,882,230,868,226,868,218,882,206,880,168}
TP[45] = {928,146,928,162,932,146,954,146,956,162,942,166,960,166,960,144}
TP[46] = {2378,140,2382,224,2388,214,2388,182}
TP[47] = {0,140,2,188,8,150}
TP[48] = {198,120,196,156,252,154,252,144,246,144,238,130}
TP[49] = {2038,112,2018,130,2024,142,2014,152,2016,174,2024,176,2024,188,2042,194,2036,206,2040,212,2058,214,2054,144}
TP[50] = {1694,102,1692,108,1702,110,1694,158,1680,160,1690,164,1690,186,1696,196,1690,352,1698,364,1708,366,1710,106}
TP[51] = {1482,88,1482,116,1474,118,1474,124,1482,126,1482,160,1508,168,1510,102,1490,102,1488,88}
TP[52] = {510,66,506,74,488,80,484,104,490,106,484,134,488,154,504,168,514,166,504,156,510,146,504,140,506,130,514,128,506,114,524,110,528,104,522,96,536,86,514,76}
TP[53] = {2154,74,2164,126,2152,124,2136,96,2120,108,2110,138,2112,164,2122,180,2142,266,2152,244,2158,246,2156,264,2160,258,2182,254,2172,238,2172,228,2180,224,2190,240,2238,246,2244,284,2292,282,2296,254,2276,258,2274,270,2256,264,2260,244,2302,240,2302,214,2294,210,2292,200,2302,184,2302,134,2276,86,2254,68,2226,60,2224,50,2220,96,2202,72,2188,78,2172,74,2168,80}
TP[54] = {2102,28,2074,32,2074,44,2088,48}
TP[55] = {2302,26,2284,34,2278,46,2290,84,2298,80}
TP[56] = {2214,12,2216,30,2262,60,2244,26,2234,22,2234,30,2228,32,2222,14}
TP[57] = {1816,18,1792,20,1790,12,1776,26,1766,28,1766,44,1770,32,1790,22,1792,46,1784,52,1798,50,1816,36}
TP[58] = {1690,12,1706,30,1706,64,1710,22,1702,12}
TP[59] = {1844,10,1892,22,1900,32,1900,48,1936,46,1940,34,1962,16,1974,32,1988,38,2018,38,2010,22,1978,24,1966,12,1946,12,1940,22}
TP[60] = {1738,10,1738,20,1764,24,1762,10}
TP[61] = {1552,10,1562,12,1564,18,1568,12,1598,12,1600,16,1670,14}
TP[62] = {650,12,712,14,744,22,768,20,768,14,776,12,784,26,866,18,894,30,900,18,898,10}
TD.layers[3] = { color={188,184,175}, ocol={157,153,150}, par=0.32, coll=0, hidden=0, polys={} }
TP = TD.layers[3].polys
TP[1] = {1820,834,1810,848,1800,850,1740,836,1742,852,1736,862,1690,862,1690,878,1736,878,1738,862,1748,868,1748,876,1798,872,1800,858,1820,856}
TP[2] = {774,856,820,860,840,872,960,874,974,866,964,850,944,844,842,844,838,826,828,826,822,834}
TP[3] = {530,826,546,838,544,850,560,850,592,834,558,830,556,824,546,824,544,830}
TP[4] = {2026,786,2024,836,2012,842,2014,870,2022,866}
TP[5] = {1616,780,1606,784,1606,874,1634,874,1636,834,1626,824,1632,794}
TP[6] = {664,756,650,758,634,788,648,786,664,770}
TP[7] = {520,704,516,728,524,730,526,744,526,706}
TP[8] = {1500,684,1498,698,1524,696,1520,680,1508,678}
TP[9] = {4,668,0,838,6,858,0,874,44,874,40,856,24,844,12,818,10,764,18,674}
TP[10] = {106,564,104,578,140,586,146,554,120,554,118,560,138,564,134,576,116,574}
TP[11] = {2646,524,2640,586,2646,566}
TP[12] = {72,452,64,464,68,484,74,474,86,472,72,464}
TP[13] = {14,436,0,446,0,558,14,554,16,544,30,536,14,530,12,516,20,506,20,490,30,488,32,478,20,476,12,460,22,458,20,448,26,446,40,466,40,440}
TP[14] = {1786,428,1792,494,1820,496,1820,436,1812,426}
TP[15] = {2704,400,2698,406,2698,426,2706,442}
TP[16] = {2642,378,2638,514,2644,516}
TP[17] = {1872,364,1866,438,1870,482,1864,484,1864,500,1892,496,1892,550,1874,552,1864,546,1858,562,1862,570,1854,828,1890,836,1890,572,1936,530,1938,502,1970,514,2006,512,2010,522,2012,512,2022,510,2030,538,2064,546,2078,556,2080,544,2070,518,2064,528,2056,526,2054,536,2032,536,2034,492,2046,498,2046,512,2058,512,2046,476,2034,476,2032,462,2002,458,1988,448,1954,450,1932,440,1930,462,1906,488,1892,494,1890,482,1898,478,1890,476,1890,408,1884,408,1886,418,1874,414,1880,380,1890,378,1890,372}
TP[18] = {248,288,240,272,228,276,224,286,216,284,220,290}
TP[19] = {24,264,0,274,0,356,2,348,10,346,8,330,30,324,10,316,12,310,24,308,26,296,36,298,36,284}
TP[20] = {1740,242,1738,290,1724,292,1716,302,1690,302,1690,308,1730,314,1738,310,1744,278}
TP[21] = {2632,198,2632,240,2638,240,2640,198}
TP[22] = {1572,198,1574,440,1582,202}
TP[23] = {150,172,140,172,134,182,156,196,146,210,136,212,138,226,158,220,160,196}
TP[24] = {2638,148,2638,158,2632,160,2634,188,2640,184}
TP[25] = {1852,112,1836,116,1844,122,1842,128,1822,134,1822,152,1836,150,1836,162,1852,158}
TP[26] = {2728,80,2710,102,2704,120,2704,146,2712,148,2718,182,2716,220,2706,228,2712,244,2712,290,2724,302,2734,300,2734,138,2728,136}
TP[27] = {1890,88,1884,88,1878,76,1854,88,1854,106,1888,104}
TP[28] = {506,68,482,68,482,88}
TP[29] = {1902,24,1886,68,1904,48}
TP[30] = {2700,36,2728,26,2726,14,2702,12}
TP[31] = {2632,12,2586,12,2604,58,2610,34,2632,24}
TP[32] = {2298,12,2306,22,2338,20,2354,44,2336,12}
TP[33] = {2216,12,2226,22,2268,20,2272,14}
TP[34] = {2052,10,2056,20,2064,14,2080,16,2080,10}
TP[35] = {2030,10,1994,20,1986,28,1986,38,2018,24}
TP[36] = {1956,10,1938,14,1932,40}
TP[37] = {1532,10,1570,12,1572,22,1596,18,1594,10}
TD.layers[4] = { color={162,160,151}, ocol={138,138,134}, par=0.45, coll=0, hidden=0, polys={} }
TP = TD.layers[4].polys
TP[1] = {738,872,838,874,820,862,772,858}
TP[2] = {1608,838,1608,870,1616,870,1618,844,1616,838}
TP[3] = {2128,768,2124,824,2138,836,2134,768}
TP[4] = {1570,712,1556,720,1552,700,1524,694,1526,700,1538,702,1540,752,1534,780,1526,778,1526,768,1504,764,1502,750,1482,756,1480,742,1454,744,1448,754,1418,758,1410,768,1408,788,1418,786,1410,810,1422,798,1426,820,1448,832,1450,824,1458,830,1498,826,1506,844,1526,842,1556,850,1564,816,1572,812,1574,724,1564,722}
TP[5] = {1102,676,1086,688,1074,678,1064,692,1044,696,1036,692,1040,682,1034,680,1026,686,1004,682,998,690,984,686,986,694,996,692,998,698,970,706,964,744,950,750,948,758,956,766,946,776,954,788,954,796,946,798,946,810,960,814,962,828,968,830,974,822,992,832,998,824,1026,824,1036,836,1036,820,1058,822,1060,814,1074,816,1068,826,1092,828,1102,822,1102,794,1096,790,1102,756}
TP[6] = {3040,670,3032,670,3024,696,3024,726,3034,732,3032,742,3040,734}
TP[7] = {616,650,590,650,590,704,560,712,554,758,522,754,522,730,514,728,514,712,524,698,526,680,564,678,562,636,540,638,540,654,546,654,546,642,556,644,552,672,512,672,512,700,496,708,498,714,510,712,508,724,490,720,488,692,478,696,476,690,470,694,476,714,470,716,474,726,468,730,440,718,414,718,412,724,304,718,282,748,288,758,274,770,268,768,268,690,258,690,258,746,264,758,258,780,258,854,268,852,274,804,294,804,326,784,376,784,386,760,396,754,422,758,440,784,440,794,446,794,466,818,488,816,490,782,574,780,574,734,580,718,632,720,632,734,616,738,644,742,640,706,626,706,624,712,604,706,602,714,596,712,596,656,612,654,614,666}
TP[8] = {1006,548,1006,582,1016,594,1100,594,1098,570,1034,570,1020,578,1012,570,1018,538,1014,548}
TP[9] = {1738,532,1730,532,1726,548,1718,552,1734,558}
TP[10] = {2066,508,2058,514,2062,578}
TP[11] = {1504,504,1506,512,1518,516,1514,528,1530,532,1528,548,1554,542,1554,510,1518,512}
TP[12] = {1762,498,1766,526,1774,530,1774,502}
TP[13] = {1774,460,1768,460,1766,474,1760,476,1762,488,1774,482}
TP[14] = {1006,440,1010,458,1028,450,1028,444}
TP[15] = {1574,354,1568,354,1568,368,1560,378,1554,376,1554,364,1540,370,1524,358,1510,362,1504,420,1522,406,1554,408,1556,420,1572,420}
TP[16] = {488,284,486,324,496,324,504,314,502,284}
TP[17] = {10,312,18,318,38,316,40,322,10,330,8,338,20,330,30,332,22,346,14,344,20,348,18,354,0,348,0,444,24,434,40,438,44,446,50,430,60,424,70,442,66,462,76,468,80,456,90,454,106,470,136,468,130,484,138,488,142,514,168,514,168,534,182,546,188,516,228,516,228,500,238,490,228,492,226,504,218,504,216,496,210,506,186,496,186,482,172,484,172,462,184,458,190,472,210,484,218,484,218,476,228,472,218,464,232,462,234,452,254,462,254,292,246,290,246,304,238,308,236,290,210,288,206,266,198,264,196,270,204,276,202,282,192,282,188,272,158,266,166,270,160,286,144,276,138,292,106,288,106,296,96,304,72,304,64,312,42,312,26,304,24,310}
TP[18] = {2740,232,2740,248,2732,260,2752,332,2754,284,2764,280,2776,296,2780,294,2770,256,2760,256,2748,232}
TP[19] = {1638,210,1626,456,1618,460,1624,490,1620,684,1612,730,1620,728,1622,678,1628,662,1622,636,1626,596,1634,582,1638,526,1630,512,1632,494,1620,478,1634,440}
TP[20] = {1502,210,1480,200,1468,208,1472,218,1476,210,1486,218,1484,234,1472,226,1476,238,1486,240,1484,258,1476,268,1444,266,1440,260,1438,268,1410,270,1410,262,1424,260,1398,260,1396,240,1388,232,1350,232,1344,204,1338,250,1372,250,1374,284,1332,288,1330,312,1392,308,1400,278,1440,278,1452,282,1450,290,1480,292,1458,290,1452,280,1498,278}
TP[21] = {1556,148,1556,170,1572,170,1568,148}
TP[22] = {1776,130,1776,190,1840,190,1830,182,1780,182}
TP[23] = {1370,94,1392,102,1390,146,1360,150,1372,156,1462,154,1468,174,1450,180,1448,170,1442,184,1466,184,1474,174,1470,148,1400,148,1394,92}
TP[24] = {2268,86,2262,92,2268,96,2260,230,2272,242,2278,196,2274,214,2266,214,2272,108}
TP[25] = {30,92,34,106,60,108,70,102,58,94,60,84}
TP[26] = {2114,72,2100,74,2110,130,2104,168,2110,236,2122,238,2122,178,2116,176,2116,166,2122,164,2122,128,2118,134,2112,132,2112,120,2120,118,2118,90,2114,96,2108,94,2108,84,2116,82}
TP[27] = {820,78,786,76,784,70,794,64,790,56,778,60,780,74,774,76,770,68,742,66,738,58,720,62,716,54,716,68,702,66,686,74,664,70,662,80,674,80,666,92,650,78,654,100,644,96,642,84,606,90,590,82,586,90,566,90,550,128,540,118,550,96,526,94,530,114,514,112,520,130,508,136,516,142,510,156,520,160,520,168,492,172,492,190,504,188,516,194,516,202,536,204,534,214,540,218,564,212,570,226,578,228,572,242,582,238,588,250,556,258,554,248,560,242,516,244,508,258,626,260,630,290,610,292,608,282,614,278,598,284,598,294,610,300,638,300,642,250,650,248,654,256,676,254,672,230,680,226,682,234,688,234,690,222,702,220,696,254,678,264,690,282,716,294,722,284,734,282,736,270,724,262,724,248,746,266,768,270,780,252,778,244,800,244,810,234,816,214,840,196,844,162,836,148,828,146,832,122,828,116,822,124,806,120,804,102,820,96,814,90}
TP[28] = {252,32,248,44,256,56,258,102,266,92,264,34}
TP[29] = {226,30,222,62,190,70,182,78,170,72,170,94,162,102,150,96,152,112,168,114,166,170,178,184,252,184,254,178,252,158,194,158,194,80,232,78,236,72,236,38}
TP[30] = {1324,26,1316,28,1318,90,1324,84}
TP[31] = {84,30,90,46,112,46,128,56,132,44,158,44,146,42,156,34,152,28,136,32,134,22,90,20}
TP[32] = {480,12,474,12,470,38,470,104,478,104}
TP[33] = {2192,8,2202,22,2244,12}
TP[34] = {2092,8,2060,8,2058,44,2076,44,2084,22,2092,20}
TP[35] = {1652,8,1646,20,1608,24,1638,28,1628,40,1608,40,1608,70,1616,72,1620,128,1608,136,1608,162,1628,162,1622,194,1632,198,1626,178,1642,146,1642,52,1648,38,1640,24,1650,20}
TP[36] = {1594,12,1580,8,1580,16,1574,18,1568,8,1560,8,1554,20,1504,22,1504,34,1486,44,1482,74,1474,78,1480,78,1482,86,1502,84,1506,104,1514,98,1554,98,1556,64,1580,64,1586,78,1584,24}
TD.layers[5] = { color={131,129,122}, ocol={113,112,110}, par=0.6, coll=0, hidden=0, polys={} }
TP = TD.layers[5].polys
TP[1] = {1506,876,1482,872,1452,878}
TP[2] = {1714,870,1680,870,1676,850,1674,870,1652,870,1650,876,1628,880,1690,880,1692,874}
TP[3] = {1522,838,1522,864,1554,866,1558,880,1582,870,1578,850,1546,844,1544,852,1532,854}
TP[4] = {1462,838,1514,858,1514,842,1506,828,1488,834,1466,830}
TP[5] = {2360,826,2360,838,2350,836,2346,870,2380,870,2372,830}
TP[6] = {994,828,998,846,1010,852,1028,846,1030,860,1040,854,1052,862,1062,858,1060,850,1068,846,1072,832,1086,834,1088,842,1070,858,1084,854,1094,866,1102,862,1098,828,1072,824,1072,830,1060,836,1062,824,1042,824,1036,838,1030,832,1022,834,1020,826}
TP[7] = {3274,822,3272,836,3302,836,3306,848,3304,832,3290,820}
TP[8] = {462,818,456,846,480,870,480,864,460,848,472,822}
TP[9] = {310,796,294,806,274,806,272,822}
TP[10] = {438,784,426,790,436,798,420,816,424,838,430,838,428,814,446,798,438,794}
TP[11] = {432,772,422,760,396,756,388,760,376,786,322,790,380,788,390,780,388,770,404,760,426,768,418,780,430,780}
TP[12] = {288,754,272,750,270,770}
TP[13] = {2346,674,2338,704,2338,736,2366,736,2366,724,2358,714,2362,694}
TP[14] = {248,492,240,492,230,514,248,514}
TP[15] = {2518,462,2518,526,2542,522,2532,490,2524,486,2524,464}
TP[16] = {942,478,940,502,1004,502,1018,510,1020,554,1014,556,1014,570,1024,576,1030,538,1040,530,1040,514,1038,528,1028,530,1028,454,1020,452,1008,464,1008,492,950,492}
TP[17] = {1006,426,1008,438,1028,440,1028,434}
TP[18] = {1868,424,1856,438,1858,470,1852,484,1860,496,1842,526,1824,532,1814,546,1794,550,1786,598,1788,740,1782,790,1788,822,1780,830,1788,832,1790,854,1782,860,1792,858,1812,872,1844,866,1852,874,1872,862,1872,536,1864,532,1858,508,1860,498,1872,502,1872,490,1858,490,1862,466,1872,460}
TP[19] = {58,422,42,452,42,468,20,468,34,478,40,524,22,550,0,564,0,618,10,620,10,640,18,634,18,606,28,590,44,584,72,550,100,540,100,528,116,528,122,548,180,548,176,538,130,538,126,526,104,524,92,532,72,526,76,514,140,514,136,494,80,492,60,482,60,450,68,448}
TP[20] = {1030,408,1034,428,1056,426,1064,416,1076,418,1078,464,1060,468,1056,452,1066,448,1054,448,1058,480,1096,476,1096,466,1084,450,1086,424,1096,422,1092,412}
TP[21] = {3308,366,3304,380,3310,534,3314,506,3328,502,3328,426,3324,408,3316,414,3310,394,3318,382,3326,400,3326,368,3314,378}
TP[22] = {3152,364,3148,418,3136,422,3126,414,3142,492,3160,494,3172,520,3178,554,3194,556,3210,582,3186,476}
TP[23] = {3110,282,3106,344,3114,346,3114,360,3124,376,3142,360,3136,334,3140,318,3124,290}
TP[24] = {3308,266,3302,268,3304,356,3312,352}
TP[25] = {2330,234,2328,290,2322,296,2336,294,2336,242}
TP[26] = {1698,202,1694,438,1690,460,1680,472,1692,492,1696,518,1694,580,1686,594,1682,634,1688,660,1682,676,1680,726,1664,730,1660,722,1668,714,1660,704,1652,706,1652,818,1662,822,1660,834,1674,834,1676,840,1682,818,1676,804,1680,790,1690,790,1700,816,1714,822,1714,532,1698,516,1692,472,1700,472,1714,486,1714,232,1706,228}
TP[27] = {498,184,496,212,488,216,484,286,504,282,504,262,514,246,504,242,504,224,512,210,520,208}
TP[28] = {1366,152,1334,152,1334,238,1342,216,1340,166,1348,156,1368,156}
TP[29] = {3072,110,3062,178,3076,232,3086,252,3090,232,3100,230,3114,254,3118,250,3110,238,3104,200}
TP[30] = {562,104,546,104,540,112,546,126}
TP[31] = {96,94,104,110,148,110,150,102,162,100,120,94,114,102,112,94}
TP[32] = {2314,80,2318,132,2330,134,2332,158,2328,84,2324,82,2324,92,2318,94}
TP[33] = {2562,74,2554,86,2554,108,2546,108,2546,88,2540,88,2542,106,2536,108,2532,228,2518,248,2518,270,2524,280,2540,278,2550,258,2538,224,2544,222,2548,230,2558,184,2562,118,2556,110}
TP[34] = {1110,44,1102,54,1110,78,1118,78,1116,44}
TP[35] = {3004,12,3018,48,3054,48,3054,34,3030,36,3050,12}
TP[36] = {258,12,254,26,266,34,268,46,268,12}
TP[37] = {224,12,224,26,236,36,236,12}
TP[38] = {0,60,26,56,26,106,42,110,32,106,28,92,44,88,40,62,46,50,72,52,66,68,74,78,78,68,104,68,108,78,128,66,124,54,88,46,82,36,86,18,134,20,136,30,146,24,162,34,172,30,186,36,198,32,210,12,14,12,0,18}
TP[39] = {1410,32,1424,44,1446,44,1454,68,1466,68,1460,74,1466,78,1480,70,1480,60,1492,44,1510,34,1512,22,1580,18,1580,12,1410,10}
TP[40] = {1038,10,1054,12,1066,24,1104,24,1118,30,1116,12}
TP[41] = {1714,6,1710,18,1702,22,1712,30,1702,50,1702,144,1686,176,1694,194,1698,174,1714,184}
TD.layers[6] = { color={86,95,82}, ocol={78,84,79}, par=0.78, coll=0, hidden=0, polys={} }
TP = TD.layers[6].polys
TP[1] = {1844,876,1990,880,1990,864,1972,874,1962,868,1926,872,1904,852,1888,872,1878,862,1874,876}
TP[2] = {3660,874,3692,874,3706,868,3706,846,3730,856,3724,848,3730,836,3694,838,3682,826,3680,840,3674,842}
TP[3] = {446,834,448,866,458,862,472,874,480,874,474,858,480,842,522,854,540,848,536,838,512,820,474,822,460,848}
TP[4] = {1876,794,1870,814,1876,818,1872,826,1878,828,1880,854}
TP[5] = {1750,790,1750,866,1784,866,1784,824,1780,816,1772,820,1760,792}
TP[6] = {3048,796,3034,796,3030,784,2992,810,2974,836,2978,854,2988,860,3048,854}
TP[7] = {3454,780,3458,804,3498,826,3504,850,3516,850,3554,874,3610,874,3634,842,3634,820,3656,822,3666,812,3626,818,3618,808,3584,798,3582,808,3598,830,3576,840,3546,828,3502,794,3488,788,3478,794}
TP[8] = {2856,780,2844,788,2826,788,2826,794,2848,810,2848,790}
TP[9] = {2880,774,2942,792,2942,782,2920,772}
TP[10] = {434,784,418,780,426,774,420,764,404,762,390,770,390,780,380,790,326,790,274,824,272,874,440,874,440,842,428,844,418,834,418,816,434,798,426,788}
TP[11] = {3288,748,3244,774,3212,760,3232,782,3242,776,3242,786,3222,810,3206,814,3200,824,3176,828,3218,832,3222,812,3276,776,3282,764,3290,764}
TP[12] = {1440,742,1408,742,1396,750,1330,744,1328,802,1336,802,1342,788,1388,766,1440,752}
TP[13] = {2952,696,2950,760,2954,770,2964,772,2978,764,2972,750,2984,750,2964,720,2970,710}
TP[14] = {272,690,272,748,288,738,302,714,374,714,400,720,402,714,442,714,468,726,466,696,448,696,446,690,360,690,358,696,344,698,334,690}
TP[15] = {3148,702,3124,686,3108,690,3096,710,3084,710,3074,720,3058,720,3054,740,3078,726,3112,736,3118,726,3146,722}
TP[16] = {1992,684,1992,742,2076,738,2076,748,2084,748,2086,732,2094,734,2094,744,2102,736,2108,744,2134,740,2136,748,2152,742,2150,680,2140,688,2108,686,2106,678,2098,678,2096,688,2084,688,2078,680,2068,684,2002,678}
TP[17] = {3340,660,3336,652,3306,658,3304,640,3246,660,3244,672,3288,656,3304,656,3306,666}
TP[18] = {2950,636,2950,676,2972,692,2966,682,2972,674,2968,646}
TP[19] = {3646,630,3612,640,3624,644,3620,682,3608,688,3612,710,3616,696,3630,700,3628,714,3618,722,3628,774,3614,772,3612,784,3616,788,3628,776,3634,794,3676,782,3654,678,3654,648,3642,642}
TP[20] = {3048,620,3038,630,3038,646,3026,664,3028,684,3034,662,3042,660,3052,642}
TP[21] = {3242,614,3156,618,3150,660,3170,650,3200,658,3204,642}
TP[22] = {2826,604,2790,624,2760,656,2778,652,2826,618}
TP[23] = {2846,600,2904,600,2942,610,2938,604,2880,594}
TP[24] = {3350,600,3352,610,3342,620,3340,642,3362,634,3406,632,3418,646,3430,646,3468,668,3486,688,3506,688,3524,698,3542,690,3552,656,3504,652,3492,668,3462,662,3444,634,3432,632,3434,626,3448,626,3462,600,3454,592,3446,610,3424,622,3402,620,3384,594}
TP[25] = {3082,572,3060,592,3054,612}
TP[26] = {2862,542,2836,542,2842,562,2850,564}
TP[27] = {2834,520,2844,532,2866,532,2868,540,2942,566,2940,556,2920,546,2868,534,2868,522,2842,528,2840,520}
TP[28] = {2628,508,2614,518,2604,514,2614,548,2622,540}
TP[29] = {3572,492,3568,502,3582,512,3600,574,3612,568,3626,576,3616,558,3598,554,3588,508,3580,494}
TP[30] = {1536,486,1584,508,1630,506,1648,536,1662,546,1668,564,1668,482,1662,492,1642,490,1638,484,1618,488,1610,482,1560,484,1552,490}
TP[31] = {3148,478,3104,502,3148,486}
TP[32] = {1762,472,1770,514,1784,528,1784,486,1770,472}
TP[33] = {3148,376,3126,376,3128,386,3116,390,3106,384,3104,394,3088,392,3076,402,3082,410,3092,400,3148,382}
TP[34] = {3762,348,3736,362,3740,394,3742,370,3750,370,3750,400,3738,418,3744,496,3738,516,3748,504,3772,504,3774,518,3780,518,3776,454,3774,498,3766,498,3766,386,3774,384,3774,364,3766,362}
TP[35] = {3562,326,3564,352,3544,366,3536,364,3534,344,3530,346,3530,368,3538,376,3558,358,3568,360,3580,352}
TP[36] = {3096,294,3076,314,3068,336,3078,330}
TP[37] = {2608,274,2604,290,2590,294,2584,286,2584,298,2606,296,2610,304}
TP[38] = {3726,174,3728,236,3738,194,3736,182}
TP[39] = {1768,174,1764,182,1770,208,1784,228,1784,184}
TP[40] = {3776,118,3766,128,3748,182,3752,294,3740,302,3736,288,3736,348,3742,344,3744,328,3752,336,3776,314}
TP[41] = {1700,12,1682,26,1684,62,1700,54}
TP[42] = {270,12,270,90,296,64,368,62,400,70,464,104,468,100,468,12}
TP[43] = {2952,8,2954,238,2946,248,2954,254,2952,510,2966,582,2990,626,2992,590,3012,522,3020,522,3006,586,3008,612,3020,638,3048,582,3050,468,3038,484,3032,478,3052,448,3050,400,3058,388,3050,382,3050,366,3062,368,3060,356,3046,356,3046,340,3052,336,3052,118,3046,76,3050,8}
TP[44] = {2868,28,2880,34,2882,18,2894,14,2894,30,2914,26,2910,10,2878,8}
TP[45] = {2566,8,2566,26,2572,32,2562,30,2576,68,2584,28,2580,8}
TP[46] = {1030,4,1102,6,1104,12,1116,12,1120,68,1144,22,1226,20,1250,24,1302,76,1302,82,1312,76,1310,16,1292,12,1290,8}
TD.layers[7] = { color={46,44,41}, ocol={55,55,53}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[7].polys
TP[1] = {476,856,508,876,528,866,524,862,522,868,512,868,510,856,502,866,494,866,492,848}
TP[2] = {4194,822,4154,822,4154,844,4130,876,4138,876,4150,860,4166,864,4166,876,4176,876,4190,844,4196,842}
TP[3] = {3478,780,3444,794,3426,810,3412,834,3392,838,3392,868,3490,868,3490,856,3432,862,3416,846,3422,822}
TP[4] = {3288,772,3334,770,3370,784,3380,792,3376,800,3382,796,3374,780,3338,766,3308,764}
TP[5] = {3190,772,3284,778,3246,772,3244,764}
TP[6] = {3954,728,3964,736,3960,748,3970,760,3966,780,3972,812,3982,824,4002,824,4014,836,4010,856,3990,850,3946,852,3976,858,3988,868,4004,858,4042,876,4070,876,4034,854,4022,854,4018,832,3974,806,3974,750,3994,748}
TP[7] = {3788,730,3806,736,3812,776,3820,772,3822,762,3838,770,3850,748,3822,740,3820,724,3814,720}
TP[8] = {3950,632,3962,634,3980,662,4010,668,4016,654,4030,652,3982,606,3976,606,3966,630}
TP[9] = {3258,598,3212,604,3210,612,3228,608,3230,602,3252,604}
TP[10] = {3904,596,3914,614,3928,622,3952,618,3968,600,3966,594,3954,614,3928,620,3916,612,3908,592}
TP[11] = {4088,506,4106,600,4104,638,4136,642,4116,660,4124,686,4134,688,4138,642,4162,630,4158,610,4138,576,4116,576,4104,528}
TP[12] = {3470,500,3450,546,3444,582,3432,582,3438,598,3446,602,3438,610,3438,624,3432,626,3416,604,3406,568,3402,578,3386,586,3394,602,3406,606,3408,616,3406,624,3388,622,3414,652,3430,638,3440,638,3446,648,3446,626,3456,626,3454,652,3448,654,3454,668,3456,650,3464,648,3476,616,3460,636,3448,604,3456,542}
TP[13] = {3548,404,3526,418,3518,398,3512,430,3488,458,3474,488,3504,448,3510,450,3510,462,3516,458,3518,432,3546,414}
TP[14] = {4256,212,4248,222,4248,236,4254,250,4252,288,4260,300}
TP[15] = {1296,78,1296,88,1312,102,1312,210,1324,238,1322,248,1328,252,1320,162,1326,114}
TP[16] = {2164,6,2134,6,2138,32,2124,42,2132,72,2122,112,2140,138,2126,254,2132,288,2150,292,2154,300,2144,306,2130,302,2116,344,2102,368,2086,380,2068,416,2052,424,2046,440,2028,454,2028,470,2022,476,2004,478,2000,528,2012,538,1998,540,1992,548,1996,590,2004,582,2026,592,2038,576,2036,566,2050,564,2058,544,2074,546,2086,532,2106,524,2116,498,2116,440,2124,426,2138,422,2136,410,2148,402,2150,358,2160,350,2170,300,2164,298,2162,186,2154,184,2150,174,2150,144,2160,134,2144,130,2140,112,2148,62,2160,52,2156,30}
TD.layers[8] = { color={46,44,41}, ocol={55,55,53}, par=1, coll=0, hidden=0, polys={} }
TP = TD.layers[8].polys
TP[1] = {4216,848,4226,856,4226,870,4212,876,4248,876,4248,862,4240,854}
TP[2] = {3232,792,3238,822,3250,826,3258,814,3256,798,3246,804}
TP[3] = {4332,748,4322,754,4318,774,4332,774}
TP[4] = {4144,698,4134,700,4134,722,4146,712}
TP[5] = {3400,662,3412,684,3388,680,3414,706,3422,698,3420,678}
TP[6] = {3524,608,3498,638,3504,648}
TP[7] = {4088,364,4070,380,4058,382,4052,376,4076,420,4086,412}
TP[8] = {2954,298,2940,308,2944,330,2948,316,2954,314}
TP[9] = {3266,276,3268,304,3278,316,3286,310,3296,280,3274,282}
TP[10] = {3284,30,3286,66,3292,78,3300,80,3318,32,3292,36}
TD.layers[9] = { color={25,23,21}, ocol={33,33,32}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[9].polys
TP[1] = {2646,842,2646,876,2844,872,2840,844,2760,844,2742,838,2736,846}
TP[2] = {3822,764,3826,780,3848,782,3846,796,3860,800,3888,794,3894,800,3886,838,3916,862,3946,848,3990,848,4004,854,4012,850,4012,836,4002,826,3982,826,3974,820,3964,780,3970,762,3958,748,3960,736,3940,712,3906,716,3900,724,3900,748,3886,740,3860,738,3842,758,3840,770}
TP[3] = {4000,624,4032,650,4054,648,4052,638,4024,612,4016,614,4010,626}
TP[4] = {3922,564,3926,574,3920,576,3916,570,3916,588,3908,598,3928,618,3954,612,3964,590,3942,566}
TP[5] = {754,552,672,552,670,604,676,612,672,716,664,736,670,744,670,806,640,822,606,830,590,846,516,876,702,876,724,862,732,864,722,874,726,876,782,848,778,838,788,824,808,822,820,810,840,810,840,804,854,796,848,762,854,748,852,732,840,746,790,746,788,750,804,748,798,764,778,766,762,780,744,778,740,636,746,616,738,596,746,586,740,576,742,558,754,558,754,622,764,588,756,580}
TP[6] = {2644,548,2556,548,2556,586,2644,584}
TP[7] = {3548,530,3538,528,3504,566,3466,646,3458,648,3456,668,3440,644,3442,626,3440,636,3430,634,3430,642,3422,646,3424,626,3420,618,3414,620,3424,692,3416,706,3422,708,3426,724,3418,732,3438,756,3436,764,3416,774,3390,776,3388,770,3354,754,3334,760,3332,754,3312,750,3296,738,3284,740,3266,726,3250,734,3252,746,3244,752,3184,756,3182,762,3138,758,3100,728,3104,708,3094,720,3080,702,3056,698,3030,668,3012,660,3000,646,3000,634,2992,640,2964,610,2960,612,2996,654,2984,670,3020,674,3050,696,3058,714,3046,720,3046,730,3082,728,3124,768,3112,780,3118,790,3150,790,3160,770,3234,762,3236,770,3276,776,3296,764,3338,764,3382,786,3384,796,3372,806,3370,822,3386,836,3404,836,3426,808,3460,782,3478,778,3480,788,3490,790,3494,774,3504,778,3510,718,3484,716,3494,696,3492,682,3502,646,3494,650,3474,696,3468,694,3466,660,3494,600}
TP[8] = {4268,510,4254,534,4236,622,4252,622,4254,628,4226,638,4230,662,4240,668,4248,724,4250,876,4318,876,4316,794,4324,792,4332,800,4332,790,4316,782,4310,682,4318,650,4306,640,4316,618,4294,540,4286,538,4284,516}
TP[9] = {2646,508,2646,544,2748,544,2756,550,2758,542,2834,542,2836,508}
TP[10] = {2432,442,2386,434,2374,440,2324,440,2322,470,2306,494,2288,504,2286,514,2258,534,2242,554,2274,588,2284,590,2330,540,2338,538,2346,520,2380,498,2432,502}
TP[11] = {3698,374,3700,384,3690,402,3684,434,3674,440,3674,486,3654,484,3624,454,3622,476,3664,506,3664,526,3652,528,3662,550,3678,544,3694,556,3702,556,3704,548,3740,554,3764,574,3770,590,3792,598,3782,610,3736,626,3704,650,3708,682,3722,692,3738,692,3760,658,3786,646,3820,640,3822,654,3848,650,3856,634,3854,618,3864,608,3858,602,3826,608,3820,596,3820,568,3806,570,3760,544,3746,548,3732,536,3694,522,3690,504,3696,488,3684,478,3690,460,3684,452,3684,432,3694,408,3708,400,3698,398,3706,376}
TP[12] = {2974,358,2972,386,3092,388,3092,358}
TP[13] = {4332,308,4290,326,4254,360,4332,324}
TP[14] = {1752,92,1748,96,1758,110,1750,124,1736,124,1736,174,1730,192,1740,222,1736,422,1682,426,1670,416,1628,414,1614,416,1602,426,1534,424,1532,402,1520,398,1500,406,1464,404,1462,428,1442,458,1408,488,1400,486,1378,512,1422,554,1462,516,1480,488,1516,460,1534,462,1534,480,1580,488,1598,482,1704,482,1708,490,1724,490,1726,482,1736,484,1740,588,1734,608,1736,664,1730,694,1740,730,1734,758,1734,876,1764,876,1764,96}
TP[15] = {478,110,474,126,454,124,448,116,454,104,368,66,296,70,258,110,254,192,264,190,258,206,258,506,252,510,258,536,240,548,252,542,260,548,250,560,224,566,198,586,174,590,154,608,128,614,116,626,98,628,86,640,98,668,128,662,138,650,164,644,184,624,200,626,216,612,240,606,242,614,258,612,258,688,336,690,340,696,356,696,360,688,448,688,450,694,464,696,456,692,458,684,480,688,476,504,484,502,484,496,476,490,482,478,480,430,486,406,480,400,476,354,482,314,476,220}
TP[16] = {1146,28,1136,48,1146,56,1144,80,1130,88,1126,110,1118,118,1108,118,1108,276,1102,292,1108,318,1108,506,1114,516,1106,530,1106,764,1100,778,1106,794,1106,876,1126,876,1126,860,1132,858,1134,876,1256,876,1258,884,1620,884,1620,878,1588,878,1586,854,1582,878,1358,878,1350,856,1350,876,1342,878,1336,862,1340,848,1330,858,1316,848,1318,834,1334,844,1322,830,1328,742,1372,742,1394,750,1406,742,1522,738,1534,744,1534,762,1616,762,1626,758,1610,756,1610,712,1622,710,1626,722,1626,708,1576,708,1596,712,1588,722,1568,718,1568,708,1548,708,1558,712,1558,722,1542,724,1532,716,1540,708,1522,696,1504,706,1468,696,1446,704,1430,696,1406,704,1392,698,1318,700,1326,656,1320,584,1330,580,1326,518,1332,500,1326,496,1326,410,1320,408,1316,390,1324,366,1320,354,1326,352,1320,338,1330,278,1324,272,1326,254,1320,252,1322,238,1310,210,1308,114,1290,94,1290,86,1296,84,1292,72,1288,82,1268,74,1260,60,1266,50,1248,28}
TP[17] = {4288,14,4244,14,4242,42,4224,92,4218,94,4206,74,4200,78,4220,106,4222,120,4232,126,4244,170,4254,180,4266,176,4274,162,4288,108,4302,106,4324,72,4330,74,4332,120,4332,46,4326,44,4330,34,4294,42}
TP[18] = {4136,14,4106,14,4102,20,4094,14,4020,14,3980,32,4032,26,4034,34,4014,56,3956,54,3926,60,3992,66,3994,72,3930,108,3910,126,3882,168,3988,92,3984,172,3992,212,4010,110,4010,72,4034,64,4032,134,4050,68,4086,122,4076,74,4110,34,4126,42,4142,80,4140,46,4146,42,4138,38}
TP[19] = {2132,6,1994,6,1996,126,1990,130,1998,136,1994,280,1988,298,1994,318,1998,488,1888,492,1890,526,1992,528,1998,538,2010,538,1994,520,2002,478,2022,474,2028,466,2026,454,2044,440,2052,422,2066,416,2084,380,2100,368,2114,344,2128,302,2154,300,2130,288,2124,254,2130,228,2128,188,2138,168,2138,138,2130,120,2122,116,2130,72,2122,42,2136,32}
TD.layers[10] = { color={25,23,21}, ocol={33,33,32}, par=1, coll=0, hidden=0, polys={} }
TP = TD.layers[10].polys
TP[1] = {4140,874,4164,876,4166,866,4150,862}
TP[2] = {3544,676,3532,678,3538,688,3528,694,3528,712,3536,716,3566,698}
TP[3] = {3614,648,3596,670,3602,682,3620,694,3620,658}
TP[4] = {3642,602,3628,602,3622,608,3622,642,3648,628,3650,612}
TP[5] = {936,444,914,462,916,478,936,476,928,468,928,454}
TP[6] = {4166,14,4198,60,4182,16}
TD.layers[11] = { color={150,45,60}, ocol={150,45,60}, par=1, coll=0, hidden=1, polys={} }
TP = TD.layers[11].polys
TP[1] = {3670,798,3660,798,3658,806,3644,802,3638,812,3650,822,3638,844,3648,846,3654,860,3662,856,3664,846,3676,844,3676,838,3658,830,3648,812,3662,806,3662,820,3680,820}
TP[2] = {3082,674,3084,692,3078,700,3088,708,3108,706,3114,716,3124,716,3134,696,3114,672,3102,668}
TP[3] = {3652,390,3640,420,3656,424,3654,402,3666,400,3664,410,3680,424,3680,398,3662,388}
TP[4] = {3708,338,3694,338,3686,346,3688,364,3692,356,3702,360}
TD.layers[12] = { color={72,115,79}, ocol={72,115,79}, par=1, coll=0, hidden=0, polys={} }
TP = TD.layers[12].polys
TD.layers[13] = { color={158,160,98}, ocol={158,160,98}, par=1, coll=0, hidden=1, polys={} }
TP = TD.layers[13].polys
TRACE_DEFS["zhumei"] = TD
TD = { base={108,128,14}, spanx2=2800, spany2=583, frw=1680, frh=910, refx=840, refy=455, layers={},
  conf={ spawn={450,940}, cps={{450,940}, {2200,700}, {3500,975}}, goal={4250,1230}, kill=1750 } }
TD.layers[1] = { color={151,161,25}, ocol={151,161,25}, par=0.18, coll=0, hidden=0, polys={} }
TP = TD.layers[1].polys
TP[1] = {1272,1001,1272,1005,1356,1006,1356,1001}
TP[2] = {136,989,136,1009,177,1009,191,1004,171,1000,168,974,156,966,149,966,151,976,164,976,166,984}
TP[3] = {313,937,309,947,309,996,327,995,321,992,322,986,328,986,321,978,328,977,328,945,319,945}
TP[4] = {1339,918,1339,942,1350,943,1341,959,1363,958,1364,963,1339,981,1338,994,1386,994,1386,914}
TP[5] = {1416,910,1416,924,1420,927,1433,927,1440,915,1454,915,1454,926,1459,925,1460,916,1466,917,1467,926,1472,925,1473,917,1478,917,1479,924,1484,926,1485,917,1491,916,1491,931,1454,932,1489,934,1491,941,1510,940,1510,928,1558,926,1558,910}
TP[6] = {422,910,424,916,439,922,440,940,447,942,441,949,458,974,454,984,441,981,440,996,469,996,471,1009,532,1008,533,996,603,996,601,983,607,975,612,976,610,996,628,996,637,970,645,967,654,950,651,922,663,912,555,910,555,921,548,922,545,910,545,921,533,926,537,940,519,941,512,935,512,928,503,924,484,932,461,919,451,922,444,910}
TP[7] = {2062,904,2067,921,2064,977,2070,980,2072,1009,2082,1011,2085,973,2081,972,2081,965,2085,960,2076,963,2076,983,2070,983,2070,916,2067,906}
TP[8] = {1815,859,1767,857,1751,849,1746,840,1705,840,1703,866,1697,873,1691,873,1690,818,1680,810,1679,910,1576,910,1575,943,1568,948,1416,948,1416,996,1625,998,1628,1011,1631,998,1671,998,1670,1011,1815,1011,1815,927,1820,923,1819,902,1815,901}
TP[9] = {406,787,402,788,398,808,388,814,388,835,396,837,397,853,401,851,399,829,406,819,402,816}
TP[10] = {362,720,362,725,367,725,368,731,381,738,382,745,387,747,389,739,379,731,379,720}
TP[11] = {851,697,860,697,863,688,877,682,852,680}
TP[12] = {213,631,193,632,182,643,176,662,162,657,146,668,133,694,141,717,119,732,106,776,97,772,97,760,102,755,82,750,77,756,77,905,147,905,148,929,165,933,169,953,171,906,217,905,217,891,224,887,224,799,217,794,216,732,224,726,224,634}
TP[13] = {2074,608,2075,616,2069,626,2070,632,2083,635,2085,710,2086,646,2083,632,2077,629,2083,614}
TP[14] = {35,619,36,625,45,621,47,626,58,628,56,642,74,643,88,659,101,662,95,652,93,632,81,615,81,606,53,618}
TP[15] = {1579,602,1574,602,1575,612,1569,617,1573,635,1563,646,1529,643,1521,645,1516,656,1467,658,1460,653,1452,633,1412,640,1408,657,1398,659,1398,705,1390,712,1392,723,1398,727,1398,757,1403,760,1424,752,1424,725,1430,719,1469,719,1470,694,1462,693,1465,704,1456,705,1453,686,1457,682,1478,682,1483,688,1481,731,1442,734,1441,750,1436,751,1436,769,1461,776,1463,785,1473,789,1475,761,1482,756,1504,754,1507,698,1535,700,1534,717,1524,717,1529,706,1515,707,1515,745,1563,745,1568,748,1569,757,1579,762,1579,700,1572,695,1572,645,1579,641}
TP[16] = {47,519,39,522,39,529,56,552,54,575,48,578,47,590,35,602,50,599,51,580,56,577,64,555,60,544,44,535,42,526,47,525}
TP[17] = {998,529,1035,530,1029,526,1034,511,1001,510}
TP[18] = {1152,500,1138,496,1137,506,1125,506,1136,508,1137,513,1126,518,1127,526,1120,528,1126,531,1124,541,1114,537,1113,542,1107,542,1099,531,1111,530,1115,525,1098,521,1089,508,1083,508,1086,518,1095,521,1093,530,1096,537,1103,538,1103,543,1138,544,1139,531,1155,531,1155,523,1149,518}
TP[19] = {1677,463,1672,478,1629,480,1638,491,1637,506,1600,508,1590,513,1599,526,1586,572,1588,592,1601,591,1595,573,1600,569,1599,544,1608,533,1639,527,1661,542,1668,572,1660,591,1670,593,1674,601,1680,602,1680,671,1676,672,1680,706,1674,714,1679,718,1691,713,1691,786,1703,795,1705,816,1715,816,1717,825,1737,824,1738,816,1756,815,1745,811,1742,791,1756,785,1758,771,1742,767,1735,756,1737,746,1749,743,1735,723,1736,711,1690,710,1690,640,1699,639,1705,645,1705,695,1768,695,1765,670,1772,663,1771,653,1775,649,1793,648,1815,657,1815,644,1824,645,1830,654,1830,669,1824,670,1823,675,1833,680,1833,648,1829,642,1815,638,1815,623,1845,622,1846,682,1841,687,1847,687,1848,622,1815,618,1816,589,1844,589,1850,585,1847,526,1844,525,1845,539,1825,538,1846,553,1843,586,1815,584,1814,552,1798,554,1798,565,1791,574,1733,574,1728,570,1729,541,1721,531,1728,508,1723,491,1707,475,1691,474,1688,506,1680,507}
TP[20] = {50,438,44,440,48,448,45,456,52,466,46,511,61,475,61,466,52,458}
TP[21] = {367,430,368,447,360,448,360,535,363,537,363,520,375,519,379,547,377,560,371,559,370,550,371,557,364,562,360,582,360,631,367,647,367,692,398,693,402,643,414,640,416,645,427,647,434,658,449,661,448,650,426,635,426,607,418,580,422,575,422,552,416,551,409,537,409,529,422,521,427,495,433,493,436,497,441,487,450,482,449,449,436,450,433,465,409,464,408,517,386,522,379,513,379,472,367,473,369,450,375,447,379,430}
TP[22] = {98,405,124,412,128,426,126,431,93,428,81,433,88,478,73,487,79,503,96,503,105,510,101,532,108,536,145,536,154,545,152,570,161,582,203,581,217,590,224,589,224,583,207,578,166,575,160,570,155,538,113,528,105,504,79,497,81,486,95,478,87,457,92,437,134,433,132,415}
TP[23] = {1681,369,1675,376,1672,392,1664,399,1674,410,1676,422}
TP[24] = {658,383,656,402,639,408,663,409,678,415,679,421,685,422,687,434,694,438,697,432,710,431,711,437,728,439,732,457,737,459,744,454,776,458,787,474,803,481,804,490,810,484,834,486,835,508,839,510,837,547,832,556,815,562,809,573,792,575,794,567,788,564,776,570,753,560,747,546,739,540,715,544,699,539,688,523,671,515,670,505,663,513,639,511,636,499,628,507,628,517,622,520,622,526,637,516,662,523,657,553,656,723,659,733,668,737,669,748,678,746,680,757,686,760,686,770,692,772,694,800,704,801,704,720,670,720,664,716,660,672,663,621,729,623,730,609,725,602,719,602,721,612,713,611,716,594,749,593,768,601,816,607,818,618,788,620,791,660,787,663,761,664,755,660,757,644,763,646,763,653,779,653,779,639,773,635,754,635,752,641,745,635,735,635,732,642,682,636,679,698,699,699,700,705,714,707,722,716,733,708,736,733,765,733,768,721,776,722,773,732,777,733,778,722,790,721,785,732,791,731,792,723,798,723,801,740,808,740,809,747,829,747,830,733,877,732,876,704,854,707,839,703,839,675,843,667,879,665,886,675,884,666,889,665,895,678,912,680,911,696,895,692,894,748,889,754,737,754,732,826,715,831,687,830,676,836,676,844,666,846,662,856,674,867,683,866,721,904,720,910,695,915,696,922,687,928,701,930,716,948,713,969,719,967,723,952,740,944,750,932,753,905,812,905,813,913,841,929,851,930,832,910,816,910,815,903,822,899,851,901,851,896,857,895,860,905,880,906,877,919,872,920,873,941,867,944,873,964,894,959,895,972,887,979,887,986,895,988,899,981,914,984,919,989,921,1009,997,1009,997,996,1034,996,1032,1009,1261,1006,1261,1001,1097,1001,1096,961,1103,958,1103,936,1015,935,1008,928,1007,910,1002,909,1002,894,1008,883,1008,856,976,837,981,831,1005,830,999,793,1007,787,1006,756,1045,742,1038,796,1043,828,1039,871,1044,887,1057,883,1064,873,1071,871,1072,863,1084,868,1084,905,1111,905,1119,897,1127,897,1130,885,1136,889,1144,884,1156,885,1155,757,1149,761,1149,784,1143,795,1118,795,1105,788,1114,769,1108,751,1129,701,1143,703,1143,694,1152,696,1152,711,1144,715,1155,716,1156,671,1140,687,1128,691,1102,687,1088,694,1095,708,1095,719,1091,722,1083,721,1081,711,1063,707,1055,717,1048,714,1031,723,1027,739,1017,744,1001,739,988,742,979,724,960,723,957,709,962,693,958,680,963,677,958,664,964,651,984,649,991,643,1017,649,1030,644,1031,640,1044,637,1044,629,1053,620,1065,623,1065,616,1072,615,1073,608,1092,601,1100,586,1110,581,1122,581,1137,588,1145,586,1151,578,1148,560,1092,561,1091,587,1081,596,1016,596,1017,576,1002,576,1000,579,1009,581,1008,593,1015,602,1013,615,1000,616,999,620,984,616,985,593,988,589,999,590,983,584,987,566,1028,566,1034,580,1071,580,1071,563,977,561,969,551,968,514,956,521,938,517,940,497,935,501,920,499,927,483,921,480,917,468,909,468,909,478,888,490,879,487,878,481,872,481,870,488,863,487,863,479,876,475,876,469,867,467,855,473,851,448,863,447,859,443,858,422,870,415,875,400,866,399,868,409,858,403,862,393,857,389,857,380,871,376,852,333,855,326,861,326,854,323,853,316,843,316,842,324,834,323,831,316,800,318,800,370,793,380}
TP[25] = {47,310,45,352,51,366,45,378,50,379,52,397,57,405,73,412,91,411,92,408,65,406,59,397,55,372,62,366,53,357,55,345,49,340}
TP[26] = {848,300,833,299,841,290,818,292,819,305,843,305}
TP[27] = {1690,253,1680,257,1680,328,1690,322}
TP[28] = {506,280,501,290,432,296,432,289,445,289,446,281,455,281,445,277,443,252,435,252,435,265,421,266,420,295,432,296,431,312,394,312,389,328,374,322,368,314,361,343,361,409,372,423,375,408,363,407,365,388,399,387,400,377,409,378,413,395,420,396,421,404,449,407,449,386,434,378,425,365,423,349,427,338,452,313,464,309,486,311,499,303,499,297,506,294}
TP[29] = {793,248,788,248,781,274,748,275,745,280,745,299,739,300,739,308,745,309,748,352,775,352,776,304,783,297,807,297,808,279}
TP[30] = {53,240,41,264,46,290,51,284}
TP[31] = {1691,115,1691,122,1699,124,1712,143,1747,135,1760,127,1766,158,1762,125,1744,123,1717,133,1705,118}
TP[32] = {1457,74,1445,73,1434,78,1408,74,1401,78,1401,105,1390,117,1392,185,1398,193,1416,190,1417,151,1425,146,1422,131,1427,128,1440,88,1456,85,1464,95,1490,100,1464,86}
TP[33] = {926,71,927,112,964,112,964,105,969,104,975,113,975,126,991,126,999,119,991,116,992,102,1008,102,1002,90,993,93,987,85,984,90,977,90,969,85,969,79,960,85,942,85,937,82,937,72}
TP[34] = {156,72,131,66,131,71,122,72,121,77,103,73,101,79,119,81,125,76,149,77}
TP[35] = {1040,63,1047,75,1055,73,1057,79,1079,81,1078,94,1086,89,1081,77,1076,76,1077,60,1072,52,1060,56,1059,63}
TP[36] = {1124,27,1108,36,1108,45,1094,54,1093,85,1124,77}
TP[37] = {1384,0,1384,63,1389,74,1389,0}
TP[38] = {1156,0,1147,0,1141,20,1141,56,1149,57,1154,48}
TP[39] = {478,37,476,49,491,48,510,59,528,62,543,52,544,46,561,43,576,69,578,90,615,89,630,95,676,97,684,100,685,108,713,107,713,98,729,96,736,106,747,139,733,155,728,170,731,179,723,184,704,184,703,194,677,194,670,207,647,208,643,216,643,247,622,247,621,243,608,240,617,277,656,351,726,352,727,326,713,321,706,305,711,304,716,313,713,297,727,293,727,266,731,261,772,261,773,247,784,247,762,241,763,233,773,224,759,224,752,237,738,234,724,207,728,194,735,194,756,208,775,205,784,208,787,215,813,213,823,219,831,234,832,258,855,273,885,281,898,295,891,323,893,343,908,344,907,329,912,330,912,335,924,335,925,329,938,332,941,326,969,332,978,323,985,329,1001,329,1013,314,1026,318,1029,314,1037,317,1047,313,1047,302,1058,303,1065,309,1067,302,1057,301,1062,293,1086,300,1097,299,1100,290,1107,290,1116,300,1118,313,1139,299,1156,309,1156,302,1148,298,1149,245,1155,244,1148,226,1144,264,1120,266,1114,263,1114,238,1098,238,1097,224,1087,223,1087,218,1095,217,1096,213,1147,215,1148,211,1078,211,1069,206,1067,134,1048,135,1048,161,1037,199,1026,202,1032,215,1023,223,1008,223,1003,215,1004,207,1012,207,1008,144,1013,143,1014,137,1039,135,913,133,909,129,907,80,880,84,869,95,842,92,856,38,846,18,838,16,839,0,611,0,602,14,533,14,532,20,524,16,532,25,535,19,567,19,576,26,575,31,564,27,545,30,540,50,517,52,512,43}
TP[40] = {482,11,520,13,519,0,493,0}
TD.layers[2] = { color={218,189,47}, ocol={218,189,47}, par=0.2, coll=0, hidden=0, polys={} }
TP = TD.layers[2].polys
TP[1] = {1014,1019,1046,1021,1050,1011,1014,1011}
TP[2] = {2104,898,2104,913,2116,913,2126,923,2127,991,2131,995,2131,975,2138,967,2137,899}
TP[3] = {1149,804,1145,805,1139,824,1136,858,1150,843}
TP[4] = {1092,748,1084,752,1084,815,1098,779,1099,761}
TP[5] = {1968,739,1968,752,1979,754,1985,763,1988,814,1995,800,1995,740}
TP[6] = {1968,688,1968,703,1994,703,1994,692,1988,692,1985,686,1975,683}
TP[7] = {2126,645,2122,648,2124,666,2136,696,2131,713,2126,712,2118,691,2114,691,2114,702,2127,724,2137,726,2138,649}
TP[8] = {1006,653,1000,652,1000,643,952,655,961,655,959,668,971,673,993,649,999,650,998,658}
TP[9] = {1832,635,1832,650,1851,650,1862,658,1863,691,1874,694,1874,635}
TP[10] = {739,594,741,622,786,622,818,615,813,606,794,607,782,600,768,602}
TP[11] = {848,604,850,608,893,609,900,620,920,620,927,633,940,624,929,617,927,610,920,612,905,597,907,590,902,587,892,589,887,601,881,597,876,601,859,598}
TP[12] = {1814,530,1812,565,1832,565,1832,596,1874,596,1874,566,1843,543,1832,548,1831,530}
TP[13] = {1660,542,1639,528,1608,534,1601,542,1601,569,1596,573,1604,592,1657,592,1667,572}
TP[14] = {1976,514,1973,531,1995,535,1995,524,1989,514}
TP[15] = {1691,483,1680,487,1680,544,1685,509,1691,505}
TP[16] = {27,356,22,362,0,363,0,395,35,397,35,424,44,432,44,439,52,441,52,457,61,466,59,486,50,498,48,525,43,529,65,551,63,565,52,580,52,600,36,603,35,615,41,627,46,618,81,605,84,620,94,632,96,652,102,658,100,664,95,664,76,650,81,659,91,664,90,669,81,669,86,674,94,673,101,689,106,672,114,673,120,682,119,726,106,741,101,741,98,734,94,741,99,746,90,748,102,755,98,772,106,775,118,732,141,716,132,701,134,688,141,682,145,668,166,656,165,648,136,643,135,619,152,615,163,598,172,597,176,606,166,615,165,629,169,647,180,649,195,630,213,630,217,634,224,631,224,590,217,591,203,582,161,582,151,571,154,545,144,537,118,537,115,532,102,531,100,516,106,511,96,504,77,502,73,486,88,478,81,457,81,433,93,427,126,430,128,417,98,408,91,412,60,408,51,397,54,390,49,388,49,379,44,378,50,360}
TP[17] = {1688,333,1680,339,1680,377,1684,372,1691,373,1692,387,1700,387,1701,395,1692,396,1692,465,1684,469,1692,470,1692,481,1723,486,1744,512,1746,466,1811,464,1811,442,1800,441,1797,435,1784,439,1764,421,1745,417,1743,405,1748,400,1735,402,1736,393,1729,387,1731,359,1738,348,1692,366}
TP[18] = {1806,158,1816,176,1831,178,1831,164,1819,165}
TP[19] = {2120,119,2104,126,2104,170,2124,159,2126,145,2131,142}
TP[20] = {1968,137,1976,136,1984,122,1993,121,1993,116,1968,116}
TP[21] = {1680,101,1680,263,1728,265,1736,256,1742,256,1747,262,1740,267,1772,267,1780,259,1793,264,1797,259,1807,261,1808,257,1831,254,1831,205,1808,203,1778,168,1776,140,1763,148,1725,155,1715,137,1691,131,1691,101}
TP[22] = {1091,56,1077,57,1079,76,1091,77}
TP[23] = {842,91,867,94,880,83,909,79,909,73,903,68,873,65,868,48,853,47,854,59}
TD.layers[3] = { color={245,222,82}, ocol={245,222,82}, par=0.22, coll=0, hidden=0, polys={} }
TP = TD.layers[3].polys
TP[1] = {315,751,299,775,297,800,301,801,300,809,309,818,309,824,315,825,315,833,322,833,326,840,327,832,320,831,319,823,314,823,305,810,306,775,315,755,320,753}
TP[2] = {298,747,295,761,288,764,289,772,282,773,284,786,278,787,282,801,277,804,286,810,280,817,287,821,294,819,287,815,284,786,290,785,294,763,300,762}
TP[3] = {676,746,670,762,661,759,661,752,651,751,661,766,667,790,662,816,653,824,652,831,645,830,645,840,656,834,657,825,668,818,667,810,672,809,675,801,671,782,674,775,682,776,681,787,685,788,684,816,677,821,692,818,687,810,695,804,690,801,694,787,688,786,690,772,683,771,684,760,677,759}
TP[4] = {118,718,105,727,97,742,86,748,106,740,117,728}
TP[5] = {58,644,71,652,78,666,102,671,106,676,105,693,114,702,121,700,114,674,87,664,73,648}
TP[6] = {117,608,116,638,122,648,125,615,123,608}
TP[7] = {162,601,158,613,137,619,135,637,141,645,164,646,166,653,175,657,177,648,168,647,164,623,166,613,176,601}
TP[8] = {1129,587,1119,583,1102,588,1100,597,1089,606,1074,610,1067,623,1079,613,1095,611,1103,594,1112,587,1127,593}
TP[9] = {1616,555,1614,576,1631,581,1639,579,1649,564,1642,554}
TP[10] = {673,508,674,514,690,522,700,537,715,542,733,539,704,534,698,527,699,520,685,517}
TP[11] = {742,459,771,464,776,478,801,489,800,483,793,476,785,476,775,461,760,455}
TP[12] = {1694,425,1694,484,1706,475,1703,455,1706,424}
TP[13] = {2158,203,2146,210,2146,246,2159,246,2163,239,2168,239,2168,233,2156,230,2156,225,2166,220}
TP[14] = {727,198,727,210,734,213,739,232,747,235,757,223,778,220,783,214,755,212,742,206,735,196}
TP[15] = {257,63,231,62,240,87,233,90,230,114,234,97,245,88}
TP[16] = {478,15,481,37,509,38,517,51,536,49,540,43,537,29,520,14}
TP[17] = {205,15,206,33,267,32,267,26,255,29,245,19,235,26,232,12,217,21,212,20,212,14}
TP[18] = {1390,0,1390,111,1398,104,1399,75,1407,71,1431,76,1456,72,1464,76,1472,89,1498,100,1510,96,1527,104,1537,104,1541,96,1549,101,1564,101,1577,85,1599,89,1610,85,1612,78,1628,82,1631,68,1661,73,1662,64,1668,63,1679,78,1679,0}
TP[19] = {448,0,441,0,438,6,418,6,415,18,448,18}
TP[20] = {174,0,0,0,0,362,20,362,27,355,44,357,42,350,46,347,45,292,39,264,48,244,41,237,24,235,23,224,29,218,14,220,10,179,24,165,14,155,31,141,28,132,37,123,35,112,41,101,52,94,49,86,60,77,69,82,73,76,99,78,102,71,120,75,136,65,157,70,159,75,176,74,181,86,190,81,195,68,200,69,201,76,207,70,218,72,214,63,185,62,175,53}
TD.layers[4] = { color={147,160,115}, ocol={147,160,115}, par=0.25, coll=0, hidden=0, polys={} }
TP = TD.layers[4].polys
TP[1] = {664,753,660,759,666,759,667,766,660,769,674,771,674,777,666,779,681,789,678,800,683,798,683,790,691,780,682,786,684,773,677,772,679,758,671,761}
TP[2] = {600,744,591,761,594,782,602,788,631,787,638,777,645,776,645,759,627,741,608,740}
TP[3] = {486,312,458,312,430,334,424,354,428,369,437,379,450,385,464,382,481,370,473,337,497,326,497,320}
TP[4] = {555,282,552,283,556,302,548,315,524,315,526,302,534,301,536,294,547,290,548,276,544,274,527,288,525,299,514,297,515,313,505,306,504,320,541,322,553,316,559,307}
TP[5] = {767,240,770,246,799,245,798,261,804,275,816,279,818,287,827,284,841,289,842,296,850,297,851,302,860,306,860,355,886,400,878,456,884,465,896,400,866,351,871,311,865,296,829,276,814,273,802,257,802,239}
TP[6] = {670,238,670,249,689,248,708,259,723,257,735,247,731,238,718,238,703,218,684,222}
TP[7] = {794,216,790,220,809,219,824,233,823,248,816,251,818,261,851,280,882,287,892,299,891,307,882,316,881,335,899,365,908,405,906,429,893,463,895,475,915,423,914,394,905,362,890,337,897,295,885,282,855,274,831,258,831,236,823,220,810,214}
TD.layers[5] = { color={72,94,12}, ocol={72,94,12}, par=0.55, coll=0, hidden=0, polys={} }
TP = TD.layers[5].polys
TP[1] = {1674,1191,1657,1192,1653,1202,1645,1205,1638,1223,1544,1219,1540,1225,1674,1226}
TP[2] = {1052,1192,1059,1193,1060,1200,1069,1196,1079,1201,1080,1211,1085,1206,1093,1208,1094,1215,1103,1214,1108,1225,1111,1219,1125,1225,1136,1221,1152,1225,1140,1216,1138,1193,1130,1197,1136,1216,1128,1219,1072,1190}
TP[3] = {2484,1177,2484,1192,2478,1193,2484,1201,2478,1204,2484,1208,2484,1227,2489,1227,2495,1194}
TP[4] = {35,1153,35,1168,46,1175,46,1182,64,1184,61,1178,49,1173,54,1165}
TP[5] = {1908,1135,1907,1202,1914,1203,1913,1223,1951,1225,1953,1193,1965,1185,1964,1150,1956,1150,1956,1161,1939,1170,1924,1161,1916,1135}
TP[6] = {1378,1131,1361,1131,1362,1168,1393,1149,1364,1147,1366,1140,1380,1134}
TP[7] = {202,1131,201,1150,214,1152,216,1131}
TP[8] = {1827,1122,1836,1130,1839,1220,1839,1128}
TP[9] = {3012,1122,3006,1139,2992,1147,2998,1150,2998,1166,3002,1157,3007,1158,3008,1191,3022,1194,3023,1201,3034,1195,3038,1202,3052,1188,3051,1168,3047,1170,3045,1184,3020,1182,3022,1137,3081,1136,3084,1203,3078,1206,3065,1202,3066,1218,3076,1225,3106,1225,3105,1200,3098,1186,3099,1124,3093,1120}
TP[10] = {2471,1227,2471,1207,2439,1174,2439,1128,2425,1116,2417,1123,2402,1122,2401,1116,2354,1117,2354,1139,2319,1143,2317,1169,2305,1180,2287,1178,2279,1166,2244,1158,2238,1152,2225,1152,2218,1158,2219,1168,2215,1171,2218,1194,2201,1194,2188,1210,2188,1217,2197,1225}
TP[11] = {1881,1074,1856,1074,1882,1078,1882,1120,1858,1125,1858,1225,1861,1126,1885,1120,1885,1077}
TP[12] = {2498,1072,2472,1071,2472,1078,2479,1082,2480,1104,2472,1106,2472,1120,2479,1111,2511,1095,2505,1077}
TP[13] = {3018,1026,3022,1048,3064,1099,3120,1102,3119,1225,3164,1225,3160,1218,3165,1192,3164,1098,3152,1088,3136,1049,3063,1043,3063,1036,3075,1033,3076,1029,3128,1031,3129,1026,3056,1026,3044,1032}
TP[14] = {1691,1001,1680,999,1666,1008,1658,1002,1656,1013,1645,1011,1645,1018,1633,1024,1625,1019,1602,1027,1603,1044}
TP[15] = {1865,996,1863,1048,1838,1054,1840,1100,1866,1100,1841,1096,1841,1056,1862,1053,1866,1047}
TP[16] = {242,991,240,1091,225,1106,225,1184,228,1104,243,1093}
TP[17] = {739,957,737,975,728,978,727,990,734,994,743,1012,762,1009,768,961,764,957}
TP[18] = {1282,910,1282,967,1295,978,1299,1031,1299,981,1285,964}
TP[19] = {452,910,455,997,456,910}
TP[20] = {1907,881,1934,862,1907,863}
TP[21] = {2604,856,2600,854,2599,859,2549,897,2538,897,2523,887,2521,879,2528,863,2540,852,2537,840,2535,853,2522,855,2523,863,2508,880,2544,912,2591,866,2599,866}
TP[22] = {2654,838,2651,889,2678,929,2688,937,2740,942,2741,1021,2722,1019,2718,1005,2719,964,2674,962,2644,964,2644,970,2702,972,2706,1000,2701,1020,2684,1019,2683,1014,2668,1020,2648,1015,2626,1019,2622,1013,2622,1018,2472,1020,2476,1032,2497,1033,2526,1032,2526,1024,2536,1024,2540,1032,2555,1034,2581,1032,2583,1025,2602,1033,2599,1024,2617,1024,2618,1030,2610,1033,2640,1032,2641,1026,2648,1025,2665,1032,2664,1024,2675,1025,2676,1031,2694,1025,2698,1032,2699,1026,2704,1025,2705,1047,2700,1050,2705,1051,2709,1069,2633,1069,2630,1075,2617,1075,2609,1069,2534,1073,2540,1079,2540,1090,2547,1091,2545,1105,2551,1106,2548,1118,2554,1126,2549,1128,2550,1135,2562,1135,2572,1144,2582,1139,2583,1148,2603,1155,2603,1173,2614,1173,2616,1154,2626,1163,2648,1160,2660,1168,2671,1168,2673,1160,2681,1160,2681,1168,2691,1162,2708,1168,2718,1154,2731,1158,2728,1167,2742,1171,2792,1173,2793,1156,2787,1154,2787,1114,2792,1111,2793,1028,2787,1016,2793,984,2792,842,2706,838,2671,844}
TP[23] = {1040,741,1029,751,1007,756,1008,787,1000,793,1006,830,975,835,1009,856,1009,886,1004,890,1003,905,1083,905,1083,868,1079,864,1072,864,1072,871,1057,884,1044,884,1039,879,1042,828,1037,796,1046,747}
TP[24] = {340,731,336,733,337,781,354,794,354,870,337,886,337,905,340,887,357,872,357,793,340,779}
TP[25] = {1717,727,1715,904,1706,916,1662,939,1614,954,1605,967,1595,971,1592,980,1584,977,1566,986,1586,1029,1589,1025,1597,1026,1586,1014,1590,1008,1590,982,1612,970,1621,975,1625,964,1636,962,1637,956,1646,956,1654,949,1660,949,1661,955,1667,953,1671,941,1709,922,1715,923,1714,928,1705,932,1715,931,1717,983}
TP[26] = {2962,764,2955,749,2937,740,2944,727,2946,706,2935,705,2935,740,2885,744,2878,732,2873,744,2846,744,2849,752,2935,753,2939,756,2939,770,2928,771,2925,765,2927,776,2948,776}
TP[27] = {2158,694,2138,703,2136,710,2129,713,2131,722,2114,737,2151,776,2202,727,2213,725,2202,723,2189,730,2157,760,2140,758,2125,742,2132,719,2139,717,2142,704,2150,704}
TP[28] = {2424,696,2420,701,2402,701,2399,694,2311,695,2304,701,2275,694,2238,693,2230,715,2249,721,2283,718,2284,743,2270,755,2286,762,2284,782,2314,826,2323,833,2382,838,2380,904,2354,891,2359,868,2353,860,2296,862,2325,874,2325,893,2308,893,2303,889,2294,893,2098,894,2097,874,2071,864,2054,869,2054,881,2048,886,2050,912,1987,912,1985,859,1954,856,1954,881,1968,879,1968,872,1963,876,1957,874,1959,864,1975,866,1976,911,1922,913,1916,918,1916,968,1909,974,1916,1002,1908,1012,1913,1012,1923,1025,1955,1025,1957,1059,1907,1061,1907,1079,1914,1082,1915,1089,1979,1088,1984,1082,1987,1055,2028,1055,2033,1064,2049,1072,2095,1074,2097,987,2148,961,2153,962,2149,996,2153,1005,2165,1005,2161,1019,2174,1020,2184,1029,2195,1023,2197,1034,2207,1034,2208,1040,2217,1039,2218,1061,2230,1061,2232,1039,2237,1039,2243,1049,2260,1050,2268,1046,2269,1051,2276,1049,2281,1056,2293,1056,2295,1047,2303,1047,2304,1055,2317,1048,2333,1055,2344,1040,2359,1039,2355,1055,2364,1055,2369,1050,2369,1058,2426,1061,2426,1042,2420,1040,2420,996,2426,993,2426,896,2420,888,2426,863,2426,767,2422,765,2420,741}
TP[29] = {1665,683,1665,694,1656,695,1656,727,1665,724,1665,737,1656,740,1661,760,1667,757,1669,744,1677,744,1677,775,1663,771,1665,793,1656,794,1658,830,1674,830,1673,823,1679,822,1679,816,1671,815,1671,792,1679,789,1679,743,1671,737,1671,686}
TP[30] = {1579,764,1568,757,1563,746,1515,745,1514,707,1521,705,1523,716,1534,716,1534,700,1507,699,1505,754,1476,761,1474,788,1464,787,1457,775,1436,770,1433,761,1435,751,1440,750,1442,733,1480,731,1482,688,1478,683,1454,686,1457,705,1464,704,1462,692,1471,694,1471,718,1430,720,1425,725,1425,751,1404,760,1397,757,1395,724,1390,724,1390,742,1376,742,1373,752,1355,751,1347,744,1265,743,1259,751,1242,751,1237,743,1158,742,1156,719,1151,718,1151,696,1144,695,1143,704,1133,700,1112,741,1109,757,1115,769,1106,788,1118,794,1143,794,1148,784,1149,757,1156,757,1157,885,1150,888,1131,882,1126,897,1115,903,1129,906,1128,938,1114,927,1035,928,1028,946,1032,960,1030,1012,1017,1010,1023,990,1022,971,1015,971,1008,987,999,986,1002,951,992,979,967,980,952,989,953,1014,965,1027,995,1031,995,1041,982,1045,982,1055,991,1059,992,1097,954,1100,937,1133,935,1150,957,1130,984,1131,993,1136,992,1184,1011,1184,1011,1167,999,1167,998,1159,994,1158,996,1127,1010,1076,1006,1066,1012,1055,1009,1035,1026,1028,1032,1033,1032,1112,1039,1122,1127,1123,1128,1146,1121,1149,1121,1184,1158,1184,1158,1196,1174,1193,1165,1188,1167,1176,1172,1177,1173,1184,1185,1184,1184,1149,1179,1148,1177,1132,1171,1131,1170,1126,1184,1116,1185,1110,1190,1110,1191,1116,1203,1126,1195,1140,1200,1157,1191,1157,1193,1184,1200,1170,1224,1149,1230,1134,1239,1134,1239,1062,1234,1059,1232,1045,1240,1006,1240,910,1172,910,1173,879,1229,851,1243,854,1244,850,1284,850,1313,823,1321,823,1325,831,1320,842,1334,842,1335,849,1341,851,1341,868,1346,866,1347,859,1354,859,1355,866,1367,876,1358,889,1352,889,1360,895,1360,907,1378,899,1375,883,1394,878,1424,881,1435,886,1449,905,1469,906,1462,919,1432,921,1423,910,1394,910,1391,904,1384,904,1383,910,1369,910,1362,918,1362,973,1370,984,1362,1018,1362,1063,1368,1075,1361,1079,1366,1079,1369,1099,1363,1104,1411,1102,1411,1184,1438,1186,1440,1135,1596,1133,1599,1058,1595,1047,1550,1048,1546,1053,1545,1082,1549,1086,1571,1085,1570,1071,1565,1080,1556,1079,1557,1061,1583,1062,1582,1115,1544,1115,1537,1104,1464,1104,1457,1116,1444,1116,1439,1112,1439,1093,1432,1083,1384,1080,1384,1049,1390,1048,1390,1041,1396,1040,1398,1047,1405,1047,1406,1040,1419,1038,1424,1025,1437,1023,1440,1016,1483,1016,1484,1034,1469,1035,1463,1025,1461,1041,1491,1044,1495,1039,1493,1006,1446,1005,1444,981,1439,976,1426,975,1424,958,1414,951,1390,948,1387,935,1395,919,1406,918,1418,931,1463,931,1474,916,1487,912,1488,905,1496,907,1509,890,1534,885,1580,863,1580,814,1573,802}
TP[31] = {1714,652,1701,655,1697,649,1687,655,1691,662,1681,667,1680,673,1712,659}
TP[32] = {2138,648,2120,648,2112,653,2120,680,2126,677}
TP[33] = {884,645,888,660,915,660,915,647}
TP[34] = {405,616,400,692,368,694,364,661,359,726,355,727,358,735,364,736,361,719,377,717,382,732,393,734,390,749,405,756,404,767,416,766,416,782,407,784,400,831,402,851,388,860,387,798,388,788,393,784,387,783,386,768,390,765,377,741,370,743,380,754,382,768,380,799,371,800,372,814,379,816,379,830,374,833,380,834,380,846,372,847,372,865,377,866,377,871,367,878,370,885,361,905,368,905,383,873,392,876,385,910,386,1007,376,1013,375,1059,380,1071,352,1074,346,1080,356,1107,364,1108,363,1128,346,1132,346,1184,374,1184,375,1174,383,1176,384,1184,450,1184,458,1203,470,1205,474,1211,474,1220,463,1225,749,1225,755,1208,754,1184,800,1184,799,1202,807,1205,808,1184,942,1184,943,1177,934,1171,910,1174,910,1167,919,1160,915,1148,894,1152,890,1132,896,1129,901,1098,857,1054,858,1029,894,1029,908,1022,910,983,904,982,904,971,910,970,910,955,829,952,812,964,808,987,804,988,798,1007,811,1014,831,1013,833,1074,876,1114,875,1119,845,1107,827,1090,779,1092,775,1120,764,1133,748,1140,741,1157,736,1156,740,1138,725,1119,700,1124,706,1128,706,1135,681,1129,674,1150,660,1162,653,1189,632,1188,636,1160,626,1171,627,1189,463,1188,464,1170,478,1171,482,1167,473,1146,486,1143,463,1128,463,1112,445,1102,445,1091,469,1097,466,1085,474,1084,487,1108,494,1094,502,1092,505,1109,497,1112,510,1121,520,1109,518,1098,516,1109,509,1109,509,1094,523,1092,529,1113,554,1122,561,1110,554,1112,552,1103,559,1099,556,1088,565,1086,559,1070,566,1059,554,1063,457,1062,450,1049,451,1061,444,1062,441,1039,438,1062,425,1062,420,1056,423,1047,428,1048,431,1056,431,1037,436,1033,422,1018,422,979,412,974,415,957,421,954,418,906,450,905,451,783,438,776,438,768,444,765,447,771,450,756,441,751,441,736,451,733,451,669,447,662,431,657,426,648,405,643,406,628,411,627,411,616}
TP[35] = {1669,601,1664,601,1665,612,1659,620,1664,623,1660,633,1665,634,1665,647,1656,648,1663,669,1672,665,1678,633,1673,632}
TP[36] = {1170,587,1157,579,1025,646,1017,654,964,677,959,685,983,733,999,738,1151,661,1157,662,1159,675,1160,657,1167,647,1154,653,1130,653,1128,656,1138,657,1137,662,1127,667,1115,662,1102,672,1088,674,1096,682,1083,689,1077,688,1076,681,1062,690,1048,692,1040,700,1030,702,1024,717,990,711,986,700,989,684,980,687,981,700,976,701,970,682,990,675,991,680,1012,675,1029,664,1033,656,1052,655,1053,652,1042,650,1043,645,1062,639,1063,644,1055,648,1058,651,1062,645,1091,637,1115,616,1138,612,1155,603}
TP[37] = {1714,557,1682,568,1680,576,1684,581,1680,584,1690,580,1693,570,1710,571,1705,564}
TP[38] = {364,520,364,537,359,538,359,572,367,556,373,555,371,574,376,579,399,575,400,580,405,578,404,560,397,570,392,569,391,561,377,560,375,520}
TP[39] = {478,414,475,525,460,540,460,630,453,630,450,612,447,623,438,614,439,608,447,610,442,589,452,586,452,566,441,564,440,557,431,561,430,552,439,551,438,523,447,515,445,512,433,516,432,511,442,502,460,498,464,492,457,491,459,483,448,485,423,510,423,600,449,653,459,656,462,654,457,652,451,634,458,633,463,638,464,539,479,526}
TP[40] = {0,397,0,412,12,411,19,421,22,578,18,620,33,622,34,642,42,645,48,661,56,656,61,661,57,666,61,673,69,669,73,673,71,680,82,682,82,695,89,689,97,697,92,704,94,712,102,706,108,708,108,713,93,727,71,730,72,734,83,734,76,745,64,738,63,729,54,728,41,715,45,710,41,705,35,709,37,721,32,722,35,753,44,758,45,783,50,784,45,789,49,815,48,909,35,910,35,1139,62,1157,63,1164,83,1184,159,1184,163,1173,195,1168,195,1142,191,1140,188,1119,171,1117,171,1093,175,1090,129,1085,128,1075,120,1073,105,1080,92,1080,91,1076,80,1074,77,1061,83,1050,108,1038,142,1047,154,1025,166,1027,186,1019,195,1023,196,934,188,929,188,910,76,909,76,756,70,749,81,749,118,709,34,625,34,600,46,590,56,555,38,531,38,522,45,518,51,466,44,458,47,450,40,430,33,427,33,398}
TP[41] = {408,378,400,378,399,388,370,388,364,392,364,409,359,410,359,447,367,447,367,440,363,439,367,431,378,432,376,447,370,450,368,475,380,474,380,513,386,521,407,517,408,464,433,464,435,450,447,448,447,408,421,405,419,396,412,395}
TP[42] = {2514,355,2521,367,2537,358,2564,362,2561,380,2552,383,2549,401,2536,415,2540,433,2534,434,2534,449,2548,458,2547,463,2537,468,2537,482,2546,487,2555,507,2548,526,2565,531,2572,551,2579,552,2593,547,2600,523,2608,527,2665,523,2668,529,2642,636,2636,636,2635,624,2630,619,2587,620,2585,638,2589,639,2591,650,2610,649,2608,636,2600,637,2601,645,2593,645,2594,630,2621,632,2621,668,2582,670,2581,675,2532,670,2525,650,2490,646,2484,596,2491,585,2582,587,2582,594,2564,596,2566,609,2589,610,2606,595,2598,581,2582,572,2533,577,2528,532,2510,532,2509,537,2525,539,2525,575,2484,577,2478,584,2479,659,2507,662,2511,668,2510,681,2505,691,2472,693,2472,704,2468,705,2471,712,2501,715,2506,731,2521,735,2522,743,2526,744,2522,759,2531,759,2533,736,2539,734,2545,711,2545,696,2534,696,2534,689,2561,687,2581,701,2608,701,2607,695,2600,692,2601,687,2624,687,2628,696,2609,764,2609,779,2625,779,2629,785,2637,781,2639,787,2686,787,2696,778,2741,778,2750,787,2792,787,2793,624,2787,603,2793,576,2793,535,2810,518,2816,503,2827,502,2823,493,2845,482,2840,475,2829,485,2820,485,2822,476,2845,468,2845,461,2829,462,2808,472,2805,458,2845,419,2846,411,2871,400,2883,400,2898,408,2909,430,2951,429,2956,445,2949,488,2906,490,2864,503,2846,503,2846,511,2867,512,2873,521,2873,539,2902,544,2901,554,2886,569,2892,589,2884,592,2886,603,2901,615,2900,621,2890,624,2889,640,2904,653,2920,657,2917,669,2927,671,2928,683,2955,681,2967,687,3030,685,3032,699,3004,812,2996,809,2995,795,2990,789,2948,791,2944,795,2943,824,2965,825,2968,821,2967,808,2957,807,2961,817,2950,816,2951,800,2980,801,2978,844,2886,843,2880,822,2846,820,2846,837,2857,840,2857,865,2846,867,2846,890,2868,892,2864,897,2868,919,2860,943,2868,937,2883,941,2885,932,2893,927,2897,888,2883,898,2878,897,2885,864,2919,863,2936,876,2957,874,2965,878,2967,874,2958,868,2959,863,2987,862,2985,890,2964,955,2967,963,2997,970,3051,970,3059,961,3112,961,3120,970,3165,970,3165,785,3159,776,3165,747,3165,699,3173,686,3191,678,3186,671,3195,669,3202,661,3198,653,3219,643,3219,634,3215,634,3205,644,3195,644,3196,635,3215,627,3219,616,3189,618,3185,627,3179,622,3179,616,3219,576,3219,320,3102,320,3106,336,3113,340,3106,363,3089,376,3059,377,3051,396,3053,403,3047,408,3055,413,3064,450,3070,450,3071,456,3077,450,3083,451,3079,461,3084,462,3084,472,3078,479,3075,505,3064,512,3047,500,3035,507,3019,503,3008,507,3005,490,2971,479,2963,459,2960,425,2950,421,2914,421,2909,412,2915,392,2928,394,2931,401,2941,401,2948,407,2954,396,2963,395,2965,386,2995,391,2996,383,3023,380,3024,374,3040,367,3042,348,3057,346,3053,335,3059,331,3060,323,3069,320,2741,320,2741,326,2726,330,2722,341,2710,348,2700,363,2684,352,2673,360,2654,358,2646,376,2609,361,2610,320,2595,320,2593,342,2575,348,2543,346}
TP[43] = {2458,326,2447,320,2438,332,2437,347,2432,348,2428,334,2432,323,2441,320,2179,320,2172,330,2177,368,2168,383,2181,385,2190,395,2190,405,2141,407,2139,368,2131,362,2132,405,2098,408,2098,417,2195,417,2196,426,2177,426,2178,446,2185,460,2177,474,2195,473,2201,490,2221,491,2227,488,2227,473,2215,473,2215,481,2210,482,2209,468,2236,466,2237,509,2196,510,2195,516,2150,518,2149,511,2139,509,2134,488,2096,485,2097,472,2089,471,1906,472,1902,479,1907,479,1908,484,1916,480,1917,487,1932,487,1932,479,1944,479,1948,487,1975,486,1976,479,1992,479,1993,487,2019,487,2017,479,2030,479,2031,488,2048,486,2049,480,2069,480,2070,486,2074,486,2075,479,2086,479,2087,488,2098,489,2098,502,2115,503,2115,534,2022,537,2020,541,2013,537,1991,537,1980,544,1908,537,1908,593,1900,632,1910,642,1916,670,1921,657,1928,660,1927,681,1920,682,1920,696,1928,693,1928,708,1920,711,1919,731,1920,743,1928,741,1928,758,1919,757,1918,782,1927,778,1928,783,1920,791,1910,793,1902,811,1911,809,1934,787,1934,730,1941,702,1934,686,1934,659,1906,630,1906,615,1919,590,1999,551,2005,552,2000,562,1999,592,2004,596,2003,603,2017,603,2013,618,2028,620,2039,630,2052,624,2054,636,2067,637,2068,643,2078,642,2079,669,2093,669,2100,581,2106,582,2106,596,2124,614,2124,623,2128,624,2125,635,2138,631,2138,616,2151,605,2160,560,2152,555,2134,559,2140,528,2174,527,2194,543,2217,541,2225,545,2221,536,2190,535,2188,528,2254,529,2232,625,2234,633,2263,639,2309,639,2318,629,2372,629,2381,639,2426,638,2426,449,2420,442,2426,411,2426,367,2434,349,2445,343,2450,331,2457,333}
TP[44] = {1914,320,1921,332,1937,335,1980,329,1993,334,2002,349,2022,338,2042,339,2047,344,2050,375,2076,403,2097,405,2097,386,2084,385,2065,363,2068,356,2078,356,2086,365,2097,363,2097,320,2026,320,2016,336,2000,340,1984,321}
TP[45] = {1874,320,1868,336,1854,346,1854,472,1856,350,1872,336}
TP[46] = {1337,261,1325,261,1324,371,1326,266,1344,267,1350,283,1349,267}
TP[47] = {1344,158,1343,253,1358,263,1361,272,1361,339,1356,349,1343,357,1346,481,1346,362,1364,343,1364,266,1346,250}
TP[48] = {921,140,919,160,931,164,936,142,924,146}
TP[49] = {1674,79,1660,82,1657,77,1645,77,1628,86,1618,85,1593,94,1591,103,1584,108,1578,108,1578,99,1573,97,1565,105,1545,105,1534,113,1521,103,1497,105,1485,99,1476,100,1464,96,1456,87,1444,86,1437,95,1429,128,1422,132,1424,148,1418,151,1417,190,1390,199,1397,202,1398,223,1397,241,1391,242,1390,393,1395,396,1393,423,1402,434,1402,449,1393,453,1390,471,1394,475,1390,524,1400,527,1400,543,1388,546,1390,653,1399,654,1400,658,1407,657,1412,639,1448,632,1456,635,1458,647,1467,657,1515,656,1520,645,1529,642,1563,645,1572,635,1569,616,1574,612,1573,602,1588,589,1585,571,1600,525,1590,512,1607,506,1637,506,1632,481,1672,477,1679,457,1679,423,1674,421,1673,410,1664,398,1671,392,1679,358,1679,87}
TP[50] = {1383,0,1368,0,1365,68,1344,68,1347,54,1343,60,1332,60,1325,50,1312,52,1311,36,1296,36,1296,55,1284,56,1279,40,1240,40,1239,24,1212,24,1211,40,1184,40,1184,47,1178,48,1177,32,1183,28,1176,18,1198,7,1207,7,1214,0,1157,0,1156,43,1150,57,1141,57,1139,26,1146,0,840,0,839,16,847,18,860,46,872,44,875,61,893,67,907,64,911,131,1014,134,1014,143,1009,144,1013,207,1004,208,1008,222,1023,222,1031,215,1025,202,1036,199,1044,177,1047,135,1067,133,1069,205,1100,210,1099,218,1088,218,1085,223,1098,224,1098,237,1115,238,1115,263,1149,262,1149,300,1140,297,1132,304,1127,299,1127,309,1117,311,1115,300,1107,291,1100,291,1097,300,1086,301,1063,293,1055,303,1048,303,1047,314,1023,318,1014,313,1001,329,984,329,978,324,969,333,945,326,939,332,918,329,912,333,908,328,906,338,910,343,898,347,915,392,917,419,904,463,894,468,895,481,882,474,882,466,876,461,885,400,877,395,874,382,858,380,862,392,859,403,870,409,871,415,859,422,863,448,852,447,849,459,855,464,855,472,867,466,879,470,878,476,862,477,862,490,871,486,893,487,897,481,908,478,909,467,917,467,927,483,920,498,940,499,941,507,936,509,939,516,951,519,952,523,964,514,970,516,971,554,987,562,984,615,991,615,992,619,1012,615,1013,586,1003,580,1004,575,1018,576,1020,596,1081,595,1090,587,1092,560,1149,559,1151,550,1159,550,1156,532,1129,531,1127,517,1137,512,1139,495,1153,500,1150,518,1156,522,1156,317,1149,307,1150,301,1159,299,1156,247,1145,241,1145,216,1127,215,1128,210,1160,212,1156,208,1153,129,1161,128,1162,134,1175,137,1177,133,1168,134,1167,129,1176,121,1186,125,1201,110,1189,111,1197,99,1202,100,1202,108,1213,103,1204,97,1205,92,1215,93,1216,98,1224,93,1225,99,1239,103,1244,101,1236,97,1237,92,1252,92,1252,103,1272,99,1271,88,1277,87,1279,99,1288,103,1288,97,1294,96,1302,109,1318,108,1327,113,1324,120,1346,128,1356,137,1364,131,1372,135,1365,143,1374,143,1372,136,1389,128}
TP[51] = {519,8,542,30,564,26,574,31,576,27,567,20,536,20,533,13,602,13,610,0,520,0}
TP[52] = {51,100,28,149,31,162,17,185,17,191,24,187,27,193,18,199,17,207,29,207,33,229,53,240,50,340,57,347,55,358,60,366,55,374,65,405,107,404,123,408,133,415,136,426,134,434,96,435,89,454,95,479,82,486,80,497,105,502,113,527,155,537,160,546,161,569,169,574,198,575,221,582,225,561,225,346,221,341,227,338,217,337,218,325,226,324,224,216,217,203,224,173,224,132,233,131,239,119,255,107,256,103,249,102,251,93,259,95,269,68,282,61,270,59,274,50,294,51,295,57,302,52,310,60,308,50,326,50,338,63,336,71,357,70,360,86,367,90,367,105,359,109,359,297,370,302,370,309,366,310,372,314,370,324,380,321,384,327,415,327,415,322,392,324,394,311,431,311,431,298,436,295,459,294,461,290,491,291,506,285,507,294,488,310,498,320,497,328,474,337,482,370,464,383,452,383,451,389,513,381,516,372,521,373,524,381,580,382,581,389,596,398,596,405,590,406,582,396,579,400,601,409,613,421,639,427,654,441,675,448,698,464,724,469,738,484,790,509,803,511,812,526,817,521,813,507,829,514,820,532,813,532,799,544,786,544,767,531,742,524,734,515,730,515,732,524,726,525,717,516,728,512,684,488,660,483,646,469,634,468,620,479,626,483,626,489,621,490,617,484,572,531,579,534,572,541,585,545,586,638,593,641,593,689,586,695,585,758,590,760,601,742,622,739,647,760,647,775,631,788,619,791,599,787,593,782,591,770,588,789,593,792,593,819,586,827,587,878,591,878,592,871,621,873,612,905,653,905,661,900,664,905,694,903,697,912,550,913,548,931,541,932,539,950,549,946,548,961,539,962,539,996,549,992,549,1007,540,1008,541,1033,544,1027,549,1028,549,1036,563,1032,565,1021,555,1008,555,994,559,990,557,977,565,976,567,1008,578,1019,578,1048,588,1038,604,1037,609,1031,607,1023,694,935,706,934,698,929,700,921,726,922,730,926,744,920,801,920,802,931,790,933,788,939,775,934,777,943,792,942,797,934,824,934,815,928,817,920,855,920,858,927,853,935,869,935,868,920,969,920,968,929,961,931,959,939,945,936,946,942,961,942,965,934,976,934,978,922,994,921,990,914,961,913,962,905,983,905,983,896,903,896,896,900,901,905,958,905,958,914,835,914,835,905,858,905,857,896,851,900,822,897,818,905,831,905,831,913,715,914,714,906,719,902,683,867,673,867,661,854,644,848,643,829,651,829,651,821,660,813,662,804,655,801,657,766,647,748,639,744,643,737,633,726,640,725,651,733,651,724,655,723,657,668,663,669,665,716,705,720,705,801,691,810,693,820,665,821,690,830,731,826,737,753,887,754,893,748,894,694,911,693,911,680,895,680,889,667,846,667,840,675,840,703,876,703,877,733,839,734,836,725,826,723,834,728,834,733,822,735,820,723,761,722,753,734,736,734,734,710,724,700,678,698,680,639,701,635,732,641,735,634,778,634,780,653,763,654,758,644,756,660,787,662,787,625,740,625,737,597,716,595,715,612,723,611,720,601,730,602,730,623,664,622,662,665,657,666,656,553,662,523,638,516,623,530,603,527,624,501,633,501,637,490,643,489,734,535,761,556,781,559,809,572,839,514,837,509,756,469,743,467,734,458,638,410,639,405,655,402,656,384,660,381,757,382,795,378,799,370,801,316,853,315,855,337,846,338,845,332,840,331,836,340,857,340,859,334,857,308,849,303,819,306,816,282,810,279,807,298,783,298,777,304,776,352,744,350,744,308,738,307,738,300,744,298,744,278,748,274,781,273,784,248,775,247,772,262,731,262,728,293,715,295,713,302,707,302,710,317,728,326,726,353,659,353,646,338,616,277,608,240,615,239,622,246,643,247,642,216,647,207,670,206,675,193,703,193,704,183,719,183,723,187,731,155,741,149,746,138,745,127,729,97,715,97,712,108,685,109,683,100,648,93,630,96,614,90,578,91,575,69,560,44,546,48,531,61,509,60,491,48,476,47,475,15,487,9,490,0,450,0,450,18,445,23,414,21,408,12,414,0,177,0,180,43,186,55,206,60,249,59,257,56,258,44,264,44,264,55,229,123,221,118,225,97,233,84,229,67,221,69,221,75,211,82,206,78,194,80,182,90,177,90,175,84,151,78,133,85,132,79,125,77,119,89,114,89,108,80,76,83,67,95}
TD.layers[6] = { color={28,41,9}, ocol={28,41,9}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[6].polys
TP[1] = {4128,1320,4118,1334,4148,1362,4142,1339,4128,1327}
TP[2] = {4358,1114,4348,1114,4354,1120,4353,1126,4342,1121,4342,1114,4331,1115,4322,1153,4316,1157,4319,1178,4323,1178,4323,1170,4333,1155,4359,1155,4370,1166}
TP[3] = {3660,939,3651,975,3646,979,3649,999,3661,978,3674,977,3663,974,3664,965,3681,965,3696,993,3699,979,3694,976,3685,940}
TP[4] = {2438,933,2356,940,2356,983,2349,1004,2354,1009,2356,1050,2416,1050,2416,996,2439,993}
TP[5] = {3937,915,3917,925,3916,938,3902,961,3886,1029,3882,1118,3878,1130,3881,1323,3876,1325,3881,1328,3878,1338,3885,1349,3884,1365,3879,1366,3878,1400,3879,1405,3886,1406,3886,1413,3878,1412,3878,1488,4082,1488,4073,1483,4073,1408,4079,1407,4080,1402,4079,1392,4073,1389,4071,1342,4078,1325,4073,1307,4073,1217,4079,1212,4071,1211,4075,1200,4069,1157,4073,1154,4075,1117,4068,1070,4068,980,4055,978,4005,926,3989,917}
TP[6] = {4479,912,4458,928,4446,946,4444,959,4433,965,4433,951,4426,965,4426,1010,4420,1035,4426,1048,4426,1233,4380,1234,4372,1225,4319,1225,4311,1234,4257,1234,4237,1229,4236,1233,4190,1235,4191,1264,4146,1306,4148,1316,4157,1321,4156,1338,4161,1328,4166,1327,4168,1340,4173,1340,4178,1348,4238,1286,4274,1286,4296,1294,4312,1288,4389,1288,4389,1295,4326,1297,4323,1307,4397,1311,4409,1344,4426,1363,4426,1455,4420,1475,4425,1488,4479,1488}
TP[7] = {1368,902,1447,905,1435,887,1408,879,1375,884,1372,888,1380,892,1380,897}
TP[8] = {4479,842,4440,879,4441,891,4448,880,4479,878}
TP[9] = {2980,779,2969,819,2964,823,2967,845,2981,822,3007,823,3018,843,3022,823,3017,821,3006,779}
TP[10] = {3296,754,3276,764,3273,782,3262,799,3252,848,3253,938,3241,1055,3243,1266,3239,1347,3243,1357,3235,1359,3240,1372,3239,1395,3246,1402,3246,1413,3240,1414,3236,1457,3240,1488,3434,1488,3429,1426,3415,1418,3412,1407,3421,1404,3425,1367,3417,1357,3423,1335,3456,1333,3449,1327,3451,1320,3442,1314,3442,1307,3457,1315,3465,1308,3468,1316,3477,1321,3476,1337,3482,1327,3487,1328,3488,1334,3563,1331,3571,1337,3584,1337,3587,1331,3663,1331,3663,1325,3651,1324,3650,1296,3643,1293,3509,1298,3421,1297,3412,1292,3421,1277,3421,1211,3426,1210,3418,1206,3422,1135,3416,1106,3417,981,3421,977,3417,817,3399,810,3388,794,3349,759,3334,753}
TP[11] = {3799,751,3778,766,3766,784,3763,798,3753,800,3757,788,3748,798,3748,839,3742,866,3748,887,3748,1049,3704,1051,3695,1042,3650,1042,3640,1051,3593,1051,3573,1046,3572,1050,3528,1052,3527,1075,3477,1137,3478,1150,3493,1160,3503,1159,3553,1117,3561,1120,3563,1108,3575,1098,3602,1098,3625,1106,3660,1100,3722,1101,3726,1106,3746,1106,3748,1247,3742,1279,3746,1280,3748,1300,3742,1416,3747,1418,3747,1436,3708,1437,3680,1431,3673,1437,3632,1437,3630,1394,3636,1388,3635,1375,3642,1371,3632,1363,3632,1358,3626,1358,3626,1363,3616,1371,3622,1375,3622,1388,3627,1395,3626,1436,3616,1437,3613,1431,3603,1431,3602,1435,3594,1431,3588,1435,3584,1431,3583,1435,3575,1432,3573,1437,3507,1437,3502,1488,3589,1483,3799,1488}
TP[12] = {3799,685,3760,721,3762,738,3768,730,3782,724,3799,723}
TP[13] = {3119,584,3107,589,3105,599,3094,611,3093,623,3083,628,3083,613,3075,630,3075,676,3069,698,3075,712,3075,901,3029,903,3020,893,2966,893,2957,903,2911,903,2887,897,2870,903,2835,903,2834,928,2815,951,2808,951,2807,959,2794,959,2792,975,2774,998,2778,1011,2803,1023,2861,975,2870,979,2870,971,2886,955,2923,956,2952,963,2959,957,3047,956,3050,963,3070,964,3075,1028,3075,1126,3069,1148,3074,1149,3075,1256,3069,1259,3069,1282,3073,1283,3069,1288,3073,1298,3069,1302,3075,1305,3075,1324,3031,1325,3001,1319,2993,1325,2948,1325,2946,1278,2952,1271,2952,1256,2959,1253,2948,1244,2948,1239,2942,1239,2942,1244,2931,1253,2937,1256,2937,1271,2943,1278,2941,1325,2931,1325,2929,1320,2921,1323,2920,1319,2916,1323,2900,1323,2896,1319,2895,1323,2885,1320,2883,1325,2810,1327,2809,1340,2814,1341,2814,1354,2821,1355,2819,1368,2825,1369,2820,1383,2826,1384,2820,1393,2823,1401,2812,1406,2810,1426,2862,1426,2864,1378,3049,1378,3053,1385,3065,1385,3073,1378,3088,1391,3088,1437,3119,1468}
TP[14] = {2558,583,2550,611,2540,621,2526,695,2534,762,2529,789,2534,866,2520,920,2523,1112,2520,1214,2514,1240,2520,1257,2520,1320,2514,1356,2518,1348,2524,1349,2520,1384,2534,1398,2535,1413,2521,1414,2521,1405,2528,1409,2527,1400,2517,1402,2515,1413,2509,1412,2509,1406,2504,1407,2502,1414,2484,1423,2466,1425,2440,1443,2440,1482,2466,1474,2477,1463,2489,1462,2499,1472,2502,1488,2718,1488,2719,1445,2708,1448,2706,1442,2715,1438,2726,1422,2731,1383,2726,1365,2729,1337,2723,1314,2708,1300,2708,1292,2717,1289,2718,1211,2751,1210,2781,1217,2791,1210,2879,1209,2882,1216,2895,1216,2901,1209,2983,1209,2983,1205,2969,1202,2971,1183,2965,1169,2875,1173,2842,1169,2814,1174,2777,1170,2715,1172,2708,1167,2718,1143,2717,1077,2721,1076,2712,926,2713,829,2720,795,2715,742,2715,656,2709,644,2690,633,2687,623,2659,600,2653,588,2642,583}
TP[15] = {2328,583,2342,599,2360,585}
TP[16] = {2022,583,2017,622,2021,679,2017,807,2010,844,2017,854,2017,932,2011,964,2016,967,2018,1004,2026,1006,2030,1016,1976,1048,1956,1050,1929,1071,1907,1077,1893,1089,1868,1095,1864,1102,1849,1110,1829,1115,1819,1126,1798,1132,1775,1149,1754,1150,1726,1171,1709,1173,1689,1189,1675,1190,1647,1210,1633,1211,1621,1223,1620,1241,1632,1256,1638,1256,1657,1244,1673,1242,1695,1226,1717,1223,1718,1230,1722,1230,1718,1221,1731,1209,1755,1198,1763,1188,1793,1178,1807,1166,1827,1164,1851,1146,1879,1137,1898,1124,1918,1122,1938,1105,1955,1103,1970,1091,1981,1091,1999,1110,1999,1126,2012,1141,2018,1163,2031,1179,2029,1191,2017,1191,2018,1292,2024,1299,2024,1312,2018,1317,2020,1350,2016,1360,2021,1365,2015,1367,2010,1387,2017,1403,2017,1488,2248,1488,2249,1398,2255,1396,2251,1392,2255,1386,2251,1381,2255,1374,2251,1362,2256,1354,2255,1345,2248,1342,2248,1286,2253,1284,2251,1274,2255,1273,2251,1269,2251,1262,2255,1261,2251,1250,2255,1245,2250,1244,2255,1233,2248,1230,2245,1169,2248,1075,2237,1076,2235,1068,2246,1064,2261,1038,2259,934,2254,917,2242,911,2236,901,2248,867,2249,800,2281,799,2322,806,2333,799,2436,798,2439,752,2423,753,2402,747,2378,752,2247,752,2238,748,2237,742,2247,737,2248,719,2247,644,2252,641,2247,632,2251,627,2247,622,2247,583}
TP[17] = {0,412,0,905,47,905,48,815,44,789,49,788,51,780,44,772,43,758,35,757,31,722,36,713,27,699,43,703,58,726,70,729,86,727,92,707,81,695,80,687,29,644,26,630,33,624,17,620,21,575,20,461,15,445,18,424,14,414}
TP[18] = {517,333,513,382,483,380,482,387,452,391,452,483,463,483,466,492,453,502,448,515,439,523,440,563,453,566,452,576,447,575,447,570,441,571,441,582,453,582,450,589,442,589,454,628,464,631,464,655,452,654,452,733,444,737,444,751,451,756,454,802,452,959,445,961,444,977,452,983,451,1039,445,1061,451,1067,452,1080,451,1185,445,1187,444,1202,452,1209,454,1251,470,1268,478,1266,480,1277,489,1277,491,1287,499,1292,510,1288,502,1285,503,1276,515,1281,515,1292,537,1289,538,1277,543,1276,543,1292,547,1292,551,1270,556,1271,559,1292,572,1292,573,1283,568,1281,567,1146,574,1136,584,1132,668,1131,716,1136,843,1132,854,1136,872,1132,946,1136,1015,1133,1024,1148,1082,1119,1112,1111,1115,1102,1159,1080,1204,1081,1231,1088,1245,1081,1269,1081,1270,1236,1262,1275,1264,1289,1269,1292,1269,1363,1260,1363,1256,1377,1220,1411,1219,1388,1228,1388,1225,1362,1234,1357,1220,1346,1220,1341,1214,1341,1214,1346,1200,1356,1209,1368,1207,1378,1213,1379,1213,1434,1207,1440,1158,1441,1160,1488,1448,1488,1442,1481,1412,1472,1400,1460,1386,1459,1378,1450,1379,1444,1401,1448,1389,1442,1390,1248,1398,1214,1390,1203,1390,1148,1397,1143,1397,1094,1390,1090,1388,1066,1379,1063,1377,1056,1413,1030,1434,1028,1459,1008,1481,1003,1501,988,1516,987,1544,967,1557,966,1577,948,1599,946,1632,923,1648,920,1658,912,1659,905,1684,903,1767,854,1766,799,1761,794,1730,803,1675,836,1658,834,1654,787,1660,766,1668,766,1670,759,1660,765,1655,744,1655,688,1659,683,1655,642,1659,625,1654,615,1658,602,1669,600,1670,596,1581,596,1581,642,1575,644,1578,654,1574,655,1578,659,1574,666,1578,671,1578,678,1574,679,1578,691,1574,694,1581,697,1581,761,1573,797,1581,814,1581,863,1534,886,1509,891,1500,910,1488,910,1387,961,1359,961,1352,952,1352,915,1360,897,1367,896,1367,891,1358,894,1359,881,1368,877,1358,870,1354,860,1346,860,1346,867,1340,868,1337,859,1342,855,1336,850,1340,843,1320,843,1319,838,1329,831,1323,831,1321,824,1313,824,1284,853,1229,852,1176,877,1172,905,1348,905,1347,953,1305,953,1295,961,1160,961,1107,992,1027,1028,1020,1034,1023,1044,1007,1049,725,1050,647,1017,593,983,581,983,572,971,572,965,584,959,584,906,610,905,619,876,586,871,585,827,592,819,592,792,587,791,591,782,584,781,585,695,592,689,592,641,585,638,584,545,574,544,569,533,633,467,646,468,660,482,684,487,732,512,742,523,767,530,786,543,804,541,812,527,803,512,790,510,738,485,724,470,698,465,675,449,652,441,639,428,613,422,601,410,586,407,577,396,577,389,584,384,524,382,519,372}
TP[19] = {1388,129,1382,130,1381,145,1363,144,1350,132,1319,122,1307,110,1291,108,1276,99,1255,104,1210,104,1175,138,1164,137,1158,130,1157,211,1150,216,1150,228,1158,235,1157,550,1150,552,1150,567,1158,571,1160,581,1167,583,1170,591,1144,612,1121,615,1095,636,1065,646,1052,656,1034,658,1014,675,994,681,987,696,992,709,1022,712,1030,701,1048,691,1062,689,1164,638,1169,647,1162,654,1158,678,1158,741,1237,742,1242,750,1259,750,1265,742,1347,743,1355,750,1373,751,1376,741,1389,740,1389,707,1394,706,1392,696,1396,695,1391,691,1391,685,1396,684,1392,679,1392,672,1396,671,1392,659,1396,655,1389,653,1389,546,1396,544,1396,527,1389,524,1389,471,1395,436,1389,428,1386,344,1389,242,1395,240,1392,231,1396,225,1392,220,1396,213,1392,207,1396,206,1397,198,1392,197,1395,189,1389,187}
TP[20] = {302,56,271,68,262,97,250,112,242,134,233,136,229,128,225,132,225,173,218,207,225,216,226,324,219,325,218,342,226,346,229,632,226,727,221,728,223,738,218,739,222,745,218,756,223,757,223,762,218,763,218,769,223,770,219,780,225,782,226,919,219,950,225,953,226,993,234,995,234,1004,219,1023,205,1030,187,1055,174,1061,168,1073,168,1088,191,1097,204,1082,216,1076,222,1063,237,1061,236,1069,224,1078,230,1095,229,1113,219,1121,223,1131,219,1132,218,1159,226,1163,228,1225,225,1414,359,1414,361,1345,352,1341,351,1336,360,1332,342,1328,345,1319,339,1310,344,1309,340,1295,346,1294,344,1281,351,1280,350,1268,357,1267,358,983,366,977,366,967,358,961,358,921,347,921,347,906,365,884,363,876,371,864,370,841,374,830,370,806,374,785,365,782,367,749,356,745,347,731,348,724,358,724,359,677,365,657,359,651,356,439,358,344,365,317,358,298,358,109,366,105,366,90,359,86,357,72,352,71,352,78,346,80,323,62}
TP[21] = {1177,18,1178,47,1183,47,1184,39,1211,39,1212,23,1219,23,1220,29,1239,23,1240,39,1279,39,1284,55,1295,55,1296,43,1311,43,1312,55,1304,56,1304,61,1319,63,1317,50,1325,49,1344,67,1365,67,1367,0,1215,0,1196,9,1195,14}
TRACE_DEFS["forest"] = TD
TD = { base={94,249,254}, spanx2=4779, spany2=678, frw=1680, frh=910, refx=840, refy=455, layers={},
  conf={ spawn={80,550}, cps={{80,550}, {2780,260}, {5716,560}}, goal={5716,500}, kill=1500 } }
TD.layers[1] = { color={206,250,252}, ocol={206,250,252}, par=0.1, coll=0, hidden=0, polys={} }
TP = TD.layers[1].polys
TP[1] = {622,84,622,112,637,114,656,127,664,163,675,163,683,149,686,122,693,114,715,110,728,118,752,112,752,90,742,90,735,102,684,104,666,98,665,94,639,96,625,82}
TP[2] = {2073,28,2073,159,2081,160,2085,175,2106,189,2117,205,2138,207,2140,85,2156,84,2156,67,2140,66,2140,28}
TP[3] = {1474,8,1473,91,1489,91,1496,79,1527,79,1532,89,1545,91,1558,103,1567,103,1586,87,1607,87,1612,91,1623,87,1624,105,1632,120,1630,137,1648,136,1642,149,1648,152,1652,163,1665,159,1679,135,1680,75,1703,77,1720,85,1738,79,1736,64,1724,54,1723,41,1716,30,1717,25,1725,22,1726,15,1748,14,1748,111,1784,101,1785,97,1790,98,1790,104,1785,105,1787,110,1793,104,1795,90,1804,90,1810,81,1812,63,1834,60,1866,41,1869,139,1862,143,1869,144,1869,178,1873,171,1901,172,1899,207,1869,216,1873,228,1880,228,1885,234,1907,213,1920,213,1925,234,1934,235,1936,220,1931,220,1930,214,1936,211,1937,133,1994,133,2004,140,2004,28,1869,28,1869,39,1864,40,1858,28,1816,28,1815,0,1680,0,1679,8,1664,8,1663,0,1479,0,1479,7}
TP[4] = {1299,0,1299,33,1315,29,1322,36,1329,63,1343,49,1349,32,1356,29,1382,31,1390,47,1409,63,1409,0}
TP[5] = {1098,0,1098,34,1109,41,1109,50,1141,66,1157,63,1163,69,1163,77,1192,92,1197,90,1205,62,1235,49,1236,0,1191,0,1190,11,1221,11,1222,19,1232,20,1233,31,1223,37,1204,34,1191,24,1179,22,1167,14,1167,8,1143,7,1143,1,1151,0}
TP[6] = {886,0,888,108,927,115,975,107,976,111,985,107,1000,111,1022,107,1022,0,950,0,925,23,920,23,915,12,903,6,903,0}
TP[7] = {819,0,809,0,810,82,819,80}
TP[8] = {730,0,738,14,740,35,751,49,752,0}
TP[9] = {622,17,635,16,640,9,652,7,653,0,623,0}
TP[10] = {408,0,411,15,439,15,442,0}
TP[11] = {244,0,244,10,270,11,272,0}
TP[12] = {58,0,32,0,31,6,0,10,0,21,21,22,35,14,42,2,57,4}
TD.layers[2] = { color={97,205,246}, ocol={97,205,246}, par=0.22, coll=0, hidden=0, polys={} }
TP = TD.layers[2].polys
TP[1] = {1054,1052,1501,1054,1501,1027,1068,1029}
TP[2] = {1941,971,1941,1054,2003,1054,2003,971}
TP[3] = {1771,971,1771,1054,1883,1054,1883,971}
TP[4] = {1560,1029,1560,1054,1713,1054,1713,971,1599,971,1617,1028}
TP[5] = {1141,900,1142,905,1180,905,1176,898}
TP[6] = {2115,887,2096,887,2096,970,2046,971,2046,1054,2109,1054,2109,969,2116,968}
TP[7] = {192,903,165,851,155,850,126,868,110,888,103,906}
TP[8] = {2395,813,2395,824,2383,826,2380,831,2380,932,2393,967,2445,968,2446,821,2440,813}
TP[9] = {894,796,882,809,876,834,872,836,871,905,988,905,988,838,974,804,966,796,931,792}
TP[10] = {625,784,572,784,559,800,536,806,520,816,492,848,488,881,479,899,280,896,280,905,625,905}
TP[11] = {758,796,746,810,738,836,737,905,852,905,852,838,838,804,829,796,812,796,809,787,797,777,788,778,783,785}
TP[12] = {1025,800,1014,817,1012,834,1007,840,1008,905,1122,905,1121,898,1088,895,1087,790,1063,776}
TP[13] = {1450,754,1441,761,1440,777,1428,780,1430,794,1440,808,1459,814,1461,845,1492,848,1493,806,1488,799,1492,798,1493,774,1487,760,1482,756}
TP[14] = {1518,742,1510,758,1512,769,1505,778,1509,804,1504,824,1504,900,1493,901,1492,907,1719,907,1708,890,1680,877,1679,896,1668,894,1668,816,1664,804,1668,776,1661,770,1663,755,1657,744,1643,737,1618,736,1600,751,1600,768,1592,778,1592,799,1597,800,1592,818,1593,900,1580,902,1580,808,1576,804,1580,799,1580,774,1574,770,1575,753,1555,736,1534,736}
TP[15] = {566,728,566,739,604,739,603,730,592,732,589,726,580,726,575,734,570,734}
TP[16] = {2162,713,2159,823,2182,881,2181,887,2159,889,2159,966,2167,969,2167,1054,2377,1056,2377,971,2325,971,2342,1025,2228,1027,2205,969,2245,968,2245,829,2199,828,2197,715}
TP[17] = {52,670,48,705,57,709,57,670}
TP[18] = {22,668,16,705,22,715,29,715,33,707,31,670}
TP[19] = {1078,634,1072,640,1070,659,1080,670,1080,679,1085,679,1087,636}
TP[20] = {1116,618,1114,655,1122,663,1133,663,1139,657,1141,624}
TP[21] = {990,618,976,624,964,638,962,647,966,655,962,665,968,672,970,691,985,695,992,711,1009,711,1020,695,1035,691,1035,674,1049,661,1047,646,1037,630,1015,618}
TP[22] = {763,618,738,634,730,650,730,661,740,669,744,690,759,695,766,711,785,711,789,698,807,685,807,628,791,618}
TP[23] = {1783,592,1781,645,1802,641,1810,650,1810,661,1799,676,1791,676,1787,681,1787,693,1781,696,1773,714,1769,741,1783,744,1780,763,1792,777,1802,781,1802,789,1814,805,1827,811,1829,881,1817,886,1801,907,1978,907,1979,846,2095,844,2095,647,2088,647,2085,655,2085,718,2056,718,2054,621,2012,619,2011,718,2002,722,1979,721,1978,678,1969,680,1973,709,1945,742,1944,764,1935,770,1947,811,1829,814,1828,600,1820,590,1787,588}
TP[24] = {340,568,314,582,302,600,292,632,292,687,308,698,312,719,326,724,330,741,345,743,357,741,359,726,375,719,377,702,385,689,389,644,383,590,349,568}
TP[25] = {2694,564,2694,750,2706,752,2710,748,2711,602,2705,579}
TP[26] = {2670,519,2666,536,2681,536,2681,519}
TP[27] = {2642,519,2638,527,2640,537,2657,537,2657,523,2651,518}
TP[28] = {0,488,0,613,9,613,22,601,49,593,57,580,37,561,37,552,49,535,43,514,29,496}
TP[29] = {178,466,166,476,164,484,170,536,168,631,172,645,184,653,205,657,212,665,229,667,231,552,221,496,203,478}
TP[30] = {2285,449,2273,457,2273,462,2285,453,2296,468,2285,506,2293,516,2302,518,2306,514,2306,459,2294,449}
TP[31] = {2090,361,2086,388,2088,406,2095,408,2095,361}
TP[32] = {584,344,577,345,577,353,564,362,566,703,572,707,601,707,604,572,597,556,581,545,579,508,594,490,604,489,617,474,625,473,625,390,616,385,615,362,607,348,591,350}
TP[33] = {2154,343,2136,353,2122,381,2122,436,2158,439,2157,446,2128,445,2126,450,2160,455,2164,668,2173,662,2187,670,2195,662,2197,379,2193,365,2183,353}
TP[34] = {2395,329,2395,388,2381,395,2373,405,2363,433,2363,528,2380,533,2378,541,2367,539,2365,546,2381,550,2383,764,2412,774,2414,765,2410,761,2404,767,2395,765,2394,753,2426,748,2420,699,2442,684,2446,413,2444,379,2436,355,2420,339}
TP[35] = {1899,251,1867,242,1829,246,1829,291,1809,298,1793,320,1791,337,1797,347,1783,368,1779,426,1781,491,1828,491,1829,451,1834,451,1865,479,1881,483,1899,481,1941,398,1955,362,1954,319,1933,277}
TP[36] = {2113,205,2096,205,2096,223,2090,224,2096,232,2096,282,2143,262,2149,255,2144,250,2142,260,2122,257,2139,241,2127,230}
TP[37] = {2590,195,2585,203,2586,381,2596,383,2606,399,2606,474,2630,479,2642,503,2681,502,2682,488,2693,477,2693,241,2670,239,2637,208,2633,193}
TP[38] = {1789,138,1777,146,1777,195,1791,213,1798,213,1810,193,1808,146,1798,138}
TP[39] = {0,138,0,429,9,429,15,384,32,367,55,361,55,202,51,178,37,156,17,142}
TP[40] = {1979,137,1979,163,1997,163,1999,154,1991,139}
TP[41] = {252,118,220,130,204,142,186,168,180,221,166,226,164,245,166,257,186,258,188,271,183,280,174,280,166,268,166,335,173,333,176,323,183,323,186,337,204,351,217,353,232,365,245,367,256,377,305,397,312,404,308,431,292,452,290,487,346,519,381,530,387,515,389,228,385,222,377,221,375,196,365,166,347,142,313,122}
TP[42] = {2471,122,2440,119,2410,131,2395,128,2395,132,2403,135,2403,148,2395,155,2394,172,2384,167,2355,169,2335,165,2285,177,2276,162,2284,141,2270,115,2246,123,2246,264,2236,270,2231,251,2224,246,2216,247,2194,268,2216,282,2225,282,2236,292,2246,293,2246,322,2240,331,2236,357,2236,420,2246,434,2268,426,2279,416,2292,414,2314,398,2310,367,2298,350,2296,329,2314,318,2317,310,2339,308,2350,298,2360,298,2372,286,2392,282,2395,208,2412,214,2415,222,2433,224,2437,232,2473,244}
TP[43] = {916,114,929,147,953,155,962,165,979,167,982,132,999,111,989,107,976,112,966,106,947,114}
TP[44] = {1228,50,1206,62,1200,74,1198,96,1216,93,1223,106,1236,113,1236,50}
TP[45] = {1302,32,1299,83,1314,93,1314,152,1336,160,1340,200,1369,200,1373,160,1395,153,1395,96,1402,85,1410,83,1410,66,1389,47,1381,32,1350,32,1333,64,1328,63,1321,36,1311,30}
TP[46] = {1827,14,1810,16,1798,27,1806,54,1817,61,1819,82,1801,85,1781,80,1773,70,1772,76,1765,76,1764,71,1735,72,1680,86,1680,135,1661,164,1652,164,1647,152,1641,149,1647,136,1629,137,1631,120,1623,105,1623,88,1586,88,1567,104,1558,104,1545,92,1532,90,1527,80,1496,80,1489,92,1476,92,1473,460,1436,462,1433,471,1428,470,1428,464,1420,464,1419,470,1413,470,1410,464,1396,464,1364,496,1374,518,1390,524,1396,543,1414,561,1427,563,1436,571,1471,585,1480,594,1480,606,1466,610,1459,626,1434,640,1444,654,1440,673,1453,681,1456,699,1471,699,1480,709,1520,711,1679,709,1680,739,1692,739,1696,734,1727,738,1735,725,1752,730,1759,722,1759,714,1765,713,1769,700,1755,698,1752,687,1748,590,1679,585,1679,496,1742,495,1746,491,1746,466,1752,447,1754,196,1750,180,1736,159,1736,140,1758,124,1786,115,1806,100,1826,93,1826,80,1818,56,1812,55,1808,28,1828,19}
TP[47] = {620,0,618,83,627,83,630,90,644,97,665,93,666,97,684,103,735,101,742,89,753,90,752,114,729,118,715,113,693,116,687,122,684,149,675,164,663,163,660,137,654,126,637,115,622,113,641,121,656,136,662,181,701,183,713,179,717,136,724,127,755,113,755,0,752,43,739,35,737,14,729,0,654,0,652,8,629,18,621,17}
TP[48] = {63,0,57,5,42,3,37,14,21,23,0,22,0,37,5,35,6,26,27,25,44,11,61,7}
TD.layers[3] = { color={74,152,200}, ocol={74,152,200}, par=0.35, coll=0, hidden=0, polys={} }
TP = TD.layers[3].polys
TP[1] = {662,910,662,956,1429,969,1446,965,1769,967,2102,958,2341,957,2341,882,2155,886,2154,910,1811,910,1802,892,1807,910,992,910,991,838,988,910,871,910,870,872,868,909,856,910,855,840,852,910,737,910,736,884,733,910}
TP[2] = {1875,678,1862,686,1865,699,1858,702,1853,714,1847,715,1842,730,1830,731,1825,724,1817,738,1825,731,1846,731,1851,717,1858,717,1859,724,1863,723,1860,714,1865,700,1874,693}
TP[3] = {2156,201,2161,213,2164,205,2171,207,2171,213,2174,205,2181,206,2181,213,2185,205,2191,206,2191,213,2194,205,2201,207,2201,213,2205,205,2210,205,2213,214,2214,205,2220,205,2223,213,2225,204,2231,210,2235,205,2243,208,2244,204,2269,204,2272,211,2279,204}
TD.layers[4] = { color={131,151,251}, ocol={131,151,251}, par=0.5, coll=0, hidden=0, polys={} }
TP = TD.layers[4].polys
TP[1] = {2898,1050,2898,1218,2954,1218,2936,1157,2948,1150,2946,1135,2952,1115,2968,1102,2968,1091,2986,1076,2988,1053}
TP[2] = {2411,1216,2839,1214,2839,1050,2489,1050,2481,1081,2465,1103,2465,1119,2456,1129,2457,1139,2447,1141,2438,1169,2460,1171,2461,1183,2437,1183,2428,1204}
TP[3] = {2880,916,2882,965,2901,965,2887,924}
TP[4] = {3291,830,3292,903,3307,903,3307,868,3299,865,3299,858,3307,857,3307,846,3294,844}
TP[5] = {3986,819,3986,949,3968,985,3967,1049,3958,1061,3945,1059,3944,1050,3936,1050,3938,1076,3996,1075,3997,1033,4002,1016,4017,1001,4049,991,4049,939,4044,943,4018,940,4018,871,4028,839}
TP[6] = {138,818,134,822,146,832,145,844,130,849,124,867,161,847}
TP[7] = {1088,790,1090,893,1121,897,1121,838,1116,835,1116,821,1097,792}
TP[8] = {1180,789,1168,793,1149,816,1147,835,1142,839,1142,897,1180,897}
TP[9] = {900,791,962,795,936,777,925,777,917,785}
TP[10] = {3237,772,3219,781,3199,810,3197,824,3213,836,3213,849,3182,868,3182,924,3191,925,3194,930,3194,947,3188,957,3192,978,3182,1023,3182,1047,3195,1047,3196,1027,3201,1026,3206,1014,3215,1013,3217,1019,3230,1018,3235,951}
TP[11] = {3085,772,3084,1043,3085,1047,3139,1047,3140,983,3130,979,3135,954,3128,948,3129,928,3140,925,3139,865,3129,865,3117,850,3107,845,3108,837,3125,825,3124,815,3105,783}
TP[12] = {3185,687,3185,693,3195,699,3197,721,3209,721,3218,735,3219,722,3225,719,3206,696}
TP[13] = {3138,687,3117,696,3104,708,3099,719,3105,734,3112,722,3126,720,3127,700,3138,692}
TP[14] = {2835,650,2821,656,2803,680,2800,692,2814,704,2815,710,2789,727,2790,774,2799,778,2799,794,2793,799,2798,818,2790,822,2788,911,2796,912,2818,965,2835,965,2835,940,2831,939,2835,883}
TP[15] = {2710,650,2710,909,2756,909,2755,822,2747,818,2752,800,2746,796,2746,779,2755,775,2755,726,2747,725,2730,711,2743,687,2731,664}
TP[16] = {810,627,808,685,804,695,811,694,811,673,825,662,823,647}
TP[17] = {3015,624,3101,626,3101,618,3082,617,3076,621,3017,617}
TP[18] = {1094,617,1075,631,1065,650,1064,662,1075,667,1069,659,1071,640,1078,633,1087,635,1086,679,1078,680,1078,693,1094,696,1103,713,1128,713,1136,695,1150,694,1150,672,1164,661,1162,648,1154,633,1127,614}
TP[19] = {874,615,850,629,841,644,838,662,851,672,853,694,869,698,874,713,902,713,903,703,910,695,924,694,924,674,929,666,938,663,937,651,930,636,912,619,899,614}
TP[20] = {1037,627,1007,613,976,619,957,639,952,663,961,664,963,638,982,620,1015,617,1034,629}
TP[21] = {800,619,767,613,752,618,735,632,725,653,725,663,732,664,738,673,740,695,749,692,741,689,739,669,729,661,729,650,737,634,763,617}
TP[22] = {2792,581,2801,592,2802,607,2812,608,2819,619,2824,606,2820,598,2802,583}
TP[23] = {2754,580,2736,588,2725,599,2722,607,2726,618,2732,609,2744,607,2745,590,2754,585}
TP[24] = {2618,530,2616,725,2626,726,2626,831,2635,831,2639,827,2639,788,2651,771,2653,754,2663,751,2666,765,2666,648,2663,641,2623,647,2623,612,2637,608,2638,592,2648,581,2636,561,2623,557,2623,531}
TP[25] = {2803,523,2804,530,2815,531,2841,530,2842,525,2847,525}
TP[26] = {2643,523,2663,525,2665,531,2776,530,2776,525}
TP[27] = {938,482,930,489,930,499,944,501,946,486}
TP[28] = {2362,424,2360,507,2348,508,2345,503,2343,520,2331,528,2326,548,2305,580,2304,596,2286,625,2260,687,2252,694,2236,732,2224,747,2224,759,2197,813,2327,811,2315,781,2315,770,2323,765,2327,738,2337,731,2339,722,2353,707,2349,680,2359,675,2359,552,2365,551,2370,558,2372,629,2378,647,2377,469,2364,460,2371,435}
TP[29] = {2542,371,2541,697,2584,697,2584,533,2576,527,2580,511,2575,504,2575,491,2584,485,2584,445,2559,425,2562,416,2572,409,2565,387}
TP[30] = {2498,361,2474,363,2448,376,2431,403,2443,427,2420,442,2420,488,2428,492,2428,505,2422,510,2426,528,2420,532,2420,563,2428,541,2441,539,2450,544,2454,693,2464,697,2499,697}
TP[31] = {2053,419,2046,435,2048,441,2186,509,2196,507,2227,517,2239,505,2238,496,2251,494,2251,489,2261,484,2236,476,2199,432,2177,423,2165,395,2165,382,2123,362,2115,363,2089,409,2093,430,2058,430}
TP[32] = {2020,360,2020,378,2035,379,2031,362}
TP[33] = {2387,348,2362,354,2360,363,2387,363}
TP[34] = {1248,343,1248,361,1287,362,1287,342}
TP[35] = {840,337,842,355,861,355,860,336}
TP[36] = {2878,318,2878,329,2863,342,2852,344,2823,362,2808,362,2790,378,2790,393,2802,414,2802,437,2732,472,2730,489,2738,507,2726,512,2706,500,2692,517,2767,517,2768,507,2775,507,2774,517,2781,517,2781,496,2768,498,2765,488,2776,475,2792,479,2789,465,2797,453,2802,453,2810,465,2801,490,2801,517,2841,517,2841,458,2855,432,2874,421,2885,421,2912,440,2920,486,2916,741,2911,748,2902,750,2901,744,2881,739,2879,612,2879,793,2913,791,2920,798,2920,907,2965,907,2965,868,2998,853,3008,856,3012,949,3031,953,3030,760,3000,763,2965,776,2965,736,2978,735,2984,722,2996,720,2997,699,3010,692,2998,666,2992,663,2989,670,2978,672,2975,657,2965,656,2965,600,2957,595,2957,566,2965,561,2966,551,2965,508,2955,501,2955,424,2965,401,2965,372,2956,372,2914,350,2907,342,2895,340}
TP[37] = {2476,310,2461,320,2435,328,2445,329,2449,339,2456,340,2456,334,2467,327}
TP[38] = {3494,274,3494,285,3475,302,3462,304,3423,326,3398,330,3391,342,3374,352,3376,369,3392,390,3394,425,3323,466,3306,468,3305,450,3315,449,3319,436,3317,432,3305,431,3305,362,3288,366,3251,388,3228,390,3223,400,3208,408,3210,429,3222,444,3224,481,3142,522,3136,528,3135,554,3128,554,3118,544,3118,549,3104,556,3099,566,3082,570,3063,584,3050,586,3041,596,3024,600,3014,611,3190,610,3191,577,3185,560,3196,559,3185,559,3178,547,3183,545,3185,532,3196,527,3205,527,3218,538,3218,593,3208,598,3196,590,3196,609,3275,610,3273,512,3283,484,3292,473,3305,467,3306,549,3365,551,3362,558,3308,556,3306,567,3347,566,3366,570,3366,987,3370,988,3366,999,3370,1000,3370,1027,3413,1026,3414,1031,3421,1031,3430,1041,3431,1047,3449,1047,3443,987,3447,920,3490,891,3543,891,3548,900,3548,1049,3505,1050,3505,1152,3538,1152,3543,1157,3567,1216,3680,1214,3659,1156,3663,1148,3670,1148,3674,1057,3688,1056,3693,1047,3745,1047,3749,1026,3755,1026,3758,1020,3777,1021,3780,1016,3770,1002,3775,986,3781,985,3782,978,3779,982,3709,977,3705,632,3717,602,3750,579,3761,579,3797,603,3797,476,3778,474,3773,466,3759,459,3759,448,3754,446,3754,457,3747,464,3740,464,3735,474,3722,476,3685,498,3654,502,3652,511,3646,514,3646,557,3652,574,3652,601,3646,604,3643,728,3646,1049,3572,1050,3573,884,3566,870,3545,865,3545,848,3538,842,3539,832,3533,828,3515,832,3454,832,3449,827,3445,462,3457,430,3466,421,3490,407,3503,407,3538,432,3546,458,3548,492,3546,723,3542,766,3544,770,3554,769,3556,761,3546,751,3546,744,3558,734,3559,724,3573,717,3574,328,3541,314,3531,304,3516,302,3499,287}
TP[39] = {2625,157,2615,158,2588,175,2570,176,2568,184,2554,192,2556,210,2567,222,2570,241,2622,239,2621,211,2613,193,2625,181}
TP[40] = {929,148,929,177,979,177,979,168,962,166,955,158}
TP[41] = {2019,94,1977,116,1968,116,1928,140,1928,159,1938,170,1946,194,1944,448,1938,491,1933,496,1866,496,1839,508,1823,505,1817,451,1817,304,1821,288,1833,271,1833,258,1783,230,1776,230,1771,222,1754,218,1751,208,1741,203,1737,180,1732,203,1717,218,1680,236,1680,709,1520,712,1480,710,1476,706,1479,719,1472,729,1498,743,1497,755,1488,758,1496,784,1494,845,1498,887,1494,899,1503,899,1504,778,1511,769,1511,750,1518,741,1532,735,1561,737,1576,753,1576,769,1582,774,1584,899,1591,899,1591,776,1597,771,1599,750,1618,735,1643,735,1660,746,1664,752,1664,771,1670,776,1670,891,1677,895,1679,780,1791,779,1797,744,1817,736,1817,656,1821,630,1832,615,1857,597,1860,587,1940,590,1946,697,1965,696,1964,686,1974,677,1974,670,1969,668,1973,652,1973,592,1978,587,2011,589,2019,599,2019,494,1974,494,1969,479,1973,368,1987,347,1981,337,1983,320,1998,297,2019,291,2020,301,2035,307,2056,335,2070,331,2111,254,2105,245,2103,214,2113,195,2107,177,2109,164,2093,156,2020,154}
TP[42] = {2016,20,2000,28,2004,53,2016,64,2019,79}
TP[43] = {8,28,0,38,0,137,13,139,35,153,52,178,56,202,56,361,32,368,16,384,12,427,0,430,0,487,13,487,29,495,46,516,50,535,38,561,56,576,58,587,45,596,22,602,9,614,0,614,0,730,19,722,29,730,67,732,76,723,85,723,98,732,139,732,146,723,154,723,165,732,182,731,83,680,81,671,87,657,80,656,80,646,90,646,96,640,96,627,114,619,181,652,169,643,167,631,169,536,163,484,172,467,185,467,207,479,220,492,232,538,230,667,220,664,217,668,245,685,260,687,283,704,280,893,288,897,479,897,487,881,487,860,493,844,522,813,561,797,572,783,625,783,625,762,604,755,603,742,575,741,580,725,589,725,594,733,604,729,604,704,599,710,588,710,565,703,563,362,566,357,581,353,584,343,589,343,594,351,602,345,592,335,583,334,584,302,571,276,588,267,595,253,612,255,640,241,649,225,668,227,704,209,710,195,727,197,758,182,764,167,782,170,819,151,819,86,810,86,805,79,807,0,756,0,756,115,722,130,716,140,714,181,701,184,662,182,655,138,641,122,619,113,619,0,444,0,439,17,411,16,407,0,276,0,276,9,271,14,240,14,239,0,64,0,61,8,44,12,33,24}
TD.layers[5] = { color={112,103,201}, ocol={112,103,201}, par=0.68, coll=0, hidden=0, polys={} }
TP = TD.layers[5].polys
TP[1] = {3337,1291,3339,1326,3360,1326,3365,1316,3376,1316,3377,1321,3400,1321,3400,1309,3388,1301,3377,1301,3376,1291}
TP[2] = {3342,1187,3336,1206,3318,1227,3309,1257,3299,1270,3284,1308,3275,1316,3268,1338,3290,1319,3297,1304,3320,1305,3320,1294,3298,1292,3297,1286,3306,1262,3316,1261,3315,1251,3326,1237,3324,1224,3340,1203}
TP[3] = {4740,1100,4744,1118,4764,1121,4782,1135,4793,1161,4795,1179,4796,1161,4790,1138,4776,1124,4744,1115}
TP[4] = {4197,1100,4193,1120,4200,1122,4205,1131,4205,1348,4216,1229,4220,1228,4220,1220,4225,1219,4240,1366,4242,1124,4252,1120,4247,1100}
TP[5] = {4417,1056,4418,1095,4442,1095,4437,1088,4425,1084}
TP[6] = {4073,1038,4073,1095,4137,1095,4121,1077,4078,1078,4077,1038}
TP[7] = {4700,1000,4681,1014,4678,1034,4691,1050,4714,1056,4730,1043,4733,1021,4719,1002}
TP[8] = {3779,990,3770,1002,3775,1028,3766,1031,3766,1072,3773,1057,3777,1028,3773,1004,3778,1000}
TP[9] = {3906,984,3904,993,3914,1000,3916,1093,3918,1012,3916,998}
TP[10] = {3223,971,3225,1061,3228,974}
TP[11] = {3824,930,3820,942,3817,1068,3803,1070,3801,1064,3792,1065,3788,1076,3781,1077,3783,1095,3823,1095}
TP[12] = {0,863,0,900,8,905,48,905,43,877,16,863}
TP[13] = {4772,859,4771,868,4796,868,4813,878,4814,867,4805,864,4798,868,4795,860,4785,857}
TP[14] = {4354,867,4358,855,4367,857,4367,867,4370,858,4379,855,4384,867,4387,855,4398,859,4402,854,4410,858,4412,867,4417,850,4354,849}
TP[15] = {4816,835,4816,840,4852,842,4875,854,4858,840,4833,834}
TP[16] = {4248,820,4234,830,4234,844,4242,859,4240,877,4248,880,4248,889,4254,893,4251,866,4242,860,4238,833,4254,825,4253,840,4257,843,4261,822}
TP[17] = {3613,806,3583,804,3570,808,3542,825,3537,836,3530,836,3515,896,3519,898,3523,883,3530,883,3534,892,3528,901,3521,902,3515,914,3526,912,3533,901,3544,897,3544,889,3528,876,3534,851,3547,834,3569,818}
TP[18] = {1263,798,1262,819,1271,826,1287,824,1289,816,1284,807,1272,797}
TP[19] = {4820,783,4821,794,4857,797,4862,806,4872,807,4881,815,4901,821,4912,833,4928,837,4928,824,4923,829,4912,829,4910,819,4891,813,4877,798,4864,802,4863,790,4847,790,4843,783,4834,780}
TP[20] = {626,780,632,887,637,839,634,808,638,804}
TP[21] = {939,777,944,785,971,795,980,804,992,838,992,905,1005,905,1005,836,1011,816,1026,795,1055,779,1033,780,1016,794,1005,817,998,820,969,782}
TP[22] = {921,777,897,781,893,788,882,792,866,815,853,807,853,801,839,790,837,781,806,779,833,795,850,816,856,840,856,905,867,905,867,842,879,808,892,793,917,784}
TP[23] = {781,777,765,780,757,789,745,791,735,799,726,848,731,902,733,846,739,818,754,795,782,783}
TP[24] = {4349,752,4333,765,4331,783,4346,800,4353,800,4353,783,4348,777,4353,768,4353,752}
TP[25] = {3728,740,3714,750,3713,771,3698,773,3694,785,3713,774,3718,751}
TP[26] = {2925,736,2929,752,2931,841,2952,843,2956,771,2945,802,2945,821,2936,821,2936,785}
TP[27] = {2217,731,2213,749,2165,763,2157,782,2142,789,2144,796,2150,795,2153,787,2167,783,2170,769,2191,772,2194,762,2204,762,2206,772,2210,771,2218,752}
TP[28] = {0,731,0,756,99,807,127,810,146,823,145,829,136,828,143,834,142,840,128,845,122,857,131,847,144,844,145,829,150,828,174,858,196,905,222,904,223,752,219,747,188,731,165,733,154,724,146,724,139,733,98,733,85,724,76,724,67,733,32,732,19,723}
TP[29] = {2956,710,2956,733,2966,737,2966,710}
TP[30] = {3298,696,3289,697,3270,713,3251,750,3249,823,3252,832,3258,834,3255,847,3261,844,3261,828,3252,824,3251,777,3277,760,3276,754,3263,743,3263,736,3276,713}
TP[31] = {3177,694,3173,699,3195,714,3207,737,3207,743,3193,756,3194,761,3219,776,3219,825,3210,829,3210,846,3216,850,3211,868,3219,872,3221,916,3222,875,3216,832,3223,820,3225,785,3218,767,3219,752,3210,724,3187,697}
TP[32] = {3949,678,3909,680,3910,688,3898,695,3897,716,3892,720,3892,815,3896,824,3892,863,3897,871,3911,874,3911,942,3902,946,3902,965,3906,971,3909,950,3917,944,3919,921,3923,918,3917,915,3920,906,3911,863,3911,823,3937,821,3943,807,3951,808,3951,819,3962,822,3962,828,3954,834,3952,855,3966,853,3968,861,3952,868,3945,885,3948,937,3963,953,3963,962,3957,968,3964,966,3965,945,3954,942,3953,875,3965,872,3974,860,3987,854,3979,839,3968,833,3971,816,3986,791,4015,771,3991,766,3987,780,3981,780,3977,750,3990,749,3992,736,3984,721,3969,717,3967,695,3957,688,3957,680}
TP[33] = {3783,661,3783,668,3792,669,3792,677,3796,677,3798,667,3805,669,3805,677,3809,677,3811,667,3818,669,3818,677,3822,677,3824,667,3831,669,3831,677,3837,667,3844,669,3844,677,3848,677,3850,667,3855,667,3859,677,3863,666,3858,661}
TP[34] = {3220,632,3209,640,3208,657,3195,660,3192,672,3206,666,3212,658}
TP[35] = {1008,716,1055,710,1056,703,1069,703,1073,713,1131,715,1134,709,1162,693,1161,683,1167,681,1170,668,1175,666,1170,659,1170,646,1176,645,1177,632,1191,630,1191,624,1198,623,1201,614,1002,610,1030,620,1044,632,1052,650,1052,663,1040,672,1040,691,1024,698,1018,712}
TP[36] = {686,614,685,637,690,641,686,710,693,713,697,704,712,709,721,700,731,699,744,716,761,715,755,698,738,694,737,673,724,663,724,653,731,636,744,622,767,612,782,612,807,621,826,654,825,664,813,673,812,694,796,698,790,715,829,717,827,709,836,707,836,717,845,713,880,716,873,713,869,699,852,694,850,672,837,662,843,638,854,624,874,614,899,613,927,631,937,648,939,663,929,667,925,674,925,694,910,696,903,713,893,716,933,715,940,704,955,704,964,715,988,716,981,698,965,694,963,671,951,663,956,639,971,622,996,611,804,614,799,610,760,609}
TP[37] = {3892,602,3898,606,3898,618,3903,604,3910,606,3912,618,3918,605,3925,607,3926,618,3929,606,3936,605,3942,618,3942,608,3950,605,3956,618,3956,608,3965,602,3970,607,3978,605,3981,617,3985,617,3987,606,3993,606,3995,618,3999,617,4002,605,4009,607,4013,617,4012,608,4020,605,4027,618,4028,607,4035,605,4041,618,4041,608,4049,605,4055,618,4055,607,4063,605,4068,618,4072,601}
TP[38] = {3134,570,3144,572,3145,581,3149,572,3156,574,3156,581,3159,572,3166,574,3166,581,3171,572,3177,576,3186,573,3188,581,3192,572,3198,574,3198,581,3202,572,3208,573,3209,581,3213,572,3220,574,3220,581,3223,572,3230,574,3230,581,3234,574,3244,581,3245,573,3254,581,3257,571,3270,572,3273,581,3276,573,3283,574,3283,581,3287,573,3292,573,3296,581,3298,573,3308,572,3306,568}
TP[39] = {3429,470,3429,597,3442,593,3479,597,3500,614,3510,636,3508,761,3490,768,3477,780,3474,815,3516,811,3515,794,3526,784,3543,786,3550,795,3578,793,3589,775,3591,758,3604,746,3605,726,3599,724,3602,698,3615,689,3616,666,3624,669,3624,677,3629,667,3637,669,3637,677,3641,668,3648,667,3650,678,3655,667,3662,669,3663,677,3668,666,3676,669,3676,677,3680,667,3688,668,3689,677,3694,666,3701,668,3702,677,3708,667,3714,669,3714,677,3718,677,3720,667,3728,669,3728,677,3733,667,3740,668,3740,677,3744,677,3745,668,3752,668,3753,677,3757,677,3759,667,3764,667,3766,677,3770,677,3770,669,3776,667,3775,661,3600,662,3598,667,3611,668,3609,678,3542,680,3539,667,3551,667,3539,661,3543,612,3549,600,3567,587,3567,562,3573,548,3561,539,3559,532,3542,532,3524,522,3517,512,3502,512,3478,500,3469,488,3454,488,3434,478}
TP[40] = {1367,470,1355,470,1349,476,1350,494,1358,503,1377,481}
TP[41] = {1323,492,1312,477,1303,480,1298,474,1295,480,1289,480,1288,471,1279,467,1258,471,1257,482,1252,483,1238,464,1226,464,1217,476,1206,467,1186,468,1181,477,1176,476,1170,464,1144,466,1142,478,1130,466,1119,466,1118,470,1104,474,1103,468,1081,462,1070,464,1069,472,1051,472,1048,466,1037,465,1022,469,1021,463,1003,463,1000,469,990,470,989,476,979,473,936,479,901,468,879,477,882,490,878,500,866,497,863,501,846,499,829,487,811,485,797,477,772,474,737,503,732,528,712,539,705,573,700,572,704,534,690,520,685,502,683,506,690,532,697,538,697,577,709,574,716,551,726,539,740,536,763,540,779,554,780,578,787,583,796,581,798,532,810,537,808,544,831,544,813,541,815,535,858,537,863,545,876,544,860,540,863,533,876,526,887,537,897,537,895,552,896,545,912,544,899,540,898,528,903,524,910,530,918,528,919,534,932,530,940,536,939,544,945,544,955,536,969,536,986,526,1005,526,1013,533,1028,524,1030,529,1113,534,1125,523,1133,536,1128,544,1138,544,1135,537,1142,530,1148,531,1150,543,1166,544,1154,540,1148,522,1182,516,1189,520,1192,531,1212,533,1214,538,1225,535,1238,539,1247,511,1276,511,1281,519,1288,515,1320,519}
TP[42] = {798,464,811,472,839,470,845,474,871,469,883,460,850,466,830,460}
TP[43] = {2971,402,2967,404,2967,457,2958,464,2958,474,2962,465,2967,466,2967,481,2962,485,2967,488,2967,519,2993,511,3016,515,3037,534,3041,544,3041,649,3016,660,3013,694,3052,696,3046,775,3053,774,3070,759,3055,740,3061,722,3071,710,3099,693,3129,691,3122,641,3126,620,3121,619,3128,586,3126,582,3071,584,3065,580,3068,524,3086,507,3092,476,3080,464,3053,456,3046,446,3033,446,3008,428,2997,428,2981,420}
TP[44] = {2692,386,2688,388,2687,404,2675,415,2697,414}
TP[45] = {2964,290,2911,292,2906,305,2920,305,2921,301,2926,305,2931,301,2950,305}
TP[46] = {2757,261,2753,263,2759,278,2759,371,2735,384,2729,398,2730,409,2734,409,2741,388,2761,375,2789,388,2786,380,2774,377,2770,364,2762,357,2764,344,2777,329,2796,327,2809,331,2794,323,2765,321,2764,289}
TP[47] = {2604,237,2604,241,2632,239,2646,245,2661,262,2665,283,2674,258,2695,241,2724,239,2742,247,2723,235,2699,236,2665,258,2638,237}
TP[48] = {2537,250,2498,235,2468,234,2446,239,2415,256,2408,265,2396,268,2377,307,2385,305,2399,278,2414,263,2440,247,2470,239,2497,239,2534,253}
TP[49] = {2382,214,2360,251,2352,257,2320,324,2304,336,2294,369,2281,380,2265,379,2266,394,2258,396,2252,409,2236,418,2231,428,2220,431,2215,422,2191,425,2174,420,2168,412,2142,412,2142,670,2148,666,2155,644,2171,639,2163,635,2164,611,2172,612,2172,623,2187,623,2187,616,2195,615,2195,608,2203,607,2203,600,2211,599,2212,593,2223,593,2224,585,2258,586,2261,603,2252,604,2253,617,2244,619,2242,628,2231,626,2237,638,2229,645,2229,651,2212,648,2212,655,2216,656,2213,693,2217,698,2213,716,2220,707,2218,691,2229,684,2227,667,2237,664,2236,645,2250,639,2255,614,2267,605,2264,591,2273,592,2279,569,2288,564,2286,549,2297,547,2296,508,2288,505,2287,511,2281,511,2280,504,2269,498,2277,490,2264,495,2262,483,2246,485,2232,470,2236,450,2250,437,2256,437,2256,428,2268,412,2275,412,2276,417,2264,442,2274,457,2283,444,2293,444,2349,475,2433,512,2289,439,2305,402,2332,409,2360,361,2353,363,2339,386,2325,388,2323,382,2316,382,2311,375,2310,358,2317,354,2318,345,2329,334,2344,284,2371,246}
TP[50] = {2390,112,2390,131,2382,147,2392,164,2388,190,2392,195,2394,163,2388,140,2397,116}
TD.layers[6] = { color={102,90,184}, ocol={102,90,184}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[6].polys
TP[1] = {5751,1426,5737,1583,5767,1583,5759,1462}
TP[2] = {5498,1352,5494,1354,5494,1437}
TP[3] = {1893,1140,1893,1169,3043,1176,3572,1169,3572,1140,3333,1141,3000,1150,2677,1148,2660,1152}
TP[4] = {6101,1116,6092,1121,6081,1137,6090,1151,6086,1162,6066,1163,6054,1182,6098,1185,6103,1202}
TP[5] = {6165,1083,6144,1107,6146,1126,6157,1132,6154,1111,6166,1095,6177,1089,6196,1091,6208,1102,6212,1120,6208,1133,6191,1149,6205,1150,6220,1130,6219,1102,6206,1085,6192,1078}
TP[6] = {5734,1017,5734,1030,5724,1038,5719,1060,5706,1070,5699,1070,5693,1093,5684,1100,5669,1101,5668,1110,5691,1121,5706,1138,5717,1175,5708,1185,5799,1185,5796,1178,5787,1175,5793,1147,5818,1117,5837,1110,5836,1101,5818,1099,5811,1090,5808,1070,5787,1059,5784,1040,5773,1030,5775,1018}
TP[7] = {3709,947,3704,964,3705,1087}
TP[8] = {2816,910,2805,927,2742,934,2666,931,2622,935,2580,929,2492,933,2470,931,2467,927,2463,935,2584,933,2637,939,2671,935,2746,939,2775,933,2806,935}
TP[9] = {2009,929,2025,926,2033,910,2012,910,2007,920}
TP[10] = {5209,898,5202,898,5196,912,5171,913,5177,1002,5182,1005,5178,1034,5170,1038,5167,1048,5170,1082,5177,1089,5176,1185,5211,1185,5210,1088,5216,1086,5215,1056,5221,1046,5206,1027,5204,980,5210,957,5225,947,5225,936,5220,936,5217,948,5210,947,5213,923,5220,912,5209,909}
TP[11] = {6107,866,6106,1109,6111,1091,6112,992,6119,953,6120,911,6125,900,6171,919,6192,920,6203,934,6221,942,6247,969,6247,1177,6252,1183,6247,1196,6249,1583,6457,1583,6454,1322,6458,1319,6458,1055,6445,1053,6423,1035,6392,1024,6387,1016,6360,1011,6343,1013,6327,994,6318,995,6305,981,6294,980,6292,970,6271,959,6245,960,6228,936,6207,929,6198,912,6175,913,6165,898,6147,901,6134,896,6120,878,6117,866}
TP[12] = {5533,866,5519,884,5521,894,5528,897,5525,909,5519,917,5503,918,5498,931,5502,946,5511,956,5515,1001,5520,1005,5532,1003,5541,1015,5541,997,5533,994,5534,986,5541,989,5540,974,5533,973,5533,956,5541,958,5540,867}
TP[13] = {5793,862,5783,862,5777,869,5782,882,5783,869,5792,868,5792,887,5780,889,5786,892,5786,899,5790,891,5795,891,5795,875,5801,873}
TP[14] = {1466,848,1466,856,1476,857,1476,867,1484,862,1492,866,1489,905,1495,886,1494,853}
TP[15] = {5237,840,5241,869,5250,855,5275,857,5274,850,5259,849,5251,840}
TP[16] = {5612,827,5592,834,5580,851,5578,872,5589,880,5590,857,5600,844,5612,841}
TP[17] = {4768,824,4769,835,4760,841,4755,864,4750,870,4739,872,4729,897,4711,899,4711,908,4720,909,4744,928,4754,949,4756,968,4748,971,4741,982,4757,1000,4769,1003,4769,1067,4759,1070,4758,1085,4764,1090,4760,1117,4769,1122,4769,1185,4806,1185,4806,1121,4816,1114,4810,1105,4810,1092,4817,1087,4818,1071,4806,1067,4805,1004,4817,1001,4836,984,4827,970,4819,967,4820,956,4834,928,4851,913,4865,908,4865,900,4850,899,4844,894,4839,870,4821,861,4819,844,4810,835,4808,823}
TP[18] = {142,834,131,824,118,822,119,842,110,843,110,849,99,854,103,860,99,875,88,878,1,834,0,862,18,862,43,876,49,905,98,905,105,886,121,868,125,847,139,842}
TP[19] = {1438,810,1452,829,1448,837,1452,851,1454,845,1459,845,1454,814}
TP[20] = {3177,803,3179,897,3181,848}
TP[21] = {4658,783,4644,788,4641,814,4646,816,4646,837,4633,848,4633,865,4626,869,4619,884,4591,886,4584,877,4567,875,4557,884,4557,902,4532,902,4532,906,4557,909,4556,969,4561,964,4564,942,4570,938,4570,926,4578,925,4589,909,4595,909,4613,895,4658,895}
TP[22] = {1258,786,1250,802,1253,825,1244,827,1244,846,1239,857,1242,904,1346,905,1346,835,1333,828,1335,798,1317,781,1279,778}
TP[23] = {953,776,978,786,990,812,1000,820,1015,794,1033,779,1039,779}
TP[24] = {627,776,638,796,632,905,730,905,725,848,734,799,743,790,757,788,768,777}
TP[25] = {1425,768,1438,771,1439,756,1452,750,1490,755,1495,752,1495,745,1480,738,1439,736,1443,749,1432,750,1428,741,1430,758}
TP[26] = {2358,826,2329,791,2329,784,2319,779,2308,765,2293,735,2269,735,2260,743,2206,745,2190,740,2186,746,2145,747,2136,767,2145,792,2143,819,2132,838,2132,849,2124,856,2106,896,2105,909,2090,910,2085,914,2086,920,2101,931,2111,925,2196,923,2198,910,2148,909,2161,885,2171,876,2185,872,2227,874,2247,890,2254,905,2327,905,2339,888,2357,880}
TP[27] = {4048,716,4044,717,4044,733,4031,756,4016,764,4013,776,3998,779,3996,784,4011,785,4035,814,4049,869,4048,910,4040,923,4047,962,4045,1043,4053,1064,4049,1183,4069,1185,4073,962,4080,933,4072,913,4072,865,4077,857,4074,840,4092,804,4112,786,4123,782,4105,775,4101,758,4088,750,4079,737,4075,717}
TP[28] = {795,717,800,762,791,775,839,780,842,792,862,814,882,791,897,780,909,778,843,775,842,725,847,717,863,716,838,716,832,708,823,710,822,717}
TP[29] = {913,716,959,718,975,714,960,714,955,705,940,705,933,716}
TP[30] = {1027,715,1044,717,1052,725,1054,757,1046,778,1073,775,1109,796,1124,837,1126,905,1136,905,1137,842,1145,814,1163,791,1178,786,1180,777,1125,777,1116,772,1115,760,1107,759,1107,744,1116,743,1120,722,1117,717,1070,714,1069,704,1048,707,1047,712}
TP[31] = {3954,673,3951,692,3946,696,3951,710,3951,727,3947,728,3951,738,3951,773}
TP[32] = {2333,648,2318,648,2317,667,2330,665}
TP[33] = {5556,616,5543,617,5542,858,5546,857,5550,661,5556,659,5557,653,5565,652,5573,658,5595,660,5612,668,5600,648,5582,652,5569,647,5556,628}
TP[34] = {1132,715,1239,717,1245,723,1245,735,1255,735,1256,731,1263,731,1264,725,1279,725,1288,717,1299,719,1305,704,1313,702,1319,688,1330,689,1332,719,1343,722,1347,717,1345,618,1324,613,1312,616,1305,611,1200,610,1201,622,1192,624,1191,631,1176,632,1178,642,1171,655,1176,668,1170,670,1168,681,1162,683,1163,693}
TP[35] = {1407,559,1410,576,1418,579,1418,599,1423,598,1424,586,1447,590,1449,595,1446,611,1425,629,1423,647,1419,648,1421,683,1439,703,1456,708,1468,719,1470,733,1477,713,1468,701,1451,705,1444,680,1432,676,1441,656,1428,642,1446,627,1455,625,1465,605,1477,605,1477,596,1470,588}
TP[36] = {2703,555,2694,555,2694,562,2688,563,2687,568,2677,568,2677,577,2685,579,2684,586,2660,586,2660,593,2648,594,2647,600,2640,600,2640,607,2632,608,2632,615,2624,616,2623,624,2608,624,2607,612,2597,612,2600,643,2592,644,2585,666,2566,691,2567,702,2555,702,2544,711,2544,716,2524,734,2522,745,2512,749,2372,897,2369,905,2435,905,2444,887,2480,844,2502,832,2507,822,2523,826,2525,813,2532,806,2560,807,2570,803,2569,793,2590,782,2601,762,2641,753,2649,746,2649,730,2656,729,2654,718,2648,717,2648,684,2653,664,2647,648,2662,651,2671,634,2667,626,2676,627,2679,619,2687,616,2688,604,2694,600,2687,579,2699,574}
TP[37] = {684,518,688,535,688,606,682,609,683,631,685,614,694,611,785,608,810,612,805,609,802,593,779,578,778,554,759,540,729,538,720,546,710,574,696,579,696,538}
TP[38] = {902,510,899,508,890,518,874,518,867,513,860,524,876,520,892,526,902,520}
TP[39] = {3183,478,3178,504,3203,505,3194,493,3194,484}
TP[40] = {620,477,584,505,583,535,588,536,589,546,606,564,606,750,610,755,625,758,619,743,625,727,625,562,620,534,624,531,626,477}
TP[41] = {1398,458,1382,463,1346,461,1348,471,1343,472,1341,479,1332,477,1335,466,1330,467,1329,473,1321,471,1324,461,1295,464,1289,479,1302,473,1304,485,1306,477,1312,476,1324,488,1320,520,1304,516,1281,520,1277,505,1276,513,1247,512,1238,540,1225,536,1214,539,1212,534,1192,532,1188,520,1182,517,1153,520,1149,529,1156,535,1165,535,1170,542,1173,535,1180,535,1194,549,1267,548,1303,552,1326,545,1331,520,1336,519,1337,541,1344,547,1359,545,1388,550,1392,540,1387,526,1372,520,1366,506,1349,498,1349,473,1369,469,1378,478,1380,467}
TP[42] = {1023,466,1048,465,1055,475,1054,465,1069,471,1070,463,1081,461,1103,469,1107,475,1109,470,1123,465,1134,467,1141,480,1144,465,1170,463,1180,480,1184,467,1206,466,1217,476,1223,463,1232,463,1233,469,1247,469,1251,481,1257,482,1257,469,1284,464,1273,459,1184,462,1178,467,1173,460,1165,459,1159,463,1141,462,1140,466,1133,461,1120,461,1106,467,1073,458,1068,467,1058,460,1054,465,1027,462}
TP[43] = {873,458,984,458,994,471,1003,462,1016,463,1008,459,992,462,981,456,943,457,925,453,890,453}
TP[44] = {759,451,713,455,695,464,685,473,679,487,681,510,683,482,693,469,718,458}
TP[45] = {3556,438,3532,440,3531,448,3523,454,3522,468,3510,472,3504,495,3488,499,3488,506,3500,511,3516,527,3523,552,3514,564,3534,584,3534,627,3525,632,3525,643,3531,650,3527,667,3534,671,3534,827,3546,912,3552,911,3550,892,3561,858,3559,677,3569,632,3564,632,3558,623,3560,580,3572,571,3570,453,3563,448,3564,440}
TP[46] = {616,355,618,381,628,392,630,471,632,399}
TP[47] = {1471,280,1469,454,1459,459,1471,455}
TP[48] = {2829,113,2833,120,2824,144,2831,161,2830,195,2822,197,2825,208,2821,209,2821,219,2796,265,2787,272,2778,306,2770,312,2770,329,2747,361,2748,371,2740,375,2751,375,2752,381,2759,381,2761,387,2775,385,2794,358,2772,345,2789,306,2797,303,2818,314,2812,302,2822,289,2827,270,2843,263,2860,248,2891,235,2934,234,2973,249,2992,264,3008,285,3022,331,3021,359,3012,391,2978,461,2978,469,2960,486,2938,488,2909,519,2878,514,2875,510,2860,514,2891,524,2922,522,2927,507,2935,507,2939,500,2954,496,2958,490,2973,488,3031,374,3038,373,3041,380,3065,391,3071,371,3101,317,3130,290,3135,291,3137,299,3148,302,3152,320,3175,354,3202,330,3224,323,3249,328,3270,346,3302,326,3320,323,3344,330,3357,342,3369,363,3372,411,3400,412,3424,420,3434,441,3425,467,3409,476,3407,483,3396,483,3390,475,3367,467,3354,474,3341,490,3337,503,3368,506,3366,556,3375,570,3384,562,3370,555,3369,550,3385,521,3406,504,3446,496,3448,397,3422,396,3417,401,3404,397,3403,401,3395,401,3385,395,3380,384,3381,352,3393,334,3401,303,3407,302,3399,291,3372,280,3040,280,3039,81,3020,100,3018,109,3005,113,2991,108,2984,119,2959,117,2951,109,2942,117,2905,115,2897,106,2890,106,2886,115,2869,111,2845,113,2841,108}
TD.layers[7] = { color={88,61,130}, ocol={88,61,130}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[7].polys
TP[1] = {5425,1190,5439,1216,5430,1233,5443,1246,5444,1256,5443,1323,5448,1374,5445,1583,5495,1583,5493,1354,5497,1338,5498,1190}
TP[2] = {3572,1170,3043,1177,1893,1174,1893,1185,3572,1185}
TP[3] = {4311,907,4312,1185,4359,1185,4360,1041,4364,1032,4377,1032,4374,1007,4369,1007,4368,1002,4387,977,4428,961,4449,962,4471,971,4497,997,4489,1029,4503,1032,4507,1042,4507,1185,4553,1185,4555,1071,4551,1037,4557,909,4456,909,4428,914,4406,909}
TP[4] = {6127,901,6121,913,6120,953,6112,1000,6110,1107,6104,1112,6110,1390,6108,1583,6244,1585,6248,1581,6247,1186,6251,1185,6246,1177,6246,969,6218,941,6203,935,6192,921,6172,921}
TP[5] = {3670,787,3670,1185,3706,1185,3703,964,3710,888,3717,886,3711,880,3713,868,3731,842,3761,830,3783,831,3801,838,3817,852,3823,864,3817,879,3827,888,3831,926,3830,1185,3866,1185,3864,958,3868,932,3870,788,3788,788,3767,793,3747,788}
TP[6] = {0,758,0,834,70,867,82,877,98,875,103,863,100,854,110,849,111,842,118,842,115,816}
TP[7] = {4821,752,4816,769,4660,770,4659,777,4660,1185,4710,1185,4711,898,4725,898,4734,889,4727,865,4722,862,4726,851,4741,835,4761,824,4802,821,4819,825,4837,836,4854,857,4849,865,4850,874,4843,880,4843,891,4850,898,4866,900,4866,1189,4779,1190,4779,1575,4794,1557,4804,1531,4811,1527,4828,1485,4847,1453,4846,1444,4864,1421,4869,1400,4894,1360,4906,1327,4918,1313,4935,1268,4956,1234,4958,1215,4972,1192,4936,1189,4941,861,4933,861,4933,1189,4916,1189,4914,772,4825,769}
TP[8] = {842,728,846,738,846,776,1044,777,1053,757,1052,729,1044,718,847,718}
TP[9] = {5056,712,5052,735,5054,1185,5105,1185,5102,1026,5106,997,5106,852,5123,848,5132,840,5126,814,5120,811,5123,799,5140,781,5158,770,5207,765,5243,780,5265,808,5251,838,5259,848,5274,849,5277,860,5277,1189,5232,1190,5231,1549,5234,1583,5283,1583,5285,1260,5288,1245,5302,1246,5305,1240,5294,1212,5306,1188,5331,1185,5330,716,5324,710,5231,710,5227,700,5222,710}
TP[10] = {4158,674,4090,673,4085,667,4082,673,3954,676,3957,1185,3993,1185,3995,781,4013,775,4015,765,4005,750,4010,737,4029,721,4048,715,4082,717,4104,731,4114,745,4111,758,4105,763,4106,775,4124,782,4127,1185,4163,1185,4162,680}
TP[11] = {5557,655,5550,670,5547,857,5540,862,5542,1185,5615,1188,5614,1583,5665,1583,5661,1347,5667,1103,5684,1099,5693,1091,5693,1080,5686,1072,5686,1062,5681,1060,5686,1046,5712,1023,5738,1015,5768,1015,5793,1023,5817,1043,5825,1056,5819,1062,5820,1072,5812,1081,5812,1090,5818,1098,5836,1100,5840,1581,5890,1583,5892,962,5793,959,5789,947,5783,959,5613,959,5612,893,5604,892,5578,873,5579,850,5592,833,5612,826,5612,671,5592,660}
TP[12] = {104,626,102,639,92,650,85,650,90,656,85,677,224,748,224,905,277,905,279,706,266,694,244,688,220,672,209,671,203,664,135,636,122,626}
TP[13] = {3367,506,3176,507,3177,784,3182,828,3179,903,3185,929,3199,930,3210,920,3213,608,3216,600,3228,599,3224,582,3220,581,3225,569,3237,557,3261,547,3281,547,3301,554,3322,578,3315,598,3325,601,3330,915,3332,928,3338,934,3355,934,3361,929}
TP[14] = {3572,396,3451,398,3447,402,3450,907,3453,932,3463,936,3475,936,3483,927,3487,499,3503,495,3506,484,3500,478,3497,464,3514,446,3545,437,3572,439}
TP[15] = {3067,394,3033,373,2978,484,2952,499,2939,501,2935,508,2926,511,2922,523,2889,525,2867,518,2720,447,2713,459,2711,484,2720,485,2725,491,2723,500,2739,508,2736,547,2745,540,2746,549,2733,566,2729,584,2721,591,2712,587,2713,615,2706,625,2699,627,2698,621,2706,609,2702,610,2693,633,2676,657,2676,662,2683,663,2682,677,2673,687,2666,685,2659,697,2668,687,2674,690,2666,707,2658,707,2657,711,2658,733,2662,727,2669,728,2667,739,2659,739,2655,746,2657,761,2650,765,2659,766,2660,771,2637,780,2620,793,2609,792,2617,781,2590,794,2593,804,2585,810,2577,809,2581,800,2558,808,2544,820,2530,822,2504,838,2515,840,2508,849,2498,849,2495,842,2491,853,2498,854,2498,862,2482,884,2470,927,2492,932,2580,928,2639,934,2666,930,2738,933,2804,924,2812,905,2824,905,2829,883,2879,799,2900,746,2913,730,2920,709,2982,593,2983,578,3003,546,3009,526,3021,515,3023,501,3039,471,3039,453,3063,416}
TP[16] = {2790,306,2774,346,2902,407,2917,406,2927,385,2926,374,2838,330,2800,305}
TP[17] = {6100,280,6107,288,6107,741,6111,843,6126,861,6151,866,6159,877,6180,886,6188,885,6207,901,6219,900,6240,917,6267,924,6290,943,6315,947,6329,961,6353,966,6362,977,6396,988,6405,999,6421,1000,6443,1017,6458,1018,6457,705,6446,698,6430,697,6427,678,6316,678,6315,695,6294,699,6285,708,6281,724,6241,726,6235,722,6227,702,6202,695,6200,616,6180,597,6182,280}
TP[18] = {5543,280,5543,604,5552,601,5562,612,5585,617,5595,629,5612,634,5612,280}
TP[19] = {823,0,822,153,791,170,766,174,760,184,735,198,712,200,703,214,668,231,649,232,644,243,594,263,594,268,583,277,590,326,615,347,633,398,633,464,627,478,625,531,621,534,626,562,626,727,620,748,626,755,628,774,748,778,783,775,798,766,799,740,794,719,749,718,736,725,707,726,683,717,688,645,682,637,681,609,687,606,687,535,678,505,678,487,684,473,708,456,768,448,788,451,809,461,832,457,840,462,866,460,887,452,981,455,992,461,1008,458,1050,463,1073,457,1108,464,1120,460,1159,462,1165,458,1181,463,1220,459,1257,462,1273,458,1292,466,1303,462,1308,468,1309,461,1322,461,1319,471,1325,473,1326,489,1331,490,1332,534,1328,545,1317,550,1200,551,1182,539,1173,542,1171,550,1158,554,1102,554,1090,550,1059,554,1045,550,1028,557,1020,553,975,555,959,549,927,555,870,550,838,554,825,549,804,555,806,574,799,585,806,609,1286,609,1343,615,1348,630,1345,722,1331,719,1329,690,1320,682,1318,697,1313,704,1306,704,1302,716,1288,718,1279,726,1264,726,1264,731,1256,732,1255,736,1244,735,1244,723,1239,718,1124,718,1118,726,1117,743,1108,744,1108,759,1115,759,1116,771,1125,776,1181,777,1184,905,1241,905,1238,857,1243,846,1242,829,1253,822,1250,795,1258,785,1285,776,1315,779,1336,798,1332,823,1334,828,1347,832,1347,905,1486,905,1491,866,1485,862,1471,875,1452,866,1447,844,1451,829,1420,783,1420,774,1429,758,1430,735,1467,738,1466,732,1448,727,1447,722,1466,724,1468,719,1440,706,1429,692,1416,694,1420,683,1418,648,1423,647,1424,629,1445,611,1447,591,1424,587,1424,598,1418,600,1418,580,1409,576,1402,554,1359,546,1344,548,1336,541,1335,519,1336,490,1342,489,1341,474,1348,470,1346,460,1429,460,1468,454,1471,0,1412,0,1413,82,1399,97,1399,152,1379,161,1375,167,1373,199,1363,205,1342,204,1334,198,1334,167,1311,151,1310,99,1307,90,1296,81,1297,0,1239,0,1237,115,1224,112,1213,100,1181,95,1150,71,1128,67,1108,53,1104,42,1096,36,1094,0,1026,0,1026,104,1022,111,1006,115,988,129,982,176,965,181,929,180,919,129,910,120,894,119,892,112,882,109,882,0}
TRACE_DEFS["water"] = TD
-- BEGIN video4 trace replica
TD = { base={221,226,220}, spanx2=3869, spany2=109, frw=992, frh=432, refx=496, refy=216, layers={},
  conf={ spawn={80,302}, cps={{80,302}, {1652,281}, {3208,270}}, goal={4374,259}, kill=801 } }
TD.layers[1] = { color={221,226,220}, ocol={221,226,220}, par=0.12, coll=0, hidden=0, polys={} }
TP = TD.layers[1].polys
TP[1] = {182,508,181,526,195,527,200,522,200,508}
TP[2] = {1230,503,1230,517,1258,516,1258,501}
TP[3] = {1303,497,1275,504,1275,517,1303,518}
TP[4] = {1372,487,1365,495,1365,517,1394,518,1394,488}
TP[5] = {1348,487,1342,485,1330,495,1320,498,1320,517,1348,518}
TP[6] = {1439,480,1431,480,1411,491,1411,517,1439,517}
TP[7] = {1167,473,1143,474,1144,513,1148,516,1169,515,1171,480}
TP[8] = {791,454,791,441,766,442,771,445,771,449}
TP[9] = {1126,440,1120,443,1116,453,1118,459,1125,457}
TP[10] = {1004,426,1004,512,1029,515,1032,504,1032,426}
TP[11] = {1004,383,1004,411,1032,411,1032,402,1026,398,1026,385}
TP[12] = {466,376,455,382,455,392,466,391}
TP[13] = {1117,372,1117,388,1126,391,1126,377,1123,372}
TP[14] = {975,368,972,368,971,379,967,383,948,381,942,388,922,389,922,441,927,441,931,449,939,450,946,446,949,428,961,429,975,425}
TP[15] = {773,374,773,380,787,397,814,396,814,378,808,376,807,371,815,369,815,366,799,368,790,363,783,372}
TP[16] = {437,362,428,362,427,374,424,376,413,375,413,367,421,365,421,361,412,362,413,380,395,380,395,387,400,387,407,394,411,394,413,389,424,391,437,382}
TP[17] = {650,363,650,372,646,377,640,407,634,420,634,432,626,438,675,435,669,432,669,428,679,411,701,406,711,414,706,437,720,434,734,438,742,436,745,428,802,428,808,435,808,459,813,458,813,419,776,419,747,384,747,380,754,379,754,376,729,376,712,358,711,346,694,351,681,349,658,354}
TP[18] = {453,323,454,358,459,358,460,368,466,370,466,358,462,357,461,327,466,322}
TP[19] = {1411,300,1411,342,1424,337,1439,339,1439,306,1421,306}
TP[20] = {1112,292,1117,304,1123,305,1126,290}
TP[21] = {1365,272,1367,321,1372,329,1385,323,1394,323,1394,290,1378,288,1374,273}
TP[22] = {1004,245,1004,270,1015,271,1031,267,1031,245}
TP[23] = {675,250,668,249,664,243,644,244,640,260,595,261,595,265,599,266,599,278,595,280,595,304,612,310,612,325,623,323,625,328,631,327,631,320,638,314,640,305,651,300,644,287,638,285,636,265,651,254,671,254}
TP[24] = {1411,235,1411,248,1421,255,1439,252,1439,245,1429,244,1423,238}
TP[25] = {1320,233,1320,253,1327,266,1327,272,1324,273,1326,291,1337,310,1348,307,1348,268,1341,262,1340,248,1329,247,1326,237}
TP[26] = {975,218,965,218,965,225,955,227,955,233,962,234,965,229,975,229}
TP[27] = {1170,216,1155,224,1143,222,1146,256,1152,259,1159,253,1169,254,1168,263,1143,273,1143,300,1150,302,1147,312,1143,313,1143,433,1152,433,1171,425}
TP[28] = {1369,214,1371,225,1384,237,1394,235,1394,223,1377,214}
TP[29] = {1098,199,1098,225,1107,225,1112,201}
TP[30] = {1275,192,1275,216,1289,224,1289,232,1294,236,1294,243,1291,244,1292,262,1295,271,1301,273,1303,216,1297,215,1294,205,1283,194}
TP[31] = {616,179,616,216,639,216,644,222,643,230,697,230,700,219,679,221,676,217,677,200,689,198,686,190,680,194,666,194,664,183,672,182,675,187,675,179}
TP[32] = {1320,176,1323,180,1331,180,1336,196,1348,201,1348,185,1334,182,1331,176}
TP[33] = {1231,156,1230,182,1238,185,1247,183,1251,189,1258,187,1258,162,1245,154}
TP[34] = {1171,147,1153,148,1150,155,1171,156}
TP[35] = {265,100,264,103,344,103,357,105,358,108,389,108,390,112,399,114,405,124,413,123,412,131,419,135,422,150,409,160,412,161,412,166,422,169,422,174,409,176,410,191,420,196,419,221,408,230,402,246,409,250,411,256,420,255,421,247,431,248,443,266,442,278,428,301,436,307,433,339,416,349,438,351,438,312,454,307,455,287,466,270,466,250,459,242,459,237,466,229,462,169,466,167,467,141,461,109,369,106,363,104,362,99}
TP[36] = {94,99,94,103,186,105,187,108,218,108,219,116,214,125,212,142,229,141,241,145,250,138,253,123,251,111,225,109,220,105,220,99,137,96}
TP[37] = {1411,95,1411,179,1419,183,1428,198,1439,201,1439,97}
TP[38] = {1365,95,1365,152,1378,154,1383,159,1385,168,1392,172,1394,95}
TP[39] = {1320,95,1320,99,1328,106,1330,115,1348,117,1348,95}
TP[40] = {417,96,477,98,478,103,538,105,545,109,594,108,595,129,589,132,592,133,591,142,599,146,595,187,599,226,595,244,625,244,626,228,607,228,604,221,604,174,620,169,636,171,636,159,624,155,625,143,639,140,644,146,645,169,681,170,690,179,712,180,693,175,693,168,697,164,683,163,680,159,680,154,687,149,685,140,669,140,666,133,661,131,662,122,645,117,644,109,611,109,611,103,742,103,744,98,787,98,788,103,1010,103,1011,108,1004,114,1004,151,1025,153,1030,158,1032,104,1041,103,1042,98,1047,98,1044,95,1027,98,990,98,989,95,635,95,634,98,580,98,579,95}
TD.layers[2] = { color={209,212,208}, ocol={209,212,208}, par=0.217143, coll=0, hidden=0, polys={} }
TP = TD.layers[2].polys
TP[1] = {1815,510,1750,511,1750,516,1815,515}
TP[2] = {1668,511,1668,516,1733,516,1733,511,1725,510}
TP[3] = {1586,510,1586,516,1651,516,1651,511}
TP[4] = {1504,511,1504,516,1569,516,1569,511,1561,510}
TP[5] = {1422,512,1422,516,1487,515,1487,510}
TP[6] = {1331,509,1304,510,1301,499,1300,509,1266,511,1266,517,1331,518}
TP[7] = {647,484,636,486,613,499,609,527,605,531,610,531,611,528,651,526,652,517,647,510}
TP[8] = {1014,482,1014,520,1051,524,1079,522,1079,510,1065,512,1039,509,1018,512,1017,504,1022,490,1020,484}
TP[9] = {1249,452,1239,453,1229,461,1222,461,1209,469,1201,468,1190,474,1188,484,1192,486,1192,490,1187,494,1184,512,1247,516,1249,509,1239,509,1238,503,1242,495,1249,495}
TP[10] = {308,448,312,464,323,467,325,454}
TP[11] = {1634,437,1612,435,1605,441,1586,441,1586,500,1617,493,1644,478,1651,478,1650,467,1634,463}
TP[12] = {1266,437,1266,474,1275,475,1276,469,1287,464,1292,465,1292,470,1298,470,1299,465,1331,467,1331,438,1273,445,1273,438,1295,427,1278,430}
TP[13] = {1565,424,1562,424,1560,432,1539,428,1531,437,1517,434,1504,436,1504,502,1513,503,1514,500,1531,495,1546,495,1561,488,1569,488,1569,467,1561,459,1568,443}
TP[14] = {1487,419,1475,419,1459,426,1422,428,1423,501,1439,502,1462,493,1487,491}
TP[15] = {710,414,701,407,684,409,676,416,673,430,669,433,692,431,697,435,705,435,709,432,707,423}
TP[16] = {1813,400,1805,401,1804,405,1793,411,1792,422,1780,437,1771,440,1770,446,1762,445,1750,451,1750,497,1770,493,1773,488,1780,488,1785,482,1815,470,1814,462,1800,461,1792,453,1794,437,1798,436,1799,428,1810,425,1813,418}
TP[17] = {1731,395,1719,405,1719,411,1707,425,1706,432,1696,434,1695,441,1668,445,1668,495,1693,492,1711,479,1733,479,1732,459,1713,461,1713,440,1719,439,1718,429,1728,427,1729,413,1733,408}
TP[18] = {465,408,440,408,433,400,432,387,425,391,413,390,411,395,395,388,383,417,375,424,377,441,370,473,378,473,394,485,408,487,414,484,416,470,424,461,424,454,428,450,461,448,464,440,457,423,463,421,466,424}
TP[19] = {397,357,394,376,411,381,410,362}
TP[20] = {595,307,596,331,599,335,596,379,600,385,600,394,596,395,596,423,600,425,600,433,609,431,625,436,633,432,633,420,649,369,644,362,630,361,627,357,625,346,620,341,624,333,623,324,612,324,611,310}
TP[21] = {1232,286,1231,297,1216,290,1209,331,1190,334,1184,338,1184,376,1190,379,1203,371,1210,357,1213,341,1220,343,1220,357,1215,363,1233,350,1237,350,1242,357,1241,362,1229,368,1224,378,1211,382,1203,393,1224,414,1232,411,1242,397,1238,368,1240,364,1249,362,1248,301,1237,298,1237,291,1233,291}
TP[22] = {1789,283,1789,291,1793,295,1815,297,1815,292,1796,293}
TP[23] = {466,271,456,287,455,308,465,307}
TP[24] = {1300,269,1282,277,1268,293,1266,335,1279,323,1282,313,1287,312,1294,301,1306,304,1309,300,1308,294,1288,292,1292,279,1300,275}
TP[25] = {1017,265,1014,267,1014,400,1031,400,1032,415,1038,422,1079,421,1079,408,1047,406,1047,381,1050,378,1072,379,1072,392,1065,392,1064,385,1059,385,1061,394,1078,394,1079,265,1044,270}
TP[26] = {1422,263,1422,288,1428,288,1436,277,1437,265}
TP[27] = {1249,246,1242,249,1243,273,1249,273}
TP[28] = {1286,238,1266,243,1266,271,1283,266,1292,252,1292,245}
TP[29] = {1266,134,1267,185,1275,176,1276,170,1282,171,1279,191,1273,194,1266,212,1282,212,1290,206,1298,206,1303,214,1315,216,1331,208,1331,150,1311,150,1309,145,1299,149,1286,149}
TP[30] = {348,137,348,140,363,144,362,151,355,149,354,159,365,159,366,164,380,163,382,169,385,163,393,164,389,197,399,195,406,199,404,224,412,225,418,221,420,197,412,196,406,185,399,189,395,176,400,167,410,163,410,154,420,153,418,135,411,131,412,123,402,122,407,129,406,148,391,156,376,156,375,148,371,147,371,140,367,139,367,135}
TP[31] = {1014,100,1014,242,1022,239,1079,240,1079,229,1071,228,1072,214,1079,210,1079,155,1074,155,1071,149,1053,150,1043,147,1036,141,1038,119,1044,112,1049,112,1058,100}
TP[32] = {230,100,231,108,252,111,254,123,250,141,247,142,249,144,256,140,258,130,263,125,265,109,261,108,261,100,246,100,245,109}
TP[33] = {106,102,112,104,113,108,159,108,161,135,187,132,195,140,205,144,212,135,218,116,218,105,222,104,222,100,211,100,214,109,210,123,205,124,204,116,182,120,181,109,174,106,174,100,169,100,168,108,161,107,161,100,141,103,140,96,146,95,146,91,140,91,139,100}
TP[34] = {272,99,316,99,316,91,274,89}
TP[35] = {1249,92,1217,95,1208,87,1184,93,1184,125,1188,139,1192,141,1192,147,1184,149,1184,302,1195,299,1197,283,1193,272,1197,265,1210,263,1229,242,1227,224,1230,221,1238,224,1239,218,1244,217,1249,208}
TD.layers[3] = { color={188,192,188}, ocol={188,192,188}, par=0.314286, coll=0, hidden=0, polys={} }
TP = TD.layers[3].polys
TP[1] = {1025,516,1025,526,1126,526,1126,519,1098,521,1049,515}
TP[2] = {1389,509,1389,514,1489,514,1481,510}
TP[3] = {1241,512,1235,509,1175,511,1172,514}
TP[4] = {2191,507,2089,510,2191,510}
TP[5] = {1852,508,1954,510,1945,507}
TP[6] = {1734,508,1835,510,1826,507}
TP[7] = {1646,508,1717,510,1717,507}
TP[8] = {1272,512,1372,514,1367,509,1313,505,1277,508,1276,512}
TP[9] = {596,515,596,522,601,522,602,528,610,528,612,537,671,533,663,524,646,529,609,528,611,500,603,502}
TP[10] = {403,489,394,492,384,522,386,528,392,527,400,501,404,500}
TP[11] = {374,423,355,423,347,431,325,430,320,427,318,432,314,432,308,447,323,451,326,454,326,465,323,468,308,468,313,473,312,483,333,477,337,471,347,467,369,471,377,433}
TP[12] = {1490,417,1475,421,1455,421,1440,426,1428,434,1427,438,1490,429}
TP[13] = {2191,410,2188,410,2187,418,2179,418,2171,431,2169,444,2179,451,2191,451}
TP[14] = {2072,407,2069,407,2065,421,2057,420,2057,434,2053,435,2054,450,2045,456,2059,450,2072,449}
TP[15] = {2191,371,2174,374,2156,397,2148,398,2147,389,2133,394,2128,407,2108,409,2105,417,2096,421,2095,425,2089,425,2089,450,2093,449,2094,444,2131,440,2138,435,2153,437,2152,429,2167,413,2168,402,2180,395,2181,391,2190,390}
TP[16] = {1835,383,1798,380,1797,375,1801,370,1795,371,1794,379,1769,382,1760,391,1755,391,1749,402,1740,402,1734,408,1734,436,1768,424,1797,427,1805,418,1835,424}
TP[17] = {2072,362,2065,362,2043,392,2036,391,2033,383,2022,384,2012,399,1993,402,1985,413,1971,419,1971,444,1989,438,1991,433,1996,436,2018,435,2032,431,2033,425,2042,423,2043,418,2053,410,2057,396,2067,385,2072,384}
TP[18] = {1954,359,1950,358,1943,372,1934,378,1934,391,1913,389,1912,383,1918,375,1912,372,1903,389,1880,393,1874,400,1867,401,1865,410,1855,411,1852,416,1852,440,1861,440,1864,435,1872,434,1874,424,1891,431,1908,431,1915,425,1935,426,1940,430,1935,455,1954,457,1954,403,1951,402,1951,397,1954,396}
TP[19] = {1713,353,1710,353,1709,367,1662,367,1647,375,1646,390,1631,390,1615,401,1615,427,1633,426,1649,417,1682,417,1703,409,1717,409}
TP[20] = {1869,338,1858,341,1852,336,1852,360,1857,357,1857,347,1868,342}
TP[21] = {688,335,674,339,674,349,689,347}
TP[22] = {1758,317,1749,322,1734,317,1734,347,1740,343,1741,333,1745,332,1748,325,1756,327}
TP[23] = {1648,296,1634,299,1625,292,1615,296,1616,335,1628,324,1630,310,1638,304,1645,307}
TP[24] = {431,250,422,252,427,255,427,260,424,263,416,315,434,314,427,304,427,297,431,295,432,285,439,278,439,264}
TP[25] = {2006,245,2002,245,2002,250,1994,261,1985,262,1987,268,1993,268,2005,276,2007,289,2011,294,2009,312,1996,337,1987,344,1992,349,1995,346,2013,347,2024,336,2027,321,2034,320,2037,326,2034,310,2046,313,2046,307,2038,298,2035,264,2015,258,2011,251,2006,250}
TP[26] = {223,239,184,239,184,268,171,275,169,289,165,294,165,317,161,328,161,344,165,345,165,372,161,374,161,398,165,400,165,449,171,448,177,434,180,402,191,379,193,359,201,328,205,324,223,250}
TP[27] = {1892,219,1894,226,1887,229,1884,239,1874,240,1871,235,1873,242,1878,242,1879,246,1893,254,1895,269,1899,273,1898,293,1883,321,1876,324,1874,331,1901,333,1917,315,1923,315,1915,312,1916,306,1924,306,1925,311,1929,311,1926,291,1931,290,1937,300,1940,290,1930,276,1931,260,1926,239,1904,233}
TP[28] = {1809,201,1800,204,1790,197,1773,198,1773,206,1767,208,1770,218,1782,226,1783,241,1788,245,1789,256,1784,276,1770,301,1760,307,1759,315,1768,317,1769,312,1791,313,1794,306,1801,305,1808,294,1815,294,1816,289,1822,288,1825,280,1819,279,1821,267,1826,267,1828,276,1831,276,1834,262,1825,254,1821,243,1823,219,1817,208,1809,208}
TP[29] = {1166,162,1165,315,1169,316,1165,331,1165,357,1170,342,1175,290,1175,166}
TP[30] = {1668,159,1660,161,1664,165,1663,171,1654,176,1649,176,1648,173,1646,175,1653,183,1656,178,1660,178,1661,184,1675,195,1683,224,1680,242,1672,258,1681,255,1684,259,1684,287,1678,288,1676,282,1672,281,1674,270,1667,263,1664,273,1649,285,1649,289,1653,290,1654,284,1658,284,1659,289,1664,285,1671,285,1672,292,1683,291,1685,285,1701,276,1701,260,1704,256,1709,257,1710,269,1717,263,1714,244,1717,237,1717,177,1705,174,1704,167,1696,170,1684,165,1683,160,1675,162}
TP[31] = {359,158,353,166,355,171,364,172,366,178,380,186,380,208,373,212,378,221,366,226,369,236,367,245,379,246,380,249,395,246,407,252,397,240,397,234,402,230,406,201,399,196,389,196,392,171,382,170,379,163,366,165,365,160}
TP[32] = {2102,131,2089,135,2089,152,2109,150,2112,158,2089,158,2089,166,2097,166,2100,184,2126,186,2127,180,2133,180,2137,191,2135,202,2131,202,2126,193,2117,197,2103,191,2097,209,2089,215,2092,232,2104,231,2108,244,2113,236,2127,237,2126,244,2117,245,2112,251,2115,268,2111,273,2104,274,2100,269,2092,268,2100,273,2103,284,2110,285,2121,294,2121,304,2126,310,2125,322,2113,346,2104,355,2104,358,2117,355,2118,343,2124,342,2126,352,2124,356,2119,356,2121,358,2128,357,2135,351,2140,334,2149,336,2148,323,2153,323,2155,330,2158,330,2158,321,2149,305,2148,281,2140,275,2129,275,2121,263,2115,262,2114,254,2117,251,2136,250,2150,258,2156,271,2166,272,2172,283,2191,282,2191,269,2179,263,2179,259,2191,246,2191,238,2171,242,2159,231,2153,220,2139,213,2139,205,2144,204,2146,210,2158,211,2162,216,2175,219,2183,225,2191,225,2191,200,2187,187,2174,180,2168,166,2151,163,2150,151,2133,149,2128,140}
TP[33] = {1173,109,1165,131,1175,136}
TP[34] = {1971,109,1971,130,1983,122,1993,122,1998,126,1996,132,1980,133,1976,137,1977,150,1975,154,1971,154,1971,173,1984,176,1984,181,1976,192,1971,193,1975,213,1989,215,1993,229,1996,229,1994,220,1998,216,2012,217,2018,234,2031,235,2040,243,2043,253,2050,249,2062,267,2072,269,2072,222,2059,223,2040,198,2033,194,2034,189,2047,189,2050,195,2058,195,2072,202,2068,182,2072,159,2066,159,2061,154,2056,140,2041,138,2036,123,2019,123,2012,112,1991,105}
TP[35] = {1734,122,1734,129,1743,135,1742,149,1752,147,1753,151,1760,150,1765,165,1769,165,1769,153,1774,153,1777,149,1790,150,1794,157,1806,159,1803,164,1805,173,1815,175,1832,196,1835,184,1827,174,1828,165,1835,164,1835,142,1829,131,1831,124,1821,127,1814,120,1798,124,1795,120,1783,120,1764,131,1764,118,1777,109,1758,114,1758,102,1743,121}
TP[36] = {1885,104,1875,98,1866,98,1865,104,1859,104,1859,114,1852,119,1852,124,1866,117,1874,118,1875,109,1881,109}
TP[37] = {234,96,234,101,246,98,246,108,265,109,264,125,258,131,262,135,278,129,276,118,291,127,304,129,311,116,320,116,321,128,328,128,332,132,349,131,358,150,362,150,363,144,355,141,356,134,368,135,368,139,372,140,372,147,376,148,376,155,391,155,405,145,407,129,402,126,399,116,386,120,385,112,388,109,365,109,364,102,347,102,346,96,273,96,272,102,257,102,256,96}
TP[38] = {164,102,164,108,168,108,170,104,182,105,184,123,188,119,204,115,207,135,212,109,192,109,191,102,179,102,178,96,173,96,172,102}
TP[39] = {1887,80,1891,95,1907,98,1909,110,1902,113,1887,111,1893,129,1898,132,1897,138,1882,140,1871,133,1872,139,1884,140,1890,146,1901,147,1908,156,1912,156,1908,148,1916,147,1918,159,1912,163,1894,161,1877,170,1878,155,1888,151,1867,149,1859,160,1855,160,1855,150,1852,147,1853,170,1859,174,1859,186,1868,183,1874,188,1874,194,1879,200,1896,198,1894,195,1881,197,1880,192,1885,187,1903,188,1904,193,1911,194,1911,199,1901,200,1901,209,1904,209,1905,202,1911,202,1914,207,1922,208,1935,222,1935,228,1941,221,1950,221,1954,228,1954,193,1938,182,1933,169,1923,162,1924,157,1937,157,1942,160,1942,164,1951,163,1949,136,1954,106,1933,101,1928,85,1909,84,1907,80}
TP[40] = {1852,93,1859,91,1869,80,1852,80}
TP[41] = {1777,99,1780,105,1790,106,1795,111,1800,110,1801,107,1810,107,1814,109,1815,116,1835,117,1834,111,1819,109,1820,103,1825,103,1835,95,1835,81,1814,80,1808,85,1798,83,1803,89,1800,107,1792,102,1793,95}
TP[42] = {1616,83,1615,89,1623,89,1632,96,1631,109,1634,105,1645,109,1646,105,1652,104,1653,116,1656,118,1671,109,1684,111,1687,118,1696,115,1697,131,1715,139,1717,132,1708,129,1707,124,1717,123,1717,80,1670,80,1657,91,1652,90,1652,80}
TP[43] = {451,80,491,82,492,95,578,95,578,92,569,89,568,83,550,85,525,83,524,80,520,83,505,83,504,80}
TP[44] = {1432,81,1440,84,1440,95,1426,103,1425,123,1445,140,1458,140,1470,130,1490,127,1490,84,1504,81,1489,81,1482,85,1464,83,1463,78,1455,77}
TD.layers[4] = { color={166,170,166}, ocol={166,170,166}, par=0.411429, coll=0, hidden=0, polys={} }
TP = TD.layers[4].polys
TP[1] = {626,537,679,539,675,534}
TP[2] = {39,521,26,528,18,526,19,536,25,539,29,535,39,534}
TP[3] = {251,476,225,476,226,503,222,507,202,507,202,523,199,528,226,532,243,527,248,520,247,492,250,490,243,487,243,481,252,480}
TP[4] = {368,474,363,479,363,485,370,490,370,499,363,502,366,518,356,526,353,535,380,539,427,539,420,530,410,530,407,526,403,501,393,527,383,527,393,492,399,488,387,485,377,475}
TP[5] = {39,451,31,452,28,460,18,460,18,507,24,508,22,516,39,515,40,472,36,471,35,457}
TP[6] = {758,430,758,434,764,439,792,439,793,452,802,453,802,436,805,435,802,430}
TP[7] = {974,428,971,431,952,431,953,444,946,452,931,451,927,444,921,444,923,532,940,532,941,539,964,539,965,533,975,530}
TP[8] = {33,373,23,373,25,387,33,383}
TP[9] = {970,355,948,355,945,370,922,372,922,386,943,385,945,379,967,381}
TP[10] = {922,340,922,356,930,356,931,341}
TP[11] = {2566,334,2555,336,2549,343,2531,342,2528,324,2526,332,2515,335,2514,344,2509,349,2501,349,2497,333,2493,346,2480,351,2482,358,2491,358,2492,363,2474,373,2466,384,2460,384,2457,377,2450,388,2441,391,2432,404,2433,411,2428,415,2428,427,2440,430,2443,426,2462,419,2475,407,2480,407,2483,398,2504,396,2507,385,2513,380,2522,380,2523,389,2526,385,2532,385,2549,364,2566,361}
TP[12] = {2411,325,2403,331,2383,331,2380,320,2370,320,2369,313,2366,313,2364,334,2328,340,2328,346,2319,350,2339,348,2340,353,2319,366,2314,375,2306,376,2305,370,2300,370,2296,380,2285,385,2278,395,2282,403,2273,410,2273,424,2286,427,2289,422,2300,419,2314,406,2326,401,2332,392,2351,389,2351,385,2357,383,2361,374,2372,373,2375,379,2383,380,2396,360,2404,352,2411,351}
TP[13] = {921,313,921,328,943,328,947,332,947,342,975,342,975,328,972,325,964,326,963,320,957,324,941,323,940,318,931,312}
TP[14] = {701,313,694,320,694,327,687,332,692,337,690,347,713,343,714,358,730,374,754,374,752,384,777,417,814,417,816,456,824,456,821,429,825,419,825,363,819,363,816,371,808,372,817,379,815,399,787,399,771,380,769,366,763,370,751,371,752,362,732,364,723,353,725,328,717,320,719,312}
TP[15] = {1230,307,1218,307,1218,332,1225,326}
TP[16] = {2256,317,2240,316,2235,302,2223,306,2223,298,2219,296,2218,316,2212,325,2200,322,2201,306,2196,305,2193,318,2198,319,2197,325,2186,322,2178,325,2180,333,2172,330,2171,334,2165,335,2191,334,2192,339,2167,354,2160,365,2152,366,2151,359,2148,359,2143,365,2146,373,2141,374,2138,369,2130,374,2119,389,2123,397,2118,399,2118,420,2130,422,2137,414,2153,407,2157,401,2165,401,2168,392,2176,390,2181,382,2203,380,2214,363,2221,364,2215,379,2235,381,2235,369,2244,363,2248,352,2256,347}
TP[17] = {2092,281,2079,285,2078,277,2074,274,2075,296,2066,307,2062,307,2060,303,2048,303,2049,296,2056,296,2053,278,2049,279,2044,302,2028,306,2031,309,2030,315,2022,313,2021,317,2013,319,2015,322,2045,315,2046,320,2036,325,2027,336,2019,336,2009,350,1999,352,2000,343,1997,343,1963,377,1967,382,1967,388,1963,389,1963,414,1976,419,1982,408,1990,407,1993,401,2003,397,2006,392,2015,392,2017,382,2027,380,2032,372,2057,369,2101,372,2099,359,2093,357,2094,351,2101,350,2101,299,2092,295}
TP[18] = {1946,257,1939,260,1938,252,1932,256,1934,274,1928,278,1924,287,1920,287,1918,280,1921,274,1916,281,1909,280,1909,274,1913,273,1910,264,1912,250,1900,252,1904,265,1899,277,1894,278,1894,285,1889,286,1887,277,1883,276,1884,284,1880,287,1884,288,1884,293,1877,294,1876,297,1867,296,1866,299,1878,299,1892,294,1900,294,1901,299,1880,316,1871,317,1865,328,1857,334,1848,336,1849,327,1841,327,1841,332,1815,354,1808,364,1808,368,1813,371,1813,375,1808,377,1808,405,1816,412,1822,411,1833,397,1839,397,1845,390,1853,387,1857,380,1873,377,1875,366,1887,358,1905,355,1938,357,1938,350,1946,349,1946,296,1937,295,1937,290,1946,286}
TP[19] = {2470,223,2460,239,2466,240,2467,257,2476,258,2482,269,2489,258,2486,240,2482,236,2479,222}
TP[20] = {968,213,960,216,922,217,921,265,926,265,931,248,936,243,947,242,949,229,954,224,963,223,963,216}
TP[21] = {2317,205,2312,208,2313,215,2305,216,2303,220,2312,222,2316,241,2323,242,2329,254,2333,251,2333,243,2340,240,2335,233,2337,223,2355,224,2355,221,2347,220,2345,216,2330,220,2328,208}
TP[22] = {167,204,165,219,161,222,162,258,167,258,168,250}
TP[23] = {19,201,19,244,23,239,32,241,32,251,35,251,35,224,39,223,39,216,35,215,35,202}
TP[24] = {2165,176,2159,179,2160,186,2153,187,2152,191,2160,193,2161,211,2164,215,2173,217,2176,229,2186,229,2187,220,2193,216,2186,207,2187,196,2198,194,2209,197,2211,193,2203,194,2197,190,2181,192,2176,179}
TP[25] = {940,176,940,182,944,183,944,199,960,201,960,193,956,193,955,186,949,184,950,176}
TP[26] = {364,173,357,173,362,182,360,205,352,207,337,227,326,226,326,235,321,236,320,241,305,239,301,231,298,231,298,236,303,239,303,247,294,253,283,252,271,241,271,237,277,235,280,225,272,224,271,234,255,234,255,255,251,258,234,258,229,255,230,247,235,247,236,251,245,251,245,239,226,239,206,316,206,327,202,328,190,387,186,389,185,398,181,402,178,434,171,449,161,450,161,465,166,467,166,479,161,482,162,493,183,491,183,499,187,499,186,479,179,478,176,470,187,462,187,450,190,447,210,447,211,436,203,435,203,429,215,429,218,432,218,452,215,455,198,455,198,493,211,493,212,470,217,465,228,465,230,437,235,438,235,457,242,458,243,465,254,464,250,410,254,408,255,385,301,384,307,390,306,403,316,431,320,428,351,429,355,422,378,419,380,400,390,395,387,387,392,384,393,356,399,354,399,342,412,332,416,332,422,340,423,333,431,329,433,316,416,316,414,311,426,258,417,256,406,259,401,255,401,250,394,246,379,250,377,246,367,245,366,226,379,220,379,217,374,216,379,204,377,197,373,195,373,190,378,185,366,179}
TP[27] = {2486,144,2479,142,2456,146,2456,151,2450,153,2449,159,2430,171,2430,174,2441,175,2450,169,2471,168,2471,157,2463,156,2461,149,2482,150,2487,148}
TP[28] = {686,137,690,150,684,153,683,160,697,162,698,173,716,175,720,179,718,190,712,190,710,184,691,181,693,198,712,201,712,231,721,231,726,239,715,243,710,252,699,252,694,248,693,251,679,251,677,255,669,257,651,256,640,265,638,271,641,284,652,292,652,296,660,300,668,292,670,275,695,275,699,271,714,275,741,275,745,270,793,270,794,274,799,275,799,270,808,261,816,261,817,266,824,266,822,175,771,175,767,170,767,138,717,140}
TP[29] = {2024,135,2023,141,2012,139,2006,142,2007,149,1999,151,1994,160,2006,160,2010,169,2009,181,2021,184,2029,204,2036,205,2034,198,2038,197,2038,189,2051,188,2051,184,2044,182,2038,173,2039,163,2043,160,2057,160,2061,165,2070,159,2054,156,2047,151,2035,157,2029,156,2028,135}
TP[30] = {186,134,161,138,163,190,189,188,185,184,183,169,187,168,187,160,193,158,191,150,203,149,203,145,191,141}
TP[31] = {931,132,922,135,922,201,934,200,934,188,927,187,923,176,931,172,929,157,933,155,933,151,928,148,927,136,932,135}
TP[32] = {2253,130,2251,135,2241,135,2241,140,2245,141,2245,145,2253,145,2256,155,2256,130}
TP[33] = {1229,127,1230,149,1237,156,1237,129}
TP[34] = {2175,115,2161,119,2161,126,2178,136,2178,140,2166,149,2165,155,2153,155,2162,162,2169,161,2179,140,2188,141,2190,137,2173,130,2172,120,2176,118}
TP[35] = {2339,119,2333,118,2332,114,2319,115,2315,121,2295,130,2290,142,2275,145,2273,152,2293,148,2299,144,2300,139,2307,139,2308,144,2313,144,2315,127,2319,123,2335,125}
TP[36] = {815,109,807,109,806,120,795,120,791,128,785,129,785,160,825,159,824,143,814,136}
TP[37] = {1865,95,1862,102,1856,103,1856,109,1839,121,1854,123,1854,127,1860,130,1860,144,1875,149,1878,165,1889,172,1885,164,1892,159,1890,152,1894,149,1907,151,1907,148,1899,146,1892,133,1892,125,1904,122,1917,127,1925,121,1922,118,1909,118,1902,111,1895,117,1886,118,1881,100,1890,94,1879,95,1874,101,1869,101}
TP[38] = {1644,85,1630,87,1630,96,1635,97,1634,105,1627,105,1626,97,1620,97,1619,109,1609,109,1612,128,1620,127,1633,114,1634,109,1642,106}
TP[39] = {862,92,862,100,890,100,891,108,937,108,938,116,942,115,942,107,953,107,954,101,965,104,968,98,1002,100,999,92,908,92,906,83,901,92}
TP[40] = {528,75,529,91,543,91,544,75}
TP[41] = {2208,90,2191,86,2190,75,2175,73,2164,77,2161,83,2153,87,2146,87,2139,102,2118,108,2118,116,2131,117,2143,111,2144,108,2157,109,2160,95,2167,94,2168,88,2177,88,2187,93,2187,98,2179,105,2183,116,2191,114,2188,110,2189,102,2204,104,2210,102}
TP[42] = {2008,77,2008,87,2023,90,2023,105,2040,101,2041,91,2023,88,2019,81,2020,76,2035,71,2020,71}
TP[43] = {1598,68,1601,73,1616,72,1617,75,1651,76,1652,72,1683,73,1684,122,1687,122,1687,73,1683,73,1682,69,1641,68,1640,73,1622,73,1621,68}
TD.layers[5] = { color={126,132,129}, ocol={126,132,129}, par=0.508571, coll=0, hidden=0, polys={} }
TP = TD.layers[5].polys
TP[1] = {919,530,919,539,940,537,940,533,923,533}
TP[2] = {188,532,191,539,212,539,216,535,213,530,210,533,200,529}
TP[3] = {1482,489,1470,486,1467,491,1446,490,1443,492,1443,499,1459,495,1469,499,1482,494}
TP[4] = {39,460,36,463,40,464,41,472,40,534,32,534,27,539,39,539,41,534,47,533,49,525,60,524,60,521,46,513,48,465,40,464}
TP[5] = {825,460,818,457,801,462,799,454,784,457,773,453,772,462,765,466,764,473,712,473,710,477,699,477,697,473,670,473,659,476,657,482,652,483,654,490,649,494,649,508,656,515,656,522,663,522,668,527,676,525,677,531,690,535,700,533,704,537,715,536,720,526,737,528,738,523,747,524,744,529,746,532,750,529,772,532,774,525,782,517,786,517,788,523,800,522,802,526,808,527,819,516,820,499,824,498}
TP[6] = {437,454,434,461,421,465,416,484,411,487,415,495,407,501,408,521,415,521,418,529,426,535,429,531,434,531,446,537,461,539,460,530,466,523,466,506,463,501,466,451}
TP[7] = {39,436,28,443,23,453,18,453,18,458,28,459,31,451,39,449}
TP[8] = {243,437,230,438,229,465,217,466,213,470,211,494,196,492,192,465,196,463,198,454,217,452,215,430,203,430,203,440,210,440,211,447,190,448,188,462,177,472,179,477,187,479,185,494,162,494,161,482,165,479,165,467,155,466,155,485,161,490,161,495,158,496,156,511,145,512,139,519,144,519,153,529,173,525,175,507,222,506,225,503,225,475,243,475,244,487,251,487,247,476,254,475,254,465,247,466,246,460,234,457,234,447,244,445}
TP[9] = {2620,390,2611,393,2598,406,2598,411,2610,409,2611,401,2620,396}
TP[10] = {2425,384,2410,391,2402,400,2402,406,2416,402,2416,394,2425,388}
TP[11] = {2232,373,2215,381,2206,391,2205,399,2219,395,2223,382,2233,378}
TP[12] = {1563,372,1563,376,1578,389,1583,401,1590,400,1588,390,1569,373}
TP[13] = {2040,360,2029,363,2012,379,2010,388,2026,386,2031,369,2041,366}
TP[14] = {2868,349,2847,353,2834,376,2843,373,2850,363,2867,354}
TP[15] = {2681,339,2657,345,2656,351,2635,375,2654,365,2659,356,2668,353}
TP[16] = {919,329,919,386,921,372,945,369,948,354,970,354,975,359,975,343,947,343,943,329}
TP[17] = {2495,325,2483,327,2480,320,2479,327,2466,333,2464,342,2444,365,2463,355,2470,344,2493,331}
TP[18] = {718,316,723,325,721,335,725,347,732,347,735,352,744,352,743,361,752,362,751,370,766,366,783,369,787,361,793,361,796,365,824,361,803,326,756,326,725,311}
TP[19] = {452,310,451,315,440,320,439,353,411,353,409,347,418,346,417,336,404,337,400,351,408,360,423,360,421,374,426,371,427,359,438,359,445,369,445,380,439,381,440,403,443,406,466,406,465,393,453,392,452,367,458,366,458,363,452,362,451,335,452,322,466,320,466,310}
TP[20] = {1521,309,1530,321,1541,316,1529,313,1528,307}
TP[21] = {2942,308,2926,305,2911,310,2906,315,2906,331,2925,333,2931,326,2942,324}
TP[22] = {2311,308,2297,309,2296,301,2293,301,2291,313,2278,316,2279,323,2252,353,2275,340,2285,326,2293,326}
TP[23] = {2751,291,2742,292,2726,301,2717,297,2721,301,2723,321,2743,321,2751,315}
TP[24] = {2131,286,2114,288,2110,279,2107,293,2100,295,2097,291,2092,297,2093,304,2086,309,2075,327,2062,334,2062,340,2065,341,2069,334,2090,322,2100,307,2109,306,2116,298,2126,294}
TP[25] = {2559,276,2547,279,2539,287,2543,306,2559,306}
TP[26] = {800,270,800,276,824,276,824,267,804,266}
TP[27] = {2365,260,2360,264,2359,286,2367,288}
TP[28] = {1028,237,1023,244,1023,305,1028,305}
TP[29] = {976,233,973,238,943,235,937,238,936,245,928,255,927,276,919,280,919,309,922,312,931,311,944,322,956,324,963,321,964,325,975,325}
TP[30] = {1006,229,1000,235,992,235,992,322,1000,322,1000,345,992,346,992,354,1006,353}
TP[31] = {40,224,36,224,35,240,23,240,19,252,18,342,22,344,27,358,18,363,18,384,22,384,23,372,32,372,39,367}
TP[32] = {670,172,670,177,678,179,678,188,666,188,666,191,680,191,681,173}
TP[33] = {24,168,27,185,21,187,20,200,39,200,39,173,37,170}
TP[34] = {711,203,707,199,679,202,682,219,692,219,694,205,702,208,700,233,649,236,648,232,642,231,642,222,638,218,615,218,614,204,610,202,610,184,613,179,639,175,650,177,650,173,641,172,638,156,637,174,611,173,607,179,608,224,628,228,628,245,596,246,595,259,637,258,641,254,642,242,665,241,669,247,692,251,692,241,709,238,713,224}
TP[35] = {346,132,343,138,331,141,331,132,315,136,312,129,307,127,306,130,291,132,290,135,262,138,257,145,236,147,226,144,217,148,208,145,207,150,193,149,192,158,187,160,188,168,184,169,184,183,189,185,189,189,164,191,172,228,169,229,168,258,161,259,161,273,177,272,182,268,184,237,245,238,245,252,239,251,239,245,230,248,229,253,234,257,254,255,255,234,271,233,272,241,277,241,281,250,289,252,301,247,304,238,319,240,321,235,325,235,326,225,337,226,346,212,361,200,361,182,352,173,352,145,344,139}
TP[36] = {1023,113,1025,177,1028,171,1028,119}
TP[37] = {816,109,815,136,820,141,825,141,828,117,832,116,831,109}
TP[38] = {47,109,37,109,36,136,29,140,19,140,18,156,21,145,40,145,41,154,44,153,47,147}
TP[39] = {1006,98,989,98,971,93,973,100,968,101,952,95,956,98,955,103,940,106,943,115,934,118,927,127,930,131,929,148,934,151,929,164,933,183,927,186,935,188,935,200,929,206,920,206,920,216,960,215,972,210,972,195,975,191,976,108,992,109,992,193,997,197,1006,195}
TP[40] = {625,88,627,97,642,98,637,108,647,108,653,118,666,120,666,128,670,129,672,137,767,137,768,170,771,174,806,175,825,172,825,161,784,160,784,129,791,127,795,119,806,119,806,109,799,107,799,98,790,97,790,88}
TP[41] = {99,88,102,97,120,91,120,88}
TD.layers[6] = { color={78,90,83}, ocol={78,90,83}, par=0.605714, coll=0, hidden=0, polys={} }
TP = TD.layers[6].polys
TP[1] = {738,529,728,527,714,539,738,539}
TP[2] = {147,527,151,539,187,539,186,534,175,529}
TP[3] = {595,510,604,499,647,479,657,478,659,473,639,473,633,477,619,473,596,473}
TP[4] = {41,539,131,539,131,533,138,528,138,516,145,511,153,514,159,511,159,490,154,487,154,468,142,468,141,465,96,465,95,468,85,468,79,464,49,465,48,505,50,515,58,519,59,524,49,526,48,533,42,535}
TP[5] = {1532,429,1529,452,1542,452,1545,444,1534,440}
TP[6] = {1893,373,1884,374,1876,380,1865,414,1872,413,1881,388}
TP[7] = {1838,356,1856,382,1861,383,1860,372,1842,355}
TP[8] = {825,358,825,310,821,315,811,315,809,311,750,311,739,315,756,325,803,325,818,353}
TP[9] = {1727,324,1709,335,1704,335,1701,331,1693,344,1677,351,1658,328,1657,319,1643,302,1624,301,1623,306,1635,309,1636,315,1640,316,1640,326,1628,329,1628,332,1641,343,1646,354,1644,369,1672,376,1683,389,1683,395,1676,398,1668,389,1662,388,1653,397,1663,418,1654,427,1650,427,1629,452,1598,456,1597,450,1601,449,1598,446,1594,449,1595,457,1589,458,1575,444,1561,446,1555,455,1552,471,1542,479,1531,478,1529,491,1559,491,1569,481,1582,481,1591,477,1605,480,1611,488,1640,487,1654,470,1658,470,1665,478,1672,475,1675,465,1670,461,1670,449,1685,435,1706,431,1724,413,1732,392,1741,388,1740,360,1725,381,1711,394,1706,394,1700,381,1685,368,1685,364,1698,351,1714,343}
TP[10] = {1802,298,1804,308,1807,309,1821,303,1810,295}
TP[11] = {1535,266,1549,278,1557,280,1557,285,1554,286,1556,291,1568,289,1583,299,1598,304,1610,317,1615,314,1616,307,1599,295,1588,267,1584,267,1588,291,1583,292,1568,286,1568,277,1554,277}
TP[12] = {1740,185,1726,201,1726,206,1716,221,1701,235,1690,238,1689,267,1686,276,1681,279,1681,285,1653,299,1653,304,1666,305,1684,299,1697,299,1700,293,1699,274,1706,256,1720,254,1733,246,1741,247,1741,244,1725,244,1717,240,1718,233,1739,199}
TP[13] = {587,109,570,109,573,123,569,128,574,134,577,134,575,123,587,123}
TP[14] = {31,109,18,109,18,121,26,119}
TP[15] = {1072,83,1055,83,1055,160,1058,162,1055,174,1058,181,1055,229,1060,197,1061,155,1066,142}
TP[16] = {801,83,800,95,806,96,808,108,831,108,833,115,838,115,842,106,853,104,854,99,861,96,869,96,876,105,897,100,897,96,881,96,880,83}
TP[17] = {429,83,429,95,446,95,448,108,470,110,469,121,474,115,484,113,486,108,500,108,503,104,511,104,514,108,549,108,550,116,553,111,557,111,562,118,565,117,565,96,546,96,545,83}
TP[18] = {48,109,47,143,51,146,64,139,74,142,75,138,90,136,95,142,117,141,123,150,141,150,149,157,149,161,144,162,151,166,154,156,159,154,152,109,130,109,129,96,110,96,109,87,105,83,81,83,80,96,57,98,55,108}
TP[19] = {2578,49,2620,51,2612,45}
TP[20] = {879,52,910,52,910,45,880,45}
TP[21] = {2843,48,2822,43,2811,49,2802,47,2800,51,2841,51}
TD.layers[7] = { color={33,37,39}, ocol={33,37,39}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[7].polys
TP[1] = {1498,459,1544,460,1564,456,1583,458,1590,453,1604,457,1645,457,1647,453,1662,456,1751,456,1752,459,1758,459,1760,453,1783,455,1787,445,1782,440,1766,441,1765,448,1662,447,1661,443,1656,447,1638,445,1591,448,1567,447,1566,440,1574,439,1571,437,1564,439,1563,448,1543,448,1542,457}
TP[2] = {1157,446,1159,452,1168,452,1170,456,1178,457,1179,464,1186,463,1187,460,1192,463,1207,461,1207,453,1222,449,1222,444,1218,441,1203,453,1186,457,1186,417,1181,422,1178,445,1173,446,1166,438,1162,438,1161,445}
TP[3] = {2356,398,2255,397,2255,405,2279,405,2286,409,2303,405,2355,405}
TP[4] = {256,387,256,475,253,487,256,489,257,522,239,531,219,535,219,539,313,539,320,531,326,532,324,539,336,533,330,530,332,524,344,523,345,528,354,525,346,523,347,518,355,515,352,503,355,490,352,482,344,488,323,493,319,501,310,501,304,507,295,506,296,500,307,499,295,498,292,493,295,475,294,461,291,459,294,450,292,432,295,420,301,419,292,415,292,409,302,408,302,404,294,403,292,394,300,386}
TP[5] = {2482,394,2475,393,2469,399,2461,400,2457,391,2461,381,2459,379,2437,405,2399,411,2391,402,2377,399,2369,405,2364,423,2354,431,2347,428,2349,435,2330,453,2330,460,2346,460,2350,447,2363,434,2405,429,2417,431,2418,435,2434,437,2428,420,2429,414,2442,413,2451,423,2451,429,2458,423,2472,428,2476,417,2471,415,2471,408,2476,397}
TP[6] = {4154,376,4152,372,4148,372,4148,378,4144,379,4136,392,4127,389,4118,377,4107,375,4107,380,4111,380,4119,390,4132,394,4133,403,4137,403,4142,389,4152,384}
TP[7] = {4492,365,4499,382,4526,397,4528,406,4532,405,4534,395,4548,386,4547,383,4539,382,4532,394,4523,395,4516,383,4505,379,4506,368,4501,368,4498,363}
TP[8] = {1878,299,2019,298,2027,295,2051,297,2057,287,2006,286,2005,283,2002,286,1931,287,1911,284,1901,286,1896,283,1894,286,1878,286}
TP[9] = {2255,282,2255,292,2272,294,2343,293,2348,297,2349,291,2368,292,2370,289,2369,281,2328,282,2310,279,2308,282}
TP[10] = {2111,286,2113,297,2118,294,2126,297,2138,295,2137,286,2128,277,2116,279}
TP[11] = {2447,272,2452,287,2439,299,2445,303,2451,315,2448,329,2456,333,2471,334,2485,348,2486,353,2494,351,2499,358,2506,358,2507,368,2513,379,2514,367,2522,349,2533,341,2551,336,2546,320,2537,318,2513,353,2502,351,2486,330,2486,324,2501,309,2511,307,2534,277,2510,296,2500,295,2498,302,2485,312,2487,320,2484,324,2473,327,2468,315,2475,314,2475,310,2466,306,2467,299,2462,287}
TP[12] = {2503,226,2493,234,2495,252,2490,256,2489,262,2479,264,2479,254,2465,260,2461,267,2476,269,2495,265}
TP[13] = {2388,207,2397,258,2388,258,2373,248,2368,250,2417,278,2420,272,2405,260,2396,235,2400,224,2393,223}
TP[14] = {59,144,58,149,63,150,63,155,53,159,51,167,45,168,44,164,40,167,41,204,37,205,41,209,42,236,41,372,38,373,41,396,31,405,18,405,18,424,29,421,31,427,41,426,41,461,44,463,79,463,85,467,95,467,96,464,142,464,143,467,152,467,153,464,159,464,159,370,163,368,163,364,159,363,159,328,162,316,157,271,160,270,161,213,157,212,160,167,156,164,156,173,146,172,139,166,139,158,132,156,129,162,123,162,121,155,124,152,110,145,110,149,114,150,114,154,109,155,108,150,101,148,101,143,95,143,95,149,89,153,81,150,67,152,64,146,71,143}
TP[15] = {2558,122,2552,130,2547,130,2547,140,2525,178,2532,178}
TP[16] = {485,112,489,116,488,129,481,134,480,143,468,152,470,174,465,240,468,247,470,355,468,482,464,494,467,504,467,539,601,539,603,533,593,535,588,529,588,523,593,522,596,472,619,472,633,476,639,472,698,471,703,476,712,471,763,471,754,468,756,457,751,445,740,448,728,445,723,448,706,445,699,448,671,446,666,449,655,446,636,449,632,445,619,446,618,449,607,446,599,449,590,447,590,440,599,442,594,439,593,355,596,344,593,336,591,278,593,234,596,226,592,203,593,152,592,149,577,144,567,130,557,125,557,111,554,117,548,117,539,109,533,109,531,104,527,104,527,109,522,109,521,103,503,103,506,106,504,112}
TP[17] = {920,96,902,97,905,100,904,106,887,103,886,106,871,107,870,102,883,97,873,96,865,101,870,104,869,109,859,110,853,117,847,117,846,110,839,114,839,118,846,119,846,124,840,129,833,128,833,132,839,133,839,139,834,144,827,140,826,175,823,182,826,192,825,277,797,278,791,272,756,272,750,277,716,277,704,273,696,277,671,277,670,292,659,307,623,337,648,361,687,321,691,321,702,310,729,310,738,314,745,314,750,310,809,310,811,314,825,314,827,420,823,432,826,440,826,539,918,539,918,145,914,143,910,123,914,118,911,101,920,101}
TD.layers[8] = { color={2,2,3}, ocol={2,2,3}, par=1, coll=1, hidden=0, polys={} }
TP = TD.layers[8].polys
TP[1] = {1171,457,1173,479,1177,488,1185,494,1187,488,1198,479,1204,462,1179,465,1178,458}
TP[2] = {2287,458,2302,460,2316,457,2319,460,2329,459,2329,455,2317,455,2305,445,2298,444,2290,450}
TP[3] = {2511,356,2499,359,2494,352,2486,354,2484,361,2477,365,2467,380,2462,381,2458,389,2461,400,2509,381,2510,372,2506,363}
TP[4] = {2418,277,2424,290,2434,292,2437,296,2442,296,2453,287,2446,279,2445,270,2439,267}
TP[5] = {1203,236,1205,256,1209,264,1217,268,1225,260,1231,244,1212,241}
TP[6] = {2511,206,2495,207,2489,219,2494,230,2519,218,2519,215,2510,214}
TP[7] = {977,109,977,539,991,539,991,109}
TP[8] = {0,109,0,539,17,539,17,109}
TP[9] = {1038,87,1038,517,1052,517,1052,87}
TP[10] = {1459,67,1459,497,1473,497,1473,67}
TP[11] = {1082,67,1082,497,1096,497,1096,67}
TP[12] = {2617,30,2617,460,2631,460,2631,30}
TP[13] = {2240,30,2240,460,2254,460,2254,30}
TP[14] = {1863,30,1862,456,1863,460,1877,460,1877,30}
TP[15] = {1528,26,1528,442,1522,450,1522,456,1542,456,1543,447,1560,445,1542,442,1542,26}
TP[16] = {2917,25,2917,455,2931,455,2931,25}
TP[17] = {2660,22,2660,452,2674,452,2674,22}
TP[18] = {1262,24,1240,25,1236,21,1232,26,1240,54,1245,55,1252,50}
TP[19] = {2885,20,2885,450,2899,450,2899,20}
TP[20] = {2754,19,2754,449,2768,449,2768,19}
TP[21] = {2707,19,2707,449,2721,449,2721,19}
TP[22] = {4846,16,4846,446,4860,446,4860,16}
TP[23] = {4469,16,4469,446,4483,446,4483,439,4494,438,4500,429,4508,432,4507,419,4525,412,4528,397,4517,394,4513,399,4506,400,4507,407,4497,414,4496,421,4491,424,4483,423,4483,365,4499,362,4499,358,4494,351,4483,349,4483,16}
TP[24] = {4092,16,4092,446,4106,446,4106,434,4113,431,4113,428,4107,427,4108,420,4121,411,4129,411,4133,406,4133,394,4127,394,4124,390,4118,395,4106,394,4106,376,4121,374,4132,361,4127,361,4119,369,4106,364,4106,16}
TP[25] = {3715,16,3715,446,3729,446,3729,16}
TP[26] = {3338,16,3338,446,3352,446,3352,16}
TP[27] = {2961,16,2960,20,2944,20,2944,450,2960,450,2961,455,2975,455,2975,16}
TP[28] = {1751,16,1751,438,1741,446,1765,447,1765,16}
TP[29] = {1710,16,1710,442,1706,446,1724,446,1724,16}
TP[30] = {1628,16,1614,16,1614,442,1577,442,1566,446,1632,446,1628,442}
TP[31] = {2800,11,2800,441,2814,441,2814,11}
TP[32] = {2845,8,2845,438,2859,438,2859,8}
TP[33] = {1796,3,1796,433,1810,433,1810,3}
TP[34] = {4811,0,4821,3,4821,15,4835,15,4835,3}
TP[35] = {3834,0,3834,15,3861,15,3861,3}
TRACE_DEFS["video4"] = TD
-- END video4 trace replica
TD = nil
TP = nil

-- ============================================================================
-- END scripts/src/86_trace_data.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/87_trace_ipoints.lua
-- ============================================================================
-- 描摹关设计锚点(手调数据;有该数据的关停用自动撒点)
-- 坐标系 = 86_trace_data 世界坐标(竹梅:×2 + 平移,世界约 4332x880)
-- kind: gust=竹梢风袂(刷新冲刺+上升) key=蓄墨苞(激活鬼阶组) pool=墨池 char=拾字
-- 梅花点苞不在此列:仍由红色隐藏层原位聚类生成(视频原生花位)
TRACE_IPTS = {}
TRACE_IPTS.zhumei = {
    ipts = {
        -- 起|左段
        { kind = "pool", x1 = 60,   x2 = 540,  y = 760 },
        { kind = "deco", x = 350,  y = 600 },
        { kind = "gust", x = 716,  y = 520 },
        { kind = "deco", x = 1245, y = 520 },
        -- 转|中段竖塔
        { kind = "gust", x = 1748, y = 64 },
        { kind = "char", x = 1810, y = 16,  ch = "疏" },
        -- 承|大断口(2100→2950):蓄墨苞实体化三根浮墨条(两岸各一苞,可回程)
        { kind = "key",  x = 2148, y = 392, grp = 1 },
        { kind = "key",  x = 2962, y = 596, grp = 1 },
        { kind = "char", x = 2600, y = 452, ch = "影" },
        { kind = "pool", x1 = 2480, x2 = 2900, y = 760 },
        -- 合|梅树区
        { kind = "gust", x = 3032, y = 330 },
        { kind = "char", x = 3520, y = 792, ch = "横" },
        { kind = "deco", x = 3900, y = 600 },
        { kind = "char", x = 4290, y = 262, ch = "斜" },
    },
    -- 苔点:断口底右壁的逃生暗示(纯视觉,非交互)
    hints = {
        { x = 2912, y = 792 }, { x = 2926, y = 748 }, { x = 2940, y = 704 },
    },
    -- 区内完整包含的碰撞体转为鬼阶(虚影,激活后 300 帧实体)
    ghosts = {
        { zone = { 2200, 380, 2880, 620 } },
    },
}

TRACE_IPTS.bamboo_v2 = {
    ipts = {
        { kind = "char", x = 1100, y = 2080, ch = "咬" },
        { kind = "char", x = 1550, y = 2100, ch = "定" },
        { kind = "char", x = 1840, y = 2200, ch = "青" },
        { kind = "char", x = 2010, y = 1530, ch = "山" },
        { kind = "char", x = 2500, y = 1180, ch = "不" },
        { kind = "char", x = 2760, y = 1150, ch = "放" },
        { kind = "char", x = 3200, y = 1050, ch = "松" },
        { kind = "char", x = 4010, y = 1080, ch = "千" },
        { kind = "char", x = 4400, y = 840, ch = "磨" },
        { kind = "char", x = 4560, y = 1460, ch = "万" },
        { kind = "char", x = 4860, y = 1860, ch = "击" },
        { kind = "char", x = 6000, y = 1800, ch = "还" },
        { kind = "char", x = 6500, y = 1800, ch = "坚" },
        { kind = "char", x = 7000, y = 1600, ch = "劲" },
        { kind = "char", x = 7600, y = 1600, ch = "任" },
        { kind = "char", x = 8000, y = 1600, ch = "尔" },
        { kind = "char", x = 8250, y = 1550, ch = "东" },
        { kind = "char", x = 8350, y = 1580, ch = "西" },
    },
    hints = {
        { x = 3700, y = 1500 }, { x = 3750, y = 1550 },
        { x = 5200, y = 2280 }, { x = 5250, y = 2290 },
    },
}

-- ============================================================================
-- END scripts/src/87_trace_ipoints.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/88_bamboo_scroll.lua
-- ============================================================================
-- 墨竹长卷(第18关重制):手绘前景地形 = 画题本身(本阶段只做前景)
-- 间距依据 docs/movement_spec.md(standard 组):
--   苞→苞 ≥780(> 跳+冲787×0.95=748 不可逾越) → 不触苞铺路,物理上过不去
--   叶台跳段 ≤460(纯跳必经上限);末台→下一苞 ≈390~440(跳或跳+冲)
--   台阶 ≤175;杈梯间距 ≤155
-- 叶台 = 画出的横枝(枝即碰撞体,完全贴合笔画),叶生枝上
-- 本文件不得新增 chunk 顶级 local(bundle 199/200),全部用全局。

BAMBOO_DATA = {
    worldW = 4750, worldH = 900, kill = 1060, zoom = 0.70,
    paper = { 243, 239, 229 },
    spawn = { 140, 780 },
    cps = { { 140, 780 }, { 2430, 608 }, { 3110, 308 } },
    goal = { 4560, 740 },
    grounds = {
        { 0, 812, 240, 798, 520, 806, 700, 818, 700, 900, 0, 900 },
        { 2340, 620, 2540, 614, 2548, 900, 2332, 900 },
        { 4380, 796, 4580, 788, 4750, 792, 4750, 900, 4380, 900 },
    },
    -- 竿(墨绿,可攀可踏):bud=true → 梢为未完之笔,触苞铺墨梁
    stalks = {
        -- 起|卷首丛:边竹 + 主攀竹(杈梯) + 笋
        { x1 = 80,  y1 = 815, x2 = 112, y2 = 520, bow = 10, w = 32 },
        { x1 = 320, y1 = 815, x2 = 350, y2 = 470, bow = -22, w = 64,
            stubs = { { 660, -1 }, { 530, 1 } }, bud = true,
            pads = { { 560, 425 }, { 755, 395 } } },
        { x1 = 555, y1 = 815, x2 = 565, y2 = 645, bow = -8, w = 40 },  -- 笋
        -- 承|涧上双丛:苞②③,墨梁是唯一的路(苞间 800,超不可逾越线)
        { x1 = 1136, y1 = 1050, x2 = 1158, y2 = 520, bow = 10, w = 32 },
        { x1 = 1200, y1 = 1050, x2 = 1190, y2 = 355, bow = 16, w = 50, bud = true,
            pads = { { 1400, 325 }, { 1600, 355 } } },
        { x1 = 2000, y1 = 1050, x2 = 1990, y2 = 325, bow = -14, w = 50, bud = true,
            pads = { { 2170, 415 }, { 2300, 530 } } },
        { x1 = 2062, y1 = 1050, x2 = 2046, y2 = 470, bow = -12, w = 30 },
        -- 转|风压斜竹长坡(踏竿喘息段,cp2→cp3)
        { x1 = 2520, y1 = 624, x2 = 3110, y2 = 330, bow = -30, w = 56 },
        -- 合|末苞垂梢长下行(cp3→卷尾涧宽1270,滑翔+跳冲也不可逾越)
        { x1 = 3510, y1 = 1050, x2 = 3500, y2 = 295, bow = 12, w = 48, bud = true,
            pads = { { 3680, 400 }, { 3810, 540 }, { 3940, 680 }, { 4140, 760 } } },
        { x1 = 4480, y1 = 790, x2 = 4460, y2 = 520, bow = -12, w = 46 },  -- 卷尾丛
        { x1 = 4580, y1 = 790, x2 = 4596, y2 = 560, bow = 10, w = 34 },
    },
    -- 中景:淡竹剪影(视差 0.6,纯景无碰撞;hero 一根粗竹立在主笔斜竹身后)
    midBamboo = {
        { x1 = 230, y1 = 1050, x2 = 260, y2 = 150, bow = 20, w = 54 },
        { x1 = 640, y1 = 1050, x2 = 600, y2 = 60, bow = -26, w = 72 },
        { x1 = 1010, y1 = 1050, x2 = 1040, y2 = 230, bow = 16, w = 44 },
        { x1 = 1480, y1 = 1050, x2 = 1430, y2 = 90, bow = -30, w = 64 },
        { x1 = 1860, y1 = 1050, x2 = 1900, y2 = 180, bow = 22, w = 50 },
        { x1 = 2330, y1 = 1050, x2 = 2290, y2 = 40, bow = -20, w = 80 },
        { x1 = 2720, y1 = 1050, x2 = 2760, y2 = 20, bow = 24, w = 110 },  -- hero
        { x1 = 3160, y1 = 1050, x2 = 3120, y2 = 160, bow = -18, w = 56 },
        { x1 = 3640, y1 = 1050, x2 = 3680, y2 = 90, bow = 20, w = 66 },
        { x1 = 4100, y1 = 1050, x2 = 4070, y2 = 200, bow = -14, w = 48 },
        { x1 = 4480, y1 = 1050, x2 = 4510, y2 = 60, bow = 16, w = 76 },
    },
    -- 远景:雾山(视差 0.3)
    mountains = {
        { 0, 760, 380, 600, 760, 700, 1180, 560, 1620, 690, 2080, 590, 2520, 700, 3000, 580, 3480, 680, 3980, 600, 4400, 690, 4750, 620, 4750, 900, 0, 900 },
        { 0, 820, 520, 720, 1080, 790, 1700, 700, 2380, 800, 3060, 710, 3760, 790, 4380, 720, 4750, 780, 4750, 900, 0, 900 },
    },
}

BAMBOO_DATA_22 = {
    worldW = 8400, worldH = 2600, kill = 2720, zoom = 0.70,
    paper = { 243, 239, 229 },
    spawn = { 140, 2280 },
    cps = { { 140, 2280 }, { 2050, 1700 }, { 2560, 1180 }, { 4340, 1100 }, { 4950, 2380 }, { 7030, 1600 }, { 8260, 1780 } },
    goal = { 8260, 1780 },
    killZones = {
        { 3550, 1700, 3900, 2700 },
        { 5040, 2280, 5660, 2700 },
    },
    inkPools = {
        { x1 = 4700, x2 = 5120, y = 2440 },
    },
    grounds = {
        { 0, 2320, 260, 2265, 620, 2285, 900, 2310, 900, 2600, 0, 2600 },
        { 1500, 2235, 1720, 2175, 1880, 2250, 1880, 2600, 1500, 2600 },
        { 4780, 2440, 5050, 2420, 5120, 2600, 4780, 2600 },
        { 5660, 2360, 5920, 2320, 6000, 2600, 5660, 2600 },
        { 6900, 1650, 7160, 1620, 7220, 2600, 6900, 2600 },
        { 8140, 1830, 8400, 1780, 8400, 2600, 8140, 2600 },
    },
    staticBeams = {
        { x = 1030, y = 2135, hw = 70 }, { x = 1300, y = 2090, hw = 80 }, { x = 1660, y = 2160, hw = 130 },
        { x = 1900, y = 2020, hw = 72 }, { x = 2050, y = 1700, hw = 130 }, { x = 2460, y = 1200, hw = 135 },
        { x = 2760, y = 1185, hw = 110 }, { x = 3480, y = 1120, hw = 110 }, { x = 4340, y = 1100, hw = 130 },
        { x = 2880, y = 1700, hw = 95 }, { x = 3320, y = 1710, hw = 95 }, { x = 4120, y = 1685, hw = 105 },
        { x = 4720, y = 1500, hw = 80 }, { x = 4950, y = 2380, hw = 130 }, { x = 5010, y = 2330, hw = 70 }, { x = 5660, y = 2320, hw = 135 },
        { x = 6990, y = 1620, hw = 125, spring = true }, { x = 8260, y = 1780, hw = 150 },
    },
    stalks = {
        { x1 = 80, y1 = 2325, x2 = 112, y2 = 2070, bow = 10, w = 32 },
        { x1 = 390, y1 = 2315, x2 = 430, y2 = 1960, bow = -24, w = 64,
            stubs = { { 2180, -1 }, { 2060, 1 } }, bud = true, mode = "bridge",
            pads = { { 820, 2040 }, { 1210, 2080 }, { 1600, 2160 } } },
        { x1 = 565, y1 = 2320, x2 = 590, y2 = 2140, bow = -8, w = 42 },
        { x1 = 1760, y1 = 2260, x2 = 1760, y2 = 1700, bow = 18, w = 60,
            stubs = { { 2140, 1 }, { 1985, -1 }, { 1830, 1 } } },
        { x1 = 2000, y1 = 2260, x2 = 2000, y2 = 1690, bow = -18, w = 60,
            stubs = { { 2090, -1 }, { 1935, 1 }, { 1780, -1 } } },
        { x1 = 2080, y1 = 1700, x2 = 2080, y2 = 1560, bow = 10, w = 48, bud = true, mode = "ladder",
            pads = { { 2200, 1500, 50 }, { 1990, 1360, 50 }, { 2210, 1220, 50 }, { 2460, 1200, 60 } } },
        { x1 = 2360, y1 = 1620, x2 = 2360, y2 = 1190, bow = 12, w = 52,
            stubs = { { 1510, 1 }, { 1380, -1 }, { 1260, 1 } } },
        { x1 = 2560, y1 = 1600, x2 = 2560, y2 = 1180, bow = -12, w = 52,
            stubs = { { 1480, -1 }, { 1340, 1 }, { 1220, -1 } } },
        { x1 = 2790, y1 = 1710, x2 = 2800, y2 = 1080, bow = 18, w = 46 },
        { x1 = 2940, y1 = 1320, x2 = 2940, y2 = 1060, bow = -10, w = 34, bud = true, mode = "chain", launchVX = 15, launchVY = -13 },
        { x1 = 3110, y1 = 1310, x2 = 3110, y2 = 1045, bow = 12, w = 34, bud = true, mode = "chain", launchVX = 15, launchVY = -12 },
        { x1 = 3280, y1 = 1320, x2 = 3280, y2 = 1060, bow = -12, w = 34, bud = true, mode = "chain", launchVX = 15, launchVY = -9 },
        { x1 = 3560, y1 = 1510, x2 = 3560, y2 = 1030, bow = 16, w = 48, bud = true, mode = "bridge",
            pads = { { 3440, 1160 }, { 3340, 1220 } } },
        { x1 = 4220, y1 = 1500, x2 = 4220, y2 = 1045, bow = -12, w = 44, bud = true, mode = "bridge",
            pads = { { 4380, 1190 }, { 4540, 1340 }, { 4700, 1500 } } },
        { x1 = 4400, y1 = 1220, x2 = 4400, y2 = 860, bow = 8, w = 34, bud = true, mode = "chain", launchVX = 15, launchVY = -11 },
        { x1 = 4560, y1 = 1660, x2 = 4560, y2 = 1500, bow = -6, w = 32, bud = true, mode = "chain", launchVX = 12, launchVY = -9 },
        { x1 = 4860, y1 = 2070, x2 = 4860, y2 = 1900, bow = 6, w = 32, bud = true, mode = "chain", launchVX = 10, launchVY = -9 },
        { x1 = 5800, y1 = 2360, x2 = 6850, y2 = 1700, bow = -60, w = 64 },
        { x1 = 6350, y1 = 2380, x2 = 6200, y2 = 1840, bow = 35, w = 38 },
        { x1 = 6650, y1 = 2360, x2 = 6460, y2 = 1900, bow = -30, w = 34 },
        { x1 = 6860, y1 = 1820, x2 = 6860, y2 = 1680, bow = 8, w = 42, bud = true, mode = "spring",
            pads = { { 6990, 1620, 58 } } },
        { x1 = 7180, y1 = 1700, x2 = 7200, y2 = 1550, bow = 8, w = 42, bud = true, mode = "long_bridge", growSpeed = 0.035, padDelayStep = 20,
            pads = { { 7360, 1600, 55 }, { 7680, 1625, 55 }, { 8000, 1700, 55 }, { 8250, 1780, 60 } } },
        { x1 = 8220, y1 = 1840, x2 = 8260, y2 = 1560, bow = -10, w = 48 },
        { x1 = 8340, y1 = 1840, x2 = 8360, y2 = 1600, bow = 12, w = 36 },
    },
    midBamboo = {
        { x1 = 260, y1 = 2700, x2 = 300, y2 = 820, bow = 22, w = 70 },
        { x1 = 980, y1 = 2700, x2 = 940, y2 = 500, bow = -26, w = 82 },
        { x1 = 1880, y1 = 2700, x2 = 1940, y2 = 420, bow = 18, w = 74 },
        { x1 = 3060, y1 = 2700, x2 = 3000, y2 = 300, bow = -34, w = 90 },
        { x1 = 4520, y1 = 2700, x2 = 4620, y2 = 540, bow = 32, w = 70 },
        { x1 = 6100, y1 = 2700, x2 = 5900, y2 = 760, bow = -36, w = 86 },
        { x1 = 7400, y1 = 2700, x2 = 7520, y2 = 640, bow = 28, w = 76 },
        { x1 = 8200, y1 = 2700, x2 = 8140, y2 = 980, bow = -20, w = 64 },
    },
    mountains = {
        { 0, 2380, 720, 2100, 1420, 2260, 2300, 1980, 3120, 2220, 4200, 1920, 5200, 2240, 6100, 2040, 7100, 2280, 8400, 2050, 8400, 2600, 0, 2600 },
        { 0, 2500, 900, 2360, 1800, 2460, 2920, 2300, 4200, 2480, 5480, 2260, 6800, 2460, 8400, 2320, 8400, 2600, 0, 2600 },
    },
    ropes = {
        { anchorX = 3560, anchorY = 950, length = 220, angle = -0.34, angularVelocity = 0, oscTime = 0 },
        { anchorX = 3880, anchorY = 920, length = 220, angle = 0.36, angularVelocity = 0, oscTime = 1.7 },
    },
    cranes = {
        { path = { { 5010, 2330 }, { 5350, 2230 }, { 5660, 2320 } }, duration = 240, t = 0, dir = 1, theta = 0, wingAngle = 0 },
    },
}

function bambooCurrentData()
    return (TRACE_RT and TRACE_RT.bambooData) or BAMBOO_DATA
end

BAMBOO_INK = { 30, 28, 26, 250 }
BAMBOO_PAD_HW = 52   -- 墨梁半宽(碰撞=梁本体)
-- 竿调色:主竿压灰墨绿 / 中景淡竹剪影
BAMBOO_PAL_MAIN = { dark = { 24, 32, 22 }, light = { 64, 80, 52 }, node = { 12, 16, 10 }, a = 250, fb = 70 }
BAMBOO_PAL_MID  = { dark = { 152, 160, 144 }, light = { 184, 190, 172 }, node = { 142, 150, 134 }, a = 215, fb = 0 }
BAMBOO_CUR_PAL = nil

function bambooAxis(s)
    local dx, dy = s.x2 - s.x1, s.y2 - s.y1
    local len = math.sqrt(dx * dx + dy * dy)
    local nx, ny = -dy / len, dx / len
    local mx2 = (s.x1 + s.x2) / 2 + nx * (s.bow or 0)
    local my2 = (s.y1 + s.y2) / 2 + ny * (s.bow or 0)
    local nseg = clamp(math.floor(len / 95 + 0.5), 4, 9)
    local rel, tot = {}, 0
    for i = 1, nseg do
        rel[i] = 0.72 + 0.55 * math.sin(3.14159 * (i - 0.5) / nseg)
        tot = tot + rel[i]
    end
    local pts = { { s.x1, s.y1, 0, 0 } }
    local acc = 0
    for i = 1, nseg do
        acc = acc + rel[i] / tot
        local t = math.min(acc, 1)
        local a, b = (1 - t) * (1 - t), 2 * (1 - t) * t
        -- 第4位:节点横向抖动(仅绘制用,碰撞不受影响)
        pts[#pts + 1] = { a * s.x1 + b * mx2 + t * t * s.x2,
            a * s.y1 + b * my2 + t * t * s.y2, t,
            (hash01(s.x1 * 7.1 + i * 13.3) - 0.5) * 5 }
    end
    return pts
end

function bambooWidthAt(s, t)
    return s.w * (1 - 0.34 * t)
end

function bambooSegCount(s)
    return #s.pts - 1 - (s.bud and 1 or 0)
end

function bambooAddPoly(flat)
    local poly = {}
    local x1, y1, x2, y2 = 1e9, 1e9, -1e9, -1e9
    for k = 1, #flat - 1, 2 do
        local x, y = flat[k], flat[k + 1]
        poly[#poly + 1] = { x, y }
        if x < x1 then x1 = x end
        if x > x2 then x2 = x end
        if y < y1 then y1 = y end
        if y > y2 then y2 = y end
    end
    poly.bb = { x1, y1, x2, y2 }
    TRACE_RT.polys[#TRACE_RT.polys + 1] = poly
    return poly
end

function bambooAxisCollision(s)
    for i = 1, bambooSegCount(s) do
        local p, q = s.pts[i], s.pts[i + 1]
        local dx, dy = q[1] - p[1], q[2] - p[2]
        local L = math.sqrt(dx * dx + dy * dy)
        if L > 1 then
            local ux, uy = dx / L, dy / L
            local nx, ny = -uy, ux
            local w1 = bambooWidthAt(s, p[3]) / 2
            local w2 = bambooWidthAt(s, q[3]) / 2
            local ax, ay = p[1] - ux * 6, p[2] - uy * 6
            local bx, by = q[1] + ux * 6, q[2] + uy * 6
            bambooAddPoly({ ax + nx * w1, ay + ny * w1, bx + nx * w2, by + ny * w2,
                bx - nx * w2, by - ny * w2, ax - nx * w1, ay - ny * w1 })
        end
    end
end

function bambooStubPoint(s, yq)
    for i = 1, #s.pts - 1 do
        local p, q = s.pts[i], s.pts[i + 1]
        if (p[2] >= yq) ~= (q[2] >= yq) and math.abs(q[2] - p[2]) > 1 then
            local f = (yq - p[2]) / (q[2] - p[2])
            return p[1] + (q[1] - p[1]) * f
        end
    end
    return s.pts[#s.pts][1]
end

-- 叶台植叶:两组"个字"叶簇长在横枝上(左节/右节各3叶 + 中央2叶)
function bambooPadLeaves(tab, cx, cy, hw)
    local nodes = { { cx - hw * 0.5, 3 }, { cx + hw * 0.5, 3 }, { cx, 2 } }
    local di = 0
    for ni, nd in ipairs(nodes) do
        local nx2 = nd[1]
        local sgn = (nx2 < cx) and -1 or 1
        if ni == 3 then sgn = 1 end
        for k = 1, nd[2] do
            -- 一上挑、一平出、一下垂
            local a
            if k == 1 then a = -1.05 + sgn * 0.35
            elseif k == 2 then a = (sgn < 0) and (3.14159 - 0.18) or 0.18
            else a = (sgn < 0) and (3.14159 - 0.55) or 0.55 end
            a = a + (hash01(nx2 + k * 7.7) - 0.5) * 0.14
            tab[#tab + 1] = { bx = nx2, by = cy + 1, a = a,
                ln = 34 + hash01(cy + k * 3.1 + ni * 11) * 22,
                w = 7.5 + hash01(k * 5.3) * 3, t = 0, delay = di * 2 }
            di = di + 1
        end
    end
end

function generateBambooScroll()
    local D = (currentLevel and currentLevel.traceKey == "bamboo_v2") and BAMBOO_DATA_22 or BAMBOO_DATA
    TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0,
        def = { conf = { kill = D.kill, goal = D.goal } },
        goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0,
        chars = {}, pools = {}, ripples = {}, ghostGrps = {}, plumDone = 0, plumTotal = 0,
        bamboo = true, bambooData = D, budDone = 0, budTotal = 0, hitstop = 0, fallPenalty = 0 }
    worldW, worldH = D.worldW, D.worldH
    willowRopes = D.ropes or {}
    cranes = D.cranes or {}
    for _, c in ipairs(cranes) do
        if c.path and c.path[1] then
            c.x, c.y = c.path[1][1], c.path[1][2]
        end
        c.theta = c.theta or 0
        c.wingAngle = c.wingAngle or 0
    end
    for _, g in ipairs(D.grounds) do bambooAddPoly(g) end
    for _, b in ipairs(D.staticBeams or {}) do
        local hw = b.hw or BAMBOO_PAD_HW
        local y = b.y or 0
        bambooAddPoly({ b.x - hw, y - 5, b.x + hw, y - 5, b.x + hw, y + 9, b.x - hw, y + 9 }).leafPlat = true
    end
    for _, s in ipairs(D.stalks) do
        s.pts = bambooAxis(s)
        bambooAxisCollision(s)
        if s.stubs then
            for _, st in ipairs(s.stubs) do
                local sx = bambooStubPoint(s, st[1])
                local ex = sx + st[2] * (58 + s.w * 0.5)
                bambooAddPoly({ sx, st[1] - 4, ex, st[1] - 12, ex, st[1] - 2, sx, st[1] + 5 })
            end
        end
    end
    if D == BAMBOO_DATA then
        -- 斜竹梢端杈台(cp3 落点)
        bambooAddPoly({ 3058, 322, 3162, 312, 3166, 328, 3062, 340 })
    end
    -- 苞:未完之笔 + 铺路链(碰撞 = 横枝本体,完全在笔画内)
    for _, s in ipairs(D.stalks) do
        if s.bud then
            local tx, ty = s.x2, s.y2
            local stEnd = s.pts[#s.pts - 1]
            local mode = s.mode or "bridge"
            local budRad = s.rad or 80

            -- 新版设计：部分点采用梅花绽放（沿用聚类原位花苞）与拾字模式
            -- 先兼容纯桥/梯模式
            local ip = { x = tx, y = ty - 10, kind = "bud", rad = budRad,
                trig = false, members = {}, stalk = s, mode = mode,
                launchVX = s.launchVX, launchVY = s.launchVY, growSpeed = s.growSpeed,
                sx = stEnd[1], sy = stEnd[2], grow = 0 }
            ip.plat = { tx - BAMBOO_PAD_HW - 4, ty + 2, tx + BAMBOO_PAD_HW + 4, ty + 2,
                tx + BAMBOO_PAD_HW + 4, ty + 12, tx - BAMBOO_PAD_HW - 4, ty + 12 }
            ip.pads = {}
            local px, py = tx, ty
            for pi, pd in ipairs(s.pads or {}) do
                local hw = pd[3] or BAMBOO_PAD_HW
                local pip = { x = pd[1], y = pd[2], px = px, py = py, hw = hw,
                    members = {}, delay = 6 + pi * (s.padDelayStep or 10), grow = 0,
                    growSpeed = s.growSpeed,
                    accDir = (pd[1] >= px) and 1 or -1 }
                pip.plat = { pd[1] - hw, pd[2] - 1, pd[1] + hw, pd[2] - 1,
                    pd[1] + hw, pd[2] + 9, pd[1] - hw, pd[2] + 9 }
                ip.pads[#ip.pads + 1] = pip
                px, py = pd[1], pd[2]
            end
            ip.accDir = (ip.pads[1] and ip.pads[1].x >= tx) and 1 or -1
            if ip.mode == "ladder" then
                ip.accDir = 1
                for _, pip in ipairs(ip.pads) do pip.accDir = 1 end
            end
            TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] = ip
            TRACE_RT.budTotal = TRACE_RT.budTotal + 1
        end
    end
    TRACE_RT.spawnX = D.spawn[1]
    TRACE_RT.spawnY = traceSnapDown(D.spawn[1], D.spawn[2] - 100) - 12
    TRACE_RT.cps = {}
    for i, cp in ipairs(D.cps) do
        TRACE_RT.cps[i] = { cp[1], traceSnapDown(cp[1], cp[2] - 100) - 12 }
        TRACE_RT.cpReached[i] = (i == 1)
    end
    TRACE_RT.zoom = TRACE_DEBUG_FIT and math.min(DESIGN_W / (worldW + 80), DESIGN_H / (worldH + 80)) or D.zoom
    TRACE_RT.camCx = TRACE_RT.spawnX
    TRACE_RT.camCy = TRACE_RT.spawnY - 50
    print(string.format("[bamboo] %s polys=%d buds=%d world=%dx%d",
        currentLevel.traceKey, #TRACE_RT.polys, TRACE_RT.budTotal, worldW, worldH))
end

function bambooCranePoint(c)
    if not c.path then return c.x or 0, c.y or 0 end
    local p = c.path
    local dur = c.duration or 240
    local tt = (c.t or 0) / dur
    tt = clamp(tt, 0, 1)
    if tt < 0.5 then
        local u = tt * 2
        local x = p[1][1] + (p[2][1] - p[1][1]) * u
        local y = p[1][2] + (p[2][2] - p[1][2]) * u
        return x, y
    end
    local u = (tt - 0.5) * 2
    local x = p[2][1] + (p[3][1] - p[2][1]) * u
    local y = p[2][2] + (p[3][2] - p[2][2]) * u
    return x, y
end

function updateBambooScrollSpecial()
    local RT = TRACE_RT
    if not RT or not RT.bamboo then return end
    updatePeachRopes()
    if RT.fallPenalty and RT.fallPenalty > 0 then
        RT.fallPenalty = RT.fallPenalty - 1
        player.vx = player.vx * 0.6
    end
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
            dashJustPressed = false
        end
        return
    elseif not player.isDashing then
        for _, rope in ipairs(willowRopes) do
            local tx, ty = ropeTip(rope)
            if dist2(player.x - tx, player.y - ty) < player.radius + 36 then
                player.swingRope = rope
                player.canDash = true
                break
            end
        end
    end
    for _, c in ipairs(cranes) do
        if c.path then
            c.t = (c.t or 0) + (c.dir or 1)
            if c.t >= (c.duration or 240) then c.t = c.duration or 240; c.dir = -1 end
            if c.t <= 0 then c.t = 0; c.dir = 1 end
            c.x, c.y = bambooCranePoint(c)
            c.theta = (c.theta or 0) + 0.035
            c.wingAngle = math.sin(c.theta * 3.5) * (math.pi / 4)
        end
    end
    if player.craneCooldown > 0 then player.craneCooldown = player.craneCooldown - 1 end
    if player.ridingCrane then
        local c = player.ridingCrane
        player.x = c.x
        player.y = c.y - 18
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
    elseif player.craneCooldown == 0 and not player.isDashing then
        for _, c in ipairs(cranes) do
            if dist2(player.x - c.x, player.y - c.y) < player.radius + 36 then
                player.ridingCrane = c
                break
            end
        end
    end
end

function bambooBudUpdate()
    local RT = TRACE_RT
    RT.budDone = 0
    for _, ip in ipairs(RT.ipoints) do
        if ip.trig then RT.budDone = RT.budDone + 1 end
        if ip.shake and ip.shake > 0 then ip.shake = ip.shake - 1 end
        if not ip.trig then
            local dx, dy = player.x - ip.x, player.y - ip.y
            if dx * dx + dy * dy < (ip.rad or 64) ^ 2 then
                if player.isDashing then
                    ip.trig = true
                    ip.ring = 0
                    player.isDashing = false
                    player.dashTime = 0
                    player.canDash = true
                    local chain = ip.mode == "chain"
                    if chain then
                        -- 链苞:不停顿,命中后弹送并刷新冲刺。
                        player.vx = ip.launchVX or ((player.facingRight and 1 or -1) * 14)
                        player.vy = ip.launchVY or -12
                        player.isGrounded = false
                    else
                        -- 冲刺命中:笔在苞处收势——结束冲刺,稳落新生叶台。
                        player.x = ip.x
                        player.y = ip.y + 12 - player.radius - 1
                        player.vx = clamp(player.vx, -2.5, 2.5)
                        player.vy = 0
                        player.isGrounded = true
                        RT.hitstop = 3
                        RT.hitstopX, RT.hitstopY = player.x, player.y
                    end
                    local nx2, ny2 = 0, -26
                    if ip.pads[1] then
                        local ddx, ddy = ip.pads[1].x - ip.x, ip.pads[1].y - ip.y
                        local dl = math.sqrt(ddx * ddx + ddy * ddy)
                        if dl > 1 then nx2, ny2 = ddx / dl * 38, ddy / dl * 24 end
                    end
                    RT.nudge = { x = nx2, y = ny2, t = 22 }
                    if not chain then bambooAddPoly(ip.plat).leafPlat = true end
                    for _, pip in ipairs(ip.pads) do bambooAddPoly(pip.plat).leafPlat = true end
                    for k = 1, 16 do
                        RT.petals[#RT.petals + 1] = { x = ip.x, y = ip.y,
                            vx = (hash01(ip.x + k * 6.1) - 0.5) * 3.6, vy = -0.8 - hash01(k * 3.7) * 2.4,
                            rot = hash01(k * 2.9) * 6.28, vr = (hash01(k * 7.7) - 0.5) * 0.2,
                            life = 56 + k * 3, age = 0, ph = k * 2.1, col = { 40, 48, 36 } }
                    end
                elseif not ip.shake or ip.shake <= 0 then
                    -- 非冲刺触碰:苞轻颤拒绝(提示要用 J 点墨)
                    ip.shake = 16
                end
            end
        else
            if ip.mode == "spring" and player.isGrounded and keys.space
                and math.abs(player.x - ip.x) < 150 and math.abs((player.y + player.radius) - (ip.y + 10)) < 48 then
                player.vy = -24
                player.isGrounded = false
                player.canDash = true
                keys.space = false
                RT.nudge = { x = 18, y = -45, t = 22 }
                for k = 1, 12 do
                    RT.petals[#RT.petals + 1] = { x = ip.x, y = ip.y + 8,
                        vx = (hash01(ip.x + k * 4.1) - 0.5) * 2.8, vy = -1.4 - hash01(k * 2.9) * 2.2,
                        rot = hash01(k * 4.9) * 6.28, vr = (hash01(k * 6.7) - 0.5) * 0.2,
                        life = 46 + k * 2, age = 0, ph = k * 1.9, col = { 38, 48, 32 } }
                end
            end
            if ip.ring then ip.ring = ip.ring + 1 end
            if ip.grow < 1 then ip.grow = math.min(1, ip.grow + (ip.growSpeed or 0.09)) end
            for _, m in ipairs(ip.members) do
                if m.delay > 0 then m.delay = m.delay - 1
                elseif m.t < 1 then m.t = math.min(1, m.t + 0.07) end
            end
            for _, pip in ipairs(ip.pads) do
                if pip.delay > 0 then pip.delay = pip.delay - 1
                else
                    if pip.grow < 1 then pip.grow = math.min(1, pip.grow + (pip.growSpeed or 0.08)) end
                    for _, m in ipairs(pip.members) do
                        if m.delay > 0 then m.delay = m.delay - 1
                        elseif m.t < 1 then m.t = math.min(1, m.t + 0.07) end
                    end
                end
            end
        end
    end
end

-- ============ 绘制 ============
function drawInkLeaf(bx, by, a, ln, w, grow, col, alpha)
    if grow <= 0.02 then return end
    local g = grow
    if g < 1 then g = 1 + 1.9 * (g - 1) ^ 3 + 0.9 * (g - 1) ^ 2 end
    local L = ln * g
    local ca, sa = math.cos(a), math.sin(a)
    -- 叶脊垂弧:撇出后自然向下坠
    local droop = L * 0.13
    local tx, ty = bx + ca * L, by + sa * L + droop
    local mxs, mys = bx + ca * L * 0.5, by + sa * L * 0.5 + droop * 0.42
    local pa = a + 1.5708
    local pcx, pcy = math.cos(pa), math.sin(pa)
    local gw = math.min(grow * 1.6, 1)
    local wUp = w * 0.6 * gw   -- 上缘瘦
    local wDn = w * 1.3 * gw   -- 下缘肥(笔肚)
    local al = alpha or 240
    nvgBeginPath(vg)
    nvgMoveTo(vg, bx, by)
    nvgBezierTo(vg,
        bx + ca * L * 0.30 + pcx * wUp, by + sa * L * 0.30 + pcy * wUp + droop * 0.16,
        mxs + pcx * wUp * 0.66, mys + pcy * wUp * 0.66, tx, ty)
    nvgBezierTo(vg,
        mxs - pcx * wDn, mys - pcy * wDn,
        bx + ca * L * 0.24 - pcx * wDn * 0.82, by + sa * L * 0.24 - pcy * wDn * 0.82,
        bx, by)
    nvgClosePath(vg)
    nvgFillColor(vg, rgba(col[1], col[2], col[3], al))
    nvgFill(vg)
    -- 锋尖补浓:末段一道更深的窄笔
    if L > 26 then
        local hx, hy = bx + ca * L * 0.55, by + sa * L * 0.55 + droop * 0.6
        nvgBeginPath(vg)
        nvgMoveTo(vg, hx, hy)
        nvgBezierTo(vg,
            hx + ca * L * 0.2 + pcx * wUp * 0.5, hy + sa * L * 0.2 + pcy * wUp * 0.5 + droop * 0.2,
            tx - ca * L * 0.1, ty - sa * L * 0.1, tx, ty)
        nvgBezierTo(vg,
            hx + ca * L * 0.22 - pcx * wDn * 0.4, hy + sa * L * 0.22 - pcy * wDn * 0.4 + droop * 0.2,
            hx, hy, hx, hy)
        nvgClosePath(vg)
        nvgFillColor(vg, rgba(math.floor(col[1] * 0.55), math.floor(col[2] * 0.55),
            math.floor(col[3] * 0.55), al * 0.7))
        nvgFill(vg)
    end
end

function drawInkBranch(ax, ay, bx, by, w, grow, alpha)
    if grow <= 0.02 then return end
    local t = grow
    local mx2 = (ax + bx) / 2
    local my2 = (ay + by) / 2 + 18
    local a1, b1 = (1 - t) * (1 - t), 2 * (1 - t) * t
    local ex = a1 * ax + b1 * mx2 + t * t * bx
    local ey = a1 * ay + b1 * my2 + t * t * by
    nvgStrokeColor(vg, rgba(30, 28, 26, alpha or 240))
    nvgStrokeWidth(vg, w * (1 - 0.4 * t) + 2)
    nvgBeginPath(vg)
    nvgMoveTo(vg, ax, ay)
    nvgBezierTo(vg, ax + (mx2 - ax) * t, ay + (my2 - ay) * t,
        ex - (bx - ax) * 0.1 * t, ey - (by - ay) * 0.1 * t, ex, ey)
    nvgStroke(vg)
end

-- 叶台:横枝(碰撞本体)+ 枝上叶簇
function drawBambooPad(anchorX, anchorY, spine, members, grow)
    if grow > 0.02 then
        local sx1, sy1, sx2, sy2 = spine[1], spine[2], spine[3], spine[4]
        local g = math.min(grow * 1.15, 1)
        -- 横枝从锚点向两端长出
        local mxm = (sx1 + sx2) / 2
        local mym = (sy1 + sy2) / 2
        nvgStrokeColor(vg, rgba(28, 26, 24, 248))
        nvgStrokeWidth(vg, 6.5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, mxm - (mxm - sx1) * g, mym - (mym - sy1) * g)
        nvgLineTo(vg, mxm + (sx2 - mxm) * g, mym + (sy2 - mym) * g)
        nvgStroke(vg)
        -- 枝端小节痕
        if g > 0.9 then
            for _, ex in ipairs({ { sx1, sy1 }, { sx2, sy2 } }) do
                nvgBeginPath(vg)
                nvgCircle(vg, ex[1], ex[2], 2.6)
                nvgFillColor(vg, rgba(16, 15, 13, 250))
                nvgFill(vg)
            end
        end
    end
    for _, m in ipairs(members) do
        drawInkLeaf(m.bx, m.by, m.a, m.ln, m.w, m.t, { 30, 36, 27 }, 246)
    end
end

function drawBambooStalk(s)
    local pal = BAMBOO_CUR_PAL or BAMBOO_PAL_MAIN
    for i = 1, bambooSegCount(s) do
        local p, q = s.pts[i], s.pts[i + 1]
        local dx, dy = q[1] - p[1], q[2] - p[2]
        local L = math.sqrt(dx * dx + dy * dy)
        if L > 1 then
            local ux, uy = dx / L, dy / L
            local nx, ny = -uy, ux
            local j1, j2 = (p[4] or 0), (q[4] or 0)
            local ax, ay = p[1] + ux * 3 + nx * j1, p[2] + uy * 3 + ny * j1
            local bx, by = q[1] - ux * 3 + nx * j2, q[2] - uy * 3 + ny * j2
            local w1 = bambooWidthAt(s, p[3]) / 2
            local w2 = bambooWidthAt(s, q[3]) / 2
            local tone_j = (hash01(s.x1 + i * 13.7) - 0.5) * 12
            -- 侧锋:一侧蘸墨深、一侧行笔淡(段内横向渐变)
            local grad = nvgLinearGradient(vg,
                ax + nx * w1, ay + ny * w1, ax - nx * w1, ay - ny * w1,
                rgba(clamp(pal.dark[1] + tone_j, 0, 255), clamp(pal.dark[2] + tone_j, 0, 255),
                    clamp(pal.dark[3] + tone_j, 0, 255), pal.a),
                rgba(clamp(pal.light[1] + tone_j, 0, 255), clamp(pal.light[2] + tone_j, 0, 255),
                    clamp(pal.light[3] + tone_j, 0, 255), pal.a - 14))
            nvgBeginPath(vg)
            nvgMoveTo(vg, ax + nx * w1, ay + ny * w1)
            nvgLineTo(vg, bx + nx * w2, by + ny * w2)
            nvgLineTo(vg, bx - nx * w2, by - ny * w2)
            nvgLineTo(vg, ax - nx * w1, ay - ny * w1)
            nvgClosePath(vg)
            nvgFillPaint(vg, grad)
            nvgFill(vg)
            -- 飞白:段内顺笔势的枯丝(纸色细线;中景剪影不画)
            if pal.fb > 0 then
                for k = 1, 2 + (i % 2) do
                    local sd = s.x1 * 3.7 + i * 17.9 + k * 7.7
                    local lat = (hash01(sd) - 0.5) * 1.5 * w1 * 0.8
                    local f1 = 0.12 + hash01(sd + 1) * 0.3
                    local f2 = f1 + 0.25 + hash01(sd + 2) * 0.35
                    strokeLine(
                        ax + ux * L * f1 + nx * lat, ay + uy * L * f1 + ny * lat,
                        ax + ux * L * math.min(f2, 0.94) + nx * lat * 0.92,
                        ay + uy * L * math.min(f2, 0.94) + ny * lat * 0.92,
                        1.1 + hash01(sd + 3) * 1.3,
                        rgba(bambooCurrentData().paper[1], bambooCurrentData().paper[2], bambooCurrentData().paper[3],
                            (pal.fb - 28) + hash01(sd + 4) * 46))
                end
            end
            -- 节:一笔浅弧(中间略粗两端收),不出箍
            if i > 1 then
                nvgStrokeColor(vg, rgba(pal.node[1], pal.node[2], pal.node[3], pal.a - 15))
                nvgStrokeWidth(vg, 2.6)
                nvgBeginPath(vg)
                nvgMoveTo(vg, ax - nx * (w1 + 1.5), ay - ny * (w1 + 1.5))
                nvgBezierTo(vg, ax - ux * 3, ay - uy * 3, ax - ux * 3, ay - uy * 3,
                    ax + nx * (w1 + 1.5), ay + ny * (w1 + 1.5))
                nvgStroke(vg)
                -- 节下淡墨小晕(墨在节处积一点)
                drawEllipse(ax, ay + 3, w1 * 0.8, 2.2,
                    rgba(pal.node[1], pal.node[2], pal.node[3], 58))
            end
        end
    end
    if s.stubs then
        for _, st in ipairs(s.stubs) do
            local sx = bambooStubPoint(s, st[1])
            local ex = sx + st[2] * (58 + s.w * 0.5)
            nvgStrokeColor(vg, rgba(20, 28, 18, 245))
            nvgStrokeWidth(vg, 5)
            nvgBeginPath(vg)
            nvgMoveTo(vg, sx, st[1] + 2)
            nvgBezierTo(vg, sx + (ex - sx) * 0.5, st[1] - 2, ex - (ex - sx) * 0.15, st[1] - 6, ex, st[1] - 8)
            nvgStroke(vg)
            drawInkLeaf(ex, st[1] - 8, 0.55 + st[2] * 0.45, 36, 5, 1, { 44, 58, 38 }, 225)
            drawInkLeaf(ex, st[1] - 8, 1.15 + st[2] * 0.3, 28, 4, 1, { 44, 58, 38 }, 195)
        end
    end
end

-- 墨梁:统一的可踏平台语言(深墨横梁 + 节凸 + 端头收点 + 梁端竹叶点缀)
function drawInkBeam(cx2, cy2, hw, grow, accDir)
    if grow <= 0.02 then return end
    local g = math.min(grow * 1.15, 1)
    local x1, x2 = cx2 - hw * g, cx2 + hw * g
    -- 梁身(横向渐变:行笔由深到淡)
    local grad = nvgLinearGradient(vg, x1, cy2, x2, cy2,
        rgba(20, 19, 17, 250), rgba(44, 42, 38, 244))
    nvgBeginPath(vg)
    nvgRect(vg, x1, cy2 - 4.5, x2 - x1, 9)
    nvgFillPaint(vg, grad)
    nvgFill(vg)
    -- 端头收笔点(略粗)
    drawCircle(x1 + 1, cy2, 6, rgba(16, 15, 13, 250))
    drawCircle(x2 - 1, cy2, 6, rgba(16, 15, 13, 250))
    -- 节凸(梁上三点)
    for k = -1, 1 do
        drawEllipse(cx2 + k * hw * 0.55 * g, cy2 - 4.2, 4.2, 2.2, rgba(14, 13, 12, 235))
    end
    -- 飞白一丝
    strokeLine(x1 + hw * 0.35, cy2 - 1, x2 - hw * 0.3, cy2 - 1.6, 1.2,
        rgba(bambooCurrentData().paper[1], bambooCurrentData().paper[2], bambooCurrentData().paper[3], 52))
    -- 梁端竹叶点缀(朝行进方向)
    if g > 0.85 and accDir then
        local exx = (accDir > 0) and x2 or x1
        drawInkLeaf(exx, cy2 - 2, (accDir > 0) and 0.5 or 2.64, 34, 4.5, 1, { 44, 58, 38 }, 220)
        drawInkLeaf(exx, cy2 - 2, (accDir > 0) and 1.05 or 2.1, 26, 4, 1, { 44, 58, 38 }, 185)
    end
end

function drawBambooScroll()
    local RT = TRACE_RT
    local D = bambooCurrentData()
    nvgSave(vg)
    nvgTranslate(vg, cameraX, cameraY)
    local z = RT.zoom or 1
    local cx = RT.camCx or (cameraX + DESIGN_W / 2)
    local cy = RT.camCy or (cameraY + DESIGN_H / 2)
    if RT.goalDone then
        local fitz = math.min(DESIGN_W / (worldW + 80), DESIGN_H / (worldH + 80)) * 0.96
        local tt = math.min(RT.vista / 170, 1)
        tt = 1 - (1 - tt) ^ 3
        z = z + (fitz - z) * tt
        cx = cx + (worldW / 2 - cx) * tt
        cy = cy + (worldH / 2 - cy) * tt
    end
    nvgTranslate(vg, DESIGN_W / 2, DESIGN_H / 2)
    nvgScale(vg, z, z)
    nvgTranslate(vg, -cx, -cy)
    local halfW = DESIGN_W / (2 * z) + 80
    local halfH = DESIGN_H / (2 * z) + 80
    nvgBeginPath(vg)
    nvgRect(vg, cx - halfW, cy - halfH, halfW * 2, halfH * 2)
    nvgFillColor(vg, rgba(D.paper[1], D.paper[2], D.paper[3], 255))
    nvgFill(vg)
    -- 宣纸纹理:分格确定性的纤维丝 + 云状淡斑(只画可视格)
    local cs = 512
    for ix = math.floor((cx - halfW) / cs), math.floor((cx + halfW) / cs) do
        for iy = math.floor((cy - halfH) / cs), math.floor((cy + halfH) / cs) do
            local sd = ix * 131.7 + iy * 57.3
            drawEllipse(ix * cs + hash01(sd + 1) * cs, iy * cs + hash01(sd + 2) * cs,
                170 + hash01(sd + 3) * 210, 90 + hash01(sd + 4) * 130,
                rgba(216, 211, 197, 8))
            for k = 1, 9 do
                local fx = ix * cs + hash01(sd + k * 7.7) * cs
                local fy = iy * cs + hash01(sd + k * 11.3) * cs
                local fa2 = hash01(sd + k * 3.1) * 3.14159
                local fl = 3 + hash01(sd + k * 5.9) * 6
                strokeLine(fx, fy, fx + math.cos(fa2) * fl, fy + math.sin(fa2) * fl,
                    0.9, rgba(188, 182, 167, 15))
            end
            for k = 1, 4 do
                drawCircle(ix * cs + hash01(sd + k * 13.7) * cs,
                    iy * cs + hash01(sd + k * 17.9) * cs,
                    0.8 + hash01(sd + k * 19.3) * 0.8, rgba(178, 172, 156, 14))
            end
        end
    end
    -- 远景:雾山(视差 0.3,两叠)
    nvgSave(vg)
    nvgTranslate(vg, (cx - worldW / 2) * (1 - 0.3), (cy - worldH / 2) * (1 - 0.3) * 0.4)
    for mi, mt in ipairs(D.mountains) do
        nvgBeginPath(vg)
        nvgMoveTo(vg, mt[1], mt[2])
        for k = 3, #mt - 1, 2 do nvgLineTo(vg, mt[k], mt[k + 1]) end
        nvgClosePath(vg)
        nvgFillColor(vg, (mi == 1) and rgba(214, 211, 200, 150) or rgba(202, 199, 188, 120))
        nvgFill(vg)
    end
    nvgRestore(vg)
    -- 中景:淡竹剪影(视差 0.6,纯景)
    nvgSave(vg)
    nvgTranslate(vg, (cx - worldW / 2) * (1 - 0.6), (cy - worldH / 2) * (1 - 0.6) * 0.5)
    BAMBOO_CUR_PAL = BAMBOO_PAL_MID
    for _, s in ipairs(D.midBamboo) do
        if not s.pts then s.pts = bambooAxis(s) end
        drawBambooStalk(s)
        -- 剪影叶冠
        for k = 1, 5 do
            local a2 = -0.5 + (k - 3) * 0.4 + hash01(s.x1 + k * 3.3) * 0.12
            drawInkLeaf(s.x2, s.y2 + 4, a2 + 0.4, 52 + hash01(s.x1 * k) * 38, 6.5, 1,
                { 150, 158, 142 }, 195)
        end
    end
    BAMBOO_CUR_PAL = nil
    nvgRestore(vg)
    -- 坡石:深底 + 受光淡斑 + 顶面浓墨踏带 + 皴笔 + 苔点 + 湿晕边
    for gi, g in ipairs(D.grounds) do
        local gx1, gx2 = g[1], g[#g - 3]
        local gw2 = gx2 - gx1
        -- 石身(略提的深墨,给皴留层次)
        nvgBeginPath(vg)
        nvgMoveTo(vg, g[1], g[2])
        for k = 3, #g - 1, 2 do nvgLineTo(vg, g[k], g[k + 1]) end
        nvgClosePath(vg)
        nvgFillColor(vg, rgba(52, 49, 44, 248))
        nvgFill(vg)
        nvgStrokeColor(vg, rgba(40, 38, 34, 42))
        nvgStrokeWidth(vg, 10)
        nvgStroke(vg)
        -- 受光淡斑:多枚错叠的小斑,破掉椭圆程序感
        for k = 1, 5 do
            local sx2 = gx1 + (0.08 + k * 0.17 + (hash01(gi * 7 + k) - 0.5) * 0.1) * gw2
            local sy2 = g[2] + 18 + hash01(gi + k * 3) * 30
            drawEllipse(sx2, sy2,
                22 + hash01(gi * 11 + k) * 38, 7 + hash01(gi * 5 + k) * 8,
                rgba(126, 120, 108, 18 + hash01(gi * 3 + k * 5) * 14))
        end
        -- 顶面浓墨踏带(可踏面的视觉锚)
        nvgStrokeColor(vg, rgba(18, 17, 15, 250))
        nvgStrokeWidth(vg, 6.5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, g[1], g[2])
        for k = 3, #g - 5, 2 do nvgLineTo(vg, g[k], g[k + 1]) end
        nvgStroke(vg)
        -- 皴笔:顶缘向下扫的弧笔
        for k = 1, 4 do
            local fx = gx1 + (0.12 + k * 0.2 + (hash01(gi * 13 + k) - 0.5) * 0.08) * gw2
            local fy = g[2] + 6
            local fl = 26 + hash01(gi * 17 + k) * 34
            nvgStrokeColor(vg, rgba(24, 23, 21, 95 + hash01(gi + k * 7) * 50))
            nvgStrokeWidth(vg, 2.2 + hash01(k * 3.3) * 1.6)
            nvgBeginPath(vg)
            nvgMoveTo(vg, fx, fy)
            nvgBezierTo(vg, fx + fl * 0.3, fy + fl * 0.4, fx + fl * 0.5, fy + fl * 0.75,
                fx + fl * 0.42, fy + fl)
            nvgStroke(vg)
        end
        -- 苔点
        for k = 1, 5 do
            local hx = gx1 + hash01(gi * 31 + k * 17) * gw2
            local hy = g[2] - 4 - hash01(gi * 13 + k * 7) * 6
            nvgSave(vg)
            nvgTranslate(vg, hx, hy)
            nvgRotate(vg, -0.5 + hash01(k * 3.7) * 0.4)
            nvgBeginPath(vg)
            nvgEllipse(vg, 0, 0, 6.5, 2.6)
            nvgFillColor(vg, rgba(52, 60, 48, 185))
            nvgFill(vg)
            nvgRestore(vg)
        end
    end
    -- 预置墨梁/杈台
    for _, b in ipairs(D.staticBeams or {}) do
        drawInkBeam(b.x, b.y, b.hw or BAMBOO_PAD_HW, 1, 1)
        if b.spring then
            nvgStrokeColor(vg, rgba(30, 28, 26, 220))
            nvgStrokeWidth(vg, 4)
            nvgBeginPath(vg)
            nvgMoveTo(vg, b.x - 60, b.y + 8)
            nvgBezierTo(vg, b.x - 20, b.y - 28, b.x + 28, b.y - 22, b.x + 66, b.y + 5)
            nvgStroke(vg)
        end
    end
    -- 雾渊死区:宣纸上的翻涌淡雾,没有苔点和浓墨落脚。
    for _, z2 in ipairs(D.killZones or {}) do
        for k = 1, 5 do
            local yy = z2[2] + 26 + k * 36 + math.sin(elapsed * 0.8 + k) * 6
            drawEllipse((z2[1] + z2[3]) * 0.5, yy, (z2[3] - z2[1]) * (0.32 + k * 0.025), 18 + k * 3,
                rgba(190, 187, 176, 38 - k * 3))
        end
        nvgStrokeColor(vg, rgba(126, 120, 108, 70))
        nvgStrokeWidth(vg, 1.5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, z2[1], z2[2])
        for k = 1, 8 do
            local x = z2[1] + (z2[3] - z2[1]) * k / 8
            nvgLineTo(vg, x, z2[2] + math.sin(k * 1.7 + elapsed) * 10)
        end
        nvgStroke(vg)
    end
    -- 垂梢荡枝 / 墨鹤雾渡
    drawRopes()
    drawCloudsAndCranes()
    -- 竿
    for _, s in ipairs(D.stalks) do drawBambooStalk(s) end
    if D == BAMBOO_DATA then
        -- 斜竹梢延伸笔 + cp3 杈台
        nvgStrokeColor(vg, rgba(30, 28, 26, 235))
        nvgStrokeWidth(vg, 6)
        nvgBeginPath(vg)
        nvgMoveTo(vg, 3110, 330)
        nvgBezierTo(vg, 3200, 306, 3270, 298, 3324, 304)
        nvgStroke(vg)
        drawInkLeaf(3324, 304, 0.5, 48, 6, 1, { 30, 28, 26 }, 220)
        drawInkLeaf(3324, 304, 1.0, 38, 5, 1, { 30, 28, 26 }, 190)
        nvgStrokeColor(vg, rgba(30, 28, 25, 250))
        nvgStrokeWidth(vg, 7)
        nvgBeginPath(vg)
        nvgMoveTo(vg, 3058, 334)
        nvgLineTo(vg, 3164, 322)
        nvgStroke(vg)
    end
    -- 苞 / 补笔生长
    for _, ip in ipairs(RT.ipoints) do
        if not ip.trig then
            -- 未完之笔:枯笔断点(越往笔锋越细越淡)
            for k = 0, 3 do
                local t1 = k * 0.25 + 0.04
                local t2 = t1 + 0.15 - k * 0.012
                strokeLine(
                    ip.sx + (ip.x - ip.sx) * t1, ip.sy + (ip.y + 8 - ip.sy) * t1,
                    ip.sx + (ip.x - ip.sx) * t2, ip.sy + (ip.y + 8 - ip.sy) * t2,
                    3.2 - k * 0.6, rgba(96, 92, 84, 120 - k * 22))
            end
            local ph = elapsed * 2.2 + ip.x * 0.013
            -- 非冲刺触碰的拒绝轻颤
            local jit = 0
            if ip.shake and ip.shake > 0 then
                jit = math.sin(ip.shake * 1.9) * (ip.shake / 16) * 4
            end
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x + jit, ip.y, 7.5 + math.sin(ph) * 1.2)
            nvgFillColor(vg, rgba(24, 22, 20, 235))
            nvgFill(vg)
            nvgStrokeColor(vg, rgba(24, 22, 20, 215))
            nvgStrokeWidth(vg, 2.6)
            nvgBeginPath(vg)
            nvgMoveTo(vg, ip.x + 2, ip.y - 7)
            nvgBezierTo(vg, ip.x + 7, ip.y - 14, ip.x + 9, ip.y - 17, ip.x + 12, ip.y - 22)
            nvgStroke(vg)
            nvgStrokeColor(vg, rgba(70, 66, 62, 56 + 26 * math.sin(ph)))
            nvgStrokeWidth(vg, 2.4)
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x, ip.y, 26 + math.sin(ph) * 4)
            nvgStroke(vg)
        else
            drawInkBranch(ip.sx, ip.sy, ip.x, ip.y + 4, 9, ip.grow, 250)
            if ip.ring and ip.ring < 40 then
                local t = ip.ring / 40
                nvgStrokeColor(vg, rgba(40, 46, 36, 210 * (1 - t)))
                nvgStrokeWidth(vg, 4 * (1 - t) + 0.6)
                nvgBeginPath(vg)
                nvgCircle(vg, ip.x, ip.y, 12 + t * 64)
                nvgStroke(vg)
            end
            -- 梢台墨梁(苞处)
            drawInkBeam(ip.x, ip.y + 7, BAMBOO_PAD_HW + 4, ip.grow, ip.accDir)
            -- 铺路墨梁链(悬浮,不连线,参考视频4语言)
            for _, pip in ipairs(ip.pads) do
                drawInkBeam(pip.x, pip.y + 4, pip.hw or BAMBOO_PAD_HW, pip.grow, pip.accDir)
            end
        end
    end
    -- 终点卷口
    local g = D.goal
    nvgStrokeColor(vg, rgba(150, 60, 50, 190 + 40 * math.sin(elapsed * 3)))
    nvgStrokeWidth(vg, 5)
    nvgBeginPath(vg)
    nvgArc(vg, g[1], g[2] - 50, 80, math.pi, 0, NVG_CW)
    nvgStroke(vg)
    nvgStrokeColor(vg, rgba(90, 84, 78, 235))
    nvgStrokeWidth(vg, 4.5)
    nvgBeginPath(vg)
    nvgCircle(vg, g[1], g[2] - 24, 33)
    nvgStroke(vg)
    -- 存档灯
    for i, cp in ipairs(RT.cps) do
        nvgStrokeColor(vg, rgba(40, 36, 33, 235))
        nvgStrokeWidth(vg, 5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cp[1], cp[2] + 12)
        nvgLineTo(vg, cp[1], cp[2] - 52)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgCircle(vg, cp[1] + 16, cp[2] - 46, RT.cpReached[i] and 7 or 5)
        nvgFillColor(vg, RT.cpReached[i] and rgba(235, 180, 90, 230) or rgba(160, 152, 140, 180))
        nvgFill(vg)
    end
    -- 墨池涟漪
    for _, rp in ipairs(RT.ripples or {}) do
        local t = rp.t / 55
        local a = (1 - t) * 150 * math.min(rp.big or 1, 1)
        for k = 0, 1 do
            local rr = (10 + t * 56) * (rp.big or 1) * (1 - k * 0.4)
            nvgStrokeColor(vg, rgba(38, 36, 33, a * (1 - k * 0.35)))
            nvgStrokeWidth(vg, 2.6 - k)
            nvgBeginPath(vg)
            nvgEllipse(vg, rp.x, rp.y, rr, rr * 0.32)
            nvgStroke(vg)
        end
    end
    -- 墨屑
    for _, pt in ipairs(RT.petals) do
        local a = 230 * (1 - pt.age / pt.life)
        local pc = pt.col or TRACE_PETAL_RED
        nvgSave(vg)
        nvgTranslate(vg, pt.x, pt.y)
        nvgRotate(vg, pt.rot)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, 0, 5.2, 2.8)
        nvgFillColor(vg, rgba(pc[1], pc[2], pc[3], a))
        nvgFill(vg)
        nvgRestore(vg)
    end
    drawParticles()
    drawPlayer()
    if RT.goalDone then traceDrawMount(z) end
    nvgRestore(vg)
end

-- ============================================================================
-- END scripts/src/88_bamboo_scroll.lua
-- ============================================================================

-- ============================================================================
-- BEGIN scripts/src/90_world_seal_runtime.lua
-- ============================================================================
-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function drawWorld()
    if currentLevel.trace then
        drawTraceWorld()
        return
    end
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
    if currentLevel.trace and TRACE_RT.bamboo then
        drawText(40, 92, 13, rgba(210, 220, 210, 220), string.format("state %s  dash %s  补笔 %d/%d",
            state, player.canDash and "ready" or "used", TRACE_RT.budDone or 0, TRACE_RT.budTotal or 0))
    elseif currentLevel.trace then
        local gotChars = 0
        for _, ch in ipairs(TRACE_RT.chars or {}) do
            if ch.got then gotChars = gotChars + 1 end
        end
        drawText(40, 92, 13, rgba(210, 220, 210, 220), string.format("state %s  dash %s  梅苞 %d/%d  拾字 %d/%d",
            state, player.canDash and "ready" or "used",
            TRACE_RT.plumDone or 0, TRACE_RT.plumTotal or 0, gotChars, #(TRACE_RT.chars or {})))
    else
        drawText(40, 92, 13, rgba(210, 220, 210, 220), string.format("state %s  dash %s  blooms %d/%d", state, player.canDash and "ready" or "used", collectedCount, #targets))
    end
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
    loadLevel(23)
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

