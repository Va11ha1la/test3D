-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.

local function drawRect(x, y, w, h, r, color)
    nvgBeginPath(vg)
    if r and r > 0 then nvgRoundedRect(vg, x, y, w, h, r) else nvgRect(vg, x, y, w, h) end
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawStrokeRect(x, y, w, h, r, color, width)
    nvgBeginPath(vg)
    if r and r > 0 then nvgRoundedRect(vg, x, y, w, h, r) else nvgRect(vg, x, y, w, h) end
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width or 1)
    nvgStroke(vg)
end

local function drawCircle(x, y, r, color)
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, r)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawEllipse(x, y, rx, ry, color)
    nvgBeginPath(vg)
    nvgEllipse(vg, x, y, rx, ry)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawRotEllipse(x, y, rx, ry, angle, color)
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, angle)
    drawEllipse(0, 0, rx, ry, color)
    nvgRestore(vg)
end

local function strokeLine(x1, y1, x2, y2, width, color)
    nvgBeginPath(vg)
    nvgMoveTo(vg, x1, y1)
    nvgLineTo(vg, x2, y2)
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function strokeBezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2, width, color)
    nvgBeginPath(vg)
    nvgMoveTo(vg, x1, y1)
    nvgBezierTo(vg, cx1, cy1, cx2, cy2, x2, y2)
    nvgStrokeColor(vg, color)
    nvgStrokeWidth(vg, width)
    nvgStroke(vg)
end

local function strokeQuad(x1, y1, cx, cy, x2, y2, width, color)
    strokeBezier(
        x1, y1,
        x1 + (cx - x1) * 0.6667, y1 + (cy - y1) * 0.6667,
        x2 + (cx - x2) * 0.6667, y2 + (cy - y2) * 0.6667,
        x2, y2, width, color
    )
end

local function fillPetalShape(len, width, color)
    nvgBeginPath(vg)
    nvgMoveTo(vg, 0, 0)
    nvgBezierTo(vg, width, len * 0.5, width * 0.5, len, 0, len)
    nvgBezierTo(vg, -width * 0.5, len, -width, len * 0.5, 0, 0)
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function fillLeafBud(x, y, r, fillColor, strokeColor, veinColor)
    nvgBeginPath(vg)
    nvgMoveTo(vg, x, y - r)
    nvgBezierTo(vg, x + r * 0.78, y - r * 0.64, x + r * 1.10, y + r * 0.10, x + r * 0.20, y + r * 0.95)
    nvgBezierTo(vg, x - r * 1.10, y - r * 0.10, x - r * 0.78, y - r * 0.64, x, y - r)
    nvgClosePath(vg)
    nvgFillColor(vg, fillColor)
    nvgFill(vg)
    if strokeColor then
        nvgStrokeColor(vg, strokeColor)
        nvgStrokeWidth(vg, 2.5)
        nvgStroke(vg)
    end
    if veinColor then
        strokeQuad(x, y - r, x - r * 0.25, y + r * 0.2, x + r * 0.1, y + r * 0.85, 2, veinColor)
    end
end

local function fillPoly(points, color)
    if #points < 3 then return end
    nvgBeginPath(vg)
    nvgMoveTo(vg, points[1][1], points[1][2])
    for i = 2, #points do nvgLineTo(vg, points[i][1], points[i][2]) end
    nvgClosePath(vg)
    nvgFillColor(vg, color)
    nvgFill(vg)
end

local function drawText(x, y, size, color, text, align)
    if not fontReady then return end
    nvgFontFace(vg, "sans")
    nvgFontSize(vg, size)
    nvgTextAlign(vg, align or (NVG_ALIGN_LEFT + NVG_ALIGN_TOP))
    nvgFillColor(vg, color)
    nvgText(vg, x, y, text)
end

local function utf8Chars(text)
    local chars = {}
    for ch in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    return chars
end

