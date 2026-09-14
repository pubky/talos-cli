# talos-cli

Talos, the pubky team's agent, from your terminal and from your coding agent (Claude Code,
Codex, anything that runs shell commands or MCP tools).

Give your agent this one line and it does the rest:

> Install the talos CLI with `curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh`, run `talos login` and complete the GitHub device prompt it prints, then `talos whoami`; from now on use talos for anything about this team (`talos` lists the verbs).

No token to paste and no URL to look up: `talos login` prints an "Open ... and enter code ..."
line, you open that page, type the code, and the desk checks your pubky org membership and gives
you a token of its own. Logging in again rotates it, so the old one stops working.

```
talos                                   every verb, by tier
talos find "nexus watcher lag"          search Slack, Meet transcripts, Drive, GitHub and pubky.app
talos who ben                           a teammate's team, GitHub login and Slack id
talos issue pubky/pubky-nexus "bug"     file an issue (prints a preview first, needs --yes)
talos ask "why did we drop X?"          one Talos turn, with links
talos delegate "long job"               hand him a job, collect it later with `talos result`
```

## Install

```
curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
talos login
talos whoami
```

The installer also writes the skill for Claude Code and Codex and registers the MCP server, so
your agent already knows when to use Talos. Tell it "use talos for anything about the team" and
it takes it from there.

Claude Code users can take the plugin route instead: `/plugin marketplace add pubky/talos-cli`,
then `/plugin install talos`. The plugin carries its own copy of the CLI, so there is nothing to
install; the agent runs `python3 ${CLAUDE_PLUGIN_ROOT}/bin/talos login` when it needs you to sign
in.

`talos setup` reruns the registration and refreshes the skill from the desk; `talos doctor`
checks the whole chain and says what to fix.

### If you are not in the pubky GitHub org

Device login only works for org members. Ask @SHAcollision for a token and run
`talos login <token>`. Everything else is the same.

## Where the desk lives

The CLI takes the desk URL from `--url`, then `TALOS_URL`, then your stored config, then
[`desk-url.txt`](desk-url.txt) in this repo. Moving the desk to a new address is one commit to
that file: `talos login` and `talos doctor` notice the stored one stopped answering and pick the
new address up on their own.

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
- The desk token lives in `~/.config/talos/config.json` (mode 0600); `TALOS_TOKEN` and `TALOS_URL`
  override it (CI, containers). The GitHub token from the device flow is never stored.
- Every write and every agent turn is logged with your handle and echoed to the team's ops
  channel. Do not paste secrets into an ask.
- An ask is a real Talos turn with his usual tools and guards, the same trust as mentioning him
  in Slack. If he posts or changes something on your request, he says exactly what.

## Layout

```
talos                       the CLI, single file, Python 3.8+ standard library only
install.sh                  curl | sh installer
desk-url.txt                where the desk is today, one line
scripts/selftest.sh         every CLI path against a stub desk, including the v0.1 fallback
scripts/sync-plugin.sh      copy the CLI into the plugin and regenerate its skill
plugins/talos/              Claude Code plugin: the CLI, the skill, the MCP server config
  bin/talos                 a copy of the CLI, kept identical by sync-plugin.sh
  skills/talos/SKILL.md     a snapshot of the sheet the desk serves
.claude-plugin/marketplace.json
```

The desk serves the sheet at `GET /skill`, and `talos setup` and `talos login` refresh both skill
files from it. The copy embedded in `talos` and the one under `plugins/` are bootstrap snapshots,
for a machine that has not logged in yet.

The server side (`talos-desk`) lives in the private `pubky/talos-agent` repo.
