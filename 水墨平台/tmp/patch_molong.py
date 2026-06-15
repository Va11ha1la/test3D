# -*- coding: utf-8 -*-
"""新增第 17 关「墨龙行雨」(陈容《九龙图》意象):活的龙身平台 + 踏云 + 碎珠雷光"""
import io

def rd(p): return io.open(p, encoding='utf-8').read()
def wr(p, s): io.open(p, 'w', encoding='utf-8').write(s)

# ---------- 00 LEVELS ----------
p = 'scripts/src/00_state_levels_keys.lua'
s = rd(p)
i = s.find('id = "xuwei_grape"')
j = s.find('    },', i) + len('    },\n')
entry = '''    {
        id = "molong",
        name = "墨龙行雨",
        title = "意象复刻 - 陈容《九龙图》墨龙",
        seal = "龙",
        note = "墨龙是一条活的平台：龙身游波起伏会驮着你、抛起你；踏云逐珠，冲刺碎珠可炸雷光。",
        wmul = 3.5,
        hmul = 2.2,
        paper = C(166, 158, 140),
        paper2 = C(138, 130, 112),
        ink = C(22, 20, 18),
        wash = C(82, 78, 70),
        accent = C(120, 96, 52),
        bloom = C(216, 174, 64),
        water = C(110, 112, 106),
        radius = 11,
        gravity = 0.52,
        jumpForce = -15.5,
        dashSpeed = 19,
        friction = 0.86,
    },
'''
s = s[:j] + entry + s[j:]
wr(p, s)
print('00 ok')

# ---------- 30 generator ----------
p = 'scripts/src/30_level_generation.lua'
s = rd(p)
gen = '''
function generateMolong()
    -- 第17关:意象复刻 - 陈容《九龙图》墨龙(波士顿美术馆)
    -- 龙身三起三伏横贯全卷,是一条"活"的平台(运行时整条做行波起伏);
    -- 龙首在右,角可攀,四爪探波;云团可踏;龙珠悬于云上与龙身。
    createBranchPath({
        { 0.040, 0.600, 14 }, { 0.085, 0.520, 18 }, { 0.130, 0.450, 22 },
        { 0.180, 0.420, 26 }, { 0.235, 0.460, 29 }, { 0.285, 0.550, 31 },
        { 0.330, 0.660, 32 }, { 0.385, 0.730, 32 }, { 0.440, 0.740, 32 },
        { 0.495, 0.680, 31 }, { 0.545, 0.570, 29 }, { 0.595, 0.460, 27 },
        { 0.645, 0.385, 25 }, { 0.700, 0.360, 23 }, { 0.755, 0.400, 21 },
        { 0.805, 0.470, 19 }, { 0.850, 0.520, 18 }, { 0.895, 0.520, 17 },
    }, "dragon_body", 0.08)
    createBranchPath({
        { 0.895, 0.520, 17 }, { 0.930, 0.480, 22 }, { 0.962, 0.450, 21 }, { 0.985, 0.440, 18 },
    }, "dragon_head", 0.08)
    createBranchPath({ { 0.945, 0.430, 7 }, { 0.958, 0.355, 5 }, { 0.968, 0.300, 4 } }, "dragon_horn", 0)
    createBranchPath({ { 0.235, 0.490, 9 }, { 0.245, 0.585, 7 }, { 0.252, 0.660, 5 }, { 0.247, 0.700, 4 } }, "dragon_leg1", 0)
    createBranchPath({ { 0.440, 0.770, 9 }, { 0.452, 0.860, 7 }, { 0.460, 0.920, 5 } }, "dragon_leg2", 0)
    createBranchPath({ { 0.645, 0.415, 9 }, { 0.655, 0.500, 7 }, { 0.662, 0.565, 5 }, { 0.657, 0.600, 4 } }, "dragon_leg3", 0)
    createBranchPath({ { 0.850, 0.550, 9 }, { 0.862, 0.640, 7 }, { 0.870, 0.710, 5 }, { 0.865, 0.750, 4 } }, "dragon_leg4", 0)
    for _, c in ipairs({
        { 0.10, 0.82, 210, 55, 0.0 }, { 0.27, 0.30, 190, 50, 1.3 },
        { 0.47, 0.30, 200, 52, 2.2 }, { 0.62, 0.80, 210, 55, 3.1 },
        { 0.80, 0.76, 190, 50, 4.0 }, { 0.93, 0.68, 160, 45, 5.0 },
    }) do
        cloudPlatforms[#cloudPlatforms + 1] = { x = W(c[1]), y = H(c[2]), rx = c[3], ry = c[4], bob = c[5] }
    end
    addTarget(W(0.27), H(0.165), 42)
    addTarget(W(0.58), H(0.150), 42)
    addTarget(W(0.74), H(0.620), 40)
    for _, p in ipairs({
        { "dragon_body", 0.30 }, { "dragon_body", 0.55 }, { "dragon_body", 0.80 },
        { "dragon_head", 0.70 },
    }) do addTargetOnBranch(p[1], p[2], 40) end
end
'''
s = s.rstrip() + '\n' + gen
wr(p, s)
print('30 ok')

