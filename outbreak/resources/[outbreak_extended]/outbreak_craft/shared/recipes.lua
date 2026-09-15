CraftCfg = {
  Seconds = 8,
  -- THE BENCH (v0.22). Recipes marked bench = true only show at a workbench: map props below
  -- (names from memory - UNVERIFIED) or a placed 'workbench' item. Field recipes work anywhere on K.
  BenchModels = { 'prop_tool_bench02', 'prop_tool_bench02_ld', 'prop_toolchest_05', 'prop_workbench_01' },
  Sound = { 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
  Recipes = {
    { id = 'molotov',   label = 'Molotov',        gives = { 'WEAPON_MOLOTOV', 1 }, needs = { { 'beer', 1 }, { 'ripped_sheet', 1 }, { 'gas_can_small', 0 } }, bench = true, desc = 'A bottle, a rag, a splash from the can. The can is not used up.' },
    { id = 'boards',    label = 'Barricade kit',  gives = { 'barricade_kit', 1 }, needs = { { 'plank', 2 }, { 'nails', 1 }, { 'hammer_tool', 0 } }, bench = true, desc = 'Boards cut and nails counted: one level of barricade, ready to hang.' },
    { id = 'keyblank',  label = 'Key blank',      gives = { 'key_blank', 1 },     needs = { { 'nails', 1 }, { 'duct_tape', 1 } }, bench = true, desc = 'Filed from a nail. Cut it on a running engine to claim the car.' },
    { id = 'padlock',   label = 'Padlock',        gives = { 'padlock', 1 },       needs = { { 'nails', 2 }, { 'engine_parts', 0 } }, bench = true, desc = 'Ugly, heavy, works.' },
    { id = 'bandage',   label = 'Bandage',        gives = { 'bandage', 1 },      needs = { { 'ripped_sheet', 2 } },                        desc = 'Two clean-ish strips, folded tight.' },
    { id = 'splint',    label = 'Splint',         gives = { 'splint', 1 },       needs = { { 'plank', 1 }, { 'ripped_sheet', 1 } },        desc = 'A plank and a strap. Medicine.' },
    { id = 'sheets',    label = 'Tear up cloth',  gives = { 'ripped_sheet', 2 }, needs = { { 'duct_tape', 1 } },                           desc = 'Sacrifice the tape roll backing for strips.' },
    { id = 'toolkit',   label = 'Engine parts',   gives = { 'engine_parts', 1 }, needs = { { 'nails', 1 }, { 'duct_tape', 2 }, { 'hammer_tool', 0 } }, desc = 'Scrap, tape, and violence. Hammer required, not consumed.' },
  },
}
