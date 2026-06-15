# -*- coding: utf-8 -*-
# 墨龙行 3D 关卡描点:条带坐标 (sx 0..19910, sy 0..1032, sy 向下)
# 世界坐标: wx = sx*2, wy = (1032-sy)*2
from PIL import Image, ImageDraw
import math

ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
ATLAS = ROOT + r"\assets\ink_atlas\molong3d"
SW, SH = 1991, 1032

# ---- 龙脊(可行走脊背): [(sx,sy,r), ...] 沿画中龙身 ----
SPINES = {
    # D1 卧云龙 (slice00): 尾在左下,盘踞后身体向右上扬
    "d1": [(240, 800, 55), (380, 700, 65), (520, 580, 75), (700, 470, 80),
           (900, 540, 70), (1150, 530, 65), (1400, 440, 60), (1650, 370, 55), (1850, 340, 50)],
    # D2 上方游龙 (slice01 上部)
    "d2": [(2080, 300, 50), (2300, 200, 55), (2550, 160, 55), (2800, 260, 50), (2980, 380, 45)],
    # D3 下方游龙 (slice01 中下)
    "d3": [(2380, 700, 60), (2600, 620, 65), (2850, 640, 60), (3050, 700, 50)],
    # D4 驭浪龙 (slice02 右,踏浪头朝左)
    "d4": [(5380, 800, 55), (5550, 680, 65), (5720, 560, 70), (5900, 470, 65),
           (6080, 420, 55), (6250, 350, 50)],
    # D5 岩上龙 (slice04 左中)
    "d5": [(8060, 450, 55), (8200, 300, 60), (8380, 180, 60), (8550, 160, 60), (8700, 260, 55), (8850, 380, 50)],
    # D6 蜷尾龙 (slice04 右 → slice05 左)
    "d6": [(9050, 480, 55), (9250, 600, 60), (9450, 720, 60), (9700, 780, 55), (9950, 700, 50)],
    # D7 俯冲龙 (slice05 右上 → 下)
    "d7": [(11980, 130, 45), (11860, 260, 55), (11740, 400, 55), (11630, 520, 50)],
    # D8 迎面龙 (slice06 左)
    "d8": [(12150, 560, 55), (12320, 680, 60), (12480, 820, 60), (12300, 920, 55)],
    # D9 山岳龙 (slice07,正面盘山)
    "d9": [(13980, 760, 55), (14150, 620, 65), (14300, 450, 70), (14420, 280, 65),
           (14600, 220, 60), (14750, 450, 60), (14950, 620, 60), (15200, 780, 55), (15450, 850, 50)],
    # D10 斜行龙 (slice08)
    "d10": [(16080, 200, 55), (16300, 320, 60), (16550, 470, 60), (16780, 620, 55), (16950, 730, 50)],
    # D11 终龙 (slice09):尾右头左,颈部上扬接龙首悬珠
    "d11": [(17850, 470, 55), (18050, 380, 55), (18250, 230, 50), (18400, 280, 50),
            (18540, 400, 55), (18420, 560, 55), (18250, 640, 55)],
}

# ---- 云台/浪台/岩台: (x1, x2, ytop) 平顶 ----
LEDGES = [
    # 起点云岸
    (40, 360, 880),
    # D1 下方兜底云 + 回升云梯
    (500, 900, 900), (1100, 1500, 880), (1600, 1720, 700), (1780, 1880, 560),
    # S2 高低路兜底 + 衔接
    (1900, 2120, 480), (3050, 3260, 600),
    # S3 浪区:浪峰台阶
    (3250, 3700, 620), (3850, 4300, 480), (4400, 4560, 680), (4620, 4760, 760),
    # 漩涡后衔接浪台
    (5050, 5300, 820),
    # S4 → S5 浪带下行 + 岩脊攀登
    (6300, 6650, 260), (6800, 7050, 460), (7150, 7400, 400), (7500, 7800, 380), (7850, 8050, 520),
    # D6 爪子悬台
    (10050, 10260, 420),
    # S8 黑暗横渡云朵
    (10500, 10650, 620), (10880, 11030, 500), (11180, 11330, 360),
    # S10 长浪带
    (12650, 12950, 620), (13050, 13350, 560), (13450, 13700, 600), (13780, 13950, 520),
    # D9 山脚岩台
    (13900, 14080, 820),
    # D9尾 → D10 云梯
    (15550, 15680, 680), (15750, 15880, 500), (15950, 16060, 360),
    # S12→S13 云朵
    (17080, 17230, 600), (17380, 17530, 450), (17600, 17760, 540),
    # 卷尾岩台(终点后装饰)
    (18900, 19300, 760),
]

# ---- 漩涡气流: (sx, sy, 半径, 强度) 进入范围内持续上推 ----
WINDS = [
    (4850, 760, 170, 0.95),   # 大漩涡
    (10830, 770, 160, 0.95),  # 黑暗漩涡
]

# ---- 彩珠: (sx, sy, 颜色) blue=视野+ green=空中冲刺补给 gold=弹射 purple=显形脉冲 ----
PEARLS = [
    (660, 400, "blue"),
    (1450, 300, "green"),
    (2550, 80, "purple"),
    (2850, 530, "blue"),
    (4850, 540, "gold"),
    (5900, 380, "blue"),
    (7500, 310, "blue"),
    (8550, 140, "green"),
    (10830, 520, "purple"),
    (12060, 480, "gold"),
    (13300, 500, "blue"),
    (14400, 120, "green"),
    (16200, 180, "blue"),
    (18560, 120, "final"),   # 龙首悬珠(终点)
]

