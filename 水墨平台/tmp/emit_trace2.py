# -*- coding: utf-8 -*-
# kb_trace2.json(长关拼接)-> 注入 main_kingsbird.lua
import json, os

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
GAME = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
data = json.load(open(os.path.join(VID, "kb_trace2.json")))

CONF = {
    1: dict(spawn=(400, 850), cps=[(400, 850), (2400, 500), (3900, 470)], goal=(4500, 430), kill=1400, player=(10, 30, 42)),
    2: dict(spawn=(160, 250), cps=[(160, 250), (760, 245), (1300, -310)], goal=(1480, -700), kill=750, player=(40, 33, 48)),
    3: dict(spawn=(450, 940), cps=[(450, 940), (2200, 700), (3500, 975)], goal=(4250, 1230), kill=1750, player=(16, 24, 8)),
    4: dict(spawn=(80, 550), cps=[(80, 550), (2780, 260), (5716, 560)], goal=(5716, 500), kill=1500, player=(58, 46, 108)),
}

L = []
L.append("-- ==== 长关逐帧描摹数据(tmp/stitch_kb2.py 生成,勿手改) ====")
L.append("local KB_TRACE = {")
for li in range(1, 5):
    fr = data[str(li)] if str(li) in data else data[li]
    L.append("  { base = {%d,%d,%d}, spanx={%d,%d}, spany={%d,%d}, layers = {" %
             (fr["base"][0], fr["base"][1], fr["base"][2],
              fr["spanx"][0], fr["spanx"][1], fr["spany"][0], fr["spany"][1]))
    for lay in fr["layers"]:
        polys = []
        for poly in lay["polys"]:
            flat = ",".join("%d,%d" % (p[0], p[1]) for p in poly)
            polys.append("{" + flat + "}")
        L.append("    { color={%d,%d,%d}, par=%g, coll=%d, polys={%s} }," %
                 (lay["color"][0], lay["color"][1], lay["color"][2], lay["par"], lay["coll"], ",".join(polys)))
    L.append("  } },")
L.append("}")
L.append("local KB_CONF = {")
for li in range(1, 5):
    c = CONF[li]
    cps = ", ".join("{%d,%d}" % p for p in c["cps"])
    L.append("  { spawn={%d,%d}, cps={%s}, goal={%d,%d}, kill=%d, player={%d,%d,%d} }," %
             (c["spawn"][0], c["spawn"][1], cps, c["goal"][0], c["goal"][1], c["kill"], *c["player"]))
L.append("""}
for li = 1, 4 do
    local tr = KB_TRACE[li]
    local cf = KB_CONF[li]
    local lv = LEVELS[li]
    lv.TRACE = tr
    lv.ZOOM = 0.92
    lv.DECOR = {}
    lv.SPAWN = cf.spawn
    lv.CPS = cf.cps
    lv.GOAL = cf.goal
    lv.KILL = cf.kill
    lv.PAL.player = cf.player
    -- 预计算各层多边形包围盒(渲染裁剪)
    for _, lay in ipairs(tr.layers) do
        lay.bb = {}
        for pi, fp in ipairs(lay.polys) do
            local x1, y1, x2, y2 = 1e9, 1e9, -1e9, -1e9
            for k = 1, #fp - 1, 2 do
                local x, y = fp[k], fp[k + 1]
                if x < x1 then x1 = x end
                if x > x2 then x2 = x end
                if y < y1 then y1 = y end
                if y > y2 then y2 = y end
            end
            lay.bb[pi] = { x1, y1, x2, y2 }
        end
    end
    -- 碰撞多边形 + 包围盒
    local polys = {}
    for _, lay in ipairs(tr.layers) do
        if lay.coll == 1 then
            for pi, fp in ipairs(lay.polys) do
                local poly = {}
                for k = 1, #fp - 1, 2 do
                    poly[#poly + 1] = { fp[k], fp[k + 1] }
                end
                poly.bb = lay.bb[pi]
                polys[#polys + 1] = poly
            end
        end
    end
    lv.POLYS = polys
end
""")

inject = "\n".join(L)
src = open(GAME, encoding="utf-8").read()
MARK = "-- @TRACE@"
END = "-- @TRACE-END@"
pre = src[:src.index(MARK)]
post = src[src.index(END) + len(END):]
src = pre + MARK + "\n" + inject + "\n" + END + post
open(GAME, "w", encoding="utf-8", newline="\n").write(src)
print("injected, bytes:", os.path.getsize(GAME))
