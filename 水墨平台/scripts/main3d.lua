-- ============================================================================
-- 《墨龙行》— 纸境 3D 关卡(3渲2:三维渲染,二维操作)
-- 世界 = 陈容《九龙图》整卷画芯(暗绢调,19910x1032 扫描px x2 = 39820x2064 世界单位)
-- 玩法:沿九龙龙脊行进,视野受限,收彩珠扩大视野,终点龙首悬珠 → 大龙显现
-- 启动: tools/run_3d.ps1
-- ============================================================================

---@type Scene
local scene_ = nil
local cameraNode_ = nil
local playerNode_ = nil
local playerGlowNode_ = nil
local vignetteNode_ = nil
local vignetteMat = nil
local zone_ = nil

-- 暗绢底色(与贴图管线 silk_dark 一致)
local SILK = Color(0.262, 0.248, 0.220)
local INK = Color(0.10, 0.094, 0.085)

-- 关卡数据(生成注入)
-- ==== 墨龙行关卡数据(由 tmp/author_molong.py 生成,勿手改) ====
SPINES = {
  { {480,464,110}, {760,664,130}, {1040,904,150}, {1400,1124,160}, {1800,984,140}, {2300,1004,130}, {2800,1184,120}, {3300,1324,110}, {3700,1384,100} },
  { {4160,1464,100}, {4600,1664,110}, {5100,1744,110}, {5600,1544,100}, {5960,1304,90} },
  { {4760,664,120}, {5200,824,130}, {5700,784,120}, {6100,664,100} },
  { {10760,464,110}, {11100,704,130}, {11440,944,140}, {11800,1124,130}, {12160,1224,110}, {12500,1364,100} },
  { {16120,1164,110}, {16400,1464,120}, {16760,1704,120}, {17100,1744,120}, {17400,1544,110}, {17700,1304,100} },
  { {18100,1104,110}, {18500,864,120}, {18900,624,120}, {19400,504,110}, {19900,664,100} },
  { {23960,1804,90}, {23720,1544,110}, {23480,1264,110}, {23260,1024,100} },
  { {24300,944,110}, {24640,704,120}, {24960,424,120}, {24600,224,110} },
  { {27960,544,110}, {28300,824,130}, {28600,1164,140}, {28840,1504,130}, {29200,1624,120}, {29500,1164,120}, {29900,824,120}, {30400,504,110}, {30900,364,100} },
  { {32160,1664,110}, {32600,1424,120}, {33100,1124,120}, {33560,824,110}, {33900,604,100} },
  { {35700,1124,110}, {36100,1304,110}, {36500,1604,100}, {36800,1504,100}, {37080,1264,110}, {36840,944,110}, {36500,784,110} },
}
LEDGES = {
  {80,720,304}, {1000,1800,264}, {2200,3000,304}, {3200,3440,664}, {3560,3760,944}, {3800,4240,1104}, {6100,6520,864}, {6500,7400,824}, {7700,8600,1104}, {8800,9120,704}, {9240,9520,544}, {10100,10600,424}, {12600,13300,1544}, {13600,14100,1144}, {14300,14800,1264}, {15000,15600,1304}, {15700,16100,1024}, {20100,20520,1224}, {21000,21300,824}, {21760,22060,1064}, {22360,22660,1344}, {25300,25900,824}, {26100,26700,944}, {26900,27400,864}, {27560,27900,1024}, {27800,28160,424}, {31100,31360,704}, {31500,31760,1064}, {31900,32120,1344}, {34160,34460,864}, {34760,35060,1164}, {35200,35520,984}, {37800,38600,544}
}
WINDS = {
  {9700,544,340,0.95},
  {21660,524,320,0.95},
}
PEARLS = {
  {x=1320, y=1264, kind="blue"},
  {x=2900, y=1464, kind="green"},
  {x=5100, y=1904, kind="purple"},
  {x=5700, y=1004, kind="blue"},
  {x=9700, y=984, kind="gold"},
  {x=11800, y=1304, kind="blue"},
  {x=15000, y=1444, kind="blue"},
  {x=17100, y=1784, kind="green"},
  {x=21660, y=1024, kind="purple"},
  {x=24120, y=1104, kind="gold"},
  {x=26600, y=1064, kind="blue"},
  {x=28800, y=1824, kind="green"},
  {x=32400, y=1704, kind="blue"},
  {x=37120, y=1824, kind="final"},
}
SPAWN_X, SPAWN_Y = 300, 424
WORLD_W, WORLD_H = 39820, 2064

