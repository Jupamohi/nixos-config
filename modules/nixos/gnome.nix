{ pkgs, lib, ... }:

let
  exts = with pkgs.gnomeExtensions; [
    dash-to-panel
    system-monitor
    caffeine
    clipboard-indicator
    appindicator
    gnome-wallpaper-engine
    blur-my-shell
  ];

  elementPositions = [
    { element = "showAppsButton"; visible = false; position = "stackedTL"; }
    { element = "activitiesButton"; visible = true; position = "stackedTL"; }
    { element = "leftBox"; visible = true; position = "stackedTL"; }
    { element = "taskbar"; visible = true; position = "stackedTL"; }
    { element = "centerBox"; visible = true; position = "stackedBR"; }
    { element = "dateMenu"; visible = true; position = "centerMonitor"; }
    { element = "rightBox"; visible = true; position = "stackedBR"; }
    { element = "systemMenu"; visible = true; position = "stackedBR"; }
    { element = "desktopButton"; visible = true; position = "stackedBR"; }
  ];
  
    # Mismo orden para los monitores 0..3, sin depender de su ID
    porMonitor = lib.genAttrs (map toString (lib.range 0 3)) (_: elementPositions);

in { services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  environment.systemPackages = exts;

  home-manager.users.jupamohi.dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (e: e.extensionUuid) exts;
    };

    "org/gnome/shell/extensions/dash-to-panel" = {
      # Apariencia de los iconos y el highlight
      appicon-margin = 3;
      appicon-padding = 3;
      animate-appicon-hover = false;
      highlight-appicon-hover = true;
      highlight-appicon-hover-background-color = "rgba(238,238,236,0.18)";
      highlight-appicon-hover-border-radius = 16;
      highlight-appicon-pressed-background-color = "rgba(238,238,236,0.18)";
      focus-highlight = true;
      focus-highlight-dominant = false;
      focus-highlight-opacity = 15;
      dot-position = "TOP";
      dot-size = 3;
      dot-style-focused = "DOTS";
      dot-style-unfocused = "DOTS";
      global-border-radius = 0;
      show-window-previews = false;
      window-preview-title-position = "TOP";

      # Panel
      intellihide = false;
      panel-side-margins = 0;
      panel-side-padding = 0;
      panel-top-bottom-margins = 0;
      panel-top-bottom-padding = 4;
      leftbox-padding = -1;
      leftbox-size = 0;
      status-icon-padding = -1;
      tray-padding = -1;
      tray-size = 16;
      panel-position = "TOP";
      panel-element-positions = builtins.toJSON porMonitor;

      # Comportamiento
      hotkeys-overlay-combo = "TEMPORARILY";
      scroll-panel-action = "CHANGE_VOLUME";
      stockgs-keep-dash = true;
      stockgs-panelbtn-click-only = true;

      # Opacidad
      trans-use-custom-opacity = true;
      trans-panel-opacity = 0.0;
      trans-use-dynamic-opacity = true;
      trans-dynamic-anim-target = 1.0;
      trans-dynamic-anim-time = 500;
      trans-use-custom-bg = false;
      trans-use-border = false;
    };

    "org/gnome/shell/extensions/blur-my-shell" = { };

    "org/gnome/shell/extensions/blur-my-shell/appfolder".blur = false;
    "org/gnome/shell/extensions/blur-my-shell/applications".pipeline = "pipeline_default";
    "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab".blur = false;
    "org/gnome/shell/extensions/blur-my-shell/dash-to-panel".blur-original-panel = false;
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = false;
      override-background = true;
      override-background-dynamically = true;
      pipeline = "pipeline_default";
      static-blur = false;
      style-panel = 2;
      unblur-in-overview = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/popup" = {
      blur = false;
      pipeline = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      blur = false;
      pipeline = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/window-list".blur = false;
  };
 }
