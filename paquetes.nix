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
    pgadmin4-desktopmode
	lazygit


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
    amberol

    # Fuentes
    fira-code
    jetbrains-mono
    noto-fonts

    # Theming (GTK)
    whitesur-cursors
  ];
}
