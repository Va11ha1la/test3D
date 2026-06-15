TRACE_DEBUG_FIT = false
-- 描摹关运行时(第 18+ 关):多边形碰撞 + 分层视差 + 触碰开花 + 画卷终幕
-- 注意:本文件不得新增 chunk 顶级 local(bundle 已 199/200),全部用全局。

TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0, def = nil,
    goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0,
    chars = {}, pools = {}, ripples = {}, ghostGrps = {}, plumDone = 0, plumTotal = 0 }

function traceInsidePoly(poly, x, y)
    local n = #poly
    local inside = false
    for i = 1, n do
        local ax, ay = poly[i][1], poly[i][2]
        local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
        if (ay > y) ~= (by > y) then
            local ix = ax + (y - ay) / (by - ay) * (bx - ax)
            if ix > x then inside = not inside end
        end
    end
    return inside
end

function traceSnapDown(x, y)
    local bestY = nil
    for _, poly in ipairs(TRACE_RT.polys) do
        local bb = poly.bb
        if (not poly.ghostGrp) and ((not bb) or (x >= bb[1] - 4 and x <= bb[3] + 4)) then
            local n = #poly
            for i = 1, n do
                local ax, ay = poly[i][1], poly[i][2]
                local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
                if (ax < x) ~= (bx < x) and math.abs(bx - ax) > 1e-6 then
                    local t = (x - ax) / (bx - ax)
                    local iy = ay + (by - ay) * t
                    if iy >= y - 100 and iy <= y + 1500 then
                        if (bestY == nil or iy < bestY) and traceInsidePoly(poly, x, iy + 5) then
                            bestY = iy
                        end
                    end
                end
            end
        end
    end
    if bestY then return bestY - 2 end
    return y
end

