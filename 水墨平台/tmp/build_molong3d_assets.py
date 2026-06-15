from PIL import Image, ImageFilter, ImageDraw
import numpy as np, os
Image.MAX_IMAGE_PIXELS = None
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
OUT = ROOT + r"\assets\ink_atlas\molong3d"
os.makedirs(OUT, exist_ok=True)

X0, X1, Y0, Y1 = 9650, 29560, 44, 1076   # 画芯范围(扫描像素)
SLICES = 10

def tone(arr):
    L = arr[..., 0]*0.299 + arr[..., 1]*0.587 + arr[..., 2]*0.114
    Lim = Image.fromarray((L*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(60))
    bgl = np.asarray(Lim).astype(np.float32)/255.0 * 1.03 + 0.02
    density = np.clip((bgl - L) / np.maximum(bgl - 0.10, 0.2), 0, 1)
    density = np.clip((density - 0.05) / 0.95, 0, 1)
    dIm = Image.fromarray((density*255).astype(np.uint8)).filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    density = np.asarray(dIm).astype(np.float32)/255.0
    silk = np.array([0.262, 0.248, 0.220], np.float32)
    pale = np.array([0.82, 0.77, 0.65], np.float32)
    t = np.clip(1.0 - density, 0, 1)[..., None]
    base = silk[None, None, :] * (0.42 + 0.58 * t)
    band = (density ** 0.85) * ((1.0 - density) ** 0.45)
    out = base + (pale[None, None, :] - base) * band[..., None] * 0.78
    dbIm = Image.fromarray((density*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.2))
    db = np.asarray(dbIm).astype(np.float32)/255.0
    gy, gx = np.gradient(db)
    edge = np.clip((np.abs(gx)+np.abs(gy)) / 0.10, 0, 1) * np.clip(db*3, 0, 1)
    out = out + (pale[None, None, :] - out) * (edge[..., None] ** 1.6) * 0.22
    return np.clip(out, 0, 1), density

img = Image.open(ROOT + r"\assets\reference\chen_rong_nine_dragons.jpg").convert("RGB")
strip = img.crop((X0, Y0, X1, Y1))
W, H = strip.size
print("strip:", W, H)
arr = np.asarray(strip).astype(np.float32)/255.0
toned, dens = tone(arr)
toned8 = (toned*255).astype(np.uint8)

sw = W // SLICES
for i in range(SLICES):
    x0 = i*sw; x1 = W if i == SLICES-1 else (i+1)*sw
    Image.fromarray(toned8[:, x0:x1]).save(OUT + rf"\scroll_{i:02d}.png")
print("slices saved, slice width =", sw)

# 视差云雾贴片(带 alpha):三块云区,淡米色,密度做 alpha + 椭圆羽化
def mist_patch(box, name, tint=(208, 196, 168)):
    gx0, gy0, gx1, gy1 = box
    c = img.crop((gx0, gy0, gx1, gy1))
    a = np.asarray(c).astype(np.float32)/255.0
    L = a[..., 0]*0.299 + a[..., 1]*0.587 + a[..., 2]*0.114
    d = np.clip((0.72 - L) / 0.55, 0, 1) ** 0.9
    dIm = Image.fromarray((d*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))
    d = np.asarray(dIm).astype(np.float32)/255.0
    h, w = d.shape
    yy, xx = np.mgrid[0:h, 0:w]
    ell = 1 - np.clip(((xx/w*2-1)**2 + (yy/h*2-1)**2), 0, 1)
    alpha = np.clip(d * (ell ** 0.8) * 1.15, 0, 1)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., 0], rgba[..., 1], rgba[..., 2] = tint
    rgba[..., 3] = (alpha*255).astype(np.uint8)
    im = Image.fromarray(rgba).resize((w//2, h//2), Image.LANCZOS)
    im.save(OUT + rf"\{name}.png"); print(name, im.size)

mist_patch((12150, 100, 14150, 950), "mist_a")
mist_patch((17800, 80, 19800, 1000), "mist_b")
mist_patch((25600, 120, 27600, 980), "mist_c")

# 视野遮罩:1024^2,中心透明孔 r=128,平滑到边缘全暗
S = 1024
yy, xx = np.mgrid[0:S, 0:S]
r = np.sqrt((xx - S/2)**2 + (yy - S/2)**2)
hole, soft = 116.0, 150.0
alpha = np.clip((r - hole) / soft, 0, 1) ** 1.5
rgba = np.zeros((S, S, 4), np.uint8)
rgba[..., 0], rgba[..., 1], rgba[..., 2] = 14, 13, 11
rgba[..., 3] = (alpha * 255).astype(np.uint8)
Image.fromarray(rgba).save(OUT + r"\vignette.png"); print("vignette ok")

# 珠光:256^2 径向白光(MatDiffColor 染色)
S = 256
yy, xx = np.mgrid[0:S, 0:S]
r = np.sqrt((xx - S/2)**2 + (yy - S/2)**2) / (S/2)
core = np.clip(1 - r/0.22, 0, 1) ** 1.2
glow = np.clip(1 - r, 0, 1) ** 2.6 * 0.85
a = np.clip(core + glow, 0, 1)
rgba = np.zeros((S, S, 4), np.uint8)
rgba[..., 0] = rgba[..., 1] = rgba[..., 2] = 255
rgba[..., 3] = (a*255).astype(np.uint8)
Image.fromarray(rgba).save(OUT + r"\pearl_glow.png"); print("pearl ok")
