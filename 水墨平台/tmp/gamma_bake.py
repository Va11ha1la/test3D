from PIL import Image
import numpy as np, os
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
OUT = ROOT + r"\assets\ink_atlas\molong3d"
# 对全部素材 RGB 做 ^2.2 编码(alpha 不动);幂等保护:写标记文件
flag = OUT + r"\.gamma_baked"
if os.path.exists(flag):
    print("already baked, skip"); raise SystemExit
for f in os.listdir(OUT):
    if not f.endswith(".png"): continue
    p = os.path.join(OUT, f)
    im = Image.open(p)
    if im.mode == "RGBA":
        a = np.asarray(im).astype(np.float32) / 255.0
        a[..., :3] = a[..., :3] ** 2.2
        Image.fromarray((a * 255 + 0.5).astype(np.uint8)).save(p)
    else:
        a = np.asarray(im.convert("RGB")).astype(np.float32) / 255.0
        a = a ** 2.2
        Image.fromarray((a * 255 + 0.5).astype(np.uint8)).save(p)
    print("baked", f)
open(flag, "w").write("v1")
