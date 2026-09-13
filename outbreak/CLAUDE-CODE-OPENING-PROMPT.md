# Paste this as the first message in Claude Code (opened in C:\FXServer)

I'm about to do the first-ever boot of a FiveM pack called Outbreak. It has never run. Read CLAUDE.md in the
outbreak folder first, then ARCHITECTURE.md and KNOWN_LIMITATIONS.md, then SMOKE-SCRIPT.md. Don't summarize
them back to me — just confirm you've read them and tell me the current state you can see:

1. Is FXServer installed here (C:\FXServer\server\FXServer.exe)? Is there a txData folder with a Qbox recipe base?
2. Is MariaDB running (standalone, not XAMPP) and does the `outbreak` database exist?
3. Are the pack's resources already copied into the live resources folder, and are migrations 001–007 applied?
4. Are the paste-ins done (ox_items_snippet into ox_inventory items.lua, weapons_snippet, jobs_snippet)?
5. Is server.cfg.additions appended to server.cfg, and are qbx_spawn / qbx_properties / qbx_hud / qbx_medical /
   qbx_ambulancejob / qbx_police / npwd / ox_fuel / qbx_density / Renewed-Weathersync disabled?

For anything that's missing, walk me through it one step at a time from INSTALL-WALKTHROUGH.md — do the file
work yourself where you can (copying resources, applying SQL, editing server.cfg) and ask me only for the things
that need my hands (installers, txAdmin clicks, license key).

Once the server is ONLINE and I'm connected, start tailing the server log for outbreak_ lines and follow
SMOKE-SCRIPT.md with me. I'll mark steps in the F9 panel; you read shakedown.log and the console. Keep replies
short — tell me what to retry, then what you changed.