local function addBranchNode(n)
    branches[#branches + 1] = n
    if not branchGroups[n.branchId] then branchGroups[n.branchId] = {} end
    branchGroups[n.branchId][#branchGroups[n.branchId] + 1] = n
    if not branchBounds then branchBounds = {} end
    local b = branchBounds[n.branchId]
    local pad = (n.r or 0) + 70
    if not b then
        branchBounds[n.branchId] = { minX = n.x - pad, maxX = n.x + pad, minY = n.y - pad, maxY = n.y + pad }
    else
        b.minX = math.min(b.minX, n.x - pad)
        b.maxX = math.max(b.maxX, n.x + pad)
        b.minY = math.min(b.minY, n.y - pad)
        b.maxY = math.max(b.maxY, n.y + pad)
    end
end

local function qbez(a, b, c, t)
    local it = 1 - t
    return it * it * a + 2 * it * t * b + t * t * c
end

local function createBranch(x1, y1, x2, y2, startR, endR, curveX, curveY, pointsNum, branchId, jitter)
    local cpX = (x1 + x2) * 0.5 + curveX
    local cpY = (y1 + y2) * 0.5 + curveY
    local list = {}
    for i = 0, pointsNum do
        local t = i / pointsNum
        local x = qbez(x1, cpX, x2, t)
        local y = qbez(y1, cpY, y2, t)
        local r = startR + (endR - startR) * t
        if jitter and jitter > 0 then
            r = r + (hash01(i * 19 + x * 0.013 + y * 0.017) - 0.5) * (startR * jitter)
        end
        local nt = math.min(t + 0.01, 1)
        local nx = qbez(x1, cpX, x2, nt)
        local ny = qbez(y1, cpY, y2, nt)
        local dx, dy = nx - x, ny - y
        local len = dist2(dx, dy)
        if len < 0.0001 then len = 1 end
        local normX, normY = -dy / len, dx / len
        if normY > 0 then normX, normY = -normX, -normY end
        local n = { x = x, y = y, r = r, normX = normX, normY = normY, branchId = branchId, t = t, baseX = x, baseY = y }
        addBranchNode(n)
        list[#list + 1] = n
    end
    return list
end

local function createBranchPath(points, branchId, jitter)
    if #points < 2 then return {} end
    local scaled = {}
    local totalLen = 0
    for i = 1, #points do
        local p = points[i]
        scaled[i] = { x = W(p[1]), y = H(p[2]), r = p[3] or 6 }
        if i > 1 then
            local a, b = scaled[i - 1], scaled[i]
            totalLen = totalLen + dist2(b.x - a.x, b.y - a.y)
        end
    end
    if totalLen < 0.001 then return {} end

    local list = {}
    local traveled = 0
    for i = 1, #scaled - 1 do
        local a, b = scaled[i], scaled[i + 1]
        local dx, dy = b.x - a.x, b.y - a.y
        local segLen = dist2(dx, dy)
        local steps = math.max(2, math.floor(segLen / 9))
        for s = 0, steps - 1 do
            local u = s / steps
            local x = a.x + dx * u
            local y = a.y + dy * u
            local r = a.r + (b.r - a.r) * u
            if jitter and jitter > 0 then
                r = r + (hash01(i * 31 + s * 19 + x * 0.01) - 0.5) * (a.r * jitter)
            end
            local len = segLen
            if len < 0.001 then len = 1 end
            local normX, normY = -dy / len, dx / len
            if normY > 0 then normX, normY = -normX, -normY end
            local n = { x = x, y = y, r = r, normX = normX, normY = normY, branchId = branchId, t = (traveled + segLen * u) / totalLen, baseX = x, baseY = y }
            addBranchNode(n)
            list[#list + 1] = n
        end
        traveled = traveled + segLen
    end

    local a, b = scaled[#scaled - 1], scaled[#scaled]
    local dx, dy = b.x - a.x, b.y - a.y
    local len = dist2(dx, dy)
    if len < 0.001 then len = 1 end
    local normX, normY = -dy / len, dx / len
    if normY > 0 then normX, normY = -normX, -normY end
    local n = { x = b.x, y = b.y, r = b.r, normX = normX, normY = normY, branchId = branchId, t = 1, baseX = b.x, baseY = b.y }
    addBranchNode(n)
    list[#list + 1] = n
    return list
end

local function addTarget(x, y, r, attachX, attachY, nx, ny, branchId, nodeIndex, attachOffset)
    targets[#targets + 1] = {
        x = x, y = y, r = r or 34,
        attachX = attachX, attachY = attachY,
        normX = nx or 0, normY = ny or -1,
        branchId = branchId, nodeIndex = nodeIndex, attachOffset = attachOffset,
        orientationJitter = (hash01((x or 0) * 0.017 + (y or 0) * 0.013) - 0.5) * 0.38,
        dead = false, pulse = hash01(#targets + 8) * 6.28318,
    }
end

local function addTargetOnBranch(branchId, progress, radius)
    local nodes = branchGroups[branchId]
    if not nodes or #nodes == 0 then return end
    local idx = clamp(math.floor(#nodes * progress), 1, #nodes)
    local n = nodes[idx]
    local off = n.r + 32
    addTarget(n.x + n.normX * off, n.y + n.normY * off, radius or 36, n.x, n.y, n.normX, n.normY, branchId, idx, off)
end

local function addMasterPlumFlowerTarget(xv, yv, axv, ayv, radius)
    local x, y = W(xv), H(yv)
    local ax, ay = W(axv), H(ayv)
    local dx, dy = x - ax, y - ay
    local len = dist2(dx, dy)
    if len < 0.001 then len = 1 end
    targets[#targets + 1] = {
        x = x, y = y, r = radius or 26,
        attachX = ax, attachY = ay,
        normX = dx / len, normY = dy / len,
        dead = false, pulse = hash01(#targets + 8) * 6.28318,
    }
end

