-- ============================================================================
-- 《墨龙·真形》— 纸境 3D:CustomGeometry 实体建模的水墨龙(3渲2)v2
-- 对标陈容《九龙图》:满身鳞甲(UV 环向贴图)/腹甲横纹/连续锯齿背鳍/
-- 后飘火焰鬃/眉骨金睛/张口獠牙/鹿角/长须/肘毛/前钩鹰爪
-- 启动: tools/run_dragon.ps1   操作: A/D 移动 SPACE 跳 J 冲刺 R 重生
-- ============================================================================

local scene_ = nil
local cameraNode_ = nil
local playerNode_ = nil
local playerGlowNode_ = nil
local zone_ = nil
local lightNode_ = nil

-- 暗绢底 / 水墨调色(贴图承担墨线,顶点色管明暗)
local SILK = Color(0.262, 0.248, 0.220)
local INK_TOP = Color(0.45, 0.42, 0.37)      -- 背脊(乘鳞片贴图后呈中墨)
local INK_BELLY = Color(0.88, 0.84, 0.74)    -- 腹甲(乘横纹贴图)
local OUTLINE_PALE = Color(0.82, 0.77, 0.63) -- 白描勾边
local BONE = Color(0.74, 0.68, 0.54)
local CLAW = Color(0.90, 0.85, 0.72)
local EYE_GOLD = Color(1.0, 0.80, 0.30)
local MANE_C = Color(0.70, 0.66, 0.55)       -- 鬃毛淡墨
local BROW_C = Color(0.20, 0.19, 0.165)      -- 眉骨浓墨
local CREST_DARK = Color(0.17, 0.16, 0.14)   -- 背鳍浓墨

-- 龙参数
local NSEG = 46
local SPACING = 62
local HEAD_X = 3350
local BASE_Y = 950
local AMP1, AMP2 = 145, 38
local ZAMP = 34
local WORLD_W = 4000

local P = {
    x = 130, y = 260, vx = 0, vy = 0, radius = 11,
    gravity = 0.52, friction = 0.86, speed = 1.6,
    jumpForce = 15.5, dashSpeed = 19,
    dashTime = 0, dashDirX = 1, dashDirY = 0,
    isDashing = false, facingRight = true, canDash = true, isGrounded = false,
}
local keys = { a = false, d = false, w = false, s = false, space = false }
local dashPressed = false
local collectWindow = 0
local elapsed, accumulator = 0, 0
local FIXED_DT = 1 / 60
local lastGroundX, lastGroundY = 130, 260
local groundSaveT = 0

local joints = {}
local sections = {}
local legs = {}
local headNode_ = nil
local jawNode_ = nil
local pearls = {}
local windNodes = {}
local mistDrift = {}
local finale = false
local finaleT = 0
local waveAmp, waveSpd = 1.0, 1.0

local outlineMat = nil   -- 勾边壳共享(终幕染金)
local vcolMat = nil      -- 顶点色(无贴图:头/鬃/角/爪等)
local scaleMat = nil     -- 顶点色 + 鳞片贴图(躯干/腿)

local FLOOR_Y = 140
local WINDS = { {800, 500, 240}, {1900, 500, 230}, {3000, 500, 230} }

local function log(msg) print("[dragon3d] " .. tostring(msg)) end

-- 引擎线性采样+sRGB 输出会抬亮颜色:进材质/顶点的颜色先 ^2.2 预编码
local function enc(c, a)
    return Color(c.r ^ 2.2, c.g ^ 2.2, c.b ^ 2.2, a or 1.0)
end

-- ----------------------------------------------------------------------------
-- 材质
-- ----------------------------------------------------------------------------
local function makeUnlitColorMaterial(color)
    local mat = Material:new()
    mat:SetTechnique(0, cache:GetResource("Technique", "Techniques/NoTextureUnlit.xml"))
    mat:SetShaderParameter("MatDiffColor", Variant(enc(color)))
    return mat
end

local function makeVColMaterial(texPath)
    local mat = Material:new()
    mat:SetTechnique(0, cache:GetResource("Technique", "Techniques/DiffVCol.xml"))
    mat:SetShaderParameter("MatDiffColor", Variant(Color(1, 1, 1, 1)))
    mat:SetShaderParameter("MatSpecColor", Variant(Color(0, 0, 0, 1)))
    if texPath then
        local tex = cache:GetResource("Texture2D", texPath)
        if tex then mat:SetTexture(0, tex) else log("WARN tex missing: " .. texPath) end
    end
    return mat
end

local function makeTexMaterial(texPath, tint)
    local tex = cache:GetResource("Texture2D", texPath)
    if not tex then log("ERROR tex: " .. texPath); return nil end
    local mat = Material:new()
    local tech = cache:GetResource("Technique", "Techniques/DiffUnlitAlpha.xml")
        or cache:GetResource("Technique", "Techniques/DiffAlpha.xml")
    mat:SetTechnique(0, tech)
    mat:SetTexture(0, tex)
    tint = tint or Color(1, 1, 1, 1)
    mat:SetShaderParameter("MatDiffColor", Variant(enc(tint, tint.a)))
    return mat
