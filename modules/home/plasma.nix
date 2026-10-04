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
    };

	workspace = {
      lookAndFeel = "com.github.vinceliuice.WhiteSur-dark";
      iconTheme = "WhiteSur-dark";
      cursor = {
        theme = "WhiteSur-cursors";
        size = 24;
      };
      wallpaper = "file:///home/jupamohi/nixos-config/dotfiles/wallpapers/windows-11-dark-mode-abstract-background-black-background-7680x4320-8710.png";
    };

	panels = [
  {
    location = "top";
    height = 44;
	opacity = "opaque";
    floating = true;
    hiding = "none";
    widgets = [
      {
        name = "org.kde.plasma.kickoff";
        config.General = {
          icon = "distributor-logo-nixos";
          useCustomButtonImage = true;
        };
      }
      "org.kde.plasma.marginsseparator"
      "org.kde.plasma.minimizeall"
      "org.kde.plasma.marginsseparator"
      {
        name = "org.kde.plasma.icontasks";
        config.General.launchers = "";
      }
      "org.kde.plasma.panelspacer"
      {
        name = "org.kde.plasma.digitalclock";
        config.Appearance = {
          dateFormat = "longDate";
          showDate = false;
          showSeconds = "Never";
        };
      }
      "org.kde.plasma.panelspacer"
      "org.kde.plasma.systemtray"
    ];
  }
];

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
}
