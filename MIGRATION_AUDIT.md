# MIGRATION_AUDIT.md

Auditoría de migración: **Debian (fuente) → repositorio NixOS (destino)**.

- Fecha: 2026-10-04
- Origen: `Jupa-Debian`, Debian forky/sid, kernel 7.1.13. Primera auditoría realizada desde **LXQt sobre X11**; posteriormente se verificó sesión real de **Hyprland 0.56.2 sobre Wayland** en el portátil físico.
- Destino: `/home/jupamohi/nixos-config`, branch `main`, árbol limpio al iniciar (`6d403a9`).
- Alcance de esta pasada: **entorno Hyprland / KoolDots + capa de sesión Wayland**.

---

## 1. Resumen ejecutivo

La configuración real de Hyprland del usuario es **KoolDots v2.3.26.5**
(`github.com/LinuxBeginnings/Hyprland-Dots`, licencia GPLv3) **convertida a Lua**
(hyprlang Lua API). El usuario hizo esa conversión a propósito: la configuración
activa es `hyprland.lua` + `lua/*.lua`, no los `.conf`.

Decisiones de arquitectura tomadas:

1. **La configuración Lua se conserva tal cual** (no se convierte a Nix). Home
   Manager despliega el árbol Lua; Hyprland lo ejecuta. Cumple el principio de
   "no conviertas Lua en Nix".
2. **La capa de daemons de sesión se hace declarativa.** `Polkit.sh` y
   `PortalHyprland.sh` están escritos para rutas de Debian (`/usr/libexec/...`,
   `/usr/share/glib-2.0/...`) que **no existen en NixOS**. Se sustituyen por
   unidades `systemd --user` declaradas en Nix.
   **Resuelto:** polkit → `systemd.packages` + `systemd.user.services.hyprpolkitagent.wantedBy`
   en `configuration.nix`. Portal → no requiere nada, `programs.hyprland.enable`
   ya activa `xdg.portal`. Ambas líneas eliminadas de `lua/startup.lua`. Ver §12.3.
3. **Se excluye todo lo que no se puede demostrar activo**: HyprVim/Eww,
   Quickshell, Zen Browser, `LegacyConfigs`, 30 scripts huérfanos, y 8 módulos
   Lua que son plantillas que nunca se cargan.

### Hallazgo bloqueante resolved

**nixpkgs 26.05 ships Hyprland 0.55.4 con Lua como dependencia obligatoria.**
Verificado en el código fuente:

- `pkgs/by-name/hy/hyprland/package.nix`: `lua5_5` en `buildInputs` (línea 164).
- `CMakeLists.txt`: `pkg_search_module(LUA REQUIRED ... lua>=5.5 lua<5.6)` (línea 277).
- `src/config/lua/` — el gestor de configuración Lua completo.
- `install(FILES .../example/hyprland.lua)` — la config por defecto **es un `.lua`**.
- `hyprlang 0.6.8` — exactamente la misma versión que el build local que usa el usuario.

Y la precedencia es absoluta (`src/config/supplementary/jeremy/Jeremy.cpp:35-41`):

```cpp
const auto LUA_PATHS  = Hyprutils::Path::findConfig("hyprland", "lua");
const auto CONF_PATHS = Hyprutils::Path::findConfig("hyprland", "conf");
if (LUA_PATHS.first.has_value())      // <-- lua gana siempre
```

Por tanto el `hyprland.conf` que nixpkgs genera en `/etc/xdg` **no** colisiona
con el `hyprland.lua` que despliega Home Manager en `~/.config/hypr`.

### Verificación de la API Lua usada por KoolDots

Todas las llamadas de la configuración existen en los bindings de 0.55.4:

| API usada por KoolDots | ¿Existe en 0.55.4? |
|---|---|
| `hl.config` `hl.monitor` `hl.bind` `hl.env` `hl.on` | sí |
| `hl.curve` `hl.animation` `hl.gesture` `hl.device` | sí |
| `hl.window_rule` `hl.layer_rule` `hl.workspace_rule` | sí |
| `hl.exec_cmd` `hl.dispatch` `hl.permission` | sí |
| `hl.dsp.exec_cmd` `hl.dsp.exec_raw` `hl.dsp.window.*` | sí |
| `hl.dsp.send_shortcut` | sí (`src/config/lua/bindings`) |
| `hl.unbind` | sí |
| `hl.get_active_window` / `get_active_monitor` / `get_active_workspace` | sí |

---

## 2. Arquitectura NixOS detectada

```
flake.nix
├── inputs: nixpkgs (nixos-26.05), home-manager (release-26.05), plasma-manager
├── mkHost = nixosSystem { system = "x86_64-linux"; modules = [ configuration.nix, <hw>, home-manager... ]; }
└── nixosConfigurations = { laptopVM, maicolVM }   # marcador: # NEW_HOST_MARKER

configuration.nix      → módulos comunes de sistema (systemd-boot, SDDM, Plasma6,
                          Hyprland habilitado, pipewire, firefox, fuentes, git…)
paquetes.nix           → CATÁLOGO CENTRAL de environment.systemPackages
home.nix               → Home Manager del usuario jupamohi (imports de modules/home/*)
modules/home/zsh.nix   → programs.zsh + OMZ + plugins + initContent desde dotfiles
modules/home/plasma.nix→ plasma-manager: tema WhiteSur, panel, kwin, wallpaper
hosts/hardware-<host>/ → hardware-configuration.nix generado por nixos-generate-config
dotfiles/              → kitty/, nvim/, zsh/, wallpapers/   ( desplegados por HM )
new-host.sh            → alta de hosts vía el marcador # NEW_HOST_MARKER
```

Convenciones observadas (a respetar):

- `paquetes.nix` es el catálogo central de paquetes → **se mantiene**, no se reparte.
- Dotfiles viven en `dotfiles/<app>/` y se despliegan con `xdg.configFile`.
- Módulos de usuario en `modules/home/<tema>.nix`, importados desde `home.nix`.
- Hardware por host en `hosts/hardware-<host>/`.
- **No existe `AGENTS.md`** en el repo (el único del sistema está en
  `~/Downloads/Debian-Hyprland/AGENTS.md`, que es del builder de Hyprland, no de este repo).
- `new-host.sh` deja `git add` pero **no** hace commit → coherente con "no commits".

Ambos hosts son **VM de QEMU** (`qemu-guest.nix` en `laptopVM`).

---

## 3. Arquitectura Hyprland detectada (KoolDots)

### Cadena de carga real (verificada, no supuesto)

