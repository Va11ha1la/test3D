-- Source chunk for the Pine InkLab level.
-- It uses raster brush stamps as a material layer over the existing procedural level.

inkLabImageNames = {
    dry = "pine_dry_brush_01.png",
    -- Round 01 dry-branch assets are style templates and first in-engine probes.
    -- Later passes should add context-specific variants instead of repeating only these.
    dryNode = "pine_dry_branch_02_alpha.png",
    dryMain = "pine_dry_branch_03_alpha.png",
    dryBroken = "pine_dry_branch_04_alpha.png",
    drySweep = "pine_dry_branch_06_alpha.png",
    branchMain = "pine_branch_main_long_01.png",
    branchBroken = "pine_branch_broken_long_01.png",
    branchNode = "pine_branch_node_knot_01.png",
    branchTip = "pine_branch_tip_sweep_01.png",
    branchMirror = "pine_branch_mirror_scurve_01.png",
    branchMainLight = "pine_branch_main_long_light_01.png",
    branchBrokenLight = "pine_branch_broken_long_light_01.png",
    branchNodeLight = "pine_branch_node_knot_light_01.png",
    branchTipLight = "pine_branch_tip_sweep_light_01.png",
    branchMirrorLight = "pine_branch_mirror_scurve_light_01.png",
    bleed = "pine_ink_bleed_01.png",
    needle = "pine_needle_fan_01.png",
    paper = "paper_grain_01.png",
    bristleTip = "ink_bristle_footprint_01.png",
    bristleWetA = "ink_bristle_wet_01.png",
    bristleWetB = "ink_bristle_wet_02.png",
    worldStrokes = "pine_inklab_world_strokes.png",
}
inkLabImages = nil
inkLabImagesTried = false
inkLabDryMainStamps = { "branchMain", "branchMirror", "dryMain", "dry" }
inkLabDryBrokenStamps = { "branchBroken", "dryBroken", "dry" }
inkLabDryNodeStamps = { "branchNode", "dryNode", "dry" }
inkLabDrySweepStamps = { "branchTip", "drySweep", "dryBroken", "dry" }
inkLabDryMainLightStamps = { "branchMainLight", "branchMirrorLight" }
inkLabDryBrokenLightStamps = { "branchBrokenLight" }
inkLabDryNodeLightStamps = { "branchNodeLight" }
inkLabDrySweepLightStamps = { "branchTipLight" }
inkLabSweepCoreStamps = { "branchMain", "branchMirror" }
inkLabSweepDryStamps = { "branchBroken", "dryBroken", "dryMain" }
inkLabSweepEdgeStamps = { "branchMainLight", "branchBrokenLight", "branchMirrorLight" }
inkLabWetBristleStamps = { "bristleWetA", "bristleWetB", "bristleTip" }

function currentLevelIsInkLab()
    return currentLevel ~= nil and currentLevel.variant == "ink_atlas"
end

function tryLoadInkLabImages()
    if inkLabImagesTried or vg == nil then return end
    inkLabImagesTried = true
    inkLabImages = {}
end

function inkLabLoadImage(name)
    tryLoadInkLabImages()
    if not inkLabImages or not inkLabImageNames[name] then return nil end
    local cached = inkLabImages[name]
    if cached ~= nil then return cached end
    if type(nvgCreateImage) ~= "function" then
        inkLabImages[name] = false
        return nil
    end
    local file = inkLabImageNames[name]
    local paths = {
        "assets/ink_atlas/" .. file,
        "ink_atlas/" .. file,
        file,
    }
    for _, path in ipairs(paths) do
        local ok, img = pcall(nvgCreateImage, vg, path, 0)
        if ok and img and img > 0 then
            inkLabImages[name] = img
            return img
        end
    end
    inkLabImages[name] = false
    return nil
end

function inkLabIsVisible(x, y, pad)
    pad = pad or 220
    return not (x + pad < cameraX or x - pad > cameraX + DESIGN_W or y + pad < cameraY or y - pad > cameraY + DESIGN_H)
end

function inkLabMeasureBranch(list)
    if not list or #list < 1 then return nil end
    if list._inkLabMeasureCount == #list and list._inkLabLen then return list end
    local len = 0
    local avgR = 0
    local minX, minY = list[1].x, list[1].y
    local maxX, maxY = minX, minY
    for i = 1, #list do
        local n = list[i]
        avgR = avgR + n.r
        if n.x - n.r < minX then minX = n.x - n.r end
        if n.x + n.r > maxX then maxX = n.x + n.r end
        if n.y - n.r < minY then minY = n.y - n.r end
        if n.y + n.r > maxY then maxY = n.y + n.r end
        if i < #list then
            local b = list[i + 1]
            len = len + dist2(b.x - n.x, b.y - n.y)
        end
    end
    list._inkLabMeasureCount = #list
    list._inkLabLen = len
    list._inkLabAvgR = avgR / #list
    list._inkLabMinX, list._inkLabMinY = minX, minY
    list._inkLabMaxX, list._inkLabMaxY = maxX, maxY
    return list
end

function inkLabBranchListVisible(list, pad)
    local m = inkLabMeasureBranch(list)
    if not m then return false end
    pad = pad or 260
    return not (
        m._inkLabMaxX + pad < cameraX or
        m._inkLabMinX - pad > cameraX + DESIGN_W or
        m._inkLabMaxY + pad < cameraY or
        m._inkLabMinY - pad > cameraY + DESIGN_H
    )
end

function drawInkLabStamp(name, x, y, w, h, angle, alpha)
    local img = inkLabLoadImage(name)
    if not img then return false end
    if type(nvgImagePattern) ~= "function" or type(nvgFillPaint) ~= "function" then return false end
    if not inkLabIsVisible(x, y, math.max(w, h) * 0.65) then return true end
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, angle or 0)
    local ok, paint = pcall(nvgImagePattern, vg, -w * 0.5, -h * 0.5, w, h, 0, img, alpha or 0.5)
    if ok and paint then
        nvgBeginPath(vg)
        nvgRect(vg, -w * 0.5, -h * 0.5, w, h)
        nvgFillPaint(vg, paint)
        nvgFill(vg)
    end
    nvgRestore(vg)
    return ok and paint ~= nil
end

function drawInkLabStampFirst(names, x, y, w, h, angle, alpha)
    for _, name in ipairs(names) do
        if drawInkLabStamp(name, x, y, w, h, angle, alpha) then return true end
    end
    return false
end

