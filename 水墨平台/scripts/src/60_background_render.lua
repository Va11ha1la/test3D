-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function updateCamera()
    if currentLevel.trace then
        traceUpdateCamera()
        return
    end
    local targetX = player.x - DESIGN_W * 0.5
    local targetY = player.y - DESIGN_H * 0.5
    cameraX = cameraX + (targetX - cameraX) * 0.10
    cameraY = cameraY + (targetY - cameraY) * 0.10
    cameraX = clamp(cameraX, 0, math.max(0, worldW - DESIGN_W))
    cameraY = clamp(cameraY, 0, math.max(0, worldH - DESIGN_H))
end

local function drawPaper()
    drawRect(0, 0, worldW, worldH, 0, colorRGB(currentLevel.paper))
    -- plum_parallax 关卡使用深色天空底色，跳过纸纹装饰以避免干扰视差层
    if currentLevel.parallaxLayers then return end
    for x = -worldH, worldW, 42 do
        strokeLine(x, 0, x + worldH, worldH, 1, colorRGBA(currentLevel.paper2, 38))
    end
    for i = 1, 56 do
        local x = hash01(i * 3.7) * worldW
        local y = hash01(i * 5.1) * worldH
        drawEllipse(x, y, 90 + hash01(i * 7.3) * 240, 16 + hash01(i * 11.5) * 54, colorRGBA(currentLevel.paper2, 18 + hash01(i) * 24))
    end
    for i = 1, 130 do
        local x = hash01(i * 13.1) * worldW
        local y = hash01(i * 17.9) * worldH
        local len = 12 + hash01(i * 19.3) * 44
        local a = -0.55 + (hash01(i * 23.7) - 0.5) * 0.35
        strokeLine(x, y, x + math.cos(a) * len, y + math.sin(a) * len, 0.6, colorRGBA(currentLevel.paper2, 14 + hash01(i * 29.1) * 20))
    end
end

local function tryLoadMasterPlumImage()
    if masterPlumImageTried or vg == nil then return end
    masterPlumImageTried = true
    if type(nvgCreateImage) ~= "function" then return end
    local candidates = {
        "assets/reference/wang_mian_fragrant_snow_met.jpg",
        "reference/wang_mian_fragrant_snow_met.jpg",
        "wang_mian_fragrant_snow_met.jpg",
    }
    for _, path in ipairs(candidates) do
        local ok, img = pcall(nvgCreateImage, vg, path, 0)
        if ok and img and img > 0 then
            masterPlumImage = img
            print("Loaded Wang Mian plum reference image: " .. path)
            return
        end
    end
end

local function drawMasterPlumReferenceImage()
    tryLoadMasterPlumImage()
    if not masterPlumImage or type(nvgImagePattern) ~= "function" or type(nvgFillPaint) ~= "function" then return false end
    local scale = math.min(worldW / MASTER_PLUM_IMAGE_W, worldH / MASTER_PLUM_IMAGE_H)
    local w = MASTER_PLUM_IMAGE_W * scale
    local h = MASTER_PLUM_IMAGE_H * scale
    local x = (worldW - w) * 0.5
    local y = (worldH - h) * 0.5
    masterPlumDrawX, masterPlumDrawY, masterPlumDrawW, masterPlumDrawH = x, y, w, h
    local ok, paint = pcall(nvgImagePattern, vg, x, y, w, h, 0, masterPlumImage, 1.0)
    if not ok or not paint then return false end
    nvgBeginPath(vg)
    nvgRect(vg, x, y, w, h)
    nvgFillPaint(vg, paint)
    nvgFill(vg)
    return true
end

local function drawMountainBand(seed, count, tint, alphaBase, heightBase, heightVar)
    for i = 0, count - 1 do
        local xStart = (i * (0.18 + hash01(seed + i) * 0.04)) * worldW - 260
        local mWidth = worldW * (0.42 + hash01(seed + i * 3) * 0.10)
        local mHeight = worldH * (heightBase + hash01(seed + i * 5) * heightVar)
        local peakY = worldH - mHeight
        local a = alphaBase + i * 9
        fillPoly({
            { xStart, worldH },
            { xStart + mWidth * 0.30, worldH - mHeight * (0.38 + hash01(seed + i * 7) * 0.12) },
            { xStart + mWidth * 0.52, peakY },
            { xStart + mWidth * 0.76, worldH - mHeight * (0.18 + hash01(seed + i * 11) * 0.12) },
            { xStart + mWidth, worldH },
        }, colorRGBA(tint, a))
    end
end

