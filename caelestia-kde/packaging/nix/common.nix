# Shared dependency sets, verified against nixpkgs-unstable (Qt 6.11, KF6 6.30).
#
# `shell` is everything shell/plug-in links against. `effect` is the extra KWin
# bits the workspace-tracker effect needs on top. Keep these in sync with
# shell/plugin/CMakeLists.txt and shell/plugin/src/Caelestia/**/CMakeLists.txt.
{ pkgs }:

let
  qt = with pkgs.qt6; [
    qtbase
    qtdeclarative
    qtshadertools
    qtsvg
    qtmultimedia
    qtwayland
    qt5compat
    qtimageformats
  ];

  kf6 = with pkgs.kdePackages; [
    kwindowsystem
    kguiaddons
    networkmanager-qt
    pulseaudio-qt
    kglobalaccel
    kconfig
  ];

  systemLibs = with pkgs; [
    libqalculate
    pipewire
    libpulseaudio
    aubio
    lm_sensors
    libcava
    fftw
    protobuf
    openssl
    libx11
    wayland
  ];
in
{
  shellBuildInputs = qt ++ kf6 ++ systemLibs;

  shellNativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    ccache
    kdePackages.extra-cmake-modules
    qt6.qttools
  ];

  effectBuildInputs = with pkgs; [
    qt6.qtbase
    kdePackages.kcoreaddons
    kdePackages.kwin
  ];

  effectNativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    kdePackages.extra-cmake-modules
  ];
}
