-- ============================================================================
-- 《王之鸟》复刻 v2 — The King's Bird 风格(世界一:笼中蓝城)
-- 运动:水墨游戏同款(跑/跳/J 八向冲刺/贴墙跳),无滑翔
-- 拖尾:拉格朗日流体墨尾移植(骨架点+梯度噪声液缩+冲刺飞白拉丝),白色气流版
-- 镜头:固定缩放、无前瞻(防晕)
-- 操作:A/D 跑  SPACE 跳  J 冲刺(WASD 定向)  R 回存档点  ESC 退出
-- 启动: tools/run_kingsbird.ps1
-- ============================================================================

local vg = nil
local screenW, screenH = 1280, 720
local accumulator = 0
local FIXED_DT = 1 / 60
local elapsed = 0

-- ---------------- 调色(笼中蓝城) ----------------
local SKY_TOP = { 10, 18, 48 }
local SKY_MID = { 36, 76, 146 }
local SKY_LOW = { 112, 164, 218 }
local FORE = { 8, 16, 42 }
local MID1 = { 36, 70, 134 }
local MID1D = { 26, 52, 104 }     -- 中景暗部(拱窗)
local MID2 = { 58, 100, 168 }
local GOLD = { 255, 208, 120 }
local PALE = { 178, 210, 255 }
local CLOUD_W = { 235, 244, 255 }

-- ---------------- 玩家(水墨游戏同口径,y 向下) ----------------
local P = {
    x = 150, y = 1800, vx = 0, vy = 0, r = 10,
    grounded = false, wallDir = 0, facing = 1,
    accel = 1.6, fric = 0.86, grav = 0.52, jumpV = 15.5,
    dashSpeed = 19, dashTime = 0, dashDirX = 1, dashDirY = 0,
    isDashing = false, canDash = true, coyote = 0,
    jumpQueued = false, dashQueued = false,
}
local keys = { a = false, d = false, w = false, s = false, space = false }
local spawnX, spawnY = 150, 1800
local camX, camY = 150, 1740
local CAM_ZOOM = 0.95
local goalDone = false
local burstFx = {}

-- ---------------- 拉格朗日流体拖尾 ----------------
local tpts = {}            -- 骨架点 {x,y,dist,vel}
local accumDist = 0
local dashInterp = 0       -- 0 常态 / 1 冲刺形态
local droplets = {}        -- 剥离墨滴 {x,y,vx,vy,r,life,decay,streak}
local permN = {}

local function initNoise()
    math.randomseed(20260610)
    for i = 0, 255 do permN[i] = math.random(0, 255) end
    for i = 0, 255 do permN[i + 256] = permN[i] end
end

local function noise1(x)
    local Xf = math.floor(x)
    local X = Xf % 256
    local xf = x - Xf
    local u = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
    local g0 = permN[X] / 127.5 - 1.0
    local g1 = permN[X + 1] / 127.5 - 1.0
    return (g0 * xf + u * (g1 * (xf - 1) - g0 * xf)) * 2.0
end

-- ---------------- 关卡 ----------------
local function rectPoly(x, y, w, h)
    return { { x, y }, { x + w, y }, { x + w, y + h }, { x, y + h } }
end

local POLYS = {
    rectPoly(-120, 1900, 1020, 240),
    rectPoly(-200, 1300, 80, 840),
    rectPoly(980, 1980, 420, 240),
    rectPoly(1480, 2080, 360, 240),
    { { 1900, 2180 }, { 2600, 2420 }, { 2600, 2660 }, { 1900, 2420 } },
    rectPoly(2950, 2050, 260, 750),
    rectPoly(3650, 1700, 280, 1100),
    rectPoly(4500, 1850, 560, 120),
    rectPoly(4500, 600, 90, 1280),
    rectPoly(4970, 600, 90, 900),
    rectPoly(5200, 700, 300, 90),
    rectPoly(5700, 640, 280, 80),
    rectPoly(6150, 600, 300, 80),
    rectPoly(6500, 800, 700, 140),
    rectPoly(6760, 560, 56, 240),
    rectPoly(6964, 560, 56, 240),
}
local EDGE_STYLE = { "g", nil, "p", "p", "g", "p", "g", "p", nil, nil, "g", "g", "g", "g", "p", "p" }

local CHECKPOINTS = { { 150, 1840 }, { 3780, 1640 }, { 5350, 640 }, { 6890, 740 } }
local cpReached = { true, false, false, false }

local UPDRAFTS = {
    { 2680, 2260, 190, 0.42, -0.91 },
    { 3330, 1980, 180, 0.30, -0.95 },
}
local GOAL = { 6890, 700 }
local KILL_Y = 3000

-- ---------------- 工具 ----------------
local function rgba(r, g, b, a)
    return nvgRGBA(math.floor(r), math.floor(g), math.floor(b), math.floor(a or 255))
