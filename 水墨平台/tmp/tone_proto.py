from PIL import Image
import numpy as np
Image.MAX_IMAGE_PIXELS = None
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
img = Image.open(ROOT + r"\assets\reference\chen_rong_nine_dragons.jpg").convert("RGB")
# 取漩涡龙区域(q3 右段)做原型
crop = img.crop((20300, 0, 22600, 1116)).resize((1150, 558), Image.LANCZOS)
a = np.asarray(crop).astype(np.float32) / 255.0
L = a[..., 0]*0.299 + a[..., 1]*0.587 + a[..., 2]*0.114
bg = 0.72            # 绢底亮度
density = np.clip((bg - L) / (bg - 0.10), 0, 1)   # 墨密度 0..1

# 暗绢底色 / 调色
silk_dark = np.array([0.27, 0.255, 0.225])   # 暗绢
pale      = np.array([0.78, 0.74, 0.66])     # 淡米(亮笔触)
inkdeep   = np.array([0.06, 0.055, 0.05])

variants = {}
# A) 原画整体压暗:亮度线性映射 [0..bg] -> [0..0.33]
t = np.clip(L / bg, 0, 1)
va = (t[..., None] ** 1.1) * silk_dark[None, None, :] / 0.30 * 0.30
variants["A_darkened"] = va
# B) 完全反墨:密度越高越亮
d = density[..., None]
vb = silk_dark[None, None, :] * (1 - d) + pale[None, None, :] * (d ** 0.85)
variants["B_inverted"] = vb
# C) 软反差双调:云雾(中密度)微亮,浓墨线条最亮,留白=暗绢
dc = density ** 0.6
vc = silk_dark[None, None, :] + (pale - silk_dark)[None, None, :] * (dc[..., None] * 0.85)
variants["C_duotone"] = vc
# D) 暗化原画+保留墨层次:silk->暗绢,墨保持深,但给笔触边缘提亮(浮雕感)
vd = silk_dark[None, None, :] * (1 - d) + inkdeep[None, None, :] * d
gy, gx = np.gradient(density)
edge = np.clip(np.abs(gx) + np.abs(gy), 0, 0.25) / 0.25
vd = vd + (pale - vd) * (edge[..., None] ** 1.4) * 0.55
variants["D_edge_glow"] = vd

for k, v in variants.items():
    out = Image.fromarray((np.clip(v, 0, 1) * 255).astype(np.uint8))
    out.save(ROOT + rf"\tmp\tone_{k}.png")
    print(k, "saved")
