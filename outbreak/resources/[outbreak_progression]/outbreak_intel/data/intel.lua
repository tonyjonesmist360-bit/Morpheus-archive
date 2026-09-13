-- STATIC INTEL CATALOG. Every intel record that can exist. Never mutated at runtime.
-- presentation: coords | area{center,radius} | landmark | frequency | photo | clue
-- sources: which discovery sources may create/upgrade this record, and the level each grants
IntelCatalog = {
  -- ── Chain 1: Grapeseed survivor camp (IMPLEMENTED) ──
  camp_grapeseed_rumor = {
    title = 'Someone is holding out near Grapeseed', category = 'transmission', reliability = 'rumor',
    area = { center = vec3(2180.0, 4990.0, 41.0), radius = 320.0 },
    clue = 'A voice on channel 4, cutting in and out: "...east of Grapeseed... the farm with the silo... we have water..."',
    sources = { radio = 'rumor', npc = 'partial', arrival = 'confirmed' }, opportunity = 'camp_defense_grapeseed',
  },
  camp_grapeseed_location = {
    title = 'Silo Farm survivor camp', category = 'discovery', reliability = 'confirmed',
    coords = vec3(2211.7, 4988.3, 41.6),
    clue = 'A dozen people behind chain-link and a wall of pickup trucks. They watched you the whole way in.',
    sources = { arrival = 'confirmed', opportunity = 'confirmed' }, opportunity = 'camp_defense_grapeseed',
  },
  camp_grapeseed_horde = {
    title = 'Migration heading for Silo Farm', category = 'transmission', reliability = 'credible',
    landmark = 'Silo Farm, Grapeseed — coming up from the south along the river road.',
    clue = '"They saw it from the water tower. Hundreds. Two nights, maybe less."',
    sources = { radio = 'confirmed', opportunity = 'confirmed' }, opportunity = 'camp_defense_grapeseed',
  },
  -- ── Chain 2: armored bus (STUB) ──
  bus_photo = { title = 'Photograph: a bus built to last', category = 'photograph', reliability = 'credible', photo = 'bus_01',
    clue = 'Plate welded over every window. A name painted on the side you can\'t quite read.', sources = { document = 'partial' }, opportunity = 'armored_bus' },
  bus_manifest = { title = 'Depot manifest, route 14', category = 'document', reliability = 'confirmed',
    area = { center = vec3(-1200.0, -1600.0, 4.0), radius = 400.0 }, sources = { document = 'partial', arrival = 'confirmed' }, opportunity = 'armored_bus' },
  -- ── Chain 3: weapons cache (STUB) ──
  cache_journal_1 = { title = 'Field journal, page 1 of 3', category = 'document', reliability = 'credible', clue = '"...buried under the third pylon past the..." (torn)', sources = { document = 'partial' }, opportunity = 'weapons_cache' },
  cache_journal_2 = { title = 'Field journal, page 2 of 3', category = 'document', reliability = 'credible', clue = '"...combination is my daughter\'s birthday. She\'d be nine."', sources = { document = 'partial' }, opportunity = 'weapons_cache' },
  cache_journal_3 = { title = 'Field journal, page 3 of 3', category = 'document', reliability = 'confirmed', coords = vec3(-2044.0, 3170.0, 32.8), sources = { document = 'confirmed' }, opportunity = 'weapons_cache' },
  -- ── Chain 4: repeater (STUB) ──
  repeater_tower = { title = 'Dead repeater on Mount Chiliad', category = 'discovery', reliability = 'confirmed', coords = vec3(501.0, 5604.0, 797.9),
    clue = 'Every radio in the county would reach farther with power and a new coil.', sources = { arrival = 'confirmed', npc = 'partial' }, opportunity = 'repeater' },
  -- ── Chain 5: island, opening chapter (STUB) ──
  island_maritime = { title = 'Maritime broadcast fragment', category = 'transmission', reliability = 'rumor', frequency = 16,
    clue = '"...all vessels... the light is still on... we can take twelve more..." A lighthouse? Which one?', sources = { radio = 'rumor' }, opportunity = 'island' },  -- opening rumor is live (needs the Chiliad relay); the chain itself is still a stub
  island_charts = { title = 'Marina charts with a circled bearing', category = 'document', reliability = 'credible',
    area = { center = vec3(-3400.0, 950.0, 8.0), radius = 600.0 }, sources = { document = 'partial', arrival = 'confirmed' }, opportunity = 'island' },
  island_landing = { title = 'The island', category = 'discovery', reliability = 'confirmed', coords = vec3(4900.0, -5180.0, 2.5),
    clue = 'Sand. Real, clean sand. A lighthouse. And people watching from the treeline who did not wave.', sources = { arrival = 'confirmed', opportunity = 'confirmed' }, opportunity = 'island' },
}
