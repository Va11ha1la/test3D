# -*- coding: utf-8 -*-
# 开花交互:红梅近身绽放+花瓣飘落;兰草摇曳;终点拉远运镜
p = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
s = open(p, encoding="utf-8").read()

# 1) 全局状态
s = s.replace("""local burstFx = {}
local goalDone, goalAge = false, 0""",
"""local burstFx = {}
local goalDone, goalAge = false, 0
local blooms = {}          -- 开花体 {lay,pi,cx,cy,by,t,trig,delay,kind}
local bloomMap = {}        -- [layer][pi] -> bloom
local petals = {}          -- 花瓣粒子""")

# 2) loadLevel 构建开花表
s = s.replace("""    cpReached = {}
    for i = 1, #LV.CPS do cpReached[i] = (i == 1) end
    print("[kingsbird] level " .. curLevel .. " " .. LV.name)""",
"""    cpReached = {}
    for i = 1, #LV.CPS do cpReached[i] = (i == 1) end
    blooms = {}
    bloomMap = {}
    petals = {}
    if LV.TRACE then
        for _, lay in ipairs(LV.TRACE.layers) do
            local c = lay.color
            local kind = nil
            if c[1] == 150 and c[2] == 45 then kind = "plum"
            elseif c[1] == 72 and c[2] == 115 then kind = "orchid"
            elseif c[1] == 158 and c[2] == 160 then kind = "flower" end
            if kind then
                bloomMap[lay] = {}
                for pi, bb in ipairs(lay.bb or {}) do
                    local b = { lay = lay, pi = pi,
                        cx = (bb[1] + bb[3]) * 0.5, cy = (bb[2] + bb[4]) * 0.5,
                        by = bb[4], t = 0, trig = false,
                        delay = math.floor(hash01(pi * 3.3 + c[1]) * 26), kind = kind }
                    blooms[#blooms + 1] = b
                    bloomMap[lay][pi] = b
                end
            end
        end
    end
    print("[kingsbird] level " .. curLevel .. " " .. LV.name .. " blooms=" .. #blooms)""")

# 3) fixedStep 更新开花与花瓣(挂在拖尾采样之前)
s = s.replace("""    if (P.dashVisualT or 0) > 0 then P.dashVisualT = P.dashVisualT - 1 end""",
"""    -- 开花交互
    for _, b in ipairs(blooms) do
        if not b.trig then
            local dx, dy = P.x - b.cx, P.y - b.cy
            if dx * dx + dy * dy < 380 * 380 then b.trig = true end
        elseif b.delay > 0 then
            b.delay = b.delay - 1
        elseif b.t < 1 then
            b.t = math.min(1, b.t + 0.045)
            if b.kind == "plum" and b.t > 0.12 and b.t < 0.18 then
                for _ = 1, 6 do
                    petals[#petals + 1] = { x = b.cx + (math.random() - 0.5) * 50,
                        y = b.cy + (math.random() - 0.5) * 36,
                        vx = (math.random() - 0.5) * 1.4, vy = -0.6 - math.random() * 0.8,
                        rot = math.random() * 6.28, vr = (math.random() - 0.5) * 0.12,
                        life = 110 + math.random(70), age = 0, ph = math.random() * 6.28 }
                end
            end
        elseif b.kind == "plum" and math.random() < 0.004 then
            petals[#petals + 1] = { x = b.cx + (math.random() - 0.5) * 60,
                y = b.cy, vx = 0.2, vy = 0.2, rot = math.random() * 6.28,
                vr = (math.random() - 0.5) * 0.1, life = 150, age = 0, ph = math.random() * 6.28 }
        end
    end
    for i = #petals, 1, -1 do
        local pt = petals[i]
        pt.age = pt.age + 1
        pt.x = pt.x + pt.vx + math.sin(pt.age * 0.08 + pt.ph) * 0.5
        pt.y = pt.y + pt.vy
        pt.vy = math.min(pt.vy + 0.022, 1.1)
        pt.rot = pt.rot + pt.vr
        if pt.age > pt.life then table.remove(petals, i) end
    end

    if (P.dashVisualT or 0) > 0 then P.dashVisualT = P.dashVisualT - 1 end""")

# 4) drawTraceLayers:开花层缩放绽放 + 兰草摇曳
s = s.replace("""        for pi, poly in ipairs(L.polys) do
            local bb = L.bb and L.bb[pi]
            if (not bb) or (bb[3] > vx1 and bb[1] < vx2 and bb[4] > vy1 and bb[2] < vy2) then
                nvgBeginPath(vg)
                nvgMoveTo(vg, poly[1], poly[2])
                for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
                nvgClosePath(vg)
                nvgFill(vg)
            end
        end
        nvgRestore(vg)""",
"""        local bm = bloomMap[L]
        for pi, poly in ipairs(L.polys) do
            local bb = L.bb and L.bb[pi]
            if (not bb) or (bb[3] > vx1 and bb[1] < vx2 and bb[4] > vy1 and bb[2] < vy2) then
                local b = bm and bm[pi]
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
                end
            end
        end
        nvgRestore(vg)""")

# 5) 花瓣渲染函数 + 调用
s = s.replace("""local function drawBursts()""",
"""local function drawPetals()
    for _, pt in ipairs(petals) do
        local a = 230 * (1 - pt.age / pt.life)
        nvgSave(vg)
        nvgTranslate(vg, pt.x, pt.y)
        nvgRotate(vg, pt.rot)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, 0, 4.6, 2.4)
        nvgFillColor(vg, rgba(176, 58, 74, a))
        nvgFill(vg)
        nvgRestore(vg)
    end
end

local function drawBursts()""")
s = s.replace("""    drawFluidTrail()
    drawDroplets()
    drawBursts()
    drawPlayer()""",
"""    drawFluidTrail()
    drawDroplets()
    drawPetals()
    drawBursts()
    drawPlayer()""")

# 6) 终点拉远运镜(描摹关)
s = s.replace("""    else
        goalAge = goalAge + 1
        if goalAge == 100 then loadLevel(curLevel % #LEVELS + 1) end
    end""",
"""    else
        goalAge = goalAge + 1
        local adv = LV.TRACE and 260 or 100
        if goalAge == adv then loadLevel(curLevel % #LEVELS + 1) end
    end""")
s = s.replace("""    nvgSave(vg)
    nvgTranslate(vg, screenW / 2, screenH / 2)
    local zoom = LV.ZOOM or CAM_ZOOM
    nvgScale(vg, zoom, zoom)""",
"""    nvgSave(vg)
    nvgTranslate(vg, screenW / 2, screenH / 2)
    local zoom = LV.ZOOM or CAM_ZOOM
    if goalDone and LV.TRACE then
        zoom = zoom * (1 - 0.35 * clamp(goalAge / 170, 0, 1))
    end
    nvgScale(vg, zoom, zoom)""")

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("bloom patched")
