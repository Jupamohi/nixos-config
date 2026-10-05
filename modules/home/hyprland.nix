{ config, lib, pkgs, ... }:

let
  cfg = config.modules.home.hyprland;
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

    # Cursor (optional; Hyprland sets via env/ctl)
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      x11.enable = true;
      gtk.enable = true;
    };

    # Systemd user services (replace Debian imperative startup)
    systemd.user.services = {
      hypridle = {
        Unit = {
          Description = "Hypridle idle manager";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hypridle}/bin/hypridle";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      hyprsunset = {
        Unit = {
          Description = "Hyprsunset color temperature manager";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      swaync = {
        Unit = {
          Description = "SwayNotificationCenter";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      networkmanagerapplet = {
        Unit = {
          Description = "NetworkManager Applet";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      cliphist = {
        Unit = {
          Description = "Cliphist clipboard manager";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
