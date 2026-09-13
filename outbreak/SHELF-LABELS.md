# Shelf item labelling — capture sheet

`v_ret_ml_bread01` and `v_ret_ml_bread02` both came back **INVALID**, and 14 substitute guesses
failed too. Guessing has run out of road. `/ob_walk` reads the real model name off whatever you
aim at, so twenty seconds in a 24/7 settles it permanently.

## Capture

1. Walk into any 24/7 or LTD.
2. `/ob_walk` — toggles on.
3. Aim at each shelf item in turn, pausing on each. F8 prints the model name.
4. `/ob_walk` again to stop.
5. Paste the F8 output here, or straight into chat.

Do the same in a house for search spots:

```
/ob_scan 6
```

## Fill this in

| What it looks like | Real model name | Item it should give |
|---|---|---|
| bread / bakery | | `bread` |
| sweets / candy | `v_ret_ml_sweet1` ✅ confirmed | `chocolate_bar` |
| crisps / chips | `v_ret_ml_chips1` ✅ confirmed | `chips` |
| soda can | `prop_ecola_can` ✅ confirmed | `soda` |
| bottled water | | `water_clean` |
| canned goods | | `canned_beans` |
| noodles | | `noodle_bowl` |
| beer | | `beer` |

## Where the results go

`outbreak_worlditems/shared/config.lua`, the `Shelves` table — the one currently holding the
invalid bread entries:

```lua
[`MODEL_NAME_HERE`] = { item = 'bread', count = 1, seconds = 2 },
```

Both `v_ret_ml_bread01` and `v_ret_ml_bread02` need replacing. If a real bakery prop does not
exist in the 24/7 interiors, drop bread from the shelf table and let it come from house searches
instead — `LootCfg` already stocks it there.

## Still open from the same class

| Model | For | Status |
|---|---|---|
| `prop_cs_body_bag` | corpse marker on death (`outbreak_down`) | INVALID, 3 candidates failed |

GTA V may ship no vanilla body-bag prop — most servers stream a custom one. If `/ob_scan` near the
morgue or a hospital turns up nothing, the honest fix is a duffel (`prop_ld_bag_01`) or a tarp, not
more guessing.
