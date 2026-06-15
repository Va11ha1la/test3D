# -*- coding: utf-8 -*-
import cv2, numpy as np, json, os, math

VIDEO = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\参考视频4.mp4"
OUT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\video4"
os.makedirs(OUT, exist_ok=True)

SAMPLE_STEP = 0.5
K = 8
MIN_AREA = 120
EPS = 2.2
BRIGHT_CUTOFF = 245


def imwrite_u(path, img):
    cv2.imencode(".png", img)[1].tofile(path)


def quantize_colors(samples, k):
    z = samples.astype(np.float32)
    crit = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 80, 0.35)
    _, labels, centers = cv2.kmeans(z, k, None, crit, 5, cv2.KMEANS_PP_CENTERS)
    centers = np.clip(centers, 0, 255).astype(np.uint8)
    # sort bright -> dark, RGB order
    lum = centers.mean(axis=1)
    order = np.argsort(-lum)
    return centers[order]


def assign_layers(img, centers):
    rgb = img[:, :, ::-1].astype(np.int16)
    cols = centers.astype(np.int16)
    d = np.stack([np.abs(rgb - c.reshape(1, 1, 3)).sum(axis=2) for c in cols])
    assign = d.argmin(axis=0).astype(np.uint8)
    lum = rgb.mean(axis=2)
    white = lum > BRIGHT_CUTOFF
    return assign, white


def est_shift(maskA, maskB, fw, fh):
    # Phase correlation gives the translation that aligns B to A. With our convention
    # B(x)=A(x+D), the returned alignment shift is D.
    ea = cv2.dilate(cv2.Canny(maskA, 50, 150), np.ones((3, 3), np.uint8)).astype(np.float32)
    eb = cv2.dilate(cv2.Canny(maskB, 50, 150), np.ones((3, 3), np.uint8)).astype(np.float32)
    win = cv2.createHanningWindow((fw, fh), cv2.CV_32F)
    (dx, dy), resp = cv2.phaseCorrelate(ea, eb, win)
    dx, dy = -dx, -dy
    # Fine local check: align B by the candidate and match in a small padded window.
    M = np.float32([[1, 0, dx], [0, 1, dy]])
    b_al = cv2.warpAffine(eb, M, (fw, fh))
    p2 = 28
    pad_a = cv2.copyMakeBorder(ea, p2, p2, p2, p2, cv2.BORDER_CONSTANT, value=0)
    res = cv2.matchTemplate(pad_a, b_al, cv2.TM_CCOEFF_NORMED)
    _, mv, _, ml = cv2.minMaxLoc(res)
    dx += (ml[0] - p2)
    dy += (ml[1] - p2)
    return dx, dy, max(float(resp), float(mv))