end
local function col(c, a) return rgba(c[1], c[2], c[3], a or 255) end
local function lerp(a, b, t) return a + (b - a) * t end
local function lerpC(c1, c2, t)
    return { lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t) }
end
local function clamp(v, a, b) return v < a and a or (v > b and b or v) end
local function hash01(n)
    local v = math.sin(n * 127.1 + 311.7) * 43758.5453
    return v - math.floor(v)
end

-- ---------------- 碰撞 ----------------
local function collideCircle(px, py, pr)
    local pushX, pushY = 0, 0
    local hitGround, hitWallDir, hitCeil = false, 0, false
    for _, poly in ipairs(POLYS) do
        local n = #poly
        for i = 1, n do
            local ax, ay = poly[i][1], poly[i][2]
            local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
            local ex, ey = bx - ax, by - ay
            local L2 = ex * ex + ey * ey
            if L2 > 1e-6 then
                local t = clamp(((px - ax) * ex + (py - ay) * ey) / L2, 0, 1)
                local cx, cy = ax + ex * t, ay + ey * t
                local dx, dy = px - cx, py - cy
                local d2 = dx * dx + dy * dy
                if d2 < pr * pr and d2 > 1e-9 then
                    local d = math.sqrt(d2)
                    local nx, ny = dx / d, dy / d
                    local push = pr - d
                    px = px + nx * push
                    py = py + ny * push
                    pushX = pushX + nx * push
                    pushY = pushY + ny * push
                    if ny < -0.55 then hitGround = true end
                    if ny > 0.55 then hitCeil = true end
                    if nx > 0.75 then hitWallDir = -1 end
                    if nx < -0.75 then hitWallDir = 1 end
                end
            end
        end
    end
    return px, py, pushX, pushY, hitGround, hitWallDir, hitCeil
end

