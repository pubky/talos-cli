#!/bin/sh
# Installs the talos CLI into ~/.local/bin and registers it with every coding harness on the machine.
#   curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
#
# The two lines below are the release: scripts/release.sh writes them, and nothing here runs unless
# the file downloaded from that tag has that sha256. This file is what pins what executes; fetching
# it at a tag (.../v0.4.1/install.sh) pins it to that tag, for as long as the tag is not moved.
set -eu
TALOS_VERSION="0.4.1"
TALOS_SHA256="79f90fe86b3baaa77b6f87696731046aebb739b55b8bb37ac2eacb60c999a67a"

REPO="${TALOS_REPO_RAW:-https://raw.githubusercontent.com/pubky/talos-cli}"
RAW="$REPO/v$TALOS_VERSION/talos"
BIN="${TALOS_BIN_DIR:-$HOME/.local/bin}"
# a relative directory would land in whatever directory this runs from, and so would the PATH advice
case "$BIN" in /*) ;; *) echo "talos: TALOS_BIN_DIR must be an absolute path, not $BIN" >&2; exit 1;; esac
mkdir -p "$BIN"

# mktemp, not a fixed name: a second installer running at the same time cannot decide what this one
# puts in place, and the download stays private until it is verified
TMP="$(mktemp "$BIN/.talos.XXXXXX")"
trap 'rm -f "$TMP" "$TMP.prev"' EXIT HUP INT TERM
# the same 4 MB cap talos update applies to a release
if command -v curl >/dev/null 2>&1; then curl -fsSL --max-filesize 4194304 "$RAW" -o "$TMP"; else wget -qO "$TMP" "$RAW"; fi

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
# the copy kept for rollback lands by rename, so it is never half written and a symlink at
# talos.prev is replaced rather than written through; reinstalling the same release keeps it
if [ -f "$BIN/talos" ] && ! cmp -s "$TMP" "$BIN/talos"; then
  cp -p "$BIN/talos" "$TMP.prev"
  mv -f "$TMP.prev" "$BIN/talos.prev"
fi
mv "$TMP" "$BIN/talos"
trap - EXIT HUP INT TERM

case ":$PATH:" in *":$BIN:"*) ;; *) echo "add $BIN to your PATH (e.g. export PATH=\"$BIN:\$PATH\" in your shell rc)";; esac
# setup registers the talos that PATH resolves, which has to be this one even before PATH has $BIN
PATH="$BIN:$PATH" "$BIN/talos" setup
echo
echo "installed $("$BIN/talos" --version). Next: run talos login   (it prints a GitHub prompt: open the page, type the code)"
echo "if a release misbehaves, talos rollback puts $BIN/talos.prev back"
