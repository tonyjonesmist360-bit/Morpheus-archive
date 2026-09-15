# UI system — one screen, one product

Written after the status panel shipped in a different visual language to the HUD. Two products on
one screen is the opposite of clean, and the HUD's identity was there first, so the HUD is the
reference and everything else conforms to it.

## The identity

**Field gear.** Stencilled bone-on-olive, worn and quiet. It is equipment, not a dashboard.

```
--bone   #d8d2c0   text, full bars, active pips
--olive  #3c4230   moodle dots
--rust   #b4552d   danger, low bars, heavy areas
--blood  #8e2f2f   critical only
--smoke  rgba(24,26,19,.72)   every panel ground
--line   rgba(216,210,192,.22)  every border
```

Type: `'Trebuchet MS','Segoe UI',sans-serif`. Labels are **uppercase, bold, letter-spaced 1.2–1.6px,
9.5–10px**. Values are `tabular-nums` so digits do not jitter.

## The rule that governs everything

> **One bold element: the moodle column. Everything else stays thin.**

Straight from the HUD source, and it is the whole reason the screen reads at a glance. When you add
something, it is thin unless you can argue it deserves to outrank a bleeding warning. Almost nothing
does.

## Bar colours mean one thing everywhere

| Bar | Colour | Tag |
|---|---|---|
| Health | `--bone` | `VIT` |
| Hunger | `#c98f3d` | `FOOD` |
| Thirst | `#5f8fa3` | `H2O` |
| Fatigue | `#7d8a5c` | `REST` |
| **Any bar under 25** | `--rust` + `throb` | — |

The status panel uses the same four colours and the same tags. A glance at the HUD and a glance at
the panel must agree.

## What lives where

| Surface | Shows | Key |
|---|---|---|
| **HUD** (`outbreak_hud`) — always on | 4 vitals bars, moodle column, noise ripple, world strip | — |
| **World strip** — thinnest line on screen | time / blackout / weather / radio channel / mob area | — |
| **Status panel** (`outbreak_status`) — on demand | condition + wounds, carrying by category, skills, world | `F1` |
| **Wheel** (`outbreak_wheel`) — on demand | contextual actions | `G` |
| **Settlement ledger** (`outbreak_supply`) — on demand | stock bars with days/units, residents + morale, cook, objectives, log | Door → Settlement, or `/ob_home` |
| **Home column** in the status panel | the same seven bars, morale, objectives, last ledger lines — only when you hold a key | `F1` |
| **World strip** token | `HOME FOOD` (rust) when critical · `HOME LOW` when low · `HOME STARVING` | — |

The ledger is an ox_lib context menu, not a new NUI page: menus are the pack's interaction
language (wheel, emotes, DM), and progress rows give bars without a second visual system to keep
in step with the HUD. The Home column reuses the panel's `bar()` treatment — stripes and throb on
low — so a starving house reads exactly like a starving body.

Nothing duplicates for its own sake: the panel repeats the vitals because you open it *to* check
them, but it never repeats the moodles, which are already unmissable.

## Adding to the HUD

1. Does it change often enough to watch, and matter enough to interrupt? If not, it belongs in the
   status panel.
2. Thin. Existing type scale, existing palette, no new accent colour.
3. **No new loop.** Subscribe to `outbreak:tick` and throttle, the way the world strip does.
   `ARCHITECTURE.md` lists every permitted client loop; adding one is a contract change.
4. Handle the NUI action in the page. `tools_diag.py` flags a `SendNUIMessage` action the HTML never
   handles, which is how the world strip's missing handler got caught before it shipped.

## Colour vision

The base palette was already close to safe: **blue (`H2O`) against orange (`FOOD`)** is the canonical
colourblind-safe pair, and bone reads as light to everyone.

The genuine failure was elsewhere. Under deuteranopia — the most common form — **rust and olive
collapse toward the same yellow-brown**, and that is precisely the *critical* colour against the
*normal fatigue* colour. A player could not tell a dying bar from a healthy one by hue.

Fixed by making "low" carry three independent signals:

| Signal | Survives colour blindness | Survives a still screenshot |
|---|---|---|
| Rust hue | ✗ | ✓ |
| **45° stripes** | ✓ | ✓ |
| Throb animation | ✓ | ✗ |
| Numeric value + stencil tag | ✓ | ✓ |

Any one of them is enough. Applied identically in the HUD and the status panel.

**Rule for anything added later:** colour may reinforce a meaning, never carry it alone. If you
cannot read the screen in greyscale, it is not finished.

## v0.22 additions (all thin, same palette)
| Surface | Shows | Key |
|---|---|---|
| **Body silhouette** (HUD, beside the bars; F1, large) | six regions: healthy / bruised (FOOD amber) / bleeding (rust, throb) / broken (blood + cross) / treated (dim bone); infected = olive outline | hover / click in F1 |
| **Crew panel** (top-left) | crew name, members: name, 60 px health line, one-word state or distance | only while in a crew |
| **Compass** (top-centre) | cardinals (N in rust), ticks: crew pins (amber), waypoint (H2O blue), home (bone) | always |
| **Journal** tabs Objectives / Factions | guide + settlement needs; standing bars | J |
| **Test menu** (F9, right) | Do / Expect per step, PASS / FAIL buttons in mouse mode | debug only |
Rule kept: nothing new is bold. The moodle column is still the only loud element.
