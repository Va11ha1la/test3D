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
