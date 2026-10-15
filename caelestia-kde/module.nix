# NixOS module for Caelestia KDE (vendored inside nixos-config).
#
# This is the adapted copy of caelestia-kde/packaging/nix/module.nix: instead of
# taking the package from a flake's `self.packages`, it builds it locally from
# the packaging/ tree vendored next to this file. That makes nixos-config
# self-contained: cloning only this repo is enough (no separate caelestia-kde
# checkout and no `path:` flake input).
#
# Scope: make the packaged shell available and start it in a Plasma/Wayland
# session. It deliberately does NOT:
#   * change the display manager or the default session,
#   * touch /etc/sddm.conf.d, udev rules, keyd, or chsh,
#   * run the upstream installer.
# Those are separate, explicit choices the user makes on top of this module.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.caelestia-kde;
  pkg = cfg.package;

  # Same composition as the upstream flake's `packages.default`: the shell plus
  # the KWin effect. The effect is built from the source vendored next to this
  # module (shell/kwin-effects/workspace-tracker), so the KWin 6.6/6.7
  # compatibility patch is honoured instead of the unpatched pinned tarball.
  caelestiaShell = pkgs.callPackage ./packaging/nix/package.nix { };
  caelestiaWorkspaceTracker = pkgs.callPackage ./packaging/nix/workspace-tracker.nix { };
  defaultPackage = pkgs.symlinkJoin {
    name = "caelestia-kde-${caelestiaShell.version}";
    paths = [
      caelestiaShell
      caelestiaWorkspaceTracker
    ];
    meta = caelestiaShell.meta;
  };

  # Environment every session process (including the systemd user service)
  # needs so Qt finds the QML modules and the CLI finds its data.
  sessionEnv = {
    QML2_IMPORT_PATH = "${pkg}/lib/qt6/qml";
    CAELESTIA_LIB_DIR = "${pkg}/lib/caelestia";
    CAELESTIA_DATA_DIR = "${pkg}/share/caelestia";
    CAELESTIA_BIN_DIR = "${pkg}/bin";
    CAELESTIA_SHELL_CONFIG = "${pkg}/etc/xdg/quickshell/caelestia/shell.qml";
  };
in
{
  options.programs.caelestia-kde = {
    enable = lib.mkEnableOption "the Caelestia KDE desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression ''pkgs.symlinkJoin { paths = [ shell tracker ]; }'';
      description = "The caelestia-kde package to use.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install and enable the systemd user service that starts the shell with
        the graphical session. Disable to start it yourself (e.g. from Plasma's
        autostart, or by running `caelestia shell -d`).
      '';
    };

    updateChecker = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the periodic update-check timer. Off by default: on NixOS the
        shell is updated with the system, so the upstream git-based checker is
        only useful if you additionally configure it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkg ];

    environment.variables = sessionEnv;
    environment.sessionVariables = sessionEnv;

    # Hard runtime deps of the shell's typography. The plugin defaults the icon
    # style to the family "Material Symbols Rounded" (appearanceconfig.hpp) and
    # the clock/workspaces fonts to "Rubik". Without them installed, Qt silently
    # falls back and glyph names ("chevron_right", "widgets", …) render as text.
    fonts.packages = [
      pkgs.material-symbols
      pkgs.rubik
    ];

    systemd.user.services.caelestia-shell = lib.mkIf cfg.autostart {
      description = "Caelestia Shell";
      documentation = [ "https://github.com/ladybug-me/caelestia-kde" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      before = [ "xdg-desktop-autostart.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkg}/bin/caelestia-autostart";
        Environment = lib.mapAttrsToList (k: v: "${k}=${v}") sessionEnv;
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = 5;
        Slice = "session.slice";
      };
    };

    systemd.user.timers.caelestia-update-checker = lib.mkIf cfg.updateChecker {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "30min";
      };
    };
    systemd.user.services.caelestia-update-checker = lib.mkIf cfg.updateChecker {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkg}/bin/caelestia-check-updates";
      };
    };
  };
}
