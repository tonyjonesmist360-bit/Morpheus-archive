# Known limitations (honest list)

1. **Forced entry trusts the client.** The pin-sweep result is reported by the client; the server only opens the stash. A cheater can skip the minigame. Mitigation planned: server-issued attempt token + server-side timing check.
2. **Wounds are client-detected.** Only the victim's client sees `CEventNetworkEntityDamage`. Server stores, validates part/kind, and rate-limits (800 ms), but a client can fabricate or suppress reports.
3. **Downed state is set by the victim's client** (replicated statebag). Same trust boundary as #2. Server-side death (`bledOut`) and everything after it is authoritative.
4. **Zombie ownership is per-client with a density split**, not true server-side population. Two players 200 m apart see different zombies. OneSync entity migration will occasionally hand a zombie to another client mid-chase; behaviour after migration is untested.
5. ~~Vehicle fuel client-authoritative~~ **Resolved in vehicles v2**: fuel burns server-side from `GetEntityVelocity`; battery/part/lock/hotwire/claim are server-validated; claimed vehicles persist and respawn via `CreateVehicleServerSetter`. Remaining gaps: pry/splice minigame *results* are still client-reported (same as #1); server has no `GetVehicleClass`, so the class profile (noise/burn) is client-reported once at register; ambient (unclaimed) vehicles do not persist by design.
6. **Corpse stashes are never garbage-collected** in ox_inventory (rows expire from our table after 24 h, the stash registration persists until restart).
7. **`ResurrectPed` in headshot-only mode** is unverified against OneSync; off by default.
8. **Animation dictionaries** in `EmoteCfg.Actions` are from memory; any that fail to load fall back to a bare progress circle (no crash, no anim).
9. **Interior coordinates** (bob74_ipl) and all world coordinates are unverified; expect a coordinate pass.
10. **qbx_core API assumptions**: `exports.qbx_core:Logout`, `QBCore:Server:PlayerLoaded`, `player.Functions.SetMoney/SetJob/SetMetaData` via the qb-core bridge. If the bridge is disabled these need the native qbx equivalents.
11. **ox_inventory client weight exports** (`GetPlayerWeight/GetPlayerMaxWeight`) are pcall-guarded; if absent, encumbrance silently does nothing.
12. **The world clock overrides GTA time every 2 s**; any other resource that sets time (Renewed-Weathersync in the recipe!) must be disabled.
13. **No anti-spam on `outbreak:server:needsTick`** beyond trusting one call per 15 s; a client could accelerate decay on itself only (self-harm, not exploit).
14. **Carried-into-vehicle flow is fragile**: `TaskWarpPedIntoVehicle` on a ragdolled/anim-locked ped and re-entering the down anim after `TaskLeaveVehicle` are both unverified; expect a tuning pass.
15. **Station coordinates** (Pillbox/Sandy/Paleto) are approximate; the recipe's `pillbox` MLO may move the triage point indoors.
16. **Radio range depends on pma-voice internals**: the client listens for `pma-voice:setTalkingOnRadio` and uses `MumbleSetVolumeOverrideByServerId`; the event name/signature varies by pma-voice version. If it doesn't fire, range silently does nothing (voice stays global) while text transmissions still garble correctly.
17. **Tower damage during the repeater boot is client-reported** (5-second chunks, server-capped) — same trust class as kill reports.
18. **ox_inventory weapon API names** (`getCurrentWeapon` client, `GetCurrentWeapon`/`SetDurability` server) are from memory; the repair path falls back to the first weapon slot if the server export is absent.
19. **Placed-object model names** are from memory (`prop_gaslamp_01`, `prop_ld_planks01`, `prop_cs_hand_radio`…); any that fail to load fall back to the paper-bag bundle. **Server-side `CreateObjectNoOffset` / `SetEntityRotation`** are OneSync natives assumed present on the recommended artifact.
20. **Shelf and takeable map props** (`v_ret_ml_*`, `prop_ecola_can`…) are named from memory — expect a verification pass with a prop-cycling debug tool; interior MLO props sometimes ignore `CreateModelHide`. Takeable map props rely on `CreateModelHide` matching the exact model at the exact coords; MLO/DLC props may not hide. `DeleteObject` on the client gives instant feedback only.
21. **Cayo Perico via `SetIslandHopperEnabled('HeistIsland', true)`**: client-side streaming toggle; all island coordinates (beach, far dock, enclave, lighthouse) are approximate and need a pass. Whether the mainland and island coexist cleanly for players on both at once is unverified (GTA normally treats the island as a separate map state).
22. **Boat server-side creation** (`CreateVehicleServerSetter(..., 'boat', ...)`) and boat class detection (class 14) are assumed.
23. **Nothing has run.** Every line is untested on FXServer. See INTEGRATION_REPORT.md.
