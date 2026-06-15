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
