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

-- 取当前关卡墨色的浓淡变体（mul 越小越浓黑）
function inkShade(mul, alpha)
    local c = currentLevel.ink
    return rgba(c[1] * mul, c[2] * mul, c[3] * mul, alpha)
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

    local haloLeft, haloRight = {}, {}
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
        local haloHalfW = outerHalfW * 1.62 + 1.4
        outerLeft[#outerLeft + 1] = { x = cx + nx * outerHalfW, y = cy + ny * outerHalfW }
        outerRight[#outerRight + 1] = { x = cx - nx * outerHalfW, y = cy - ny * outerHalfW }
        innerLeft[#innerLeft + 1] = { x = cx + nx * innerHalfW, y = cy + ny * innerHalfW }
        innerRight[#innerRight + 1] = { x = cx - nx * innerHalfW, y = cy - ny * innerHalfW }
        haloLeft[#haloLeft + 1] = { x = cx + nx * haloHalfW, y = cy + ny * haloHalfW }
        haloRight[#haloRight + 1] = { x = cx - nx * haloHalfW, y = cy - ny * haloHalfW }
    end

    local outerAlpha = 115 * (1.0 - fluidTrailDashBlend) + 72 * fluidTrailDashBlend
    local innerAlpha = 238 * (1.0 - fluidTrailDashBlend) + 230 * fluidTrailDashBlend
    -- 三层水墨：最外湿晕（纸面洇开）→ 中层墨身 → 内芯浓墨
    fillFluidPath(haloLeft, haloRight, inkShade(0.92, 15 + 9 * (1.0 - fluidTrailDashBlend)))
    fillFluidPath(outerLeft, outerRight, inkShade(0.82, outerAlpha))
    fillFluidPath(innerLeft, innerRight, inkShade(0.52, innerAlpha))
    -- 尾端飞白散锋：沿两缘交替甩出干笔细丝，越近尾端越实
    local m = math.min(16, #outerLeft - 1)
    for i = 1, m do
        local fade = 1 - i / (m + 1)
        local edge = (i % 2 == 0) and outerLeft or outerRight
        local a, b = edge[i], edge[i + 1]
        strokeLine(a.x, a.y, b.x + (b.x - a.x) * 0.8, b.y + (b.y - a.y) * 0.8, 0.9 + fade * 0.5, inkShade(0.6, 86 * fade))
    end
    for _, f in ipairs(fiberLines) do
        strokeLine(f.x1, f.y1, f.x2, f.y2, f.width, inkShade(0.5, f.alpha))
    end
end

local function drawDashFluidDroplets()
    for _, d in ipairs(dashFluidDroplets) do
        local r = d.radius * math.max(0, d.life)
        if d.kind == "dash_streak" then
            strokeLine(d.x, d.y, d.x - d.vx * 1.4, d.y - d.vy * 1.4, math.max(0.4, r * 1.3), inkShade(0.62, 190 * d.life))
        else
            drawCircle(d.x, d.y, r * 1.55, inkShade(0.95, 26 * d.life))
            drawCircle(d.x, d.y, r, inkShade(0.82, 115 * d.life))
            drawCircle(d.x, d.y, r * 0.60, inkShade(0.52, 238 * d.life))
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

-- 活体墨滴：闭合贝塞尔轮廓 + 表面波动 + 速度形变（squash & stretch）
function buildInkBlobOutline(cx, cy, baseR, spd, ang, squash, tear, wallAng)
    local pts = {}
    local n = 14
    local stretchE = player.isDashing and 0.40 or clamp(spd * 0.027, 0, 0.30)
    for k = 0, n - 1 do
        local th = k / n * math.pi * 2
        -- 三重表面波（整数倍频保证首尾无缝），墨滴永远在"呼吸"
        local wob = 0.055 * math.sin(th * 3 + elapsed * 4.1)
            + 0.040 * math.sin(th * 5 - elapsed * 3.3 + 1.7)
            + 0.028 * math.sin(th * 7 + elapsed * 5.9 + 4.2)
        local r = baseR * (1 + wob)
        -- 沿速度方向拉伸（垂直方向等量收缩，体积守恒感）
        r = r * (1 + stretchE * math.cos(2 * (th - ang)))
        -- 落地挤压：横向变宽、纵向压扁
        r = r * (1 + squash * math.cos(2 * th))
        -- 运动拖墨：尾侧微微隆起拖长
        if tear > 0.01 then
            local rear = math.cos(th - ang - math.pi)
            if rear > 0 then r = r * (1 + tear * rear * rear) end
        end
        -- 贴墙：朝墙一侧压平
        if wallAng then
            local press = math.cos(th - wallAng)
            if press > 0 then r = r * (1 - 0.24 * press * press) end
        end
        pts[#pts + 1] = { x = cx + math.cos(th) * r, y = cy + math.sin(th) * r }
    end
    return pts
end

function fillInkBlob(pts, color)
    if #pts < 3 then return end
    nvgBeginPath(vg)
    local prev = pts[#pts]
    local curX, curY = (prev.x + pts[1].x) * 0.5, (prev.y + pts[1].y) * 0.5
    nvgMoveTo(vg, curX, curY)
    for i = 1, #pts do
        local a = pts[i]
        local b = pts[i % #pts + 1]
        local mx, my = (a.x + b.x) * 0.5, (a.y + b.y) * 0.5
        fluidQuadTo(curX, curY, a.x, a.y, mx, my)
        curX, curY = mx, my
    end
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawPlayer()
    local spd = dist2(player.vx or 0, player.vy or 0)
    local r0 = player.radius

    -- 落地挤压检测（用 player 表存帧间状态，避免新增 chunk 级 local）
    if player.isGrounded and (player.blobPrevVy or 0) > 5.5 then
        player.blobSquash = math.min(0.42, (player.blobPrevVy or 0) * 0.035)
    end
    player.blobPrevVy = player.vy
    player.blobSquash = (player.blobSquash or 0) * 0.85

    local ang
    if spd > 0.6 then
        ang = math.atan2(player.vy, player.vx)
    else
        ang = player.facingRight and 0 or math.pi
    end
    local tear = player.isDashing and 0.34 or clamp(spd * 0.016, 0, 0.24)
    local wallAng = nil
    if player.isWallClinging then
        wallAng = player.wallSide > 0 and 0 or math.pi
    end

    -- 冲刺彗尾：三层拖影 + 速度线
    if player.isDashing then
        drawRotEllipse(player.x - player.vx * 0.58, player.y - player.vy * 0.58, r0 + 26, r0 * 1.05, ang, inkShade(0.95, 36))
        drawRotEllipse(player.x - player.vx * 0.40, player.y - player.vy * 0.40, r0 + 18, r0 * 0.84, ang, inkShade(0.75, 62))
        drawRotEllipse(player.x - player.vx * 0.24, player.y - player.vy * 0.24, r0 + 9, r0 * 0.58, ang, inkShade(0.45, 92))
        for i = 1, 3 do
            local seed = math.floor(elapsed * 40) * 13 + i * 57
            local side = (hash01(seed) - 0.5) * r0 * 2.6
            local nx2, ny2 = -math.sin(ang), math.cos(ang)
            local sx = player.x - math.cos(ang) * r0 * (1.2 + hash01(seed + 3) * 1.6) + nx2 * side
            local sy = player.y - math.sin(ang) * r0 * (1.2 + hash01(seed + 3) * 1.6) + ny2 * side
            local ln = 10 + hash01(seed + 7) * 22
            strokeLine(sx, sy, sx - math.cos(ang) * ln, sy - math.sin(ang) * ln, 0.8 + hash01(seed + 11) * 0.8, inkShade(0.5, 70 + hash01(seed + 13) * 60))
        end
    end

    -- 贴墙：墨珠沿墙面滑出细痕
    if player.isWallClinging then
        local wx = player.x + player.wallSide * (r0 - 2)
        strokeLine(wx, player.y - 4, wx + player.wallSide * 1.5, player.y + r0 + 10, 1.6, inkShade(0.6, 96))
        if hash01(elapsed * 80) > 0.45 then
            drawCircle(player.x + player.wallSide * 8, player.y + (hash01(elapsed * 100) - 0.5) * 10, 2.8, colorRGBA(currentLevel.ink, 110))
        end
    end

    -- 静止沉积：墨珠落定时在脚下洇出一圈淡墨（缓慢呼吸）
    if player.isGrounded and not player.isDashing and spd < 0.8 then
        local soak = 0.5 + 0.5 * math.sin(elapsed * 1.7)
        drawEllipse(player.x, player.y + r0 * 0.82, r0 * (0.9 + soak * 0.35), r0 * 0.26, inkShade(0.95, 26 + soak * 16))
    end

    -- 湿晕（随速度变大，像快速运笔时墨来不及渗）
    local bleedScale = 1.42 + math.min(0.5, spd * 0.022)
    drawInkBleed(player.x, player.y, r0 * bleedScale, r0 * (bleedScale - 0.25), currentLevel.ink, 50, elapsed * 7.1 + player.x * 0.01, 3)

    -- 墨滴本体：外层墨身 + 滞后的内芯浓墨
    local body = buildInkBlobOutline(player.x, player.y, r0 * 1.04, spd, ang, player.blobSquash, tear, wallAng)
    fillInkBlob(body, inkShade(0.78, 248))
    local coreLagX = spd > 0.6 and -math.cos(ang) * r0 * 0.20 or 0
    local coreLagY = spd > 0.6 and -math.sin(ang) * r0 * 0.20 or 0
    local core = buildInkBlobOutline(
        player.x + coreLagX, player.y + coreLagY + math.sin(elapsed * 2.3) * 0.6,
        r0 * 0.58, spd, ang, player.blobSquash * 0.6, tear * 0.5, nil)
    fillInkBlob(core, inkShade(0.42, 252))

    -- 飞白颗粒 + 行进向高光（湿亮点）
    drawInkSpeckles(player.x - r0, player.y - r0, r0 * 2, r0 * 2, currentLevel.paper, 42, elapsed * 3.7 + player.y * 0.01, 5)
    local hlA = ang
    if spd <= 0.6 then hlA = player.facingRight and -0.5 or math.pi + 0.5 end
    local hx = player.x + math.cos(hlA) * r0 * 0.36
    local hy = player.y + math.sin(hlA) * r0 * 0.36 - 1.5
    drawCircle(hx, hy, 2.6, colorRGBA(currentLevel.paper, 235))
    drawCircle(hx + 2.2, hy + 1.8, 1.2, colorRGBA(currentLevel.paper, 160))
end

local function drawPoetry()
    local poems = {
        bamboo = { x = W(0.05), y = H(0.15), lines = { "咬定青山不放松", "立根原在破岩中", "千磨万击还坚劲", "任尔东西南北风" } },
        pine = { x = W(0.05), y = H(0.22), lines = { "松风吹解带", "山泉声自流" } },
        maple = { x = W(0.08), y = H(0.28), lines = { "停车坐爱枫林晚", "霜叶红于二月花" } },
        plum = { x = W(0.18), y = H(0.28), lines = { "吾家洗砚池头树", "个个花开淡墨痕", "不要人夸好颜色", "只留清气满乾坤" } },
        eaves = { x = W(0.08), y = H(0.18), lines = { "界画楼台工整描", "金碧山水自天娇" } },
        plum_xiyan = { x = W(0.295), y = H(0.08), lines = { "吾家洗砚池头树", "个个花开淡墨痕", "不要人夸好颜色", "只留清气满乾坤" } },
        xuwei_grape = { x = W(0.06), y = H(0.07), lines = { "半生落魄已成翁", "独立书斋啸晚风", "笔底明珠无处卖", "闲抛闲掷野藤中" } },
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

