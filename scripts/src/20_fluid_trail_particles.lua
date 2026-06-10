-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function addTrail(x, y, r, alpha, life, kind)
    trailParticles[#trailParticles + 1] = { x = x, y = y, r = r, alpha = alpha or 0.18, life = life or 45, maxLife = life or 45, kind = kind }
end

local fluidTrailConfig = {
    normalMaxLength = 80,
    dashMaxLength = 130,
    baseWidth = 24,
    spineTension = 0.65,
    dashSpineTension = 0.93,
    pinchPropensity = 0.85,
    neckingExponent = 2.4,
    stationaryHoldFrames = 1,
    stationarySettleSpeed = 2.4,
    stationaryReflowSpacing = 1.6,
    enhancedReflowSpacing = 1.1,
    stationaryReflowConstraint = 0.86,
    enhancedReflowConstraint = 0.92,
    stationaryCollapsePull = 0.18,
    enhancedCollapsePull = 0.26,
    stationaryCullPerFrame = 3,
    enhancedCullPerFrame = 5,
    tailCollapseDistance = 2.4,
}

function fluidTrailIsEnhanced()
    return player.isDashing or keys.shift or fluidTrailEnhancedFrames > 0
end

local function fluidNoise1D(x, seed)
    local ix = math.floor(x)
    local xf = x - ix
    local u = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
    local g0 = hash01(ix * 17.37 + seed * 101.13) * 2 - 1
    local g1 = hash01((ix + 1) * 17.37 + seed * 101.13) * 2 - 1
    return (g0 * xf + u * (g1 * (xf - 1) - g0 * xf)) * 2
end

local function beginDashFluid(x, y)
    dashFluidPoints = {}
    dashFluidDistance = 0
    if x and y then
        dashFluidPoints[#dashFluidPoints + 1] = {
            x = x,
            y = y,
            dist = 0,
            velocity = dist2(player.vx or 0, player.vy or 0),
            dirX = player.facingRight and 1 or -1,
            dirY = 0,
            enhanced = false,
        }
    end
end

local function boostFluidTrail(frames)
    fluidTrailEnhancedFrames = math.max(fluidTrailEnhancedFrames, frames or 24)
end

local function spawnDashFluidDroplet(x, y, parentVel, nx, ny, seed, enhanced, dirX, dirY)
    local angle = hash01(seed + 13) * math.pi * 2
    local ejectSpeed = enhanced and (1.5 + hash01(seed + 17) * 5.0) or (0.5 + hash01(seed + 17) * 1.5)
    local tangentX, tangentY = dirX or (player.facingRight and 1 or -1), dirY or 0
    local tangentLen = dist2(tangentX, tangentY)
    if tangentLen < 0.001 then tangentX, tangentY, tangentLen = player.facingRight and 1 or -1, 0, 1 end
    tangentX, tangentY = tangentX / tangentLen, tangentY / tangentLen
    local backPull = enhanced and 0.38 or 0.15
    dashFluidDroplets[#dashFluidDroplets + 1] = {
        x = x,
        y = y,
        vx = -tangentX * parentVel * backPull + math.cos(angle) * ejectSpeed * 0.4 + nx * (hash01(seed + 23) - 0.5) * 0.7,
        vy = -tangentY * parentVel * backPull + math.sin(angle) * ejectSpeed * 0.4 + (enhanced and (-1.0 - hash01(seed + 29) * 2.0) or 0.4),
        radius = enhanced and (0.6 + hash01(seed + 31) * 1.8) or (2.0 + hash01(seed + 31) * 3.5),
        life = 1.0,
        decay = enhanced and (0.022 + hash01(seed + 37) * 0.03) or (0.015 + hash01(seed + 37) * 0.015),
        kind = enhanced and "dash_streak" or "normal_blob",
    }
    if #dashFluidDroplets > 120 then table.remove(dashFluidDroplets, 1) end
end

local function addDashFluidPoint(targetX, targetY, velocity, anchorHead, enhanced, dirX, dirY)
    local nextX, nextY = targetX, targetY
    local isEnhanced = enhanced or fluidTrailIsEnhanced()
    if #dashFluidPoints > 0 then
        local head = dashFluidPoints[#dashFluidPoints]
        if not anchorHead then
            local tension = isEnhanced and fluidTrailConfig.dashSpineTension or fluidTrailConfig.spineTension
            nextX = head.x + (targetX - head.x) * tension
            nextY = head.y + (targetY - head.y) * tension
        end
        dashFluidDistance = dashFluidDistance + dist2(nextX - head.x, nextY - head.y)
    end
    local tangentX, tangentY = dirX, dirY
    if not tangentX or not tangentY or dist2(tangentX, tangentY) < 0.001 then
        tangentX, tangentY = player.facingRight and 1 or -1, 0
    end
    dashFluidPoints[#dashFluidPoints + 1] = {
        x = nextX,
        y = nextY,
        dist = dashFluidDistance,
        velocity = velocity or 0,
        dirX = tangentX,
        dirY = tangentY,
        enhanced = isEnhanced,
    }
    local maxLength = fluidTrailIsEnhanced() and fluidTrailConfig.dashMaxLength or fluidTrailConfig.normalMaxLength
    while #dashFluidPoints > maxLength do table.remove(dashFluidPoints, 1) end
end

local function addDashStreak(x1, y1, x2, y2, kind)
    local dx, dy = x2 - x1, y2 - y1
    local len = dist2(dx, dy)
    if len < 1 then return end
    local enhanced = kind == true or kind == "enhanced" or fluidTrailIsEnhanced()
    local steps = math.max(1, math.ceil(len / (enhanced and 3 or 5)))
    local velocity = math.max(len, dist2(player.vx or 0, player.vy or 0))
    local dirX, dirY = dx / len, dy / len
    for i = 1, steps do
        local t = i / steps
        addDashFluidPoint(x1 + dx * t, y1 + dy * t, velocity, i == steps, enhanced, dirX, dirY)
    end
end

local function updateFluidTrailFromPlayer(prevX, prevY)
    prevX = prevX or player.x
    prevY = prevY or player.y
    local dx, dy = player.x - prevX, player.y - prevY
    local moveLen = dist2(dx, dy)
    local speed = math.max(moveLen, dist2(player.vx or 0, player.vy or 0))
    local enhanced = fluidTrailIsEnhanced()
    local inputActive = keys.a or keys.d or keys.w or keys.s or keys.space or keys.shift or player.isDashing
    local drivenMotion = player.onEaves or player.swingRope or player.ridingCrane or player.isGliding
    local settled = (not inputActive) and (not drivenMotion) and speed < fluidTrailConfig.stationarySettleSpeed

    if #dashFluidPoints == 0 then
        beginDashFluid(prevX, prevY)
    end

    if moveLen > 0.35 and not settled then
        fluidTrailRecentMoveFrames = fluidTrailConfig.stationaryHoldFrames
        addDashStreak(prevX, prevY, player.x, player.y, enhanced and "enhanced" or "normal")
    elseif #dashFluidPoints > 0 then
        if settled then fluidTrailRecentMoveFrames = 0 end
        local last = dashFluidPoints[#dashFluidPoints]
        last.x, last.y = player.x, player.y
        last.velocity = speed
        last.dirX = math.abs(player.vx or 0) + math.abs(player.vy or 0) > 0.001 and (player.vx / math.max(0.001, dist2(player.vx, player.vy))) or last.dirX
        last.dirY = math.abs(player.vx or 0) + math.abs(player.vy or 0) > 0.001 and (player.vy / math.max(0.001, dist2(player.vx, player.vy))) or last.dirY
        last.enhanced = last.enhanced or enhanced
    else
        addDashFluidPoint(player.x, player.y, speed, true, enhanced, player.facingRight and 1 or -1, 0)
    end

    local last = dashFluidPoints[#dashFluidPoints]
    if last then
        last.x, last.y = player.x, player.y
        last.velocity = speed
        local vLen = dist2(player.vx or 0, player.vy or 0)
        if vLen > 0.001 then
            last.dirX, last.dirY = player.vx / vLen, player.vy / vLen
        end
        last.enhanced = last.enhanced or enhanced
    end
end

function recomputeFluidTrailDistances()
    dashFluidDistance = 0
    for i = 1, #dashFluidPoints do
        local p = dashFluidPoints[i]
        if i == 1 then
            p.dist = 0
        else
            local prev = dashFluidPoints[i - 1]
            dashFluidDistance = dashFluidDistance + dist2(p.x - prev.x, p.y - prev.y)
            p.dist = dashFluidDistance
        end
    end
end

function reflowFluidTrailToPlayer()
    local count = #dashFluidPoints
    if count <= 1 then return end

    local enhanced = fluidTrailIsEnhanced()
    local spacing = enhanced and fluidTrailConfig.enhancedReflowSpacing or fluidTrailConfig.stationaryReflowSpacing
    local constraint = enhanced and fluidTrailConfig.enhancedReflowConstraint or fluidTrailConfig.stationaryReflowConstraint
    local collapsePull = enhanced and fluidTrailConfig.enhancedCollapsePull or fluidTrailConfig.stationaryCollapsePull
    local head = dashFluidPoints[count]
    head.x, head.y = player.x, player.y
    head.velocity = 0

    for i = count - 1, 1, -1 do
        local p = dashFluidPoints[i]
        local next = dashFluidPoints[i + 1]
        local dx, dy = p.x - next.x, p.y - next.y
        local d = dist2(dx, dy)
        if d > spacing then
            local targetX = next.x + dx / d * spacing
            local targetY = next.y + dy / d * spacing
            p.x = p.x + (targetX - p.x) * constraint
            p.y = p.y + (targetY - p.y) * constraint
        else
            p.x = p.x + (next.x - p.x) * collapsePull
            p.y = p.y + (next.y - p.y) * collapsePull
        end
        p.velocity = (p.velocity or 0) * 0.55
        p.dirX, p.dirY = next.x - p.x, next.y - p.y
    end

    local cull = enhanced and fluidTrailConfig.enhancedCullPerFrame or fluidTrailConfig.stationaryCullPerFrame
    local removed = 0
    while #dashFluidPoints > 1 and removed < cull do
        local tail = dashFluidPoints[1]
        local next = dashFluidPoints[2]
        if dist2(tail.x - next.x, tail.y - next.y) > fluidTrailConfig.tailCollapseDistance then break end
        table.remove(dashFluidPoints, 1)
        removed = removed + 1
    end

    recomputeFluidTrailDistances()
end

local function addBristle(x, y, vx, vy, kind)
    bristleParticles[#bristleParticles + 1] = {
        x = x, y = y,
        vx = -(vx or 0) * 0.18 + (hash01(elapsed * 50 + x) - 0.5) * 5,
        vy = -(vy or 0) * 0.18 + (hash01(elapsed * 70 + y) - 0.5) * 5,
        life = 28 + hash01(x * 0.03 + y) * 18,
        maxLife = 46,
        kind = kind,
    }
end
