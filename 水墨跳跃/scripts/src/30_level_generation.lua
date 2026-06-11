-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.

local function resetBranchMetadata()
    branchMetadata = {
        main = { parentBranchId = nil, parentT = 0, bend = 0, targetBend = 0, springVel = 0, mass = 120, k = 0.24, damping = 0.82, maxBend = 85, deflectionCoeff = 0.0018, bounceFactor = 0.018, springBackForce = 1.7 },
        main2 = { parentBranchId = "main", parentT = 0.69, bend = 0, targetBend = 0, springVel = 0, mass = 78, k = 0.28, damping = 0.79, maxBend = 105, deflectionCoeff = 0.0035, bounceFactor = 0.045, springBackForce = 2.4 },
        side1 = { parentBranchId = "main", parentT = 0.72, bend = 0, targetBend = 0, springVel = 0, mass = 70, k = 0.31, damping = 0.77, maxBend = 120, deflectionCoeff = 0.0042, bounceFactor = 0.075, springBackForce = 3.0 },
        vertical = { parentBranchId = "main2", parentT = 1.0, bend = 0, targetBend = 0, springVel = 0, mass = 48, k = 0.34, damping = 0.73, maxBend = 150, deflectionCoeff = 0.007, bounceFactor = 0.145, springBackForce = 4.1 },
        bridge = { parentBranchId = "main2", parentT = 1.0, bend = 0, targetBend = 0, springVel = 0, mass = 58, k = 0.31, damping = 0.76, maxBend = 135, deflectionCoeff = 0.0048, bounceFactor = 0.105, springBackForce = 3.4 },
        high1 = { parentBranchId = "vertical", parentT = 1.0, bend = 0, targetBend = 0, springVel = 0, mass = 34, k = 0.38, damping = 0.70, maxBend = 170, deflectionCoeff = 0.010, bounceFactor = 0.20, springBackForce = 4.8 },
        peak = { parentBranchId = "bridge", parentT = 0.85, bend = 0, targetBend = 0, springVel = 0, mass = 30, k = 0.40, damping = 0.68, maxBend = 185, deflectionCoeff = 0.012, bounceFactor = 0.26, springBackForce = 5.3 },
    }
end

local mapleBranchOrder = { "main", "main2", "side1", "vertical", "bridge", "high1", "peak" }
local mapleReverseBranchOrder = { "peak", "high1", "bridge", "vertical", "side1", "main2", "main" }

