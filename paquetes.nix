{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Navegadores / comunicación
    brave
    discord
    localsend

    # Editores / desarrollo
    vscode
    neovim
    git
	obsidian
	mysql-workbench
	mysql84

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

    # Hyprland y ecosistema
    hyprland
    hyprlock
    hyprpolkitagent
    hyprsunset
    hypridle
    xdg-desktop-portal-hyprland
    waybar
    rofi
    swaynotificationcenter
	bc

    # KoolDots extras
    wallust
    awww
    thunar
    thunar-volman
    gvfs
    xdg-desktop-portal-gtk
    networkmanagerapplet
    hyprpicker
    wlr-randr
    libnotify
    cliphist
    wl-clipboard
    wtype
    grim
    slurp
    swappy
    wlogout
    nwg-displays
    nwg-look
    brightnessctl
    playerctl
    pamixer
    pavucontrol

    # Multimedia
    quodlibet

    # Virtualización

    # Utilidades
    qalculate-gtk
    system-config-printer
    sane-frontends
    yad
    espanso
    tlp

    # Fuentes
    fira-code
    jetbrains-mono
    noto-fonts

    # Theming
    libsForQt5.qt5ct
    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    gtk-engine-murrine

	# Theming MacOS
    whitesur-gtk-theme
    whitesur-icon-theme
    whitesur-kde
    whitesur-cursors
  ];
}
