# -*- coding: utf-8 -*-
"""新增 17 富春山居(段) / 18 六君子 / 19 墨荷 三关"""
import io

def rd(p): return io.open(p, encoding='utf-8').read()
def wr(p, s): io.open(p, 'w', encoding='utf-8').write(s)

# ---------- 00 LEVELS ----------
p = 'scripts/src/00_state_levels_keys.lua'
s = rd(p)
i = s.find('id = "xuwei_grape"')
j = s.find('    },', i) + len('    },\n')
entries = '''    {
        id = "fuchun",
        sourceImage = "reference/fuchun_detail_npm.jpg",
        name = "富春山居",
        title = "母本复刻 - 黄公望《富春山居图》主峰段",
        seal = "富",
        note = "复刻无用师卷主峰段：近岸松林立坡，披麻皴大岭一脊到顶，山腰树丛、山脚汀渚皆可游。",
        -- 画芯 2200x804,比例 2.736;大画布精刻
        wmul = 4.5,
        hmul = 2.92,
        paper = C(214, 206, 176),
        paper2 = C(192, 182, 148),
        ink = C(58, 60, 54),
        wash = C(110, 114, 98),
        accent = C(86, 96, 78),
        bloom = C(52, 58, 48),
        water = C(170, 176, 150),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "nizan",
        sourceImage = "reference/nizan_six_gentlemen.jpg",
        name = "六君子",
        title = "母本复刻 - 倪瓒《六君子图》",
        seal = "君",
        note = "复刻上博倪瓒《六君子图》：一河两岸，前坡六树亭亭直立，远山一抹永不可及，余皆留白。",
        -- 画芯 2688x4976,比例 0.540;立轴
        wmul = 1.9,
        hmul = 6.25,
        paper = C(204, 200, 186),
        paper2 = C(182, 178, 162),
        ink = C(64, 60, 52),
        wash = C(124, 120, 108),
        accent = C(96, 92, 80),
        bloom = C(78, 74, 62),
        water = C(174, 172, 158),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
    {
        id = "bada_lotus",
        sourceImage = "reference/bada_lotus_ducks.jpg",
        name = "墨荷",
        title = "母本复刻 - 八大山人《荷塘图》",
        seal = "荷",
        note = "复刻八大山人荷塘：泼墨大叶高擎如盖，长茎细可攀，太湖石蹲踞坡上，白荷藏于叶底。",
        -- 画芯 1473x2700,比例 0.546;立轴
        wmul = 1.9,
        hmul = 6.19,
        paper = C(212, 206, 194),
        paper2 = C(188, 182, 168),
        ink = C(44, 42, 38),
        wash = C(100, 96, 88),
        accent = C(70, 68, 62),
        bloom = C(120, 114, 104),
        water = C(178, 174, 164),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
'''
s = s[:j] + entries + s[j:]
wr(p, s)
print('00 ok')

