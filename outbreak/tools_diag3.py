#!/usr/bin/env python3
"""
tools_diag3.py - the bug classes that slipped past tools_diag.py and tools_diag2.py
during the 2026-09-13 first boot. Each check exists because a real bug got through.

  1. Undefined helper calls      -> FB-6: outbreak_faction called cid() which was never defined
  2. Client-only natives on the server -> FB-8: outbreak_needs called SetEntityHealth server-side
  3. Manifest includes vs globals used -> PB-4: outbreak_faction used MySQL without @oxmysql
  4. Config key paths            -> a CfgTable.a.b that no config file defines
  5. Cross-resource exports      -> exports.outbreak_x:y() with no matching exports('y')

Run alongside the other two:
    python tools_diag.py && python tools_diag2.py && python tools_diag3.py
"""
import re, os, glob, sys

GROUPS = ('[outbreak]', '[outbreak_extended]', '[outbreak_progression]')

STDLIB = set("""assert collectgarbage dofile error getmetatable ipairs load loadstring next pairs pcall
print rawequal rawget rawlen rawset require select setmetatable tonumber tostring type unpack xpcall
math table string os io coroutine debug bit32 utf8 json msgpack vector2 vector3 vector4 quat
exports export source""".split())
# Real FiveM/CFX globals that look like plain lowercase calls.
FIVEM_GLOBALS = set("""joaat vec vec2 vec3 vec4 lib cache exports source msgpack promise
Citizen GetConvar GetConvarInt SetConvar TriggerEvent TriggerServerEvent TriggerClientEvent
AddEventHandler RegisterNetEvent RegisterCommand CreateThread Wait SetTimeout""".split())

LUA_KW = set("and break do else elseif end false for function goto if in local nil not or repeat return then true until while".split())

# Natives that do NOT exist in the server runtime. Conservative list: every entry here
# is one we either hit or can state confidently. False negatives are fine, false
# positives are not - a noisy checker gets ignored.
CLIENT_ONLY = {
    'SetEntityHealth', 'PlayerPedId', 'PlayerId', 'SetPedMovementClipset',
    'SetPedComponentVariation', 'SetPedPropIndex', 'RequestModel', 'HasModelLoaded',
    'RequestAnimDict', 'HasAnimDictLoaded', 'RequestAnimSet', 'HasAnimSetLoaded',
    'TaskPlayAnim', 'ClearPedTasks', 'SetNuiFocus', 'SendNUIMessage',
    'IsControlJustPressed', 'IsControlPressed', 'DrawText', 'DrawMarker',
    'SetEntityInvincible', 'SetEntityVisible', 'NetworkFadeOutEntity',
    'StartScreenEffect', 'DoScreenFadeOut', 'DoScreenFadeIn', 'SetPedArmour',
}

def strip(src):
    """Remove comments AND string literals. Without the strings, SQL table names like
    'INSERT INTO outbreak_memorial (' parse as function calls."""
    src = re.sub(r'--\[\[.*?\]\]', '', src, flags=re.S)
    src = re.sub(r'--.*', '', src)
    src = re.sub(r'\[\[.*?\]\]', '""', src, flags=re.S)   # long strings
    src = re.sub(r"'(\\.|[^'\\])*'", "''", src)
    src = re.sub(r'"(\\.|[^"\\])*"', '""', src)
    src = re.sub(r'`[^`]*`', '0', src)                      # hash literals
    return src

def resources():
    # NOTE: glob treats [outbreak] as a character class, exactly like PowerShell does.
    # Use listdir, not glob, for any path containing the bracketed group folders.
    out = []
    for g in GROUPS:
        base = os.path.join('resources', g)
        if not os.path.isdir(base): continue
        for n in sorted(os.listdir(base)):
            d = os.path.join(base, n)
            if os.path.isdir(d): out.append(d)
    return out

def lua_files(res, sub=None):
    out = []
    for root, _dirs, files in os.walk(res):
        for fn in files:
            if fn.endswith('.lua') and fn != 'fxmanifest.lua':
                p = os.path.join(root, fn)
                if sub and os.sep + sub + os.sep not in p + os.sep: continue
                out.append(p)
    return sorted(out)

errors, warns, infos = [], [], []

# ---------------------------------------------------------------- 1 + 2 + 4
all_cfg_defs = {}          # CfgName -> set of top-level keys
for res in resources():
    for f in [x for x in lua_files(res) if (os.sep+'shared'+os.sep in x or os.sep+'client'+os.sep in x)]:
        src = strip(open(f, encoding='utf-8', errors='replace').read())
        for m in re.finditer(r'^([A-Z][A-Za-z]*Cfg)\s*=\s*\{', src, re.M):
            name = m.group(1)
            body = src[m.end():]
            depth, end = 1, 0
            for i, ch in enumerate(body):
                if ch == '{': depth += 1
                elif ch == '}':
                    depth -= 1
                    if depth == 0: end = i; break
            inner, depth2 = body[:end], 0
            keys = set()
            for mm in re.finditer(r'([{}])|([A-Za-z_]\w*)\s*=', inner):
                if mm.group(1) == '{': depth2 += 1
                elif mm.group(1) == '}': depth2 -= 1
                elif mm.group(2) is not None and depth2 == 0: keys.add(mm.group(2))
            all_cfg_defs.setdefault(name, set()).update(keys)
        # Keys can also be assigned outside the constructor: EmoteCfg.Actions = { ... }
        for m in re.finditer(r'^([A-Z][A-Za-z]*Cfg)\.([A-Za-z_]\w*)\s*=', src, re.M):
            all_cfg_defs.setdefault(m.group(1), set()).add(m.group(2))

