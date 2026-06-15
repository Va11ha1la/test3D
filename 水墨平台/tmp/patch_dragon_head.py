# -*- coding: utf-8 -*-
"""墨龙关:龙首精绘 + 鳞甲/腹甲/钩爪升级(贴陈容《九龙图》)"""
import io

p = 'scripts/src/70_entities_targets_render.lua'
s = io.open(p, encoding='utf-8').read()

old = '''    if currentLevel.id == "molong" then
        -- 龙体:背鳍尖刺 / 鳞弧 / 龙首眼须 / 爪趾
        local body = branchGroups.dragon_body
        if body then
            for i = 3, #body - 2, 4 do
                local n = body[i]
                local seed = i * 13.7
                local fl = 14 + hash01(seed) * 22
                local bx1, by1 = n.x + n.normX * n.r, n.y + n.normY * n.r
                local tx2, ty2 = n.x + n.normX * (n.r + fl) - 6, n.y + n.normY * (n.r + fl)
                fillPoly({ { bx1 - 9, by1 + 2 }, { tx2, ty2 }, { bx1 + 9, by1 - 2 } }, colorRGBA(currentLevel.ink, 215))
            end
            for i = 2, #body - 1, 2 do
                local n = body[i]
                nvgBeginPath(vg)
                nvgCircle(vg, n.x - n.normX * n.r * 0.25, n.y - n.normY * n.r * 0.25, n.r * 0.62)
                nvgStrokeWidth(vg, 1.1)
                nvgStrokeColor(vg, colorRGBA(currentLevel.paper, 54))
                nvgStroke(vg)
            end
        end
        local head = branchGroups.dragon_head
        if head and #head > 4 then
            local eye = head[math.floor(#head * 0.55)]
            drawCircle(eye.x, eye.y - eye.r * 0.4, 7.5, rgba(216, 174, 64, 235))
            drawCircle(eye.x + 1.5, eye.y - eye.r * 0.4, 3.4, rgba(12, 10, 8, 250))
            local tip = head[#head]
            strokeQuad(tip.x, tip.y, tip.x + 46, tip.y - 26, tip.x + 88, tip.y - 14, 1.6, colorRGBA(currentLevel.ink, 190))
            strokeQuad(tip.x, tip.y + 8, tip.x + 52, tip.y + 22, tip.x + 96, tip.y + 40, 1.6, colorRGBA(currentLevel.ink, 170))
        end
        for li = 1, 4 do
            local l = branchGroups["dragon_leg" .. li]
            if l and #l > 1 then
                local tip = l[#l]
                for k = -1, 1 do
                    strokeLine(tip.x, tip.y, tip.x + k * 9 - 4, tip.y + 13, 2.0, colorRGBA(currentLevel.ink, 225))
                end
            end
        end
    end'''

new = '''    if currentLevel.id == "molong" then
        -- 龙体:火焰背鳍 / 网纹鳞甲 / 腹甲横纹 / 龙首精绘 / 三趾钩爪
        local body = branchGroups.dragon_body
        if body then
            for i = 3, #body - 2, 4 do
                local n = body[i]
                local seed = i * 13.7
                local fl = 16 + hash01(seed) * 24
                local bx1, by1 = n.x + n.normX * n.r, n.y + n.normY * n.r
                local tx2, ty2 = n.x + n.normX * (n.r + fl) - 8, n.y + n.normY * (n.r + fl)
                fillPoly({ { bx1 - 9, by1 + 2 }, { tx2, ty2 }, { bx1 + 9, by1 - 2 } }, colorRGBA(currentLevel.ink, 215))
                strokeQuad(tx2, ty2, tx2 - 10, ty2 - 8, tx2 - 20, ty2 - 10, 1.2, colorRGBA(currentLevel.ink, 150))
            end
            -- 网纹鳞:两排交错半圆鳞 + 鳞心点,贴近真迹留白勾鳞
            for i = 2, #body - 1, 2 do
                local n = body[i]
                for row = -1, 1 do
                    local ox = n.x + n.normX * n.r * row * 0.42
                    local oy = n.y + n.normY * n.r * row * 0.42
                    nvgBeginPath(vg)
                    nvgCircle(vg, ox + (i % 4 - 2) * 3, oy, n.r * 0.30)
                    nvgStrokeWidth(vg, 1.2)
                    nvgStrokeColor(vg, colorRGBA(currentLevel.paper, row == 0 and 78 or 56))
                    nvgStroke(vg)
                end
            end
            -- 腹甲横纹:沿腹侧的节状横线
            for i = 2, #body - 2, 2 do
                local n1, n2 = body[i], body[i + 1]
                local ax = n1.x - n1.normX * n1.r * 0.74
                local ay = n1.y - n1.normY * n1.r * 0.74
                local bx2 = n2.x - n2.normX * n2.r * 0.74
                local by2 = n2.y - n2.normY * n2.r * 0.74
                strokeLine(ax, ay, bx2, by2, 2.4, colorRGBA(currentLevel.paper, 64))
                if i % 4 == 0 then
                    strokeLine(ax, ay, ax + n1.normX * n1.r * 0.34, ay + n1.normY * n1.r * 0.34, 1.6, colorRGBA(currentLevel.paper, 70))
                end
            end
        end
        local head = branchGroups.dragon_head
        if head and #head > 4 then
            local sk = head[math.floor(#head * 0.45)]
            drawMolongHead(sk.x, sk.y - sk.r * 0.2, 1.45)
        end
        for li = 1, 4 do
            local l = branchGroups["dragon_leg" .. li]
            if l and #l > 1 then
                local tip = l[#l]
                local root = l[1]
                -- 肘毛火焰
                strokeQuad(root.x - 6, root.y + 10, root.x - 26, root.y + 2, root.x - 40, root.y - 10, 2.0, colorRGBA(currentLevel.ink, 170))
                strokeQuad(root.x - 4, root.y + 18, root.x - 28, root.y + 16, root.x - 44, root.y + 6, 1.6, colorRGBA(currentLevel.ink, 140))
                -- 三趾钩爪:弧形利爪
                for k = -1, 1 do
                    local spread = k * 12
                    strokeQuad(tip.x, tip.y, tip.x + spread * 0.6 - 2, tip.y + 12, tip.x + spread, tip.y + 20, 2.6, colorRGBA(currentLevel.ink, 235))
                    strokeQuad(tip.x + spread, tip.y + 20, tip.x + spread + 4, tip.y + 26, tip.x + spread + 9, tip.y + 27, 1.8, colorRGBA(currentLevel.ink, 235))
                end
            end
        end
    end'''
