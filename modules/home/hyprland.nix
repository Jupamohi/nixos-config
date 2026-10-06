{ config, lib, pkgs, ... }:

let
  cfg = config.modules.home.hyprland;

  # Shared unit stanza for the Wayland-only services, so the isolation
  # settings (PartOf/After on hyprland-session.target + the Wayland
  # ConditionEnvironment guard) cannot drift apart between services.
  #
  # ConditionEnvironment is a second line of defence: even if something else
  # ever starts these units manually, they refuse to run outside a Wayland
  # Hyprland session.
  waylandOnly =
    { description, execStart }:
    {
      Unit = {
        Description = description;
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
        ConditionEnvironment = [
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP=Hyprland"
        ];
      };
      Service = {
        ExecStart = execStart;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
in
{
  options.modules.home.hyprland = {
    enable = lib.mkEnableOption "KoolDots Hyprland (Lua) via Home Manager";
  };

  config = lib.mkIf cfg.enable {
    # XDG config for Hyprland (Lua + scripts + assets)
    xdg.configFile."hypr" = {
      source = ../../dotfiles/hypr;
      recursive = true;
    };

    # Waybar (mínimo, layout/style activos personalizados)
    xdg.configFile."waybar" = {
      source = ../../dotfiles/waybar;
      recursive = true;
    };

    # waybar-weather (binario Go, no está en nixpkgs -> ver paquetes.nix).
    # Lo invoca el módulo "custom/weather2" de dotfiles/waybar/ModulesCustom.
    # Declarado como symlink gestionado para que el toggle de unidades
    # (scripts/Toggle-weather-waybar-units.sh) pueda editarlo con sed -i.
    xdg.configFile."waybar-weather" = {
      source = ../../dotfiles/waybar-weather;
      recursive = true;
    };

    # Cursor (optional; Hyprland sets via env/ctl)
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      x11.enable = true;
      gtk.enable = true;
    };

    # =====================================================================
    # Session isolation: Hyprland vs Plasma X11
    # =====================================================================
    # This machine runs Plasma (X11) and Hyprland side by side, and SDDM
    # starts graphical-session.target for BOTH. Anything WantedBy that target
    # therefore also boots under Plasma, where waybar/swaync/hypridle/etc. are
    # useless and only burn RAM.
    #
    # Fix: introduce hyprland-session.target and move every Wayland-only unit
    # onto it. The target is deliberately declared WITHOUT an [Install]
    # section (static target): nothing pulls it in automatically, it is only
    # ever started by Hyprland itself, via
    # `systemctl --user start hyprland-session.target` in
    # dotfiles/hypr/lua/startup.lua. Plasma never runs that command, so the
    # target and everything bound to it stays inactive under Plasma X11.
    #
    # Note: the upstream hyprland package ships no systemd units and this
    # Hyprland build does not reference hyprland-session.target itself, so the
    # target has to be declared here.
    systemd.user.targets.hyprland-session = {
      Unit = {
        Description = "Hyprland compositor session";
        Documentation = [ "https://wiki.hypr.land/" ];
        # Tear the whole Hyprland stack down when the graphical session ends.
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
      };
    };

    # Wayland-only services, all sharing the isolation stanza in the module
    # `let` block above.
    systemd.user.services = {
      hypridle = waylandOnly {
        description = "Hypridle idle manager";
        execStart = "${pkgs.hypridle}/bin/hypridle";
      };

      hyprsunset = waylandOnly {
        description = "Hyprsunset color temperature manager";
        execStart = "${pkgs.hyprsunset}/bin/hyprsunset";
      };

      swaync = waylandOnly {
        description = "SwayNotificationCenter";
        execStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      };

      networkmanagerapplet = waylandOnly {
        description = "NetworkManager Applet";
        execStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
      };

      cliphist = waylandOnly {
        description = "Cliphist clipboard manager (text)";
        execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      };

      cliphist-image = waylandOnly {
        description = "Cliphist clipboard manager (image)";
        execStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      };
    };
  };
}