# ---------- 40 dispatch + spawn + 运行时动画/云台 ----------
p = 'scripts/src/40_gameplay_targets.lua'
s = rd(p)
old = '    elseif currentLevel.id == "xuwei_grape" then generateXuweiGrape()\n'
assert old in s
s = s.replace(old, old + '    elseif currentLevel.id == "molong" then generateMolong()\n')
old = '''    elseif currentLevel.id == "xuwei_grape" then
        local ns = branchGroups.xw_vine or {}
        local safe = ns[8]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.92), H(0.26) end
        player.facingRight = false
'''
assert old in s
s = s.replace(old, old + '''    elseif currentLevel.id == "molong" then
        local ns = branchGroups.dragon_body or {}
        local safe = ns[math.max(1, math.floor(#ns * 0.45))]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.40), H(0.65) end
        player.facingRight = true
''')
# 运行时:龙身行波 + 云台站立(插入 updateSpecialBeforeMovement 的 bamboo 分支前)
old = '''    if currentLevel.id == "bamboo" then
        local x1, x2 = W(0.32), W(0.80)'''
assert old in s
s = s.replace(old, '''    if currentLevel.id == "molong" then
        -- 墨龙行波:整条龙身按行波起伏,玩家被驮起/抛出;龙首、角、爪随波同摆
        local ph = elapsed * 3.0
        local function wob(t) return math.sin(ph - t * 14.0) * 26 end
        local body = branchGroups.dragon_body
        if body then
            for _, n in ipairs(body) do n.y = n.baseY + wob(n.t) end
            refreshBranchNormalsForCurrentPose(body)
        end
        local hw = wob(1)
        for _, bid in ipairs({ "dragon_head", "dragon_horn" }) do
            local l = branchGroups[bid]
            if l then for _, n in ipairs(l) do n.y = n.baseY + hw end end
        end
        local legRoots = { 0.22, 0.42, 0.62, 0.82 }
        for i = 1, 4 do
            local l = branchGroups["dragon_leg" .. i]
            if l then
                local o = wob(legRoots[i])
                for _, n in ipairs(l) do n.y = n.baseY + o end
            end
        end
        for _, t in ipairs(targets) do bindItemToBranch(t) end
        for _, b in ipairs(blooms) do bindItemToBranch(b) end
        for _, cp in ipairs(cloudPlatforms) do
            local cy = cp.y + math.sin(elapsed * 1.2 + cp.bob) * 8
            if math.abs(player.x - cp.x) < cp.rx and math.abs((player.y + player.radius) - cy) < cp.ry * 0.75 and player.vy >= 0 then
                player.y = cy - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
            end
        end
        return
    end

    if currentLevel.id == "bamboo" then
        local x1, x2 = W(0.32), W(0.80)''')
wr(p, s)
print('40 ok')