# ---------- 30 generators ----------
p = 'scripts/src/30_level_generation.lua'
s = rd(p)
gens = '''
function generateFuchun()
    -- 第17关:母本复刻 - 黄公望《富春山居图》主峰段(台北故宫无用师卷)
    -- 近岸松林坡在左,披麻皴大岭一脊到顶在右,山腰台地、山脚汀渚、右坡松岭。
    createBranchPath({
        { 0.020, 0.800, 30 }, { 0.100, 0.745, 28 }, { 0.180, 0.745, 27 },
        { 0.260, 0.770, 26 }, { 0.340, 0.780, 26 }, { 0.420, 0.775, 25 },
        { 0.500, 0.800, 25 },
    }, "fc_shore", 0.10)
    -- 八株高松(干细可攀,冠为目标)
    createBranchPath({ { 0.130, 0.780, 6 }, { 0.126, 0.660, 5 }, { 0.124, 0.540, 4 }, { 0.126, 0.460, 4 } }, "fc_tree1", 0.10)
    createBranchPath({ { 0.170, 0.775, 6 }, { 0.176, 0.650, 5 }, { 0.180, 0.530, 4 }, { 0.182, 0.450, 4 } }, "fc_tree2", 0.10)
    createBranchPath({ { 0.215, 0.775, 6 }, { 0.210, 0.650, 5 }, { 0.206, 0.525, 4 }, { 0.205, 0.440, 4 } }, "fc_tree3", 0.10)
    createBranchPath({ { 0.260, 0.780, 6 }, { 0.266, 0.655, 5 }, { 0.270, 0.530, 4 }, { 0.272, 0.445, 4 } }, "fc_tree4", 0.10)
    createBranchPath({ { 0.305, 0.785, 6 }, { 0.300, 0.660, 5 }, { 0.296, 0.535, 4 }, { 0.295, 0.450, 4 } }, "fc_tree5", 0.10)
    createBranchPath({ { 0.350, 0.785, 6 }, { 0.356, 0.660, 5 }, { 0.360, 0.540, 4 }, { 0.362, 0.455, 4 } }, "fc_tree6", 0.10)
    createBranchPath({ { 0.400, 0.780, 6 }, { 0.395, 0.655, 5 }, { 0.392, 0.535, 4 }, { 0.390, 0.450, 4 } }, "fc_tree7", 0.10)
    createBranchPath({ { 0.445, 0.785, 6 }, { 0.450, 0.665, 5 }, { 0.454, 0.545, 4 }, { 0.456, 0.465, 4 } }, "fc_tree8", 0.10)
    -- 主山:一脊到顶再落右肩(披麻皴大岭)
    createBranchPath({
        { 0.500, 0.880, 26 }, { 0.550, 0.680, 24 }, { 0.600, 0.460, 22 },
        { 0.650, 0.260, 20 }, { 0.700, 0.100, 18 }, { 0.745, 0.045, 16 },
        { 0.790, 0.090, 15 }, { 0.840, 0.200, 14 }, { 0.880, 0.300, 14 },
        { 0.930, 0.380, 14 }, { 0.980, 0.420, 14 },
    }, "fc_ridge_main", 0.10)
    -- 中腹台地脊
    createBranchPath({
        { 0.540, 0.740, 18 }, { 0.600, 0.600, 16 }, { 0.660, 0.470, 15 },
        { 0.720, 0.400, 14 }, { 0.780, 0.380, 13 }, { 0.840, 0.420, 13 },
    }, "fc_ridge_mid", 0.10)
    -- 山脚汀渚线
    createBranchPath({
        { 0.500, 0.920, 16 }, { 0.600, 0.900, 15 }, { 0.700, 0.880, 14 },
        { 0.800, 0.840, 13 }, { 0.900, 0.780, 12 }, { 0.980, 0.740, 12 },
    }, "fc_foot", 0.10)
    -- 右下松坡
    createBranchPath({ { 0.800, 0.620, 12 }, { 0.880, 0.560, 11 }, { 0.960, 0.520, 10 } }, "fc_spur", 0.10)
    for _, p in ipairs({
        { "fc_tree2", 0.88 }, { "fc_tree4", 0.88 }, { "fc_tree6", 0.88 }, { "fc_tree8", 0.88 },
        { "fc_shore", 0.30 },
        { "fc_ridge_main", 0.42 }, { "fc_ridge_main", 0.75 },
        { "fc_ridge_mid", 0.55 }, { "fc_foot", 0.50 }, { "fc_spur", 0.60 },
    }) do addTargetOnBranch(p[1], p[2], 38) end
end

function generateNizan()
    -- 第18关:母本复刻 - 倪瓒《六君子图》(上海博物馆)
    -- 一河两岸:前坡大石、后坡平台,六株疏树亭亭直上,冠层点叶可行;
    -- 中段大留白湖面与远山为背景,永不可及。
    createBranchPath({
        { 0.040, 0.945, 30 }, { 0.160, 0.925, 28 }, { 0.280, 0.915, 28 },
        { 0.400, 0.920, 28 }, { 0.500, 0.930, 26 },
    }, "nz_slope_front", 0.10)
    createBranchPath({
        { 0.280, 0.885, 24 }, { 0.400, 0.865, 22 }, { 0.520, 0.855, 22 },
        { 0.640, 0.855, 22 }, { 0.760, 0.865, 22 }, { 0.860, 0.880, 20 },
    }, "nz_slope_back", 0.10)
    createBranchPath({ { 0.335, 0.875, 6 }, { 0.325, 0.740, 5 }, { 0.318, 0.620, 4 }, { 0.315, 0.545, 4 } }, "nz_tree1", 0.10)
    createBranchPath({ { 0.385, 0.870, 6 }, { 0.392, 0.720, 5 }, { 0.398, 0.600, 4 }, { 0.402, 0.520, 4 } }, "nz_tree2", 0.10)
    createBranchPath({ { 0.445, 0.868, 7 }, { 0.438, 0.700, 5 }, { 0.430, 0.575, 4 }, { 0.428, 0.495, 4 } }, "nz_tree3", 0.10)
    createBranchPath({ { 0.525, 0.862, 6 }, { 0.535, 0.700, 5 }, { 0.545, 0.580, 4 }, { 0.552, 0.505, 4 } }, "nz_tree4", 0.10)
    createBranchPath({ { 0.605, 0.860, 6 }, { 0.598, 0.720, 5 }, { 0.592, 0.600, 4 }, { 0.588, 0.530, 4 } }, "nz_tree5", 0.10)
    createBranchPath({ { 0.685, 0.862, 5 }, { 0.695, 0.730, 4 }, { 0.705, 0.615, 4 }, { 0.712, 0.555, 3.5 } }, "nz_tree6", 0.10)
    -- 冠层点叶线(参差相接,可行走)
    createBranchPath({
        { 0.300, 0.520, 12 }, { 0.380, 0.492, 13 }, { 0.460, 0.475, 13 },
        { 0.560, 0.488, 13 }, { 0.650, 0.505, 12 }, { 0.730, 0.535, 11 },
    }, "nz_canopy", 0.10)
    for _, p in ipairs({
        { "nz_canopy", 0.06 }, { "nz_canopy", 0.22 }, { "nz_canopy", 0.40 },
        { "nz_canopy", 0.58 }, { "nz_canopy", 0.76 }, { "nz_canopy", 0.92 },
        { "nz_slope_front", 0.15 }, { "nz_slope_back", 0.80 }, { "nz_tree3", 0.50 },
    }) do addTargetOnBranch(p[1], p[2], 36) end
end

function generateBadaLotus()
    -- 第19关:母本复刻 - 八大山人《荷塘图》(鸭雀省略,聚焦荷石)
    -- 太湖石蹲踞坡上;长茎三条细可攀;泼墨大叶与顶叶为高台;残茎斜出左上。
    createBranchPath({
        { 0.020, 0.915, 18 }, { 0.200, 0.895, 17 }, { 0.400, 0.875, 17 },
        { 0.550, 0.880, 16 }, { 0.700, 0.890, 16 }, { 0.850, 0.875, 15 }, { 0.970, 0.860, 15 },
    }, "bd_ground", 0.10)
    createBranchPath({
        { 0.300, 0.800, 26 }, { 0.380, 0.745, 25 }, { 0.480, 0.725, 26 },
        { 0.580, 0.730, 25 }, { 0.660, 0.760, 24 }, { 0.710, 0.800, 22 },
    }, "bd_rock", 0.12)
    createBranchPath({
        { 0.700, 0.900, 7 }, { 0.715, 0.760, 6 }, { 0.735, 0.560, 6 },
        { 0.760, 0.360, 5 }, { 0.778, 0.200, 5 }, { 0.788, 0.135, 5 },
    }, "bd_stem1", 0)
    createBranchPath({
        { 0.830, 0.870, 6 }, { 0.845, 0.660, 5 }, { 0.858, 0.450, 5 },
        { 0.868, 0.280, 4 }, { 0.872, 0.180, 4 },
    }, "bd_stem2", 0)
    createBranchPath({
        { 0.620, 0.885, 6 }, { 0.610, 0.700, 5 }, { 0.590, 0.520, 5 },
        { 0.560, 0.380, 4 }, { 0.530, 0.300, 4 },
    }, "bd_stem3", 0)
    -- 顶叶(浓墨一柄高擎)与中部大叶团(泼墨,叶面可站)
    createBranchPath({
        { 0.600, 0.105, 16 }, { 0.700, 0.085, 18 }, { 0.800, 0.100, 17 }, { 0.900, 0.125, 15 },
    }, "bd_leaf_top", 0.12)
    createBranchPath({
        { 0.560, 0.210, 20 }, { 0.660, 0.180, 22 }, { 0.760, 0.200, 21 }, { 0.860, 0.240, 19 },
    }, "bd_leaf_mid", 0.12)
    -- 左上斜残茎(雀栖处,化作花苞栖位)
    createBranchPath({
        { 0.065, 0.335, 5 }, { 0.150, 0.315, 5 }, { 0.230, 0.302, 5 }, { 0.300, 0.300, 4 },
    }, "bd_stem_broken", 0)
    addTarget(W(0.565), H(0.300), 34)  -- 叶底白荷
    for _, p in ipairs({
        { "bd_leaf_top", 0.50 }, { "bd_leaf_mid", 0.30 }, { "bd_leaf_mid", 0.70 },
        { "bd_stem_broken", 0.85 }, { "bd_rock", 0.50 },
        { "bd_ground", 0.15 }, { "bd_ground", 0.85 }, { "bd_stem2", 0.50 },
    }) do addTargetOnBranch(p[1], p[2], 36) end
end
'''
s = s.rstrip() + '\n' + gens
wr(p, s)
print('30 ok')

