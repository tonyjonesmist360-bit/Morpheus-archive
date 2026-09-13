# START HERE — Outbreak v0.13.3

Everything needed for the first-ever boot is in this folder. Nothing has run on FXServer yet.

## What changed since v0.13.2

| | |
|---|---|
| **+ `INSTALL-WALKTHROUGH.md`** | Was referenced by three docs but **missing from the zip**. Reconstructed as Parts 1–7, verified against the live Qbox recipe. |
| **+ `setup/`** | Seven PowerShell scripts that do Parts 6 and 7 for you. |
| **+ `SHAKEDOWN-NOTES.md`** | The pre-boot audit: what was fixed, what was verified, what is deferred. |
| **✎ `outbreak_spawn/server/spawn.lua`** | **Fix PB-1.** `player.Functions.SetMoney` does not exist in Qbox. Would have killed the whole first-join flow. |
| **✎ `outbreak_faction/fxmanifest.lua`** | **Fix PB-4.** Never loaded oxmysql; errored on every connect. |

Both fixes are in the resource files in this zip. Copy them in and you have them.

## Read in this order

1. `CLAUDE.md` — the rules for the evening
2. `ARCHITECTURE.md` — the ownership contract
3. `KNOWN_LIMITATIONS.md` — the 23 things already expected to be wrong
4. `SMOKE-SCRIPT.md` — the evening, top to bottom
5. **`INSTALL-WALKTHROUGH.md`** — if the server is not installed yet ← **you are here tonight**
6. `SHAKEDOWN-NOTES.md` — what the pre-boot pass already found

## The setup, in one screen

**Yours (~45 min, cannot be scripted):** INSTALL-WALKTHROUGH Parts 1–5.

1. FXServer artifact (LATEST RECOMMENDED) → `C:\FXServer\server\`, create `C:\FXServer\txData\`
2. Server key from **portal.cfx.re** (Keymaster retired 2026-08-04)
3. **MariaDB 11.8 LTS standalone MSI — not XAMPP.** Root password, UTF8, install as service. `CREATE DATABASE outbreak;`
4. Run `FXServer.exe` → `localhost:40120` → PIN → recipe **Remote URL**:
   `https://raw.githubusercontent.com/Qbox-project/txAdminRecipe/main/qbox.yaml`
   → point it at database **`outbreak`** (the same one — oxmysql has a single connection)
5. **Boot stock Qbox and connect before touching anything.** Then `status` in the console, copy your
   identifier, add `add_principal identifier.<yours> group.admin` to `<BASE>\permissions.cfg`. Stop the server.

**Mine (~5 min, server stopped):**

```powershell
cd C:\outbreak-pack
powershell -ExecutionPolicy Bypass -File .\setup\00-preflight.ps1     # read-only: where am I?
powershell -ExecutionPolicy Bypass -File .\setup\RUN-ALL.ps1 -DryRun  # preview every change
powershell -ExecutionPolicy Bypass -File .\setup\RUN-ALL.ps1          # do it
```

That covers Part 6 (disable the nine competing resources + npwd) and Part 7 (copy resources, migrations
001–007, the two paste-ins, append the start order), then re-runs preflight to prove it worked.

**Then:** start the server, `connect localhost`, F8 open — and go to `SMOKE-SCRIPT.md` **section 1 first**.
`/ob_animcheck`, `/ob_models`, `/ob_walk` resolve limitations #8, #19 and #20 in two minutes and make every
later section cheaper.

## The scripts

| Script | Does | Part |
|---|---|---|
| `00-preflight.ps1` | Read-only status of all five setup questions | — |
| `01-disable-competing.ps1` | Nine resources → `[disabled]`, comment three npwd lines. `-Revert` undoes it | 6 |
| `02-copy-resources.ps1` | Copies the three groups, verifies 21 resources **and both pre-boot fixes** | 7.1 |
| `03-apply-migrations.ps1` | Applies 001–007, verifies 21 tables | 7.3 |
| `04-paste-ins.ps1` | items.lua + jobs.lua, marker-guarded and brace-checked | 7.4 |
| `05-append-cfg.ps1` | Appends the start order, verifies it landed after `ensure [qbx]` | 7.5 |
| `RUN-ALL.ps1` | 01→05 in order, then preflight | 6–7 |

Common flags: `-Base <path>` if auto-detect can't pick your `.base`, `-DryRun` to preview, `-Force` to skip
prompts. Every file is backed up with a timestamp before it is touched, and every script is safe to re-run —
`02-copy-resources.ps1` is also how you deploy a patch mid-shakedown.

## Three things that will bite

- **PowerShell treats `[qbx]` as a wildcard**, not a folder name. Any command touching a bracketed path needs
  `-LiteralPath` or it fails with "cannot find path". The scripts handle it; hand-typed commands often don't.
- **`04-paste-ins.ps1` edits ox_inventory.** A malformed `items.lua` takes ox_inventory down and the server
  with it. If the server won't boot right after that step, restore the `.bak` beside the file.
- **Removing `qbx_medical` / `qbx_police` may upset other `[qbx]` job resources.** Expected. Collect the
  resource names from the Part 6 boot; don't fix by guessing.

## Ops, later

`ops/OPS.md` covers backups, scheduled restarts and the whitelist. **Edit `ops/backup.bat` line 8** — it
hardcodes `MariaDB 11.4`; set it to the version you actually installed or backups fail silently.

Before the crew joins: `setr ob_debug 0` and drop `ensure outbreak_debug`.
