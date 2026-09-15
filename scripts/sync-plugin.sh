#!/usr/bin/env bash
# Copies the CLI into the Claude Code plugin, stamps the plugin manifest with the CLI's version and
# regenerates the plugin's skill from the sheet embedded in the CLI. Run it after any change to
# `talos`; selftest.sh fails if the three drift apart.
#
#   scripts/sync-plugin.sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/plugins/talos"
MANIFEST="$PLUGIN/.claude-plugin/plugin.json"
SKILL="$PLUGIN/skills/talos/SKILL.md"
mkdir -p "$PLUGIN/bin" "$PLUGIN/skills/talos" "$PLUGIN/.claude-plugin"

install -m 755 "$ROOT/talos" "$PLUGIN/bin/.talos.new"
mv "$PLUGIN/bin/.talos.new" "$PLUGIN/bin/talos"

# both generated files land by rename, so a run that dies half way never leaves an empty skill or a
# manifest with no version in it
python3 - "$ROOT/talos" "$SKILL.new" "$MANIFEST" <<'EOF'
import importlib.machinery, importlib.util, json, os, sys
loader = importlib.machinery.SourceFileLoader("talos_cli", sys.argv[1])
spec = importlib.util.spec_from_loader("talos_cli", loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)
with open(sys.argv[2], "w") as fh:
    fh.write(mod.FRONTMATTER + mod.SKILL_MD.rstrip() + """

## Running it from this plugin

The CLI ships inside the plugin, so there is nothing to install:

```
python3 ${CLAUDE_PLUGIN_ROOT}/bin/talos find "nexus watcher lag"
```

If any verb answers `not logged in` (exit 4), run `python3 ${CLAUDE_PLUGIN_ROOT}/bin/talos login`,
show the user the "Open ... and enter code ..." line it prints, and wait: they open that page and
type the code. No token and no desk URL to ask for. On a machine that has `talos` on the PATH the
plain `talos` command does the same thing.
""")
manifest = sys.argv[3]
data = json.load(open(manifest)) if os.path.isfile(manifest) else {}
data["version"] = mod.VERSION          # the CLI's VERSION is the only version in this repo
with open(manifest + ".new", "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
EOF
mv "$SKILL.new" "$SKILL"
mv "$MANIFEST.new" "$MANIFEST"
echo "synced $PLUGIN/bin/talos, its skill and its manifest"