# ---------- 40 dispatch + spawn ----------
p = 'scripts/src/40_gameplay_targets.lua'
s = rd(p)
old = '    elseif currentLevel.id == "xuwei_grape" then generateXuweiGrape()\n'
assert old in s
s = s.replace(old, old + '''    elseif currentLevel.id == "fuchun" then generateFuchun()
    elseif currentLevel.id == "nizan" then generateNizan()
    elseif currentLevel.id == "bada_lotus" then generateBadaLotus()
''')
old = '''    elseif currentLevel.id == "xuwei_grape" then
        local ns = branchGroups.xw_vine or {}
        local safe = ns[8]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.92), H(0.26) end
        player.facingRight = false
'''
assert old in s
s = s.replace(old, old + '''    elseif currentLevel.id == "fuchun" then
        local ns = branchGroups.fc_shore or {}
        local safe = ns[10]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.05), H(0.74) end
        player.facingRight = true
    elseif currentLevel.id == "nizan" then
        local ns = branchGroups.nz_slope_front or {}
        local safe = ns[math.floor(#ns / 2)]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.20), H(0.90) end
        player.facingRight = true
    elseif currentLevel.id == "bada_lotus" then
        local ns = branchGroups.bd_ground or {}
        local safe = ns[12]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.10), H(0.88) end
        player.facingRight = true
''')
wr(p, s)
print('40 ok')

