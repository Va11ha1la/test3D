-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.

local function masterPlumBranchAlpha(id)
    if id == "master_trunk" then return 62 end
    if id:find("twig") then return 48 end
    return 54
end

function drawPineNeedleCluster(x, y, nx, ny, lenBase, count, spread, seed, alpha)
    local base = math.atan2(ny or -1, nx or 0)
    local needleTint = currentLevel.id == "huangshan" and C(32, 86, 58) or C(28, 76, 43)
    local darkTint = currentLevel.id == "huangshan" and C(11, 30, 21) or C(9, 24, 15)
    for layer = 1, 2 do
        local layerCount = math.floor((count or 18) * (layer == 1 and 1 or 0.72))
        local layerLen = (lenBase or 36) * (layer == 1 and 1.0 or 0.72)
        local layerSpread = (spread or 1.15) * (layer == 1 and 1.0 or 0.62)
        nvgBeginPath(vg)
        for i = 0, layerCount - 1 do
            local t = layerCount <= 1 and 0.5 or i / (layerCount - 1)
            local s = seed + layer * 997 + i * 37
            local a = base + (t - 0.5) * layerSpread + (hash01(s) - 0.5) * 0.23
            local len = layerLen * (0.62 + hash01(s + 5) * 0.68)
            local bend = (hash01(s + 7) - 0.5) * len * 0.18
            local tx, ty = math.cos(a), math.sin(a)
            local px = x + tx * len - ty * bend
            local py = y + ty * len + tx * bend
            nvgMoveTo(vg, x, y)
            nvgLineTo(vg, px, py)
        end
        nvgStrokeColor(vg, colorRGBA(layer == 1 and needleTint or darkTint, (alpha or 130) * (layer == 1 and 0.82 or 0.52)))
    nvgStrokeWidth(vg, layer == 1 and 1.15 or 0.75)
        nvgStroke(vg)
    end
    drawRotEllipse(x, y, (lenBase or 36) * 0.20, (lenBase or 36) * 0.08, base, colorRGBA(needleTint, (alpha or 130) * 0.12))
    if currentLevelIsInkLab and currentLevelIsInkLab() then
        drawInkLabNeedleTexture(x, y, nx or 0, ny or -1, lenBase or 36, alpha or 130, seed or 0)
    end
end

function drawTinyBlossom(x, y, r, tintA, tintB, centerTint, seed, alpha, petals)
    local n = petals or 5
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, hash01(seed + 3) * math.pi * 2)
    for i = 0, n - 1 do
        local a = i / n * math.pi * 2 + (hash01(seed + i * 13) - 0.5) * 0.25
        nvgSave(vg)
        nvgRotate(vg, a)
        fillPetalShape(r * (0.88 + hash01(seed + i * 17) * 0.22), r * (0.33 + hash01(seed + i * 19) * 0.10), colorRGBA(i % 2 == 0 and tintA or tintB, (alpha or 150) * (0.82 + hash01(seed + i * 23) * 0.18)))
        nvgRestore(vg)
    end
    drawCircle(0, 0, r * 0.16, colorRGBA(centerTint, alpha or 150))
    nvgRestore(vg)
    drawInkSpeckles(x - r * 0.55, y - r * 0.55, r * 1.1, r * 1.1, centerTint, (alpha or 150) * 0.28, seed + 41, 7)
end

