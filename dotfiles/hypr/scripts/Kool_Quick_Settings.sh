#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Rofi menu for KooL Hyprland Quick Settings (SUPER SHIFT E)
# Updated for UserConfigs/configs separation

# Detect active Hyprland config mode (Lua entrypoint vs legacy .conf includes)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
hypr_dir="$config_home/hypr"
lua_entry="$hypr_dir/hyprland.lua"
legacy_lua_entry="$config_home/hyprland.lua"
if [[ -f "$lua_entry" || -f "$legacy_lua_entry" ]]; then
  hypr_config_mode="lua"
else
  hypr_config_mode="conf"
fi

# Resolve defaults file used to get terminal/editor values
config_file="$hypr_dir/UserConfigs/01-UserDefaults.conf"
lua_defaults_file="$hypr_dir/UserConfigs/user_defaults.lua"
lua_system_defaults_file="$hypr_dir/lua/user_defaults.lua"
user_env_lua="$hypr_dir/UserConfigs/user_env.lua"
system_env_lua="$hypr_dir/configs/system_env.lua"
term="${term:-${TERMINAL:-kitty}}"
edit="${edit:-${EDITOR:-}}"
visual="${visual:-${VISUAL:-}}"

if [[ "$hypr_config_mode" == "conf" && -f "$config_file" ]]; then
  tmp_config_file=$(mktemp)
  sed 's/^\$//g; s/ = /=/g' "$config_file" >"$tmp_config_file"
  source "$tmp_config_file"
  conf_editor=$(sed -n 's/^[[:space:]]*env[[:space:]]*=[[:space:]]*EDITOR[[:space:]]*,[[:space:]]*\([^#[:space:]]*\).*$/\1/p' "$config_file" | tail -n1)
  conf_visual=$(sed -n 's/^[[:space:]]*env[[:space:]]*=[[:space:]]*VISUAL[[:space:]]*,[[:space:]]*\([^#[:space:]]*\).*$/\1/p' "$config_file" | tail -n1)
  [[ -n "$conf_editor" ]] && edit="$conf_editor"
  [[ -n "$conf_visual" ]] && visual="$conf_visual"
