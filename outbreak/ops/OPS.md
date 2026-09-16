# Ops — keeping it up

## Backups
- `ops/backup.bat` — DB dump + zip of the three outbreak resource groups + server.cfg. Keeps 14 days. Edit the three paths at the top.
- Schedule: `powershell -ExecutionPolicy Bypass -File .\ops\install-backup-task.ps1 -RunNow` from an **elevated** PowerShell
  registers the daily 04:00 task, runs it once, and verifies the output. `-Remove` unregisters it.
- Verify any time: `powershell -ExecutionPolicy Bypass -File .\ops\verify-backup.ps1` (add `-RestoreTest` to restore the dump
  into a scratch database and drop it again - never touches the live DB).
- `ops/restore.bat <dump.sql>` puts a dump back. Stop the server first.

## Scheduled restart (txAdmin)
txAdmin → Settings → Restarter → Scheduled Restarts: `04:10` (after the backup). Warning announcements on.
Our world clock, weather, opportunities, camps, vehicles (claimed), world items, intel and needs all survive a restart by design;
hordes in progress, unclaimed ambient vehicles and spawned NPCs do not.

## Whitelist (friends only)
txAdmin → Settings → Player Manager → Whitelist: **Discord** mode. Link txAdmin's Discord bot to your server, add the crew's IDs.
Anyone not on it is rejected at the queue. Keep `sv_lan 0` and forward 30120 TCP+UDP once you go public to friends
(or use Tailscale/ZeroTier and skip forwarding entirely).

## Roles
- `group.admin` (txAdmin admins) → aces: `outbreak.debug` (only with `ob_debug 1`), `outbreak.admin` (/ob_revive), `outbreak.dm` (Director).
- For the crew: `setr ob_debug 0` and remove `ensure outbreak_debug`. Keep `outbreak_dm` and `outbreak.admin`.

## After a bad night
- A stuck player: `/ob_revive <id>`.
- A broken world item / object: `DELETE FROM outbreak_world_items WHERE id = ?` then `restart outbreak_worlditems`.
- An opportunity wedged: `/ob_opp expire <id>` (debug on) or `UPDATE outbreak_opportunities SET state='dormant', stage=0, data='{}' WHERE opp_id=?`.
- Rolling back: stop server → `restore.bat` → start.

## Health checks (weekly, 2 minutes)
- `SELECT COUNT(*) FROM outbreak_world_items;` — if it's in the thousands, raise `MaxPlacedPerPlayer` limits or purge `placed_by='world'` older than a month.
- `SELECT * FROM outbreak_memorial ORDER BY died_at DESC LIMIT 10;` — the wall.
- `SELECT * FROM outbreak_dm_log ORDER BY at DESC LIMIT 20;` — what the director did.
- Backup folder has today's files.

## v0.23 — day-to-day operations
| Need | Do |
|---|---|
| Roll back to a date | stop the server → `powershell -ExecutionPolicy Bypass -File .\ops\restore-backup.ps1 -Date 20260916 -Apply` (current files move aside first; DB dumped before restore) |
| List backups | `restore-backup.ps1` with no arguments |
| Weekly restore test | `verify-backup.ps1 -RestoreTest` (scratch DB) |
| Retention | `backup.bat` keeps `KEEP_DAYS=7` |
| Daily restart | txAdmin → Settings → FXServer → Restart schedule `04:00`. The pack warns players at 60/15/5/1 min before `ops.restartHour` (tuning) and flushes state at 0. Keep the two in step. |
| Tune a number | console `ob_tune set loot.multiplier 1.5` (live). `ob_tune` lists. `BALANCE-TUNING.md`. |
| Read the day | `logs kind:faction` / `logs kind:death` / `logs player:12` / `logs date:2026-09-15 text:zancudo`; `event log` for the last 30 |
| Health | `server stats` (players, loop lateness, memory, schedules). Per-resource CPU: txAdmin Resources page or `resmon 1` in F8 |
| Moderation | `mute <id> [min] [reason]`, `unmute`, `kick <id> [reason]`, `ban <id> <min|perm> [reason]`, `unban <license|name>`, `bans`. All logged under `mod.*` |
| Hotfix a resource | `hotfix reload outbreak_minigames` (a restart of that one resource, logged) |
