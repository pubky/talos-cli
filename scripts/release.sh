#!/usr/bin/env bash
# One release, one command: set the version in `talos`, sync the plugin, pin the new file's sha256
# in install.sh, run the selftest, commit and tag. The tag is what install.sh downloads and the
# checksum is what it checks, so a release nobody made by hand cannot be installed.
#
#   scripts/release.sh 0.4.0        then: git push origin main && git push origin v0.4.0
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
V="${1:-}"
case "$V" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "usage: scripts/release.sh <x.y.z>" >&2; exit 2;;
esac
cd "$ROOT"
[ -z "$(git status --porcelain)" ] || { echo "release: commit or stash your changes first" >&2; exit 1; }
if git rev-parse -q --verify "refs/tags/v$V" >/dev/null; then echo "release: v$V already exists" >&2; exit 1; fi

python3 - "$V" <<'EOF'
import re, sys
v = sys.argv[1]
src = open("talos").read()
out = re.sub(r'(?m)^VERSION = "[^"]*"$', 'VERSION = "%s"' % v, src, count=1)
if out == src and 'VERSION = "%s"' % v not in src:
    sys.exit("release: could not set VERSION in talos")
open("talos", "w").write(out)
EOF

scripts/sync-plugin.sh >/dev/null

python3 - "$V" <<'EOF'
import hashlib, re, sys
v = sys.argv[1]
sha = hashlib.sha256(open("talos", "rb").read()).hexdigest()
src = open("install.sh").read()
src = re.sub(r'(?m)^TALOS_VERSION="[^"]*"$', 'TALOS_VERSION="%s"' % v, src, count=1)
src = re.sub(r'(?m)^TALOS_SHA256="[^"]*"$', 'TALOS_SHA256="%s"' % sha, src, count=1)
src = re.sub(r'\.\.\./v[0-9][^/]*/install\.sh', '.../v%s/install.sh' % v, src)
open("install.sh", "w").write(src)

# the README publishes the pinned line and the checksum, so both are part of the release
doc = open("README.md").read()
doc = re.sub(r'/talos-cli/v[0-9][^/]*/install\.sh', '/talos-cli/v%s/install.sh' % v, doc)
doc = re.sub(r'(?m)^talos [0-9][^ ]* is sha256 `[0-9a-f]{64}`',
             'talos %s is sha256 `%s`' % (v, sha), doc)
open("README.md", "w").write(doc)
EOF
SHA="$(python3 -c 'import hashlib;print(hashlib.sha256(open("talos","rb").read()).hexdigest())')"

scripts/selftest.sh

git add -A
git commit -m "release: $V"
git tag -a "v$V" -m "talos $V"
cat <<EOF

talos $V is committed and tagged. Push both:

  git push origin main && git push origin v$V

The install line, unchanged:

  curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh

Pinned to this release, with the checksum it verifies:

  curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/v$V/install.sh | sh
  talos $V sha256 $SHA
EOF
