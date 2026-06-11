# -*- coding: utf-8 -*-
"""
movement_metrics.py - 逐帧复刻 scripts/src/50_simulation_update.lua 的玩家运动学,
输出各关卡参数组的运动能力指标,供 docs/movement_spec.md 与地图设计使用。

复刻的帧序(60Hz 固定步长,与 fixedStep 一致):
  非冲刺帧: [输入加速 vx±=speed] -> [vy+=gravity] -> [vx*=friction] -> [位置+=速度]
  冲刺帧:   dashTime-=1; vx,vy = dir*dashSpeed; 若 dashTime<=0: vx*=0.5 (vy 保留!)
  起跳:     vy = jumpForce (同帧仍会 +gravity)
  蹬墙跳:   vy = jumpForce*0.95, vx = -wallSide*11.5 (bamboo: *1.05 / 14)
  贴墙下滑: vy = min(vy, 1.8) (bamboo: 2.5)

用法: python tools/movement_metrics.py
"""

PARAM_SETS = {
    # name: (gravity, jumpForce, dashSpeed, friction, speed, levels)
    "standard":     (0.52, -15.5, 19.0, 0.86, 1.6, "2松/3枫/4梅/5桃/7黄山/9InkLab/11梅影重楼"),
    "bamboo":       (0.55, -16.0, 20.0, 0.85, 1.6, "1幽竹飞瀑"),
    "eaves":        (0.52, -15.5, 19.5, 0.86, 1.6, "6古阁飞檐"),
    "plum_master":  (0.53, -15.8, 19.0, 0.86, 1.6, "8墨梅母本"),
    "grand_scroll": (0.52, -15.8, 19.0, 0.86, 1.6, "10长卷"),
    "plum_swift":   (0.46, -16.5, 21.0, 0.84, 1.6, "12梅影倒卷/13双清梅卷"),
}

DASH_FRAMES = 12
WALL_JUMP_VX = 11.5
WALL_JUMP_VY_MUL = 0.95


class Sim:
    def __init__(self, g, j, d, f, s):
        self.g, self.j, self.d, self.f, self.s = g, j, d, f, s
        self.x = 0.0
        self.y = 0.0
        self.vx = 0.0
        self.vy = 0.0

    def frame(self, ax=0):
        """普通帧: ax=+1/-1/0 输入方向"""
        self.vx += ax * self.s
        self.vy += self.g
        self.vx *= self.f
        self.x += self.vx
        self.y += self.vy

    def dash(self, dirx, diry):
        """完整冲刺 12 帧(归一化方向)"""
        n = (dirx * dirx + diry * diry) ** 0.5 or 1.0
        dirx, diry = dirx / n, diry / n
        for i in range(DASH_FRAMES):
            self.vx = dirx * self.d
            self.vy = diry * self.d
            if i == DASH_FRAMES - 1:
                self.vx *= 0.5
            self.x += self.vx
            self.y += self.vy


def run_speed(p):
    s = Sim(*p)
    for _ in range(600):
        s.vx += s.s
        s.vx *= s.f
    vx = s.vx
    # 达到 90% 稳速所需帧数
    s2 = Sim(*p)
    n90 = 0
    for i in range(600):
        s2.vx += s2.s
        s2.vx *= s2.f
        if s2.vx >= vx * 0.9:
            n90 = i + 1
            break
    return vx, n90


def jump_profile(p, hold=0, v0x=0.0):
    """起跳(可带水平输入/初速),返回 (apex高度, 到apex帧数, 回到起跳高度时的水平位移, 总滞空帧)"""
    s = Sim(*p)
    s.vx = v0x
    s.vy = s.j
    apex, apex_n = 0.0, 0
    for n in range(1, 400):
        s.frame(hold)
        if -s.y > apex:
            apex, apex_n = -s.y, n
        if s.y >= 0:
            return apex, apex_n, s.x, n
    return apex, apex_n, s.x, 400


