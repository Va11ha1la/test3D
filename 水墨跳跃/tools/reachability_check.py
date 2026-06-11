# -*- coding: utf-8 -*-
"""
reachability_check.py - 关卡可交互点可达性审计。

原理:
1. 按 scripts/src/30_level_generation.lua / 35_ldtk_*.lua 逐函数移植各关几何
   (确定性纯数学,hash01 同公式,结果与游戏一致)。
2. 收集"支撑点"(可站立的枝节/平台面,坡度<=66度)与"贴墙点"(陡枝/字柱)。
3. 用 movement_metrics 同款逐帧模拟,预生成两类"冲刺可达点云":
   - 地面起跳云:初速{0,稳速} x 输入{0,1} x 跳{0,1} x 冲刺时机{0..60帧} x 8方向
   - 蹬墙云:    蹬墙跳{0,1} x 输入{0,1} x 冲刺时机{0..50帧} x 8方向
   收集**冲刺帧**位置(收集目标要求 isDashing 且 dist < t.r + 玩家半径 + 20)。
4. 对每个目标:
   a. 贴枝直采(DASH-BY): 某支撑位玩家中心与目标距离 <= 收集半径-6
   b. 地面起跳云 / 蹬墙云 命中(左右镜像各查一次)
   c. 特殊机制兜底: 瀑布走廊 / 仙鹤航线 / 柳绳尖端 / 风铃弹射
   全部失败 => FAIL,人工复查。

用法: python tools/reachability_check.py
"""
import math

PR = 11          # 玩家半径(各关 10/11,统一取 11;bamboo 取 10 误差 1px 可忽略)
DESIGN_W, DESIGN_H = 1280, 720
DIRS = [(1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1)]


def frac(v):
    return v - math.floor(v)


def hash01(seed):
    return frac(math.sin(seed * 12.9898) * 43758.5453)


def dist(ax, ay, bx, by):
    return math.hypot(ax - bx, ay - by)


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


