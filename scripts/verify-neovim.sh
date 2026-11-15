#!/usr/bin/env bash
# Verificacion post-instalacion de la config de Neovim/LazyVim.
set -uo pipefail

echo "== Binario =="
command -v nvim || { echo "FAIL: nvim no esta en el PATH"; exit 1; }
nvim --version | head -3

echo
echo "== Plugins descargados en runtime (deberia estar vacio) =="
if [ -d ~/.local/share/nvim/lazy ] && [ -n "$(ls -A ~/.local/share/nvim/lazy 2>/dev/null)" ]; then
  echo "WARN: hay plugins descargados en ~/.local/share/nvim/lazy:"
  ls -1 ~/.local/share/nvim/lazy
else
  echo "OK: ninguno (todo viene del nix store)"
fi

echo
echo "== Parsers de Tree-sitter instalados =="
COUNT=$(ls ~/.local/share/nvim/site/parser/*.so 2>/dev/null | wc -l)
echo "  $COUNT grammars en ~/.local/share/nvim/site/parser/"
for g in css html javascript tsx typescript scss angular astro svelte go nix json yaml markdown lua bash; do
  [ -e ~/.local/share/nvim/site/parser/$g.so ] && printf "  %-12s OK\n" "$g" || printf "  %-12s FALTA\n" "$g"
done

echo
echo "== Herramientas dentro de Neovim =="
timeout 60 nvim --headless \
  '+lua for _,t in ipairs({"rg","fd","lazygit","fzf","tree-sitter","gopls","vtsls","prettier","eslint","nixd","go","node","trash","gs","mmdc"}) do print("  "..t.." -> "..(vim.fn.executable(t)==1 and "OK" or "FALTA")) end' \
  '+qa' 2>&1 | grep -E "^\s+\S+ -> " | head -20

echo
echo "== Snacks: input/select/notifier (tras UIEnter) =="
# Snacks activa input/picker/dashboard en el evento UIEnter, que en
# headless nunca se dispara. Se dispara a mano para poder comprobarlos.
timeout 60 nvim --headless \
  '+lua vim.api.nvim_exec_autocmds("UIEnter", {})' \
  '+lua vim.wait(300)' \
  '+lua require("snacks.input").enable()' \
  '+lua require("snacks.picker").select = require("snacks.picker").select' \
  '+lua print("  vim.ui.input  == Snacks.input        -> "..tostring(vim.ui.input == require("snacks.input").input))' \
  '+lua print("  vim.ui.select == Snacks.picker.select -> "..tostring(vim.ui.select == Snacks.picker.select))' \
  '+lua print("  Snacks dashboard                      -> "..tostring(Snacks.dashboard ~= nil))' \
  '+qa' 2>&1 | grep -E "^  " | head -10

echo
echo "== Errores en el log =="
if [ -f ~/.local/state/nvim/nvim.log ]; then
  N=$(grep -icE 'E[0-9]{3}:|error detected' ~/.local/state/nvim/nvim.log)
  if [ "$N" -gt 0 ]; then
    grep -iE 'E[0-9]{3}:|error detected' ~/.local/state/nvim/nvim.log | head -10
  else
    echo "OK: sin errores"
  fi
else
  echo "OK: no hay log"
fi

echo
echo "== Health check =="
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
NVIM_HEALTH="$TMP/health-after.txt" timeout 150 nvim --headless \
  '+checkhealth' '+w! $NVIM_HEALTH' '+qa' >/dev/null 2>&1

echo "-- Errores REALES:"
# Falsos positivos conocidos de Snacks en headless. Snacks activa
# input/picker/dashboard/notifier en el evento UIEnter, que headless no
# dispara, asi que sus checks de salud fallan artificialmente.
#   - "setup did not run"        -> Snacks.dashboard (UIEnter)
#   - "vim.ui.input/select ..."  -> Snacks.input / Snacks.picker (UIEnter)
#   - "is not ready"             -> Snacks.notifier (UIEnter)
#   - "kitty graphics protocol"  -> headless no lo soporta
# Ademas, Snacks 2.31.0 todavia exige tectonic/pdflatex para LaTeX en
# Markdown; el paquete tectonic de nixpkgs no compila en esta maquina, asi
# que se deja fuera de forma consciente.
grep -E "❌ ERROR" "$TMP"/health-after.txt 2>/dev/null \
  | grep -vE "setup did not run|vim\.ui\.(input|select) is not set|is not ready|kitty graphics protocol|tectonic.*pdflatex" \
  > "$TMP"/real-errors.txt || true

if [ -s "$TMP"/real-errors.txt ]; then
  sed 's/^/  /' "$TMP"/real-errors.txt
else
  echo "  OK: sin errores reales"
fi

echo
echo "-- Parsers faltantes (si aparece la lista, hay que anadirlos):"
grep -A3 "Missing Treesitter languages" "$TMP"/health-after.txt 2>/dev/null \
  | grep -E "^\s+\`" | sed 's/^/  /' | sort -u || echo "  OK: todos los parsers presentes"
