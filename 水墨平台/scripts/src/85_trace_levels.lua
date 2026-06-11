-- 描摹关运行时(第 18+ 关):多边形碰撞 + 分层视差 + 触碰开花 + 画卷终幕
-- 注意:本文件不得新增 chunk 顶级 local(bundle 已 199/200),全部用全局。

TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0, def = nil,
    goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0 }

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
        if (not bb) or (x >= bb[1] - 4 and x <= bb[3] + 4) then
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
    local def = TRACE_DEFS[currentLevel.traceKey]
    TRACE_RT = { polys = {}, ipoints = {}, petals = {}, vista = 0, def = def,
        goalDone = false, cpReached = {}, spawnX = 0, spawnY = 0, gx = 0, gy = 0 }
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
    -- 自动补点(顶面)
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
    TRACE_RT.zoom = ({ zhumei = 0.75, forest = 0.92, water = 0.92 })[currentLevel.traceKey] or 1.0
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
    RT.camCy = (RT.camCy or ty) + (ty - (RT.camCy or ty)) * 0.06
    if worldW <= halfW * 2 then RT.camCx = worldW / 2
    else RT.camCx = clamp(RT.camCx, halfW, worldW - halfW) end
    if worldH <= halfH * 2 then RT.camCy = worldH / 2
    else RT.camCy = clamp(RT.camCy, halfH, worldH - halfH) end
    cameraX = RT.camCx - DESIGN_W / 2
    cameraY = RT.camCy - DESIGN_H / 2
end

function traceCollideOnce()
    local pr = player.radius
    local px, py = player.x, player.y
    local hitG, wallSide = false, 0
    for _, poly in ipairs(TRACE_RT.polys) do
        local bb = poly.bb
        if not (bb and (px + pr < bb[1] or px - pr > bb[3] or py + pr < bb[2] or py - pr > bb[4])) then
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
    -- 跌落回档
    if player.y > RT.def.conf.kill then
        player.x, player.y = RT.spawnX, RT.spawnY - 24
        player.vx, player.vy = 0, 0
        player.isDashing = false
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
    -- 终点
    local g = RT.def.conf.goal
    local dgx, dgy = player.x - g[1], player.y - g[2]
    if dgx * dgx + dgy * dgy < 95 * 95 then
        RT.goalDone = true
        RT.vista = 0
        RT.gx, RT.gy = player.x, player.y
    end
    -- 交互点:触碰开花
    for _, ip in ipairs(RT.ipoints) do
        if not ip.trig then
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
    -- 交互点 / 花
    for _, ip in ipairs(RT.ipoints) do
        if not ip.trig then
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
        nvgSave(vg)
        nvgTranslate(vg, pt.x, pt.y)
        nvgRotate(vg, pt.rot)
        nvgBeginPath(vg)
        nvgEllipse(vg, 0, 0, 5.2, 2.8)
        nvgFillColor(vg, rgba(198, 46, 66, a))
        nvgFill(vg)
        nvgRestore(vg)
    end
    -- 终点门
    local g = def.conf.goal
    nvgStrokeColor(vg, rgba(150, 60, 50, 190))
    nvgStrokeWidth(vg, 5)
    nvgBeginPath(vg)
    nvgArc(vg, g[1], g[2] - 50, 80, math.pi, 0, NVG_CW)
    nvgStroke(vg)
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
