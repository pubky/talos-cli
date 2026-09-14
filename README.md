# talos-cli

Talos, the pubky team's agent, from your terminal and from your coding agent (Claude Code,
Codex, anything that runs shell commands or MCP tools).

```
talos                                   every verb, by tier
talos find "nexus watcher lag"          search Slack, Meet transcripts, Drive, GitHub and pubky.app
talos who ben                           a teammate's team, GitHub login and Slack id
talos issue pubky/pubky-nexus "bug"     file an issue (prints a preview first, needs --yes)
talos ask "why did we drop X?"          one Talos turn, with links
talos delegate "long job"               hand him a job, collect it later with `talos result`
```

## Install

Two commands, and you run them yourself in your terminal, not through your agent: the second
one carries your token, and agents are right to refuse to handle secrets pasted into a prompt.

1. Ask @SHAcollision for a token. It comes with the desk URL.
2. Run:

   ```
   curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
   talos login <token> --url <desk url>
   ```

3. `talos whoami` should print your name. Done: the installer also wrote the skill for Claude
   Code and Codex and registered the MCP server, so your agent already knows when to use Talos.
   Tell it "use talos for anything about the team" and it takes it from there.

Claude Code users can take the plugin route instead of step 2's first line:
`/plugin marketplace add pubky/talos-cli`, then `/plugin install talos`, then `talos login`.

`talos setup` reruns the registration and refreshes the skill from the desk; `talos doctor`
checks the whole chain and says what to fix.

## Using it from an agent

The skill file tells Claude Code and Codex when to reach for Talos without being asked: `find`
for any "where did we discuss", "did anyone report", "who owns", "what did the call conclude";
`skills` for what the team already wrote down; `ask` only when the answer needs Talos's memory or
judgement; `review` after opening a PR. The same verbs are MCP tools (`talos_find`, `talos_who`,
`talos_issue`, and so on), and the readable knowledge skills are MCP resources
(`talos://skills/<name>`). A write tool without `yes: true` returns the preview instead of acting.

## Details

- `talos ask --thread <name>` continues a conversation; every answer prints its thread name.
- `talos delegate --key <k>` is idempotent: a retry with the same key returns the same run.
- The token lives in `~/.config/talos/config.json` (mode 0600); `TALOS_TOKEN` and `TALOS_URL`
  override it (CI, containers).
- Every write and every agent turn is logged with your handle and echoed to the team's ops
  channel. Do not paste secrets into an ask.
- An ask is a real Talos turn with his usual tools and guards, the same trust as mentioning him
  in Slack. If he posts or changes something on your request, he says exactly what.

## Layout

```
talos                       the CLI, single file, Python 3.8+ standard library only
install.sh                  curl | sh installer
scripts/selftest.sh         every CLI path against a stub desk, including the v0.1 fallback
plugins/talos/              Claude Code plugin: skill + MCP server config
  skills/talos/SKILL.md     a snapshot of the sheet the desk serves
.claude-plugin/marketplace.json
```

The desk serves the sheet at `GET /skill`, and `talos setup` and `talos login` refresh both skill
files from it. The copy embedded in `talos` and the one under `plugins/` are bootstrap snapshots,
for a machine that has not logged in yet.

The server side (`talos-desk`) lives in the private `pubky/talos-agent` repo.