function drawInkLabStampChoice(names, seed, x, y, w, h, angle, alpha)
    local idx = 1 + math.floor(hash01(seed or 0) * #names)
    if idx < 1 then idx = 1 end
    if idx > #names then idx = #names end
    if drawInkLabStamp(names[idx], x, y, w, h, angle, alpha) then return true end
    return drawInkLabStampFirst(names, x, y, w, h, angle, alpha)
end

function drawInkLabWorldStrokeLayer()
    if not currentLevelIsInkLab() then return false end
    local img = inkLabLoadImage("worldStrokes")
    if not img then return false end
    if type(nvgImagePattern) ~= "function" or type(nvgFillPaint) ~= "function" then return false end
    local ok, paint = pcall(nvgImagePattern, vg, 0, 0, worldW, worldH, 0, img, 0.92)
    if not ok or not paint then return false end
    nvgBeginPath(vg)
    nvgRect(vg, cameraX - 4, cameraY - 4, DESIGN_W + 8, DESIGN_H + 8)
    nvgFillPaint(vg, paint)
    nvgFill(vg)
    return true
end

function drawInkLabBranchGrain(names, lightNames, seed, x, y, nx, ny, r, w, h, angle)
    local darkAlpha = 0.13 + hash01(seed + 23) * 0.055
    drawInkLabStampChoice(names, seed, x, y, w, h, angle, darkAlpha)

    local passCount = 3
    if r > 20 then passCount = 4 end
    for pass = 1, passCount do
        local s = seed + pass * 97
        local lane = (pass - (passCount + 1) * 0.5) / math.max(1, (passCount - 1) * 0.5)
        local offset = lane * r * (0.42 + hash01(s + 3) * 0.18)
        local jitter = (hash01(s + 5) - 0.5) * r * 0.16
        local px = x + nx * (offset + jitter)
        local py = y + ny * (offset + jitter)
        local lw = w * (0.62 + hash01(s + 7) * 0.34)
        local lh = math.max(7, h * (0.24 + hash01(s + 11) * 0.16))
        local la = 0.105 + hash01(s + 13) * 0.075
        drawInkLabStampChoice(lightNames, s, px, py, lw, lh, angle + (hash01(s + 17) - 0.5) * 0.035, la)
    end

    if hash01(seed + 29) > 0.50 then
        local side = hash01(seed + 31) > 0.5 and 1 or -1
        drawInkLabStampFirst(inkLabDryBrokenStamps, x + nx * r * side * 0.28, y + ny * r * side * 0.28, w * 0.58, math.max(9, h * 0.38), angle + (hash01(seed + 37) - 0.5) * 0.07, 0.07)
        drawInkLabStampFirst(inkLabDryBrokenLightStamps, x + nx * r * side * 0.30, y + ny * r * side * 0.30, w * 0.46, math.max(6, h * 0.22), angle + (hash01(seed + 39) - 0.5) * 0.07, 0.10)
    end
end

function inkLabBranchPressure(t, seed)
    local body = 0.94 + math.sin(t * math.pi) * 0.10
    local startPress = t < 0.16 and (1.10 - t * 0.70) or 1.0
    local tipLift = t > 0.86 and (1.0 - (t - 0.86) * 1.55) or 1.0
    local pulse = 1.0 + math.sin(t * math.pi * 3.0 + seed * 0.019) * 0.08 + (hash01(seed + math.floor(t * 13) * 31) - 0.5) * 0.075
    local p = body * startPress * tipLift * pulse
    if p < 0.58 then p = 0.58 end
    if p > 1.18 then p = 1.18 end
    return p
end

function inkLabInkLoad(t, seed)
    local wave = 0.66 + math.sin(t * math.pi * 2.0 + seed * 0.031) * 0.20 + math.sin(t * math.pi * 5.0 + seed * 0.013) * 0.11
    local pocket = hash01(seed + math.floor(t * 9) * 97)
    if pocket > 0.66 then wave = wave * 0.48 end
    if pocket < 0.14 then wave = wave * 1.16 end
    if t > 0.82 then wave = wave * (1.0 - (t - 0.82) * 0.80) end
    if wave < 0.24 then wave = 0.24 end
    if wave > 1.08 then wave = 1.08 end
    return wave
end

function inkLabDryness(t, seed)
    local dry = 0.38 + math.sin(t * math.pi * 2.7 + seed * 0.021) * 0.20 + math.sin(t * math.pi * 7.0 + seed * 0.011) * 0.12
    local pocket = hash01(seed + math.floor(t * 12) * 131)
    if pocket > 0.67 then dry = dry + 0.28 end
    if pocket < 0.16 then dry = dry - 0.16 end
    if t < 0.12 then dry = dry - (0.12 - t) * 0.55 end
    if t > 0.72 then dry = dry + (t - 0.72) * 0.95 end
    if dry < 0.08 then dry = 0.08 end
    if dry > 0.96 then dry = 0.96 end
    return dry
end

function drawInkLabOneStrokeBody(list, tint, alpha, seed, scale, fillTint)
    if not list or #list < 2 then return end
    local count = #list
    local stride = math.max(1, math.floor(count / 46))
    local first, second = list[1], list[2]
    local prevTail, tail = list[count - 1], list[count]
    local startDx, startDy = second.x - first.x, second.y - first.y
    local tailDx, tailDy = tail.x - prevTail.x, tail.y - prevTail.y
    local startLen = math.max(1, dist2(startDx, startDy))
    local tailLen = math.max(1, dist2(tailDx, tailDy))
    local startTx, startTy = startDx / startLen, startDy / startLen
    local tailTx, tailTy = tailDx / tailLen, tailDy / tailLen
    local startX = first.x - startTx * first.r * 1.35
    local startY = first.y - startTy * first.r * 1.35
    local tailX = tail.x + tailTx * tail.r * 1.75
    local tailY = tail.y + tailTy * tail.r * 1.75
    local startSide = first.r * (scale or 1.0) * 0.26
    local tailSide = tail.r * (scale or 1.0) * 0.16
    nvgBeginPath(vg)
    nvgMoveTo(vg, startX + first.normX * startSide, startY + first.normY * startSide)
    for i = 1, count, stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local rough = 1.0 + (hash01(seed + i * 19) - 0.5) * 0.018
        local side = n.r * inkLabBranchPressure(t, seed) * (scale or 1.0) * rough
        local x = n.x + n.normX * side
        local y = n.y + n.normY * side
        nvgLineTo(vg, x, y)
    end
    if ((count - 1) % stride) ~= 0 then
        local n = tail
        local rough = 1.0 + (hash01(seed + count * 19) - 0.5) * 0.018
        local side = n.r * inkLabBranchPressure(1, seed) * (scale or 1.0) * rough
        nvgLineTo(vg, n.x + n.normX * side, n.y + n.normY * side)
    end
    nvgLineTo(vg, tailX + tail.normX * tailSide, tailY + tail.normY * tailSide)
    nvgLineTo(vg, tailX - tail.normX * tailSide, tailY - tail.normY * tailSide)
    for i = count, 1, -stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local rough = 1.0 + (hash01(seed + i * 23 + 7) - 0.5) * 0.022
        local side = n.r * inkLabBranchPressure(t, seed + 3) * (scale or 1.0) * rough
        nvgLineTo(vg, n.x - n.normX * side, n.y - n.normY * side)
    end
    nvgLineTo(vg, startX - first.normX * startSide, startY - first.normY * startSide)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(fillTint or tint, alpha))
    nvgFill(vg)
end

function drawInkLabPathStroke(list, lane, width, tint, alpha, seed, step)
    if not list or #list < 2 then return end
    local count = #list
    local stride = step or math.max(2, math.floor(count / 64))
    local startIndex = math.max(2, math.floor(count * 0.055))
    local endIndex = math.min(count - 1, math.ceil(count * 0.945))
    if endIndex <= startIndex then startIndex, endIndex = 1, count end
    nvgBeginPath(vg)
    local moved = false
    for i = startIndex, endIndex, stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local drift = math.sin(t * math.pi * 2.0 + seed * 0.037) * 0.035
        local jitter = (hash01(seed + i * 29) - 0.5) * 0.045
        local off = n.r * ((lane or 0) + drift + jitter)
        local x = n.x + n.normX * off
        local y = n.y + n.normY * off
        if not moved then
            nvgMoveTo(vg, x, y)
            moved = true
        else
            nvgLineTo(vg, x, y)
        end
    end
    local last = list[endIndex]
    local off = last.r * (lane or 0)
    nvgLineTo(vg, last.x + last.normX * off, last.y + last.normY * off)
    nvgStrokeColor(vg, colorRGBA(tint, alpha))
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

