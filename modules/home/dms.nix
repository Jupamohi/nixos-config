{ pkgs, ... }:

{
  programs.dank-material-shell = {
    enable = true;
    # NO activar systemd.enable (arrancaría también en Plasma)
    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;

    settings = builtins.fromJSON (builtins.readFile ../../dotfiles/dms/settings.json);
  };

  wayland.windowManager.labwc = {
    enable = true;
    systemd.enable = true;
    environment = [ "XKB_DEFAULT_LAYOUT=latam" "QT_QPA_PLATFORM=wayland" ];
    autostart = [ "dms run &" ];
  };

  xdg.configFile."labwc/rc.xml".source = ../../dotfiles/labwc/rc.xml;

  # Avatar del usuario (AccountsService usa ~/.face por defecto; DMS lo lee).
  home.file.".face".source = ../../assets/icono.png;


  home.packages = with pkgs; [
    kitty playerctl grim slurp wl-clipboard wev
    gtk3 xdg-utils libnotify
  ];

  home.file.".local/bin/captura" = {
    executable = true;
    text = ''
      #!/bin/sh
      f="$HOME/Pictures/Screenshots/$(date +%F_%H-%M-%S).png"
      mkdir -p "$(dirname "$f")"
      geom="$(slurp)" || exit 0
      grim -g "$geom" "$f" && wl-copy < "$f"
    '';
  };

  home.file.".local/bin/abrir-navegador" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec gtk-launch "$(xdg-settings get default-web-browser)"
    '';
  };
}
