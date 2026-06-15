# -*- coding: utf-8 -*-
import sys, importlib.util
spec = importlib.util.spec_from_file_location("am", r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\author_molong.py")
am = importlib.util.module_from_spec(spec); spec.loader.exec_module(am)

H = 1032
def wx(sx): return round(sx*2, 1)
def wy(sy): return round((H-sy)*2, 1)

L = []
L.append("-- ==== 墨龙行关卡数据(由 tmp/author_molong.py 生成,勿手改) ====")
L.append("SPINES = {")
for name, pts in am.SPINES.items():
    s = ", ".join("{%g,%g,%g}" % (wx(x), wy(y), r*2) for (x,y,r) in pts)
    L.append("  { %s }," % s)
L.append("}")
L.append("LEDGES = {")
row = []
for (a,b,y) in am.LEDGES:
    row.append("{%g,%g,%g}" % (wx(a), wx(b), wy(y)))
L.append("  " + ", ".join(row))
L.append("}")
L.append("WINDS = {")
for (x,y,r,s) in am.WINDS:
    L.append("  {%g,%g,%g,%g}," % (wx(x), wy(y), r*2, s))
L.append("}")
L.append("PEARLS = {")
for (x,y,c) in am.PEARLS:
    L.append('  {x=%g, y=%g, kind="%s"},' % (wx(x), wy(y), c))
L.append("}")
L.append("SPAWN_X, SPAWN_Y = %g, %g" % (wx(am.SPAWN[0]), wy(am.SPAWN[1])))
L.append("WORLD_W, WORLD_H = %g, %g" % (19910*2, H*2))
data = "\n".join(L)

tpl_path = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\scripts\main3d.lua"
src = open(tpl_path, encoding="utf-8").read()
if "-- @DATA@" in src:
    src = src.replace("-- @DATA@", data)
    open(tpl_path, "w", encoding="utf-8").write(src)
    print("data injected into main3d.lua")
else:
    open(r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\molong_data.lua", "w", encoding="utf-8").write(data)
    print("main3d.lua has no @DATA@ marker; wrote tmp/molong_data.lua")
