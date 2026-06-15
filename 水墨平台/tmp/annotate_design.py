# -*- coding: utf-8 -*-
# 在 18 关全景截图上标注交互点设计提案(讨论用例图,不改游戏)
from PIL import Image, ImageDraw, ImageFont

SRC = r"C:\Users\202102-91\AppData\Roaming\xdt-maker\cc-agent\images\xn5bmf4kvt17ucgz8y9gg0js\94b67189-ee0c-46cb-bde1-029943051d59-1781172524916.png"
OUT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\design_l18_proposal.png"

im = Image.open(SRC).convert("RGB")
S = 2
im = im.resize((im.width * S, im.height * S), Image.LANCZOS)
dr = ImageDraw.Draw(im, "RGBA")
F  = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 22)
Fs = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 17)
Fb = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 26)

def P(x, y):  # 原图坐标 -> 放大坐标
    return x * S, y * S

def mark(x, y, r, color, label=None, ly=-1, dash=False):
    x, y = P(x, y)
    if dash:
        import math
        n = 28
        for i in range(n):
            if i % 2: continue
            a0 = i / n * 6.2832; a1 = (i + 0.9) / n * 6.2832
            dr.arc([x - r, y - r, x + r, y + r], a0 * 57.3, a1 * 57.3, fill=color, width=3)
    else:
        dr.ellipse([x - r, y - r, x + r, y + r], outline=color, width=4)
        dr.ellipse([x - 4, y - 4, x + 4, y + 4], fill=color)
    if label:
        tw = dr.textlength(label, font=Fs)
        tx, ty = x - tw / 2, y + (r + 6 if ly > 0 else -r - 28)
        dr.rectangle([tx - 5, ty - 3, tx + tw + 5, ty + 24], fill=(250, 247, 238, 215))
        dr.text((tx, ty), label, font=Fs, fill=color)

def arc_bridge(x1, y1, x2, y2, color, label):
    import math
    pts = []
    for i in range(25):
        t = i / 24
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t - math.sin(t * math.pi) * 26
        pts.append(P(x, y))
    for i in range(0, 24, 2):
        dr.line([pts[i], pts[i + 1]], fill=color, width=4)
    mx, my = pts[12]
    tw = dr.textlength(label, font=Fs)
    dr.rectangle([mx - tw/2 - 5, my - 56, mx + tw/2 + 5, my - 30], fill=(250, 247, 238, 215))
    dr.text((mx - tw/2, my - 54), label, font=Fs, fill=color)

GREEN = (46, 110, 60, 255)    # 竹梢风袂
RED   = (168, 32, 54, 255)    # 梅枝点苞
PINK  = (196, 84, 110, 255)   # 花开生桥
BLUE  = (58, 92, 128, 255)    # 墨池涟漪
GRAY  = (110, 105, 92, 255)   # 兰丛(土坡限定)
GOLD  = (146, 110, 38, 255)   # 题跋拾字

# ---- 第一幕|起:左侧竹林(教学:竹梢风袂) ----
mark( 97,  62, 16, GREEN, "竹梢·风袂①")
mark(270,  52, 16, GREEN, "竹梢·风袂②")
mark(150, 196, 14, BLUE,  "墨池涟漪", ly=1)
mark(205, 168, 12, GRAY,  "兰丛(灰土坡限定)", ly=1)

# ---- 第二幕|承:中段断崖(花开生桥) ----
mark(388,  68, 16, GREEN, "竹梢·风袂③")
arc_bridge(462, 118, 540, 142, PINK, "花开生桥(苞→枝桥 5s)")
mark(462, 118, 12, PINK)
mark(620, 208, 14, BLUE,  "墨池涟漪", ly=1)

# ---- 第三幕|转:中右浮阶(收集计数 + 题跋字) ----
mark(560, 140, 12, GOLD, "拾字「疏」", ly=1)
mark(655, 116, 12, GOLD, "拾字「影」")

# ---- 第四幕|合:右侧梅树(点苞连锁 → 终幕) ----
for i, (x, y) in enumerate([(668, 184), (724, 158), (768, 128), (800, 106)]):
    mark(x, y, 13, RED, "梅枝·点苞%d" % (i + 1) if i in (0, 3) else None)
mark(845,  72, 16, GREEN, "竹梢·风袂④(终)")

# ---- 幕分隔虚线 ----
for bx, t in [(330, "起|竹林教学"), (505, "承|断崖生桥"), (700, "转|浮阶拾字"), (935, "合|梅梢点苞")]:
    x, _ = P(bx, 0)
    if bx < 930:
        for yy in range(34 * S, 228 * S, 14):
            dr.line([(x, yy), (x, yy + 7)], fill=(90, 86, 78, 130), width=2)
    tw = dr.textlength(t, font=F)
    dr.rectangle([x - tw - 16, 36 * S, x - 6, 36 * S + 30], fill=(250, 247, 238, 225))
    dr.text((x - tw - 11, 36 * S + 2), t, font=F, fill=(70, 66, 58))

# ---- 图例 ----
lg = [(GREEN, "竹梢风袂:上升气流+刷新冲刺(只长在竹竿顶)"),
      (PINK,  "花开生桥:触苞 5 秒长出枝桥,过断崖"),
      (RED,   "梅枝点苞:连锁开花,集满开终点(只长在梅枝梢)"),
      (GOLD,  "拾字:收集题跋文字,终幕画卷补全落款"),
      (BLUE,  "墨池涟漪:黑地面专属,入水墨晕+短滑步"),
      (GRAY,  "兰丛:仅灰绿土坡,纯景观呼吸感")]
y0 = im.height - len(lg) * 30 - 14
dr.rectangle([10, y0 - 8, 560, im.height - 8], fill=(250, 247, 238, 232))
for i, (c, t) in enumerate(lg):
    yy = y0 + i * 30
    dr.ellipse([20, yy + 4, 38, yy + 22], outline=c, width=4)
    dr.text((48, yy), t, font=Fs, fill=(60, 56, 50))
dr.text((14, 10), "第18关·水墨竹梅|交互点重布提案(例图)", font=Fb, fill=(60, 56, 50))

im.save(OUT)
print("saved", OUT, im.size)
