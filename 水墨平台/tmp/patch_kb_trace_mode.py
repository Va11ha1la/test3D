# -*- coding: utf-8 -*-
p = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
s = open(p, encoding="utf-8").read()

# 1) skyGradient: 描摹关用帧底色平涂
s = s.replace("""local function skyGradient(w, h)
    local PAL = LV.PAL
    local bands = 64""",
"""local function skyGradient(w, h)
    local PAL = LV.PAL
    if LV.TRACE then
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, w, h)
        nvgFillColor(vg, rgba(LV.TRACE.base[1], LV.TRACE.base[2], LV.TRACE.base[3], 255))
        nvgFill(vg)
        return
    end
    local bands = 64""")

# 2) 描摹层渲染函数(插在 drawTerrain 前)
s = s.replace("-- ============================================================================\n-- 渲染:前景地形 + 边缘样式",
"""-- 描摹层渲染(1:1):各层按视差对齐参考相机位
local TR_REFX, TR_REFY = 840, 455
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
end

-- ============================================================================
-- 渲染:前景地形 + 边缘样式""")

# 3) 渲染主流程:描摹关走描摹层,镜头缩放按关
s = s.replace("""    nvgSave(vg)
    nvgTranslate(vg, screenW / 2, screenH / 2)
    nvgScale(vg, CAM_ZOOM, CAM_ZOOM)
    nvgTranslate(vg, -camX, -camY)

    BG_FN[curLevel](camX, camY)
    drawSquaresPass()
    drawTerrain()
    drawDecor()""",
"""    nvgSave(vg)
    nvgTranslate(vg, screenW / 2, screenH / 2)
    local zoom = LV.ZOOM or CAM_ZOOM
    nvgScale(vg, zoom, zoom)
    nvgTranslate(vg, -camX, -camY)

    if LV.TRACE then
        drawTraceLayers()
    else
        BG_FN[curLevel](camX, camY)
        drawSquaresPass()
        drawTerrain()
        drawDecor()
    end""")

# 4) 玩家颜色按关覆盖
s = s.replace("""local function drawPlayer()
    local spd = math.sqrt(P.vx * P.vx + P.vy * P.vy)
    nvgSave(vg)
    nvgTranslate(vg, P.x, P.y)
    nvgScale(vg, P.facing, 1)
    nvgFillColor(vg, col(LV.PAL.fore))""",
"""local function drawPlayer()
    local pc = LV.PAL.player or LV.PAL.fore
    local spd = math.sqrt(P.vx * P.vx + P.vy * P.vy)
    nvgSave(vg)
    nvgTranslate(vg, P.x, P.y)
    nvgScale(vg, P.facing, 1)
    nvgFillColor(vg, col(pc))""")
s = s.replace("    nvgStrokeColor(vg, col(LV.PAL.fore))\n    nvgStrokeWidth(vg, 3.4)", "    nvgStrokeColor(vg, col(pc))\n    nvgStrokeWidth(vg, 3.4)")
s = s.replace("    nvgFillColor(vg, col(LV.PAL.fore, 230))\n    nvgBeginPath(vg)\n    nvgMoveTo(vg, -3, -12)", "    nvgFillColor(vg, col(pc, 230))\n    nvgBeginPath(vg)\n    nvgMoveTo(vg, -3, -12)")

# 5) 存档点/终点标记在描摹关里用深色保证可读(沿用即可),相机镜头限制在帧内
s = s.replace("""    camX = camX + (P.x - camX) * 0.07
    camY = camY + (P.y - 50 - camY) * 0.06""",
"""    camX = camX + (P.x - camX) * 0.07
    camY = camY + (P.y - 50 - camY) * 0.06
    if LV.TRACE then
        local halfW = (screenW / 2) / (LV.ZOOM or CAM_ZOOM)
        local halfH = (screenH / 2) / (LV.ZOOM or CAM_ZOOM)
        camX = clamp(camX, math.min(halfW, 840), math.max(1680 - halfW, 840))
        if halfH >= 455 then camY = 455 else camY = clamp(camY, halfH, 910 - halfH) end
    end""")

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("trace mode patched")
