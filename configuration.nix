# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./paquetes.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Bogota";

  # Select internationalisation properties.
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
 
  # resolucion 1920x180 para las VMs
  boot.kernelParams = [ "video=Virtual-1:1920x1080@60" ];

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable the XFCE desktop environment (sesion X11 ligera).
  services.xserver.desktopManager.xfce.enable = true;

  # ------------------------------------------------------------------
  # Sesiones visibles en SDDM: "plasma" (Wayland), "hyprland" y "xfce"
  # ------------------------------------------------------------------
  # services.displayManager.hiddenSessions NO existe en este nixpkgs (26.05):
  # se elimino en favor de services.displayManager.sessionPackages, que es la
  # lista de paquetes que aportan ficheros .desktop de sesion. SDDM lee
  # ${sessionData.desktops}/share/{xsessions,wayland-sessions}, y ese directorio
  # se construye enlazando los .desktop de cada sessionPackage.
  #
  # Paquetes que aportan sesiones por defecto:
  #   - programs.hyprland -> [ hyprland ]  (aporta hyprland + hyprland-uwsm)
  #   - plasma6           -> [ plasma-workspace.sessions ] (plasma + plasmax11)
  #   - xfce              -> paquete "xfce" generado desde desktopManager.session
  #
  # Reemplazamos la lista por paquetes de sesion filtrados que exponen solo los
  # .desktop deseados:
  #   - hyprland -> solo "hyprland" (Wayland); se descarta "hyprland-uwsm"
  #   - plasma   -> solo "plasma"   (Wayland); se descarta "plasmax11" (X11)
  #   - xfce     -> solo "xfce"     (X11). pkgs.xfce4-session ya instala
  #                 share/xsessions/xfce.desktop (Exec=startxfce4) upstream, asi
  #                 que reutilizamos ese fichero real en lugar de duplicar la
  #                 generacion de NixOS. startxfce4 esta en el PATH del sistema
  #                 porque el modulo XFCE anade xfce4-session a systemPackages.
  services.displayManager.sessionPackages = let
    # mkForce es imprescindible: programs.hyprland y plasma6 añaden sus
    # propios paquetes con lib.mkAfter, y ademas NixOS anade el paquete "xfce"
    # generado; sin forzar esta definicion la lista quedaria con todas las
    # sesiones y seguirian apareciendo las no deseadas.
    filtered = lib.mkForce (let
      mkSessionPkg =
      { pkg, keep }:
      pkgs.runCommand "${pkg.pname or pkg.name}-filtered-sessions"
        {
          nativeBuildInputs = [ pkgs.lndir ];
          src = pkg;
          passthru.providedSessions = keep;
        }
        ''
          mkdir -p "$out/share/xsessions" "$out/share/wayland-sessions"
          for d in xsessions wayland-sessions; do
            [ -d "$src/share/$d" ] || continue
            for n in ${lib.concatStringsSep " " keep}; do
              if [ -f "$src/share/$d/$n.desktop" ]; then
                ln -s "$src/share/$d/$n.desktop" "$out/share/$d/$n.desktop"
              fi
            done
          done
        '';
      in
      [
	    (mkSessionPkg {
          pkg = pkgs.labwc;
          keep = [ "labwc" ];
        })
        (mkSessionPkg {
          pkg = pkgs.hyprland;
          keep = [ "hyprland" ];
        })
        (mkSessionPkg {
          pkg = pkgs.kdePackages.plasma-workspace.sessions;
          keep = [ "plasma" ];
        })
        (mkSessionPkg {
          pkg = pkgs.xfce4-session;
          keep = [ "xfce" ];
        })
      ]);
  in
  filtered;

  # La sesion por defecto: plasma6.nix ya la deja en "plasma" con mkDefault, y
  # "plasma" es justo la sesion Wayland que ahora exponemos, asi que la asercion
  # "Default graphical session, 'plasma', not found" se cumple. Se deja explicito
  # por claridad (antes apuntaba a "plasmax11", ya no visible).
  services.displayManager.defaultSession = "plasma";

  # habilitar hyprland
  programs.hyprland.enable = true;

  # 32 bits para Heroic Games Launcher
  hardware.graphics.enable32Bit = true;


  # Agente de autenticación polkit para sesiones Hyprland.
  # hyprpolkitagent ya viene en environment.systemPackages (paquetes.nix), pero eso
  # NO instala su unit de usuario. hace falta:
  # - systemd.packages: instala share/systemd/user/hyprpolkitagent.service
  # - wantedBy: crea el symlink hyprland-session.target.wants (usando la unit
  #   del paquete vía overrideStrategy=asDropinIfExists, sin pisar su ExecStart)
  #
  # Se ata a hyprland-session.target y NO a graphical-session.target a
  # propósito: SDDM arranca graphical-session.target tanto en Plasma X11 como
  # en Hyprland, así que con graphical-session.target el agente de polkit
  # (que es Wayland) también arrancaba bajo Plasma. Ese target lo declara
  # modules/home/hyprland.nix y solo lo activa Hyprland.
  # El portal NO se declara aquí: programs.hyprland.enable ya activa
  # xdg.portal.enable + extraPortals con xdg-desktop-portal-hyprland.
  systemd.packages = [
    pkgs.hyprpolkitagent
  ];
  systemd.user.services.hyprpolkitagent = {
    wantedBy = [ "hyprland-session.target" ];
    partOf = [ "hyprland-session.target" ];
    after = [ "hyprland-session.target" ];
    # Guarda extra: solo arranca dentro de una sesión Hyprland (Wayland).
    unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
  };

  # Shell Caelestia. El empaquetado esta vendorizado dentro de este repo en
  # ./caelestia-kde (modulo NixOS + packaging/nix + el fuente parcheado del
  # efecto KWin), y se registra en ./caelestia-kde/module.nix desde flake.nix.
  # Asi clonar solo nixos-config es suficiente; no hace falta el input flake del
  # proyecto caelestia-kde.
  # Disponible en todos los hosts (el modulo se anade en flake.nix a los modules
  # comunes de mkHost), pero debe arrancar SOLO en la sesion Plasma (Wayland).
  programs.caelestia-kde.enable = true;

  # El modulo caelestia-kde ata el servicio a graphical-session.target, que SDDM
  # activa en las tres sesiones (Plasma, XFCE, Hyprland). Anadimos la misma
  # guarda de entorno que hyprpolkitagent para que se omita fuera de Plasma:
  # plasma.desktop declara DesktopNames=KDE y SDDM exporta
  # XDG_CURRENT_DESKTOP=KDE en Plasma Wayland; en XFCE el valor es XFCE y en
  # Hyprland es Hyprland, de modo que el servicio no arranca alli.
  systemd.user.services.caelestia-shell = {
    unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=KDE";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "la-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."jupamohi" = {
    isNormalUser = true;
    description = "Juan Pablo Mosquera Hinestroza";
    extraGroups = [ "networkmanager" "wheel" "input" "libvirtd" "kvm" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # zen browser
  environment.systemPackages = [
  inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];



  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [     
  # ];

#*************************** aqui pongo mis servicios************************************#
  # portapapeles entre VM y HOST
  services.spice-vdagentd.enable = true;

  # configuracion para zsh
  programs.zsh.enable = true;
  users.users.jupamohi.shell = pkgs.zsh;

  # habilitar los flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # limitar el menu de arranque
  boot.loader.systemd-boot.configurationLimit = 5;

  # borrar generaciones 
  # --keep 3 conserva como mínimo las últimas 3 generaciones.
  # --keep-since 7d conserva además todo lo de la última semana. Si hiciste muchos cambios seguidos, no te quedas con solo tres.
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 3 --keep-since 7d";
    };
  };

  nix.optimise.automatic = true;   # deduplica el store con hard links

  # cosas para el control
  hardware.uinput.enable = true;  
  hardware.steam-hardware.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;
    enableTCPIP = true; # pgAdmin desktop normalmente conecta por localhost:5432
  };

  # El módulo inicia PostgreSQL mediante este target al arrancar.
  # Quitar wantedBy evita el arranque automático.
  systemd.targets.postgresql.wantedBy = lib.mkForce [ ];

  # Evita también el inicio automático de pgAdmin.
  systemd.services.pgadmin.wantedBy = lib.mkForce [ ];

  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*Motion Sensors", ENV{ID_INPUT_JOYSTICK}="0", ENV{ID_INPUT_ACCELEROMETER}="0", GROUP="root", MODE="0600"
  '';

  # compartir pantalla
  xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

  # adjuntar archivos en whatsie
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "xdgdesktopportal";

  # habilitar flatpak
  services.flatpak.enable = true;

  # libvirt + QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;   # solo la arquitectura del host, más ligero
      runAsRoot = true;
      swtpm.enable = true;       # TPM emulado (necesario para Windows 11)
    };
  };

  # Interfaz gráfica
  programs.virt-manager.enable = true;

  # Opcional: portapapeles compartido y USB redirect en las VMs
  virtualisation.spiceUSBRedirection.enable = true;

  # bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };










  # fuentes
  #
  # Audit de glifos rotos en Waybar (ver dotfiles/waybar/style.css, font-family):
  #
  # - nerd-fonts.jetbrains-mono cubre 199 de los 203 glifos de planos
  #   privados que usan los módulos de Waybar. Los 4 ausentes (U+E6BB,
  #   U+F590, U+F61F, U+F6A9) salen de Font Awesome, no de Nerd Fonts, y solo
  #   corresponden a iconos de audio-dispositivo y kdeconnect; se cubren con
  #   font-awesome_6 (líneas de abajo).
  #
  # - El glifo del clima que emite waybar-weather (use_css_icon=false) es un
  #   emoji del plano U+1F3xx (ej. 🌧️ = U+1F327). JetBrainsMono Nerd Font no lo
  #   cubre, así que fontconfig recurría a Noto Color Emoji, un bitmap CBDT con
  #   un único strike de 136px y sin contornos: Pango no puede escalarlo a los
  #   ~14px de la barra y avisa "failed to create cairo scaled font ... Noto
  #   Color Emoji 12.999", dejando el glifo en blanco.
  #
  #   Solución: noto-fonts-monochrome-emoji (Noto Emoji) es outline y sí escala.
  #   Fontconfig da prioridad absoluta a las fuentes de emoji en color siempre
  #   que estén instaladas (lo advierte la propia descripción de
  #   fonts.fontconfig.defaultFonts.emoji), así que para que el monochrome sea
  #   el que se usa hay que NO instalar el de color.
  #
  #   `fonts.enableDefaultPackages` viene activado por graphical-desktop.nix
  #   (dependencia de SDDM/Plasma) y su lista incluye noto-fonts-color-emoji.
  #   Lo desactivamos con mkForce y añadimos explícitamente el resto de
  #   paquetes por defecto, excepto ese, más los nuestros. Efecto secundario:
  #   los emoji salen en monocromo, no en color.
  fonts.enableDefaultPackages = lib.mkForce false;
  fonts.packages = with pkgs; [
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.jetbrains-mono
    font-awesome_6
    nerd-fonts.symbols-only
    noto-fonts-monochrome-emoji
    dejavu_fonts
    freefont_ttf
    gyre-fonts
    liberation_ttf
    unifont
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ];

  fonts.fontconfig.defaultFonts.emoji = [ "Noto Emoji" ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

   programs.git = {
     enable = true;
     config = {
       user.name = "Jupamohi";
       user.email = "mosquerahinestrozajuanpablo13@gmail.com";
     };
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
