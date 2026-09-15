#!/bin/sh
# Installs the talos CLI into ~/.local/bin and registers it with every coding harness on the machine.
#   curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
#
# The two lines below are the release: scripts/release.sh writes them, and nothing here runs unless
# the file downloaded from that tag has that sha256. This file is what pins what executes, so
# fetching it at a tag (.../v0.4.0/install.sh) pins the whole chain.
set -eu
TALOS_VERSION="0.4.0"
TALOS_SHA256="8dcc3bd9c2d2c9e3e70576f545632cd58bcc03b36070baae9d5d5f726bc23aab"

REPO="${TALOS_REPO_RAW:-https://raw.githubusercontent.com/pubky/talos-cli}"
RAW="$REPO/v$TALOS_VERSION/talos"
BIN="${TALOS_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$BIN"

# mktemp, not a fixed name: a second installer running at the same time cannot decide what this one
# puts in place, and the download stays private until it is verified
TMP="$(mktemp "$BIN/.talos.XXXXXX")"
trap 'rm -f "$TMP"' EXIT INT TERM
if command -v curl >/dev/null 2>&1; then curl -fsSL "$RAW" -o "$TMP"; else wget -qO "$TMP" "$RAW"; fi

if command -v sha256sum >/dev/null 2>&1; then GOT="$(sha256sum "$TMP" | cut -d' ' -f1)"
elif command -v shasum >/dev/null 2>&1; then GOT="$(shasum -a 256 "$TMP" | cut -d' ' -f1)"
else
  echo "talos: no sha256sum or shasum here, so nothing can be verified; not installing" >&2
  exit 1
fi
if [ "$GOT" != "$TALOS_SHA256" ]; then
  echo "talos: $RAW is not the file this installer pins, nothing was installed" >&2
  echo "  expected $TALOS_SHA256" >&2
  echo "  got      $GOT" >&2
  exit 1
fi

chmod 755 "$TMP"
if [ -f "$BIN/talos" ]; then cp -p "$BIN/talos" "$BIN/talos.prev"; fi
mv "$TMP" "$BIN/talos"
trap - EXIT INT TERM

case ":$PATH:" in *":$BIN:"*) ;; *) echo "add $BIN to your PATH (e.g. export PATH=\"$BIN:\$PATH\" in your shell rc)";; esac
"$BIN/talos" setup
echo
echo "installed $("$BIN/talos" --version). Next: run talos login   (it prints a GitHub prompt: open the page, type the code)"
echo "if a release misbehaves, talos rollback puts $BIN/talos.prev back"