elif [[ "$hypr_config_mode" == "lua" ]]; then
  # 1. Parse active overrides from user_defaults.lua
  if [[ -f "$lua_defaults_file" ]]; then
    lua_term=$(sed -n 's/^[[:space:]]*KOOLDOTS_DEFAULTS\.term[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$lua_defaults_file" | tail -n1)
    lua_edit=$(sed -n 's/^[[:space:]]*KOOLDOTS_DEFAULTS\.edit[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$lua_defaults_file" | tail -n1)
    lua_visual=$(sed -n 's/^[[:space:]]*KOOLDOTS_DEFAULTS\.visual[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$lua_defaults_file" | tail -n1)
    [[ -n "$lua_term" ]] && term="$lua_term"
    [[ -n "$lua_edit" ]] && edit="$lua_edit"
    [[ -n "$lua_visual" ]] && visual="$lua_visual"
  fi
  # 2. Parse env overrides from user_env.lua / system_env.lua
  for env_file in "$user_env_lua" "$system_env_lua"; do
    if [[ -f "$env_file" ]]; then
      env_edit=$(sed -n 's/^[[:space:]]*hl\.env([[:space:]]*["\x27]EDITOR["\x27][[:space:]]*,[[:space:]]*["\x27]\([^"\x27]*\)["\x27].*$/\1/p' "$env_file" | tail -n1)
      env_visual=$(sed -n 's/^[[:space:]]*hl\.env([[:space:]]*["\x27]VISUAL["\x27][[:space:]]*,[[:space:]]*["\x27]\([^"\x27]*\)["\x27].*$/\1/p' "$env_file" | tail -n1)
      [[ -n "$env_edit" ]] && edit="$env_edit"
      [[ -n "$env_visual" ]] && visual="$env_visual"
    fi
  done
  # 3. Fallback to 01-UserDefaults.conf if edit is still unset
  if [[ -z "${edit:-}" && -f "$config_file" ]]; then
    conf_editor=$(sed -n 's/^[[:space:]]*env[[:space:]]*=[[:space:]]*EDITOR[[:space:]]*,[[:space:]]*\([^#[:space:]]*\).*$/\1/p' "$config_file" | tail -n1)
    conf_visual=$(sed -n 's/^[[:space:]]*env[[:space:]]*=[[:space:]]*VISUAL[[:space:]]*,[[:space:]]*\([^#[:space:]]*\).*$/\1/p' "$config_file" | tail -n1)
    [[ -n "$conf_editor" ]] && edit="$conf_editor"
    [[ -n "$conf_visual" ]] && visual="$conf_visual"
  fi
  # 4. Fallback to system lua defaults
  if [[ -z "${lua_term:-}" && -f "$lua_system_defaults_file" ]]; then
    sys_term=$(sed -n 's/^[[:space:]]*KOOLDOTS_DEFAULTS\.term[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$lua_system_defaults_file" | tail -n1)
    [[ -n "$sys_term" ]] && term="$sys_term"
  fi
  if [[ -z "${edit:-}" && -f "$lua_system_defaults_file" ]]; then
    sys_edit=$(sed -n 's/^[[:space:]]*KOOLDOTS_DEFAULTS\.edit[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$lua_system_defaults_file" | tail -n1)
    [[ -n "$sys_edit" ]] && edit="$sys_edit"
  fi
fi

# Final fallback for editor
if [[ -z "${edit:-}" ]]; then
  if command -v nvim >/dev/null 2>&1; then
    edit="nvim"
  elif command -v vim >/dev/null 2>&1; then
    edit="vim"
  else
    edit="nano"
  fi
fi
# ##################################### #

# variables
configs="$hypr_dir/configs"
UserConfigs="$hypr_dir/UserConfigs"
rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/rofi/config-edit.rasi"
msg=' ⁉️ Choose what to do ⁉️'
iDIR="${XDG_CONFIG_HOME:-$HOME/.config}/swaync/images"
scriptsDir="$hypr_dir/scripts"
UserScripts="$hypr_dir/UserScripts"
user_defaults_conf="$UserConfigs/01-UserDefaults.conf"
user_defaults_lua="$UserConfigs/user_defaults.lua"
user_env_conf="$UserConfigs/ENVariables.conf"
user_env_lua="$UserConfigs/user_env.lua"
user_keybinds_conf="$UserConfigs/UserKeybinds.conf"
user_keybinds_lua="$UserConfigs/user_keybinds.lua"
user_startup_conf="$UserConfigs/Startup_Apps.conf"
user_startup_lua="$UserConfigs/user_startup.lua"
user_window_rules_conf="$UserConfigs/WindowRules.conf"
user_window_rules_lua="$UserConfigs/user_window_rules.lua"
user_layer_rules_conf="$UserConfigs/LayerRules.conf"
user_layer_rules_lua="$UserConfigs/user_layer_rules.lua"
user_settings_conf="$UserConfigs/UserSettings.conf"
user_settings_lua="$UserConfigs/user_settings.lua"
user_decorations_conf="$UserConfigs/UserDecorations.conf"
user_decorations_lua="$UserConfigs/user_decorations.lua"
user_animations_conf="$UserConfigs/UserAnimations.conf"
user_animations_lua="$UserConfigs/user_animations.lua"
user_laptops_conf="$UserConfigs/Laptops.conf"
user_laptops_lua="$UserConfigs/user_laptops.lua"
user_monitors_conf="$hypr_dir/monitors.conf"
user_monitors_lua="$UserConfigs/monitors.lua"

# Function to show info notification
show_info() {
  if [[ -f "$iDIR/info.png" ]]; then
    notify-send -i "$iDIR/info.png" "Info" "$1"
  else
    notify-send "Info" "$1"
  fi
}

get_context_monitor_name() {
  if ! command -v hyprctl >/dev/null 2>&1; then
    return 1
  fi
  local monitor=""
  if command -v jq >/dev/null 2>&1; then
    monitor="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty' | head -n1)"
    if [[ -z "$monitor" ]]; then
      monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' | head -n1)"
    fi
  else
    monitor="$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{name=$2} /focused: yes/{print name; exit}')"
  fi
  printf '%s' "$monitor"
}

# Determine whether an editor command is terminal-based (TUI)
is_tui_editor() {
  local -a cmd=("$@")
  local bin base arg
  [[ ${#cmd[@]} -eq 0 ]] && return 1

  bin="${cmd[0]}"
  base="$(basename "$bin")"

  case "$base" in
  vi | vim | nvim | nano | hx | helix | kak | micro | emacs-nox)
    return 0
    ;;
  emacs | emacsclient)
    for arg in "${cmd[@]:1}"; do
      case "$arg" in
      -nw | --no-window-system | -t | --tty)
        return 0
        ;;
      esac
    done
    return 1
    ;;
  esac

  return 1
}

resolve_system_lua_file() {
  local file_name="$1"
  local preferred="$configs/$file_name"
  local legacy="$UserConfigs/$file_name"
  if [[ -f "$preferred" || ! -f "$legacy" ]]; then
    printf '%s' "$preferred"
  else
    printf '%s' "$legacy"
  fi
}

resolve_system_keybinds_file() {
  local lua_keybinds="$hypr_dir/lua/keybinds.lua"
  local legacy_system_lua="$configs/system_keybinds.lua"
  local conf_file="$configs/Keybinds.conf"

  if [[ "$hypr_config_mode" == "lua" ]]; then
    if [[ -f "$lua_keybinds" || ! -f "$legacy_system_lua" ]]; then
      printf '%s' "$lua_keybinds"
    else
      printf '%s' "$legacy_system_lua"
    fi
  else
    if [[ -f "$conf_file" || ! -f "$lua_keybinds" ]]; then
      printf '%s' "$conf_file"
    else
      printf '%s' "$lua_keybinds"
    fi
  fi
}

resolve_mode_file() {
  local preferred="$1"
  local fallback="$2"
  if [[ -f "$preferred" || ! -f "$fallback" ]]; then
    printf '%s' "$preferred"
  else
    printf '%s' "$fallback"
  fi
}

resolve_user_overlay_file() {
  local lua_file="$1"
  local conf_file="$2"
  if [[ "$hypr_config_mode" == "lua" ]]; then
    resolve_mode_file "$lua_file" "$conf_file"
  else
    resolve_mode_file "$conf_file" "$lua_file"
  fi
}
rainbow_mode_file() {
  printf '%s' "$UserScripts/rainbow-borders.mode"
}

rainbow_write_mode() {
  local mode="$1"
  printf '%s\n' "$mode" >"$(rainbow_mode_file)"
}

rainbow_mode_file() {
 printf '%s' "$UserScripts/rainbow-borders.mode"
}

rainbow_write_mode() {
 local mode="$1"
 printf '%s\n' "$mode" >"$(rainbow_mode_file)"
}

rainbow_mode_file() {
 printf '%s' "$UserScripts/rainbow-borders.mode"
}

rainbow_write_mode() {
 local mode="$1"
 printf '%s\n' "$mode" >"$(rainbow_mode_file)"
}

rainbow_read_mode() {
 local mode_file="${UserScripts}/rainbow-borders.mode"

 if [[ -f "$mode_file" ]]; then
   tr -d '[:space:]' <"$mode_file"
   return
 fi

 if pgrep -f 'RainbowBorders-low-cpu\.sh' >/dev/null 2>&1; then
   printf '%s' "low_cpu"
   return
 fi

 printf '%s' "disabled"
}

stop_lowcpu_rainbow() {
 local lockfile="${RB_LOCKFILE:-/tmp/hypr-rainbowborders.lock}"
 local oldpid=""

 if [[ -f "$lockfile" ]]; then
   oldpid="$(cat "$lockfile" 2>/dev/null || true)"
   if [[ -n "${oldpid:-}" ]] && kill -0 "$oldpid" 2>/dev/null; then
     kill "$oldpid" >/dev/null 2>&1 || true
     sleep 0.1
     kill -0 "$oldpid" 2>/dev/null && kill -9 "$oldpid" >/dev/null 2>&1 || true
   fi
   rm -f "$lockfile" >/dev/null 2>&1 || true
 fi

 pkill -f 'RainbowBorders-low-cpu\.sh' >/dev/null 2>&1 || true
}

start_lowcpu_rainbow() {
 local lowcpu_script="$UserScripts/RainbowBorders-low-cpu.sh"

 if [[ ! -x "$lowcpu_script" ]]; then
   if [[ -f "$lowcpu_script" ]]; then
     chmod +x "$lowcpu_script" >/dev/null 2>&1 || true
   fi
 fi

 if [[ ! -x "$lowcpu_script" ]]; then
   show_info "RainbowBorders-low-cpu.sh not found in $UserScripts."
   return 1
 fi

 stop_lowcpu_rainbow
 "$lowcpu_script" >/dev/null 2>&1 &
 return 0
}

toggle_rainbow_borders() {
 local refresh_script="$scriptsDir/Refresh.sh"
 local status=""
 local current

 current="$(rainbow_read_mode)"

 if [[ "$current" == "disabled" ]]; then
   if start_lowcpu_rainbow; then
     rainbow_write_mode "low_cpu"
     status="enabled (low cpu)"
   else
     return
   fi
 else
   stop_lowcpu_rainbow
   rainbow_write_mode "disabled"
   status="disabled"

   if command -v hyprctl &>/dev/null; then
     hyprctl reload >/dev/null 2>&1 || true
   fi
 fi

 if [[ -x "$refresh_script" ]]; then
   "$refresh_script" >/dev/null 2>&1 &
 elif [[ "$status" == enabled* ]]; then
   start_lowcpu_rainbow >/dev/null 2>&1 || true
 fi

 if [[ -n "$status" ]]; then
   show_info "Rainbow Borders ${status}."
 fi
}

# Submenu to choose Rainbow Borders mode.
# Only the supported low-CPU implementation is available.
rainbow_borders_menu() {
 local lowcpu_script="$UserScripts/RainbowBorders-low-cpu.sh"
 local refresh_script="$scriptsDir/Refresh.sh"
 local current
 local current_display
 local options
 local choice

 current="$(rainbow_read_mode)"

 case "$current" in
 low_cpu) current_display="Low CPU Rainbow" ;;
 *) current_display="Disabled" ;;
 esac

 options="Disable Rainbow Borders\nLow CPU Rainbow"
 "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/RofiFocusedWallpaperLink.sh" >/dev/null 2>&1 || true
 choice=$(printf "%b" "$options" | rofi -i -dmenu -config "$rofi_theme" -mesg "Rainbow Borders: current = $current_display")

 [[ -z "$choice" ]] && return

 case "$choice" in
 "Disable Rainbow Borders")
   stop_lowcpu_rainbow
   rainbow_write_mode "disabled"
   current="disabled"

   if command -v hyprctl &>/dev/null; then
     hyprctl reload >/dev/null 2>&1 || true
   fi
   ;;
 "Low CPU Rainbow")
   if [[ ! -f "$lowcpu_script" ]]; then
     show_info "RainbowBorders-low-cpu.sh not found in $UserScripts."
     return
   fi

   if ! start_lowcpu_rainbow; then
     return
   fi

   rainbow_write_mode "low_cpu"
   current="low_cpu"
   ;;
 *)
   return
   ;;
 esac

 if [[ -x "$refresh_script" ]]; then
   "$refresh_script" >/dev/null 2>&1 &
 fi

 if [[ "$current" == "low_cpu" ]] &&
    ! pgrep -f 'RainbowBorders-low-cpu\.sh' >/dev/null 2>&1; then
   start_lowcpu_rainbow >/dev/null 2>&1 || true
 fi
}