function refreshBranchNormalsForCurrentPose(list)
    if not list or #list < 2 then return end
    for i = 1, #list do
        local a = list[math.max(1, i - 1)]
        local b = list[math.min(#list, i + 1)]
        if i == 1 then a, b = list[1], list[2] end
        if i == #list then a, b = list[#list - 1], list[#list] end
        local dx, dy = b.x - a.x, b.y - a.y
        local len = dist2(dx, dy)
        if len < 0.001 then len = 1 end
        local nx, ny = -dy / len, dx / len
        if ny > 0 then nx, ny = -nx, -ny end
        list[i].normX, list[i].normY = nx, ny
    end
end

function bindItemToBranch(item)
    if not item or not item.branchId or not item.nodeIndex then return end
    local nodes = branchGroups[item.branchId]
    local n = nodes and nodes[item.nodeIndex]
    if not n then return end
    local off = item.attachOffset or (n.r + 32)
    item.x = n.x + n.normX * off
    item.y = n.y + n.normY * off
    item.attachX, item.attachY = n.x, n.y
    item.normX, item.normY = n.normX, n.normY
end

function branchFacingAngle(item)
    local nx = (item and item.normX) or 0
    local ny = (item and item.normY) or -1
    return math.atan2(ny, nx) + math.pi * 0.5 + ((item and item.orientationJitter) or 0)
end

local function applyStaticBranchBend()
    if currentLevel.id ~= "maple" then return end

    for _, bid in ipairs(mapleReverseBranchOrder) do
        local meta = branchMetadata[bid]
        if meta and meta.parentBranchId and branchMetadata[meta.parentBranchId] then
            local parent = branchMetadata[meta.parentBranchId]
            parent.targetBend = math.min(parent.maxBend, parent.targetBend + meta.targetBend * 0.22)
        end
    end

    for _, bid in ipairs(mapleBranchOrder) do
        local meta = branchMetadata[bid]
        if branchGroups[bid] then
            local force = -meta.k * (meta.bend - meta.targetBend)
            local acc = force / meta.mass
            meta.springVel = (meta.springVel + acc) * meta.damping
            meta.bend = meta.bend + meta.springVel
            meta.targetBend = meta.targetBend * 0.90
        end
    end

    for _, bid in ipairs(mapleBranchOrder) do
        local meta = branchMetadata[bid]
        local nodes = branchGroups[bid]
        if meta and nodes and #nodes > 0 then
            local root = nodes[1]
            local inheritX, inheritY = 0, 0
            if meta.parentBranchId then
                local parentNodes = branchGroups[meta.parentBranchId]
                if parentNodes and #parentNodes > 0 then
                    local idx = clamp(math.floor(#parentNodes * meta.parentT), 1, #parentNodes)
                    local parentNode = parentNodes[idx]
                    inheritX = parentNode.x - root.baseX
                    inheritY = parentNode.y - root.baseY
                end
            end
            for _, n in ipairs(branchGroups[bid]) do
                local drop = meta.bend * n.t * n.t * 0.92
                n.x = n.baseX + inheritX
                n.y = n.baseY + inheritY + drop
            end
        end
    end

    for _, bid in ipairs(mapleBranchOrder) do
        refreshBranchNormalsForCurrentPose(branchGroups[bid])
    end

    for _, t in ipairs(targets) do
        bindItemToBranch(t)
    end
    for _, b in ipairs(blooms) do
        bindItemToBranch(b)
    end
end

local function generateBamboo()
    local function createBambooStalk(startX, startY, angle, length, radius, segmentsCount, stalkId)
        local currentX, currentY = startX, startY
        local segLen = length / segmentsCount
        for i = 0, segmentsCount - 1 do
            local bendDir = angle > -math.pi / 2 and 1 or -1
            local curAngle = angle + (i * 0.015 * bendDir)
            local nextX = currentX + math.cos(curAngle) * segLen
            local nextY = currentY + math.sin(curAngle) * segLen
            local currentR = radius * (1 - (i / segmentsCount) * 0.5)
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

    createBambooStalk(W(0.15), H(1.1), -math.pi * 0.48, H(0.8), 18, 12, "bamboo1")
    createBambooStalk(W(0.35), H(0.9), -math.pi * 0.35, H(0.7), 14, 10, "bamboo2")
    -- bamboo3/4 基部下移：原 H(0.25)/H(0.3) 时顶部目标位于世界顶以上(y<0)，
    -- 相机上界钳在 0，玩家永远看不到；下移后所有竹节目标均在镜头内
    createBambooStalk(W(0.72), H(0.50), -math.pi * 0.55, H(0.5), 12, 8, "bamboo3")
    createBambooStalk(W(0.78), H(0.55), -math.pi * 0.4, H(0.4), 8, 6, "bamboo4")

    local placements = {
        { id = "bamboo1", nodes = { 4, 8, 11 } },
        { id = "bamboo2", nodes = { 5, 9 } },
        { id = "bamboo3", nodes = { 3, 7 } },
        { id = "bamboo4", nodes = { 4 } },
    }
    for _, p in ipairs(placements) do
        local segs = {}
        for _, s in ipairs(bambooSegments) do if s.stalkId == p.id then segs[#segs + 1] = s end end
        for _, idx0 in ipairs(p.nodes) do
            local s = segs[idx0 + 1]
            if s then addTarget(s.nodeX, s.nodeY, s.r + 18, s.x1, s.y1, 0, -1) end
        end
    end
end

local function generatePine()
    createBranch(W(0.10), H(0.75), W(0.35), H(0.65), 38, 25, 80, -60, 100, "pine1", 0.15)
    createBranch(W(0.35), H(0.65), W(0.22), H(0.48), 25, 15, -80, -80, 80, "pine_return", 0.15)
    createBranch(W(0.35), H(0.65), W(0.65), H(0.58), 25, 18, 100, 80, 120, "pine2", 0.15)
    createBranch(W(0.65), H(0.58), W(0.50), H(0.32), 18, 10, -90, -100, 110, "pine_bridge", 0.15)
    createBranch(W(0.65), H(0.58), W(0.92), H(0.40), 18, 8, 120, -80, 120, "pine_peak", 0.15)
    streams[#streams + 1] = { x1 = W(0.30), y1 = H(0.20), x2 = W(0.50), y2 = H(0.80), width = 85 }
    for _, p in ipairs({
        { "pine1", 0.28 }, { "pine1", 0.45 }, { "pine1", 0.62 },
        { "pine_return", 0.35 }, { "pine_return", 0.70 },
        { "pine2", 0.22 }, { "pine2", 0.40 }, { "pine2", 0.58 }, { "pine2", 0.78 },
        { "pine_bridge", 0.32 }, { "pine_bridge", 0.66 },
        { "pine_peak", 0.25 }, { "pine_peak", 0.52 }, { "pine_peak", 0.85 },
    }) do addTargetOnBranch(p[1], p[2], 42) end
end

local function addMapleTarget(branchId, progress)
    local nodes = branchGroups[branchId]
    if not nodes then return end
    local idx = clamp(math.floor(#nodes * progress), 1, #nodes)
    local n = nodes[idx]
    local off = n.r + 32
    targets[#targets + 1] = {
        x = n.x + n.normX * off, y = n.y + n.normY * off, r = 36,
        attachX = n.x, attachY = n.y, normX = n.normX, normY = n.normY,
        dead = false, pulse = hash01(#targets + 17) * 6.28318,
        branchId = branchId, nodeIndex = idx, attachOffset = off,
        orientationJitter = (hash01(n.x * 0.017 + n.y * 0.013) - 0.5) * 0.38,
    }
end

local function generateMaple()
    resetBranchMetadata()
    createBranch(W(0.05), H(0.82), W(0.22), H(0.70), 45, 30, 50, -100, 150, "main", 0.12)
    createBranch(W(0.20), H(0.72), W(0.44), H(0.76), 26, 16, 100, 110, 110, "side1", 0.12)
    createBranch(W(0.21), H(0.69), W(0.4), H(0.48), 28, 20, -120, -100, 180, "main2", 0.12)
    createBranch(W(0.4), H(0.48), W(0.42), H(0.22), 20, 10, -150, -50, 150, "vertical", 0.12)
    createBranch(W(0.42), H(0.22), W(0.62), H(0.28), 12, 6, 100, -100, 120, "high1", 0.12)
    createBranch(W(0.42), H(0.48), W(0.72), H(0.5), 18, 12, 150, 150, 180, "bridge", 0.12)
    createBranch(W(0.68), H(0.51), W(0.96), H(0.18), 12, 4, 200, -180, 220, "peak", 0.12)
    for _, p in ipairs({
        { "main", 0.45 }, { "side1", 0.65 }, { "main2", 0.6 }, { "high1", 0.25 },
        { "high1", 0.75 }, { "bridge", 0.3 }, { "bridge", 0.75 },
        { "peak", 0.45 }, { "peak", 0.88 },
    }) do addMapleTarget(p[1], p[2]) end
    for i = 1, 18 do
        glidingLeaves[#glidingLeaves + 1] = {
            x = hash01(i * 15) * worldW,
            y = hash01(i * 25) * worldH * 0.5,
            size = 20 + hash01(i * 35) * 18,
            speed = 1.2 + hash01(i * 45) * 1.8,
            bob = hash01(i * 55) * 6.28,
        }
    end
    for i = 1, 9 do
        local row = (i - 1) % 3
        local col = math.floor((i - 1) / 3)
        glidingLeaves[#glidingLeaves + 1] = {
            x = W(0.34 + row * 0.13 + hash01(300 + i * 7) * 0.045),
            y = H(0.64 + col * 0.10 + hash01(330 + i * 11) * 0.030),
            size = 25 + hash01(360 + i * 13) * 8,
            speed = 0.36 + hash01(390 + i * 17) * 0.28,
            bob = hash01(420 + i * 19) * 6.28,
            platform = true,
        }
    end
end

local function generatePlum()
    createBranch(W(0.95), H(0.58), W(0.55), H(0.68), 42, 28, -100, 70, 120, "main_trunk", 0.12)
    createBranch(W(0.55), H(0.68), W(0.35), H(0.78), 28, 16, -80, 50, 100, "hanging_branch", 0.12)
    createBranch(W(0.55), H(0.68), W(0.25), H(0.52), 26, 12, -120, -100, 120, "left_crescent", 0.12)
    createBranch(W(0.62), H(0.62), W(0.42), H(0.22), 14, 6, -40, -120, 140, "upright_young_shoot", 0.12)
    createBranch(W(0.18), H(0.28), W(0.18), H(0.62), 4, 4, 0, 0, 40, "poetry_col_1", 0)
    createBranch(W(0.14), H(0.28), W(0.14), H(0.62), 4, 4, 0, 0, 40, "poetry_col_2", 0)
    createBranch(W(0.10), H(0.28), W(0.10), H(0.62), 4, 4, 0, 0, 40, "poetry_col_3", 0)
    createBranch(W(0.06), H(0.28), W(0.06), H(0.62), 4, 4, 0, 0, 40, "poetry_col_4", 0)
    for _, p in ipairs({
        { "main_trunk", 0.5 }, { "hanging_branch", 0.4 }, { "hanging_branch", 0.9 },
        { "upright_young_shoot", 0.45 }, { "upright_young_shoot", 0.95 },
        { "left_crescent", 0.4 }, { "left_crescent", 0.85 }, { "poetry_col_1", 0.6 },
    }) do addTargetOnBranch(p[1], p[2], 36) end
end

function generatePlumMirror()
    if LDTK_PLUM_MIRROR then
        for _, b in ipairs(LDTK_PLUM_MIRROR.branches or {}) do
            createBranch(b.x1, b.y1, b.x2, b.y2, b.startR, b.endR, b.curveX, b.curveY, b.pointsNum, b.id, b.jitter)
        end
        for _, t in ipairs(LDTK_PLUM_MIRROR.targets or {}) do
            addTargetOnBranch(t.branchId, t.progress, t.radius)
        end
        return
    end

    -- 第12关：蟠梅长卷的镜像版，从左往右行动
    -- 性能优化：减少 pointsNum（节点数减半），大幅降低每帧绘制量
    -- 原 plum 用 120/100/120/140 节点，这里减半以保持流畅
    createBranch(W(0.05), H(0.60), W(0.42), H(0.66), 46, 32, 80, 50, 60, "main_trunk", 0.10)
    createBranch(W(0.42), H(0.66), W(0.62), H(0.74), 32, 20, 60, 30, 50, "hanging_branch", 0.10)
    createBranch(W(0.42), H(0.66), W(0.72), H(0.50), 30, 16, 100, -80, 60, "right_crescent", 0.10)
    createBranch(W(0.35), H(0.60), W(0.56), H(0.24), 18, 8, 30, -100, 70, "upright_young_shoot", 0.10)
    createBranch(W(0.82), H(0.28), W(0.82), H(0.62), 4, 4, 0, 0, 20, "poetry_col_1", 0)
    createBranch(W(0.86), H(0.28), W(0.86), H(0.62), 4, 4, 0, 0, 20, "poetry_col_2", 0)
    createBranch(W(0.90), H(0.28), W(0.90), H(0.62), 4, 4, 0, 0, 20, "poetry_col_3", 0)
    createBranch(W(0.94), H(0.28), W(0.94), H(0.62), 4, 4, 0, 0, 20, "poetry_col_4", 0)
    for _, p in ipairs({
        { "main_trunk", 0.5 }, { "hanging_branch", 0.4 }, { "hanging_branch", 0.9 },
        { "upright_young_shoot", 0.4 }, { "upright_young_shoot", 0.9 },
        { "right_crescent", 0.35 }, { "right_crescent", 0.8 }, { "poetry_col_1", 0.6 },
    }) do addTargetOnBranch(p[1], p[2], 38) end
end

function generatePlumFinale()
    -- 第13关：母本复刻 - 王冕《梅竹双清卷》梅段（台北故宫，22.4x81.4cm 中画芯约 25.6x22.4cm）
    -- 坐标自 assets/reference/wang_mian_twin_purities_plum.jpg (1045x900) 网格描取，
    -- 所有枝干走向与母本一致：
    --   主枝自左缘横出，斜度逐渐加大，化作"长鞭梢"一笔拖至右下角收笔；
    --   上层弧枝与主枝同根，先扬后抑，繁花尽缀此枝（圈花白描）；
    --   交搭小枝自主枝中段挑向右上，与上弧枝成女字穿插；
    --   左下垂梢带花穗回锋；两条垂花小枝自上弧枝下挂；
    --   两条短仰枝挑出顶缘；右壁题诗满纸（化作三柱可攀字柱）。

    -- 主枝（粗入细出，长鞭拖尾）
    createBranchPath({
        { 0.000, 0.150, 24 }, { 0.060, 0.163, 23 }, { 0.130, 0.190, 21 },
        { 0.200, 0.232, 19 }, { 0.270, 0.272, 18 }, { 0.340, 0.314, 16 },
        { 0.405, 0.352, 14 }, { 0.465, 0.412, 12 }, { 0.525, 0.480, 10 },
        { 0.585, 0.555, 8 },  { 0.645, 0.652, 7 },  { 0.710, 0.748, 6 },
        { 0.780, 0.840, 5 },  { 0.850, 0.905, 4 },  { 0.920, 0.952, 3 },
        { 0.978, 0.974, 2.5 },
    }, "finale_trunk", 0.10)

    -- 上层弧枝（满花主枝，先扬后抑，末端发丝细、微微回挑）
    createBranchPath({
        { 0.012, 0.132, 12 }, { 0.060, 0.104, 11 }, { 0.120, 0.082, 10 },
        { 0.190, 0.071, 9 },  { 0.258, 0.082, 8 },  { 0.320, 0.104, 7 },
        { 0.380, 0.134, 5.5 }, { 0.440, 0.158, 4 }, { 0.498, 0.171, 3 },
        { 0.545, 0.163, 2.5 },
    }, "finale_upper", 0.10)

    -- 交搭小枝（自主枝挑向右上，与上弧枝成女字穿插）
    createBranchPath({
        { 0.300, 0.290, 5 }, { 0.345, 0.257, 4 }, { 0.385, 0.234, 3 }, { 0.418, 0.221, 2.5 },
    }, "finale_cross", 0.12)

    -- 中部细长挑枝及其下叉（自主枝沿势向右）
    createBranchPath({
        { 0.400, 0.345, 5 }, { 0.450, 0.352, 4 }, { 0.495, 0.366, 3 },
        { 0.540, 0.381, 2.5 }, { 0.578, 0.394, 2.5 },
    }, "finale_spray", 0.12)
    createBranchPath({
        { 0.432, 0.387, 4 }, { 0.470, 0.407, 3 }, { 0.506, 0.424, 2.5 },
    }, "finale_spray_fork", 0.12)

    -- 左下垂梢（带花穗，回锋收笔）
    createBranchPath({
        { 0.130, 0.205, 7 }, { 0.110, 0.264, 6 }, { 0.094, 0.330, 5 },
        { 0.085, 0.394, 4 }, { 0.082, 0.452, 3 }, { 0.091, 0.503, 2.5 },
    }, "finale_droop", 0.12)
    createBranchPath({
        { 0.075, 0.172, 5 }, { 0.048, 0.200, 4 }, { 0.026, 0.218, 3 },
    }, "finale_droop2", 0.12)

    -- 顶部短仰枝两条
    createBranchPath({
        { 0.128, 0.086, 4 }, { 0.140, 0.048, 3 }, { 0.149, 0.022, 2.5 },
    }, "finale_spur1", 0.12)
    createBranchPath({
        { 0.262, 0.078, 4 }, { 0.276, 0.040, 3 }, { 0.286, 0.017, 2.5 },
    }, "finale_spur2", 0.12)

    -- 上弧枝下挂的垂花小枝两条
    createBranchPath({
        { 0.330, 0.096, 3 }, { 0.318, 0.140, 2.5 }, { 0.309, 0.176, 2.5 },
    }, "finale_hang1", 0.12)
    createBranchPath({
        { 0.405, 0.140, 3 }, { 0.420, 0.184, 2.5 }, { 0.433, 0.219, 2.5 },
    }, "finale_hang2", 0.12)

    -- 尾段最后花枝（主枝中后段，末花所在）
    createBranchPath({
        { 0.473, 0.424, 4 }, { 0.508, 0.453, 3 }, { 0.544, 0.488, 2.5 }, { 0.572, 0.518, 2.5 },
    }, "finale_tail_twig", 0.12)

    -- 右壁题诗（母本右缘满纸行书，化作三柱可攀字柱）
    createBranchPath({ { 0.806, 0.100, 4 }, { 0.806, 0.780, 4 } }, "poetry_col_1", 0)
    createBranchPath({ { 0.866, 0.080, 4 }, { 0.866, 0.780, 4 } }, "poetry_col_2", 0)
    createBranchPath({ { 0.926, 0.100, 4 }, { 0.926, 0.780, 4 } }, "poetry_col_3", 0)

    for _, p in ipairs({
        { "finale_spur1", 0.75 }, { "finale_spur2", 0.75 },
        { "finale_upper", 0.10 }, { "finale_upper", 0.55 }, { "finale_upper", 0.93 },
        { "finale_cross", 0.70 }, { "finale_droop", 0.85 },
        { "finale_trunk", 0.40 },
        { "finale_spray", 0.72 }, { "finale_tail_twig", 0.80 },
        { "poetry_col_2", 0.55 },
    }) do addTargetOnBranch(p[1], p[2], 34) end
end

function generateWentongZhu()
    -- 第14关:母本复刻 - 文同《墨竹图》(台北故宫,绢本 1830x2880) 大画布精刻
    -- S 形主竿自左上倒垂入谷再扬至右缘;每节双向生枝,枝梢缀叶(叶扇为渲染层)。
    createBranchPath({
        { 0.050, 0.205, 24 }, { 0.115, 0.262, 23 }, { 0.180, 0.325, 21 },
        { 0.245, 0.395, 20 }, { 0.305, 0.465, 18 }, { 0.355, 0.535, 17 },
        { 0.395, 0.600, 15 }, { 0.425, 0.650, 14 }, { 0.475, 0.668, 13 },
        { 0.535, 0.668, 12 }, { 0.600, 0.655, 12 }, { 0.665, 0.632, 11 },
        { 0.730, 0.607, 10 }, { 0.795, 0.588, 9 },  { 0.860, 0.580, 8 },
        { 0.920, 0.592, 7 },  { 0.960, 0.615, 6 },
    }, "wt_cane", 0.10)
    createBranchPath({ { 0.180, 0.325, 7 }, { 0.125, 0.375, 5 }, { 0.080, 0.415, 4 } }, "wt_zhi1", 0.12)
    createBranchPath({ { 0.115, 0.262, 6 }, { 0.075, 0.300, 4 }, { 0.045, 0.330, 3 } }, "wt_zhi1b", 0.12)
    createBranchPath({ { 0.305, 0.465, 7 }, { 0.245, 0.530, 6 }, { 0.195, 0.585, 5 }, { 0.165, 0.625, 4 } }, "wt_zhi2", 0.12)
    createBranchPath({ { 0.245, 0.395, 6 }, { 0.205, 0.450, 4 }, { 0.175, 0.495, 3 } }, "wt_zhi2b", 0.12)
    createBranchPath({ { 0.425, 0.650, 7 }, { 0.380, 0.710, 5 }, { 0.345, 0.760, 4 } }, "wt_zhi3", 0.12)
    createBranchPath({ { 0.395, 0.600, 5 }, { 0.355, 0.655, 4 }, { 0.325, 0.700, 3 } }, "wt_zhi3b", 0.12)
    createBranchPath({ { 0.535, 0.668, 6 }, { 0.560, 0.730, 5 }, { 0.575, 0.775, 4 } }, "wt_zhi4", 0.12)
    createBranchPath({ { 0.475, 0.668, 5 }, { 0.448, 0.730, 4 }, { 0.430, 0.778, 3 } }, "wt_zhi4b", 0.12)
    createBranchPath({ { 0.665, 0.632, 7 }, { 0.715, 0.560, 6 }, { 0.760, 0.505, 5 }, { 0.790, 0.468, 4 } }, "wt_zhi5", 0.12)
    createBranchPath({ { 0.665, 0.632, 5 }, { 0.690, 0.690, 4 }, { 0.710, 0.738, 3 } }, "wt_zhi5b", 0.12)
    createBranchPath({ { 0.795, 0.588, 6 }, { 0.845, 0.650, 5 }, { 0.880, 0.700, 4 } }, "wt_zhi6", 0.12)
    createBranchPath({ { 0.730, 0.607, 5 }, { 0.762, 0.665, 4 }, { 0.785, 0.710, 3 } }, "wt_zhi6b", 0.12)
    createBranchPath({ { 0.920, 0.592, 6 }, { 0.950, 0.535, 5 }, { 0.968, 0.495, 4 } }, "wt_zhi7", 0.12)
    createBranchPath({ { 0.860, 0.580, 5 }, { 0.900, 0.640, 4 }, { 0.928, 0.688, 3 } }, "wt_zhi8", 0.12)
    for _, p in ipairs({
        { "wt_zhi1", 0.8 }, { "wt_zhi1b", 0.8 },
        { "wt_zhi2", 0.55 }, { "wt_zhi2", 0.92 }, { "wt_zhi2b", 0.8 },
        { "wt_zhi3", 0.8 }, { "wt_zhi3b", 0.85 },
        { "wt_zhi4", 0.85 }, { "wt_zhi4b", 0.85 },
        { "wt_zhi5", 0.6 }, { "wt_zhi5", 0.95 }, { "wt_zhi5b", 0.85 },
        { "wt_zhi6", 0.85 }, { "wt_zhi6b", 0.85 },
        { "wt_zhi7", 0.8 }, { "wt_zhi8", 0.85 }, { "wt_cane", 0.50 },
    }) do addTargetOnBranch(p[1], p[2], 36) end
end

function generatePlumXiyan()
    -- 第15关:母本复刻 - 王冕《墨梅图》卷(北京故宫) 大画布精刻
    -- 主干右出渐细成长梢、左端回锋;双枝上扬各带分梢;沿干小花枝;题诗四柱。
    createBranchPath({
        { 1.000, 0.500, 44 }, { 0.940, 0.472, 41 }, { 0.880, 0.450, 38 },
        { 0.820, 0.435, 35 }, { 0.760, 0.420, 32 }, { 0.700, 0.412, 29 },
        { 0.640, 0.416, 25 }, { 0.580, 0.428, 20 }, { 0.520, 0.448, 16 },
        { 0.460, 0.466, 13 }, { 0.400, 0.492, 10 }, { 0.340, 0.512, 9 },
        { 0.280, 0.528, 7 },  { 0.220, 0.545, 6 },  { 0.170, 0.552, 6 },
    }, "xy_trunk", 0.10)
    createBranchPath({ { 0.170, 0.552, 6 }, { 0.135, 0.512, 5 }, { 0.108, 0.462, 4 }, { 0.092, 0.418, 3.5 } }, "xy_hook", 0.12)
    createBranchPath({
        { 0.790, 0.408, 15 }, { 0.745, 0.330, 13 }, { 0.705, 0.258, 11 },
        { 0.668, 0.196, 9 },  { 0.628, 0.146, 7 },  { 0.585, 0.112, 6 },
        { 0.540, 0.098, 4 },  { 0.495, 0.105, 3.5 },
    }, "xy_up_a", 0.10)
    createBranchPath({ { 0.705, 0.258, 7 }, { 0.665, 0.232, 5 }, { 0.625, 0.218, 4 }, { 0.588, 0.214, 3 } }, "xy_up_a2", 0.12)
    createBranchPath({ { 0.745, 0.330, 7 }, { 0.778, 0.276, 5 }, { 0.800, 0.235, 4 }, { 0.818, 0.202, 3 } }, "xy_up_a3", 0.12)
    createBranchPath({
        { 0.872, 0.428, 13 }, { 0.888, 0.345, 11 }, { 0.902, 0.270, 9 },
        { 0.918, 0.205, 7 },  { 0.936, 0.152, 5 },  { 0.952, 0.118, 4 },
    }, "xy_up_b", 0.10)
    createBranchPath({ { 0.902, 0.270, 6 }, { 0.872, 0.225, 4 }, { 0.845, 0.192, 3.5 } }, "xy_up_b2", 0.12)
    createBranchPath({ { 0.560, 0.432, 9 }, { 0.532, 0.498, 7 }, { 0.512, 0.556, 6 }, { 0.500, 0.600, 4 } }, "xy_down_mid", 0.12)
    createBranchPath({
        { 0.430, 0.478, 9 }, { 0.370, 0.530, 7 }, { 0.305, 0.568, 6 },
        { 0.245, 0.588, 4 }, { 0.190, 0.595, 3.5 },
    }, "xy_down_left", 0.12)
    createBranchPath({ { 0.940, 0.474, 10 }, { 0.918, 0.530, 7 }, { 0.900, 0.578, 6 }, { 0.888, 0.615, 4 } }, "xy_right_drop", 0.12)
    createBranchPath({ { 0.700, 0.412, 8 }, { 0.682, 0.352, 6 }, { 0.668, 0.300, 4 } }, "xy_twig1", 0.12)
    createBranchPath({ { 0.640, 0.416, 7 }, { 0.615, 0.360, 5 }, { 0.595, 0.315, 4 } }, "xy_twig2", 0.12)
    createBranchPath({ { 0.400, 0.492, 6 }, { 0.378, 0.442, 4 }, { 0.362, 0.402, 3.5 } }, "xy_mid_twig", 0.12)
    createBranchPath({ { 0.280, 0.528, 6 }, { 0.258, 0.482, 4 }, { 0.242, 0.448, 3.5 } }, "xy_left_twig", 0.12)
    createBranchPath({ { 0.315, 0.060, 6 }, { 0.315, 0.420, 6 } }, "poetry_col_1", 0)
    createBranchPath({ { 0.355, 0.060, 6 }, { 0.355, 0.420, 6 } }, "poetry_col_2", 0)
    createBranchPath({ { 0.395, 0.060, 6 }, { 0.395, 0.420, 6 } }, "poetry_col_3", 0)
    createBranchPath({ { 0.435, 0.050, 6 }, { 0.435, 0.300, 6 } }, "poetry_col_4", 0)
    for _, p in ipairs({
        { "xy_up_a", 0.45 }, { "xy_up_a", 0.80 }, { "xy_up_a2", 0.8 }, { "xy_up_a3", 0.8 },
        { "xy_up_b", 0.55 }, { "xy_up_b", 0.90 }, { "xy_up_b2", 0.8 },
        { "xy_trunk", 0.30 }, { "xy_twig1", 0.8 }, { "xy_twig2", 0.8 },
        { "xy_down_mid", 0.80 }, { "xy_down_left", 0.55 }, { "xy_down_left", 0.92 },
        { "xy_mid_twig", 0.8 }, { "xy_left_twig", 0.8 },
        { "xy_hook", 0.80 }, { "xy_right_drop", 0.80 }, { "poetry_col_2", 0.50 },
    }) do addTargetOnBranch(p[1], p[2], 38) end
end

function generateXuweiGrape()
    -- 第16关:母本复刻 - 徐渭《墨葡萄图》(北京故宫) 大画布精刻
    -- 狂草主藤右上横垂;左右垂蔓各带分梢;缠绕圈藤;飘垂细蔓;葡萄串/泼墨叶为渲染层。
    createBranchPath({
        { 0.960, 0.285, 19 }, { 0.880, 0.330, 18 }, { 0.800, 0.368, 16 },
        { 0.720, 0.400, 14 }, { 0.640, 0.428, 13 }, { 0.560, 0.452, 13 },
        { 0.480, 0.478, 11 }, { 0.400, 0.500, 10 }, { 0.320, 0.522, 10 },
        { 0.240, 0.540, 8 },  { 0.160, 0.552, 8 },  { 0.090, 0.558, 6 },
    }, "xw_vine", 0.12)
    createBranchPath({
        { 0.160, 0.552, 8 }, { 0.135, 0.620, 6 }, { 0.118, 0.690, 6 },
        { 0.108, 0.760, 5 }, { 0.105, 0.825, 5 }, { 0.112, 0.880, 4 },
    }, "xw_left_drop", 0.12)
    createBranchPath({
        { 0.800, 0.368, 10 }, { 0.825, 0.440, 8 }, { 0.845, 0.515, 6 },
        { 0.858, 0.590, 6 },  { 0.862, 0.660, 5 }, { 0.855, 0.730, 5 }, { 0.840, 0.795, 4 },
    }, "xw_right_drop", 0.12)
    createBranchPath({ { 0.845, 0.515, 6 }, { 0.890, 0.560, 5 }, { 0.920, 0.610, 5 }, { 0.938, 0.660, 4 } }, "xw_right_drop2", 0.12)
    createBranchPath({ { 0.460, 0.482, 5 }, { 0.452, 0.560, 4 }, { 0.448, 0.635, 4 }, { 0.450, 0.705, 4 } }, "xw_trail1", 0)
    createBranchPath({ { 0.560, 0.455, 5 }, { 0.572, 0.535, 4 }, { 0.580, 0.610, 4 }, { 0.585, 0.680, 4 } }, "xw_trail2", 0)
    createBranchPath({ { 0.660, 0.425, 5 }, { 0.672, 0.500, 4 }, { 0.680, 0.572, 4 }, { 0.685, 0.640, 4 } }, "xw_trail3", 0)
    createBranchPath({ { 0.640, 0.428, 8 }, { 0.565, 0.392, 6 }, { 0.495, 0.372, 5 }, { 0.435, 0.368, 4 } }, "xw_top_leaf", 0.12)
    -- 狂草缠绕圈藤(近闭环)
    createBranchPath({
        { 0.480, 0.478, 7 }, { 0.508, 0.516, 6 }, { 0.500, 0.560, 5 },
        { 0.462, 0.572, 5 }, { 0.432, 0.543, 5 }, { 0.446, 0.506, 5 }, { 0.474, 0.494, 5 },
    }, "xw_curl1", 0.10)
    createBranchPath({
        { 0.320, 0.522, 6 }, { 0.348, 0.556, 5 }, { 0.336, 0.596, 4 },
        { 0.300, 0.588, 4 }, { 0.292, 0.552, 4 },
    }, "xw_curl2", 0.10)
    for _, p in ipairs({
        { "xw_vine", 0.25 }, { "xw_vine", 0.55 }, { "xw_vine", 0.85 },
        { "xw_right_drop", 0.45 }, { "xw_right_drop", 0.85 }, { "xw_right_drop2", 0.85 },
        { "xw_left_drop", 0.50 }, { "xw_left_drop", 0.90 },
        { "xw_trail1", 0.85 }, { "xw_trail2", 0.85 }, { "xw_trail3", 0.85 },
        { "xw_top_leaf", 0.80 }, { "xw_curl1", 0.45 },
    }) do addTargetOnBranch(p[1], p[2], 40) end
end


local function generatePeach()
    waterLevel = H(0.86)
    createBranch(W(0.05), H(0.82), W(0.22), H(0.68), 42, 28, 50, -80, 120, "main_trunk", 0.12)
    createBranch(W(0.42), H(0.65), W(0.55), H(0.45), 28, 20, 50, -50, 120, "middle_main", 0.12)
    createBranch(W(0.55), H(0.45), W(0.92), H(0.38), 20, 12, 100, 30, 150, "middle_bridge", 0.12)
    for _, p in ipairs({
        { "main_trunk", 0.25 }, { "main_trunk", 0.40 }, { "main_trunk", 0.62 }, { "main_trunk", 0.85 },
        { "middle_main", 0.22 }, { "middle_main", 0.42 }, { "middle_main", 0.62 }, { "middle_main", 0.82 },
        { "middle_bridge", 0.18 }, { "middle_bridge", 0.35 }, { "middle_bridge", 0.52 },
        { "middle_bridge", 0.70 }, { "middle_bridge", 0.84 }, { "middle_bridge", 0.94 },
    }) do addTargetOnBranch(p[1], p[2], 50) end
    for _, r in ipairs({
        { W(0.25), H(0.12), H(0.48) }, { W(0.30), H(0.14), H(0.52) },
        { W(0.35), H(0.11), H(0.48) }, { W(0.40), H(0.13), H(0.46) },
    }) do
        willowRopes[#willowRopes + 1] = {
            anchorX = r[1], anchorY = r[2], length = r[3],
            angle = (hash01(r[1] * 0.01) - 0.5) * 0.15,
            angularVelocity = 0,
            oscTime = hash01(r[2] * 0.02) * math.pi,
        }
    end
    for i = 1, 32 do
        floatingPetals[#floatingPetals + 1] = {
            x = hash01(i * 12) * worldW,
            y = waterLevel + (hash01(i * 22) - 0.5) * 18,
            w = 82 + hash01(i * 28) * 34, h = 22 + hash01(i * 30) * 10,
            speed = 0.7 + hash01(i * 32) * 1.35,
            bob = hash01(i * 42) * math.pi,
        }
    end
end

local function addRoof(x1, y1, x2, y2, cp)
    local r = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, cp = cp, points = {} }
    for i = 0, 40 do
        local t = i / 40
        r.points[#r.points + 1] = { x = qbez(x1, cp.x, x2, t), y = qbez(y1, cp.y, y2, t), t = t }
    end
    roofs[#roofs + 1] = r
end

local function addPavilion(x, y, w, layers, layerH)
    pavilions[#pavilions + 1] = { x = x, y = y, w = w, layers = layers, layerH = layerH }
    for i = 0, layers - 1 do
        local ly = y + i * layerH
        for bx = x - 15, x + w + 15, 8 do
            addBranchNode({ x = bx, y = ly, r = 6, branchId = "pavilion_beam_" .. tostring(i), t = 0, normX = 0, normY = -1, baseX = bx, baseY = ly })
        end
    end
end

local function generatePlumMaster()
    createBranchPath({
        { 0.50, 0.045, 34 }, { 0.47, 0.115, 33 }, { 0.43, 0.205, 32 },
        { 0.42, 0.300, 31 }, { 0.38, 0.430, 30 }, { 0.36, 0.535, 28 },
        { 0.31, 0.650, 25 }, { 0.30, 0.755, 23 }, { 0.34, 0.930, 18 },
    }, "master_trunk", 0.18)
    createBranchPath({
        { 0.43, 0.180, 17 }, { 0.36, 0.185, 15 }, { 0.26, 0.205, 12 },
        { 0.17, 0.220, 8 }, { 0.08, 0.212, 4 },
    }, "master_upper_left", 0.20)
    createBranchPath({
        { 0.47, 0.135, 16 }, { 0.56, 0.145, 14 }, { 0.66, 0.165, 11 },
        { 0.76, 0.195, 7 }, { 0.93, 0.190, 4 },
    }, "master_upper_right", 0.18)
    createBranchPath({
        { 0.40, 0.345, 20 }, { 0.32, 0.360, 17 }, { 0.23, 0.385, 12 },
        { 0.14, 0.425, 7 }, { 0.05, 0.495, 3 },
    }, "master_mid_left", 0.18)
    createBranchPath({
        { 0.42, 0.405, 22 }, { 0.52, 0.430, 20 }, { 0.63, 0.475, 15 },
        { 0.74, 0.535, 10 }, { 0.89, 0.600, 5 },
    }, "master_mid_right", 0.18)
    createBranchPath({
        { 0.35, 0.535, 20 }, { 0.27, 0.585, 17 }, { 0.18, 0.645, 12 },
        { 0.09, 0.710, 7 }, { 0.03, 0.780, 3 },
    }, "master_lower_left", 0.18)
    createBranchPath({
        { 0.33, 0.615, 25 }, { 0.45, 0.650, 22 }, { 0.57, 0.685, 18 },
        { 0.70, 0.735, 12 }, { 0.83, 0.785, 7 }, { 0.97, 0.855, 3 },
    }, "master_lower_right_sweep", 0.18)
    createBranchPath({
        { 0.31, 0.755, 18 }, { 0.40, 0.805, 15 }, { 0.50, 0.860, 11 },
        { 0.63, 0.910, 7 }, { 0.80, 0.970, 3 },
    }, "master_bottom_spray", 0.18)

    createBranchPath({ { 0.18, 0.220, 5 }, { 0.12, 0.185, 3 }, { 0.06, 0.170, 2 } }, "master_twig_ul_1", 0.22)
    createBranchPath({ { 0.22, 0.238, 5 }, { 0.27, 0.272, 3 }, { 0.32, 0.325, 2 } }, "master_twig_ul_2", 0.22)
    createBranchPath({ { 0.56, 0.145, 5 }, { 0.63, 0.105, 3 }, { 0.69, 0.085, 2 } }, "master_twig_ur_1", 0.22)
    createBranchPath({ { 0.66, 0.170, 5 }, { 0.75, 0.135, 3 }, { 0.84, 0.120, 2 } }, "master_twig_ur_2", 0.22)
    createBranchPath({ { 0.76, 0.195, 4 }, { 0.86, 0.225, 3 }, { 0.96, 0.235, 2 } }, "master_twig_ur_3", 0.22)
    createBranchPath({ { 0.23, 0.385, 6 }, { 0.16, 0.475, 3 }, { 0.10, 0.535, 2 } }, "master_twig_ml_1", 0.22)
    createBranchPath({ { 0.31, 0.360, 5 }, { 0.24, 0.315, 3 }, { 0.18, 0.295, 2 } }, "master_twig_ml_2", 0.22)
    addMasterPlumFlowerTarget(0.21, 0.23, 0.18, 0.22, 25)
    addMasterPlumFlowerTarget(0.60, 0.15, 0.55, 0.14, 25)
    addMasterPlumFlowerTarget(0.76, 0.20, 0.72, 0.19, 25)
    addMasterPlumFlowerTarget(0.22, 0.42, 0.18, 0.41, 25)
    addMasterPlumFlowerTarget(0.70, 0.45, 0.66, 0.43, 25)
    addMasterPlumFlowerTarget(0.20, 0.62, 0.17, 0.60, 25)
    addMasterPlumFlowerTarget(0.42, 0.60, 0.38, 0.58, 25)
    addMasterPlumFlowerTarget(0.65, 0.64, 0.61, 0.62, 25)
    addMasterPlumFlowerTarget(0.38, 0.80, 0.34, 0.78, 25)
    addMasterPlumFlowerTarget(0.53, 0.88, 0.49, 0.86, 25)
end

local function generateEaves()
    addPavilion(W(0.05), H(0.55), 260, 3, 110)
    addRoof(W(0.05), H(0.55), W(0.01), H(0.48), { x = W(0.03), y = H(0.56) })
    addRoof(W(0.05) + 260, H(0.55), W(0.05) + 320, H(0.48), { x = W(0.05) + 290, y = H(0.56) })
    gears[#gears + 1] = { x = W(0.24), y = H(0.62), radius = 110, speed = 0.012, teethHeight = 18, angle = 0 }
    gears[#gears + 1] = { x = W(0.35), y = H(0.52), radius = 90, speed = -0.016, teethHeight = 16, angle = 0 }
    addPavilion(W(0.45), H(0.45), 340, 4, 120)
    addRoof(W(0.45) + 340, H(0.45), W(0.68), H(0.32), { x = W(0.58), y = H(0.52) })
    addRoof(W(0.45), H(0.45), W(0.39), H(0.35), { x = W(0.42), y = H(0.47) })
    chimes[#chimes + 1] = { x = W(0.39), y = H(0.39), pulse = 0, swayAngle = 0 }
    chimes[#chimes + 1] = { x = W(0.68), y = H(0.37), pulse = 0, swayAngle = 0 }
    chimes[#chimes + 1] = { x = W(0.01), y = H(0.52), pulse = 0, swayAngle = 0 }
    addPavilion(W(0.78), H(0.35), 220, 2, 130)
    addRoof(W(0.78), H(0.35), W(0.72), H(0.26), { x = W(0.75), y = H(0.37) })
    addRoof(W(0.78) + 220, H(0.35), W(0.92), H(0.22), { x = W(0.88), y = H(0.37) })
    chimes[#chimes + 1] = { x = W(0.72), y = H(0.31), pulse = 0, swayAngle = 0 }
    for _, p in ipairs({
        { W(0.12), H(0.42) }, { W(0.18), H(0.38) }, { W(0.24), H(0.46) },
        { W(0.30), H(0.41) }, { W(0.35), H(0.35) }, { W(0.48), H(0.36) },
        { W(0.56), H(0.32) }, { W(0.62), H(0.28) }, { W(0.70), H(0.22) },
        { W(0.78), H(0.24) }, { W(0.88), H(0.18) }, { W(0.94), H(0.16) },
    }) do addTarget(p[1], p[2], 46) end
end

local function generateHuangshan()
    createBranch(W(0.12), H(0.58), W(0.35), H(0.56), 32, 20, 80, -60, 100, "pine_l1", 0.10)
    createBranch(W(0.35), H(0.56), W(0.25), H(0.42), 20, 10, -80, -80, 80, "pine_l1_spur", 0.10)
    createBranch(W(0.48), H(0.45), W(0.72), H(0.48), 25, 14, 100, 110, 110, "pine_r1", 0.10)
    createBranch(W(0.72), H(0.48), W(0.62), H(0.35), 14, 8, -80, -80, 80, "pine_r1_spur", 0.10)
    createBranch(W(0.88), H(0.35), W(0.96), H(0.28), 15, 6, 50, -50, 80, "pine_peak", 0.10)
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.25), y = H(0.75), rx = 180, ry = 50, bob = 0 }
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.45), y = H(0.65), rx = 220, ry = 55, bob = 1.7 }
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.68), y = H(0.72), rx = 190, ry = 48, bob = 3.0 }
    cloudPlatforms[#cloudPlatforms + 1] = { x = W(0.82), y = H(0.62), rx = 160, ry = 42, bob = 4.2 }
    for _, p in ipairs({
        { "pine_l1", 0.25 }, { "pine_l1", 0.50 }, { "pine_l1", 0.75 },
        { "pine_l1_spur", 0.45 }, { "pine_l1_spur", 0.80 },
        { "pine_r1", 0.22 }, { "pine_r1", 0.45 }, { "pine_r1", 0.72 },
        { "pine_r1_spur", 0.45 }, { "pine_r1_spur", 0.82 },
        { "pine_peak", 0.35 }, { "pine_peak", 0.65 }, { "pine_peak", 0.90 },
    }) do
        addTargetOnBranch(p[1], p[2], 40)
    end
    for i = 0, 2 do
        cranes[#cranes + 1] = {
            x = W(0.3 + i * 0.3),
            y = H(0.2 + hash01(i + 100) * 0.3),
            startY = H(0.2 + hash01(i + 100) * 0.3),
            speed = 2.2 + hash01(i + 200) * 0.6,
            amplitude = 45 + hash01(i + 300) * 25,
            theta = hash01(i + 400) * math.pi * 2,
            wingAngle = 0,
        }
    end
end

function generateMolong()
    -- 第17关:意象复刻 - 陈容《九龙图》墨龙(波士顿美术馆)
    -- 龙身三起三伏横贯全卷,是一条"活"的平台(运行时整条做行波起伏);
    -- 龙首在右,角可攀,四爪探波;云团可踏;龙珠悬于云上与龙身。
    createBranchPath({
        { 0.040, 0.600, 14 }, { 0.085, 0.520, 18 }, { 0.130, 0.450, 22 },
        { 0.180, 0.420, 26 }, { 0.235, 0.460, 29 }, { 0.285, 0.550, 31 },
        { 0.330, 0.660, 32 }, { 0.385, 0.730, 32 }, { 0.440, 0.740, 32 },
        { 0.495, 0.680, 31 }, { 0.545, 0.570, 29 }, { 0.595, 0.460, 27 },
        { 0.645, 0.385, 25 }, { 0.700, 0.360, 23 }, { 0.755, 0.400, 21 },
        { 0.805, 0.470, 19 }, { 0.850, 0.520, 18 }, { 0.895, 0.520, 17 },
    }, "dragon_body", 0.08)
    createBranchPath({
        { 0.895, 0.520, 17 }, { 0.930, 0.480, 22 }, { 0.962, 0.450, 21 }, { 0.985, 0.440, 18 },
    }, "dragon_head", 0.08)
    createBranchPath({ { 0.940, 0.425, 7 }, { 0.922, 0.360, 5 }, { 0.905, 0.300, 4 } }, "dragon_horn", 0)
    createBranchPath({ { 0.235, 0.490, 10 }, { 0.222, 0.558, 8 }, { 0.249, 0.624, 6 }, { 0.244, 0.685, 4 } }, "dragon_leg1", 0)
    createBranchPath({ { 0.440, 0.770, 10 }, { 0.426, 0.832, 8 }, { 0.456, 0.884, 6 }, { 0.450, 0.925, 4 } }, "dragon_leg2", 0)
    createBranchPath({ { 0.645, 0.415, 10 }, { 0.631, 0.478, 8 }, { 0.659, 0.538, 6 }, { 0.654, 0.595, 4 } }, "dragon_leg3", 0)
    createBranchPath({ { 0.850, 0.550, 10 }, { 0.836, 0.614, 8 }, { 0.865, 0.674, 6 }, { 0.860, 0.740, 4 } }, "dragon_leg4", 0)
    for _, c in ipairs({
        { 0.10, 0.82, 210, 55, 0.0 }, { 0.27, 0.30, 190, 50, 1.3 },
        { 0.47, 0.30, 200, 52, 2.2 }, { 0.62, 0.80, 210, 55, 3.1 },
        { 0.80, 0.76, 190, 50, 4.0 }, { 0.93, 0.68, 160, 45, 5.0 },
    }) do
        cloudPlatforms[#cloudPlatforms + 1] = { x = W(c[1]), y = H(c[2]), rx = c[3], ry = c[4], bob = c[5] }
    end
    addTarget(W(0.27), H(0.165), 42)
    addTarget(W(0.58), H(0.150), 42)
    addTarget(W(0.74), H(0.620), 40)
    for _, p in ipairs({
        { "dragon_body", 0.30 }, { "dragon_body", 0.55 }, { "dragon_body", 0.80 },
        { "dragon_head", 0.70 },
    }) do addTargetOnBranch(p[1], p[2], 40) end
end
