-- client half of CHAIN 2: the bus is a normal vehicles-v2 vehicle. We only add a blip and armor cosmetics once it's known.
local blip
RegisterNetEvent('outbreak:opp:bus:spawned', function(netId)
  CreateThread(function()
    local t = GetGameTimer(); local ent = 0
    while GetGameTimer() - t < 10000 do ent = NetworkGetEntityFromNetworkId(netId); if ent ~= 0 and DoesEntityExist(ent) then break end Wait(250) end
    if ent == 0 then return end
    SetVehicleCanBeVisiblyDamaged(ent, false); SetVehicleStrong(ent, true); SetVehicleHasStrongAxles(ent, true)
    SetVehicleColours(ent, 0, 0); SetVehicleDirtLevel(ent, 12.0)
  end)
end)
-- journal confirmation of the depot puts a blip on it (exact coords intel handled by outbreak_intel's presentation; nothing extra here)
