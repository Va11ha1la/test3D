# -*- coding: utf-8 -*-
# 多帧拼接长关:前景相位相关估计镜头位移 -> 各帧描摹 -> 按视差归位拼接
import cv2, numpy as np, json, os, glob

def imread_u(path):
    return cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
def imwrite_u(path, img):
    cv2.imencode(".png", img)[1].tofile(path)

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
CROP_Y = 40
MIN_AREA = 200
EPS = 3.0

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
    assign = d.argmin(axis=0)
    white = lum > 235
    return assign, white

def fore_mask(assign, white, layers):
    m = np.zeros(assign.shape, np.uint8)
    for i, (c, p, k) in enumerate(layers):
        if k == 1:
            m |= ((assign == i) & (~white)).astype(np.uint8)
    return (m * 255)

def trace_layers(assign, white, layers):
    out = []
    for i, (c, par, coll) in enumerate(layers):
        mask = ((assign == i) & (~white)).astype(np.uint8) * 255
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        polys = []
        for cnt in contours:
            if cv2.contourArea(cnt) < MIN_AREA:
                continue
            ap = cv2.approxPolyDP(cnt, EPS, True)
            if len(ap) >= 3:
                polys.append([[int(p[0][0]), int(p[0][1])] for p in ap])
        out.append(dict(color=list(c), par=par, coll=coll, polys=polys))
    return out

