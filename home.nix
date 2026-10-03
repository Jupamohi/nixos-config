{ config, pkgs, ... }:

{
  home.username = "jupamohi";
  home.homeDirectory = "/home/jupamohi";
  home.stateVersion = "26.05";

  # Paquetes que antes tenías en paquetes.nix a nivel de sistema,
  # pero que en realidad son "de usuario" (opcional moverlos aquí después)

  # --- Dotfiles: symlinks directos a lo que ya tienes en el repo ---
  home.file.".p10k.zsh".source = ./dotfiles/zsh/p10k.zsh;

  xdg.configFile."nvim/init.lua".source = ./dotfiles/nvim/init.lua;
  xdg.configFile."kitty".source = ./dotfiles/kitty;

  # --- Zsh: Home Manager maneja oh-my-zsh y plugins de forma nativa ---
  programs.zsh = {
  enable = true;
  oh-my-zsh = {
    enable = true;
    plugins = [ "git" ];
  };
  plugins = [
    {
      name = "zsh-autosuggestions";
      src = pkgs.zsh-autosuggestions;
    }
    {
      name = "zsh-syntax-highlighting";
      src = pkgs.zsh-syntax-highlighting;
    }
    {
      name = "powerlevel10k";
      src = pkgs.zsh-powerlevel10k;
      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }
  ];
  initContent = builtins.readFile ./dotfiles/zsh/zshrc;
  };
}
