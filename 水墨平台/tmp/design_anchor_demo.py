# -*- coding: utf-8 -*-
# 例图v2:从 kb_trace_v2.json 真实数据自动提取语义锚点(竹竿顶/红苞原位/地面段/黑墨池)
# 这是"语义标注 pass"的可行性演示,同时产出讨论用例图
import json, os, math
from PIL import Image, ImageDraw, ImageFont

VID = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\vid"
OUT = r"C:\Users\202102-91\Desktop\项目\横板平台跳跃\UrhoX2\tmp\design_l18_proposal.png"
fr = json.load(open(os.path.join(VID, "kb_trace_v2.json")))

SC = 2  # 与游戏一致 ×2
sx1, sy1 = fr["spanx"][0]*SC, fr["spany"][0]*SC
Sx, Sy = -sx1, -sy1
W = fr["spanx"][1]*SC + Sx
H = fr["spany"][1]*SC + Sy

XUAN = {
    (216,213,207):(243,239,229),(197,194,190):(229,225,214),(181,179,174):(212,208,197),
    (157,153,150):(188,184,175),(138,138,134):(162,160,151),(113,112,110):(131,129,122),
    (78,84,79):(86,95,82),(55,55,53):(46,44,41),(33,33,32):(25,23,21),
}
RED_C, YEL_C = (150,45,60), (158,160,98)

DS = 0.42  # 显示缩放
PAD, TOP = 30, 64
img = Image.new("RGB", (int(W*DS)+PAD*2, int(H*DS)+TOP+PAD+200), (250,247,238))
dr = ImageDraw.Draw(img, "RGBA")
F  = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 22)
Fs = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 18)
Fb = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 28)

def V(x, y): return PAD + x*DS, TOP + y*DS

red_polys, dark_polys = [], []
for lay in fr["layers"]:
    c = tuple(lay["color"])
    if c in (RED_C, YEL_C):
        if c == RED_C:
            for p in lay["polys"]:
                red_polys.append([(q[0]*SC+Sx, q[1]*SC+Sy) for q in p])
        continue  # 红黄程序花,不画底色
    col = XUAN.get(c, c)
    for p in lay["polys"]:
        pts = [(q[0]*SC+Sx, q[1]*SC+Sy) for q in p]
        if len(pts) >= 3:
            dr.polygon([V(x,y) for x,y in pts], fill=col)
        if lay["coll"] == 1:
            dark_polys.append(pts)

def bbox(p):
    xs=[q[0] for q in p]; ys=[q[1] for q in p]
    return min(xs),min(ys),max(xs),max(ys)

# ---- 语义分类 ----
stalks, grounds, pools = [], [], []
for p in dark_polys:
    x1,y1,x2,y2 = bbox(p)
    w,h = x2-x1, y2-y1
    if h >= 320 and w <= 190 and h/max(w,1) >= 2.2:
        # 竹竿:锚点取顶部中心
        topy = y1; topxs=[q[0] for q in p if q[1] < y1+h*0.12]
        stalks.append((sum(topxs)/len(topxs) if topxs else (x1+x2)/2, topy))
    elif w >= 420 and w/max(h,1) >= 2.4 and y1 > H*0.45:
        grounds.append((x1,y1,x2,y2))
        if w >= 700: pools.append(((x1+x2)/2, y1))

# 红苞原位(视频本来的花位):聚类质心
buds = []
for p in red_polys:
    x1,y1,x2,y2 = bbox(p)
    cx,cy=(x1+x2)/2,(y1+y2)/2
    for b in buds:
        if (b[0]-cx)**2+(b[1]-cy)**2 < 130**2:
            break
    else:
        buds.append((cx,cy))

GREEN=(46,110,60); RED=(168,32,54); PINK=(196,84,110); BLUE=(58,92,128); GOLD=(146,110,38)

def mark(x, y, r, color, label=None, below=False):
    X,Y=V(x,y)
    dr.ellipse([X-r,Y-r,X+r,Y+r], outline=color, width=4)
    dr.ellipse([X-3,Y-3,X+3,Y+3], fill=color)
    if label:
        tw=dr.textlength(label,font=Fs)
        tx,ty=X-tw/2, Y+(r+5 if below else -r-27)
        tx=max(4,min(tx,img.width-tw-8))
        dr.rectangle([tx-4,ty-2,tx+tw+4,ty+23], fill=(250,247,238,220))
        dr.text((tx,ty),label,font=Fs,fill=color)

# 竹梢风袂:只取够高且彼此 >600 间距的竿顶
stalks.sort(key=lambda s:s[0])
picked=[]
for sx_,sy_ in stalks:
    if sy_ < H*0.55 and all(abs(sx_-p[0])>600 for p in picked):
        picked.append((sx_,sy_))
for i,(x,y) in enumerate(picked):
    mark(x,y,15,GREEN, "风袂%d"%(i+1) if i%2==0 else None)

# 梅枝点苞:红苞原位
buds.sort(key=lambda b:b[0])
for i,(x,y) in enumerate(buds):
    mark(x,y,12,RED, "点苞%d"%(i+1) if i in (0,len(buds)-1) else None, below=True)

# 墨池涟漪:宽黑地面中点
for i,(x,y) in enumerate(pools[:4]):
    mark(x,y,12,BLUE, "墨池" if i==0 else None, below=True)

# 花开生桥:找相邻地面段之间最宽的横向断口
grounds.sort(key=lambda g:g[0])
best=None
for a in grounds:
    for b in grounds:
        gap = b[0]-a[2]
        if 260 < gap < 900 and abs(a[1]-b[1]) < 260:
            if best is None or gap > best[0]: best=(gap,a,b)
if best:
    _,a,b = best
    x1,y1 = a[2], a[1]; x2,y2 = b[0], b[1]
    pts=[]
    for i in range(25):
        t=i/24
        pts.append(V(x1+(x2-x1)*t, y1+(y2-y1)*t - math.sin(t*math.pi)*60))
    for i in range(0,24,2):
        dr.line([pts[i],pts[i+1]], fill=PINK, width=4)
    mark(x1,y1,12,PINK,"花开生桥(苞→枝桥)")

# 拾字:挑两个中段高处竿顶旁
if len(picked)>=3:
    gx,gy = picked[len(picked)//2]
    mark(gx+170, gy+130, 11, GOLD, "拾字「疏」", below=True)

# 标题+图例
dr.text((PAD,14),"第18关·水墨竹梅|语义锚点自动提取(真实数据例图)",font=Fb,fill=(60,56,50))
lg=[(GREEN,"竹梢风袂:竹竿顶自动锚(高瘦碰撞体 h/w≥2.2)— 上升气流+刷新冲刺"),
    (RED,  "梅枝点苞:用视频原红苞坐标(红层质心)— 连锁开花,集满开终点"),
    (PINK, "花开生桥:自动找最宽地面断口 — 触苞5秒长出枝桥"),
    (GOLD, "拾字:题跋文字散布高路线 — 终幕画卷补全落款"),
    (BLUE, "墨池涟漪:宽黑地面专属 — 墨晕+短滑步,替代'黑地长花'")]
y0=img.height-len(lg)*32-16
dr.rectangle([10,y0-8,860,img.height-8],fill=(244,240,230,255))
for i,(c,t) in enumerate(lg):
    yy=y0+i*32
    dr.ellipse([20,yy+5,40,yy+25],outline=c,width=4)
    dr.text((50,yy+2),t,font=Fs,fill=(60,56,50))

img.save(OUT)
print("saved",OUT,img.size,"stalks=%d picked=%d buds=%d grounds=%d"%(len(stalks),len(picked),len(buds),len(grounds)))