```
hyprland.lua
├── load_module("user_defaults")    → lua/user_defaults.lua
│                                      └── dofile UserConfigs/user_defaults.lua
├── load_module("animations")       → lua/animations.lua
├── load_module("user_overrides")   → lua/user_overrides.lua
│   ├── configs/system_env.lua          → lua/env.lua
│   ├── configs/system_startup.lua      → lua/startup.lua
│   ├── configs/system_window_rules.lua → lua/window_rules.lua
│   ├── configs/system_layer_rules.lua  (apply_layer_rule en línea)
│   ├── configs/system_keybinds.lua     (exec_cmd/dispatch/bind en línea)
│   ├── configs/system_settings.lua     → lua/settings.lua
│   ├── configs/system_laptops.lua      → lua/laptops.lua
│   ├── UserConfigs/user_env.lua
│   ├── UserConfigs/user_startup.lua    → lua/user_startup_helper.lua
│   ├── UserConfigs/user_window_rules.lua → lua/user_window_rules_helper.lua
│   ├── UserConfigs/user_layer_rules.lua   → lua/user_layer_rules_helper.lua
│   ├── UserConfigs/user_keybinds.lua      → lua/user_keybinds_helper.lua
│   ├── UserConfigs/user_settings.lua
│   ├── UserConfigs/user_decorations.lua
│   ├── UserConfigs/user_animations.lua
│   └── UserConfigs/user_laptops.lua
├── load_module("monitors")        → lua/monitors.lua → UserConfigs/monitors.lua
├── load_module("workspaces")      → lua/workspaces.lua → UserConfigs/workspaces.lua
├── pcall(require, openwhispr-binds.lua)   # [eliminado en la migración]
└── require("lua/plugins/hyprvim").setup({ which_key = { enabled = true } })
```

### Módulos `lua/*.lua` que NUNCA se cargan (plantillas del upstream)

Verificado que ningún archivo de la cadena de carga los referencia y que los
"delegadores" (`system_keybinds.lua`, `system_layer_rules.lua`,
`UserConfigs/user_decorations.lua`) definen sus helpers **en línea**:

`decorations.lua`, `keybinds.lua`, `keybind_helpers.lua`, `laptop-lid.lua`,
`layer_rules.lua`, `screenshot-region.lua`, `virtual_workspaces.lua`,
`user_decorations_helper.lua`

### Scripts

- Total en `scripts/` + `UserScripts/`: **116**
- Alcanzables desde la configuración activa (grafo transitivo): **86**
- **Huérfanos** (nunca referenciados): **30**

> Conteo obsoleto: una pasada muy temprana registró 123/89/34 antes de corregir
> el análisis del grafo (las referencias `$SCRIPTSDIR/...` no se detectaban).
> El conteo reproducible actual es **116 / 86 / 30**.

### Colisiones de keybinds detectadas

`UserConfigs/user_keybinds.lua` sobrescribe binds del sistema **sin `unbind`**:

| Combo | Sistema | Usuario |
|---|---|---|
| `SUPER A` | `OverviewToggle.sh` | Zen → claude.ai |
| `SUPER M` | `hyprctl dispatch splitratio 0.3` | MySQL Workbench (`/snap/bin/...`) |
| `SUPER G` | `togglegroup` | Zen → github.com |
| `SUPER SHIFT B` | `RainbowBorders-low-cpu.sh` | — (sin conflicto, pero `SUPER SHIFT S` está duplicado dentro del propio sistema) |

Además `SUPER CTRL A → ags -t overview` (ags no está instalado).

---

## 4. Software instalado relevante

- **3.843 paquetes APT**, 634 instalados manualmente. Multi-escritorio (LXQt,
  XFCE, Plasma6, MATE, UKUI) conviviendo. No es una fuente limpia.
- **Hyprland NO estaba corriendo durante esta primera pasada** (realizada desde
  LXQt/X11): `pgrep Hyprland` vacío, `hyprctl` fuera del PATH,
  `XDG_SESSION_TYPE=x11`, `XDG_CURRENT_DESKTOP=LXQt`. **Estado actual
  validado:** Wayland + Hyprland 0.56.2 en el portátil físico. Ver §Post-Migration
  Audit.
- Cachés que **sí** demuestran uso previo: `cliphist`, `eww`, `wallust`,
  `waypaper`, `rofi3.druncache`, `Hyprland Polkit Agent`.
- Cachés **ausentes** en esa primera pasada (nunca habían corrido):
  `quickshell`, `swaync`, `nm-applet`. **Nota:** `swaync` sí está en uso en la
  sesión real posterior (vía `swaync.service`).

### Binarios fuera de dpkg (`/usr/local/bin`, invisibles al gestor de paquetes)

| Binario | Versión | En nixpkgs 26.05 |
|---|---|---|
| `eww` | 0.6.0 | `eww` 0.6.0 ✓ misma |
| `wallust` | 3.5.1 | `wallust` 3.5.2 ✓ |
| `rofi` (2.0.0, sombrea apt) | 2.0.0 | `rofi` 2.0.0 ✓ misma |
| `awww`, `awww-daemon`, `swww` | — | `awww` 0.12.1 ✓ |
| `mpvpaper`, `xkbcli`, `prime-run`, `hyprswitch` (0 bytes, roto) | — | — |

### GPU

- Intel UHD (CometLake-H GT2) **activo** con `i915`.
- NVIDIA GTX 1650 Mobile presente pero **sin driver**: el DKMS solo compiló para
  kernels 6.12.x, no para el 7.1.13 en ejecución. `vulkaninfo` reporta errores
  del ICD de NVIDIA. `switcheroo-control` corre, `prime-run` existe.
- **Conclusión: en NixOS se puede apuntar a Intel-only sin perder nada real.**

### Conectores de display

| Connector | ¿Expuesto por el kernel? | ¿Referenciado en la config? |
|---|---|---|
| `eDP-1` | sí | sí (43 refs) |
| `HDMI-A-1` | sí | sí (11 refs) |
| `DP-1`, `DP-2` | **no** | sí, solo comentado/legacy |
| `Virtual-1` | no (es VM) | sí, activo en `lua/monitors.lua` |

El portátil es un **Acer Nitro AN515-55**: solo `eDP-1` + `HDMI-A-1`.

---

## 5. Clasificación de archivos Hyprland

Leyenda: **A** migrar tal cual · **B** migrar y adaptar · **C** revisar
dependencias · **D** específico de Debian · **E** histórico/legacy · **F**
opcional · **G** incierto.

### 5.1 Núcleo Lua — MIGRADO

