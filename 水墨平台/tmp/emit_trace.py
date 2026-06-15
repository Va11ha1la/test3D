# -*- coding: utf-8 -*-
# kb_trace.json -> 注入 main_kingsbird.lua(描摹层渲染 + 前景碰撞 + 各关参数)
import json, os

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
GAME = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
data = json.load(open(os.path.join(VID, "kb_trace.json")))

ORDER = ["key_9.2", "key_11.2", "key_20.3", "key_26.0"]
# 额外并入碰撞的层(同时视差归一)
COLL_EXTRA = {"key_9.2": [5], "key_26.0": [5]}
# 各关玩法参数(帧坐标系)
CONF = {
    1: dict(spawn=(650, 470), cps=[(650, 470), (1180, 480)], goal=(1430, 450), kill=1300, player=(10, 30, 42)),
    2: dict(spawn=(220, 700), cps=[(220, 700), (530, 380)], goal=(905, 270), kill=1250, player=(40, 33, 48)),
    3: dict(spawn=(60, 590), cps=[(60, 590), (800, 430)], goal=(1560, 550), kill=1250, player=(16, 24, 8)),
    4: dict(spawn=(80, 550), cps=[(80, 550), (850, 210)], goal=(1500, 120), kill=1000, player=(58, 46, 108)),
}

L = []
L.append("-- ==== 逐帧描摹数据(tmp/trace_kb.py 生成,勿手改) ====")
L.append("local KB_TRACE = {")
for li, name in enumerate(ORDER, 1):
    fr = data[name]
    extra = set(COLL_EXTRA.get(name, []))
    L.append("  { base = {%d,%d,%d}, layers = {" % tuple(fr["base"]))
    for i, lay in enumerate(fr["layers"]):
        par = lay["par"]
        coll = lay["coll"]
        if i in extra:
            par, coll = 1.0, 1
        polys = []
        for poly in lay["polys"]:
            flat = ",".join("%d,%d" % (p[0], p[1]) for p in poly)
            polys.append("{" + flat + "}")
        L.append("    { color={%d,%d,%d}, par=%g, coll=%d, polys={%s} }," %
                 (lay["color"][0], lay["color"][1], lay["color"][2], par, coll, ",".join(polys)))
    L.append("  } },")
L.append("}")

# 安装:覆盖 LEVELS 1-4 的碰撞/参数
L.append("""
local KB_CONF = {
""")
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
    lv.ZOOM = 0.762
    lv.DECOR = {}
    lv.SPAWN = cf.spawn
    lv.CPS = cf.cps
    lv.GOAL = cf.goal
    lv.KILL = cf.kill
    lv.PAL.player = cf.player
    lv.PAL.base = tr.base
    -- 碰撞多边形:coll 层轮廓,剔除贯穿全屏的背景体(高>=800)
    local polys = {}
    for _, lay in ipairs(tr.layers) do
        if lay.coll == 1 then
            for _, fp in ipairs(lay.polys) do
                local minY, maxY = 1e9, -1e9
                local poly = {}
                for k = 1, #fp - 1, 2 do
                    local x, y = fp[k], fp[k + 1]
                    poly[#poly + 1] = { x, y }
                    if y < minY then minY = y end
                    if y > maxY then maxY = y end
                end
                if (maxY - minY) < 800 then
                    polys[#polys + 1] = poly
                end
            end
        end
    end
    lv.POLYS = polys
end
""")

inject = "\n".join(L)
src = open(GAME, encoding="utf-8").read()
MARK = "-- @TRACE@"
if MARK in src:
    pre = src[:src.index(MARK)]
    post = src[src.index(MARK):]
    post = post[post.index("\n-- @TRACE-END@") + len("\n-- @TRACE-END@"):] if "-- @TRACE-END@" in post else post[len(MARK):]
    src = pre + MARK + "\n" + inject + "\n-- @TRACE-END@" + post
else:
    anchor = "local curLevel = 1"
    src = src.replace(anchor, MARK + "\n" + inject + "\n-- @TRACE-END@\n\n" + anchor, 1)
open(GAME, "w", encoding="utf-8", newline="\n").write(src)
print("injected, game file bytes:", os.path.getsize(GAME))
