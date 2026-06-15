# -*- coding: utf-8 -*-
# 逐帧描摹:原视频帧 -> 分层轮廓多边形(1:1 配色与几何)
import cv2, numpy as np, json, os
def imread_u(path):
    return cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
def imwrite_u(path, img):
    cv2.imencode(".png", img)[1].tofile(path)

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
CROP_Y = 40

# 每帧的层定义: (RGB, parallax, collide)  按绘制顺序(远->近); 像素归属取最近层色
FRAMES = {
    "key_9.2": {  # 金绿神庙
        "base": (130, 140, 98),
        "layers": [
            ((123, 135, 95), 0.12, 0),
            ((158, 158, 109), 0.15, 0),
            ((217, 189, 153), 0.15, 0),
            ((81, 112, 94), 0.45, 0),
            ((43, 86, 88), 0.70, 0),
            ((26, 52, 66), 0.92, 0),
            ((14, 40, 55), 1.00, 1),
        ],
    },
    "key_11.2": {  # 紫灰废墟
        "base": (66, 55, 74),
        "layers": [
            ((59, 47, 66), 0.20, 0),
            ((52, 40, 59), 0.55, 0),
            ((86, 76, 103), 0.75, 0),
            ((105, 149, 122), 0.97, 0),
            ((103, 105, 125), 1.00, 1),
        ],
    },
    "key_20.3": {  # 金绿森林
        "base": (108, 128, 14),
        "layers": [
            ((151, 161, 25), 0.18, 0),
            ((218, 189, 47), 0.20, 0),
            ((245, 222, 82), 0.22, 0),
            ((147, 160, 115), 0.25, 0),
            ((72, 94, 12), 0.55, 0),
            ((28, 41, 9), 1.00, 1),
        ],
    },
    "key_26.0": {  # 青蓝水城
        "base": (94, 249, 254),
        "layers": [
            ((206, 250, 252), 0.10, 0),
            ((97, 205, 246), 0.22, 0),
            ((74, 152, 200), 0.35, 0),
            ((131, 151, 251), 0.50, 0),
            ((112, 103, 201), 0.68, 0),
            ((102, 90, 184), 0.85, 0),
            ((88, 61, 130), 1.00, 1),
        ],
    },
}

MIN_AREA = 140
EPS = 2.6

out = {}
for name, spec in FRAMES.items():
    img = imread_u(os.path.join(VID, name + ".png"))
    img = img[CROP_Y:950, 0:1680]
    H, W = img.shape[:2]
    rgb = img[:, :, ::-1].astype(np.int32)
    lum = rgb.mean(axis=2)

    cols = np.array([c for (c, p, k) in spec["layers"]], np.int32)
    # 像素 -> 最近层
    d = np.zeros((len(cols), H, W), np.int32)
    for i, c in enumerate(cols):
        d[i] = np.abs(rgb - c.reshape(1, 1, 3)).sum(axis=2)
    assign = d.argmin(axis=0)
    # 高亮白(拖尾/角色/奖标)剔除 -> 归 base(不出多边形)
    white = lum > 235
    layers_out = []
    for i, (c, par, coll) in enumerate(spec["layers"]):
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
        layers_out.append({"color": list(map(int, c)), "par": par, "coll": coll, "polys": polys})
        npts = sum(len(p) for p in polys)
        print(f"{name} layer{i} rgb{tuple(c)} par={par} polys={len(polys)} pts={npts}")
    out[name] = {"base": spec["base"], "W": W, "H": H, "layers": layers_out}

    # 预览渲染(带 100px 网格)
    prev = np.zeros((H, W, 3), np.uint8)
    prev[:, :] = spec["base"][::-1]
    for L in layers_out:
        colbgr = tuple(int(x) for x in L["color"][::-1])
        for poly in L["polys"]:
            cv2.fillPoly(prev, [np.array(poly, np.int32)], colbgr)
    for gx in range(0, W, 100):
        cv2.line(prev, (gx, 0), (gx, H), (90, 90, 90), 1)
        cv2.putText(prev, str(gx), (gx + 2, 14), 0, 0.35, (240, 240, 90))
    for gy in range(0, H, 100):
        cv2.line(prev, (0, gy), (W, gy), (90, 90, 90), 1)
        cv2.putText(prev, str(gy), (2, gy + 12), 0, 0.35, (240, 160, 120))
    imwrite_u(os.path.join(VID, "trace_" + name + ".png"), prev)

json.dump(out, open(os.path.join(VID, "kb_trace.json"), "w"))
print("total bytes:", os.path.getsize(os.path.join(VID, "kb_trace.json")))
