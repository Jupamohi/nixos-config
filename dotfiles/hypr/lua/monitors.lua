-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- Converted from config/hypr/monitors.conf (active monitor entries only).

-- NOTE: the upstream conversion left three rules with an EMPTY `output = ""`
-- ("preferred"/"highrr"/"highres"). In Hyprland an empty output name is a
-- catch-all that matches every monitor and, since it is registered first, it
-- wins over the explicit rule below. "preferred" resolves to the DRM preferred
-- mode of the output, so the explicit mode was silently discarded and any
-- mode/scale change appeared to do nothing (hyprctl would report "ok" while
-- the output stayed put, which also makes the display scale from a mismatched
-- framebuffer and look pixelated). They are removed deliberately: name every
-- output explicitly instead.

hl.monitor({
    output = "Virtual-1",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

-- Load user monitor overrides from UserConfigs when present.
do
    local configHome = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
    local userMonitors = configHome .. "/hypr/UserConfigs/monitors.lua"
    local ok, err = pcall(dofile, userMonitors)
    if not ok and err and tostring(err):find("No such file or directory", 1, true) == nil then
        print("[WARN] Unable to load user monitor overrides from " .. userMonitors .. ": " .. tostring(err))
    end
end
