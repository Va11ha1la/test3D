-- Rendering helpers for the LDtk grand-scroll bridge.

function ldtkVisible(x, y, w, h, pad)
    pad = pad or 160
    return x + w >= cameraX - pad and x <= cameraX + DESIGN_W + pad and y + h >= cameraY - pad and y <= cameraY + DESIGN_H + pad
end

function drawLDtkGrandScrollDecorWash()
    if not ldtkDecor then return end

    for _, r in ipairs(ldtkDecor) do
        if ldtkVisible(r.x, r.y, r.w, r.h, 220) then
            local cx, cy = r.x + r.w * 0.5, r.y + r.h * 0.5
            if r.v == 1 then
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(currentLevel.wash, 9))
                drawDryBrushLine(r.x, r.y + r.h * 0.28, r.x + r.w, r.y + r.h * 0.55, math.max(1.0, math.min(5.0, r.h * 0.16)), currentLevel.wash, 34, r.x * 0.017 + r.y * 0.011, 1)
            elseif r.v == 2 then
                drawInkBleed(cx, cy, math.max(28, r.w * 0.58), math.max(10, r.h * 1.8), currentLevel.paper, 34, r.x * 0.019 + r.y * 0.013, 2)
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(C(207, 215, 202), 10))
            elseif r.v == 3 then
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(currentLevel.water, 13))
                drawDryBrushLine(r.x, cy, r.x + r.w, cy + math.sin(r.x * 0.014) * 4, math.max(1.0, math.min(4.0, r.h * 0.22)), currentLevel.water, 45, r.x * 0.009 + r.y * 0.021, 1)
            elseif r.v == 4 then
                local x = cx + math.sin(r.y * 0.03) * 3
                drawDryBrushLine(x, r.y + r.h, x + math.sin(r.x * 0.02) * 8, r.y, math.max(1.2, math.min(4.2, r.w * 0.32)), currentLevel.accent, 58, r.x * 0.021 + r.y * 0.017, 1)
            elseif r.v == 5 then
                drawInkBleed(cx, cy, math.max(12, r.w * 1.7), math.max(8, r.h * 1.8), currentLevel.bloom, 24, r.x * 0.027 + r.y * 0.019, 2)
                drawRotEllipse(cx, cy, math.max(5, r.w * 0.62), math.max(3, r.h * 0.72), math.sin(cx * 0.01) * 0.8, colorRGBA(currentLevel.bloom, 62))
            elseif r.v == 6 then
                drawRect(r.x, r.y, r.w, r.h, 0, colorRGBA(currentLevel.ink, 22))
                drawDryBrushLine(r.x, r.y + r.h * 0.35, r.x + r.w, r.y + r.h * 0.56, math.max(1.0, math.min(6.0, r.h * 0.20)), currentLevel.ink, 74, r.x * 0.012 + r.y * 0.018, 1)
            end
        end
    end
end

function drawLDtkGrandScrollBackdrop()
    if not currentLevelIsLDtkGrandScroll() then return end
    drawVerticalWash(0, worldH, C(224, 231, 220), C(242, 235, 218), 54, 26, 28)
    drawMountainBandAt(1210, 7, C(92, 118, 102), 12, 0.20, 0.22, 0.18, 0.34, -220)
    drawMistBand(1220, 24, currentLevel.paper, 30, 0.08, 0.76, 160, 520, 18, 92)

    local bands = {
        { x = 0, w = 1550, tint = C(64, 106, 76), alpha = 14 },
        { x = 1550, w = 1500, tint = C(70, 88, 65), alpha = 12 },
        { x = 3050, w = 1400, tint = C(118, 150, 122), alpha = 12 },
        { x = 4450, w = 1500, tint = C(116, 82, 70), alpha = 13 },
        { x = 5950, w = 1600, tint = C(126, 98, 62), alpha = 13 },
        { x = 7550, w = 2050, tint = C(156, 180, 172), alpha = 16 },
    }
    for _, b in ipairs(bands) do
        if ldtkVisible(b.x, 0, b.w, worldH, 260) then
            drawRect(b.x, 0, b.w, worldH, 0, colorRGBA(b.tint, b.alpha))
            for i = 1, 6 do
                local x = b.x + hash01(b.x * 0.017 + i * 19) * b.w
                strokeLine(x, H(0.06), x + (hash01(i * 41 + b.x) - 0.5) * 220, H(0.86), 0.8, colorRGBA(b.tint, b.alpha * 1.8))
            end
        end
    end
    drawLDtkGrandScrollDecorWash()
end