-- ---------------- 拖尾骨架写入(拉格朗日) ----------------
local function trailAddPoint(tx, ty, vel)
    local tension = (dashInterp > 0.5) and 0.93 or 0.65
    local nx, ny = tx, ty
    if #tpts > 0 then
        local head = tpts[#tpts]
        nx = head.x + (tx - head.x) * tension
        ny = head.y + (ty - head.y) * tension
        local dx, dy = nx - head.x, ny - head.y
        accumDist = accumDist + math.sqrt(dx * dx + dy * dy)
    end
    tpts[#tpts + 1] = { x = nx, y = ny, dist = accumDist, vel = vel }
    local maxLen = (dashInterp > 0.5) and 92 or 58
    while #tpts > maxLen do table.remove(tpts, 1) end
end

local function spawnDroplet(x, y, parentVel, dashing)
    local ang = math.random() * math.pi * 2
    local eject = dashing and (1.5 + math.random() * 5.0) or (0.5 + math.random() * 1.5)
    droplets[#droplets + 1] = {
        x = x, y = y,
        vx = -P.vx * (dashing and 0.38 or 0.15) + math.cos(ang) * eject * 0.4,
        vy = math.sin(ang) * eject * 0.4 + (dashing and (-1.0 - math.random() * 2.0) or 0.4),
        r = dashing and (0.6 + math.random() * 1.8) or (2.0 + math.random() * 3.5),
        life = 1.0,
        decay = dashing and (0.022 + math.random() * 0.03) or (0.015 + math.random() * 0.015),
        streak = dashing,
    }
end

-- ---------------- 物理(水墨游戏口径) ----------------
local function respawn()
    P.x, P.y = spawnX, spawnY - 30
    P.vx, P.vy = 0, 0
    P.isDashing = false
    P.canDash = true
    tpts = {}
    droplets = {}
end

local function fixedStep()
    elapsed = elapsed + FIXED_DT
    local prevY = P.y

    -- 冲刺触发(J,八向)
    if P.dashQueued then
        if P.canDash and not P.isDashing then
            local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
            local dy = (keys.s and 1 or 0) - (keys.w and 1 or 0)
            if dx == 0 and dy == 0 then dx = P.facing end
            local d = math.sqrt(dx * dx + dy * dy)
            P.isDashing = true
            P.canDash = false
            P.dashTime = 12
            P.dashDirX, P.dashDirY = dx / d, dy / d
        end
        P.dashQueued = false
    end

    if P.isDashing then
        P.dashTime = P.dashTime - 1
        P.vx = P.dashDirX * P.dashSpeed
        P.vy = P.dashDirY * P.dashSpeed
        if P.dashTime <= 0 then
            P.isDashing = false
            P.vx = P.vx * 0.5
        end
    else
        if keys.a then P.vx = P.vx - P.accel; P.facing = -1 end
        if keys.d then P.vx = P.vx + P.accel; P.facing = 1 end
        P.vy = P.vy + P.grav
        P.vx = P.vx * P.fric
        -- 贴墙缓降
        if P.wallDir ~= 0 and not P.grounded and P.vy > 3.0
            and ((P.wallDir == -1 and keys.a) or (P.wallDir == 1 and keys.d)) then
            P.vy = 3.0
        end
    end

    -- 跳跃
    if P.jumpQueued then
        if P.grounded or P.coyote > 0 then
            P.vy = -P.jumpV
            P.grounded = false
            P.coyote = 0
        elseif P.wallDir ~= 0 then
            P.vx = -P.wallDir * 9.5
            P.vy = -13
            P.facing = -P.wallDir
            P.canDash = true
        end
        P.jumpQueued = false
    end

    -- 上升气旋(轻推,不依赖滑翔)
    for _, u in ipairs(UPDRAFTS) do
        local dx, dy = P.x - u[1], P.y - u[2]
        if dx * dx + dy * dy < u[3] * u[3] and not P.isDashing then
            P.vy = math.max(P.vy - 1.25, -9.5)
            P.vx = P.vx + u[4] * 0.3
        end
    end

    -- 位移 + 碰撞
    local steps = (math.abs(P.vx) + math.abs(P.vy) > 14) and 3 or 1
    local hitG, hitW = false, 0
    for _ = 1, steps do
        P.x = P.x + P.vx / steps
        P.y = P.y + P.vy / steps
        local nx, ny, pX, pY, g, w = collideCircle(P.x, P.y, P.r)
        P.x, P.y = nx, ny
        if g then hitG = true end
        if w ~= 0 then hitW = w end
        if pX ~= 0 or pY ~= 0 then
            local pl = math.sqrt(pX * pX + pY * pY)
            local nnx, nny = pX / pl, pY / pl
            local vn = P.vx * nnx + P.vy * nny
            if vn < 0 then
                P.vx = P.vx - nnx * vn
                P.vy = P.vy - nny * vn
            end
        end
    end
    P.grounded = hitG
    P.wallDir = hitW
    if P.grounded then
        P.coyote = 6
        P.canDash = true
    elseif P.coyote > 0 then
        P.coyote = P.coyote - 1
    end

    -- 存档点 / 终点
    for i, cp in ipairs(CHECKPOINTS) do
        if not cpReached[i] then
            local dx, dy = P.x - cp[1], P.y - cp[2]
            if dx * dx + dy * dy < 70 * 70 then
                cpReached[i] = true
                spawnX, spawnY = cp[1], cp[2]
                burstFx[#burstFx + 1] = { x = cp[1], y = cp[2] - 30, age = 0, kind = "cp" }
            end
        end
    end
    if not goalDone then
        local dx, dy = P.x - GOAL[1], P.y - GOAL[2]
        if dx * dx + dy * dy < 90 * 90 then
            goalDone = true
            burstFx[#burstFx + 1] = { x = GOAL[1], y = GOAL[2], age = 0, kind = "goal" }
        end
    end
    if P.y > KILL_Y then respawn() end

    -- 拖尾形态插值与骨架写入
    local spd = math.sqrt(P.vx * P.vx + P.vy * P.vy)
    local stretched = P.isDashing or spd > 13.5
    dashInterp = dashInterp + ((stretched and 1 or 0) - dashInterp) * 0.12
    trailAddPoint(P.x, P.y, spd)
    if #tpts == 0 or not stretched then
        -- 静止时尾部自然回缩
        if spd < 0.8 and #tpts > 0 then table.remove(tpts, 1) end
    end

    -- 墨滴更新
    for i = #droplets, 1, -1 do
        local d = droplets[i]
        d.x = d.x + d.vx
        d.y = d.y + d.vy
        d.vy = d.vy + 0.06
        d.vx = d.vx * 0.96
        d.life = d.life - d.decay
        if d.life <= 0 then table.remove(droplets, i) end
    end
    for _, b in ipairs(burstFx) do b.age = b.age + 1 end
    for i = #burstFx, 1, -1 do if burstFx[i].age > 70 then table.remove(burstFx, i) end end

    -- 镇定镜头:无前瞻、固定缩放
    camX = camX + (P.x - camX) * 0.07
    camY = camY + (P.y - 50 - camY) * 0.06
end

-- ---------------- 渲染:背景 ----------------
local function skyGradient(w, h)
    local bands = 64
    for i = 0, bands - 1 do
        local t = i / (bands - 1)
        local c
        if t < 0.55 then c = lerpC(SKY_TOP, SKY_MID, t / 0.55)
        else c = lerpC(SKY_MID, SKY_LOW, (t - 0.55) / 0.45) end
        nvgBeginPath(vg)
        nvgRect(vg, 0, h * i / bands - 1, w, h / bands + 2)
        nvgFillColor(vg, col(c))
        nvgFill(vg)
    end
end

local function drawGlow(x, y, r, c, a)
    for i = 6, 1, -1 do
        nvgBeginPath(vg)
        nvgCircle(vg, x, y, r * i / 6 * 1.8)
        nvgFillColor(vg, col(c, a / (i * 3.2)))
        nvgFill(vg)
    end
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, r * 0.5)
    nvgFillColor(vg, col(c, a))
    nvgFill(vg)
end

local function drawSwirlCloud(x, y, sc, alpha)
    nvgFillColor(vg, col(CLOUD_W, alpha))
    local puffs = { { 0, 0, 52 }, { 48, 10, 38 }, { -52, 12, 40 }, { 92, 22, 26 }, { -96, 24, 26 }, { 22, -26, 34 }, { -28, -22, 30 } }
    for _, p in ipairs(puffs) do
        nvgBeginPath(vg)
        nvgCircle(vg, x + p[1] * sc, y + p[2] * sc, p[3] * sc)
        nvgFill(vg)
    end
    nvgStrokeColor(vg, col(CLOUD_W, alpha * 0.9))
    nvgStrokeWidth(vg, 7 * sc)
    nvgBeginPath(vg)
    local cxx, cyy = x - 70 * sc, y + 6 * sc
    local rr = 30 * sc
    for k = 0, 22 do
        local a = k / 22 * math.pi * 1.9 + math.pi * 0.3
        local r2 = rr * (1 - k / 30)
        local px = cxx + math.cos(a) * r2
        local py = cyy + math.sin(a) * r2
        if k == 0 then nvgMoveTo(vg, px, py) else nvgLineTo(vg, px, py) end
    end
    nvgStroke(vg)
end

local function drawCage(px)
    local cx = 4200 - px * 0.10
    local baseY, topY = 1500, -160
    nvgStrokeColor(vg, col(MID2, 52))
    nvgStrokeWidth(vg, 6)
    for i = -5, 5 do
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx + i * 360, baseY)
        nvgBezierTo(vg, cx + i * 300, baseY - 900, cx + i * 90, topY + 300, cx, topY)
        nvgStroke(vg)
    end
    nvgStrokeWidth(vg, 4)
    for k = 1, 3 do
        local ry = topY + k * 420
        local rw = 360 * 5 * (k / 3.2)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - rw, ry + 120)
        nvgBezierTo(vg, cx - rw * 0.4, ry - 60, cx + rw * 0.4, ry - 60, cx + rw, ry + 120)
        nvgStroke(vg)
    end
    nvgFillColor(vg, col(MID2, 110))
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - 130, 2400)
    nvgLineTo(vg, cx - 70, 300)
    nvgLineTo(vg, cx - 22, 140)
    nvgLineTo(vg, cx, 60)
    nvgLineTo(vg, cx + 22, 140)
    nvgLineTo(vg, cx + 70, 300)
    nvgLineTo(vg, cx + 130, 2400)
    nvgClosePath(vg)
    nvgFill(vg)
