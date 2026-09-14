-- outbreak_chat/client/chat.lua — chat suggestions only; templates are sent inline by the server.
CreateThread(function()
  Wait(1000)
  TriggerEvent('chat:addSuggestion', '/ooc', 'Out of character. Grey, bracketed, never IC. Works while down.', { { name = 'message', help = 'what you want to say' } })
  TriggerEvent('chat:addSuggestion', '/announce', 'Admin: server-wide styled message', { { name = 'message', help = 'text' } })
  TriggerEvent('chat:addSuggestion', '/ob_voicereset', 'Reset your own voice connection (nobody can hear you)')
  TriggerEvent('chat:addSuggestion', '/ob_distress', 'Distress call: radio if tuned, a scream if not. Works while down.')
end)