function drawLDtkGrandScrollCollisionInk()
    if not currentLevelIsLDtkGrandScroll() then return end

    for _, r in ipairs(ldtkSolidRects) do
        if ldtkVisible(r.x, r.y, r.w, r.h, 80) then
            if r.y < worldH - 80 then
                local bodyAlpha = r.h > 70 and 8 or 3
                drawRect(r.x, r.y + math.max(6, r.h * 0.18), r.w, math.max(4, r.h * 0.70), 0, colorRGBA(currentLevel.ink, bodyAlpha))
                drawDryBrushLine(r.x, r.y + 1, r.x + r.w, r.y + math.sin(r.x * 0.01) * 3, math.max(1.0, math.min(3.0, r.h * 0.06)), currentLevel.ink, 42, r.x * 0.011 + r.y * 0.013, 1)
                if r.w > 42 and r.h > 18 then
                    drawDryBrushLine(r.x + 4, r.y + r.h * 0.48, r.x + r.w - 4, r.y + r.h * 0.45 + math.sin(r.y * 0.014) * 2, 0.65, currentLevel.paper, 18, r.x * 0.017, 1)
                end
            end
        end
    end

    for _, r in ipairs(ldtkOneWayRects) do
        if ldtkVisible(r.x, r.y, r.w, r.h, 80) then
            drawDryBrushLine(r.x, r.y + 2, r.x + r.w, r.y + math.sin(r.x * 0.02) * 4, math.max(1.4, math.min(3.8, r.h * 0.10)), currentLevel.accent, 58, r.x * 0.019 + r.y * 0.007, 1)
            drawDryBrushLine(r.x + 8, r.y + r.h * 0.45, r.x + r.w - 8, r.y + r.h * 0.42, 0.7, currentLevel.ink, 20, r.x * 0.013, 1)
        end
    end
end

function drawLDtkGrandScrollWaterAndPetals()
    if not currentLevelIsLDtkGrandScroll() then return end

    for _, fall in ipairs(ldtkWaterfalls) do
        if ldtkVisible(fall.x, fall.y, fall.w, fall.h, 220) then
            local cx = fall.x + fall.w * 0.45
            drawRect(fall.x, fall.y - 120, fall.w, fall.h + 180, 0, colorRGBA(currentLevel.paper, 24))
            for i = 1, 18 do
                local x = fall.x + hash01(i * 23 + fall.x) * fall.w
                local y1 = fall.y - 120 + hash01(i * 29 + fall.y) * 110
                local y2 = fall.y + fall.h + hash01(i * 31 + fall.x) * 120
                drawDryBrushLine(x, y1, x + math.sin(elapsed * 1.6 + i) * 20, y2, 1.2 + hash01(i * 37) * 4.2, currentLevel.paper, 84 + hash01(i * 41) * 72, i * 47 + fall.x, 2)
            end
            drawInkBleed(cx, fall.y + fall.h * 0.86, fall.w * 0.42, 38, currentLevel.water, 26, fall.x * 0.013 + fall.y * 0.019, 4)
        end
    end

    for _, p in ipairs(floatingPetals) do
        local y = p.y + math.sin(p.bob) * 4
        if ldtkVisible(p.x - p.w, y - p.h, p.w * 2, p.h * 2, 80) then
            nvgSave(vg)
            nvgTranslate(vg, p.x, y)
            nvgRotate(vg, math.sin(p.bob) * 0.16)
            fillPetalShape(p.w * 0.55, p.h * 0.70, colorRGBA(currentLevel.bloom, 170))
            nvgRestore(vg)
            drawDryBrushLine(p.x - p.w * 0.12, y + p.h * 0.10, p.x + p.w * 0.16, y + p.h * 0.46, 0.85, C(96, 55, 70), 48, p.x * 0.017 + p.y * 0.013, 1)
        end
    end
end

function drawLDtkGrandScrollLabels()
    if not currentLevelIsLDtkGrandScroll() then return end

    for _, label in ipairs(ldtkLabels) do
        if ldtkVisible(label.x, label.y, 260, 40, 120) then
            drawText(label.x, label.y, 18, colorRGBA(currentLevel.ink, 150), label.text)
            strokeLine(label.x, label.y + 26, label.x + 210, label.y + 26, 1.1, colorRGBA(currentLevel.ink, 72))
        end
    end

    for _, cp in ipairs(ldtkCheckpoints) do
        if ldtkVisible(cp.x - 20, cp.y - 36, 40, 72, 80) then
            drawDryBrushLine(cp.x, cp.y + 30, cp.x, cp.y - 30, 2.0, currentLevel.accent, 140, cp.x * 0.013, 1)
            drawRect(cp.x - 13, cp.y - 36, 26, 18, 0, rgba(150, 35, 30, 155))
        end
    end

    if ldtkExit and ldtkVisible(ldtkExit.x - 70, ldtkExit.y - 120, 160, 220, 160) then
        drawRect(ldtkExit.x - 18, ldtkExit.y - 58, 48, 92, 0, rgba(150, 35, 30, 128))
        drawStrokeRect(ldtkExit.x - 18, ldtkExit.y - 58, 48, 92, 0, rgba(35, 20, 16, 196), 2)
        drawDryBrushLine(ldtkExit.x - 62, ldtkExit.y + 36, ldtkExit.x + 88, ldtkExit.y + 36, 5, currentLevel.ink, 128, ldtkExit.x * 0.01, 2)
    end
end
