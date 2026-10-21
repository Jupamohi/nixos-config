{ pkgs, ... }:


let
  # Upstream no está en nixpkgs; el dotfile lo invoca como binario
  # `waybar-weather` (waybar/ModulesCustom -> "custom/weather2").
  # Upstream: https://github.com/wneessen/waybar-weather
  waybar-weather = pkgs.buildGoModule {
    pname = "waybar-weather";
    version = "0.3.1";

    src = pkgs.fetchgit {
      url = "https://github.com/wneessen/waybar-weather.git";
      rev = "cbf1d8aa80f16226b83031a3124d636604e1e811"; # v0.3.1
      hash = "sha256-OAqwl3GILTzYOk7pbREaLbDVhDPpbrrkrUfuSo5L3oY=";
    };

    vendorHash = "sha256-4Ccz/l1hX/NplF+M6jzUEuu8U90x986XBVJ9qNFVGoA=";

    subPackages = [ "cmd/waybar-weather" ];

    meta = {
      description = "Waybar module for weather information";
      homepage = "https://github.com/wneessen/waybar-weather";
      license = pkgs.lib.licenses.mit;
      mainProgram = "waybar-weather";
      platforms = pkgs.lib.platforms.unix;
    };
  };
in
{
  environment.systemPackages = with pkgs; [
    waybar-weather
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


    # Utilidades
    qalculate-gtk
    system-config-printer
    sane-frontends
    yad
    espanso
    tlp
	libreoffice-qt
	heroic
    efibootmgr

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
