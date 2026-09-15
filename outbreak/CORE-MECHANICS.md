# CORE MECHANICS — protected (permanent rule, 2026-09-15)

The last build broke vehicle entry and punching. From now on **any code that hooks input, controls,
movement clipsets, ped tasks or ped events is reviewed against this list before it ships**, and every
item on the list is a step in the F9 test menu (section 1 CORE MECHANICS, K1–K14).

## The protected list
| Mechanic | Controls / natives that can break it | F9 |
|---|---|---|
| Enter / exit vehicles (driver + passenger) | control 23; `SetVehicleDoorsLocked`; `SetVehicleUndriveable`; anything that fights the door lock | K1 K2 K3 |
| Melee / punching | controls 24, 140–143; **any `SetPedMovementClipset`** (crouch, walk styles, limp) | K4 K5 |
| Weapon draw / holster / fire | 24, 25, 37, 257; `DisablePlayerFiring`; `SetPedCanSwitchWeapon` | K6 K7 |
| Sprint / jump / climb | 21, 22; `SetPlayerSprint`; `SetPedMoveRateOverride`; stamina | K8 K9 |
| Swim | 21, 22, 30–35 | K10 |
| Ragdoll / get-up | `SetPedCanRagdoll`, `SetPedToRagdoll`, `ClearPedTasksImmediately`, `FreezeEntityPosition` on the player | K11 |
| Ladders | 21, 22, 32, 33 | K12 |
| Cover | 44 | K13 |
| (pad) inventory / wheel / radio buttons | 27 (D-pad Up), 173, 174 | K14 |

## The review rule
1. `grep -rn "DisableControlAction\|SetPedMovementClipset\|ClearPedTasks\|FreezeEntityPosition(Player\|SetPlayerControl\|SetPlayerSprint\|SetPedCanRagdoll"` across `resources/`.
2. Every hit must be **conditional on a state that ends** (downed, noclip, placing, jammed, crouched, injured) and
   must **restore** on every exit path (including `onResourceStop`).
3. No new per-frame loop. A per-frame disable from a 500 ms tick does nothing (one frame in fifteen) — that is a
   bug, not a feature.
4. If two systems want the same native (clipset: crouch vs walk style vs limp) **one resource owns it**
   (`outbreak_emotes.applyWalk`) and the others ask.
5. Add or update the K-step in `shakedown.lua`, regenerate `TEST-GUIDE.md`.

## Hook inventory (2026-09-15, after this sheet)
| Where | What | Condition | Restores |
|---|---|---|---|
| outbreak_down `down.lua` | BODY_CONTROLS (21–25, 30–37, 44, 47, 58, 75, 140–143, 257, 263–273) | while `downState` | prompt cleared + loop idles when not down |
| outbreak_down `down.lua` | `SetPedCanRagdoll`, `SetEntityHealth(120)` | while down | on clearDown |
| outbreak_down `down.lua` | recovering: move rate 0.6 + `needs:cutSprint('recovering')` | while `recovering` statebag | statebag cleared |
| outbreak_dm `admin.lua` | 24, 25, 37, 44, 140–142; freeze/collision/invincible | while noclip | on toggle + onResourceStop |
| outbreak_dm `admin.lua` | 24, 257 | while entity gun | on toggle |
| outbreak_worlditems `place.lua` | 24, 25 | while placing | loop ends |
| outbreak_weapons `weapons.lua` | 24, 257, 140 | while `jammed` (firearms only) | on clear |
| outbreak_emotes `emotes.lua` | `SetPedMovementClipset`: crouch / walk style / **injured limp** | one owner, `applyWalk()` | `ResetPedMovementClipset` when none apply; attack input while crouched stands you up |
| outbreak_needs `needs.lua` | `SetPlayerSprint(false)` | while any cut reason is live (1.5 s window) | re-asserted `true` every tick otherwise |
| outbreak_needs `needs.lua` | `ShakeGameplayCam('HAND_SHAKE')` | while aiming with an untreated arm wound | `StopGameplayCamShaking` |
| outbreak_core `quietkill.lua` | `ClearPedTasksImmediately`, `FreezeEntityPosition` on the **zombie**, `ClearPedTasks(me)` after the clip | during the takedown only | unfreezes |
| outbreak_intel `journal.lua` | `DisableAllControlActions(0)` | while the journal is open (menu) | loop ends on close |
| outbreak_radio `radio.lua` | ~~per-frame `DisableControlAction(0, 27)`~~ | **removed** (R1-1) | — |

## Root causes found this sheet
- **Vehicle entry (2026-09-14).** Two locks stacked: the vehicles-v2 first-seen roll locked 55 % of cars with
  no keys anywhere, and the stock QBox recipe ships `qbx_vehiclekeys`, which locks any car you hold none of
  *its* keys for and blocks the driver door. Fix: era roll tables (`setr ob_veh_era early`: 15 % locked, 60 %
  keys in the ignition), keys on every DM spawn mirrored to qbx_vehiclekeys, red boot warning while it runs.
  **Needs you:** comment `ensure qbx_vehiclekeys` out of the recipe cfg (outside our block).
- **Punching (2026-09-14).** `/crouch` applied `move_ped_crouched`, and GTA does not allow melee from that
  clipset. Fix: an attack input while crouched resets the clipset for the swing and re-crouches 1.5 s after
  melee ends. Same class of bug the limp could have caused — which is why the limp lives in `applyWalk()`.
- **Zombies cancelling their own attacks (2026-09-14).** The v0.19 suspicion loop called
  `TaskTurnPedToFaceEntity` every tick line-of-sight flickered. Fix: `aggro[ped]` latches.
- **R1-1 Pad inventory button dead.** `outbreak_radio` ran a per-frame `DisableControlAction(0, 27)` "no
  phone" loop; 27 is also D-pad Up, which `outbreak_binds` maps to the inventory. Removed.
- **R1-2 "No sprint" never worked.** `RestorePlayerStamina(PlayerId(), 0.0)` *restores* 0 % — it is a no-op —
  and `DisableControlAction(0, 21)` from the 500 ms tick is a one-frame flicker. Replaced by one sprint-cut
  owner in `outbreak_needs` using `SetPlayerSprint` (persistence between calls **unverified**: K9).
- **`SetPedMoveRateOverride` from a tick** only applies for the frame it is called (native must be per-frame).
  The old "fracture slows you" was therefore invisible. The limp clipset is the real effect now; the move-rate
  call stays as a harmless nudge.
