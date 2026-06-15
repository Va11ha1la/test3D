# -*- coding: utf-8 -*-
# 长关拼接 v2:模板匹配位移 + 世界空间掩码并集 -> 单次描摹(无重影)
import cv2, numpy as np, json, os, glob

def imread_u(path):
    return cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
def imwrite_u(path, img):
    cv2.imencode(".png", img)[1].tofile(path)

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
CROP_Y = 40
MIN_AREA = 240
EPS = 3.0
FW, FH = 1680, 910

SEGS = {
    1: dict(prefix="st1_", base=(130, 140, 98), layers=[
        ((123, 135, 95), 0.12, 0), ((158, 158, 109), 0.15, 0), ((217, 189, 153), 0.15, 0),
        ((81, 112, 94), 0.45, 0), ((43, 86, 88), 0.70, 0),
        ((26, 52, 66), 1.00, 1), ((14, 40, 55), 1.00, 1)]),
    2: dict(prefix="st2_", base=(66, 55, 74), layers=[
        ((59, 47, 66), 0.20, 0), ((52, 40, 59), 0.55, 0), ((86, 76, 103), 0.75, 0),
        ((105, 149, 122), 0.97, 0), ((103, 105, 125), 1.00, 1)]),
    3: dict(prefix="st3_", base=(108, 128, 14), layers=[
        ((151, 161, 25), 0.18, 0), ((218, 189, 47), 0.20, 0), ((245, 222, 82), 0.22, 0),
        ((147, 160, 115), 0.25, 0), ((72, 94, 12), 0.55, 0), ((28, 41, 9), 1.00, 1)]),
    4: dict(prefix="st4_", base=(94, 249, 254), layers=[
        ((206, 250, 252), 0.10, 0), ((97, 205, 246), 0.22, 0), ((74, 152, 200), 0.35, 0),
        ((131, 151, 251), 0.50, 0), ((112, 103, 201), 0.68, 0),
        ((102, 90, 184), 1.00, 1), ((88, 61, 130), 1.00, 1)]),
}

def assign_layers(img, layers):
    rgb = img[:, :, ::-1].astype(np.int32)
    lum = rgb.mean(axis=2)
    cols = np.array([c for (c, p, k) in layers], np.int32)
    d = np.stack([np.abs(rgb - c.reshape(1, 1, 3)).sum(axis=2) for c in cols])
    return d.argmin(axis=0), (lum > 235)

def est_shift(maskA, maskB):
    """约定: b(x)=A(x+D) <=> 镜头位移 +D。返回 (Dx, Dy, conf)。"""
    sc = 0.25
    ea = cv2.dilate(cv2.Canny(maskA, 50, 150), np.ones((3, 3), np.uint8))
    eb = cv2.dilate(cv2.Canny(maskB, 50, 150), np.ones((3, 3), np.uint8))
    a = cv2.resize(ea, None, fx=sc, fy=sc).astype(np.float32)
    b = cv2.resize(eb, None, fx=sc, fy=sc).astype(np.float32)
    PX, PY = 260, 140
    pad = cv2.copyMakeBorder(a, PY, PY, PX, PX, cv2.BORDER_CONSTANT, value=0)
    res = cv2.matchTemplate(pad, b, cv2.TM_CCOEFF_NORMED)
    _, mv, _, ml = cv2.minMaxLoc(res)
    D0x = (ml[0] - PX) / sc
    D0y = (ml[1] - PY) / sc
    # 精修:b 含量右移 D0 对齐 A,残差再匹配(±24)
    M = np.float32([[1, 0, D0x], [0, 1, D0y]])
    bAl = cv2.warpAffine(eb.astype(np.float32), M, (FW, FH))
    P2 = 26
    padA = cv2.copyMakeBorder(ea.astype(np.float32), P2, P2, P2, P2, cv2.BORDER_CONSTANT, value=0)
    res2 = cv2.matchTemplate(padA, bAl, cv2.TM_CCOEFF_NORMED)
    _, mv2, _, ml2 = cv2.minMaxLoc(res2)
    Dx = D0x + (ml2[0] - P2)
    Dy = D0y + (ml2[1] - P2)
    return Dx, Dy, max(mv, mv2)

# ---- 自检:已知位移还原 ----
_rng = np.random.RandomState(5)
_A = (cv2.GaussianBlur((_rng.rand(FH, FW) > 0.992).astype(np.float32), (0, 0), 9) > 0.02).astype(np.uint8) * 255
for _D in [(190, 60), (-240, -90), (520, 0)]:
    _B = np.roll(_A, shift=(-_D[1], -_D[0]), axis=(0, 1))
    _dx, _dy, _c = est_shift(_A, _B)
    print("selftest D=%s -> est=(%.0f,%.0f) conf=%.2f" % (_D, _dx, _dy, _c))
    assert abs(_dx - _D[0]) < 8 and abs(_dy - _D[1]) < 8, "EST SHIFT SELFTEST FAILED"
print("selftest passed")

