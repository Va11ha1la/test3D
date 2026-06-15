# -*- coding: utf-8 -*-
import json, os, re

ROOT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2"
VID = os.path.join(ROOT, "tmp", "video4")
SRC = os.path.join(ROOT, "scripts", "src", "86_trace_data.lua")
trace = json.load(open(os.path.join(VID, "video4_trace.json"), encoding="utf-8"))

# Keep the raw panorama coordinates. Existing trace runtime computes worldW = spanx2 + frw.
spanx = trace["spanx"]
spany = trace["spany"]
fw, fh = trace["FW"], trace["FH"]
# rough playable marks on stitched panorama; runtime snap-down will project to support surfaces
world_w = (spanx[1] - spanx[0]) + fw
world_h = (spany[1] - spany[0]) + fh
spawn = (80, int(world_h * 0.56))
cps = [spawn, (int(world_w * 0.34), int(world_h * 0.52)), (int(world_w * 0.66), int(world_h * 0.50))]
goal = (int(world_w * 0.90), int(world_h * 0.48))
kill = int(world_h + 260)

L = []
L.append('-- BEGIN video4 trace replica')
L.append('TD = { base={%d,%d,%d}, spanx2=%d, spany2=%d, frw=%d, frh=%d, refx=%d, refy=%d, layers={},' % (
    trace["base"][0], trace["base"][1], trace["base"][2],
    spanx[1] - spanx[0], spany[1] - spany[0], fw, fh, fw // 2, fh // 2))
cps_s = ", ".join("{%d,%d}" % p for p in cps)
L.append('  conf={ spawn={%d,%d}, cps={%s}, goal={%d,%d}, kill=%d } }' % (
    spawn[0], spawn[1], cps_s, goal[0], goal[1], kill))
for li, lay in enumerate(trace["layers"], 1):
    c = lay["color"]
    L.append('TD.layers[%d] = { color={%d,%d,%d}, ocol={%d,%d,%d}, par=%g, coll=%d, hidden=0, polys={} }' % (
        li, c[0], c[1], c[2], c[0], c[1], c[2], lay["par"], lay["coll"]))
    L.append('TP = TD.layers[%d].polys' % li)
    for pi, poly in enumerate(lay["polys"], 1):
        flat = ",".join("%d,%d" % (int(p[0] - spanx[0]), int(p[1] - spany[0])) for p in poly)
        L.append('TP[%d] = {%s}' % (pi, flat))
L.append('TRACE_DEFS["video4"] = TD')
L.append('-- END video4 trace replica')
block = "\n".join(L)

src = open(SRC, encoding="utf-8").read()
marker = 'TD = nil\nTP = nil'
if 'TRACE_DEFS["video4"]' in src:
    src = re.sub(r'\n-- BEGIN video4 trace replica.*?\n-- END video4 trace replica', '', src, flags=re.S)
idx = src.index(marker)
src = src[:idx] + block + "\n" + src[idx:]
open(SRC, "w", encoding="utf-8", newline="\n").write(src)
print('wrote video4 trace into', SRC)
print('world approx', world_w, world_h, 'spawn', spawn, 'goal', goal, 'kill', kill)