-- 运动参数:与 2D 版逐帧模型同口径(Y 翻转为 Y-up)
local P = {
    x = 0, y = 0, vx = 0, vy = 0, radius = 11,
    gravity = 0.52, friction = 0.86, speed = 1.6,
    jumpForce = 15.5, dashSpeed = 19,
    dashTime = 0, dashDirX = 1, dashDirY = 0,
    isDashing = false, facingRight = true, canDash = true, isGrounded = false,
}
local keys = { a = false, d = false, w = false, s = false, space = false }
local dashPressed = false
local collectWindow = 0      -- 冲刺及冲刺后短窗内可收珠(与 2D 版一致)
local elapsed, accumulator = 0, 0
local FIXED_DT = 1 / 60

-- 视野系统
local visionR = 250          -- 基础视野半径(世界单位,投影到玩法平面)
local revealT = 0            -- 紫珠显形脉冲剩余帧
local finale = false         -- 终幕:大龙显现
local finaleT = 0
local lastGroundX, lastGroundY = 0, 0
local groundSaveT = 0

local circles = {}           -- 龙脊碰撞圆(稠密插值)
local buckets = {}           -- x 分桶
local pearlNodes = {}        -- {node=核心球, glow=光晕, data=PEARLS[i]}
local mistNodes = {}
local windNodes = {}

local function log(msg) print("[molong3d] " .. tostring(msg)) end

-- 引擎线性采样 + sRGB 输出会把颜色抬亮 ^(1/2.2):所有进材质的颜色先 ^2.2 预编码
local function enc(c, a)
    return Color(c.r ^ 2.2, c.g ^ 2.2, c.b ^ 2.2, a or c.a or 1.0)
end

-- ----------------------------------------------------------------------------
-- 材质 / 贴片工具
-- ----------------------------------------------------------------------------
local function makeUnlitColorMaterial(color)
    local mat = Material()
    local tech = cache:GetResource("Technique", "Techniques/NoTextureUnlit.xml")
    if tech then mat:SetTechnique(0, tech) end
    mat:SetShaderParameter("MatDiffColor", Variant(enc(color, 1.0)))
    return mat
end

local function makeTexMaterial(texPath, alphaTech, tint)
    local tex = cache:GetResource("Texture2D", texPath)
    if not tex then log("ERROR texture missing: " .. texPath); return nil end
    local mat = Material()
    local list = alphaTech and { "Techniques/DiffUnlitAlpha.xml", "Techniques/DiffAlpha.xml" }
        or { "Techniques/DiffUnlit.xml", "Techniques/Diff.xml" }
    local tech = nil
    for _, t in ipairs(list) do
        tech = cache:GetResource("Technique", t)
        if tech then break end
    end
    if not tech then log("ERROR no technique"); return nil end
    mat:SetTechnique(0, tech)
    mat:SetTexture(0, tex)
    tint = tint or Color(1, 1, 1, 1)
    mat:SetShaderParameter("MatDiffColor", Variant(enc(tint, tint.a)))
    return mat
end

-- 面向相机(-Z)的贴图平面
local function makeQuad(name, texPath, w, h, x, y, z, alphaTech, tint)
    local node = scene_:CreateChild(name)
    node.position = Vector3(x, y, z)
    node.rotation = Quaternion(-90, Vector3(1, 0, 0))
    node.scale = Vector3(w, 1, h)
    local model = node:CreateComponent("StaticModel")
    model:SetModel(cache:GetResource("Model", "Models/Plane.mdl"))
    local mat = makeTexMaterial(texPath, alphaTech, tint)
    if mat then model:SetMaterial(mat) end
    return node, mat
end

-- ----------------------------------------------------------------------------
-- 场景搭建
-- ----------------------------------------------------------------------------
local function createScene()
    scene_ = Scene()
    scene_:CreateComponent("Octree")
    local zoneNode = scene_:CreateChild("Zone")
    local zone = zoneNode:CreateComponent("Zone")
    zone.boundingBox = BoundingBox(-100000, 100000)
    zone.ambientColor = Color(1, 1, 1)
    zone.fogColor = Color(SILK.r ^ 2.2, SILK.g ^ 2.2, SILK.b ^ 2.2)
    zone.fogStart = 1300
    zone.fogEnd = 3600
    zone_ = zone
    log("paper-fog zone ok")
end

