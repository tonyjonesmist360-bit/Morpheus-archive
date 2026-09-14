-- outbreak_chat/server/chat.lua
-- /ooc  — out of character, grey and bracketed so it never reads as IC.
-- /announce (ace outbreak.admin) — server-wide, styled, also a notify so nobody misses it.
local OOC = '<div style="padding:4px 8px;margin:2px 0;background:rgba(24,26,19,.65);border-left:3px solid rgba(216,210,192,.35);color:rgba(216,210,192,.75);font-style:italic"><b style="font-style:normal;letter-spacing:1px;font-size:11px;color:rgba(216,210,192,.5)">OOC</b> &nbsp;<span style="color:rgba(216,210,192,.9);font-style:normal">{0}</span>: {1}</div>'
local ANN = '<div style="padding:8px 12px;margin:4px 0;background:rgba(142,47,47,.55);border:1px solid rgba(216,210,192,.35);color:#d8d2c0;letter-spacing:.5px"><b style="letter-spacing:1.6px;font-size:11px;text-transform:uppercase">Announcement</b><br>{0}</div>'

local function clean(s) return (tostring(s):gsub('[<>]', '')):sub(1, 240) end
local function nameOf(src)
  local ok, p = pcall(function() return exports['qb-core']:GetCoreObject().Functions.GetPlayer(src) end)
  local ci = ok and p and p.PlayerData and p.PlayerData.charinfo
  return ci and ci.firstname and (ci.firstname .. ' ' .. (ci.lastname or '')) or GetPlayerName(src) or ('#' .. src)
end

RegisterCommand('ooc', function(src, args, raw)
  if src == 0 then return end
  local msg = clean(table.concat(args, ' '))
  if msg == '' then TriggerClientEvent('chat:addMessage', src, { template = OOC, args = { 'usage', '/ooc your message' } }) return end
  TriggerClientEvent('chat:addMessage', -1, { template = OOC, args = { clean(nameOf(src)), msg } })
end, false)

RegisterCommand('announce', function(src, args)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  local msg = clean(table.concat(args, ' ')); if msg == '' then return end
  TriggerClientEvent('chat:addMessage', -1, { template = ANN, args = { msg } })
  TriggerClientEvent('ox_lib:notify', -1, { title = 'ANNOUNCEMENT', description = msg, type = 'warning', duration = 15000, position = 'top' })
  print(('^3[OB-ADMIN]^7 announce by %s: %s'):format(src == 0 and 'console' or GetPlayerName(src), msg))
end, true)
