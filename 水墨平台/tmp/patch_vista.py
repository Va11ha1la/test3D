# -*- coding: utf-8 -*-
# 终幕全卷铺开 + 左段补交互点 + 宣纸化调色 + 程序兰草
p = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
s = open(p, encoding="utf-8").read()

# ---------- A. 宣纸调色表 + 应用 ----------
s = s.replace("local curLevel = 1", """-- 宣纸色阶重映射(原帧色 -> 暖纸白水墨)
local XUAN_GRADE = {
    ["216,213,207"] = { 243, 239, 229 },
    ["197,194,190"] = { 229, 225, 214 },
    ["181,179,174"] = { 212, 208, 197 },
    ["157,153,150"] = { 188, 184, 175 },
    ["138,138,134"] = { 162, 160, 151 },
    ["113,112,110"] = { 131, 129, 122 },
    ["78,84,79"] = { 86, 95, 82 },
    ["55,55,53"] = { 46, 44, 41 },
    ["33,33,32"] = { 25, 23, 21 },
}
if LEVELS[1] then LEVELS[1].PAPER = "xuan" end

local curLevel = 1""", 1)

s = s.replace("""    blooms = {}""", """    -- 宣纸化调色(按原色精确匹配,一次性)
    if LV.TRACE and LV.PAPER == "xuan" and not LV.graded then
        LV.graded = true
        local key = string.format("%d,%d,%d", LV.TRACE.base[1], LV.TRACE.base[2], LV.TRACE.base[3])
        if XUAN_GRADE[key] then LV.TRACE.base = XUAN_GRADE[key] end
        for _, lay in ipairs(LV.TRACE.layers) do
            local k2 = string.format("%d,%d,%d", lay.color[1], lay.color[2], lay.color[3])
            if XUAN_GRADE[k2] then lay.color = XUAN_GRADE[k2] end
        end
    end
    blooms = {}""") if "    blooms = {}" in s else s
# (上一步如果占位不存在就改 ipoints 行)
if "宣纸化调色" not in s:
    s = s.replace("""    ipoints = {}
    bloomMap = {}
    petals = {}""", """    if LV.TRACE and LV.PAPER == "xuan" and not LV.graded then
        LV.graded = true
        local key = string.format("%d,%d,%d", LV.TRACE.base[1], LV.TRACE.base[2], LV.TRACE.base[3])
        if XUAN_GRADE[key] then LV.TRACE.base = XUAN_GRADE[key] end
        for _, lay in ipairs(LV.TRACE.layers) do
            local k2 = string.format("%d,%d,%d", lay.color[1], lay.color[2], lay.color[3])
            if XUAN_GRADE[k2] then lay.color = XUAN_GRADE[k2] end
        end
    end
    ipoints = {}
    bloomMap = {}
    petals = {}""")

# ---------- B. 左段自动补交互点 ----------
s = s.replace("""        clusterize(plumPts, 220, "plum")
        clusterize(orchidPts, 170, "orchid")
    end""",
"""        clusterize(plumPts, 220, "plum")
        clusterize(orchidPts, 170, "orchid")
        -- 沿前景顶面自动补充交互点(避开已有点,间距 >=420)
        local cands = {}
        for _, poly in ipairs(LV.POLYS) do
            local n = #poly
            for i = 1, n do
                local ax, ay = poly[i][1], poly[i][2]
                local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
                if math.abs(by - ay) < 12 and math.abs(bx - ax) > 70 then
                    local mx, my = (ax + bx) / 2, (ay + by) / 2
                    if insidePoly(poly, mx, my + 8) then
                        cands[#cands + 1] = { x = mx, y = my }
                    end
                end
            end
        end
        table.sort(cands, function(a, b) return a.x < b.x end)
        local lastX = -1e9
        for ci, cd in ipairs(cands) do
            if cd.x - lastX > 420 then
                local clash = false
                for _, ip in ipairs(ipoints) do
                    if (ip.x - cd.x) ^ 2 + (ip.y - cd.y) ^ 2 < 300 * 300 then
                        clash = true
                        break
                    end
                end
                if not clash then
                    lastX = cd.x
                    local kind = (hash01(ci * 5.3) > 0.45) and "plum" or "sprout"
                    local ip = { x = cd.x, y = cd.y - 14, kind = kind, trig = false, members = {} }
                    if kind == "plum" then
                        for k = 1, 4 + math.floor(hash01(ci) * 3) do
                            ip.members[#ip.members + 1] = { x = cd.x + (hash01(ci * 7 + k) - 0.5) * 110,
                                y = cd.y - 8 - hash01(ci * 11 + k) * 34,
                                r = 9 + hash01(ci * 13 + k) * 6, t = 0, delay = 0 }
                        end
                    else
                        ip.members[#ip.members + 1] = { x = cd.x, y = cd.y, r = 1, t = 0, delay = 0 }
                    end
                    ipoints[#ipoints + 1] = ip
                end
            end
        end
    end""")

