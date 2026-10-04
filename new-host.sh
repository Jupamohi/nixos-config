#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

read -p "Nombre del nuevo host (ej. pcAmigo): " HOSTNAME

if grep -q "^  ${HOSTNAME} = mkHost" flake.nix; then
  echo "Ya existe un host con ese nombre en flake.nix. Abortando."
  exit 1
fi

HW_DIR="hosts/hardware-${HOSTNAME}"
mkdir -p "$HW_DIR"

sudo cp /etc/nixos/hardware-configuration.nix "$HW_DIR/hardware-configuration.nix"
sudo chown "$USER":users "$HW_DIR/hardware-configuration.nix"

sed -i "s|  # NEW_HOST_MARKER|  ${HOSTNAME} = mkHost ./hosts/hardware-${HOSTNAME}/hardware-configuration.nix;\n  # NEW_HOST_MARKER|" flake.nix

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