local function drawBranches()
    local inkLabWorldLayerActive = false
    if currentLevelIsInkLab and currentLevelIsInkLab() and currentLevel.id == "pine" and drawInkLabWorldStrokeLayer then
        inkLabWorldLayerActive = drawInkLabWorldStrokeLayer()
    end
    for id, list in pairs(branchGroups) do
        local mainTint = currentLevel.id == "pine" and C(45, 38, 32) or currentLevel.ink
        local mainAlpha = 232
        local isLDtkRoute = currentLevel.id == "ldtk_grand_scroll" and id:find("^ldtk_route_") ~= nil
        local isInkLabPine = currentLevelIsInkLab and currentLevelIsInkLab() and currentLevel.id == "pine"
        local inkLabVisibleBranch = true
        if isInkLabPine and inkLabBranchListVisible then
            inkLabVisibleBranch = inkLabBranchListVisible(list, 360)
        end
        if isInkLabPine then
            mainTint, mainAlpha = C(39, 35, 30), 214
        end
        if id:find("poetry") then mainTint, mainAlpha = currentLevel.ink, 150 end
        if currentLevel.id == "plum_master" then mainTint, mainAlpha = C(34, 27, 22), masterPlumBranchAlpha(id) end
        if isLDtkRoute then mainTint, mainAlpha = C(34, 30, 24), 112 end
        local isPavilion = id:find("pavilion") ~= nil
        if isPavilion then mainTint, mainAlpha = currentLevel.ink, 95 end
        if ((not isPavilion) or showDebug) and inkLabVisibleBranch then
            if (not isPavilion) and not (currentLevel.id == "plum_master" and id:find("twig")) then
                local isInkLabBranch = isInkLabPine and drawInkLabSoftRibbon
                if isLDtkRoute then
                    fillBrushRibbon(list, mainTint, mainAlpha, (#id * 37) + (list[1] and list[1].x or 0) * 0.01)
                elseif isInkLabBranch and not inkLabWorldLayerActive then
                    drawInkLabSoftRibbon(list, mainTint, mainAlpha, (#id * 37) + (list[1] and list[1].x or 0) * 0.01)
                elseif not isInkLabPine then
                    fillBrushRibbon(list, mainTint, mainAlpha, (#id * 37) + (list[1] and list[1].x or 0) * 0.01)
                end
                if isInkLabPine and (not inkLabWorldLayerActive) and drawInkLabBranchMaterial then
                    drawInkLabBranchMaterial(id, list)
                end
            end
            if not (isInkLabPine and inkLabWorldLayerActive and not showDebug) then
                for i = 1, #list - 1 do
                    local n1, n2 = list[i], list[i + 1]
                    local angle = math.atan2(n2.y - n1.y, n2.x - n1.x)
                    local showBrushNode = isPavilion or (currentLevel.id ~= "plum_master" and (i == 1 or i % 8 == 0))
                    if isInkLabPine then
                        showBrushNode = false
                    end
                    if isLDtkRoute then
                        showBrushNode = false
                    end
                    if currentLevel.id == "plum_mirror" then
                        showBrushNode = (i == 1 or i % 16 == 0)
                    end
                    if showBrushNode then
                        local nodeScale = currentLevel.id == "plum_master" and 0.56 or 1.0
                        local nodeAlpha = currentLevel.id == "plum_master" and math.min(64, mainAlpha) or math.min(190, mainAlpha)
                        if isInkLabPine then
                            nodeScale = 0.76
                            nodeAlpha = 82
                        end
                        drawRotEllipse(n1.x, n1.y, n1.r * nodeScale * (0.82 + hash01(i + n1.x) * 0.18), n1.r * nodeScale * (0.55 + hash01(i + n1.y) * 0.18), angle, colorRGBA(mainTint, isPavilion and mainAlpha or nodeAlpha))
                    end
                    if (not isLDtkRoute) and (not isPavilion) and (not isInkLabPine) and currentLevel.id ~= "plum_master" and currentLevel.id ~= "plum_mirror" and i % 11 == 0 then
                        drawInkBleed(n1.x, n1.y, n1.r * 1.15, n1.r * 0.68, mainTint, 28, n1.x * 0.019 + n1.y * 0.013 + i, 2)
                    end
                    if showDebug then drawCircle(n1.x, n1.y, 2, rgba(255, 220, 20, 180)) end
                    if (not isPavilion) and currentLevel.id == "plum_master" then
                        if id:find("twig") or i % 3 == 0 then
                            local w = id:find("twig") and math.max(0.65, n1.r * 0.26) or 0.95
                            local a = id:find("twig") and 70 or 54
                            drawDryBrushLine(n1.x, n1.y, n2.x, n2.y, w, C(20, 16, 13), a, i * 17 + n1.x * 0.01, 1)
                        end
                    elseif not isPavilion then
                        local edgeTint = currentLevel.id == "pine" and C(15, 12, 10) or C(18, 14, 11)
                        local edgeAlphaA = 176
                        local edgeAlphaB = 142
                        if isLDtkRoute then
                            edgeAlphaA = 54
                            edgeAlphaB = 38
                        end
                        if isInkLabPine then
                            -- Pine InkLab branches are rendered as one pre-baked world brush layer above.
                        elseif currentLevel.id == "pine" or currentLevel.id == "huangshan" or currentLevel.id == "maple" or currentLevel.id == "plum_mirror" then
                            local edgeStep = currentLevel.id == "maple" and 3 or (currentLevel.id == "plum_mirror" and 3 or 4)
                            if i % edgeStep == 0 then
                                strokeLine(n1.x + n1.normX * n1.r, n1.y + n1.normY * n1.r, n2.x + n2.normX * n2.r, n2.y + n2.normY * n2.r, 1.25, colorRGBA(edgeTint, 118))
                                strokeLine(n1.x - n1.normX * n1.r, n1.y - n1.normY * n1.r, n2.x - n2.normX * n2.r, n2.y - n2.normY * n2.r, 1.0, colorRGBA(edgeTint, 92))
                            end
                            if (currentLevel.id == "maple" or currentLevel.id == "plum_mirror") and i % 21 == 0 then
                                drawInkSpeckles(n1.x - n1.r, n1.y - n1.r, n1.r * 2, n1.r * 2, edgeTint, 48, i * 23 + n1.x, 2)
                            end
                        else
                            drawDryBrushLine(n1.x + n1.normX * n1.r, n1.y + n1.normY * n1.r, n2.x + n2.normX * n2.r, n2.y + n2.normY * n2.r, 2.2, edgeTint, edgeAlphaA, i * 17 + n1.x * 0.01, 2)
                            drawDryBrushLine(n1.x - n1.normX * n1.r, n1.y - n1.normY * n1.r, n2.x - n2.normX * n2.r, n2.y - n2.normY * n2.r, 1.9, edgeTint, edgeAlphaB, i * 19 + n1.y * 0.01, 2)
                            if (not isLDtkRoute) and i % 9 == 0 then
                                drawInkSpeckles(n1.x - n1.r, n1.y - n1.r, n1.r * 2, n1.r * 2, edgeTint, 78, i * 23 + n1.x, 4)
                            end
                        end
                    end
                end
            end
        end
    end
    if currentLevel.id == "peach" then
        for id, list in pairs(branchGroups) do
            if (not id:find("pavilion")) and (not id:find("poetry")) then
                for i = 6, #list - 2, 14 do
                    local n = list[i]
                    local seed = i * 47 + n.x * 0.017 + n.y * 0.013
                    drawTinyBlossom(n.x + n.normX * (n.r + 18), n.y + n.normY * (n.r + 18), 10 + hash01(seed) * 5, C(240, 95, 120), C(255, 178, 190), C(90, 34, 48), seed, 72, 5)
                    if i % 28 == 0 then
                        drawTinyBlossom(n.x + n.normX * (n.r + 38) + (hash01(seed + 7) - 0.5) * 24, n.y + n.normY * (n.r + 34) + (hash01(seed + 11) - 0.5) * 24, 7 + hash01(seed + 13) * 4, C(255, 184, 196), C(240, 95, 120), C(95, 40, 52), seed + 811, 56, 5)
                    end
                end
            end
        end
    end
    for _, s in ipairs(streams) do
        strokeQuad(s.x1, s.y1, (s.x1 + s.x2) * 0.5 - 45, (s.y1 + s.y2) * 0.5, s.x2, s.y2, s.width * 0.18, colorRGBA(currentLevel.water, 72))
        local streamAngle = math.atan2(s.y2 - s.y1, s.x2 - s.x1)
        for i = 1, 12 do
            local t = i / 13
            local px = s.x1 + (s.x2 - s.x1) * t + (hash01(i * 31 + s.x1) - 0.5) * s.width * 0.35
            local py = s.y1 + (s.y2 - s.y1) * t + (hash01(i * 37 + s.y1) - 0.5) * s.width * 0.18
            drawRotEllipse(px, py, s.width * (0.12 + hash01(i * 41) * 0.16), 3 + hash01(i * 43) * 8, streamAngle, colorRGBA(currentLevel.water, 30 + hash01(i * 47) * 36))
        end
        for off = -10, 10, 6 do
            strokeQuad(s.x1 + off, s.y1, (s.x1 + s.x2) * 0.5 - 30 + off, (s.y1 + s.y2) * 0.5 + math.sin(elapsed * 2 + off) * 8, s.x2 + off, s.y2, 1.5, colorRGBA(currentLevel.water, 138))
        end
    end
end

local function drawBamboo()
    for _, s in ipairs(bambooSegments) do
        local nx = math.cos(s.angle + math.pi / 2)
        local ny = math.sin(s.angle + math.pi / 2)
        fillPoly({
            { s.x1 + nx * s.r * 0.86, s.y1 + ny * s.r * 0.86 },
            { s.x2 + nx * s.r * 0.68, s.y2 + ny * s.r * 0.68 },
            { s.x2 - nx * s.r * 0.68, s.y2 - ny * s.r * 0.68 },
            { s.x1 - nx * s.r * 0.86, s.y1 - ny * s.r * 0.86 },
        }, colorRGBA(currentLevel.accent, 118))
        drawDryBrushLine(s.x1, s.y1, s.x2, s.y2, s.r * 2.05, currentLevel.accent, 205, s.x1 * 0.013 + s.y1 * 0.017, 4)
        strokeLine(s.x1 + nx * s.r * 0.38, s.y1 + ny * s.r * 0.38, s.x2 + nx * s.r * 0.22, s.y2 + ny * s.r * 0.22, 1.2, rgba(232, 238, 230, 62))
        if hash01(s.x1 * 0.015 + s.y1 * 0.019) > 0.35 then
            drawDryBrushLine(s.x1 - nx * s.r * 0.58, s.y1 - ny * s.r * 0.58, s.x2 - nx * s.r * 0.42, s.y2 - ny * s.r * 0.42, 0.8, currentLevel.paper, 45, s.x1 * 0.02 + s.y2 * 0.01, 1)
        end
        drawRotEllipse(s.nodeX, s.nodeY, s.r * 1.4, s.r * 0.6, s.angle, colorRGBA(currentLevel.ink, 245))
        drawInkBleed(s.nodeX, s.nodeY, s.r * 1.2, s.r * 0.42, currentLevel.ink, 44, s.nodeX * 0.017 + s.nodeY * 0.011, 2)
        if hash01(s.nodeX * 0.01) > 0.45 then
            drawDryBrushLine(s.nodeX, s.nodeY, s.nodeX + math.cos(s.angle + 0.7) * s.r * 4, s.nodeY + math.sin(s.angle + 0.7) * s.r * 4, s.r * 0.35, currentLevel.ink, 155, s.nodeX * 0.02, 2)
        end
        if showDebug then drawCircle(s.nodeX, s.nodeY, 3, rgba(255, 220, 20, 180)) end
    end
end

local function drawLeavesAndPetals()
    if currentLevel.id == "maple" then
        for _, leaf in ipairs(glidingLeaves) do
            local y = mapleLeafVisualY(leaf)
            if leaf.platform then
                local squash = leaf.squash or 0
                drawInkBleed(leaf.x, y + leaf.size * 0.10, leaf.size * 0.78, leaf.size * 0.24, currentLevel.bloom, 18 + squash * 12, leaf.x * 0.01 + leaf.y * 0.02, 2)
                drawAutumnLeaf(leaf.x, y, leaf.size * (0.78 + squash * 0.06), rgba(210, 24, 24, 168))
            else
                drawAutumnLeaf(leaf.x, y, leaf.size * 0.72, colorRGBA(currentLevel.bloom, 145))
                if hash01(leaf.x * 0.01) > 0.55 then
                    drawInkBleed(leaf.x, y, leaf.size * 0.45, leaf.size * 0.18, currentLevel.bloom, 22, leaf.x * 0.01 + leaf.y * 0.02, 2)
                end
            end
        end
    elseif currentLevel.id == "peach" then
        for _, p in ipairs(floatingPetals) do
            local y = p.y + math.sin(p.bob) * 4
            nvgSave(vg)
            nvgTranslate(vg, p.x, y)
            nvgRotate(vg, math.sin(p.bob) * 0.16)
            fillPetalShape(p.w * 0.55, p.h * 0.70, colorRGBA(currentLevel.bloom, 198))
            drawDryBrushLine(-p.w * 0.18, p.h * 0.10, p.w * 0.18, p.h * 0.45, 1.0, C(96, 55, 70), 58, p.x * 0.017 + p.y * 0.013, 1)
            nvgRestore(vg)
            drawInkBleed(p.x, y + p.h * 0.12, p.w * 0.32, p.h * 0.23, currentLevel.bloom, 18, p.x * 0.01 + p.y * 0.02, 2)
        end
    end
end

local function drawRopes()
    for _, rope in ipairs(willowRopes) do
        local lastX, lastY = rope.anchorX, rope.anchorY
        for i = 1, 20 do
            local ratio = i / 20
            local len = rope.length * ratio
            local a = rope.angle * (1 - (1 - ratio) * (1 - ratio) * 0.3)
            local x = rope.anchorX + math.sin(a) * len
            local y = rope.anchorY + math.cos(a) * len
            drawDryBrushLine(lastX, lastY, x, y, 2.2, currentLevel.accent, 198, rope.anchorX * 0.01 + i * 31, 2)
            if i > 3 and i % 3 == 0 then
                drawRotEllipse(x + math.cos(a) * 12, y + math.sin(a) * 4, 12, 4, a + math.pi / 2, colorRGBA(currentLevel.accent, 180))
                drawDryBrushLine(x, y, x + math.cos(a + 0.45) * 26, y + math.sin(a + 0.45) * 8, 1.0, currentLevel.accent, 118, rope.anchorY * 0.01 + i, 1)
            end
            lastX, lastY = x, y
        end
    end
end

function drawEavesFlowerSprays()
    if currentLevel.id ~= "eaves" then return end
    for _, r in ipairs(roofs) do
        for j = 1, 5 do
            local t = (j - 0.35) / 5.3
            local x = qbez(r.x1, r.cp.x, r.x2, t)
            local y = qbez(r.y1, r.cp.y, r.y2, t)
            local seed = x * 0.014 + y * 0.018 + j * 53
            local hang = 18 + hash01(seed + 3) * 34
            strokeQuad(x, y + 4, x + (hash01(seed + 5) - 0.5) * 16, y + hang * 0.58, x + (hash01(seed + 7) - 0.5) * 22, y + hang, 1.0, rgba(42, 32, 22, 82))
            drawTinyBlossom(x + (hash01(seed + 11) - 0.5) * 28, y + hang, 13 + hash01(seed + 13) * 7, C(188, 70, 70), C(218, 165, 32), C(58, 32, 14), seed, 126, 5)
            if j % 2 == 0 then
                drawTinyBlossom(x + (hash01(seed + 17) - 0.5) * 42, y + hang + 20 + hash01(seed + 19) * 16, 9 + hash01(seed + 23) * 5, C(220, 112, 84), C(240, 210, 150), C(70, 35, 18), seed + 419, 86, 5)
            end
        end
    end
    for _, ch in ipairs(chimes) do
        for i = 1, 3 do
            local seed = ch.x * 0.013 + ch.y * 0.019 + i * 71
            local a = -math.pi * 0.5 + (i - 2) * 0.62
            local d = 28 + hash01(seed) * 16
            drawTinyBlossom(ch.x + math.cos(a) * d, ch.y + 18 + math.sin(a) * d * 0.45, 10 + hash01(seed + 3) * 5, C(188, 70, 70), C(218, 165, 32), C(58, 32, 14), seed + 811, 112, 5)
        end
    end
end

local function drawRoofsAndGears()
    for _, p in ipairs(pavilions) do
        local buildingH = p.layers * p.layerH
        drawRect(p.x - 18, p.y + 10, p.w + 36, buildingH - 8, 0, rgba(126, 98, 62, 34))
        drawStrokeRect(p.x - 18, p.y + 10, p.w + 36, buildingH - 8, 0, rgba(42, 32, 22, 42), 1.0)
        for i = 0, p.layers - 1 do
            local ly = p.y + i * p.layerH
            fillPoly({
                { p.x - 34, ly + 8 },
                { p.x + p.w * 0.50, ly - 22 },
                { p.x + p.w + 34, ly + 8 },
                { p.x + p.w + 18, ly + 20 },
                { p.x - 18, ly + 20 },
            }, rgba(42, 32, 22, 112))
            for j = 0, 8 do
                local tx = p.x - 18 + j * (p.w + 36) / 8
                drawDryBrushLine(tx, ly + 17, tx + p.w / 14, ly + 2, 0.9, C(224, 188, 118), 52, tx * 0.01 + ly, 1)
            end
            drawRect(p.x - 10, ly, p.w + 20, 10, 0, colorRGBA(currentLevel.ink, 232))
            drawStrokeRect(p.x - 10, ly, p.w + 20, 10, 0, rgba(22, 18, 15, 230), 2.5)
            drawInkBleed(p.x + p.w * 0.5, ly + 6, p.w * 0.45, 9, currentLevel.ink, 28, p.x * 0.01 + ly * 0.02, 3)
            for _, f in ipairs({ 0.20, 0.48, 0.76 }) do
                drawRect(p.x + p.w * f, ly + 10, 8, p.layerH - 10, 0, colorRGBA(currentLevel.ink, 198))
                drawStrokeRect(p.x + p.w * f, ly + 10, 8, p.layerH - 10, 0, rgba(22, 18, 15, 160), 1.2)
                drawDryBrushLine(p.x + p.w * f + 4, ly + 12, p.x + p.w * f + 4, ly + p.layerH - 10, 1.1, currentLevel.ink, 108, p.x * 0.012 + f * 100 + ly, 1)
            end
            for j = 0, 7 do
                local x = p.x + j * p.w / 7
                drawDryBrushLine(x, ly + 25, x + p.w / 9, ly + 10, 1, currentLevel.ink, 92, x * 0.01 + ly * 0.02, 1)
                if i < p.layers - 1 then
                    strokeLine(x, ly + p.layerH - 18, x + p.w / 12, ly + p.layerH - 4, 0.9, rgba(42, 32, 22, 70))
                end
            end
        end
    end
    for _, r in ipairs(roofs) do
        nvgBeginPath(vg)
        nvgMoveTo(vg, r.points[1].x, r.points[1].y)
        for _, p in ipairs(r.points) do nvgLineTo(vg, p.x, p.y) end
        nvgStrokeColor(vg, rgba(42, 32, 22, 120))
        nvgStrokeWidth(vg, 17)
        nvgStroke(vg)
        nvgBeginPath(vg)
        nvgMoveTo(vg, r.points[1].x, r.points[1].y)
        for _, p in ipairs(r.points) do nvgLineTo(vg, p.x, p.y) end
        nvgStrokeColor(vg, colorRGBA(currentLevel.ink, 240))
        nvgStrokeWidth(vg, 5)
        nvgStroke(vg)
        for i = 1, #r.points - 1, 2 do
            local p, q = r.points[i], r.points[i + 1]
            local a = math.atan2(q.y - p.y, q.x - p.x)
            drawDryBrushLine(p.x, p.y, p.x + math.cos(a + math.pi / 2) * 15, p.y + math.sin(a + math.pi / 2) * 15, 1.2, currentLevel.ink, 95, p.x * 0.01 + p.y * 0.01, 1)
        end
    end
    for _, gear in ipairs(gears) do
        nvgSave(vg)
        nvgTranslate(vg, gear.x, gear.y)
        nvgRotate(vg, gear.angle)
        drawCircle(0, 0, gear.radius, colorRGBA(currentLevel.ink, 95))
        drawCircle(0, 0, gear.radius - 22, colorRGB(currentLevel.paper))
        drawInkSpeckles(-gear.radius, -gear.radius, gear.radius * 2, gear.radius * 2, currentLevel.ink, 34, gear.x * 0.01 + gear.y * 0.01, 34)
        for i = 0, 15 do
            local a = i / 16 * math.pi * 2
            drawDryBrushLine(math.cos(a) * (gear.radius - 12), math.sin(a) * (gear.radius - 12), math.cos(a) * (gear.radius + gear.teethHeight), math.sin(a) * (gear.radius + gear.teethHeight), 7, currentLevel.ink, 198, gear.radius * 0.1 + i * 19, 2)
        end
        nvgRestore(vg)
    end
    for _, ch in ipairs(chimes) do
        nvgSave(vg)
        nvgTranslate(vg, ch.x, ch.y)
        nvgRotate(vg, ch.swayAngle)
        drawDryBrushLine(0, 0, 0, 24, 1.5, currentLevel.ink, 208, ch.x * 0.01 + ch.y * 0.01, 1)
        fillPoly({ { -10, 24 }, { -6, 10 }, { 6, 10 }, { 10, 24 }, { 0, 20 } }, colorRGBA(currentLevel.water, 225))
        fillPoly({ { -2, 22 }, { 2, 22 }, { 4, 38 }, { -4, 38 } }, rgba(188, 70, 70, 200))
        nvgRestore(vg)
    end
    for _, w in ipairs(windWaves) do
        local a = clamp(w.life / w.maxLife, 0, 1)
        nvgBeginPath(vg)
        nvgCircle(vg, w.x, w.y, w.r)
        nvgStrokeColor(vg, rgba(218, 165, 32, 150 * a))
        nvgStrokeWidth(vg, 2)
        nvgStroke(vg)
    end
end

local function drawCloudsAndCranes()
    for _, cp in ipairs(cloudPlatforms) do
        local cy = cp.y + math.sin(elapsed * 1.2 + cp.bob) * 8
        drawInkBleed(cp.x, cy, cp.rx * 0.65, cp.ry * 0.65, currentLevel.paper, 88, cp.x * 0.01 + cp.y * 0.017, 5)
        for i = 0, 6 do
            local k = i - 3
            drawEllipse(cp.x + k * cp.rx * 0.18, cy + math.sin(elapsed + i) * 5, cp.rx * (0.24 + hash01(i + cp.x) * 0.08), cp.ry * (0.62 + hash01(i + cp.y) * 0.25), colorRGBA(currentLevel.paper, 150))
        end
        drawDryBrushLine(cp.x - cp.rx, cy + cp.ry * 0.55, cp.x + cp.rx, cy + cp.ry * 0.55, 2.0, currentLevel.ink, 58, cp.x * 0.01 + cp.y * 0.01, 2)
        drawDryBrushLine(cp.x - cp.rx * 0.62, cy + cp.ry * 0.72, cp.x + cp.rx * 0.62, cy + cp.ry * 0.72, 1.0, C(190, 207, 198), 56, cp.x * 0.02 + cp.y * 0.01, 1)
    end
    for _, c in ipairs(cranes) do
        nvgSave(vg)
        nvgTranslate(vg, c.x, c.y)
        nvgRotate(vg, math.cos(c.theta) * 0.08)
        fillPoly({ { -32, 0 }, { -62, 14 }, { -32, -4 } }, colorRGBA(currentLevel.ink, 235))
        drawRotEllipse(-5, 0, 34, 12, 0, rgba(235, 240, 235, 215))
        strokeLine(18, -4, 65, -22, 2.2, colorRGBA(currentLevel.ink, 220))
        drawCircle(70, -24, 4, colorRGBA(currentLevel.ink, 220))
        nvgSave(vg)
        nvgTranslate(-5, -6)
        nvgRotate(c.wingAngle * 0.8 - 0.15)
        fillPoly({ { 0, 0 }, { -8, -54 }, { 18, -35 }, { 10, -8 } }, rgba(235, 240, 235, 205))
        nvgRestore(vg)
        nvgSave(vg)
        nvgTranslate(-3, 6)
        nvgRotate(-c.wingAngle * 0.75 + 0.2)
        fillPoly({ { 0, 0 }, { 4, 54 }, { 25, 28 }, { 10, 7 } }, rgba(235, 240, 235, 180))
        nvgRestore(vg)
        strokeLine(-30, 2, -75, 12, 1.2, colorRGBA(currentLevel.ink, 210))
        strokeLine(-28, -1, -72, 7, 1.2, colorRGBA(currentLevel.ink, 210))
        nvgRestore(vg)
    end
end

local function drawAttachment(x1, y1, x2, y2, nx, ny, width)
    if not x1 then return end
    strokeQuad(x1, y1, (x1 + x2) * 0.5 - (ny or -1) * 12, (y1 + y2) * 0.5 + (nx or 0) * 12, x2, y2, width or 4, rgba(22, 18, 14, 205))
    drawDryBrushLine(x1, y1, x2, y2, (width or 4) * 0.55, C(22, 18, 14), 125, x1 * 0.01 + y1 * 0.02, 2)
end

local function drawPineConeTarget(t, r)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 4)
    local ang = branchFacingAngle(t)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, ang)
    drawInkBleed(0, 0, r * 0.78, r * 1.10, C(75, 55, 40), 46, t.x * 0.013 + t.y * 0.017, 4)
    drawEllipse(0, 0, r * 0.85, r * 1.15, rgba(75, 55, 40, 245))
    nvgBeginPath(vg)
    nvgEllipse(vg, 0, 0, r * 0.85, r * 1.15)
    nvgStrokeColor(vg, rgba(12, 10, 8, 245))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
    for row = -2, 2 do
        for col = -1, 1 do
            local x = col * r * 0.28 + (row % 2) * r * 0.13
            local y = row * r * 0.25
            nvgBeginPath(vg)
            nvgArc(vg, x, y, 6, math.pi, 0, NVG_CW)
            nvgStrokeColor(vg, rgba(45, 30, 18, 210))
            nvgStrokeWidth(vg, 2)
            nvgStroke(vg)
        end
    end
    drawInkSpeckles(-r * 0.58, -r * 0.78, r * 1.16, r * 1.56, C(45, 30, 18), 110, t.x * 0.01 + t.y * 0.01, 16)
    nvgRestore(vg)
    if currentLevelIsInkLab and currentLevelIsInkLab() then drawInkLabPineConeAura(t, r) end
end

local function drawLeafTarget(t, r, fillColor)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 4.5)
    if t.attachX then
        for _, a in ipairs({ 0.5, 2.2, 3.8 }) do
            drawCircle(t.x + math.cos(a) * 8, t.y + math.sin(a) * 8, 5.5, rgba(10, 8, 5, 245))
        end
    end
    local tint = currentLevel.id == "peach" and C(240, 95, 120) or currentLevel.bloom
    drawInkBleed(t.x, t.y, r * 0.78, r * 0.58, tint, 42, t.x * 0.011 + t.y * 0.017, 4)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, branchFacingAngle(t))
    fillLeafBud(0, 0, r, fillColor, rgba(40, 10, 10, 80), rgba(235, 180, 45, 215))
    nvgRestore(vg)
    drawInkSpeckles(t.x - r * 0.45, t.y - r * 0.35, r * 0.90, r * 0.75, tint, 72, t.x * 0.02 + t.y * 0.01, 8)
end

local function drawCloudRuneTarget(t, r)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 4.5)
    drawInkBleed(t.x, t.y, r * 1.05, r * 0.82, C(224, 168, 38), 48, t.x * 0.013 + t.y * 0.019, 4)
    nvgBeginPath(vg)
    nvgMoveTo(vg, t.x, t.y - r)
    nvgBezierTo(vg, t.x + r * 1.2, t.y - r * 0.5, t.x + r * 0.6, t.y + r * 1.1, t.x, t.y + r)
    nvgBezierTo(vg, t.x - r * 0.6, t.y + r * 1.1, t.x - r * 1.2, t.y - r * 0.5, t.x, t.y - r)
    nvgClosePath(vg)
    nvgFillColor(vg, rgba(224, 168, 38, 238))
    nvgFill(vg)
    nvgStrokeColor(vg, rgba(42, 30, 8, 205))
    nvgStrokeWidth(vg, 2)
    nvgStroke(vg)
    strokeQuad(t.x - 8, t.y - 12, t.x + 8, t.y - 8, t.x - 6, t.y, 2, rgba(255, 255, 255, 215))
    strokeQuad(t.x - 6, t.y, t.x + 10, t.y + 12, t.x - 12, t.y + 14, 2, rgba(255, 255, 255, 215))
    drawInkSpeckles(t.x - r * 0.7, t.y - r * 0.7, r * 1.4, r * 1.4, C(42, 30, 8), 66, t.x * 0.02 + t.y * 0.01, 10)
end

function drawNeedleEnemyTarget(t, r, isHuangshan)
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, isHuangshan and 3.5 or 4)
    local seed = t.x * 0.017 + t.y * 0.013
    local pulse = 0.5 + math.sin(elapsed * 4.6 + t.pulse) * 0.5
    local hit = clamp((t.hitCooldown or 0) / 22, 0, 1)
    local bodyTint = isHuangshan and C(87, 61, 38) or C(75, 55, 40)
    local darkTint = isHuangshan and C(24, 17, 12) or C(18, 13, 9)
    local bodyR = r * (0.78 + pulse * 0.035 + hit * 0.06)
    drawInkBleed(t.x, t.y, bodyR * 0.92, bodyR * 1.08, bodyTint, 42 + pulse * 8 + hit * 22, seed + 29, 4)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, branchFacingAngle(t))
    nvgScale(vg, 1 + hit * 0.08, 1 - hit * 0.035)
    drawEllipse(0, 0, bodyR * 0.78, bodyR * 1.04, colorRGBA(bodyTint, 245))
    nvgBeginPath(vg)
    nvgEllipse(vg, 0, 0, bodyR * 0.78, bodyR * 1.04)
    nvgStrokeColor(vg, colorRGBA(darkTint, 228))
    nvgStrokeWidth(vg, 1.9 + hit * 0.8)
    nvgStroke(vg)
    for row = -2, 2 do
        for col = -1, 1 do
            local sx = col * bodyR * 0.25 + (row % 2) * bodyR * 0.11
            local sy = row * bodyR * 0.22
            nvgBeginPath(vg)
            nvgArc(vg, sx, sy, bodyR * 0.13, math.pi, 0, NVG_CW)
            nvgStrokeColor(vg, rgba(45, 30, 18, 190 + hit * 40))
            nvgStrokeWidth(vg, 1.65)
            nvgStroke(vg)
        end
    end
    for i = 0, 7 do
        local a = -math.pi * 0.5 + (i / 7 - 0.5) * math.pi * 0.82
        local len = bodyR * (0.42 + hash01(seed + i * 17) * 0.20 + hit * 0.10)
        strokeLine(math.cos(a) * bodyR * 0.28, math.sin(a) * bodyR * 0.45, math.cos(a) * len, math.sin(a) * len, 0.9, colorRGBA(darkTint, 136 + hit * 50))
    end
    drawDryBrushLine(-bodyR * 0.22, bodyR * 0.72, -bodyR * 0.36, bodyR * 1.08, 1.25, darkTint, 178, seed + 71, 1)
    drawDryBrushLine(bodyR * 0.22, bodyR * 0.72, bodyR * 0.36, bodyR * 1.08, 1.25, darkTint, 178, seed + 79, 1)
    local eyeX = bodyR * (0.18 + pulse * 0.025)
    drawCircle(eyeX, -bodyR * 0.15, bodyR * 0.09, colorRGB(currentLevel.paper))
    drawCircle(eyeX + bodyR * 0.02, -bodyR * 0.15, bodyR * 0.040, colorRGBA(darkTint, 245))
    nvgRestore(vg)
    if hit > 0.01 then
        drawInkSpeckles(t.x - r * 0.50, t.y - r * 0.55, r, r * 1.1, darkTint, 34 * hit, seed + 181, 8)
    end