# ---------- 60 background ----------
p = 'scripts/src/60_background_render.lua'
s = rd(p)
old = '''    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" then'''
assert old in s
s = s.replace(old, '''    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" or currentLevel.id == "fuchun"
        or currentLevel.id == "nizan" or currentLevel.id == "bada_lotus" then''')
old = '''        elseif currentLevel.id == "plum_xiyan" then'''
assert old in s
extra = '''        elseif currentLevel.id == "fuchun" then
            -- 左上远峰群(淡墨)+ 江面沙汀横线
            for i = 0, 5 do
                local bx = W(0.02 + i * 0.075)
                local bw = W(0.085 + hash01(i * 7.7) * 0.04)
                local bh = H(0.060 + hash01(i * 11.3) * 0.070)
                local by = H(0.175)
                fillPoly({ { bx, by }, { bx + bw * 0.4, by - bh }, { bx + bw * 0.65, by - bh * 0.6 }, { bx + bw, by } }, colorRGBA(currentLevel.wash, 34 + hash01(i * 13) * 16))
            end
            for i = 0, 6 do
                local sy = H(0.30 + i * 0.018)
                strokeLine(W(0.27 + hash01(i * 3.3) * 0.04), sy, W(0.44 + hash01(i * 5.1) * 0.05), sy + 2, 1.2, colorRGBA(currentLevel.wash, 50))
            end
        elseif currentLevel.id == "nizan" then
            -- 远山一抹(永不可及)+ 顶部题诗字影
            for i = 0, 3 do
                local bx = W(0.08 + i * 0.24)
                local bw = W(0.26)
                local bh = H(0.030 + hash01(i * 9.1) * 0.022)
                local by = H(0.300)
                fillPoly({ { bx, by }, { bx + bw * 0.45, by - bh }, { bx + bw, by } }, colorRGBA(currentLevel.wash, 44 + hash01(i * 7) * 14))
            end
            for i = 1, 64 do
                local cx2 = W(0.05 + hash01(i * 13.1) * 0.62)
                local cy2 = H(0.030 + hash01(i * 17.9) * 0.075)
                drawInkBleed(cx2, cy2, 4 + hash01(i * 23) * 6, 6 + hash01(i * 29) * 8, currentLevel.ink, 26 + hash01(i * 37) * 26, i * 5.3, 2)
            end
        elseif currentLevel.id == "bada_lotus" then
            -- 左侧草书题诗列影 + 鉴藏小印
            for col = 0, 1 do
                local colX = W(0.095 + col * 0.035)
                for k = 0, 17 do
                    local cy2 = H(0.360 + k * 0.019)
                    local seed = col * 71.3 + k * 13.9
                    drawInkBleed(colX + (hash01(seed) - 0.5) * 8, cy2, 5 + hash01(seed + 3) * 7, 6 + hash01(seed + 7) * 7, currentLevel.ink, 30 + hash01(seed + 11) * 30, seed, 2)
                end
            end
            for _, sl in ipairs({ { 0.060, 0.940 }, { 0.130, 0.945 }, { 0.880, 0.945 }, { 0.930, 0.940 } }) do
                drawRect(W(sl[1]), H(sl[2]), 26, 26, 0, rgba(186, 72, 48, 40))
            end
        elseif currentLevel.id == "plum_xiyan" then'''