# ---------- C. 终幕:锁操作 + 镜头铺开全卷 ----------
s = s.replace("""        if keys.a then P.vx = P.vx - P.accel; P.facing = -1 end
        if keys.d then P.vx = P.vx + P.accel; P.facing = 1 end
        P.vy = P.vy + P.grav""",
"""        if not (goalDone and LV.TRACE) then
            if keys.a then P.vx = P.vx - P.accel; P.facing = -1 end
            if keys.d then P.vx = P.vx + P.accel; P.facing = 1 end
        end
        P.vy = P.vy + P.grav""")
s = s.replace("""    if P.dashQueued then
        if P.canDash and not P.isDashing then""",
"""    if goalDone and LV.TRACE then
        P.dashQueued = false
        P.jumpQueued = false
    end
    if P.dashQueued then
        if P.canDash and not P.isDashing then""")
s = s.replace("""    camX = camX + (P.x - camX) * 0.07
    camY = camY + (P.y - 50 - camY) * 0.06
    if LV.TRACE then""",
"""    if goalDone and LV.TRACE then
        -- 终幕:镜头移向画卷中心
        local ccx = (LV.TRACE.spanx[1] + LV.TRACE.spanx[2] + (LV.FRW or 1680)) / 2
        local ccy = (LV.TRACE.spany[1] + LV.TRACE.spany[2] + (LV.FRH or 910)) / 2
        camX = camX + (ccx - camX) * 0.045
        camY = camY + (ccy - camY) * 0.045
        goto cam_done
    end
    camX = camX + (P.x - camX) * 0.07
    camY = camY + (P.y - 50 - camY) * 0.06
    if LV.TRACE then""")
s = s.replace("""        if sy2 - sy1 <= halfH * 2 then
            camY = (sy1 + sy2) / 2
        else
            camY = clamp(camY, sy1 + halfH, sy2 - halfH)
        end
    end
end""",
"""        if sy2 - sy1 <= halfH * 2 then
            camY = (sy1 + sy2) / 2
        else
            camY = clamp(camY, sy1 + halfH, sy2 - halfH)
        end
    end
    ::cam_done::
end""")
# 缩放:渐变到整卷入画
s = s.replace("""    local zoom = LV.ZOOM or CAM_ZOOM
    if goalDone and LV.TRACE then
        zoom = zoom * (1 - 0.35 * clamp(goalAge / 170, 0, 1))
    end
    nvgScale(vg, zoom, zoom)""",
"""    local zoom = LV.ZOOM or CAM_ZOOM
    if goalDone and LV.TRACE then
        local w = (LV.TRACE.spanx[2] - LV.TRACE.spanx[1]) + (LV.FRW or 1680)
        local h = (LV.TRACE.spany[2] - LV.TRACE.spany[1]) + (LV.FRH or 910)
        local fit = math.min(screenW / w, screenH / h) * 0.94
        local tt = clamp(goalAge / 170, 0, 1)
        tt = 1 - (1 - tt) ^ 3
        zoom = zoom + (fit - zoom) * tt
    end
    nvgScale(vg, zoom, zoom)""")
# 裁剪用 zoom 同步(防止终幕缩放后两侧被剔除)
s = s.replace("""local function drawTraceLayers()
    local TR_REFX, TR_REFY = LV.REFX or 840, LV.REFY or 455
    local zoom = LV.ZOOM or CAM_ZOOM""",
"""local function drawTraceLayers()
    local TR_REFX, TR_REFY = LV.REFX or 840, LV.REFY or 455
    local zoom = LV.ZOOM or CAM_ZOOM
    if goalDone then zoom = zoom * 0.2 end -- 终幕放宽裁剪""")
# 终幕时长
s = s.replace("        local adv = LV.TRACE and 260 or 100", "        local adv = LV.TRACE and 430 or 100")

