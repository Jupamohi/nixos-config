-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- Virtual-1 native profile (recommended for the VM)
--
-- "preferred" resolves to the mode the virtio-gpu/SPICE display advertises
-- (1280x800@74.99Hz on this VM). Requesting a larger fixed mode such as
-- 1920x1080 does not get accepted by the DRM atomic commit on this device, so
-- the compositor keeps a larger swapchain than the scanout and the screen ends
-- up scaled, i.e. visibly pixelated. Use this profile for crisp output.

hl.monitor({
    output = "Virtual-1",
    mode = "preferred",
    position = "auto",
    scale = "1",
})