end

local function drawMasterPlumBlossomGlyph(x, y, r, alpha)
    local a = alpha or 178
    local seed = x * 0.017 + y * 0.013
    nvgSave(vg)
    nvgTranslate(vg, x, y)
    nvgRotate(vg, hash01(seed) * math.pi * 2)
    for i = 0, 4 do
        local rot = i / 5 * math.pi * 2 + (hash01(seed + i * 11) - 0.5) * 0.22
        nvgSave(vg)
        nvgRotate(vg, rot)
        local len = r * (0.72 + hash01(seed + i * 17) * 0.18)
        local wid = r * (0.18 + hash01(seed + i * 23) * 0.05)
        fillPetalShape(len, wid, rgba(226, 207, 180, a * 0.82))
        drawDryBrushLine(0, r * 0.05, 0, len * 0.88, 0.7, C(80, 54, 44), a * 0.34, seed + i * 31, 1)
        nvgRestore(vg)
    end
    drawCircle(0, 0, r * 0.15, rgba(31, 22, 18, a))
    for i = 0, 8 do
        local rot = i / 9 * math.pi * 2
        strokeLine(0, 0, math.cos(rot) * r * 0.32, math.sin(rot) * r * 0.32, 0.9, rgba(42, 27, 21, a * 0.72))
    end
    nvgRestore(vg)
    drawInkSpeckles(x - r * 0.36, y - r * 0.36, r * 0.72, r * 0.72, C(36, 25, 21), 24, seed + 19, 6)
