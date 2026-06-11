-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function fluidQuadTo(fromX, fromY, cx, cy, x, y)
    nvgBezierTo(
        vg,
        fromX + (cx - fromX) * 0.6667,
        fromY + (cy - fromY) * 0.6667,
        x + (cx - x) * 0.6667,
        y + (cy - y) * 0.6667,
        x,
        y
    )
end

local function fillFluidPath(left, right, color)
    if #left < 2 or #right < 2 then return end
    nvgBeginPath(vg)
    local curX, curY = left[1].x, left[1].y
    nvgMoveTo(vg, curX, curY)
    for i = 2, #left do
        local ctrl = left[i - 1]
        local x = (left[i].x + left[i - 1].x) * 0.5
        local y = (left[i].y + left[i - 1].y) * 0.5
        fluidQuadTo(curX, curY, ctrl.x, ctrl.y, x, y)
        curX, curY = x, y
    end
    nvgLineTo(vg, left[#left].x, left[#left].y)
    nvgLineTo(vg, right[#right].x, right[#right].y)
    curX, curY = right[#right].x, right[#right].y
    for i = #right - 1, 1, -1 do
        local ctrl = right[i + 1]
        local x = (right[i].x + right[i + 1].x) * 0.5
        local y = (right[i].y + right[i + 1].y) * 0.5
        fluidQuadTo(curX, curY, ctrl.x, ctrl.y, x, y)
        curX, curY = x, y
    end
    nvgLineTo(vg, right[1].x, right[1].y)
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawDashFluidRibbon()
    if #dashFluidPoints < 4 then return end
    local outerLeft, outerRight = {}, {}
    local innerLeft, innerRight = {}, {}
    local fiberLines = {}
    local time = elapsed * 1000
    local targetBlend = fluidTrailIsEnhanced() and 1.0 or 0.0
    fluidTrailDashBlend = fluidTrailDashBlend + (targetBlend - fluidTrailDashBlend) * 0.12

    for i = 1, #dashFluidPoints do
        local curr = dashFluidPoints[i]
        local prev = dashFluidPoints[i - 1] or curr
        local next = dashFluidPoints[i + 1] or curr
        local dx, dy = next.x - prev.x, next.y - prev.y
        local len = dist2(dx, dy)
        if len < 0.001 then dx, dy, len = 1, 0, 1 end
        local nx, ny = -dy / len, dx / len
        local t = (i - 1) / math.max(1, #dashFluidPoints - 1)
        local speedScale = 1.0 + math.min(2.0, (curr.velocity or 0) * 0.05)
        local freqScale = 0.012 + fluidTrailDashBlend * 0.024
        local spineNoiseVal = fluidNoise1D(curr.dist * freqScale - time * 0.008, 17) * speedScale
        local spineWiggleAmp = (9 - fluidTrailDashBlend * 5.5) * (1 - (t - 1) * (t - 1))
        local cx = curr.x + nx * spineNoiseVal * spineWiggleAmp
        local cy = curr.y + ny * spineNoiseVal * spineWiggleAmp
        if i == #dashFluidPoints then
            cx, cy = curr.x, curr.y
        end

        local widthNoiseVal = fluidNoise1D(curr.dist * 0.014 - time * 0.006, 71)
        local normNoise = clamp((widthNoiseVal + 1.0) * 0.5, 0, 1)
        local currentNecking = fluidTrailConfig.neckingExponent + fluidTrailDashBlend * 1.1
        local liquidMod = 0.18 + 1.55 * (normNoise ^ currentNecking)
        local stateBaseWidth = fluidTrailConfig.baseWidth * (1.0 - fluidTrailDashBlend * 0.42)
        local taper = (math.max(0, t) ^ 0.45) * (1.05 - 0.15 * t)
        local shredMultiplier = 1.0
        if fluidTrailDashBlend > 0.02 then
            local shredNoise = fluidNoise1D(curr.dist * 0.08 + time * 0.01, 131)
            if shredNoise > 0.35 then
                local shredded = math.max(0.1, 1.0 - (shredNoise - 0.35) * 2.8)
                shredMultiplier = 1.0 - (1.0 - shredded) * fluidTrailDashBlend
            end
        end
        local outerHalfW = math.max(0.1, (stateBaseWidth * 0.5) * taper * liquidMod * shredMultiplier)

        local pointEnhanced = curr.enhanced or fluidTrailDashBlend > 0.35
        if pointEnhanced and outerHalfW < 2.0 and i > 5 and i < #dashFluidPoints - 8 then
            local seed = curr.dist * 0.013 + i * 41 + math.floor(elapsed * 16)
            local prob = (0.03 + 0.15 * fluidTrailDashBlend) * fluidTrailConfig.pinchPropensity
            if hash01(seed) < prob then
                spawnDashFluidDroplet(cx, cy, curr.velocity or 0, nx, ny, seed, true, curr.dirX, curr.dirY)
            end
        end

        if pointEnhanced and fluidTrailDashBlend > 0.12 and i > 2 and i < #dashFluidPoints - 2 then
            local seed = curr.dist * 0.031 + i * 19 + math.floor(elapsed * 24)
            if hash01(seed + 301) < 0.22 * fluidTrailDashBlend then
                local tx, ty = curr.dirX or dx / len, curr.dirY or dy / len
                local tl = dist2(tx, ty)
                if tl < 0.001 then tx, ty, tl = dx, dy, len end
                tx, ty = tx / tl, ty / tl
                local side = (hash01(seed + 307) - 0.5) * outerHalfW * 1.6
                local lineLen = (8 + hash01(seed + 311) * 28) * (0.65 + fluidTrailDashBlend)
                fiberLines[#fiberLines + 1] = {
                    x1 = cx + nx * side,
                    y1 = cy + ny * side,
                    x2 = cx + nx * side - tx * lineLen,
                    y2 = cy + ny * side - ty * lineLen,
                    width = 0.45 + hash01(seed + 313) * 1.2,
                    alpha = (38 + hash01(seed + 317) * 92) * fluidTrailDashBlend,
                }
            end
        end

        local innerHalfW = outerHalfW * (0.62 - fluidTrailDashBlend * 0.12)
        outerLeft[#outerLeft + 1] = { x = cx + nx * outerHalfW, y = cy + ny * outerHalfW }
        outerRight[#outerRight + 1] = { x = cx - nx * outerHalfW, y = cy - ny * outerHalfW }
        innerLeft[#innerLeft + 1] = { x = cx + nx * innerHalfW, y = cy + ny * innerHalfW }
        innerRight[#innerRight + 1] = { x = cx - nx * innerHalfW, y = cy - ny * innerHalfW }
    end

    local outerAlpha = 115 * (1.0 - fluidTrailDashBlend) + 72 * fluidTrailDashBlend
    local innerAlpha = 238 * (1.0 - fluidTrailDashBlend) + 230 * fluidTrailDashBlend
    fillFluidPath(outerLeft, outerRight, rgba(24, 24, 24, outerAlpha))
    fillFluidPath(innerLeft, innerRight, rgba(17, 17, 17, innerAlpha))
    for _, f in ipairs(fiberLines) do
        strokeLine(f.x1, f.y1, f.x2, f.y2, f.width, rgba(18, 18, 18, f.alpha))
    end
end

local function drawDashFluidDroplets()
    for _, d in ipairs(dashFluidDroplets) do
        local r = d.radius * math.max(0, d.life)
        if d.kind == "dash_streak" then
            strokeLine(d.x, d.y, d.x - d.vx * 1.4, d.y - d.vy * 1.4, math.max(0.4, r * 1.3), rgba(24, 24, 24, 190 * d.life))
        else
            drawCircle(d.x, d.y, r, rgba(24, 24, 24, 115 * d.life))
            drawCircle(d.x, d.y, r * 0.60, rgba(17, 17, 17, 238 * d.life))
        end
    end
end

local function drawParticles()
    drawDashFluidRibbon()
    drawDashFluidDroplets()
    for _, p in ipairs(trailParticles) do
        local a = clamp(p.life / p.maxLife, 0, 1)
        local color = colorRGBA(currentLevel.ink, 200 * p.alpha * a)
        if p.kind == "gold" then color = rgba(218, 165, 32, 220 * p.alpha * a)
        elseif p.kind == "energy" or p.kind == "inkgas" then color = rgba(8, 7, 6, 180 * p.alpha * a)
        elseif p.kind == "red" or p.kind == "maple" then color = rgba(195, 22, 22, 220 * p.alpha * a)
        elseif p.kind == "water" then color = rgba(232, 238, 230, 220 * p.alpha * a) end
        drawEllipse(p.x, p.y, p.r * 1.3, p.r * 0.75, color)
    end
    for _, p in ipairs(bristleParticles) do
        local a = clamp(p.life / p.maxLife, 0, 1)
        local color = colorRGBA(currentLevel.ink, 150 * a)
        if p.kind == "gold" then color = rgba(218, 165, 32, 170 * a)
        elseif p.kind == "bloom" then color = colorRGBA(currentLevel.bloom, 180 * a)
        elseif p.kind == "inkgas" then color = rgba(6, 5, 4, 120 * a)
        elseif p.kind == "leaf" then color = colorRGBA(currentLevel.accent, 160 * a) end
        strokeLine(p.x, p.y, p.x + p.vx * 2.4, p.y + p.vy * 2.4, 1.4, color)
    end
end

local function drawPlayer()
    if player.isDashing then
        local ang = math.atan2(player.vy, player.vx)
        drawRotEllipse(player.x - player.vx * 0.44, player.y - player.vy * 0.44, player.radius + 23, player.radius * 0.95, ang, rgba(8, 7, 6, 58))
        drawRotEllipse(player.x - player.vx * 0.28, player.y - player.vy * 0.28, player.radius + 12, player.radius * 0.62, ang, rgba(2, 2, 2, 86))
    end
    if player.isWallClinging and hash01(elapsed * 80) > 0.45 then
        drawCircle(player.x + player.wallSide * 8, player.y + (hash01(elapsed * 100) - 0.5) * 10, 2.8, colorRGBA(currentLevel.ink, 110))
    end
    drawInkBleed(player.x, player.y, player.radius * 1.45, player.radius * 1.20, currentLevel.ink, 54, elapsed * 7.1 + player.x * 0.01, 3)
    drawCircle(player.x, player.y, player.radius, colorRGBA(currentLevel.ink, 248))
    drawInkSpeckles(player.x - player.radius, player.y - player.radius, player.radius * 2, player.radius * 2, currentLevel.paper, 42, elapsed * 3.7 + player.y * 0.01, 5)
    drawCircle(player.x + (player.facingRight and 3 or -3), player.y - 2, 2.5, colorRGB(currentLevel.paper))
end

local function drawPoetry()
    local poems = {
        bamboo = { x = W(0.05), y = H(0.15), lines = { "咬定青山不放松", "立根原在破岩中", "千磨万击还坚劲", "任尔东西南北风" } },
        pine = { x = W(0.05), y = H(0.22), lines = { "松风吹解带", "山泉声自流" } },
        maple = { x = W(0.08), y = H(0.28), lines = { "停车坐爱枫林晚", "霜叶红于二月花" } },
        plum = { x = W(0.18), y = H(0.28), lines = { "吾家洗砚池头树", "个个花开淡墨痕", "不要人夸好颜色", "只留清气满乾坤" } },
        eaves = { x = W(0.08), y = H(0.18), lines = { "界画楼台工整描", "金碧山水自天娇" } },
    }
    local p = poems[currentLevel.id]
    if not p then return end
    for i = 1, #p.lines do
        local vx = p.x + (#p.lines - i) * 45
        local chars = utf8Chars(p.lines[i])
        for j = 1, #chars do
            drawText(vx, p.y + (j - 1) * 32, 28, colorRGBA(currentLevel.ink, 185), chars[j])
        end
    end
    drawRect(p.x + 45, p.y - 45, 24, 24, 0, rgba(168, 43, 43, 165))
end