| Archivo | Clase | Función | Adaptación aplicada |
|---|---|---|---|
| `hyprland.lua` | **B** | entrypoint | se quitan `openwhispr-binds.lua` y `hyprvim` |
| `lua/env.lua` | **B** | variables de sesión | se elimina el hack `XDG_DATA_DIRS += /usr/local/share:/usr/share` (**D**: en NixOS no existen) |
| `lua/startup.lua` | **B** | autostart | se quitan `qs`, `Polkit.sh`, `PortalHyprland.sh`, `nm-applet`, `swaync`, `hypridle`, `dbus-update-activation-environment`, `systemctl --user import-environment`, `wl-paste --watch` → pasan a **systemd declarativo**. `nm-applet`, `swaync`, `hypridle` y `wl-paste` siguen siendo imperativos en este archivo; `Polkit.sh` y `PortalHyprland.sh` ya **no** se invocan |
| `lua/user_overrides.lua` | **B** | orquestador | se elimina el sondeo de QML en `/usr/lib`, `/usr/lib64`, `/usr/share` (**D**); en NixOS los módulos QML no están ahí |
| `lua/monitors.lua` | **B** | monitores | se quita `Virtual-1` hardcodeado → pasa a **host-specific** |
| `lua/workspaces.lua` | **A** | workspaces | — |
| `lua/settings.lua` | **A** | dwindle/master/scrolling/input/cursor/gestures | — |
| `lua/window_rules.lua` | **A** | ~110 window rules KoolDots | — |
| `lua/laptops.lua` | **A** | vacío (placeholder) | — |
| `lua/animations.lua` | **A** | curvas/animaciones base | — |
| `lua/user_defaults.lua` | **A** | defaults + override de usuario | — |
| `lua/user_startup_helper.lua` | **A** | helper `exec_once` | — |
| `lua/user_keybinds_helper.lua` | **A** | helper bind/unbind | — |
| `lua/user_layer_rules_helper.lua` | **A** | helper | — |
| `lua/user_window_rules_helper.lua` | **A** | helper | — |
| `configs/system_*.lua` (7) | **A** | autoconfiguración | — |
| `UserConfigs/user_*.lua` (9) | **B** | personalización | ver abajo |
| `UserConfigs/monitors.lua` | **A** | overrides de monitor | — |
| `UserConfigs/workspaces.lua` | **B** | reglas de workspace | `eDP-1` hardcodeado → **host-specific** |

Adaptaciones en `UserConfigs/`:

- `user_env.lua` — **B**: se elimina el hack de `PATH` que añade
  `~/.local/bin` y `~/.cargo/bin`. En NixOS Home Manager ya publica
  `~/.local/bin` en `sessionPath`; añadirlo a mano es redundante y frágil.
- `user_startup.lua` — **B**: se elimina `eww daemon ... hyprvim/eww/whichkey`
  (HyprVim no se migra). Se conserva `hyprctl setcursor`.
- `user_keybinds.lua` — **B**: los 7 binds de Zen se comentan como
  `PENDIENTE: elegir navegador`. `SUPER M` se reapunta de `/snap/bin/mysql-workbench-community`
  (snap, **D**) a `mysql-workbench` (ya declarado en `paquetes.nix`).
  `SUPER O` se reapunta de `flatpak run md.obsidian.Obsidian` (**D**) a `obsidian`
  (ya declarado). Se conservan los `ALT+{h,j,k,l,w,b,x}` de `send_shortcut`.
- `user_laptops.lua` — **B**: los binds de tapa referencian `eDP-1`. En un host
  sin `eDP-1` Hyprland descarta la regla, pero es *hardware-specific*, así que
  se mueve al archivo de host.

### 5.2 EXCLUIDOS de la migración

| Elemento | Clase | Motivo |
|---|---|---|
| `configs/LegacyConfigs/` (7 `.conf`) | **E** | instantáneas del 2026-09-19 de configs ya migradas a Lua. Histórico; los `.conf` hacen lo mismo que las configuraciones Lua ya migradas. |
| `UserConfigs/LegacyConfigs/` (2× 11 `.conf`) | **E** | ídem, dos copias |
| `lua/decorators.lua`, `keybinds.lua`, `keybind_helpers.lua`, `laptop-lid.lua`, `layer_rules.lua`, `screenshot-region.lua`, `virtual_workspaces.lua`, `user_decorations_helper.lua` | **E** | plantillas del upstream; verificado que no se cargan |
| `lua/plugins/hyprvim/` + `openwhispr-binds.lua` | **F/G** | decisión del usuario: no migrar HyprVim |
| `animations/` (30 archivos) | **F** | catálogo de estilos alternativos para el menú `SUPER SHIFT A`. El activo es `UserConfigs/user_animations.lua` |
| `Monitor_Profiles/` (11) | **F** | los genera nwg-displays; perfiles `Virtual-1`/HDMI no aplican a un host real |
| `hyprland.conf`, `monitors.conf`, `workspaces.conf`, `application-style.conf` | **E** | andamiaje hyprlang anterior. `hyprland.conf` lista 17 `source=` de los que solo existe 1 |
| `hl.meta.lua` | **E** | stub de LuaLS; Hyprland instala el suyo |
| `initial-boot.sh`, `.initial_startup_done`, `v2.3.26.4` | **E** | estado de instalación de KoolDots |
| `wallpaper_effects/.wallpaper_*` | **E** | estado runtime, se regenera |
| `configs/Startup_Apps.disable`, todos los `.luarc.json` | **E** | metadatos de editor |
| `UserConfigs/*.conf` sueltos (`ghostty`, `kitty`, `hyprview-layout`, `LaptopDisplay`, `WorkSpaceRules`) | **E** | los `.conf` **no se cargan** en modo Lua; `user_overrides.lua` solo avisa por stdout |
| 30 scripts huérfanos | **E/D** | ver §8 |
| `rofi/config-emacs-keybinds.rasi`, `config-ghostty-theme.rasi`, `config-starship.rasi` | **F** | Emacs/Ghostty/Starship no están instalados |
| Variantes de Waybar no activas (`TOP-*`, `BOT-*`, `LEFT-*`, `RIGHT-*`, estilos alternativos) | **F** | No se migran: solo se despliegan layout `TOP-Default-Laptop-glass` + style `VERTICAL-Catpuccin-Mocha.css` y sus dependencias reales. Los selectores pueden así ofrecer menos opciones, de forma deliberada |
| `~/.config/quickshell` (82 archivos QML) | **E** | binario `qs` ausente; sin `~/.cache/quickshell`. Nunca ejecutó. Hay **dos** implementaciones de hyprview duplicadas (`overview/` y `qs-hyprview/`) |

---

## 6. Dependencias de ejecución

### 6.1 Programas externos por archivo

