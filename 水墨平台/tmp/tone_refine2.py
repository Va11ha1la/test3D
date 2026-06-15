from PIL import Image, ImageFilter
import numpy as np
Image.MAX_IMAGE_PIXELS = None
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"

def process(arr):
    L = arr[..., 0]*0.299 + arr[..., 1]*0.587 + arr[..., 2]*0.114
    Lim = Image.fromarray((L*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(60))
    bgl = np.asarray(Lim).astype(np.float32)/255.0 * 1.03 + 0.02
    density = np.clip((bgl - L) / np.maximum(bgl - 0.10, 0.2), 0, 1)
    density = np.clip((density - 0.05) / 0.95, 0, 1)
    # 去破损亮斑:中值滤波
    dIm = Image.fromarray((density*255).astype(np.uint8)).filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    density = np.asarray(dIm).astype(np.float32)/255.0
    silk = np.array([0.262, 0.248, 0.220], np.float32)
    pale = np.array([0.82, 0.77, 0.65], np.float32)
    d = density[..., None]
    # 基底:保留原画明暗骨架(绢->暗绢,墨->更深)
    t = np.clip(1.0 - density, 0, 1)[..., None]
    base = silk[None, None, :] * (0.42 + 0.58 * t)
    # 带通亮提:中间调笔触发光,浓墨核心保持深
    band = (density ** 0.85) * ((1.0 - density) ** 0.45)
    out = base + (pale[None, None, :] - base) * band[..., None] * 0.78
    # 轻微边缘勾线
    dbIm = Image.fromarray((density*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.2))
    db = np.asarray(dbIm).astype(np.float32)/255.0
    gy, gx = np.gradient(db)
    edge = np.clip((np.abs(gx)+np.abs(gy)) / 0.10, 0, 1) * np.clip(db*3, 0, 1)
    out = out + (pale[None, None, :] - out) * (edge[..., None] ** 1.6) * 0.22
    return np.clip(out, 0, 1)

img = Image.open(ROOT + r"\assets\reference\chen_rong_nine_dragons.jpg").convert("RGB")
for name, box in [("whirl", (20300, 0, 22600, 1116)), ("rock", (24200, 0, 26500, 1116)), ("first", (9300, 0, 11600, 1116))]:
    c = img.crop(box).resize((1150, 558), Image.LANCZOS)
    a = np.asarray(c).astype(np.float32)/255.0
    Image.fromarray((process(a)*255).astype(np.uint8)).save(ROOT + rf"\tmp\tone_R2_{name}.png")
    print(name, "ok")
