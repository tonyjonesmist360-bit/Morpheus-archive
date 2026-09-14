#!/usr/bin/env python3
"""
tools_luac.py - real Lua 5.4 parse of every script in the pack (luac -p), the closest
thing to a boot we can do without FXServer. Catches what regex analyzers cannot:
unbalanced blocks, stray tokens, bad string escapes, `local` in expression position.

FiveM extensions that stock luac rejects are rewritten before parsing:
  `HASH_NAME`   -> 0        (backtick joaat literal)
Everything else FiveM adds (vector3, exports, Citizen.*) is a plain global to the parser.

Run with the other three:
    python tools_diag.py && python tools_diag2.py && python tools_diag3.py && python tools_luac.py
"""
import os, re, subprocess, sys, tempfile

GROUPS = ('[outbreak]', '[outbreak_extended]', '[outbreak_progression]')
LUAC = None
for c in ('luac5.4', 'luac54', 'luac'):
    try:
        subprocess.run([c, '-v'], capture_output=True, check=True); LUAC = c; break
    except Exception: pass
if not LUAC:
    print("luac not found - install lua5.4 (apt: lua5.4) or skip this pass"); sys.exit(2)

def files():
    for g in GROUPS:
        base = os.path.join('resources', g)
        if not os.path.isdir(base): continue
        for res in sorted(os.listdir(base)):
            rd = os.path.join(base, res)
            if not os.path.isdir(rd): continue
            for root, _d, fs in os.walk(rd):
                for fn in sorted(fs):
                    # data/*_snippet.lua are paste-in fragments (table bodies), not files
                    if fn.endswith('.lua') and not (os.sep + 'data' + os.sep in root + os.sep and fn.endswith('_snippet.lua')):
                        yield res, os.path.join(root, fn)

errors, n = [], 0
for res, path in files():
    src = open(path, encoding='utf-8', errors='replace').read()
    if src.startswith('﻿'):
        errors.append(f"**{res}** - `{path}` starts with a UTF-8 BOM"); src = src[1:]
    src = re.sub(r'`[^`\n]*`', '0', src)
    with tempfile.NamedTemporaryFile('w', suffix='.lua', delete=False, encoding='utf-8') as t:
        t.write(src); tmp = t.name
    r = subprocess.run([LUAC, '-p', tmp], capture_output=True, text=True)
    os.unlink(tmp); n += 1
    if r.returncode != 0:
        msg = r.stderr.strip().replace(tmp, os.path.relpath(path))
        errors.append(f"**{res}** - {msg}")

print(f"# LUA PARSE ({LUAC}) - {n} files\n")
print(f"## ERROR ({len(errors)})\n")
for e in errors: print(f"- {e}")
sys.exit(1 if errors else 0)