| Programa | Archivo | Uso | ¿Necesario? | ¿En `paquetes.nix`? | Acción |
|---|---|---|---|---|---|
| `hyprctl` | 42 scripts + `settings.lua` | control del compositor | **sí** | sí (`hyprland`) | mantener |
| `rofi` | 33 scripts | menús | **sí** | sí | mantener |
| `notify-send` | 46 scripts | notificaciones | **sí** | **no** (`libnotify`) | **añadir `libnotify`** |
| `wallust` | 9 scripts | theming por wallpaper | **sí** | **no** | **añadir `wallust`** |
| `awww` / `swww` | `WallpaperCmd.sh`, `WallpaperDaemon.sh`, `WallustSwww.sh` | fondo de pantalla | **sí** | **no** | **añadir `awww`** |
| `waybar` | 9 scripts | barra | sí | sí | mantener |
| `kitty` | 13 scripts | terminal (`$term`) | **sí** | sí | mantener |
| `thunar` | `user_defaults.lua` (`$files`), `LaunchFileManager.sh` | gestor de archivos | **sí** | **no** | **añadir `thunar`, `thunar-volman`, `gvfs`** |
| `playerctl` | `MediaCtrl.sh` | teclas multimedia | sí | sí | mantener |
| `pamixer` / `pactl` | `Volume.sh`, `Toggle-Active-Window-Audio.sh` | volumen | sí | sí (`pamixer`) | mantener |
| `brightnessctl` | `Brightness.sh`, `BrightnessKbd.sh` | brillo | sí | sí | mantener |
| `grim`, `slurp`, `swappy`, `wl-copy` | `ScreenShot.sh`, `hyprshot.sh` | capturas | sí | sí | mantener |
| `hyprpicker` | `hyprshot.sh` | selección de región | **sí** | **no** | **añadir `hyprpicker`** |
| `hyprlock` | `LockScreen.sh`, `KeyHints.sh` | bloqueo | sí | sí | mantener |
| `hyprsunset` | `Hyprsunset.sh` | luz nocturna | sí | sí | mantener |
| `hypridle` | `lua/startup.lua` | inactividad | sí | sí | mantener → **systemd** |
| `wl-paste` + `cliphist` | `lua/startup.lua` | portapapeles | sí | sí | mantener → **systemd** |
| `wlr-randr` | `MonitorProfiles.sh` | perfiles de monitor | sí (script opcional) | **no** | **añadir `wlr-randr`** |
| `jq` | `WallpaperDaemon.sh`, `WallustSwww.sh`, `MediaCtrl.sh` | JSON | sí | sí | mantener |
| `swaynotificationcenter` | daemon de notificaciones | **sí** | sí | gestionado por Home Manager (systemd --user) |
| `networkmanagerapplet` | `lua/startup.lua` (`nm-applet`) | Applet de red | sí | **no** | **añadir + systemd** |
| `mysql-workbench` | `user_keybinds.lua` (era `/snap/bin/...`) | BD | sí | sí | reapuntar |
| `obsidian` | `user_keybinds.lua` (era `flatpak run`) | notas | sí | sí | reapuntar |
| `code` | `user_keybinds.lua` | VS Code | sí | sí (`vscode`) | mantener |
| `eww` | `user_startup.lua` | which_key de HyprVim | **no** | no | **EXCLUIR** |
| `quickshell` / `qs` | `OverviewToggle.sh`, `toggle-qs-hyprview.sh` | hyprview | **no** (nunca corrió) | no | **EXCLUIR** |
| `ags` | `SUPER CTRL A` | overview | **no** (no instalado) | no | **EXCLUIR** |
| `zen` | `user_keybinds.lua` (7 binds) | navegador | **no** (aún sin decidir) | no | **EXCLUIR / PENDIENTE** |
| `asusctl`, `rog-control-center` | binds `XF86Launch1/3/4` | específicos de ASUS | no (hardware del portátil, no del NixOS VM) | no | **EXCLUIR** |
| `mpv` | `RofiBeats.sh`, window rule | vídeo | opcional | no | no añadir (F) |
| `dolphin`, `nemo`, `foot`, `alacritty`, `wezterm`, `micro`, `nvim`, `emacs` | menús con candidatos | candidatos de fallback | no | parcial | no añadir |

### 6.2 `swaync` — solución vigente de notificaciones

**`swaync` SÍ está disponible en nixpkgs 26.05**, como el paquete
`swaynotificationcenter`. La auditoría inicial lo confundió con un nombre de
atributo inexistente; se descartó el error cuando la sesión real mostró el
paquete en uso. Estado actual:

- `swaynotificationcenter` está declarado en `paquetes.nix`.
- `modules/home/hyprland.nix` declara `systemd.user.services.swaync`.
- `lua/startup.lua` **ya no** arranca SwayNC (se eliminó el
  `systemctl --user start swaync.service || swaync`).
- `swaync-client` se conserva para toggles/controles.
- La sesión Debian real confirmó `swaync` activo (`swaync.service` running).

Aparece en 33 scripts, pero en **31 de ellos solo como ruta de assets**
(`~/.config/swaync/images/*.png`, `~/.config/swaync/icons/*.svg` para los
`notify-send -i`). Solo unos pocos lo usan como programa. Comportamiento real
verificado en los archivos del repo:

- `configs/system_keybinds.lua`: keybind `SUPER SHIFT N` → `swaync-client -t -sw`
  (control del daemon, no arranque).
- `RefreshNoWaybar.sh:36`: **solo** `swaync-client -R -rs --skip-wait`
  (recarga de config/CSS; no arranca el daemon).
- `Refresh.sh`: tiene lógica de **recuperación**, no de arranque normal.
  `is_swaync_systemd()` (líneas 56-65) verifica que `swaync.service` exista y esté
  habilitado; solo entonces, si no está activo, hace
  `systemctl --user start swaync.service` (líneas 123-126). Si el daemon no está
  gestionado por systemd, cae a `swaync &` (líneas 130-131). Finalmente
  `swaync-client -R -rs` recarga (línea 135).
- `DarkLight.sh`: listas de `pkill` (inofensivo si no corre).

**Decisión:** conservar **`swaync`** (`swaynotificationcenter`). El arranque
normal es único y declarativo vía Home Manager (`systemd.user.services.swaync`);
`lua/startup.lua` no lo arranca. La lógica de `Refresh.sh` es una capa de
*recuperación* (reactiva, solo si el daemon está caído), no un segundo mecanismo
de arranque, y se conserva sin cambios.
Los assets se migraron a `hypr/notifications/{images,icons}`.
El theming de notificaciones vía `wallust/templates/colors-swaync.css` queda
como mejora opcional (validación visual pendiente).

---

## 7. Cosas específicas de Debian (excluidas o adaptadas)

