-- outbreak_spawn/client/spawn.lua
-- MOTD: every load, six seconds in, once.
local motdShown = false
local function motd()
  if motdShown or not SpawnCfg.Motd then return end
  motdShown = true
  local m = SpawnCfg.Motd
  for i, l in ipairs(m.lines) do
    TriggerEvent('chat:addMessage', { template = '<div style="padding:4px 8px;margin:1px 0;background:rgba(24,26,19,.55);border-left:3px solid #b4552d;color:#d8d2c0">{0}</div>', args = { (i == 1 and ('<b style="letter-spacing:1.6px">' .. m.title .. '</b> &nbsp; ') or '') .. l } })
  end
  lib.notify({ title = m.title, description = m.lines[1], type = 'inform', duration = 12000, position = 'top' })
end
AddEventHandler('QBCore:Client:OnPlayerLoaded', function() SetTimeout(6000, motd) end)

-- ── FIRST TEN MINUTES ──
local guide = { running = false, done = {}, step = 0 }
local function kvpKey() local ok, cid = pcall(function() return exports['qb-core']:GetCoreObject().Functions.GetPlayerData().citizenid end); return 'ob_guide_' .. tostring(ok and cid or 'x') end
local function snd(s) if s then PlaySoundFrontend(-1, s[1], s[2], true) end end
local function nearestHouseDoor(pos)
  local best, bd = nil, math.huge
  for _, h in ipairs((HousingCfg and HousingCfg.Houses) or {}) do local d = #(pos - h.door); if d < bd then best, bd = h, d end end
  return best, bd
end
local function runGuide()
  local G = SpawnCfg.Guide; if not G or not G.enabled or guide.running then return end
  guide.running = true; guide.done = {}; guide.step = 0
  Wait(9000) -- let the scenario story cards go first
  for i, s in ipairs(G.Steps) do
    if not guide.running then break end
    guide.step = i
    lib.showTextUI(('%d/%d  %s'):format(i, #G.Steps, s.text), { position = 'top-center' })
    local t0 = exports.outbreak_core:getTick() or {}
    local startPos = t0.pos or GetEntityCoords(PlayerPedId())
    local startThirst = 0; pcall(function() startThirst = exports.outbreak_needs:getNeeds().thirst or 0 end)
    local target
    if s.check == 'house' then
      local h = nearestHouseDoor(startPos)
      if h then target = h.door; SetNewWaypoint(h.door.x, h.door.y) end
    end
    local began = GetGameTimer()
    while guide.running do
      Wait(500)
      local t = exports.outbreak_core:getTick() or {}
      local pos = t.pos or GetEntityCoords(PlayerPedId())
      local ok = false
      if s.check == 'moved' then ok = #(pos - startPos) >= (s.arg or 5.0)
      elseif s.check == 'wait' then ok = GetGameTimer() - began >= (s.arg or 8) * 1000
      elseif s.check == 'thirst' then local th = 0; pcall(function() th = exports.outbreak_needs:getNeeds().thirst or 0 end); ok = th >= startThirst + (s.arg or 5)
      elseif s.check == 'house' then ok = (not target) or #(pos - target) <= (s.arg or 25.0) end
      if not ok and s.timeout and s.timeout > 0 and GetGameTimer() - began >= s.timeout * 1000 then ok = true end
      if ok then break end
    end
    guide.done[s.id] = true
    snd(i == #G.Steps and G.doneSound or G.stepSound)
    if s.check == 'house' and target then local b = GetFirstBlipInfoId(8); if DoesBlipExist(b) then SetWaypointOff() end end
    Wait(400)
  end
  lib.hideTextUI()
  if guide.running then SetResourceKvp(kvpKey(), '1') end
  guide.running = false
end
exports('onboarding', function()
  local out = {}
  for _, s in ipairs((SpawnCfg.Guide or {}).Steps or {}) do out[#out + 1] = { id = s.id, text = s.text, done = guide.done[s.id] == true } end
  return out
end)
RegisterCommand('tutorial', function(_, a)
  if a[1] == 'off' then guide.running = false; lib.hideTextUI(); lib.notify({ title = 'Guide off.', type = 'inform' }) return end
  if guide.running then lib.notify({ title = 'Already running.', description = '/tutorial off stops it.', type = 'inform' }) return end
  CreateThread(runGuide)
end, false)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and guide.running then lib.hideTextUI() end end)

RegisterNetEvent('outbreak:client:freshSpawn', function(id)
  local p = SpawnCfg.Scenarios[id]; if not p then return end
  local ped = PlayerPedId()
  DoScreenFadeOut(0)
  SetEntityCoords(ped, p.pos.x, p.pos.y, p.pos.z); SetEntityHeading(ped, p.pos.w)
  Wait(1000); DoScreenFadeIn(4000); Wait(1500)
  lib.notify({ title = p.label, description = p.story, duration = 10000, type = 'inform' })
  Wait(5000)
  lib.notify({ title = 'Check your pockets.', description = 'Find water. Find a radio. Stay quiet. Press G.', duration = 8000, type = 'warning' })
  if SpawnCfg.Guide and SpawnCfg.Guide.enabled and GetResourceKvpString(kvpKey()) ~= '1' then CreateThread(runGuide) end
end)
