-- outbreak_binds/client/binds.lua — THE ONLY RegisterKeyMapping calls in the pack.
-- Pad parameter IDs are RAGE index names (LDOWN_INDEX etc), NOT 'DPAD_DOWN'. The old
-- names printed 'Invalid key name DPAD_DOWN' on every client start and registered nothing.
-- Verify: join and watch F8 - no 'Invalid key name' lines means these are right.
-- Design: one wheel key does almost everything. A handful of "reflex" keys for things
-- you need mid-fight without a menu. Every bind registers a keyboard AND a pad default.
local function bind(cmd, desc, key, pad)
  RegisterKeyMapping(cmd, desc, 'keyboard', key)
  if pad then RegisterKeyMapping(cmd, desc .. ' (pad)', 'pad_digitalbuttonany', pad) end
end
-- commands that already exist in their owner resources; we only map keys to them
bind('ob_status',  'Status - everything at once','F1',     'SELECT_INDEX')
bind('ob_wheel',   'Survival wheel',            'G',      'LDOWN_INDEX')
bind('inv',        'Inventory',                 'TAB',    'LUP_INDEX')          -- ox_inventory's own command
bind('handsup',    'Hands up (reflex)',         'T',      nil)
bind('whistle',    'Whistle (LOUD, reflex)',    'GRAVE',  nil)
bind('stopemote',  'Stop emote / cancel',       'X',      'RRIGHT_INDEX')          -- B is "cancel" muscle memory
bind('ob_radioptt','Radio quick-open',          'N',      'LLEFT_INDEX')
bind('ob_radioup', 'Radio channel up',           'RBRACKET', nil)
bind('ob_radiodown','Radio channel down',        'LBRACKET', nil)
bind('fallen',     'Memorial wall',             'F5',     nil)
bind('ob_distress','Distress call (works while down)','F6',  'RLEFT_INDEX')   -- pad X
bind('crouch',     'Crouch (toggle)',           '', nil)   -- unbound by default (Ctrl is GTA's stealth); bind it in Settings > Key Bindings > FiveM, or use the wheel
bind('journal',    'Field journal',             'J',      nil)   -- pad: via the wheel
bind('dm',         'Director menu (DMs only)',  'F10',    nil)
bind('craft',      'Craft (when enabled)',      'K',      'LRIGHT_INDEX')
bind('shakedown',  'Shakedown panel (debug)',   'F9',     nil)
RegisterCommand('ob_radioptt', function() TriggerEvent('outbreak:client:openRadio') end, false)
-- NOTE: pma-voice PTT (CapsLock / pad RB) and ox_target (LeftAlt → rebind to E) register their own keys.