s = s.replace(old, extra)
wr(p, s)
print('60 ok')

# ---------- 70 decor + blooms ----------
p = 'scripts/src/70_entities_targets_render.lua'
s = rd(p)
# decor: 在 xuwei 装饰块结尾(其 end 之后)追加三关装饰
anchor = '''    if currentLevel.id == "wentong_zhu" then'''
assert anchor in s
decor = '''    if currentLevel.id == "fuchun" then
        -- 披麻皴:沿山脊向下披出长弧皴线;树冠横点;汀渚苇点
        for _, rid in ipairs({ "fc_ridge_main", "fc_ridge_mid", "fc_foot", "fc_shore", "fc_spur" }) do
            local list = branchGroups[rid]
            if list then
                for i = 2, #list - 1, 3 do
                    local n = list[i]
                    local seed = i * 23.7 + n.x * 0.009
                    for k = 0, 1 do
                        local a = math.pi * 0.5 + (hash01(seed + k * 7) - 0.5) * 0.7
                        local ln = 26 + hash01(seed + k * 11) * 52
                        local ex = n.x + math.cos(a) * ln
                        local ey = n.y + n.r + math.sin(a) * ln * 0.9
                        strokeLine(n.x + (hash01(seed + k * 3) - 0.5) * n.r, n.y + n.r * 0.6, ex, ey, 0.9, colorRGBA(currentLevel.ink, 34 + hash01(seed + k * 13) * 30))
                    end
                end
            end
        end
        for t = 1, 8 do
            local list = branchGroups["fc_tree" .. t]
            if list then
                local tip = list[#list]
                local seed = t * 91.3
                for k = 1, 7 do
                    local ox = (hash01(seed + k * 7) - 0.5) * 64
                    local oy = -8 - hash01(seed + k * 11) * 56
                    drawRotEllipse(tip.x + ox, tip.y + oy, 13 + hash01(seed + k * 13) * 8, 3.6, (hash01(seed + k * 17) - 0.5) * 0.3, colorRGBA(currentLevel.ink, 140 + hash01(seed + k * 19) * 80))
                end
            end
        end
    elseif currentLevel.id == "nizan" then
        -- 冠层横点叶(参差浓淡)+ 坡石折带皴 + 苔点
        local cl = branchGroups.nz_canopy
        if cl then
            for i = 1, #cl, 2 do
                local n = cl[i]
                local seed = i * 17.3 + n.x * 0.01
                for k = 1, 3 do
                    drawRotEllipse(n.x + (hash01(seed + k * 7) - 0.5) * 30, n.y + (hash01(seed + k * 11) - 0.5) * 34 - 8,
                        11 + hash01(seed + k * 13) * 7, 3.0, (hash01(seed + k * 17) - 0.5) * 0.24,
                        colorRGBA(currentLevel.ink, 96 + hash01(seed + k * 19) * 96))
                end
            end
        end
        for _, sid in ipairs({ "nz_slope_front", "nz_slope_back" }) do
            local list = branchGroups[sid]
            if list then
                for i = 3, #list - 2, 5 do
                    local n = list[i]
                    local seed = i * 31.7 + n.x * 0.008
                    strokeLine(n.x - 26, n.y + n.r * 0.7, n.x + 20, n.y + n.r * 0.7 + 3, 1.3, colorRGBA(currentLevel.ink, 70))
                    strokeLine(n.x + 20, n.y + n.r * 0.7 + 3, n.x + 30, n.y + n.r * 0.7 + 16, 1.1, colorRGBA(currentLevel.ink, 56))
                    if hash01(seed) > 0.5 then
                        drawCircle(n.x + (hash01(seed + 3) - 0.5) * 40, n.y - n.r * 0.5, 2.4, colorRGBA(currentLevel.ink, 150))
                    end
                end
            end
        end
    elseif currentLevel.id == "bada_lotus" then
        -- 泼墨大叶(叶面浓墨多层 + 放射叶脉);茎上刺点;残叶白描圈
        for _, lid in ipairs({ "bd_leaf_top", "bd_leaf_mid" }) do
            local list = branchGroups[lid]
            if list then
                for i = 2, #list - 1, 4 do
                    local n = list[i]
                    local seed = i * 27.9 + n.x * 0.01
                    drawInkBleed(n.x, n.y + 4, n.r * (2.0 + hash01(seed) * 1.1), n.r * (1.1 + hash01(seed + 3) * 0.6), currentLevel.ink, 64 + hash01(seed + 7) * 40, seed, 3)
                end
                local mid = list[math.floor(#list / 2)]
                for k = 0, 8 do
                    local a = math.pi * (0.15 + 0.7 * k / 8)
                    strokeLine(mid.x, mid.y, mid.x + math.cos(a) * 70, mid.y + math.sin(a) * 36, 1.1, colorRGBA(currentLevel.ink, 70))
                end
            end
        end
        for _, sid in ipairs({ "bd_stem1", "bd_stem2", "bd_stem3", "bd_stem_broken" }) do
            local list = branchGroups[sid]
            if list then
                for i = 3, #list - 2, 6 do
                    local n = list[i]
                    local seed = i * 19.1 + n.y * 0.01
                    strokeLine(n.x + n.r, n.y, n.x + n.r + 4 + hash01(seed) * 3, n.y - 2, 1.0, colorRGBA(currentLevel.ink, 110))
                end
            end
        end
    end
    if currentLevel.id == "wentong_zhu" then'''
