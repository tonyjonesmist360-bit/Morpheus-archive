-- outbreak_map/server/scuff.lua
RegisterNetEvent('outbreak:server:scuff', function(d)
  local src = source
  if type(d) ~= 'table' or type(d.note) ~= 'string' then return end
  MySQL.insert('INSERT INTO outbreak_scuffs (reporter, x, y, z, note, reported_at) VALUES (?, ?, ?, ?, ?, NOW())',
    { GetPlayerName(src), d.x, d.y, d.z, d.note:sub(1, 200) })
  print(('^3[SCUFF]^7 %s @ %.1f, %.1f, %.1f — %s'):format(GetPlayerName(src), d.x, d.y, d.z, d.note))
end)

RegisterCommand('scufflist', function(src)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'command') then return end
  local rows = MySQL.query.await('SELECT * FROM outbreak_scuffs ORDER BY reported_at DESC LIMIT 50') or {}
  for _, r in ipairs(rows) do print(('%s | %.1f, %.1f, %.1f | %s'):format(r.reporter, r.x, r.y, r.z, r.note)) end
end, true)
