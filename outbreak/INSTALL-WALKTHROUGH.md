# INSTALL-WALKTHROUGH — Outbreak on FXServer (Windows, localhost)

> **Reconstructed 2026-09-12.** The original of this file was missing from `outbreak-pack-v0.13.2.zip`.
> Parts 1–6 get **stock Qbox** booting. Part 7 installs the Outbreak pack. That split matches
> `FIRST_BOOT_CHECKLIST.md` ("Parts 1–6 done (stock Qbox boots), then: …").
>
> Verified against the live Qbox txAdmin recipe (`Qbox-project/txAdminRecipe`, `qbox.yaml` + `server.cfg`)
> rather than from memory — the resource-group layout in Part 6 is the real one.
> `README.md`'s 12-step "Install" section is **superseded by this file**; it predates migrations 001–007
> and still says XAMPP is acceptable. It is not.
>
> Tick each box. Copy any error verbatim — that is the patch list.

---

## Part 0 · Before you start

- [ ] Windows 10/11, ~20 GB free on `C:`
- [ ] A Cfx.re account (forum login) — <https://portal.cfx.re>
- [ ] [7-Zip](https://www.7-zip.org/) installed (the artifact ships as `.7z`)
- [ ] The pack unzipped somewhere that is **not** inside `C:\FXServer` — e.g. `C:\outbreak-pack\`.
      That folder is the source of truth. You copy *out* of it into the live tree, never the reverse.

**Naming used throughout:**

| Placeholder | Means |
|---|---|
| `C:\FXServer\server\` | the artifact (contains `FXServer.exe`) |
| `C:\FXServer\txData\` | txAdmin's data root |
| `<BASE>` | `C:\FXServer\txData\<something>.base\` — created by the recipe in Part 4. You will not know the exact name until then. |
| `C:\outbreak-pack\` | this pack, unzipped |

---

## Part 1 · FXServer artifact

- [ ] 1.1 Go to <https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/>
- [ ] 1.2 Download the build marked **LATEST RECOMMENDED** (not "latest optional"), file `server.7z`.
      `MANIFEST.md` wants ≥ 7290; any current recommended build is far past that.
- [ ] 1.3 Create `C:\FXServer\server\` and extract `server.7z` **into** it.
- [ ] 1.4 Create the sibling folder `C:\FXServer\txData\` (leave it empty).
- [ ] 1.5 Confirm `C:\FXServer\server\FXServer.exe` exists and `C:\FXServer\server\citizen\` sits beside it.

> If you end up with `C:\FXServer\server\server\FXServer.exe`, the extract nested one level. Move the contents up.

---

## Part 2 · License key

Keymaster was retired on **2026-08-04**; keys now live in the Cfx.re Portal. `keymaster.fivem.net` redirects there.

- [ ] 2.1 Sign in at <https://portal.cfx.re> with your Cfx.re forum account
- [ ] 2.2 Create a new **server key**. It asks for a display name only — the old "bind to an IP" step is gone.
      Name it `outbreak`.
- [ ] 2.3 Copy the key (`cfxk_…`) into a text file. You paste it once, in Part 4.

> You need this even for a LAN-only server, because txAdmin's setup asks for it before it will deploy.

---

## Part 3 · MariaDB (standalone — **not** XAMPP)

XAMPP is explicitly unsupported by Qbox and by this pack. Install the real service.

- [ ] 3.1 Download the **Windows x86_64 MSI** from <https://mariadb.org/download/>.
      Take the current **LTS** (11.8.x). 12.x also works. Qbox's floor is 10.9.
- [ ] 3.2 Run the installer:
  - set a **root password** — write it down, you need it three more times
  - tick **"Use UTF8 as default server's character set"**
  - tick **"Install as service"**, service name `MariaDB` (the default)
  - leave the port at **3306**
- [ ] 3.3 Note the install path exactly — e.g. `C:\Program Files\MariaDB 11.8\`.
      **`ops/backup.bat` line 8 hardcodes `MariaDB 11.4`** — edit it to your real version or backups silently fail.
- [ ] 3.4 Confirm the service is running:
  ```powershell
  Get-Service MariaDB
  ```
  Expect `Status: Running`.
- [ ] 3.5 Create the database. Open **"MariaDB Command Prompt"** from the Start menu (it puts the client on PATH), then:
  ```sql
  CREATE DATABASE outbreak CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  SHOW DATABASES;
  ```
  Expect `outbreak` in the list.

> **This is the one thing people get wrong.** `outbreak` is **not** a second database alongside a Qbox one.
> oxmysql has a single connection. Qbox's own tables (`players`, `bans`, …) and our `outbreak_*` tables
> live in **the same** database. In Part 4 you point the recipe at `outbreak`, and the recipe fills it.

- [ ] 3.6 *(optional but worth it)* Install [HeidiSQL](https://www.heidisql.com/) — it usually ships with the MariaDB MSI.
      Part 7.3 is much less painful with a GUI.

---

## Part 4 · txAdmin + the Qbox recipe

- [ ] 4.1 Run `C:\FXServer\server\FXServer.exe`. A console window opens and prints a **PIN** and a
      `http://localhost:40120` link. Open it.
- [ ] 4.2 Enter the PIN, create your txAdmin master account. **Remember this password.**
- [ ] 4.3 Deployment type → **"Popular templates"** / recipe-based. Then choose **"Remote URL"** and paste:
  ```
  https://raw.githubusercontent.com/Qbox-project/txAdminRecipe/main/qbox.yaml
  ```
  (If a "Qbox" template is already listed, using it is the same thing.)
- [ ] 4.4 Server name: `outbreak` (this becomes the `.base` folder name — keep it simple, no spaces)
- [ ] 4.5 Paste your `cfxk_…` license key from Part 2
- [ ] 4.6 Database settings:
  - host `localhost`, port `3306`
  - user `root`, password = your Part 3.2 password
  - **database `outbreak`**
- [ ] 4.7 Run the deployer. It downloads ~50 Qbox resources plus the ox stack and imports `qbox.sql`.
      Takes several minutes. Watch for red lines.
- [ ] 4.8 Find your base folder and **write the path down** — every later step needs it:
  ```powershell
  Get-ChildItem C:\FXServer\txData -Directory
  ```
  You want the one ending `.base`, e.g. `C:\FXServer\txData\outbreak.base`. That is `<BASE>` from here on.

### What the recipe already gave you

All of `MANIFEST.md`'s dependencies ship with this recipe. **You do not need to install anything by hand.**

| Folder under `<BASE>\resources\` | Contains |
|---|---|
| `[ox]` | ox_lib, oxmysql, ox_inventory, ox_target, ox_doorlock, **ox_fuel** |
| `[qbx]` | qbx_core + ~47 others, incl. **qbx_spawn, qbx_properties, qbx_hud, qbx_medical, qbx_ambulancejob, qbx_police, qbx_density** |
| `[standalone]` | **illenium-appearance**, **bob74_ipl**, scully_emotemenu, **Renewed-Weathersync**, loadscreen, … |
| `[voice]` | **pma-voice**, **mm_radio** |
| `[npwd]`, `[npwd-apps]` | npwd, qbx_npwd, npwd_qbx_garages, npwd_qbx_mail |
| `[assets]` | pillbox (the MLO behind `KNOWN_LIMITATIONS.md` #15) |

Bold = either something Outbreak needs, or something Part 6 switches off.

---

## Part 5 · Boot stock Qbox once, before touching anything

Do not skip this. If Qbox is broken on its own, you will waste the evening blaming Outbreak.

- [ ] 5.1 txAdmin → **Start** the server
- [ ] 5.2 Live console reaches **ONLINE** / "server is now available"
- [ ] 5.3 No red lines mentioning `oxmysql` or `Access denied` (those mean Part 4.6 was wrong — fix in
      `<BASE>\server.cfg`, the `set mysql_connection_string` line, then restart)
- [ ] 5.4 Launch FiveM → F8 → `connect localhost` → you spawn in Los Santos with a normal QBox HUD
- [ ] 5.5 **Get your identifier** — server console (or txAdmin live console), type:
  ```
  status
  ```
  Copy the whole identifier for your slot, e.g. `license:110000112345678` or `fivem:1234567`.

  > Under `sv_lan 1` (which Part 7.5 turns on) a `license:` identifier may not be issued.
  > Use whatever `status` actually prints — that is why you read it here rather than guessing.

- [ ] 5.6 Make yourself an admin principal. Open `<BASE>\permissions.cfg`, add at the bottom:
  ```
  add_principal identifier.license:110000112345678 group.admin
  ```
  substituting your real identifier from 5.5 (keep the `identifier.` prefix).
  This is what makes `outbreak.debug` / `outbreak.admin` / `outbreak.dm` work in Part 7.
- [ ] 5.7 Stop the server in txAdmin. Everything from here is done with the server **stopped**.

---

## Part 6 · Disable the systems Outbreak replaces

**Read this first — it is not what you expect.** The recipe's `server.cfg` does not have one `ensure` line per
resource. It ensures whole folders:

```
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure [ox]
ensure [qbx]
ensure [standalone]
ensure [voice]
ensure [assets]
ensure [npwd-apps]
ensure qbx_npwd
ensure npwd
```

So there is **no `ensure qbx_spawn` line to comment out.** To disable one resource inside a group you move the
folder out of the group. A folder that is never `ensure`d never starts.

### 6a · Create the graveyard

- [ ] 6.1 Make `<BASE>\resources\[disabled]\` — an empty folder. Nothing ever ensures it.

### 6b · Move these nine folders into it

```powershell
$B = "C:\FXServer\txData\outbreak.base\resources"   # <-- your <BASE>
New-Item -ItemType Directory -Force "$B\[disabled]"

# from [qbx]
Move-Item "$B\[qbx]\qbx_spawn"        "$B\[disabled]\"
Move-Item "$B\[qbx]\qbx_properties"   "$B\[disabled]\"
Move-Item "$B\[qbx]\qbx_hud"          "$B\[disabled]\"
Move-Item "$B\[qbx]\qbx_medical"      "$B\[disabled]\"
Move-Item "$B\[qbx]\qbx_ambulancejob" "$B\[disabled]\"
Move-Item "$B\[qbx]\qbx_police"       "$B\[disabled]\"
Move-Item "$B\[qbx]\qbx_density"      "$B\[disabled]\"

# from [ox]
Move-Item "$B\[ox]\ox_fuel"           "$B\[disabled]\"

# from [standalone]
Move-Item "$B\[standalone]\Renewed-Weathersync" "$B\[disabled]\"
```

Why each one, so you can argue with it later:

| Moved | Replaced by | Reference |
|---|---|---|
| qbx_spawn | `outbreak_spawn` | apocalypse spawn flow, no apartments |
| qbx_properties | `outbreak_housing` | keys are items, not an app |
| qbx_hud | `outbreak_hud` | vitals + moodles |
| qbx_medical | `outbreak_needs` | needs/wounds are our authoritative store |
| qbx_ambulancejob | `outbreak_down` | permadeath owns death |
| qbx_police | `outbreak_faction` | police → Military Remnant |
| qbx_density | `outbreak_core` | core zeroes ambient population itself |
| ox_fuel | `outbreak_vehicles` | server-authoritative fuel (vehicles v2) |
| Renewed-Weathersync | `outbreak_world` | **`KNOWN_LIMITATIONS.md` #12** — two resources fighting over GTA time is a guaranteed bug |

### 6c · Turn off npwd (phones are blocked in this world)

- [ ] 6.2 In `<BASE>\server.cfg`, comment out these three lines:
  ```
  # ensure [npwd-apps]
  # ensure qbx_npwd
  # ensure npwd
  ```
  These *are* individual lines, so commenting works. Leave the `[npwd]` folders on disk.

### 6d · Keep these — they are dependencies, not competition

`illenium-appearance` (the creator), `bob74_ipl` (house interiors), `pma-voice` (radio), `mm_radio` (radio UI),
`scully_emotemenu` (`outbreak_emotes` layers over it), `pillbox` (station MLO), and the whole `[ox]` stack
minus `ox_fuel`.

### 6e · Boot again, stock-minus-nine

- [ ] 6.3 Start the server. Watch for **"dependency not found"** or "failed to load resource".
- [ ] 6.4 Expect possible fallout from removing `qbx_medical` / `qbx_police` — other `[qbx]` job resources may
      declare them as dependencies. **Write down every resource name that errors. Do not fix it by guessing.**
      That list is a decision for the shakedown, not for you at 9pm.
- [ ] 6.5 Server reaches ONLINE and you can still `connect localhost`. Stop the server.

---

## Part 7 · Install the Outbreak pack

Server **stopped** for all of this.

### 7.1 · Copy the resources

- [ ] Copy `C:\outbreak-pack\resources\[outbreak]\` → `<BASE>\resources\[outbreak]\`

```powershell
Copy-Item -Recurse -Force "C:\outbreak-pack\resources\[outbreak]" "$B\"
```

- [ ] Copy `[outbreak_extended]` and `[outbreak_progression]` across **too**. They are commented out in the
      cfg and will not start — having them on disk now saves a copy later.
- [ ] Verify 21 folders landed:
  ```powershell
  (Get-ChildItem "$B\[outbreak]" -Directory).Count
  ```
  Expect **21** (17 slice services + hud + wheel + dm + debug).

> `CLAUDE.md`: the pack folder is the source of truth. When you patch, you patch
> `C:\outbreak-pack\`, run both analyzers, *then* copy here. Never edit the live tree only.

### 7.2 · Lua 5.4 for the analyzers (do it now, not mid-patch)

`tools_diag.py` shells out to `luac5.4` and dies with `FileNotFoundError` if it is absent.
`tools_diag2.py` runs without it. You want both.

- [ ] Install Lua 5.4 for Windows and put `luac5.4.exe` on PATH
      (or edit line 22 of `tools_diag.py` to your actual binary name — Windows builds often ship `luac54.exe`).
- [ ] Verify from the pack folder:
  ```
  python tools_diag.py && python tools_diag2.py
  ```
  Expect **0 ERROR, 0 WARN** from both. `tools_diag2.py` should report
  `Resources: 31 · Lua files: 134 · migrations: 7 · items defined: 63 · commands: 66`.

### 7.3 · Apply the migrations

In HeidiSQL (connect to `localhost` / root / your password / database `outbreak`), open each file and run it.
Or from the MariaDB Command Prompt:

```
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\001_slice.sql
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\002_extended.sql
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\003_progression.sql
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\004_vehicles.sql
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\005_radio.sql
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\006_worlditems.sql
mysql -u root -p outbreak < C:\outbreak-pack\sql\migrations\007_dm.sql
```

- [ ] Run all seven **in order**. Every statement is `CREATE TABLE IF NOT EXISTS` — idempotent, safe to re-run.
- [ ] Verify — expect **21 tables**:
  ```sql
  USE outbreak; SHOW TABLES LIKE 'outbreak\_%';
  ```

Which ones the ensured slice actually reads, if you are curious: `001` (players, needs, identity, skills,
houses, loot, memorial, corpses, reputation), `005` (repeaters, base_radios), `006` (world_items, hidden_props),
`007` (dm_log). `002`/`003`/`004` are for extended / progression / vehicles v2 — applying them now creates empty
tables and changes no behaviour.

### 7.4 · The three paste-ins

These are **fragments, not loadable files** — both analyzers flag them as INFO for exactly this reason.

- [ ] **Items** — open `C:\outbreak-pack\resources\[outbreak]\outbreak_items\data\ox_items_snippet.lua`.
      Copy everything below the two comment lines. Paste into
      `<BASE>\resources\[ox]\ox_inventory\data\items.lua`, **inside** the `return { … }` table,
      just before the closing brace. 63 items.
      Verify: `Select-String "$B\[ox]\ox_inventory\data\items.lua" -Pattern "canned_beans"` → one hit.

- [ ] **Weapons** — open `…\outbreak_weapons\data\weapons_snippet.lua`.
      **Read it before pasting: every weapon line in it is commented out.** It documents the durability and
      `ammoname` values to merge into the `Weapons` table of
      `<BASE>\resources\[ox]\ox_inventory\data\weapons.lua`, plus repair items for `items.lua`.
      ox_inventory already defines these weapons — you are editing existing entries, not adding new ones.
      This is the one paste-in you can defer past first boot; nothing in the slice hard-requires it.

- [ ] **Jobs** — open `…\outbreak_faction\data\jobs_snippet.lua`.
      In `<BASE>\resources\[qbx]\qbx_core\shared\jobs.lua`, **replace the `police` entry** with the
      `military` and `raider` entries from the snippet. Keep the surrounding table syntax intact.
      Verify: `Select-String "$B\[qbx]\qbx_core\shared\jobs.lua" -Pattern "Military Remnant"` → one hit.

> `CLAUDE.md` hard rule: these three paste-ins are the **only** edits you make to ox_inventory or qbx_core.
> Nothing else in those resources gets touched.

### 7.5 · Append the start order to server.cfg

- [ ] Open `<BASE>\server.cfg`. Go to the very **end** — after every `exec` and every `ensure`.
- [ ] Append the entire contents of `C:\outbreak-pack\server.cfg.additions`.

```powershell
Get-Content "C:\outbreak-pack\server.cfg.additions" | Add-Content "$B\server.cfg"
```

- [ ] Confirm it landed after the recipe's block:
  ```powershell
  Select-String "$B\server.cfg" -Pattern "ensure outbreak_core|ensure \[qbx\]" | Select LineNumber,Line
  ```
  `ensure [qbx]` must have a **lower** line number than `ensure outbreak_core`. The additions file is ordered
  by dependency — **do not reorder it.**

- [ ] The block ends with `set sv_lan 1`, which overrides the recipe's `sv_lan 0`. Correct for tonight
      (localhost only). `ops/OPS.md` covers flipping it back when the crew joins.

### 7.6 · Sanity pass before the first boot

- [ ] `setr ob_debug 1` present (it is, in the additions)
- [ ] `add_ace group.admin outbreak.debug allow` / `outbreak.admin` / `outbreak.dm` present
- [ ] Your `add_principal … group.admin` line from 5.6 still in `permissions.cfg`
- [ ] `ensure outbreak_debug` present (last line of the ensured block)
- [ ] Everything under `## VEHICLES v2`, `## PROGRESSION`, `## EXTENDED` still commented with `#`.
      **Leave them commented.** `CLAUDE.md`: nothing there gets enabled until smoke sections 0–11 pass.

### 7.7 · First boot

- [ ] Start the server in txAdmin. Watch the live console.
- [ ] Expected: 21 `outbreak_*` resources start. Yellow warnings are fine.
- [ ] **Red `outbreak_*` lines or "dependency not found" → stop and paste them.** That is a start-order or
      missing-dependency problem, and it is `SMOKE-SCRIPT.md` step 0 / `FIRST_BOOT_CHECKLIST.md` B1–B3.
- [ ] `connect localhost`, F8 open. No red `outbreak_*` on join.

### 7.8 · Then, and only then

Go to **`SMOKE-SCRIPT.md` section 0**, top to bottom. Section 1 first (`/ob_animcheck`, `/ob_models`,
`/ob_walk`) — that pass kills the name-from-memory bugs before they cost you an evening. Press **F9** for the
checklist panel; marks land in `resources/[outbreak]/outbreak_debug/shakedown.log`.

---

## Appendix A · Boot errors you should expect

Everything here is a *known* class, not a surprise. Cross-referenced to `KNOWN_LIMITATIONS.md`.

| Console line | Cause | Do this |
|---|---|---|
| `Failed to load script @outbreak_x/…` | Lua syntax that got past the analyzer | paste the line + file |
| `No such export GetCoreObject` | qb-core bridge disabled in qbx | enable the bridge in qbx config — **do not** rewrite our resources (`CLAUDE.md`) |
| `attempt to index a nil value (field 'Functions')` | qbx bridge API mismatch | limitation **#10** |
| `dependency not found: qbx_medical` | Part 6b removed it, something else wanted it | note the resource name, leave it, raise it |
| anim dict fails / bare progress circle | anim names from memory | limitation **#8** — `/ob_animcheck` in smoke §1 |
| props spawn as paper bags | prop names from memory | limitation **#19/#20** — `/ob_models` in smoke §1 |
| radio text works, voice range does not | pma-voice event name differs by version | limitation **#16** — check pma-voice's own source |
| GTA time snaps back every few seconds | a second weather/time resource is alive | Renewed-Weathersync did not get moved (6b) |
| `Access denied for user 'root'@'localhost'` | wrong connection string | `set mysql_connection_string` in `<BASE>\server.cfg` |
| `Unknown database 'outbreak'` | Part 3.5 not done, or a typo | recreate it |

**Watch list, not an instruction:** `qbx_radialmenu` may fight `outbreak_wheel` for **G**, and `qbx_seatbelt`
may fight `outbreak_binds`. Neither is on the pack's disable list, so do not move them pre-emptively — if the
wheel misbehaves in smoke §4, that is the first thing to test.

---

## Appendix B · Paths worth pinning to a note

```
Artifact      C:\FXServer\server\FXServer.exe
txAdmin       http://localhost:40120
Base          C:\FXServer\txData\<name>.base\
Live cfg      <BASE>\server.cfg
Permissions   <BASE>\permissions.cfg
Live pack     <BASE>\resources\[outbreak]\
Log           C:\FXServer\txData\logs\fxserver.log
Shakedown log <BASE>\resources\[outbreak]\outbreak_debug\shakedown.log
Source pack   C:\outbreak-pack\
DB            localhost:3306 / root / outbreak
```

## Appendix C · Rolling back

Part 6 moved folders, it did not delete them. To get stock Qbox back: move the nine folders out of
`[disabled]` into the groups they came from, un-comment the three npwd lines, and delete the appended block
from `server.cfg`. The `outbreak_*` tables can stay — nothing else reads them.

Once you are live, `ops/backup.bat` (with the MariaDB path from 3.3 corrected) is the real answer. See `ops/OPS.md`.
