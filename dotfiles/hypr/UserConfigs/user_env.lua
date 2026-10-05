-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- User environment overrides template.
-- Keep this file for personal env additions that should survive updates.

-- Examples:
-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- hl.env("GDK_SCALE", "1")
-- hl.env("QT_SCALE_FACTOR", "1")
hl.env("WEATHER_UNITS", "metric")
hl.env("HYPRCURSOR_THEME", "macOS-hypr")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Hyprland arranca con un PATH minimo y no incluye ~/.local/bin ni ~/.cargo/bin,
-- por lo que los keybinds que lanzan apps instaladas ahi (zen, etc.) fallan en
-- silencio. Anadimos esos directorios al PATH de Hyprland.
do
  local current_path = os.getenv("PATH") or ""
  local home = os.getenv("HOME") or ""
  local extra = {}
  if home ~= "" then
    for _, dir in ipairs({ home .. "/.local/bin", home .. "/.cargo/bin" }) do
      local already = false
      for part in current_path:gmatch("[^:]+") do
        if part == dir then already = true break end
      end
      if not already then
        extra[#extra + 1] = dir
      end
    end
  end
  if #extra > 0 then
    hl.env("PATH", current_path .. ":" .. table.concat(extra, ":"))
  end
end
