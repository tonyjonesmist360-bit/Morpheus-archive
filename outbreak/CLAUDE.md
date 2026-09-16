# CLAUDE.md — Outbreak shakedown

You are working on a FiveM server pack called **Outbreak** (Project Zomboid survival RP on QBox). Tony built it
with Claude in chat over many sessions. **Nothing has ever run on FXServer.** Your job tonight is to get it
booting, run the smoke script with Tony, and patch what breaks — not to add features.

## Ground truth (read these first, in this order)
1. `ARCHITECTURE.md` — the ownership contract: who owns which state, the one tick loop, statebags, event list, server-authority audit. Every patch must obey it.
2. `KNOWN_LIMITATIONS.md` — the 23 things we already expect to be wrong (native/anim/prop names from memory, coordinates, framework API assumptions, pma-voice event, OneSync behaviour). If a failure matches one, it is not a surprise: fix it the way the entry suggests.
3. `SMOKE-SCRIPT.md` — the evening, top to bottom. Tony drives; you watch logs and patch.
4. `INSTALL-WALKTHROUGH.md` — only if the server isn't installed yet (Parts 1–7, MariaDB standalone not XAMPP).
5. `server.cfg.additions` — the start order. It is ordered by dependency; do not reorder casually.
6. `MANIFEST.md`, `CONFIG.md`, `INTEGRATION_REPORT.md` for reference.

## Layout
```
resources/[outbreak]/              the slice + services (ensured)
resources/[outbreak_extended]/     held (commented out) — vehicles v2, craft, military, stations, raiders, camps, broadcast, map
resources/[outbreak_progression]/  ENSURED since v0.22 — outbreak_intel, outbreak_opportunities (5 chains)
CORE-MECHANICS.md                  the protected-mechanics list + review rule: read before touching controls/clipsets/tasks
outbreak_tuning/shared/defaults.lua every magic number; consumers read GlobalState.obTune (BALANCE-TUNING.md). New knob = new key here
outbreak_log                       exports.outbreak_log:log(kind, src, details) for anything an admin would ask "why" about (ADMIN-COMMANDS.md)
TEST-GUIDE.md                      GENERATED from outbreak_debug/client/shakedown.lua by tools/gen_test_guide.py - never hand-edit
sql/migrations/001..008            apply in order, idempotent
tools_diag*.py + tools_luac.py     static analyzers — run ALL FOUR after every patch:
                                   `python tools_diag.py && python tools_diag2.py && python tools_diag3.py && python tools_luac.py`
                                   (pass 3 covers undefined helpers, client-only natives on the server,
                                    manifest includes and forward references; luac is a real Lua 5.4
                                    parse of every file — the closest thing to a boot without FXServer)
ops/                               backup/restore
```
Live server files live in `C:\Outbreak\txData\` (resources/ and server.cfg). The pack source of truth is `C:\Outbreak\pack\`. Every setup script takes `-Base "C:\Outbreak\txData"`. Copy resources into the live tree, don't edit the live tree only.

## Hard rules
- **Patch, don't rewrite.** Smallest change that fixes the failure. Preserve the ownership contract, the single tick loop, and server authority. If a fix needs a second polling loop or a client deciding an outcome, stop and say so.
- **Anchor-safe edits.** When editing Lua, confirm the exact anchor text exists once before replacing. Never regenerate a whole file to fix one line.
- **Every patch:** (1) make the change in the pack folder, (2) run all four analyzers, (3) copy to the live tree, (4) `restart <resource>` in txAdmin console, (5) tell Tony what to retry and which smoke step.
- **Settlements / Director** (v0.16): `DESIGN-supply.md` is the contract. The stockpile is the house stash — never add a second store. Both ticks go through `outbreak_core:scheduleEvent`; do not add a thread.
- **Log discipline.** Tail `txData\logs\fxserver.log` (or the txAdmin live console) for `outbreak_` lines. Read `resources/[outbreak]/outbreak_debug/shakedown.log` (JSON lines) for Tony's pass/fail marks and notes — that is the shared record. Append your own findings to `SHAKEDOWN-NOTES.md` in the pack root: step, symptom, root cause, patch, status.
- **Ordering.** Boot → instrumentation (`/ob_animcheck`, `/ob_models`, `/ob_walk`) → fix name classes in one pass each → then the rest of the script. Don't chase a wound bug while three anim dictionaries are still wrong.
- **Framework API.** qbx_core runs a qb-core bridge; we call `exports['qb-core']:GetCoreObject()`. If the bridge is off, the fix is enabling it in qbx config, not rewriting resources. `exports.qbx_core:Logout`, `illenium-appearance` exports, `mm_radio` exports, `pma-voice` `getRadioChannel`/`setTalkingOnRadio` are the likeliest wrong names — check their actual source in `resources/` before guessing.
- **Extended groups** other than vehicles and craft stay held (military, stations, raiders, camps, broadcast, map). `[outbreak_progression]` is ensured since v0.22. Enable anything further in the order the cfg comments give, one group per restart.
- **Don't** touch ox_inventory / qbx_core / ox_lib internals; only our resources and the documented paste-ins (`ox_items_snippet.lua`, `weapons_snippet.lua`, `jobs_snippet.lua`).
- **Core mechanics are protected.** Any change that hooks input, controls, clipsets, ped tasks or ped events goes through `CORE-MECHANICS.md` (conditional, restores on every exit, one owner per native, no per-frame loops, F9 K-step updated).
- **Debug is debug.** `setr ob_debug 1` and `ensure outbreak_debug` tonight; both come out before the crew joins.

## How to talk to Tony
Short. He's playing. Lead with what to do next ("retry W2"), then what you changed, one line each. Ask before anything destructive (DB changes, deleting files, reordering the cfg). If you're not sure a native/export name is right, say "unverified" — don't present a guess as a fix.

## When something is bigger than a patch
Log it in `SHAKEDOWN-NOTES.md` under **Deferred**, with the smoke step and a one-line proposal, and move on. Tony and chat-Claude design those after the evening; you don't.