local function drawMountainBandAt(seed, count, tint, alphaBase, heightBase, heightVar, stepMul, widthMul, xOffset)
    local step = stepMul or 0.20
    local width = widthMul or 0.48
    local offset = xOffset or -300
    for i = 0, count - 1 do
        local xStart = i * step * worldW + offset
        local mWidth = worldW * width
        local mHeight = worldH * (heightBase + hash01(seed + i * 17) * heightVar)
        local peakY = worldH - mHeight
        local points = { { xStart, worldH } }
        points[#points + 1] = { xStart + mWidth * 0.30, worldH - mHeight * 0.42 }
        for s = 0, 8 do
            local t = s / 8
            local it = 1 - t
            local px = it * it * (xStart + mWidth * 0.30) + 2 * it * t * (xStart + mWidth * 0.50) + t * t * (xStart + mWidth * 0.75)
            local py = it * it * (worldH - mHeight * 0.42) + 2 * it * t * peakY + t * t * (worldH - mHeight * 0.22)
            points[#points + 1] = { px, py }
        end
        points[#points + 1] = { xStart + mWidth, worldH }
        fillPoly(points, colorRGBA(tint, alphaBase + i * 3.6))
    end
end

local function drawVerticalWash(y, h, tintTop, tintBottom, alphaTop, alphaBottom, bands)
    local n = bands or 18
    for i = 0, n - 1 do
        local t = i / math.max(1, n - 1)
        local r = tintTop[1] * (1 - t) + tintBottom[1] * t
        local g = tintTop[2] * (1 - t) + tintBottom[2] * t
        local b = tintTop[3] * (1 - t) + tintBottom[3] * t
        local a = alphaTop * (1 - t) + alphaBottom * t
        drawRect(0, y + h * t, worldW, h / n + 2, 0, rgba(r, g, b, a))
    end
end

local function drawMist(seed, count, tint, alpha)
    for i = 1, count do
        local cx = hash01(seed + i * 13) * worldW
        local cy = worldH * (0.08 + hash01(seed + i * 17) * 0.62)
        local rx = 150 + hash01(seed + i * 19) * 300
        local ry = 20 + hash01(seed + i * 23) * 55
        drawRotEllipse(cx, cy, rx, ry, (hash01(seed + i * 29) - 0.5) * 0.20, colorRGBA(tint, alpha + hash01(seed + i * 31) * alpha))
    end
end

local function drawMistBand(seed, count, tint, alpha, yMin, yMax, rxMin, rxMax, ryMin, ryMax)
    for i = 1, count do
        local cx = hash01(seed + i * 13) * worldW
        local cy = H(yMin + hash01(seed + i * 17) * (yMax - yMin))
        local rx = rxMin + hash01(seed + i * 19) * (rxMax - rxMin)
        local ry = ryMin + hash01(seed + i * 23) * (ryMax - ryMin)
        drawRotEllipse(cx, cy, rx, ry, (hash01(seed + i * 29) - 0.5) * 0.20, colorRGBA(tint, alpha + hash01(seed + i * 31) * alpha))
    end
end

local function drawInkBleed(x, y, rx, ry, tint, alpha, seed, layers)
    local count = layers or 4
    for i = 1, count do
        local s = seed + i * 23
        local ox = (hash01(s) - 0.5) * rx * 0.34
        local oy = (hash01(s + 3) - 0.5) * ry * 0.34
        local sx = rx * (0.72 + hash01(s + 7) * 0.48)
        local sy = ry * (0.58 + hash01(s + 11) * 0.55)
        drawRotEllipse(x + ox, y + oy, sx, sy, (hash01(s + 17) - 0.5) * 0.7, colorRGBA(tint, alpha * (0.35 + hash01(s + 19) * 0.65)))
    end
end

local function drawInkSpeckles(x, y, w, h, tint, alpha, seed, count)
    for i = 1, count do
        local s = seed + i * 37
        local px = x + hash01(s) * w
        local py = y + hash01(s + 5) * h
        local r = 1.2 + hash01(s + 9) * 4.5
        drawRotEllipse(px, py, r, r * (0.45 + hash01(s + 13) * 0.50), hash01(s + 17) * math.pi, colorRGBA(tint, alpha * (0.35 + hash01(s + 21) * 0.75)))
    end
end

local function drawDryBrushLine(x1, y1, x2, y2, width, tint, alpha, seed, passes)
    local dx, dy = x2 - x1, y2 - y1
    local len = dist2(dx, dy)
    if len < 0.001 then return end
    local nx, ny = -dy / len, dx / len
    local tx, ty = dx / len, dy / len
    local count = passes or 3
    for p = 1, count do
        local s = seed + p * 41
        local off = (hash01(s) - 0.5) * width * 0.95
        local pull1 = (hash01(s + 5) - 0.5) * width * 0.45
        local pull2 = (hash01(s + 9) - 0.5) * width * 0.45
        strokeLine(
            x1 + nx * off + tx * pull1, y1 + ny * off + ty * pull1,
            x2 + nx * (off + (hash01(s + 13) - 0.5) * width * 0.28) + tx * pull2,
            y2 + ny * (off + (hash01(s + 17) - 0.5) * width * 0.28) + ty * pull2,
            math.max(0.7, width * (0.18 + hash01(s + 21) * 0.38)),
            colorRGBA(tint, alpha * (0.42 + hash01(s + 25) * 0.58))
        )
    end
    local bristles = math.max(2, math.floor(len / 85))
    for i = 1, bristles do
        local s = seed + i * 59
        local t = hash01(s)
        local cx = x1 + dx * t
        local cy = y1 + dy * t
        local side = hash01(s + 3) > 0.5 and 1 or -1
        local blen = width * (0.8 + hash01(s + 7) * 1.8)
        strokeLine(cx, cy, cx + nx * side * blen + tx * (hash01(s + 11) - 0.5) * width, cy + ny * side * blen + ty * (hash01(s + 15) - 0.5) * width, 0.8, colorRGBA(tint, alpha * 0.34))
    end
end

local function drawInkContour(points, tint, alpha, width, seed)
    for i = 1, #points do
        local a = points[i]
        local b = points[(i % #points) + 1]
        drawDryBrushLine(a[1], a[2], b[1], b[2], width, tint, alpha, seed + i * 71, 2)
    end
end

local function fillBrushRibbon(list, tint, alpha, seed)
    if #list < 2 then return end
    nvgBeginPath(vg)
    for i = 1, #list do
        local n = list[i]
        local rough = 1 + (hash01(seed + i * 13) - 0.5) * 0.18
        local side = n.r * rough
        local x = n.x + n.normX * side
        local y = n.y + n.normY * side
        if i == 1 then nvgMoveTo(vg, x, y) else nvgLineTo(vg, x, y) end
    end
    for i = #list, 1, -1 do
        local n = list[i]
        local rough = 1 + (hash01(seed + i * 17) - 0.5) * 0.20
        local side = n.r * rough
        nvgLineTo(vg, n.x - n.normX * side, n.y - n.normY * side)
    end
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)

    local step = math.max(7, math.floor(#list / 16))
    for i = 2, #list - 1, step do
        local n = list[i]
        drawInkBleed(n.x, n.y, n.r * 1.7, n.r * 0.85, tint, 24, seed + i * 29, 3)
    end
    for i = 4, #list - 2, step + 2 do
        local n1 = list[i]
        local n2 = list[math.min(#list, i + 3)]
        drawDryBrushLine(n1.x - n1.normX * n1.r * 0.18, n1.y - n1.normY * n1.r * 0.18, n2.x - n2.normX * n2.r * 0.12, n2.y - n2.normY * n2.r * 0.12, 1.0, currentLevel.paper, 42, seed + i * 43, 1)
    end
end

local function drawRockShape(x, y, w, h, fillColor, strokeColor)
    local points = {
        { x, y + h },
        { x + w * 0.10, y + h * 0.40 },
        { x + w * 0.30, y + h * 0.10 },
        { x + w * 0.50, y + h * 0.20 },
        { x + w * 0.70, y },
        { x + w * 0.85, y + h * 0.30 },
        { x + w, y + h },
    }
    fillPoly(points, fillColor)
    drawInkBleed(x + w * 0.45, y + h * 0.55, w * 0.42, h * 0.28, currentLevel.ink, 34, x * 0.017 + y * 0.013, 5)
    nvgBeginPath(vg)
    nvgMoveTo(vg, points[1][1], points[1][2])
    for i = 2, #points do nvgLineTo(vg, points[i][1], points[i][2]) end
    nvgClosePath(vg)
    nvgStrokeColor(vg, strokeColor)
    nvgStrokeWidth(vg, 4)
    nvgStroke(vg)
    for i = 1, 16 do
        local rx = x + hash01(x * 0.01 + i * 7) * w
        local ry = y + hash01(y * 0.01 + i * 11) * h
        strokeLine(rx, ry, rx + (hash01(i * 17) - 0.5) * w * 0.30, ry + hash01(i * 19) * h * 0.30, 2, rgba(10, 8, 5, 65))
    end
    drawInkContour(points, currentLevel.ink, 150, 4.5, x * 0.021 + y * 0.019)
    drawInkSpeckles(x + w * 0.05, y + h * 0.08, w * 0.88, h * 0.80, currentLevel.ink, 120, x * 0.009 + y * 0.011, 42)
    for i = 1, 24 do
        drawRotEllipse(x + hash01(i * 23 + w) * w, y + hash01(i * 29 + h) * h * 0.8, 2 + hash01(i * 31) * 5, 1.5 + hash01(i * 37) * 3, hash01(i) * math.pi, rgba(15, 12, 10, 160))
    end
end

local function strokeWavyStream(x1, y1, x2, y2, offset, waveAmp, waveFreq, width, color)
    nvgBeginPath(vg)
    for i = 0, 44 do
        local t = i / 44
        local x = x1 + (x2 - x1) * t
        local y = y1 + (y2 - y1) * t + math.sin(t * waveFreq + offset * 0.18) * waveAmp + offset
        if i == 0 then nvgMoveTo(vg, x, y) else nvgLineTo(vg, x, y) end
    end
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function drawCascadeSpringWash(x1, y1, x2, y2, width)
    strokeWavyStream(x1, y1, x2, y2, -width * 0.5, 8, 15, 4.0, rgba(35, 45, 40, 76))
    strokeWavyStream(x1, y1, x2, y2, width * 0.5, 8, 15, 4.0, rgba(35, 45, 40, 76))
    for _, off in ipairs({ -18, -10, -3, 4, 12, 20 }) do
        strokeWavyStream(x1, y1, x2, y2, off, 6, 15, 1.7, rgba(255, 255, 255, 190))
    end
    for i = 1, 16 do
        local t = hash01(i * 27)
        local x = x1 + (x2 - x1) * t + (hash01(i * 31) - 0.5) * width
        local y = y1 + (y2 - y1) * t + math.sin(t * 15) * 10
        drawRotEllipse(x, y, 18 + hash01(i * 37) * 32, 4 + hash01(i * 41) * 8, -0.35, rgba(244, 246, 236, 62))
    end
end

local function drawWaterfallWash()
    local x, w = W(0.36), W(0.28)
    drawRect(x - 170, H(0.02), w + 340, H(0.90), 0, rgba(248, 252, 248, 70))
    strokeLine(x - 104, H(0.04), x - 140, H(0.92), 2.0, rgba(220, 232, 224, 96))
    strokeLine(x + w + 104, H(0.03), x + w + 132, H(0.90), 2.0, rgba(220, 232, 224, 88))
    for i = 1, 72 do
        local px = x - 58 + hash01(i * 14) * (w + 116)
        local yy = H(0.03) + ((elapsed * 188 + i * 37) % H(0.98))
        strokeLine(px, yy - 188, px + math.sin(elapsed * 1.55 + i) * 24, yy + 218, 1.2 + hash01(i) * 3.7, rgba(236, 244, 236, 108))
    end
    for i = 0, 12 do
        local t = i / 12
        drawRect(x - 205, H(0.50) + H(0.50) * t, w + 410, H(0.50) / 12 + 4, 0, rgba(232, 238, 230, 12 + t * 112))
    end
    for i = 1, 24 do
        local px = x - 135 + hash01(330 + i * 13) * (w + 270)
        local py = H(0.03 + hash01(340 + i * 17) * 0.15)
        drawRotEllipse(px, py, 60 + hash01(350 + i) * 145, 10 + hash01(360 + i) * 30, (hash01(370 + i) - 0.5) * 0.25, rgba(248, 252, 248, 40 + hash01(380 + i) * 56))
    end
    drawMistBand(316, 34, currentLevel.paper, 32, 0.45, 0.98, 160, 470, 18, 88)
end

local function drawAxCutCliff(baseX, baseY, topX, topY, dir)
    fillPoly({
        { baseX - dir * 300, baseY },
        { baseX, baseY },
        { topX, topY },
        { topX - dir * 300, topY },
    }, rgba(35, 42, 38, 232))
    for i = 0, 39 do
        local t = i / 39
        local edgeX = baseX + (topX - baseX) * t
        local edgeY = baseY + (topY - baseY) * t
        local len = 50 + hash01(400 + i * 7) * 150
        drawDryBrushLine(edgeX, edgeY, edgeX - dir * len * 0.7, edgeY + len, 2 + hash01(410 + i) * 6, C(10, 15, 12), 190, 410 + i * 13, 2)
        strokeLine(edgeX, edgeY, edgeX - dir * len * 0.9, edgeY + len * 0.8, 1 + hash01(430 + i) * 2, rgba(10, 15, 12, 75))
    end
    for i = 1, 36 do
        local t = hash01(470 + i * 7)
        local edgeX = baseX + (topX - baseX) * t
        local edgeY = baseY + (topY - baseY) * t
        local sx = edgeX - dir * (25 + hash01(480 + i) * 180)
        local sy = edgeY + hash01(490 + i) * 210
        drawRotEllipse(sx, sy, 8 + hash01(500 + i) * 32, 2 + hash01(510 + i) * 8, -dir * (0.65 + hash01(520 + i) * 0.35), rgba(7, 12, 9, 52 + hash01(530 + i) * 46))
    end
end

local function drawRaindropCliff(x, y, w, h, facingLeft, fillColor)
    local dir = facingLeft and -1 or 1
    local points = {
        { x, y + h },
        { x + (facingLeft and w * 0.10 or w * 0.90), y + h * 0.60 },
        { x + (facingLeft and w * 0.30 or w * 0.70), y + h * 0.35 },
        { x + (facingLeft and w * 0.15 or w * 0.85), y + h * 0.15 },
        { x + (facingLeft and 0 or w), y },
        { x + (facingLeft and -100 or w + 100), y },
        { x + (facingLeft and -100 or w + 100), y + h },
    }
    fillPoly(points, fillColor)
    drawInkSpeckles(x + w * 0.05, y + h * 0.05, w * 0.82, h * 0.82, C(12, 18, 14), 54, x * 0.011 + y * 0.019, 34)
    nvgBeginPath(vg)
    nvgMoveTo(vg, points[1][1], points[1][2])
    for i = 2, #points do nvgLineTo(vg, points[i][1], points[i][2]) end
    nvgClosePath(vg)
    nvgStrokeColor(vg, rgba(10, 12, 10, 225))
    nvgStrokeWidth(vg, 5)
    nvgStroke(vg)
    for i = 1, 70 do
        local rx = x + hash01(i * 11 + w) * w
        local ry = y + hash01(i * 13 + h) * h
        local len = 10 + hash01(i * 17) * 40
        drawDryBrushLine(rx, ry, rx + (hash01(i * 19) - 0.5) * 3, ry + len, 1.5, C(8, 10, 8), 94, i * 31 + w, 1)
    end
    drawInkContour(points, C(10, 12, 10), 152, 4.0, x * 0.017 + y * 0.013)
    drawInkSpeckles(x, y, w, h * 0.9, C(10, 12, 10), 130, x * 0.007 + h * 0.01, 46)
    for i = 1, 28 do
        drawRotEllipse(x + hash01(i * 23) * w, y + hash01(i * 29) * h * 0.9, 2 + hash01(i * 31) * 5, 1.5 + hash01(i * 37) * 3, hash01(i) * math.pi, rgba(10, 12, 10, 170))
    end
end

local function drawSpires(x, y, w, h, facingLeft)
    drawRaindropCliff(x, y, w, h, facingLeft, rgba(42, 48, 44, 215))
    local sign = facingLeft and -1 or 1
    for i = 1, 36 do
        local rx = x + hash01(i * 43 + w) * w
        local ry = y + hash01(i * 47 + h) * h
        local len = 15 + hash01(i * 53) * 45
        strokeLine(rx, ry, rx + sign * len, ry, 1.8, rgba(10, 15, 12, 85))
        strokeLine(rx + sign * len, ry, rx + sign * len * 1.2, ry + hash01(i * 59) * 20, 1.8, rgba(10, 15, 12, 70))
    end
end

local function drawAutumnLeaf(x, y, s, color)
    fillPoly({
        { x, y - s }, { x + s * 0.45, y - s * 0.25 }, { x + s, y },
        { x + s * 0.22, y + s * 0.18 }, { x + s * 0.12, y + s },
        { x - s * 0.25, y + s * 0.28 }, { x - s, y + s * 0.10 },
        { x - s * 0.34, y - s * 0.18 },
    }, color)
    strokeLine(x - s * 0.10, y - s * 0.50, x + s * 0.08, y + s * 0.72, 1.0, rgba(86, 24, 18, 85))
end

local function drawSpringWater()
    drawVerticalWash(waterLevel - H(0.06), worldH - waterLevel + H(0.06), C(206, 221, 202), currentLevel.water, 34, 96, 18)
    for i = 1, 30 do
        local y = waterLevel + i * 12
        local off = math.sin(elapsed * 1.8 + i) * 3
        strokeLine(W(0.02), y + off, W(0.98), y + off, i % 4 == 0 and 2.0 or 1.0, colorRGBA(currentLevel.water, 48 + (i % 4) * 10))
    end
    for i = 1, 42 do
        local x = (hash01(i * 42) * worldW + elapsed * (12 + i % 6)) % worldW
        local y = waterLevel + hash01(i * 77) * 58 - 18
        nvgBeginPath(vg)
        nvgEllipse(vg, x, y, 22 + hash01(i * 17) * 46, 3 + hash01(i * 9) * 7)
        nvgStrokeColor(vg, rgba(242, 236, 218, 64))
        nvgStrokeWidth(vg, 1.3)
        nvgStroke(vg)
    end
    for i = 1, 38 do
        local x = hash01(i * 101) * worldW
        local y = H(0.14) + hash01(i * 103) * H(0.46)
        strokeLine(x, y, x + 24 + hash01(i * 107) * 60, y + 5 + hash01(i * 109) * 18, 0.9, rgba(245, 239, 220, 62))
    end
end

local function drawCloudSea()
    drawVerticalWash(H(0.52), H(0.48), C(235, 240, 232), C(245, 248, 244), 18, 92, 18)
    for i = 1, 38 do
        local x = hash01(1500 + i * 11) * worldW
        local y = H(0.55 + hash01(1500 + i * 13) * 0.32)
        local rx = 170 + hash01(1500 + i * 17) * 360
        local ry = 26 + hash01(1500 + i * 19) * 72
        drawRotEllipse(x, y, rx, ry, (hash01(1500 + i * 23) - 0.5) * 0.16, rgba(244, 248, 244, 96 + hash01(i) * 70))
    end
    for i = 1, 20 do
        local y = H(0.60 + i * 0.015)
        strokeLine(0, y + math.sin(elapsed + i) * 2, worldW, y + math.sin(elapsed + i) * 2, 1.0, rgba(190, 207, 198, 28))
    end
end

local function drawMasterPlumTexture(x, y, w, h, seed, count, alpha)
    for i = 1, count do
        local s = seed + i * 17
        local px = x + hash01(s) * w
        local py = y + hash01(s + 3) * h
        local len = 8 + hash01(s + 7) * 24
        drawDryBrushLine(px, py, px + (hash01(s + 11) - 0.5) * 8, py + len, 1.0 + hash01(s + 13) * 1.8, currentLevel.ink, alpha * (0.45 + hash01(s + 19) * 0.65), s, 1)
    end
end

local function drawMasterPlumProceduralBackground()
    drawVerticalWash(0, worldH, C(224, 218, 200), C(188, 178, 154), 56, 78, 34)
    drawMistBand(1880, 18, C(232, 225, 207), 24, 0.12, 0.92, 80, 260, 24, 92)
    drawMasterPlumTexture(W(0.04), H(0.06), W(0.88), H(0.88), 1900, 130, 56)
    strokeQuad(W(0.08), H(0.82), W(0.40), H(0.62), W(0.88), H(0.48), 42, rgba(32, 26, 22, 118))
    strokeQuad(W(0.28), H(0.76), W(0.10), H(0.54), W(0.08), H(0.36), 18, rgba(32, 26, 22, 92))
    strokeQuad(W(0.50), H(0.68), W(0.68), H(0.45), W(0.75), H(0.28), 14, rgba(32, 26, 22, 86))
end

local function drawMasterPlumBackground()
    local hasImage = drawMasterPlumReferenceImage()
    if hasImage then
        return
    end
    drawMasterPlumProceduralBackground()
end

-- ============================================================================
-- 多层视差背景系统 - 梅影重楼 (plum_parallax)
-- 参考风格: 深蓝夜色水墨 + 多层建筑剪影 + 流动云雾
-- ============================================================================
do -- parallax scope (避免顶层 local 变量超200限制)

local function parallaxOffset(factor)
    -- factor: 0=固定在屏幕(不随相机动), 1=完全跟随世界(正常)
    -- 当前已经在 camera transform 内, 所以需要补偿: offset = cameraX * (1 - factor)
    return cameraX * (1 - factor), cameraY * (1 - factor)
end

local function drawParallaxPagoda(cx, baseY, w, h, tint, alpha)
    -- 宝塔剪影: 多层飞檐逐级收窄
    local floors = 5
    local floorH = h / (floors + 1)
    local topW = w * 0.25
    -- 塔身
    for f = 0, floors - 1 do
        local t = f / floors
        local fw = w * (1 - t * 0.65) -- 逐级变窄
        local fy = baseY - f * floorH
        local eaveW = fw * 1.35  -- 飞檐比塔身宽
        -- 楼层主体
        drawRect(cx - fw * 0.5, fy - floorH, fw, floorH, 0, colorRGBA(tint, alpha))
        -- 飞檐
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx - eaveW * 0.5, fy)
        nvgQuadTo(vg, cx - eaveW * 0.45, fy - floorH * 0.15, cx - fw * 0.5, fy - floorH * 0.05)
        nvgLineTo(vg, cx + fw * 0.5, fy - floorH * 0.05)
        nvgQuadTo(vg, cx + eaveW * 0.45, fy - floorH * 0.15, cx + eaveW * 0.5, fy)
        nvgClosePath(vg)
        nvgFillColor(vg, colorRGBA(tint, alpha))
        nvgFill(vg)
        -- 檐角上翘
        local tipY = fy - floorH * 0.12
        strokeLine(cx - eaveW * 0.5, fy, cx - eaveW * 0.55, tipY, 2.0, colorRGBA(tint, alpha))
        strokeLine(cx + eaveW * 0.5, fy, cx + eaveW * 0.55, tipY, 2.0, colorRGBA(tint, alpha))
    end
    -- 塔顶尖刹
    local spireBase = baseY - floors * floorH
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - topW * 0.15, spireBase)
    nvgLineTo(vg, cx, spireBase - floorH * 1.2)
    nvgLineTo(vg, cx + topW * 0.15, spireBase)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 宝珠
    drawEllipse(cx, spireBase - floorH * 1.35, topW * 0.2, topW * 0.2, colorRGBA(tint, alpha))
end

local function drawParallaxArch(cx, baseY, w, h, tint, alpha)
    -- 拱桥/拱门剪影
    local pillarW = w * 0.08
    local archH = h * 0.7
    -- 左右柱子
    drawRect(cx - w * 0.5, baseY - h, pillarW, h, 0, colorRGBA(tint, alpha))
    drawRect(cx + w * 0.5 - pillarW, baseY - h, pillarW, h, 0, colorRGBA(tint, alpha))
    -- 拱形顶
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - w * 0.5, baseY - archH)
    nvgBezierTo(vg, cx - w * 0.3, baseY - h - h * 0.15, cx + w * 0.3, baseY - h - h * 0.15, cx + w * 0.5, baseY - archH)
    nvgLineTo(vg, cx + w * 0.5, baseY - archH + pillarW)
    nvgBezierTo(vg, cx + w * 0.25, baseY - h - h * 0.05, cx - w * 0.25, baseY - h - h * 0.05, cx - w * 0.5, baseY - archH + pillarW)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 横梁
    drawRect(cx - w * 0.5, baseY - archH, w, pillarW * 0.6, 0, colorRGBA(tint, alpha))
end

local function drawParallaxPavilion(cx, baseY, w, h, tint, alpha)
    -- 亭台剪影: 两层飞檐 + 柱子
    local roofH = h * 0.35
    local bodyH = h * 0.45
    local topH = h * 0.2
    local roofW = w * 1.3
    local topRoofW = w * 0.7
    -- 柱子
    local pillarCount = 4
    for i = 0, pillarCount - 1 do
        local px = cx - w * 0.4 + i * (w * 0.8 / (pillarCount - 1))
        drawRect(px - 2, baseY - bodyH - roofH, 4, bodyH, 0, colorRGBA(tint, alpha))
    end
    -- 底层大屋顶
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - roofW * 0.5, baseY - bodyH)
    nvgQuadTo(vg, cx - roofW * 0.3, baseY - bodyH - roofH * 0.8, cx, baseY - bodyH - roofH)
    nvgQuadTo(vg, cx + roofW * 0.3, baseY - bodyH - roofH * 0.8, cx + roofW * 0.5, baseY - bodyH)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 上层小顶
    nvgBeginPath(vg)
    nvgMoveTo(vg, cx - topRoofW * 0.5, baseY - bodyH - roofH)
    nvgQuadTo(vg, cx - topRoofW * 0.25, baseY - bodyH - roofH - topH * 0.7, cx, baseY - bodyH - roofH - topH)
    nvgQuadTo(vg, cx + topRoofW * 0.25, baseY - bodyH - roofH - topH * 0.7, cx + topRoofW * 0.5, baseY - bodyH - roofH)
    nvgClosePath(vg)
    nvgFillColor(vg, colorRGBA(tint, alpha))
    nvgFill(vg)
    -- 飞檐角翘
    strokeLine(cx - roofW * 0.5, baseY - bodyH, cx - roofW * 0.55, baseY - bodyH - roofH * 0.2, 2, colorRGBA(tint, alpha))
    strokeLine(cx + roofW * 0.5, baseY - bodyH, cx + roofW * 0.55, baseY - bodyH - roofH * 0.2, 2, colorRGBA(tint, alpha))
end

local function drawParallaxBridge(x1, x2, y, tint, alpha)
    -- 石桥剪影
    local w = x2 - x1
    local railH = 18
    local deckH = 8
    -- 桥面
    drawRect(x1, y, w, deckH, 0, colorRGBA(tint, alpha))
    -- 栏杆
    drawRect(x1, y - railH, w, 3, 0, colorRGBA(tint, alpha))
    -- 栏杆柱
    local spacing = 30
    for x = x1, x2, spacing do
        drawRect(x, y - railH, 3, railH, 0, colorRGBA(tint, alpha))
    end
    -- 拱形桥洞
    local archCount = math.max(1, math.floor(w / 120))
    local archW = w / archCount
    for i = 0, archCount - 1 do
        local acx = x1 + archW * (i + 0.5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, acx - archW * 0.35, y + deckH)
        nvgBezierTo(vg, acx - archW * 0.2, y + deckH + 40, acx + archW * 0.2, y + deckH + 40, acx + archW * 0.35, y + deckH)
        nvgStrokeColor(vg, colorRGBA(tint, alpha))
        nvgStrokeWidth(vg, 3)
        nvgStroke(vg)
    end
end

local function drawParallaxStele(cx, baseY, w, h, tint, alpha)
    -- 碑石/石柱剪影
    -- 柱身
    drawRect(cx - w * 0.5, baseY - h, w, h, 0, colorRGBA(tint, alpha))
    -- 顶部装饰（圆球或尖顶）
    drawEllipse(cx, baseY - h - w * 0.3, w * 0.4, w * 0.4, colorRGBA(tint, alpha))
    -- 基座
    drawRect(cx - w * 0.7, baseY - h * 0.05, w * 1.4, h * 0.05, 0, colorRGBA(tint, alpha))
end

local function drawParallaxSwirlCloud(cx, cy, rx, ry, tint, alpha, seed)
    -- 水墨卷云纹
    drawRotEllipse(cx, cy, rx, ry, 0, colorRGBA(tint, alpha * 0.6))
    -- 卷曲尾巴
    local arms = 2 + math.floor(hash01(seed) * 2)
    for a = 1, arms do
        local angle = (a / arms) * math.pi * 2 + hash01(seed + a) * 1.5
        local spiralLen = rx * (0.8 + hash01(seed + a * 7) * 0.6)
        nvgBeginPath(vg)
        local steps = 12
        for s = 0, steps do
            local t = s / steps
            local r = rx * 0.3 + spiralLen * t
            local th = angle + t * 2.5 * (hash01(seed + a * 11) > 0.5 and 1 or -1)
            local px = cx + math.cos(th) * r
            local py = cy + math.sin(th) * r * (ry / rx)
            if s == 0 then nvgMoveTo(vg, px, py) else nvgLineTo(vg, px, py) end
        end
        nvgStrokeColor(vg, colorRGBA(tint, alpha * 0.5))
        nvgStrokeWidth(vg, 1.5 + hash01(seed + a * 13) * 1.5)
        nvgStroke(vg)
    end
end

local function drawParallaxLayer(layerIdx, factor, tint, alpha, seed)
    -- 计算视差偏移: 在已应用camera transform的上下文中，补偿偏移实现不同速度
    local offX, offY = parallaxOffset(factor)
    nvgSave(vg)
    nvgTranslate(vg, offX, offY * 0.3) -- Y轴视差弱一些，保持水平为主

    local layerW = worldW * 1.5  -- 层宽度大于世界宽度以覆盖视差范围
    local baseX = -worldW * 0.25 -- 起始偏左

    if layerIdx == 1 then
        -- 远景层: 淡淡的山峦轮廓 + 分散的卷云
        for i = 0, 7 do
            local mh = worldH * (0.15 + hash01(seed + i * 3) * 0.2)
            local mw = layerW * (0.18 + hash01(seed + i * 5) * 0.12)
            local mx = baseX + i * layerW * 0.13
            local my = worldH
            fillPoly({
                { mx, my }, { mx + mw * 0.2, my - mh * 0.5 },
                { mx + mw * 0.45, my - mh }, { mx + mw * 0.7, my - mh * 0.6 },
                { mx + mw, my },
            }, colorRGBA(tint, alpha * 0.5))
        end
        -- 远景卷云
        for i = 1, 12 do
            local cx = baseX + hash01(seed + 100 + i * 11) * layerW
            local cy = worldH * (0.15 + hash01(seed + 100 + i * 13) * 0.45)
            drawParallaxSwirlCloud(cx, cy, 60 + hash01(seed + 100 + i * 17) * 100, 20 + hash01(seed + 100 + i * 19) * 35, tint, alpha * 0.4, seed + i * 31)
        end

    elseif layerIdx == 2 then
        -- 中景层: 建筑剪影（宝塔、拱门、碑石）
        -- 左侧宝塔
        drawParallaxPagoda(baseX + layerW * 0.12, worldH * 0.95, 110, worldH * 0.55, tint, alpha)
        -- 中间拱桥
        drawParallaxBridge(baseX + layerW * 0.25, baseX + layerW * 0.42, worldH * 0.7, tint, alpha * 0.9)
        -- 右侧亭台
        drawParallaxPavilion(baseX + layerW * 0.55, worldH * 0.92, 140, worldH * 0.38, tint, alpha)
        -- 远处碑石群
        for i = 1, 4 do
            local sx = baseX + layerW * (0.65 + i * 0.08)
            local sh = worldH * (0.2 + hash01(seed + 200 + i * 7) * 0.25)
            drawParallaxStele(sx, worldH * 0.95, 22 + hash01(seed + 200 + i * 11) * 18, sh, tint, alpha * 0.85)
        end
        -- 中景云带
        for i = 1, 8 do
            local cx = baseX + hash01(seed + 250 + i * 7) * layerW
            local cy = worldH * (0.4 + hash01(seed + 250 + i * 9) * 0.3)
            drawRotEllipse(cx, cy, 120 + hash01(seed + 250 + i * 13) * 180, 18 + hash01(seed + 250 + i * 17) * 30, (hash01(seed + 250 + i * 19) - 0.5) * 0.2, colorRGBA(tint, alpha * 0.35))
        end

    elseif layerIdx == 3 then
        -- 近景层: 更大的建筑剪影，带细节
        -- 大型拱门群
        drawParallaxArch(baseX + layerW * 0.08, worldH, 160, worldH * 0.6, tint, alpha)
        drawParallaxArch(baseX + layerW * 0.22, worldH, 130, worldH * 0.5, tint, alpha * 0.9)
        -- 宏伟宝塔
        drawParallaxPagoda(baseX + layerW * 0.45, worldH, 150, worldH * 0.7, tint, alpha)
        -- 长桥连接
        drawParallaxBridge(baseX + layerW * 0.58, baseX + layerW * 0.78, worldH * 0.55, tint, alpha * 0.9)
        -- 右侧亭台群
        drawParallaxPavilion(baseX + layerW * 0.82, worldH * 0.9, 180, worldH * 0.45, tint, alpha)
        drawParallaxPavilion(baseX + layerW * 0.95, worldH, 120, worldH * 0.35, tint, alpha * 0.8)
        -- 碑石
        drawParallaxStele(baseX + layerW * 0.35, worldH, 30, worldH * 0.32, tint, alpha * 0.9)
        drawParallaxStele(baseX + layerW * 0.38, worldH, 24, worldH * 0.26, tint, alpha * 0.85)

    elseif layerIdx == 4 then
        -- 前景雾气层: 浓重的云雾覆盖底部
        for i = 1, 18 do
            local cx = baseX + hash01(seed + 400 + i * 7) * layerW
            local cy = worldH * (0.7 + hash01(seed + 400 + i * 9) * 0.28)
            local rx = 180 + hash01(seed + 400 + i * 11) * 320
            local ry = 35 + hash01(seed + 400 + i * 13) * 65
            drawRotEllipse(cx, cy, rx, ry, (hash01(seed + 400 + i * 17) - 0.5) * 0.15, colorRGBA(tint, alpha * 0.6))
        end
        -- 顶部薄雾
        for i = 1, 8 do
            local cx = baseX + hash01(seed + 450 + i * 11) * layerW
            local cy = worldH * (0.05 + hash01(seed + 450 + i * 13) * 0.2)
            local rx = 200 + hash01(seed + 450 + i * 17) * 250
            local ry = 25 + hash01(seed + 450 + i * 19) * 40
            drawRotEllipse(cx, cy, rx, ry, 0, colorRGBA(tint, alpha * 0.4))
        end
        -- 卷云装饰
        for i = 1, 6 do
            local cx = baseX + hash01(seed + 500 + i * 13) * layerW
            local cy = worldH * (0.55 + hash01(seed + 500 + i * 17) * 0.25)
            drawParallaxSwirlCloud(cx, cy, 50 + hash01(seed + 500 + i * 19) * 80, 18 + hash01(seed + 500 + i * 23) * 25, tint, alpha * 0.5, seed + 500 + i)
        end
    end

    nvgRestore(vg)
end

function drawParallaxBackground()
    -- 天空渐变 (固定在视口, 不随相机移动)
    local skyOffX, skyOffY = parallaxOffset(0)
    nvgSave(vg)
    nvgTranslate(vg, skyOffX, skyOffY)
    -- 深蓝渐变天空
    local skyTop = C(8, 18, 42)
    local skyMid = C(22, 48, 88)
    local skyBot = C(55, 105, 155)
    drawVerticalWash(0, worldH * 0.5, skyTop, skyMid, 255, 255, 24)
    drawVerticalWash(worldH * 0.5, worldH * 0.5, skyMid, skyBot, 255, 180, 24)
    nvgRestore(vg)

    -- 层1: 远景山峦与卷云 (0.05x 视差 - 几乎不动)
    local farTint = C(40, 70, 115)
    drawParallaxLayer(1, 0.05, farTint, 90, 1100)

    -- 层2: 中景建筑剪影 (0.25x 视差)
    local midTint = C(50, 80, 130)
    drawParallaxLayer(2, 0.25, midTint, 130, 1200)

    -- 中间云雾分隔带 (0.15x 视差)
    local mistOffX, mistOffY = parallaxOffset(0.15)
    nvgSave(vg)
    nvgTranslate(vg, mistOffX, mistOffY * 0.2)
    for i = 1, 15 do
        local cx = -worldW * 0.2 + hash01(1300 + i * 11) * worldW * 1.4
        local cy = worldH * (0.35 + hash01(1300 + i * 13) * 0.2)
        local rx = 200 + hash01(1300 + i * 17) * 400
        local ry = 30 + hash01(1300 + i * 19) * 60
        drawRotEllipse(cx, cy, rx, ry, (hash01(1300 + i * 23) - 0.5) * 0.15, rgba(70, 120, 175, 55 + hash01(1300 + i) * 40))
    end
    nvgRestore(vg)

    -- 层3: 近景建筑剪影 (0.50x 视差)
    local nearTint = C(30, 50, 90)
    drawParallaxLayer(3, 0.50, nearTint, 180, 1400)

    -- 层4: 前景雾气 (0.80x 视差 - 接近跟随相机)
    local fogTint = C(100, 155, 200)
    drawParallaxLayer(4, 0.80, fogTint, 70, 1500)

    -- 游戏世界底部的纸纹（正常世界坐标，跟随相机）
    -- 轻微的纸纹质感覆盖
    for i = 1, 40 do
        local x = hash01(i * 37 + 1600) * worldW
        local y = hash01(i * 41 + 1600) * worldH
        local len = 15 + hash01(i * 43 + 1600) * 50
        local a = -0.5 + (hash01(i * 47 + 1600) - 0.5) * 0.4
        strokeLine(x, y, x + math.cos(a) * len, y + math.sin(a) * len, 0.5, rgba(80, 130, 180, 12 + hash01(i * 51 + 1600) * 14))
    end
end
end -- parallax scope

local function drawBackground()
    if currentLevel.id == "bamboo" then
        fillPoly({
            { 0, worldH }, { 0, H(0.40) },
            { W(0.20), H(0.20) }, { W(0.40), H(0.50) },
            { W(0.70), H(0.30) }, { worldW, H(0.60) },
            { worldW, worldH },
        }, rgba(120, 135, 125, 20))
        drawMountainBandAt(300, 5, C(120, 135, 125), 8, 0.24, 0.20, 0.24, 0.42, -240)
        drawAxCutCliff(W(0.20), worldH, W(0.40), H(0.20), -1)
        drawAxCutCliff(W(0.55), worldH, W(0.75), H(0.10), 1)
        drawWaterfallWash()
    elseif currentLevel.id == "pine" then
        drawMountainBandAt(510, 6, C(110, 125, 115), 8, 0.28, 0.30, 0.18, 0.45, -200)
        drawMistBand(520, 18, currentLevel.paper, 32, 0.10, 0.72, 150, 450, 20, 80)
        drawRaindropCliff(0, H(0.50), W(0.12), H(0.50), true, rgba(35, 38, 35, 220))
        drawRaindropCliff(W(0.88), H(0.40), W(0.12), H(0.60), false, rgba(35, 38, 35, 220))
        drawCascadeSpringWash(W(0.30), H(0.20), W(0.50), H(0.80), 85)
        if currentLevelIsInkLab and currentLevelIsInkLab() then drawInkLabPineBackground() end
    elseif currentLevel.id == "maple" then
        drawVerticalWash(0, H(0.75), C(225, 185, 140), C(247, 238, 219), 96, 0, 22)
        drawMountainBandAt(610, 6, C(155, 120, 95), 10, 0.28, 0.30, 0.20, 0.48, -300)
        drawMistBand(620, 15, C(235, 205, 175), 26, 0.12, 0.68, 150, 400, 20, 70)
        drawRockShape(W(-0.05), H(0.78), W(0.22), H(0.25), rgba(40, 35, 30, 185), rgba(10, 8, 5, 210))
        drawRockShape(W(0.35), H(0.72), W(0.16), H(0.30), rgba(40, 35, 30, 165), rgba(10, 8, 5, 190))
        for i = 1, 62 do
            local x = (hash01(i * 73) * worldW + elapsed * (9 + hash01(i) * 18)) % worldW
            local y = (hash01(i * 79) * worldH + elapsed * (12 + hash01(i * 3) * 26)) % worldH
            local s = 5 + hash01(i * 83) * 12
            drawAutumnLeaf(x, y, s, rgba(195, 22, 22, 42 + hash01(i) * 95))
        end
    elseif currentLevel.id == "plum" then
        drawVerticalWash(0, H(0.52), C(235, 229, 218), currentLevel.paper, 36, 0, 16)
        drawMountainBandAt(710, 6, C(135, 142, 135), 8, 0.25, 0.30, 0.20, 0.48, -300)
        drawMistBand(720, 16, C(215, 205, 185), 20, 0.12, 0.70, 150, 400, 20, 70)
        drawRect(W(0.035), H(0.12), W(0.19), H(0.60), 0, rgba(42, 30, 24, 10))
        for i = 0, 3 do
            strokeLine(W(0.06 + i * 0.04), H(0.24), W(0.06 + i * 0.04), H(0.66), 1.2, rgba(42, 30, 24, 48))
            strokeLine(W(0.06 + i * 0.04) + 7, H(0.24), W(0.06 + i * 0.04) + 7, H(0.66), 0.7, rgba(42, 30, 24, 20))
        end
    elseif currentLevel.id == "plum_mirror" then
        drawVerticalWash(0, H(0.52), C(235, 229, 218), currentLevel.paper, 36, 0, 16)
        drawMountainBandAt(710, 6, C(135, 142, 135), 8, 0.25, 0.30, 0.20, 0.48, -300)
        drawMistBand(720, 16, C(215, 205, 185), 20, 0.12, 0.70, 150, 400, 20, 70)
        drawRect(W(0.775), H(0.12), W(0.19), H(0.60), 0, rgba(42, 30, 24, 10))
        for i = 0, 3 do
            strokeLine(W(0.82 + i * 0.04), H(0.24), W(0.82 + i * 0.04), H(0.66), 1.2, rgba(42, 30, 24, 48))
            strokeLine(W(0.82 + i * 0.04) + 7, H(0.24), W(0.82 + i * 0.04) + 7, H(0.66), 0.7, rgba(42, 30, 24, 20))
        end
    elseif currentLevel.id == "plum_finale" then
        -- 母本复刻：王冕《梅竹双清卷》梅段的旧纸底——无山无雾，只有岁月斑驳的卷纸、
        -- 鉴藏朱印与右壁满纸行书。印章位置按母本描取。
        drawVerticalWash(0, worldH, C(205, 180, 140), currentLevel.paper, 26, 10, 12)
        -- 旧纸的水渍与霉斑
        for i = 1, 14 do
            local sx = hash01(i * 37.7) * worldW
            local sy = hash01(i * 53.3) * worldH
            drawInkBleed(sx, sy, 60 + hash01(i * 17) * 160, 40 + hash01(i * 23) * 90, C(168, 142, 102), 7 + hash01(i * 29) * 7, i * 7.1, 2)
        end
        -- 鉴藏印（仿乾隆鉴藏诸玺布局）：圆玺——细环 + 印泥斑点，避免大色块
        local rsX, rsY, rsR = W(0.665), H(0.095), W(0.052)
        drawCircle(rsX, rsY, rsR, rgba(186, 72, 48, 30))
        drawCircle(rsX, rsY, rsR - 4, colorRGBA(currentLevel.paper, 235))
        drawInkSpeckles(rsX - rsR * 0.8, rsY - rsR * 0.8, rsR * 1.6, rsR * 1.6, C(186, 72, 48), 64, 311.7, 22)
        -- 方玺两枚（描边 + 印文斑点）
        for _, s in ipairs({
            { 0.585, 0.275, 0.095, 0.150 },
            { 0.505, 0.455, 0.055, 0.100 },
        }) do
            local x1, y1, w1, h1 = W(s[1]), H(s[2]), W(s[3]), H(s[4])
            drawRect(x1, y1, w1, h1, 0, rgba(186, 72, 48, 9))
            strokeLine(x1, y1, x1 + w1, y1, 2.2, rgba(186, 72, 48, 46))
            strokeLine(x1 + w1, y1, x1 + w1, y1 + h1, 2.2, rgba(186, 72, 48, 46))
            strokeLine(x1 + w1, y1 + h1, x1, y1 + h1, 2.2, rgba(186, 72, 48, 46))
            strokeLine(x1, y1 + h1, x1, y1, 2.2, rgba(186, 72, 48, 46))
            drawInkSpeckles(x1 + 6, y1 + 6, w1 - 12, h1 - 12, C(186, 72, 48), 52, s[1] * 97.3, 26)
        end
        -- 边角小印（左缘与左下角，仿历代收传印记）
        for _, s in ipairs({
            { 0.006, 0.300, 0.020, 0.045 }, { 0.006, 0.360, 0.020, 0.040 },
            { 0.022, 0.800, 0.030, 0.055 }, { 0.060, 0.840, 0.026, 0.048 },
            { 0.014, 0.880, 0.034, 0.060 },
        }) do
            drawRect(W(s[1]), H(s[2]), W(s[3]), H(s[4]), 0, rgba(186, 72, 48, 26))
            drawInkSpeckles(W(s[1]), H(s[2]), W(s[3]), H(s[4]), currentLevel.paper, 150, s[2] * 131.1, 12)
        end
        -- 右壁满纸行书（题诗柱的纸面墨痕：三主柱 + 两道残柱）
        for i = 0, 4 do
            local colX = W(0.806 + i * 0.045)
            local topY, botY = H(0.080 + hash01(i * 13.7) * 0.030), H(0.780 - hash01(i * 19.3) * 0.040)
            if i == 1 then colX = W(0.866) end
            if i == 2 then colX = W(0.926) end
            if i > 2 then colX = W(0.962 + (i - 3) * 0.022) end
            strokeLine(colX + 8, topY, colX + 8, botY, 0.8, rgba(56, 46, 36, 20))
            -- 行书字团：沿柱身的浓淡墨点
            local steps = i > 2 and 9 or 14
            for k = 0, steps do
                local cy = topY + (botY - topY) * k / steps
                local seed = i * 71.3 + k * 13.9
                drawInkBleed(colX + (hash01(seed) - 0.5) * 10, cy, 7 + hash01(seed + 3) * 9, 5 + hash01(seed + 7) * 7, C(56, 46, 36), 26 + hash01(seed + 11) * 30, seed, 2)
            end
        end
        -- 极疏的飘瓣（白描花瓣偶然离枝）
        for i = 1, 12 do
            local drift = elapsed * (5 + hash01(i * 13) * 8)
            local x = (hash01(i * 67) * worldW - drift) % worldW
            local y = (hash01(i * 71) * worldH + drift * 0.55) % worldH
            local s = 3.5 + hash01(i * 77) * 4
            local a = 20 + hash01(i * 83) * 34
            drawTinyBlossom(x, y, s, C(238, 230, 212), C(222, 210, 188), C(90, 75, 58), i * 91.3, a, 5)
        end
    elseif currentLevel.id == "peach" then
        drawVerticalWash(0, worldH, C(160, 184, 163), C(242, 230, 208), 126, 0, 30)
        drawMountainBandAt(810, 5, C(85, 115, 95), 13, 0.28, 0.35, 0.22, 0.45, -200)
        drawMistBand(820, 15, C(240, 235, 215), 22, 0.10, 0.66, 150, 400, 20, 70)
        drawRockShape(W(-0.05), H(0.78), W(0.22), H(0.25), rgba(40, 35, 30, 175), rgba(10, 8, 5, 205))
        drawRockShape(W(0.35), H(0.72), W(0.16), H(0.30), rgba(40, 35, 30, 145), rgba(10, 8, 5, 180))
        drawSpringWater()
    elseif currentLevel.id == "eaves" then
        drawVerticalWash(0, worldH, C(22, 33, 26), currentLevel.paper, 92, 0, 26)
        drawMountainBandAt(910, 5, C(28, 76, 120), 16, 0.24, 0.28, 0.22, 0.46, -300)
        drawMountainBandAt(940, 5, C(38, 120, 76), 13, 0.30, 0.28, 0.20, 0.44, -220)
        drawMistBand(920, 15, C(230, 210, 180), 26, 0.12, 0.70, 150, 400, 20, 70)
        for i = 1, 30 do
            local x = hash01(950 + i * 17) * worldW
            local y = hash01(950 + i * 23) * H(0.74)
            local len = 44 + hash01(950 + i * 29) * 120
            strokeLine(x, y, x + len, y - 5 - hash01(950 + i * 31) * 20, 1.0, rgba(218, 165, 32, 24 + hash01(i) * 34))
        end
        for i = 0, 5 do
            local x = W(0.08 + i * 0.16)
            strokeLine(x, H(0.18), x + W(0.10), H(0.12 + hash01(930 + i) * 0.12), 1.0, rgba(218, 165, 32, 42))
            strokeLine(x + W(0.10), H(0.12 + hash01(930 + i) * 0.12), x + W(0.18), H(0.19), 1.0, rgba(17, 21, 18, 38))
        end
    elseif currentLevel.id == "huangshan" then
        drawVerticalWash(0, worldH, C(196, 209, 200), C(236, 240, 235), 110, 20, 28)
        drawMountainBandAt(1010, 6, C(90, 115, 100), 13, 0.30, 0.25, 0.18, 0.45, -150)
        drawSpires(W(0.00), H(0.50), W(0.15), H(0.50), true)
        drawSpires(W(0.30), H(0.45), W(0.15), H(0.55), false)
        drawSpires(W(0.48), H(0.38), W(0.16), H(0.62), true)
        drawSpires(W(0.85), H(0.30), W(0.15), H(0.70), false)
        drawCloudSea()
    elseif currentLevel.id == "plum_master" then
        drawMasterPlumBackground()
    elseif currentLevel.id == "plum_parallax" then
        drawParallaxBackground()
    elseif currentLevel.id == "molong" then
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
        or currentLevel.id == "xuwei_grape" then
        -- 母本复刻关:素纸/素绢,不画山;只铺岁月痕迹与母本固有的纸面元素
        for i = 1, 12 do
            local sx = hash01(i * 43.7) * worldW
            local sy = hash01(i * 57.3) * worldH
            drawInkBleed(sx, sy, 50 + hash01(i * 19) * 140, 36 + hash01(i * 27) * 80, currentLevel.paper2, 8 + hash01(i * 31) * 7, i * 9.3, 2)
        end
        if currentLevel.id == "wentong_zhu" then
            -- 绢本横丝纹理 + 顶部题跋墨影带
            for i = 0, 26 do
                local y = worldH * i / 26 + hash01(i * 7.7) * 14
                strokeLine(0, y, worldW, y + (hash01(i * 11.3) - 0.5) * 8, 0.6, rgba(120, 92, 50, 14))
            end
            for i = 1, 56 do
                local cx2 = W(0.03 + hash01(i * 13.1) * 0.94)
                local cy2 = H(0.022 + hash01(i * 17.9) * 0.12)
                drawInkBleed(cx2, cy2, 5 + hash01(i * 23) * 7, 7 + hash01(i * 29) * 10, C(30, 24, 16), 30 + hash01(i * 37) * 30, i * 5.7, 2)
            end
        elseif currentLevel.id == "plum_xiyan" then
            -- 右上鉴藏圆玺 + 左下收传印群(位置按母本)
            local rx2, ry2, rr2 = W(0.835), H(0.085), W(0.030)
            drawCircle(rx2, ry2, rr2, rgba(186, 72, 48, 30))
            drawCircle(rx2, ry2, rr2 - 4, colorRGBA(currentLevel.paper, 235))
            drawInkSpeckles(rx2 - rr2 * 0.8, ry2 - rr2 * 0.8, rr2 * 1.6, rr2 * 1.6, C(186, 72, 48), 60, 411.3, 16)
            for _, s in ipairs({
                { 0.020, 0.560, 0.022, 0.045 }, { 0.024, 0.640, 0.020, 0.040 },
                { 0.018, 0.870, 0.026, 0.050 }, { 0.060, 0.900, 0.022, 0.045 },
            }) do
                drawRect(W(s[1]), H(s[2]), W(s[3]), H(s[4]), 0, rgba(186, 72, 48, 26))
                drawInkSpeckles(W(s[1]), H(s[2]), W(s[3]), H(s[4]), currentLevel.paper, 150, s[2] * 97.1, 10)
            end
        end
    else
        drawMountainBand(100, 6, currentLevel.wash, 12, 0.28, 0.30)
    end

    if currentLevel.id == "bamboo" then
        -- waterfall is drawn above with the cliffs so the central paper-white gap stays crisp
    elseif currentLevel.id == "peach" then
        -- spring water is part of the scenic background and already includes its ripple field
    end
end
