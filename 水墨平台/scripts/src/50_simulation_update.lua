-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function fixedStep()
    elapsed = elapsed + FIXED_DT
    applyStaticBranchBend()

    for _, g in ipairs(gears) do g.angle = g.angle + g.speed end
    for _, ch in ipairs(chimes) do
        ch.pulse = ch.pulse + 0.04
        ch.swayAngle = math.sin(ch.pulse) * 0.08
    end
    for _, c in ipairs(cranes) do
        if not c.path then
            c.x = c.x + c.speed
            c.theta = c.theta + 0.03
            c.y = c.startY + math.sin(c.theta) * c.amplitude
            c.wingAngle = math.sin(c.theta * 3.5) * (math.pi / 4)
            if c.x > worldW + 100 then
                c.x = -100
                c.startY = H(0.2 + hash01(elapsed + c.speed) * 0.4)
            end
        end
    end
    for _, leaf in ipairs(glidingLeaves) do
        leaf.x = leaf.x + leaf.speed
        leaf.y = leaf.y + math.sin(elapsed * 1.2 + leaf.bob) * (leaf.platform and 0.06 or 0.18)
        if leaf.platform then
            leaf.squash = math.max(0, (leaf.squash or 0) - 0.08)
            if leaf.x > worldW + 50 then
                leaf.x = -50
                leaf.y = H(0.64 + hash01(elapsed + leaf.size) * 0.26)
            end
        elseif leaf.x > worldW + 50 then
            leaf.x = -50
            leaf.y = hash01(elapsed + leaf.size) * worldH * 0.5
        end
    end
    for _, p in ipairs(floatingPetals) do
        p.x = p.x + p.speed
        p.bob = p.bob + 0.02
        if p.x > worldW + 80 then
            p.x = -80
            p.y = waterLevel + (hash01(elapsed + p.speed) - 0.5) * 15
        end
    end

    if dashJustPressed then startDash() end

    local prevX, prevY = player.x, player.y
    updateSpecialBeforeMovement()
    if updateEavesMechanics() then
        updateFluidTrailFromPlayer(prevX, prevY)
        updateTargets()
        return
    end
    if player.swingRope or player.ridingCrane then
        updateFluidTrailFromPlayer(prevX, prevY)
        updateTargets()
        return
    end

    if player.isDashing then
        player.dashTime = player.dashTime - 1
        local dashBoost = player.waterfallDashBoost or 0
        player.vx = player.dashDirX * (player.dashSpeed + dashBoost)
        player.vy = player.dashDirY * (player.dashSpeed + dashBoost)
        if player.dashTime <= 0 then
            player.isDashing = false
            player.waterfallDashBoost = 0
            player.vx = player.vx * 0.5
        end
    else
        if player.isGliding then
            player.gravity = 0.08
            player.vy = math.min(player.vy, 1.8)
            if keys.a then player.vx = player.vx - 0.6; player.facingRight = false end
            if keys.d then player.vx = player.vx + 0.6; player.facingRight = true end
            if hash01(elapsed * 99) > 0.4 then addTrail(player.x, player.y, player.radius * 1.5, 0.35, 60, "red") end
        else
            player.gravity = player.gravityDefault
            if keys.a then player.vx = player.vx - player.speed; player.facingRight = false end
            if keys.d then player.vx = player.vx + player.speed; player.facingRight = true end
        end

        if keys.space then
            if player.isGrounded then
                local extraJump = 0
                if currentLevel.id == "maple" then
                    for _, b in ipairs(branches) do
                        if dist2(player.x - b.x, player.y - b.y) < b.r + player.radius + 5 and branchMetadata[b.branchId] then
                            local meta = branchMetadata[b.branchId]
                            extraJump = meta.bend * b.t * b.t * meta.bounceFactor
                            meta.springVel = -meta.springBackForce * 1.25
                            break
                        end
                    end
                end
                player.vy = player.jumpForce - extraJump
                player.isGrounded = false
            elseif player.isWallClinging then
                player.vy = player.jumpForce * (currentLevel.id == "bamboo" and 1.05 or 0.95)
                player.vx = -player.wallSide * (currentLevel.id == "bamboo" and 14 or 11.5)
                player.canDash = true
                player.isWallClinging = false
                for i = 1, 8 do addBristle(player.x, player.y, -player.vx, -player.vy, currentLevel.id) end
            end
            keys.space = false
        end

        if player.isWallClinging then
            player.vy = math.min(player.vy, currentLevel.id == "bamboo" and 2.5 or 1.8)
        else
            player.vy = player.vy + player.gravity
        end
        player.vx = player.vx * player.friction
    end

    player.x = player.x + player.vx
    player.y = player.y + player.vy

    if player.isDashing then
        local mx, my = player.x - prevX, player.y - prevY
        local steps = math.max(math.ceil(dist2(mx, my) / 6), 1)
        boostFluidTrail(4)
        for i = 0, steps do
            local t = i / steps
            if hash01(elapsed * 80 + i) > 0.82 then addBristle(prevX + mx * t, prevY + my * t, player.vx, player.vy, "inkgas") end
        end
    end

    if currentLevel.trace then
        traceCollision(prevX, prevY)
    elseif currentLevel.id == "bamboo" then
        bambooCollision()
    elseif currentLevel.id == "ldtk_grand_scroll" then
        ldtkGrandScrollCollision(prevX, prevY)
    else
        circleBranchCollision()
    end
    if currentLevel.id == "maple" then mapleLeafPlatformCollision() end
    updateBloomSpringInteractions()

    if currentLevel.id == "peach" and player.vy >= 0 then
        for _, p in ipairs(floatingPetals) do
            local y = p.y + math.sin(p.bob) * 4
            if math.abs(player.x - p.x) < p.w * 0.5 + player.radius and player.y - y < 0 and player.y - y > -p.h - player.radius then
                player.y = y - player.radius - 2
                player.vy = 0
                player.isGrounded = true
                player.canDash = true
            end
        end
    elseif currentLevel.id == "eaves" then
        if not player.onEaves and not player.isDashing and player.vy >= 0 then
            for _, r in ipairs(roofs) do
                for _, p in ipairs(r.points) do
                    if dist2(player.x - p.x, player.y - p.y) < player.radius + 15 then
                        player.onEaves = r
                        player.eavesT = p.t
                        player.eavesSpeed = math.abs(player.vx) * 0.5 + 1.2
                        break
                    end
                end
                if player.onEaves then break end
            end
        end
        for _, ch in ipairs(chimes) do
            if dist2(player.x - ch.x, player.y - (ch.y + 16)) < player.radius + 24 then
                player.vy = player.jumpForce * 1.05
                player.vx = player.vx + (player.x - ch.x) * 1.5
                player.canDash = true
                player.onEaves = nil
                ch.swayAngle = (player.vx > 0 and 1 or -1) * 0.25
                windWaves[#windWaves + 1] = { x = ch.x, y = ch.y + 16, r = 0, life = 42, maxLife = 42 }
            end
        end
        if not player.onEaves and not player.isDashing then
            for _, gear in ipairs(gears) do
                local d = dist2(player.x - gear.x, player.y - gear.y)
                if d < gear.radius + player.radius + gear.teethHeight and d > gear.radius - 30 then
                    player.isGrounded = true
                    player.canDash = true
                    local a = math.atan2(player.y - gear.y, player.x - gear.x) + gear.speed
                    player.x = gear.x + math.cos(a) * (gear.radius + player.radius - 2)
                    player.y = gear.y + math.sin(a) * (gear.radius + player.radius - 2)
                    player.vx, player.vy = 0, 0
                    if keys.space then
                        player.vx = -math.sin(a) * gear.speed * gear.radius * 12 + (keys.d and 4 or -4)
                        player.vy = player.jumpForce
                        player.isGrounded = false
                        keys.space = false
                    end
                    break
                end
            end
        end
    end

    if player.y > worldH + 100 then
        resetPlayer()
        prevX, prevY = player.x, player.y
    end
    player.x = clamp(player.x, -120, worldW + 120)
    updateFluidTrailFromPlayer(prevX, prevY)
    updateTargets()
    player.isGliding = false
end

local function updateParticles()
    if fluidTrailEnhancedFrames > 0 then
        fluidTrailEnhancedFrames = fluidTrailEnhancedFrames - 1
    end
    if fluidTrailRecentMoveFrames > 0 then
        fluidTrailRecentMoveFrames = fluidTrailRecentMoveFrames - 1
    elseif #dashFluidPoints > 1 then
        reflowFluidTrailToPlayer()
    end
    for i = #dashFluidDroplets, 1, -1 do
        local d = dashFluidDroplets[i]
        d.x = d.x + d.vx
        d.y = d.y + d.vy
        d.vy = d.vy + 0.06
        d.vx = d.vx * 0.96
        d.life = d.life - d.decay
        if d.life <= 0 or d.radius * math.max(0, d.life) <= 0.1 then table.remove(dashFluidDroplets, i) end
    end
    for i = #trailParticles, 1, -1 do
        local p = trailParticles[i]
        p.life = p.life - 1
        if p.life <= 0 then table.remove(trailParticles, i) end
    end
    for i = #bristleParticles, 1, -1 do
        local p = bristleParticles[i]
        p.life = p.life - 1
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.vx = p.vx * 0.98
        p.vy = p.vy + 0.12
        if p.life <= 0 then table.remove(bristleParticles, i) end
    end
    for _, b in ipairs(blooms) do
        b.progress = math.min(1, b.progress + 0.08)
        local t = b.progress
        b.scale = 1 + 1.5 * (t - 1) ^ 3 + 0.5 * (t - 1) ^ 2
        b.springPulse = math.max(0, (b.springPulse or 0) - 0.08)
        if b.springCooldown and b.springCooldown > 0 then b.springCooldown = b.springCooldown - 1 end
    end
    for i = #windWaves, 1, -1 do
        local w = windWaves[i]
        w.life = w.life - 1
        w.r = w.r + 5
        if w.life <= 0 then table.remove(windWaves, i) end
    end
end

