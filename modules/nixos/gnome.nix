{ pkgs, ... }:
let
  exts = with pkgs.gnomeExtensions; [
    dash-to-panel
    system-monitor
    caffeine
    clipboard-indicator
	appindicator
	gnome-wallpaper-engine
  ];
in
{
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  environment.systemPackages = exts;

  home-manager.users.jupamohi.dconf.settings."org/gnome/shell" = {
    disable-user-extensions = false;
    enabled-extensions = map (e: e.extensionUuid) exts;
  };
}