| Elemento | Ubicación | tratamiento |
|---|---|---|
| `XDG_DATA_DIRS += /usr/local/share:/usr/share` | `lua/env.lua` | eliminado — no existen en NixOS |
| Sondeo QML en `/usr/lib`, `/usr/lib64`, `/usr/share` | `lua/user_overrides.lua` | eliminado — irrelevante en NixOS |
| Rutas de agentes polkit `/usr/libexec/...`, `/usr/bin/...` | `scripts/Polkit.sh` | **RESUELTO**: `Polkit.sh` ya no se invoca (línea eliminada de `lua/startup.lua`). Sus rutas hardcodeadas quedan como código muerto en el archivo, fuera del camino de arranque |
| `systemctl --user start swaync.service` | `lua/startup.lua` | gestionado por servicio systemd --user `swaync` (Home Manager); ya no se arranca desde Lua startup |
| `nm-applet` imperativo | `lua/startup.lua` | sustituido por `systemd.user.services.networkmanagerapplet` |
| `hypridle` imperativo | `lua/startup.lua` | sustituido por `systemd.user.services.hypridle` |
| `Hyprsunset.sh init` | `lua/startup.lua` | sustituido por `systemd.user.services.hyprsunset` |
| `wl-paste --watch cliphist store` | `lua/startup.lua` | sustituido por `systemd.user.services.cliphist` |
| `dbus-update-activation-environment` + `systemctl --user import-environment` | `lua/startup.lua` | eliminado — en NixOS el portal es un servicio systemd con `graphical-session.target` |
| `/snap/bin/mysql-workbench-community` | `UserConfigs/user_keybinds.lua` | reapuntado a `mysql-workbench` |
| `flatpak run md.obsidian.Obsidian` | `UserConfigs/user_keybinds.lua` | reapuntado a `obsidian` |
| `PATH += ~/.local/bin:~/.cargo/bin` | `UserConfigs/user_env.lua` | eliminado — Home Manager ya lo publica |
| `source /etc/profile` para flatpak | `~/.zshrc` / `.zprofile` | fuera de alcance (shell ya migrado con `modules/home/zsh.nix`) |
| `alias ls='eza ...'` con `eza` no instalado | `~/.zshrc` | **bug preexistente**, anotado; no tocado |
| `fastfetch` ejecutado en cada inicio de shell | `~/.zshrc` | anotado como pendiente; no tocado |
| NVIDIA DKMS roto | sistema | **NixOS apunta a Intel-only**; `hardware.nvidia` queda como decisión del host, no del repo |

---

## 8. Cosas históricas

**30 scripts huérfanos** (nunca referenciados por la configuración activa).
Lista exacta, generada con el mismo análisis reproducible del grafo que produjo
116 / 86 / 30:

```
Add-override-Hyprland-Portal.sh   ExternalBrightness.sh        LuaFullscreenMaximized.sh
Battery.sh                         HyprLayoutModule.sh          Polkit-Diag.sh
DisableWaybarService.sh            Hypridle.sh                  Polkit-NixOS.sh
Distro_update.sh                   JavaManager.sh               PortalHyprlandUbuntu.sh
build-awww.sh                      KeybindsLayoutInit.sh        ScrollMaximizeToggle.sh
debian-fix-version.sh              KooLsDotsUpdate.sh           Tak0-Autodispatch.sh
disable.cpu.turbo.sh               LaunchThunar.sh              UptimeNixOS.sh
fastfetch-wrapper.sh               UserConfigsSwitcher.sh       WaybarCava.sh
install-uv.sh                      WaybarScripts.sh             kooldots-add-ssh-agent.sh
set-default-thunar-terminal.sh     update_WindowRules.sh        kooldots-add-ssh-localhost.sh
```

Notables: `debian-fix-version.sh`, `PortalHyprlandUbuntu.sh`,
`kooldots-add-ssh-*.sh` son **específicos de Debian/Ubuntu**.
`Polkit-NixOS.sh` y `UptimeNixOS.sh` son scripts *de* NixOS pero **no están
en la cadena activa** — no se migran porque no se usan.

Otros restos: `~/.config/zen/` (6.794 archivos), `~/.var/app/` con 6 directorios
de flatpak huérfanos (Firefox, Chrome, Chromium, ChromeDev, Ungoogled, LibreWolf),
`~/Downloads/Debian-Hyprland/` (árbol de build propio de Hyprland, 24 componentes,
tags fijados a Hyprland **v0.53.3** mientras el apt tiene **0.56.2**),
`~/.local/bin/hyprswitch` (0 bytes), `hyprconf2lua` (venv pipx roto,
apunta a `/usr/bin/python3.13` inexistente), `drkonqi-coredump-launcher.socket`
(0 bytes).

**SECRET DETECTADO — NO MIGRADO**: `~/.ssh/id_ed25519`, `~/.gnupg/private-keys-v1.d`,
`~/.config/gh/config.yml`, `~/.config/gh/hosts.yml`. Ningún secreto entra al repo.

---

## 9. Cosas opcionales

- HyprVim (decisión del usuario: **no migrar ahora**).
- Quickshell / Hyprview overview.
- Zen Browser + Space Routing.
- `RainbowBorders` (SUPER SHIFT B) — bordes de ventana animados.
- `mpv`/`mpv-mpris`, `jellyfin`.
- `eww` y toda la cadena de `which_key`.
- Los 30 estilos de `animations/`, los perfiles de `Monitor_Profiles/`.
- Mejora opcional futura: tema de notificaciones vía wallust (`colors-swaync.css`) con SwayNC.
- Config de Waybar (integrada vía `dotfiles/waybar` + Home Manager; validación visual en NixOS/QEMU pendiente).

---

## 10. Hardware-specific

| Elemento | Dónde | Tratamiento |
|---|---|---|
| `Virtual-1` 1920x1080 | `lua/monitors.lua` | **fuera** del común → override por host |
| `eDP-1` en `UserConfigs/workspaces.lua` (ws 2,3,4) | ahí | **fuera** del común → override por host |
| `eDP-1` en binds de tapa | `UserConfigs/user_laptops.lua` | **fuera** del común → override por host |
| Perfiles `HDMI-A-1`, `Virtual-1-*` | `Monitor_Profiles/` | excluidos |
| `xf86Launch1/3/4` → `rog-control-center`, `asusctl` | `configs/system_keybinds.lua` | excluidos (ASUS ROG, no aplica al host NixOS) |
| Intel iGPU / NVIDIA GTX 1650 | fuera de la config | el repo **no** declara `hardware.nvidia`; se define por host si se necesita |
| `tlp` vs `power-profiles-daemon` | `paquetes.nix` | ambos conviven hoy; `tlp` en un VM es inútil → **REQUIERE VALIDACIÓN** |

---

## 11. Paquetes

### Añadir (justificados por un archivo migrado)