end

-- 单体建筑绘制(对照原作:多檐宝塔/洋葱穹顶/拱廊桥/旗杆细塔)
local function drawBuilding(bx, byBase, kindSeed, cMain, cDark, scale)
    local kind = math.floor(hash01(kindSeed) * 4)
    local s = scale or 1
    nvgFillColor(vg, col(cMain))
    if kind == 0 then
        -- 洋葱穹顶塔
        local bw, bh = 200 * s, (700 + hash01(kindSeed + 1) * 400) * s
        nvgBeginPath(vg)
        nvgRect(vg, bx, byBase - bh, bw, bh)
        nvgFill(vg)
        nvgBeginPath(vg)
        nvgEllipse(vg, bx + bw / 2, byBase - bh, bw * 0.46, bw * 0.55)
        nvgFill(vg)
        nvgBeginPath(vg)
        nvgMoveTo(vg, bx + bw / 2 - 6 * s, byBase - bh - bw * 0.5)
        nvgLineTo(vg, bx + bw / 2, byBase - bh - bw * 0.5 - 80 * s)
        nvgLineTo(vg, bx + bw / 2 + 6 * s, byBase - bh - bw * 0.5)
        nvgClosePath(vg)
        nvgFill(vg)
        -- 拱窗
        nvgFillColor(vg, col(cDark))
        for wy = 1, 3 do
            local yy = byBase - bh * wy / 3.6
            nvgBeginPath(vg)
            nvgRect(vg, bx + bw / 2 - 18 * s, yy, 36 * s, 52 * s)
            nvgCircle(vg, bx + bw / 2, yy, 18 * s)
            nvgFill(vg)
        end
    elseif kind == 1 then
        -- 多檐宝塔(三层缩进 + 飞檐)
        local bw, bh = 260 * s, (260 + hash01(kindSeed + 2) * 80) * s
        local y0 = byBase
        for tier = 0, 2 do
            local tw = bw * (1 - tier * 0.24)
            local tx = bx + (bw - tw) / 2
            nvgBeginPath(vg)
            nvgRect(vg, tx, y0 - bh, tw, bh)
            nvgFill(vg)
            -- 飞檐(上挑)
            nvgBeginPath(vg)
            nvgMoveTo(vg, tx - 34 * s, y0 - bh)
            nvgBezierTo(vg, tx + tw * 0.25, y0 - bh - 56 * s, tx + tw * 0.75, y0 - bh - 56 * s, tx + tw + 34 * s, y0 - bh)
            nvgClosePath(vg)
            nvgFill(vg)
            y0 = y0 - bh - 30 * s
            bh = bh * 0.78
        end
        -- 顶刹
        nvgBeginPath(vg)
        nvgMoveTo(vg, bx + bw / 2 - 5 * s, y0)
        nvgLineTo(vg, bx + bw / 2, y0 - 70 * s)
        nvgLineTo(vg, bx + bw / 2 + 5 * s, y0)
        nvgClosePath(vg)
        nvgFill(vg)
    elseif kind == 2 then
        -- 细旗杆塔
        local bw, bh = 110 * s, (500 + hash01(kindSeed + 3) * 300) * s
        nvgBeginPath(vg)
        nvgRect(vg, bx, byBase - bh, bw, bh)
        nvgFill(vg)
        nvgStrokeColor(vg, col(cMain))
        nvgStrokeWidth(vg, 5 * s)
        nvgBeginPath(vg)
        nvgMoveTo(vg, bx + bw / 2, byBase - bh)
        nvgLineTo(vg, bx + bw / 2, byBase - bh - 110 * s)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgMoveTo(vg, bx + bw / 2, byBase - bh - 110 * s)
        nvgLineTo(vg, bx + bw / 2 + 46 * s, byBase - bh - 92 * s)
        nvgLineTo(vg, bx + bw / 2, byBase - bh - 74 * s)
        nvgClosePath(vg)
        nvgFill(vg)
    else
        -- 拱廊桥段
        local bw, bh = 420 * s, (260 + hash01(kindSeed + 4) * 120) * s
        nvgBeginPath(vg)
        nvgRect(vg, bx, byBase - bh, bw, bh)
        nvgFill(vg)
        nvgFillColor(vg, col(cDark))
        for k = 0, 2 do
            local ax = bx + bw * (0.18 + k * 0.32)
            nvgBeginPath(vg)
            nvgRect(vg, ax - 36 * s, byBase - bh * 0.62, 72 * s, bh * 0.62)
            nvgCircle(vg, ax, byBase - bh * 0.62, 36 * s)
            nvgFill(vg)
        end
    end