function drawInkLabWideBrushStroke(list, width, tint, alpha, seed, step)
    if not list or #list < 2 then return end
    local count = #list
    local stride = step or math.max(1, math.floor(count / 56))
    local startIndex = math.max(2, math.floor(count * 0.045))
    local endIndex = math.min(count - 1, math.ceil(count * 0.955))
    if endIndex <= startIndex then startIndex, endIndex = 1, count end
    local first = list[startIndex]
    nvgBeginPath(vg)
    nvgMoveTo(vg, first.x, first.y)
    for i = startIndex, endIndex, stride do
        local n = list[i]
        local t = (i - 1) / math.max(1, count - 1)
        local off = math.sin(t * math.pi * 2.0 + seed * 0.021) * n.r * 0.025
        nvgLineTo(vg, n.x + n.normX * off, n.y + n.normY * off)
    end
    local tail = list[endIndex]
    nvgLineTo(vg, tail.x, tail.y)
    nvgStrokeColor(vg, colorRGBA(tint, alpha))
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

function inkLabPathLength(list)
    local m = inkLabMeasureBranch(list)
    return m and m._inkLabLen or 0
end

function inkLabSampleBranch(list, t)
    local count = #list
    if count < 2 then return nil end
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    local f = 1 + t * (count - 1)
    local i = math.floor(f)
    if i >= count then i = count - 1 end
    local u = f - i
    local a, b = list[i], list[i + 1]
    local x = a.x + (b.x - a.x) * u
    local y = a.y + (b.y - a.y) * u
    local r = a.r + (b.r - a.r) * u
    local nx = a.normX + (b.normX - a.normX) * u
    local ny = a.normY + (b.normY - a.normY) * u
    local nlen = dist2(nx, ny)
    if nlen < 0.001 then nx, ny = a.normX, a.normY else nx, ny = nx / nlen, ny / nlen end
    return {
        x = x, y = y, r = r, normX = nx, normY = ny,
        angle = math.atan2(b.y - a.y, b.x - a.x),
    }
end

function drawInkLabSweepFootprint(names, seed, x, y, w, h, angle, alpha)
    local drift = (hash01(seed + 5) - 0.5) * h * 0.10
    local dx = math.cos(angle + math.pi * 0.5) * drift
    local dy = math.sin(angle + math.pi * 0.5) * drift
    return drawInkLabStampChoice(
        names,
        seed,
        x + dx,
        y + dy,
        w,
        h,
        angle + (hash01(seed + 9) - 0.5) * 0.035,
        alpha
    )
end

function inkLabAddPlannedStamp(plan, names, seed, x, y, w, h, angle, alpha)
    local drift = (hash01(seed + 5) - 0.5) * h * 0.10
    local dx = math.cos(angle + math.pi * 0.5) * drift
    local dy = math.sin(angle + math.pi * 0.5) * drift
    plan.stamps[#plan.stamps + 1] = {
        names = names,
        seed = seed,
        x = x + dx,
        y = y + dy,
        w = w,
        h = h,
        angle = angle + (hash01(seed + 9) - 0.5) * 0.035,
        alpha = alpha,
    }
end

