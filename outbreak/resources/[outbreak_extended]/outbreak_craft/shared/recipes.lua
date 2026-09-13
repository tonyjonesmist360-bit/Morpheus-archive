CraftCfg = {
  Seconds = 8,
  Recipes = {
    { id = 'bandage',   label = 'Bandage',        gives = { 'bandage', 1 },      needs = { { 'ripped_sheet', 2 } },                        desc = 'Two clean-ish strips, folded tight.' },
    { id = 'splint',    label = 'Splint',         gives = { 'splint', 1 },       needs = { { 'plank', 1 }, { 'ripped_sheet', 1 } },        desc = 'A plank and a strap. Medicine.' },
    { id = 'sheets',    label = 'Tear up cloth',  gives = { 'ripped_sheet', 2 }, needs = { { 'duct_tape', 1 } },                           desc = 'Sacrifice the tape roll backing for strips.' },
    { id = 'toolkit',   label = 'Engine parts',   gives = { 'engine_parts', 1 }, needs = { { 'nails', 1 }, { 'duct_tape', 2 }, { 'hammer_tool', 0 } }, desc = 'Scrap, tape, and violence. Hammer required, not consumed.' },
  },
}