end

local function drawFarCity(px)
    local off = -px * 0.28
    for i = 0, 16 do
        local bx = i * 720 + hash01(i) * 300 + off
        drawBuilding(bx, 2680, i * 7.3, MID2, lerpC(MID2, SKY_MID, 0.5), 0.9 + hash01(i + 9) * 0.5)
    end
end

local function drawMidCity(px)
    local off = -px * 0.55
    for i = 0, 12 do
        local bx = i * 940 + hash01(i + 40) * 380 + off
        drawBuilding(bx, 2800, i * 13.7 + 3, MID1, MID1D, 1.1 + hash01(i + 50) * 0.6)
    end
end

local function drawWindStreaks(px, py)
    nvgStrokeColor(vg, col(CLOUD_W, 30))
    nvgStrokeWidth(vg, 3)
    for i = 0, 7 do
        local yy = 300 + i * 360 + math.sin(elapsed * 0.4 + i * 2.2) * 40 - py * 0.1
        local xx = (elapsed * 50 * (0.5 + i % 3 * 0.3) + i * 900) % 9000 - 1200 - px * 0.18
        nvgBeginPath(vg)
        nvgMoveTo(vg, xx, yy)
        nvgBezierTo(vg, xx + 160, yy - 26, xx + 320, yy + 22, xx + 520, yy - 8)
        nvgStroke(vg)
    end
end

