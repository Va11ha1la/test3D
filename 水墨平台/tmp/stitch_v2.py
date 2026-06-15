# -*- coding: utf-8 -*-
# 参考视频2(水墨竹梅)长关拼接:同 stitch_kb2 方法,小分辨率参数适配
import cv2, numpy as np, json, os, glob

def imread_u(path):
    return cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
def imwrite_u(path, img):
    cv2.imencode(".png", img)[1].tofile(path)

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
FW, FH = 992, 432
MIN_AREA = 50
EPS = 2.0

BASE = (216, 213, 207)          # 宣纸
LAYERS = [
    ((197, 194, 190), 0.10, 0),  # 远山淡墨
    ((181, 179, 174), 0.18, 0),  # 淡灰洗
    ((157, 153, 150), 0.32, 0),  # 远竹
    ((138, 138, 134), 0.45, 0),  # 中竹
    ((113, 112, 110), 0.60, 0),  # 近中竹/云纹
    ((78, 84, 79), 0.78, 0),     # 暗青竹/叶
    ((55, 55, 53), 1.00, 1),     # 浓墨软笔
    ((33, 33, 32), 1.00, 1),     # 焦墨平台(主碰撞)
    ((150, 45, 60), 1.00, 0),    # 梅红(贴前景装饰)
    ((72, 115, 79), 1.00, 0),    # 兰绿(装饰)
    ((158, 160, 98), 1.00, 0),   # 花黄(装饰)
]

def assign_layers(img):
    rgb = img[:, :, ::-1].astype(np.int32)
    cols = np.array([c for (c, p, k) in LAYERS], np.int32)
    d = np.stack([np.abs(rgb - c.reshape(1, 1, 3)).sum(axis=2) for c in cols])
    return d.argmin(axis=0)

def est_shift(maskA, maskB):
    sc = 0.5
    ea = cv2.dilate(cv2.Canny(maskA, 50, 150), np.ones((3, 3), np.uint8))
    eb = cv2.dilate(cv2.Canny(maskB, 50, 150), np.ones((3, 3), np.uint8))
    a = cv2.resize(ea, None, fx=sc, fy=sc).astype(np.float32)
    b = cv2.resize(eb, None, fx=sc, fy=sc).astype(np.float32)
    PX, PY = 240, 110
    pad = cv2.copyMakeBorder(a, PY, PY, PX, PX, cv2.BORDER_CONSTANT, value=0)
    res = cv2.matchTemplate(pad, b, cv2.TM_CCOEFF_NORMED)
    _, mv, _, ml = cv2.minMaxLoc(res)
    D0x = (ml[0] - PX) / sc
    D0y = (ml[1] - PY) / sc
    M = np.float32([[1, 0, D0x], [0, 1, D0y]])
    bAl = cv2.warpAffine(eb.astype(np.float32), M, (FW, FH))
    P2 = 18
    padA = cv2.copyMakeBorder(ea.astype(np.float32), P2, P2, P2, P2, cv2.BORDER_CONSTANT, value=0)
    res2 = cv2.matchTemplate(padA, bAl, cv2.TM_CCOEFF_NORMED)
    _, mv2, _, ml2 = cv2.minMaxLoc(res2)
    return D0x + (ml2[0] - P2), D0y + (ml2[1] - P2), max(mv, mv2)

files = sorted(glob.glob(os.path.join(VID, "w2_*.png")))[:-3]
print("frames:", len(files))
frames = []
for f in files:
    img = imread_u(f)
    assign = assign_layers(img)
    fm = np.zeros(assign.shape, np.uint8)
    for i, (c, p, k) in enumerate(LAYERS):
        if k == 1:
            fm |= (assign == i).astype(np.uint8)
    frames.append(dict(assign=assign, fmask=fm * 255))

def edge_of(m):
    return cv2.dilate(cv2.Canny(m, 50, 150), np.ones((3, 3), np.uint8))

# 锚定全局画布的位移链(每帧对齐到已拼世界图,消除累计漂移;本片无纵向运动,dy 钳 ±8)
SC = 0.5
CW0 = 6000
canvasE = np.zeros((int((FH + 60) * SC), int(CW0 * SC)), np.float32)
def paste_edge(e, fx, fy):
    es = cv2.resize(e, None, fx=SC, fy=SC).astype(np.float32)
    x0 = int((fx) * SC); y0 = int((30 + fy) * SC)
    roi = canvasE[y0:y0 + es.shape[0], x0:x0 + es.shape[1]]
    np.maximum(roi, es[:roi.shape[0], :roi.shape[1]], out=roi)

