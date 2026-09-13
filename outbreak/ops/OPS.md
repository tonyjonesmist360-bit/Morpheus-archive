# Ops — keeping it up

## Backups
- `ops/backup.bat` — DB dump + zip of the three outbreak resource groups + server.cfg. Keeps 14 days. Edit the three paths at the top.
- Schedule: Task Scheduler → Create Basic Task → Daily 04:00 → run `backup.bat`. Test once by double-clicking it.
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
