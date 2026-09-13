-- outbreak_binds/client/binds.lua — THE ONLY RegisterKeyMapping calls in the pack.
-- Design: one wheel key does almost everything. A handful of "reflex" keys for things
-- you need mid-fight without a menu. Every bind registers a keyboard AND a pad default.
local function bind(cmd, desc, key, pad)
  RegisterKeyMapping(cmd, desc, 'keyboard', key)
  if pad then RegisterKeyMapping(cmd, desc .. ' (pad)', 'pad_digitalbuttonany', pad) end
end
-- commands that already exist in their owner resources; we only map keys to them
bind('ob_wheel',   'Survival wheel',            'G',      'DPAD_DOWN')
bind('inv',        'Inventory',                 'TAB',    'DPAD_UP')          -- ox_inventory's own command
bind('handsup',    'Hands up (reflex)',         'T',      nil)
bind('whistle',    'Whistle (LOUD, reflex)',    'GRAVE',  nil)
bind('stopemote',  'Stop emote / cancel',       'X',      'BUTTON_B')          -- B is "cancel" muscle memory
bind('ob_radioptt','Radio quick-open',          'N',      'DPAD_LEFT')
bind('fallen',     'Memorial wall',             'F5',     nil)
bind('journal',    'Field journal',             'J',      nil)   -- pad: via the wheel
bind('dm',         'Director menu (DMs only)',  'F10',    nil)
bind('craft',      'Craft (when enabled)',      'K',      'DPAD_RIGHT')
bind('shakedown',  'Shakedown panel (debug)',   'F9',     nil)
RegisterCommand('ob_radioptt', function() TriggerEvent('outbreak:client:openRadio') end, false)
-- NOTE: pma-voice PTT (CapsLock / pad RB) and ox_target (LeftAlt → rebind to E) register their own keys.
