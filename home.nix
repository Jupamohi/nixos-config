{ config, pkgs, ... }:

{
  home.username = "jupamohi";
  home.homeDirectory = "/home/jupamohi";
  home.stateVersion = "26.05";
  home.packages = [ pkgs.freerdp ];

  imports = [
    ./modules/home/zsh.nix
    ./modules/home/plasma.nix
    ./modules/home/hyprland.nix
    ./modules/home/dms.nix
  ];

  home.file.".p10k.zsh".source = ./dotfiles/zsh/p10k.zsh;

  xdg.configFile."nvim/init.lua".source = ./dotfiles/nvim/init.lua;
  xdg.configFile."kitty" = {
    source = ./dotfiles/kitty;
    recursive = true;
  };
  xdg.configFile."systemd/user/plasma-xdg-desktop-portal-kde.service.d/override.conf".text = ''
    [Unit]
    AssertEnvironment=XDG_CURRENT_DESKTOP=*KDE*
  '';
  # KoolDots Hyprland (Lua)
  modules.home.hyprland.enable = true;
}