function generateTraceLevel()
    if currentLevel.traceKey == "bamboo" or currentLevel.traceKey == "bamboo_v2" then
        generateBambooScroll()
        return
    end
    local def = TRACE_DEFS[currentLevel.traceKey]
    TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0, def = def,
        goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0,
        chars = {}, pools = {}, ripples = {}, ghostGrps = {}, plumDone = 0, plumTotal = 0 }
    TRACE_RT.design = TRACE_IPTS and TRACE_IPTS[currentLevel.traceKey] or nil
    worldW = def.spanx2 + def.frw
    worldH = def.spany2 + def.frh
    -- 层包围盒 + 碰撞多边形
    for _, lay in ipairs(def.layers) do
        if not lay.bb then
            lay.bb = {}
            for pi, fp in ipairs(lay.polys) do
                local x1, y1, x2, y2 = 1e9, 1e9, -1e9, -1e9
                for k = 1, #fp - 1, 2 do
                    local x, y = fp[k], fp[k + 1]
                    if x < x1 then x1 = x end
                    if x > x2 then x2 = x end
                    if y < y1 then y1 = y end
                    if y > y2 then y2 = y end
                end
                lay.bb[pi] = { x1, y1, x2, y2 }
            end
        end
        if lay.coll == 1 then
            for pi, fp in ipairs(lay.polys) do
                local poly = {}
                for k = 1, #fp - 1, 2 do poly[#poly + 1] = { fp[k], fp[k + 1] } end
                poly.bb = lay.bb[pi]
                TRACE_RT.polys[#TRACE_RT.polys + 1] = poly
            end
        end
    end
    -- 鬼阶:设计区内完整包含的碰撞体转虚影组(激活后限时实体)
    if TRACE_RT.design and TRACE_RT.design.ghosts then
        for _, gz in ipairs(TRACE_RT.design.ghosts) do
            local grp = { timer = 0, polys = {} }
            for _, poly in ipairs(TRACE_RT.polys) do
                local bb = poly.bb
                if bb and bb[1] >= gz.zone[1] and bb[2] >= gz.zone[2]
                    and bb[3] <= gz.zone[3] and bb[4] <= gz.zone[4] then
                    poly.ghostGrp = grp
                    grp.polys[#grp.polys + 1] = poly
                end
            end
            TRACE_RT.ghostGrps[#TRACE_RT.ghostGrps + 1] = grp
        end
    end
    -- 出生/存档吸附
    TRACE_RT.spawnX = def.conf.spawn[1]
    TRACE_RT.spawnY = traceSnapDown(def.conf.spawn[1], def.conf.spawn[2]) - 12
    TRACE_RT.cps = {}
    for i, cp in ipairs(def.conf.cps) do
        TRACE_RT.cps[i] = { cp[1], traceSnapDown(cp[1], cp[2]) - 12 }
        TRACE_RT.cpReached[i] = (i == 1)
    end
    -- 交互点:装饰层聚类(梅红/兰绿) + 沿顶面自动补点
    local plumPts, orchidPts = {}, {}
    for _, lay in ipairs(def.layers) do
        local oc = lay.ocol
        if oc[1] == 150 and oc[2] == 45 then
            for _, bb in ipairs(lay.bb) do
                plumPts[#plumPts + 1] = { x = (bb[1] + bb[3]) * 0.5, y = (bb[2] + bb[4]) * 0.5,
                    r = clamp(math.max(bb[3] - bb[1], bb[4] - bb[2]) * 0.5, 12, 30) }
            end
        elseif oc[1] == 72 and oc[2] == 115 then
            for pi, bb in ipairs(lay.bb) do
                orchidPts[#orchidPts + 1] = { x = (bb[1] + bb[3]) * 0.5, y = bb[4], lay = lay, pi = pi }
            end
        end
    end
    local function clusterize(pts, rad, kind)
        for _, pt in ipairs(pts) do
            local home = nil
            for _, ip in ipairs(TRACE_RT.ipoints) do
                if ip.kind == kind and (ip.x - pt.x) ^ 2 + (ip.y - pt.y) ^ 2 < rad * rad then
                    home = ip
                    break
                end
            end
            if not home then
                home = { x = pt.x, y = pt.y, kind = kind, trig = false, members = {}, n = 0 }
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] = home
            end
            pt.t = 0
            pt.delay = 0
            home.members[#home.members + 1] = pt
            home.n = home.n + 1
            home.x = home.x + (pt.x - home.x) / home.n
            home.y = home.y + (pt.y - home.y) / home.n
        end
    end
    clusterize(plumPts, 360, "plum")
    clusterize(orchidPts, 300, "orchid")
    for _, ip in ipairs(TRACE_RT.ipoints) do
        if ip.kind == "plum" then TRACE_RT.plumTotal = TRACE_RT.plumTotal + 1 end
    end
    -- 设计锚点(87_trace_ipoints):风袂/蓄墨苞/墨池/拾字
    if TRACE_RT.design then
        for _, d in ipairs(TRACE_RT.design.ipts) do
            if d.kind == "gust" then
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] =
                    { x = d.x, y = d.y, kind = "gust", arm = 0, burst = 999, members = {} }
            elseif d.kind == "key" then
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] =
                    { x = d.x, y = d.y, kind = "key", grp = TRACE_RT.ghostGrps[d.grp],
                        bloomT = 0, members = {} }
            elseif d.kind == "deco" then
                -- 石上兰:吸附到岩面再生成(沿用 sprout 触碰开兰逻辑)
                local sy2 = traceSnapDown(d.x, d.y - 120)
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] =
                    { x = d.x, y = sy2 - 14, kind = "sprout", trig = false,
                        members = { { x = d.x, y = sy2, r = 1, t = 0, delay = 0 } } }
            elseif d.kind == "char" then
                TRACE_RT.chars[#TRACE_RT.chars + 1] =
                    { x = d.x, y = d.y, ch = d.ch, got = false, fade = 0 }
            elseif d.kind == "pool" then
                local my2 = traceSnapDown((d.x1 + d.x2) * 0.5, d.y - 200)
                TRACE_RT.pools[#TRACE_RT.pools + 1] = { x1 = d.x1, x2 = d.x2, y = my2 }
            end
        end
    end
    -- 自动补点(顶面;有设计数据的关停用,避免黑地长花)
    local cands = {}
    for _, poly in ipairs(TRACE_RT.polys) do
        local n = #poly
        for i = 1, n do
            local ax, ay = poly[i][1], poly[i][2]
            local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
            if math.abs(by - ay) < 14 and math.abs(bx - ax) > 90 then
                local mx, my = (ax + bx) / 2, (ay + by) / 2
                if traceInsidePoly(poly, mx, my + 8) then
                    cands[#cands + 1] = { x = mx, y = my }
                end
            end
        end
    end
    table.sort(cands, function(a, b) return a.x < b.x end)
    local lastX = -1e9
    if TRACE_RT.design then cands = {} end
    for ci, cd in ipairs(cands) do
        if cd.x - lastX > 520 then
            local clash = false
            for _, ip in ipairs(TRACE_RT.ipoints) do
                if (ip.x - cd.x) ^ 2 + (ip.y - cd.y) ^ 2 < 360 * 360 then
                    clash = true
                    break
                end
            end
            if not clash then
                lastX = cd.x
                local kind = (hash01(ci * 5.3) > 0.45) and "plum" or "sprout"
                local ip = { x = cd.x, y = cd.y - 16, kind = kind, trig = false, members = {} }
                if kind == "plum" then
                    for k = 1, 4 + math.floor(hash01(ci) * 3) do
                        ip.members[#ip.members + 1] = { x = cd.x + (hash01(ci * 7 + k) - 0.5) * 130,
                            y = cd.y - 10 - hash01(ci * 11 + k) * 42,
                            r = 11 + hash01(ci * 13 + k) * 8, t = 0, delay = 0 }
                    end
                else
                    ip.members[#ip.members + 1] = { x = cd.x, y = cd.y, r = 1, t = 0, delay = 0 }
                end
                TRACE_RT.ipoints[#TRACE_RT.ipoints + 1] = ip
            end
        end
    end
    -- 描摹关专属镜头(沿用 kingsbird 设计:广角+慢跟随)
    TRACE_RT.zoom = TRACE_DEBUG_FIT and math.min(DESIGN_W / (worldW + 80), DESIGN_H / (worldH + 80)) or (({ zhumei = 0.75, forest = 0.92, water = 0.92 })[currentLevel.traceKey] or 1.0)
    TRACE_RT.camCx = TRACE_RT.spawnX
    TRACE_RT.camCy = TRACE_RT.spawnY - 50
    print(string.format("[trace] %s polys=%d ipoints=%d world=%dx%d",
        currentLevel.traceKey, #TRACE_RT.polys, #TRACE_RT.ipoints, worldW, worldH))
end

function traceUpdateCamera()
    local RT = TRACE_RT
    if not RT.def then return end
    local z = RT.zoom or 1
    local halfW = DESIGN_W / (2 * z)
    local halfH = DESIGN_H / (2 * z)
    local tx = player.x
    local ty = player.y - 50
    RT.camCx = (RT.camCx or tx) + (tx - (RT.camCx or tx)) * 0.07
    local yFollow = 0.06
    if RT.bamboo and RT.bambooData == BAMBOO_DATA_22 and player.x > 4400 and player.x < 5050 then yFollow = 0.12 end
    RT.camCy = (RT.camCy or ty) + (ty - (RT.camCy or ty)) * yFollow
    if worldW <= halfW * 2 then RT.camCx = worldW / 2
    else RT.camCx = clamp(RT.camCx, halfW, worldW - halfW) end
    if worldH <= halfH * 2 then RT.camCy = worldH / 2
    else RT.camCy = clamp(RT.camCy, halfH, worldH - halfH) end
    cameraX = RT.camCx - DESIGN_W / 2
    cameraY = RT.camCy - DESIGN_H / 2
    -- 镜头随笔锋:触苞瞬间朝生长方向轻推
    if RT.nudge and RT.nudge.t > 0 then
        local f = RT.nudge.t / 22
        f = f * f
        cameraX = cameraX + RT.nudge.x * f
        cameraY = cameraY + RT.nudge.y * f
        RT.nudge.t = RT.nudge.t - 1
    end
end

function traceCollideOnce()
    local pr = player.radius
    local px, py = player.x, player.y
    local hitG, wallSide = false, 0
    for _, poly in ipairs(TRACE_RT.polys) do
        local bb = poly.bb
        if (poly.ghostGrp and poly.ghostGrp.timer <= 0) then
            -- 鬼阶未实体化:无碰撞
        elseif not (bb and (px + pr < bb[1] or px - pr > bb[3] or py + pr < bb[2] or py - pr > bb[4])) then
            local n = #poly
            local inside = false
            local bestD2, bestX, bestY = 1e18, 0, 0
            for i = 1, n do
                local ax, ay = poly[i][1], poly[i][2]
                local bx, by = poly[i % n + 1][1], poly[i % n + 1][2]
                if (ay > py) ~= (by > py) then
                    local ix = ax + (py - ay) / (by - ay) * (bx - ax)
                    if ix > px then inside = not inside end
                end
                local ex, ey = bx - ax, by - ay
                local L2 = ex * ex + ey * ey
                if L2 > 1e-6 then
                    local t = clamp(((px - ax) * ex + (py - ay) * ey) / L2, 0, 1)
                    local cx, cy = ax + ex * t, ay + ey * t
                    local dx, dy = px - cx, py - cy
                    local d2 = dx * dx + dy * dy
                    if d2 < bestD2 then bestD2, bestX, bestY = d2, cx, cy end
                end
            end
            if inside then
                local dx, dy = bestX - px, bestY - py
                local d = math.sqrt(dx * dx + dy * dy)
                local nx, ny
                if d > 1e-4 then nx, ny = dx / d, dy / d else nx, ny = 0, -1 end
                local vdot = nx * player.vx + ny * player.vy
                if vdot > 0.1 then
                    local spd = math.sqrt(player.vx ^ 2 + player.vy ^ 2)
                    if spd > 0.5 then nx, ny = -player.vx / spd, -player.vy / spd; bestX, bestY = px, py end
                end
                px = bestX + nx * (pr + 1)
                py = bestY + ny * (pr + 1)
                local vn = player.vx * nx + player.vy * ny
                if vn < 0 then player.vx = player.vx - nx * vn; player.vy = player.vy - ny * vn end
                if ny < -0.55 then hitG = true end
                if nx > 0.75 then wallSide = -1 end
                if nx < -0.75 then wallSide = 1 end
            elseif bestD2 < pr * pr and bestD2 > 1e-9 then
                local d = math.sqrt(bestD2)
                local nx, ny = (px - bestX) / d, (py - bestY) / d
                px = bestX + nx * pr
                py = bestY + ny * pr
                local vn = player.vx * nx + player.vy * ny
                if vn < 0 then player.vx = player.vx - nx * vn; player.vy = player.vy - ny * vn end
                if ny < -0.55 then hitG = true end
                if nx > 0.75 then wallSide = -1 end
                if nx < -0.75 then wallSide = 1 end
            end
        end
    end
    player.x, player.y = px, py
    return hitG, wallSide
end

function traceCollision(prevX, prevY)
    local RT = TRACE_RT
    if not RT.def then return end
    -- 顿笔:触苞瞬间冻结数帧(有收笔点则锁在收笔点,否则回卷上一帧)
    if RT.hitstop and RT.hitstop > 0 then
        RT.hitstop = RT.hitstop - 1
        if RT.hitstopX then
            player.x, player.y = RT.hitstopX, RT.hitstopY
            if RT.hitstop <= 0 then RT.hitstopX = nil end
        else
            player.x, player.y = prevX, prevY
        end
        return
    end
    -- 终幕:冻结
    if RT.goalDone then
        RT.vista = RT.vista + 1
        player.x, player.y = RT.gx, RT.gy
        player.vx, player.vy = 0, 0
        player.isDashing = false
        player.canDash = false
        if RT.vista == 430 then loadLevel(currentLevelIdx + 1) end
        return
    end
    -- 子步碰撞(防高速穿透):回退到 prev 再分步推进
    local mx, my = player.x - prevX, player.y - prevY
    local steps = math.max(1, math.ceil(math.sqrt(mx * mx + my * my) / 6))
    player.x, player.y = prevX, prevY
    local hitG, wallSide = false, 0
    for i = 1, steps do
        player.x = player.x + mx / steps
        player.y = player.y + my / steps
        local g, w = traceCollideOnce()
        if g then hitG = true end
        if w ~= 0 then wallSide = w end
    end
    player.isGrounded = hitG
    if hitG then
        player.canDash = true
        player.isWallClinging = false
    elseif wallSide ~= 0 and player.vy > 0 then
        player.isWallClinging = true
        player.wallSide = wallSide
    else
        player.isWallClinging = false
    end
    -- 跌落/雾渊回档
    local dead = player.y > RT.def.conf.kill
    if (not dead) and RT.bamboo and RT.bambooData and RT.bambooData.killZones then
        for _, z in ipairs(RT.bambooData.killZones) do
            if player.x >= z[1] and player.x <= z[3] and player.y >= z[2] and player.y <= z[4] then
                dead = true
                break
            end
        end
    end
    if dead then
        player.x, player.y = RT.spawnX, RT.spawnY - 24
        player.vx, player.vy = 0, 0
        player.isDashing = false
        player.swingRope, player.ridingCrane = nil, nil
        player.canDash = true
    end
    -- 存档点
    for i, cp in ipairs(RT.cps) do
        if not RT.cpReached[i] then
            local dx, dy = player.x - cp[1], player.y - cp[2]
            if dx * dx + dy * dy < 80 * 80 then
                RT.cpReached[i] = true
                RT.spawnX, RT.spawnY = cp[1], cp[2]
            end
        end
    end
    -- 终点(梅苞集满才开卷)
    local g = RT.def.conf.goal
    local dgx, dgy = player.x - g[1], player.y - g[2]
    if dgx * dgx + dgy * dgy < 95 * 95 and RT.plumDone >= RT.plumTotal then
        RT.goalDone = true
        RT.vista = 0
        RT.gx, RT.gy = player.x, player.y
    end
    -- 鬼阶计时
    for _, grp in ipairs(RT.ghostGrps) do
        if grp.timer > 0 then grp.timer = grp.timer - 1 end
    end
    -- 拾字
    for _, ch in ipairs(RT.chars) do
        if not ch.got then
            local dx, dy = player.x - ch.x, player.y - ch.y
            if dx * dx + dy * dy < 58 * 58 then
                ch.got = true
                for k = 1, 10 do
                    RT.petals[#RT.petals + 1] = { x = ch.x, y = ch.y,
                        vx = (hash01(ch.x + k * 7) - 0.5) * 2.6, vy = -0.8 - hash01(k * 3.1) * 1.4,
                        rot = hash01(k * 5.7) * 6.28, vr = (hash01(k * 9.1) - 0.5) * 0.15,
                        life = 80 + k * 4, age = 0, ph = k, col = { 176, 142, 56 } }
                end
            end
        elseif ch.fade < 1 then
            ch.fade = math.min(1, ch.fade + 0.03)
        end
    end
    -- 墨池:落入溅墨晕 + 轻滑步
    if RT.bamboo and RT.bambooData and RT.bambooData.inkPools then
        for _, pl in ipairs(RT.bambooData.inkPools) do
            if player.isGrounded and player.x > pl.x1 and player.x < pl.x2
                and math.abs(player.y - pl.y) < 130 then
                if my > 5.5 then
                    RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                        t = 0, big = math.min(my / 14, 1.4) }
                    RT.fallPenalty = math.max(RT.fallPenalty or 0, 30)
                elseif math.abs(player.vx) > 5 and hash01(elapsed * 53 + player.x) < 0.10 then
                    RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                        t = 0, big = 0.45 }
                end
                if math.abs(player.vx) > 1 and math.abs(player.vx) < 13 then
                    player.vx = player.vx * 1.05
                end
            end
        end
    end
    for _, pl in ipairs(RT.pools) do
        if player.isGrounded and player.x > pl.x1 and player.x < pl.x2
            and math.abs(player.y - pl.y) < 130 then
            if my > 5.5 then
                RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                    t = 0, big = math.min(my / 14, 1.4) }
            elseif math.abs(player.vx) > 5 and hash01(elapsed * 53 + player.x) < 0.10 then
                RT.ripples[#RT.ripples + 1] = { x = player.x, y = player.y + player.radius,
                    t = 0, big = 0.45 }
            end
            if math.abs(player.vx) > 1 and math.abs(player.vx) < 13 then
                player.vx = player.vx * 1.05
            end
        end
    end
    for i = #RT.ripples, 1, -1 do
        local rp = RT.ripples[i]
        rp.t = rp.t + 1
        if rp.t > 55 then table.remove(RT.ripples, i) end
    end
    -- 交互点
    if RT.bamboo then
        bambooBudUpdate()
        for i = #RT.petals, 1, -1 do
            local pt = RT.petals[i]
            pt.age = pt.age + 1
            pt.x = pt.x + pt.vx + math.sin(pt.age * 0.08 + pt.ph) * 0.5
            pt.y = pt.y + pt.vy
            pt.vy = math.min(pt.vy + 0.022, 1.0)
            pt.rot = pt.rot + pt.vr
            if pt.age > pt.life then table.remove(RT.petals, i) end
        end
        return
    end
    RT.plumDone = 0
    for _, ip in ipairs(RT.ipoints) do
        if ip.kind == "plum" and ip.trig then RT.plumDone = RT.plumDone + 1 end
        if ip.kind == "gust" then
            -- 风袂:可重复触发,刷新冲刺+上推
            if ip.arm > 0 then ip.arm = ip.arm - 1 end
            ip.burst = ip.burst + 1
            local dx, dy = player.x - ip.x, player.y - ip.y
            -- 站定不触发:需在空中或有明确移动意图,避免落竿后被反复弹起
            local moving = (not player.isGrounded) or math.abs(player.vx) > 1.5 or player.vy < -1
            if ip.arm <= 0 and moving and dx * dx + dy * dy < 80 * 80 then
                ip.arm = 160
                ip.burst = 0
                player.canDash = true
                if player.vy > -13 then player.vy = -13 end
                for k = 1, 14 do
                    RT.petals[#RT.petals + 1] = { x = ip.x + (hash01(k * 3.3) - 0.5) * 46,
                        y = ip.y + (hash01(k * 7.1) - 0.5) * 30,
                        vx = (hash01(k * 5.9) - 0.5) * 3.4, vy = -1.2 - hash01(k * 2.7) * 2.2,
                        rot = hash01(k * 4.3) * 6.28, vr = (hash01(k * 8.3) - 0.5) * 0.2,
                        life = 60 + k * 3, age = 0, ph = k * 1.7, col = { 56, 78, 50 } }
                end
            end
        elseif ip.kind == "key" then
            -- 蓄墨苞:触碰实体化鬼阶组(可在余时 <240 帧时续墨)
            local dx, dy = player.x - ip.x, player.y - ip.y
            if ip.grp and dx * dx + dy * dy < 72 * 72 and ip.grp.timer < 240 then
                ip.grp.timer = 300
                ip.ring = 0
                ip.bloomT = 0.01
                for k = 1, 12 do
                    RT.petals[#RT.petals + 1] = { x = ip.x, y = ip.y,
                        vx = (hash01(k * 6.1) - 0.5) * 3.0, vy = -0.6 - hash01(k * 3.7) * 1.6,
                        rot = hash01(k * 2.9) * 6.28, vr = (hash01(k * 7.7) - 0.5) * 0.18,
                        life = 70 + k * 3, age = 0, ph = k * 2.1, col = { 40, 38, 34 } }
                end
            end
            if ip.ring then ip.ring = ip.ring + 1 end
            if ip.bloomT > 0 and ip.bloomT < 1 then ip.bloomT = math.min(1, ip.bloomT + 0.05) end
        elseif not ip.trig then
            local dx, dy = player.x - ip.x, player.y - ip.y
            if dx * dx + dy * dy < 64 * 64 then
                ip.trig = true
                ip.ring = 0
                for mi, m in ipairs(ip.members) do
                    m.delay = (mi - 1) * 6 + math.floor(hash01(mi * 7.7) * 5)
                end
            end
        else
            if ip.ring then ip.ring = ip.ring + 1 end
            for _, m in ipairs(ip.members) do
                if m.delay > 0 then
                    m.delay = m.delay - 1
                elseif m.t < 1 then
                    m.t = math.min(1, m.t + 0.055)
                    if ip.kind == "plum" and m.t > 0.12 and m.t < 0.18 then
                        for _ = 1, 4 do
                            TRACE_RT.petals[#TRACE_RT.petals + 1] = {
                                x = m.x + (hash01(elapsed * 91 + m.x) - 0.5) * 28,
                                y = m.y + (hash01(elapsed * 47 + m.y) - 0.5) * 20,
                                vx = (hash01(m.x + elapsed) - 0.5) * 1.4,
                                vy = -0.5 - hash01(m.y + elapsed * 3) * 0.8,
                                rot = hash01(m.x * 3) * 6.28, vr = (hash01(m.y * 5) - 0.5) * 0.12,
                                life = 110 + math.floor(hash01(m.x + m.y) * 70), age = 0,
                                ph = hash01(m.x) * 6.28 }
                        end
                    end
                elseif ip.kind == "plum" and hash01(elapsed * 13 + ip.x) < 0.003 then
                    TRACE_RT.petals[#TRACE_RT.petals + 1] = { x = m.x, y = m.y, vx = 0.2, vy = 0.2,
                        rot = hash01(m.x) * 6.28, vr = 0.05, life = 140, age = 0, ph = hash01(m.y) * 6.28 }
                end
            end
        end
    end
    for i = #RT.petals, 1, -1 do
        local pt = RT.petals[i]
        pt.age = pt.age + 1
        pt.x = pt.x + pt.vx + math.sin(pt.age * 0.08 + pt.ph) * 0.5
        pt.y = pt.y + pt.vy
        pt.vy = math.min(pt.vy + 0.022, 1.0)
        pt.rot = pt.rot + pt.vr
        if pt.age > pt.life then table.remove(RT.petals, i) end
    end
end

TRACE_PETAL_RED = { 198, 46, 66 }

function traceDrawGust(ip)
    local ready = ip.arm <= 0
    local grow = ready and 1 or clamp((160 - ip.arm) / 160, 0.25, 1)
    local sway = math.sin(elapsed * 1.8 + ip.x * 0.02) * 0.12
    -- 竹梢叶簇(触发后凋落重生)
    for k = 0, 4 do
        local a = -1.5708 + (k - 2) * 0.42 + sway + (ready and 0 or 0.3)
        local ln = (34 + hash01(ip.x + k * 13) * 20) * grow
        nvgSave(vg)
        nvgTranslate(vg, ip.x, ip.y)
        nvgRotate(vg, a)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, -ln * 0.5, 4.6, ln * 0.5)
        nvgFillColor(vg, rgba(48, 66, 44, ready and 235 or 150))
        nvgFill(vg)
        nvgRestore(vg)
    end
    -- 就绪时的上升风纹
    if ready then
        for k = 0, 2 do
            local t = (elapsed * 0.7 + k * 0.33) % 1
            nvgStrokeColor(vg, rgba(96, 104, 92, 120 * (1 - t)))
            nvgStrokeWidth(vg, 2.2)
            nvgBeginPath(vg)
            nvgArc(vg, ip.x, ip.y - 14 - t * 64, 16 + t * 10, math.pi * 1.15, math.pi * 1.85, NVG_CW)
            nvgStroke(vg)
        end
    end
    if ip.burst < 26 then
        local t = ip.burst / 26
        nvgStrokeColor(vg, rgba(70, 90, 64, 200 * (1 - t)))
        nvgStrokeWidth(vg, 3 * (1 - t) + 0.6)
        nvgBeginPath(vg)
        nvgCircle(vg, ip.x, ip.y, 14 + t * 64)
        nvgStroke(vg)
    end
    -- 触发后的上升气流柱:让"被托起"读得见
    if ip.burst < 44 then
        local t = ip.burst / 44
        for k = 0, 3 do
            local xx = ip.x + (hash01(ip.x + k * 17.3) - 0.5) * 44
            local len = 36 + hash01(k * 7.9) * 28
            local yy = ip.y - 16 - t * 175 - k * 22
            nvgStrokeColor(vg, rgba(110, 120, 104, 155 * (1 - t)))
            nvgStrokeWidth(vg, 2.6 - k * 0.4)
            nvgBeginPath(vg)
            nvgMoveTo(vg, xx, yy)
            nvgBezierTo(vg, xx + 5, yy - len * 0.4, xx - 5, yy - len * 0.7, xx + 2, yy - len)
            nvgStroke(vg)
        end
    end
end

function traceDrawKeyBud(ip)
    local grp = ip.grp
    local act = grp and grp.timer > 0
    local ph = elapsed * 2.4 + ip.x * 0.01
    -- 触发后的墨瓣绽开
    if ip.bloomT > 0 then
        local sc = 1 - (1 - ip.bloomT) ^ 3
        for k = 0, 4 do
            local a = k * 1.2566 + 0.4
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x + math.cos(a) * 11 * sc, ip.y + math.sin(a) * 11 * sc, 6.5 * sc)
            nvgFillColor(vg, rgba(44, 42, 38, 200))
            nvgFill(vg)
        end
    end
    nvgBeginPath(vg)
    nvgCircle(vg, ip.x, ip.y, act and 10.5 or (9 + math.sin(ph) * 1.5))
    nvgFillColor(vg, rgba(34, 32, 30, act and 245 or 215))
    nvgFill(vg)
    if not act then
        nvgStrokeColor(vg, rgba(70, 66, 62, 56 + 26 * math.sin(ph)))
        nvgStrokeWidth(vg, 2.4)
        nvgBeginPath(vg)
        nvgCircle(vg, ip.x, ip.y, 26 + math.sin(ph) * 4)
        nvgStroke(vg)
    else
        -- 余墨计时弧
        local f = grp.timer / 300
        nvgStrokeColor(vg, rgba(40, 38, 34, 205))
        nvgStrokeWidth(vg, 3)
        nvgBeginPath(vg)
        nvgArc(vg, ip.x, ip.y, 19, -1.5708, -1.5708 + f * 6.2832, NVG_CW)
        nvgStroke(vg)
        -- 墨脉:苞到各鬼阶的流动墨点,标出因果
        for _, poly in ipairs(grp.polys) do
            local bb = poly.bb
            if bb then
                local tx2, ty2 = (bb[1] + bb[3]) * 0.5, bb[2]
                for k = 0, 2 do
                    local t = (elapsed * 0.8 + k * 0.34 + bb[1] * 0.001) % 1
                    local mx2 = ip.x + (tx2 - ip.x) * t
                    local my3 = ip.y + (ty2 - ip.y) * t - math.sin(t * 3.14159) * 46
                    nvgBeginPath(vg)
                    nvgCircle(vg, mx2, my3, 3.2 * (1 - t * 0.5))
                    nvgFillColor(vg, rgba(44, 42, 38, 165 * (1 - t * 0.6) * math.min(f * 4, 1)))
                    nvgFill(vg)
                end
            end
        end
    end
    if ip.ring and ip.ring < 50 then
        local t = ip.ring / 50
        nvgStrokeColor(vg, rgba(60, 56, 52, 200 * (1 - t)))
        nvgStrokeWidth(vg, 3.5 * (1 - t) + 0.6)
        nvgBeginPath(vg)
        nvgCircle(vg, ip.x, ip.y, 16 + t * 70)
        nvgStroke(vg)
    end
end

function traceDrawPlumFlower(x, y, r, t, seed)
    local sc = (1 - (1 - t) ^ 3)
    sc = sc * (1 + 0.35 * math.sin(t * 3.14159) * (1 - t * 0.6))
    local rr = r * sc
    if rr < 0.6 then return end
    local jit = hash01(seed) * 6.28
    for k = 0, 4 do
        local a = jit + k * 1.2566 + math.sin(seed * 3 + k) * 0.12
        nvgBeginPath(vg)
        nvgCircle(vg, x + math.cos(a) * rr * 0.52, y + math.sin(a) * rr * 0.52,
            rr * 0.46 * (0.92 + hash01(seed + k) * 0.16))
        nvgFillColor(vg, rgba(197, 38, 64, 232))
        nvgFill(vg)
    end
    nvgBeginPath(vg)
    nvgCircle(vg, x, y, rr * 0.3)
    nvgFillColor(vg, rgba(140, 18, 40, 240))
    nvgFill(vg)
    if t > 0.72 then
        local fa = (t - 0.72) / 0.28
        for k = 0, 4 do
            local a = jit + k * 1.2566 + 0.6
            nvgBeginPath(vg)
            nvgCircle(vg, x + math.cos(a) * rr * 0.2, y + math.sin(a) * rr * 0.2, rr * 0.07 + 0.7)
            nvgFillColor(vg, rgba(252, 228, 150, 230 * fa))
            nvgFill(vg)
        end
    end
end

function traceDrawOrchid(x, y, t, seed)
    local sc = 1 - (1 - t) ^ 3
    if sc < 0.03 then return end
    for k = 0, 8 do
        local a = -1.5708 + (k / 8 - 0.5) * 2.5 + math.sin(elapsed * 1.6 + seed + k * 1.7) * 0.05 * t
        local ln = (30 + hash01(seed + k * 3) * 42) * sc
        local ex = x + math.cos(a) * ln
        local ey = y + math.sin(a) * ln
        nvgStrokeColor(vg, rgba(64, 94, 60, 235))
        nvgStrokeWidth(vg, 3.6 - (k % 3) * 0.8)
        nvgBeginPath(vg)
        nvgMoveTo(vg, x, y)
        nvgBezierTo(vg, x + math.cos(a) * ln * 0.4, y + math.sin(a) * ln * 0.5 - 5,
            ex - math.cos(a) * ln * 0.08, ey + 3, ex, ey)
        nvgStroke(vg)
    end
    if t > 0.8 then
        local fa = (t - 0.8) / 0.2
        nvgBeginPath(vg)
        nvgCircle(vg, x + 4, y - 40 * sc, 3.2)
        nvgFillColor(vg, rgba(240, 226, 152, 235 * fa))
        nvgFill(vg)
    end
end

function traceDrawMount(z)
    local RT = TRACE_RT
    local v = clamp((RT.vista - 50) / 90, 0, 1)
    v = 1 - (1 - v) ^ 2
    if v <= 0.01 then return end
    local bw = 26 / z * v
    nvgFillColor(vg, rgba(58, 42, 30, 245 * v))
    nvgBeginPath(vg)
    nvgRect(vg, -bw, -bw, worldW + bw * 2, bw)
    nvgRect(vg, -bw, worldH, worldW + bw * 2, bw)
    nvgRect(vg, -bw, 0, bw, worldH)
    nvgRect(vg, worldW, 0, bw, worldH)
    nvgFill(vg)
    nvgStrokeColor(vg, rgba(150, 122, 88, 200 * v))
    nvgStrokeWidth(vg, 2 / z)
    nvgBeginPath(vg)
    nvgRect(vg, 3 / z, 3 / z, worldW - 6 / z, worldH - 6 / z)
    nvgStroke(vg)
    -- 题跋 + 印章(画心右上)
    local k = clamp(worldH / 1400, 0.6, 1.6)
    nvgSave(vg)
    nvgTranslate(vg, worldW - 240 * k, worldH * 0.12)
    nvgScale(vg, k, k)
    for c2 = 0, 2 do
        local cx2 = c2 * 24
        for r2 = 0, 9 - c2 * 2 do
            local seed = c2 * 31 + r2 * 7
            nvgBeginPath(vg)
            nvgRect(vg, cx2 - 6, r2 * 22, 12 * (0.5 + hash01(seed) * 0.6), 3.2)
            nvgFillColor(vg, rgba(74, 70, 64, 130 * v))
            nvgFill(vg)
        end
    end
    -- 拾得题字成行(漏拾的字留空框)
    for i, ch in ipairs(RT.chars) do
        local cy3 = (i - 1) * 58
        if ch.got then
            drawText(-86, cy3 - 4, 46, rgba(56, 50, 44, 235 * v), ch.ch)
        else
            nvgStrokeColor(vg, rgba(120, 112, 102, 90 * v))
            nvgStrokeWidth(vg, 1.6)
            nvgBeginPath(vg)
            nvgRect(vg, -84, cy3, 40, 40)
            nvgStroke(vg)
        end
    end
    local sv = clamp((RT.vista - 150) / 26, 0, 1)
    if sv > 0 then
        local pop = 1 + (1 - sv) * 0.7
        nvgSave(vg)
        nvgTranslate(vg, 12, 270)
        nvgRotate(vg, -0.05)
        nvgScale(vg, pop, pop)
        nvgBeginPath(vg)
        nvgRect(vg, -25, -25, 50, 50)
        nvgFillColor(vg, rgba(186, 48, 40, 235 * sv))
        nvgFill(vg)
        nvgFillColor(vg, rgba(242, 236, 224, 230 * sv))
        for gx2 = 0, 1 do
            for gy2 = 0, 1 do
                nvgBeginPath(vg)
                nvgRect(vg, -18 + gx2 * 21, -18 + gy2 * 21, 14, 14)
                nvgFill(vg)
            end
        end
        nvgRestore(vg)
    end
    local sv2 = clamp((RT.vista - 185) / 26, 0, 1)
    if sv2 > 0 then
        local pop = 1 + (1 - sv2) * 0.7
        nvgSave(vg)
        nvgTranslate(vg, -42, 352)
        nvgScale(vg, pop, pop)
        nvgStrokeColor(vg, rgba(186, 48, 40, 230 * sv2))
        nvgStrokeWidth(vg, 3.4)
        nvgBeginPath(vg)
        nvgRect(vg, -14, -44, 28, 88)
        nvgStroke(vg)
        nvgFillColor(vg, rgba(186, 48, 40, 215 * sv2))
        for r2 = 0, 3 do
            nvgBeginPath(vg)
            nvgRect(vg, -7, -35 + r2 * 20, 14, 9)
            nvgFill(vg)
        end
        nvgRestore(vg)
    end
    nvgRestore(vg)
end

function drawTraceWorld()
    local RT = TRACE_RT
    if RT.bamboo then
        drawBambooScroll()
        return
    end
    local def = RT.def
    if not def then return end
    nvgSave(vg)
    nvgTranslate(vg, cameraX, cameraY)   -- 抵消外层相机
    local z = RT.zoom or 1
    local cx = RT.camCx or (cameraX + DESIGN_W / 2)
    local cy = RT.camCy or (cameraY + DESIGN_H / 2)
    if RT.goalDone then
        local fitz = math.min(DESIGN_W / (worldW + 80), DESIGN_H / (worldH + 80)) * 0.96
        local tt = math.min(RT.vista / 170, 1)
        tt = 1 - (1 - tt) ^ 3
        z = z + (fitz - z) * tt
        cx = cx + (worldW / 2 - cx) * tt
        cy = cy + (worldH / 2 - cy) * tt
    end
    nvgTranslate(vg, DESIGN_W / 2, DESIGN_H / 2)
    nvgScale(vg, z, z)
    nvgTranslate(vg, -cx, -cy)
    local halfW = DESIGN_W / (2 * z) + 80
    local halfH = DESIGN_H / (2 * z) + 80
    -- 底色
    nvgBeginPath(vg)
    nvgRect(vg, cx - halfW, cy - halfH, halfW * 2, halfH * 2)
    nvgFillColor(vg, rgba(def.base[1], def.base[2], def.base[3], 255))
    nvgFill(vg)
    -- 分层视差
    for _, lay in ipairs(def.layers) do
        if lay.hidden ~= 1 then
            local tox = (cx - def.refx) * (1 - lay.par)
            local toy = (cy - def.refy) * (1 - lay.par) * 0.5
            nvgSave(vg)
            nvgTranslate(vg, tox, toy)
            nvgFillColor(vg, rgba(lay.color[1], lay.color[2], lay.color[3], 255))
            local vx1, vx2 = cx - halfW - tox, cx + halfW - tox
            local vy1, vy2 = cy - halfH - toy, cy + halfH - toy
            for pi, fp in ipairs(lay.polys) do
                local bb = lay.bb[pi]
                if bb[3] > vx1 and bb[1] < vx2 and bb[4] > vy1 and bb[2] < vy2 then
                    nvgBeginPath(vg)
                    nvgMoveTo(vg, fp[1], fp[2])
                    for k = 3, #fp - 1, 2 do nvgLineTo(vg, fp[k], fp[k + 1]) end
                    nvgClosePath(vg)
                    if lay.par >= 0.99 then
                        nvgStrokeColor(vg, rgba(lay.color[1], lay.color[2], lay.color[3], 42))
                        nvgStrokeWidth(vg, 9)
                        nvgStroke(vg)
                    end
                    nvgFill(vg)
                end
            end
            nvgRestore(vg)
        end
    end
    -- 鬼阶虚影:未实体化时罩宣纸色淡化 + 呼吸墨边;余时将尽时闪烁警示
    for _, grp in ipairs(RT.ghostGrps) do
        local wash
        if grp.timer <= 0 then
            wash = 205
        elseif grp.timer < 80 then
            wash = (math.floor(grp.timer / 7) % 2 == 0) and 150 or 0
        else
            wash = 0
        end
        for _, poly in ipairs(grp.polys) do
            nvgBeginPath(vg)
            nvgMoveTo(vg, poly[1][1], poly[1][2])
            for k = 2, #poly do nvgLineTo(vg, poly[k][1], poly[k][2]) end
            nvgClosePath(vg)
            if wash > 0 then
                nvgFillColor(vg, rgba(def.base[1], def.base[2], def.base[3], wash))
                nvgFill(vg)
            end
            if grp.timer <= 0 then
                nvgStrokeColor(vg, rgba(64, 60, 56, 92 + 36 * math.sin(elapsed * 2.6 + poly[1][1] * 0.01)))
                nvgStrokeWidth(vg, 2.2)
                nvgStroke(vg)
            else
                -- 墨衣:实体期描边浓度=剩余时间,台上读秒
                local f = grp.timer / 300
                nvgStrokeColor(vg, rgba(22, 20, 18, 60 + 150 * f))
                nvgStrokeWidth(vg, 2 + 4 * f)
                nvgStroke(vg)
            end
        end
    end
    -- 墨池涟漪
    for _, rp in ipairs(RT.ripples) do
        local t = rp.t / 55
        local a = (1 - t) * 150 * math.min(rp.big, 1)
        for k = 0, 1 do
            local rr = (10 + t * 56) * rp.big * (1 - k * 0.4)
            nvgStrokeColor(vg, rgba(38, 36, 33, a * (1 - k * 0.35)))
            nvgStrokeWidth(vg, 2.6 - k)
            nvgBeginPath(vg)
            nvgEllipse(vg, rp.x, rp.y, rr, rr * 0.32)
            nvgStroke(vg)
        end
    end
    -- 苔点(逃生路暗示:斜点上行,水墨皴法里的苔)
    if RT.design and RT.design.hints then
        for hi, hp in ipairs(RT.design.hints) do
            local wob = math.sin(elapsed * 1.4 + hi * 2.1) * 1.5
            nvgSave(vg)
            nvgTranslate(vg, hp.x, hp.y + wob)
            nvgRotate(vg, -0.5)
            nvgBeginPath(vg)
            nvgEllipse(vg, 0, 0, 7.5, 3)
            nvgFillColor(vg, rgba(52, 60, 48, 170))
            nvgFill(vg)
            nvgRestore(vg)
        end
    end
    -- 拾字
    for _, ch in ipairs(RT.chars) do
        if not ch.got then
            local bob = math.sin(elapsed * 2 + ch.x * 0.013) * 5
            nvgStrokeColor(vg, rgba(170, 138, 60, 70 + 30 * math.sin(elapsed * 2.4 + ch.x)))
            nvgStrokeWidth(vg, 2)
            nvgBeginPath(vg)
            nvgCircle(vg, ch.x, ch.y + bob, 30)
            nvgStroke(vg)
            drawText(ch.x - 17, ch.y + bob - 19, 34, rgba(50, 46, 42, 230), ch.ch)
        elseif ch.fade < 1 then
            drawText(ch.x - 17, ch.y - 19 - ch.fade * 46, 34,
                rgba(150, 120, 52, 220 * (1 - ch.fade)), ch.ch)
        end
    end
    -- 交互点 / 花
    for _, ip in ipairs(RT.ipoints) do
        if ip.kind == "gust" then
            traceDrawGust(ip)
        elseif ip.kind == "key" then
            traceDrawKeyBud(ip)
        elseif not ip.trig then
            local ph = elapsed * 2.2 + ip.x * 0.01
            nvgStrokeColor(vg, rgba(70, 66, 62, 56 + 26 * math.sin(ph)))
            nvgStrokeWidth(vg, 2.4)
            nvgBeginPath(vg)
            nvgCircle(vg, ip.x, ip.y, 26 + math.sin(ph) * 4)
            nvgStroke(vg)
            for _, m in ipairs(ip.members) do
                nvgBeginPath(vg)
                nvgCircle(vg, m.x, m.y, ip.kind == "plum" and 4.2 or 3.4)
                nvgFillColor(vg, ip.kind == "plum" and rgba(132, 22, 44, 235) or rgba(60, 88, 56, 235))
                nvgFill(vg)
            end
        else
            if ip.ring and ip.ring < 50 then
                local t = ip.ring / 50
                nvgStrokeColor(vg, rgba(60, 56, 52, 200 * (1 - t)))
                nvgStrokeWidth(vg, 3.5 * (1 - t) + 0.6)
                nvgBeginPath(vg)
                nvgCircle(vg, ip.x, ip.y, 16 + t * 70)
                nvgStroke(vg)
            end
            for mi, m in ipairs(ip.members) do
                if ip.kind == "plum" then
                    if m.t > 0 then
                        traceDrawPlumFlower(m.x, m.y, m.r, m.t, mi * 13.7 + ip.x)
                    else
                        nvgBeginPath(vg)
                        nvgCircle(vg, m.x, m.y, 4.2)
                        nvgFillColor(vg, rgba(132, 22, 44, 235))
                        nvgFill(vg)
                    end
                elseif ip.kind == "sprout" then
                    traceDrawOrchid(m.x, m.y, m.t, ip.x * 0.013)
                elseif ip.kind == "orchid" then
                    -- 描摹兰叶生长:用缩放重绘该层多边形
                    if m.lay and m.t > 0.01 then
                        local sc = 1 - (1 - m.t) ^ 3
                        local bb = m.lay.bb[m.pi]
                        local bx, by = (bb[1] + bb[3]) * 0.5, bb[4]
                        nvgSave(vg)
                        nvgTranslate(vg, bx, by)
                        nvgRotate(vg, math.sin(elapsed * 1.5 + bx * 0.013) * 0.06 * m.t)
                        nvgScale(vg, sc, sc)
                        nvgTranslate(vg, -bx, -by)
                        local fp = m.lay.polys[m.pi]
                        nvgBeginPath(vg)
                        nvgMoveTo(vg, fp[1], fp[2])
                        for k = 3, #fp - 1, 2 do nvgLineTo(vg, fp[k], fp[k + 1]) end
                        nvgClosePath(vg)
                        nvgFillColor(vg, rgba(m.lay.color[1], m.lay.color[2], m.lay.color[3], 255))
                        nvgFill(vg)
                        nvgRestore(vg)
                    end
                end
            end
        end
    end
    -- 花瓣
    for _, pt in ipairs(RT.petals) do
        local a = 230 * (1 - pt.age / pt.life)
        local pc = pt.col or TRACE_PETAL_RED
        nvgSave(vg)
        nvgTranslate(vg, pt.x, pt.y)
        nvgRotate(vg, pt.rot)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, 0, 5.2, 2.8)
        nvgFillColor(vg, rgba(pc[1], pc[2], pc[3], a))
        nvgFill(vg)
        nvgRestore(vg)
    end
    -- 终点门(梅苞未集满时灰锁,苞计点亮进度)
    local g = def.conf.goal
    local locked = RT.plumTotal > 0 and RT.plumDone < RT.plumTotal
    -- 玩家靠近锁定门:苞计脉动放大 + 灰涟漪,提示去寻梅
    local nearLock = 0
    if locked then
        local ddx, ddy = player.x - g[1], player.y - g[2]
        if ddx * ddx + ddy * ddy < 230 * 230 then
            RT.gatePulse = (RT.gatePulse or 0) + 1
            nearLock = 1
            local t = (RT.gatePulse % 70) / 70
            nvgStrokeColor(vg, rgba(110, 104, 96, 130 * (1 - t)))
            nvgStrokeWidth(vg, 2.6 * (1 - t) + 0.5)
            nvgBeginPath(vg)
            nvgCircle(vg, g[1], g[2] - 40, 40 + t * 90)
            nvgStroke(vg)
        else
            RT.gatePulse = 0
        end
    end
    if locked then
        nvgStrokeColor(vg, rgba(122, 116, 108, 165))
    else
        nvgStrokeColor(vg, rgba(150, 60, 50, 190 + 40 * math.sin(elapsed * 3)))
    end
    nvgStrokeWidth(vg, 5)
    nvgBeginPath(vg)
    nvgArc(vg, g[1], g[2] - 50, 80, math.pi, 0, NVG_CW)
    nvgStroke(vg)
    if RT.plumTotal > 0 then
        for i = 1, RT.plumTotal do
            local pulse = (nearLock == 1 and i > RT.plumDone)
                and (1 + 0.45 * math.sin(elapsed * 5 + i * 1.4)) or 1
            local bx = g[1] + (i - (RT.plumTotal + 1) * 0.5) * 30
            local by = g[2] - 150
            nvgBeginPath(vg)
            nvgCircle(vg, bx, by, 7 * pulse)
            if i <= RT.plumDone then
                nvgFillColor(vg, rgba(197, 38, 64, 235))
                nvgFill(vg)
            else
                nvgStrokeColor(vg, rgba(120, 112, 104, 200))
                nvgStrokeWidth(vg, 2.2)
                nvgStroke(vg)
            end
        end
    end
    nvgStrokeColor(vg, rgba(90, 84, 78, 235))
    nvgStrokeWidth(vg, 4.5)
    nvgBeginPath(vg)
    nvgCircle(vg, g[1], g[2] - 24, 33)
    nvgStroke(vg)
    nvgBeginPath(vg)
    nvgMoveTo(vg, g[1] - 22, g[2] - 13)
    nvgBezierTo(vg, g[1] - 3, g[2] - 37, g[1] + 9, g[2] - 23, g[1] + 24, g[2] - 37)
    nvgStroke(vg)
    -- 存档灯
    for i, cp in ipairs(RT.cps) do
        nvgStrokeColor(vg, rgba(40, 36, 33, 235))
        nvgStrokeWidth(vg, 5)
        nvgBeginPath(vg)
        nvgMoveTo(vg, cp[1], cp[2] + 12)
        nvgLineTo(vg, cp[1], cp[2] - 52)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgCircle(vg, cp[1] + 16, cp[2] - 46, RT.cpReached[i] and 7 or 5)
        nvgFillColor(vg, RT.cpReached[i] and rgba(235, 180, 90, 230) or rgba(160, 152, 140, 180))
        nvgFill(vg)
    end
    -- 拖尾与角色(原生)
    drawParticles()
    drawPlayer()
    -- 终幕装裱
    if RT.goalDone then traceDrawMount(z) end
    nvgRestore(vg)
end