SPAWN = (150, 820)

PEARL_COL = {"blue": (110, 175, 255), "green": (130, 235, 160), "gold": (255, 205, 100),
             "purple": (200, 140, 255), "final": (255, 240, 200)}


def interp_spine(pts, step=18):
    out = []
    for i in range(len(pts) - 1):
        x1, y1, r1 = pts[i]; x2, y2, r2 = pts[i + 1]
        d = math.hypot(x2 - x1, y2 - y1)
        n = max(1, int(d / step))
        for k in range(n):
            t = k / n
            out.append((x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, r1 + (r2 - r1) * t))
    out.append(pts[-1])
    return out


def render_overlays():
    for i in range(10):
        im = Image.open(ATLAS + rf"\scroll_{i:02d}.png").convert("RGB")
        d = ImageDraw.Draw(im, "RGBA")
        x0, x1 = i * SW, (i + 1) * SW
        # 网格(细)
        sx = (x0 // 500 + 1) * 500
        while sx < x1:
            d.line([(sx - x0, 0), (sx - x0, SH)], fill=(120, 170, 110, 120), width=1)
            d.text((sx - x0 + 4, 4), str(sx), fill=(190, 250, 160, 200))
            sx += 500
        for gy in range(0, SH, 200):
            d.line([(0, gy), (SW, gy)], fill=(170, 120, 100, 110), width=1)
            d.text((4, gy + 2), str(gy), fill=(245, 185, 155, 200))
        # 龙脊
        for name, pts in SPINES.items():
            for (x, y, r) in interp_spine(pts, 30):
                if x0 - 100 < x < x1 + 100:
                    d.ellipse([x - x0 - r, y - r, x - x0 + r, y + r], outline=(255, 90, 90, 200), width=2)
            for (x, y, r) in pts:
                if x0 - 100 < x < x1 + 100:
                    d.ellipse([x - x0 - 4, y - 4, x - x0 + 4, y + 4], fill=(255, 60, 60, 255))
        # 云台
        for (a, b, y) in LEDGES:
            if a < x1 and b > x0:
                d.line([(max(a, x0) - x0, y), (min(b, x1) - x0, y)], fill=(120, 220, 255, 230), width=4)
        # 气流
        for (x, y, r, s) in WINDS:
            if x0 - 200 < x < x1 + 200:
                d.ellipse([x - x0 - r, y - r, x - x0 + r, y + r], outline=(150, 255, 150, 200), width=3)
        # 珠
        for (x, y, c) in PEARLS:
            if x0 - 50 < x < x1 + 50:
                col = PEARL_COL[c] + (255,)
                d.ellipse([x - x0 - 12, y - 12, x - x0 + 12, y + 12], outline=col, width=4)
                d.line([(x - x0, y - 22), (x - x0, y + 22)], fill=col, width=2)
        # 出生点
        if x0 <= SPAWN[0] < x1:
            d.ellipse([SPAWN[0] - x0 - 10, SPAWN[1] - 10, SPAWN[0] - x0 + 10, SPAWN[1] + 10],
                      outline=(255, 255, 0, 255), width=4)
        im.resize((995, 516), Image.LANCZOS).save(ROOT + rf"\tmp\ov_{i:02d}.png")
    print("overlays ok")


def check_route():
    # 简易可达性:所有站立点(脊顶/台面/珠下方落点)排序后检查相邻横向衔接
    nodes = []
    for name, pts in SPINES.items():
        for (x, y, r) in interp_spine(pts, 40):
            nodes.append((x, y - r))  # 脊背顶面
    for (a, b, y) in LEDGES:
        for x in range(int(a), int(b) + 1, 60):
            nodes.append((x, y))
    nodes.sort()
    # 沿 x 扫:对每个节点找右侧 600 条带内最近可达节点 (世界 dx<=790 即 sx 395; 上跳 sy<=110, 用 dash+jump 上限)
    gaps = []
    xs = [n[0] for n in nodes]
    import bisect
    for idx, (x, y) in enumerate(nodes):
        lo = bisect.bisect_left(xs, x + 1)
        hi = bisect.bisect_right(xs, x + 400)
        ok = False
        for j in range(lo, hi):
            nx, ny = nodes[j]
            dx = (nx - x) * 2; dy = (y - ny) * 2  # dy>0 = 目标更高(世界)
            if dx <= 0: continue
            if dy <= -600: continue
            if dy <= 0 and dx <= 780: ok = True; break
            if dy <= 220 and dx <= 700: ok = True; break
            if dy <= 390 and dx <= 480: ok = True; break
        if not ok:
            gaps.append((x, y))
    # 聚合相邻 gap
    agg = []
    for g in gaps:
        if agg and g[0] - agg[-1][1][0] < 120:
            agg[-1] = (agg[-1][0], g)
        else:
            agg.append((g, g))
    for a, b in agg:
        # 气流区豁免
        inwind = any(abs((a[0]+b[0])/2 - wx) < wr + 350 for (wx, wy, wr, ws) in WINDS)
        print(("WIND-OK " if inwind else "GAP     "), f"sx {a[0]:.0f}..{b[0]:.0f}  sy {a[1]:.0f}")


if __name__ == "__main__":
    render_overlays()
    print("--- route check (right-going) ---")
    check_route()
