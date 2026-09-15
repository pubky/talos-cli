#!/bin/sh
# Installs the talos CLI into ~/.local/bin and registers it with every coding harness on the machine.
#   curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
set -e
RAW="https://raw.githubusercontent.com/pubky/talos-cli/main/talos"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW" -o "$BIN/talos.tmp"; else wget -qO "$BIN/talos.tmp" "$RAW"; fi
chmod +x "$BIN/talos.tmp" && mv "$BIN/talos.tmp" "$BIN/talos"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "add $BIN to your PATH (e.g. export PATH=\"$BIN:\$PATH\" in your shell rc)";; esac
"$BIN/talos" setup
echo
echo "installed $("$BIN/talos" --version). Next: run talos login   (it prints a GitHub prompt: open the page, type the code)"