-- ---------------- 渲染:前景地形 ----------------
local function drawTerrain()
    for pi, poly in ipairs(POLYS) do
        nvgBeginPath(vg)
        nvgMoveTo(vg, poly[1][1], poly[1][2])
        for i = 2, #poly do nvgLineTo(vg, poly[i][1], poly[i][2]) end
        nvgClosePath(vg)
        nvgFillColor(vg, col(FORE))
        nvgFill(vg)
        local st = EDGE_STYLE[pi]
        if st then
            local c = (st == "g") and GOLD or PALE
            nvgStrokeColor(vg, col(c, 200))
            nvgStrokeWidth(vg, 3.4)
            nvgBeginPath(vg)
            nvgMoveTo(vg, poly[1][1] + 3, poly[1][2] + 2)
            nvgLineTo(vg, poly[2][1] - 3, poly[2][2] + 2)
            nvgStroke(vg)
            -- 栏杆桩(贴原作桥面)
            if st == "g" then
                local x1, x2 = poly[1][1], poly[2][1]
                nvgStrokeWidth(vg, 2)
                nvgStrokeColor(vg, col(c, 130))
                local nposts = math.floor((x2 - x1) / 120)
                for k = 0, nposts do
                    local tx = x1 + (x2 - x1) * k / math.max(nposts, 1)
                    local ty = poly[1][2] + (poly[2][2] - poly[1][2]) * k / math.max(nposts, 1)
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, tx, ty)
                    nvgLineTo(vg, tx, ty - 16)
                    nvgStroke(vg)
                    nvgBeginPath(vg)
                    nvgCircle(vg, tx, ty - 19, 2.6)
                    nvgStroke(vg)
                end
            end
            -- 端头卷纹
            for _, ex in ipairs({ { poly[1][1] + 10, poly[1][2] }, { poly[2][1] - 10, poly[2][2] } }) do
                nvgBeginPath(vg)
                nvgArc(vg, ex[1], ex[2] + 12, 9, -math.pi / 2, math.pi * 0.7, NVG_CW)
                nvgStrokeWidth(vg, 2.2)
                nvgStroke(vg)
            end
            -- 板底垂穗
            if #poly == 4 then
                local bx1, bx2, by = poly[4][1], poly[3][1], poly[3][2]
                nvgStrokeColor(vg, col(c, 130))
                for k = 1, 3 do
                    local tx = bx1 + (bx2 - bx1) * k / 4
                    local tl = 20 + (k % 2) * 14
                    nvgStrokeWidth(vg, 2)
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, tx, by)
                    nvgLineTo(vg, tx, by + tl)
                    nvgStroke(vg)
                    nvgBeginPath(vg)
                    nvgCircle(vg, tx, by + tl + 5, 4)
                    nvgStroke(vg)
                end
            end
        end
    end
end

local function drawUpdrafts()
    for _, u in ipairs(UPDRAFTS) do
        for k = 0, 2 do
            local ph = elapsed * 1.4 + k * 2.1
            local yy = u[2] + u[3] * 0.7 - ((ph * 60) % (u[3] * 1.5))
            local alpha = 90 * (1 - ((ph * 60) % (u[3] * 1.5)) / (u[3] * 1.5))
            nvgStrokeColor(vg, col(CLOUD_W, alpha))
            nvgStrokeWidth(vg, 4)
            nvgBeginPath(vg)
            nvgMoveTo(vg, u[1] - 50, yy)
            nvgBezierTo(vg, u[1] - 16, yy - 26, u[1] + 16, yy + 14, u[1] + 50, yy - 18)
            nvgStroke(vg)
        end
    end
end

local function drawCheckpoints()
    for i, cp in ipairs(CHECKPOINTS) do
        local x, y = cp[1], cp[2]
        nvgStrokeColor(vg, col(FORE, 255))
        nvgStrokeWidth(vg, 6)
        nvgBeginPath(vg)
        nvgMoveTo(vg, x, y)
        nvgLineTo(vg, x, y - 64)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgMoveTo(vg, x, y - 64)
        nvgBezierTo(vg, x + 20, y - 70, x + 26, y - 56, x + 30, y - 46)
        nvgStrokeWidth(vg, 4)
        nvgStroke(vg)
        local lit = cpReached[i]
        drawGlow(x + 30, y - 40, lit and 16 or 9, lit and GOLD or PALE, lit and 220 or 90)
    end
end

local function drawGoalGate()
    local gx, gy = GOAL[1], GOAL[2]
    nvgStrokeColor(vg, col(GOLD, 170))
    nvgStrokeWidth(vg, 5)
    nvgBeginPath(vg)
    nvgArc(vg, gx, gy - 60, 86, math.pi, 0, NVG_CW)
    nvgStroke(vg)
    drawGlow(gx, gy - 30, 26 + math.sin(elapsed * 2.2) * 5, CLOUD_W, 160)
    nvgStrokeColor(vg, col(CLOUD_W, 230))
    nvgStrokeWidth(vg, 4.5)
    nvgBeginPath(vg)
    nvgCircle(vg, gx, gy - 30, 36)
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgMoveTo(vg, gx - 24, gy - 18)
    nvgBezierTo(vg, gx - 4, gy - 44, gx + 10, gy - 28, gx + 26, gy - 44)
    nvgStroke(vg)