# ---------- 60 背景:风雷烟云 ----------
p = 'scripts/src/60_background_render.lua'
s = rd(p)
old = '''    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" then'''
assert old in s
s = s.replace(old, '''    elseif currentLevel.id == "molong" then
        -- 风雷烟云:旋涡云带横贯,斜雨如丝,远雷淡痕,下缘云涛
        for band = 0, 2 do
            local by = H(0.16 + band * 0.30)
            for i = 1, 16 do
                local seed = band * 97.7 + i * 13.1
                local cx2 = hash01(seed) * worldW
                local cy2 = by + (hash01(seed + 3) - 0.5) * H(0.14)
                drawRotEllipse(cx2, cy2, 160 + hash01(seed + 7) * 240, 26 + hash01(seed + 11) * 40,
                    (hash01(seed + 13) - 0.5) * 0.3, colorRGBA(currentLevel.paper2, 22 + hash01(seed + 17) * 26))
            end
            for i = 1, 10 do
                local seed = band * 71.3 + i * 17.9
                local cx2 = hash01(seed) * worldW
                local cy2 = by + (hash01(seed + 5) - 0.5) * H(0.12)
                local r0 = 36 + hash01(seed + 7) * 60
                for k = 0, 5 do
                    local a1 = k * 1.05 + hash01(seed + k) * 0.4
                    strokeLine(cx2 + math.cos(a1) * r0, cy2 + math.sin(a1) * r0 * 0.5,
                        cx2 + math.cos(a1 + 0.8) * r0 * 0.74, cy2 + math.sin(a1 + 0.8) * r0 * 0.38,
                        1.1, colorRGBA(currentLevel.wash, 30 + hash01(seed + k + 9) * 22))
                end
            end
        end
        for i = 1, 130 do
            local seed = i * 23.3
            local x = hash01(seed) * worldW
            local y = hash01(seed + 3) * worldH
            local ln = 30 + hash01(seed + 7) * 60
            strokeLine(x, y, x - ln * 0.26, y + ln, 0.7, colorRGBA(currentLevel.wash, 10 + hash01(seed + 11) * 14))
        end
        for i = 0, 1 do
            local sx = W(0.30 + i * 0.40) + hash01(i * 7.1) * W(0.06)
            local sy = H(0.04)
            local px, py = sx, sy
            for k = 1, 4 do
                local nx2 = px + (hash01(i * 31 + k * 7) - 0.5) * 90 - 20
                local ny2 = py + H(0.07 + hash01(i * 37 + k * 11) * 0.05)
                strokeLine(px, py, nx2, ny2, 1.6, rgba(232, 222, 188, 34))
                px, py = nx2, ny2
            end
        end
        for i = 1, 22 do
            local seed = i * 31.7
            local cx2 = hash01(seed) * worldW
            local cy2 = H(0.93 + hash01(seed + 3) * 0.05)
            strokeQuad(cx2 - 70, cy2, cx2, cy2 - 34 - hash01(seed + 7) * 26, cx2 + 70, cy2, 2.2, colorRGBA(currentLevel.wash, 60))
        end
    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" then''')
wr(p, s)
print('60 ok')

# ---------- 70: 龙体细节 + 龙珠目标形 + 雷光绽放 ----------
p = 'scripts/src/70_entities_targets_render.lua'
s = rd(p)
anchor = '''    if currentLevel.id == "wentong_zhu" then'''
assert anchor in s
decor = '''    if currentLevel.id == "molong" then
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
    end
    if currentLevel.id == "wentong_zhu" then'''
s = s.replace(anchor, decor, 1)
# 龙珠目标形
old = '''            elseif currentLevel.id == "plum_master" then
                drawMasterPlumBudTarget(t, r)'''
assert old in s
s = s.replace(old, '''            elseif currentLevel.id == "plum_master" then
                drawMasterPlumBudTarget(t, r)
            elseif currentLevel.id == "molong" then
                drawCircle(t.x, t.y, r * 1.18, rgba(216, 174, 64, 46))
                drawCircle(t.x, t.y, r * 0.82, rgba(216, 174, 64, 235))
                nvgBeginPath(vg)
                nvgCircle(vg, t.x, t.y, r * 0.82)
                nvgStrokeWidth(vg, 2.2)
                nvgStrokeColor(vg, colorRGBA(currentLevel.ink, 200))
                nvgStroke(vg)
                drawCircle(t.x - r * 0.26, t.y - r * 0.30, r * 0.18, rgba(248, 240, 214, 220))
                for k = 0, 3 do
                    local a = elapsed * 1.4 + k * math.pi * 0.5
                    strokeQuad(t.x + math.cos(a) * r, t.y + math.sin(a) * r,
                        t.x + math.cos(a + 0.5) * r * 1.5, t.y + math.sin(a + 0.5) * r * 1.5,
                        t.x + math.cos(a + 0.9) * r * 1.9, t.y + math.sin(a + 0.9) * r * 1.9,
                        1.4, rgba(216, 174, 64, 110))
                end''', 1)
# 雷光绽放
anchor2 = '''        elseif b.kind == "wentong_zhu" then'''
assert anchor2 in s
s = s.replace(anchor2, '''        elseif b.kind == "molong" then
            -- 碎珠雷光:金墨电光放射 + 墨环扩散
            local pr2 = clamp(b.progress or 1, 0, 1)
            for i = 0, 7 do
                local seed = b.x * 0.013 + i * 41
                local a = i / 8 * math.pi * 2 + hash01(seed) * 0.4
                local r1 = 16 + 52 * pr2
                local mx2 = math.cos(a + 0.32) * r1 * 0.55
                local my2 = math.sin(a + 0.32) * r1 * 0.55
                local ex2 = math.cos(a) * r1 * (0.9 + hash01(seed + 7) * 0.5)
                local ey2 = math.sin(a) * r1 * (0.9 + hash01(seed + 7) * 0.5)
                strokeLine(0, 0, mx2, my2, 2.4, rgba(216, 174, 64, 235 * (1.2 - pr2)))
                strokeLine(mx2, my2, ex2, ey2, 1.7, rgba(22, 20, 18, 215 * (1.2 - pr2)))
            end
            nvgBeginPath(vg)
            nvgCircle(vg, 0, 0, 18 + 64 * pr2)
            nvgStrokeWidth(vg, 2.6 * (1.1 - pr2))
            nvgStrokeColor(vg, rgba(216, 174, 64, 190 * (1.05 - pr2)))
            nvgStroke(vg)
            drawInkSpeckles(-30, -30, 60, 60, currentLevel.ink, 90 * (1.1 - pr2), b.x * 0.01, 7)
        elseif b.kind == "wentong_zhu" then''', 1)