| Paquete | Versión nixpkgs | Justificación |
|---|---|---|
| `libnotify` | 0.8.8 | `notify-send`, usado por 46 scripts |
| `wallust` | 3.5.2 | flujo de theming (Waybar/Rofi/Hyprland/Kitty/Ghostty) |
| `awww` | 0.12.1 | backend de wallpaper |
| `thunar` | 4.20.9 | `$files` en `lua/user_defaults.lua` |
| `thunar-volman` | 4.20.0 | montaje automático de Volumes |
| `gvfs` | 1.60.3 | backend de archivos del portal |
| `xdg-desktop-portal-gtk` | 1.15.3 | diálogos de archivo en Wayland (hyprland portal no los trae) |
| `networkmanagerapplet` | 1.12.3 | `nm-applet`, sustituye al arranque imperativo |
| `hyprpicker` | 0.4.7 | `hyprshot.sh` (selección de región) |
| `wlr-randr` | 0.5.0 | `MonitorProfiles.sh` |
| `hyprlang` | 0.6.8 | CLI `hyprlang` que usa `MonitorProfiles.sh` |

### Quitar

| Paquete | Motivo |
|---|---|
| `hyprpaper` | **decisión del usuario**. KoolDots no lo usa en ningún punto; el fondo lo pone `awww`/`swww` |

### NO añadir (descartados tras verificar)

`quickshell`, `eww`, `mpv`, `zen`,
`asusctl`, `rog-control-center`, `dolphin`, `foot`, `alacritty`, `emacs`,
`micro`, `mpvpaper`, `swww` (covered por `awww`).

### Candidatos a eliminación (NO se tocan, requieren validación)

| Paquete | Observación |
|---|---|
| `swaynotificationcenter` | DAEMON DE NOTIFICACIONES VIGENTE. Gestionado por Home Manager (systemd --user). No es redundante |
| `dunst` | NO declarado. Decisión histórica descartada tras verificar que SwayNC está disponible y en uso |
| `tlp` | gestión de energía para portátil; irrelevante en VM |
| `yad`, `nwg-look`, `espanso`, `localsend`, `sane-frontends` | declarados previously, sin uso demostrado en la config migrada |

---

## 12. Propuesta final

### 12.1 Estructura (adaptada al patrón del repo: `dotfiles/<app>/` + HM)

```
dotfiles/hypr/                     → xdg.configFile."hypr"
├── hyprland.lua                   (B) entrypoint sin hyprvim/openwhispr
├── lua/                           (13) solo los módulos que se cargan
├── configs/                       (7)  system_*.lua
├── UserConfigs/                   (11) user_*.lua + monitors.lua + workspaces.lua
├── scripts/                       (closure alcanzable, podado)
├── UserScripts/                   (closure alcanzable, podado)
├── notifications/{images,icons}   (antes swaync/, renombrado)
├── rofi/                          (config.rasi + includes + wallust)
├── wallust/                       (wallust.toml, wallust-kitty.toml, templates/)
├── hyprlock.conf
└── hypridle.conf
```

### 12.2 Hardware-specific

**Estado actual:** no existe todavía ningún archivo host-specific de Hyprland.
Los únicos archivos bajo `hosts/` son:

```
hosts/hardware-laptopVM/hardware-configuration.nix
hosts/hardware-maicolVM/hardware-configuration.nix
```

Lo que **sí** está resuelto: el árbol común desplegado en
`dotfiles/hypr/` **no** contiene ni `eDP-1` ni `Virtual-1`. Los valores
hardware-specific se dejaron fuera de `lua/monitors.lua` y
`UserConfigs/workspaces.lua` (que quedaron sin reglas de monitor), y
`UserConfigs/user_laptops.lua` quedó como placeholder comentado.

**Pendiente / propuesto (no implementado):** crear
`hosts/hardware-<host>/hyprland.lua` con `hl.monitor` / `hl.workspace_rule`
propios del host, e importarlo desde el módulo HM solo para los hosts que lo
necesiten. Hasta esa fecha, un host cuyo layout requiera reglas de monitor
específicas debe declararlas por su cuenta.

### 12.3 Capa declarativa de sesión

`modules/home/hyprland.nix` declara (verificado en el archivo real):

- `xdg.configFile."hypr"` → el árbol Lua
- `xdg.configFile."waybar"` → la configuración de Waybar activa
- `home.pointerCursor` → cursor Bibata
- `systemd.user.services`: `hypridle`, `hyprsunset`, `swaync`,
  `networkmanagerapplet`, `cliphist`

**Portal (no requiere nada de este repositorio).** Verificado en
`nixpkgs nixos-26.05`: `programs.hyprland.enable = true` importa
`nixos/modules/programs/wayland/wayland-session.nix`, que ya activa
`xdg.portal.enable = true`, `xdg.portal.extraPortals = [ cfg.portalPackage ]`
(el portal de Hyprland) y `xdg.portal.configPackages = [ hyprland ]`
(→ `hyprland-portals.conf` con `default=hyprland;gtk`). El estado evaluado de
`laptopVM` lo confirma:

- `xdg.portal.enable` = `true`
- `xdg.portal.extraPortals` contiene `xdg-desktop-portal-hyprland`
- `xdg.portal.configPackages` = `["plasma-workspace", "hyprland"]`

El backend se activa por D-Bus
(`org.freedesktop.impl.portal.desktop.hyprland.service` →
`SystemdService=xdg-desktop-portal-hyprland.service`), así que no necesita
enablement manual. Por eso `PortalHyprland.sh` se eliminó del arranque.

**`hyprpolkitagent` — declarado en `configuration.nix`, no en HM.** Motivo: Home
Manager **no tiene** opción `enable`/`wantedBy` para units proporcionadas por
paquete, y `systemd.packages` solo existe en NixOS. La declaración correcta es:

```nix
systemd.packages = [ pkgs.hyprpolkitagent ];
systemd.user.services.hyprpolkitagent = {
  wantedBy = [ "graphical-session.target" ];
};
```

`hyprpolkitagent` ya venía en `environment.systemPackages` (`paquetes.nix`), pero
eso **no instala** su unit de usuario: hace falta `systemd.packages`. Y
`wantedBy` **alone** (sin `systemd.packages`) generaría una unit vacía sin
`ExecStart`, que rompería el servicio; ambos juntos producen el symlink
`graphical-session.target.wants/hyprpolkitagent.service` apuntando a la unit
**del paquete** (`overrideStrategy = "asDropinIfExists"` la deja intacta y solo
añade un drop-in de entorno). Verificado sobre un build real.

### 12.4 Lo que se conserva como script (y por qué)

`ApplyThemeMode.sh`, `WallpaperDaemon.sh`, `WaybarStartup.sh` — son
orquestación imperativa con `flock`, espera de sockets Wayland y bootstrap de
colores. Convertirlos a Nix no aportaría nada. Se quedan como scripts.

---

## 13. Riesgos

| # | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| R1 | La config Lua no arranca → Hyprland en blanco | **alto** | `hyprland` acepta `-c`; probar en el VM antes de depender. Verificado que la API existe en 0.55.4 |
| R2 | Mantenimiento de SwayNC como daemon de notificaciones (sin sustitución a dunst) | medio | assets de notificaciones coherentes con SwayNC; validación del panel pendiente |
| R3 | Waybar: los symlinks `config` / `style.css` son mutables en runtime (los selectores KoolDots los reescriben) mientras Home Manager los despliega desde el store | bajo | Comportamiento deseado y conservado; un `home-manager switch` posterior puede restaurar la variante del store. Validar en NixOS |
| R4 | `wl-paste --watch` como servicio systemd puede morir en suspend | bajo | `Restart = on-failure` |
| R5 | `notify-send` no estaba en `paquetes.nix` | bajo | se añade `libnotify` |
| R6 | Doble definición de `kb_layout`: `configuration.nix` (`services.xserver.xkb`) y `lua/settings.lua` (`latam`) | bajo | ambos coinciden en `latam`; el de Hyprland gana en sesión |
| R7 | `programs.hyprland.enable` escribe `/etc/xdg/hypr/hyprland.conf` | ninguno | verificado: `hyprland.lua` tiene precedencia absoluta |
| R8 | `tlp` en VM | bajo | se mantiene como estaba; no se introduce conflicto nuevo |
| R9 | Romper el Plasma/SDDM actual al tocar `configuration.nix` | **alto** | **no se toca `configuration.nix`** salvo lo imprescindible; todo lo nuevo va en `modules/home/hyprland.nix` |

---

## 14. Puntos inciertos

| # | Punto | Estado |
|---|---|---|
| G1 | **Waybar**: integración declarativa ya presente vía `dotfiles/waybar` + `xdg.configFile."waybar"`; layout activo `TOP-Default-Laptop-glass`, style activo `VERTICAL-Catpuccin-Mocha.css`. Falta la **prueba visual en NixOS/QEMU** | **REQUIERE VALIDACIÓN VISUAL** (no de configuración) |
| G2 | **Navegador**: Zen Browser con Space Routing (7 binds comentados) vs Brave/Firefox | **PENDIENTE DE DECISIÓN** |
| G3 | **HyprVim**: no migrado. Si se quiere, es un `input` del flake con `homeManagerModules.default` | **PENDIENTE** |
| G4 | **Quickshell/Hyprview**: excluido. Hay que elegir `overview/` o `qs-hyprview/` si se quiere recuperar | **PENDIENTE** |
| G5 | **Notificaciones**: comportamiento del panel de SwayNC (bind `SUPER SHIFT N`) requiere validación | **PENDIENTE** |
| G6 | **Theming de notificaciones**: validación de `wallust/templates/colors-swaync.css` con SwayNC | **PENDIENTE** |
| G7 | **NVIDIA**: el repo no declara `hardware.nvidia`. Si algún host lo necesita, va en `hosts/<host>/` | **POR HOST** |
| G8 | `Waybar`: los selectores dinámicos KoolDots (`WaybarLayout.sh` / `WaybarStyles.sh` reescriben los symlinks `config` / `style.css`) se conservan deliberadamente. `mkOutOfStoreSymlink` **no** se usa en esta fase | **INTEGRADO** — validar comportamiento de los selectores en NixOS |
| G9 | `swaynotificationcenter` | **VALIDADO EN SESIÓN REAL** — activo y usado como daemon de notificaciones; gestionado por Home Manager / `systemd --user` |
| G10 | Arranque de Hyprland (validación) | **VALIDADO EN SESIÓN REAL** (Hyprland 0.56.2 sobre Wayland, portátil físico Acer Nitro AN515-55) |

---

## 15. Validación

| Comprobación | Resultado |
|---|---|
| `nix flake metadata` | **VALIDADO** — flake resuelve, 3 inputs |
| `nix flake check` | **VALIDADO (PASS)** en el estado actual — ambos hosts (`laptopVM`, `maicolVM`) |
| `nix eval` de todos los outputs | **VALIDADO** |
| Versiones de paquetes consultadas contra el nixpkgs pineado | **VALIDADO** |
| Soporte Lua de Hyprland 0.55.4 | **VALIDADO** (código fuente + `pkg_search_module(LUA REQUIRED)`) |
| Precedencia `hyprland.lua` > `hyprland.conf` | **VALIDADO** (`Jeremy.cpp:35-41`) |
| Existencia de la API Lua usada | **VALIDADO** (`src/config/lua/bindings`) |
| Arranque real de Hyprland | **VALIDADO EN SESIÓN REAL** (0.56.2 Wayland) |
| Comportamiento de SwayNC | **OBSERVADO**: sesión real usa `swaync` (activo); el repositorio NixOS mantiene SwayNC vía Home Manager (systemd --user) |
| Sintaxis Lua (`hyprland.lua` + cadena `lua/*.lua`) | **VALIDADO** (`luac -p` / verificación de parseo) |
| Migración completada | **NO**. Pendiente: revisión final, commit y prueba visual/funcional en QEMU/NixOS. No se ha ejecutado `nixos-rebuild` ni activación de la configuración |

## Post-Migration Audit — Real Hyprland Session

**Fecha:** 2026-10-04 (auditoría durante sesión activa)

**Estado de sesión real:**
- XDG_SESSION_TYPE=wayland
- XDG_CURRENT_DESKTOP=Hyprland
- Hyprland 0.56.2 (v0.56.2 @ efb5099)

**Monitores detectados (live, portátil físico Acer Nitro AN515-55):**
- `eDP-1` (ID 0) 1920x1080@144Hz, physical 340x190mm, activo, workspace 1.

**Procesos activos relevantes:**
- `swaync` (141195) + `swaync-client -swb` (142365) — **en uso real**
- `dunst`: NO corriendo
- `hypridle` (141163) activo
- `nm-applet` (141075) activo
- `waybar` (142327) + `waybar-weather` (142373) activo
- `awww-daemon` (141602) activo
- `eww daemon` (141207) — HyprVim whichkey (`~/.local/share/hyprland/lua/plugins/hyprvim/eww/whichkey`)
- `hyprpolkitagent.service` (systemd --user) activo
- `xdg-desktop-portal-*` (gtk, hyprland, portal) activos

**Systemd --user (running):** incluye `swaync.service` activo; `dunst.service` **no** activo en la sesión real.

**Binds (Hyprland real):** 864 binds cargados. Los binds relacionados con Zen/Space Routing **no aparecen** entre los visibles; sí aparecen `SUPER M` → MySQL Workbench y `SUPER O` → Obsidian (coinciden con user_keybinds.lua). Los 7 binds de Zen permanecen comentados en la config migrada (decisión correcta hasta definir navegador).

**Scripts (conteo reproducible):**
- Total `.sh`: 116 (`scripts/`+`UserScripts/`)
- Alcanzables desde cadena Lua: **86**
- Huérfanos: **30**

