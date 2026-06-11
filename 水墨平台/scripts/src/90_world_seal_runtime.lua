-- Source chunk from original scripts/main.lua. Runtime bundle keeps chunks in filename order.
local function drawWorld()
    if currentLevel.trace then
        drawTraceWorld()
        return
    end
    drawPaper()
    drawBackground()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollBackdrop() end
    drawPoetry()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollCollisionInk() end
    if currentLevel.id == "bamboo" then
        drawBamboo()
    else
        drawBranches()
        if currentLevelIsLDtkGrandScroll() then drawBamboo() end
    end
    drawLeavesAndPetals()
    drawRopes()
    drawRoofsAndGears()
    drawCloudsAndCranes()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollWaterAndPetals() end
    drawNeedleCorpseScatter()
    drawTargets()
    if currentLevelIsLDtkGrandScroll() then drawLDtkGrandScrollLabels() end
    drawParticles()
    drawPlayer()
    if showDebug then
        drawStrokeRect(cameraX, cameraY, DESIGN_W, DESIGN_H, 0, rgba(255, 255, 0, 120), 2)
        drawCircle(player.x, player.y, player.radius + 2, rgba(70, 210, 255, 140))
    end
end

function enterSealView()
    showSeal = true
    showHelp = false
    sealViewProgress = 0
    sealStampProgress = 0
    completionSealDelay = 0
    player.isDashing = false
    dashJustPressed = false
    keys.a = false
    keys.d = false
    keys.w = false
    keys.s = false
    keys.space = false
    keys.shift = false
end

function exitSealView()
    showSeal = false
    sealViewProgress = 0
    sealStampProgress = 0
    completionSealDelay = 0
end

function sealInfoForCurrentLevel()
    if currentLevel.id == "bamboo" then
        return { x = 0.94, y = 0.65, size = 100, primaryA = "风竹", primaryB = "傲骨", paper = C(232, 238, 230), wear = 60 }
    elseif currentLevel.id == "pine" then
        return { x = 0.94, y = 0.45, size = 130, primaryA = "听泉", primaryB = "破境", vertical = "清气乾坤", paper = C(242, 230, 207), wear = 80 }
    elseif currentLevel.id == "peach" then
        return { x = 0.94, y = 0.45, size = 130, primaryA = "春水", primaryB = "破境", vertical = "春江水暖", paper = C(236, 241, 226), wear = 80 }
    elseif currentLevel.id == "eaves" then
        return { x = 0.94, y = 0.45, size = 130, primaryA = "古阁", primaryB = "飞檐", vertical = "古阁金秋", paper = C(239, 230, 213), wear = 80 }
    elseif currentLevel.id == "plum_finale" then
        return { x = 0.94, y = 0.88, size = 110, primaryA = "双清", primaryB = "梅卷", vertical = "梅竹双清", paper = C(214, 190, 152), wear = 80 }
    elseif currentLevel.id == "wentong_zhu" then
        return { x = 0.06, y = 0.85, size = 110, primaryA = "与可", primaryB = "倒垂", vertical = "胸有成竹", paper = C(172, 140, 86), wear = 90 }
    elseif currentLevel.id == "plum_xiyan" then
        return { x = 0.06, y = 0.80, size = 110, primaryA = "洗砚", primaryB = "清气", vertical = "淡墨痕", paper = C(206, 202, 192), wear = 80 }
    elseif currentLevel.id == "molong" then
        return { x = 0.03, y = 0.08, size = 110, primaryA = "九龙", primaryB = "行雨", vertical = "神龙见首", paper = C(166, 158, 140), wear = 90 }
    elseif currentLevel.id == "xuwei_grape" then
        return { x = 0.80, y = 0.88, size = 110, primaryA = "青藤", primaryB = "明珠", vertical = "笔底明珠", paper = C(214, 202, 176), wear = 90 }
    else
        return { x = 0.94, y = 0.45, size = 130, primaryA = "弄梅", primaryB = "破境", vertical = "清气乾坤", paper = C(246, 237, 225), wear = 80 }
    end
end