result = {}
for li, spec in SEGS.items():
    files = sorted(glob.glob(os.path.join(VID, spec["prefix"] + "*.png")),
                   key=lambda f: float(os.path.basename(f)[len(spec["prefix"]):-4]))
    print(f"--- level {li}: {len(files)} frames")
    frames = []
    for f in files:
        img = imread_u(f)[CROP_Y:950, 0:1680]
        assign, white = assign_layers(img, spec["layers"])
        frames.append(dict(img=img, assign=assign, white=white,
                           fmask=fore_mask(assign, white, spec["layers"]).astype(np.float32)))
    # ORB 特征匹配(限前景) -> 镜头位移
    orb = cv2.ORB_create(nfeatures=2000, fastThreshold=12)
    bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
    def frame_feats(fr):
        gray = cv2.cvtColor(fr["img"], cv2.COLOR_BGR2GRAY)
        m = (fr["fmask"] > 0).astype(np.uint8)
        m = cv2.dilate(m, np.ones((9, 9), np.uint8))
        kp, des = orb.detectAndCompute(gray, m * 255)
        return kp, des
    feats = [frame_feats(fr) for fr in frames]
    def est_offset(a, b):
        kpa, da = feats[a]
        kpb, db = feats[b]
        if da is None or db is None or len(kpa) < 10 or len(kpb) < 10:
            return None
        ms = bf.match(da, db)
        if len(ms) < 10:
            return None
        dl = np.array([[kpb[m.trainIdx].pt[0] - kpa[m.queryIdx].pt[0],
                        kpb[m.trainIdx].pt[1] - kpa[m.queryIdx].pt[1]] for m in ms])
        # 剔除静止簇(画面水印/奖标),优先取移动簇
        moving = dl[np.abs(dl).max(axis=1) > 6]
        use = moving if len(moving) >= 12 else dl
        med = np.median(use, axis=0)
        inl = use[(np.abs(use - med).max(axis=1) < 14)]
        if len(inl) < 8:
            return None
        v = np.median(inl, axis=0)
        return (-float(v[0]), -float(v[1]), len(inl))
    Fx, Fy = [0.0], [0.0]
    lastd = (300.0, 0.0)
    for k in range(1, len(frames)):
        r = est_offset(k - 1, k)
        if r is None:
            dx, dy = lastd
            print(f"  [{k}] ORB fail -> reuse d=({dx:.0f},{dy:.0f})")
        else:
            dx, dy, n = r
            print(f"  [{k}] d=({dx:.0f},{dy:.0f}) inliers={n}")
            lastd = (dx, dy)
        Fx.append(Fx[-1] + dx)
        Fy.append(Fy[-1] + dy)
    # 描摹并按层视差归位
    Lcount = len(spec["layers"])
    glayers = [dict(color=list(spec["layers"][i][0]), par=spec["layers"][i][1],
                    coll=spec["layers"][i][2], polys=[]) for i in range(Lcount)]
    for k, fr in enumerate(frames):
        if k > 0 and abs(Fx[k] - Fx[k - 1]) < 25 and abs(Fy[k] - Fy[k - 1]) < 25:
            continue  # 镜头几乎没动,跳过冗余帧
        traced = trace_layers(fr["assign"], fr["white"], spec["layers"])
        for i, lay in enumerate(traced):
            p = lay["par"]
            ox, oy = p * Fx[k], p * Fy[k]
            for poly in lay["polys"]:
                ys = [pt[1] for pt in poly]
                if lay["coll"] == 1 and (max(ys) - min(ys)) >= 800:
                    tgt = dict(color=lay["color"], par=p, coll=0)  # 贯穿背景体降为非碰撞
                    glayers_nc = None
                    # 直接放进同层但标记: 简化 -> 加入 polys 时记 coll 由层定,改为单独 nocoll 层
                    # 这里简单处理:整层 coll 仍为 1,但该 poly 放入同色 nocoll 附加层
                    pass
                shifted = [[int(pt[0] + ox), int(pt[1] + oy)] for pt in poly]
                if lay["coll"] == 1 and (max(ys) - min(ys)) >= 800:
                    # 附加非碰撞层(同色)
                    key = "nc%d" % i
                    found = None
                    for g in glayers:
                        if g.get("tag") == key:
                            found = g
                            break
                    if found is None:
                        found = dict(color=lay["color"], par=p, coll=0, polys=[], tag=key)
                        glayers.append(found)
                    found["polys"].append(shifted)
                else:
                    glayers[i]["polys"].append(shifted)
    # 关卡范围
    spanX = (min(Fx), max(Fx))
    spanY = (min(Fy), max(Fy))
    result[li] = dict(base=list(spec["base"]), layers=glayers,
                      fx=[round(v) for v in Fx], fy=[round(v) for v in Fy],
                      spanx=[round(spanX[0]), round(spanX[1])], spany=[round(spanY[0]), round(spanY[1])])
    # 前景全景预览(0.3x + 网格)
    minx = int(min(Fx)) - 50
    maxx = int(max(Fx)) + 1730
    miny = int(min(Fy)) - 50
    maxy = int(max(Fy)) + 960
    W2, H2 = maxx - minx, maxy - miny
    sc = 0.3
    pano = np.zeros((int(H2 * sc), int(W2 * sc), 3), np.uint8)
    pano[:, :] = (60, 60, 60)
    for g in glayers:
        colbgr = tuple(int(x) for x in g["color"][::-1])
        if g["coll"] != 1:
            continue
        for poly in g["polys"]:
            pts = np.array([[(p[0] - minx) * sc, (p[1] - miny) * sc] for p in poly], np.int32)
            cv2.fillPoly(pano, [pts], colbgr)
    for gx in range(0, W2, 500):
        px = int(gx * sc)
        cv2.line(pano, (px, 0), (px, pano.shape[0]), (110, 110, 110), 1)
        cv2.putText(pano, str(gx + minx), (px + 2, 14), 0, 0.4, (90, 240, 240))
    for gy in range(0, H2, 250):
        py = int(gy * sc)
        cv2.line(pano, (0, py), (pano.shape[1], py), (110, 110, 110), 1)
        cv2.putText(pano, str(gy + miny), (2, py + 13), 0, 0.4, (140, 180, 250))
    imwrite_u(os.path.join(VID, f"pano_{li}.png"), pano)
    tot = sum(len(p) for g in glayers for p in g["polys"])
    print(f"  level {li}: layers={len(glayers)} polys={sum(len(g['polys']) for g in glayers)} pts~{tot}")

json.dump(result, open(os.path.join(VID, "kb_trace2.json"), "w"))
print("json bytes:", os.path.getsize(os.path.join(VID, "kb_trace2.json")))
