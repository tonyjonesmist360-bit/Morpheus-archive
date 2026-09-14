-- outbreak_supply/client/supply.lua
-- Renders only. The ledger is an ox_lib context menu (the pack's menu language), fed by a
-- server callback on open and by pushes from the server whenever the settlement changes.
-- No loop: the HUD reads hudFlags() from inside outbreak_core's existing tick.
local C = SupplyCfg
local home = nil   -- last model the server pushed for MY home (nil = I hold no key to a claimed house)

RegisterNetEvent('outbreak:supply:update', function(m) home = m end)
CreateThread(function()
  Wait(8000); TriggerServerEvent('outbreak:supply:hello')
  Wait(30000); TriggerServerEvent('outbreak:supply:hello')   -- second ask: the first can land before the character has loaded
end)

exports('getHome', function() return home end)
-- Thin summary for the HUD strip. Colour is reinforced by the word, never the carrier (UI-SYSTEM.md).
exports('hudFlags', function()
  if not home then return nil end
  local crit, low = {}, {}
  for _, c in ipairs(C.Categories) do
    local st = home.stock[c] and home.stock[c].status
    if st == 'critical' then crit[#crit + 1] = c elseif st == 'low' then low[#low + 1] = c end
  end
  return { critical = crit, low = low, starving = home.starving or false, label = home.label }
end)

local COLOR = { critical = 'red', low = 'orange', ok = 'yellow', good = 'green' }
local ICON  = { critical = 'triangle-exclamation', low = 'circle-exclamation', info = 'circle-info' }
local function ago(t)
  local d = math.max(0, GetCloudTimeAsInt() - (t or 0))
  if d < 60 then return 'just now' elseif d < 3600 then return ('%dm ago'):format(d // 60) elseif d < 86400 then return ('%dh ago'):format(d // 3600) end
  return ('%dd ago'):format(d // 86400)
end

local openLedger
local function cookMenu(m)
  local opts = {}
  for _, r in ipairs(m.recipes or {}) do
    opts[#opts + 1] = { title = r.label, icon = 'fire', description = r.can and ('Makes %s · %ds'):format(r.makes, r.seconds) or ('Missing: %s'):format(r.missing),
      disabled = not r.can,
      onSelect = function()
        if exports.outbreak_emotes:action('siphon', r.seconds * 1000, r.label .. '...') then
          TriggerServerEvent('outbreak:supply:cook', m.id, r.id)
          Wait(700); openLedger(m.id)
        end
      end }
  end
  if #opts == 0 then opts[1] = { title = 'Nothing to cook.', readOnly = true } end
  lib.registerContext({ id = 'ob_supply_cook', title = 'Cook — from the stockpile, into it', menu = 'ob_supply', options = opts })
end

local function residentsMenu(m)
  local opts = {}
  for _, n in ipairs(m.names or {}) do
    local o = { title = n, icon = 'user' }
    if m.mine then
      o.description = 'Ask them to leave (they go quietly, take nothing).'
      o.onSelect = function()
        local ok = lib.alertDialog({ header = 'Ask ' .. n .. ' to leave?', content = 'They will go quietly. The others will notice.', centered = true, cancel = true })
        if ok == 'confirm' then TriggerServerEvent('outbreak:supply:dismiss', m.id, n); Wait(500); openLedger(m.id) end
      end
    else o.readOnly = true end
    opts[#opts + 1] = o
  end
  if #opts == 0 then opts[1] = { title = 'Nobody lives here yet.', description = 'Keep food on hand. Strangers come to a fed house.', readOnly = true } end
  lib.registerContext({ id = 'ob_supply_residents', title = ('Residents · %d of %d'):format(m.residents, m.targetResidents), menu = 'ob_supply', options = opts })
end

local function needsMenu(m)
  local opts = {}
  for _, n in ipairs(m.needs or {}) do opts[#opts + 1] = { title = n.text, icon = ICON[n.status] or 'circle', readOnly = true } end
  if #opts == 0 then opts[1] = { title = 'Nothing pressing.', description = 'Stock is good. Enjoy it while it lasts.', readOnly = true } end
  lib.registerContext({ id = 'ob_supply_needs', title = 'Objectives', menu = 'ob_supply', options = opts })
end

local function logMenu(m)
  local opts = {}
  for i, l in ipairs(m.log or {}) do
    if i > 14 then break end
    opts[#opts + 1] = { title = l.text, description = ago(l.at), readOnly = true }
  end
  if #opts == 0 then opts[1] = { title = 'Nothing written yet.', readOnly = true } end
  lib.registerContext({ id = 'ob_supply_log', title = 'Ledger', menu = 'ob_supply', options = opts })
end

openLedger = function(id)
  local m = lib.callback.await('outbreak:supply:model', false, id)
  if not m then lib.notify({ title = 'Nobody lives here.', description = 'Claim it first.', type = 'inform' }) return end
  home = home and home.id == m.id and m or home
  cookMenu(m); residentsMenu(m); needsMenu(m); logMenu(m)
  local opts = {}
  local moraleWord = m.morale >= 70 and 'steady' or m.morale >= 45 and 'uneasy' or m.morale >= 25 and 'fraying' or 'breaking'
  opts[#opts + 1] = { title = ('RESIDENTS %d  ·  MORALE %d (%s)'):format(m.residents, m.morale, moraleWord), icon = 'people-roof',
    progress = m.morale, colorScheme = m.morale < 25 and 'red' or m.morale < 45 and 'orange' or 'green',
    description = #m.names > 0 and table.concat(m.names, ', ') or 'Nobody yet. Strangers come to a fed house.', menu = 'ob_supply_residents' }
  for _, c in ipairs(C.Categories) do
    local s = m.stock[c]
    local right = s.days and (s.days < 0.05 and 'empty' or ('%.1f days'):format(s.days)) or ('%d %s'):format(math.floor(s.units), s.unit)
    opts[#opts + 1] = { title = ('%s  %s'):format(s.label:upper(), right), progress = s.pct, colorScheme = COLOR[s.status] or 'gray', readOnly = true,
      description = s.status == 'good' and 'Fine.' or ('%s — bring %d %s.'):format(s.status, s.ask, s.unit) }
  end
  if m.unboiled > 0 then opts[#opts + 1] = { title = ('%d unboiled water'):format(m.unboiled), icon = 'droplet', description = 'Boil it below. It does not count until you do.', readOnly = true } end
  opts[#opts + 1] = { title = 'Open the stockpile', icon = 'box', description = 'The house storage. Put things in, take things out.', onSelect = function() TriggerEvent('outbreak:client:openStash', m.id) end }
  opts[#opts + 1] = { title = 'Cook', icon = 'fire', description = 'Boil, stew, noodles, meat. Needs a plank or fuel in stock.', menu = 'ob_supply_cook' }
  opts[#opts + 1] = { title = 'Objectives', icon = 'list-check', description = #m.needs > 0 and m.needs[1].text or 'Nothing pressing.', menu = 'ob_supply_needs' }
  opts[#opts + 1] = { title = 'Ledger', icon = 'book', description = m.lastLine or 'Nothing written yet.', menu = 'ob_supply_log' }
  lib.registerContext({ id = 'ob_supply', title = m.label, options = opts })
  lib.showContext('ob_supply')
end

RegisterNetEvent('outbreak:supply:openLedger', function(id) openLedger(id) end)
RegisterCommand('ob_home', function() if home then openLedger(home.id) else lib.notify({ title = 'You have no home.', description = 'Claim a safehouse, or get a key to one.', type = 'inform' }) end end, false)