for res in resources():
    name = os.path.basename(res)
    files = [f for f in lua_files(res) if os.sep + 'data' + os.sep not in f]
    defined, called = set(), {}
    for f in files:
        src = strip(open(f, encoding='utf-8', errors='replace').read())
        rel = os.path.relpath(f, res)
        for pat in (r'\blocal\s+function\s+([A-Za-z_]\w*)',
                    r'(?<!\.)\bfunction\s+([A-Za-z_]\w*)\s*\(',
                    r'^\s*([A-Za-z_]\w*)\s*=\s*function'):
            for m in re.finditer(pat, src, re.M): defined.add(m.group(1))
        for m in re.finditer(r'\blocal\s+([A-Za-z_][\w,\s]*?)\s*=', src):
            for n in m.group(1).split(','): defined.add(n.strip())
        # parameters are callables too (callbacks: cb, fn, handler...)
        for m in re.finditer(r'function\s*(?:[A-Za-z_][\w.:]*)?\s*\(([^)]*)\)', src):
            for n in m.group(1).split(','):
                n = n.strip()
                if re.fullmatch(r'[A-Za-z_]\w*', n): defined.add(n)
        for m in re.finditer(r'\bfor\s+([A-Za-z_][\w,\s]*?)\s+(?:=|in)\b', src):
            for n in m.group(1).split(','): defined.add(n.strip())
        for m in re.finditer(r'(?<![\w.:])([a-z_]\w*)\s*\(', src):
            n = m.group(1)
            if n not in STDLIB and n not in LUA_KW and n not in FIVEM_GLOBALS:
                called.setdefault(n, set()).add(rel)
        # 2. client-only natives in server scripts
        if os.sep + 'server' + os.sep in f:
            for nat in CLIENT_ONLY:
                for m in re.finditer(r'(?<![\w.:])' + nat + r'\s*\(', src):
                    line = src[:m.start()].count('\n') + 1
                    errors.append(f"**{name}** - `{nat}` is client-only, called in `{rel}:{line}`")
        # 4. config key paths
        for m in re.finditer(r'\b([A-Z][A-Za-z]*Cfg)\.([A-Za-z_]\w*)', src):
            cfg, key = m.group(1), m.group(2)
            if cfg in all_cfg_defs and key not in all_cfg_defs[cfg]:
                line = src[:m.start()].count('\n') + 1
                infos.append(f"**{name}** - `{cfg}.{key}` not defined in any config, used in `{rel}:{line}`")
    for n, where in sorted(called.items()):
        if n not in defined:
            errors.append(f"**{name}** - `{n}()` called but never defined ({', '.join(sorted(where))})")

# ---------------------------------------------------------------- 3
for res in resources():
    name = os.path.basename(res)
    man = os.path.join(res, 'fxmanifest.lua')
    if not os.path.isfile(man): continue
    manifest = open(man, encoding='utf-8', errors='replace').read()
    body = ' '.join(strip(open(f, encoding='utf-8', errors='replace').read())
                    for f in lua_files(res) if os.sep + 'data' + os.sep not in f)
    if re.search(r'(?<![\w.])MySQL\.', body) and 'oxmysql' not in manifest:
        errors.append(f"**{name}** - uses `MySQL.*` but the manifest never includes `@oxmysql/lib/MySQL.lua`")
    if re.search(r'(?<![\w.])lib\.', body) and '@ox_lib/init.lua' not in manifest:
        errors.append(f"**{name}** - uses `lib.*` but the manifest never includes `@ox_lib/init.lua`")
    if re.search(r'(?<![\w.])cache\.', body) and '@ox_lib/init.lua' not in manifest:
        errors.append(f"**{name}** - uses `cache.*` but the manifest never includes `@ox_lib/init.lua`")

# ---------------------------------------------------------------- 5
defined_exports = {}
for res in resources():
    # RAW source here on purpose: export names live inside string literals, and
    # strip() removes those. Stripping first made every export look undefined.
    body = ' '.join(open(f, encoding='utf-8', errors='replace').read()
                    for f in lua_files(res))
    defined_exports[os.path.basename(res)] = set(re.findall(r"exports\(\s*'([A-Za-z_]\w*)'", body))
for res in resources():
    name = os.path.basename(res)
    for f in lua_files(res):
        raw = open(f, encoding='utf-8', errors='replace').read()
        src = re.sub(r'--.*', '', raw)
        rel = os.path.relpath(f, res)
        for m in re.finditer(r"exports\.?\[?'?(outbreak_[a-z]+)'?\]?:([A-Za-z_]\w*)", src):
            target, fn = m.group(1), m.group(2)
            if target in defined_exports and fn not in defined_exports[target]:
                line = src[:m.start()].count('\n') + 1
                errors.append(f"**{name}** - `exports.{target}:{fn}()` has no matching `exports('{fn}')` ({rel}:{line})")

print("# SYSTEMS CHECK - pass 3 (classes that slipped past passes 1 and 2)\n")
print(f"Resources: {len(resources())}\n")
for label, items in (('ERROR', errors), ('WARN', warns), ('INFO', infos)):
    print(f"\n## {label} ({len(items)})\n")
    for i in sorted(set(items)): print(f"- {i}")
sys.exit(1 if errors else 0)