assert old in s
s = s.replace(old, new, 1)

# 在 drawOutlineBlossom 之前插入 drawMolongHead 全局函数
anchor = 'function drawOutlineBlossom(x, y, r, inkTint, alpha, seed)'
assert anchor in s
head_fn = '''-- 陈容《九龙图》式龙首精绘:分层 口腔/上颚/下颚/獠牙/金睛/火焰眉/鹿角/鬃毛/长须/颌髯
-- (hx,hy) 为颅心锚点(随龙身行波),sc 为整体缩放,面朝右
function drawMolongHead(hx, hy, sc)
    local ink = currentLevel.ink
    local paper = currentLevel.paper
    local function P(pts)
        local out = {}
        for _, q in ipairs(pts) do out[#out + 1] = { hx + q[1] * sc, hy + q[2] * sc } end
        return out
    end
    -- 口腔(张口的留白)
    fillPoly(P({ { 6, 0 }, { 78, -6 }, { 84, 18 }, { 8, 22 } }), colorRGBA(paper, 185))
    -- 上颚与颅顶:长吻,鼻端隆起
    fillPoly(P({
        { -56, 6 }, { -54, -16 }, { -34, -26 }, { -8, -32 }, { 16, -28 },
        { 40, -24 }, { 62, -18 }, { 80, -10 }, { 86, -4 }, { 74, -2 },
        { 46, 0 }, { 14, 2 }, { -22, 6 },
    }), colorRGBA(ink, 245))
    -- 鼻端上卷
    strokeQuad(hx + 84 * sc, hy - 8 * sc, hx + 94 * sc, hy - 18 * sc, hx + 86 * sc, hy - 26 * sc, 2.6 * sc, colorRGBA(ink, 230))
    -- 下颚:钩状颌尖
    fillPoly(P({
        { 4, 12 }, { 32, 16 }, { 58, 20 }, { 80, 18 }, { 88, 24 },
        { 64, 34 }, { 36, 36 }, { 8, 30 }, { -12, 20 },
    }), colorRGBA(ink, 245))
    -- 獠牙:上 4 下 3(纸色尖三角)
    for k = 0, 3 do
        local tx = (22 + k * 16) * sc
        fillPoly({ { hx + tx, hy - 1 * sc }, { hx + tx + 4 * sc, hy + 11 * sc }, { hx + tx + 8 * sc, hy - 1 * sc } }, colorRGBA(paper, 235))
    end
    for k = 0, 2 do
        local tx = (30 + k * 17) * sc
        fillPoly({ { hx + tx, hy + 17 * sc }, { hx + tx + 4 * sc, hy + 7 * sc }, { hx + tx + 8 * sc, hy + 17 * sc } }, colorRGBA(paper, 225))
    end
    -- 金睛圆瞪:眼眶留白圈 + 金珠 + 浓墨点睛
    nvgBeginPath(vg)
    nvgCircle(vg, hx - 6 * sc, hy - 16 * sc, 10.5 * sc)
    nvgStrokeWidth(vg, 2.2 * sc)
    nvgStrokeColor(vg, colorRGBA(paper, 200))
    nvgStroke(vg)
    drawCircle(hx - 6 * sc, hy - 16 * sc, 8.2 * sc, rgba(216, 174, 64, 245))
    drawCircle(hx - 4 * sc, hy - 16 * sc, 3.8 * sc, rgba(10, 8, 6, 250))
    -- 火焰眉:眼上两束后掠焰
    strokeQuad(hx + 2 * sc, hy - 26 * sc, hx - 16 * sc, hy - 38 * sc, hx - 38 * sc, hy - 40 * sc, 3.4 * sc, colorRGBA(ink, 235))
    strokeQuad(hx + 4 * sc, hy - 30 * sc, hx - 10 * sc, hy - 46 * sc, hx - 30 * sc, hy - 52 * sc, 2.2 * sc, colorRGBA(ink, 195))
    -- 鹿角双枝:主梁后掠 + 两级分叉
    for side = 0, 1 do
        local bx = hx + (-14 - side * 10) * sc
        local by = hy + (-26 - side * 3) * sc
        local a1x, a1y = bx - 26 * sc, by - 26 * sc
        local a2x, a2y = bx - 58 * sc, by - 38 * sc
        local a3x, a3y = bx - 84 * sc, by - 42 * sc
        strokeQuad(bx, by, a1x, a1y, a2x, a2y, (3.6 - side) * sc, colorRGBA(ink, 240))
        strokeQuad(a2x, a2y, (a2x + a3x) * 0.5, a2y - 6 * sc, a3x, a3y, (2.4 - side * 0.6) * sc, colorRGBA(ink, 225))
        strokeQuad(a1x, a1y, a1x - 8 * sc, a1y - 16 * sc, a1x - 10 * sc, a1y - 28 * sc, 2.0 * sc, colorRGBA(ink, 215))
        strokeQuad(a2x, a2y, a2x - 4 * sc, a2y - 14 * sc, a2x - 2 * sc, a2y - 24 * sc, 1.6 * sc, colorRGBA(ink, 200))
    end
    -- 鬃毛:颅后五束飞扬火焰
    for k = 0, 4 do
        local oy = (-18 + k * 8) * sc
        local ln = (66 + hash01(k * 7.7) * 44) * sc
        strokeQuad(hx - 30 * sc, hy + oy, hx - 30 * sc - ln * 0.5, hy + oy - 14 * sc - k * 2 * sc,
            hx - 30 * sc - ln, hy + oy + (k - 2) * 6 * sc, (3.0 - k * 0.35) * sc, colorRGBA(ink, 215 - k * 18))
    end
    -- 长须:吻端两根细长 S 须
    strokeQuad(hx + 78 * sc, hy - 8 * sc, hx + 120 * sc, hy - 30 * sc, hx + 165 * sc, hy - 22 * sc, 1.5 * sc, colorRGBA(ink, 200))
    strokeQuad(hx + 165 * sc, hy - 22 * sc, hx + 196 * sc, hy - 16 * sc, hx + 214 * sc, hy - 30 * sc, 1.1 * sc, colorRGBA(ink, 165))
    strokeQuad(hx + 80 * sc, hy + 14 * sc, hx + 124 * sc, hy + 34 * sc, hx + 170 * sc, hy + 30 * sc, 1.5 * sc, colorRGBA(ink, 200))
    strokeQuad(hx + 170 * sc, hy + 30 * sc, hx + 200 * sc, hy + 26 * sc, hx + 220 * sc, hy + 40 * sc, 1.1 * sc, colorRGBA(ink, 165))
    -- 颌髯:下颚四束短髯
    for k = 0, 3 do
        local bx = hx + (12 + k * 14) * sc
        strokeQuad(bx, hy + 30 * sc, bx - 4 * sc, hy + 44 * sc, bx - 12 * sc, hy + 54 * sc, 1.6 * sc, colorRGBA(ink, 185 - k * 12))
    end
    -- 颊纹三道
    for k = 0, 2 do
        strokeQuad(hx + (-30 + k * 6) * sc, hy + (-6 + k * 7) * sc, hx + (-14 + k * 8) * sc, hy + (-2 + k * 7) * sc,
            hx + (2 + k * 8) * sc, hy + (2 + k * 6) * sc, 1.1 * sc, colorRGBA(paper, 60))
    end
end

function drawOutlineBlossom(x, y, r, inkTint, alpha, seed)'''
s = s.replace(anchor, head_fn, 1)
io.open(p, 'w', encoding='utf-8').write(s)
print('70 ok')
