{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Navegadores / comunicación
    brave
    discord
    whatsie
    localsend
    teams-for-linux

    # Editores / desarrollo
    vscode
    neovim
    git
    obsidian
    mysql-workbench
    mysql84
    pgadmin4-desktopmode

    # Terminal / shell
    zsh
    kitty
    eza
    bat
    tree
    btop
    nvtopPackages.full
    cava
    gum
    fastfetch
    inxi
    jq
    w3m
    oh-my-zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-powerlevel10k
    postgresql
    flatpak
    bc

    # Utilidades
    wl-clipboard
    libnotify
    brightnessctl
    playerctl
    pamixer
    pavucontrol
    qalculate-gtk
    system-config-printer
    sane-frontends
    yad
    espanso
    tlp
    libreoffice
    heroic
    efibootmgr
    evtest
	gparted
	unetbootin
	mpv
    ffmpeg

    # Multimedia
    quodlibet

    # Fuentes
    fira-code
    jetbrains-mono
    noto-fonts

    # Theming (GTK)
   # gtk-engine-murrine
   # whitesur-gtk-theme
   # whitesur-icon-theme
    whitesur-cursors
  ];
}
