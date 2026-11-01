{ config, pkgs, ... }:

{
  programs.plasma = {
    enable = true;

    shortcuts = {
      "services/code.desktop"._launch = "Meta+C";
      "services/discord.desktop"._launch = "Meta+Shift+D";
      "services/firefox.desktop"._launch = "Meta+B";
      "services/kitty.desktop"._launch = "Meta+Return";
      kwin.ClearLastMouseMark = "Meta+Shift+F12";
      kwin.ClearMouseMarks = "Meta+Shift+F11";
      org_kde_powerdevil.powerProfile = "Battery";
      # Free the bare Meta (Super) key. Plasma's launcher defaults to Meta, so it
      # grabs Super before the Caelestia shell can register its own launcher
      # binding (Meta+Space and Meta, see ~/.config/caelestia/keybinds.json).
      # Moving the Plasma launcher to its alternate default (Alt+F1) lets Super
      # open the Caelestia launcher instead.
      "plasmashell"."activate application launcher" = "Alt+F1";
    };

	workspace = {
      lookAndFeel = "com.github.vinceliuice.WhiteSur-dark";
      iconTheme = "WhiteSur-dark";
      cursor = {
        theme = "WhiteSur-cursors";
        size = 24;
      };
      wallpaper = "/home/jupamohi/nixos-config/dotfiles/wallpapers/windows-11-dark-mode-abstract-background-black-background-7680x4320-8710.png";
    };

    # The Caelestia shell draws its own bar (a Quickshell layer-shell surface at
    # the bottom), so a Plasma panel would duplicate it. The original panel is
    # kept commented below as the recovery path: uncomment `panels` and drop the
    # `caelestia-remove-plasma-panel` desktopScript to get it back. It also lives
    # in git history.
    #
    # `programs.plasma.panels` only emits its panel script when non-empty, so an
    # empty list would leave the panel from the previous generation in place.
    # The desktopScript below runs after plasma-manager's own script (priority 2)
    # and removes any leftover panel, so only Caelestia's bar is shown.
    #
    # panels = [
    #   {
    #     location = "top";
    #     height = 44;
    #     opacity = "opaque";
    #     floating = true;
    #     hiding = "none";
    #     widgets = [
    #       {
    #         name = "org.kde.plasma.kickoff";
    #         config.General = {
    #           icon = "distributor-logo-nixos";
    #           useCustomButtonImage = true;
    #         };
    #       }
    #       "org.kde.plasma.marginsseparator"
    #       "org.kde.plasma.minimizeall"
    #       "org.kde.plasma.marginsseparator"
    #       {
    #         name = "org.kde.plasma.icontasks";
    #         config.General.launchers = "";
    #       }
    #       "org.kde.plasma.panelspacer"
    #       {
    #         name = "org.kde.plasma.digitalclock";
    #         config.Appearance = {
    #           dateFormat = "longDate";
    #           showDate = false;
    #           showSeconds = "Never";
    #         };
    #       }
    #       "org.kde.plasma.panelspacer"
    #       "org.kde.plasma.systemtray"
    #     ];
    #   }
    # ];
    startup.desktopScript.caelestia-remove-plasma-panel = {
      priority = 3;
      runAlways = true;
      text = ''
        panels().forEach((panel) => panel.remove());
      '';
    };

    configFile = {
	  kdeglobals.KDE.AutomaticLookAndFeel = false;
      kscreenlockerrc.Daemon.Autolock = false;
      kscreenlockerrc.Daemon.Timeout = 0;
      kwinrc.Compositing.WindowsBlockCompositing = false;
      kwinrc.Plugins.blurEnabled = true;
      kwinrc.Plugins.contrastEnabled = true;
      kwinrc.Plugins.diminactiveEnabled = true;
      kwinrc.Plugins.mousemarkEnabled = true;
      kwinrc.Effect-mousemark.Freedrawalt = true;
      kwinrc.Effect-mousemark.Freedrawcontrol = true;
      kwinrc.Effect-mousemark.Freedrawshift = false;
      kwinrc."org.kde.kdecoration2".theme = "__aurorae__svg__WhiteSur-dark";
      kdeglobals.WM.activeBackground = "51,51,51";
      kdeglobals.WM.activeBlend = "171,171,171";
      kdeglobals.WM.activeForeground = "252,252,252";
      kdeglobals.WM.inactiveBackground = "66,66,66";
      kdeglobals.WM.inactiveBlend = "85,85,85";
      kdeglobals.WM.inactiveForeground = "170,170,170";
      plasmarc.Wallpapers.usersWallpapers = "/home/jupamohi/nixos-config/dotfiles/wallpapers/windows-11-dark-mode-abstract-background-black-background-7680x4320-8710.png,/home/jupamohi/nixos-config/dotfiles/wallpapers/linux-3840x2160-18053.png,/home/jupamohi/nixos-config/dotfiles/wallpapers/japan-artistic-5120x2880-25406.jpg";
    };
  };
  systemd.user.services.plasma-manager-late = {
    Unit = {
      Description = "Reaplica la config de plasma-manager cuando plasmashell esta listo";
      After = [ "plasma-plasmashell.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "plasma-manager-late" ''
        for i in $(seq 1 60); do
          ${pkgs.systemd}/bin/busctl --user status org.kde.plasmashell >/dev/null 2>&1 && break
          sleep 1
        done
        exec "$HOME/.local/share/plasma-manager/run_all.sh"
      '';
    };
    Install.WantedBy = [ "plasma-workspace.target" ];
  };
}