Fx, Fy = [0.0], [0.0]
paste_edge(edge_of(frames[0]["fmask"]), 0, 0)
lastdx = 60.0
for k in range(1, len(frames)):
    eb = edge_of(frames[k]["fmask"])
    ebs = cv2.resize(eb, None, fx=SC, fy=SC).astype(np.float32)
    pred = Fx[-1] + lastdx
    wx0 = max(0, int((pred - 200) * SC))
    wx1 = min(canvasE.shape[1], int((pred + FW + 200) * SC))
    win = canvasE[:, wx0:wx1]
    if win.shape[1] <= ebs.shape[1] + 4:
        Fx.append(pred); Fy.append(0.0)
        paste_edge(eb, pred, 0)
        print(f"  [{k}] window too small -> pred {pred:.0f}")
        continue
    res = cv2.matchTemplate(win, ebs, cv2.TM_CCOEFF_NORMED)
    _, mv, _, ml = cv2.minMaxLoc(res)
    fx = wx0 / SC + ml[0] / SC
    fy = ml[1] / SC - 30
    if mv < 0.18 or fx < Fx[-1] - 60:
        fx, fy = pred, 0.0
        tag = "PRED"
    else:
        tag = "EST"
        lastdx = max(10.0, min(200.0, fx - Fx[-1]))
    if abs(fy) > 8: fy = 0.0
    print(f"  [{k}] F=({fx:.0f},{fy:.0f}) conf={mv:.2f} {tag}")
    Fx.append(fx); Fy.append(fy)
    paste_edge(eb, fx, fy)

minFx, maxFx = min(Fx), max(Fx)
minFy, maxFy = min(Fy), max(Fy)
print(f"world span x {minFx:.0f}..{maxFx:.0f}  y {minFy:.0f}..{maxFy:.0f}")

glayers = []
for i, (c, par, coll) in enumerate(LAYERS):
    CH = int((maxFy - minFy) * par) + FH + 10
    CW = int((maxFx - minFx) * par) + FW + 10
    canvas = np.zeros((CH, CW), np.uint8)
    covered = np.zeros((CH, CW), np.uint8)
    ox = -minFx * par
    oy = -minFy * par
    # 全层中央带拼布:刚性层等价于整幅;前置快速层(梅枝)冻结为居中时位置
    BAND = (280, 740)
    nF = len(frames)
    for k, fr in enumerate(frames):
        m = (fr["assign"] == i).astype(np.uint8) * 255
        b0, b1 = BAND
        if k == 0: b0 = 0
        if k == nF - 1: b1 = FW
        m2 = np.zeros_like(m)
        m2[:, b0:b1] = m[:, b0:b1]
        m = m2
        x0 = int(ox + par * Fx[k])
        y0 = int(oy + par * Fy[k])
        roi = canvas[y0:y0 + FH, x0:x0 + FW]
        cov = covered[y0:y0 + FH, x0:x0 + FW]
        mm = m[:roi.shape[0], :roi.shape[1]]
        novel = (cov == 0)
        roi[novel] = np.maximum(roi[novel], mm[novel])
        cov[:, b0:b1] = 1
    canvas = cv2.morphologyEx(canvas, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8))
    canvas = cv2.morphologyEx(canvas, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    contours, _ = cv2.findContours(canvas, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    polys, deco = [], []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < MIN_AREA:
            continue
        ap = cv2.approxPolyDP(cnt, EPS, True)
        if len(ap) < 3:
            continue
        poly = [[int(p[0][0] - ox), int(p[0][1] - oy)] for p in ap]
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        # 黑层小孤块(烘焙小人/碎渍)降为装饰
        if coll == 1 and (max(xs) - min(xs)) < 22 and (max(ys) - min(ys)) < 36 and area < 450:
            deco.append(poly)
        else:
            polys.append(poly)
    glayers.append(dict(color=list(c), par=par, coll=coll, polys=polys))
    if deco:
        glayers.append(dict(color=list(c), par=par, coll=0, polys=deco))
    print(f"  layer{i} rgb{tuple(c)} polys={len(polys)} deco={len(deco)}")

result = dict(base=list(BASE), layers=glayers,
              spanx=[int(minFx), int(maxFx)], spany=[int(minFy), int(maxFy)],
              FW=FW, FH=FH)
json.dump(result, open(os.path.join(VID, "kb_trace_v2.json"), "w"))

# 碰撞全景(×0.5,网格 = 源坐标;游戏内坐标 = 此处 ×2)
sc = 0.5
W2 = int(maxFx - minFx) + FW + 10
H2 = int(maxFy - minFy) + FH + 10
pano = np.zeros((int(H2 * sc) + 30, int(W2 * sc) + 30, 3), np.uint8)
pano[:, :] = (200, 205, 208)
offx, offy = -int(minFx) + 5, -int(minFy) + 5
for g in glayers:
    colbgr = tuple(int(x) for x in g["color"][::-1])
    if g["coll"] != 1:
        continue
    for poly in g["polys"]:
        pts = np.array([[(p[0] + offx) * sc, (p[1] + offy) * sc] for p in poly], np.int32)
        cv2.fillPoly(pano, [pts], colbgr)
for gx in range(int(minFx) // 250 * 250, int(maxFx) + FW, 250):
    px2 = int((gx + offx) * sc)
    cv2.line(pano, (px2, 0), (px2, pano.shape[0]), (120, 160, 120), 1)
    cv2.putText(pano, str(gx), (px2 + 2, 12), 0, 0.35, (30, 90, 200))
for gy in range(int(minFy) // 100 * 100, int(maxFy) + FH, 100):
    py2 = int((gy + offy) * sc)
    cv2.line(pano, (0, py2), (pano.shape[1], py2), (160, 130, 120), 1)
    cv2.putText(pano, str(gy), (2, py2 + 11), 0, 0.35, (10, 60, 160))
imwrite_u(os.path.join(VID, "pano_v2.png"), pano)
print("json bytes:", os.path.getsize(os.path.join(VID, "kb_trace_v2.json")))