function drawSealWear(x, y, w, h, seed, count, maxRadius, alpha, paper)
    paper = paper or currentLevel.paper
    for i = 1, count do
        local px = x + hash01(seed + i * 17.31) * w
        local py = y + hash01(seed + i * 23.17) * h
        local r = 0.7 + hash01(seed + i * 29.41) * maxRadius
        drawCircle(px, py, r, rgba(paper[1], paper[2], paper[3], 230 * alpha))
    end
end

function drawVerticalSealText(text, x, y, size, gap, color)
    local chars = utf8Chars(text)
    for i = 1, #chars do
        drawText(x, y + (i - 1) * gap, size, color, chars[i], NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
end

function drawSealImpression(alpha)
    if alpha <= 0 then return end
    local info = sealInfoForCurrentLevel()
    local stampX = worldW * info.x
    local stampY = worldH * info.y
    local size = info.size
    local red = rgba(181, 28, 28, 235 * alpha)
    local paper = info.paper or currentLevel.paper
    local paperInk = rgba(paper[1], paper[2], paper[3], 245 * alpha)

    drawRect(stampX, stampY, size, size, 0, red)
    drawStrokeRect(stampX, stampY, size, size, 0, rgba(120, 10, 10, 115 * alpha), 4)
    drawText(stampX + size * 0.5, stampY + size * 0.20, size * 0.32, paperInk, info.primaryA, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    drawText(stampX + size * 0.5, stampY + size * 0.62, size * 0.32, paperInk, info.primaryB, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)

    if info.vertical then
        local stamp2X = stampX - 160
        local stamp2Y = stampY + 120
        drawStrokeRect(stamp2X, stamp2Y, 110, 240, 0, red, 8)
        drawVerticalSealText(info.vertical, stamp2X + 55, stamp2Y + 26, 32, 50, red)
        drawSealWear(stamp2X, stamp2Y, 110, 240, worldW * 0.012 + worldH * 0.019 + 91, info.wear, 3, alpha, paper)
    end

    drawSealWear(stampX, stampY, size, size, worldW * 0.013 + worldH * 0.017 + 37, info.wear, size == 100 and 2 or 3, alpha, paper)
end

function drawSealGallery()
    local p = clamp(sealViewProgress, 0, 1)
    local ease = p * p * (3 - 2 * p)
    local finalScale = math.min(DESIGN_W / worldW, DESIGN_H / worldH) * 0.82
    local finalX = (DESIGN_W - worldW * finalScale) * 0.5
    local finalY = (DESIGN_H - worldH * finalScale) * 0.5
    local tx = -cameraX + (finalX + cameraX) * ease
    local ty = -cameraY + (finalY + cameraY) * ease
    local scale = 1 + (finalScale - 1) * ease
    local frameA = ease * ease
    local framePad = 24
    local frameX = tx - framePad
    local frameY = ty - framePad
    local frameW = worldW * scale + framePad * 2
    local frameH = worldH * scale + framePad * 2

    drawRect(0, 0, DESIGN_W, DESIGN_H, 0, rgba(8, 7, 6, 250))
    for i = 1, 18 do
        local bandA = 12 + i * 3
        drawRect(0, (i - 1) * DESIGN_H / 18, DESIGN_W, DESIGN_H / 18 + 2, 0, rgba(32, 24, 18, bandA * frameA))
    end

    if frameA > 0.02 then
        drawRect(frameX - 6, frameY - 6, frameW + 12, frameH + 12, 0, rgba(20, 13, 8, 230 * frameA))
        drawRect(frameX, frameY, frameW, frameH, 0, currentLevel.id == "bamboo" and rgba(36, 48, 39, 235 * frameA) or rgba(60, 42, 26, 235 * frameA))
        drawStrokeRect(frameX, frameY, frameW, frameH, 0, rgba(12, 8, 5, 245 * frameA), 6)
    end

    nvgSave(vg)
    nvgTranslate(vg, tx, ty)
    nvgScale(vg, scale, scale)
    drawWorld()
    drawSealImpression(clamp((sealStampProgress - 0.76) / 0.20, 0, 1))
    nvgRestore(vg)

    if p >= 0.98 then
        drawText(DESIGN_W * 0.5, DESIGN_H - 34, 13, rgba(230, 214, 190, 150), "F 退出雅鉴    Q/E 换卷", NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
end

local function drawHud()
    local state = "air"
    if player.isDashing then state = "dash"
    elseif player.onEaves then state = "eaves"
    elseif player.swingRope then state = "rope"
    elseif player.ridingCrane then state = "crane"
    elseif player.isWallClinging then state = "wall"
    elseif player.isGrounded then state = "ground" end
    local h = showHelp and 184 or 88
    drawRect(18, 18, 720, h, 4, rgba(8, 12, 10, 188))
    drawStrokeRect(18, 18, 720, h, 4, colorRGBA(currentLevel.accent, 170), 2)
    drawText(40, 34, 25, rgba(250, 250, 246, 240), string.format("%d/%d  %s", currentLevelIdx, #LEVELS, currentLevel.name))
    drawText(40, 66, 14, rgba(220, 226, 218, 225), currentLevel.title)
    drawText(40, 92, 13, rgba(210, 220, 210, 220), string.format("state %s  dash %s  blooms %d/%d", state, player.canDash and "ready" or "used", collectedCount, #targets))
    if showHelp then
        drawText(40, 120, 13, rgba(205, 216, 204, 220), "A/D or Arrows: move    Space/W/Up: jump    J: 8-way dash    S/Down: dash downward")
        drawText(40, 142, 13, rgba(205, 216, 204, 220), "Q/E or 1-9/0: switch scroll    C: debug nodes    F: seal    R: reload")
        drawText(40, 164, 13, rgba(178, 194, 178, 220), currentLevel.note)
    end
    if completionTimer > 0 then
        drawRect(DESIGN_W - 182, 36, 112, 112, 2, rgba(150, 20, 18, 215))
        drawStrokeRect(DESIGN_W - 182, 36, 112, 112, 2, rgba(245, 230, 205, 220), 3)
        drawText(DESIGN_W - 126, 68, 46, rgba(245, 230, 205, 235), currentLevel.seal, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        drawText(DESIGN_W - 126, 124, 13, rgba(245, 230, 205, 220), "落款", NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
end

local function loadDefaultFont()
    local fontId = nvgCreateFont(vg, "sans", "Fonts/MiSans-Regular.ttf")
    if fontId < 0 then fontId = nvgCreateFont(vg, "sans", "Fonts/Anonymous Pro.ttf") end
    fontReady = fontId >= 0
    if not fontReady then print("WARNING: failed to load NanoVG font") end
end

function Start()
    print("=== Faithful ink HTML port start ===")
    vg = nvgCreate(1)
    if vg == nil then
        print("ERROR: failed to create NanoVG")
        return
    end
    loadDefaultFont()
    loadLevel(1)
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent(vg, "NanoVGRender", "HandleNanoVGRender")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("KeyUp", "HandleKeyUp")
end

function Stop()
end

function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    if dt > 0.05 then dt = 0.05 end
    accumulator = accumulator + dt
    while accumulator >= FIXED_DT do
        if showSeal then
            sealViewProgress = math.min(1, sealViewProgress + FIXED_DT / 3.8)
            sealStampProgress = math.min(1, sealStampProgress + FIXED_DT / 3.8)
        else
            fixedStep()
            updateParticles()
            updateCamera()
            if completionSealDelay > 0 then
                completionSealDelay = completionSealDelay - FIXED_DT
                if completionSealDelay <= 0 then
                    local ready = true
                    for _, b in ipairs(blooms) do
                        if (b.progress or 1) < 0.98 then
                            ready = false
                            break
                        end
                    end
                    if ready then
                        completionSealDelay = 0
                        enterSealView()
                    else
                        completionSealDelay = FIXED_DT
                    end
                end
            end
            if completionTimer > 0 then completionTimer = completionTimer - FIXED_DT end
        end
        accumulator = accumulator - FIXED_DT
    end
end

function setKeyState(key, value)
    if keyMatches(key, leftKeys) then keys.a = value end
    if keyMatches(key, rightKeys) then keys.d = value end
    if keyMatches(key, upKeys) then keys.w = value end
    if keyMatches(key, downKeys) then keys.s = value end
    if keyMatches(key, jumpKeys) or keyMatches(key, upKeys) then
        if value and not keys.space then keys.space = true elseif not value and keyMatches(key, jumpKeys) then keys.space = false end
    end
end

function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    if showSeal then
        if keyMatches(key, sealKeys) then
            exitSealView()
        elseif keyMatches(key, resetKeys) then
            loadLevel(currentLevelIdx)
        elseif keyMatches(key, prevKeys) then
            loadLevel(currentLevelIdx - 1)
        elseif keyMatches(key, nextKeys) then
            loadLevel(currentLevelIdx + 1)
        elseif KEY_ESCAPE and key == KEY_ESCAPE and engine ~= nil then
            engine:Exit()
        else
            if #LEVELS >= 10 and (key == string.byte("0") or (_G["KEY_0"] and key == _G["KEY_0"])) then
                loadLevel(10)
                return
            end
            for i = 1, #LEVELS do
                if key == string.byte(tostring(i)) or (_G["KEY_" .. tostring(i)] and key == _G["KEY_" .. tostring(i)]) then
                    loadLevel(i)
                    break
                end
            end
        end
        return
    end
    setKeyState(key, true)
    if keyMatches(key, dashKeys) then
        if not keys.shift then dashJustPressed = true end
        keys.shift = true
    elseif keyMatches(key, debugKeys) then
        showDebug = not showDebug
    elseif keyMatches(key, helpKeys) then
        showHelp = not showHelp
    elseif keyMatches(key, resetKeys) then
        loadLevel(currentLevelIdx)
    elseif keyMatches(key, prevKeys) then
        loadLevel(currentLevelIdx - 1)
    elseif keyMatches(key, nextKeys) then
        loadLevel(currentLevelIdx + 1)
    elseif keyMatches(key, sealKeys) then
        enterSealView()
    elseif KEY_ESCAPE and key == KEY_ESCAPE and engine ~= nil then
        engine:Exit()
    else
        if #LEVELS >= 10 and (key == string.byte("0") or (_G["KEY_0"] and key == _G["KEY_0"])) then
            loadLevel(10)
            return
        end
        for i = 1, #LEVELS do
            if key == string.byte(tostring(i)) or (_G["KEY_" .. tostring(i)] and key == _G["KEY_" .. tostring(i)]) then
                loadLevel(i)
                break
            end
        end
    end
end

function HandleKeyUp(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    setKeyState(key, false)
    if keyMatches(key, dashKeys) then keys.shift = false end
end

function HandleNanoVGRender(eventType, eventData)
    local physW = graphics:GetWidth()
    local physH = graphics:GetHeight()
    local dpr = graphics:GetDPR()
    screenW = physW / dpr
    screenH = physH / dpr

    nvgBeginFrame(vg, screenW, screenH, dpr)
    if currentLevel and currentLevel.backdrop then
        drawRect(0, 0, screenW, screenH, 0, colorRGB(currentLevel.backdrop))
    else
        drawRect(0, 0, screenW, screenH, 0, rgba(0, 0, 0, 255))
    end

    fitScale = math.min(screenW / DESIGN_W, screenH / DESIGN_H)
    local renderW = DESIGN_W * fitScale
    local renderH = DESIGN_H * fitScale
    viewX = (screenW - renderW) * 0.5
    viewY = (screenH - renderH) * 0.5

    nvgSave(vg)
    nvgTranslate(vg, viewX, viewY)
    nvgScale(vg, fitScale, fitScale)
    nvgScissor(vg, 0, 0, DESIGN_W, DESIGN_H)
    if showSeal then
        drawSealGallery()
    else
        nvgSave(vg)
        nvgTranslate(vg, -cameraX, -cameraY)
        drawWorld()
        nvgRestore(vg)
        drawHud()
    end
    nvgResetScissor(vg)
    nvgRestore(vg)
    nvgEndFrame(vg)
end
