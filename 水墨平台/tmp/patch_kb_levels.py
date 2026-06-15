# -*- coding: utf-8 -*-
p = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
s = open(p, encoding="utf-8").read()

# ---------- L1 金庙背景重写 ----------
old1 = s[s.index("local function bgGoldTemple(px, py)"):s.index("local function bgMauveRuins(px, py)")]
new1 = '''local function bgGoldTemple(px, py)
    local PAL = LV.PAL
    -- 远景:连续金光拱窗墙(整面)
    nvgFillColor(vg, rgba(112, 128, 84, 200))
    nvgBeginPath(vg)
    nvgRect(vg, px - 2400, -600, 4800, 3200)
    nvgFill(vg)
    local boff = px * 0.75
    local bx0 = math.floor((px - 2400 + boff) / 520) * 520 - boff
    for k = 0, 10 do
        local ax = bx0 + k * 520
        local gi = math.floor((ax + boff) / 520)
        local aw = 300
        local ah = 620 + hash01(gi) * 260
        local ay = 1500 - hash01(gi * 3) * 700
        nvgFillColor(vg, rgba(236, 208, 112, 255))
        nvgBeginPath(vg)
        nvgRect(vg, ax, ay - ah * 0.5, aw, ah)
        nvgCircle(vg, ax + aw / 2, ay - ah * 0.5, aw / 2)
        nvgFill(vg)
    end
    drawGodRays(px, py)
    -- 中景:连续茶绿拱廊带(两层)
    for band = 0, 1 do
        local bandY = 1340 + band * 300
        local boff2 = px * (0.5 - band * 0.06)
        local bx2 = math.floor((px - 2400 + boff2) / 130) * 130 - boff2
        drawArchRow(bx2, bandY, 4900, 250, 130, PAL.mid, band == 0 and 245 or 215)
        drawBalustrade(bx2, bandY - 250 * 0.55 - 8, 4900, PAL.mid, 200)
    end
    -- 中景垂藤帘
    for i = 0, 13 do
        local vx = i * 430 + hash01(i + 31) * 240 - px * 0.5
        nvgStrokeColor(vg, col(PAL.mid, 175))
        nvgStrokeWidth(vg, 4)
        nvgBeginPath(vg)
        nvgMoveTo(vg, vx, -300)
        nvgBezierTo(vg, vx + 26, 200, vx - 20, 600, vx + 12, 820 + hash01(i) * 420)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgCircle(vg, vx + 12, 826 + hash01(i) * 420, 6)
        nvgFillColor(vg, col(PAL.mid, 190))
        nvgFill(vg)
    end
end

'''
s = s.replace(old1, new1)

# ---------- L2 紫废墟背景:加暗龛层次 ----------
old2 = s[s.index("local function bgMauveRuins(px, py)"):s.index("local function bgGoldForest(px, py)")]
new2 = '''local function bgMauveRuins(px, py)
    local PAL = LV.PAL
    for i = 0, 9 do
        local bx = i * 880 + hash01(i + 2) * 320 - px * 0.22
        local bw = 420 + hash01(i + 6) * 260
        local bh = 800 + hash01(i + 9) * 900
        nvgFillColor(vg, col(PAL.mid2, 235))
        nvgBeginPath(vg)
        nvgRect(vg, bx, 2300 - bh, bw, bh)
        nvgFill(vg)
    end
    -- 暗龛(深紫凹陷,纵深)
    for i = 0, 8 do
        local bx = i * 1000 + hash01(i + 71) * 420 - px * 0.36
        local bw = 240 + hash01(i + 81) * 200
        local bh = 420 + hash01(i + 91) * 500
        nvgFillColor(vg, rgba(58, 50, 66, 210))
        nvgBeginPath(vg)
        nvgRect(vg, bx, 1900 - bh + hash01(i + 5) * 600, bw, bh)
        nvgFill(vg)
    end
    -- 中景紫块 + 暗拱洞
    for i = 0, 7 do
        local bx = i * 1100 + hash01(i + 22) * 380 - px * 0.48
        local bw = 360 + hash01(i + 12) * 220
        local bh = 600 + hash01(i + 17) * 700
        nvgFillColor(vg, col(PAL.mid, 245))
        nvgBeginPath(vg)
        nvgRect(vg, bx, 2400 - bh, bw, bh)
        nvgFill(vg)
        nvgFillColor(vg, rgba(64, 56, 72, 235))
        nvgBeginPath(vg)
        nvgRect(vg, bx + bw * 0.3, 2400 - bh * 0.7, bw * 0.4, bh * 0.34)
        nvgCircle(vg, bx + bw * 0.5, 2400 - bh * 0.7, bw * 0.2)
        nvgFill(vg)
    end
end

'''
s = s.replace(old2, new2)