end

local function drawMasterPlumBudTarget(t, r)
    local seed = t.x * 0.017 + t.y * 0.013
    local pulse = 0.5 + math.sin(elapsed * 2.4 + t.pulse) * 0.5
    drawAttachment(t.attachX, t.attachY, t.x, t.y, t.normX, t.normY, 2.2)
    drawRotEllipse(t.x, t.y, r * (0.92 + pulse * 0.12), r * (0.62 + pulse * 0.08), (hash01(seed) - 0.5) * 0.5, rgba(226, 206, 178, 20 + pulse * 20))
    nvgBeginPath(vg)
    nvgCircle(vg, t.x, t.y, r * (0.58 + pulse * 0.08))
    nvgStrokeColor(vg, rgba(226, 206, 178, 58 + pulse * 48))
    nvgStrokeWidth(vg, 1.15)
    nvgStroke(vg)
    nvgSave(vg)
    nvgTranslate(vg, t.x, t.y)
    nvgRotate(vg, math.atan2(t.normY or -1, t.normX or 0) + math.pi * 0.5 + (hash01(seed) - 0.5) * 0.35)
    fillPetalShape(r * 0.44, r * 0.16, rgba(46, 33, 27, 188))
    drawDryBrushLine(0, r * 0.05, 0, r * 0.34, 0.8, C(228, 207, 176), 44, seed + 7, 1)
    nvgRestore(vg)
    drawCircle(t.x, t.y, r * 0.09, rgba(24, 18, 15, 205))
    drawInkSpeckles(t.x - r * 0.38, t.y - r * 0.38, r * 0.76, r * 0.76, C(30, 22, 18), 36, seed + 19, 7)