end

local function makeQuad(name, texPath, w, h, x, y, z, tint, parent)
    local node = (parent or scene_):CreateChild(name)
    node.position = Vector3(x, y, z)
    node.rotation = Quaternion(-90, Vector3(1, 0, 0))
    node.scale = Vector3(w, 1, h)
    local model = node:CreateComponent("StaticModel")
    model:SetModel(cache:GetResource("Model", "Models/Plane.mdl"))
    local mat = makeTexMaterial(texPath, tint)
    if mat then model:SetMaterial(mat) end
    return node, mat
end

-- ----------------------------------------------------------------------------
-- 锥管几何:扫掠管 + UV(u 环向: 0=背脊 0.5=腹中, v 沿身) + 反相壳勾边
-- rings: { {x,y,z, r, sy, col}, ... }
-- ----------------------------------------------------------------------------
local function shadeInk(ny)
    local u = (ny + 1) * 0.5
    local t = u ^ 1.2
    return Color(
        INK_BELLY.r + (INK_TOP.r - INK_BELLY.r) * t,
        INK_BELLY.g + (INK_TOP.g - INK_BELLY.g) * t,
        INK_BELLY.b + (INK_TOP.b - INK_BELLY.b) * t)
end

local function ringFrame(rings, i)
    local a = rings[math.max(1, i - 1)]
    local b = rings[math.min(#rings, i + 1)]
    local ax, ay, az = b[1] - a[1], b[2] - a[2], b[3] - a[3]
    local d = math.sqrt(ax * ax + ay * ay + az * az)
    if d < 1e-5 then ax, ay, az = 1, 0, 0; d = 1 end
    ax, ay, az = ax / d, ay / d, az / d
    local ux, uy, uz = 0, 1, 0
    if math.abs(ay) > 0.93 then ux, uy, uz = 0, 0, 1 end
    local sx = ay * uz - az * uy
    local sy = az * ux - ax * uz
    local sz = ax * uy - ay * ux
    local sd = math.sqrt(sx * sx + sy * sy + sz * sz)
    sx, sy, sz = sx / sd, sy / sd, sz / sd
    local vx = sy * az - sz * ay
    local vy = sz * ax - sx * az
    local vz = sx * ay - sy * ax
    return sx, sy, sz, vx, vy, vz
end

local function buildTube(parent, rings, opts)
    opts = opts or {}
    local S = opts.segments or 12
    local capEnd = opts.capEnd ~= false
    local capStart = opts.capStart ~= false
    local outline = opts.outline
    local outW = opts.outlineW or 5.5
    local mat = opts.mat or vcolMat
    local vTile = opts.vTile or 440    -- 鳞片沿身平铺周期(一鳞约 14 世界单位)

    -- 环间累计弧长(v 坐标)
    local dist = { 0 }
    for i = 2, #rings do
        local a, b = rings[i - 1], rings[i]
        local dd = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2)
        dist[i] = dist[i - 1] + dd
    end

    local main, shell = {}, {}
    for i, rg in ipairs(rings) do
        local sx, sy, sz, vx, vy, vz = ringFrame(rings, i)
        local r, syq = rg[4], rg[5] or 1.0
        main[i], shell[i] = {}, {}
        for k = 0, S - 1 do
            local ang = (k / S) * 2 * math.pi
            local c, s = math.cos(ang), math.sin(ang)
            local nx = sx * c + vx * s
            local ny = sy * c + vy * s * syq
            local nz = sz * c + vz * s
            local nd = math.sqrt(nx * nx + ny * ny + nz * nz)
            nx, ny, nz = nx / nd, ny / nd, nz / nd
            main[i][k] = {
                rg[1] + sx * c * r + vx * s * r * syq,
                rg[2] + sy * c * r + vy * s * r * syq,
                rg[3] + sz * c * r + vz * s * r * syq,
                nx, ny, nz }
            local ro = r + outW
            shell[i][k] = {
                rg[1] + sx * c * ro + vx * s * ro * syq,
                rg[2] + sy * c * ro + vy * s * ro * syq,
                rg[3] + sz * c * ro + vz * s * ro * syq }
        end
    end

    local geomNode = parent:CreateChild("tube")
    local geom = geomNode:CreateComponent("CustomGeometry")
    geom:SetNumGeometries(1)
    geom:BeginGeometry(0, TRIANGLE_LIST)
    local hasTC = geom.DefineTexCoord ~= nil
    -- u: 环向角 -> 0=背脊(ang=π/2), 0.5=腹中;不取模保证缠绕连续
    local function uOf(k) return k / S - 0.25 end
    local function emitV(v, col, u, vd)
        geom:DefineVertex(Vector3(v[1], v[2], v[3]))
        geom:DefineNormal(Vector3(v[4], v[5], v[6]))
        if hasTC then geom:DefineTexCoord(Vector2(u, vd / vTile)) end
        geom:DefineColor(enc(col))
    end
    local function colorOf(ringIdx, v)
        local rc = rings[ringIdx][6]
        if rc then return rc end
        return shadeInk(v[5])
    end
    for i = 1, #rings - 1 do
        for k = 0, S - 1 do
            local k2 = (k + 1) % S
            local u1, u2 = uOf(k), uOf(k + 1)
            local a, b = main[i][k], main[i][k2]
            local c, d = main[i + 1][k], main[i + 1][k2]
            emitV(a, colorOf(i, a), u1, dist[i]); emitV(c, colorOf(i + 1, c), u1, dist[i + 1]); emitV(b, colorOf(i, b), u2, dist[i])
            emitV(b, colorOf(i, b), u2, dist[i]); emitV(c, colorOf(i + 1, c), u1, dist[i + 1]); emitV(d, colorOf(i + 1, d), u2, dist[i + 1])
        end
    end
    local function cap(idx, dirSign)
        local rg = rings[idx]
        local cc = rings[idx][6] or shadeInk(0)
        for k = 0, S - 1 do
            local k2 = (k + 1) % S
            local a, b = main[idx][k], main[idx][k2]
            geom:DefineVertex(Vector3(rg[1], rg[2], rg[3])); geom:DefineNormal(Vector3(dirSign, 0, 0))
            if hasTC then geom:DefineTexCoord(Vector2(0.25, 0.25)) end
            geom:DefineColor(enc(cc))
            local p1, p2
            if dirSign > 0 then p1, p2 = a, b else p1, p2 = b, a end
            geom:DefineVertex(Vector3(p1[1], p1[2], p1[3])); geom:DefineNormal(Vector3(dirSign, 0, 0))
            if hasTC then geom:DefineTexCoord(Vector2(0.25, 0.25)) end
            geom:DefineColor(enc(cc))
            geom:DefineVertex(Vector3(p2[1], p2[2], p2[3])); geom:DefineNormal(Vector3(dirSign, 0, 0))
            if hasTC then geom:DefineTexCoord(Vector2(0.25, 0.25)) end
            geom:DefineColor(enc(cc))
        end
    end
    if capStart then cap(1, -1) end
    if capEnd then cap(#rings, 1) end
    geom:Commit()
    geom:SetMaterial(mat)

    if outline then
        local olNode = parent:CreateChild("ol")
        local og = olNode:CreateComponent("CustomGeometry")
        og:SetNumGeometries(1)
        og:BeginGeometry(0, TRIANGLE_LIST)
        local function emitO(v)
            og:DefineVertex(Vector3(v[1], v[2], v[3]))
            og:DefineNormal(Vector3(0, 1, 0))
            og:DefineColor(Color(1, 1, 1, 1))
        end
        for i = 1, #rings - 1 do
            for k = 0, S - 1 do
                local k2 = (k + 1) % S
                local a, b = shell[i][k], shell[i][k2]
                local c, d = shell[i + 1][k], shell[i + 1][k2]
                emitO(a); emitO(b); emitO(c)
                emitO(b); emitO(d); emitO(c)
            end
        end
        og:Commit()
        og:SetMaterial(outlineMat)
    end
    return geomNode
end

-- 鳍/鬃/火焰片:双面三角片
local function buildFin(parent, x, y, z, len, h, lean, thick, c1, c2)
    local node = parent:CreateChild("fin")
    local geom = node:CreateComponent("CustomGeometry")
    geom:SetNumGeometries(1)
    geom:BeginGeometry(0, TRIANGLE_LIST)
    local baseC, tipC = enc(c1 or CREST_DARK), enc(c2 or OUTLINE_PALE)
    local tipX, tipY = x - len * lean, y + h
    thick = thick or 3
    local function tri(p1, p2, p3, n)
        for _, pc in ipairs({ { p1, baseC }, { p2, baseC }, { p3, tipC } }) do
            geom:DefineVertex(pc[1]); geom:DefineNormal(n); geom:DefineColor(pc[2])
        end
    end
    tri(Vector3(x - len * 0.5, y, z - thick), Vector3(x + len * 0.5, y, z - thick), Vector3(tipX, tipY, z), Vector3(0, 0, -1))
    tri(Vector3(x + len * 0.5, y, z + thick), Vector3(x - len * 0.5, y, z + thick), Vector3(tipX, tipY, z), Vector3(0, 0, 1))
    geom:Commit()
    geom:SetMaterial(vcolMat)
    return node
end

-- ----------------------------------------------------------------------------
-- 龙身:鳞甲管节 + 连续锯齿背鳍
-- ----------------------------------------------------------------------------
local function radAt(i)
    local t = i / (NSEG - 1)
    if t < 0.10 then return 42 + t / 0.10 * 16
    elseif t < 0.30 then return 58 + (t - 0.10) / 0.20 * 8
    elseif t < 0.62 then return 66 - (t - 0.30) / 0.32 * 14
    else return math.max(6, 52 - (t - 0.62) / 0.38 * 46) end
end

local function jointPose(i, t)
    local s = i * SPACING
    local x = HEAD_X - s
    -- 尾段下垂:从云海登上龙背的坡道
    local droop = math.max(0, i - 31) * 17
    local y = BASE_Y - droop + AMP1 * waveAmp * math.sin(t * 1.05 * waveSpd - i * 0.32)
        + AMP2 * math.sin(t * 0.47 * waveSpd - i * 0.13 + 0.8)
    local z = ZAMP * math.sin(t * 0.66 - i * 0.21 + 1.4)
    return x, y, z
end

local function createDragonBody()
    for i = 0, NSEG - 1 do
        local x, y, z = jointPose(i, 0)
        joints[i] = { x = x, y = y, z = z, py = y, r = radAt(i) }
    end
    for i = 0, NSEG - 2 do
        local node = scene_:CreateChild("seg" .. i)
        local r1, r2 = radAt(i), radAt(i + 1)
        local len = SPACING
        buildTube(node, {
            { -10,      0, 0, r1, 1.12 },
            { len + 10, 0, 0, r2, 1.12 },
        }, { segments = 14, outline = true, outlineW = 5, capStart = (i == NSEG - 2), capEnd = false, mat = scaleMat })
        -- 连续锯齿背鳍:每节 3 齿,后倾火焰状
        if i > 0 and i < NSEG - 6 then
            local r = (r1 + r2) * 0.5
            for tooth = 0, 2 do
                local bx = len * (0.16 + tooth * 0.33)
                local hh = (r * 0.34 + 12) * (tooth == 1 and 1.25 or 1.0)
                buildFin(node, bx, r * 1.04, 0, 13 + r * 0.10, hh, 1.15, 2)
            end
        end
        sections[i] = { node = node, len = len }
    end
    -- 尾尖火焰束
    local tail = sections[NSEG - 2].node
    for k = 1, 5 do
        buildFin(tail, SPACING + 6, -6 + k * 3, (k - 3) * 4, 24, 26 + k * 9, 1.0 - k * 0.08, 2, CREST_DARK, MANE_C)
    end
    log("body ok: " .. (NSEG - 1) .. " sections (scaled)")
end

-- ----------------------------------------------------------------------------
-- 腿爪:鳞甲腿 + 肘毛 + 鹰爪(三前钩趾 + 一后趾)
-- ----------------------------------------------------------------------------
local function buildLeg(secIdx, side, phase)
    local parent = sections[secIdx].node
    local r = radAt(secIdx)
    local hip = parent:CreateChild("hip")
    hip.position = Vector3(SPACING * 0.5, -r * 0.35, side * r * 0.72)
    buildTube(hip, {
        { 0, 6, 0, 16, 1.0 },
        { 26, -60, side * 14, 12, 1.0 },
    }, { segments = 10, outline = true, outlineW = 4, mat = scaleMat, vTile = 200 })
    local knee = hip:CreateChild("knee")
    knee.position = Vector3(26, -60, side * 14)
    buildTube(knee, {
        { 0, 0, 0, 11, 1.0 },
        { -12, -56, side * 6, 8.5, 1.0 },
    }, { segments = 10, outline = true, outlineW = 3.5, mat = scaleMat, vTile = 200 })
    -- 肘毛:肘后火焰两束
    buildFin(knee, 6, -6, side * 8, 16, 30, -1.5, 2, CREST_DARK, MANE_C)
    buildFin(knee, 10, -16, side * 8, 13, 22, -1.7, 2, CREST_DARK, MANE_C)
    -- 鹰爪:三前趾(前钩)
    for c = -1, 1 do
        buildTube(knee, {
            { -12, -56, side * 6 + c * 9, 5.0, 1, CLAW },
            { 6, -64, side * 6 + c * 13, 3.2, 1, CLAW },
            { 18, -58, side * 6 + c * 15, 1.4, 1, CLAW },
            { 22, -50, side * 6 + c * 15, 0.6, 1, CLAW },
        }, { segments = 8, capStart = false })
    end
    -- 后趾
    buildTube(knee, {
        { -12, -56, side * 6, 4.2, 1, CLAW },
        { -26, -62, side * 4, 2.2, 1, CLAW },
        { -32, -54, side * 4, 0.8, 1, CLAW },
    }, { segments = 8, capStart = false })
    legs[#legs + 1] = { hip = hip, phase = phase }
end

-- ----------------------------------------------------------------------------
-- 龙首:扁长颅/眉骨/张口獠牙/鹿角/后飘鬃/长须
-- ----------------------------------------------------------------------------
local function createDragonHead()
    headNode_ = scene_:CreateChild("dragonHead")
    -- 颅 + 上颚(扁长,鼻端上翘)
    buildTube(headNode_, {
        { -36, 4, 0, 38, 1.02 },
        { 8, 12, 0, 44, 1.10 },
        { 52, 8, 0, 29, 0.88 },
        { 96, 12, 0, 21, 0.78 },
        { 132, 26, 0, 14, 0.68 },
    }, { segments = 14, outline = true, outlineW = 5 })
    -- 眉骨(浓墨棱)
    for side = -1, 1, 2 do
        buildTube(headNode_, {
            { 24, 34, side * 26, 8, 1, BROW_C },
            { 48, 41, side * 25, 6, 1, BROW_C },
            { 62, 36, side * 23, 2.5, 1, BROW_C },
        }, { segments = 8, capStart = false })
    end
    -- 下颌(大张口)
    jawNode_ = headNode_:CreateChild("jaw")
    jawNode_.position = Vector3(40, -12, 0)
    buildTube(jawNode_, {
        { 0, 0, 0, 16, 0.70 },
        { 46, -8, 0, 11, 0.60 },
        { 78, -2, 0, 6.5, 0.52 },
    }, { segments = 10, outline = true, outlineW = 4 })
    -- 獠牙
    for _, d in ipairs({ { 122, 10, 10, -24 }, { 122, 10, -10, -24 } }) do
        buildTube(headNode_, {
            { d[1], d[2], d[3], 4, 1, CLAW },
            { d[1] + 7, d[2] + d[4], d[3], 1.1, 1, CLAW },
        }, { segments = 8, capStart = false })
    end
    for _, d in ipairs({ { 70, 0, 8, 18 }, { 70, 0, -8, 18 } }) do
        buildTube(jawNode_, {
            { d[1], d[2], d[3], 3.4, 1, CLAW },
            { d[1] + 5, d[2] + d[4], d[3], 0.9, 1, CLAW },
        }, { segments = 8, capStart = false })
    end
    -- 金睛墨瞳(眉骨下)
    for side = -1, 1, 2 do
        local eye = headNode_:CreateChild("eye")
        eye.position = Vector3(40, 28, side * 28)
        eye.scale = Vector3(15, 15, 15)
        local em = eye:CreateComponent("StaticModel")
        em:SetModel(cache:GetResource("Model", "Models/Sphere.mdl"))
        em:SetMaterial(makeUnlitColorMaterial(EYE_GOLD))
        local pup = headNode_:CreateChild("pupil")
        pup.position = Vector3(44, 29, side * 33)
        pup.scale = Vector3(6.5, 8.5, 6.5)
        local pm = pup:CreateComponent("StaticModel")
        pm:SetModel(cache:GetResource("Model", "Models/Sphere.mdl"))
        pm:SetMaterial(makeUnlitColorMaterial(Color(0.04, 0.04, 0.035)))
    end
    -- 鹿角(更长,后掠带双叉)
    for side = -1, 1, 2 do
        local horn = headNode_:CreateChild("horn")
        horn.position = Vector3(4, 38, side * 17)
        buildTube(horn, {
            { 0, 0, 0, 7.5, 1, BONE },
            { -34, 26, side * 9, 5.5, 1, BONE },
            { -70, 44, side * 15, 4.0, 1, BONE },
            { -108, 56, side * 19, 1.5, 1, BONE },
        }, { segments = 9, outline = true, outlineW = 3, capStart = false })
        local fork = horn:CreateChild("fork")
        buildTube(fork, {
            { -34, 26, side * 9, 4.0, 1, BONE },
            { -52, 54, side * 13, 1.2, 1, BONE },
        }, { segments = 8, capStart = false })
        buildTube(fork, {
            { -70, 44, side * 15, 3.0, 1, BONE },
            { -88, 68, side * 18, 1.0, 1, BONE },
        }, { segments = 7, capStart = false })
    end
    -- 鬃毛:向后飘的火焰束(风吹感)
    for k = 0, 9 do
        local a = (k / 9 - 0.5) * 2.6
        local zz = math.sin(a) * 30
        local yy = 12 + math.cos(a) * 24
        local ln = 56 + (k % 3) * 24
        buildTube(headNode_, {
            { -22, yy, zz, 5.0, 1, MANE_C },
            { -22 - ln * 0.5, yy + 16 + (k % 2) * 9, zz * 1.3, 3.0, 1, MANE_C },
            { -22 - ln, yy + 24 + (k % 2) * 14, zz * 1.5, 0.9, 1, MANE_C },
        }, { segments = 7, capStart = false })
    end
    -- 颊毛短簇
    for side = -1, 1, 2 do
        buildFin(headNode_, 8, 6, side * 34, 22, 18, 1.6, 2, CREST_DARK, MANE_C)
        buildFin(headNode_, -8, -8, side * 32, 20, -22, 1.8, 2, CREST_DARK, MANE_C)
    end
    -- 颌下须髯(细管后飘)
    for k = -1, 1 do
        buildTube(jawNode_, {
            { 10, -10, k * 9, 3.0, 1, MANE_C },
            { -16, -26, k * 13, 1.8, 1, MANE_C },
            { -42, -30, k * 15, 0.7, 1, MANE_C },
        }, { segments = 6, capStart = false })
    end
    -- 长须(吻侧,S 形卷曲后飘)
    for side = -1, 1, 2 do
        buildTube(headNode_, {
            { 120, 16, side * 13, 2.0, 1, BONE },
            { 96, 34, side * 30, 1.6, 1, BONE },
            { 60, 50, side * 42, 1.3, 1, BONE },
            { 22, 44, side * 50, 1.0, 1, BONE },
            { -12, 30, side * 54, 0.6, 1, BONE },
        }, { segments = 6, capStart = false })
    end
    log("head ok")
end

-- ----------------------------------------------------------------------------
-- 场景 / 环境 / 珠 / 玩家
-- ----------------------------------------------------------------------------
local function createScene()
    scene_ = Scene()
    scene_:CreateComponent("Octree")
    local zoneNode = scene_:CreateChild("Zone")
    local zone = zoneNode:CreateComponent("Zone")
    zone.boundingBox = BoundingBox(-100000, 100000)
    zone.ambientColor = Color(0.72, 0.70, 0.65)
    zone.fogColor = Color(SILK.r ^ 2.2, SILK.g ^ 2.2, SILK.b ^ 2.2)
    zone.fogStart = 1400
    zone.fogEnd = 3800
    zone_ = zone
    lightNode_ = scene_:CreateChild("Sun")
    lightNode_.direction = Vector3(0.35, -0.5, 0.72)
    local light = lightNode_:CreateComponent("Light")
    light.lightType = LIGHT_DIRECTIONAL
    light.color = Color(0.55, 0.52, 0.46)
    log("scene ok")
end

local function createEnvironment()
    makeQuad("floorWisp1", "assets/ink_atlas/molong3d/mist_b.png", 2600, 360, 900, FLOOR_Y - 60, 12, Color(0.9, 0.86, 0.76, 0.40))
    makeQuad("floorWisp2", "assets/ink_atlas/molong3d/mist_a.png", 2600, 340, 2700, FLOOR_Y - 70, 14, Color(0.9, 0.86, 0.76, 0.36))
    local defs = {
        { "mist_a", 800, 1300, 800, 2400 }, { "mist_c", 2200, 700, 1200, 3000 },
        { "mist_b", 3400, 1500, 900, 2600 }, { "mist_a", 1500, 1700, 1500, 3200 },
    }
    for i, d in ipairs(defs) do
        local n = makeQuad("mistF" .. i, "assets/ink_atlas/molong3d/" .. d[1] .. ".png",
            d[5], d[5] * 0.45, d[2], d[3], d[4], Color(1, 1, 1, 0.30))
        mistDrift[#mistDrift + 1] = { node = n, baseX = d[2], spd = 0.6 + i * 0.2 }
    end
    local nearM = makeQuad("mistN", "assets/ink_atlas/molong3d/mist_b.png",
        1600, 720, 2000, 600, -150, Color(1, 1, 1, 0.10))
    mistDrift[#mistDrift + 1] = { node = nearM, baseX = 2000, spd = -1.2 }
    for i, w in ipairs(WINDS) do
        local n = makeQuad("wind" .. i, "assets/ink_atlas/molong3d/pearl_glow.png",
            w[3] * 2.4, w[3] * 2.4, w[1], w[2], 16, Color(0.75, 0.82, 0.78, 0.10))
        windNodes[i] = n
    end
    log("env ok")
end

local PEARL_COLORS = {
    blue = Color(0.45, 0.70, 1.00), green = Color(0.50, 0.92, 0.62),
    gold = Color(1.00, 0.80, 0.38), final = Color(1.00, 0.95, 0.80),
}

local function createPearls()
    local defs = {
        { seg = 40, kind = "blue" }, { seg = 32, kind = "green" },
        { seg = 24, kind = "gold" }, { seg = 16, kind = "blue" },
        { seg = 8,  kind = "green" }, { head = true, kind = "final" },
    }
    for i, d in ipairs(defs) do
        local col = PEARL_COLORS[d.kind]
        local isF = (d.kind == "final")
        local glow = makeQuad("pglow" .. i, "assets/ink_atlas/molong3d/pearl_glow.png",
            isF and 260 or 140, isF and 260 or 140, 0, 0, 6, Color(col.r, col.g, col.b, isF and 0.85 or 0.62))
        local core = scene_:CreateChild("pearl" .. i)
        local cr = isF and 24 or 12
        core.scale = Vector3(cr * 2, cr * 2, cr * 2)
        local cm = core:CreateComponent("StaticModel")
        cm:SetModel(cache:GetResource("Model", "Models/Sphere.mdl"))
        cm:SetMaterial(makeUnlitColorMaterial(Color(
            math.min(1, col.r * 1.15 + 0.2), math.min(1, col.g * 1.15 + 0.2), math.min(1, col.b * 1.15 + 0.2))))
        pearls[i] = { seg = d.seg, head = d.head, kind = d.kind, node = core, glow = glow,
            taken = false, phase = i * 1.4, x = 0, y = 0 }
    end
    log("pearls ok")
end

local function createPlayer()
    playerNode_ = scene_:CreateChild("InkBall")
    playerNode_.position = Vector3(P.x, P.y, 0)
    playerNode_.scale = Vector3(P.radius * 2, P.radius * 2, P.radius * 2)
    local pm = playerNode_:CreateComponent("StaticModel")
    pm:SetModel(cache:GetResource("Model", "Models/Sphere.mdl"))
    pm:SetMaterial(makeUnlitColorMaterial(Color(0.07, 0.065, 0.06)))
    playerGlowNode_ = makeQuad("playerGlow", "assets/ink_atlas/molong3d/pearl_glow.png",
        300, 300, P.x, P.y, 20, Color(0.95, 0.88, 0.70, 0.07))
end

local function createCamera()
    cameraNode_ = scene_:CreateChild("Camera")
    cameraNode_.position = Vector3(P.x, P.y + 60, -880)
    local camera = cameraNode_:CreateComponent("Camera")
    camera.nearClip = 10
    camera.farClip = 7000
    camera.fov = 45
    renderer:SetViewport(0, Viewport:new(scene_, camera))
end

-- ----------------------------------------------------------------------------
-- 动画与物理
-- ----------------------------------------------------------------------------
local FROM_X = Vector3(1, 0, 0)

local function updateDragon(t)
    for i = 0, NSEG - 1 do
        local j = joints[i]
        j.py = j.y
        j.x, j.y, j.z = jointPose(i, t)
    end
    for i = 0, NSEG - 2 do
        local a, b = joints[i], joints[i + 1]
        local node = sections[i].node
        node.position = Vector3(b.x, b.y, b.z)
        local dir = Vector3(a.x - b.x, a.y - b.y, a.z - b.z)
        local q = Quaternion()
        q:FromRotationTo(FROM_X, dir:Normalized())
        node.rotation = q
    end
    local j0, j1 = joints[0], joints[1]
    local hd = Vector3(j0.x - j1.x, j0.y - j1.y, j0.z - j1.z):Normalized()
    headNode_.position = Vector3(j0.x + hd.x * 30, j0.y + hd.y * 30 + math.sin(t * 1.3) * 6, j0.z + hd.z * 30)
    local hq = Quaternion()
    hq:FromRotationTo(FROM_X, hd)
    headNode_.rotation = hq * Quaternion(math.sin(t * 0.9) * 6, Vector3(0, 1, 0))
    -- 大张口呼吸
    jawNode_.rotation = Quaternion(0, 0, -22 + math.sin(t * 1.7) * 6)
    for _, leg in ipairs(legs) do
        leg.hip.rotation = Quaternion(0, 0, math.sin(t * 1.05 + leg.phase) * 14)
    end
end

local function onPearl(i)
    local pr = pearls[i]
    pr.taken = true
    pr.node.enabled = false
    pr.glow.enabled = false
    P.canDash = true
    P.vy = math.max(P.vy, 18.5)
    if pr.kind == "gold" then P.vy = 26 end
    if pr.kind == "final" then
        finale = true
        finaleT = 0
        waveAmp, waveSpd = 1.45, 1.35
        if outlineMat then
            outlineMat:SetShaderParameter("MatDiffColor", Variant(enc(Color(1.0, 0.82, 0.35))))
        end
    end
    log("pearl " .. pr.kind)
end

local function respawn()
    P.x, P.y, P.vx, P.vy = lastGroundX, lastGroundY + 30, 0, 0
    P.isDashing = false
    P.canDash = true
end

local function fixedStep()
    elapsed = elapsed + FIXED_DT
    local t = elapsed
    updateDragon(t)

    local prevY = P.y
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

    if not P.isDashing then
        for _, w in ipairs(WINDS) do
            local dx, dy = P.x - w[1], P.y - w[2]
            local rr = w[3] * 1.7
            if dx * dx + dy * dy < rr * rr then
                P.vy = math.min(P.vy + 0.95, 11.5)
                P.vx = P.vx - dx * 0.002
            end
        end
    end

    P.x = P.x + P.vx
    P.y = P.y + P.vy
    if P.x < P.radius then P.x = P.radius; P.vx = 0 end
    if P.x > WORLD_W - P.radius then P.x = WORLD_W - P.radius; P.vx = 0 end

    P.isGrounded = false
    if P.vy <= 0 and P.y - P.radius <= FLOOR_Y and prevY - P.radius >= FLOOR_Y - 8 then
        P.y = FLOOR_Y + P.radius
        P.vy = 0
        P.isGrounded = true
        P.canDash = true
    end
    for i = 0, NSEG - 1 do
        local j = joints[i]
        local dx, dy = P.x - j.x, P.y - j.y
        local R = j.r * 0.95 + P.radius
        local d2 = dx * dx + dy * dy
        if d2 < R * R and d2 > 1e-6 then
            local d = math.sqrt(d2)
            local nx, ny = dx / d, dy / d
            P.x = j.x + nx * R
            P.y = j.y + ny * R
            local vn = P.vx * nx + P.vy * ny
            if vn < 0 then P.vx = P.vx - nx * vn; P.vy = P.vy - ny * vn end
            if ny > 0.4 then
                P.isGrounded = true
                P.canDash = true
                P.y = P.y + (j.y - j.py)
            end
        end
    end

    if P.isGrounded then
        groundSaveT = groundSaveT + 1
        if groundSaveT > 18 then
            lastGroundX, lastGroundY = P.x, P.y
            groundSaveT = 0
        end
    else
        groundSaveT = 0
    end
    if P.y < -200 then respawn() end

    for i, pr in ipairs(pearls) do
        if not pr.taken then
            if pr.head then
                local hp = headNode_.position
                local ang = t * 1.2
                pr.x = hp.x + math.cos(ang) * 150
                pr.y = hp.y + 60 + math.sin(ang) * 70
            else
                local j = joints[pr.seg]
                pr.x = j.x
                pr.y = j.y + j.r + 58 + math.sin(t * 2 + pr.phase) * 9
            end
            pr.node.position = Vector3(pr.x, pr.y, 0)
            pr.glow.position = Vector3(pr.x, pr.y, 6)
            local dx, dy = P.x - pr.x, P.y - pr.y
            local d2 = dx * dx + dy * dy
            if pr.head then
                if d2 < 95 * 95 then onPearl(i) end
            elseif collectWindow > 0 and d2 < 64 * 64 then
                onPearl(i)
            end
        end
    end

    playerNode_.position = Vector3(P.x, P.y, 0)
    local sq = P.isDashing and 1.18 or 1.0
    playerNode_.scale = Vector3(P.radius * 2 * sq, P.radius * 2 / sq, P.radius * 2)
    playerGlowNode_.position = Vector3(P.x, P.y, 20)
    for _, m in ipairs(mistDrift) do
        local p = m.node.position
        m.node.position = Vector3(m.baseX + math.sin(t * 0.05 * m.spd) * 120, p.y, p.z)
    end
    for i, n in ipairs(windNodes) do
        n.rotation = Quaternion(-90, Vector3(1, 0, 0)) * Quaternion(t * 20 + i * 50, Vector3(0, 1, 0))
    end

    local camZ = -880
    local camY = P.y + 60
    local camX = P.x + (P.facingRight and 60 or -60)
    if finale then
        finaleT = finaleT + 1
        camZ = -880 - math.min(finaleT * 6, 1500)
        camY = camY + math.min(finaleT * 1.0, 260)
        if zone_ then
            zone_.fogStart = math.min(1400 + finaleT * 9, 3200)
            zone_.fogEnd = math.min(3800 + finaleT * 12, 7000)
        end
    end
    local halfH = math.abs(camZ) * 0.4142
    if camY < halfH * 0.60 then camY = halfH * 0.60 end
    cameraNode_.position = cameraNode_.position:Lerp(Vector3(camX, camY, camZ), 0.06)
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
    log("=== 墨龙·真形 v2 start ===")
    createScene()
    vcolMat = makeVColMaterial(nil)
    vcolMat:SetShaderParameter("MatDiffColor", Variant(Color(0.62, 0.60, 0.56, 1)))
    scaleMat = makeVColMaterial("assets/ink_atlas/molong3d/dragon_scales.png")
    outlineMat = makeUnlitColorMaterial(OUTLINE_PALE)
    createEnvironment()
    createDragonBody()
    buildLeg(6, 1, 0); buildLeg(6, -1, 1.6)
    buildLeg(24, 1, 0.8); buildLeg(24, -1, 2.4)
    createDragonHead()
    createPearls()
    createPlayer()
    createCamera()
    updateDragon(0)
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("KeyUp", "HandleKeyUp")
    log("=== ready ===")
end

function Stop()
end