end

-- ---------------- 渲染:拉格朗日流体拖尾(白色气流版) ----------------
local function drawFluidTrail()
    local n = #tpts
    if n < 5 then return end
    local tNow = elapsed * 1000
    local outerL, outerR, innerL, innerR = {}, {}, {}, {}
    local dashing = dashInterp > 0.5

    for i = 1, n do
        local curr = tpts[i]
        local prev = tpts[math.max(1, i - 1)]
        local nxt = tpts[math.min(n, i + 1)]
        local dx, dy = nxt.x - prev.x, nxt.y - prev.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1e-6 then dx, dy, len = 1, 0, 1 end
        local nx, ny = -dy / len, dx / len
        local t = (i - 1) / (n - 1)

        -- 速度响应波动:冲刺高频细颤,常态低频自然摆
        local freq = 0.012 + dashInterp * 0.024
        local noiseVal = noise1(curr.dist * freq - tNow * 0.008)
        local wiggleAmp = (9 - dashInterp * 5.5) * (1.0 - (t - 1.0) ^ 2)
        local cx = curr.x + nx * noiseVal * wiggleAmp
        local cy = curr.y + ny * noiseVal * wiggleAmp

        -- 液缩鼓包宽度
        local wn = noise1(curr.dist * 0.014 - tNow * 0.006 + 137.7)
        local normNoise = (wn + 1.0) * 0.5
        local necking = 2.4 + dashInterp * 1.1
        local liquidMod = 0.18 + 1.55 * normNoise ^ necking
        local stateBaseW = 20 * (1.0 - dashInterp * 0.42)
        local taper = (t ^ 0.45) * (1.05 - 0.15 * t)

        -- 冲刺飞白撕裂
        local shred = 1.0
        if dashing then
            local sn = noise1(curr.dist * 0.08 + tNow * 0.01 + 71.3)
            if sn > 0.35 then shred = math.max(0.1, 1.0 - (sn - 0.35) * 2.8) end
        end

        local outerHalfW = math.max(0.1, stateBaseW * 0.5 * taper * liquidMod * shred)
        -- 裂口处剥离墨滴
        if outerHalfW < 2.0 and i > 5 and i < n - 8 then
            local prob = dashing and 0.18 or 0.03
            if math.random() < prob then spawnDroplet(cx, cy, curr.vel, dashing) end
        end
        local innerHalfW = outerHalfW * (0.62 - dashInterp * 0.12)

        outerL[i] = { cx + nx * outerHalfW, cy + ny * outerHalfW }
        outerR[i] = { cx - nx * outerHalfW, cy - ny * outerHalfW }
        innerL[i] = { cx + nx * innerHalfW, cy + ny * innerHalfW }
        innerR[i] = { cx - nx * innerHalfW, cy - ny * innerHalfW }
    end

    local function fillStrip(L, R, color)
        nvgBeginPath(vg)
        nvgMoveTo(vg, L[1][1], L[1][2])
        for i = 2, n do nvgLineTo(vg, L[i][1], L[i][2]) end
        for i = n, 1, -1 do nvgLineTo(vg, R[i][1], R[i][2]) end
        nvgClosePath(vg)
        nvgFillColor(vg, color)
        nvgFill(vg)
    end
    -- 外缘透亮气流 / 内芯实白
    fillStrip(outerL, outerR, rgba(225, 240, 255, lerp(110, 70, dashInterp)))
    fillStrip(innerL, innerR, rgba(248, 252, 255, 235))
end

local function drawDroplets()
    for _, d in ipairs(droplets) do
        local r = d.r * math.max(0, d.life)
        if r > 0.1 then
            if d.streak then
                nvgStrokeColor(vg, rgba(235, 245, 255, d.life * 190))
                nvgStrokeWidth(vg, r * 1.3)
                nvgBeginPath(vg)
                nvgMoveTo(vg, d.x, d.y)
                nvgLineTo(vg, d.x - d.vx * 1.4, d.y - d.vy * 1.4)
                nvgStroke(vg)
            else
                nvgBeginPath(vg)
                nvgCircle(vg, d.x, d.y, r)
                nvgFillColor(vg, rgba(225, 240, 255, d.life * 110))
                nvgFill(vg)
                nvgBeginPath(vg)
                nvgCircle(vg, d.x, d.y, r * 0.6)
                nvgFillColor(vg, rgba(248, 252, 255, d.life * 200))
                nvgFill(vg)
            end
        end
    end
end

local function drawBursts()
    for _, b in ipairs(burstFx) do
        local t = b.age / 70
        local r = 20 + t * (b.kind == "goal" and 220 or 110)
        nvgStrokeColor(vg, col(b.kind == "goal" and GOLD or PALE, 220 * (1 - t)))
        nvgStrokeWidth(vg, 5 * (1 - t) + 1)
        nvgBeginPath(vg)
        nvgCircle(vg, b.x, b.y, r)
        nvgStroke(vg)
    end
