#!/usr/bin/env bash
# One release, one command: set the version in `talos`, sync the plugin, pin the new file's sha256
# in install.sh, run the selftest, commit and tag. The tag is what install.sh downloads and the
# checksum is what it checks, so a release nobody made by hand cannot be installed.
#
#   scripts/release.sh 0.4.0        then: git push origin main && git push origin v0.4.0
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
V="${1:-}"
# digits and dots only: the version is written into Python, shell and markdown unescaped
[[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "usage: scripts/release.sh <x.y.z>" >&2; exit 2; }
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

def sub(pattern, text, new, name):
    # a pattern that no longer matches would publish the previous pin under the new tag
    out, n = re.subn(pattern, lambda m: new, text)
    if not n:
        sys.exit("release: found no %s to rewrite" % name)
    return out

src = open("install.sh").read()
src = sub(r'(?m)^TALOS_VERSION="[^"]*"$', src, 'TALOS_VERSION="%s"' % v, "TALOS_VERSION in install.sh")
src = sub(r'(?m)^TALOS_SHA256="[^"]*"$', src, 'TALOS_SHA256="%s"' % sha, "TALOS_SHA256 in install.sh")
src = sub(r'\.\.\./v[0-9][^/]*/install\.sh', src, '.../v%s/install.sh' % v, "tag in install.sh")
open("install.sh", "w").write(src)

# the README publishes the pinned lines and the checksum, so all of them are part of the release
doc = open("README.md").read()
doc = sub(r'/talos-cli/v[0-9][^/]*/install\.sh', doc, '/talos-cli/v%s/install.sh' % v, "pinned install line in README.md")
doc = sub(r'talos-cli#v[0-9][0-9.]*[0-9]', doc, 'talos-cli#v%s' % v, "pinned marketplace in README.md")
doc = sub(r'(?m)^talos [0-9][^ ]* is sha256 `[0-9a-f]{64}`', doc,
          'talos %s is sha256 `%s`' % (v, sha), "checksum line in README.md")
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
