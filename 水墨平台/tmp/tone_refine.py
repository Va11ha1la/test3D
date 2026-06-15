from PIL import Image, ImageFilter
import numpy as np
Image.MAX_IMAGE_PIXELS = None
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"

def process(arr):
    L = arr[..., 0]*0.299 + arr[..., 1]*0.587 + arr[..., 2]*0.114
    # 局部背景估计(大核模糊近似绢底,消除扫描明暗不均)
    Lim = Image.fromarray((L*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(60))
    bgl = np.asarray(Lim).astype(np.float32)/255.0 * 1.03 + 0.02
    density = np.clip((bgl - L) / np.maximum(bgl - 0.10, 0.2), 0, 1)
    # 去绢纹噪点:低密度截断 + 轻模糊
    density = np.clip((density - 0.06) / 0.94, 0, 1)
    dIm = Image.fromarray((density*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.9))
    density = np.asarray(dIm).astype(np.float32)/255.0
    silk = np.array([0.255, 0.242, 0.215], np.float32)
    pale = np.array([0.80, 0.75, 0.64], np.float32)
    d = density[..., None]
    # 体积:云雾/龙身按密度柔和提亮
    out = silk[None, None, :] + (pale - silk)[None, None, :] * (d ** 0.75) * 0.34
    # 边缘线描发光
    dbIm = Image.fromarray((density*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.6))
    db = np.asarray(dbIm).astype(np.float32)/255.0
    gy, gx = np.gradient(db)
    edge = np.clip((np.abs(gx)+np.abs(gy)) / 0.16, 0, 1)
    out = out + (pale[None, None, :] - out) * (edge[..., None] ** 1.5) * 0.62
    return np.clip(out, 0, 1)

img = Image.open(ROOT + r"\assets\reference\chen_rong_nine_dragons.jpg").convert("RGB")
# 两个测试区:漩涡龙 + q4 山石龙
for name, box in [("whirl", (20300, 0, 22600, 1116)), ("rock", (22600, 0, 24900, 1116))]:
    c = img.crop(box).resize((1150, 558), Image.LANCZOS)
    a = np.asarray(c).astype(np.float32)/255.0
    Image.fromarray((process(a)*255).astype(np.uint8)).save(ROOT + rf"\tmp\tone_R_{name}.png")
    print(name, "ok")
