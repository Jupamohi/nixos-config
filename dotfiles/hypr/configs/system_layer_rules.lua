-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- System defaults migrated from configs/LayerRules.conf (auto-generated).
-- Add additional rules with apply_layer_rule({
apply_layer_rule({
  name = "system-layer-layerrule-006",
  match = {
    namespace = "wallpaper",
  },
  blur = true,
  ignore_alpha = 0,
})

apply_layer_rule({
  name = "system-layer-layerrule-007",
  match = {
    namespace = "swaync-notification-window",
  },
  blur = true,
  ignore_alpha = 0,
})

apply_layer_rule({
  name = "system-layer-layerrule-008",
  match = {
    namespace = "com.aurora.keybinds_help",
  },
  blur = true,
  ignore_alpha = 0,
})

apply_layer_rule({
  name = "system-layer-layerrule-009",
  match = {
    namespace = "logout_dialog",
  },
  blur = true,
  ignore_alpha = 0,
})
