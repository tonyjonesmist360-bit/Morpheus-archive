#!/usr/bin/env python3
"""Generate TEST-GUIDE.md from outbreak_debug/client/shakedown.lua so the doc and the F9 menu never drift."""
import re, io, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = io.open(os.path.join(ROOT, 'resources/[outbreak]/outbreak_debug/client/shakedown.lua'), encoding='utf-8').read()
rows = re.findall(r"\{\s*sec = '((?:[^'\\]|\\.)*)',\s*id = '([^']+)',\s*label = '((?:[^'\\]|\\.)*)',\s*cmd = '((?:[^'\\]|\\.)*)',\s*expect = '((?:[^'\\]|\\.)*)'\s*\}", src)
un = lambda s: s.replace("\\'", "'")
PRE = """# TEST-GUIDE — the F9 run (v0.22)

Keep this beside you. **F9** opens the same list in game; **M** gives it the mouse so the PASS / FAIL buttons
work, **Esc** or **M** hands the mouse back. Passive keys: ▲▼ select, **P** pass, **F** fail, **N** note, **L** export.
Results land in `resources/[outbreak]/outbreak_debug/shakedown-results.md` (readable) and `shakedown.log`
(raw). Paste the .md to Claude. `/bug <text>` from anywhere appends to `bugs.log`.

## Setup before you start
- `setr ob_debug 1` is in the cfg (F9 refuses without it). `ob_kit` gives the whole slice kit.
- **Second player** for T3/T4 (crew), U7 (a punch), K2 (passenger). Solo: mark those with a note.
- **Infection test (T2)** needs a zombie wound left 20 minutes. To shorten: `NeedsCfg.Infection.dirtyMinutes = 1`
  in `outbreak_needs/shared/config.lua`, `restart outbreak_needs`, then set it back.
- **Vehicle persistence (T6)** needs a server restart mid-run. Do it after T8 so nothing else is half-done.
- **Sandy 24/7 cleanup (E7)** is a console command: `ob_scene_clear 1960.5 3740.6 32.3 45`. It writes a backup
  (`outbreak_worlditems/cleared-*.json`); `ob_scene_restore <file>` undoes it.
- **Model names** (`ob_models`), walk styles, sprite ids and anim clips are from memory. Anything INVALID:
  note it on the step. That is a name fix, not a system failure.
- Every mark is timestamped and attributed, so two people can test at once.

## Run order
Boot → Core mechanics → UI + body scan → Economy / looting → Story + factions → Ten additions → Prior sheet → Legacy.
Core mechanics first on purpose: if K1 or K4 fail, stop and tell me before anything else.

"""
out = [PRE]
last = None
for sec, sid, label, cmd, expect in rows:
    if sec != last:
        out.append(f"\n## {un(sec)}\n\n| # | Test | Do | Expect |\n|---|---|---|---|")
        last = sec
    out.append(f"| {sid} | {un(label)} | {un(cmd)} | {un(expect)} |")
out.append(f"\n---\nGenerated {datetime.date.today()} by tools/gen_test_guide.py from shakedown.lua ({len(rows)} steps). Edit the Lua, rerun the script.\n")
io.open(os.path.join(ROOT, 'TEST-GUIDE.md'), 'w', encoding='utf-8').write('\n'.join(out))
print(f'TEST-GUIDE.md: {len(rows)} steps')