end

local function drawBambooBloom(b)
    local base = -math.pi * 0.5 + (hash01(b.x * 0.02) - 0.5)
    for i = 0, 6 do
        local a = base + (i - 3) * 0.38 + (hash01(b.y + i) - 0.5) * 0.18
        nvgSave(vg)
        nvgRotate(vg, a)
        fillPetalShape(50 + hash01(i * 9 + b.x) * 20, 8 + hash01(i * 11 + b.y) * 4, i % 2 == 0 and rgba(43, 89, 63, 232) or rgba(67, 106, 76, 218))
        drawDryBrushLine(0, 0, 0, 42 + hash01(i * 17 + b.x) * 18, 1.0, C(18, 45, 28), 82, b.x * 0.01 + i, 1)
        nvgRestore(vg)
    end
end

local function drawNeedleBloom(b, lenBase)
    local pulse = b.springPulse or 0
    lenBase = lenBase * (1 + pulse * 0.16)
    local spread = currentLevel.id == "huangshan" and 1.34 or 1.55
    local count = currentLevel.id == "huangshan" and 30 or 36
    local alpha = (currentLevel.id == "huangshan" and 170 or 188) + pulse * 38
    drawPineNeedleCluster(0, 0, 0, -1, lenBase * 1.55, count, spread, b.x * 0.011 + b.y * 0.017, alpha)
    drawPineNeedleCluster(-4, 2, -0.55, -0.83, lenBase * 1.18, math.floor(count * 0.72), spread * 0.78, b.x * 0.019 + 317, alpha * 0.74)
    drawPineNeedleCluster(4, 2, 0.55, -0.83, lenBase * 1.18, math.floor(count * 0.72), spread * 0.78, b.y * 0.017 + 619, alpha * 0.74)
    nvgBeginPath(vg)
    for i = 0, 33 do
        local a = -math.pi * 0.5 + (i / 33 - 0.5) * (math.pi * (currentLevel.id == "huangshan" and 0.95 or 1.08))
        local len = lenBase * 1.18 + hash01(b.x * 0.01 + i * 33) * 30
        nvgMoveTo(vg, 0, 0)
        nvgLineTo(vg, math.cos(a) * len, math.sin(a) * len * 0.76)
    end
    nvgStrokeColor(vg, currentLevel.id == "huangshan" and rgba(43, 89, 63, 235) or rgba(43, 89, 63, 230))
    nvgStrokeWidth(vg, currentLevel.id == "huangshan" and 2.1 or 1.9)
    nvgStroke(vg)
    drawInkBleed(0, 0, lenBase * 0.48, lenBase * 0.24, C(31, 82, 50), 46, b.x * 0.013 + b.y * 0.019, 4)
    drawCircle(0, 0, currentLevel.id == "huangshan" and 11 or 9, rgba(12, 15, 12, 245))
