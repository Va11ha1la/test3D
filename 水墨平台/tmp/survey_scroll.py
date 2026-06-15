from PIL import Image
Image.MAX_IMAGE_PIXELS = None
ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
img = Image.open(ROOT + r"\assets\reference\chen_rong_nine_dragons.jpg")
W, H = img.size
print("size:", W, H)
# 总览:切成 4 段,每段缩到宽 1400 方便看清龙的位置
seg = W // 4
for i in range(4):
    c = img.crop((i*seg, 0, min((i+1)*seg, W), H))
    r = c.resize((1400, int(H * 1400 / seg)), Image.LANCZOS)
    r.save(ROOT + rf"\tmp\scroll_q{i+1}.png")
    print("q%d: x %d..%d" % (i+1, i*seg, min((i+1)*seg, W)))
