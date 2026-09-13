-- outbreak_opportunities/client/opportunities.lua — generic client side: state mirror + journal feed
local opps = {}
RegisterNetEvent('outbreak:opp:state', function(id, v)
  opps[id] = v
  TriggerEvent('outbreak:intel:journalData', exports.outbreak_intel:getIntel(), opps)
  if v.state == 'active' and v.stage == 1 then lib.notify({ title = 'Opportunity: ' .. v.title, description = 'Open your journal (J).', type = 'warning', duration = 9000 }) end
end)
RegisterNetEvent('outbreak:opp:stage', function(id, stage, data)
  if opps[id] then opps[id].stage = stage end
  TriggerEvent('outbreak:opp:stageLocal', id, stage, data)
end)
-- hook for chain client files: AddEventHandler('outbreak:opp:stageLocal', function(id, stage, data) ... end)
AddEventHandler('outbreak:opp:stageLocal', function() end)
exports('getOpportunities', function() return opps end)
