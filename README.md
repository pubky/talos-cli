# talos-cli

Talos, the pubky team's agent, from your terminal and from your coding agent (Claude Code,
Codex, anything that runs shell commands or MCP tools).

```
talos find "nexus watcher lag"          search Slack, Meet transcripts, Drive, GitHub and pubky.app; seconds, no model
talos ask "why did we drop X?"          one Talos turn; he answers with links (30 to 180 s, 30 per person per day)
talos review <pr-url>                   Talos reviews the PR; the review lands on GitHub within minutes
```

## Install

1. Ask @SHAcollision for a token (one per person, revocable). It comes with the desk URL.
2. Install the CLI. It registers itself with Claude Code and Codex when they are present:

   ```
   curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
   talos login <token> --url <desk url>
   ```

   Claude Code users can also take the plugin route: `/plugin marketplace add pubky/talos-cli`,
   then `/plugin install talos`. The plugin's MCP server runs `talos mcp`, so step 2 is still
   needed once for the binary.

3. Check: `talos whoami`.

`talos setup` can be rerun any time; it is idempotent. What it does: writes the skill to
`~/.claude/skills/talos/SKILL.md` and `~/.codex/skills/talos/SKILL.md`, registers the MCP
server `talos` (user scope) with `claude mcp add` and in `~/.codex/config.toml`.

## Using it from an agent

The skill file tells Claude Code and Codex when to reach for Talos without being asked: `find`
for any "where did we discuss", "did anyone report", "who owns", "what did the call conclude";
`ask` only when the answer needs Talos's memory, cross-repo context, who is out, Sentry or CI
history; `review` after opening a PR in a pubky repo. Same rules for the MCP tools
`talos_find`, `talos_ask`, `talos_review`, `talos_whoami`.

## Details

- `talos ask --thread <name>` continues a conversation; every answer prints its thread name.
- `--json` on `find` and `ask` for scripting. Exit codes: 0 ok, 1 error, 2 usage, 3 over
  budget, 4 not logged in or token revoked.
- The token lives in `~/.config/talos/config.json` (mode 0600); `TALOS_TOKEN` and `TALOS_URL`
  override it (CI, containers).
- Every ask and review request is logged with your handle and echoed to the team's ops channel.
  Do not paste secrets into an ask.
- An ask is a real Talos turn with his usual tools and guards, the same trust as mentioning him
  in Slack. If he posts or changes something on your request, he says exactly what.

## Layout

```
talos                       the CLI, single file, Python 3.8+ standard library only
install.sh                  curl | sh installer
plugins/talos/              Claude Code plugin: skill + MCP server config
  skills/talos/SKILL.md     the skill; the same text is embedded at the end of `talos` (keep both in sync)
.claude-plugin/marketplace.json
```

The server side (`talos-desk`) lives in the private `pubky/talos-agent` repo.