handle_choice() {
  local choice="$1"
  local quick_settings_monitor="$2"
  local file=""

  case "$choice" in
  "Edit User Defaults")
    file="$(resolve_user_overlay_file "$user_defaults_lua" "$user_defaults_conf")"
    ;;
  "Edit User ENV variables" | "Set User ENV variables")
    file="$(resolve_user_overlay_file "$user_env_lua" "$user_env_conf")"
    ;;
  "Edit User Keybinds" | "Set User Keybinds")
    file="$(resolve_user_overlay_file "$user_keybinds_lua" "$user_keybinds_conf")"
    ;;
  "Edit User Startup Apps (overlay)")
    file="$(resolve_user_overlay_file "$user_startup_lua" "$user_startup_conf")"
    ;;
  "Edit User Window Rules (overlay)")
    file="$(resolve_user_overlay_file "$user_window_rules_lua" "$user_window_rules_conf")"
    ;;
  "Edit User Layer Rules (overlay)")
    file="$(resolve_user_overlay_file "$user_layer_rules_lua" "$user_layer_rules_conf")"
    ;;
  "Edit User Settings")
    file="$(resolve_user_overlay_file "$user_settings_lua" "$user_settings_conf")"
    ;;
  "Edit User Decorations" | "Set User Decorations")
    file="$(resolve_user_overlay_file "$user_decorations_lua" "$user_decorations_conf")"
    ;;
  "Edit User Animations")
    file="$(resolve_user_overlay_file "$user_animations_lua" "$user_animations_conf")"
    ;;
  "Edit User Laptop Settings")
    file="$(resolve_user_overlay_file "$user_laptops_lua" "$user_laptops_conf")"
    ;;
  "Edit System Default Keybinds")
    file="$(resolve_system_keybinds_file)"
    ;;
  "Edit System Default Startup Apps")
    if [[ "$hypr_config_mode" == "lua" ]]; then file="$(resolve_system_lua_file system_startup.lua)"; else file="$configs/Startup_Apps.conf"; fi
    ;;
  "Edit System Default Window Rules")
    if [[ "$hypr_config_mode" == "lua" ]]; then file="$(resolve_system_lua_file system_window_rules.lua)"; else file="$configs/WindowRules.conf"; fi
    ;;
  "Edit System Default Layer Rules")
    if [[ "$hypr_config_mode" == "lua" ]]; then file="$(resolve_system_lua_file system_layer_rules.lua)"; else file="$configs/LayerRules.conf"; fi
    ;;
  "Edit System Default Settings")
    if [[ "$hypr_config_mode" == "lua" ]]; then file="$(resolve_system_lua_file system_settings.lua)"; else file="$configs/SystemSettings.conf"; fi
    ;;
  "Change Starship Prompt") "$scriptsDir/ChangeStarshipPrompt.sh" ;;
  "Set SDDM Wallpaper")
    if [[ -n "$quick_settings_monitor" ]]; then
      "$scriptsDir/sddm_wallpaper.sh" --normal "$quick_settings_monitor"
    else
      "$scriptsDir/sddm_wallpaper.sh" --normal
    fi
    ;;
  "Choose Kitty Terminal Theme") "$scriptsDir/Kitty_themes.sh" ;;
  "Choose Ghostty Terminal Theme") "$scriptsDir/Ghostty_themes.sh" ;;
  "Edit User Monitor config")
    file="$(resolve_user_overlay_file "$user_monitors_lua" "$user_monitors_conf")"
    ;;
  "Configure Workspace Rules (nwg-displays)")
    if ! command -v nwg-displays &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
      return
    fi
    nwg-displays
    ;;
  "GTK Settings (nwg-look)")
    if ! command -v nwg-look &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-look first"
      return
    fi
    nwg-look
    ;;
  "QT Apps Settings (qt6ct)")
    if ! command -v qt6ct &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt6ct first"
      return
    fi
    qt6ct
    ;;
  "QT Apps Settings (qt5ct)")
    if ! command -v qt5ct &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt5ct first"
      return
    fi
    qt5ct
    ;;
  "Set Hyprlock Wallpaper" | "Set Hyprlock paper")
    if [[ -n "$quick_settings_monitor" ]]; then
      "$scriptsDir/HyprlockWallpaperSelect.sh" "$quick_settings_monitor"
    else
      "$scriptsDir/HyprlockWallpaperSelect.sh"
    fi
    ;;
  "Choose Hyprland Animations") "$scriptsDir/Animations.sh" ;;
  "Choose Monitor Profiles") "$scriptsDir/MonitorProfiles.sh" ;;
  "Choose Rofi Themes") "$scriptsDir/RofiThemeSelector.sh" ;;
  "Search for Keybinds") "$scriptsDir/KeyBinds.sh" ;;
  "Toggle Waybar Weather units"* | "Toggle Waybar Weather units (C/F)") "$scriptsDir/Toggle-weather-waybar-units.sh" ;;
  "Toggle Waybar Clock (12H/24H)") "$scriptsDir/ToggleWaybarTime.sh" ;;
  "Toggle Game Mode") "$scriptsDir/GameMode.sh" ;;
  "Switch Dark-Light Theme") "$scriptsDir/DarkLight.sh" ;;
  "Rainbow Borders Mode") rainbow_borders_menu ;;
  *) return ;;
  esac

  if [ -n "$file" ]; then
    local -a edit_cmd term_cmd visual_cmd selected_cmd
    read -r -a edit_cmd <<<"$edit"
    read -r -a term_cmd <<<"$term"
    [[ -n "$visual" ]] && read -r -a visual_cmd <<<"$visual"
    selected_cmd=("${edit_cmd[@]}")
    [[ ${#visual_cmd[@]} -gt 0 ]] && selected_cmd=("${visual_cmd[@]}")

    if is_tui_editor "${selected_cmd[@]}"; then
      if [[ -x "$scriptsDir/LaunchTerminal.sh" ]]; then
        "$scriptsDir/LaunchTerminal.sh" "$term" "${selected_cmd[*]} '$file'" >/dev/null 2>&1 &
      elif command -v kitty >/dev/null 2>&1; then
        kitty "${selected_cmd[@]}" "$file" >/dev/null 2>&1 &
      elif command -v ghostty >/dev/null 2>&1; then
        ghostty -e "${selected_cmd[@]}" "$file" >/dev/null 2>&1 &
      elif command -v alacritty >/dev/null 2>&1; then
        alacritty -e "${selected_cmd[@]}" "$file" >/dev/null 2>&1 &
      elif command -v "${term_cmd[0]}" >/dev/null 2>&1; then
        "${term_cmd[@]}" -e "${selected_cmd[@]}" "$file" >/dev/null 2>&1 &
      fi
    else
      "${selected_cmd[@]}" "$file" >/dev/null 2>&1 &
    fi
  fi
}

get_weather_units_label() {
  local unit="metric"
  local env_lua="$UserConfigs/user_env.lua"
  local env_conf="$UserConfigs/ENVariables.conf"
  local waybar_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/waybar-weather/config.toml"

  if [[ -f "$env_lua" ]] && grep -qE '^[[:space:]]*hl\.env\([[:space:]]*["'\'']WEATHER_UNITS["'\'']' "$env_lua"; then
    local val
    val=$(sed -nE 's/^[[:space:]]*hl\.env\([[:space:]]*["'\'']WEATHER_UNITS["'\''][[:space:]]*,[[:space:]]*["'\'']([^"'\'']+)["'\''].*/\1/p' "$env_lua" | tail -n1)
    [[ -n "$val" ]] && unit="$val"
  elif [[ -f "$env_conf" ]] && grep -qE '^[[:space:]]*env[[:space:]]*=[[:space:]]*WEATHER_UNITS' "$env_conf"; then
    local val
    val=$(sed -nE 's/^[[:space:]]*env[[:space:]]*=[[:space:]]*WEATHER_UNITS[[:space:]]*,[[:space:]]*([^#[:space:]]+).*/\1/p' "$env_conf" | tail -n1)
    [[ -n "$val" ]] && unit="$val"
  elif [[ -f "$waybar_cfg" ]] && grep -qE '^[[:space:]]*units[[:space:]]*=' "$waybar_cfg"; then
    local val
    val=$(sed -nE 's/^[[:space:]]*units[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$waybar_cfg" | tail -n1)
    [[ -n "$val" ]] && unit="$val"
  elif [[ -n "${WEATHER_UNITS:-}" ]]; then
    unit="$WEATHER_UNITS"
  fi

  unit=$(echo "$unit" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  if [[ "$unit" == "imperial" || "$unit" == "fahrenheit" || "$unit" == "f" ]]; then
    echo "Imperial (°F)"
  else
    echo "Metric (°C)"
  fi
}

show_category_menu() {
  local category="$1"
  local quick_settings_monitor="$2"
  local options=""

  case "$category" in
  "[[ User Settings ]]")
    options=$(
      cat <<EOF
Edit User Defaults
Edit User Keybinds
Edit User ENV variables
Edit User Startup Apps (overlay)
Edit User Window Rules (overlay)
Edit User Layer Rules (overlay)
Edit User Settings
Edit User Decorations
Edit User Animations
Edit User Laptop Settings
Edit User Monitor config
EOF
    )
    ;;
  "[[ System Settings ]]")
    options=$(
      cat <<EOF
Edit System Default Keybinds
Edit System Default Startup Apps
Edit System Default Window Rules
Edit System Default Layer Rules
Edit System Default Settings
EOF
    )
    ;;
  "[[ Toggle Options ]]")
    local weather_label
    weather_label="$(get_weather_units_label)"
    options=$(
      cat <<EOF
Toggle Waybar Weather units [Current: $weather_label]
Toggle Waybar Clock (12H/24H)
Toggle Game Mode
EOF
    )
    ;;
  "[[ Misc ]]")
    options=$(
      cat <<EOF
Change Starship Prompt
Set SDDM Wallpaper
Choose Kitty Terminal Theme
Choose Ghostty Terminal Theme
Configure Workspace Rules (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Set Hyprlock Wallpaper
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Switch Dark-Light Theme
Rainbow Borders Mode
EOF
    )
    ;;
  *)
    return
    ;;
  esac

  local sub_choice=""
  "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/RofiFocusedWallpaperLink.sh" >/dev/null 2>&1 || true
  sub_choice=$(
    {
      printf "%s\n" "$options"
      printf "\n"
      printf "[ SUPER+SHIFT+E to return to main menu ]\n"
    } | rofi -i -dmenu -config "$rofi_theme" \
      -mesg "$category" \
      -theme-str 'listview { lines: 8; }'
  )
  [[ -z "$sub_choice" ]] && return
  [[ "$sub_choice" == "[ SUPER+SHIFT+E to return to main menu ]" ]] && return
  handle_choice "$sub_choice" "$quick_settings_monitor"
}

show_main_menu() {
  local weather_label
  weather_label="$(get_weather_units_label)"
  printf '%s\n' "[ Settings ]"
  printf '%b\n' "[[ User Settings ]]\x00meta\x1fEdit User Defaults Edit User Keybinds Edit User ENV variables Edit User Startup Apps overlay Edit User Window Rules overlay Edit User Layer Rules overlay Edit User Settings Edit User Decorations Edit User Animations Edit User Laptop Settings Edit User Monitor config"
  printf '%b\n' "[[ System Settings ]]\x00meta\x1fEdit System Default Keybinds Edit System Default Startup Apps Edit System Default Window Rules Edit System Default Layer Rules Edit System Default Settings"
  printf '%b\n' "[[ Toggle Options ]]\x00meta\x1fToggle Waybar Weather units C F Toggle Waybar Clock 12H 24H Toggle Game Mode"
  printf '%b\n' "[[ Misc ]]\x00meta\x1fChange Starship Prompt Set SDDM Wallpaper Choose Kitty Terminal Theme Choose Ghostty Terminal Theme Configure Workspace Rules nwg-displays GTK Settings nwg-look QT Apps Settings qt6ct QT Apps Settings qt5ct Set Hyprlock Wallpaper Choose Hyprland Animations Choose Monitor Profiles Choose Rofi Themes Search for Keybinds Switch Dark-Light Theme Rainbow Borders Mode"
  printf '%s\n' "[ Quick Links]"
  printf '%s\n' "Set User Keybinds"
  printf '%s\n' "Set User Decorations"
  printf '%s\n' "Set Hyprlock paper"
  printf '%s\n' "Set User ENV variables"
  printf '%s\n' "Edit User Defaults"
  printf '%s\n' "Edit User Keybinds"
  printf '%s\n' "Edit User ENV variables"
  printf '%s\n' "Edit User Startup Apps (overlay)"
  printf '%s\n' "Edit User Window Rules (overlay)"
  printf '%s\n' "Edit User Layer Rules (overlay)"
  printf '%s\n' "Edit User Settings"
  printf '%s\n' "Edit User Decorations"
  printf '%s\n' "Edit User Animations"
  printf '%s\n' "Edit User Laptop Settings"
  printf '%s\n' "Edit User Monitor config"
    printf '%s\n' "Edit System Default Keybinds"
  printf '%s\n' "Edit System Default Startup Apps"
  printf '%s\n' "Edit System Default Window Rules"
  printf '%s\n' "Edit System Default Layer Rules"
  printf '%s\n' "Edit System Default Settings"
  printf '%s\n' "Toggle Waybar Weather units [Current: $weather_label]"
  printf '%s\n' "Toggle Waybar Clock (12H/24H)"
  printf '%s\n' "Toggle Game Mode"
  printf '%s\n' "Change Starship Prompt"
  printf '%s\n' "Set SDDM Wallpaper"
  printf '%s\n' "Choose Kitty Terminal Theme"
  printf '%s\n' "Choose Ghostty Terminal Theme"
  printf '%s\n' "Configure Workspace Rules (nwg-displays)"
  printf '%s\n' "GTK Settings (nwg-look)"
  printf '%s\n' "QT Apps Settings (qt6ct)"
  printf '%s\n' "QT Apps Settings (qt5ct)"
  printf '%s\n' "Set Hyprlock Wallpaper"
  printf '%s\n' "Choose Hyprland Animations"
  printf '%s\n' "Choose Monitor Profiles"
  printf '%s\n' "Choose Rofi Themes"
  printf '%s\n' "Search for Keybinds"
  printf '%s\n' "Switch Dark-Light Theme"
  printf '%s\n' "Rainbow Borders Mode"
}

main() {
  local quick_settings_monitor choice
  quick_settings_monitor="$(get_context_monitor_name)"
  "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/RofiFocusedWallpaperLink.sh" >/dev/null 2>&1 || true

  choice=$(
    show_main_menu | rofi -i -dmenu -config "$rofi_theme" \
      -mesg "Left: Categories • Right: Quick Links" \
      -theme-str 'listview { columns: 2; lines: 5; }'
  )

  case "$choice" in
  "[[ User Settings ]]" | "[[ System Settings ]]" | "[[ Toggle Options ]]" | "[[ Misc ]]")
    show_category_menu "$choice" "$quick_settings_monitor"
    ;;
  "[ Settings ]" | "[[ Quick Links]]")
    return
    ;;
  "Set User Keybinds" | "Set User Decorations" | "Set Hyprlock paper" | "Set User ENV variables")
    handle_choice "$choice" "$quick_settings_monitor"
    ;;
  *)
    handle_choice "$choice" "$quick_settings_monitor"
    ;;
  esac
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main
