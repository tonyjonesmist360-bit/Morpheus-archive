IntelCfg = {
  States = { 'undiscovered', 'rumor', 'partial', 'confirmed', 'active', 'completed', 'failed', 'obsolete' },
  Rank   = { undiscovered = 0, rumor = 1, partial = 2, confirmed = 3, active = 4, completed = 5, failed = 5, obsolete = 9 },
  Reliability = { 'rumor', 'credible', 'confirmed' },
  Categories = { 'document', 'transmission', 'rumor', 'photograph', 'coordinates', 'npc', 'discovery' },
  ArrivalCheckTicks = 8,     -- every N core ticks (500ms each)
  DocumentItem = 'document', -- ox item; metadata.intel = intelId (set server-side)
}