wr(p, s)
print('70 ok')

# ---------- 90 seal ----------
p = 'scripts/src/90_world_seal_runtime.lua'
s = rd(p)
old = '''    elseif currentLevel.id == "xuwei_grape" then'''
assert old in s
s = s.replace(old, '''    elseif currentLevel.id == "molong" then
        return { x = 0.03, y = 0.08, size = 110, primaryA = "九龙", primaryB = "行雨", vertical = "神龙见首", paper = C(166, 158, 140), wear = 90 }
    elseif currentLevel.id == "xuwei_grape" then''', 1)
wr(p, s)
print('90 ok')

# ---------- checker ----------
p = 'tools/reachability_check.py'
s = rd(p)
gen = '''
def gen_molong(geo):
    paths = [
        ([(0.040, 0.600, 14), (0.085, 0.520, 18), (0.130, 0.450, 22), (0.180, 0.420, 26), (0.235, 0.460, 29),
          (0.285, 0.550, 31), (0.330, 0.660, 32), (0.385, 0.730, 32), (0.440, 0.740, 32), (0.495, 0.680, 31),
          (0.545, 0.570, 29), (0.595, 0.460, 27), (0.645, 0.385, 25), (0.700, 0.360, 23), (0.755, 0.400, 21),
          (0.805, 0.470, 19), (0.850, 0.520, 18), (0.895, 0.520, 17)], "dragon_body", 0.08),
        ([(0.895, 0.520, 17), (0.930, 0.480, 22), (0.962, 0.450, 21), (0.985, 0.440, 18)], "dragon_head", 0.08),
        ([(0.945, 0.430, 7), (0.958, 0.355, 5), (0.968, 0.300, 4)], "dragon_horn", 0),
        ([(0.235, 0.490, 9), (0.245, 0.585, 7), (0.252, 0.660, 5), (0.247, 0.700, 4)], "dragon_leg1", 0),
        ([(0.440, 0.770, 9), (0.452, 0.860, 7), (0.460, 0.920, 5)], "dragon_leg2", 0),
        ([(0.645, 0.415, 9), (0.655, 0.500, 7), (0.662, 0.565, 5), (0.657, 0.600, 4)], "dragon_leg3", 0),
        ([(0.850, 0.550, 9), (0.862, 0.640, 7), (0.870, 0.710, 5), (0.865, 0.750, 4)], "dragon_leg4", 0),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for cx, cy, rx in ((0.10, 0.82, 210), (0.27, 0.30, 190), (0.47, 0.30, 200), (0.62, 0.80, 210),
                       (0.80, 0.76, 190), (0.93, 0.68, 160)):
        X, Y = geo.W(cx), geo.H(cy)
        for sx in range(int(X - rx) + 10, int(X + rx) - 9, 40):
            geo.stand.append((sx, Y - PR))
    geo.add_target(geo.W(0.27), geo.H(0.165), 42, "pearl")
    geo.add_target(geo.W(0.58), geo.H(0.150), 42, "pearl")
    geo.add_target(geo.W(0.74), geo.H(0.620), 40, "pearl")
    for bid, p in (("dragon_body", .30), ("dragon_body", .55), ("dragon_body", .80), ("dragon_head", .70)):
        geo.add_target_on_branch(bid, p, 40)


'''
anchor = '# ---------------------------------------------------------------- 主流程'
assert anchor in s
s = s.replace(anchor, gen + anchor, 1)
old = '    (16, "墨葡萄 xuwei_grape", 1.6, 7.49, (0.52, -15.5, 19, 0.86, 1.6), gen_xuwei, 11.5, 0.95),\n'
assert old in s
s = s.replace(old, old + '    (17, "墨龙行雨 molong", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_molong, 11.5, 0.95),\n')
wr(p, s)
print('checker ok')
