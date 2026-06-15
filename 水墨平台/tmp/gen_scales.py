# -*- coding: utf-8 -*-
# 水墨龙鳞贴图(无缝平铺):u 环向(0=背脊, 0.5=腹中), v 沿身
# 背/侧 = 鲤鱼鳞弧片;腹带 u 0.40-0.60 = 横纹腹甲
from PIL import Image, ImageDraw, ImageFilter
import numpy as np, random, math
random.seed(7)
S = 512
img = Image.new("RGB", (S, S), (200, 192, 172))
d = ImageDraw.Draw(img)

def wrap_arc(box, start, end, fill, width):
    for ox in (-S, 0, S):
        for oy in (-S, 0, S):
            b = [box[0]+ox, box[1]+oy, box[2]+ox, box[3]+oy]
            d.arc(b, start, end, fill=fill, width=width)

# 鳞片:行高16,宽32,半错排;弧口朝 -v(朝尾叠瓦)
ROW, W = 16, 32
for row in range(S // ROW):
    y = row * ROW
    off = (W // 2) if row % 2 else 0
    for col in range(S // W + 1):
        x = col * W + off
        u_center = ((x + W/2) % S) / S
        if 0.385 < u_center < 0.615:   # 腹带区跳过
            continue
        jit = random.randint(-14, 10)
        base = 52 + jit
        # 鳞弧(下半圆,开口朝上=朝头,叠瓦感)
        wrap_arc([x - W*0.55, y - ROW*0.9, x + W*0.55, y + ROW*1.1], 20, 160,
                 (base, base-4, base-8), 3)
        # 鳞内淡墨晕
        wrap_arc([x - W*0.40, y - ROW*0.5, x + W*0.40, y + ROW*0.95], 30, 150,
                 (150+jit, 144+jit, 128+jit), 5)

# 腹甲横纹带
x0, x1 = int(0.40*S), int(0.60*S)
d.rectangle([x0, 0, x1, S], fill=(214, 206, 186))
for k in range(S // 18):
    y = k * 18
    d.line([(x0, y), (x1, y)], fill=(70, 64, 55), width=3)
    d.line([(x0, y+4), (x1, y+4)], fill=(176, 168, 150), width=2)
# 腹带边界双勾线
for xx in (x0, x1):
    d.line([(xx, 0), (xx, S)], fill=(60, 55, 48), width=3)
    d.line([(xx + (3 if xx==x0 else -3), 0), (xx + (3 if xx==x0 else -3), S)], fill=(150, 143, 128), width=2)

img = img.filter(ImageFilter.GaussianBlur(0.6))
# 整体墨色杂噪
a = np.asarray(img).astype(np.float32) / 255.0
noise = np.random.RandomState(3).normal(0, 0.025, (S, S, 1)).astype(np.float32)
a = np.clip(a + noise, 0, 1)
# gamma 预编码(与 molong3d 资产一致)
a = a ** 2.2
out = Image.fromarray((a * 255 + 0.5).astype(np.uint8))
out.save(r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\assets\ink_atlas\molong3d\dragon_scales.png")
# 预览(未编码版)
prev = Image.fromarray((np.clip((a ** (1/2.2)), 0, 1) * 255).astype(np.uint8))
prev.save(r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\scales_preview.png")
print("scales texture ok")
