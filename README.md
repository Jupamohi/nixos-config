# vt-lens-nix

Paquete de Nix para [VT Lens](https://github.com/ValentinTorassa/VT-Lens), una GUI nativa en Rust (egui/eframe) para entender qué hace tu equipo: procesos en ejecución, conexiones de red visibles y un espacio de evidencia que genera prompts y exportaciones en Markdown.

Este repositorio contiene solo el empaquetado. El flake descarga el código de VT Lens desde GitHub y lo compila.

## Uso

Requiere Nix con flakes activados.

```bash
nix run github:Jupamohi/vt-lens-nix                  # ejecutar sin instalar
nix run github:Jupamohi/vt-lens-nix -- --demo        # con datos sintéticos
nix profile install github:Jupamohi/vt-lens-nix      # instalar en tu perfil
```

La primera vez compila Rust desde cero, así que tarda unos minutos.

Probado en NixOS (nixos-unstable). Las demás plataformas que declara el flake (aarch64-linux y macOS) no se han probado.

### NixOS

Añade el paquete a `environment.systemPackages` en una configuración basada en flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vt-lens-nix.url = "github:Jupamohi/vt-lens-nix";
    vt-lens-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, vt-lens-nix, ... }: {
    nixosConfigurations.mi-equipo = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            vt-lens-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        })
      ];
    };
  };
}
```

También se expone un overlay (`overlays.default`) que añade `pkgs.vt-lens`.

## Contenido

| Archivo | Qué hace |
| --- | --- |
| `flake.nix` | Expone el paquete, la app y el overlay. Fija la versión de VT Lens con el input `vt-lens-src`. |
| `package.nix` | Derivación: compila con `rustPlatform.buildRustPackage` usando el `Cargo.lock` del proyecto. |

El paquete añade al rpath las bibliotecas que eframe/winit cargan en tiempo de ejecución (wayland, xkbcommon, libGL, vulkan y X11), instala el lanzador `vt-lens.desktop` y deja `secret-tool` (libsecret) disponible para guardar la API key en el llavero.

## Actualizar a otra versión de VT Lens

Cambia el tag en `flake.nix` (`github:ValentinTorassa/VT-Lens/v0.3.0`) y ejecuta:

```bash
nix flake update vt-lens-src
```

## Licencia

Los archivos de este repositorio se publican bajo licencia MIT (ver `LICENSE`).

VT Lens es de [Valentin Torassa](https://github.com/ValentinTorassa) y se distribuye bajo GPL-3.0-only.
