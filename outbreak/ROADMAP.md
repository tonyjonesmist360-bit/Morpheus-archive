# Roadmap — held until the slice passes FIRST_BOOT_CHECKLIST.md

Two design documents were adopted as the post-slice direction (progression systems; NoPixel-V-style interaction polish).
Nothing below is built. Order is the agreed priority; each item becomes its own phase with its own checklist.

## Progression (emergent endgame, no scripted storyline)
1. Intel & leads (searching yields documents/coordinates/frequencies; leads with Confirmed/Credible/Rumor reliability; some are traps)
2. Dynamic survivor camps (population, food, water, meds, power, defenses, morale, threat; requests; visible upgrades or decline)
3. Camp reputation (already a service — `outbreak_faction:getRep/addRep`) with cross-faction consequences
4. Horde defense events (prep phase → defense phase → consequences)
5. Legendary vehicles via multi-step leads (each with a real operating cost)
6. Island expedition (broadcast → charts → boat → marine fuel → repair → nav → weather window → island with its own problems)
7. Regional infrastructure projects (deliveries over time: water tower, repeater, substation, bridge, clinic, marina pumps)
8. Rare weapon leads with drawbacks (ammo scarcity, noise, faction attention)
9. Survivor NPC recruitment (solo alternative for every co-op objective)
10. Convoys & distress calls with regional consequences (extended `broadcast`/`camps` are the seeds)
11. Safehouse expansion with a detectable profile (noise, light, smoke, radio, stock)
12. Survivor journal & legacy (auto-recorded milestones; memorial already exists)

## NoPixel-V-style polish (design philosophy only — no NoPixel code, art, or assets exist publicly to use)
1. Universal contextual interaction (the wheel + ox_target; expand vehicle/house/person verbs)
2. Minimal HUD that appears when relevant (moodles already; hide bars when full)
3. Animation-first interactions (action service exists; add props)
4. Persistent, detailed vehicles (extended `vehicles` must become server-authoritative first)
5. Intel terminal (safehouse laptop) + physical radio network (repeaters extend range)
6. Traits + deteriorating appearance (dirt, blood, bandages, beard)
7. NPC dialogue with memory (reputation-aware)
8. Purposeful interiors (MLO shortlist)
9. Safehouse furnishing
10. Expanded movement (crawl when badly hurt, lean, vault, boost)
11. Social camp activities
12. Atmospheric map pass (extended `map` is the seed)

## Solo-support rule
Every co-op objective ships with a solo path (NPC recruit, rare item, slower method). The adrenaline shot and self-splint are the first two.

## Status (v0.12)
Every item on both lists has a first implementation on paper. Chains 1–5 implemented. Nothing tested. The next phase is not a build: it is the RAM, the checklist, and the shakedown.
