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
    hyprpaper
    hyprpolkitagent
    hyprsunset
    hypridle
    xdg-desktop-portal-hyprland
    waybar
    rofi
    dunst
    swaynotificationcenter
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
#	nerd-fonts.fantasque-sans-mono   
#   nerd-fonts.jetbrains-mono       
#   noto-fonts-color-emoji

    # Theming
    libsForQt5.qt5ct
    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    gtk-engine-murrine
	plank

	# Theming MacOS
    whitesur-gtk-theme
    whitesur-icon-theme
    whitesur-kde
    whitesur-cursors
  ];
}