local function createScroll()
    -- 整卷画芯:10 片不透明贴图,z=30(玩家平面后方一点)
    local sliceW = WORLD_W / 10
    for i = 0, 9 do
        local path = string.format("assets/ink_atlas/molong3d/scroll_%02d.png", i)
        makeQuad("scroll" .. i, path, sliceW + 2, WORLD_H, (i + 0.5) * sliceW, WORLD_H * 0.5, 30, false)
    end
    log("scroll quads ok")
end

local function createParallax()
    -- 远景云雾(慢视差,雾色吞远)
    local defs = {
        { tex = "mist_a", x = 3000,  y = 1500, z = 700,  s = 2600 },
        { tex = "mist_b", x = 8200,  y = 900,  z = 1100, s = 3200 },
        { tex = "mist_c", x = 13500, y = 1600, z = 800,  s = 2800 },
        { tex = "mist_a", x = 19000, y = 1100, z = 1300, s = 3600 },
        { tex = "mist_b", x = 25000, y = 1500, z = 750,  s = 2600 },
        { tex = "mist_c", x = 31000, y = 900,  z = 1200, s = 3400 },
        { tex = "mist_a", x = 36500, y = 1400, z = 900,  s = 3000 },
    }
    for i, d in ipairs(defs) do
        local node = makeQuad("mistFar" .. i, "assets/ink_atlas/molong3d/" .. d.tex .. ".png",
            d.s, d.s * 0.45, d.x, d.y, d.z, true, Color(1, 1, 1, 0.34))
        mistNodes[#mistNodes + 1] = { node = node, baseX = d.x, spd = 0.10 + i * 0.025 }
    end
    -- 近景浮雾(在玩家前方,擦肩而过)
    local near = {
        { x = 5200,  y = 800,  s = 1500 },
        { x = 15500, y = 1200, s = 1700 },
        { x = 27500, y = 700,  s = 1500 },
        { x = 35500, y = 1300, s = 1600 },
    }
    for i, d in ipairs(near) do
        local node = makeQuad("mistNear" .. i, "assets/ink_atlas/molong3d/mist_b.png",
            d.s, d.s * 0.45, d.x, d.y, -140, true, Color(1, 1, 1, 0.13))
        mistNodes[#mistNodes + 1] = { node = node, baseX = d.x, spd = -0.18 - i * 0.03 }
    end
    log("parallax ok")
end

local PEARL_COLORS = {
    blue   = Color(0.45, 0.70, 1.00),
    green  = Color(0.50, 0.92, 0.62),
    gold   = Color(1.00, 0.80, 0.38),
    purple = Color(0.78, 0.55, 1.00),
    final  = Color(1.00, 0.95, 0.80),
}

local function createPearls()
    for i, pr in ipairs(PEARLS) do
        local col = PEARL_COLORS[pr.kind]
        local isFinal = (pr.kind == "final")
        local glowSize = isFinal and 300 or 150
        local glow = makeQuad("pearlGlow" .. i, "assets/ink_atlas/molong3d/pearl_glow.png",
            glowSize, glowSize, pr.x, pr.y, 6, true, Color(col.r, col.g, col.b, isFinal and 0.85 or 0.62))
        local core = scene_:CreateChild("pearl" .. i)
        core.position = Vector3(pr.x, pr.y, 0)
        local cr = isFinal and 26 or 13
        core.scale = Vector3(cr * 2, cr * 2, cr * 2)
        local cm = core:CreateComponent("StaticModel")
        cm:SetModel(cache:GetResource("Model", "Models/Sphere.mdl"))
        cm:SetMaterial(makeUnlitColorMaterial(Color(
            math.min(1, col.r * 1.15 + 0.2), math.min(1, col.g * 1.15 + 0.2), math.min(1, col.b * 1.15 + 0.2))))
        pearlNodes[i] = { core = core, glow = glow, data = pr, taken = false, phase = i * 1.7 }
    end
    log("pearls ok: " .. #PEARLS)
end

local function createLedgeWisps()
    -- 云台可视化:一缕淡墨云痕(否则平台不可见)
    for i, L in ipairs(LEDGES) do
        local w = L[2] - L[1]
        makeQuad("wisp" .. i, "assets/ink_atlas/molong3d/mist_b.png",
            w * 1.25, 64, (L[1] + L[2]) * 0.5, L[3] - 18, 10, true, Color(0.92, 0.88, 0.78, 0.30))
    end
    log("ledge wisps ok")
end

local function createWinds()
    -- 漩涡气流的视觉提示:缓转淡光盘
    for i, w in ipairs(WINDS) do
        local node = makeQuad("wind" .. i, "assets/ink_atlas/molong3d/pearl_glow.png",
            w[3] * 2.6, w[3] * 2.6, w[1], w[2], 14, true, Color(0.75, 0.82, 0.78, 0.10))
        windNodes[i] = { node = node, w = w }
    end
end

local function createPlayer()
    playerNode_ = scene_:CreateChild("InkBall")
    playerNode_.position = Vector3(P.x, P.y, 0)
    playerNode_.scale = Vector3(P.radius * 2, P.radius * 2, P.radius * 2)
    local pm = playerNode_:CreateComponent("StaticModel")
    pm:SetModel(cache:GetResource("Model", "Models/Sphere.mdl"))
    pm:SetMaterial(makeUnlitColorMaterial(INK))
    -- 墨珠周身一圈暖光:黑暗中的"灯笼"
    playerGlowNode_ = makeQuad("playerGlow", "assets/ink_atlas/molong3d/pearl_glow.png",
        320, 320, P.x, P.y, 18, true, Color(0.95, 0.88, 0.70, 0.085))
    log("player ok")
end

local function createVignette()
    -- 视野遮罩:跟随玩家的暗幕,中心透孔
    local node, mat = makeQuad("vignette", "assets/ink_atlas/molong3d/vignette.png",
        1500, 1500, P.x, P.y, -300, true)
    vignetteNode_ = node
    vignetteMat = mat
    log("vignette ok")
end

local function createCamera()
    cameraNode_ = scene_:CreateChild("Camera")
    cameraNode_.position = Vector3(P.x, P.y + 60, -880)
    local camera = cameraNode_:CreateComponent("Camera")
    camera.nearClip = 10
    camera.farClip = 7000
    camera.fov = 45
    renderer:SetViewport(0, Viewport:new(scene_, camera))
    log("camera ok")
end

-- ----------------------------------------------------------------------------
-- 碰撞构建:龙脊稠密圆链 + x 分桶
-- ----------------------------------------------------------------------------
local function buildCollision()
    for _, pts in ipairs(SPINES) do
        for i = 1, #pts - 1 do
            local a, b = pts[i], pts[i + 1]
            local dx, dy = b[1] - a[1], b[2] - a[2]
            local dist = math.sqrt(dx * dx + dy * dy)
            local n = math.max(1, math.floor(dist / 36))
            for k = 0, n - 1 do
                local t = k / n
                circles[#circles + 1] = {
                    a[1] + dx * t, a[2] + dy * t, a[3] + (b[3] - a[3]) * t }
            end
        end
        local last = pts[#pts]
        circles[#circles + 1] = { last[1], last[2], last[3] }
    end
    for _, c in ipairs(circles) do
        local b0 = math.floor((c[1] - c[3]) / 512)
        local b1 = math.floor((c[1] + c[3]) / 512)
        for b = b0, b1 do
            buckets[b] = buckets[b] or {}
            local list = buckets[b]
            list[#list + 1] = c
        end
    end
    log("collision circles: " .. #circles)
end

-- ----------------------------------------------------------------------------
-- 逐帧物理(2D 版同口径)
-- ----------------------------------------------------------------------------
local function respawn()
    P.x, P.y, P.vx, P.vy = lastGroundX, lastGroundY + 30, 0, 0
    P.isDashing = false
    P.canDash = true
end

local function onPearl(idx)
    local pn = pearlNodes[idx]
    pn.taken = true
    pn.core.enabled = false
    pn.glow.enabled = false
    local kind = pn.data.kind
    P.canDash = true
    P.vy = math.max(P.vy, 18.5)        -- 收珠弹跳(2D 版 -18.5 的 Y-up 版)
    if kind == "blue" then
        visionR = math.min(visionR + 115, 780)
    elseif kind == "green" then
        visionR = math.min(visionR + 55, 780)
    elseif kind == "gold" then
        visionR = math.min(visionR + 55, 780)
        P.vy = 26                       -- 金珠强弹射
    elseif kind == "purple" then
        visionR = math.min(visionR + 55, 780)
        revealT = 400                   -- 显形脉冲
    elseif kind == "final" then
        finale = true
        finaleT = 0
    end
    lastGroundX, lastGroundY = pn.data.x, pn.data.y   -- 珠即存盘点
    log("pearl " .. kind .. "  vision=" .. visionR)
end

local function fixedStep()
    elapsed = elapsed + FIXED_DT
    local prevY = P.y

    -- 冲刺触发
    if dashPressed and (not P.isDashing) and P.canDash then
        P.isDashing = true
        P.canDash = false
        P.dashTime = 12
        collectWindow = 34
        local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
        local dy = (keys.w and 1 or 0) - (keys.s and 1 or 0)
        if dx == 0 and dy == 0 then dx = P.facingRight and 1 or -1 end
        local d = math.sqrt(dx * dx + dy * dy)
        P.dashDirX, P.dashDirY = dx / d, dy / d
        P.vy = 0
    end
    dashPressed = false

    if P.isDashing then
        P.dashTime = P.dashTime - 1
        P.vx = P.dashDirX * P.dashSpeed
        P.vy = P.dashDirY * P.dashSpeed
        if P.dashTime <= 0 then
            P.isDashing = false
            P.vx = P.vx * 0.5
        end
    else
        if keys.a then P.vx = P.vx - P.speed; P.facingRight = false end
        if keys.d then P.vx = P.vx + P.speed; P.facingRight = true end
        if keys.space and P.isGrounded then
            P.vy = P.jumpForce
            P.isGrounded = false
            keys.space = false
        end
        P.vy = P.vy - P.gravity
        P.vx = P.vx * P.friction
    end
    if collectWindow > 0 then collectWindow = collectWindow - 1 end

    -- 漩涡气流:卷着玩家上升
    if not P.isDashing then
        for _, w in ipairs(WINDS) do
            local dx, dy = P.x - w[1], P.y - w[2]
            local rr = w[3] * 1.6
            if dx * dx + dy * dy < rr * rr then
                P.vy = math.min(P.vy + w[4], 11.5)
                P.vx = P.vx - dx * 0.002
            end
        end
    end

    P.x = P.x + P.vx
    P.y = P.y + P.vy
    if P.x < P.radius then P.x = P.radius; P.vx = 0 end
    if P.x > WORLD_W - P.radius then P.x = WORLD_W - P.radius; P.vx = 0 end

    -- 碰撞:云台(从上方落入)
    P.isGrounded = false
    for _, L in ipairs(LEDGES) do
        if P.vy <= 0 and P.x >= L[1] - P.radius and P.x <= L[2] + P.radius then
            local bottom = P.y - P.radius
            if bottom <= L[3] and prevY - P.radius >= L[3] - 6 then
                P.y = L[3] + P.radius
                P.vy = 0
                P.isGrounded = true
                P.canDash = true
            end
        end
    end
    -- 碰撞:龙脊圆链
    local bx = math.floor(P.x / 512)
    for b = bx - 1, bx + 1 do
        local list = buckets[b]
        if list then
            for _, c in ipairs(list) do
                local dx, dy = P.x - c[1], P.y - c[2]
                local R = c[3] + P.radius
                local d2 = dx * dx + dy * dy
                if d2 < R * R and d2 > 1e-6 then
                    local d = math.sqrt(d2)
                    local nx, ny = dx / d, dy / d
                    P.x = c[1] + nx * R
                    P.y = c[2] + ny * R
                    local vn = P.vx * nx + P.vy * ny
                    if vn < 0 then P.vx = P.vx - nx * vn; P.vy = P.vy - ny * vn end
                    if ny > 0.45 then P.isGrounded = true; P.canDash = true end
                end
            end
        end
    end

    -- 存盘点:站稳时记录
    if P.isGrounded then
        groundSaveT = groundSaveT + 1
        if groundSaveT > 18 then
            lastGroundX, lastGroundY = P.x, P.y
            groundSaveT = 0
        end
    else
        groundSaveT = 0
    end

    -- 跌落
    if P.y < -200 then respawn() end

    -- 收珠
    for i, pn in ipairs(pearlNodes) do
        if not pn.taken then
            local pr = pn.data
            local dx, dy = P.x - pr.x, P.y - pr.y
            local d2 = dx * dx + dy * dy
            if pr.kind == "final" then
                if d2 < 90 * 90 then onPearl(i) end
            elseif collectWindow > 0 and d2 < 64 * 64 then
                onPearl(i)
            end
        end
    end

    -- 节点同步
    playerNode_.position = Vector3(P.x, P.y, 0)
    local sq = 1.0
    if P.isDashing then sq = 1.18 end
    playerNode_.scale = Vector3(P.radius * 2 * sq, P.radius * 2 / sq, P.radius * 2)
    playerGlowNode_.position = Vector3(P.x, P.y, 18)

    -- 珠浮动
    for i, pn in ipairs(pearlNodes) do
        if not pn.taken then
            local bob = math.sin(elapsed * 2.0 + pn.phase) * 9
            pn.core.position = Vector3(pn.data.x, pn.data.y + bob, 0)
            pn.glow.position = Vector3(pn.data.x, pn.data.y + bob, 6)
            local pul = 1 + 0.10 * math.sin(elapsed * 3.1 + pn.phase)
            local base = (pn.data.kind == "final") and 300 or 150
            pn.glow.scale = Vector3(base * pul, 1, base * pul)
        end
    end
    -- 气流盘旋光
    for _, wn in ipairs(windNodes) do
        wn.node.rotation = Quaternion(-90, Vector3(1, 0, 0)) * Quaternion(elapsed * 18, Vector3(0, 1, 0))
    end
    -- 云雾漂移
    for _, m in ipairs(mistNodes) do
        local p = m.node.position
        m.node.position = Vector3(m.baseX + math.sin(elapsed * 0.05 * m.spd * 10) * 130, p.y, p.z)
    end

    -- 视野遮罩
    if revealT > 0 then revealT = revealT - 1 end
    local effR = visionR + (revealT > 0 and (900 * (revealT / 400) ^ 1.4) or 0)
    effR = effR * (1 + 0.022 * math.sin(elapsed * 1.7))
    if finale then
        finaleT = finaleT + 1
        -- 雾随拉远后退,保住全卷显现
        if zone_ then
            zone_.fogStart = math.min(1300 + finaleT * 10, 3400)
            zone_.fogEnd = math.min(3600 + finaleT * 14, 7600)
        end
        local fade = math.min(finaleT / 300, 1)
        if vignetteMat then
            vignetteMat:SetShaderParameter("MatDiffColor", Variant(Color(1, 1, 1, 1 - fade)))
        end
        if fade >= 1 and vignetteNode_.enabled then vignetteNode_.enabled = false end
    end
    -- 遮罩量纲:孔半径 = scale*0.1719(z=-300 投影到 z=0)
    local vs = effR / 0.1719
    vignetteNode_.position = Vector3(P.x, P.y, -300)
    vignetteNode_.scale = Vector3(vs, 1, vs)

    -- 相机:平滑跟随;终幕拉远纵览全卷
    local camZ = -880
    local camY = P.y + 60
    local camX = P.x + (P.facingRight and 60 or -60)
    if finale then
        camZ = -880 - math.min(finaleT * 6, 1700)
        camY = camY + math.min(finaleT * 1.2, 320)
    end
    local halfH = math.abs(camZ) * 0.4142
    if camY < halfH * 0.62 then camY = halfH * 0.62 end
    local target = Vector3(camX, camY, camZ)
    cameraNode_.position = cameraNode_.position:Lerp(target, 0.06)
end

-- ----------------------------------------------------------------------------
-- 事件
-- ----------------------------------------------------------------------------
function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    if dt > 0.05 then dt = 0.05 end
    accumulator = accumulator + dt
    while accumulator >= FIXED_DT do
        fixedStep()
        accumulator = accumulator - FIXED_DT
    end
end

function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    if key == KEY_A or key == KEY_LEFT then keys.a = true end
    if key == KEY_D or key == KEY_RIGHT then keys.d = true end
    if key == KEY_W or key == KEY_UP then keys.w = true end
    if key == KEY_S or key == KEY_DOWN then keys.s = true end
    if key == KEY_SPACE then keys.space = true end
    if key == KEY_J then dashPressed = true end
    if key == KEY_R then respawn() end
    if key == KEY_ESCAPE and engine ~= nil then engine:Exit() end
end

function HandleKeyUp(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    if key == KEY_A or key == KEY_LEFT then keys.a = false end
    if key == KEY_D or key == KEY_RIGHT then keys.d = false end
    if key == KEY_W or key == KEY_UP then keys.w = false end
    if key == KEY_S or key == KEY_DOWN then keys.s = false end
    if key == KEY_SPACE then keys.space = false end
end

function Start()
    log("=== 墨龙行 3D start ===")
    P.x, P.y = SPAWN_X, SPAWN_Y + 40
    lastGroundX, lastGroundY = SPAWN_X, SPAWN_Y
    createScene()
    createScroll()
    createParallax()
    createLedgeWisps()
    createWinds()
    createPearls()
    createPlayer()
    createVignette()
    createCamera()
    buildCollision()
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("KeyUp", "HandleKeyUp")
    log("=== ready: A/D 移动 SPACE 跳 J 冲刺 R 重生 ===")
end

function Stop()
end
