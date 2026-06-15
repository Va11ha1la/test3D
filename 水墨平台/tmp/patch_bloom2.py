# -*- coding: utf-8 -*-
# 开花 2.0:主动触碰交互点 + 程序没骨梅花 + 墨晕软边 + 纸纹
p = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
s = open(p, encoding="utf-8").read()

# 1) 全局:blooms -> ipoints(交互点)
s = s.replace("""local blooms = {}          -- 开花体 {lay,pi,cx,cy,by,t,trig,delay,kind}
local bloomMap = {}        -- [layer][pi] -> bloom
local petals = {}          -- 花瓣粒子""",
"""local ipoints = {}         -- 交互点 {x,y,kind,trig,members}
local bloomMap = {}        -- [layer][pi] -> 兰草生长体(仅绿层)
local petals = {}          -- 花瓣粒子""")

# 2) loadLevel:聚类出交互点;红/黄描摹层隐藏(改程序花),绿层保留生长
old_build = s[s.index("    blooms = {}\n    bloomMap = {}"):s.index('    print("[kingsbird] level " .. curLevel .. " " .. LV.name .. " blooms=" .. #blooms)')]
new_build = """    ipoints = {}
    bloomMap = {}
    petals = {}
    if LV.TRACE then
        local plumPts, orchidPts = {}, {}
        for _, lay in ipairs(LV.TRACE.layers) do
            local c = lay.color
            if c[1] == 150 and c[2] == 45 then
                lay.hidden = true
                for pi, bb in ipairs(lay.bb or {}) do
                    plumPts[#plumPts + 1] = { x = (bb[1] + bb[3]) * 0.5, y = (bb[2] + bb[4]) * 0.5,
                        r = clamp(math.max(bb[3] - bb[1], bb[4] - bb[2]) * 0.5, 9, 22) }
                end
            elseif c[1] == 158 and c[2] == 160 then
                lay.hidden = true
            elseif c[1] == 72 and c[2] == 115 then
                bloomMap[lay] = {}
                for pi, bb in ipairs(lay.bb or {}) do
                    local g = { cx = (bb[1] + bb[3]) * 0.5, by = bb[4], t = 0, delay = 0 }
                    bloomMap[lay][pi] = g
                    orchidPts[#orchidPts + 1] = { x = g.cx, y = bb[4], g = g }
                end
            end
        end
        -- 贪心聚类 -> 交互点
        local function clusterize(pts, rad, kind)
            for _, pt in ipairs(pts) do
                local home = nil
                for _, ip in ipairs(ipoints) do
                    if ip.kind == kind and (ip.x - pt.x) ^ 2 + (ip.y - pt.y) ^ 2 < rad * rad then
                        home = ip
                        break
                    end
                end
                if not home then
                    home = { x = pt.x, y = pt.y, kind = kind, trig = false, members = {}, n = 0 }
                    ipoints[#ipoints + 1] = home
                end
                pt.t = 0
                pt.delay = 0
                home.members[#home.members + 1] = pt
                home.n = home.n + 1
                home.x = home.x + (pt.x - home.x) / home.n
                home.y = home.y + (pt.y - home.y) / home.n
            end
        end
        clusterize(plumPts, 220, "plum")
        clusterize(orchidPts, 170, "orchid")
    end
"""
s = s.replace(old_build, new_build)
s = s.replace('print("[kingsbird] level " .. curLevel .. " " .. LV.name .. " blooms=" .. #blooms)',
              'print("[kingsbird] level " .. curLevel .. " " .. LV.name .. " ipoints=" .. #ipoints)')