# ---------- D. 程序兰草 + sprout 渲染 ----------
s = s.replace("""local function drawFlowers()""",
"""-- 程序兰草:扇形叶片随生长展开
local function drawOrchidSprout(x, y, t, seed)
    local sc2 = 1 - (1 - t) ^ 3
    if sc2 < 0.03 then return end
    for k = 0, 8 do
        local a = -1.5708 + (k / 8 - 0.5) * 2.5 + math.sin(elapsed * 1.6 + seed + k * 1.7) * 0.05 * t
        local ln = (26 + hash01(seed + k * 3) * 36) * sc2
        local ex = x + math.cos(a) * ln
        local ey = y + math.sin(a) * ln
        nvgStrokeColor(vg, rgba(64, 94, 60, 235))
        nvgStrokeWidth(vg, 3.4 - (k % 3) * 0.8)
        nvgBeginPath(vg)
        nvgMoveTo(vg, x, y)
        nvgBezierTo(vg, x + math.cos(a) * ln * 0.4, y + math.sin(a) * ln * 0.5 - 5,
            ex - math.cos(a) * ln * 0.08, ey + 3, ex, ey)
        nvgStroke(vg)
    end
    if t > 0.8 then
        local fa = (t - 0.8) / 0.2
        nvgBeginPath(vg)
        nvgCircle(vg, x + 4, y - 34 * sc2, 3.0)
        nvgFillColor(vg, rgba(240, 226, 152, 235 * fa))
        nvgFill(vg)
        nvgBeginPath(vg)
        nvgCircle(vg, x - 6, y - 27 * sc2, 2.2)
        nvgFillColor(vg, rgba(244, 238, 200, 220 * fa))
        nvgFill(vg)
    end
end

local function drawFlowers()""")
s = s.replace("""            for mi, m in ipairs(ip.members) do
                if ip.kind == "plum" then
                    if m.t > 0 then
                        drawPlumFlower(m.x, m.y, m.r, m.t, mi * 13.7 + ip.x)
                    else
                        nvgBeginPath(vg)
                        nvgCircle(vg, m.x, m.y, 3.6)
                        nvgFillColor(vg, rgba(132, 22, 44, 235))
                        nvgFill(vg)
                    end
                end
            end""",
"""            for mi, m in ipairs(ip.members) do
                if ip.kind == "plum" then
                    if m.t > 0 then
                        drawPlumFlower(m.x, m.y, m.r, m.t, mi * 13.7 + ip.x)
                    else
                        nvgBeginPath(vg)
                        nvgCircle(vg, m.x, m.y, 3.6)
                        nvgFillColor(vg, rgba(132, 22, 44, 235))
                        nvgFill(vg)
                    end
                elseif ip.kind == "sprout" then
                    drawOrchidSprout(m.x, m.y, m.t, ip.x * 0.013)
                end
            end""")

# ---------- E. 纸面水渍晕 + 纤维加密 ----------
s = s.replace("""local function drawPaperGrain(w, h)
    nvgStrokeWidth(vg, 1)
    for i = 1, 64 do""",
"""local function drawPaperGrain(w, h)
    -- 水渍淡晕(固定位置,极淡)
    if LV.PAPER == "xuan" then
        for i = 1, 7 do
            local bx = hash01(i * 11.3) * w
            local by = hash01(i * 17.9) * h
            local br = 90 + hash01(i * 5.1) * 240
            local warm = (i % 2 == 0)
            for ring = 3, 1, -1 do
                nvgBeginPath(vg)
                nvgCircle(vg, bx, by, br * ring / 3)
                nvgFillColor(vg, warm and rgba(196, 178, 142, 4) or rgba(150, 158, 162, 3))
                nvgFill(vg)
            end
        end
        -- 纸屑斑点
        for i = 1, 36 do
            nvgBeginPath(vg)
            nvgCircle(vg, hash01(i * 23.7) * w, hash01(i * 31.1) * h, 0.8 + hash01(i * 3.3) * 1.6)
            nvgFillColor(vg, rgba(130, 118, 96, 10 + hash01(i * 7.7) * 10))
            nvgFill(vg)
        end
    end
    nvgStrokeWidth(vg, 1)
    for i = 1, (LV.PAPER == "xuan" and 112 or 64) do""")

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("vista patched")
