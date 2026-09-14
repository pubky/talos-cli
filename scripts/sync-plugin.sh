#!/usr/bin/env bash
# Copies the CLI into the Claude Code plugin and regenerates the plugin's skill from the sheet
# embedded in it. Run it after any change to `talos`; selftest.sh fails if the two drift apart.
#
#   scripts/sync-plugin.sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/plugins/talos"
mkdir -p "$PLUGIN/bin" "$PLUGIN/skills/talos"
cp "$ROOT/talos" "$PLUGIN/bin/talos"
chmod +x "$PLUGIN/bin/talos"

python3 - "$ROOT/talos" > "$PLUGIN/skills/talos/SKILL.md" <<'EOF'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("talos_cli", sys.argv[1])
spec = importlib.util.spec_from_loader("talos_cli", loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)
sys.stdout.write(mod.FRONTMATTER + mod.SKILL_MD.rstrip() + """

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
EOF
echo "synced $PLUGIN/bin/talos and its skill"
