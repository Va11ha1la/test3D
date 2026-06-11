-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function resetCollections()
    branches = {}
    branchGroups = {}
    branchBounds = {}
    branchMetadata = {}
    bambooSegments = {}
    targets = {}
    blooms = {}
    trailParticles = {}
    dashFluidPoints = {}
    dashFluidDroplets = {}
    dashFluidDistance = 0
    fluidTrailEnhancedFrames = 0
    fluidTrailRecentMoveFrames = 0
    fluidTrailDashBlend = 0
    bristleParticles = {}
    needleCorpses = {}
    ambientParticles = {}
    glidingLeaves = {}
    willowRopes = {}
    floatingPetals = {}
    roofs = {}
    pavilions = {}
    gears = {}
    chimes = {}
    cranes = {}
    cloudPlatforms = {}
    streams = {}
    pineSprings = {}
    windWaves = {}
    collectedCount = 0
    completionTimer = 0
    completionSealDelay = 0
    waterLevel = 0
end

local function resetPlayer()
    player.radius = currentLevel.radius
    player.gravityDefault = currentLevel.gravity
    player.gravity = currentLevel.gravity
    player.jumpForce = currentLevel.jumpForce
    player.dashSpeed = currentLevel.dashSpeed
    player.friction = currentLevel.friction
    player.speed = 1.6
    player.vx, player.vy = 0, 0
    player.isDashing, player.dashTime = false, 0
    player.waterfallDashBoost = 0
    player.facingRight, player.canDash = true, true
    player.isGrounded, player.isWallClinging = false, false
    player.wallSide = 0
    player.isGliding = false
    player.swingRope, player.ridingCrane = nil, nil
    player.craneCooldown = 0
    player.onEaves = nil
    player.eavesT, player.eavesSpeed = 0, 0

    if currentLevel.trace then
        player.x, player.y = TRACE_RT.spawnX, TRACE_RT.spawnY - 24
    elseif currentLevel.id == "bamboo" then
        local nodes = {}
        for _, s in ipairs(bambooSegments) do if s.stalkId == "bamboo1" and s.isNode then nodes[#nodes + 1] = s end end
        local safe = nodes[math.max(1, #nodes - 3)]
        if safe then player.x, player.y = safe.nodeX - 25, safe.nodeY - 200 else player.x, player.y = W(0.15), H(0.3) end
    elseif currentLevel.id == "pine" then
        local ns = branchGroups.pine1 or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.10), H(0.70) end
    elseif currentLevel.id == "maple" then
        local ns = branchGroups.main or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.05), H(0.72) end
    elseif currentLevel.id == "plum" or currentLevel.id == "plum_parallax" then
        local ns = branchGroups.main_trunk or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.90), H(0.55) end
        player.facingRight = false
    elseif currentLevel.id == "plum_mirror" then
        local ns = branchGroups.main_trunk or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.10), H(0.55) end
        player.facingRight = true
    elseif currentLevel.id == "plum_finale" then
        local ns = branchGroups.finale_trunk or {}
        local safe = ns[12]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.06), H(0.78) end
        player.facingRight = true
    elseif currentLevel.id == "wentong_zhu" then
        local ns = branchGroups.wt_cane or {}
        local safe = ns[10]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.08), H(0.18) end
        player.facingRight = true
    elseif currentLevel.id == "plum_xiyan" then
        local ns = branchGroups.xy_trunk or {}
        local safe = ns[12]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.95), H(0.45) end
        player.facingRight = false
    elseif currentLevel.id == "xuwei_grape" then
        local ns = branchGroups.xw_vine or {}
        local safe = ns[8]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.92), H(0.26) end
        player.facingRight = false
    elseif currentLevel.id == "molong" then
        local ns = branchGroups.dragon_body or {}
        local safe = ns[math.max(1, math.floor(#ns * 0.45))]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.40), H(0.65) end
        player.facingRight = true
    elseif currentLevel.id == "peach" then
        local ns = branchGroups.main_trunk or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 25) else player.x, player.y = W(0.05), H(0.72) end
    elseif currentLevel.id == "eaves" then
        local ns = branchGroups.pavilion_beam_0 or {}
        local safe = ns[math.floor(#ns / 2)]
        if safe then player.x, player.y = safe.x, safe.y - player.radius - 20 else player.x, player.y = W(0.05), H(0.60) end
    elseif currentLevel.id == "huangshan" then
        local ns = branchGroups.pine_l1 or {}
        local safe = ns[15]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 15) else player.x, player.y = W(0.05), H(0.50) end
    elseif currentLevel.id == "plum_master" then
        local ns = branchGroups.master_mid_right or branchGroups.master_trunk or {}
        local safe = ns[math.max(1, math.floor(#ns * 0.22))]
        if safe then player.x, player.y = safe.x, safe.y - (safe.r + player.radius + 20) else player.x, player.y = W(0.50), H(0.38) end
    elseif currentLevel.id == "ldtk_grand_scroll" then
        if not resetLDtkGrandScrollPlayer() then
            player.x, player.y = W(0.02), H(0.82)
        end
    end
    fluidTrailEnhancedFrames = 0
    fluidTrailRecentMoveFrames = 0
    fluidTrailDashBlend = 0
    beginDashFluid(player.x, player.y)
    dashFluidDroplets = {}
end

local function loadLevel(index)
    if index < 1 then index = #LEVELS end
    if index > #LEVELS then index = 1 end
    currentLevelIdx = index
    currentLevel = LEVELS[currentLevelIdx]
    worldW = DESIGN_W * currentLevel.wmul
    worldH = DESIGN_H * currentLevel.hmul
    resetCollections()

    if currentLevel.id == "bamboo" then generateBamboo()
    elseif currentLevel.id == "pine" then generatePine()
    elseif currentLevel.id == "maple" then generateMaple()
    elseif currentLevel.id == "plum" then generatePlum()
    elseif currentLevel.id == "peach" then generatePeach()
    elseif currentLevel.id == "eaves" then generateEaves()
    elseif currentLevel.id == "huangshan" then generateHuangshan()
    elseif currentLevel.id == "plum_master" then generatePlumMaster()
    elseif currentLevel.id == "plum_parallax" then generatePlum() -- 视差关复用蟠梅长卷地形(sourceLevelIndex=4)
    elseif currentLevel.id == "plum_mirror" then generatePlumMirror()
    elseif currentLevel.id == "plum_finale" then generatePlumFinale()
    elseif currentLevel.id == "wentong_zhu" then generateWentongZhu()
    elseif currentLevel.id == "plum_xiyan" then generatePlumXiyan()
    elseif currentLevel.id == "xuwei_grape" then generateXuweiGrape()
    elseif currentLevel.id == "molong" then generateMolong()
    elseif currentLevel.id == "ldtk_grand_scroll" then generateLDtkGrandScroll()
    elseif currentLevel.trace then generateTraceLevel()
    end

    resetPlayer()
    cameraX = clamp(player.x - DESIGN_W * 0.5, 0, math.max(0, worldW - DESIGN_W))
    cameraY = clamp(player.y - DESIGN_H * 0.5, 0, math.max(0, worldH - DESIGN_H))
    showSeal = false
    sealViewProgress = 0
    sealStampProgress = 0
    print(string.format("Loaded ink HTML port %d/%d: %s", currentLevelIdx, #LEVELS, currentLevel.name))
end

local function startDash()
    local inBambooFall = currentLevel and currentLevel.id == "bamboo" and player.x > W(0.32) and player.x < W(0.80) and player.y > H(0.03)
    if player.isDashing or ((not player.canDash) and (not inBambooFall)) then return end
    boostFluidTrail(26)
    player.isDashing = true
    player.canDash = false
    player.dashTime = inBambooFall and 16 or 12
    local dx = (keys.d and 1 or 0) - (keys.a and 1 or 0)
    local dy = (keys.s and 1 or 0) - (keys.w and 1 or 0)
    if inBambooFall and dx == 0 and dy == 0 then
        dx, dy = 1, -0.28
    elseif dx == 0 and dy == 0 then
        dx = player.facingRight and 1 or -1
    end
    local d = dist2(dx, dy)
    if d < 0.001 then d = 1 end
    player.dashDirX, player.dashDirY = dx / d, dy / d
    player.vy = 0
    player.waterfallDashBoost = inBambooFall and 3.5 or 0
    if inBambooFall then
        player.vx = player.dashDirX * (player.dashSpeed + 3.0)
        player.vy = player.dashDirY * (player.dashSpeed + 3.0)
    end
    dashJustPressed = false
end

local function circleBranchCollision()
    player.isGrounded = false
    local nearWall, detectedWallSide = false, 0
    local closest = {}

    for branchId, list in pairs(branchGroups) do
        local bounds = branchBounds and branchBounds[branchId]
        local pad = currentLevel.id == "maple" and 260 or 90
        if (not bounds) or (player.x >= bounds.minX - pad and player.x <= bounds.maxX + pad and player.y >= bounds.minY - pad and player.y <= bounds.maxY + pad) then
            for _, b in ipairs(list) do
                if math.abs(player.x - b.x) <= b.r + 55 and math.abs(player.y - b.y) <= b.r + 55 then
                    local dx, dy = player.x - b.x, player.y - b.y
                    local d = dist2(dx, dy)
                    if not closest[b.branchId] or d < closest[b.branchId].dist then
                        closest[b.branchId] = { node = b, dist = d, dx = dx, dy = dy }
                    end
                end
            end
        end
    end

    for _, item in pairs(closest) do
        local b, d = item.node, item.dist
        local minDist = player.radius + b.r * 0.96
        if d < minDist then
            local overlap = minDist - d
            local nx, ny = item.dx / (d == 0 and 1 or d), item.dy / (d == 0 and 1 or d)
            if d == 0 then nx, ny, overlap = 0, -1, minDist end
            player.x = player.x + nx * overlap
            player.y = player.y + ny * overlap
            if ny < -0.4 then
                player.isGrounded = true
                player.canDash = true
                player.isWallClinging = false
                local impactVy = math.max(0, player.vy)
                if player.vy > 0 then player.vy = 0 end
                if currentLevel.id == "maple" and branchMetadata[b.branchId] then
                    local meta = branchMetadata[b.branchId]
                    meta.targetBend = math.min(meta.maxBend, meta.targetBend + 7.5 + impactVy * 4.2)
                end
            elseif ny > 0.4 and player.vy < 0 then
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
    else
        player.isWallClinging = false
    end
end

local function bambooCollision()
    player.isGrounded = false
    local nearWall, detectedWallSide = false, 0
    for _, seg in ipairs(bambooSegments) do
        local dx, dy = seg.x2 - seg.x1, seg.y2 - seg.y1
        local len2 = dx * dx + dy * dy
        local t = clamp(((player.x - seg.x1) * dx + (player.y - seg.y1) * dy) / len2, 0, 1)
        local px, py = seg.x1 + t * dx, seg.y1 + t * dy
        local distX, distY = player.x - px, player.y - py
        local d = dist2(distX, distY)
        local minDist = player.radius + seg.r
        if d < minDist then
            local nx, ny = distX / (d == 0 and 1 or d), distY / (d == 0 and 1 or d)
            player.x = player.x + nx * (minDist - d)
            player.y = player.y + ny * (minDist - d)
            if player.isDashing and hash01(elapsed * 88 + px) > 0.55 then
                addBristle(px, py, player.vx, player.vy, "leaf")
            end
            if math.abs(nx) > 0.7 and not player.isGrounded then
                if (keys.a and nx > 0) or (keys.d and nx < 0) then
                    nearWall = true
                    detectedWallSide = nx > 0 and -1 or 1
                end
            end
        end
        if seg.isNode and player.vy >= 0 and math.abs(player.x - seg.nodeX) < seg.r * 3 and player.y < seg.nodeY and player.y + player.radius > seg.nodeY - 5 then
            player.y = seg.nodeY - player.radius
            player.vy = 0
            player.isGrounded = true
            player.canDash = true
            player.isWallClinging = false
        end
    end
    if nearWall and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = detectedWallSide
    else
        player.isWallClinging = false
    end
end

local function updateTargets()
    for _, t in ipairs(targets) do
        if not t.dead then
            if t.hitCooldown and t.hitCooldown > 0 then t.hitCooldown = t.hitCooldown - 1 end
            local dx, dy = player.x - t.x, player.y - t.y
            local d = dist2(dx, dy)
            local isNeedleEnemy = currentLevel.id == "pine" or currentLevel.id == "huangshan"
            if d < t.r + player.radius + 20 and player.isDashing then
                t.dead = true
                collectedCount = collectedCount + 1
                if isNeedleEnemy then
                    player.vy = (player.dashDirY or 0) * currentLevel.dashSpeed * 0.24
                    player.dashTime = math.max(player.dashTime or 0, 7)
                elseif currentLevel.id == "peach" or currentLevel.id == "bamboo" then
                    -- These targets only change the scene; they should not steer the player.
                else
                    player.vy = currentLevel.id == "bamboo" and -12 or -18.5
                end
                player.canDash = true
                local bloom = {
                    x = t.x, y = t.y, attachX = t.attachX, attachY = t.attachY,
                    scale = 0, progress = 0, normX = t.normX, normY = t.normY,
                    branchId = t.branchId, nodeIndex = t.nodeIndex, attachOffset = t.attachOffset,
                    orientationJitter = t.orientationJitter,
                    kind = currentLevel.id, r = t.r,
                }
                blooms[#blooms + 1] = bloom
                if triggerTargetEffect then triggerTargetEffect(t, bloom) end
                for i = 1, 18 do addBristle(t.x, t.y, -player.vx, -player.vy, "bloom") end
                if collectedCount >= #targets then
                    completionSealDelay = 0.95
                end
            elseif isNeedleEnemy and d < t.r + player.radius + 8 and (not t.hitCooldown or t.hitCooldown <= 0) then
                local nx, ny = dx, dy
                if d < 0.001 then
                    nx = player.facingRight and -1 or 1
                    ny = -0.35
                    d = dist2(nx, ny)
                end
                nx, ny = nx / d, ny / d
                if math.abs(nx) < 0.32 then nx = player.x < t.x and -0.72 or 0.72 end
                player.x = player.x + nx * 7
                player.vx = nx * 8.2 + (t.normX or 0) * 2.0
                player.vy = math.min(player.vy, -4.2)
                player.isGrounded = false
                player.canDash = true
                t.hitCooldown = 22
                t.hitFlash = 1
                for i = 1, 10 do addBristle(t.x, t.y, -nx * 8, -ny * 3, currentLevel.id) end
            end
        end
    end
end

function spawnMapleLeafChain(t)
    local baseSeed = t.x * 0.017 + t.y * 0.013 + collectedCount * 31
    for i = 1, 3 do
        glidingLeaves[#glidingLeaves + 1] = {
            x = t.x + W(0.035 * i) + (hash01(baseSeed + i * 7) - 0.5) * 18,
            y = t.y + H(0.030 * i) + (hash01(baseSeed + i * 11) - 0.5) * 24,
            size = 22 + hash01(baseSeed + i * 13) * 7,
            speed = 0.55 + hash01(baseSeed + i * 17) * 0.35,
            bob = hash01(baseSeed + i * 19) * 6.28,
            platform = true,
            spawned = true,
        }
    end
    player.vy = math.min(player.vy, currentLevel.jumpForce * 0.82)
end

function swayNearestWillow(x, y)
    local best, bestD = nil, 999999
    for _, rope in ipairs(willowRopes) do
        local tipX = rope.anchorX + math.sin(rope.angle or 0) * rope.length
        local tipY = rope.anchorY + math.cos(rope.angle or 0) * rope.length
        local d = math.min(dist2(x - tipX, y - tipY), dist2(x - rope.anchorX, y - rope.anchorY) * 0.72)
        if d < bestD then best, bestD = rope, d end
    end
    local dir = player.facingRight and 1 or -1
    if best then
        dir = x > best.anchorX and 1 or -1
        best.angularVelocity = best.angularVelocity + dir * 0.052
        best.angle = clamp((best.angle or 0) + dir * 0.09, -1.18, 1.18)
    end
    for i = 1, 16 do addBristle(x, y, -dir * 5, -8, "bloom") end
end

function pulseNearestChime(x, y)
    local best, bestD = nil, 999999
    for _, ch in ipairs(chimes) do
        local d = dist2(x - ch.x, y - ch.y)
        if d < bestD then best, bestD = ch, d end
    end
    if best then
        best.swayAngle = (x > best.x and -1 or 1) * 0.32
        best.pulse = best.pulse + 1.6
        windWaves[#windWaves + 1] = { x = best.x, y = best.y + 16, r = 0, life = 46, maxLife = 46 }
    else
        windWaves[#windWaves + 1] = { x = x, y = y, r = 0, life = 38, maxLife = 38 }
    end
end

function launchAlongEavesRoute(t)
    local best, bestD = nil, 999999
    for _, ch in ipairs(chimes) do
        local d = dist2(t.x - ch.x, t.y - (ch.y + 26))
        if d < bestD then
            best, bestD = ch, d
        end
    end
    player.isDashing = false
    player.dashTime = 0
    player.onEaves = nil
    player.canDash = true
    if best then
        local bellX, bellY = best.x, best.y + 28
        local dx, dy = t.x - bellX, t.y - bellY
        local len = dist2(dx, dy)
        if len < 0.001 then
            dx = player.facingRight and 1 or -1
            dy = -0.45
            len = dist2(dx, dy)
        end
        dx, dy = dx / len, dy / len
        if math.abs(dx) < 0.28 then dx = player.facingRight and 0.72 or -0.72 end
        best.swayAngle = -dx * 0.58
        best.pulse = best.pulse + 2.6
        player.x = bellX + dx * (player.radius + 10)
        player.y = bellY + dy * 10
        player.vx = dx * 14.5
        player.vy = math.min(dy * 8.0 - 10.5, -7.8)
        windWaves[#windWaves + 1] = { x = bellX, y = bellY, r = 0, life = 48, maxLife = 48 }
        windWaves[#windWaves + 1] = { x = t.x, y = t.y, r = 0, life = 30, maxLife = 30 }
        for i = 1, 24 do addBristle(bellX, bellY, -player.vx, -player.vy, "gold") end
    else
        player.vx = player.vx * 0.4
        player.vy = math.min(player.vy, -7.2)
        for i = 1, 14 do addBristle(t.x, t.y, -player.vx, -player.vy, "gold") end
    end
end

MAX_NEEDLE_CORPSES = 260

function spawnNeedleCorpseScatter(t, amount)
    local nx, ny = t.normX or 0, t.normY or -1
    local tx, ty = -ny, nx
    local baseX = t.attachX and (t.attachX + nx * ((t.r or 36) * 0.42)) or t.x
    local baseY = t.attachY and (t.attachY + ny * ((t.r or 36) * 0.42)) or t.y
    local count = amount or (currentLevel.id == "huangshan" and 15 or 18)
    local branchAngle = math.atan2(ty, tx)
    for i = 1, count do
        local seed = t.x * 0.017 + t.y * 0.013 + i * 31 + collectedCount * 7
        local along = (hash01(seed + 3) - 0.5) * (t.r or 36) * 2.6
        local lift = (hash01(seed + 7) - 0.22) * (t.r or 36) * 0.58
        needleCorpses[#needleCorpses + 1] = {
            x = baseX + tx * along + nx * lift,
            y = baseY + ty * along + ny * lift,
            angle = branchAngle + (hash01(seed + 11) - 0.5) * 0.95,
            len = (t.r or 36) * (0.38 + hash01(seed + 17) * 0.48),
            width = 0.85 + hash01(seed + 19) * 0.95,
            alpha = 96 + hash01(seed + 23) * 88,
            seed = seed,
            kind = currentLevel.id,
        }
    end
    while #needleCorpses > MAX_NEEDLE_CORPSES do table.remove(needleCorpses, 1) end
end

function triggerTargetEffect(t, bloom)
    if currentLevel.id == "pine" or currentLevel.id == "huangshan" then
        bloom.springPulse = 0.65
        local dirX = player.dashDirX or (player.facingRight and 1 or -1)
        if math.abs(dirX) < 0.18 then dirX = player.facingRight and 1 or -1 end
        player.vx = player.vx + dirX * 4.8
        player.vy = player.vy * 0.35
        player.dashTime = math.max(player.dashTime or 0, 7)
        for i = 1, 28 do addBristle(t.x, t.y, -player.vx * 0.35, -player.vy * 0.2, currentLevel.id) end
        if spawnInkLabHitFeedback then spawnInkLabHitFeedback(t) end
    elseif currentLevel.id == "maple" then
        spawnMapleLeafChain(t)
    elseif currentLevel.id == "peach" then
        swayNearestWillow(t.x, t.y)
    elseif currentLevel.id == "eaves" then
        launchAlongEavesRoute(t)
    end
end

local function updatePeachRopes()
    for _, rope in ipairs(willowRopes) do
        local g = 0.3
        rope.oscTime = rope.oscTime + 0.015
        local wind = math.sin(rope.oscTime) * 0.0008
        local accel = -(g / rope.length) * math.sin(rope.angle) + wind
        rope.angularVelocity = (rope.angularVelocity + accel) * 0.995
        rope.angularVelocity = clamp(rope.angularVelocity, -0.05, 0.05)
        rope.angle = clamp(rope.angle + rope.angularVelocity, -1.3, 1.3)
    end
end

local function ropeTip(rope)
    return rope.anchorX + math.sin(rope.angle) * rope.length, rope.anchorY + math.cos(rope.angle) * rope.length
end

function mapleLeafVisualY(leaf)
    return leaf.y + math.sin(elapsed + leaf.bob) * (leaf.platform and 10 or 18)
end

function mapleLeafPlatformCollision()
    if currentLevel.id ~= "maple" or player.vy < 0 then return end
    for _, leaf in ipairs(glidingLeaves) do
        if leaf.platform then
            local y = mapleLeafVisualY(leaf)
            local topY = y - leaf.size * 0.22
            local halfW = leaf.size * 1.36
            local footY = player.y + player.radius
            if math.abs(player.x - leaf.x) < halfW + player.radius and footY >= topY and footY <= topY + math.max(24, player.vy + 14) then
                player.y = topY - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
                player.isGliding = false
                leaf.squash = 1
                if hash01(elapsed * 120 + leaf.x) > 0.62 then addBristle(player.x, player.y + player.radius, player.vx, -2, "red") end
                break
            end
        end
    end
end

function updateBloomSpringInteractions()
    return
end

local function updateSpecialBeforeMovement()
    if currentLevel.id == "ldtk_grand_scroll" then
        updateLDtkGrandScrollSpecial()
        return
    end

    if currentLevel.id == "molong" then
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
        local x1, x2 = W(0.32), W(0.80)
        if player.x > x1 and player.x < x2 and player.y > H(0.03) then
            local center = W(0.56)
            local fallHalf = W(0.27)
            local lift = clamp(1 - math.abs(player.x - center) / fallHalf, 0.42, 1)
            player.vy = math.max(player.vy - 1.92 * lift, -14.2)
            player.vx = player.vx + 0.18 * lift
            if player.isDashing then
                player.vx = player.vx + 0.38 * lift
                player.vy = player.vy - 0.30 * lift
            end
            if hash01(elapsed * 60 + player.x) > 0.52 then addTrail(player.x, player.y + 10, player.radius * (1.1 + lift * 0.5), 0.12, 34, "water") end
        end
    elseif currentLevel.id == "pine" then
        for _, s in ipairs(streams) do
            local dx, dy = s.x2 - s.x1, s.y2 - s.y1
            local len2 = dx * dx + dy * dy
            local t = clamp(((player.x - s.x1) * dx + (player.y - s.y1) * dy) / len2, 0, 1)
            local px, py = s.x1 + t * dx, s.y1 + t * dy
            local d = dist2(player.x - px, player.y - py)
            if d < s.width then
                local l = math.sqrt(len2)
                player.vx = player.vx + (dx / l) * 0.42
                player.vy = player.vy + (dy / l) * 0.28
                if hash01(elapsed * 80 + d) > 0.6 then addTrail(player.x, player.y, player.radius * 1.5, 0.10, 20, "water") end
            end
        end
    elseif currentLevel.id == "maple" then
        if player.vy > 0 and not player.isDashing then
            for _, leaf in ipairs(glidingLeaves) do
                if dist2(player.x - leaf.x, player.y - leaf.y) < player.radius + leaf.size then
                    player.isGliding = true
                end
            end
        end
    elseif currentLevel.id == "peach" then
        updatePeachRopes()
        if player.swingRope then
            local rope = player.swingRope
            local tx, ty = ropeTip(rope)
            player.x, player.y = tx, ty
            local push = (keys.d and 1 or 0) - (keys.a and 1 or 0)
            rope.angularVelocity = rope.angularVelocity + push * 0.002
            if keys.space or dashJustPressed then
                player.swingRope = nil
                player.vx = math.cos(rope.angle) * rope.angularVelocity * rope.length * 0.9 + push * 6
                player.vy = currentLevel.jumpForce * 0.85
                player.canDash = true
                keys.space = false
            end
            return
        elseif not player.isDashing then
            for _, rope in ipairs(willowRopes) do
                local tx, ty = ropeTip(rope)
                if dist2(player.x - tx, player.y - ty) < player.radius + 36 then
                    player.swingRope = rope
                    break
                end
            end
        end
    elseif currentLevel.id == "huangshan" then
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
            return
        elseif player.craneCooldown == 0 and not player.isDashing then
            for _, c in ipairs(cranes) do
                if dist2(player.x - c.x, player.y - c.y) < player.radius + 36 then
                    player.ridingCrane = c
                    break
                end
            end
        end
        for _, cp in ipairs(cloudPlatforms) do
            local cy = cp.y + math.sin(elapsed * 1.2 + cp.bob) * 8
            if math.abs(player.x - cp.x) < cp.rx and math.abs((player.y + player.radius) - cy) < cp.ry * 0.75 and player.vy >= 0 then
                player.y = cy - player.radius
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
            end
        end
    end
end

local function updateEavesMechanics()
    if currentLevel.id ~= "eaves" then return false end
    if player.y > H(0.84) then
        player.vy = -7.6
        player.vx = -4.5
        player.onEaves = nil
        addTrail(player.x, player.y, player.radius * 2, 0.20, 50, "gold")
    end
    if player.onEaves then
        local r = player.onEaves
        player.isGrounded = true
        player.canDash = true
        local slopeY = r.y2 - r.y1
        local slideDir = r.x2 > r.x1 and 1 or -1
        player.eavesSpeed = (player.eavesSpeed + slideDir * slopeY * 0.00065) * 0.985
        if keys.a then player.eavesSpeed = player.eavesSpeed - 0.18 end
        if keys.d then player.eavesSpeed = player.eavesSpeed + 0.18 end
        player.eavesT = player.eavesT + player.eavesSpeed * 0.0022
        if player.eavesT < 0 then player.eavesT, player.eavesSpeed = 0, -player.eavesSpeed * 0.2 end
        local t = player.eavesT
        if t >= 1 then
            t = 1
            local dx = 2 * (1 - t) * (r.cp.x - r.x1) + 2 * t * (r.x2 - r.cp.x)
            local dy = 2 * (1 - t) * (r.cp.y - r.y1) + 2 * t * (r.y2 - r.cp.y)
            local len = dist2(dx, dy)
            local finalSpd = math.max(9.5, math.abs(player.eavesSpeed) * 1.4)
            player.x = qbez(r.x1, r.cp.x, r.x2, t)
            player.y = qbez(r.y1, r.cp.y, r.y2, t) - player.radius - 5
            player.vx = (dx / len) * finalSpd
            player.vy = (dy / len) * finalSpd - 8.5
            player.onEaves = nil
            for i = 1, 16 do addBristle(player.x, player.y, player.vx, player.vy, "gold") end
        else
            player.x = qbez(r.x1, r.cp.x, r.x2, t)
            player.y = qbez(r.y1, r.cp.y, r.y2, t) - player.radius - 5
            player.vx, player.vy = 0, 0
            if math.abs(player.eavesSpeed) > 1.2 and hash01(elapsed * 90 + player.x) > 0.4 then
                addTrail(player.x, player.y, player.radius * 1.5, 0.25, 40, "gold")
                addBristle(player.x, player.y + player.radius, player.eavesSpeed * slideDir, 2, "gold")
            end
            if keys.space then
                player.onEaves = nil
                player.vy = player.jumpForce - 2
                player.vx = player.eavesSpeed * slideDir * 1.2
                keys.space = false
            end
        end
        return true
    end
    return false
end