# 3) fixedStep:触碰触发 + 成员错峰绽放
old_fx = s[s.index("    -- 开花交互"):s.index("    if (P.dashVisualT or 0) > 0 then")]
new_fx = """    -- 交互点:主动触碰开花
    for _, ip in ipairs(ipoints) do
        if not ip.trig then
            local dx, dy = P.x - ip.x, P.y - ip.y
            if dx * dx + dy * dy < 58 * 58 then
                ip.trig = true
                burstFx[#burstFx + 1] = { x = ip.x, y = ip.y, age = 0, kind = "ink" }
                for mi, m in ipairs(ip.members) do
                    m.delay = (mi - 1) * 6 + math.floor(hash01(mi * 7.7) * 5)
                end
            end
        else
            for _, m in ipairs(ip.members) do
                if m.delay > 0 then
                    m.delay = m.delay - 1
                elseif m.t < 1 then
                    m.t = math.min(1, m.t + 0.055)
                    if ip.kind == "plum" and m.t > 0.12 and m.t < 0.18 then
                        for _ = 1, 4 do
                            petals[#petals + 1] = { x = m.x + (math.random() - 0.5) * 24,
                                y = m.y + (math.random() - 0.5) * 18,
                                vx = (math.random() - 0.5) * 1.2, vy = -0.5 - math.random() * 0.7,
                                rot = math.random() * 6.28, vr = (math.random() - 0.5) * 0.12,
                                life = 100 + math.random(60), age = 0, ph = math.random() * 6.28 }
                        end
                    end
                    if ip.kind == "orchid" and m.g then m.g.t = m.t end
                elseif ip.kind == "plum" and math.random() < 0.0025 then
                    petals[#petals + 1] = { x = m.x + (math.random() - 0.5) * 26,
                        y = m.y, vx = 0.2, vy = 0.2, rot = math.random() * 6.28,
                        vr = (math.random() - 0.5) * 0.1, life = 140, age = 0, ph = math.random() * 6.28 }
                end
            end
        end
    end
    for i = #petals, 1, -1 do
        local pt = petals[i]
        pt.age = pt.age + 1
        pt.x = pt.x + pt.vx + math.sin(pt.age * 0.08 + pt.ph) * 0.5
        pt.y = pt.y + pt.vy
        pt.vy = math.min(pt.vy + 0.022, 1.0)
        pt.rot = pt.rot + pt.vr
        if pt.age > pt.life then table.remove(petals, i) end
    end

"""
s = s.replace(old_fx, new_fx)

# 4) drawTraceLayers:隐藏层跳过 + 前景墨晕软边;绿层生长沿用 bloomMap(锚点底心)
s = s.replace("""    for _, L in ipairs(LV.TRACE.layers) do
        local tox = (camX - TR_REFX) * (1 - L.par)""",
"""    for _, L in ipairs(LV.TRACE.layers) do
        if L.hidden then goto next_layer end
        local tox = (camX - TR_REFX) * (1 - L.par)""")
s = s.replace("""                local b = bm and bm[pi]
                if b then
                    local t = b.t
                    if t > 0.01 then
                        local sc2 = (1 - (1 - t) ^ 3)
                        sc2 = sc2 * (1 + 0.3 * math.sin(t * 3.14159) * (1 - t * 0.5))
                        nvgSave(vg)
                        nvgTranslate(vg, b.cx, b.by)
                        if b.kind ~= "plum" then
                            nvgRotate(vg, math.sin(elapsed * 1.5 + b.cx * 0.013) * 0.06 * t)
                        end
                        nvgScale(vg, sc2, sc2)
                        nvgTranslate(vg, -b.cx, -b.by)
                        nvgBeginPath(vg)
                        nvgMoveTo(vg, poly[1], poly[2])
                        for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
                        nvgClosePath(vg)
                        nvgFill(vg)
                        nvgRestore(vg)
                    end
                else
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, poly[1], poly[2])
                    for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
                    nvgClosePath(vg)
                    nvgFill(vg)
                end""",
"""                local b = bm and bm[pi]
                if b then
                    local t = b.t
                    if t > 0.01 then
                        local sc2 = (1 - (1 - t) ^ 3)
                        sc2 = sc2 * (1 + 0.3 * math.sin(t * 3.14159) * (1 - t * 0.5))
                        nvgSave(vg)
                        nvgTranslate(vg, b.cx, b.by)
                        nvgRotate(vg, math.sin(elapsed * 1.5 + b.cx * 0.013) * 0.06 * t)
                        nvgScale(vg, sc2, sc2)
                        nvgTranslate(vg, -b.cx, -b.by)
                        nvgBeginPath(vg)
                        nvgMoveTo(vg, poly[1], poly[2])
                        for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
                        nvgClosePath(vg)
                        nvgFill(vg)
                        nvgRestore(vg)
                    end
                else
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, poly[1], poly[2])
                    for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
                    nvgClosePath(vg)
                    if L.par >= 0.99 then
                        nvgStrokeColor(vg, rgba(L.color[1], L.color[2], L.color[3], 42))
                        nvgStrokeWidth(vg, 9)
                        nvgStroke(vg)
                    end
                    nvgFill(vg)
                end""")
s = s.replace("""        nvgRestore(vg)
    end
end

-- ============================================================================
-- 渲染:前景地形 + 边缘样式""",
"""        nvgRestore(vg)
        ::next_layer::
    end
end

-- ============================================================================
-- 渲染:前景地形 + 边缘样式""")

