export ZSH="$HOME/.oh-my-zsh"

# El tema lo cargamos manual más abajo (powerlevel10k vía paquete Nix),
# así que aquí dejamos el de Oh My Zsh en blanco o con uno simple de respaldo
ZSH_THEME=""

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Plugins instalados vía Nix (no clonados a mano)
source /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Powerlevel10k, también vía Nix
source /run/current-system/sw/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Tus alias y configuración
alias actualizar="~/.local/bin/update-system.sh"
alias ls="eza --icons=auto --git"

fastfetch