-- outbreak_radio/client/range.lua — applies the server's reach row to who you actually hear on the radio.
-- pma-voice tells us when a remote player keys their radio; we scale their volume by the server-computed quality.
local talking = {}
local function reach(sid) local row = LocalPlayer.state.radioReach; return row and row[tostring(sid)] or nil end

AddEventHandler('pma-voice:setTalkingOnRadio', function(sid, on)
  if on then
    local q = reach(sid)
    if q == nil then return end                       -- not on my channel per server: leave pma's default
    talking[sid] = true
    if q < RadioCfg.Floor then MumbleSetVolumeOverrideByServerId(sid, 0.0); lib.notify({ title = '*static*', type = 'inform', duration = 1500 })
    else MumbleSetVolumeOverrideByServerId(sid, math.max(0.2, q)) end
  elseif talking[sid] then
    talking[sid] = nil
    MumbleSetVolumeOverrideByServerId(sid, -1.0)      -- back to proximity rules
  end
end)
-- some pma-voice versions use this name instead
AddEventHandler('pma-voice:radioActive', function(on) end)

-- repeater blips (dead = grey, active = green)
local blips = {}
local function drawRepeaters()
  for id, r in pairs(RadioCfg.Repeaters) do
    if blips[id] then RemoveBlip(blips[id]) end
    local st = (GlobalState.obRepeaters or {})[id]
    local b = AddBlipForCoord(r.pos.x, r.pos.y, r.pos.z); SetBlipSprite(b, 459); SetBlipScale(b, 0.7); SetBlipColour(b, st and st.active and 2 or 40)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(r.label .. (st and st.active and ' (active)' or ' (dead)')); EndTextCommandSetBlipName(b)
    blips[id] = b
  end
end
AddStateBagChangeHandler('obRepeaters', 'global', function() Wait(0); drawRepeaters() end)
CreateThread(function() Wait(3000); drawRepeaters() end)
