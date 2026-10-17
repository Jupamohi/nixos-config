# Declarative package for Caelestia KDE.
#
# Builds shell/ (Quickshell QML + C++ QML plug-in) with its pinned M3Shapes
# dependency, plus the Caelestia KWin effect, and installs everything into $out.
# The original installer (install.sh / caelestia-install) is never run.
{
  lib,
  pkgs,
  stdenv,
  fetchgit,
  cmake,
  ninja,
  pkg-config,
  makeWrapper,
  qt6,
  kdePackages,
  # Pinned upstream source. Override with `caelestiaSrc = ./.;` to build a checkout.
  caelestiaSrc ? fetchgit {
    url = "https://github.com/ladybug-me/caelestia-kde.git";
    rev = "426e5d7021526b15a2100e0ce5cfd12886e2bfd3";
    hash = "sha256-03z2wkuhfPFizrjVIVUF65n8U4HA8KpZT8tpvcDZC7U=";
    fetchSubmodules = true;
  },
  # Pinned M3Shapes source (FetchContent input). Built in-tree by shell/CMakeLists.
  m3shapesSrc ? import ./m3shapes-src.nix { inherit fetchgit; },
}:

let
  version = "2.6.0";
  gitRevision = "426e5d7021526b15a2100e0ce5cfd12886e2bfd3";

  common = import ./common.nix { inherit pkgs; };

  # Runtime tools the bash CLI helpers look up by name through PATH. Without
  # this a NixOS user gets "command not found" from caelestia-color, record,
  # screenshot, and from the environment probes in the shell.
  # NixOS's Qt6 ships the D-Bus client as `qdbus` (qt6.qttools); Caelestia's QML
  # and scripts call `qdbus6` by name. Provide that name on the shell PATH.
  qdbus6 = pkgs.runCommand "qdbus6-${pkgs.qt6.qttools.version}" { } ''
    mkdir -p "$out/bin"
    ln -s ${pkgs.qt6.qttools}/bin/qdbus "$out/bin/qdbus6"
  '';

  runtimeDeps = with pkgs; [
    quickshell
    matugen
    python3
    bash
    coreutils
    gnused
    gnugrep
    procps
    systemd
    util-linux
    libnotify
    wl-clipboard
    gpu-screen-recorder
    imagemagick
    jq
    inotify-tools
    cliphist
    wl-clip-persist
    ydotool
    ddcutil
    brightnessctl
    xdg-user-dirs
    polkit
    kdePackages.spectacle
    kdePackages.kconfig
    # Keyboard-layout popout (KbLayoutModel.qml) parses XKB rules and queries
    # org.kde.keyboard over D-Bus; these tools are invoked by name from QML.
    libxml2.bin
    qdbus6
    # globalshortcut.cpp (KDE port) releases a shortcut it conflicts with by
    # spawning `gdbus org.kde.KGlobalAccel.setShortcutKeys` before claiming the
    # key, and uses it again for crash recovery. On Arch gdbus lives in /usr/bin
    # (glib is a base package), so upstream's runtime list never named it; on
    # NixOS the shell PATH is only this list, so the release silently failed and
    # every conflicting key (Meta+V, Meta+B, Meta+Tab, Meta+1..9, ...) stayed
    # owned by Plasma/KWin with Caelestia's own entry left empty. glib's default
    # output ships bin/gdbus.
    glib
  ];
  runtimePath = lib.makeBinPath runtimeDeps;

  # KbLayoutModel.qml reads XKB layout rules straight from
  # /usr/share/X11/xkb/rules/{base,evdev}.xml, which does not exist on NixOS.
  # Point it at the store path of xkeyboard-config instead.
  xkbRulesDir = "${pkgs.xkeyboard-config}/share/X11/xkb/rules";

  caelestiaBinScripts = [
    "caelestia"
    "caelestia-check-updates"
    "caelestia-color"
    "caelestia-record"
    "caelestia-screenshot"
    "caelestia-shell-ipc"
    "caelestia-update"
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "caelestia-kde";
  inherit version;
  src = caelestiaSrc;

  nativeBuildInputs =
    common.shellNativeBuildInputs
    ++ [
      makeWrapper
    ];
  buildInputs = common.shellBuildInputs ++ [ pkgs.xkeyboard-config ];

  # The CMake project lives in shell/ (it pulls ../src/* via relative paths).
  # cmakeDir is resolved relative to the build dir, hence the "../".
  cmakeDir = "../shell";

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
    (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" (placeholder "out"))
    (lib.cmakeFeature "CMAKE_INSTALL_RPATH_USE_LINK_PATH" "ON")
    (lib.cmakeFeature "VERSION" version)
    (lib.cmakeFeature "GIT_REVISION" gitRevision)
    (lib.cmakeFeature "DISTRIBUTOR" "NixOS")
    # Keep the FHS-relative layout but rooted at $out.
    (lib.cmakeFeature "INSTALL_BINDIR" "bin")
    (lib.cmakeFeature "INSTALL_LIBDIR" "lib/caelestia")
    (lib.cmakeFeature "INSTALL_DATADIR" "share/caelestia")
    (lib.cmakeFeature "INSTALL_QMLDIR" "lib/qt6/qml")
    (lib.cmakeFeature "INSTALL_QSCONFDIR" "etc/xdg/quickshell/caelestia")
    # Reproducibility: no network during the build.
    (lib.cmakeBool "CAELESTIA_OFFLINE" true)
    (lib.cmakeBool "CAELESTIA_PACKAGE" true)
    (lib.cmakeBool "REQUIRE_CAVA" true)
    "-DCAELESTIA_M3SHAPES_SOURCE_DIR:PATH=${m3shapesSrc}"
  ];

  # Everything installed here is a library/QML module or a script; the only real
  # executable (`caelestia-version`) does not link Qt, so skip app wrapping.
  dontWrapQtApps = true;

  # ccache is baked into the compiler wrapper and cannot create its cache in the
  # isolated build env; pass through to the real compiler instead.
  CCACHE_DISABLE = "1";

  # The build tree sets QT_QML_OUTPUT_DIRECTORY under build/qml; nothing external.

  postInstall = ''
    # CAELESTIA_PACKAGE installs the SDDM theme and the Plasma/Shell KPackage
    # under a literal usr/ prefix (their CMake DESTINATIONs are hardcoded). Move
    # them to ordinary Nix output paths.
    if [ -d "$out/usr/share" ]; then
      mkdir -p "$out/share"
      cp -r "$out/usr/share/." "$out/share/"
      rm -rf "$out/usr"
    fi

    # Wrap the CLI helpers so the tools they call by name resolve on NixOS, and
    # so their install-layout looks land inside $out instead of /usr.
    for prog in ${lib.concatStringsSep " " caelestiaBinScripts}; do
      if [ -f "$out/bin/$prog" ]; then
        wrapProgram "$out/bin/$prog" \
          --prefix PATH : "$out/bin:${runtimePath}" \
          --set-default QML2_IMPORT_PATH "$out/lib/qt6/qml" \
          --set-default CAELESTIA_LIB_DIR "$out/lib/caelestia" \
          --set-default CAELESTIA_BIN_DIR "$out/bin" \
          --set-default CAELESTIA_DATA_DIR "$out/share/caelestia" \
          --set-default CAELESTIA_SHELL_CONFIG "$out/etc/xdg/quickshell/caelestia/shell.qml"
      fi
    done

    # Autostart launcher (the AUR file hardcodes /usr).
    cp ${./caelestia-autostart.in} "$out/bin/caelestia-autostart"
    substituteInPlace "$out/bin/caelestia-autostart" \
      --replace-fail "@quickshell@" "${pkgs.quickshell}" \
      --replace-fail "@out@" "$out" \
      --replace-fail "@caelestiaRuntimePath@" "${runtimePath}"
    chmod +x "$out/bin/caelestia-autostart"

    # Quickshell's .desktop is what makes KWin advertise its privileged Wayland
    # interfaces (live window thumbnails). KWin matches Exec against the client's
    # real executable, so it must name the store path of the real quickshell.
    install -d "$out/share/applications"
    sed -e "s|^Exec=.*|Exec=${pkgs.quickshell}/bin/quickshell|" \
        -e "s|/usr/share/applications|$out/share/applications|" \
        "$out/share/caelestia/assets/org.quickshell.desktop" \
        > "$out/share/applications/org.quickshell.desktop"

    # Build-time sanity: every QML module the CI script expects must be present.
    for module in Caelestia Caelestia/Components Caelestia/Config Caelestia/Settings \
                  Caelestia/Models Caelestia/Services Caelestia/Services/QuickShare \
                  Caelestia/Blobs Caelestia/Images Caelestia/Layouts M3Shapes; do
      test -f "$out/lib/qt6/qml/$module/qmldir" || {
        echo "ERROR: missing QML module $module" >&2; exit 1; }
    done
    test -f "$out/etc/xdg/quickshell/caelestia/shell.qml" || {
      echo "ERROR: shell.qml missing" >&2; exit 1; }

    # Point the keyboard-layout popout at the Nix store XKB rules. Sanity-check
    # that no upstream /usr/share/X11/xkb path survives in the installed QML.
    for kb in $(find "$out/etc/xdg" -name KbLayoutModel.qml); do
      substituteInPlace "$kb" \
        --replace-fail "/usr/share/X11/xkb/rules/base.xml" "${xkbRulesDir}/base.xml" \
        --replace-fail "/usr/share/X11/xkb/rules/evdev.xml" "${xkbRulesDir}/evdev.xml"
      test -z "$(grep -o '/usr/share/X11/xkb/rules/' "$kb" || true)" || {
        echo "ERROR: hardcoded XKB path still present in $kb" >&2; exit 1; }
    done
  '';

  meta = {
    description = "The Caelestia desktop shell, ported to KDE Plasma";
    homepage = "https://github.com/ladybug-me/caelestia-kde";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "caelestia";
  };
})