result = {}
for li, spec in SEGS.items():
    files = sorted(glob.glob(os.path.join(VID, spec["prefix"] + "*.png")),
                   key=lambda f: float(os.path.basename(f)[len(spec["prefix"]):-4]))
    print(f"--- level {li}: {len(files)} frames")
    frames = []
    for f in files:
        img = imread_u(f)[CROP_Y:950, 0:FW]
        assign, white = assign_layers(img, spec["layers"])
        fm = np.zeros(assign.shape, np.uint8)
        for i, (c, p, k) in enumerate(spec["layers"]):
            if k == 1:
                fm |= ((assign == i) & (~white)).astype(np.uint8)
        frames.append(dict(assign=assign, white=white, fmask=fm * 255))
    Fx, Fy = [0.0], [0.0]
    keep = [True]
    for k in range(1, len(frames)):
        dx, dy, conf = est_shift(frames[k - 1]["fmask"], frames[k]["fmask"])
        good = conf > 0.30 and abs(dx) < 1300 and abs(dy) < 600 and (dx >= -80 or conf >= 0.40)
        if not good:
            # 低置信 -> 右进步长先验(保持拼布推进,不重影)
            dx, dy = 680, 0
        print(f"  [{k}] d=({dx:.0f},{dy:.0f}) conf={conf:.2f} {'EST' if good else 'STRIDE'}")
        Fx.append(Fx[-1] + dx)
        Fy.append(Fy[-1] + dy)
        keep.append(True)
    # 世界空间掩码并集(逐层)
    minFx, maxFx = min(Fx), max(Fx)
    minFy, maxFy = min(Fy), max(Fy)
    W2 = int(maxFx - minFx) + FW + 20
    H2 = int(maxFy - minFy) + FH + 20
    print(f"  world {W2}x{H2}")
    glayers = []
    for i, (c, par, coll) in enumerate(spec["layers"]):
        CH = int((maxFy - minFy) * par) + FH + 20
        CW = int((maxFx - minFx) * par) + FW + 20
        canvas = np.zeros((CH, CW), np.uint8)
        covered = np.zeros((CH, CW), np.uint8)
        ox = -minFx * par
        oy = -minFy * par
        for k, fr in enumerate(frames):
            if not keep[k]:
                continue
            m = ((fr["assign"] == i) & (~fr["white"])).astype(np.uint8) * 255
            x0 = int(ox + par * Fx[k])
            y0 = int(oy + par * Fy[k])
            roi = canvas[y0:y0 + FH, x0:x0 + FW]
            cov = covered[y0:y0 + FH, x0:x0 + FW]
            mm = m[:roi.shape[0], :roi.shape[1]]
            novel = (cov == 0)
            roi[novel] = np.maximum(roi[novel], mm[novel])
            cov[:, :] = 1
        canvas = cv2.morphologyEx(canvas, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
        canvas = cv2.morphologyEx(canvas, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
        contours, _ = cv2.findContours(canvas, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        polys, ncpolys = [], []
        for cnt in contours:
            if cv2.contourArea(cnt) < MIN_AREA:
                continue
            ap = cv2.approxPolyDP(cnt, EPS, True)
            if len(ap) < 3:
                continue
            poly = [[int(p[0][0] - ox), int(p[0][1] - oy)] for p in ap]
            ys = [pt[1] for pt in poly]
            xs = [pt[0] for pt in poly]
            polys.append(poly)   # 前景层全部参与碰撞(原作:黑柱是需蹬墙绕越的实体)
        glayers.append(dict(color=list(c), par=par, coll=coll, polys=polys))
        if ncpolys:
            glayers.append(dict(color=list(c), par=par, coll=0, polys=ncpolys))
        print(f"  layer{i} polys={len(polys)}+nc{len(ncpolys)}")
    result[li] = dict(base=list(spec["base"]),
                      layers=glayers,
                      spanx=[int(minFx), int(maxFx)], spany=[int(minFy), int(maxFy)])
    # 前景全景预览
    sc = 0.3
    pano = np.zeros((int(H2 * sc) + 40, int(W2 * sc) + 40, 3), np.uint8)
    pano[:, :] = (60, 60, 60)
    offx, offy = -int(minFx) + 10, -int(minFy) + 10
    for g in glayers:
        if g["coll"] != 1:
            continue
        colbgr = tuple(int(x) for x in g["color"][::-1])
        for poly in g["polys"]:
            pts = np.array([[(p[0] + offx) * sc, (p[1] + offy) * sc] for p in poly], np.int32)
            cv2.fillPoly(pano, [pts], colbgr)
    for gx in range(int(minFx) // 500 * 500, int(maxFx) + FW, 500):
        px2 = int((gx + offx) * sc)
        cv2.line(pano, (px2, 0), (px2, pano.shape[0]), (110, 110, 110), 1)
        cv2.putText(pano, str(gx), (px2 + 2, 14), 0, 0.4, (90, 240, 240))
    for gy in range(int(minFy) // 250 * 250, int(maxFy) + FH, 250):
        py2 = int((gy + offy) * sc)
        cv2.line(pano, (0, py2), (pano.shape[1], py2), (110, 110, 110), 1)
        cv2.putText(pano, str(gy), (2, py2 + 13), 0, 0.4, (140, 180, 250))
    imwrite_u(os.path.join(VID, f"pano2_{li}.png"), pano)

json.dump(result, open(os.path.join(VID, "kb_trace2.json"), "w"))
print("json bytes:", os.path.getsize(os.path.join(VID, "kb_trace2.json")))
