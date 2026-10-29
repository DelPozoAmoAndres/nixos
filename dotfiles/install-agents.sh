#!/usr/bin/env bash
# Despliega la configuracion de agentes (Claude, opencode, Penpot, paperclip)
# desde el repo a tu home. Es idempotente: se puede volver a ejecutar.
#
#   ~/nixos/dotfiles/install-agents.sh
#
# Los ficheros se copian (no se enlazan) porque los gestores de plugins
# necesitan poder escribir en esos directorios para instalar o actualizar
# skills. No se borra nada de lo que haya en el destino.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/agents"
HOME_DIR="${HOME}"

copiar_dir() {
  local origen="$1" destino="$2"
  [ -d "$origen" ] || { echo "  - no existe $origen, se omite"; return 0; }
  mkdir -p "$destino"
  rsync -a --no-owner --no-group "$origen/" "$destino/"
  echo "  ✓ $(basename "$destino")"
}

copiar_fichero() {
  local origen="$1" destino="$2"
  [ -f "$origen" ] || { echo "  - no existe $origen, se omite"; return 0; }
  mkdir -p "$(dirname "$destino")"
  if [ -e "$destino" ] && ! cmp -s "$origen" "$destino"; then
    cp -a "$destino" "$destino.bak"
  fi
  cp -a "$origen" "$destino"
  echo "  ✓ $(basename "$destino")"
}

echo "Skills de Claude"
copiar_dir "$SRC/claude/skills" "$HOME_DIR/.claude/skills"

echo "opencode"
copiar_dir "$SRC/opencode/skills" "$HOME_DIR/.config/opencode/skills"
copiar_dir "$SRC/opencode/agents" "$HOME_DIR/.config/opencode/agents"
copiar_dir "$SRC/opencode/agent"  "$HOME_DIR/.config/opencode/agent"
copiar_fichero "$SRC/opencode/opencode.json" "$HOME_DIR/.config/opencode/opencode.json"

# El config con los MCP (Stitch, Penpot) lleva credenciales, asi que no va al
# repo. Si el destino ya tiene bloque "mcp" se respeta y no se toca.
if [ -f "$HOME_DIR/.config/opencode/opencode.jsonc" ] && grep -q '"mcp"' "$HOME_DIR/.config/opencode/opencode.jsonc"; then
  echo "  · opencode.jsonc conserva tu bloque mcp local, no se sobreescribe"
else
  copiar_fichero "$SRC/opencode/opencode.jsonc" "$HOME_DIR/.config/opencode/opencode.jsonc"
fi

echo "Kit de Penpot"
copiar_dir "$SRC/penpot-ai-kit" "$HOME_DIR/.penpot-ai-kit"

echo "paperclip"
copiar_fichero "$SRC/paperclip/adapter-settings.json" "$HOME_DIR/.paperclip/adapter-settings.json"
copiar_dir "$SRC/paperclip/adapter-plugins" "$HOME_DIR/.paperclip/adapter-plugins"

echo
echo "Listo. Reinicia opencode y claude para que carguen los cambios."
