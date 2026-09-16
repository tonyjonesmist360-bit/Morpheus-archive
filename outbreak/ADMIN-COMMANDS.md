# ADMIN COMMANDS — day-to-day (v0.23)

All need `outbreak.admin` (or the DM ace) or the txAdmin console. Typed in chat with `/`, or in the console without.
Every one writes a line to the event log (`logs kind:admin`).

| Command | Does |
|---|---|
| `time set <0-23>` | sets the clock now |
| `weather set <CLEAR\|CLOUDS\|OVERCAST\|FOGGY\|RAIN\|THUNDER\|CLEARING>` | immediate weather |
| `spawn mob <zombie\|runner\|bloater\|screamer\|horde\|survivor\|raider\|military> [count]` | at your position (in game only) |
| `trigger encounter <stranger\|rumor_food\|rumor_medicine\|probe\|unrest\|trader\|tide\|director> [house_id]` | one director action now, at one settlement (first settlement if omitted) |
| `settle morale <0-100> [house_id]` · `settle residents <+n\|-n> [house_id]` | adjust a settlement instantly |
| `loot reset` | every container and site fresh again |
| `announce <text>` | server-wide banner + notify |
| `event log [n]` | last n log lines (memory) |
| `logs kind:<prefix> player:<id> date:YYYY-MM-DD text:<word> n:<count>` | query the daily file |
| `server stats` | players, uptime, Lua memory, loop lateness, live schedules |
| `ob_tune` · `ob_tune set <key> <value>` · `ob_tune reload` · `ob_tune reset` · `ob_tune get <key>` | tuning, live |
| `mute <id> [minutes] [reason]` · `unmute <id>` | no chat, no radio, no voice |
| `kick <id> [reason]` · `ban <id> <minutes\|perm> [reason]` · `unban <license\|name>` · `bans` | moderation with audit trail (`bans.json` in outbreak_log) |
| `hotfix reload <outbreak_resource>` | restart that one resource, logged |
| `restart_warn [minutes]` | fire a restart warning by hand |
| `ob_scene_clear x y z [r]` · `ob_scene_restore <file>` | undo a DM scene |
| `ob_vehera early\|live` | vehicle era |

Log line format: `date time | src:name:citizenid | kind | {json}`. Kinds so far: `player.join/drop`, `faction.join/leave/standing_change`,
`death.<mode>`, `house.claim`, `house.spot`, `loot.search`, `crew.create`, `dm.<action>`, `director.<action>`, `admin.<cmd>`,
`tune.set`, `mod.mute/unmute/kick/ban/unban`, `perf.alert/report`, `ops.restartWarn/preRestart`, `resource.start/stop`, `server.boot`.
