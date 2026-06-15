-- 描摹关设计锚点(手调数据;有该数据的关停用自动撒点)
-- 坐标系 = 86_trace_data 世界坐标(竹梅:×2 + 平移,世界约 4332x880)
-- kind: gust=竹梢风袂(刷新冲刺+上升) key=蓄墨苞(激活鬼阶组) pool=墨池 char=拾字
-- 梅花点苞不在此列:仍由红色隐藏层原位聚类生成(视频原生花位)
TRACE_IPTS = {}
TRACE_IPTS.zhumei = {
    ipts = {
        -- 起|左段
        { kind = "pool", x1 = 60,   x2 = 540,  y = 760 },
        { kind = "deco", x = 350,  y = 600 },
        { kind = "gust", x = 716,  y = 520 },
        { kind = "deco", x = 1245, y = 520 },
        -- 转|中段竖塔
        { kind = "gust", x = 1748, y = 64 },
        { kind = "char", x = 1810, y = 16,  ch = "疏" },
        -- 承|大断口(2100→2950):蓄墨苞实体化三根浮墨条(两岸各一苞,可回程)
        { kind = "key",  x = 2148, y = 392, grp = 1 },
        { kind = "key",  x = 2962, y = 596, grp = 1 },
        { kind = "char", x = 2600, y = 452, ch = "影" },
        { kind = "pool", x1 = 2480, x2 = 2900, y = 760 },
        -- 合|梅树区
        { kind = "gust", x = 3032, y = 330 },
        { kind = "char", x = 3520, y = 792, ch = "横" },
        { kind = "deco", x = 3900, y = 600 },
        { kind = "char", x = 4290, y = 262, ch = "斜" },
    },
    -- 苔点:断口底右壁的逃生暗示(纯视觉,非交互)
    hints = {
        { x = 2912, y = 792 }, { x = 2926, y = 748 }, { x = 2940, y = 704 },
    },
    -- 区内完整包含的碰撞体转为鬼阶(虚影,激活后 300 帧实体)
    ghosts = {
        { zone = { 2200, 380, 2880, 620 } },
    },
}

TRACE_IPTS.bamboo_v2 = {
    ipts = {
        { kind = "char", x = 1100, y = 2080, ch = "咬" },
        { kind = "char", x = 1550, y = 2100, ch = "定" },
        { kind = "char", x = 1840, y = 2200, ch = "青" },
        { kind = "char", x = 2010, y = 1530, ch = "山" },
        { kind = "char", x = 2500, y = 1180, ch = "不" },
        { kind = "char", x = 2760, y = 1150, ch = "放" },
        { kind = "char", x = 3200, y = 1050, ch = "松" },
        { kind = "char", x = 4010, y = 1080, ch = "千" },
        { kind = "char", x = 4400, y = 840, ch = "磨" },
        { kind = "char", x = 4560, y = 1460, ch = "万" },
        { kind = "char", x = 4860, y = 1860, ch = "击" },
        { kind = "char", x = 6000, y = 1800, ch = "还" },
        { kind = "char", x = 6500, y = 1800, ch = "坚" },
        { kind = "char", x = 7000, y = 1600, ch = "劲" },
        { kind = "char", x = 7600, y = 1600, ch = "任" },
        { kind = "char", x = 8000, y = 1600, ch = "尔" },
        { kind = "char", x = 8250, y = 1550, ch = "东" },
        { kind = "char", x = 8350, y = 1580, ch = "西" },
    },
    hints = {
        { x = 3700, y = 1500 }, { x = 3750, y = 1550 },
        { x = 5200, y = 2280 }, { x = 5250, y = 2290 },
    },
}
