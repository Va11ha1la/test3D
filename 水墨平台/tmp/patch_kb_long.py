# -*- coding: utf-8 -*-
# 长关运行时:渲染包围盒裁剪 + 碰撞包围盒剔除 + 相机限位按拼接范围 + 掉落诊断
p = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
s = open(p, encoding="utf-8").read()

# 1) drawTraceLayers 加包围盒裁剪
s = s.replace("""local TR_REFX, TR_REFY = 840, 455
local function drawTraceLayers()
    for _, L in ipairs(LV.TRACE.layers) do
        nvgSave(vg)
        nvgTranslate(vg, (camX - TR_REFX) * (1 - L.par), (camY - TR_REFY) * (1 - L.par) * 0.5)
        nvgFillColor(vg, rgba(L.color[1], L.color[2], L.color[3], 255))
        for _, poly in ipairs(L.polys) do
            nvgBeginPath(vg)
            nvgMoveTo(vg, poly[1], poly[2])
            for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
            nvgClosePath(vg)
            nvgFill(vg)
        end
        nvgRestore(vg)
    end
end""",
"""local TR_REFX, TR_REFY = 840, 455
local function drawTraceLayers()
    local zoom = LV.ZOOM or CAM_ZOOM
    local halfW = (screenW / 2) / zoom + 60
    local halfH = (screenH / 2) / zoom + 60
    for _, L in ipairs(LV.TRACE.layers) do
        local tox = (camX - TR_REFX) * (1 - L.par)
        local toy = (camY - TR_REFY) * (1 - L.par) * 0.5
        nvgSave(vg)
        nvgTranslate(vg, tox, toy)
        nvgFillColor(vg, rgba(L.color[1], L.color[2], L.color[3], 255))
        local vx1, vx2 = camX - halfW - tox, camX + halfW - tox
        local vy1, vy2 = camY - halfH - toy, camY + halfH - toy
        for pi, poly in ipairs(L.polys) do
            local bb = L.bb and L.bb[pi]
            if (not bb) or (bb[3] > vx1 and bb[1] < vx2 and bb[4] > vy1 and bb[2] < vy2) then
                nvgBeginPath(vg)
                nvgMoveTo(vg, poly[1], poly[2])
                for k = 3, #poly - 1, 2 do nvgLineTo(vg, poly[k], poly[k + 1]) end
                nvgClosePath(vg)
                nvgFill(vg)
            end
        end
        nvgRestore(vg)
    end
end""")

# 2) collideCircle 加包围盒剔除
s = s.replace("""    for _, poly in ipairs(LV.POLYS) do
        local n = #poly
        for i = 1, n do""",
"""    for _, poly in ipairs(LV.POLYS) do
        local bb = poly.bb
        if bb and (px + pr < bb[1] or px - pr > bb[3] or py + pr < bb[2] or py - pr > bb[4]) then
            goto next_poly
        end
        local n = #poly
        for i = 1, n do""")
s = s.replace("""                    if nx > 0.75 then hitWallDir = -1 end
                    if nx < -0.75 then hitWallDir = 1 end
                end
            end
        end
    end
    return px, py, pushX, pushY, hitGround, hitWallDir
end""",
"""                    if nx > 0.75 then hitWallDir = -1 end
                    if nx < -0.75 then hitWallDir = 1 end
                end
            end
        end
        ::next_poly::
    end
    return px, py, pushX, pushY, hitGround, hitWallDir
end""")

# 3) 相机限位:用拼接范围替换单帧限位
s = s.replace("""    if LV.TRACE then
        local halfW = (screenW / 2) / (LV.ZOOM or CAM_ZOOM)
        local halfH = (screenH / 2) / (LV.ZOOM or CAM_ZOOM)
        camX = clamp(camX, math.min(halfW, 840), math.max(1680 - halfW, 840))
        if halfH >= 455 then camY = 455 else camY = clamp(camY, halfH, 910 - halfH) end
    end""",
"""    if LV.TRACE then
        local halfW = (screenW / 2) / (LV.ZOOM or CAM_ZOOM)
        local halfH = (screenH / 2) / (LV.ZOOM or CAM_ZOOM)
        local sx1 = LV.TRACE.spanx[1] + halfW * 0.0
        local sx2 = LV.TRACE.spanx[2] + 1680
        camX = clamp(camX, math.min(sx1 + halfW, 840), math.max(sx2 - halfW, 840))
        local sy1 = LV.TRACE.spany[1]
        local sy2 = LV.TRACE.spany[2] + 910
        if sy2 - sy1 <= halfH * 2 then
            camY = (sy1 + sy2) / 2
        else
            camY = clamp(camY, sy1 + halfH, sy2 - halfH)
        end
    end""")

# 4) 掉落诊断
s = s.replace("""local function respawn()
    P.x, P.y = spawnX, spawnY - 30
    P.vx, P.vy = 0, 0
    P.isDashing = false
    P.canDash = true
    tpts = {}
    droplets = {}
end""",
"""local function respawn()
    print(string.format("[kb] respawn at lv%d (was %.0f,%.0f)", curLevel, P.x, P.y))
    P.x, P.y = spawnX, spawnY - 30
    P.vx, P.vy = 0, 0
    P.isDashing = false
    P.canDash = true
    tpts = {}
    droplets = {}
end""")

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("long-level runtime patched")
