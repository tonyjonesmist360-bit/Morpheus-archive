GroupCfg = {
  MaxMembers = 6,
  InviteRange = 6.0,          -- metres: invite the nearest player
  InviteSeconds = 45,         -- an invite you do not answer lapses
  MaxPins = 8,
  PublishSeconds = 5,         -- how often a member's position/vitals go out (statebag, only while in a crew)
  MemberBlip = { sprite = 1, colour = 3, scale = 0.85 },   -- blue dot. sprite ids from memory - unverified
  PinBlip    = { sprite = 1, colour = 5, scale = 0.7 },    -- yellow dot with the label
  Sound = { join = { 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET' }, pin = { 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET' } },
}