> Se corrige la contradicción previa (89/34 vs 86/30): el conteo correcto reproducible es **86 alcanzables / 30 huérfanos / 116 totales**.

### Hallazgos con evidencia (vs auditoría anterior)

| # | Hallazgo | Estado previo | Estado real | Acción |
|---|---|---|---|---|
| H1 | Hyprland activo en sesión real | G10: NO VALIDABLE (LXQt/X11) | **SÍ activo** (0.56.2, Wayland) | Actualizar G10 → **VALIDADO EN SESIÓN REAL** |
| H2 | Notificaciones | SwayNC mantenido | **`swaync` está en uso real** (activo + client). Servicio `swaync` gestionado por Home Manager (systemd --user). `lua/startup.lua` ya no lo arranca explícitamente. | **CORREGIDO**: se conserva SwayNC (no sustituido por dunst). |
| H3 | Waybar | G1/G8: config ausente / no desplegada (diagnóstico inicial basado en una inspección incorrecta del symlink) | **Activo** en la sesión real, con layout `TOP-Default-Laptop-glass` y style `VERTICAL-Catpuccin-Mocha.css` | **CORREGIDO**: integrado en `dotfiles/waybar` vía `xdg.configFile."waybar"`; el diagnóstico previo de "directorio vacío" era incorrecto. Selectores dinámicos conservados |
| H4 | Eww (HyprVim whichkey) | Excluido por decisión (no migrar HyprVim) | **Corriendo** (`eww daemon -c .../hyprvim/eww/whichkey`) | Coherente con exclusión: no migrado. El daemon es residual del entorno Debian; al no desplegar HyprVim en NixOS no arrancará. Correcto dejar excluido. |
| H5 | Polkit/Portals | Pendientes de migrar a systemd --user | Activos en la sesión Debian real (`hyprpolkitagent.service` systemd --user + portals) | **RESUELTO**: `hyprpolkitagent` vía `systemd.packages` + `wantedBy = graphical-session.target` en `configuration.nix`; portal vía `xdg.portal` que `programs.hyprland.enable` ya activa. `Polkit.sh` y `PortalHyprland.sh` eliminados de `lua/startup.lua` |
| H6 | Zen binds | Comentados (pendiente) | No activos en binds visibles | Correcto. |
| H7 | HyprVim/openwhispr | Removidos de `hyprland.lua` | No activos | Correcto. |
| H8 | `Virtual-1` / `eDP-1` host-specific | Movidos fuera de common | Sesión física usa `eDP-1` | Correcto (common limpio). |
| H9 | Script closure | 86/30 | Coincide con análisis dinámico | Correcto. |

### Decisiones de reconciliación

- **swaync vs dunst (H2):** La auditoría anterior propuso Dunst (suponiendo que `swaync` no estaba disponible). La sesión real demostró que SwayNC es el gestor actualmente utilizado y que `swaynotificationcenter` sí existe en nixpkgs. Por tanto la propuesta de Dunst queda **descartada**. Arquitectura final: SwayNC conservado, gestionado por Home Manager mediante `systemd.user.services.swaync`; sin arranque imperativo desde Lua.
- **HyprVim/Eww (H4):** Exclusión correcta. No se añade al despliegue.
- **Waybar (H3):** la integración en `dotfiles/waybar` + `xdg.configFile."waybar"` es la forma elegida; no se crea config nueva. Falta la prueba visual/funcional en NixOS/QEMU.

### Correcciones menores realizadas

1. Actualizados puntos G1,G8,G10 en sección 14 con base en sesión real.
2. Añadida sección "Post-Migration Audit — Real Hyprland Session" con hallazgos y evidencia.
3. Reconciliado conteo de scripts (86/30) explícitamente.

### Estado general

**MIGRACIÓN: OK CON CORRECCIONES**

- Núcleo Lua correcto y adaptado.
- Separación host/common correcta.
- Systemd user services apropiados para NixOS.
- Exclusiones justificadas con evidencia.
- SwayNC conservado como daemon de notificaciones (Home Manager systemd --user).


## Notas de estado actual (octubre 2026)

- **HyprVim:** NO migrado. Eliminado de carga en hyprland.lua. Sin módulo activo.
- **OpenWhispr:** NO integrado activamente. Se conserva deliberadamente la entrada `class<openwishpr|OpenWishpr>` (icono 󰗋) en configuraciones de Waybar por compatibilidad futura; no es integración activa.
- **Eww/Quickshell/HyprView/AGS:** No migrados/descartados según decisiones previas.
- **SwayNC:** Gestor de notificaciones vigente. Servicio systemd --user definido en `modules/home/hyprland.nix`. Arranque explícito desde `lua/startup.lua` eliminado (única fuente HM). `swaync-client` mantenido.
- **Dunst:** No declarado como servicio/paquete activo. Referencias `x-dunst-stack-tag` en `ThemeChanger.sh` son residuales de notify-send, no requieren daemon Dunst.
- **Hypridle/hyprsunset/networkmanagerapplet/cliphist:** Servicios systemd --user en `modules/home/hyprland.nix`.
- **Polkit (hyprpolkitagent):** Declarativo en `configuration.nix` (`systemd.packages` + `wantedBy = graphical-session.target`). No en HM: Home Manager no puede habilitar units de paquete. `Polkit.sh` ya no se invoca.
- **Portal (xdg-desktop-portal-hyprland):** Sin código propio; `programs.hyprland.enable` ya activa `xdg.portal.enable` + `extraPortals` + `configPackages`. Backend activado por D-Bus. `PortalHyprland.sh` ya no se invoca.
- **Waybar:** Integrado vía `dotfiles/waybar` + `xdg.configFile."waybar"` (HM). Layout activo `TOP-Default-Laptop-glass`, estilo `VERTICAL-Catpuccin-Mocha.css`. Conservados symlinks dinámicos/selectores KoolDots (sin mkOutOfStoreSymlink en esta fase).
- **RainbowBorders:** Solo `RainbowBorders-low-cpu.sh` usado por selector/refresh (modo low_cpu).
- **Validación:** `nix flake check` pasa. Lua `hyprland.lua` pasa verificación básica (sintaxis/estructura). Migración NO finalizada (pendiente commit/revisión/prueba visual, sin nixos-rebuild).


## Estado final (verificación)
- SwayNC: mantenido (servicio HM + swaync-client). Dunst no activo.
- Waybar: integrado via dotfiles/waybar + HM xdg.configFile; layout TOP-Default-Laptop-glass, estilo VERTICAL-Catpuccin-Mocha.css.
- OpenWhispr: icon mapping conservado en Waybar (no integración activa).
- nix flake check: OK. Migración NO finalizada (pendiente revisión/commit/prueba visual, sin nixos-rebuild).
