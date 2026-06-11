-- LDtk grand-scroll runtime bridge. Data is generated in 34_ldtk_grand_scroll_data.lua.

LDTK_GRAND_SCROLL_ID = "ldtk_grand_scroll"
ldtkSolidRects = {}
ldtkOneWayRects = {}
ldtkHazardRects = {}
ldtkLabels = {}
ldtkDecor = {}
ldtkMotifs = {}
ldtkCheckpoints = {}
ldtkWaterfalls = {}
ldtkStart = nil
ldtkExit = nil

function currentLevelIsLDtkGrandScroll()
    return currentLevel and currentLevel.id == LDTK_GRAND_SCROLL_ID
end

function ldtkEntityCenter(e)
    return e.x + e.w * 0.5, e.y + e.h * 0.5
end

function addLDtkRect(r)
    local out = { x = r.x, y = r.y, w = r.w, h = r.h, v = r.v }
    if r.v == 2 then
        ldtkOneWayRects[#ldtkOneWayRects + 1] = out
    elseif r.v == 3 then
        ldtkHazardRects[#ldtkHazardRects + 1] = out
    else
        ldtkSolidRects[#ldtkSolidRects + 1] = out
    end
end

function addLDtkBambooStalk(startX, startY, angle, length, radius, segmentsCount, stalkId)
    local currentX, currentY = startX, startY
    local segLen = length / segmentsCount
    for i = 0, segmentsCount - 1 do
        local bendDir = angle > -math.pi / 2 and 1 or -1
        local curAngle = angle + i * 0.018 * bendDir
        local nextX = currentX + math.cos(curAngle) * segLen
        local nextY = currentY + math.sin(curAngle) * segLen
        local currentR = radius * (1 - (i / segmentsCount) * 0.45)
        bambooSegments[#bambooSegments + 1] = {
            x1 = currentX, y1 = currentY,
            x2 = nextX, y2 = nextY,
            r = currentR, stalkId = stalkId,
            isNode = true, nodeX = nextX, nodeY = nextY,
            angle = curAngle,
        }
        currentX, currentY = nextX, nextY
    end
end

function addLDtkBambooCluster(e, index)
    local x = e.x + e.w * 0.5
    local y = e.y + e.h
    addLDtkBambooStalk(x - 30, y + 160, -math.pi * 0.48, 470, 16, 11, "ldtk_bamboo_" .. index .. "_a")
    addLDtkBambooStalk(x + 36, y + 110, -math.pi * 0.39, 390, 12, 9, "ldtk_bamboo_" .. index .. "_b")
    addLDtkBambooStalk(x + 94, y + 60, -math.pi * 0.54, 330, 9, 8, "ldtk_bamboo_" .. index .. "_c")
end

function addLDtkBranchForMotif(e, index)
    local x, y = ldtkEntityCenter(e)
    if e.id == "PineBranch" then
        createBranch(x - 80, y + 60, x + 320, y - 48, 22, 8, 96, -88, 56, "ldtk_pine_" .. index, 0.14)
        addTargetOnBranch("ldtk_pine_" .. index, 0.52, 38)
    elseif e.id == "PlumBranch" then
        createBranch(x + 110, y + 38, x - 270, y - 18, 24, 5, -82, -62, 58, "ldtk_plum_" .. index, 0.16)
        addTargetOnBranch("ldtk_plum_" .. index, 0.58, 34)
    elseif e.id == "EavesRail" then
        createBranch(e.x, y, e.x + e.w * 1.85, y - 34, 9, 7, 38, -42, 42, "ldtk_eaves_rail_" .. index, 0.04)
    end
end

function addLDtkPavilion(e, index)
    addPavilion(e.x, e.y, math.max(180, e.w * 1.5), 3, 92)
    addRoof(e.x, e.y, e.x - 90, e.y - 70, { x = e.x - 40, y = e.y + 12 })
    addRoof(e.x + math.max(180, e.w * 1.5), e.y, e.x + math.max(260, e.w * 2.0), e.y - 74, { x = e.x + math.max(220, e.w * 1.75), y = e.y + 10 })
    chimes[#chimes + 1] = { x = e.x - 90, y = e.y - 46, pulse = 0, swayAngle = 0 }
    chimes[#chimes + 1] = { x = e.x + math.max(260, e.w * 2.0), y = e.y - 50, pulse = 0, swayAngle = 0 }
end

function addLDtkCloud(e, index)
    local x, y = ldtkEntityCenter(e)
    cloudPlatforms[#cloudPlatforms + 1] = {
        x = x, y = y,
        rx = math.max(110, e.w * 0.85),
        ry = math.max(34, e.h * 0.70),
        bob = index * 1.37,
    }
end

function addLDtkCrane(e, index)
    local x, y = ldtkEntityCenter(e)
    cranes[#cranes + 1] = {
        x = x, y = y,
        startY = y,
        speed = 1.6 + (index % 3) * 0.22,
        amplitude = 38 + (index % 5) * 7,
        theta = index * 0.91,
        wingAngle = 0,
        ldtkHomeX = x,
    }
end

function addLDtkPeachWater(e, index)
    local x, y = ldtkEntityCenter(e)
    waterLevel = math.max(waterLevel, y + 80)
    for i = 1, 8 do
        floatingPetals[#floatingPetals + 1] = {
            x = x - 260 + i * 70,
            y = y + (hash01(index * 41 + i * 7) - 0.5) * 24,
            w = 72 + hash01(index * 47 + i * 11) * 34,
            h = 18 + hash01(index * 53 + i * 13) * 9,
            speed = 0.45 + hash01(index * 59 + i * 17) * 0.55,
            bob = hash01(index * 61 + i * 19) * math.pi,
        }
    end
end

function ldtkCatmull(a, b, c, d, t)
    local t2 = t * t
    local t3 = t2 * t
    return 0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
end

function ldtkSampleCatmull(nodes, i, u)
    local p0 = nodes[math.max(1, i - 1)]
    local p1 = nodes[i]
    local p2 = nodes[i + 1]
    local p3 = nodes[math.min(#nodes, i + 2)]
    return ldtkCatmull(p0.x, p1.x, p2.x, p3.x, u), ldtkCatmull(p0.y, p1.y, p2.y, p3.y, u)
end

function buildLDtkBrushRoute()
    local nodes = {}
    for _, e in ipairs(LDTK_GRAND_SCROLL.entities or {}) do
        if e.id == "BrushPathNode" then
            local x, y = ldtkEntityCenter(e)
            nodes[#nodes + 1] = { x = x, y = y }
        end
    end
    table.sort(nodes, function(a, b) return a.x < b.x end)

    local samples = {}
    for i = 1, #nodes - 1 do
        local a, b = nodes[i], nodes[i + 1]
        local len = dist2(b.x - a.x, b.y - a.y)
        local steps = math.max(10, math.floor(len / 22))
        for s = 0, steps - 1 do
            local u = s / steps
            local x, y = ldtkSampleCatmull(nodes, i, u)
            samples[#samples + 1] = { x = x, y = y }
        end
    end
    if #nodes > 0 then
        samples[#samples + 1] = { x = nodes[#nodes].x, y = nodes[#nodes].y }
    end

    local count = #samples
    if count < 2 then return end
    local branchId = "ldtk_route_scroll"
    for i, p in ipairs(samples) do
        local prev = samples[math.max(1, i - 1)]
        local next = samples[math.min(count, i + 1)]
        local dx, dy = next.x - prev.x, next.y - prev.y
        local len = dist2(dx, dy)
        if len < 0.001 then len = 1 end
        local normX, normY = -dy / len, dx / len
        if normY > 0 then normX, normY = -normX, -normY end
        local t = (i - 1) / math.max(1, count - 1)
        local taper = 1 - math.abs(t - 0.46) * 0.22
        local pulse = math.sin(t * math.pi * 7.2) * 1.9 + math.sin(t * math.pi * 17.0) * 0.8
        local dry = hash01(i * 37 + p.x * 0.009 + p.y * 0.011) - 0.5
        local r = (17.5 - 5.8 * t) * taper + pulse + dry * 2.1
        if t < 0.055 then r = r * (0.58 + t * 7.6) end
        if t > 0.93 then r = r * (1 - (t - 0.93) * 7.2) end
        r = clamp(r, 6.5, 21)
        addBranchNode({ x = p.x, y = p.y, r = r, normX = normX, normY = normY, branchId = branchId, t = t, baseX = p.x, baseY = p.y })
    end
end

function generateLDtkGrandScroll()
    if not LDTK_GRAND_SCROLL then return end

    worldW = LDTK_GRAND_SCROLL.width
    worldH = LDTK_GRAND_SCROLL.height
    ldtkSolidRects = {}
    ldtkOneWayRects = {}
    ldtkHazardRects = {}
    ldtkLabels = {}
    ldtkDecor = {}
    ldtkMotifs = {}
    ldtkCheckpoints = {}
    ldtkWaterfalls = {}
    ldtkStart = nil
    ldtkExit = nil
    waterLevel = H(0.78)

    for _, r in ipairs(LDTK_GRAND_SCROLL.collision or {}) do
        addLDtkRect(r)
    end
    for _, r in ipairs(LDTK_GRAND_SCROLL.decor or {}) do
        ldtkDecor[#ldtkDecor + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, v = r.v }
    end

    buildLDtkBrushRoute()

    local labelNames = {
        "01_Bamboo_Falls",
        "02_Pine_Rock_Ledge",
        "03_Peach_Water_Reserve",
        "04_Pavilion_Cloud_Plum",
    }
    local labelIndex = 1

    for i, e in ipairs(LDTK_GRAND_SCROLL.entities or {}) do
        local cx, cy = ldtkEntityCenter(e)
        if e.id == "PlayerStart" then
            ldtkStart = { x = cx, y = cy }
        elseif e.id == "GrandExit" then
            ldtkExit = { x = cx, y = cy, w = e.w, h = e.h }
        elseif e.id == "Checkpoint" then
            ldtkCheckpoints[#ldtkCheckpoints + 1] = { x = cx, y = cy }
        elseif e.id == "RegionLabel" then
            ldtkLabels[#ldtkLabels + 1] = { x = e.x, y = e.y, text = labelNames[labelIndex] or ("Region_" .. labelIndex) }
            labelIndex = labelIndex + 1
        elseif e.id == "InkTarget" then
            addTarget(cx, cy, math.max(30, math.min(e.w, e.h) + 14))
        elseif e.id == "BambooCluster" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkBambooCluster(e, i)
        elseif e.id == "Waterfall" then
            ldtkWaterfalls[#ldtkWaterfalls + 1] = { x = e.x, y = e.y, w = math.max(260, e.w * 3.2), h = math.max(620, e.h * 3.8) }
            streams[#streams + 1] = { x1 = e.x + e.w * 0.5, y1 = e.y - 140, x2 = e.x + e.w * 0.8, y2 = e.y + e.h * 3.4, width = 120 }
        elseif e.id == "PineBranch" or e.id == "PlumBranch" or e.id == "EavesRail" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkBranchForMotif(e, i)
        elseif e.id == "PlumBlossom" then
            blooms[#blooms + 1] = {
                x = cx, y = cy, scale = 1, progress = 1,
                normX = 0, normY = -1, kind = "plum", r = 24,
            }
        elseif e.id == "PeachPetalWater" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkPeachWater(e, i)
        elseif e.id == "Pavilion" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkPavilion(e, i)
        elseif e.id == "CloudPlatform" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkCloud(e, i)
        elseif e.id == "CraneRide" then
            ldtkMotifs[#ldtkMotifs + 1] = e
            addLDtkCrane(e, i)
        end
    end
end

function resetLDtkGrandScrollPlayer()
    if not ldtkStart then return false end
    local best = nil
    local bestScore = 999999
    local function scanRects(rects)
        for _, r in ipairs(rects) do
            local left = r.x + player.radius + 2
            local right = r.x + r.w - player.radius - 2
            local clampedX = clamp(ldtkStart.x, left, right)
            local horizontalGap = math.max(0, r.x - ldtkStart.x, ldtkStart.x - (r.x + r.w))
            if horizontalGap <= 120 then
                local verticalGap = math.abs(r.y - ldtkStart.y)
                local score = verticalGap + horizontalGap * 1.8
                if r.y > ldtkStart.y + 260 then score = score + 300 end
                if score < bestScore then
                    bestScore = score
                    best = { x = clampedX, y = r.y - player.radius - 1 }
                end
            end
        end
    end
    scanRects(ldtkSolidRects)
    scanRects(ldtkOneWayRects)
    if best then
        player.x = best.x
        player.y = best.y
    else
        player.x = ldtkStart.x
        player.y = ldtkStart.y - player.radius - 8
    end
    player.facingRight = true
    return true
end

function resolveLDtkSolidRect(r)
    local rad = player.radius
    if player.x < r.x - rad or player.x > r.x + r.w + rad or player.y < r.y - rad or player.y > r.y + r.h + rad then
        return false
    end

    local leftPen = player.x - (r.x - rad)
    local rightPen = (r.x + r.w + rad) - player.x
    local topPen = player.y - (r.y - rad)
    local bottomPen = (r.y + r.h + rad) - player.y
    local minPen = math.min(math.min(leftPen, rightPen), math.min(topPen, bottomPen))

    if minPen == topPen then
        player.y = r.y - rad
        if player.vy > 0 then player.vy = 0 end
        player.isGrounded = true
        player.canDash = true
        player.isWallClinging = false
    elseif minPen == bottomPen then
        player.y = r.y + r.h + rad
        if player.vy < 0 then player.vy = 0 end
    elseif minPen == leftPen then
        player.x = r.x - rad
        if player.vx > 0 then player.vx = 0 end
        if keys.d then
            player.isWallClinging = true
            player.wallSide = 1
        end
    else
        player.x = r.x + r.w + rad
        if player.vx < 0 then player.vx = 0 end
        if keys.a then
            player.isWallClinging = true
            player.wallSide = -1
        end
    end
    return true
end

function resolveLDtkRouteCollision()
    local nearWall, detectedWallSide = false, 0
    local closest = {}

    for branchId, list in pairs(branchGroups) do
        if branchId:find("^ldtk_route_") then
            local bounds = branchBounds and branchBounds[branchId]
            local pad = 120
            if (not bounds) or (player.x >= bounds.minX - pad and player.x <= bounds.maxX + pad and player.y >= bounds.minY - pad and player.y <= bounds.maxY + pad) then
                for _, b in ipairs(list) do
                    local hitR = b.r * 1.02
                    if math.abs(player.x - b.x) <= hitR + player.radius + 24 and math.abs(player.y - b.y) <= hitR + player.radius + 24 then
                        local dx, dy = player.x - b.x, player.y - b.y
                        local d = dist2(dx, dy)
                        if not closest[branchId] or d < closest[branchId].dist then
                            closest[branchId] = { node = b, dist = d, dx = dx, dy = dy, hitR = hitR }
                        end
                    end
                end
            end
        end
    end

    for _, item in pairs(closest) do
        local b, d = item.node, item.dist
        local minDist = player.radius + item.hitR
        if d < minDist then
            local overlap = minDist - d
            local nx, ny = item.dx / (d == 0 and 1 or d), item.dy / (d == 0 and 1 or d)
            if d == 0 then nx, ny, overlap = 0, -1, minDist end
            player.x = player.x + nx * overlap
            player.y = player.y + ny * overlap
            if ny < -0.36 then
                player.isGrounded = true
                player.canDash = true
                player.isWallClinging = false
                if player.vy > 0 then player.vy = 0 end
            elseif ny > 0.45 and player.vy < 0 then
                player.vy = 0
            end
            if not player.isGrounded and math.abs(nx) > 0.72 then
                if (keys.a and nx > 0) or (keys.d and nx < 0) then
                    nearWall = true
                    detectedWallSide = nx > 0 and -1 or 1
                end
            end
        end
    end

    if nearWall and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = detectedWallSide
    end
end

function ldtkGrandScrollCollision(prevX, prevY)
    player.isGrounded = false
    player.isWallClinging = false
    prevY = prevY or player.y

    for _, r in ipairs(ldtkSolidRects) do
        if math.abs(player.x - (r.x + r.w * 0.5)) < r.w * 0.5 + player.radius + 90 and math.abs(player.y - (r.y + r.h * 0.5)) < r.h * 0.5 + player.radius + 90 then
            resolveLDtkSolidRect(r)
        end
    end

    resolveLDtkRouteCollision()

    if player.vy >= 0 then
        for _, r in ipairs(ldtkOneWayRects) do
            local footPrev = prevY + player.radius
            local footNow = player.y + player.radius
            if player.x >= r.x - player.radius and player.x <= r.x + r.w + player.radius and footPrev <= r.y + 8 and footNow >= r.y and footNow <= r.y + math.max(24, r.h + 20) then
                player.y = r.y - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
                player.isWallClinging = false
                break
            end
        end
    end

    for _, r in ipairs(ldtkHazardRects) do
        if player.x > r.x - player.radius and player.x < r.x + r.w + player.radius and player.y > r.y - player.radius and player.y < r.y + r.h + player.radius then
            resetLDtkGrandScrollPlayer()
            break
        end
    end
end

function updateLDtkGrandScrollSpecial()
    if not currentLevelIsLDtkGrandScroll() then return false end

    for _, fall in ipairs(ldtkWaterfalls) do
        if player.x > fall.x - 70 and player.x < fall.x + fall.w and player.y > fall.y - 160 and player.y < fall.y + fall.h then
            local center = fall.x + fall.w * 0.45
            local lift = clamp(1 - math.abs(player.x - center) / (fall.w * 0.62), 0.25, 1)
            player.vy = math.max(player.vy - 1.1 * lift, -12.5)
            player.vx = player.vx + 0.06 * lift
            if hash01(elapsed * 60 + player.x) > 0.48 then addTrail(player.x, player.y + 10, player.radius * 1.25, 0.13, 32, "water") end
        end
    end

    for _, s in ipairs(streams) do
        local dx, dy = s.x2 - s.x1, s.y2 - s.y1
        local len2 = dx * dx + dy * dy
        if len2 > 0.01 then
            local t = clamp(((player.x - s.x1) * dx + (player.y - s.y1) * dy) / len2, 0, 1)
            local px, py = s.x1 + t * dx, s.y1 + t * dy
            local d = dist2(player.x - px, player.y - py)
            if d < s.width then
                local len = math.sqrt(len2)
                player.vx = player.vx + (dx / len) * 0.22
                player.vy = player.vy + (dy / len) * 0.10
                if hash01(elapsed * 80 + d) > 0.65 then addTrail(player.x, player.y, player.radius * 1.2, 0.10, 20, "water") end
            end
        end
    end

    if player.craneCooldown > 0 then player.craneCooldown = player.craneCooldown - 1 end
    if player.ridingCrane then
        player.x = player.ridingCrane.x
        player.y = player.ridingCrane.y - 12
        player.vx, player.vy = 0, 0
        player.canDash = true
        if dashJustPressed or keys.space then
            local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
            local dy = (keys.s and 1 or 0) - (keys.w and 1 or 0)
            if dx == 0 and dy == 0 then dx = player.facingRight and 1 or -1 end
            local d = dist2(dx, dy)
            if d < 0.001 then d = 1 end
            player.ridingCrane = nil
            boostFluidTrail(26)
            player.isDashing = true
            player.canDash = false
            player.dashTime = 12
            player.dashDirX, player.dashDirY = dx / d, dy / d
            player.craneCooldown = 40
            keys.space = false
            dashJustPressed = false
        end
        return true
    elseif player.craneCooldown == 0 and not player.isDashing then
        for _, c in ipairs(cranes) do
            if dist2(player.x - c.x, player.y - c.y) < player.radius + 38 then
                player.ridingCrane = c
                break
            end
        end
    end

    return false
end