end

function drawNeedleCorpseScatter()
    if #needleCorpses == 0 then return end
    for i, n in ipairs(needleCorpses) do
        local sway = math.sin(elapsed * 0.7 + n.seed) * 0.018
        local a = n.angle + sway
        local ca, sa = math.cos(a), math.sin(a)
        local x1 = n.x - ca * n.len * 0.46
        local y1 = n.y - sa * n.len * 0.46
        local x2 = n.x + ca * n.len * 0.56
        local y2 = n.y + sa * n.len * 0.56
        local tint = n.kind == "huangshan" and C(28, 72, 50) or C(24, 58, 35)
        strokeLine(x1, y1, x2, y2, n.width, colorRGBA(i % 4 == 0 and tint or currentLevel.ink, n.alpha))
        if i % 5 == 0 then
            strokeLine(n.x, n.y, n.x + math.cos(a + 0.55) * n.len * 0.36, n.y + math.sin(a + 0.55) * n.len * 0.28, 0.7, colorRGBA(tint, n.alpha * 0.64))
        end
    end
end

local function drawFlowerBloom(b, palette)
    if palette.darkKnots then
        for _, a in ipairs({ 0.6, 2.2, 3.8 }) do
            drawCircle(math.cos(a) * 9, math.sin(a) * 9, 6, rgba(12, 10, 8, 245))
        end
    end
    local base = hash01(b.x * 0.03 + b.y * 0.01) * math.pi
    drawInkBleed(0, 0, palette.outerLen * 0.58, palette.outerLen * 0.42, currentLevel.bloom, 30, b.x * 0.017 + b.y * 0.013, 4)
    for i = 0, 4 do
        nvgSave(vg)
        nvgRotate(vg, base + i / 5 * math.pi * 2 + (hash01(i + b.x) - 0.5) * 0.15)
        fillPetalShape(palette.outerLen + hash01(i * 7 + b.y) * 8, palette.outerWidth + hash01(i * 13 + b.x) * 5, i % 2 == 0 and palette.outerA or palette.outerB)
        drawDryBrushLine(0, 4, 0, palette.outerLen * 0.70, 1.0, C(80, 18, 20), 66, b.x * 0.01 + i * 7, 1)
        nvgRestore(vg)
    end
    if palette.inner then
        for i = 0, 4 do
            nvgSave(vg)
            nvgRotate(vg, base + i / 5 * math.pi * 2 + 0.6)
            fillPetalShape(palette.innerLen + hash01(i * 17 + b.y) * 5, palette.innerWidth + hash01(i * 19 + b.x) * 4, palette.inner)
            drawDryBrushLine(0, 2, 0, palette.innerLen * 0.58, 0.8, C(110, 38, 44), 52, b.y * 0.01 + i * 11, 1)
            nvgRestore(vg)
        end
    end
    if palette.stamen then
        for i = 0, 13 do
            local a = i / 14 * math.pi * 2
            local len = palette.stamenLen + hash01(i * 23 + b.x) * 8
            strokeLine(0, 0, math.cos(a) * len, math.sin(a) * len, 1.4, rgba(42, 8, 8, 220))
            drawCircle(math.cos(a) * len, math.sin(a) * len, 2.6, rgba(224, 173, 43, 235))
        end
    end
