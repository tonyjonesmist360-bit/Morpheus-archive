-- outbreak_status/client/status.lua
-- ONE key -> everything you need or have. Reads only existing client exports, so this
-- resource cannot desync state or add authority. If an export is missing the panel shows
-- a dash for that field rather than erroring - it must never be the thing that breaks.
local open = false

local function ex(fn, default)
  local ok, v = pcall(fn)
  if ok and v ~= nil then return v end
  return default
end

-- What counts as food / water / meds / tools. Keep in sync with ox_items_snippet.
local GROUPS = {
  food  = { 'canned_beans', 'mre', 'chocolate_bar', 'bread', 'noodle_bowl', 'chips', 'sweets' },
  water = { 'water_clean', 'water_dirty', 'purify_tabs', 'soda', 'beer' },
  meds  = { 'bandage', 'ripped_sheet', 'antibiotics', 'splint', 'adrenaline_shot', 'painkillers' },
  tools = { 'hammer_tool', 'crowbar_tool', 'can_opener', 'plank', 'nails', 'radio_handheld', 'radio_battery' },
}

local function counts(list)
  local out, total = {}, 0
  for _, item in ipairs(list) do
    local n = ex(function() return exports.ox_inventory:Search('count', item) end, 0) or 0
    if n > 0 then out[#out + 1] = { name = item:gsub('_', ' '), n = n }; total = total + n end
  end
  table.sort(out, function(a, b) return a.n > b.n end)
  return out, total
end

local SKILLS = { 'mechanics', 'medicine', 'stealth', 'fitness', 'scavenging' }

local function gather()
  local needs   = ex(function() return exports.outbreak_needs:getNeeds() end, {}) or {}
  local wounds  = ex(function() return exports.outbreak_needs:getWounds() end, {}) or {}
  local bleeding= ex(function() return exports.outbreak_needs:isBleeding() end, false)
  local ident   = ex(function() return lib.callback.await('outbreak:identity:get', false) end, nil)

  local skills = {}
  for _, s in ipairs(SKILLS) do
    skills[#skills + 1] = { name = s, level = ex(function() return exports.outbreak_skills:getLevel(s) end, 0) or 0 }
  end

  local woundList = {}
  for part, w in pairs(wounds) do
    woundList[#woundList + 1] = { part = tostring(part):gsub('_', ' '), kind = type(w) == 'table' and (w.kind or w.type or 'wound') or tostring(w) }
  end
  table.sort(woundList, function(a, b) return a.part < b.part end)

  local carrying = {}
  for group, list in pairs(GROUPS) do
    local items, total = counts(list)
    carrying[group] = { items = items, total = total }
  end

  local hour = GlobalState.obTime
  return {
    identity = {
      callsign = ident and ident.callsign or nil,
      former   = ident and ident.former or nil,
      desc     = ident and ident.description or nil,
    },
    condition = {
      hunger   = math.floor(tonumber(needs.hunger) or 0),
      thirst   = math.floor(tonumber(needs.thirst) or 0),
      fatigue  = math.floor(tonumber(needs.fatigue) or 0),
      health   = math.floor(((GetEntityHealth(PlayerPedId()) - 100) / 100) * 100),
      infected = needs.infected and true or false,
      bleeding = bleeding and true or false,
      down     = ex(function() return exports.outbreak_down:getDownState() end, nil),
      wounds   = woundList,
    },
    carrying = carrying,
    skills = skills,
    world = {
      hour    = hour and math.floor(hour) or nil,
      weather = GlobalState.obWeather or nil,
      blackout= GlobalState.obBlackout and true or false,
      noise   = math.floor(ex(function() return exports.outbreak_noise:getNoise() end, 0) or 0),
      zombies = ex(function() return exports.outbreak_core:countZombies() end, 0) or 0,
      channel = ex(function() return exports.outbreak_radio:getChannel() end, 0) or 0,
      job     = ex(function() return exports.outbreak_faction:getJob() end, nil),
      zone    = ex(function() local z = exports.outbreak_core:currentZone(); return z and z.id end, nil),
      heavy   = ex(function() local z = exports.outbreak_core:currentZone(); return z and (z.mult or 1) > 1.5 end, false),
    },
  }
end

local function close()
  if not open then return end
  open = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })
end

local function show()
  if open then close() return end
  open = true
  SendNUIMessage({ action = 'open', data = gather() })
  SetNuiFocus(true, true)
end

RegisterCommand('ob_status', show, false)
RegisterNUICallback('close', function(_, cb) close(); cb('ok') end)

-- Never let the panel trap the player: Escape and Backspace both release focus.
CreateThread(function()
  while true do
    if open then
      Wait(0)
      if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then close() end
    else
      Wait(300)
    end
  end
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then SetNuiFocus(false, false) end end)