function inkLabGetStrokePlan(list, seed)
    if not list or #list < 2 then return nil end
    local seedKey = math.floor((seed or 0) * 1000)
    if list._inkLabStrokePlan and list._inkLabStrokePlanSeed == seedKey then
        return list._inkLabStrokePlan
    end

    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return nil end
    local avgR = list._inkLabAvgR or list[1].r
    local plan = {
        stamps = {},
        fibers = {},
        accents = {},
        length = totalLen,
        avgR = avgR,
    }

    local head = inkLabSampleBranch(list, 0.02)
    local middle = inkLabSampleBranch(list, 0.50)
    local foot = inkLabSampleBranch(list, 0.98)
    if head and middle and foot then
        local fullAngle = math.atan2(foot.y - head.y, foot.x - head.x)
        inkLabAddPlannedStamp(
            plan,
            inkLabSweepCoreStamps,
            seed + 610,
            middle.x,
            middle.y,
            totalLen * 1.10 + avgR * 3.5,
            math.max(48, avgR * 3.05),
            fullAngle,
            0.40
        )
    end

    local count = math.max(1, math.min(4, math.ceil(totalLen / math.max(360, avgR * 13.0))))
    local overlap = 1.48
    for k = 1, count do
        local t0 = (k - 1) / count
        local t1 = k / count
        local tm = (t0 + t1) * 0.5
        local a = inkLabSampleBranch(list, t0)
        local b = inkLabSampleBranch(list, t1)
        local m = inkLabSampleBranch(list, tm)
        if a and b and m then
            local segLen = dist2(b.x - a.x, b.y - a.y)
            local pressure = inkLabBranchPressure(tm, seed + k * 37)
            local h = math.max(38, m.r * (2.45 + hash01(seed + k * 17) * 0.26) * pressure)
            local w = math.max(120, segLen * overlap + m.r * 2.4)
            local s = seed + k * 151
            inkLabAddPlannedStamp(plan, inkLabSweepCoreStamps, s, m.x, m.y, w, h, m.angle, 0.40)
            if hash01(s + 3) > 0.45 then
                inkLabAddPlannedStamp(plan, inkLabSweepDryStamps, s + 31, m.x, m.y, w * 0.76, h * 0.58, m.angle, 0.12)
            end
            if hash01(s + 7) > 0.52 then
                inkLabAddPlannedStamp(plan, inkLabSweepEdgeStamps, s + 53, m.x, m.y, w * 0.66, h * 0.44, m.angle, 0.09)
            end
        end
    end

    local first = inkLabSampleBranch(list, 0.025)
    local tailA = inkLabSampleBranch(list, 0.84)
    local tail = inkLabSampleBranch(list, 0.985)
    if first then
        plan.stamps[#plan.stamps + 1] = {
            names = inkLabDryNodeStamps,
            seed = seed + 811,
            x = first.x,
            y = first.y,
            w = first.r * 3.2,
            h = first.r * 2.5,
            angle = first.angle,
            alpha = 0.16,
            first = true,
        }
    end
    if tailA and tail then
        local dx, dy = tail.x - tailA.x, tail.y - tailA.y
        plan.stamps[#plan.stamps + 1] = {
            names = inkLabDrySweepStamps,
            seed = seed + 941,
            x = tail.x,
            y = tail.y,
            w = tail.r * 5.8,
            h = math.max(30, tail.r * 2.2),
            angle = math.atan2(dy, dx),
            alpha = 0.22,
            first = true,
        }
    end

    local fiberSamples = math.max(6, math.min(9, math.floor(totalLen / 170)))
    local lanes = { -0.48, 0.42 }
    for laneIndex, lane in ipairs(lanes) do
        local laneSeed = seed + 3100 + laneIndex * 257
        local points = {}
        local function flushFiber()
            if #points >= 2 then
                local tone = math.abs(lane) > 0.50 and "dark" or "body"
                plan.fibers[#plan.fibers + 1] = {
                    tone = tone,
                    points = points,
                    width = 0.75 + (1.0 - math.abs(lane)) * 1.20 + hash01(laneSeed + #plan.fibers * 13) * 0.45,
                    alpha = 22 + (1.0 - math.abs(lane)) * 28 + hash01(laneSeed + #plan.fibers * 17) * 10,
                }
            end
            points = {}
        end
        for i = 0, fiberSamples do
            local t = i / fiberSamples
            local n = inkLabSampleBranch(list, t)
            if n then
                local pressure = inkLabBranchPressure(t, laneSeed + 19)
                local dry = inkLabDryness(t, laneSeed + 43)
                local gate = 0.16 + math.abs(lane) * 0.22 + dry * 0.18
                local active = hash01(laneSeed + i * 41) > gate or (math.abs(lane) < 0.20 and dry < 0.86)
                local wob = math.sin(t * math.pi * 4.4 + laneSeed * 0.03) * n.r * 0.030 + (hash01(laneSeed + i * 47) - 0.5) * n.r * 0.070
                if active then
                    points[#points + 1] = {
                        x = n.x + n.normX * (lane * n.r * pressure + wob),
                        y = n.y + n.normY * (lane * n.r * pressure + wob),
                    }
                else
                    flushFiber()
                end
            end
        end
        flushFiber()
    end

    local samples = math.max(5, math.min(10, math.floor(totalLen / 150)))
    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local s = seed + 1700 + i * 149
            local pressure = inkLabBranchPressure(t, s)
            local load = inkLabInkLoad(t, s + 300)
            local dry = inkLabDryness(t, s + 700)
            local bend = math.abs(inkLabBranchCurvature(list, t))
            local slip = (hash01(s + 5) - 0.5) * n.r * (0.12 + bend * 0.42)
            local cx = n.x + n.normX * slip
            local cy = n.y + n.normY * slip
            plan.accents[#plan.accents + 1] = {
                kind = "ellipse",
                tone = "body",
                x = cx,
                y = cy,
                rx = n.r * (0.46 + load * 0.28 + pressure * 0.12),
                ry = n.r * (0.15 + pressure * 0.11),
                angle = n.angle + (hash01(s + 9) - 0.5) * 0.08,
                alpha = 13 + load * 24,
            }
            if i % 5 == 2 and load > 0.66 and bend > 0.16 then
                plan.accents[#plan.accents + 1] = {
                    kind = "stamp",
                    names = inkLabWetBristleStamps,
                    seed = s + 61,
                    x = cx,
                    y = cy,
                    w = n.r * (1.35 + pressure * 0.42),
                    h = n.r * (0.72 + load * 0.28),
                    angle = n.angle + (hash01(s + 63) - 0.5) * 0.16,
                    alpha = 0.048 + load * 0.030,
                }
            end
            if dry > 0.34 or bend > 0.16 then
                local lane = (hash01(s + 13) - 0.5) * n.r * 0.95
                plan.accents[#plan.accents + 1] = {
                    kind = "dryLine",
                    tone = "dark",
                    x0 = n.x + n.normX * lane - math.cos(n.angle) * n.r * 0.68,
                    y0 = n.y + n.normY * lane - math.sin(n.angle) * n.r * 0.68,
                    x1 = n.x + n.normX * lane + math.cos(n.angle) * n.r * (0.86 + dry * 0.48),
                    y1 = n.y + n.normY * lane + math.sin(n.angle) * n.r * (0.86 + dry * 0.48),
                    width = math.max(0.75, n.r * 0.13),
                    alpha = 16 + dry * 18,
                    seed = s + 19,
                }
            end
            if load > 0.58 and hash01(s + 21) > 0.58 then
                plan.accents[#plan.accents + 1] = {
                    kind = "bleed",
                    tone = "body",
                    x = cx,
                    y = cy,
                    rx = n.r * 0.30,
                    ry = n.r * 0.12,
                    alpha = 4 + load * 5,
                    seed = s + 23,
                }
            end
            if dry > 0.52 and hash01(s + 31) > 0.46 then
                plan.accents[#plan.accents + 1] = {
                    kind = "ellipse",
                    tone = "pale",
                    x = n.x + n.normX * (hash01(s + 33) - 0.5) * n.r * 0.62,
                    y = n.y + n.normY * (hash01(s + 37) - 0.5) * n.r * 0.62,
                    rx = n.r * (0.20 + hash01(s + 41) * 0.16),
                    ry = n.r * 0.045,
                    angle = n.angle,
                    alpha = 20 + hash01(s + 43) * 18,
                }
            end
        end
    end

    list._inkLabStrokePlan = plan
    list._inkLabStrokePlanSeed = seedKey
    return plan
end

function drawInkLabPlannedStamp(stamp)
    if stamp.first then
        return drawInkLabStampFirst(stamp.names, stamp.x, stamp.y, stamp.w, stamp.h, stamp.angle, stamp.alpha)
    end
    return drawInkLabStampChoice(stamp.names, stamp.seed, stamp.x, stamp.y, stamp.w, stamp.h, stamp.angle, stamp.alpha)
end

function inkLabPlanTone(tone, body)
    if tone == "dark" then return C(17, 15, 13) end
    if tone == "pale" then return currentLevel and currentLevel.paper or C(243, 239, 230) end
    return body or C(39, 35, 30)
end

function drawInkLabPlannedFiber(fiber, body)
    if not fiber or not fiber.points or #fiber.points < 2 then return end
    nvgBeginPath(vg)
    nvgMoveTo(vg, fiber.points[1].x, fiber.points[1].y)
    for i = 2, #fiber.points do
        nvgLineTo(vg, fiber.points[i].x, fiber.points[i].y)
    end
    nvgStrokeColor(vg, colorRGBA(inkLabPlanTone(fiber.tone, body), fiber.alpha))
    nvgStrokeWidth(vg, fiber.width)
    nvgStroke(vg)
end

function drawInkLabContinuousLane(list, lane, widthScale, tint, alpha, seed, samples)
    if not list or #list < 2 then return end
    local moved = false
    nvgBeginPath(vg)
    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local pressure = inkLabBranchPressure(t, seed + 17)
            local dry = inkLabDryness(t, seed + 31)
            local load = inkLabInkLoad(t, seed + 43)
            local wob = math.sin(t * math.pi * 3.6 + seed * 0.017) * n.r * 0.030 + (hash01(seed + i * 37) - 0.5) * n.r * 0.045
            local off = lane * n.r * pressure + wob
            local lift = t > 0.88 and (1.0 - (t - 0.88) * 2.6) or 1.0
            local x = n.x + n.normX * off
            local y = n.y + n.normY * off
            if dry < 0.84 or load > 0.44 or math.abs(lane) < 0.18 then
                if not moved then
                    nvgMoveTo(vg, x, y)
                    moved = true
                else
                    nvgLineTo(vg, x, y)
                end
            elseif moved then
                nvgStrokeColor(vg, colorRGBA(tint, alpha * (0.70 + load * 0.24)))
                nvgStrokeWidth(vg, math.max(0.9, widthScale * n.r * (0.22 + pressure * 0.08) * lift))
                nvgStroke(vg)
                nvgBeginPath(vg)
                moved = false
            end
        end
    end
    if moved then
        nvgStrokeColor(vg, colorRGBA(tint, alpha))
        local mid = inkLabSampleBranch(list, 0.52)
        nvgStrokeWidth(vg, math.max(0.9, (mid and mid.r or 8) * widthScale * 0.28))
        nvgStroke(vg)
    end
end

function drawInkLabContinuousBrushStroke(list, tint, seed)
    if not list or #list < 2 then return false end
    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return false end

    local body = tint or C(34, 30, 26)
    local dark = C(14, 12, 10)
    local pale = currentLevel and currentLevel.paper or C(243, 239, 230)
    local samples = math.max(8, math.min(12, math.floor(totalLen / 155)))

    -- Main body is one swept contact surface, not a sequence of pasted branch textures.
    drawInkLabOneStrokeBody(list, body, 126, seed + 1800, 0.70, C(30, 27, 23))
    drawInkLabOneStrokeBody(list, dark, 64, seed + 1817, 0.36, C(16, 14, 12))

    local depositCount = math.max(3, math.min(6, math.floor(totalLen / 260)))
    for k = 1, depositCount do
        local t = k / (depositCount + 1)
        local n = inkLabSampleBranch(list, t)
        if n then
            local s = seed + k * 211
            local pressure = inkLabBranchPressure(t, s + 17)
            local load = inkLabInkLoad(t, s + 31)
            local dry = inkLabDryness(t, s + 47)
            local lane = (hash01(s + 5) - 0.5) * n.r * (0.64 + dry * 0.22)
            local tx, ty = math.cos(n.angle), math.sin(n.angle)
            local px = n.x + n.normX * lane + tx * (hash01(s + 7) - 0.5) * n.r * 0.46
            local py = n.y + n.normY * lane + ty * (hash01(s + 11) - 0.5) * n.r * 0.46
            drawInkLabStampChoice(
                inkLabWetBristleStamps,
                s,
                px,
                py,
                n.r * (2.05 + pressure * 0.34),
                n.r * (1.08 + load * 0.18),
                n.angle + (hash01(s + 13) - 0.5) * 0.18,
                0.060 + load * 0.050
            )
        end
    end

    local edgeSamples = math.max(3, math.min(5, math.floor(totalLen / 310)))
    for i = 1, edgeSamples do
        local t0 = (i - 1) / edgeSamples
        local t1 = i / edgeSamples
        local a = inkLabSampleBranch(list, t0)
        local b = inkLabSampleBranch(list, t1)
        if a and b then
            local s = seed + i * 173
            local side = hash01(s + 3) > 0.45 and 1 or -1
            local dry = inkLabDryness((t0 + t1) * 0.5, s + 17)
            local edgeA = a.r * (0.74 + dry * 0.24 + (hash01(s + 5) - 0.5) * 0.12)
            local edgeB = b.r * (0.74 + dry * 0.24 + (hash01(s + 7) - 0.5) * 0.12)
            drawDryBrushLine(
                a.x + a.normX * edgeA * side,
                a.y + a.normY * edgeA * side,
                b.x + b.normX * edgeB * side,
                b.y + b.normY * edgeB * side,
                math.max(1.0, (a.r + b.r) * 0.075),
                dry > 0.55 and dark or body,
                34 + dry * 28,
                s + 11,
                1
            )
            if dry > 0.50 and hash01(s + 13) > 0.44 then
                local lane = (hash01(s + 19) - 0.5) * 0.50
                drawDryBrushLine(
                    a.x + a.normX * a.r * lane,
                    a.y + a.normY * a.r * lane,
                    b.x + b.normX * b.r * lane,
                    b.y + b.normY * b.r * lane,
                    math.max(0.8, (a.r + b.r) * 0.050),
                    pale,
                    24 + dry * 26,
                    s + 23,
                    1
                )
            end
        end
    end

    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local s = seed + i * 131
            local pressure = inkLabBranchPressure(t, s)
            local load = inkLabInkLoad(t, s + 300)
            local dry = inkLabDryness(t, s + 700)
            local bend = math.abs(inkLabBranchCurvature(list, t))
            local slip = (hash01(s + 5) - 0.5) * n.r * (0.10 + bend * 0.50)
            local cx = n.x + n.normX * slip
            local cy = n.y + n.normY * slip
            local contactLong = n.r * (0.50 + pressure * 0.18 + load * 0.10)
            local contactWide = n.r * (0.18 + pressure * 0.14)
            drawRotEllipse(cx, cy, contactLong, contactWide, n.angle, colorRGBA(dark, 8 + load * 10))
            if dry > 0.46 then
                local lane = (hash01(s + 17) - 0.5) * n.r * 1.15
                drawDryBrushLine(
                    cx + n.normX * lane - math.cos(n.angle) * n.r * 0.34,
                    cy + n.normY * lane - math.sin(n.angle) * n.r * 0.34,
                    cx + n.normX * lane + math.cos(n.angle) * n.r * 0.56,
                    cy + n.normY * lane + math.sin(n.angle) * n.r * 0.56,
                    math.max(0.8, n.r * 0.16),
                    pale,
                    24 + dry * 22,
                    s + 19,
                    1
                )
            end
        end
    end

    drawInkLabContinuousLane(list, -0.50, 0.28, dark, 58, seed + 2200, samples)
    drawInkLabContinuousLane(list, 0.18, 0.26, body, 44, seed + 2400, samples)

    local drySamples = math.max(4, math.min(7, math.floor(totalLen / 260)))
    for i = 1, drySamples do
        local t = i / (drySamples + 1)
        local n = inkLabSampleBranch(list, t)
        if n then
            local dry = inkLabDryness(t, seed + i * 97)
            if dry > 0.40 then
                local lane = (hash01(seed + i * 101) - 0.5) * 1.25
                local x0 = n.x + n.normX * lane * n.r - math.cos(n.angle) * n.r * (0.54 + dry * 0.18)
                local y0 = n.y + n.normY * lane * n.r - math.sin(n.angle) * n.r * (0.54 + dry * 0.18)
                local x1 = n.x + n.normX * lane * n.r + math.cos(n.angle) * n.r * (0.72 + dry * 0.35)
                local y1 = n.y + n.normY * lane * n.r + math.sin(n.angle) * n.r * (0.72 + dry * 0.35)
                drawDryBrushLine(x0, y0, x1, y1, math.max(0.8, n.r * 0.18), pale, 28 + dry * 22, seed + i * 109, 1)
            end
        end
    end
    return true
end

function drawInkLabImageBrushSweep(list, tint, alpha, seed)
    if not list or #list < 2 then return false end
    if not inkLabBranchListVisible(list, 340) then return true end
    local plan = inkLabGetStrokePlan(list, seed)
    if not plan then return false end

    drawInkLabContinuousBrushStroke(list, tint, seed)

    for _, stamp in ipairs(plan.stamps) do
        if stamp.first then
            drawInkLabPlannedStamp(stamp)
        end
    end

    return true
end

function drawInkLabFiberPath(list, lane, width, tint, alpha, seed, samples, paleMode)
    if not list or #list < 2 then return end
    local drawing = false
    local moved = false
    for i = 1, samples - 1 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local dry = inkLabDryness(t, seed)
            local noise = hash01(seed + i * 37)
            local active
            if paleMode then
                active = noise < 0.18 + dry * 0.42
            else
                active = noise > 0.22 + dry * 0.20
            end
            local jitter = math.sin(t * math.pi * 5.0 + seed * 0.023) * 0.045 + (hash01(seed + i * 41) - 0.5) * 0.075
            local off = (lane + jitter) * n.r * inkLabBranchPressure(t, seed + 19)
            local x = n.x + n.normX * off
            local y = n.y + n.normY * off
            if active then
                if not drawing then
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, x, y)
                    drawing = true
                    moved = true
                else
                    nvgLineTo(vg, x, y)
                end
            elseif drawing then
                nvgStrokeColor(vg, colorRGBA(tint, alpha))
                nvgStrokeWidth(vg, width)
                nvgStroke(vg)
                drawing = false
            end
        end
    end
    if drawing and moved then
        nvgStrokeColor(vg, colorRGBA(tint, alpha))
        nvgStrokeWidth(vg, width)
        nvgStroke(vg)
    end
end

function inkLabBranchCurvature(list, t)
    local a = inkLabSampleBranch(list, math.max(0, t - 0.035))
    local b = inkLabSampleBranch(list, t)
    local c = inkLabSampleBranch(list, math.min(1, t + 0.035))
    if not a or not b or not c then return 0 end
    local a1 = math.atan2(b.y - a.y, b.x - a.x)
    local a2 = math.atan2(c.y - b.y, c.x - b.x)
    return math.atan2(math.sin(a2 - a1), math.cos(a2 - a1))
end

function drawInkLabContactPatch(n, stepLen, tint, seed, t)
    local pressure = inkLabBranchPressure(t, seed + 1200)
    local load = inkLabInkLoad(t, seed + 2200)
    local dry = inkLabDryness(t, seed + 3200)
    local bend = inkLabBranchCurvature(currentInkLabStrokeList, t)
    local tangentX, tangentY = math.cos(n.angle), math.sin(n.angle)
    local sideSlip = math.atan2(math.sin(bend), math.cos(bend)) * n.r * 0.32
    local cx = n.x + n.normX * sideSlip
    local cy = n.y + n.normY * sideSlip
    local contactLen = math.max(stepLen * 0.78, n.r * (0.58 + pressure * 0.24))
    local contactHalf = n.r * (0.58 + pressure * 0.55 + load * 0.18)
    local inkAlpha = 7 + load * 22 + pressure * 8
    local dryAlpha = 10 + dry * 20
    local dark = C(18, 16, 14)
    local bodyTint = tint or C(34, 30, 26)

    drawRotEllipse(cx, cy, contactLen * 0.78, contactHalf * 0.82, n.angle, colorRGBA(bodyTint, inkAlpha))

    local lanes = 7
    for j = 1, lanes do
        local laneT = (j - (lanes + 1) * 0.5) / ((lanes - 1) * 0.5)
        local laneSeed = seed + j * 53
        local bristleLoad = load * (0.72 + hash01(laneSeed + math.floor(t * 97)) * 0.46)
        local laneDry = dry + math.abs(laneT) * 0.18
        if hash01(laneSeed + math.floor(t * 181)) > laneDry * 0.38 then
            local spread = contactHalf * (0.82 + dry * 0.28)
            local lx = cx + n.normX * laneT * spread + tangentX * (hash01(laneSeed + 7) - 0.5) * stepLen * 0.36
            local ly = cy + n.normY * laneT * spread + tangentY * (hash01(laneSeed + 7) - 0.5) * stepLen * 0.36
            local rx = contactLen * (0.62 + bristleLoad * 0.42)
            local ry = math.max(0.65, contactHalf * (0.12 + (1.0 - math.abs(laneT)) * 0.16) * (0.76 + pressure * 0.24))
            local a = 5 + bristleLoad * 28 + (1.0 - math.abs(laneT)) * 8
            drawRotEllipse(lx, ly, rx, ry, n.angle + (hash01(laneSeed + 11) - 0.5) * 0.05, colorRGBA(math.abs(laneT) > 0.72 and dark or bodyTint, a))
        end
    end

    if dry > 0.38 then
        local gaps = 2 + math.floor(dry * 3)
        for g = 1, gaps do
            local gapSeed = seed + g * 89
            if hash01(gapSeed + math.floor(t * 223)) < dry * 0.72 then
                local lane = (hash01(gapSeed + 3) - 0.5) * 0.92
                local gx = cx + n.normX * lane * contactHalf * 0.72 + tangentX * (hash01(gapSeed + 5) - 0.5) * contactLen * 0.50
                local gy = cy + n.normY * lane * contactHalf * 0.72 + tangentY * (hash01(gapSeed + 5) - 0.5) * contactLen * 0.50
                drawRotEllipse(gx, gy, contactLen * (0.18 + hash01(gapSeed + 7) * 0.22), contactHalf * (0.035 + hash01(gapSeed + 9) * 0.045), n.angle, colorRGBA(currentLevel.paper, dryAlpha))
            end
        end
    end
end

function drawInkLabDepositedBrushStroke(list, tint, alpha, seed)
    if not list or #list < 2 then return false end
    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return false end

    local dark = C(18, 16, 14)
    local body = tint or C(34, 30, 26)
    local samples = math.max(48, math.min(260, math.floor(totalLen / 5.2)))
    local stepLen = totalLen / samples

    currentInkLabStrokeList = list
    drawInkLabOneStrokeBody(list, body, 18, seed + 610, 0.34, C(30, 27, 24))

    for i = 0, samples do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            drawInkLabContactPatch(n, stepLen, body, seed + i * 131, t)
        end
    end

    for laneIndex, lane in ipairs({ -0.72, -0.48, -0.26, -0.09, 0.08, 0.24, 0.44, 0.66 }) do
        local laneSeed = seed + laneIndex * 997
        local width = 0.85 + (1.0 - math.abs(lane)) * 1.6 + hash01(laneSeed + 5) * 0.65
        local a = 18 + (1.0 - math.abs(lane)) * 31 + hash01(laneSeed + 7) * 12
        drawInkLabFiberPath(list, lane, width, math.abs(lane) > 0.62 and dark or body, a, laneSeed, samples, false)
    end

    for laneIndex, lane in ipairs({ -0.34, -0.16, 0.12, 0.32 }) do
        local laneSeed = seed + 4100 + laneIndex * 307
        drawInkLabFiberPath(list, lane, 0.95 + hash01(laneSeed + 3) * 0.95, currentLevel.paper, 26 + hash01(laneSeed + 7) * 18, laneSeed, samples, true)
    end

    for i = 5, samples - 5, 7 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local load = inkLabInkLoad(t, seed + 2200)
            if load > 0.54 and hash01(seed + i * 67) > 0.42 then
                drawInkBleed(n.x, n.y, n.r * (0.42 + load * 0.24), n.r * (0.18 + load * 0.14), body, 5 + load * 8, seed + i * 71, 2)
            end
        end
    end

    local first = inkLabSampleBranch(list, 0.02)
    local tail = inkLabSampleBranch(list, 0.985)
    if first then
        drawInkBleed(first.x, first.y, first.r * 1.35, first.r * 0.62, dark, 32, seed + 811, 4)
    end
    if tail then
        drawDryBrushLine(
            tail.x - math.cos(tail.angle) * tail.r * 0.8,
            tail.y - math.sin(tail.angle) * tail.r * 0.8,
            tail.x + math.cos(tail.angle) * tail.r * 2.6,
            tail.y + math.sin(tail.angle) * tail.r * 2.6,
            math.max(1.1, tail.r * 0.20),
            dark,
            42,
            seed + 941,
            2
        )
    end

    currentInkLabStrokeList = nil
    return true
end

function drawInkLabVirtualBristleStroke(list, tint, alpha, seed)
    if not list or #list < 2 then return false end
    local totalLen = inkLabPathLength(list)
    if totalLen < 8 then return false end

    local dark = C(17, 15, 13)
    local wet = tint or C(38, 34, 29)
    local pale = currentLevel and currentLevel.paper or C(232, 228, 214)
    local samples = math.max(20, math.min(88, math.floor(totalLen / 14)))
    local brushLanes = { -0.78, -0.56, -0.36, -0.18, -0.04, 0.10, 0.27, 0.46, 0.66 }
    local useRepeatedFootprints = true

    drawInkLabOneStrokeBody(list, wet, 34, seed + 1800, 0.42, C(24, 21, 18))

    for i = 0, samples, 7 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local pressure = inkLabBranchPressure(t, seed + 3500)
            local load = inkLabInkLoad(t, seed + 6100)
            local s = seed + i * 71
            if useRepeatedFootprints and load > 0.72 and hash01(s + 13) > 0.48 then
                local side = (hash01(s + 3) - 0.5) * n.r * 0.18
                local w = n.r * (1.65 + hash01(s + 5) * 0.34) * pressure
                local h = n.r * (1.05 + hash01(s + 7) * 0.24) * pressure
                local a = 0.045 + load * 0.040 + hash01(s + 11) * 0.020
                drawInkLabStampChoice(
                    inkLabWetBristleStamps,
                    s,
                    n.x + n.normX * side,
                    n.y + n.normY * side,
                    w,
                    h,
                    n.angle + (hash01(s + 9) - 0.5) * 0.14,
                    a
                )
            end
        end
    end

    for laneIndex, lane in ipairs(brushLanes) do
        local laneSeed = seed + laneIndex * 389
        local laneWidthBase = 1.05 + (1.0 - math.abs(lane)) * 3.10 + hash01(laneSeed + 3) * 0.70
        local laneAlphaBase = 46 + (1.0 - math.abs(lane)) * 94 + hash01(laneSeed + 7) * 16
        local moved = false
        local drawing = false
        for i = 0, samples do
            local t = i / samples
            local n = inkLabSampleBranch(list, t)
            if n then
                local pressure = inkLabBranchPressure(t, seed + laneIndex * 17)
                local paperNoise = hash01(laneSeed + math.floor(t * 28) * 29)
                local dry = inkLabDryness(t, seed + laneIndex * 73)
                local dryGate = 0.12 + math.abs(lane) * 0.22 + dry * 0.15
                local active = paperNoise > dryGate or (math.abs(lane) < 0.20 and dry < 0.86)
                local wob = math.sin(t * math.pi * 4.0 + laneSeed * 0.17) * n.r * 0.055 + (hash01(laneSeed + i * 31) - 0.5) * n.r * 0.060
                local off = lane * n.r * pressure * 0.92 + wob
                local x = n.x + n.normX * off
                local y = n.y + n.normY * off
                if active then
                    if not drawing then
                        nvgBeginPath(vg)
                        nvgMoveTo(vg, x, y)
                        drawing = true
                        moved = true
                    else
                        nvgLineTo(vg, x, y)
                    end
                elseif drawing then
                    nvgStrokeColor(vg, colorRGBA(math.abs(lane) > 0.65 and dark or wet, laneAlphaBase * (0.62 + hash01(laneSeed + i * 37) * 0.34)))
                    nvgStrokeWidth(vg, laneWidthBase * (0.74 + pressure * 0.34))
                    nvgStroke(vg)
                    drawing = false
                end
            end
        end
        if drawing and moved then
            nvgStrokeColor(vg, colorRGBA(math.abs(lane) > 0.65 and dark or wet, laneAlphaBase * 0.98))
            nvgStrokeWidth(vg, laneWidthBase)
            nvgStroke(vg)
        end
    end

    for laneIndex, lane in ipairs({ -0.16, 0.10 }) do
        local laneSeed = seed + 2800 + laneIndex * 127
        for i = 1, samples - 1, 3 do
            local t0 = (i - 1) / (samples - 1)
            local t1 = i / (samples - 1)
            local a = inkLabSampleBranch(list, t0)
            local b = inkLabSampleBranch(list, t1)
            if a and b and hash01(laneSeed + i * 41) > 0.44 then
                local off0 = lane * a.r * inkLabBranchPressure(t0, seed)
                local off1 = lane * b.r * inkLabBranchPressure(t1, seed)
                drawDryBrushLine(
                    a.x + a.normX * off0, a.y + a.normY * off0,
                    b.x + b.normX * off1, b.y + b.normY * off1,
                    1.0 + hash01(laneSeed + i * 47) * 1.3,
                    pale,
                    18 + hash01(laneSeed + i * 53) * 20,
                    laneSeed + i * 59,
                    1
                )
            end
        end
    end

    for i = 0, samples, 8 do
        local t = i / samples
        local n = inkLabSampleBranch(list, t)
        if n then
            local pressure = inkLabBranchPressure(t, seed + 4200)
            local s = seed + i * 83
            local side = (hash01(s + 3) - 0.5) * n.r * 0.28
            local w = n.r * (1.85 + hash01(s + 5) * 0.34) * pressure
            local h = n.r * (1.15 + hash01(s + 7) * 0.24) * pressure
            if useRepeatedFootprints then
                drawInkLabStamp(
                    "bristleTip",
                    n.x + n.normX * side,
                    n.y + n.normY * side,
                    w,
                    h,
                    n.angle + (hash01(s + 9) - 0.5) * 0.18,
                    0.040 + hash01(s + 11) * 0.025
                )
            end
        end
    end

    for laneIndex, lane in ipairs({ -0.32, -0.14, 0.10, 0.30 }) do
        local laneSeed = seed + 8400 + laneIndex * 173
        drawInkLabFiberPath(list, lane, 1.25 + hash01(laneSeed + 3) * 1.15, pale, 34 + hash01(laneSeed + 7) * 22, laneSeed, samples, true)
    end
    for sideIndex, lane in ipairs({ -0.88, 0.88 }) do
        local laneSeed = seed + 6900 + sideIndex * 211
        drawInkLabFiberPath(list, lane, 0.95 + hash01(laneSeed + 3) * 1.35, dark, 30 + hash01(laneSeed + 7) * 22, laneSeed, samples, false)
    end

    for i = 1, samples - 1 do
        if i % 5 == 0 then
            local t = i / (samples - 1)
            local n = inkLabSampleBranch(list, t)
            if n and hash01(seed + i * 67) > 0.35 then
                drawInkBleed(n.x, n.y, n.r * (0.68 + hash01(seed + i * 71) * 0.34), n.r * 0.34, wet, 10 + hash01(seed + i * 73) * 14, seed + i * 79, 2)
            end
        end
    end

    local first = inkLabSampleBranch(list, 0.02)
    local tail = inkLabSampleBranch(list, 0.985)
    if first then
        drawInkBleed(
            first.x - math.cos(first.angle) * first.r * 0.45,
            first.y - math.sin(first.angle) * first.r * 0.45,
            first.r * 1.28,
            first.r * 0.58,
            dark,
            24,
            seed + 811,
            3
        )
        drawDryBrushLine(
            first.x - math.cos(first.angle) * first.r * 1.5,
            first.y - math.sin(first.angle) * first.r * 1.5,
            first.x + math.cos(first.angle) * first.r * 0.9,
            first.y + math.sin(first.angle) * first.r * 0.9,
            math.max(1.0, first.r * 0.20),
            dark,
            36,
            seed + 829,
            2
        )
    end
    if tail then
        drawDryBrushLine(
            tail.x - math.cos(tail.angle) * tail.r * 0.7,
            tail.y - math.sin(tail.angle) * tail.r * 0.7,
            tail.x + math.cos(tail.angle) * tail.r * 2.1,
            tail.y + math.sin(tail.angle) * tail.r * 2.1,
            math.max(1.1, tail.r * 0.22),
            dark,
            34,
            seed + 941,
            2
        )
    end

    return true
end

function drawInkLabRuntimeFootprintAccents(list, tint, seed)
    if not list or #list < 2 then return false end
    if not inkLabBranchListVisible(list, 220) then return true end
    local plan = inkLabGetStrokePlan(list, (seed or 0) - 1000)
    if not plan then return false end
    local body = tint or C(39, 35, 30)
    for _, accent in ipairs(plan.accents) do
        local tone = inkLabPlanTone(accent.tone, body)
        if accent.kind == "ellipse" then
            if accent.tone ~= "body" then
                drawRotEllipse(accent.x, accent.y, accent.rx, accent.ry, accent.angle, colorRGBA(tone, accent.alpha))
            end
        elseif accent.kind == "stamp" then
            drawInkLabStampChoice(accent.names, accent.seed, accent.x, accent.y, accent.w, accent.h, accent.angle, accent.alpha)
        elseif accent.kind == "dryLine" then
            drawDryBrushLine(accent.x0, accent.y0, accent.x1, accent.y1, accent.width, tone, accent.alpha, accent.seed, 1)
        elseif accent.kind == "bleed" then
            drawInkBleed(accent.x, accent.y, accent.rx, accent.ry, tone, accent.alpha, accent.seed, 1)
        end
    end

    return true
end

function drawInkLabSoftRibbon(list, tint, alpha, seed)
    if not currentLevelIsInkLab() or not list or #list < 2 then return false end
    if not inkLabBranchListVisible(list, 360) then return true end
    local body = tint or C(39, 35, 30)
    local s = seed or 0
    drawInkLabImageBrushSweep(list, body, alpha or 214, s + 700)
    drawInkLabRuntimeFootprintAccents(list, body, s + 1700)
    return true
end

function drawInkLabPineBackground()
    if not currentLevelIsInkLab() then return end
    for i = 0, 5 do
        local x = W(0.06 + i * 0.105)
        local y = H(0.18 + hash01(1600 + i * 13) * 0.52)
        drawInkLabStamp("paper", x, y, 660, 560, (hash01(1700 + i) - 0.5) * 0.08, 0.22)
    end
    for i = 1, 8 do
        local seed = 2100 + i * 37
        local x = hash01(seed) * worldW
        local y = H(0.12 + hash01(seed + 3) * 0.60)
        local s = 180 + hash01(seed + 5) * 340
        drawInkLabStamp("bleed", x, y, s * 1.6, s * 0.86, (hash01(seed + 7) - 0.5) * 0.6, 0.10 + hash01(seed + 11) * 0.08)
    end
    for i = 1, 10 do
        local seed = 2600 + i * 31
        local x = hash01(seed) * worldW
        local y = H(0.20 + hash01(seed + 2) * 0.48)
        local len = 180 + hash01(seed + 5) * 300
        if inkLabIsVisible(x + len * 0.5, y, len * 0.6) then
            drawDryBrushLine(x, y, x + len, y + (hash01(seed + 7) - 0.5) * 28, 0.8 + hash01(seed + 11) * 1.6, currentLevel.ink, 18 + hash01(seed + 13) * 26, seed, 1)
        end
    end
end

function drawInkLabBranchMaterial(id, list)
    if not currentLevelIsInkLab() or not list or #list < 2 then return end
    if id:find("poetry") or id:find("pavilion") then return end
    if not inkLabBranchListVisible(list, 220) then return end

    local step = math.max(9, math.floor(#list / 8))
    for i = 3, #list - 3, step * 2 do
        local prev, n, nextN = list[i - 2], list[i], list[i + 2]
        local a1 = math.atan2(n.y - prev.y, n.x - prev.x)
        local a2 = math.atan2(nextN.y - n.y, nextN.x - n.x)
        local bend = math.abs(math.atan2(math.sin(a2 - a1), math.cos(a2 - a1)))
        if bend > 0.18 then
            local seed = i * 59 + n.x * 0.01 + n.y * 0.02
            drawInkBleed(n.x, n.y, n.r * 0.40, n.r * 0.16, C(18, 16, 13), 4 + hash01(seed + 3) * 4, seed, 2)
            drawDryBrushLine(
                n.x - math.cos(a2) * n.r * 0.72,
                n.y - math.sin(a2) * n.r * 0.72,
                n.x + math.cos(a2) * n.r * 0.92,
                n.y + math.sin(a2) * n.r * 0.92,
                math.max(0.75, n.r * 0.12),
                C(18, 16, 13),
                18 + hash01(seed + 9) * 12,
                seed + 17,
                1
            )
        end
    end

    local first, second = list[1], list[math.min(#list, step + 1)]
    if first and second then
        local dx, dy = second.x - first.x, second.y - first.y
        local angle = math.atan2(dy, dx)
        local startSeed = (#id * 83) + first.x * 0.013 + first.y * 0.017
        drawInkBleed(first.x, first.y, first.r * 0.48, first.r * 0.20, C(18, 16, 13), 6 + hash01(startSeed) * 5, startSeed, 2)
    end

    if #list > 3 then
        local tailA = list[math.max(1, #list - step)]
        local tailB = list[#list]
        local dx, dy = tailB.x - tailA.x, tailB.y - tailA.y
        local len = dist2(dx, dy)
        if len > 4 then
            local angle = math.atan2(dy, dx)
            drawDryBrushLine(
                tailB.x - math.cos(angle) * tailB.r * 0.4,
                tailB.y - math.sin(angle) * tailB.r * 0.4,
                tailB.x + math.cos(angle) * tailB.r * 2.3,
                tailB.y + math.sin(angle) * tailB.r * 2.3,
                math.max(1.0, tailB.r * 0.18),
                C(18, 16, 13),
                28,
                tailB.x * 0.017 + tailB.y * 0.013,
                2
            )
        end
    end
end

function drawInkLabBranchOverlay()
    -- Kept for older call sites. Branch texture now belongs inside drawBranches,
    -- immediately after the branch ribbon fill and before edge lines/targets.
end

function drawInkLabNeedleTexture(x, y, nx, ny, lenBase, alpha, seed)
    if not currentLevelIsInkLab() then return end
    local base = math.atan2(ny or -1, nx or 0)
    local size = (lenBase or 36) * 2.55
    if not inkLabIsVisible(x, y, size * 0.75) then return end
    drawInkLabStamp("needle", x + (nx or 0) * size * 0.12, y + (ny or -1) * size * 0.12, size, size, base + math.pi * 0.5, 0.46)
    for i = 1, 3 do
        local s = (seed or 0) + i * 67
        local a = base + (hash01(s) - 0.5) * 1.55
        local l = (lenBase or 36) * (0.45 + hash01(s + 3) * 0.72)
        drawDryBrushLine(x, y, x + math.cos(a) * l, y + math.sin(a) * l * 0.78, 0.55 + hash01(s + 5) * 0.9, C(6, 18, 10), (alpha or 120) * 0.26, s, 1)
    end
end

function drawInkLabPineConeAura(t, r)
    if not currentLevelIsInkLab() then return end
    drawInkLabStamp("bleed", t.x, t.y, r * 3.8, r * 3.0, t.pulse or 0, 0.18)
    if hash01(t.x * 0.011 + t.y * 0.017 + elapsed * 0.6) > 0.52 then
        drawCircle(t.x, t.y, r * 1.35, rgba(92, 58, 24, 20))
    end
end

function spawnInkLabHitFeedback(t)
    if not currentLevelIsInkLab() then return end
    windWaves[#windWaves + 1] = { x = t.x, y = t.y, r = 0, life = 26, maxLife = 26 }
    for i = 1, 10 do addBristle(t.x, t.y, -player.vx * 0.2, -player.vy * 0.2, "gold") end
    for i = 1, 16 do addBristle(t.x, t.y, player.vx * 0.15, player.vy * 0.15, "inkgas") end
end
