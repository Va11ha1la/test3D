# -*- coding: utf-8 -*-
# 注入:槽1=水墨竹梅(视频2,坐标x2) 槽3=金绿森林 槽4=青蓝水城;槽2(紫废墟)由主文件移除
import json, os

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
GAME = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main_kingsbird.lua"
kb = json.load(open(os.path.join(VID, "kb_trace2.json")))
v2 = json.load(open(os.path.join(VID, "kb_trace_v2.json")))

CONF = {
    1: dict(spawn=(120, 720), cps=[(120, 720), (1480, 460), (3000, 640)], goal=(4160, 580), kill=1000,
            player=(30, 30, 30), zoom=0.75, refx=992, refy=432, frw=1984, frh=864),
    3: dict(spawn=(450, 940), cps=[(450, 940), (2200, 700), (3500, 975)], goal=(4250, 1230), kill=1750,
            player=(16, 24, 8), zoom=0.92, refx=840, refy=455, frw=1680, frh=910),
    4: dict(spawn=(80, 550), cps=[(80, 550), (2780, 260), (5716, 560)], goal=(5716, 500), kill=1500,
            player=(58, 46, 108), zoom=0.92, refx=840, refy=455, frw=1680, frh=910),
}

def emit_level(fr, scale):
    out = []
    out.append("  { base = {%d,%d,%d}, spanx={%d,%d}, spany={%d,%d}, layers = {" %
               (fr["base"][0], fr["base"][1], fr["base"][2],
                fr["spanx"][0] * scale, fr["spanx"][1] * scale,
                fr["spany"][0] * scale, fr["spany"][1] * scale))
    for lay in fr["layers"]:
        polys = []
        for poly in lay["polys"]:
            flat = ",".join("%d,%d" % (p[0] * scale, p[1] * scale) for p in poly)
            polys.append("{" + flat + "}")
        out.append("    { color={%d,%d,%d}, par=%g, coll=%d, polys={%s} }," %
                   (lay["color"][0], lay["color"][1], lay["color"][2], lay["par"], lay["coll"], ",".join(polys)))
    out.append("  } },")
    return out

L = []
L.append("-- ==== 长关逐帧描摹数据(stitch_kb2/stitch_v2 生成,勿手改) ====")
L.append("local KB_TRACE = {}")
L.append("KB_TRACE[1] = ")
last = emit_level(v2, 2)
L.append("\n".join(last)[2:].rstrip(","))   # 去掉行首缩进逗号适配单独赋值
L.append("KB_TRACE[3] = ")
L.append("\n".join(emit_level(kb["3"] if "3" in kb else kb[3], 1))[2:].rstrip(","))
L.append("KB_TRACE[4] = ")
L.append("\n".join(emit_level(kb["4"] if "4" in kb else kb[4], 1))[2:].rstrip(","))
L.append("local KB_CONF = {}")
for li, c in CONF.items():
    cps = ", ".join("{%d,%d}" % p for p in c["cps"])
    L.append("KB_CONF[%d] = { spawn={%d,%d}, cps={%s}, goal={%d,%d}, kill=%d, player={%d,%d,%d}, zoom=%g, refx=%d, refy=%d, frw=%d, frh=%d }" %
             (li, c["spawn"][0], c["spawn"][1], cps, c["goal"][0], c["goal"][1], c["kill"],
              c["player"][0], c["player"][1], c["player"][2], c["zoom"], c["refx"], c["refy"], c["frw"], c["frh"]))
L.append("""
for _, li in ipairs({1, 3, 4}) do
    local tr = KB_TRACE[li]
    local cf = KB_CONF[li]
    local lv = LEVELS[li]
    lv.TRACE = tr
    lv.ZOOM = cf.zoom
    lv.REFX = cf.refx
    lv.REFY = cf.refy
    lv.FRW = cf.frw
    lv.FRH = cf.frh
    lv.DECOR = {}
    lv.SPAWN = cf.spawn
    lv.CPS = cf.cps
    lv.GOAL = cf.goal
    lv.KILL = cf.kill
    lv.PAL.player = cf.player
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
