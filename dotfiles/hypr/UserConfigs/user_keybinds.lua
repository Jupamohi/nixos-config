-- User keybind overrides.
-- Add, override, or rebind keybinds here.
--
-- =============================================================================
-- KEYBIND RULES & SYNTAX
-- =============================================================================
-- • bind("MODS", "KEY", action, [options])
-- • unbind("MODS", "KEY")
--
-- Supported modifiers:
--   "SUPER", "SHIFT", "CTRL", "ALT", or combinations like "SUPER SHIFT", "SUPER ALT"
--
-- Actions:
--   • exec_cmd("command")       -> launches a terminal command or script
--   • dispatch("dispatcher", [arg]) -> triggers a Hyprland dispatcher (e.g. killactive, togglefloating)
--
-- =============================================================================
-- EXAMPLES
-- =============================================================================
--
-- NOTE ON LUA REBINDS:
--   Yes — same rule as Hyprlang applies in practice: if a key combo is already bound,
--   unbind("MODS", "KEY") first, then bind(...) it to the new action.
--   This keeps behavior explicit and avoids duplicate/conflicting binds.
--
-- 1. ADDING A BRAND NEW KEYBIND (combo not used by default):
--    bind("SUPER", "Z", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--    bind("SUPER SHIFT", "V", exec_cmd("pavucontrol"), { description = "Audio Control" })
--    bind("SUPER", "X", dispatch("killactive"), { description = "Close active window" })
--
-- 2. OVERRIDING AN EXISTING COMBO WITH A DIFFERENT APP/COMMAND:
--    -- To replace what SUPER+Return opens (default: kitty):
--    unbind("SUPER", "Return")
--    bind("SUPER", "Return", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--
-- 3. REBINDING / MOVING AN ACTION TO A NEW KEY COMBINATION:
--    -- Example: Move File Manager from SUPER+E to SUPER+F, and use SUPER+E for Emacs:
--    unbind("SUPER", "E")       -- unbind default file manager from SUPER+E
--    unbind("SUPER", "F")       -- unbind whatever SUPER+F was doing (default: fake fullscreen)
--    bind("SUPER", "F", exec_cmd("$HOME/.config/hypr/scripts/LaunchFileManager.sh '$files' '$term'"), { description = "File manager" })
--    bind("SUPER", "E", exec_cmd("emacsclient -c -a 'emacs'"), { description = "Launch Emacs" })
--
-- 4. REBINDING COMPOSITOR DISPATCHERS (e.g. workspace, fullscreen, floating):
--    unbind("SUPER", "Q")
--    bind("SUPER", "Q", dispatch("killactive"), { description = "Close active window" })
--    unbind("SUPER", "F") -- default fakefullscreen
--    bind("SUPER SHIFT", "F", dispatch("fullscreen", "0"), { description = "Toggle fullscreen" })
--    bind("SUPER ALT", "W", dispatch("workspace", "special:scratchpad"), { description = "Toggle scratchpad" })
--
-- 5. BIND OPTIONS (locked, repeating):
--    -- locked = true     -> runs even when lockscreen is active (e.g. media keys)
--    -- repeating = true  -> repeats when key is held down (e.g. volume / brightness)
--    bind("CTRL ALT", "bracketright", exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"), { description = "Brightness up", repeating = true })
--    bind("", "XF86AudioMute", exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"), { description = "Mute audio", locked = true })
--
-- =============================================================================
local user_keybinds_helper = nil
do
  local source = (debug.getinfo(1, "S") or {}).source or ""
  local source_path = source:match("^@(.+)$")
  local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
  local home = os.getenv("HOME") or ""
  local candidate_paths = {
    source_dir and (source_dir .. "/../lua/user_keybinds_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/lua/user_keybinds_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/user_keybinds_helper.lua") or nil,
  }

  local tried_paths = {}
  for _, helper_path in ipairs(candidate_paths) do
    if helper_path then
      table.insert(tried_paths, helper_path)
      local f = io.open(helper_path, "r")
      if f then
        f:close()
        local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
        if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.bind then
          user_keybinds_helper = loaded_helpers
          break
        end
      end
    end
  end

  if not user_keybinds_helper then
    error("Failed to load user_keybinds_helper.lua from: " .. table.concat(tried_paths, ", "))
  end
end


local exec_cmd = user_keybinds_helper.exec_cmd
local dispatch = user_keybinds_helper.dispatch
local bind = user_keybinds_helper.bind
local unbind = user_keybinds_helper.unbind


-- ============================ Aqui pondré mis Keybinds ===============================

bind("SUPER", "M", exec_cmd("/snap/bin/mysql-workbench-community"), { description = "Launch MySQL Workbench" })   
bind("SUPER", "O", exec_cmd("flatpak run md.obsidian.Obsidian"), { description = "Launch Obsidian" })

-- Zen enruta SOLO estas URLs exactas (matchType "equal-to") a su Space mediante
-- Space Routing (zen-space-routing.jsonlz4), y aplica el container del Space.
-- El parametro ?zenws=personal / ?zenws=universidad es la marca que hace que la
-- URL del keybind coincida con la ruta; navegar a mano (claude.ai, claude.ai/chats,
-- etc.) NO coincide y se queda en el space que estes usando.
-- Si anades o cambias una URL aqui, actualiza tambien la ruta en Space Routing
-- (en Zen: los 3 puntos del nombre del space -> "Space Routing Settings").
bind("SUPER ALT", "W", exec_cmd("$HOME/.local/bin/zen 'https://web.whatsapp.com/?zenws=personal'"), { description = "Open WhatsApp (Personal)" })
bind("SUPER ALT", "M", exec_cmd("$HOME/.local/bin/zen 'https://mail.google.com/?zenws=personal'"), { description = "Open Gmail (Personal)" })
bind("SUPER", "G", exec_cmd("$HOME/.local/bin/zen 'https://github.com/?zenws=personal'"), { description = "Open GitHub (Personal)" })
bind("SUPER", "A", exec_cmd("$HOME/.local/bin/zen 'https://claude.ai/?zenws=personal'"), { description = "Open Claude (Personal)" })

-- URL Universidad
bind("SUPER ALT", "T", exec_cmd("$HOME/.local/bin/zen 'https://teams.microsoft.com/?zenws=universidad'"), { description = "Open Teams (Universidad)" })
bind("SUPER ALT", "D", exec_cmd("$HOME/.local/bin/zen 'https://onedrive.live.com/?zenws=universidad'"), { description = "Open OneDrive (Universidad)" })
bind("SUPER ALT", "I", exec_cmd("$HOME/.local/bin/zen 'https://outlook.office.com/?zenws=universidad'"), { description = "Open Outlook (Universidad)" })    

unbind("SUPER", "C")
bind("SUPER", "C", exec_cmd("code"), { description = "Launch VS Code" })

-- Navegación vim-like global en campos de texto
local function send_key(key, mods)
    return hl.dsp.send_shortcut({ mods = mods or "", key = key })
end

-- Movimiento por caracteres
hl.bind("ALT + H", send_key("LEFT"),   { repeating = true })
hl.bind("ALT + J", send_key("DOWN"),   { repeating = true })
hl.bind("ALT + K", send_key("UP"),     { repeating = true })
hl.bind("ALT + L", send_key("RIGHT"),  { repeating = true })

-- Movimiento por palabras (Ctrl+← / Ctrl+→ es el estándar en la mayoría de apps)
hl.bind("ALT + W", send_key("RIGHT", "CTRL"), { repeating = true })
hl.bind("ALT + B", send_key("LEFT",  "CTRL"), { repeating = true })

-- Backspace
hl.bind("ALT + X", send_key("BACKSPACE"), { repeating = true })   


