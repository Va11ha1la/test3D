# -*- coding: utf-8 -*-
# 生成 scripts/src/86_trace_data.lua:TRACE_DEFS(竹梅×2宣纸化 / 森林 / 水城,世界平移至 0 起)
import json, os

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
OUT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\src\86_trace_data.lua"
kb = json.load(open(os.path.join(VID, "kb_trace2.json")))
v2 = json.load(open(os.path.join(VID, "kb_trace_v2.json")))

XUAN = {
    (216,213,207):(243,239,229),(197,194,190):(229,225,214),(181,179,174):(212,208,197),
    (157,153,150):(188,184,175),(138,138,134):(162,160,151),(113,112,110):(131,129,122),
    (78,84,79):(86,95,82),(55,55,53):(46,44,41),(33,33,32):(25,23,21),
}
HIDE = {(150,45,60),(158,160,98)}   # 竹梅:红/黄改程序花

def build(fr, scale, conf, xuan=False):
    sx1, sy1 = fr["spanx"][0]*scale, fr["spany"][0]*scale
    Sx, Sy = -sx1, -sy1
    frw = fr.get("FW", 1680)*scale if "FW" in fr else 1680
    frh = fr.get("FH", 910)*scale if "FH" in fr else 910
    d = {
        "base": list(XUAN.get(tuple(fr["base"]), fr["base"])) if xuan else fr["base"],
        "spanx2": fr["spanx"][1]*scale + Sx, "spany2": fr["spany"][1]*scale + Sy,
        "frw": frw, "frh": frh,
        "refx": (fr.get("FW",1680)*scale//2 if "FW" in fr else 840) + Sx,
        "refy": (fr.get("FH",910)*scale//2 if "FH" in fr else 455) + Sy,
        "layers": [],
        "conf": {
            "spawn": [conf["spawn"][0]+Sx, conf["spawn"][1]+Sy],
            "cps": [[c[0]+Sx, c[1]+Sy] for c in conf["cps"]],
            "goal": [conf["goal"][0]+Sx, conf["goal"][1]+Sy],
            "kill": conf["kill"]+Sy,
        },
    }
    for lay in fr["layers"]:
        c = tuple(lay["color"])
        col = list(XUAN.get(c, c)) if xuan else list(c)
        hidden = 1 if (xuan and c in HIDE) else 0
        polys = []
        for poly in lay["polys"]:
            polys.append([(p[0]*scale + Sx, p[1]*scale + Sy) for p in poly])
        d["layers"].append({"color": col, "ocolor": list(c), "par": lay["par"],
                            "coll": lay["coll"], "hidden": hidden, "polys": polys})
    return d

DEFS = {
    "zhumei": build(v2, 2, dict(spawn=(120,720), cps=[(120,720),(1480,460),(3000,640)], goal=(4160,580), kill=1000), xuan=True),
    "forest": build(kb.get("3", kb.get(3)), 1, dict(spawn=(450,940), cps=[(450,940),(2200,700),(3500,975)], goal=(4250,1230), kill=1750)),
    "water":  build(kb.get("4", kb.get(4)), 1, dict(spawn=(80,550), cps=[(80,550),(2780,260),(5716,560)], goal=(5716,500), kill=1500)),
}

L = ["-- 描摹关数据(tmp/emit_bundle_trace.py 生成,勿手改)", "TRACE_DEFS = {}"]
for key, d in DEFS.items():
    c = d["conf"]
    cps = ", ".join("{%d,%d}" % (pp[0], pp[1]) for pp in c["cps"])
    L.append('TD = { base={%d,%d,%d}, spanx2=%d, spany2=%d, frw=%d, frh=%d, refx=%d, refy=%d, layers={},' %
             (d["base"][0], d["base"][1], d["base"][2], d["spanx2"], d["spany2"],
              d["frw"], d["frh"], d["refx"], d["refy"]))
    L.append("  conf={ spawn={%d,%d}, cps={%s}, goal={%d,%d}, kill=%d } }" %
             (c["spawn"][0], c["spawn"][1], cps, c["goal"][0], c["goal"][1], c["kill"]))
    for li, lay in enumerate(d["layers"], 1):
        L.append("TD.layers[%d] = { color={%d,%d,%d}, ocol={%d,%d,%d}, par=%g, coll=%d, hidden=%d, polys={} }" %
                 (li, lay["color"][0], lay["color"][1], lay["color"][2],
                  lay["ocolor"][0], lay["ocolor"][1], lay["ocolor"][2],
                  lay["par"], lay["coll"], lay["hidden"]))
        L.append("TP = TD.layers[%d].polys" % li)
        for pi, poly in enumerate(lay["polys"], 1):
            L.append("TP[%d] = {%s}" % (pi, ",".join("%d,%d" % (x, y) for x, y in poly)))
    L.append('TRACE_DEFS["%s"] = TD' % key)
L.append("TD = nil")
L.append("TP = nil")
open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(L) + "\n")
print("wrote", OUT, os.path.getsize(OUT), "bytes")