s = s.replace(anchor, decor, 1)
# blooms
anchor2 = '''        elseif b.kind == "wentong_zhu" then'''
assert anchor2 in s
blooms = '''        elseif b.kind == "fuchun" then
            -- 墨点树丛迸发(横点层层堆出)
            local pr2 = clamp(b.progress or 1, 0, 1)
            for i = 1, 11 do
                local seed = b.x * 0.013 + i * 47
                local a = hash01(seed) * math.pi * 2
                local d = (6 + hash01(seed + 3) * 34) * pr2
                drawRotEllipse(math.cos(a) * d, math.sin(a) * d * 0.7, 12 + hash01(seed + 7) * 8, 3.4, (hash01(seed + 11) - 0.5) * 0.3, colorRGBA(currentLevel.ink, (120 + hash01(seed + 13) * 110) * pr2))
            end
            drawInkSpeckles(-30, -30, 60, 60, currentLevel.ink, 70 * pr2, b.x * 0.01, 6)
        elseif b.kind == "nizan" then
            -- 疏叶飘散:几片横点叶向上散开,余皆空寂
            local pr2 = clamp(b.progress or 1, 0, 1)
            for i = 1, 6 do
                local seed = b.x * 0.011 + i * 53
                local a = -math.pi * 0.5 + (hash01(seed) - 0.5) * 1.6
                local d = (10 + hash01(seed + 3) * 40) * pr2
                drawRotEllipse(math.cos(a) * d, math.sin(a) * d, 11 + hash01(seed + 7) * 6, 2.8, (hash01(seed + 11) - 0.5) * 0.4, colorRGBA(currentLevel.ink, (110 + hash01(seed + 13) * 90) * pr2))
            end
        elseif b.kind == "bada_lotus" then
            -- 白荷绽放:淡墨勾大瓣 + 莲蓬墨点
            local pr2 = clamp(b.progress or 1, 0, 1)
            drawFlowerBloom(b, {
                outerA = rgba(226, 220, 208, 235), outerB = rgba(202, 196, 184, 235),
                inner = rgba(236, 230, 218, 235), outerLen = 46, outerWidth = 26,
                innerLen = 27, innerWidth = 15, darkKnots = true,
            })
            drawCircle(0, 0, 9 * pr2, rgba(86, 80, 70, 220))
            for i = 0, 6 do
                local a = i / 7 * math.pi * 2
                drawCircle(math.cos(a) * 5.2 * pr2, math.sin(a) * 5.2 * pr2, 1.6, rgba(40, 36, 32, 235))
            end
        elseif b.kind == "wentong_zhu" then'''
s = s.replace(anchor2, blooms, 1)
wr(p, s)
print('70 ok')

# ---------- 90 seals ----------
p = 'scripts/src/90_world_seal_runtime.lua'
s = rd(p)
old = '''    elseif currentLevel.id == "xuwei_grape" then'''
assert old in s
s = s.replace(old, '''    elseif currentLevel.id == "fuchun" then
        return { x = 0.03, y = 0.06, size = 100, primaryA = "富春", primaryB = "大岭", vertical = "富春山居", paper = C(214, 206, 176), wear = 80 }
    elseif currentLevel.id == "nizan" then
        return { x = 0.86, y = 0.62, size = 100, primaryA = "云林", primaryB = "清閟", paper = C(204, 200, 186), wear = 70 }
    elseif currentLevel.id == "bada_lotus" then
        return { x = 0.84, y = 0.06, size = 100, primaryA = "八大", primaryB = "山人", paper = C(212, 206, 194), wear = 90 }
    elseif currentLevel.id == "xuwei_grape" then''', 1)
wr(p, s)
print('90 ok')