end

local function drawPlayer()
    local spd = math.sqrt(P.vx * P.vx + P.vy * P.vy)
    nvgSave(vg)
    nvgTranslate(vg, P.x, P.y)
    nvgScale(vg, P.facing, 1)
    nvgFillColor(vg, col(FORE))
    nvgBeginPath(vg)
    nvgEllipse(vg, 0, -4, 5.5, 9)
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgCircle(vg, 2, -15, 5)
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgMoveTo(vg, 6, -15)
    nvgLineTo(vg, 11, -13)
    nvgLineTo(vg, 6, -11)
    nvgClosePath(vg)
    nvgFill(vg)
    local ph = elapsed * (6 + spd * 1.2)
    local l1 = math.sin(ph) * (P.grounded and clamp(spd, 0, 6) or 2)
    local l2 = math.sin(ph + math.pi) * (P.grounded and clamp(spd, 0, 6) or 2)
    nvgStrokeColor(vg, col(FORE))
    nvgStrokeWidth(vg, 3.4)
    nvgBeginPath(vg)
    nvgMoveTo(vg, 0, 3)
    nvgLineTo(vg, l1, 11)
    nvgMoveTo(vg, 0, 3)
    nvgLineTo(vg, l2, 11)
    nvgStroke(vg)
    nvgFillColor(vg, col(FORE, 230))
    nvgBeginPath(vg)
    nvgMoveTo(vg, -3, -12)
    nvgBezierTo(vg, -10 - P.vx * P.facing, -6, -9 - P.vx * P.facing, 4, -4, 6)
    nvgClosePath(vg)
    nvgFill(vg)
    nvgRestore(vg)
end

function HandleNanoVGRender(eventType, eventData)
    local physW = graphics:GetWidth()
    local physH = graphics:GetHeight()
    local dpr = graphics:GetDPR()
    screenW = physW / dpr
    screenH = physH / dpr

    nvgBeginFrame(vg, screenW, screenH, dpr)
    skyGradient(screenW, screenH)
    drawGlow(screenW * 0.72, screenH * 0.20, 60, CLOUD_W, 70)

    nvgSave(vg)
    nvgTranslate(vg, screenW / 2, screenH / 2)
    nvgScale(vg, CAM_ZOOM, CAM_ZOOM)
    nvgTranslate(vg, -camX, -camY)

    drawCage(camX)
    for i = 0, 7 do
        local cx = i * 1700 + (i % 3) * 420 - camX * 0.15
        drawSwirlCloud(cx, 250 + (i % 4) * 330, 0.9 + (i % 2) * 0.4, 80)
    end
    drawFarCity(camX)
    for i = 0, 13 do
        local cx = i * 620 + (i % 3) * 180 - camX * 0.32
        local cy = 2010 + (i % 3) * 120 + math.sin(elapsed * 0.20 + i) * 14
        drawSwirlCloud(cx, cy, 1.6 + (i % 3) * 0.4, 200)
    end
    drawMidCity(camX)
    for i = 0, 15 do
        local cx = i * 680 + (i % 2) * 260 - camX * 0.52
        local cy = 2420 + (i % 2) * 170 + math.sin(elapsed * 0.26 + i * 1.7) * 18
        drawSwirlCloud(cx, cy, 2.3 + (i % 3) * 0.5, 245)
    end
    drawWindStreaks(camX, camY)

    drawTerrain()
    drawUpdrafts()
    drawCheckpoints()
    drawGoalGate()
    drawFluidTrail()
    drawDroplets()
    drawBursts()
    drawPlayer()

    nvgRestore(vg)

    for i = 0, 3 do
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, screenW, 26 - i * 6)
        nvgRect(vg, 0, screenH - 26 + i * 6, screenW, 26 - i * 6)
        nvgFillColor(vg, rgba(4, 8, 22, 26))
        nvgFill(vg)
    end
    nvgEndFrame(vg)
end

-- ---------------- 事件 ----------------
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
    if key == KEY_SPACE then
        if not keys.space then P.jumpQueued = true end
        keys.space = true
    end
    if key == KEY_J then P.dashQueued = true end
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
    print("[kingsbird] === v2: ink-movement + Lagrangian fluid trail ===")
    initNoise()
    vg = nvgCreate(1)
    if vg == nil then
        print("[kingsbird] ERROR: NanoVG create failed")
        return
    end
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent(vg, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("KeyUp", "HandleKeyUp")
    print("[kingsbird] === ready: A/D run, SPACE jump, J dash, R respawn ===")
end

function Stop()
end
