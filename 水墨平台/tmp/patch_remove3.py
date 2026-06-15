# -*- coding: utf-8 -*-
"""移除 17 富春 / 18 六君子 / 19 墨荷 三关"""
import io, re

def rd(p): return io.open(p, encoding='utf-8').read()
def wr(p, s): io.open(p, 'w', encoding='utf-8').write(s)

def cut_level_entry(s, lid):
    i = s.find('id = "%s"' % lid)
    assert i > 0, lid
    a = s.rfind('    {', 0, i)
    b = s.find('    },', i) + len('    },\n')
    return s[:a] + s[b:]

def cut_fn(s, name):
    i = s.find('function %s()' % name)
    assert i >= 0, name
    j = s.find('\nend\n', i) + len('\nend\n')
    return s[:i].rstrip() + '\n\n' + s[j:].lstrip('\n')

# 00
p = 'scripts/src/00_state_levels_keys.lua'
s = rd(p)
for lid in ('fuchun', 'nizan', 'bada_lotus'):
    s = cut_level_entry(s, lid)
wr(p, s)
print('00 ok')

# 30
p = 'scripts/src/30_level_generation.lua'
s = rd(p)
for fn in ('generateFuchun', 'generateNizan', 'generateBadaLotus'):
    s = cut_fn(s, fn)
wr(p, s)
print('30 ok')

# 40
p = 'scripts/src/40_gameplay_targets.lua'
s = rd(p)
for lid, fn in (('fuchun', 'generateFuchun'), ('nizan', 'generateNizan'), ('bada_lotus', 'generateBadaLotus')):
    line = '    elseif currentLevel.id == "%s" then %s()\n' % (lid, fn)
    assert line in s, lid
    s = s.replace(line, '')
# spawn blocks
for lid in ('fuchun', 'nizan', 'bada_lotus'):
    m = re.search(r'    elseif currentLevel\.id == "%s" then\n(.*?\n)*?        player\.facingRight = true\n' % lid, s)
    assert m, lid
    s = s[:m.start()] + s[m.end():]
wr(p, s)
print('40 ok')

# 60
p = 'scripts/src/60_background_render.lua'
s = rd(p)
old = '''    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" or currentLevel.id == "fuchun"
        or currentLevel.id == "nizan" or currentLevel.id == "bada_lotus" then'''
assert old in s
s = s.replace(old, '''    elseif currentLevel.id == "wentong_zhu" or currentLevel.id == "plum_xiyan"
        or currentLevel.id == "xuwei_grape" then''')
# 删三段 per-id 背景
for lid in ('fuchun', 'nizan', 'bada_lotus'):
    i = s.find('        elseif currentLevel.id == "%s" then' % lid)
    assert i > 0, lid
    j = s.find('        elseif', i + 10)
    s = s[:i] + s[j:]
wr(p, s)
print('60 ok')

# 70: decor 三段 + bloom 三段
p = 'scripts/src/70_entities_targets_render.lua'
s = rd(p)
i = s.find('    if currentLevel.id == "fuchun" then')
assert i > 0
j = s.find('    if currentLevel.id == "wentong_zhu" then', i)
assert j > i
s = s[:i] + s[j:]
for lid in ('fuchun', 'nizan', 'bada_lotus'):
    i = s.find('        elseif b.kind == "%s" then' % lid)
    assert i > 0, lid
    j = s.find('        elseif b.kind == ', i + 10)
    s = s[:i] + s[j:]
wr(p, s)
print('70 ok')

# 90 seals
p = 'scripts/src/90_world_seal_runtime.lua'
s = rd(p)
for lid in ('fuchun', 'nizan', 'bada_lotus'):
    i = s.find('    elseif currentLevel.id == "%s" then' % lid)
    assert i > 0, lid
    j = s.find('    elseif', i + 10)
    s = s[:i] + s[j:]
wr(p, s)
print('90 ok')

# checker
p = 'tools/reachability_check.py'
s = rd(p)
for fn in ('gen_fuchun', 'gen_nizan', 'gen_bada'):
    i = s.find('def %s(geo):' % fn)
    assert i >= 0, fn
    j = s.find('\ndef ', i + 5)
    if j < 0:
        j = s.find('# ---------------------------------------------------------------- 主流程', i)
        s = s[:i] + s[j:]
    else:
        s = s[:i] + s[j + 1:]
for row in ('fuchun', 'nizan', 'bada_lotus'):
    m = re.search(r'    \(\d+, "[^"]*%s[^"]*".*?\),\n' % row, s)
    assert m, row
    s = s[:m.start()] + s[m.end():]
wr(p, s)
print('checker ok')
