{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./paquetes.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Bogota";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CO.UTF-8";
    LC_IDENTIFICATION = "es_CO.UTF-8";
    LC_MEASUREMENT = "es_CO.UTF-8";
    LC_MONETARY = "es_CO.UTF-8";
    LC_NAME = "es_CO.UTF-8";
    LC_NUMERIC = "es_CO.UTF-8";
    LC_PAPER = "es_CO.UTF-8";
    LC_TELEPHONE = "es_CO.UTF-8";
    LC_TIME = "es_CO.UTF-8";
  };

  # resolucion para las VMs
  boot.kernelParams = [ "video=Virtual-1:1920x1080@60" ];

  # GNOME y GDM los activa modules/nixos/gnome.nix
  services.xserver.enable = true;


  # 32 bits para Heroic Games Launcher
  hardware.graphics.enable32Bit = true;

  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };
  console.keyMap = "la-latin1";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."jupamohi" = {
    isNormalUser = true;
    description = "Juan Pablo Mosquera Hinestroza";
    extraGroups = [ "networkmanager" "wheel" "input" "libvirtd" "kvm" ];
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  # zen browser
  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  #*************************** servicios ************************************#
  # portapapeles entre VM y HOST
  services.spice-vdagentd.enable = true;

  programs.zsh.enable = true;
  users.users.jupamohi.shell = pkgs.zsh;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.configurationLimit = 5;

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 3 --keep-since 7d";
    };
  };

  nix.optimise.automatic = true;

  # cosas para el control
  hardware.uinput.enable = true;
  hardware.steam-hardware.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;
    enableTCPIP = true;
  };
  systemd.targets.postgresql.wantedBy = lib.mkForce [ ];
  systemd.services.pgadmin.wantedBy = lib.mkForce [ ];

  services.udev.packages = [ pkgs.game-devices-udev-rules ];
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*Motion Sensors", ENV{ID_INPUT_JOYSTICK}="0", ENV{ID_INPUT_ACCELEROMETER}="0", GROUP="root", MODE="0600"
  '';

  # adjuntar archivos en whatsie (dialogos via portal; con GNOME usa xdg-desktop-portal-gnome)
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "xdgdesktopportal";

  services.flatpak.enable = true;

  # libvirt + QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # keyring (VS Code guarda contraseñas)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # fuentes (enableDefaultPackages vuelve a su valor normal: emoji a color)
  fonts.packages = with pkgs; [
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ];

  programs.git = {
    enable = true;
    config = {
      user.name = "Jupamohi";
      user.email = "mosquerahinestrozajuanpablo13@gmail.com";
    };
  };

  # activar localSend y recibir archivos, el firewall por defecto ya viene en true pero no pierdo nada dejandolo declarado, y me ahorro imprevistos
  programs.localsend.enable = true;
  programs.localsend.openFirewall = true;

  # habilitar gamemode
  programs.gamemode.enable = true;

  # ************************** !OJO¡ no tocar sin comprobar antes ******************************************************************
  system.stateVersion = "26.05";
  # ******************************************************************************************************************************
}