# ---------- L3 森林背景:树干树冠加密 ----------
old3 = s[s.index("local function bgGoldForest(px, py)"):s.index("local function bgWaterCity(px, py)")]
new3 = '''local function bgGoldForest(px, py)
    local PAL = LV.PAL
    for i = 0, 13 do
        local bx = i * 640 + hash01(i + 4) * 360 - px * 0.18
        local by = 200 + hash01(i + 14) * 1500
        nvgFillColor(vg, rgba(234, 188, 72, 90 + hash01(i) * 70))
        nvgBeginPath(vg)
        nvgCircle(vg, bx, by, 200 + hash01(i + 24) * 180)
        nvgFill(vg)
    end
    -- 远树干
    for i = 0, 11 do
        local tx = i * 700 + hash01(i + 71) * 320 - px * 0.3
        nvgFillColor(vg, col(PAL.mid2, 200))
        nvgBeginPath(vg)
        nvgRect(vg, tx, -300, 60 + hash01(i + 6) * 60, 2900)
        nvgFill(vg)
    end
    drawGodRays(px, py)
    -- 中景粗树干
    for i = 0, 9 do
        local tx = i * 820 + hash01(i + 41) * 380 - px * 0.45
        nvgFillColor(vg, col(PAL.mid, 230))
        nvgBeginPath(vg)
        nvgRect(vg, tx, -300, 100 + hash01(i + 8) * 90, 2900)
        nvgFill(vg)
    end
    -- 树冠团(上沿)
    for i = 0, 12 do
        local cx2 = i * 600 + hash01(i + 52) * 300 - px * 0.5
        local cy2 = 60 + hash01(i + 62) * 320
        nvgFillColor(vg, rgba(58, 92, 30, 235))
        for b = 0, 4 do
            nvgBeginPath(vg)
            nvgCircle(vg, cx2 + b * 100 - 200 + hash01(i * 5 + b) * 70, cy2 + hash01(i * 3 + b) * 140, 140 + hash01(b + i) * 90)
            nvgFill(vg)
        end
    end
    -- 底部灌木
    for i = 0, 12 do
        local cx2 = i * 620 + hash01(i + 82) * 300 - px * 0.5
        nvgFillColor(vg, rgba(58, 92, 30, 220))
        for b = 0, 3 do
            nvgBeginPath(vg)
            nvgCircle(vg, cx2 + b * 110 - 160, 2280 + hash01(i + b) * 80, 120 + hash01(i * 9 + b) * 80)
            nvgFill(vg)
        end
    end
end

'''
s = s.replace(old3, new3)

# ---------- L4 白点饰边细密 ----------
s = s.replace('''            local segLen = x2 - x1
            nvgFillColor(vg, rgba(255, 255, 255, 220))
            for k = 0, math.floor(segLen / 34) do
                nvgBeginPath(vg)
                nvgRect(vg, x1 + k * 34 + 8, y1 - 3, 14, 4)
                nvgFill(vg)
            end''',
'''            local segLen = x2 - x1
            nvgFillColor(vg, rgba(255, 255, 255, 185))
            for k = 0, math.floor(segLen / 20) do
                nvgBeginPath(vg)
                nvgRect(vg, x1 + k * 20 + 6, y1 - 2.5, 9, 3.5)
                nvgFill(vg)
            end''')

# ---------- L4 远城加密 ----------
s = s.replace("    -- 远景极淡蓝城\n    for i = 0, 10 do\n        local bx = i * 850",
              "    -- 远景极淡蓝城\n    for i = 0, 15 do\n        local bx = i * 560")

# ---------- 草缘改柔 ----------
s = s.replace('''            for gx = x1 + 6, x2 - 6, 14 do
                local gh = 7 + hash01(gx) * 9
                nvgBeginPath(vg)
                nvgMoveTo(vg, gx, y1)
                nvgLineTo(vg, gx + 4 + hash01(gx + 1) * 3, y1 - gh)
                nvgLineTo(vg, gx + 9, y1)
                nvgClosePath(vg)
                nvgFill(vg)
            end''',
'''            for gx = x1 + 6, x2 - 6, 24 do
                if hash01(gx * 0.7) > 0.25 then
                    local gh = 5 + hash01(gx) * 8
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, gx, y1 + 1)
                    nvgBezierTo(vg, gx + 2, y1 - gh * 0.7, gx + 3 + hash01(gx + 1) * 3, y1 - gh, gx + 5 + hash01(gx + 2) * 3, y1 - gh * 0.5)
                    nvgLineTo(vg, gx + 7, y1 + 1)
                    nvgClosePath(vg)
                    nvgFill(vg)
                end
            end''')

# ---------- L2 前景亮一档 + 右缘阴影 ----------
s = s.replace("        fore = { 96, 86, 102 }, foreDk = { 56, 48, 62 },",
              "        fore = { 106, 96, 112 }, foreDk = { 54, 46, 60 },")
s = s.replace('''        elseif PAL.trim == "mauve" then''',
'''        elseif PAL.trim == "mauve" then
            if #poly == 4 then
                nvgFillColor(vg, col(PAL.foreDk, 160))
                nvgBeginPath(vg)
                nvgRect(vg, poly[2][1] - 30, poly[2][2], 30, poly[3][2] - poly[2][2])
                nvgFill(vg)
            end''')

open(p, "w", encoding="utf-8", newline="\n").write(s)
print("patched ok")