end

local function drawTargets()
    for _, t in ipairs(targets) do
        if not t.dead then
            local r = t.r + math.sin(elapsed * 3 + t.pulse) * (currentLevel.id == "bamboo" and 2 or 3)
            if currentLevel.id == "bamboo" then
                drawInkBleed(t.x, t.y, r * 1.05, r * 0.72, currentLevel.wash, 54, t.x * 0.013 + t.y * 0.019, 5)
                strokeQuad(t.x, t.y, t.x - r, t.y + r * 0.5, t.x - r * 0.5, t.y + r, 3, rgba(40, 50, 45, 205))
                drawDryBrushLine(t.x, t.y, t.x - r * 0.5, t.y + r * 0.92, 1.1, currentLevel.ink, 98, t.x * 0.01 + t.y * 0.01, 1)
            elseif currentLevel.id == "pine" then
                drawNeedleEnemyTarget(t, r, false)
            elseif currentLevel.id == "huangshan" then
                drawNeedleEnemyTarget(t, r, true)
            elseif currentLevel.id == "plum_master" then
                drawMasterPlumBudTarget(t, r)
            elseif currentLevel.id == "peach" then
                drawLeafTarget(t, r, rgba(240, 95, 120, 245))
            elseif currentLevel.id == "eaves" then
                nvgSave(vg)
                nvgTranslate(vg, t.x, t.y)
                nvgRotate(vg, branchFacingAngle(t))
                fillLeafBud(0, 0, r, rgba(188, 70, 70, 238), rgba(40, 10, 10, 90), rgba(235, 180, 45, 220))
                nvgRestore(vg)
            else
                drawLeafTarget(t, r, colorRGBA(currentLevel.bloom, 245))
            end
        end
    end
    for _, b in ipairs(blooms) do
        if b.kind == "plum_master" then
            drawAttachment(b.attachX, b.attachY, b.x, b.y, b.normX, b.normY, 2.2)
            local t = clamp(b.progress, 0, 1)
            drawMasterPlumBlossomGlyph(b.x, b.y, (b.r or 24) * (0.62 + 0.38 * t), 90 + 95 * t)
            local seed = b.x * 0.011 + b.y * 0.019
            for i = 1, 2 do
                local a = hash01(seed + i * 17) * math.pi * 2
                local d = (b.r or 24) * (0.34 + hash01(seed + i * 23) * 0.34) * t
                local rr = (b.r or 24) * (0.40 + hash01(seed + i * 29) * 0.16) * (0.72 + 0.28 * t)
                drawMasterPlumBlossomGlyph(b.x + math.cos(a) * d, b.y + math.sin(a) * d, rr, 62 + 82 * t)
            end
            drawInkSpeckles(b.x - (b.r or 24), b.y - (b.r or 24), (b.r or 24) * 2, (b.r or 24) * 2, C(32, 24, 20), 28 * (1 - t), b.x * 0.01 + b.y * 0.013, 8)
        else
        if b.kind ~= "bamboo" then
            drawAttachment(b.attachX, b.attachY, b.x, b.y, b.normX, b.normY, b.kind == "pine" and 4 or 4.5)
        end
        nvgSave(vg)
        nvgTranslate(vg, b.x, b.y)
        if b.kind ~= "bamboo" then
            nvgRotate(vg, branchFacingAngle(b))
        end
        nvgScale(vg, b.scale, b.scale)
        if b.kind == "bamboo" then
            drawBambooBloom(b)
        elseif b.kind == "pine" or b.kind == "huangshan" then
            drawNeedleBloom(b, b.kind == "huangshan" and 52 or 46)
        elseif b.kind == "plum_master" then
            drawMasterPlumBlossomGlyph(0, 0, 24, 150)
        elseif b.kind == "peach" then
            drawFlowerBloom(b, {
                outerA = rgba(240, 95, 120, 245), outerB = rgba(210, 50, 80, 245),
                inner = rgba(255, 175, 185, 245), outerLen = 74, outerWidth = 48,
                innerLen = 45, innerWidth = 29, stamen = true, stamenLen = 34,
            })
            for i = 1, 4 do
                local seed = b.x * 0.017 + b.y * 0.013 + i * 79
                local a = hash01(seed) * math.pi * 2
                local d = 42 + hash01(seed + 3) * 42
                drawTinyBlossom(math.cos(a) * d, math.sin(a) * d * 0.74, 17 + hash01(seed + 7) * 9, C(240, 95, 120), C(255, 184, 196), C(95, 40, 52), seed, 122 + 38 * clamp(b.progress or 1, 0, 1), 5)
            end
        elseif b.kind == "eaves" then
            drawFlowerBloom(b, {
                outerA = rgba(188, 70, 70, 245), outerB = rgba(218, 165, 32, 245),
                inner = rgba(240, 220, 180, 245), outerLen = 58, outerWidth = 40,
                innerLen = 34, innerWidth = 23,
            })
            for i = 1, 3 do
                local seed = b.x * 0.015 + b.y * 0.011 + i * 89
                local a = hash01(seed) * math.pi * 2
                local d = 32 + hash01(seed + 5) * 28
                drawTinyBlossom(math.cos(a) * d, math.sin(a) * d * 0.76, 12 + hash01(seed + 9) * 7, C(188, 70, 70), C(218, 165, 32), C(58, 32, 14), seed + 211, 112 + 30 * clamp(b.progress or 1, 0, 1), 5)
            end
        else
            drawFlowerBloom(b, {
                outerA = rgba(195, 18, 18, 245), outerB = rgba(148, 10, 10, 245),
                inner = rgba(228, 45, 45, 245), outerLen = 44, outerWidth = 30,
                innerLen = 25, innerWidth = 18, stamen = true, stamenLen = 22,
                darkKnots = b.kind == "plum",
            })
        end
        nvgRestore(vg)
        end
    end
end

