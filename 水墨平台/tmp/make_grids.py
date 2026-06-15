from PIL import Image, ImageDraw
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
OUT = ROOT + r"\assets\ink_atlas\molong3d"
SW = 1991
for i in range(10):
    im = Image.open(OUT + rf"\scroll_{i:02d}.png").convert("RGB")
    w, h = im.size
    d = ImageDraw.Draw(im)
    sx0 = i*SW
    sx = (sx0 // 100 + 1) * 100
    while sx < sx0 + w:
        gx = sx - sx0
        major = (sx % 500 == 0)
        d.line([(gx, 0), (gx, h)], fill=(140,200,120) if major else (90,110,80), width=2 if major else 1)
        if major: d.text((gx+4, 4), str(sx), fill=(190, 250, 160))
        sx += 100
    for gy in range(0, h, 100):
        major = (gy % 500 == 0)
        d.line([(0, gy), (w, gy)], fill=(200,140,120) if major else (110,90,80), width=2 if major else 1)
        d.text((4, gy+2), str(gy), fill=(245, 185, 155))
    im.resize((995, 516), Image.LANCZOS).save(ROOT + rf"\tmp\grid_{i:02d}.png")
print("ok")
