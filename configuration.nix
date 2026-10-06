# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, lib, ... }:

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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ------------------------------------------------------------------
  # Sesiones visibles en SDDM: solo "hyprland" y "plasma x11"
  # ------------------------------------------------------------------
  # services.displayManager.hiddenSessions NO existe en este nixpkgs (26.05):
  # se elimino en favor de services.displayManager.sessionPackages, que es la
  # lista de paquetes que aportan ficheros .desktop de sesion. SDDM lee
  # ${sessionData.desktops}/share/{xsessions,wayland-sessions}, y ese directorio
  # se construye enlazando los .desktop de cada sessionPackage.
  #
  # Los dos modulos que anaden sesiones aqui:
  #   - programs.hyprland -> [ hyprland ]  (aporta hyprland + hyprland-uwsm)
  #   - plasma6           -> [ plasma-workspace.sessions ] (aporta plasma + plasmax11)
  #
  # Reemplazamos la lista por paquetes de sesion filtrados que exponen solo los
  # .desktop que queremos: hyprland (Wayland) y plasmax11 (X11, que SDDM
  # muestra como "Plasma (X11)"). Así desaparecen "hyprland-uwsm" y
  # "plasma" (Wayland) sin tocar nada mas del sistema.
  services.displayManager.sessionPackages = let
    # mkForce es imprescindible: programs.hyprland y plasma6 añaden sus
    # propios paquetes con lib.mkAfter, así que sin forzar esta definición la
    # lista quedaría con los 4 paquetes y seguirían apareciendo las sesiones
    # ocultas.
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
          pkg = pkgs.hyprland;
          keep = [ "hyprland" ];
        })
        (mkSessionPkg {
          pkg = pkgs.kdePackages.plasma-workspace.sessions;
          keep = [ "plasmax11" ];
        })
      ]);
  in
  filtered;

  # La sesion por defecto. plasma6.nix pone defaultSession = mkDefault "plasma",
  # pero "plasma" es precisamente la sesion Wayland que acabamos de ocultar, asi
  # que hay que sobreescribirla: sin esto el rebuild falla la asercion
  # "Default graphical session, 'plasma', not found". Se deja Plasma X11 como
  # sesion por defecto, que es la equivalente mas cercana de lo que pedia Plasma.
  services.displayManager.defaultSession = "plasmax11";

  # habilitar hyprland
  programs.hyprland.enable = true;

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
    extraGroups = [ "networkmanager" "wheel" "input" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [     
  # ];

#*************************** Aqui pongo mis servicios************************************#
  # portapapeles entre VM y HOST
  services.spice-vdagentd.enable = true;

  # configuracion para zsh
  programs.zsh.enable = true;
  users.users.jupamohi.shell = pkgs.zsh;

  # habilitar los flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # fuentes
  #
  # Audit de glifos rotos en Waybar (dotfiles/waybar/style.css usa
  # font-family: "JetBrainsMono Nerd Font"):
  #
  # - nerd-fonts.jetbrains-mono cubre 199 de los 203 glifos de planos
  #   privados que usan los módulos de Waybar. Los 4 ausentes (U+E6BB,
  #   U+F590, U+F61F, U+F6A9) salen de Font Awesome, no de Nerd Fonts, y solo
  #   corresponden a iconos de audio-dispositivo y kdeconnect; se añaden con
  #   font-awesome.v5 más abajo.
  #
  # - La nube del clima que emite waybar-weather es U+2601 + U+FE0F. JetBrainsMono
  #   Nerd Font no cubre ni U+2601 ni U+FE0F, así que fontconfig recurría a
  #   Noto Color Emoji, que es un bitmap CBDT con un único strike de 136px y sin
  #   contornos: Pango no puede escalarlo a los ~14px de la barra y avisa
  #   "failed to create cairo scaled font ... Noto Color Emoji 12.999", dejando
  #   el glifo en blanco.
  #
  #   Solución: noto-fonts-monochrome-emoji (Noto Emoji) es outline y sí escala.
  #   Fontconfig da prioridad absoluta a las fuentes de emoji en color siempre
  #   que estén instaladas (lo advierte la propia descripción de
  #   fonts.fontconfig.defaultFonts.emoji), así que para que el monochrome sea el
  #   que se usa hay que NO instalar el de color. Efecto secundario: los emoji
  #   salen en monocromo, no en color.
  #
  #   Para recuperar los emoji en color hay que volver a añadir
  #   noto-fonts-color-emoji a la lista; entonces los glifos pequeños de la barra
  #   vuelven a salirse, y la alternativa sería cambiar el glifo del clima por uno
  #   de Nerd Font (ver dotfiles/waybar-weather/config.toml, use_css_icon).
  fonts.packages = with pkgs; [
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.jetbrains-mono
    font-awesome_6
    noto-fonts-monochrome-emoji
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
