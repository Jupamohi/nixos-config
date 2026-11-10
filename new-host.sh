#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

read -p "Nombre del nuevo host (ej. pcAmigo): " HOSTNAME

if [[ ! "$HOSTNAME" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
  echo "Nombre inválido: usa letras, números, guion o guion bajo, y empieza por una letra."
  exit 1
fi

if grep -qE "^[[:space:]]*${HOSTNAME} = mkHost" flake.nix; then
  echo "Ya existe un host con ese nombre en flake.nix. Abortando."
  exit 1
fi

HW_DIR="hosts/hardware-${HOSTNAME}"
mkdir -p "$HW_DIR"

sudo cp /etc/nixos/hardware-configuration.nix "$HW_DIR/hardware-configuration.nix"
sudo chown "$USER":users "$HW_DIR/hardware-configuration.nix"

# Inserta el host antes del marcador, conservando su indentación.
# mkHost recibe dos argumentos: el hardware y una lista de módulos extra.
sed -i "s|^\( *\)# NEW_HOST_MARKER|\1${HOSTNAME} = mkHost ./hosts/hardware-${HOSTNAME}/hardware-configuration.nix [ ];\n\1# NEW_HOST_MARKER|" flake.nix

echo ""
echo "Host '${HOSTNAME}' agregado a flake.nix y hardware-configuration.nix copiado."
echo ""
git add "$HW_DIR" flake.nix
git status

echo ""
read -p "¿Hacer rebuild ahora con este host? (s/n): " DO_REBUILD
if [[ "$DO_REBUILD" == "s" ]]; then
  sudo nixos-rebuild switch --flake ".#${HOSTNAME}"
fi