# ---------------------------------------------------------------- 几何容器
class Geo:
    def __init__(self, worldW, worldH):
        self.worldW, self.worldH = worldW, worldH
        self.nodes = []        # (x,y,r,nx,ny,branchId)
        self.targets = []      # dict(x,y,r,branch,tag)
        self.stand = []        # 玩家中心可停留点 (x,y)
        self.cling = []        # 贴墙点(节点中心) (x,y,r)
        self.launch_extra = [] # 额外地面型起跳点(绳尖/风铃/齿轮顶) (x,y,tag)
        self.crane_bands = []  # (ymin,ymax)
        self.waterfalls = []   # (x1,y1,x2,y2) 走廊矩形

    def W(self, v):
        return self.worldW * v

    def H(self, v):
        return self.worldH * v

    # --- 与 10_drawing_primitives_layout.lua 一致 ---
    def add_node(self, x, y, r, nx, ny, bid):
        self.nodes.append((x, y, r, nx, ny, bid))

    def create_branch(self, x1, y1, x2, y2, sr, er, cx, cy, n, bid, jit):
        cpX = (x1 + x2) * 0.5 + cx
        cpY = (y1 + y2) * 0.5 + cy
        qb = lambda a, b, c, t: (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c
        for i in range(n + 1):
            t = i / n
            x, y = qb(x1, cpX, x2, t), qb(y1, cpY, y2, t)
            r = sr + (er - sr) * t
            if jit and jit > 0:
                r += (hash01(i * 19 + x * 0.013 + y * 0.017) - 0.5) * (sr * jit)
            nt = min(t + 0.01, 1)
            dx, dy = qb(x1, cpX, x2, nt) - x, qb(y1, cpY, y2, nt) - y
            ln = math.hypot(dx, dy) or 1
            nx, ny = -dy / ln, dx / ln
            if ny > 0:
                nx, ny = -nx, -ny
            self.add_node(x, y, r, nx, ny, bid)

    def create_branch_path(self, pts, bid, jit):
        sc = [(self.W(p[0]), self.H(p[1]), p[2]) for p in pts]
        for i in range(len(sc) - 1):
            ax, ay, ar = sc[i]
            bx, by, br = sc[i + 1]
            seg = math.hypot(bx - ax, by - ay)
            steps = max(2, int(seg / 9))
            dx, dy = bx - ax, by - ay
            ln = seg or 1
            nx, ny = -dy / ln, dx / ln
            if ny > 0:
                nx, ny = -nx, -ny
            for s in range(steps):
                u = s / steps
                r = ar + (br - ar) * u
                if jit and jit > 0:
                    r += (hash01((i + 1) * 31 + s * 19 + (ax + dx * u) * 0.01) - 0.5) * (ar * jit)
                self.add_node(ax + dx * u, ay + dy * u, r, nx, ny, bid)
        bx, by, br = sc[-1]
        ax, ay, _ = sc[-2]
        dx, dy = bx - ax, by - ay
        ln = math.hypot(dx, dy) or 1
        nx, ny = -dy / ln, dx / ln
        if ny > 0:
            nx, ny = -nx, -ny
        self.add_node(bx, by, br, nx, ny, bid)

    def nodes_of(self, bid):
        return [n for n in self.nodes if n[5] == bid]

    def add_target_on_branch(self, bid, progress, radius, tag=""):
        ns = self.nodes_of(bid)
        if not ns:
            self.targets.append(dict(x=-9999, y=-9999, r=radius, branch=bid, tag="NO-BRANCH"))
            return
        idx = clamp(int(len(ns) * progress), 1, len(ns)) - 1  # lua 1-based -> 0-based
        x, y, r, nx, ny, _ = ns[idx]
        off = r + 32
        self.targets.append(dict(x=x + nx * off, y=y + ny * off, r=radius, branch=bid, tag=tag))

    def add_target(self, x, y, r, tag=""):
        self.targets.append(dict(x=x, y=y, r=r, branch="-", tag=tag))

    def finalize_supports(self):
        for x, y, r, nx, ny, bid in self.nodes:
            if ny < -0.4:  # 站立条件与 circleBranchCollision 一致
                self.stand.append((x + nx * (r * 0.96 + PR), y + ny * (r * 0.96 + PR)))
            else:
                self.cling.append((x, y, r))

    def add_rect_top(self, x, y, w):
        for sx in range(int(x) + 8, int(x + w) - 7, 36):
            self.stand.append((sx, y - PR))


# ---------------------------------------------------------------- 运动点云
def build_clouds(g, j, d, f, s, wall_vx=11.5, wall_jmul=0.95):
    vrun = s * f / (1 - f)

    def run(vx0, vy0, hold, k, ddx, ddy):
        pts = []
        x = y = 0.0
        vx, vy = vx0, vy0
        for _ in range(k):
            vx += hold * s
            vy += g
            vx *= f
            x += vx
            y += vy
        ln = math.hypot(ddx, ddy)
        ddx, ddy = ddx / ln, ddy / ln
        for i in range(12):
            vx, vy = ddx * d, ddy * d
            if i == 11:
                vx *= 0.5
            x += vx
            y += vy
            pts.append((x, y))
        return pts

    ground = []
    for vx0 in (0.0, vrun):
        for hold in (0, 1):
            for jump in (0, 1):
                for k in range(0, 61, 2):
                    for ddx, ddy in DIRS:
                        ground += run(vx0, j if jump else 0.0, hold, k, ddx, ddy)
    wall = []
    for wj in (0, 1):
        for hold in (0, 1):
            for k in range(0, 51, 2):
                for ddx, ddy in DIRS:
                    wall += run(wall_vx if wj else 0.0, j * wall_jmul if wj else 0.0, hold, k, ddx, ddy)
    return Grid(ground), Grid(wall)


class Grid:
    CELL = 28.0

    def __init__(self, pts):
        self.cells = {}
        for x, y in pts:
            key = (int(x // self.CELL), int(y // self.CELL))
            self.cells.setdefault(key, []).append((x, y))

    def hit(self, dx, dy, rad):
        cr = int(rad // self.CELL) + 1
        cx, cy = int(dx // self.CELL), int(dy // self.CELL)
        r2 = rad * rad
        for ix in range(cx - cr, cx + cr + 1):
            for iy in range(cy - cr, cy + cr + 1):
                for px, py in self.cells.get((ix, iy), ()):
                    ddx, ddy = px - dx, py - dy
                    if ddx * ddx + ddy * ddy <= r2:
                        return True
        return False


# ---------------------------------------------------------------- 各关生成
def gen_bamboo(geo):
    def stalk(sx, sy, ang, length, radius, n, sid):
        cx, cy = sx, sy
        seg = length / n
        for i in range(n):
            bend = 1 if ang > -math.pi / 2 else -1
            a = ang + i * 0.015 * bend
            nx_, ny_ = cx + math.cos(a) * seg, cy + math.sin(a) * seg
            r = radius * (1 - (i / n) * 0.5)
            geo.stand.append((nx_, ny_ - PR))  # 竹节站立(isNode)
            geo.nodes.append((cx, cy, r, 0, -1, sid + "_seg%d" % i))
            if sid not in stalk_nodes:
                stalk_nodes[sid] = []
            stalk_nodes[sid].append((nx_, ny_, r))
            cx, cy = nx_, ny_

    stalk_nodes = {}
    W, H = geo.W, geo.H
    stalk(W(0.15), H(1.1), -math.pi * 0.48, H(0.8), 18, 12, "bamboo1")
    stalk(W(0.35), H(0.9), -math.pi * 0.35, H(0.7), 14, 10, "bamboo2")
    stalk(W(0.72), H(0.50), -math.pi * 0.55, H(0.5), 12, 8, "bamboo3")
    stalk(W(0.78), H(0.55), -math.pi * 0.4, H(0.4), 8, 6, "bamboo4")
    for sid, idxs in (("bamboo1", (4, 8, 11)), ("bamboo2", (5, 9)), ("bamboo3", (3, 7)), ("bamboo4", (4,))):
        for i0 in idxs:
            if i0 < len(stalk_nodes[sid]):
                nx_, ny_, r = stalk_nodes[sid][i0]
                geo.add_target(nx_, ny_, r + 18, sid)
    geo.waterfalls.append((W(0.32), H(0.03), W(0.80), geo.worldH))


def gen_pine(geo):
    W, H = geo.W, geo.H
    geo.create_branch(W(0.10), H(0.75), W(0.35), H(0.65), 38, 25, 80, -60, 100, "pine1", 0.15)
    geo.create_branch(W(0.35), H(0.65), W(0.22), H(0.48), 25, 15, -80, -80, 80, "pine_return", 0.15)
    geo.create_branch(W(0.35), H(0.65), W(0.65), H(0.58), 25, 18, 100, 80, 120, "pine2", 0.15)
    geo.create_branch(W(0.65), H(0.58), W(0.50), H(0.32), 18, 10, -90, -100, 110, "pine_bridge", 0.15)
    geo.create_branch(W(0.65), H(0.58), W(0.92), H(0.40), 18, 8, 120, -80, 120, "pine_peak", 0.15)
    for bid, p in (("pine1", .28), ("pine1", .45), ("pine1", .62), ("pine_return", .35), ("pine_return", .70),
                   ("pine2", .22), ("pine2", .40), ("pine2", .58), ("pine2", .78),
                   ("pine_bridge", .32), ("pine_bridge", .66),
                   ("pine_peak", .25), ("pine_peak", .52), ("pine_peak", .85)):
        geo.add_target_on_branch(bid, p, 42)


def gen_maple(geo):
    W, H = geo.W, geo.H
    geo.create_branch(W(0.05), H(0.82), W(0.22), H(0.70), 45, 30, 50, -100, 150, "main", 0.12)
    geo.create_branch(W(0.20), H(0.72), W(0.44), H(0.76), 26, 16, 100, 110, 110, "side1", 0.12)
    geo.create_branch(W(0.21), H(0.69), W(0.4), H(0.48), 28, 20, -120, -100, 180, "main2", 0.12)
    geo.create_branch(W(0.4), H(0.48), W(0.42), H(0.22), 20, 10, -150, -50, 150, "vertical", 0.12)
    geo.create_branch(W(0.42), H(0.22), W(0.62), H(0.28), 12, 6, 100, -100, 120, "high1", 0.12)
    geo.create_branch(W(0.42), H(0.48), W(0.72), H(0.5), 18, 12, 150, 150, 180, "bridge", 0.12)
    geo.create_branch(W(0.68), H(0.51), W(0.96), H(0.18), 12, 4, 200, -180, 220, "peak", 0.12)
    for bid, p in (("main", .45), ("side1", .65), ("main2", .6), ("high1", .25), ("high1", .75),
                   ("bridge", .3), ("bridge", .75), ("peak", .45), ("peak", .88)):
        geo.add_target_on_branch(bid, p, 36)
    for i in range(1, 10):  # 3x3 平台落叶
        row, col = (i - 1) % 3, (i - 1) // 3
        x = W(0.34 + row * 0.13 + hash01(300 + i * 7) * 0.045)
        y = H(0.64 + col * 0.10 + hash01(330 + i * 11) * 0.030)
        size = 25 + hash01(360 + i * 13) * 8
        for sx in (-1, 0, 1):
            geo.stand.append((x + sx * size, y - size * 0.22 - PR))


def gen_plum(geo):
    W, H = geo.W, geo.H
    geo.create_branch(W(0.95), H(0.58), W(0.55), H(0.68), 42, 28, -100, 70, 120, "main_trunk", 0.12)
    geo.create_branch(W(0.55), H(0.68), W(0.35), H(0.78), 28, 16, -80, 50, 100, "hanging_branch", 0.12)
    geo.create_branch(W(0.55), H(0.68), W(0.25), H(0.52), 26, 12, -120, -100, 120, "left_crescent", 0.12)
    geo.create_branch(W(0.62), H(0.62), W(0.42), H(0.22), 14, 6, -40, -120, 140, "upright_young_shoot", 0.12)
    for i, fx in enumerate((0.18, 0.14, 0.10, 0.06)):
        geo.create_branch(W(fx), H(0.28), W(fx), H(0.62), 4, 4, 0, 0, 40, "poetry_col_%d" % (i + 1), 0)
    for bid, p in (("main_trunk", .5), ("hanging_branch", .4), ("hanging_branch", .9),
                   ("upright_young_shoot", .45), ("upright_young_shoot", .95),
                   ("left_crescent", .4), ("left_crescent", .85), ("poetry_col_1", .6)):
        geo.add_target_on_branch(bid, p, 36)


def gen_peach(geo):
    W, H = geo.W, geo.H
    geo.create_branch(W(0.05), H(0.82), W(0.22), H(0.68), 42, 28, 50, -80, 120, "main_trunk", 0.12)
    geo.create_branch(W(0.42), H(0.65), W(0.55), H(0.45), 28, 20, 50, -50, 120, "middle_main", 0.12)
    geo.create_branch(W(0.55), H(0.45), W(0.92), H(0.38), 20, 12, 100, 30, 150, "middle_bridge", 0.12)
    for bid, p in (("main_trunk", .25), ("main_trunk", .40), ("main_trunk", .62), ("main_trunk", .85),
                   ("middle_main", .22), ("middle_main", .42), ("middle_main", .62), ("middle_main", .82),
                   ("middle_bridge", .18), ("middle_bridge", .35), ("middle_bridge", .52),
                   ("middle_bridge", .70), ("middle_bridge", .84), ("middle_bridge", .94)):
        geo.add_target_on_branch(bid, p, 50)
    water = H(0.86)
    for sx in range(0, int(geo.worldW), 70):  # 浮瓣水面
        geo.stand.append((sx, water - PR))
    for ax, ay, ln in ((W(0.25), H(0.12), H(0.48)), (W(0.30), H(0.14), H(0.52)),
                       (W(0.35), H(0.11), H(0.48)), (W(0.40), H(0.13), H(0.46))):
        for a in [x * 0.13 - 1.3 for x in range(21)]:  # 柳绳尖端扫掠
            geo.launch_extra.append((ax + math.sin(a) * ln, ay + math.cos(a) * ln, "rope"))


def gen_eaves(geo):
    W, H = geo.W, geo.H
    qb = lambda a, b, c, t: (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c

    def pav(x, y, w, layers, lh):
        for i in range(layers):
            ly = y + i * lh
            for bx in range(int(x - 15), int(x + w + 15), 8):
                geo.stand.append((bx, ly - 6 - PR))

    def roof(x1, y1, x2, y2, cpx, cpy):
        for i in range(41):
            t = i / 40
            geo.stand.append((qb(x1, cpx, x2, t), qb(y1, cpy, y2, t) - PR - 5))

    pav(W(0.05), H(0.55), 260, 3, 110)
    roof(W(0.05), H(0.55), W(0.01), H(0.48), W(0.03), H(0.56))
    roof(W(0.05) + 260, H(0.55), W(0.05) + 320, H(0.48), W(0.05) + 290, H(0.56))
    for gx, gy, gr in ((W(0.24), H(0.62), 110), (W(0.35), H(0.52), 90)):
        for a in [x * 0.2 for x in range(-7, 8)]:
            geo.launch_extra.append((gx + math.sin(a) * (gr + PR - 2), gy - math.cos(a) * (gr + PR - 2), "gear"))
    pav(W(0.45), H(0.45), 340, 4, 120)
    roof(W(0.45) + 340, H(0.45), W(0.68), H(0.32), W(0.58), H(0.52))
    roof(W(0.45), H(0.45), W(0.39), H(0.35), W(0.42), H(0.47))
    pav(W(0.78), H(0.35), 220, 2, 130)
    roof(W(0.78), H(0.35), W(0.72), H(0.26), W(0.75), H(0.37))
    roof(W(0.78) + 220, H(0.35), W(0.92), H(0.22), W(0.88), H(0.37))
    for cx_, cy_ in ((W(0.39), H(0.39)), (W(0.68), H(0.37)), (W(0.01), H(0.52)), (W(0.72), H(0.31))):
        geo.launch_extra.append((cx_, cy_ + 16, "chime"))
    for fx, fy in ((.12, .42), (.18, .38), (.24, .46), (.30, .41), (.35, .35), (.48, .36),
                   (.56, .32), (.62, .28), (.70, .22), (.78, .24), (.88, .18), (.94, .16)):
        geo.add_target(W(fx), H(fy), 46)


def gen_huangshan(geo):
    W, H = geo.W, geo.H
    geo.create_branch(W(0.12), H(0.58), W(0.35), H(0.56), 32, 20, 80, -60, 100, "pine_l1", 0.10)
    geo.create_branch(W(0.35), H(0.56), W(0.25), H(0.42), 20, 10, -80, -80, 80, "pine_l1_spur", 0.10)
    geo.create_branch(W(0.48), H(0.45), W(0.72), H(0.48), 25, 14, 100, 110, 110, "pine_r1", 0.10)
    geo.create_branch(W(0.72), H(0.48), W(0.62), H(0.35), 14, 8, -80, -80, 80, "pine_r1_spur", 0.10)
    geo.create_branch(W(0.88), H(0.35), W(0.96), H(0.28), 15, 6, 50, -50, 80, "pine_peak", 0.10)
    for cx_, cy_, rx in ((W(0.25), H(0.75), 180), (W(0.45), H(0.65), 220), (W(0.68), H(0.72), 190), (W(0.82), H(0.62), 160)):
        for sx in range(int(cx_ - rx) + 10, int(cx_ + rx) - 9, 40):
            geo.stand.append((sx, cy_ - PR))
    for bid, p in (("pine_l1", .25), ("pine_l1", .50), ("pine_l1", .75),
                   ("pine_l1_spur", .45), ("pine_l1_spur", .80),
                   ("pine_r1", .22), ("pine_r1", .45), ("pine_r1", .72),
                   ("pine_r1_spur", .45), ("pine_r1_spur", .82),
                   ("pine_peak", .35), ("pine_peak", .65), ("pine_peak", .90)):
        geo.add_target_on_branch(bid, p, 40)
    for i in range(3):
        sy = geo.H(0.2 + hash01(i + 100) * 0.3)
        amp = 45 + hash01(i + 300) * 25
        geo.crane_bands.append((sy - amp, sy + amp))


def gen_plum_master(geo):
    paths = [
        ([(.50, .045, 34), (.47, .115, 33), (.43, .205, 32), (.42, .300, 31), (.38, .430, 30), (.36, .535, 28),
          (.31, .650, 25), (.30, .755, 23), (.34, .930, 18)], "master_trunk", .18),
        ([(.43, .180, 17), (.36, .185, 15), (.26, .205, 12), (.17, .220, 8), (.08, .212, 4)], "master_upper_left", .20),
        ([(.47, .135, 16), (.56, .145, 14), (.66, .165, 11), (.76, .195, 7), (.93, .190, 4)], "master_upper_right", .18),
        ([(.40, .345, 20), (.32, .360, 17), (.23, .385, 12), (.14, .425, 7), (.05, .495, 3)], "master_mid_left", .18),
        ([(.42, .405, 22), (.52, .430, 20), (.63, .475, 15), (.74, .535, 10), (.89, .600, 5)], "master_mid_right", .18),
        ([(.35, .535, 20), (.27, .585, 17), (.18, .645, 12), (.09, .710, 7), (.03, .780, 3)], "master_lower_left", .18),
        ([(.33, .615, 25), (.45, .650, 22), (.57, .685, 18), (.70, .735, 12), (.83, .785, 7), (.97, .855, 3)], "master_lower_right_sweep", .18),
        ([(.31, .755, 18), (.40, .805, 15), (.50, .860, 11), (.63, .910, 7), (.80, .970, 3)], "master_bottom_spray", .18),
        ([(.18, .220, 5), (.12, .185, 3), (.06, .170, 2)], "master_twig_ul_1", .22),
        ([(.22, .238, 5), (.27, .272, 3), (.32, .325, 2)], "master_twig_ul_2", .22),
        ([(.56, .145, 5), (.63, .105, 3), (.69, .085, 2)], "master_twig_ur_1", .22),
        ([(.66, .170, 5), (.75, .135, 3), (.84, .120, 2)], "master_twig_ur_2", .22),
        ([(.76, .195, 4), (.86, .225, 3), (.96, .235, 2)], "master_twig_ur_3", .22),
        ([(.23, .385, 6), (.16, .475, 3), (.10, .535, 2)], "master_twig_ml_1", .22),
        ([(.31, .360, 5), (.24, .315, 3), (.18, .295, 2)], "master_twig_ml_2", .22),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for fx, fy in ((.21, .23), (.60, .15), (.76, .20), (.22, .42), (.70, .45),
                   (.20, .62), (.42, .60), (.65, .64), (.38, .80), (.53, .88)):
        geo.add_target(geo.W(fx), geo.H(fy), 25)


LDTK_PLUM_MIRROR_BRANCHES = [
    ("main_trunk", 224, 950.4, 1881.6, 1045.44, 46, 32, 80, 50, 60, 0.1),
    ("hanging_branch", 1881.6, 1045.44, 2777.6, 1172.16, 32, 20, 60, 30, 50, 0.1),
    ("right_crescent", 1881.6, 1045.44, 3225.6, 792, 30, 16, 100, -80, 60, 0.1),
    ("upright_young_shoot", 1568, 950.4, 2508.8, 380.16, 18, 8, 30, -100, 70, 0.1),
    ("poetry_col_1", 3673.6, 443.52, 3673.6, 982.08, 4, 4, 0, 0, 20, 0),
    ("poetry_col_2", 3852.8, 443.52, 3852.8, 982.08, 4, 4, 0, 0, 20, 0),
    ("poetry_col_3", 4032, 443.52, 4032, 982.08, 4, 4, 0, 0, 20, 0),
    ("poetry_col_4", 4211.2, 443.52, 4211.2, 982.08, 4, 4, 0, 0, 20, 0),
]
LDTK_PLUM_MIRROR_TARGETS = [
    ("main_trunk", .5), ("hanging_branch", .4), ("hanging_branch", .9),
    ("upright_young_shoot", .4), ("upright_young_shoot", .9),
    ("right_crescent", .35), ("right_crescent", .8), ("poetry_col_1", .6),
]


def gen_plum_mirror(geo):
    for bid, x1, y1, x2, y2, sr, er, cx, cy, n, jit in LDTK_PLUM_MIRROR_BRANCHES:
        geo.create_branch(x1, y1, x2, y2, sr, er, cx, cy, n, bid, jit)
    for bid, p in LDTK_PLUM_MIRROR_TARGETS:
        geo.add_target_on_branch(bid, p, 38)


def gen_plum_finale(geo):
    paths = [
        ([(0.000, 0.150, 24), (0.060, 0.163, 23), (0.130, 0.190, 21), (0.200, 0.232, 19), (0.270, 0.272, 18),
          (0.340, 0.314, 16), (0.405, 0.352, 14), (0.465, 0.412, 12), (0.525, 0.480, 10), (0.585, 0.555, 8),
          (0.645, 0.652, 7), (0.710, 0.748, 6), (0.780, 0.840, 5), (0.850, 0.905, 4), (0.920, 0.952, 3),
          (0.978, 0.974, 2.5)], "finale_trunk", 0.10),
        ([(0.012, 0.132, 12), (0.060, 0.104, 11), (0.120, 0.082, 10), (0.190, 0.071, 9), (0.258, 0.082, 8),
          (0.320, 0.104, 7), (0.380, 0.134, 5.5), (0.440, 0.158, 4), (0.498, 0.171, 3), (0.545, 0.163, 2.5)],
         "finale_upper", 0.10),
        ([(0.300, 0.290, 5), (0.345, 0.257, 4), (0.385, 0.234, 3), (0.418, 0.221, 2.5)], "finale_cross", 0.12),
        ([(0.400, 0.345, 5), (0.450, 0.352, 4), (0.495, 0.366, 3), (0.540, 0.381, 2.5), (0.578, 0.394, 2.5)],
         "finale_spray", 0.12),
        ([(0.432, 0.387, 4), (0.470, 0.407, 3), (0.506, 0.424, 2.5)], "finale_spray_fork", 0.12),
        ([(0.130, 0.205, 7), (0.110, 0.264, 6), (0.094, 0.330, 5), (0.085, 0.394, 4), (0.082, 0.452, 3),
          (0.091, 0.503, 2.5)], "finale_droop", 0.12),
        ([(0.075, 0.172, 5), (0.048, 0.200, 4), (0.026, 0.218, 3)], "finale_droop2", 0.12),
        ([(0.128, 0.086, 4), (0.140, 0.048, 3), (0.149, 0.022, 2.5)], "finale_spur1", 0.12),
        ([(0.262, 0.078, 4), (0.276, 0.040, 3), (0.286, 0.017, 2.5)], "finale_spur2", 0.12),
        ([(0.330, 0.096, 3), (0.318, 0.140, 2.5), (0.309, 0.176, 2.5)], "finale_hang1", 0.12),
        ([(0.405, 0.140, 3), (0.420, 0.184, 2.5), (0.433, 0.219, 2.5)], "finale_hang2", 0.12),
        ([(0.473, 0.424, 4), (0.508, 0.453, 3), (0.544, 0.488, 2.5), (0.572, 0.518, 2.5)], "finale_tail_twig", 0.12),
        ([(0.806, 0.100, 4), (0.806, 0.780, 4)], "poetry_col_1", 0),
        ([(0.866, 0.080, 4), (0.866, 0.780, 4)], "poetry_col_2", 0),
        ([(0.926, 0.100, 4), (0.926, 0.780, 4)], "poetry_col_3", 0),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for bid, p in (("finale_spur1", .75), ("finale_spur2", .75),
                   ("finale_upper", .10), ("finale_upper", .55), ("finale_upper", .93),
                   ("finale_cross", .70), ("finale_droop", .85), ("finale_trunk", .40),
                   ("finale_spray", .72), ("finale_tail_twig", .80), ("poetry_col_2", .55)):
        geo.add_target_on_branch(bid, p, 34)


GS_COLLISION = [
    (0, 2864, 1200, 144, 1), (1440, 2576, 816, 128, 1), (2432, 2144, 928, 16, 1), (2432, 2160, 304, 112, 1),
    (2736, 2224, 624, 48, 1), (2944, 2656, 864, 112, 1), (6592, 2048, 800, 112, 1), (7392, 2336, 896, 16, 1),
    (7392, 2352, 736, 112, 1), (8128, 2416, 160, 48, 1), (8672, 2768, 832, 144, 1),
    (2736, 2160, 800, 64, 2), (3440, 1968, 864, 64, 2), (3728, 2784, 1408, 64, 2), (3968, 1760, 816, 48, 2),
    (5136, 2832, 1440, 64, 2), (6272, 1872, 1104, 64, 2), (6864, 1568, 832, 64, 2), (7600, 1824, 992, 64, 2),
    (8128, 2352, 960, 64, 2),
]
GS_INK_TARGETS = [(617, 2450), (1733, 2033), (2833, 1733), (3867, 1417), (4833, 2683),
                  (6333, 2367), (7067, 1667), (8067, 1167), (8967, 1967)]
GS_BRUSH_NODES = [(183, 2800), (1033, 2700), (1733, 2300), (2450, 1917), (3000, 2000), (3533, 1850),
                  (4100, 1433), (4667, 1567), (5333, 2517), (6133, 2750), (6900, 1983), (7400, 1567),
                  (7933, 1217), (8467, 1300), (9000, 1867), (9367, 2083)]
GS_PINE_BRANCH = (2400, 1733, 2933, 883)
GS_PLUM_BRANCHES = [(7767, 533, 2367, 883), (8300, 1117, 1800, 667)]
GS_EAVES_RAILS = [(6583, 1367, 1333, 300), (7300, 1340, 1200, 287)]
GS_BAMBOO = [(17, 900, 600, 2283), (373, 783, 633, 2133), (850, 1217, 500, 1733)]
GS_CLOUDS = [(6183, 1683, 1567, 483), (6833, 1433, 1433, 433), (7467, 1783, 1700, 467), (8117, 2300, 1433, 400)]
GS_CRANES = [(6350, 973, 633, 350), (8317, 1483, 567, 317)]
GS_PAVILION = (6750, 1033, 1667, 1100)
GS_WATERFALLS = [(1240, 783, 933, 2067), (1950, 1383, 783, 1683)]


def gen_grand_scroll(geo):
    for x, y, w, h, v in GS_COLLISION:
        geo.add_rect_top(x, y, w)
    # 毛笔路线脊(Catmull 简化为折线采样,r 6.5~21,可站立)
    nodes = sorted([(x + 8, y + 8) for x, y in GS_BRUSH_NODES])
    for i in range(len(nodes) - 1):
        ax, ay = nodes[i]
        bx, by = nodes[i + 1]
        seg = math.hypot(bx - ax, by - ay)
        steps = max(10, int(seg / 22))
        for s in range(steps):
            u = s / steps
            geo.stand.append((ax + (bx - ax) * u, ay + (by - ay) * u - 17 - PR))
    for x, y in GS_INK_TARGETS:
        geo.add_target(x + 24, y + 24, 62, "ink")
    ex, ey, ew, eh = GS_PINE_BRANCH
    cx_, cy_ = ex + ew / 2, ey + eh / 2
    geo.create_branch(cx_ - 80, cy_ + 60, cx_ + 320, cy_ - 48, 22, 8, 96, -88, 56, "gs_pine", 0.14)
    geo.add_target_on_branch("gs_pine", 0.52, 38, "pine_motif")
    for i, (ex, ey, ew, eh) in enumerate(GS_PLUM_BRANCHES):
        cx_, cy_ = ex + ew / 2, ey + eh / 2
        geo.create_branch(cx_ + 110, cy_ + 38, cx_ - 270, cy_ - 18, 24, 5, -82, -62, 58, "gs_plum_%d" % i, 0.16)
        geo.add_target_on_branch("gs_plum_%d" % i, 0.58, 34, "plum_motif")
    for ex, ey, ew, eh in GS_EAVES_RAILS:
        cy_ = ey + eh / 2
        geo.create_branch(ex, cy_, ex + ew * 1.85, cy_ - 34, 9, 7, 38, -42, 42, "gs_rail_%d" % ex, 0.04)
    for ex, ey, ew, eh in GS_BAMBOO:
        x, y = ex + ew / 2, ey + eh
        for dx0, dy0, ang, ln, r0, n in ((-30, 160, -math.pi * .48, 470, 16, 11),
                                         (36, 110, -math.pi * .39, 390, 12, 9),
                                         (94, 60, -math.pi * .54, 330, 9, 8)):
            cx2, cy2 = x + dx0, y + dy0
            seg = ln / n
            for i in range(n):
                bend = 1 if ang > -math.pi / 2 else -1
                a = ang + i * 0.018 * bend
                cx2, cy2 = cx2 + math.cos(a) * seg, cy2 + math.sin(a) * seg
                geo.stand.append((cx2, cy2 - PR))
    for ex, ey, ew, eh in GS_CLOUDS:
        x, y = ex + ew / 2, ey + eh / 2
        rx = max(110, ew * 0.85)
        for sx in range(int(x - rx) + 10, int(x + rx) - 9, 50):
            geo.stand.append((sx, y - PR))
    for ex, ey, ew, eh in GS_CRANES:
        y = ey + eh / 2
        geo.crane_bands.append((y - 73, y + 73))
    px, py, pw, ph = GS_PAVILION
    w2 = max(180, pw * 1.5)
    for i in range(3):
        ly = py + i * 92
        for bx in range(int(px - 15), int(px + w2 + 15), 12):
            geo.stand.append((bx, ly - 6 - PR))
    for x, y, w, h in GS_WATERFALLS:
        geo.waterfalls.append((x, y - 140, x + max(260, w * 3.2), y + max(620, h * 3.8)))


def gen_wentong(geo):
    paths = [
        ([(0.050, 0.205, 16), (0.115, 0.262, 15), (0.180, 0.325, 14), (0.245, 0.395, 13), (0.305, 0.465, 12),
          (0.355, 0.535, 11), (0.395, 0.600, 10), (0.425, 0.650, 9), (0.475, 0.668, 9), (0.535, 0.668, 8),
          (0.600, 0.655, 8), (0.665, 0.632, 7), (0.730, 0.607, 7), (0.795, 0.588, 6), (0.860, 0.580, 6),
          (0.920, 0.592, 5), (0.960, 0.615, 5)], "wt_cane", 0.10),
        ([(0.180, 0.325, 7), (0.125, 0.375, 5), (0.080, 0.415, 4)], "wt_zhi1", 0.12),
        ([(0.115, 0.262, 6), (0.075, 0.300, 4), (0.045, 0.330, 3)], "wt_zhi1b", 0.12),
        ([(0.305, 0.465, 7), (0.245, 0.530, 6), (0.195, 0.585, 5), (0.165, 0.625, 4)], "wt_zhi2", 0.12),
        ([(0.245, 0.395, 6), (0.205, 0.450, 4), (0.175, 0.495, 3)], "wt_zhi2b", 0.12),
        ([(0.425, 0.650, 7), (0.380, 0.710, 5), (0.345, 0.760, 4)], "wt_zhi3", 0.12),
        ([(0.395, 0.600, 5), (0.355, 0.655, 4), (0.325, 0.700, 3)], "wt_zhi3b", 0.12),
        ([(0.535, 0.668, 6), (0.560, 0.730, 5), (0.575, 0.775, 4)], "wt_zhi4", 0.12),
        ([(0.475, 0.668, 5), (0.448, 0.730, 4), (0.430, 0.778, 3)], "wt_zhi4b", 0.12),
        ([(0.665, 0.632, 7), (0.715, 0.560, 6), (0.760, 0.505, 5), (0.790, 0.468, 4)], "wt_zhi5", 0.12),
        ([(0.665, 0.632, 5), (0.690, 0.690, 4), (0.710, 0.738, 3)], "wt_zhi5b", 0.12),
        ([(0.795, 0.588, 6), (0.845, 0.650, 5), (0.880, 0.700, 4)], "wt_zhi6", 0.12),
        ([(0.730, 0.607, 5), (0.762, 0.665, 4), (0.785, 0.710, 3)], "wt_zhi6b", 0.12),
        ([(0.920, 0.592, 6), (0.950, 0.535, 5), (0.968, 0.495, 4)], "wt_zhi7", 0.12),
        ([(0.860, 0.580, 5), (0.900, 0.640, 4), (0.928, 0.688, 3)], "wt_zhi8", 0.12),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for bid, p in (("wt_zhi1", .8), ("wt_zhi1b", .8), ("wt_zhi2", .55), ("wt_zhi2", .92), ("wt_zhi2b", .8),
                   ("wt_zhi3", .8), ("wt_zhi3b", .85), ("wt_zhi4", .85), ("wt_zhi4b", .85),
                   ("wt_zhi5", .6), ("wt_zhi5", .95), ("wt_zhi5b", .85), ("wt_zhi6", .85), ("wt_zhi6b", .85),
                   ("wt_zhi7", .8), ("wt_zhi8", .85), ("wt_cane", .50)):
        geo.add_target_on_branch(bid, p, 36)


def gen_xiyan(geo):
    paths = [
        ([(1.000, 0.500, 30), (0.940, 0.472, 28), (0.880, 0.450, 26), (0.820, 0.435, 24), (0.760, 0.420, 22),
          (0.700, 0.412, 20), (0.640, 0.416, 17), (0.580, 0.428, 14), (0.520, 0.448, 11), (0.460, 0.466, 9),
          (0.400, 0.492, 7), (0.340, 0.512, 6), (0.280, 0.528, 5), (0.220, 0.545, 4), (0.170, 0.552, 4)],
         "xy_trunk", 0.10),
        ([(0.170, 0.552, 4), (0.135, 0.512, 3), (0.108, 0.462, 3), (0.092, 0.418, 2.5)], "xy_hook", 0.12),
        ([(0.790, 0.408, 10), (0.745, 0.330, 9), (0.705, 0.258, 8), (0.668, 0.196, 6), (0.628, 0.146, 5),
          (0.585, 0.112, 4), (0.540, 0.098, 3), (0.495, 0.105, 2.5)], "xy_up_a", 0.10),
        ([(0.872, 0.428, 9), (0.888, 0.345, 8), (0.902, 0.270, 6), (0.918, 0.205, 5), (0.936, 0.152, 4),
          (0.952, 0.118, 3)], "xy_up_b", 0.10),
        ([(0.560, 0.432, 6), (0.532, 0.498, 5), (0.512, 0.556, 4), (0.500, 0.600, 3)], "xy_down_mid", 0.12),
        ([(0.430, 0.478, 6), (0.370, 0.530, 5), (0.305, 0.568, 4), (0.245, 0.588, 3), (0.190, 0.595, 2.5)],
         "xy_down_left", 0.12),
        ([(0.940, 0.474, 10), (0.918, 0.530, 7), (0.900, 0.578, 6), (0.888, 0.615, 4)], "xy_right_drop", 0.12),
        ([(0.705, 0.258, 7), (0.665, 0.232, 5), (0.625, 0.218, 4), (0.588, 0.214, 3)], "xy_up_a2", 0.12),
        ([(0.745, 0.330, 7), (0.778, 0.276, 5), (0.800, 0.235, 4), (0.818, 0.202, 3)], "xy_up_a3", 0.12),
        ([(0.902, 0.270, 6), (0.872, 0.225, 4), (0.845, 0.192, 3.5)], "xy_up_b2", 0.12),
        ([(0.700, 0.412, 8), (0.682, 0.352, 6), (0.668, 0.300, 4)], "xy_twig1", 0.12),
        ([(0.640, 0.416, 7), (0.615, 0.360, 5), (0.595, 0.315, 4)], "xy_twig2", 0.12),
        ([(0.400, 0.492, 6), (0.378, 0.442, 4), (0.362, 0.402, 3.5)], "xy_mid_twig", 0.12),
        ([(0.280, 0.528, 6), (0.258, 0.482, 4), (0.242, 0.448, 3.5)], "xy_left_twig", 0.12),
        ([(0.315, 0.060, 4), (0.315, 0.420, 4)], "poetry_col_1", 0),
        ([(0.355, 0.060, 4), (0.355, 0.420, 4)], "poetry_col_2", 0),
        ([(0.395, 0.060, 4), (0.395, 0.420, 4)], "poetry_col_3", 0),
        ([(0.435, 0.050, 4), (0.435, 0.300, 4)], "poetry_col_4", 0),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for bid, p in (("xy_up_a", .45), ("xy_up_a", .80), ("xy_up_a2", .8), ("xy_up_a3", .8),
                   ("xy_up_b", .55), ("xy_up_b", .90), ("xy_up_b2", .8),
                   ("xy_trunk", .30), ("xy_twig1", .8), ("xy_twig2", .8),
                   ("xy_down_mid", .80), ("xy_down_left", .55), ("xy_down_left", .92),
                   ("xy_mid_twig", .8), ("xy_left_twig", .8),
                   ("xy_hook", .80), ("xy_right_drop", .80), ("poetry_col_2", .50)):
        geo.add_target_on_branch(bid, p, 38)


def gen_xuwei(geo):
    paths = [
        ([(0.960, 0.285, 12), (0.880, 0.330, 11), (0.800, 0.368, 10), (0.720, 0.400, 9), (0.640, 0.428, 8),
          (0.560, 0.452, 8), (0.480, 0.478, 7), (0.400, 0.500, 6), (0.320, 0.522, 6), (0.240, 0.540, 5),
          (0.160, 0.552, 5), (0.090, 0.558, 4)], "xw_vine", 0.12),
        ([(0.160, 0.552, 5), (0.135, 0.620, 4), (0.118, 0.690, 4), (0.108, 0.760, 3), (0.105, 0.825, 3),
          (0.112, 0.880, 2.5)], "xw_left_drop", 0.12),
        ([(0.800, 0.368, 6), (0.825, 0.440, 5), (0.845, 0.515, 4), (0.858, 0.590, 4), (0.862, 0.660, 3),
          (0.855, 0.730, 3), (0.840, 0.795, 2.5)], "xw_right_drop", 0.12),
        ([(0.845, 0.515, 6), (0.890, 0.560, 5), (0.920, 0.610, 5), (0.938, 0.660, 4)], "xw_right_drop2", 0.12),
        ([(0.460, 0.482, 5), (0.452, 0.560, 4), (0.448, 0.635, 4), (0.450, 0.705, 4)], "xw_trail1", 0),
        ([(0.560, 0.455, 5), (0.572, 0.535, 4), (0.580, 0.610, 4), (0.585, 0.680, 4)], "xw_trail2", 0),
        ([(0.660, 0.425, 5), (0.672, 0.500, 4), (0.680, 0.572, 4), (0.685, 0.640, 4)], "xw_trail3", 0),
        ([(0.640, 0.428, 8), (0.565, 0.392, 6), (0.495, 0.372, 5), (0.435, 0.368, 4)], "xw_top_leaf", 0.12),
        ([(0.480, 0.478, 7), (0.508, 0.516, 6), (0.500, 0.560, 5), (0.462, 0.572, 5), (0.432, 0.543, 5),
          (0.446, 0.506, 5), (0.474, 0.494, 5)], "xw_curl1", 0.10),
        ([(0.320, 0.522, 6), (0.348, 0.556, 5), (0.336, 0.596, 4), (0.300, 0.588, 4), (0.292, 0.552, 4)], "xw_curl2", 0.10),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for bid, p in (("xw_vine", .25), ("xw_vine", .55), ("xw_vine", .85),
                   ("xw_right_drop", .45), ("xw_right_drop", .85), ("xw_right_drop2", .85),
                   ("xw_left_drop", .50), ("xw_left_drop", .90),
                   ("xw_trail1", .85), ("xw_trail2", .85), ("xw_trail3", .85),
                   ("xw_top_leaf", .80), ("xw_curl1", .45)):
        geo.add_target_on_branch(bid, p, 40)




def gen_molong(geo):
    paths = [
        ([(0.040, 0.600, 14), (0.085, 0.520, 18), (0.130, 0.450, 22), (0.180, 0.420, 26), (0.235, 0.460, 29),
          (0.285, 0.550, 31), (0.330, 0.660, 32), (0.385, 0.730, 32), (0.440, 0.740, 32), (0.495, 0.680, 31),
          (0.545, 0.570, 29), (0.595, 0.460, 27), (0.645, 0.385, 25), (0.700, 0.360, 23), (0.755, 0.400, 21),
          (0.805, 0.470, 19), (0.850, 0.520, 18), (0.895, 0.520, 17)], "dragon_body", 0.08),
        ([(0.895, 0.520, 17), (0.930, 0.480, 22), (0.962, 0.450, 21), (0.985, 0.440, 18)], "dragon_head", 0.08),
        ([(0.940, 0.425, 7), (0.922, 0.360, 5), (0.905, 0.300, 4)], "dragon_horn", 0),
        ([(0.235, 0.490, 10), (0.222, 0.558, 8), (0.249, 0.624, 6), (0.244, 0.685, 4)], "dragon_leg1", 0),
        ([(0.440, 0.770, 10), (0.426, 0.832, 8), (0.456, 0.884, 6), (0.450, 0.925, 4)], "dragon_leg2", 0),
        ([(0.645, 0.415, 10), (0.631, 0.478, 8), (0.659, 0.538, 6), (0.654, 0.595, 4)], "dragon_leg3", 0),
        ([(0.850, 0.550, 10), (0.836, 0.614, 8), (0.865, 0.674, 6), (0.860, 0.740, 4)], "dragon_leg4", 0),
    ]
    for pts, bid, jit in paths:
        geo.create_branch_path(pts, bid, jit)
    for cx, cy, rx in ((0.10, 0.82, 210), (0.27, 0.30, 190), (0.47, 0.30, 200), (0.62, 0.80, 210),
                       (0.80, 0.76, 190), (0.93, 0.68, 160)):
        X, Y = geo.W(cx), geo.H(cy)
        for sx in range(int(X - rx) + 10, int(X + rx) - 9, 40):
            geo.stand.append((sx, Y - PR))
    geo.add_target(geo.W(0.27), geo.H(0.165), 42, "pearl")
    geo.add_target(geo.W(0.58), geo.H(0.150), 42, "pearl")
    geo.add_target(geo.W(0.74), geo.H(0.620), 40, "pearl")
    for bid, p in (("dragon_body", .30), ("dragon_body", .55), ("dragon_body", .80), ("dragon_head", .70)):
        geo.add_target_on_branch(bid, p, 40)


# ---------------------------------------------------------------- 主流程
LEVELS = [
    (1, "幽竹飞瀑 bamboo", 3.0, 2.5, (0.55, -16.0, 20, 0.85, 1.6), gen_bamboo, 14, 1.05),
    (2, "松风听泉 pine", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_pine, 11.5, 0.95),
    (3, "秋林红叶 maple", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_maple, 11.5, 0.95),
    (4, "蟠梅长卷 plum", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_plum, 11.5, 0.95),
    (5, "桃花春水 peach", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_peach, 11.5, 0.95),
    (6, "古阁飞檐 eaves", 3.5, 2.2, (0.52, -15.5, 19.5, 0.86, 1.6), gen_eaves, 11.5, 0.95),
    (7, "黄山云海 huangshan", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_huangshan, 11.5, 0.95),
    (8, "墨梅母本 plum_master", 1.0, 2.667, (0.53, -15.8, 19, 0.86, 1.6), gen_plum_master, 11.5, 0.95),
    (9, "Pine InkLab(同2关几何)", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_pine, 11.5, 0.95),
    (10, "Grand Scroll ldtk", None, None, (0.52, -15.8, 19, 0.86, 1.6), gen_grand_scroll, 11.5, 0.95),
    (11, "梅影重楼 plum_parallax(复用 plum 地形)", 4.0, 2.5, (0.52, -15.5, 19, 0.86, 1.6), gen_plum, 11.5, 0.95),
    (12, "梅影倒卷 plum_mirror", 3.5, 2.2, (0.46, -16.5, 21, 0.84, 1.6), gen_plum_mirror, 11.5, 0.95),
    (13, "双清梅卷 plum_finale", 2.0, 3.06, (0.46, -16.5, 21, 0.84, 1.6), gen_plum_finale, 11.5, 0.95),
    (14, "倒垂竹 wentong_zhu", 2.2, 6.16, (0.52, -15.5, 19, 0.86, 1.6), gen_wentong, 11.5, 0.95),
    (15, "洗砚梅 plum_xiyan", 3.8, 4.18, (0.52, -15.5, 19, 0.86, 1.6), gen_xiyan, 11.5, 0.95),
    (16, "墨葡萄 xuwei_grape", 1.6, 7.49, (0.52, -15.5, 19, 0.86, 1.6), gen_xuwei, 11.5, 0.95),
    (17, "墨龙行雨 molong", 3.5, 2.2, (0.52, -15.5, 19, 0.86, 1.6), gen_molong, 11.5, 0.95),
]


def check_level(idx, name, wmul, hmul, params, gen, wall_vx, wall_jmul):
    if gen is None:
        print(f"\n[{idx}] {name}: !! 配置缺陷:loadLevel 无该 id 分发,关卡为空(无地形/无目标/无出生点)")
        return [("LEVEL", "NO-GENERATOR")]
    if idx == 10:
        worldW, worldH = 9600, 3200
    else:
        worldW, worldH = DESIGN_W * wmul, DESIGN_H * hmul
    geo = Geo(worldW, worldH)
    gen(geo)
    geo.finalize_supports()
    g, j, d, f, s = params
    ground, wall = build_clouds(g, j, d, f, s, wall_vx, wall_jmul)

    fails = []
    print(f"\n[{idx}] {name}  目标 {len(geo.targets)} | 站立点 {len(geo.stand)} | 贴墙点 {len(geo.cling)}")
    for ti, t in enumerate(geo.targets):
        if t["tag"] == "NO-BRANCH":
            print(f"  T{ti+1:02d} FAIL: 目标挂在不存在的枝 {t['branch']}")
            fails.append((ti, t))
            continue
        R = t["r"] + PR + 20
        status, best = None, 1e9
        for sx, sy in geo.stand:
            dd = dist(sx, sy, t["x"], t["y"])
            best = min(best, dd)
            if dd <= R - 6:
                status = "DASH-BY"
                break
        if not status:
            for sx, sy in geo.stand:
                dx, dy = t["x"] - sx, t["y"] - sy
                if abs(dx) > 980 or dy < -1150 or dy > 1500:
                    continue
                if ground.hit(dx, dy, R - 4) or ground.hit(-dx, dy, R - 4):
                    status = "JUMP/DASH"
                    break
        if not status:
            for cx_, cy_, cr in geo.cling:
                for side in (1, -1):
                    px = cx_ + side * (cr * 0.96 + PR)
                    dx, dy = t["x"] - px, t["y"] - cy_
                    if abs(dx) > 900 or abs(dy) > 1100:
                        continue
                    if wall.hit(dx, dy, R - 4) or wall.hit(-dx, dy, R - 4):
                        status = "WALL"
                        break
                if status:
                    break
        if not status:
            for lx, ly, tag in geo.launch_extra:
                dx, dy = t["x"] - lx, t["y"] - ly
                if abs(dx) > 980 or abs(dy) > 1200:
                    continue
                if ground.hit(dx, dy, R - 4) or ground.hit(-dx, dy, R - 4):
                    status = tag.upper()
                    break
        if not status:
            for ymin, ymax in geo.crane_bands:
                if ymin - 320 <= t["y"] <= ymax + 320:
                    status = "CRANE"
                    break
        if not status:
            for x1, y1, x2, y2 in geo.waterfalls:
                if x1 - 60 <= t["x"] <= x2 + 60 and y1 - 200 <= t["y"] <= y2:
                    status = "WATERFALL"
                    break
        if status:
            print(f"  T{ti+1:02d} ({t['x']:6.0f},{t['y']:6.0f}) r{t['r']:.0f} [{t['branch']}] {status}")
        else:
            print(f"  T{ti+1:02d} ({t['x']:6.0f},{t['y']:6.0f}) r{t['r']:.0f} [{t['branch']}] ** FAIL ** 最近支撑 {best:.0f}px")
            fails.append((ti, t))
    return fails


def main():
    all_fails = {}
    for lv in LEVELS:
        fails = check_level(*lv)
        if fails:
            all_fails[lv[0]] = fails
    print("\n" + "=" * 64)
    if all_fails:
        print("存在问题的关卡:", {k: len(v) for k, v in all_fails.items()})
    else:
        print("全部关卡所有可交互点均可达。")


if __name__ == "__main__":
    main()
