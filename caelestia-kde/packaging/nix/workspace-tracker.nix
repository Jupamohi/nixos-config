# The Caelestia KWin effect (workspace tracker). Separate CMake project under
# shell/kwin-effects/workspace-tracker, built and installed on its own.
{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  qt6,
  kdePackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "caelestia-workspace-tracker";
  version = "6.0.0";

  src = lib.cleanSourceWith {
    src = ../../shell/kwin-effects/workspace-tracker;
    filter =
      path: type:
      let
        base = baseNameOf (toString path);
      in
      base != "build";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.kconfig
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    kdePackages.kcoreaddons
    kdePackages.kwin
  ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" (placeholder "out"))
  ];

  # KWin effect plug-in (.so), not an application: nothing to wrap.
  dontWrapQtApps = true;

  meta = {
    description = "Caelestia workspace tracker KWin effect";
    homepage = "https://github.com/ladybug-me/caelestia-kde";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