# 5) 程序没骨梅花 + 花苞/呼吸墨圈 + 纸纹
s = s.replace("""local function drawPetals()""",
"""-- 没骨梅花:5 圆瓣 + 深红心 + 黄蕊
local function drawPlumFlower(x, y, r, t, seed)
    local sc2 = (1 - (1 - t) ^ 3)
    sc2 = sc2 * (1 + 0.35 * math.sin(t * 3.14159) * (1 - t * 0.6))
    local rr = r * sc2
    if rr < 0.5 then return end
    local jit = hash01(seed) * 6.28
    for k = 0, 4 do
        local a = jit + k * 1.2566 + math.sin(seed * 3 + k) * 0.12
        local px = x + math.cos(a) * rr * 0.52
        local py = y + math.sin(a) * rr * 0.52
        nvgBeginPath(vg)
        nvgCircle(vg, px, py, rr * 0.46 * (0.92 + hash01(seed + k) * 0.16))
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
            nvgCircle(vg, x + math.cos(a) * rr * 0.2, y + math.sin(a) * rr * 0.2, rr * 0.07 + 0.6)
            nvgFillColor(vg, rgba(252, 228, 150, 230 * fa))
            nvgFill(vg)
        end
    end
end

local function drawFlowers()
    for _, ip in ipairs(ipoints) do
        if not ip.trig then
            -- 花苞 + 呼吸墨圈(可交互提示)
            local ph = elapsed * 2.2 + ip.x * 0.01
            nvgStrokeColor(vg, rgba(70, 66, 62, 56 + 26 * math.sin(ph)))
            nvgStrokeWidth(vg, 2.2)
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x, ip.y, 24 + math.sin(ph) * 4)
            nvgStroke(vg)
            for _, m in ipairs(ip.members) do
                nvgBeginPath(vg)
                nvgCircle(vg, m.x, m.y, ip.kind == "plum" and 3.6 or 3.0)
                nvgFillColor(vg, ip.kind == "plum" and rgba(132, 22, 44, 235) or rgba(60, 88, 56, 235))
                nvgFill(vg)
            end
        else
            for mi, m in ipairs(ip.members) do
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
            end
        end
    end
end

-- 纸纹与晕染(屏幕空间)
local function drawPaperGrain(w, h)
    nvgStrokeWidth(vg, 1)
    for i = 1, 64 do
        local fx = hash01(i * 3.1) * w
        local fy = hash01(i * 7.7) * h
        local fl = 6 + hash01(i * 1.3) * 22
        local fa = hash01(i * 9.1) * 3.14
        nvgStrokeColor(vg, rgba(120, 112, 96, 7 + hash01(i) * 8))
        nvgBeginPath(vg)
        nvgMoveTo(vg, fx, fy)
        nvgLineTo(vg, fx + math.cos(fa) * fl, fy + math.sin(fa) * fl)
        nvgStroke(vg)
    end
end

local function drawPetals()""")
s = s.replace("""    drawFluidTrail()
    drawDroplets()
    drawPetals()
    drawBursts()
    drawPlayer()""",
"""    drawFlowers()
    drawFluidTrail()
    drawDroplets()
    drawPetals()
    drawBursts()
    drawPlayer()""")
s = s.replace("""    nvgRestore(vg)

    for i = 0, 3 do
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, screenW, 26 - i * 6)
        nvgRect(vg, 0, screenH - 26 + i * 6, screenW, 26 - i * 6)""",
"""    nvgRestore(vg)

    if LV.TRACE then drawPaperGrain(screenW, screenH) end

    for i = 0, 3 do
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, screenW, 26 - i * 6)
        nvgRect(vg, 0, screenH - 26 + i * 6, screenW, 26 - i * 6)""")

# 6) 触发墨花 burst("ink" 种类) + 花瓣色
s = s.replace("""local function drawBursts()
    for _, b in ipairs(burstFx) do
        local t = b.age / 70
        local r = 20 + t * (b.kind == "goal" and 220 or 110)""",
"""local function drawBursts()
    for _, b in ipairs(burstFx) do
        local t = b.age / 70
        if b.kind == "ink" then
            local rr = 14 + t * 60
            nvgStrokeColor(vg, rgba(60, 56, 52, 200 * (1 - t)))
            nvgStrokeWidth(vg, 3.5 * (1 - t) + 0.6)
            nvgBeginPath(vg)
            nvgCircle(vg, b.x, b.y, rr)
            nvgStroke(vg)
            goto next_burst
        end
        local r = 20 + t * (b.kind == "goal" and 220 or 110)""")
s = s.replace("""        nvgBeginPath(vg)
        nvgCircle(vg, b.x, b.y, r)
        nvgStroke(vg)
    end
end

local function drawPlayer()""",
"""        nvgBeginPath(vg)
        nvgCircle(vg, b.x, b.y, r)
        nvgStroke(vg)
        ::next_burst::
    end
end

local function drawPlayer()""")
s = s.replace("        nvgFillColor(vg, rgba(176, 58, 74, a))", "        nvgFillColor(vg, rgba(198, 46, 66, a))")

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("bloom2 patched")