def dash_h(p, with_tail=True):
    """水平冲刺位移: 冲刺 12 帧本体 + 余势滑行(无输入,直到 |vx|<0.3)"""
    s = Sim(*p)
    s.dash(1, 0)
    core = s.x
    if with_tail:
        n = 0
        while abs(s.vx) > 0.3 and n < 240:
            # 空中余势(忽略重力对水平的影响)
            s.vx *= s.f
            s.x += s.vx
            n += 1
    return core, s.x


def updash_height(p):
    """原地向上冲刺: 12 帧冲刺 + 结束后 vy=-dashSpeed 的弹道余升"""
    s = Sim(*p)
    s.dash(0, -1)
    core = -s.y
    while s.vy < 0:
        s.frame(0)
    return core, -s.y


def jump_apex_updash(p):
    """起跳至 apex 后向上冲刺的总到达高度"""
    s = Sim(*p)
    s.vy = s.j
    while True:
        nvy = s.vy + s.g
        if nvy >= 0:
            break
        s.frame(0)
    s.dash(0, -1)
    while s.vy < 0:
        s.frame(0)
    return -s.y


def jump_apex_hdash_gap(p):
    """满速助跑起跳 + apex 水平冲刺 + 持续输入,回到起跳高度时的水平位移(最大平距)"""
    vrun, _ = run_speed(p)
    s = Sim(*p)
    s.vx = vrun
    s.vy = s.j
    while True:
        nvy = s.vy + s.g
        if nvy >= 0:
            break
        s.frame(1)
    s.dash(1, 0)
    n = 0
    while s.y < 0 and n < 600:
        s.frame(1)
        n += 1
    return s.x


def diag_updash(p):
    """45° 右上冲刺(原地): 冲刺结束 + 弹道余升结束时的 (dx, 总升高)"""
    s = Sim(*p)
    s.dash(1, -1)
    while s.vy < 0:
        s.frame(1)
    return s.x, -s.y


def wall_jump(p):
    """蹬墙跳(无输入): 返回 (高度, 回到起跳高度时水平位移)"""
    s = Sim(*p)
    s.vx = WALL_JUMP_VX
    s.vy = s.j * WALL_JUMP_VY_MUL
    apex = 0.0
    n = 0
    while True:
        s.frame(0)
        n += 1
        apex = max(apex, -s.y)
        if s.y >= 0 or n > 400:
            return apex, s.x


def main():
    cols = [
        "参数组", "适用关卡",
        "稳速px/f", "稳速px/s", "90%稳速帧",
        "原地跳高", "apex帧", "滞空帧",
        "助跑跳远", "上冲刺总高", "跳+上冲总高",
        "冲刺本体", "冲刺+余势", "跳+冲刺最大平距",
        "45°上冲dx", "45°上冲dy", "蹬墙跳高", "蹬墙跳远",
    ]
    rows = []
    for name, (g, j, d, f, s, levels) in PARAM_SETS.items():
        p = (g, j, d, f, s)
        vrun, n90 = run_speed(p)
        apex0, apexn, _, air = jump_profile(p, hold=0)
        _, _, runjump_x, _ = jump_profile(p, hold=1, v0x=vrun)
        dcore, dtail = dash_h(p)
        ucore, utotal = updash_height(p)
        jud = jump_apex_updash(p)
        gap = jump_apex_hdash_gap(p)
        ddx, ddy = diag_updash(p)
        wj_h, wj_x = wall_jump(p)
        rows.append([
            name, levels,
            f"{vrun:.2f}", f"{vrun*60:.0f}", n90,
            f"{apex0:.0f}", apexn, air,
            f"{runjump_x:.0f}", f"{utotal:.0f}", f"{jud:.0f}",
            f"{dcore:.0f}", f"{dtail:.0f}", f"{gap:.0f}",
            f"{ddx:.0f}", f"{ddy:.0f}", f"{wj_h:.0f}", f"{wj_x:.0f}",
        ])

    widths = [max(len(str(r[i])) for r in rows + [cols]) for i in range(len(cols))]
    print(" | ".join(str(c).ljust(w) for c, w in zip(cols, widths)))
    print("-+-".join("-" * w for w in widths))
    for r in rows:
        print(" | ".join(str(c).ljust(w) for c, w in zip(r, widths)))


if __name__ == "__main__":
    main()
