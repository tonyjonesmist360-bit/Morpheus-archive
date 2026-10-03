-- outbreak_editor/server/packs.lua — one JSON for the whole authored world. packs/<name>.json in this resource.
local Ed = function() return exports.outbreak_editor end
local function allowed(src) return src == 0 or IsPlayerAceAllowed(src, EditorCfg.Ace) end
local function export(name)
  local S = Ed():get()
  local pack = { name = name, version = 1, at = os.date('%Y-%m-%d %H:%M'), npcs = {}, hidden = {}, interactions = {}, zones = {}, kv = S.kv, missions = {} }
  for _, v in pairs(S.npcs) do pack.npcs[#pack.npcs + 1] = v end
  for _, v in pairs(S.hidden) do pack.hidden[#pack.hidden + 1] = v end
  for _, v in pairs(S.interactions) do pack.interactions[#pack.interactions + 1] = v end
  for _, v in pairs(S.zones) do pack.zones[#pack.zones + 1] = v end
  for _, v in pairs(S.missions) do pack.missions[#pack.missions + 1] = v end
  local file = ('packs/%s.json'):format(name:gsub('[^%w_%-]', ''))
  SaveResourceFile(GetCurrentResourceName(), file, json.encode(pack, { indent = true }), -1)
  return file, #pack.npcs + #pack.hidden + #pack.interactions + #pack.zones + #pack.missions
end
local function import(name, src)
  local raw = LoadResourceFile(GetCurrentResourceName(), ('packs/%s.json'):format(name:gsub('[^%w_%-]', '')))
  if not raw then return nil, 'no such pack' end
  local ok, pack = pcall(json.decode, raw); if not ok or type(pack) ~= 'table' then return nil, 'bad json' end
  local n = 0
  for _, v in ipairs(pack.npcs or {}) do v.id = nil; if Ed():ops('npc.save', src, v) then n = n + 1 end end
  for _, v in ipairs(pack.hidden or {}) do v.id = nil; if Ed():ops('hidden.add', src, v) then n = n + 1 end end
  for _, v in ipairs(pack.interactions or {}) do v.id = nil; if Ed():ops('interaction.save', src, v) then n = n + 1 end end
  for _, v in ipairs(pack.zones or {}) do v.id = nil; if Ed():ops('zone.save', src, v) then n = n + 1 end end
  for k, v in pairs(pack.kv or {}) do if Ed():ops('kv.set', src, { k = k, v = v }) then n = n + 1 end end
  for _, v in ipairs(pack.missions or {}) do if Ed():ops('mission.save', src, { def = v.def, enabled = v.enabled }) then n = n + 1 end end
  return n
end
RegisterCommand('editor_export', function(src, a) if not allowed(src) then return end; local f, n = export(a[1] or os.date('world-%Y%m%d-%H%M')); print(('^5[OB-EDITOR]^7 exported %d objects -> %s'):format(n, f)); if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = 'Pack exported', description = f, type = 'success' }) end end, true)
RegisterCommand('editor_import', function(src, a) if not allowed(src) then return end; if not a[1] then print('usage: editor_import <name>') return end; local n, err = import(a[1], src); print(('^5[OB-EDITOR]^7 import %s: %s'):format(a[1], n and (n .. ' objects') or err)) end, true)
lib.callback.register('outbreak:editor:pack', function(src, op, name) if not allowed(src) then return nil end; if op == 'export' then local f, n = export(name or os.date('world-%Y%m%d-%H%M')); return { file = f, n = n } elseif op == 'import' then local n, err = import(name or '', src); return { n = n, err = err } end end)
