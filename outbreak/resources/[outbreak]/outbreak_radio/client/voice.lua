-- outbreak_radio/client/voice.lua — voice reinit without a reconnect.
-- Best-effort, in order of how often each step is the actual fix. UNVERIFIED against a live
-- mumble failure: the natives are real, the pma-voice internals they poke are inferred.
local function voiceReset()
  local me = GetPlayerServerId(PlayerId())
  local before = MumbleIsConnected()
  -- 1. pma-voice's voice target is 1; drop and rebuild it, and put us back in our own channel
  MumbleClearVoiceTarget(1)
  MumbleSetVoiceTarget(1)
  MumbleSetVoiceChannel(me)
  -- 2. bounce the radio channel so pma-voice rebuilds its radio targets
  local ch = 0
  pcall(function() ch = exports['pma-voice']:getRadioChannel() or 0 end)
  pcall(function() exports['pma-voice']:setRadioChannel(0) end)
  Wait(250)
  pcall(function() exports['pma-voice']:setRadioChannel(ch) end)
  -- 3. bounce proximity so the proximity targets are re-added (cycleproximity is pma-voice's own command)
  pcall(function() ExecuteCommand('cycleproximity') end); Wait(150)
  pcall(function() ExecuteCommand('cycleproximity') end); Wait(150)
  pcall(function() ExecuteCommand('cycleproximity') end)
  -- 4. external mumble server configured? force a reconnect to it
  local addr, port = GetConvar('voice_externalAddress', ''), GetConvarInt('voice_externalPort', 0)
  if addr ~= '' and port > 0 then MumbleSetServerAddress(addr, port) end
  Wait(500)
  local after = MumbleIsConnected()
  lib.notify({ title = 'Voice reset.', description = ('Mumble was %s, now %s. Say something.'):format(before and 'connected' or 'DOWN', after and 'connected' or 'reconnecting'), type = after and 'success' or 'warning', duration = 8000 })
  if GlobalState.obDebug then print(('[OB-VOICE] reset: connected before=%s after=%s ch=%d'):format(tostring(before), tostring(after), ch)) end
end
RegisterNetEvent('outbreak:client:voiceReset', voiceReset)
RegisterCommand('ob_voicereset', voiceReset, false)   -- self, no gate: if you cannot be heard you cannot ask an admin
