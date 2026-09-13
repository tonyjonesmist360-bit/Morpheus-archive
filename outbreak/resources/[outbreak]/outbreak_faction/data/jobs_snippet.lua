-- PASTE INTO qbx_core/shared/jobs.lua (replace the 'police' entry with these two)
-- Players are assigned via /setjob <id> military <grade> from the admin menu / txAdmin.

military = {
  label = 'Military Remnant',
  type = 'leo',             -- keeps leo-gated scripts working if any survive the strip
  defaultDuty = true,
  offDutyPay = false,
  grades = {
    [0] = { name = 'Private',    payment = 0 },
    [1] = { name = 'Corporal',   payment = 0 },
    [2] = { name = 'Sergeant',   payment = 0 },
    [3] = { name = 'Lieutenant', payment = 0 },
    [4] = { name = 'Captain',    payment = 0, isboss = true },
  },
},
raider = {
  label = 'Raider',
  defaultDuty = true,
  offDutyPay = false,
  grades = {
    [0] = { name = 'Scavenger', payment = 0 },
    [1] = { name = 'Enforcer',  payment = 0 },
    [2] = { name = 'Warlord',   payment = 0, isboss = true },
  },
},