def draw_pano_preview(glayers, min_fx, min_fy, max_fx, max_fy, fw, fh):
    w2 = int(max_fx - min_fx) + fw + 30
    h2 = int(max_fy - min_fy) + fh + 30
    sc = 0.45
    pano = np.zeros((int(h2 * sc) + 60, int(w2 * sc) + 60, 3), np.uint8)
    pano[:, :] = (56, 56, 56)
    offx, offy = -int(min_fx) + 12, -int(min_fy) + 12
    for lay in glayers:
        colbgr = tuple(int(x) for x in lay["color"][::-1])
        if lay["coll"] != 1:
            colbgr = tuple(int(v * 0.55 + 50) for v in colbgr)
        for poly in lay["polys"]:
            pts = np.array([[(p[0] + offx) * sc, (p[1] + offy) * sc] for p in poly], np.int32)
            if len(pts) >= 3:
                cv2.fillPoly(pano, [pts], colbgr)
    for gx in range(int(min_fx) // 200 * 200, int(max_fx) + fw, 200):
        px = int((gx + offx) * sc)
        cv2.line(pano, (px, 0), (px, pano.shape[0]), (95, 95, 95), 1)
        cv2.putText(pano, str(gx), (px + 2, 14), 0, 0.36, (90, 240, 240), 1)
    for gy in range(int(min_fy) // 100 * 100, int(max_fy) + fh, 100):
        py = int((gy + offy) * sc)
        cv2.line(pano, (0, py), (pano.shape[1], py), (95, 95, 95), 1)
        cv2.putText(pano, str(gy), (2, py + 12), 0, 0.36, (140, 190, 250), 1)
    imwrite_u(os.path.join(OUT, "pano_video4.png"), pano)


cap = cv2.VideoCapture(VIDEO)
if not cap.isOpened():
    raise SystemExit("cannot open video")
fps = cap.get(cv2.CAP_PROP_FPS)
frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
fw = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
fh = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
dur = frame_count / fps
print("video", fw, fh, fps, frame_count, dur)

frames = []
t = 0.0
while t <= dur + 1e-3:
    cap.set(cv2.CAP_PROP_POS_MSEC, t * 1000.0)
    ok, img = cap.read()
    if not ok:
        break
    frames.append((t, img))
    imwrite_u(os.path.join(OUT, "frame_%05.2f.png" % t), img)
    t += SAMPLE_STEP
print("sample frames", len(frames))

# kmeans sample from frames, downsampled; ignore near-white UI/background specks only for clustering stability
pixs = []
for _, img in frames:
    small = cv2.resize(img, None, fx=0.35, fy=0.35, interpolation=cv2.INTER_AREA)
    rgb = small[:, :, ::-1]
    lum = rgb.mean(axis=2)
    keep = lum < 252
    pts = rgb[keep]
    if len(pts) > 6000:
        pts = pts[np.linspace(0, len(pts) - 1, 6000).astype(np.int32)]
    pixs.append(pts)
samples = np.concatenate(pixs, axis=0)
if len(samples) > 60000:
    samples = samples[np.linspace(0, len(samples) - 1, 60000).astype(np.int32)]
centers = quantize_colors(samples, K)
print("centers RGB bright->dark:")
for i, c in enumerate(centers):
    print(i, tuple(int(x) for x in c), "lum", float(c.mean()))

# Collision candidates: darkest 2 clusters, but ignore very bright pixels.
lums = centers.mean(axis=1)
coll_ids = set(np.argsort(lums)[:2].tolist())
# If darkest two are too close to pure black/player silhouette, still keep: false-player cleanup is later.
print("collision cluster ids", sorted(coll_ids))

proc = []
for t, img in frames:
    assign, white = assign_layers(img, centers)
    fmask = np.zeros((fh, fw), np.uint8)
    for cid in coll_ids:
        fmask |= ((assign == cid) & (~white)).astype(np.uint8) * 255
    # reduce tiny player/trail noise for motion only
    fmask = cv2.morphologyEx(fmask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    proc.append(dict(t=t, img=img, assign=assign, white=white, fmask=fmask))

# shift selftest
rng = np.random.RandomState(8)
A = (cv2.GaussianBlur((rng.rand(fh, fw) > 0.993).astype(np.float32), (0, 0), 8) > 0.02).astype(np.uint8) * 255
for D in [(120, 20), (-90, -15), (260, 0)]:
    B = np.roll(A, shift=(-D[1], -D[0]), axis=(0, 1))
    dx, dy, conf = est_shift(A, B, fw, fh)
    print("selftest", D, "->", round(dx), round(dy), "conf", round(conf, 2))
    assert abs(dx - D[0]) < 8 and abs(dy - D[1]) < 8
print("selftest passed")

Fx, Fy = [0.0], [0.0]
for k in range(1, len(proc)):
    dx, dy, conf = est_shift(proc[k - 1]["fmask"], proc[k]["fmask"], fw, fh)
    good = conf > 0.24 and abs(dx) < fw * 1.25 and abs(dy) < fh * 0.75
    if not good:
        # conservative right-scroll prior: video is a short showcase, keep panorama coherent
        dx, dy = fw * 0.38, 0
    Fx.append(Fx[-1] + dx)
    Fy.append(Fy[-1] + dy)
    print("shift", k, "d=(%.0f,%.0f) conf=%.2f %s" % (dx, dy, conf, "EST" if good else "STRIDE"))

minFx, maxFx = min(Fx), max(Fx)
minFy, maxFy = min(Fy), max(Fy)
W2 = int(maxFx - minFx) + fw + 30
H2 = int(maxFy - minFy) + fh + 30
print("world", W2, H2, "span", (minFx, maxFx), (minFy, maxFy))

# parallax: bright far, dark near. Collision cluster(s) par=1.
# Sort centers already bright->dark.
pars = []
for i in range(K):
    if i in coll_ids:
        pars.append(1.0)
    else:
        pars.append(0.12 + 0.68 * (i / max(1, K - 1)))

glayers = []
for i, c in enumerate(centers):
    par = pars[i]
    coll = 1 if i in coll_ids else 0
    cw = int((maxFx - minFx) * par) + fw + 30
    ch = int((maxFy - minFy) * par) + fh + 30
    canvas = np.zeros((ch, cw), np.uint8)
    covered = np.zeros((ch, cw), np.uint8)
    ox, oy = -minFx * par + 12, -minFy * par + 12
    for k, fr in enumerate(proc):
        m = ((fr["assign"] == i) & (~fr["white"])).astype(np.uint8) * 255
        if coll:
            m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
        x0, y0 = int(ox + par * Fx[k]), int(oy + par * Fy[k])
        roi = canvas[y0:y0 + fh, x0:x0 + fw]
        cov = covered[y0:y0 + fh, x0:x0 + fw]
        if roi.size == 0:
            continue
        mm = m[:roi.shape[0], :roi.shape[1]]
        novel = cov == 0
        roi[novel] = np.maximum(roi[novel], mm[novel])
        cov[:, :] = 1
    canvas = cv2.morphologyEx(canvas, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    canvas = cv2.morphologyEx(canvas, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    contours, _ = cv2.findContours(canvas, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    polys = []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < (MIN_AREA if not coll else MIN_AREA * 1.4):
            continue
        ap = cv2.approxPolyDP(cnt, EPS, True)
        if len(ap) < 3:
            continue
        poly = [[int(p[0][0] - ox), int(p[0][1] - oy)] for p in ap]
        # skip tiny vertical silhouettes likely to be the player only, unless very large
        xs = [p[0] for p in poly]; ys = [p[1] for p in poly]
        if coll and (max(xs)-min(xs) < 24 and max(ys)-min(ys) < 80):
            continue
        polys.append(poly)
    glayers.append(dict(color=[int(x) for x in c], par=par, coll=coll, polys=polys))
    print("layer", i, "rgb", tuple(int(x) for x in c), "par", par, "coll", coll, "polys", len(polys))

# Pick base as brightest center, but if too white use median bright-ish center.
base = [int(x) for x in centers[0]]
result = {
    "video": VIDEO,
    "FW": fw,
    "FH": fh,
    "base": base,
    "layers": glayers,
    "spanx": [int(minFx), int(maxFx)],
    "spany": [int(minFy), int(maxFy)],
    "frames": [float(x[0]) for x in frames],
    "shifts": [[float(Fx[i]), float(Fy[i])] for i in range(len(Fx))],
}
with open(os.path.join(OUT, "video4_trace.json"), "w", encoding="utf-8") as f:
    json.dump(result, f)
draw_pano_preview(glayers, minFx, minFy, maxFx, maxFy, fw, fh)
print("json", os.path.getsize(os.path.join(OUT, "video4_trace.json")))
print("pano", os.path.join(OUT, "pano_video4.png"))
