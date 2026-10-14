# Single source of truth for the pinned M3Shapes revision. Used both to build the
# m3shapes package and, as *source*, as the FetchContent input of the main shell
# build (CAELESTIA_M3SHAPES_SOURCE_DIR must point at a tree with CMakeLists.txt,
# not at a built output).
{ fetchgit }:
fetchgit {
  url = "https://github.com/soramanew/m3shapes.git";
  rev = "bdc327b29f95394a732baf3c9b19658ba23755b6";
  hash = "sha256-kfHyzZaPHgqZML48OA+5JwBOsLdQJ2ci/aGPShvUB4Y=";
}
